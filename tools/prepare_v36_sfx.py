#!/usr/bin/env python3
"""2.0.36 고급 효과음 전면 교체 (외부 샘플·비용 0원, 전부 직접 합성).

사용자 지적(2.0.35 실기기): "효과음이 너무 별로다. 팅팅·으응·우웅 이런 전자음 말고
고급 효과음으로 바꿔 줘."

이 생성기는 단순 사인파/단음 드론을 쓰지 않는다. 모든 소리는 상용 게임 SFX처럼
네 겹을 쌓아 만든다.
  1) 어택 트랜지언트  : 1~8ms의 필터드 노이즈 클릭(재질의 '닿는 순간')
  2) 표면 텍스처      : 대역별 노이즈(천·종이·나뭇결·모래·물·금속 부스러기)
  3) 공명 바디        : 짧게 감쇠하는 다중 모드(비배음 포함) + 피치 드롭 저음 펀치
  4) 공간/잔향        : 초기 반사 + 지수 감쇠 IR 컨볼루션(작은 방/홀), 스테레오 폭
마지막에 트랜지언트 셰이핑·소프트 새추레이션·하이셸프 감쇠로 '싸구려 삐-' 소리를 없앤다.

결과물은 기존 파일 이름을 그대로 덮어쓴다(임포트 파일 재생성 불필요).
  assets/audio/*.wav            UI·문·봉인·구출·기믹·발소리
  assets/audio/skills/*.wav     도술 30종

사용: python3 tools/prepare_v36_sfx.py
검증: python3 tools/verify_v36_audio.py
"""
from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np
from scipy import signal

SR = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
SKILLS = OUT / "skills"
RNG = np.random.default_rng(20261136)
TAU = 2 * math.pi


# ---------------------------------------------------------------- 기본 DSP
def n_of(d: float) -> int:
    return max(8, int(SR * d))


def tt(n: int) -> np.ndarray:
    return np.arange(n) / SR


def noise(n: int) -> np.ndarray:
    return RNG.normal(0.0, 1.0, n)


def pink(n: int) -> np.ndarray:
    """간단한 핑크 노이즈(자연스러운 바람·물·천 질감)."""
    white = noise(n)
    b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
    a = [1, -2.494956002, 2.017265875, -0.522189400]
    return signal.lfilter(b, a, white)


def sos(kind: str, lo: float, hi: float, order: int = 2):
    nyq = SR / 2
    lo = max(20.0, min(lo, nyq * 0.98))
    hi = max(lo + 20.0, min(hi, nyq * 0.99))
    if kind == "band":
        return signal.butter(order, [lo / nyq, hi / nyq], btype="band", output="sos")
    if kind == "low":
        return signal.butter(order, hi / nyq, btype="low", output="sos")
    return signal.butter(order, lo / nyq, btype="high", output="sos")


def bp(x, lo, hi, order=2):
    return signal.sosfilt(sos("band", lo, hi, order), x)


def lp(x, cut, order=2):
    return signal.sosfilt(sos("low", 20, cut, order), x)


def hp(x, cut, order=2):
    return signal.sosfilt(sos("high", cut, SR / 2 * 0.9, order), x)


