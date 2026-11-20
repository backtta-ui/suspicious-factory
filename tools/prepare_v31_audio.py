#!/usr/bin/env python3
"""2.0.31 사운드 개편: 듣기 좋은 기본 SFX + 도사·도술별 맞춤 효과음 30종을 순수 합성한다.

사용자 지적(2.0.30 실기기): "스킬별로 도사별로 전부 효과음이 같고, 듣기 싫은 소리임.
게임 소리가 아니라 무슨 트앙 트앙 이러는디 … 스킬과 알맞는 효과음으로 바꿔"

원인과 해결
- 2.0.30의 `bell()`은 2.01·2.98·4.16·5.43·6.79배처럼 **비정수(비배음) 배음**을 겹쳐
  금속 타격음('트앙')을 만들었다. 이 파일은 비배음 성분을 완전히 없애고,
  정수 배음 + 목재/대나무/가죽/현(Plackett) 재질의 합성만 쓴다.
- 모든 도술이 `play_clip("spell")` 하나를 쓰던 것을 도술 id별 30종으로 나눈다.
  결과물: `assets/audio/*.wav`(기본 SFX) 와 `assets/audio/skills/<skill_id>.wav`(도술 30종).
- 외부 샘플·유료 API 없이 numpy/scipy만 사용한다(무저작권, 저장소에 결과 WAV 보관).

사용: python3 tools/prepare_v31_audio.py
검증: python3 tools/verify_v31_audio.py   (클리핑·고주파·비배음 공명 수치 검사)
"""
from pathlib import Path
import hashlib, json, wave
import numpy as np
from scipy import signal

SR = 22050
ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets" / "audio"
SKILL_DIR = TARGET / "skills"
rng = np.random.default_rng(20261131)
TAU = 2 * np.pi

# 계면조(도·레·미·솔·라)를 옮긴 다섯 음. 전통 악기 느낌의 맑은 음색을 만든다.
D3, F3, G3, A3, C4 = 146.83, 174.61, 196.00, 220.00, 261.63
D4, F4, G4, A4, C5 = 293.66, 349.23, 392.00, 440.00, 523.25
D5, F5, G5, A5, C6 = 587.33, 698.46, 783.99, 880.00, 1046.50


# ---------------------------------------------------------------- 기본 도구
def n_of(dur: float) -> int:
    return max(1, int(SR * dur))


def tt(n: int) -> np.ndarray:
    return np.arange(n) / SR


def noise(n: int) -> np.ndarray:
    return rng.normal(0.0, 1.0, n)


