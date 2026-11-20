#!/usr/bin/env python3
"""2.0.35 맵 BGM 생성기(저작권 없음, 전부 numpy 합성).

- bgm_haeundae.wav   부산 해운대: 밝고 시원한 밤바다 · 경쾌한 파도 리듬에
                     술래잡기 텐션만 살린 해변 BGM(어둡고 무거운 공포풍 아님).
- bgm_dongseongno.wav 대구 동성로: 도심 번화가·아케이드 느낌의 리드미컬한 네온 신스.

    python3 tools/prepare_v35_audio.py
"""
from __future__ import annotations

import math
import os
import wave

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SR = 44100


def sine(freq: float, n: int, phase: float = 0.0) -> np.ndarray:
    return np.sin(2 * math.pi * freq * np.arange(n) / SR + phase)


def pluck(freq: float, n: int, decay: float = 0.35, harmonics=((1, 1.0), (2, 0.32), (3, 0.14), (4, 0.06))) -> np.ndarray:
    t = np.arange(n) / SR
    out = np.zeros(n)
    for harmonic, amp in harmonics:
        out += np.sin(2 * math.pi * freq * harmonic * t) * amp * np.exp(-t * (decay * (1.0 + 0.35 * harmonic)))
    attack = np.clip(t / 0.004, 0, 1)
    return out * attack


def mallet(freq: float, n: int) -> np.ndarray:
    t = np.arange(n) / SR
    body = np.sin(2 * math.pi * freq * t) * np.exp(-t / 0.28)
    overtone = np.sin(2 * math.pi * freq * 3.02 * t) * np.exp(-t / 0.10) * 0.35
    click = np.exp(-t / 0.006) * 0.10
    return (body + overtone + click) * np.clip(t / 0.003, 0, 1)