def fade(x, a=0.002, r=0.04, curve=1.6):
    n = len(x)
    na, nr = min(int(a * SR), n // 2), min(int(r * SR), n // 2)
    if na > 1:
        x[:na] *= np.linspace(0, 1, na) ** (1 / curve)
    if nr > 1:
        x[-nr:] *= np.linspace(1, 0, nr) ** curve
    return x


def decay_env(n, attack=0.002, tau=0.12):
    t = tt(n)
    return np.clip(t / max(attack, 1e-5), 0, 1) * np.exp(-t / max(tau, 1e-5))


def add_at(dst, clip, at=0.0, gain=1.0):
    start = int(at * SR)
    if start < 0 or start >= len(dst):
        return
    end = min(len(dst), start + len(clip))
    dst[start:end] += clip[: end - start] * gain


def pan_stereo(x: np.ndarray, pan: float = 0.0) -> tuple[np.ndarray, np.ndarray]:
    """pan -1..1, 등파워 패닝. 살짝 다른 딜레이로 폭을 준다."""
    a = (pan + 1) * math.pi / 4
    l, r = x * math.cos(a), x * math.sin(a)
    if abs(pan) < 0.5:
        d = int(0.0007 * SR)
        r = np.concatenate([np.zeros(d), r[:-d]]) if d > 0 else r
    return l, r


# ---------------------------------------------------------------- 물리 재질
def click(dur=0.008, lo=1800, hi=9500, tau=0.0018, gain=1.0):
    n = n_of(dur)
    c = bp(noise(n) * decay_env(n, 0.0002, tau), lo, hi, 2)
    return c * gain


def wood_tap(f0=420.0, dur=0.16, tau=0.045, bright=0.22, grain=0.5):
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    # 나무/대나무의 짧은 모드(정수 배 + 아주 약한 비배음 2.71 = 속이 빈 느낌)
    for ratio, amp, tk in ((1.0, 1.0, 1.0), (2.0, 0.34, 0.45), (2.71, 0.10, 0.22), (3.9, 0.05, 0.15)):
        out += amp * np.sin(TAU * f0 * ratio * t + RNG.uniform(0, TAU)) * np.exp(-t / (tau * tk))
    out += bp(pink(n), f0 * 2.2, 5200, 2) * decay_env(n, 0.0005, tau * 0.35) * grain
    add_at(out, click(0.006, f0 * 2.0, 9000, 0.0012, 0.5), 0.0, 0.6)
    out *= 1 + bright * np.sin(TAU * 118.0 * t) * np.exp(-t / 0.03)  # 나뭇결 진동
    return fade(out, 0.0008, 0.04)


def ceramic_knock(f0=760.0, dur=0.22, tau=0.07):
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    for ratio, amp, tk in ((1.0, 1.0, 1.0), (1.62, 0.45, 0.55), (2.83, 0.24, 0.32), (4.41, 0.10, 0.18)):
        out += amp * np.sin(TAU * f0 * ratio * t + RNG.uniform(0, TAU)) * np.exp(-t / (tau * tk))
    out += bp(noise(n), 1200, 9000, 2) * decay_env(n, 0.0003, 0.006) * 0.7
    return fade(out, 0.0005, 0.04)


def metal_hit(f0=520.0, dur=1.1, tau=0.35, bright=0.5, strike=0.8):
    """종·꽹과리 계열. 비배음 모드를 짧게 쓰고 노이즈 타격을 크게 넣어 '팅'이 아닌 '쨍그랑'."""
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    modes = ((1.0, 1.0, 1.0), (2.74, 0.55, 0.55), (5.41, 0.30, 0.33), (8.93, 0.16, 0.20), (13.34, 0.08, 0.12))
    for ratio, amp, tk in modes:
        out += amp * np.sin(TAU * f0 * ratio * t + RNG.uniform(0, TAU)) * np.exp(-t / (tau * tk))
    out += bp(noise(n), 2200, 12000, 2) * decay_env(n, 0.0002, 0.004) * strike
    out += bp(pink(n), 800, 5000, 2) * decay_env(n, 0.0005, 0.03) * 0.25
    out *= 1 + bright * np.exp(-t / 0.02)
    return fade(out, 0.0004, 0.08)


def gong(f0=110.0, dur=2.4, tau=0.9):
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    for ratio, amp, tk in ((1.0, 1.0, 1.0), (1.48, 0.5, 0.8), (2.1, 0.34, 0.65), (2.87, 0.22, 0.5), (4.12, 0.12, 0.35)):
        out += amp * np.sin(TAU * f0 * ratio * t + RNG.uniform(0, TAU)) * np.exp(-t / (tau * tk))
    out += bp(noise(n), 200, 2000, 2) * decay_env(n, 0.0008, 0.05) * 0.4
    return fade(out, 0.002, 0.2)


def thump(f0=120.0, f1=48.0, dur=0.35, tau=0.09, skin=0.25):
    n = n_of(dur)
    t = tt(n)
    f = f1 + (f0 - f1) * np.exp(-t / 0.045)
    phase = np.cumsum(TAU * f / SR)
    out = np.sin(phase) * np.exp(-t / tau)
    out += np.sin(phase * 2) * np.exp(-t / (tau * 0.5)) * 0.22
    out += bp(noise(n), 120, 900, 2) * decay_env(n, 0.0005, 0.02) * skin
    return fade(out, 0.001, 0.05)


def whoosh(dur=0.42, f0=220.0, f1=3400.0, q=0.6, stereo=0.7):
    n = n_of(dur)
    t = tt(n)
    env = np.sin(np.clip(t / dur, 0, 1) * math.pi) ** 0.8
    src = pink(n) * 0.7 + noise(n) * 0.3
    out = np.zeros(n)
    bands = 6
    for i in range(bands):
        lo = f0 * (f1 / f0) ** (i / bands)
        hi = f0 * (f1 / f0) ** ((i + 1) / bands)
        m = bp(src, lo, hi, 2)
        out += m * np.exp(-((t / dur - (i + 0.5) / bands) ** 2) / 0.045)
    out *= env
    return fade(out, 0.01, 0.12)


def cloth(dur=0.3, cut=2600, tau=0.12, flutter=7.0):
    n = n_of(dur)
    t = tt(n)
    out = bp(pink(n), 300, cut, 2) * decay_env(n, 0.002, tau)
    out *= 1 + 0.35 * np.sin(TAU * flutter * t + RNG.uniform(0, TAU))
    return fade(out, 0.001, 0.08)


def paper(dur=0.35):
    n = n_of(dur)
    t = tt(n)
    out = bp(noise(n), 1800, 11000, 2) * decay_env(n, 0.002, 0.09)
    # 종이의 불규칙한 바스락: 빠른 랜덤 게이트
    gate = np.abs(signal.sosfilt(sos("low", 20, 70, 1), noise(n)))
    gate /= max(1e-6, gate.max())
    out *= 0.35 + 0.65 * gate
    return fade(out, 0.001, 0.07)


def creak(dur=0.6, f0=180.0, f1=320.0):
    n = n_of(dur)
    t = tt(n)
    # 마찰 진동(톱니) + 나무 공명 = 문 삐걱
    vib = signal.sawtooth(TAU * (f0 + (f1 - f0) * t / dur) * t + RNG.uniform(0, TAU))
    vib = lp(vib, 1400, 2)
    body = bp(noise(n), 700, 3200, 2) * 0.5
    env = decay_env(n, 0.03, dur * 0.45) * (0.4 + 0.6 * np.abs(np.sin(TAU * 3.1 * t)))
    return fade((vib * 0.55 + body) * env, 0.01, 0.15)


def ratchet(dur=0.35, count=7, lo=1200, hi=5200):
    n = n_of(dur)
    out = np.zeros(n)
    for i in range(count):
        at = dur * i / count
        add_at(out, bp(noise(n_of(0.02)), lo, hi, 2) * decay_env(n_of(0.02), 0.0002, 0.0025), at, 0.8 - 0.06 * i)
    add_at(out, thump(90, 48, 0.2, 0.06, 0.1), 0.0, 0.5)
    return fade(out, 0.0005, 0.03)


def roller(dur=0.7):
    n = n_of(dur)
    t = tt(n)
    body = bp(pink(n), 90, 1400, 2)
    body *= 0.5 + 0.5 * np.sin(TAU * 23.0 * t) ** 2  # 금속 롤러 진동
    body += bp(noise(n), 1800, 7000, 2) * 0.18
    return fade(body * decay_env(n, 0.01, dur * 0.5), 0.005, 0.1)


def servo(dur=0.25, f0=320, f1=520):
    n = n_of(dur)
    t = tt(n)
    f = f0 + (f1 - f0) * (t / dur)
    motor = signal.sawtooth(np.cumsum(TAU * f / SR)) * 0.35
    motor = lp(motor, 2200, 2)
    grit = bp(noise(n), 900, 4800, 2) * 0.3
    return fade((motor + grit) * decay_env(n, 0.01, dur * 0.7), 0.004, 0.06)


def switch(dur=0.18, heavy=True):
    n = n_of(dur)
    out = np.zeros(n)
    add_at(out, click(0.006, 900, 8000, 0.0015, 1.0), 0.0)
    add_at(out, wood_tap(190 if heavy else 320, 0.12, 0.03, 0.2, 0.3), 0.003, 0.9)
    add_at(out, thump(80, 45, 0.16, 0.05, 0.15), 0.002, 0.6)
    if heavy:
        add_at(out, bp(noise(n_of(0.05)), 2500, 9000, 2) * decay_env(n_of(0.05), 0.0003, 0.008), 0.0, 0.4)
    return fade(out, 0.0005, 0.04)


def coin_jingle(dur=0.5, count=9):
    n = n_of(dur)
    out = np.zeros(n)
    for i in range(count):
        at = RNG.uniform(0, dur * 0.55)
        f = RNG.uniform(2300, 5200)
        add_at(out, metal_hit(f, 0.25, 0.08, 0.2, 0.5), at, RNG.uniform(0.12, 0.3))
    return fade(out, 0.002, 0.12)


def growl(dur=1.1, f0=64.0):
    n = n_of(dur)
    t = tt(n)
    mod = 1 + 0.06 * np.sin(TAU * 27.0 * t) + 0.03 * np.sin(TAU * 41.0 * t)
    base = signal.sawtooth(np.cumsum(TAU * f0 * mod / SR))
    formant = bp(base, 180, 900, 3) + bp(base, 900, 2200, 3) * 0.5
    breath = bp(pink(n), 200, 1600, 2) * 0.4
    env = decay_env(n, 0.03, dur * 0.55)
    return fade((formant * 0.7 + breath) * env, 0.02, 0.2)


def voice_blip(dur=0.45, f0=180.0):
    """목소리 흉내: 포먼트 3개를 통과한 톱니+노이즈(사람 목소리처럼 들리게)."""
    n = n_of(dur)
    t = tt(n)
    base = signal.sawtooth(np.cumsum(TAU * f0 * (1 + 0.03 * np.sin(TAU * 5 * t)) / SR))
    out = np.zeros(n)
    for lo, hi, amp in ((300, 800, 0.7), (800, 1800, 0.5), (1800, 3200, 0.25)):
        out += bp(base, lo, hi, 3) * amp
    out += bp(pink(n), 250, 3000, 2) * 0.2
    return fade(out * decay_env(n, 0.02, dur * 0.5), 0.01, 0.12)


# ---------------------------------------------------------------- 공간(잔향)
def make_ir(seconds=0.5, damp=0.55, predelay=0.012):
    n = n_of(seconds)
    t = tt(n)
    ir = noise(n) * np.exp(-t * (6.0 / seconds))
    ir = lp(ir, 9000 * damp, 2)
    early = np.zeros(n)
    for delay, gain in ((0.007, 0.5), (0.013, 0.36), (0.021, 0.26), (0.033, 0.18), (0.049, 0.12)):
        i = int(delay * SR)
        if i < n:
            early[i] += gain
    ir = ir * 0.55 + early
    ir = np.concatenate([np.zeros(int(predelay * SR)), ir])
    return ir / max(1e-9, np.max(np.abs(ir)))


IR_SMALL = make_ir(0.35, 0.6, 0.008)
IR_ROOM = make_ir(0.75, 0.5, 0.012)
IR_HALL = make_ir(1.6, 0.42, 0.02)


def reverb(x, ir=IR_SMALL, amount=0.18):
    wet = signal.fftconvolve(x, ir, mode="full")[: len(x)]
    return x * (1 - amount) + wet * amount


def saturate(x, drive=1.3):
    return np.tanh(x * drive) / np.tanh(drive)


def transient_shape(x, attack_gain=1.35):
    """첫 30ms를 살짝 강조해 '때리는' 느낌을 준다."""
    n = len(x)
    env = np.ones(n)
    k = min(n, int(0.03 * SR))
    env[:k] = np.linspace(attack_gain, 1.0, k)
    return x * env


def master(x, room=0.14, ir=IR_ROOM, high_shelf=-2.0, drive=1.25, peak=0.89):
    x = transient_shape(x)
    x = reverb(x, ir, room)
    x = saturate(x, drive)
    if high_shelf != 0:
        # 6kHz 위를 부드럽게 눌러 '치직' 고주파를 줄인다.
        sos_hs = signal.butter(2, 6000 / (SR / 2), btype="low", output="sos")
        x = signal.sosfilt(sos_hs, x) * 0.35 + x * 0.65
    x = fade(x, 0.0008, 0.03)
    # 피크가 아니라 RMS로 라우드니스를 맞춘다(게임 SFX가 갑자기 터지지 않게).
    rms = max(1e-9, float(np.sqrt(np.mean(x ** 2))))
    x = x * (0.105 / rms)
    p = max(1e-9, float(np.max(np.abs(x))))
    if p > peak:
        x = x / p * peak
    return x


def save(name: str, x: np.ndarray, pan: float = 0.0, room=0.14, ir=IR_ROOM, peak=0.89):
    x = master(np.asarray(x, dtype=np.float64), room, ir, peak=peak)
    l, r = pan_stereo(x, pan)
    if len(l) < len(r):
        l = np.pad(l, (0, len(r) - len(l)))
    if len(r) < len(l):
        r = np.pad(r, (0, len(l) - len(r)))
    data = np.stack([l, r], axis=1)
    data = np.clip(data * 32767.0, -32768, 32767).astype(np.int16)
    path = (SKILLS if name.startswith("skills/") else OUT) / Path(name).name
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())
    print("WROTE", path.relative_to(ROOT), "%.2fs" % (len(l) / SR))


