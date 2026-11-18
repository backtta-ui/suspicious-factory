#!/usr/bin/env python3
"""월하의 서원 인게임 사운드/긴장 BGM을 결정적으로 합성한다.

외부 샘플·유료 API 없이 numpy 표준 연산만 사용하며, 결과는
assets/audio/ 에 WAV(22050Hz mono 16bit)로 저장된다.
사용: python3 tools/prepare_ingame_audio.py
"""
from pathlib import Path
import json, hashlib, wave
import numpy as np

SR = 22050
TARGET = Path(__file__).resolve().parents[1] / "assets" / "audio"
rng = np.random.default_rng(20261118)


def save(name: str, data: np.ndarray, peak: float = 0.62) -> None:
    data = np.nan_to_num(data)
    top = float(np.max(np.abs(data))) or 1.0
    data = data / top * peak
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(TARGET / name), "wb") as w:
        w.setparams((1, 2, SR, 0, "NONE", ""))
        w.writeframes(pcm.tobytes())


def env(n: int, attack: float, decay: float) -> np.ndarray:
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-t / max(decay, 1e-4))
    return a * d


def tone(freq: float, dur: float, decay: float = 0.25, attack: float = 0.004) -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    wave_ = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(4 * np.pi * freq * t) + 0.12 * np.sin(6 * np.pi * freq * t)
    return wave_ * env(n, attack, decay)


def noise(dur: float, decay: float = 0.1) -> np.ndarray:
    n = int(SR * dur)
    return rng.uniform(-1, 1, n) * env(n, 0.002, decay)


def lowpass(x: np.ndarray, alpha: float) -> np.ndarray:
    out = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        out[i] = acc
    return out


def karplus(freq: float, dur: float, damp: float = 0.9965) -> np.ndarray:
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period)
    out = np.empty(n)
    idx = 0
    for i in range(n):
        value = buf[idx]
        nxt = buf[(idx + 1) % period]
        buf[idx] = damp * 0.5 * (value + nxt)
        out[i] = value
        idx = (idx + 1) % period
    return out * env(n, 0.002, dur * 0.55)


def place(track: np.ndarray, clip: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(SR * at)
    end = min(len(track), start + len(clip))
    if start >= len(track):
        return
    track[start:end] += clip[: end - start] * gain


def make_sfx() -> None:
    # 점프: 짧은 공기 흐름 + 낮은 탄성
    j = np.zeros(int(SR * 0.3))
    place(j, noise(0.22, 0.06) * 0.5, 0.0)
    place(j, tone(320, 0.22, 0.09) * 0.5, 0.0)
    place(j, tone(180, 0.22, 0.12) * 0.35, 0.0)
    save("jump.wav", lowpass(j, 0.35), 0.5)
    # 문: 나무 삐걱임 + 걸쇠
    n = noise(0.55, 0.22)
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(90, 150, int(SR * 0.55))) / SR) * env(int(SR * 0.55), 0.03, 0.18)
    d = lowpass(n, 0.12) * 0.8 + sweep * 0.5
    place(d, tone(1100, 0.06, 0.02) * 0.4, 0.42)
    save("door.wav", d, 0.5)
    # 봉인: 낮은 종 + 금빛 울림
    s = tone(196, 1.1, 0.4) * 0.6 + tone(392, 1.1, 0.3) * 0.25
    place(s, tone(587, 0.9, 0.18) * 0.12, 0.0)
    s += (rng.uniform(-1, 1, len(s)) * env(len(s), 0.001, 0.05)) * 0.08
    place(s, tone(1568, 0.4, 0.12) * 0.2, 0.02)
    save("seal.wav", s, 0.55)
    # 구출: 상승 아르페지오
    r = np.zeros(int(SR * 0.9))
    for i, f in enumerate([523, 659, 784, 1046]):
        place(r, tone(f, 0.5, 0.22) * 0.45, i * 0.09)
    save("rescue.wav", r, 0.55)
    # 둔갑: 뿅 + 작은 방울
    p = np.zeros(int(SR * 0.6))
    place(p, noise(0.18, 0.05) * 0.5, 0.0)
    place(p, tone(900, 0.2, 0.05) * 0.35, 0.0)
    place(p, tone(1760, 0.35, 0.1) * 0.3, 0.03)
    place(p, tone(2349, 0.3, 0.08) * 0.18, 0.08)
    save("transform.wav", p, 0.5)


