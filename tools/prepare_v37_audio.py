#!/usr/bin/env python3
"""2.0.37 상용 수준 CC0 오디오 전면 교체 준비.

합성음을 모두 버리고 OpenGameArt의 CC0 실제 녹음만으로 다시 만든다.
- BGM 5곡(로비·조선·강남역·해운대·동성로): 원본 .ogg를 그대로 넣는다(무손실 재인코딩 없음).
- 바닥 재질별 발소리: grass_dirt / stone / wood / tile_indoor / asphalt / sand / water / escalator.
- 도술 30종 + 기본 SFX·UI·기믹: 실제 녹음을 잘라 44.1kHz 스테레오 16bit WAV로 정규화.

원본은 `V37_SRC`(기본 /workspace/work/v37_audio_src)에서 읽는다. 이 폴더는 저장소에 넣지 않는다.
사용: python3 tools/prepare_v37_audio.py [--src DIR]
"""
from __future__ import annotations

import argparse
import math
import os
import wave
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "audio"
SR = 44100


# ---------------------------------------------------------------- 기본 도구
def load(path: Path) -> np.ndarray:
    data, sr = sf.read(str(path), always_2d=True)
    x = data.mean(axis=1).astype(np.float64)
    if sr != SR:
        g = math.gcd(int(sr), SR)
        x = signal.resample_poly(x, SR // g, int(sr) // g)
    return x


def trim(x: np.ndarray, thresh: float = 0.012, pad: float = 0.01) -> np.ndarray:
    if len(x) == 0:
        return x
    env = np.abs(x)
    peak = float(env.max())
    if peak <= 1e-9:
        return x
    gate = max(thresh * peak, 0.002)
    idx = np.flatnonzero(env > gate)
    if len(idx) == 0:
        return x
    a = max(0, int(idx[0] - pad * SR))
    b = min(len(x), int(idx[-1] + pad * SR))
    return x[a:b]


def lowpass(x: np.ndarray, hz: float) -> np.ndarray:
    if hz >= SR / 2 * 0.95:
        return x
    b, a = signal.butter(4, hz / (SR / 2), "low")
    return signal.filtfilt(b, a, x)


def highpass(x: np.ndarray, hz: float) -> np.ndarray:
    if hz <= 20:
        return x
    b, a = signal.butter(4, hz / (SR / 2), "high")
    return signal.filtfilt(b, a, x)


def fade(x: np.ndarray, ms: float = 6.0) -> np.ndarray:
    n = max(1, int(ms / 1000 * SR))
    if len(x) < 2 * n:
        n = max(1, len(x) // 4)
    ramp = np.linspace(0.0, 1.0, n)
    x = x.copy()
    x[:n] *= ramp
    x[-n:] *= ramp[::-1]
    return x


def normalize(x: np.ndarray, peak: float = 0.88, rms_target: float = 0.0) -> np.ndarray:
    p = float(np.max(np.abs(x))) if len(x) else 0.0
    if p > 0:
        x = x * (peak / p)
    if rms_target > 0:
        r = float(np.sqrt(np.mean(x ** 2)))
        if r > 1e-6:
            x = x * min(rms_target / r, 0.92 / max(1e-9, float(np.max(np.abs(x)))))
    return x


def hue(x: np.ndarray, hz: float | None = None) -> np.ndarray:
    """8kHz 위 에너지가 과하면 부드럽게 깎아 치직거림을 줄인다."""
    if hz is None:
        hz = 12000.0
    y = lowpass(x, hz)
    while hz > 5000:
        spec = np.abs(np.fft.rfft(y * np.hanning(len(y)))) ** 2
        freqs = np.fft.rfftfreq(len(y), 1 / SR)
        total = max(1e-12, float(spec.sum()))
        hf = float(spec[freqs > 8000].sum() / total)
        if hf <= 0.17:
            break
        hz *= 0.75
        y = lowpass(x, hz)
    return y


def pitch(x: np.ndarray, factor: float) -> np.ndarray:
    """간단한 피치 이동(길이도 함께 변한다). factor>1 = 높은 소리."""
    if abs(factor - 1.0) < 0.001:
        return x
    n = max(2, int(len(x) / factor))
    return signal.resample(x, n)


def stretch_to(x: np.ndarray, seconds: float) -> np.ndarray:
    n = max(2, int(seconds * SR))
    return signal.resample(x, n)


def slice_at(x: np.ndarray, start: float, seconds: float) -> np.ndarray:
    a = max(0, int(start * SR))
    b = min(len(x), a + int(seconds * SR))
    return x[a:b]


def loudest(x: np.ndarray, seconds: float) -> np.ndarray:
    """긴 녹음에서 가장 에너지가 큰 구간을 잘라 낸다(소리가 거의 없는 구간 회피)."""
    n = max(2, int(seconds * SR))
    if len(x) <= n:
        return x
    hop = max(1, int(0.025 * SR))
    best_pos, best_energy = 0, -1.0
    for pos in range(0, len(x) - n, hop):
        e = float(np.sqrt(np.mean(x[pos:pos + n] ** 2)))
        if e > best_energy:
            best_energy, best_pos = e, pos
    return x[best_pos:best_pos + n]


def mix(*layers: tuple[np.ndarray, float]) -> np.ndarray:
    n = max(len(y) for y, _ in layers)
    out = np.zeros(n)
    for y, gain in layers:
        out[: len(y)] += y * gain
    return out


def onsets(x: np.ndarray, count: int, win: float = 0.30, gap: float = 0.18) -> list[np.ndarray]:
    """에너지가 솟는 지점을 찾아 count개의 짧은 조각을 돌려준다(발소리 잘라내기)."""
    win_n = int(win * SR)
    hop = int(0.01 * SR)
    energy = np.array([
        float(np.sqrt(np.mean(x[i:i + win_n] ** 2))) if i + win_n <= len(x) else 0.0
        for i in range(0, max(1, len(x) - win_n), hop)
    ])
    if energy.size == 0:
        return []
    floor = float(np.percentile(energy, 20))
    peaks: list[int] = []
    for i in range(1, energy.size - 1):
        if energy[i] > energy[i - 1] and energy[i] >= energy[i + 1] and energy[i] > floor * 1.6:
            pos = i * hop
            if all(abs(pos - p) > gap * SR for p in peaks):
                peaks.append(pos)
    peaks.sort(key=lambda p: -float(energy[p // hop]))
    chosen = sorted(peaks[:count])
    return [x[max(0, p - int(0.01 * SR)): p + win_n] for p in chosen]


def write_wav(path: Path, x: np.ndarray, min_seconds: float = 0.09) -> None:
    """44.1kHz 스테레오 16bit WAV. 두 채널에 아주 작은 시간차를 두어 폭을 준다."""
    if len(x) < int(min_seconds * SR):
        x = stretch_to(x, min_seconds)
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    if peak > 0.985:
        x = x * (0.985 / peak)
    delay = int(0.0006 * SR)
    left = np.concatenate([x[delay:], np.zeros(delay)])
    right = x
    stereo = np.stack([left, right], axis=1)
    stereo = np.clip(stereo, -1.0, 1.0)
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (stereo * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# ---------------------------------------------------------------- 원본 로드
class Src:
    def __init__(self, root: Path):
        self.root = root
        self.cache: dict[str, np.ndarray] = {}

    def __call__(self, rel: str) -> np.ndarray:
        if rel not in self.cache:
            path = self.root / rel
            if not path.exists():
                raise FileNotFoundError(path)
            self.cache[rel] = load(path)
        return self.cache[rel]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.environ.get("V37_SRC", "/workspace/work/v37_audio_src"))
    args = ap.parse_args()
    src = Src(Path(args.src))
    made: list[tuple[str, float]] = []

    def out(rel: str, x: np.ndarray, peak: float = 0.88, min_sec: float = 0.09, hp: float = 0.0) -> None:
        y = trim(x)
        if hp > 0:
            y = highpass(y, hp)
        y = hue(normalize(y, peak))
        write_wav(AUDIO / rel, fade(y), min_sec)
        made.append((rel, len(y) / SR))

    # ------------------------------------------------------------ BGM (원본 ogg 그대로)
    bgm = {
        "bgm/lobby_fantasy.ogg": "bgm/heartfelt-battle_full.ogg",
        "bgm/seowon_battle.ogg": "bgm/fairy_battles_bpm180_0.ogg",
        "bgm/gangnam_trance.ogg": "bgm/trance_city_bpm130_0.ogg",
        "bgm/haeundae_beach.ogg": "bgm/ogg_beachtheme_3.ogg",
        "bgm/dongseongno_urban.ogg": "bgm/urban_theme_bpm115_0.ogg",
    }
    for rel, source in bgm.items():
        data = (Path(args.src) / source).read_bytes()
        target = AUDIO / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

    # ------------------------------------------------------------ 발소리: 바닥 재질별
    def fant(name: str) -> np.ndarray:
        return src(f"fantozzi/Fantozzi-footsteps/ogg/{name}.ogg")

    grass = [fant(n) for n in ("Fantozzi-SandL1", "Fantozzi-SandL2", "Fantozzi-SandL3", "Fantozzi-SandR1", "Fantozzi-SandR2")]
    stone = [fant(n) for n in ("Fantozzi-StoneL1", "Fantozzi-StoneL2", "Fantozzi-StoneL3", "Fantozzi-StoneR1", "Fantozzi-StoneR2")]
    for i, x in enumerate(grass, 1):
        out(f"steps/grass_dirt_{i}.wav", slice_at(x, 0.0, 0.32), 0.72)
    for i, x in enumerate(stone, 1):
        out(f"steps/stone_{i}.wav", slice_at(x, 0.0, 0.30), 0.72)

    # 나무 마루: kdd wood 3종 + 가죽 부츠 + Kenney footstep04
    woods = [src("kdd/wood01.ogg"), src("kdd/wood02.ogg"), src("kdd/wood03.ogg"),
             src("tiny/sfx-cc0/boots-leather-step-01.wav"), src("kenney/OGG/footstep04.ogg")]
    for i, x in enumerate(woods, 1):
        out(f"steps/wood_{i}.wav", slice_at(x, 0.0, 0.30), 0.75)

    # 실내 타일: 단단한 돌발음을 살짝 밝게 + 짧은 반사(타일 홀)
    for i, x in enumerate(stone, 1):
        base = slice_at(highpass(x, 160.0), 0.0, 0.26)
        echo = np.zeros(int(0.05 * SR))
        tap = np.concatenate([echo, base * 0.20])
        out(f"steps/tile_indoor_{i}.wav", mix((base, 1.0), (tap, 0.55)), 0.72)

    # 아스팔트: 자갈 + 둔탁하게 깎은 돌
    grav = [src("kdd/gravel.ogg"), src("kdd/leaves01.ogg"), src("kdd/stone01.ogg")]
    for i in range(5):
        base = slice_at(grav[i % 3], 0.0, 0.28)
        dull = lowpass(slice_at(stone[i % 5], 0.0, 0.24), 2400.0)
        out(f"steps/asphalt_{i+1}.wav", mix((base, 0.85), (dull, 0.75)), 0.70)

    # 모래: 실제 해변 발소리 녹음에서 잘라 쓴다.
    beach = src("sand_footsteps_0.mp3")
    sand_parts = onsets(beach, 5, win=0.30)
    for i, x in enumerate(sand_parts, 1):
        out(f"steps/sand_{i}.wav", lowpass(x, 9000.0), 0.62)

    # 물: 첨벙임 + 물방울
    splash = src("splash1_0.wav")
    splash2 = src("splash2_0.wav")
    drops = [src("tiny/sfx-cc0/water-drop-01.wav"), src("tiny/sfx-cc0/water-drop-02.wav")]
    spl = onsets(splash, 3, win=0.34) + onsets(splash2, 2, win=0.34)
    for i, x in enumerate(spl[:4], 1):
        out(f"steps/water_{i}.wav", lowpass(x, 10000.0), 0.68)
    for i, x in enumerate(drops, 5):
        out(f"steps/water_{i}.wav", loudest(x, 0.26), 0.80, 0.12)

    # 에스컬레이터: 금속 발판 클랭크(돌발음 + 금속 걸쇠)
    latch = src("kenney/OGG/metalLatch.ogg")
    for i in range(3):
        clank = pitch(slice_at(latch, 0.0, 0.16), 1.25)
        step = slice_at(stone[i], 0.0, 0.26)
        out(f"steps/escalator_{i+1}.wav", mix((step, 0.75), (clank, 0.55)), 0.72)

    # 항아리(둔갑 중 이동): 옹기 두드림
    for i in range(3):
        pot = pitch(slice_at(src(f"kenney/OGG/metalPot{i+1}.ogg"), 0.0, 0.26), 0.72)
        out(f"steps/jar_{i+1}.wav", lowpass(pot, 5200.0), 0.72)

    # ------------------------------------------------------------ 도술 30종
    magical = {n: src(f"magic/magical_{n}.ogg") for n in ("1_0", "2", "3", "4", "6_0", "7_0")}
    horror1 = src("horror/horror_effect1.wav")
    horror2 = src("horror/horror_effect2.wav")
    sting = src("horrorsting/dark_stinger_0.ogg")
    abyss = src("horrorsting/abyss_0.ogg")
    kenney = lambda n: src(f"kenney/OGG/{n}.ogg")  # noqa: E731
    tiny = lambda n: src(f"tiny/sfx-cc0/{n}.wav")  # noqa: E731

    def chunk(x: np.ndarray, start: float, seconds: float) -> np.ndarray:
        return slice_at(x, start, seconds)

    skill_recipes: dict[str, tuple[np.ndarray, float]] = {
        # 전우치 — 먹·종이·부적
        "clone": (mix((chunk(kenney("cloth3"), 0.0, 0.55), 1.0), (chunk(tiny("cover-paper-tear-01"), 0.0, 0.5), 0.7)), 0.82),
        "transform": (mix((chunk(kenney("cloth4"), 0.0, 0.6), 1.0), (chunk(magical["3"], 0.0, 0.7), 0.8)), 0.84),
        "painting": (mix((chunk(kenney("bookFlip2"), 0.0, 0.8), 1.0), (chunk(kenney("bookOpen"), 0.0, 0.6), 0.6)), 0.82),
        # 홍길동 — 바람
        "wallhop": (mix((chunk(tiny("tin-whistle-whoosh-01"), 0.0, 0.7), 1.0), (chunk(kenney("cloth1"), 0.0, 0.5), 0.5)), 0.84),
        "windstep": (chunk(tiny("tube-plastic-whoosh-01"), 0.0, 0.75), 0.84),
        "eightleap": (mix((chunk(tiny("tube-plastic-whoosh-02"), 0.0, 0.9), 1.0),
                          (pitch(chunk(tiny("tin-whistle-whoosh-02"), 0.0, 0.55), 1.2), 0.6)), 0.84),
        # 장영실 — 청동·태엽
        "puppet": (mix((chunk(kenney("metalLatch"), 0.0, 0.5), 1.0), (chunk(kenney("creak1"), 0.0, 0.6), 0.55)), 0.84),
        "trap": (mix((chunk(kenney("metalClick"), 0.0, 0.28), 1.0), (chunk(kenney("metalPot2"), 0.0, 0.5), 0.8)), 0.85),
        "astrolabe": (mix((loudest(tiny("chimes-wood-rattle"), 0.7), 1.0), (chunk(magical["4"], 0.0, 0.9), 0.7)), 0.84),
        # 바리공주 — 옥빛 생명
        "lifelamp": (mix((chunk(magical["7_0"], 0.0, 1.0), 1.0), (loudest(tiny("chimes-wood-rattle"), 0.6), 0.45)), 0.82),
        "deathflower": (mix((chunk(magical["6_0"], 0.0, 0.9), 1.0), (loudest(tiny("water-drop-02"), 0.4), 0.4)), 0.82),
        "returnpath": (mix((chunk(magical["1_0"], 0.0, 0.9), 1.0), (chunk(tiny("water-pour-01"), 0.0, 0.6), 0.45)), 0.82),
        # 강림도령 — 저승
        "ghostgate": (chunk(abyss, 0.0, 1.1), 0.55),
        "soulmark": (mix((chunk(magical["2"], 0.0, 0.7), 1.0), (chunk(kenney("metalLatch"), 0.0, 0.4), 0.5)), 0.82),
        "underworldgate": (mix((chunk(sting, 0.0, 1.2), 1.0), (chunk(abyss, 0.0, 0.8), 0.6)), 0.62),
        # 구미호
        "mimic": (mix((chunk(kenney("cloth2"), 0.0, 0.6), 1.0), (pitch(chunk(magical["3"], 0.0, 0.6), 1.18), 0.7)), 0.82),
        "foxscent": (mix((pitch(chunk(magical["6_0"], 0.0, 0.8), 1.12), 1.0), (chunk(tiny("compressed-air-spray-01"), 0.0, 0.5), 0.5)), 0.82),
        "foxdream": (mix((chunk(magical["4"], 0.0, 1.1)[::-1].copy(), 1.0), (chunk(tiny("bottle-pills-shake-01"), 0.0, 0.5), 0.35)), 0.80),
        # 장산범 — 울음·청각
        "voicemimic": (mix((pitch(chunk(horror2, 2.4, 0.9), 0.82), 1.0), (chunk(tiny("floor-creak-01"), 0.0, 0.6), 0.45)), 0.80),
        "soundhunt": (mix((loudest(tiny("water-drop-01"), 0.5), 1.0), (pitch(chunk(magical["2"], 0.0, 0.6), 1.3), 0.45)), 0.80),
        "mountaingrowl": (mix((chunk(horror1, 3.0, 1.4), 1.0), (lowpass(chunk(horror1, 5.2, 1.2), 900.0), 0.8)), 0.72),
        # 도깨비 — 방망이·보물
        "mischief": (mix((chunk(tiny("coins-shake-01"), 0.0, 0.9), 1.0), (loudest(tiny("chimes-wood-rattle"), 0.8), 0.9), (chunk(kenney("handleCoins2"), 0.0, 0.6), 0.6)), 0.78),
        "faketreasure": (mix((chunk(tiny("coin-spin-fall-01"), 0.0, 0.8), 1.0), (chunk(tiny("coinflip-01"), 0.0, 0.7), 0.6)), 0.84),
        "goblinfest": (mix((chunk(tiny("coins-shake-01"), 0.0, 0.9), 1.0), (chunk(tiny("wood-twigs-break-01"), 0.0, 0.7), 0.7), (chunk(magical["4"], 0.0, 0.8), 0.5)), 0.85),
        # 어둑시니 — 공포
        "douse": (mix((lowpass(chunk(horror1, 0.4, 1.3), 1400.0), 1.0), (pitch(chunk(horror2, 0.0, 1.0), 0.8), 0.6)), 0.68),
        "blackvision": (mix((lowpass(chunk(horror1, 6.8, 1.5), 800.0), 1.0), (chunk(abyss, 0.0, 0.9), 0.45)), 0.62),
        "moonlessnight": (mix((chunk(sting, 0.0, 1.6), 1.0), (lowpass(chunk(horror1, 1.6, 1.6), 700.0), 0.7), (pitch(chunk(abyss, 0.2, 1.2), 0.7), 0.5)), 0.70),
        # 야광귀 — 발자국·야광
        "shoeprints": (mix((chunk(stone[1], 0.0, 0.3), 1.0), (pitch(chunk(magical["6_0"], 0.0, 0.6), 1.25), 0.6)), 0.80),
        "glowpowder": (mix((chunk(tiny("compressed-air-spray-02"), 0.0, 0.7), 1.0), (chunk(magical["7_0"], 0.0, 0.8), 0.6)), 0.82),
        "footprintmap": (mix((chunk(kenney("bookOpen"), 0.0, 0.6), 1.0), (chunk(magical["2"], 0.0, 0.7), 0.55)), 0.82),
    }
    for skill, (data, peak) in skill_recipes.items():
        out(f"skills/{skill}.wav", data, peak, 0.30)

    # ------------------------------------------------------------ 기본 클립
    clips: dict[str, tuple[np.ndarray, float]] = {
        "ui_tap": (slice_at(tiny("wood-bowl-spoon-01"), 0.0, 0.16), 0.72),
        "ui_tab": (slice_at(tiny("book-page-01"), 0.0, 0.18), 0.70),
        "ui_back": (slice_at(tiny("drawer-close-01"), 0.0, 0.22), 0.70),
        "button": (lowpass(slice_at(tiny("wood-bowl-spoon-02"), 0.0, 0.18), 6500.0), 0.72),
        "lock_in": (slice_at(kenney("metalLatch"), 0.0, 0.34), 0.80),
        "match_join": (slice_at(tiny("chimes-wood-rattle"), 0.0, 0.55), 0.78),
        "match_found": (slice_at(magical["1_0"], 0.0, 0.85), 0.82),  # highpass below
        "attack": (slice_at(kenney("knifeSlice"), 0.0, 0.3), 0.84),
        "hit": (slice_at(kenney("chop"), 0.0, 0.35), 0.84),
        "reward": (slice_at(kenney("handleCoins"), 0.0, 0.55), 0.80),
        "spell": (slice_at(magical["2"], 0.0, 0.7), 0.82),
        "dialogue": (slice_at(tiny("book-page-02"), 0.0, 0.25), 0.66),
        "jump": (slice_at(tiny("boots-leather-jump-01"), 0.0, 0.4), 0.80),
        "door": (slice_at(kenney("doorOpen_1"), 0.0, 0.9), 0.80),
        "seal": (mix((slice_at(tiny("sword-clash-02"), 0.0, 0.7), 1.0), (lowpass(slice_at(kenney("metalPot1"), 0.0, 0.6), 4000.0), 0.6)), 0.84),
        "rescue": (mix((slice_at(magical["7_0"], 0.0, 0.9), 1.0), (slice_at(tiny("chimes-wood-rattle"), 0.0, 0.6), 0.5)), 0.82),
        "transform": (slice_at(kenney("cloth4"), 0.0, 0.7), 0.82),
        "gimmick_turnstile": (slice_at(tiny("handcuffs-metal-lock-01"), 0.0, 0.5), 0.82),
        "gimmick_cctv": (slice_at(kenney("metalClick"), 0.0, 0.25), 0.78),
        "gimmick_lights_off": (mix((slice_at(tiny("drawer-close-01"), 0.0, 0.35), 1.0), (lowpass(slice_at(abyss, 0.0, 0.5), 1500.0), 0.6)), 0.78),
        "gimmick_lights_on": (pitch(slice_at(kenney("metalClick"), 0.0, 0.25), 1.35), 0.78),
        "gimmick_shutter": (mix((slice_at(kenney("doorClose_3"), 0.0, 0.7), 1.0), (slice_at(tiny("handsaw-knife-scrape-01"), 0.0, 0.6), 0.5)), 0.82),
        "zone_warning": (mix((slice_at(tiny("metal-hammer-hit-01"), 0.0, 0.6), 1.0), (pitch(slice_at(tiny("chimes-wood-rattle"), 0.0, 0.5), 1.2), 0.5)), 0.84),
    }
    for name, (data, peak) in clips.items():
        out(f"{name}.wav", data, peak, 0.09, 40.0)

    total = sum(p.stat().st_size for p in AUDIO.rglob("*") if p.suffix in (".wav", ".ogg"))
    for rel, seconds in made:
        pass
    print(f"wrote {len(made)} wav clips, 5 bgm tracks; audio folder now {total/1024/1024:.1f} MB")
    long = [(rel, round(s, 2)) for rel, s in made if s > 3.0 or s < 0.08]
    if long:
        print("OUT OF RANGE:", long)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