def bp(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    nyq = SR / 2
    lo = max(lo / nyq, 1e-4)
    hi = min(hi / nyq, 0.999)
    if hi <= lo:
        return x
    b, a = signal.butter(order, [lo, hi], btype="band")
    return signal.lfilter(b, a, x)


def lp(x: np.ndarray, cut: float, order: int = 2) -> np.ndarray:
    b, a = signal.butter(order, min(cut / (SR / 2), 0.999), btype="low")
    return signal.lfilter(b, a, x)


def hp(x: np.ndarray, cut: float, order: int = 2) -> np.ndarray:
    b, a = signal.butter(order, max(cut / (SR / 2), 1e-4), btype="high")
    return signal.lfilter(b, a, x)


def add_at(dst: np.ndarray, clip: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(SR * at)
    if start >= len(dst) or start < 0:
        return
    end = min(len(dst), start + len(clip))
    if end <= start:
        return
    dst[start:end] += clip[: end - start] * gain


def fade(x: np.ndarray, attack: float = 0.004, release: float = 0.03, curve: float = 1.5) -> np.ndarray:
    n = len(x)
    a = min(int(SR * attack), n // 2)
    r = min(int(SR * release), n // 2)
    if a > 1:
        x[:a] *= np.linspace(0.0, 1.0, a) ** (1.0 / curve)
    if r > 1:
        x[-r:] *= np.linspace(1.0, 0.0, r) ** curve
    return x


def env(n: int, attack: float = 0.004, tau: float = 0.2) -> np.ndarray:
    t = tt(n)
    return np.clip(t / max(attack, 1e-4), 0.0, 1.0) * np.exp(-t / max(tau, 1e-4))


# ---------------------------------------------------------------- 재질별 음원
def wood(f: float = 620.0, dur: float = 0.10, tau: float = 0.014, grain: float = 0.45) -> np.ndarray:
    """나무/대나무를 '톡' 치는 소리: 단단한 기본음 + 짧은 배음 + 살짝의 나뭇결 소음."""
    n = n_of(dur)
    t = tt(n)
    out = np.sin(TAU * f * t) * np.exp(-t / tau)
    out += 0.30 * np.sin(TAU * 2.0 * f * t) * np.exp(-t / (tau * 0.55))
    out += 0.10 * np.sin(TAU * 3.0 * f * t) * np.exp(-t / (tau * 0.35))
    if grain > 0:
        out += bp(noise(n), f * 1.4, min(f * 5.0, 7600.0)) * np.exp(-t / (tau * 0.45)) * grain
    return fade(out, 0.001, 0.02)


def marimba(f: float = 330.0, dur: float = 0.42, tau: float = 0.13) -> np.ndarray:
    """마림바/편종 계열: 실제 목재 타악기의 정수 배음 비(1:4:10)만 쓴다(금속성 없음)."""
    n = n_of(dur)
    t = tt(n)
    out = np.sin(TAU * f * t) * np.exp(-t / tau)
    out += 0.22 * np.sin(TAU * 4.0 * f * t) * np.exp(-t / (tau * 0.35))
    out += 0.05 * np.sin(TAU * 10.0 * f * t) * np.exp(-t / (tau * 0.12))
    out += bp(noise(n), 400.0, 2600.0) * np.exp(-t / 0.005) * 0.22
    return fade(out, 0.002, 0.05)


def tube(f: float = 440.0, dur: float = 0.55, tau: float = 0.16, air: float = 0.05) -> np.ndarray:
    """속이 빈 대나무·옥 풍경: 홀수 배음(1·3·5)만 써서 맑고 둥근 울림."""
    n = n_of(dur)
    t = tt(n)
    out = np.sin(TAU * f * t) * np.exp(-t / tau)
    out += 0.20 * np.sin(TAU * 3.0 * f * t) * np.exp(-t / (tau * 0.5))
    out += 0.06 * np.sin(TAU * 5.0 * f * t) * np.exp(-t / (tau * 0.3))
    if air > 0:
        out += lp(noise(n), 3200.0) * np.exp(-t / 0.02) * air
    return fade(out, 0.003, 0.06)


def chime(f: float = 880.0, dur: float = 0.9, tau: float = 0.28) -> np.ndarray:
    """방울/오르골: 정수 배음만, 위쪽 배음은 아주 약하게. 맑고 부드러운 반짝임."""
    n = n_of(dur)
    t = tt(n)
    out = np.sin(TAU * f * t) * np.exp(-t / tau)
    out += 0.26 * np.sin(TAU * 2.0 * f * t) * np.exp(-t / (tau * 0.45))
    out += 0.07 * np.sin(TAU * 3.0 * f * t) * np.exp(-t / (tau * 0.25))
    return fade(out, 0.004, min(0.12, dur * 0.3))


def pluck(f: float, dur: float = 0.7, damp: float = 0.9955, bright: float = 0.5) -> np.ndarray:
    """가야금/거문고 계열 현 소리(Karplus-Strong). 배음이 자연스럽게 감쇠한다."""
    n = n_of(dur)
    period = max(3, int(SR / max(f, 30.0)))
    buf = lp(noise(period * 3), 2600.0)[:period]
    buf = buf - buf.mean()
    out = np.zeros(n)
    idx = 0
    for i in range(n):
        v = buf[idx]
        out[i] = v
        nxt = buf[(idx + 1) % period]
        buf[idx] = damp * (bright * v + (1.0 - bright) * nxt)
        idx = (idx + 1) % period
    out = lp(out, 3000.0)
    return fade(out, 0.002, min(0.12, dur * 0.35))


def gliss(pitches, span: float = 0.09, each: float = 0.8, gain: float = 1.0, bright: float = 0.5) -> np.ndarray:
    """여러 음을 빠르게 훑는 가야금 글리산도."""
    total = span * (len(pitches) - 1) + each if pitches else 0.2
    out = np.zeros(n_of(total))
    for i, f in enumerate(pitches):
        add_at(out, pluck(f, each, bright=bright), i * span, gain * (1.0 - 0.05 * i))
    return out


def thump(f0: float = 92.0, f1: float = 56.0, dur: float = 0.28, tau: float = 0.07, skin: float = 0.22) -> np.ndarray:
    """저음 펀치: 음정이 살짝 떨어지는 사인 + 배음 + 짧은 가죽 소음. 봉인·충격의 몸통."""
    n = n_of(dur)
    t = tt(n)
    freq = f1 + (f0 - f1) * np.exp(-t / 0.028)
    phase = TAU * np.cumsum(freq) / SR
    out = np.sin(phase) * np.exp(-t / tau)
    out += 0.16 * np.sin(2 * phase) * np.exp(-t / (tau * 0.7))
    if skin > 0:
        out += lp(noise(n), 1100.0) * np.exp(-t / 0.009) * skin
    return fade(out, 0.0015, 0.03)


def drum(f0: float = 96.0, f1: float = 58.0, dur: float = 0.55, tau: float = 0.14) -> np.ndarray:
    """전통 북(장구 북편): 가죽을 두드린 둔탁함 + 몸통 울림."""
    n = n_of(dur)
    t = tt(n)
    freq = f1 + (f0 - f1) * np.exp(-t / 0.05)
    phase = TAU * np.cumsum(freq) / SR
    out = np.sin(phase) * np.exp(-t / tau)
    out += 0.10 * np.sin(2 * phase) * np.exp(-t / (tau * 0.5))
    skin = bp(noise(n), 180.0, 1900.0) * np.exp(-t / 0.035)
    out += skin * 0.5
    return fade(out, 0.002, 0.06)


def swish(dur: float = 0.3, f0: float = 2600.0, f1: float = 700.0, width: float = 1.5,
          tau: float = 0.10, attack: float = 0.006) -> np.ndarray:
    """바람/옷자락: 좁은 대역 소음이 f0→f1로 훑고 지나간다(고주파를 잘라 쏘지 않게 한다)."""
    n = n_of(dur)
    src = noise(n)
    out = np.zeros(n)
    pieces = 10
    for i in range(pieces):
        lo_i, hi_i = int(n * i / pieces), int(n * (i + 1) / pieces)
        if hi_i <= lo_i:
            continue
        cut = f0 * (f1 / f0) ** (i / max(pieces - 1, 1))
        seg = bp(src, max(cut / width, 90.0), min(cut * width, 7200.0))
        w = np.ones(hi_i - lo_i)
        edge = max(1, (hi_i - lo_i) // 4)
        w[:edge] = np.linspace(0.0, 1.0, edge)
        w[-edge:] = np.linspace(1.0, 0.0, edge)
        out[lo_i:hi_i] += seg[lo_i:hi_i] * w
    out = lp(out, 7600.0)
    t = tt(n)
    out *= np.clip(t / max(attack, 1e-4), 0.0, 1.0) * np.exp(-t / max(tau, 1e-4))
    return fade(out, 0.002, 0.03)


def breath(dur: float = 0.4, cut: float = 1400.0, tau: float = 0.12) -> np.ndarray:
    """부드러운 숨결(훅·연기). 고역을 잘라 귀에 거슬리지 않게 한다."""
    n = n_of(dur)
    t = tt(n)
    out = lp(noise(n), cut) * np.clip(t / 0.03, 0.0, 1.0) * np.exp(-t / tau)
    return fade(out, 0.005, 0.05)


def grains(dur: float, count: int, lo: float, hi: float, gain: float = 0.18,
           length: float = 0.012) -> np.ndarray:
    """사슬·불티·가루가 흩날리는 짧은 알갱이들(고역을 잘라 금속 쇳소리를 막는다)."""
    n = n_of(dur)
    out = np.zeros(n)
    for _ in range(count):
        at = rng.uniform(0.0, max(dur - length, 0.001))
        g = noise(n_of(length))
        clip = lp(bp(g, lo, hi), 6400.0) * env(len(g), 0.001, length * 0.45)
        add_at(out, clip, at, gain * rng.uniform(0.45, 1.0))
    return out


def reverb(x: np.ndarray, taps=((0.023, 0.20), (0.041, 0.13), (0.067, 0.09), (0.101, 0.06), (0.149, 0.04)),
           damp: float = 4200.0, wet: float = 0.5) -> np.ndarray:
    """한옥 마당 정도의 짧은 잔향. 젖은 신호는 저역만 남겨 '쨍'한 금속 잔향을 만들지 않는다."""
    out = x.copy()
    dry = x
    for delay, gain in taps:
        d = int(SR * delay)
        if d <= 0 or d >= len(x):
            continue
        pad = np.zeros_like(x)
        pad[d:] = dry[:-d] * gain
        out += pad
    tail = lp(out - dry, damp) * wet
    return dry + tail


# ---------------------------------------------------------------- 출력
def master(x: np.ndarray, rms_target: float = 0.11, peak_ceiling: float = 0.72,
           cut: float = 8000.0, warmth: float = 1.0) -> np.ndarray:
    """DC 제거 → 부드러운 고역 정리 → 살짝의 포화(따뜻함) → RMS 정규화 + 피크 상한."""
    x = np.nan_to_num(np.asarray(x, dtype=np.float64))
    if len(x) == 0:
        return x
    x = x - x.mean()
    x = lp(x, cut)
    peak = float(np.max(np.abs(x))) or 1.0
    x = np.tanh(x / peak * warmth) / np.tanh(warmth)  # 부드러운 포화(클리핑 없음)
    cur_rms = float(np.sqrt(np.mean(x ** 2))) or 1e-9
    x = x * (rms_target / cur_rms)
    peak = float(np.max(np.abs(x)))
    if peak > peak_ceiling:
        x = x * (peak_ceiling / peak)
    return fade(x, 0.003, 0.05, 1.2)


def save(path: Path, data: np.ndarray, rms: float = 0.11, peak: float = 0.72, cut: float = 8000.0) -> None:
    data = master(data, rms_target=rms, peak_ceiling=peak, cut=cut)
    pcm = np.clip(np.round(data * 32767.0), -32767, 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setparams((1, 2, SR, 0, "NONE", ""))
        w.writeframes(pcm.tobytes())


# ---------------------------------------------------------------- 기본 SFX
def make_ui() -> None:
    """버튼: 나무 도장을 '톡' 누르는 소리. 삐- 하는 사인파도, 쇳소리도 없다."""
    n = n_of(0.11)
    t = tt(n)
    click = bp(noise(n), 700.0, 2900.0) * np.exp(-t / 0.010) * 0.55
    body = wood(860.0, 0.11, 0.012, grain=0.2) * 0.7
    out = click + body
    save(TARGET / "button.wav", out, rms=0.075, peak=0.5, cut=6500.0)
    # 대화: 낮고 부드러운 목소리 결(가까이에서 나직이 말하는 느낌).
    n2 = n_of(0.30)
    t2 = tt(n2)
    d = lp(noise(n2), 1300.0) * env(n2, 0.02, 0.10) * 0.5
    d += np.sin(TAU * 188.0 * t2) * env(n2, 0.03, 0.12) * 0.35
    d += 0.12 * np.sin(TAU * 376.0 * t2) * env(n2, 0.03, 0.08)
    save(TARGET / "dialogue.wav", d, rms=0.075, peak=0.45, cut=3200.0)


def make_spell() -> None:
    """도술 공용(등록되지 않은 스킬의 대체음): 부적이 찰싹 + 바람 + 따뜻한 울림."""
    dur = 0.8
    n = n_of(dur)
    out = np.zeros(n)
    add_at(out, swish(0.34, 3000.0, 800.0, 1.6, 0.09) * 0.55, 0.0)
    add_at(out, wood(720.0, 0.12, 0.02, 0.3) * 0.30, 0.004)
    add_at(out, chime(D4, 0.75, 0.22) * 0.30, 0.02)
    add_at(out, chime(A4, 0.7, 0.18) * 0.18, 0.09)
    add_at(out, thump(150.0, 105.0, 0.35, 0.09, 0.05) * 0.28, 0.0)
    save(TARGET / "spell.wav", reverb(out, wet=0.35), rms=0.10, peak=0.66)


def make_seal() -> None:
    """봉인: 먹물 도장을 '쿵' 찍는 소리 + 종이 스치는 소리 + 낮게 번지는 울림."""
    dur = 1.4
    out = np.zeros(n_of(dur))
    add_at(out, thump(88.0, 52.0, 0.65, 0.20, 0.30) * 0.85, 0.0)
    add_at(out, swish(0.22, 1800.0, 500.0, 1.6, 0.06) * 0.35, 0.0)
    add_at(out, wood(420.0, 0.14, 0.03, 0.35) * 0.35, 0.0)
    # 낮게 번지는 울림: 110Hz 정수 배음만 사용(금속 종소리 금지).
    n = n_of(dur)
    t = tt(n)
    deep = np.sin(TAU * 110.0 * t) * np.exp(-t / 0.55) * 0.30
    deep += 0.16 * np.sin(TAU * 220.0 * t) * np.exp(-t / 0.30)
    deep += 0.06 * np.sin(TAU * 330.0 * t) * np.exp(-t / 0.20)
    deep *= np.clip(t / 0.03, 0.0, 1.0)
    out += deep
    save(TARGET / "seal.wav", reverb(out, wet=0.4), rms=0.12, peak=0.7)


def make_rescue() -> None:
    """구출: 따뜻한 화음이 아래에서 위로 올라온다(생명등불이 켜지는 느낌)."""
    dur = 1.25
    out = np.zeros(n_of(dur))
    for i, f in enumerate([D4, A4, D5]):
        add_at(out, tube(f, 1.1, 0.30, air=0.03) * (0.42 - i * 0.07), 0.05 * i)
    add_at(out, swish(0.55, 500.0, 2400.0, 1.4, 0.18) * 0.20, 0.0)
    add_at(out, chime(D5, 1.0, 0.35) * 0.14, 0.22)
    save(TARGET / "rescue.wav", reverb(out, wet=0.45), rms=0.10, peak=0.66)


def make_jump() -> None:
    """점프: 옷자락이 가볍게 펄럭이며 떠오르는 소리(고역 17%였던 쇳소리 제거)."""
    dur = 0.32
    n = n_of(dur)
    out = np.zeros(n)
    add_at(out, swish(0.26, 700.0, 2600.0, 1.5, 0.08) * 0.55, 0.0)
    t = tt(n)
    rise = np.sin(TAU * np.cumsum(320.0 + 260.0 * (t / dur)) / SR) * env(n, 0.02, 0.09)
    out += rise * 0.20
    add_at(out, thump(120.0, 90.0, 0.12, 0.04, 0.08) * 0.22, 0.06)
    save(TARGET / "jump.wav", out, rms=0.085, peak=0.55)


def make_transform() -> None:
    """둔갑: 연기가 '펑' 퍼지고 낮은 몸통 + 작은 방울 하나."""
    dur = 0.65
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.5, 950.0, 300.0, 1.7, 0.16) * 0.7, 0.0)
    add_at(out, breath(0.45, 900.0, 0.14) * 0.45, 0.0)
    add_at(out, thump(140.0, 96.0, 0.35, 0.09, 0.10) * 0.30, 0.0)
    add_at(out, chime(F4, 0.6, 0.20) * 0.16, 0.05)
    save(TARGET / "transform.wav", reverb(out, wet=0.3), rms=0.098, peak=0.62)


def make_combat() -> None:
    """공격/피격: 바람을 가르는 소리와 둔탁한 나무·가죽 타격(쇳소리 없음)."""
    dur = 0.24
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.2, 2300.0, 650.0, 1.7, 0.07) * 0.5, 0.0)
    add_at(out, thump(135.0, 92.0, 0.2, 0.05, 0.18) * 0.55, 0.02)
    save(TARGET / "attack.wav", out, rms=0.10, peak=0.62)

    n = n_of(0.28)
    t = tt(n)
    th = thump(96.0, 62.0, 0.28, 0.075, 0.32) * 0.85
    th += lp(bp(noise(n), 240.0, 1800.0), 3000.0) * np.exp(-t / 0.03) * 0.30
    save(TARGET / "hit.wav", th, rms=0.12, peak=0.68)


# ---------------------------------------------------------------- 도술 30종
def sk_talisman() -> np.ndarray:
    """전우치 · 부적날리기: 종이 찰싹 + 바람 + 맑은 울림."""
    dur = 0.62
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.30, 3400.0, 900.0, 1.7, 0.08) * 0.55, 0.0)
    add_at(out, wood(980.0, 0.09, 0.012, 0.55) * 0.35, 0.01)
    add_at(out, wood(1240.0, 0.08, 0.010, 0.5) * 0.22, 0.06)
    add_at(out, chime(A4, 0.55, 0.16) * 0.24, 0.04)
    return reverb(out, wet=0.28)