def make_music() -> None:
    bpm = 84.0
    beat = 60.0 / bpm
    bars = 8
    total = beat * 4 * bars
    track = np.zeros(int(SR * total) + SR // 2)
    # A 단조 계면조(라·도·레·미·솔)
    scale = [0, 3, 5, 7, 10]
    root = 220.0

    def note(degree: int, octave: int = 0) -> float:
        return root * (2 ** ((scale[degree % 5] + 12 * (octave + degree // 5)) / 12))

    # 장구: 낮은 북 + 채편
    for b in range(bars * 4):
        at = b * beat
        boom = np.zeros(int(SR * 0.42))
        place(boom, tone(72, 0.42, 0.16) * 0.55, 0.0)
        place(boom, noise(0.12, 0.05) * 0.12, 0.0)
        place(track, boom, at, 1.0)
        if b % 2 == 1:
            place(track, lowpass(noise(0.16, 0.045), 0.6) * 0.22, at + beat * 0.5)
        if b % 4 == 3:
            place(track, tone(98, 0.3, 0.1) * 0.25, at + beat * 0.75)

    # 가야금 같은 뜯는 선율
    melody = [0, 2, 1, 3, 2, 0, 4, 3, 2, 1, 0, 2, 3, 1, 0, 4]
    for i, degree in enumerate(melody):
        at = i * beat * 2
        f = note(degree, 1 if i % 4 == 2 else 0)
        place(track, karplus(f, 1.1) * 0.42, at)
        if i % 4 == 0:
            place(track, karplus(note(degree, -1), 1.4) * 0.30, at + beat * 0.25)

    # 대금: 길게 숨을 얹은 음
    for i, (degree, at, length) in enumerate([(3, 0.0, 3.2), (2, 6.4, 3.6), (4, 13.0, 3.4), (1, 19.0, 3.0)]):
        n = int(SR * length)
        t = np.arange(n) / SR
        f = note(degree, 0)
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
        breath = lowpass(rng.uniform(-1, 1, n), 0.08) * 0.06
        s = np.sin(2 * np.pi * f * np.cumsum(vib) / SR) * 0.16
        s += np.sin(4 * np.pi * f * np.cumsum(vib) / SR) * 0.05 + breath
        place(track, s * env(n, 0.6, 1.6), at * beat)

    # 마지막 마디를 처음으로 부드럽게 겹쳐 루프 이음새 제거
    loop_len = int(SR * total)
    fade = int(SR * 1.2)
    body = track[:loop_len].copy()
    tail = track[loop_len:loop_len + fade]
    body[fade:loop_len] += 0.0
    body[:len(tail)] += tail * np.linspace(1, 0, len(tail)) * 0.6
    # 완만한 저역 패드로 밤 분위기
    t = np.arange(loop_len) / SR
    pad = (np.sin(2 * np.pi * 55 * t) + 0.5 * np.sin(2 * np.pi * 82.5 * t)) * 0.06
    body = lowpass(body + pad, 0.85)
    save("seowon_ingame.wav", body, 0.55)

    manifest_path = TARGET / "provenance.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for name in ["jump.wav", "door.wav", "seal.wav", "rescue.wav", "transform.wav", "seowon_ingame.wav"]:
        path = TARGET / name
        manifest[name] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size}
    manifest_path.write_text(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    make_sfx()
    make_music()
    print("월하의 서원 인게임 SFX/BGM 생성 완료")