# ---------------------------------------------------------------- UI/기본
def ui_tap():
    out = np.zeros(n_of(0.22))
    add_at(out, click(0.005, 2500, 12000, 0.0012, 0.9), 0.0)
    add_at(out, wood_tap(520, 0.14, 0.035, 0.2, 0.35), 0.002, 0.85)
    add_at(out, ceramic_knock(1180, 0.12, 0.03), 0.004, 0.25)
    return out


def ui_tab():
    out = np.zeros(n_of(0.35))
    add_at(out, wood_tap(392, 0.18, 0.06, 0.15, 0.25), 0.0, 0.9)
    add_at(out, wood_tap(587, 0.18, 0.05, 0.12, 0.2), 0.055, 0.5)
    return out


def ui_back():
    out = np.zeros(n_of(0.3))
    add_at(out, wood_tap(330, 0.16, 0.05, 0.2, 0.3), 0.0, 0.9)
    add_at(out, whoosh(0.18, 900, 300, 0.6), 0.02, 0.25)
    return out


def lock_in():
    out = np.zeros(n_of(1.0))
    add_at(out, thump(130, 42, 0.5, 0.16, 0.3), 0.0, 1.0)
    add_at(out, ceramic_knock(340, 0.25, 0.09), 0.0, 0.8)
    add_at(out, metal_hit(880, 0.7, 0.18, 0.3, 0.4), 0.01, 0.30)
    add_at(out, paper(0.4), 0.05, 0.25)
    return out


