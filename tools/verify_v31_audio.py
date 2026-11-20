#!/usr/bin/env python3
"""2.0.31 효과음 수치 검증: 클리핑·피크·RMS·스펙트럼·비배음(금속 공명) 검사.

사용자 귀에 '트앙 트앙'으로 들리던 2.0.30 음원은 2.01·2.98·4.16배 같은
비정수 배음(금속 타격음)을 크게 섞고 있었다. 이 검사는 각 WAV의 강한 스펙트럼
봉우리가 기준음의 정수 배에 놓이는지(=배음 악기/재질인지) 수치로 확인한다.

사용: python3 tools/verify_v31_audio.py [--json builds/audio-v31.json]
"""
import json
import sys
import wave
from pathlib import Path

import numpy as np
from scipy.signal import find_peaks

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets" / "audio"
SKILL_DIR = TARGET / "skills"

MAX_PEAK = 0.92
MIN_RMS, MAX_RMS = 0.035, 0.26
MAX_HF = 0.12          # 6kHz 이상 에너지 비율(쇳소리·히스)
MAX_BRIGHT_PEAKS = 40  # 1.5kHz 위 좁은 봉우리 수(2.0.30 '트앙'은 382개였고 새 음원은 최대 24개)
CENTROID_RANGE = (220.0, 4600.0)


def load(path: Path):
    with wave.open(str(path)) as w:
        if w.getnchannels() != 1 or w.getsampwidth() != 2:
            raise ValueError(f"{path.name}: mono 16-bit only")
        sr = w.getframerate()
        frames = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
    return frames, sr


def metallic_ratio(x: np.ndarray, sr: int) -> tuple[float, list[float]]:
    """강한 봉우리 중 기준음의 정수 배에서 6% 이상 벗어난 비율."""
    if len(x) < 256:
        return 0.0, [], []
    win = np.hanning(len(x))
    spec = np.abs(np.fft.rfft(x * win))
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    kernel = np.ones(5) / 5.0
    smooth = np.convolve(spec, kernel, mode="same")
    peaks, _ = find_peaks(smooth, height=0.12 * smooth.max(), distance=4)
    if len(peaks) < 2:
        return 0.0, [], []
    order = np.argsort(smooth[peaks])[::-1][:8]
    chosen = sorted(freqs[peaks[order]])
    all_peaks = [float(v) for v in freqs[peaks]]
    f0 = min(chosen)
    if f0 <= 0:
        return 0.0, []
    bad = 0
    counted = 0
    for fr in chosen:
        ratio = fr / f0
        if ratio < 1.6:
            continue
        counted += 1
        if abs(ratio - round(ratio)) > 0.06:
            bad += 1
    return (bad / counted if counted else 0.0), [round(v, 1) for v in chosen], all_peaks


def late_band(x: np.ndarray, sr: int, start: float = 0.12) -> float:
    """타격 뒤(0.12s~) 남는 1.2~5kHz 에너지 비율 = 금속이 오래 울리는지 보는 지표(진단용)."""
    tail = x[int(start * sr):] if len(x) > int(start * sr) + 512 else x
    spec = np.abs(np.fft.rfft(tail * np.hanning(len(tail))))
    freqs = np.fft.rfftfreq(len(tail), 1.0 / sr)
    return float(spec[(freqs >= 1200.0) & (freqs <= 5000.0)].sum() / max(spec.sum(), 1e-9))


def analyse(path: Path) -> dict:
    x, sr = load(path)
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    rms = float(np.sqrt(np.mean(x ** 2))) if len(x) else 0.0
    dc = float(np.mean(x)) if len(x) else 0.0
    clipped = int(np.sum(np.abs(x) >= 0.999))
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    total = float(spec.sum()) or 1e-9
    centroid = float((spec * freqs).sum() / total)
    hf = float(spec[freqs >= 6000.0].sum() / total)
    metal, peaks, all_peaks = metallic_ratio(x, sr)
    bright = int(sum(1 for fr in all_peaks if fr > 1500.0))
    tail_mid = late_band(x, sr)
    problems = []
    if sr not in (22050, 44100):
        problems.append(f"sample rate {sr}")
    if not (0.05 <= len(x) / sr <= 3.2):
        problems.append(f"length {len(x)/sr:.2f}s")
    if peak > MAX_PEAK:
        problems.append(f"peak {peak:.2f}")
    if clipped:
        problems.append(f"{clipped} clipped samples")
    if abs(dc) > 0.02:
        problems.append(f"dc {dc:.3f}")
    if not (MIN_RMS <= rms <= MAX_RMS):
        problems.append(f"rms {rms:.3f}")
    if hf > MAX_HF:
        problems.append(f"hf {hf*100:.1f}%")
    if bright > MAX_BRIGHT_PEAKS:
        problems.append(f"{bright} bright narrow peaks")
    if not (CENTROID_RANGE[0] <= centroid <= CENTROID_RANGE[1]):
        problems.append(f"centroid {centroid:.0f}Hz")
    return {"name": path.stem, "sr": sr, "seconds": round(len(x) / sr, 3), "peak": round(peak, 3),
            "rms": round(rms, 3), "centroid": round(centroid), "hf": round(hf, 4),
            "inharmonic": round(metal, 3), "bright_peaks": bright, "tail_mid": round(tail_mid, 3),
            "peaks": peaks, "problems": problems}


def main() -> None:
    paths = [TARGET / n for n in ("button.wav", "dialogue.wav", "spell.wav", "seal.wav", "rescue.wav",
                                  "jump.wav", "transform.wav", "hit.wav", "attack.wav")]
    paths += sorted(SKILL_DIR.glob("*.wav"))
    rows = []
    failed = []
    for path in paths:
        if not path.exists():
            failed.append((path.stem, ["missing"]))
            continue
        row = analyse(path)
        rows.append(row)
        if row["problems"]:
            failed.append((row["name"], row["problems"]))
        print(f"{row['name']:14s} {row['seconds']:.2f}s peak={row['peak']:.2f} rms={row['rms']:.3f} "
              f"centroid={row['centroid']:5d}Hz hf={row['hf']*100:4.1f}% bright={row['bright_peaks']:3d} "
              f"tail={row['tail_mid']:.2f} "
              f"{'OK' if not row['problems'] else 'FAIL ' + ','.join(row['problems'])}")
    total_bytes = sum(p.stat().st_size for p in paths if p.exists())
    print(f"AUDIO VERIFY: {len(rows)} clips / {total_bytes/1024:.0f}KB / {len(failed)} failing")
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps({"clips": rows, "failing": failed, "total_bytes": total_bytes}, indent=2) + "\n")
    if failed:
        for name, problems in failed:
            print(f"  FAIL {name}: {', '.join(problems)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