def sk_clone() -> np.ndarray:
    """전우치 · 분신술: 먹 연기가 휙 흩어지고 두 겹의 발소리 같은 톡."""
    dur = 0.72
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.45, 1200.0, 380.0, 1.8, 0.13) * 0.6, 0.0)
    add_at(out, breath(0.5, 1100.0, 0.15) * 0.4, 0.02)
    add_at(out, wood(560.0, 0.12, 0.02, 0.4) * 0.28, 0.03)
    add_at(out, wood(520.0, 0.12, 0.02, 0.4) * 0.20, 0.13)
    add_at(out, chime(D4, 0.5, 0.14) * 0.12, 0.1)
    return reverb(out, wet=0.3)


def sk_painting() -> np.ndarray:
    """전우치 · 화중은신: 족자가 스르륵 펼쳐지고 먹물이 번지는 깊은 울림."""
    dur = 1.05
    out = np.zeros(n_of(dur))
    # 족자 펼침: 천천히 올라가는 종이 스침
    add_at(out, swish(0.62, 420.0, 1500.0, 1.5, 0.32) * 0.42, 0.0)
    add_at(out, grains(0.5, 7, 900.0, 2600.0, 0.035, 0.02), 0.02)
    n = n_of(dur)
    t = tt(n)
    deep = np.sin(TAU * 98.0 * t) * np.exp(-t / 0.45) * 0.32
    deep += 0.12 * np.sin(TAU * 196.0 * t) * np.exp(-t / 0.28)
    deep *= np.clip(t / 0.08, 0.0, 1.0)
    out += deep
    add_at(out, chime(D4, 0.7, 0.24) * 0.18, 0.12)
    return reverb(out, wet=0.45)