def match_join():
    out = np.zeros(n_of(0.6))
    add_at(out, metal_hit(1320, 0.5, 0.16, 0.15, 0.3), 0.0, 0.35)
    add_at(out, metal_hit(1760, 0.5, 0.14, 0.15, 0.3), 0.06, 0.28)
    add_at(out, whoosh(0.3, 2000, 6000, 0.5), 0.0, 0.12)
    return out


def match_found():
    out = np.zeros(n_of(1.6))
    add_at(out, gong(120, 1.6, 0.5), 0.0, 0.55)
    add_at(out, metal_hit(990, 1.0, 0.3, 0.25, 0.3), 0.05, 0.30)
    add_at(out, whoosh(0.7, 300, 3200, 0.5), 0.0, 0.15)
    return out


def button():
    return ui_tap()


def attack():
    out = np.zeros(n_of(0.35))
    add_at(out, whoosh(0.22, 500, 3800, 0.6), 0.0, 0.7)
    add_at(out, thump(110, 55, 0.25, 0.07, 0.2), 0.02, 0.8)
    add_at(out, cloth(0.2, 3200, 0.08), 0.0, 0.25)
    return out


def hit():
    out = np.zeros(n_of(0.45))
    add_at(out, thump(95, 40, 0.35, 0.1, 0.35), 0.0, 1.0)
    add_at(out, bp(noise(n_of(0.06)), 300, 3200, 2) * decay_env(n_of(0.06), 0.0005, 0.015), 0.0, 0.5)
    add_at(out, wood_tap(180, 0.2, 0.05, 0.2, 0.4), 0.005, 0.5)
    return out


