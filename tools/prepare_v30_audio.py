#!/usr/bin/env python3
"""2.0.30 사운드 고급화: 도술/봉인/구출/버튼 SFX와 인게임 긴장 BGM을 numpy+scipy로 합성한다.

- 단순 사인/구형파 '튱튱 퐁퐁' 대신, 필터링된 노이즈 + 저음 펀치 + 배음 레이어 +
  피치 엔벨로프 + 짧은 잔향으로 묵직하고 깔끔한 소리를 만든다.
- 인게임 BGM은 낮은 서스펜스 드론 + 심장박동/전통 북 맥동 + 계면조 대금 잔향 멜로디로
  '조용하지만 긴박한 술래잡기' 분위기를 만든다(플레이를 방해하지 않는 음량).
- 외부 샘플/유료 API 를 쓰지 않는다(무저작권). 결과는 assets/audio/*.wav.

사용: python3 tools/prepare_v30_audio.py
"""
from pathlib import Path
import hashlib, json, wave
import numpy as np
from scipy import signal

SR = 22050
TARGET = Path(__file__).resolve().parents[1] / "assets" / "audio"
rng = np.random.default_rng(20261120)


def save(name: str, data: np.ndarray, peak: float = 0.6) -> None:
    data = np.nan_to_num(np.asarray(data, dtype=np.float64))
    top = float(np.max(np.abs(data))) or 1.0
    data = np.tanh(data / top * 1.15) / np.tanh(1.15) * peak
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(TARGET / name), "wb") as w:
        w.setparams((1, 2, SR, 0, "NONE", ""))
        w.writeframes(pcm.tobytes())


def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(SR * dur)) / SR