def sk_transform() -> np.ndarray:
    """전우치 · 둔갑술: 몸이 사물로 접히듯 짧게 '푹' — 연기 + 낮은 몸통 + 작은 방울."""
    dur = 0.72
    out = np.zeros(n_of(dur))
    add_at(out, breath(0.42, 800.0, 0.12) * 0.55, 0.0)
    add_at(out, swish(0.4, 1400.0, 420.0, 1.8, 0.12) * 0.45, 0.0)
    add_at(out, thump(160.0, 104.0, 0.3, 0.07, 0.12) * 0.34, 0.02)
    add_at(out, wood(520.0, 0.1, 0.02, 0.35) * 0.22, 0.18)
    add_at(out, chime(F4, 0.5, 0.16) * 0.14, 0.2)
    return reverb(out, wet=0.3)


def sk_wallhop() -> np.ndarray:
    """홍길동 · 담장넘기: 옷자락이 바람을 가르고 가볍게 내려앉는 소리."""
    dur = 0.55
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.26, 600.0, 2800.0, 1.4, 0.07) * 0.6, 0.0)
    add_at(out, swish(0.22, 2600.0, 800.0, 1.4, 0.06) * 0.3, 0.16)
    add_at(out, thump(130.0, 92.0, 0.18, 0.045, 0.10) * 0.35, 0.30)
    add_at(out, wood(300.0, 0.1, 0.02, 0.3) * 0.12, 0.30)
    return out