def reward():
    out = np.zeros(n_of(0.9))
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5)):
        add_at(out, metal_hit(f, 0.6, 0.16, 0.15, 0.25), 0.07 * i, 0.30)
    add_at(out, whoosh(0.6, 1500, 7000, 0.5), 0.0, 0.10)
    return out


def spell():
    out = np.zeros(n_of(0.8))
    add_at(out, whoosh(0.45, 300, 4200, 0.6), 0.0, 0.55)
    add_at(out, paper(0.4), 0.1, 0.25)
    add_at(out, ceramic_knock(620, 0.3, 0.1), 0.02, 0.3)
    return out


def dialogue():
    out = np.zeros(n_of(0.4))
    add_at(out, voice_blip(0.28, 190), 0.0, 0.65)
    add_at(out, click(0.006, 2000, 8000, 0.0015, 0.3), 0.0, 0.2)
    return out


def jump():
    out = np.zeros(n_of(0.5))
    add_at(out, whoosh(0.28, 700, 2600, 0.6), 0.0, 0.55)
    add_at(out, cloth(0.2, 3000, 0.08), 0.02, 0.25)
    add_at(out, wood_tap(240, 0.12, 0.03, 0.15, 0.2), 0.34, 0.25)
    return out


def door():
    out = np.zeros(n_of(1.1))
    add_at(out, creak(0.7, 160, 260), 0.0, 0.7)
    add_at(out, switch(0.16, False), 0.72, 0.8)
    add_at(out, wood_tap(220, 0.2, 0.05, 0.2, 0.3), 0.74, 0.5)
    return out


def seal():
    out = np.zeros(n_of(1.2))
    add_at(out, paper(0.35), 0.0, 0.7)
    add_at(out, thump(90, 38, 0.5, 0.14, 0.3), 0.01, 1.0)
    add_at(out, metal_hit(420, 1.0, 0.28, 0.2, 0.6), 0.03, 0.25)
    return out


def rescue():
    out = np.zeros(n_of(1.2))
    add_at(out, metal_hit(660, 0.9, 0.25, 0.15, 0.25), 0.0, 0.32)
    add_at(out, metal_hit(990, 0.9, 0.22, 0.12, 0.2), 0.09, 0.22)
    add_at(out, whoosh(0.6, 400, 5000, 0.5), 0.0, 0.18)
    add_at(out, cloth(0.3, 3200, 0.1), 0.0, 0.15)
    return out


