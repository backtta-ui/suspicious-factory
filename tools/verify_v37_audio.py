#!/usr/bin/env python3
"""2.0.37 CC0 실제 녹음 오디오 무결성 검사.

2.0.36의 합성음 검사(verify_v36_audio.py)를 대체한다. 이제 음원은 실제 녹음이라
"순수 사인 드론" 회귀 검사는 사라지고, 다음을 확인한다.

- 형식: 44.1kHz 스테레오 16-bit WAV, 0바이트 아님
- 길이: 발소리 0.10~0.75초, 도술 0.25~3.0초, 기본 SFX 0.08~3.0초
- 레벨: 클리핑 없음(피크 < 0.99), RMS 0.014~0.26, DC 오프셋 작음
- 고주파: 8kHz 위 에너지 비율 < 0.22 (치직거리는 히스)
- 무음/단일톤 아님: 스펙트럼 평탄도나 과도(transient)가 충분해야 한다
- BGM: Ogg Vorbis 헤더와 크기, 5곡 모두 존재
- 매핑: sound.gd의 preload 경로가 전부 실재하고, 30도술·8재질 발소리가 빠짐없이 걸려 있다

사용: python3 tools/verify_v37_audio.py [--json builds/audio-v37.json]
"""
from __future__ import annotations

import json
import math
import re
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "audio"
SOUND = ROOT / "scripts" / "woo" / "sound.gd"

SKILL_IDS = ("clone transform painting wallhop windstep eightleap puppet trap astrolabe "
             "lifelamp deathflower returnpath ghostgate soulmark underworldgate mimic foxscent "
             "foxdream voicemimic soundhunt mountaingrowl mischief faketreasure goblinfest douse "
             "blackvision moonlessnight shoeprints glowpowder footprintmap").split()
MATERIALS = ["grass_dirt", "stone", "wood", "tile_indoor", "asphalt", "sand", "water", "escalator", "jar"]
CLIPS = ["ui_tap", "ui_tab", "ui_back", "button", "lock_in", "match_join", "match_found",
         "attack", "hit", "reward", "spell", "dialogue", "jump", "door", "seal", "rescue", "transform",
         "gimmick_turnstile", "gimmick_cctv", "gimmick_lights_off", "gimmick_lights_on",
         "gimmick_shutter", "zone_warning"]
BGM = ["lobby_fantasy", "seowon_battle", "gangnam_trance", "haeundae_beach", "dongseongno_urban"]


def load(path: Path):
    with wave.open(str(path)) as w:
        ch, width, sr, frames = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = np.frombuffer(w.readframes(frames), dtype="<i2").astype(np.float64) / 32768.0
    if ch > 1:
        raw = raw.reshape(-1, ch).mean(axis=1)
    return raw, ch, width, sr, frames


def analyse(path: Path, low: float, high: float) -> dict:
    out = {"file": str(path.relative_to(ROOT)), "ok": True, "errors": []}
    x, ch, width, sr, frames = load(path)
    if ch != 2:
        out["errors"].append(f"channels={ch}")
    if width != 2:
        out["errors"].append(f"width={width}")
    if sr != 44100:
        out["errors"].append(f"sr={sr}")
    if frames < 100:
        out["errors"].append("too short")
        out["ok"] = False
        return out
    dur = frames / sr
    if not (low <= dur <= high):
        out["errors"].append(f"duration={dur:.2f}s (want {low}-{high})")
    peak = float(np.max(np.abs(x)))
    rms = float(np.sqrt(np.mean(x ** 2)))
    if peak >= 0.99:
        out["errors"].append(f"clip peak={peak:.3f}")
    if not (0.014 <= rms <= 0.26):
        out["errors"].append(f"rms={rms:.3f}")
    if abs(float(np.mean(x))) > 0.02:
        out["errors"].append("dc offset")
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x)))) ** 2
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    total = max(1e-12, float(spec.sum()))
    hf = float(spec[freqs > 8000].sum() / total)
    if hf > 0.22:
        out["errors"].append(f"hf={hf:.3f}")
    p = spec / total
    flatness = float(math.exp(np.mean(np.log(p + 1e-12))) / (np.mean(p) + 1e-12))
    smooth = np.convolve(np.abs(x), np.ones(64) / 64, mode="valid")
    peak_threshold = 0.35 * float(smooth.max()) if len(smooth) else 1.0
    attacks = 0
    for i in range(2, max(0, len(smooth) - 2)):
        if smooth[i] >= peak_threshold and smooth[i] >= smooth[i - 2] and smooth[i] > smooth[i + 2]:
            attacks += 1
    if flatness < 0.012 and attacks < 2:
        out["errors"].append(f"pure-tone regression flatness={flatness:.3f} attacks={attacks}")
    if len(out["errors"]):
        out["ok"] = False
    out.update({"seconds": round(dur, 3), "peak": round(peak, 3), "rms": round(rms, 4), "hf": round(hf, 3)})
    return out