def sk_windstep() -> np.ndarray:
    """홍길동 · 바람발: 가볍고 시원한 바람이 발밑에서 솟는다(부드러운 휘파람 한 음)."""
    dur = 0.5
    n = n_of(dur)
    out = np.zeros(n)
    add_at(out, swish(0.36, 900.0, 3400.0, 1.6, 0.09) * 0.55, 0.0)
    t = tt(n)
    pitch = 720.0 + 260.0 * np.clip(t / 0.3, 0.0, 1.0)
    whistle = np.sin(TAU * np.cumsum(pitch) / SR) * env(n, 0.05, 0.14) * 0.16
    out += whistle
    add_at(out, chime(C5, 0.4, 0.12) * 0.12, 0.04)
    return out


def sk_eightleap() -> np.ndarray:
    """홍길동 · 팔방도약: 세 번의 짧은 바람 도약이 위로 사라진다."""
    dur = 0.75
    out = np.zeros(n_of(dur))
    for i, (at, f0) in enumerate([(0.0, 2600.0), (0.11, 3000.0), (0.22, 3500.0)]):
        add_at(out, swish(0.2, f0, 900.0, 1.5, 0.06) * (0.5 - i * 0.08), at)
        add_at(out, chime(C5 * (1.0 + 0.12 * i), 0.35, 0.12) * 0.10, at + 0.01)
    return reverb(out, wet=0.25)


def sk_puppet() -> np.ndarray:
    """장영실 · 기관인형: 나무 톱니가 딸깍 딸깍, 작은 태엽이 감긴다."""
    dur = 0.75
    out = np.zeros(n_of(dur))
    for i, at in enumerate([0.0, 0.09, 0.17, 0.33]):
        add_at(out, wood(760.0 + i * 90.0, 0.09, 0.012, 0.5) * (0.55 - i * 0.07), at)
    n = n_of(dur)
    t = tt(n)
    whirr = np.sin(TAU * 210.0 * t) * 0.06 * (0.5 + 0.5 * np.sin(TAU * 11.0 * t))
    whirr *= np.clip((0.36 - t) / 0.36, 0.0, 1.0)
    out += whirr
    add_at(out, chime(G4, 0.5, 0.16) * 0.14, 0.18)
    return reverb(out, wet=0.22)


def sk_trap() -> np.ndarray:
    """장영실 · 압력기관: 판이 '철컥' 눌리고 낮게 풀리는 소리."""
    dur = 0.7
    out = np.zeros(n_of(dur))
    add_at(out, wood(520.0, 0.1, 0.016, 0.6) * 0.45, 0.0)
    add_at(out, thump(150.0, 110.0, 0.2, 0.05, 0.14) * 0.35, 0.02)
    add_at(out, wood(690.0, 0.1, 0.014, 0.5) * 0.30, 0.12)
    n = n_of(dur)
    t = np.arange(n) / SR
    release = np.sin(TAU * np.cumsum(190.0 * np.exp(-t / 0.25) + 120.0) / SR) * np.exp(-t / 0.18) * 0.16
    out += release
    return reverb(out, wet=0.2)


def sk_astrolabe() -> np.ndarray:
    """장영실 · 천문기계: 황동 톱니 3번 + 별빛 차임(정수 배음만, 쇳소리 금지)."""
    dur = 1.0
    out = np.zeros(n_of(dur))
    for i, at in enumerate([0.0, 0.075, 0.15]):
        add_at(out, wood(880.0 + i * 110.0, 0.08, 0.010, 0.55) * (0.42 - i * 0.05), at)
    for i, f in enumerate([D5, A5, C6]):
        add_at(out, chime(f, 0.85, 0.30) * (0.22 - i * 0.04), 0.18 + 0.07 * i)
    return reverb(out, wet=0.4)


def sk_lifelamp() -> np.ndarray:
    """바리공주 · 생명등불: 따뜻한 화음이 둥글게 번지며 오래 남는다."""
    dur = 1.3
    out = np.zeros(n_of(dur))
    for i, f in enumerate([D4, A4, D5]):
        add_at(out, tube(f, 1.2, 0.42, air=0.04) * (0.45 - i * 0.08), 0.04 * i)
    add_at(out, breath(0.6, 900.0, 0.20) * 0.18, 0.0)
    return reverb(out, wet=0.5)