def transform():
    out = np.zeros(n_of(0.9))
    add_at(out, cloth(0.3, 3600, 0.12), 0.0, 0.6)
    add_at(out, whoosh(0.4, 1800, 500, 0.6), 0.0, 0.4)
    add_at(out, wood_tap(500, 0.14, 0.04, 0.2, 0.3), 0.3, 0.35)
    add_at(out, coin_jingle(0.4, 5), 0.25, 0.12)
    return out


def steps(kind: str):
    out = np.zeros(n_of(0.3))
    if kind in ("stone", "step", "step2", "step3"):
        add_at(out, click(0.01, 1200, 9000, 0.002, 0.8), 0.0)
        add_at(out, wood_tap(220 + RNG.uniform(-30, 30), 0.12, 0.03, 0.1, 0.5), 0.002, 0.5)
        add_at(out, thump(80, 50, 0.15, 0.04, 0.1), 0.0, 0.3)
    elif kind == "grass":
        add_at(out, bp(pink(n_of(0.12)), 500, 5000, 2) * decay_env(n_of(0.12), 0.004, 0.04), 0.0, 0.7)
        add_at(out, cloth(0.12, 4500, 0.05), 0.0, 0.3)
    elif kind == "dirt":
        add_at(out, bp(noise(n_of(0.08)), 200, 2200, 2) * decay_env(n_of(0.08), 0.001, 0.02), 0.0, 0.7)
    elif kind == "wood":
        add_at(out, wood_tap(300, 0.14, 0.04, 0.2, 0.6), 0.0, 0.9)
        add_at(out, thump(90, 60, 0.12, 0.03, 0.1), 0.0, 0.3)
    elif kind == "water":
        add_at(out, bp(noise(n_of(0.18)), 400, 5000, 2) * decay_env(n_of(0.18), 0.002, 0.05), 0.0, 0.6)
        add_at(out, whoosh(0.18, 600, 2400, 0.6), 0.0, 0.3)
    elif kind == "jar":
        add_at(out, ceramic_knock(640, 0.2, 0.07), 0.0, 0.7)
        add_at(out, thump(70, 45, 0.12, 0.03, 0.1), 0.0, 0.3)
    return out


# ---------------------------------------------------------------- 기믹
def gimmick_turnstile():
    out = np.zeros(n_of(0.8))
    add_at(out, ratchet(0.4, 6, 1500, 6500), 0.0, 0.55)
    add_at(out, metal_hit(380, 0.5, 0.12, 0.2, 0.5), 0.35, 0.35)
    add_at(out, thump(90, 50, 0.2, 0.05, 0.15), 0.36, 0.35)
    return out


def gimmick_cctv():
    out = np.zeros(n_of(0.5))
    add_at(out, servo(0.22, 280, 460), 0.0, 0.55)
    add_at(out, click(0.008, 2000, 9000, 0.002, 0.5), 0.22, 0.4)
    add_at(out, metal_hit(1400, 0.3, 0.08, 0.1, 0.2), 0.24, 0.18)
    return out


def gimmick_lights_off():
    out = np.zeros(n_of(0.6))
    add_at(out, switch(0.2, True), 0.0, 1.0)
    add_at(out, bp(noise(n_of(0.1)), 3000, 12000, 2) * decay_env(n_of(0.1), 0.0005, 0.006), 0.01, 0.35)
    return out


def gimmick_lights_on():
    out = np.zeros(n_of(0.6))
    add_at(out, switch(0.2, True), 0.0, 0.9)
    add_at(out, metal_hit(1700, 0.4, 0.1, 0.2, 0.3), 0.02, 0.2)
    return out


def gimmick_shutter():
    out = np.zeros(n_of(0.9))
    add_at(out, roller(0.7), 0.0, 0.9)
    add_at(out, thump(80, 42, 0.3, 0.08, 0.2), 0.55, 0.6)
    return out


def zone_warning():
    out = np.zeros(n_of(1.3))
    # 두 음 경보(삐-가 아니라 낮은 호른 + 숨결)
    for at, f in ((0.0, 150.0), (0.42, 118.0)):
        n = n_of(0.5)
        t = tt(n)
        horn = signal.sawtooth(np.cumsum(TAU * f * (1 + 0.01 * np.sin(TAU * 5.5 * t)) / SR))
        horn = lp(horn, 800, 2) + bp(horn, 800, 2200, 2) * 0.3
        body = horn * np.sin(np.clip(t / 0.5, 0, 1) * math.pi) ** 0.7 * 0.7
        body += bp(pink(n), 300, 1500, 2) * decay_env(n, 0.05, 0.3) * 0.2
        add_at(out, body, at, 0.65)
    return out


def bgm_placeholder():  # BGM은 이 스크립트에서 건드리지 않는다.
    return None


