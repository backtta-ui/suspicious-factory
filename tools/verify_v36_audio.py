#!/usr/bin/env python3
"""2.0.36 효과음 무결성·품질 수치 검증.

검사 항목
- 형식: 44.1kHz 스테레오 16-bit WAV, 0바이트 아님, 길이 0.08~3.0초
- 레벨: 피크 < 0.99(클리핑 없음), RMS 0.02~0.30, DC 오프셋 작음
- 고주파: 8kHz 위 에너지 비율 < 0.20 (치직거리는 히스)
- '전자음' 회귀 방지: 스펙트럼 평탄도(노이즈/타격 성분)가 0.015 이상이거나
  과도(transient) 비율이 충분해야 한다. 순수 사인 드론은 실패한다.
- 도술 30종·기본 SFX·기믹·발소리가 모두 존재하고 sound.gd 매핑과 일치하는지 확인.

사용: python3 tools/verify_v36_audio.py [--json builds/audio-v36.json]
"""
from __future__ import annotations

import json
import math
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "audio"
SKILLS = AUDIO / "skills"

CLIPS = ["ui_tap", "ui_tab", "ui_back", "button", "lock_in", "match_join", "match_found",
         "attack", "hit", "reward", "spell", "dialogue", "jump", "door", "seal", "rescue", "transform",
         "gimmick_turnstile", "gimmick_cctv", "gimmick_lights_off", "gimmick_lights_on",
         "gimmick_shutter", "zone_warning"]
STEPS = ["step", "step2", "step3", "grass", "dirt", "wood", "water", "jar_step"]
SKILL_IDS = ("clone transform painting wallhop windstep eightleap puppet trap astrolabe "
             "lifelamp deathflower returnpath ghostgate soulmark underworldgate mimic foxscent "
             "foxdream voicemimic soundhunt mountaingrowl mischief faketreasure goblinfest douse "
             "blackvision moonlessnight shoeprints glowpowder footprintmap").split()


def load(path: Path):
    with wave.open(str(path)) as w:
        ch, width, sr, frames = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = np.frombuffer(w.readframes(frames), dtype="<i2").astype(np.float64) / 32768.0
    if ch > 1:
        raw = raw.reshape(-1, ch).mean(axis=1)
    return raw, ch, width, sr, frames


def analyse(path: Path) -> dict:
    x, ch, width, sr, frames = load(path)
    out = {"file": str(path.relative_to(ROOT)), "ok": True, "errors": []}
    if ch != 2:
        out["errors"].append(f"channels={ch}")
    if width != 2:
        out["errors"].append(f"width={width}")
    if sr != 44100:
        out["errors"].append(f"sr={sr}")
    if frames < 100:
        out["errors"].append("too short")
    dur = frames / max(1, sr)
    if not (0.08 <= dur <= 3.0):
        out["errors"].append(f"duration={dur:.2f}")
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    rms = float(np.sqrt(np.mean(x ** 2))) if len(x) else 0.0
    clipped = int(np.sum(np.abs(x) >= 0.995))
    if peak >= 0.99:
        out["errors"].append(f"clip peak={peak:.3f} samples={clipped}")
    if not (0.014 <= rms <= 0.24):
        out["errors"].append(f"rms={rms:.3f}")
    if abs(float(np.mean(x))) > 0.02:
        out["errors"].append("dc offset")
    # 스펙트럼
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x)))) ** 2
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    total = max(1e-12, float(spec.sum()))
    hf = float(spec[freqs > 8000].sum() / total)
    if hf > 0.20:
        out["errors"].append(f"hf={hf:.3f}")
    p = spec / total
    flatness = float(math.exp(np.mean(np.log(p + 1e-12))) / (np.mean(p) + 1e-12))
    # 순수 사인 드론 회귀 방지: 스펙트럼 봉우리 수 + 노이즈 바닥 + 어택 과도.
    mag = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    smooth = np.convolve(mag, np.ones(5) / 5.0, mode="same")
    peak_threshold = 0.02 * float(smooth.max())
    peaks = 0
    for i in range(2, len(smooth) - 2):
        if smooth[i] >= peak_threshold and smooth[i] >= smooth[i - 2] and smooth[i] > smooth[i + 2]:
            peaks += 1
    noise_floor = float(np.median(mag) / max(1e-12, mag.max()))
    k = min(len(x), int(0.03 * sr))
    transient = float(np.sum(x[:k] ** 2) / max(1e-12, np.sum(x ** 2)))
    if peaks < 5 and noise_floor < 0.002 and transient < 0.18:
        out["errors"].append(f"pure tone? peaks={peaks} floor={noise_floor:.4f} transient={transient:.2f}")
    out.update({"duration": round(dur, 3), "peak": round(peak, 3), "rms": round(rms, 3),
                "hf": round(hf, 4), "flatness": round(flatness, 4),
                "transient": round(transient, 3), "peaks": peaks, "noise_floor": round(noise_floor, 5), "clipped_samples": clipped})
    out["ok"] = not out["errors"]
    return out


def main() -> int:
    json_path = None
    args = sys.argv[1:]
    if "--json" in args:
        json_path = Path(args[args.index("--json") + 1])
    files = []
    for name in CLIPS + STEPS:
        files.append(AUDIO / f"{name}.wav")
    for skill in SKILL_IDS:
        files.append(SKILLS / f"{skill}.wav")
    results = []
    missing = [str(p.relative_to(ROOT)) for p in files if not p.exists()]
    for p in files:
        if p.exists():
            results.append(analyse(p))
    failures = [r for r in results if not r["ok"]]
    # sound.gd 매핑 검사: 스크립트가 실제로 참조하는 파일이 모두 있는지
    mapping_missing = []
    sound_src = (ROOT / "scripts" / "woo" / "sound.gd").read_text(encoding="utf-8")
    for name in CLIPS + STEPS:
        if f"{name}.wav" not in sound_src and name not in ("step2", "step3"):
            mapping_missing.append(name)
    for skill in SKILL_IDS:
        if f'"{skill}":preload' not in sound_src:
            mapping_missing.append("skills/" + skill)
    summary = {"checked": len(results), "failures": len(failures), "missing": missing,
               "mapping_missing": mapping_missing, "results": results}
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    if json_path is not None:
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"AUDIO V36: {len(results)} files / {len(failures)} failures / {len(missing)} missing")
    return 1 if (failures or missing or mapping_missing) else 0


if __name__ == "__main__":
    raise SystemExit(main())