def sk_deathflower() -> np.ndarray:
    """바리공주 · 저승꽃: 낮게 피어오르는 꽃 + 맑은 옥 울림."""
    dur = 1.1
    out = np.zeros(n_of(dur))
    add_at(out, breath(0.7, 700.0, 0.25) * 0.30, 0.0)
    for i, f in enumerate([F4, C5, F5]):
        add_at(out, tube(f, 0.95, 0.30, air=0.02) * (0.34 - i * 0.07), 0.06 + 0.07 * i)
    add_at(out, chime(F5, 0.7, 0.22) * 0.12, 0.3)
    return reverb(out, wet=0.45)


def sk_returnpath() -> np.ndarray:
    """바리공주 · 귀환의 길: 바람이 위로 열리고 화음이 도착한다."""
    dur = 1.15
    out = np.zeros(n_of(dur))
    add_at(out, swish(0.55, 600.0, 3200.0, 1.5, 0.22) * 0.38, 0.0)
    for i, f in enumerate([A4, D5, A5]):
        add_at(out, chime(f, 0.9, 0.32) * (0.26 - i * 0.05), 0.16 + 0.09 * i)
    return reverb(out, wet=0.5)


def sk_ghostgate() -> np.ndarray:
    """강림도령 · 귀문보기: 낮은 공명이 스르르 열리며 사슬이 가볍게 흔들린다."""
    dur = 1.15
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    low = np.sin(TAU * 55.0 * t) * 0.34 + 0.14 * np.sin(TAU * 110.0 * t) + 0.06 * np.sin(TAU * 165.0 * t)
    out += low * np.clip(t / 0.25, 0.0, 1.0) * np.exp(-t / 0.7)
    add_at(out, grains(dur, 7, 1400.0, 3200.0, 0.055, 0.02), 0.1)
    add_at(out, breath(0.8, 600.0, 0.35) * 0.22, 0.0)
    return reverb(out, wet=0.45)


def sk_soulmark() -> np.ndarray:
    """강림도령 · 혼길표식: 나무 말뚝을 세우고 낮은 울림이 남는다."""
    dur = 0.85
    out = np.zeros(n_of(dur))
    add_at(out, thump(160.0, 96.0, 0.3, 0.07, 0.22) * 0.5, 0.0)
    add_at(out, wood(400.0, 0.14, 0.03, 0.4) * 0.4, 0.0)
    add_at(out, chime(D4, 0.7, 0.20) * 0.14, 0.06)
    add_at(out, grains(0.4, 4, 1600.0, 3400.0, 0.03, 0.02), 0.1)
    return reverb(out, wet=0.4)


def sk_underworldgate() -> np.ndarray:
    """강림도령 · 저승문: 낮게 가라앉는 바람 + 문이 닫히는 묵직한 울림."""
    dur = 1.1
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    add_at(out, swish(0.6, 1400.0, 320.0, 1.7, 0.3) * 0.4, 0.0)
    freq = 120.0 * np.exp(-t / 0.45) + 48.0
    out += np.sin(TAU * np.cumsum(freq) / SR) * np.clip(t / 0.08, 0.0, 1.0) * np.exp(-t / 0.6) * 0.34
    add_at(out, thump(90.0, 52.0, 0.6, 0.18, 0.2) * 0.35, 0.04)
    return reverb(out, wet=0.5)


def sk_mimic() -> np.ndarray:
    """구미호 · 인간둔갑: 가야금이 위로 스르륵 훑고 여우불이 사그라든다."""
    dur = 0.95
    out = np.zeros(n_of(dur))
    add_at(out, gliss([D4, F4, G4, A4, C5], 0.055, 0.85, 0.55, 0.55), 0.0)
    add_at(out, breath(0.5, 1200.0, 0.16) * 0.25, 0.02)
    add_at(out, chime(A5, 0.6, 0.2) * 0.10, 0.22)
    return reverb(out, wet=0.4)


def sk_foxscent() -> np.ndarray:
    """구미호 · 여우향: 달콤한 화음이 부드럽게 번진다(현 + 옥)."""
    dur = 1.0
    out = np.zeros(n_of(dur))
    for i, f in enumerate([D4, F4, A4]):
        add_at(out, pluck(f, 0.9, 0.996, 0.42) * (0.4 - i * 0.06), 0.03 * i)
    for i, f in enumerate([A4, D5]):
        add_at(out, tube(f, 0.85, 0.26, air=0.03) * 0.16, 0.05 + 0.05 * i)
    add_at(out, breath(0.5, 1500.0, 0.18) * 0.14, 0.0)
    return reverb(out, wet=0.45)


def sk_foxdream() -> np.ndarray:
    """구미호 · 구미환몽: 아래로 흐르는 가야금 + 몽환적인 겹울림."""
    dur = 1.25
    out = np.zeros(n_of(dur))
    add_at(out, gliss([C5, A4, G4, F4, D4], 0.075, 1.0, 0.5, 0.4), 0.0)
    n = n_of(dur)
    t = tt(n)
    pad = np.sin(TAU * 220.0 * t) * 0.10 + np.sin(TAU * 329.63 * t) * 0.07
    pad *= np.clip(t / 0.2, 0.0, 1.0) * np.exp(-t / 0.55)
    out += pad
    add_at(out, chime(F5, 0.8, 0.24) * 0.10, 0.3)
    return reverb(out, wet=0.55)


