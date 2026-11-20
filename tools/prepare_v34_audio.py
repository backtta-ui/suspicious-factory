#!/usr/bin/env python3
"""2.0.34 UI·기믹·BGM 사운드 생성기(저작권 없음, 전부 numpy 합성).

상용 게임처럼 '밋밋한 단일 사인파'가 아니라 재질(목재·옥구슬·금속·북·징·신스)을
여러 겹으로 합성하고, 어택/감쇠·노이즈 성분·약한 스테레오를 넣는다.

    python3 tools/prepare_v34_audio.py
"""
from __future__ import annotations

import math
import os
import wave

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SR = 44100


def env(n: int, attack: float, decay: float, power: float = 2.0) -> np.ndarray:
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-np.clip(t - attack, 0, None) / max(decay, 1e-4))
    return (a * d) ** power


def sine(freq: float, n: int, phase: float = 0.0) -> np.ndarray:
    return np.sin(2 * math.pi * freq * np.arange(n) / SR + phase)


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
    print("wrote", os.path.relpath(path, os.path.dirname(__file__)))


def wood_tap(freq: float = 420.0, length: float = 0.16) -> tuple[np.ndarray, np.ndarray]:
    """목재 몸통 + 옥구슬 배음: 부드럽고 선명한 UI 탭."""
    rng = np.random.default_rng(7)
    n = int(SR * length)
    body = np.zeros(n)
    for mult, amp, dec in ((1.0, 0.9, 0.05), (2.02, 0.45, 0.035), (3.11, 0.22, 0.025), (4.8, 0.12, 0.018)):
        body += sine(freq * mult, n) * amp * env(n, 0.002, dec, 1.6)
    click = bandpass(noise(n, rng), 1200, 9000) * env(n, 0.0005, 0.008, 2.2) * 0.35
    jade = sine(freq * 5.4, n) * env(n, 0.001, 0.09, 2.6) * 0.18
    sig = body + click + jade
    return sig, np.concatenate([np.zeros(int(SR * 0.004)), sig])[:n] * 0.96


def ui_sounds() -> None:
    rng = np.random.default_rng(11)
    # 1) UI 탭: 목재 탭 + 옥구슬
    left, right = wood_tap(430.0)
    write("ui_tap.wav", left, right)
    # 2) 탭 전환: 조금 높고 짧은 두 음(목재 + 유리)
    a, b = wood_tap(560.0, 0.13)
    n = int(SR * 0.20)
    sig = np.zeros(n)
    sig[: len(a)] += a
    delay = int(SR * 0.035)
    sig[delay : delay + len(b)] += b * 0.55
    write("ui_tab.wav", sig, np.roll(sig, 6))
    # 3) 뒤로가기: 낮게 내려가는 목재 + 부드러운 공기
    n = int(SR * 0.26)
    sweep = 520 * np.exp(-np.arange(n) / SR * 6.0) + 190
    body = np.sin(2 * math.pi * np.cumsum(sweep) / SR) * env(n, 0.004, 0.075, 1.7)
    air = lowpass(noise(n, rng), 2600) * env(n, 0.01, 0.09, 2.0) * 0.25
    write("ui_back.wav", body + air)


def match_join() -> None:
    """인원 합류: 영롱한 차임(음정은 재생 시 피치로 올린다)."""
    n = int(SR * 0.6)
    sig = np.zeros(n)
    for mult, amp, dec in ((1.0, 1.0, 0.16), (2.0, 0.5, 0.12), (3.0, 0.3, 0.09), (4.02, 0.18, 0.07)):
        sig += sine(880 * mult, n) * amp * env(n, 0.003, dec, 1.5)
    shimmer = bandpass(np.random.default_rng(3).standard_normal(n), 4000, 12000) * env(n, 0.02, 0.10, 2.0) * 0.12
    write("match_join.wav", sig + shimmer, np.roll(sig + shimmer, 12))


def match_found() -> None:
    """8/8 매칭 성사: 웅장한 북 + 징 화음 + 상승 차임."""
    rng = np.random.default_rng(5)
    n = int(SR * 1.9)
    t = np.arange(n) / SR
    # 큰 북(낮은 사인 + 노이즈 타격)
    drum_freq = 58 * np.exp(-t * 3.0) + 42
    drum = np.sin(2 * math.pi * np.cumsum(drum_freq) / SR) * np.exp(-t / 0.28) ** 1.4
    thump = lowpass(noise(n, rng), 220) * np.exp(-t / 0.05) * 0.8
    # 징 화음(배음이 많은 금속)
    gong = np.zeros(n)
    for f, a, d in ((196, 0.5, 0.9), (294, 0.36, 0.75), (392, 0.28, 0.6), (512, 0.2, 0.45), (765, 0.12, 0.3)):
        gong += np.sin(2 * math.pi * f * t + 0.4 * np.sin(2 * math.pi * 3.1 * t)) * a * np.exp(-t / d)
    # 상승 차임
    chime = np.zeros(n)
    for i, f in enumerate((523, 659, 784, 1046)):
        start = int(SR * (0.18 + i * 0.09))
        seg = int(SR * 0.6)
        if start + seg > n:
            seg = n - start
        chime[start : start + seg] += sine(f, seg) * env(seg, 0.004, 0.14, 1.6) * 0.5
    sig = drum * 0.9 + thump + gong * 0.55 + chime * 0.5
    write("match_found.wav", sig, np.roll(sig, 40) * 0.98)