# ---------------------------------------------------------------- 도술 30종
def sk_paper(f0=500):
    out = np.zeros(n_of(0.9))
    add_at(out, paper(0.5), 0.0, 0.7)
    add_at(out, whoosh(0.4, 700, 3800, 0.6), 0.05, 0.35)
    add_at(out, wood_tap(f0, 0.14, 0.04, 0.2, 0.3), 0.01, 0.35)
    return out


def sk_wind(dur=0.8, f0=400, f1=3600, power=1.0):
    out = np.zeros(n_of(dur))
    add_at(out, whoosh(dur * 0.9, f0, f1, 0.6), 0.0, 0.9 * power)
    add_at(out, cloth(dur * 0.5, 4200, 0.15), 0.0, 0.3 * power)
    add_at(out, thump(100, 55, 0.3, 0.06, 0.1), 0.0, 0.25 * power)
    return out


def sk_machine(f0=300):
    out = np.zeros(n_of(1.1))
    add_at(out, ratchet(0.5, 9, 1200, 5200), 0.0, 0.6)
    add_at(out, servo(0.5, f0, f0 * 1.6), 0.1, 0.4)
    add_at(out, metal_hit(f0, 0.7, 0.2, 0.2, 0.4), 0.3, 0.25)
    return out


def sk_lotus(f0=660):
    out = np.zeros(n_of(1.4))
    add_at(out, metal_hit(f0, 1.1, 0.35, 0.12, 0.2), 0.0, 0.28)
    add_at(out, metal_hit(f0 * 1.5, 1.0, 0.3, 0.1, 0.2), 0.1, 0.2)
    add_at(out, whoosh(0.8, 600, 3600, 0.5), 0.0, 0.15)
    add_at(out, cloth(0.5, 3000, 0.2), 0.0, 0.12)
    return out


def sk_dark(dur=1.0):
    out = np.zeros(n_of(dur))
    add_at(out, whoosh(dur * 0.8, 180, 900, 0.7), 0.0, 0.55)
    add_at(out, bp(pink(n_of(dur)), 60, 500, 2) * decay_env(n_of(dur), 0.05, dur * 0.5), 0.0, 0.5)
    add_at(out, thump(70, 36, 0.5, 0.1, 0.1), 0.0, 0.4)
    return out


def sk_fox(f0=880):
    out = np.zeros(n_of(0.8))
    add_at(out, metal_hit(f0, 0.6, 0.2, 0.2, 0.25), 0.0, 0.20)
    add_at(out, whoosh(0.5, 1200, 6000, 0.5), 0.0, 0.20)
    add_at(out, bp(noise(n_of(0.3)), 3000, 9000, 2) * decay_env(n_of(0.3), 0.003, 0.06), 0.0, 0.18)
    return out


def sk_tiger(f0=70):
    out = np.zeros(n_of(1.4))
    add_at(out, growl(0.9, f0), 0.0, 0.85)
    add_at(out, thump(85, 40, 0.4, 0.12, 0.4), 0.0, 0.6)
    return out


def sk_goblin():
    out = np.zeros(n_of(1.2))
    add_at(out, coin_jingle(0.5, 8), 0.0, 0.35)
    add_at(out, wood_tap(330, 0.16, 0.05, 0.25, 0.4), 0.05, 0.5)
    add_at(out, whoosh(0.4, 600, 4200, 0.5), 0.0, 0.25)
    return out


def sk_gate():
    out = np.zeros(n_of(1.4))
    add_at(out, whoosh(0.9, 120, 1600, 0.7), 0.0, 0.6)
    add_at(out, metal_hit(180, 1.0, 0.35, 0.2, 0.4), 0.2, 0.3)
    add_at(out, bp(pink(n_of(1.0)), 80, 700, 2) * decay_env(n_of(1.0), 0.05, 0.4), 0.0, 0.35)
    return out


def sk_clockwork():
    out = np.zeros(n_of(1.1))
    add_at(out, ratchet(0.45, 10, 900, 4500), 0.0, 0.55)
    add_at(out, metal_hit(620, 0.8, 0.25, 0.25, 0.4), 0.15, 0.25)
    add_at(out, servo(0.3, 200, 420), 0.0, 0.25)
    return out


def sk_steps() -> np.ndarray:
    out = np.zeros(n_of(0.6))
    add_at(out, steps("stone"), 0.0, 0.8)
    add_at(out, whoosh(0.25, 1200, 5200, 0.5), 0.02, 0.25)
    return out