def sk_voicemimic() -> np.ndarray:
    """장산범 · 목소리흉내: 멀리서 들리는 낮은 부름(가까이서 울리지 않게 먹먹하게)."""
    dur = 1.0
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    pitch = 196.0 * (1.0 + 0.012 * np.sin(TAU * 4.5 * t))
    voice = np.sin(TAU * np.cumsum(pitch) / SR) * 0.24
    voice += 0.10 * np.sin(TAU * np.cumsum(pitch * 2.0) / SR)
    voice *= np.clip(t / 0.12, 0.0, 1.0) * np.exp(-t / 0.35)
    out += lp(voice, 1200.0)
    add_at(out, breath(0.8, 900.0, 0.3) * 0.16, 0.05)
    out = reverb(out, taps=((0.061, 0.22), (0.103, 0.14), (0.157, 0.08)), wet=0.6)
    return out


def sk_soundhunt() -> np.ndarray:
    """장산범 · 청각사냥: 귀를 기울이는 낮은 울림 + 나무가 딱딱."""
    dur = 0.9
    out = np.zeros(n_of(dur))
    add_at(out, breath(0.5, 700.0, 0.22) * 0.22, 0.0)
    add_at(out, wood(640.0, 0.1, 0.014, 0.35) * 0.28, 0.10)
    add_at(out, wood(820.0, 0.1, 0.012, 0.35) * 0.22, 0.24)
    n = n_of(dur)
    t = tt(n)
    out += np.sin(TAU * 98.0 * t) * np.exp(-t / 0.4) * 0.14
    return reverb(out, wet=0.35)


def sk_mountaingrowl() -> np.ndarray:
    """장산범 · 산군의 울음: 깊은 저역이 산을 타고 번진다(찢어지는 고역 없음)."""
    dur = 1.35
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    base = 46.0 + 3.0 * np.sin(TAU * 0.7 * t)
    growl = np.sin(TAU * np.cumsum(base) / SR) * 0.40
    growl += 0.16 * np.sin(TAU * np.cumsum(base * 2.0) / SR)
    growl += 0.06 * np.sin(TAU * np.cumsum(base * 3.0) / SR)
    tremolo = 0.72 + 0.28 * np.sin(TAU * 7.5 * t)
    growl *= tremolo * np.clip(t / 0.18, 0.0, 1.0) * np.exp(-t / 0.75)
    out += growl
    add_at(out, lp(noise(n), 420.0) * 0.10 * np.exp(-t / 0.5), 0.0)
    return reverb(out, taps=((0.047, 0.20), (0.083, 0.13), (0.137, 0.07)), wet=0.5)


def sk_mischief() -> np.ndarray:
    """도깨비 · 도깨비장난: 장난스러운 나무 타격 여러 번 + 작은 웃음 같은 음 굴림."""
    dur = 0.8
    out = np.zeros(n_of(dur))
    for i, at in enumerate([0.0, 0.07, 0.15, 0.24, 0.36]):
        add_at(out, wood(620.0 + 120.0 * (i % 3), 0.09, 0.012, 0.55) * (0.4 - i * 0.04), at)
    n = n_of(dur)
    t = np.arange(n) / SR
    giggle = np.sin(TAU * np.cumsum(520.0 + 160.0 * np.sin(TAU * 9.0 * t)) / SR)
    giggle *= np.clip((t - 0.4) / 0.05, 0.0, 1.0) * np.exp(-np.maximum(t - 0.4, 0.0) / 0.12)
    out += lp(giggle, 1800.0) * 0.10
    return reverb(out, wet=0.25)


def sk_faketreasure() -> np.ndarray:
    """도깨비 · 가짜보물: 반짝이는 보물 같지만 어딘가 헛빠진 소리."""
    dur = 0.8
    out = np.zeros(n_of(dur))
    for i, f in enumerate([D5, G5, C6]):
        add_at(out, chime(f, 0.6, 0.22) * (0.24 - i * 0.04), 0.02 + 0.08 * i)
    n = n_of(dur)
    t = tt(n)
    wobble = np.sin(TAU * np.cumsum(330.0 + 60.0 * np.sin(TAU * 6.0 * t)) / SR) * np.exp(-t / 0.25) * 0.12
    out += wobble
    add_at(out, wood(700.0, 0.08, 0.012, 0.4) * 0.18, 0.0)
    return reverb(out, wet=0.4)


def sk_goblinfest() -> np.ndarray:
    """도깨비 · 도깨비잔치: 북소리 + 도깨비불 타닥 + 경쾌한 방울."""
    dur = 1.1
    out = np.zeros(n_of(dur))
    add_at(out, drum(104.0, 62.0, 0.55, 0.15) * 0.55, 0.0)
    add_at(out, wood(760.0, 0.09, 0.012, 0.5) * 0.22, 0.02)
    add_at(out, grains(dur, 16, 900.0, 3600.0, 0.075, 0.018), 0.12)
    for i, f in enumerate([D5, A5]):
        add_at(out, chime(f, 0.6, 0.2) * 0.14, 0.1 + 0.12 * i)
    return reverb(out, wet=0.3)


def sk_douse() -> np.ndarray:
    """어둑시니 · 등불끄기: '후-' 하고 불이 꺼지며 낮게 가라앉는다."""
    dur = 0.9
    out = np.zeros(n_of(dur))
    add_at(out, breath(0.55, 1100.0, 0.16) * 0.55, 0.0)
    add_at(out, swish(0.5, 1500.0, 300.0, 1.8, 0.2) * 0.3, 0.0)
    n = n_of(dur)
    t = tt(n)
    fall = np.sin(TAU * np.cumsum(220.0 * np.exp(-t / 0.3) + 70.0) / SR) * np.exp(-t / 0.3) * 0.16
    out += fall
    return reverb(out, wet=0.35)