def lock_in() -> None:
    """캐릭터 확정: 묵직한 금빛 공명 + 도장 임팩트."""
    rng = np.random.default_rng(13)
    n = int(SR * 1.4)
    t = np.arange(n) / SR
    # 금빛 공명(금속 배음, 서서히 열림)
    metal = np.zeros(n)
    for f, a, d in ((110, 0.6, 0.7), (165, 0.42, 0.55), (247, 0.32, 0.42), (330, 0.22, 0.32), (494, 0.14, 0.22)):
        metal += np.sin(2 * math.pi * f * t + 0.6 * np.sin(2 * math.pi * 2.4 * t)) * a * np.exp(-t / d)
    # 도장(낮은 쿵 + 짧은 마찰)
    stamp = np.sin(2 * math.pi * (72 * np.exp(-t * 6) + 46) * t) * np.exp(-t / 0.12) ** 1.3 * 0.9
    stamp += lowpass(noise(n, rng), 400) * np.exp(-t / 0.03) * 0.7
    riser = np.sin(2 * math.pi * (300 * np.exp(t * 2.2)) * t) * np.clip(t / 0.25, 0, 1) * np.exp(-t / 0.35) * 0.25
    sig = metal * 0.7 + stamp + riser
    write("lock_in.wav", sig, np.roll(sig, 20) * 0.97)


def gimmick_sounds() -> None:
    rng = np.random.default_rng(21)
    # 개찰구: 쇠 걸쇠 '철커덕' (금속 클릭 2연타 + 낮은 몸통)
    n = int(SR * 0.42)
    sig = np.zeros(n)
    for start, amp, cut in ((0.0, 1.0, 5200), (0.11, 0.75, 4200)):
        s = int(SR * start)
        seg = min(n - s, int(SR * 0.12))
        click = bandpass(noise(seg, rng), 900, cut) * env(seg, 0.0006, 0.012, 2.4) * amp
        sig[s : s + seg] += click
        sig[s : s + seg] += sine(210, seg) * env(seg, 0.001, 0.03, 2.0) * amp * 0.5
    write("gimmick_turnstile.wav", sig, np.roll(sig, 9))

    # CCTV 전환: 전자 틱 + 스캔 노이즈
    n = int(SR * 0.5)
    t = np.arange(n) / SR
    tick = sine(1400, n) * env(n, 0.001, 0.02, 2.2) * 0.5 + sine(2100, n) * env(n, 0.001, 0.012, 2.2) * 0.3
    scan = bandpass(noise(n, rng), 2500, 9000) * (0.12 + 0.10 * np.sin(2 * math.pi * 30 * t))
    hum = sine(120, n) * 0.12 * np.exp(-t / 0.25)
    write("gimmick_cctv.wav", tick + scan + hum)

    # 조명 끔: 전원이 내려가는 하강음 + 유리 필라멘트
    n = int(SR * 0.55)
    t = np.arange(n) / SR
    sweep = 340 * np.exp(-t * 5.5) + 48
    off = np.sin(2 * math.pi * np.cumsum(sweep) / SR) * env(n, 0.005, 0.16, 1.7)
    spark = bandpass(noise(n, rng), 3000, 11000) * env(n, 0.01, 0.03, 2.4) * 0.2
    write("gimmick_lights_off.wav", off + spark)
    # 조명 켬: 딸깍 + 밝게 올라가는 금속
    n = int(SR * 0.4)
    t = np.arange(n) / SR
    click = bandpass(noise(n, rng), 1500, 9000) * env(n, 0.0006, 0.012, 2.4) * 0.6
    rise = np.zeros(n)
    for f, a, d in ((523, 0.4, 0.10), (784, 0.32, 0.09), (1046, 0.24, 0.08), (1568, 0.14, 0.06)):
        rise += sine(f, n) * a * np.exp(-t / d)
    write("gimmick_lights_on.wav", click + rise)

    # 셔터: 드르륵(모터 + 금속 슬랫)
    n = int(SR * 1.05)
    t = np.arange(n) / SR
    motor = np.sin(2 * math.pi * (110 + 8 * np.sin(2 * math.pi * 7 * t)) * t) * 0.45
    rattle = bandpass(noise(n, rng), 800, 5200) * (0.5 + 0.5 * np.sin(2 * math.pi * 22 * t)) * 0.45
    shut = (motor + rattle) * np.clip(t / 0.06, 0, 1) * np.exp(-np.clip(t - 0.7, 0, None) / 0.12)
    write("gimmick_shutter.wav", shut, np.roll(shut, 14) * 0.95)

    # 안전구역 경고 펄스: 낮은 심장박동 2연타
    n = int(SR * 0.75)
    t = np.arange(n) / SR
    pulse = np.zeros(n)
    for start in (0.0, 0.26):
        s = int(SR * start)
        seg = min(n - s, int(SR * 0.22))
        tt = np.arange(seg) / SR
        pulse[s : s + seg] += np.sin(2 * math.pi * (96 * np.exp(-tt * 8) + 54) * tt) * np.exp(-tt / 0.09) ** 1.2
    warn = bandpass(noise(n, rng), 200, 1200) * env(n, 0.02, 0.12, 2.0) * 0.12
    write("zone_warning.wav", pulse + warn)