def skill_sound(skill_id: str) -> np.ndarray:
    table = {
        "clone": lambda: sk_paper(620),
        "transform": lambda: transform(),
        "painting": lambda: sk_paper(420),
        "wallhop": lambda: sk_wind(0.7, 500, 4200),
        "windstep": lambda: sk_wind(0.9, 300, 5000, 1.1),
        "eightleap": lambda: sk_wind(1.0, 400, 4800, 0.9),
        "puppet": lambda: sk_clockwork(),
        "trap": lambda: sk_machine(260),
        "astrolabe": lambda: sk_machine(420),
        "lifelamp": lambda: sk_lotus(700),
        "deathflower": lambda: sk_lotus(560),
        "returnpath": lambda: sk_lotus(840),
        "ghostgate": lambda: sk_gate(),
        "soulmark": lambda: sk_paper(720),
        "underworldgate": lambda: sk_gate(),
        "mimic": lambda: sk_fox(760),
        "foxscent": lambda: sk_fox(980),
        "foxdream": lambda: sk_fox(1240),
        "voicemimic": lambda: voice_blip(0.6, 200),
        "soundhunt": lambda: sk_wind(0.6, 900, 3400, 0.6),
        "mountaingrowl": lambda: sk_tiger(66),
        "mischief": lambda: sk_goblin(),
        "faketreasure": lambda: coin_jingle(0.7, 12),
        "goblinfest": lambda: sk_goblin(),
        "douse": lambda: gimmick_lights_off(),
        "blackvision": lambda: sk_dark(1.2),
        "moonlessnight": lambda: sk_dark(1.6),
        "shoeprints": lambda: sk_steps(),
        "glowpowder": lambda: sk_fox(1500),
        "footprintmap": lambda: sk_paper(520),
    }
    fn = table.get(skill_id)
    if fn is None:
        return spell()
    return fn()


def main() -> None:
    # 1) UI·기본
    save("ui_tap.wav", ui_tap(), pan=0.0, room=0.10, ir=IR_SMALL)
    save("ui_tab.wav", ui_tab(), pan=0.05, room=0.12, ir=IR_SMALL)
    save("ui_back.wav", ui_back(), pan=-0.05, room=0.10, ir=IR_SMALL)
    save("button.wav", button(), room=0.10, ir=IR_SMALL)
    save("lock_in.wav", lock_in(), room=0.20, ir=IR_ROOM)
    save("match_join.wav", match_join(), pan=0.1, room=0.25, ir=IR_ROOM)
    save("match_found.wav", match_found(), room=0.30, ir=IR_HALL)
    # 2) 전투·상호작용
    save("attack.wav", attack(), pan=-0.1)
    save("hit.wav", hit(), pan=0.05)
    save("reward.wav", reward(), room=0.25, ir=IR_ROOM)
    save("spell.wav", spell(), room=0.2)
    save("dialogue.wav", dialogue(), room=0.08, ir=IR_SMALL)
    save("jump.wav", jump(), room=0.12)
    save("door.wav", door(), room=0.22, ir=IR_ROOM)
    save("seal.wav", seal(), room=0.22, ir=IR_ROOM)
    save("rescue.wav", rescue(), room=0.28, ir=IR_HALL)
    save("transform.wav", transform(), room=0.18)
    # 3) 기믹
    save("gimmick_turnstile.wav", gimmick_turnstile(), room=0.14)
    save("gimmick_cctv.wav", gimmick_cctv(), pan=0.2, room=0.12)
    save("gimmick_lights_off.wav", gimmick_lights_off(), room=0.10)
    save("gimmick_lights_on.wav", gimmick_lights_on(), room=0.10)
    save("gimmick_shutter.wav", gimmick_shutter(), room=0.16)
    save("zone_warning.wav", zone_warning(), room=0.30, ir=IR_HALL)
    # 4) 발소리(재질별)
    for kind, name in (("stone", "step.wav"), ("stone", "step2.wav"), ("stone", "step3.wav"),
                       ("grass", "grass.wav"), ("dirt", "dirt.wav"), ("wood", "wood.wav"),
                       ("water", "water.wav"), ("jar", "jar_step.wav")):
        save(name, steps(kind), pan=RNG.uniform(-0.15, 0.15), room=0.06, ir=IR_SMALL, peak=0.75)
    # 5) 도술 30종
    for skill_id in ("clone transform painting wallhop windstep eightleap puppet trap astrolabe "
                     "lifelamp deathflower returnpath ghostgate soulmark underworldgate mimic "
                     "foxscent foxdream voicemimic soundhunt mountaingrowl mischief faketreasure "
                     "goblinfest douse blackvision moonlessnight shoeprints glowpowder footprintmap").split():
        x = skill_sound(skill_id)
        if len(x) < n_of(0.25):
            x = np.pad(x, (0, n_of(0.25) - len(x)))
        save(f"skills/{skill_id}.wav", x, pan=RNG.uniform(-0.18, 0.18), room=0.22, ir=IR_ROOM)


if __name__ == "__main__":
    main()