def sk_blackvision() -> np.ndarray:
    """어둑시니 · 검은시야: 시야가 먹물처럼 좁아지는 낮고 먹먹한 울림."""
    dur = 1.05
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    out += (np.sin(TAU * 65.0 * t) * 0.26 + 0.10 * np.sin(TAU * 130.0 * t)) * np.clip(t / 0.3, 0.0, 1.0) * np.exp(-t / 0.6)
    add_at(out, breath(0.7, 500.0, 0.35) * 0.28, 0.0)
    add_at(out, grains(0.9, 5, 700.0, 2200.0, 0.03, 0.03), 0.2)
    return reverb(out, wet=0.45)


def sk_moonlessnight() -> np.ndarray:
    """어둑시니 · 무월야: 달이 가린 밤처럼 낮게 길게 번지는 어둠."""
    dur = 1.6
    n = n_of(dur)
    t = tt(n)
    out = np.zeros(n)
    drone = np.sin(TAU * 44.0 * t) * 0.30 + 0.12 * np.sin(TAU * 88.0 * t) + 0.05 * np.sin(TAU * 132.0 * t)
    out += drone * np.clip(t / 0.5, 0.0, 1.0) * np.exp(-t / 1.1)
    add_at(out, swish(1.1, 900.0, 220.0, 1.9, 0.55) * 0.22, 0.0)
    add_at(out, grains(dur, 6, 1200.0, 2600.0, 0.022, 0.04), 0.3)
    return reverb(out, taps=((0.053, 0.20), (0.089, 0.12), (0.151, 0.07)), wet=0.5)


def sk_shoeprints() -> np.ndarray:
    """야광귀 · 신발흔적: 발자국이 반짝이며 찍힌다."""
    dur = 0.75
    out = np.zeros(n_of(dur))
    for i, at in enumerate([0.0, 0.16, 0.32]):
        add_at(out, wood(420.0, 0.1, 0.018, 0.25) * (0.25 - i * 0.04), at)
        add_at(out, chime(D5 * (1.0 + 0.125 * i), 0.35, 0.12) * (0.12 - i * 0.02), at + 0.02)
    return reverb(out, wet=0.3)


def sk_glowpowder() -> np.ndarray:
    """야광귀 · 야광가루: 가볍고 영롱한 반짝임이 흩날린다."""
    dur = 0.9
    out = np.zeros(n_of(dur))
    notes = [D5, F5, A5, C6, D5 * 2, A5]
    for i, f in enumerate(notes):
        add_at(out, chime(f, 0.5, 0.16) * (0.16 - 0.012 * i), 0.02 + 0.055 * i)
    add_at(out, grains(0.8, 10, 2600.0, 6800.0, 0.035, 0.016), 0.0)
    return reverb(out, wet=0.4)


def sk_footprintmap() -> np.ndarray:
    """야광귀 · 발자국지도: 위로 올라가는 영롱한 아르페지오 + 은은한 바탕."""
    dur = 1.15
    out = np.zeros(n_of(dur))
    for i, f in enumerate([D4, A4, D5, A5, C6]):
        add_at(out, chime(f, 0.85, 0.26) * (0.22 - i * 0.025), 0.06 * i)
    n = n_of(dur)
    t = tt(n)
    out += np.sin(TAU * 146.83 * t) * 0.10 * np.clip(t / 0.2, 0.0, 1.0) * np.exp(-t / 0.6)
    return reverb(out, wet=0.5)


SKILLS = {
    "clone": sk_clone, "transform": sk_transform, "painting": sk_painting,
    "wallhop": sk_wallhop, "windstep": sk_windstep, "eightleap": sk_eightleap,
    "puppet": sk_puppet, "trap": sk_trap, "astrolabe": sk_astrolabe,
    "lifelamp": sk_lifelamp, "deathflower": sk_deathflower, "returnpath": sk_returnpath,
    "ghostgate": sk_ghostgate, "soulmark": sk_soulmark, "underworldgate": sk_underworldgate,
    "mimic": sk_mimic, "foxscent": sk_foxscent, "foxdream": sk_foxdream,
    "voicemimic": sk_voicemimic, "soundhunt": sk_soundhunt, "mountaingrowl": sk_mountaingrowl,
    "mischief": sk_mischief, "faketreasure": sk_faketreasure, "goblinfest": sk_goblinfest,
    "douse": sk_douse, "blackvision": sk_blackvision, "moonlessnight": sk_moonlessnight,
    "shoeprints": sk_shoeprints, "glowpowder": sk_glowpowder, "footprintmap": sk_footprintmap,
}


def make_skills() -> None:
    for skill_id, maker in SKILLS.items():
        data = maker()
        save(SKILL_DIR / f"{skill_id}.wav", data, rms=0.105, peak=0.68)
    # 둔갑술은 기본 사물 둔갑 SFX(transform.wav)와 결을 맞춘 별도 도술 음을 쓴다.
    save(SKILL_DIR / "transform.wav", sk_transform(), rms=0.105, peak=0.68)


def main() -> None:
    make_ui()
    make_spell()
    make_seal()
    make_rescue()
    make_jump()
    make_transform()
    make_combat()
    make_skills()
    manifest_path = TARGET / "provenance.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for path in sorted(list(TARGET.glob("*.wav")) + list(SKILL_DIR.glob("*.wav"))):
        key = path.name if path.parent == TARGET else "skills/" + path.name
        manifest[key] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                         "bytes": path.stat().st_size}
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    total = sum((TARGET / n).stat().st_size for n in ["spell.wav", "seal.wav", "rescue.wav", "jump.wav",
                                                      "transform.wav", "button.wav", "dialogue.wav",
                                                      "attack.wav", "hit.wav"])
    skills = sum(p.stat().st_size for p in SKILL_DIR.glob("*.wav"))
    print(f"AUDIO V31 READY · base {total/1024:.0f}KB · skills {len(SKILLS)}종 {skills/1024:.0f}KB")


if __name__ == "__main__":
    main()