def sound_mapping_errors() -> list[str]:
    errors: list[str] = []
    src = SOUND.read_text()
    for rel in sorted(set(re.findall(r'preload\("res://([^"]+)"\)', src))):
        if not (ROOT / rel).exists():
            errors.append(f"sound.gd preload missing file: {rel}")
    for skill in SKILL_IDS:
        if f"skills/{skill}.wav" not in src:
            errors.append(f"skill mapping missing: {skill}")
    for material in MATERIALS:
        if f'"{material}"' not in src:
            errors.append(f"footstep material missing: {material}")
    for track in BGM:
        if f"bgm/{track}.ogg" not in src:
            errors.append(f"bgm mapping missing: {track}")
    return errors


def main() -> int:
    targets: list[tuple[Path, float, float]] = []
    for skill in SKILL_IDS:
        targets.append((AUDIO / "skills" / f"{skill}.wav", 0.25, 3.0))
    for name in CLIPS:
        targets.append((AUDIO / f"{name}.wav", 0.08, 3.0))
    for path in sorted((AUDIO / "steps").glob("*.wav")):
        targets.append((path, 0.10, 0.75))

    results = []
    missing = [str(p.relative_to(ROOT)) for p, _, _ in targets if not p.exists()]
    for path, low, high in targets:
        if path.exists():
            results.append(analyse(path, low, high))
    failed = [r for r in results if not r["ok"]]

    bgm_rows = []
    for track in BGM:
        path = AUDIO / "bgm" / f"{track}.ogg"
        row = {"file": str(path.relative_to(ROOT)), "ok": False, "errors": []}
        if not path.exists():
            row["errors"].append("missing")
        else:
            data = path.read_bytes()
            if not data.startswith(b"OggS"):
                row["errors"].append("not an ogg container")
            if b"vorbis" not in data[:512]:
                row["errors"].append("not vorbis")
            if len(data) < 200_000:
                row["errors"].append(f"too small {len(data)}")
            row.update({"bytes": len(data)})
            row["ok"] = not row["errors"]
        bgm_rows.append(row)

    mapping = sound_mapping_errors()
    total_errors = len(missing) + len(failed) + sum(len(r["errors"]) for r in bgm_rows) + len(mapping)
    summary = {
        "clips": len(results),
        "failed_clips": len(failed),
        "missing": missing,
        "failures": failed,
        "bgm": bgm_rows,
        "mapping": mapping,
        "ok": total_errors == 0,
    }
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(summary, ensure_ascii=False, indent=1))
    print(f"AUDIO V37: {len(results)} clips, {len(failed)} failed, {len(missing)} missing, "
          f"{sum(1 for r in bgm_rows if r['ok'])}/5 bgm, {len(mapping)} mapping errors")
    for row in failed[:12]:
        print(" FAIL", row["file"], "; ".join(row["errors"]))
    for row in bgm_rows:
        if not row["ok"]:
            print(" FAIL", row["file"], "; ".join(row["errors"]))
    for item in mapping[:12]:
        print(" MAP", item)
    return 0 if total_errors == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