def noise(n: int, rng: np.random.Generator) -> np.ndarray:
    return rng.standard_normal(n)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    a = math.exp(-2 * math.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = a * acc + (1 - a) * v
        y[i] = acc
    return y


def bandpass(x: np.ndarray, low: float, high: float) -> np.ndarray:
    return lowpass(x, high) - lowpass(x, low)


def write(name: str, left: np.ndarray, right: np.ndarray | None = None, gain: float = 0.9) -> None:
    left = np.asarray(left, dtype=np.float64)
    right = left if right is None else np.asarray(right, dtype=np.float64)
    peak = max(1e-9, float(np.max(np.abs(np.concatenate([left, right])))))
    left = left / peak * gain
    right = right / peak * gain
    data = np.stack([left, right], axis=1)
    pcm = np.clip(data * 32767.0, -32768, 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("WROTE", path, "%.1fs" % (len(left) / SR), "%.1fMB" % (os.path.getsize(path) / 1e6))


def bgm_haeundae() -> None:
    """밝은 밤바다: D–A–Bm–G 말림, 마림바 아르페지오 + 부드러운 파도 + 가벼운 비트."""
    rng = np.random.default_rng(35)
    bpm = 104.0
    beat = 60.0 / bpm
    bars = 16
    bar_len = beat * 4
    total = int(SR * bar_len * bars)
    out = np.zeros(total)
    # 코드 진행 D - A - Bm - G (밝은 장조 중심)
    chords = [
        {"root": 146.83, "notes": [293.66, 369.99, 440.00]},   # D
        {"root": 110.00, "notes": [277.18, 329.63, 440.00]},   # A
        {"root": 123.47, "notes": [246.94, 293.66, 369.99]},   # Bm
        {"root": 98.00, "notes": [246.94, 293.66, 392.00]},    # G
    ]
    for bar in range(bars):
        chord = chords[bar % len(chords)]
        start = int(SR * bar_len * bar)
        seg = min(int(SR * bar_len), total - start)
        if seg <= 0:
            break
        tt = np.arange(seg) / SR
        # 따뜻한 패드(밝은 밤 공기)
        for freq in chord["notes"]:
            out[start:start + seg] += np.sin(2 * math.pi * freq * tt + 0.15 * np.sin(2 * math.pi * 0.18 * tt)) * 0.055
            out[start:start + seg] += np.sin(2 * math.pi * freq * 2 * tt) * 0.018
        # 베이스: 1·3박 루트 + 4박 옥타브 움직임
        for pos, mul in ((0.0, 1.0), (2.0, 0.5), (3.5, 0.75)):
            at = start + int(SR * beat * pos)
            n = min(int(SR * beat * 0.9), total - at)
            if n > 0:
                out[at:at + n] += pluck(chord["root"] * mul, n, 0.9, ((1, 0.6), (2, 0.2))) * 0.30
        # 마림바 아르페지오(8분음표, 밝은 상행·하행 혼합)
        pattern = [0, 1, 2, 1, 2, 0, 1, 2]
        for step in range(8):
            at = start + int(SR * beat * 0.5 * step)
            n = min(int(SR * beat * 0.7), total - at)
            if n <= 0:
                continue
            note = chord["notes"][pattern[step]] * (2 if step in (3, 6) else 1)
            out[at:at + n] += mallet(note, n) * (0.16 if step % 2 else 0.22)
    # 파도: 4마디마다 밀려오는 소리(밝은 물빛)
    for k in range(4):
        at = int(SR * bar_len * 4 * k)
        seg = min(int(SR * bar_len * 3.2), total - at)
        if seg <= 0:
            continue
        tt = np.arange(seg) / SR
        swell = np.sin(np.clip(tt / (seg / SR), 0, 1) * math.pi) ** 1.6
        wash = bandpass(noise(seg, rng), 300, 4200) * swell * 0.075
        wash += np.sin(2 * math.pi * 0.16 * tt) * swell * 0.02
        out[at:at + seg] += wash
    # 가벼운 비트: 셰이커 8분 + 부드러운 킥 1·3박 + 손뼉 2·4박
    step = beat / 2
    for i in range(int(total / (SR * step)) + 1):
        at = int(SR * step * i)
        if at >= total:
            break
        n = min(int(SR * 0.20), total - at)
        tt = np.arange(n) / SR
        shaker = bandpass(noise(n, rng), 5200, 13000) * np.exp(-tt / 0.020) * (0.055 if i % 2 else 0.085)
        out[at:at + n] += shaker
        if i % 8 == 0:
            kick = np.sin(2 * math.pi * (110 * np.exp(-tt * 20) + 48) * tt) * np.exp(-tt / 0.10) * 0.34
            out[at:at + n] += kick
        if i % 8 == 4:
            clap = bandpass(noise(n, rng), 900, 4200) * np.exp(-tt / 0.045) * 0.14
            out[at:at + n] += clap
    # 술래잡기 텐션: 아주 옅은 8분 고음 펄스(밝은 채로 긴장만)
    for i in range(int(total / (SR * step))):
        if i % 4 != 2:
            continue
        at = int(SR * step * i)
        n = min(int(SR * 0.14), total - at)
        tt = np.arange(n) / SR
        out[at:at + n] += np.sin(2 * math.pi * 1318.5 * tt) * np.exp(-tt / 0.05) * 0.045
    # 루프 이음새
    fade = int(SR * 1.4)
    idx = np.arange(total)
    shape = np.clip(idx / fade, 0, 1) * np.clip((total - idx) / fade, 0, 1)
    mix = out * (0.55 + 0.45 * shape)
    left = mix
    right = np.roll(mix, int(SR * 0.008)) * 0.97
    write("bgm_haeundae.wav", left, right, gain=0.84)


def bgm_dongseongno() -> None:
    """네온 번화가: A단조 4도 진행, 아르페지오 신스 리드 + 펌핑 베이스 + 전자 비트."""
    rng = np.random.default_rng(37)
    bpm = 110.0
    beat = 60.0 / bpm
    bars = 16
    bar_len = beat * 4
    total = int(SR * bar_len * bars)
    out = np.zeros(total)
    # Am - F - C - G (도심 네온)
    chords = [
        {"root": 55.00, "notes": [220.00, 261.63, 329.63]},
        {"root": 43.65, "notes": [174.61, 220.00, 261.63]},
        {"root": 65.41, "notes": [261.63, 329.63, 392.00]},
        {"root": 49.00, "notes": [196.00, 246.94, 293.66]},
    ]
    for bar in range(bars):
        chord = chords[bar % len(chords)]
        start = int(SR * bar_len * bar)
        seg = min(int(SR * bar_len), total - start)
        if seg <= 0:
            break
        tt = np.arange(seg) / SR
        # 신스 패드(살짝 디튠)
        for freq in chord["notes"]:
            out[start:start + seg] += np.sin(2 * math.pi * freq * tt) * 0.045
            out[start:start + seg] += np.sin(2 * math.pi * freq * 1.005 * tt + 0.7) * 0.030
        # 펌핑 베이스(8분)
        for step in range(8):
            at = start + int(SR * beat * 0.5 * step)
            n = min(int(SR * beat * 0.46), total - at)
            if n <= 0:
                continue
            t2 = np.arange(n) / SR
            base = np.sin(2 * math.pi * chord["root"] * t2) * np.exp(-t2 / 0.16)
            base += np.sin(2 * math.pi * chord["root"] * 2 * t2) * np.exp(-t2 / 0.10) * 0.35
            out[at:at + n] += base * (0.30 if step % 2 == 0 else 0.20)
        # 아르페지오 리드(16분, 네온 반짝임)
        pattern = [0, 2, 1, 2, 0, 1, 2, 1, 0, 2, 1, 2, 2, 1, 0, 1]
        for step in range(16):
            at = start + int(SR * beat * 0.25 * step)
            n = min(int(SR * beat * 0.42), total - at)
            if n <= 0:
                continue
            note = chord["notes"][pattern[step]] * (2 if step % 8 in (3, 7) else 1)
            out[at:at + n] += pluck(note, n, 1.5, ((1, 0.5), (2, 0.28), (3, 0.16), (4, 0.08))) * 0.13
        # 4마디마다 상승하는 네온 스윕
        if bar % 4 == 3:
            at = start + int(SR * beat * 2.0)
            n = min(int(SR * beat * 2.0), total - at)
            if n > 0:
                t3 = np.arange(n) / SR
                sweep = np.sin(2 * math.pi * (300 + 900 * t3 / (n / SR)) * t3) * np.exp(-t3 / 0.5) * 0.05
                out[at:at + n] += sweep
    # 전자 비트: 4/4 킥 + 2·4박 스네어 + 8분 하이햇 + 16분 셰이커
    step = beat / 4
    for i in range(int(total / (SR * step)) + 1):
        at = int(SR * step * i)
        if at >= total:
            break
        n = min(int(SR * 0.18), total - at)
        tt = np.arange(n) / SR
        if i % 2 == 0:
            hat = bandpass(noise(n, rng), 7000, 15000) * np.exp(-tt / 0.011) * (0.075 if i % 4 == 0 else 0.045)
            out[at:at + n] += hat
        if i % 16 % 4 == 0:
            kick = np.sin(2 * math.pi * (130 * np.exp(-tt * 24) + 44) * tt) * np.exp(-tt / 0.12) * 0.58
            out[at:at + n] += kick
        if i % 16 in (4, 12):
            snare = bandpass(noise(n, rng), 240, 5600) * np.exp(-tt / 0.075) * 0.24
            out[at:at + n] += snare
        if i % 4 == 2:
            shaker = bandpass(noise(n, rng), 6000, 14000) * np.exp(-tt / 0.018) * 0.035
            out[at:at + n] += shaker
    # 도심 잔향: 낮은 럼블 + 먼 차량 소리
    rumble = lowpass(noise(total, rng), 110) * 0.16
    for k in range(3):
        at = int(total * (0.12 + 0.32 * k))
        seg = min(int(SR * 1.8), total - at)
        if seg <= 0:
            continue
        tt = np.arange(seg) / SR
        env_t = np.sin(np.clip(tt / (seg / SR), 0, 1) * math.pi) ** 2
        out[at:at + seg] += bandpass(noise(seg, rng), 180, 1400) * env_t * 0.06
    fade = int(SR * 1.2)
    idx = np.arange(total)
    shape = np.clip(idx / fade, 0, 1) * np.clip((total - idx) / fade, 0, 1)
    mix = (out + rumble) * (0.45 + 0.55 * shape)
    left = mix
    right = np.roll(mix, int(SR * 0.005)) * 0.96
    write("bgm_dongseongno.wav", left, right, gain=0.86)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    bgm_haeundae()
    bgm_dongseongno()


if __name__ == "__main__":
    main()