def bgm_gangnam() -> None:
    """서울 강남역: 심야 지하철 네온 신스 베이스 + 전자 비트(루프 8마디)."""
    rng = np.random.default_rng(31)
    bpm = 96.0
    beat = 60.0 / bpm
    bars = 16
    total = int(SR * beat * 4 * bars)
    t = np.arange(total) / SR
    out = np.zeros(total)
    # 신스 베이스(단조 진행: A1 - F1 - C2 - G1)
    roots = [55.0, 43.65, 65.41, 49.0]
    for bar in range(bars):
        root = roots[bar % len(roots)]
        start = int(SR * beat * 4 * bar)
        seg = int(SR * beat * 4)
        if start >= total:
            break
        seg = min(seg, total - start)
        tt = np.arange(seg) / SR
        for harmonic, amp in ((1, 0.55), (2, 0.22), (3, 0.12), (0.5, 0.25)):
            out[start : start + seg] += np.sin(2 * math.pi * root * harmonic * tt) * amp * (0.55 + 0.45 * np.sin(2 * math.pi * 0.26 * tt)) * 0.34
        # 패드(네온 코드)
        for f, amp in ((root * 3, 0.10), (root * 4.5, 0.07), (root * 6, 0.045)):
            out[start : start + seg] += np.sin(2 * math.pi * f * tt + 0.3 * np.sin(2 * math.pi * 0.2 * tt)) * amp * 0.7
    # 전자 비트: 킥 4/4 + 하이햇 8분 + 스네어 2·4박
    step = beat / 2
    for i in range(int(total / (SR * step)) + 1):
        at = int(SR * step * i)
        if at >= total:
            break
        seg = min(int(SR * 0.22), total - at)
        tt = np.arange(seg) / SR
        if i % 2 == 0:  # 하이햇
            hat = bandpass(noise(seg, rng), 7000, 15000) * np.exp(-tt / 0.012) * 0.10
            out[at : at + seg] += hat
        if i % 4 == 0:  # 킥
            kick = np.sin(2 * math.pi * (120 * np.exp(-tt * 22) + 46) * tt) * np.exp(-tt / 0.11) * 0.55
            out[at : at + seg] += kick
        if i % 8 == 4:  # 스네어
            snare = bandpass(noise(seg, rng), 220, 5200) * np.exp(-tt / 0.07) * 0.26
            out[at : at + seg] += snare
    # 지하철 잔향: 낮은 럼블 + 먼 열차 소리
    rumble = lowpass(noise(total, rng), 90) * 0.22
    train = np.zeros(total)
    for k in range(3):
        at = int(total * (0.16 + 0.31 * k))
        seg = min(int(SR * 2.2), total - at)
        if seg <= 0:
            continue
        tt = np.arange(seg) / SR
        env_t = np.sin(np.clip(tt / (seg / SR), 0, 1) * math.pi) ** 2
        train[at : at + seg] += bandpass(noise(seg, rng), 120, 900) * env_t * 0.10
    # 전체 페이드 인/아웃(루프 이음새)
    fade = int(SR * 1.2)
    shape = np.clip(np.arange(total) / fade, 0, 1) * np.clip((total - np.arange(total)) / fade, 0, 1)
    mix = (out * 0.8 + rumble + train) * (0.35 + 0.65 * shape)
    left = mix
    right = np.roll(mix, int(SR * 0.006)) * 0.97
    write("bgm_gangnam.wav", left, right, gain=0.82)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    ui_sounds()
    match_join()
    match_found()
    lock_in()
    gimmick_sounds()
    bgm_gangnam()


if __name__ == "__main__":
    main()