def adsr(n: int, attack: float, decay: float, sustain: float = 0.0, release: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = sustain + (1 - sustain) * np.exp(-t / max(decay, 1e-4))
    if release > 0:
        d *= np.clip((n / SR - t) / release, 0, 1)
    return a * d


def bandpass(x: np.ndarray, low: float, high: float, order: int = 2) -> np.ndarray:
    nyq = SR / 2
    b, a = signal.butter(order, [max(low / nyq, 1e-4), min(high / nyq, 0.999)], btype="band")
    return signal.lfilter(b, a, x)


def lowpass(x: np.ndarray, cut: float, order: int = 2) -> np.ndarray:
    nyq = SR / 2
    b, a = signal.butter(order, min(cut / nyq, 0.999), btype="low")
    return signal.lfilter(b, a, x)


def highpass(x: np.ndarray, cut: float, order: int = 2) -> np.ndarray:
    nyq = SR / 2
    b, a = signal.butter(order, max(cut / nyq, 1e-4), btype="high")
    return signal.lfilter(b, a, x)


def sweep_noise(dur: float, f0: float, f1: float, width: float = 1.6, decay: float = 0.25) -> np.ndarray:
    """주파수가 f0→f1 로 훑고 지나가는 노이즈(바람·연기·칼날)."""
    n = int(SR * dur)
    noise = rng.normal(0, 1, n)
    # 시간에 따라 변하는 대역을 8구간으로 나눠 크로스페이드한다.
    out = np.zeros(n)
    pieces = 8
    for i in range(pieces):
        lo = int(n * i / pieces)
        hi = int(n * (i + 1) / pieces)
        if hi <= lo:
            continue
        cut = f0 * (f1 / f0) ** (i / max(pieces - 1, 1))
        seg = bandpass(noise, max(cut / width, 60), min(cut * width, SR * 0.45))
        w = np.ones(hi - lo)
        edge = max(1, (hi - lo) // 6)
        w[:edge] = np.linspace(0, 1, edge)
        w[-edge:] = np.linspace(1, 0, edge)
        out[lo:hi] += seg[lo:hi] * w
    return out * adsr(n, 0.004, decay)


def thump(freq: float, dur: float, drop: float = 0.45, decay: float = 0.15) -> np.ndarray:
    """저음 펀치: 피치가 빠르게 떨어지는 사인 + 배음. 봉인/충격의 몸통."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    pitch = freq * (1.0 + drop * np.exp(-t / 0.035))
    phase = 2 * np.pi * np.cumsum(pitch) / SR
    body = np.sin(phase) + 0.28 * np.sin(2 * phase) + 0.10 * np.sin(3 * phase)
    return body * adsr(n, 0.002, decay)


def bell(freq: float, dur: float, decay: float = 0.5) -> np.ndarray:
    """비배음(비정수 배음)을 섞은 종소리: 금속·맑은 공명."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    partials = [1.0, 2.01, 2.98, 4.16, 5.43, 6.79]
    gains = [1.0, 0.5, 0.34, 0.22, 0.14, 0.09]
    out = np.zeros(n)
    for p, g in zip(partials, gains):
        out += g * np.sin(2 * np.pi * freq * p * t) * np.exp(-t / (decay / (1 + 0.4 * (p - 1))))
    return out * adsr(n, 0.002, decay * 0.9)


def reverb(x: np.ndarray, taps=((0.031, 0.35), (0.047, 0.26), (0.071, 0.19), (0.109, 0.12), (0.163, 0.08))) -> np.ndarray:
    out = x.copy()
    for delay, gain in taps:
        d = int(SR * delay)
        if d <= 0 or d >= len(x):
            continue
        pad = np.zeros_like(x)
        pad[d:] = x[:-d] * gain
        out += pad
    return out


def make_spell() -> None:
    """도술 시전: 부적이 흩날리는 바람 + 낮은 울림 + 맑은 배음 꼬리."""
    dur = 0.85
    n = int(SR * dur)
    out = np.zeros(n)
    air = sweep_noise(dur, 3200, 620, width=1.9, decay=0.30)
    alen = min(n, len(air))
    out[:alen] += air[:alen] * 0.75
    _body = thump(190, 0.5, 0.30, 0.10) * 0.35
    out[: min(n, len(_body))] += _body[: min(n, len(_body))]
    # 부적이 부딪히는 짧은 금속성 클릭 여러 개
    for i, at in enumerate([0.012, 0.052, 0.098, 0.151, 0.213]):
        clip = bandpass(rng.normal(0, 1, int(SR * 0.09)), 1800, 7200) * adsr(int(SR * 0.09), 0.001, 0.018)
        start = int(SR * at)
        _e = min(n, start + len(clip))
        out[start:_e] += clip[: _e - start] * (0.20 - i * 0.02)
    tail = bell(784, 0.7, 0.34) * 0.10
    out[: min(n, len(tail))] += tail[: min(n, len(tail))]
    save("spell.wav", reverb(out, ((0.021, 0.22), (0.043, 0.14), (0.081, 0.08))), 0.55)


def make_seal() -> None:
    """접촉 봉인: 저음 임팩트 + 먹물이 닫히는 웅웅거림 + 금속 여운."""
    dur = 1.5
    n = int(SR * dur)
    out = np.zeros(n)
    _th = thump(58, 0.7, 0.55, 0.22) * 0.95
    out[: min(n, len(_th))] += _th[: min(n, len(_th))]
    shudder = bandpass(rng.normal(0, 1, int(SR * 0.9)), 90, 420) * adsr(int(SR * 0.9), 0.02, 0.30)
    out[: len(shudder)] += shudder * 0.30
    clang = bell(233, 1.2, 0.62) * 0.30
    out[: min(n, len(clang))] += clang[: min(n, len(clang))]
    hiss = highpass(rng.normal(0, 1, int(SR * 0.45)), 2600) * adsr(int(SR * 0.45), 0.001, 0.07)
    out[: len(hiss)] += hiss * 0.16
    save("seal.wav", reverb(out, ((0.037, 0.28), (0.059, 0.20), (0.113, 0.12), (0.191, 0.07))), 0.6)


def make_rescue() -> None:
    """구출: 맑게 울리는 종의 화음 + 떠오르는 숨결."""
    dur = 1.3
    n = int(SR * dur)
    out = np.zeros(n)
    for i, f in enumerate([523.25, 659.25, 987.77]):
        clip = bell(f, 1.2, 0.55) * (0.32 - i * 0.05)
        start = int(SR * 0.06 * i)
        end = min(n, start + len(clip))
        out[start:end] += clip[: end - start]
    rise = sweep_noise(0.7, 500, 2600, width=1.5, decay=0.35)
    rlen = min(n, len(rise))
    out[:rlen] += lowpass(rise, 5200)[:rlen] * 0.22
    save("rescue.wav", reverb(out, ((0.041, 0.30), (0.067, 0.20), (0.131, 0.11))), 0.55)


def make_transform() -> None:
    """둔갑: 연기처럼 퍼지는 숨 + 낮은 몸통 + 부드러운 방울."""
    dur = 0.7
    n = int(SR * dur)
    out = np.zeros(n)
    puff = sweep_noise(0.55, 900, 320, width=1.6, decay=0.18)
    plen = min(n, len(puff))
    out[:plen] += puff[:plen] * 0.75
    out[: int(SR * 0.35)] += thump(150, 0.35, 0.25, 0.08) * 0.28
    bubble = bell(1174, 0.5, 0.24) * 0.12
    bstart = int(SR * 0.05)
    bend = min(n, bstart + len(bubble))
    out[bstart:bend] += bubble[: bend - bstart]
    save("transform.wav", out, 0.5)


def make_ui() -> None:
    """버튼: 나무 도장을 '톡' 누르는 짧은 소리(사인파 삐 소리 금지)."""
    n = int(SR * 0.12)
    click = bandpass(rng.normal(0, 1, n), 700, 3400) * adsr(n, 0.001, 0.012)
    body = np.sin(2 * np.pi * 420 * np.arange(n) / SR) * adsr(n, 0.001, 0.02) * 0.35
    out = click * 0.7 + body
    save("button.wav", out, 0.42)
    # 대화: 부드러운 목소리 느낌의 낮은 울림
    n2 = int(SR * 0.28)
    d = bandpass(rng.normal(0, 1, n2), 260, 1900) * adsr(n2, 0.01, 0.07)
    d += np.sin(2 * np.pi * 196 * np.arange(n2) / SR) * adsr(n2, 0.02, 0.09) * 0.25
    save("dialogue.wav", d, 0.35)


def make_combat() -> None:
    """공격/피격: 짧은 바람 가르기와 둔탁한 타격."""
    n = int(SR * 0.22)
    swing = sweep_noise(0.18, 2400, 700, 1.8, 0.10) * 0.6
    out = np.zeros(n)
    out[: len(swing)] += swing
    hit = thump(120, 0.22, 0.4, 0.06) * 0.6
    out[: len(hit)] += hit
    save("attack.wav", out, 0.5)
    n2 = int(SR * 0.3)
    th = thump(80, 0.3, 0.5, 0.09) * 0.8
    th[:] += bandpass(rng.normal(0, 1, n2), 300, 2600) * adsr(n2, 0.001, 0.035) * 0.35
    save("hit.wav", th, 0.55)


def make_match_music() -> None:
    """인게임 술래잡기 BGM: 낮은 서스펜스 드론 + 심장박동·전통 북 + 오싹한 대금."""
    bpm = 76.0
    beat = 60.0 / bpm
    bars = 8
    total = beat * 4 * bars
    n = int(SR * total)
    t = np.arange(n) / SR
    track = np.zeros(n)

    # 1) 낮은 드론(단2도 불협을 아주 옅게 겹쳐 불안감)
    drone = (
        np.sin(2 * np.pi * 55.0 * t) * 0.30
        + np.sin(2 * np.pi * 58.27 * t) * 0.16
        + np.sin(2 * np.pi * 82.5 * t) * 0.10
        + np.sin(2 * np.pi * 110.0 * t) * 0.05
    )
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * t / (beat * 8) - np.pi / 2)
    track += lowpass(drone * swell, 220) * 0.42

    # 2) 심장박동: 두 번 울리는 낮은 쿵(2박마다) — 아주 낮게 깔아 긴장만 준다.
    for b in range(bars * 2):
        at = b * beat * 2
        for offset, gain in ((0.0, 0.55), (0.16, 0.34)):
            clip = thump(52, 0.42, 0.30, 0.13) * gain
            start = int(SR * (at + offset))
            end = min(n, start + len(clip))
            if start < n:
                track[start:end] += clip[: end - start] * 0.5

    # 3) 전통 북(장구 북편): 1·3박에 낮게, 4박 뒤에 채편.
    for bar in range(bars):
        for beat_i, gain in ((0, 0.5), (2, 0.32)):
            clip = thump(74, 0.5, 0.22, 0.16) * gain
            start = int(SR * (bar * 4 + beat_i) * beat)
            end = min(n, start + len(clip))
            track[start:end] += clip[: end - start]
        if bar % 2 == 1:
            at = int(SR * (bar * 4 + 3.5) * beat)
            stick = bandpass(rng.normal(0, 1, int(SR * 0.12)), 900, 3600) * adsr(int(SR * 0.12), 0.001, 0.02)
            end = min(n, at + len(stick))
            track[at:end] += stick[: end - at] * 0.20

    # 4) 오싹한 대금: 계면조(라·도·레·미·솔)에서 반음 겹친 불협을 섞어 길게 분다.
    scale = [0, 3, 5, 7, 10]
    root = 220.0
    phrases = [(3, 0.0, 3.0), (2, 5.0, 3.4), (4, 10.4, 3.2), (1, 16.0, 3.6), (0, 21.5, 4.2)]
    for degree, at_beat, length in phrases:
        f = root * (2 ** (scale[degree % 5] / 12))
        seg_n = int(SR * length)
        seg_t = np.arange(seg_n) / SR
        bend = 1 + 0.02 * np.sin(2 * np.pi * 0.35 * seg_t) + 0.004 * np.sin(2 * np.pi * 5.4 * seg_t)
        phase = 2 * np.pi * np.cumsum(f * bend) / SR
        breath = lowpass(rng.normal(0, 1, seg_n), 1400) * 0.05
        voice = np.sin(phase) * 0.16 + np.sin(2 * phase) * 0.06 + np.sin(3 * phase) * 0.03 + breath
        # 반음 위 그림자 음을 아주 옅게(불협)
        ghost = np.sin(2 * np.pi * f * 1.0595 * seg_t) * 0.045
        clip = (voice + ghost) * adsr(seg_n, 0.5, length * 0.45, 0.15, 0.9)
        start = int(SR * at_beat * beat)
        end = min(n, start + seg_n)
        if start < n:
            track[start:end] += clip[: end - start]

    # 5) 아주 옅은 고음 현의 떨림(초조함)
    shimmer = np.sin(2 * np.pi * 1320 * t) * 0.010 * (0.5 + 0.5 * np.sin(2 * np.pi * t / (beat * 4)))
    shimmer += np.sin(2 * np.pi * 1396 * t) * 0.008 * (0.5 + 0.5 * np.sin(2 * np.pi * t / (beat * 6) + 1.0))
    track += shimmer

    # 6) 루프 이음새: 마지막 1.2초를 앞부분에 겹쳐 자연스럽게 만든다.
    loop = track.copy()
    fade = int(SR * 1.2)
    tail = loop[n - fade :]
    loop[:fade] = loop[:fade] * np.linspace(0, 1, fade) + tail * np.linspace(1, 0, fade)
    loop = reverb(loop, ((0.073, 0.16), (0.149, 0.10), (0.263, 0.06)))
    # 전체 음량은 낮게(플레이 방해 금지). music player volume_db가 추가로 -15dB를 준다.
    save("seowon_ingame.wav", loop, 0.42)


def main() -> None:
    make_spell()
    make_seal()
    make_rescue()
    make_transform()
    make_ui()
    make_combat()
    make_match_music()
    manifest_path = TARGET / "provenance.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for name in ["spell.wav", "seal.wav", "rescue.wav", "transform.wav", "button.wav",
                 "dialogue.wav", "attack.wav", "hit.wav", "seowon_ingame.wav"]:
        path = TARGET / name
        manifest[name] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size}
    manifest_path.write_text(json.dumps(manifest, indent=2))
    print("AUDIO V30 READY")


if __name__ == "__main__":
    main()
