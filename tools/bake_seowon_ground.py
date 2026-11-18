#!/usr/bin/env python3
"""월하의 서원 바닥 통 원화(assets/woo/seowon/seowon_ground.png) 베이크.

layout.gd가 내보낸 geometry JSON으로 이동 가능 마스크를 만들어
돌바닥 원화와 이끼 마당 원화를 1:1로 합성한다. 격자·타일 블록은 만들지 않고,
경계는 돌 턱(curb) + 이끼 펄 + 접지 그림자로 자연스럽게 마감한다.

사용:
  godot --headless --path . --script res://tools/export_seowon_geometry.gd -- res://builds/seowon_geometry.json
  python3 tools/bake_seowon_ground.py
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art_sources" / "seowon_ground"
GEOMETRY = ROOT / "builds" / "seowon_geometry.json"
OUT = ROOT / "assets" / "woo" / "seowon" / "seowon_ground.png"
PREVIEW = ROOT / "builds" / "seowon_ground_preview.png"
SEED = 20261118


def rng(tag: int) -> np.random.Generator:
    return np.random.default_rng(SEED + tag)


# ---------------------------------------------------------------- 기본 재질
def read_rgb(path: Path) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise SystemExit(f"cannot read {path}")
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0


def mirror_tile(source: np.ndarray, size: tuple[int, int], scale: float, offset: tuple[float, float]) -> np.ndarray:
    """거울 반복으로 이음매 없이 큰 평면을 채운다."""
    width, height = size
    h, w = source.shape[:2]
    if scale != 1.0:
        image = cv2.resize(source, (max(2, int(round(w * scale))), max(2, int(round(h * scale)))), interpolation=cv2.INTER_LANCZOS4)
    else:
        image = source
    ih, iw = image.shape[:2]
    xs = np.arange(width) + int(round(offset[0]))
    ys = np.arange(height) + int(round(offset[1]))
    ix = np.mod(xs, 2 * iw)
    ix = np.where(ix < iw, ix, 2 * iw - 1 - ix)
    iy = np.mod(ys, 2 * ih)
    iy = np.where(iy < ih, iy, 2 * ih - 1 - iy)
    return image[iy][:, ix]


def cover(source: np.ndarray, size: tuple[int, int], angle: float = 0.0, zoom: float = 1.0) -> np.ndarray:
    """한 장의 원화를 회전·확대해 화면을 꽉 채운다(타일 반복 없음)."""
    width, height = size
    image = source
    if abs(angle) > 0.01:
        h, w = image.shape[:2]
        matrix = cv2.getRotationMatrix2D((w * 0.5, h * 0.5), angle, 1.0)
        cos, sin = abs(matrix[0, 0]), abs(matrix[0, 1])
        new_w, new_h = int(h * sin + w * cos), int(h * cos + w * sin)
        matrix[0, 2] += new_w * 0.5 - w * 0.5
        matrix[1, 2] += new_h * 0.5 - h * 0.5
        image = cv2.warpAffine(image, matrix, (new_w, new_h), flags=cv2.INTER_LANCZOS4)
    scale = max(width / image.shape[1], height / image.shape[0]) * zoom
    image = cv2.resize(image, (max(2, int(round(image.shape[1] * scale))), max(2, int(round(image.shape[0] * scale)))), interpolation=cv2.INTER_LANCZOS4)
    y0 = (image.shape[0] - height) // 2
    x0 = (image.shape[1] - width) // 2
    return image[y0:y0 + height, x0:x0 + width]


def blob_noise(size: tuple[int, int], cells: float, tag: int, octaves: int = 3) -> np.ndarray:
    """저주파 얼룩(0~1). cells = 화면을 가로지르는 큰 덩어리 수."""
    width, height = size
    out = np.zeros((height, width), np.float32)
    weight = 0.0
    for index in range(octaves):
        level = cells * (2.0 ** index)
        small = rng(tag + index).random((max(2, int(level * height / width)) + 2, max(2, int(level)) + 2)).astype(np.float32)
        scaled = cv2.resize(small, (width, height), interpolation=cv2.INTER_CUBIC)
        out += scaled / (2.0 ** index)
        weight += 1.0 / (2.0 ** index)
    out /= weight
    out -= out.min()
    peak = out.max()
    if peak > 1e-6:
        out /= peak
    return out


def smoothstep(x: np.ndarray, edge0: float, edge1: float) -> np.ndarray:
    t = np.clip((x - edge0) / max(1e-6, edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------- 마스크
def load_geometry() -> dict:
    if not GEOMETRY.exists():
        raise SystemExit(f"missing {GEOMETRY}; run tools/export_seowon_geometry.gd first")
    return json.loads(GEOMETRY.read_text())


def fill_rect(mask: np.ndarray, rect, grow: float = 0.0, value: int = 1) -> None:
    height, width = mask.shape[:2]
    x, y, w, h = rect
    x0 = max(0, int(np.floor(x - grow)))
    y0 = max(0, int(np.floor(y - grow)))
    x1 = min(width, int(np.ceil(x + w + grow)))
    y1 = min(height, int(np.ceil(y + h + grow)))
    if x1 > x0 and y1 > y0:
        mask[y0:y1, x0:x1] = value


def bridge_fields(shape: tuple[int, int], bridge: dict) -> tuple[np.ndarray, np.ndarray]:
    height, width = shape
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    ax, ay = bridge["a"]
    bx, by = bridge["b"]
    dx, dy = bx - ax, by - ay
    length = float(np.hypot(dx, dy))
    ux, uy = dx / length, dy / length
    rx, ry = xs - ax, ys - ay
    t = (rx * dx + ry * dy) / (length * length)
    offset = np.abs(rx * uy - ry * ux)
    return t, offset


def build_masks(geometry: dict, size: tuple[int, int]) -> dict:
    width, height = size
    margin = float(geometry.get("stand_margin", 9.0))
    walk = np.zeros((height, width), np.uint8)
    fill_rect(walk, geometry["walk"], grow=-margin)
    blocked = np.zeros((height, width), np.uint8)
    for key in ("hard", "bamboo", "furniture", "low"):
        for rect in geometry.get(key, []):
            fill_rect(blocked, rect, grow=margin)
    t, offset = bridge_fields((height, width), geometry["bridge"])
    half = float(geometry["bridge"]["half"])
    on_bridge = (t >= 0.0) & (t <= 1.0) & (offset <= half - margin)
    water = np.zeros((height, width), np.uint8)
    fill_rect(water, geometry["pond"], grow=margin)
    blocked = np.maximum(blocked, np.where(on_bridge, 0, water).astype(np.uint8))
    walk = np.where(blocked > 0, 0, walk).astype(np.uint8)

    # 화단(자연 지형): 대나무 군락 + 연못. 여기에만 돌 턱을 세운다.
    beds = np.zeros((height, width), np.uint8)
    for rect in geometry.get("bamboo", []):
        fill_rect(beds, rect, grow=6)
    fill_rect(beds, geometry["pond"], grow=3)
    # 담장 밑 그늘: 기와 담장 + 외곽 담장.
    walls = np.zeros((height, width), np.uint8)
    for rect in geometry.get("walls", []):
        fill_rect(walls, rect, grow=1)
    for rect in geometry.get("hard", [])[:4]:
        fill_rect(walls, rect, grow=6)

    deck = (t >= -0.02) & (t <= 1.02) & (offset <= half + 12.0)
    pond = np.zeros((height, width), np.uint8)
    fill_rect(pond, geometry["pond"], grow=2.0)
    courtyard = np.zeros((height, width), np.uint8)
    fill_rect(courtyard, [60.0, 120.0, 1680.0, 1220.0])
    return {"walk": walk, "blocked": (walk == 0).astype(np.uint8), "on_bridge": on_bridge, "deck": deck,
            "pond": pond, "courtyard": courtyard, "beds": beds, "walls": walls, "margin": margin}


# ---------------------------------------------------------------- 소품
def draw_polyline_band(size, points, width, sigma) -> np.ndarray:
    width_px, height_px = size
    canvas = np.zeros((height_px, width_px), np.uint8)
    pts = np.array([[int(round(x)), int(round(y))] for x, y in points], np.int32)
    cv2.polylines(canvas, [pts], False, 255, int(width), lineType=cv2.LINE_AA)
    band = canvas.astype(np.float32) / 255.0
    if sigma > 0:
        band = cv2.GaussianBlur(band, (0, 0), sigma)
    return band


def draw_blob(size, center, radius, falloff: float = 2.2) -> np.ndarray:
    width, height = size
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    d = np.sqrt((xs - center[0]) ** 2 + (ys - center[1]) ** 2) / max(1.0, radius)
    return np.clip(1.0 - d, 0.0, 1.0) ** falloff


# ---------------------------------------------------------------- 메인 베이크
def bake() -> None:
    geometry = load_geometry()
    width, height = int(geometry["size"][0]), int(geometry["size"][1])
    size = (width, height)
    print(f"ground {width}x{height}")

    stone_src = read_rgb(SRC / "stone_src.png")
    stone_warm = read_rgb(SRC / "stone_warm_src.png")
    moss_src = read_rgb(SRC / "moss_src.png")

    # 재질: 서로 다른 두 돌 원화를 다른 회전·배율로 크게 깔고 저주파 얼룩으로 섞는다.
    # 타일 반복을 쓰지 않으므로 격자나 같은 무늬 반복이 생기지 않는다.
    stone_a = cover(stone_src, size, angle=0.0, zoom=1.45)
    stone_b = cover(stone_warm, size, angle=17.0, zoom=1.22)
    mix = smoothstep(blob_noise(size, 2.6, 11), 0.22, 0.78)[..., None]
    stone = stone_a * (1.0 - mix) + stone_b * mix
    stone *= (0.90 + 0.26 * blob_noise(size, 4.0, 12))[..., None]
    # 달빛이 드는 마당: 차가운 회청색을 조금 밝게 끌어올린다.
    stone = stone * 1.34 + np.array([0.040, 0.040, 0.046], np.float32)
    stone = np.clip(stone, 0.0, 1.0)

    moss_a = cover(moss_src, size, angle=0.0, zoom=1.0)
    moss_b = cover(moss_src, size, angle=-24.0, zoom=1.1)
    moss_mix = smoothstep(blob_noise(size, 3.0, 21), 0.25, 0.75)[..., None]
    moss = moss_a * (1.0 - moss_mix) + moss_b * moss_mix
    # 화단은 밤 그늘: 어둡고 차갑게, 초록은 살짝 남긴다.
    moss = moss * np.array([0.26, 0.36, 0.30], np.float32) + np.array([0.010, 0.024, 0.026], np.float32)
    moss *= (0.70 + 0.45 * blob_noise(size, 6.0, 22))[..., None]
    moss = np.clip(moss, 0.0, 1.0)

    masks = build_masks(geometry, size)
    walk = masks["walk"].astype(np.float32)

    # 경계를 노이즈로 흔들고 부드럽게: 20px 칸 같은 각진 계단이 남지 않게.
    warp_x = (blob_noise(size, 26.0, 31) - 0.5) * 9.0
    warp_y = (blob_noise(size, 26.0, 32) - 0.5) * 9.0
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    warped = cv2.remap(walk, (xs + warp_x).astype(np.float32), (ys + warp_y).astype(np.float32),
                       interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    warped = cv2.GaussianBlur(warped, (0, 0), 2.2)
    soft = smoothstep(warped, 0.36, 0.64)

    ground = stone * soft[..., None] + moss * (1.0 - soft[..., None])

    # ---------- 화단(대나무·연못) 경계: 돌 턱 → 그림자 → 이끼
    beds = masks["beds"].astype(np.uint8)
    dist_bed = cv2.distanceTransform(1 - beds, cv2.DIST_L2, 5)      # 화단에서 떨어진 거리(화단=0)
    dist_walk = cv2.distanceTransform(masks["walk"].astype(np.uint8), cv2.DIST_L2, 5)
    bed_soft = cv2.GaussianBlur(beds.astype(np.float32), (0, 0), 2.0)
    # 화단 자체는 원화(이끼·양치)를 더 어둡게 깔아 길과 확실히 갈라 놓는다.
    ground = ground * (1.0 - bed_soft[..., None] * 0.55) + moss * (bed_soft[..., None] * 0.55)
    ground *= (1.0 - bed_soft[..., None] * 0.22)

    # 화단 바로 바깥(걸을 수 있는 쪽)을 밝은 화강석 턱으로 세운다.
    curb = np.clip(1.0 - dist_bed / 11.0, 0.0, 1.0) ** 0.8 * walk
    curb_stone = np.clip(stone * 1.22 + 0.055, 0.0, 1.0)
    ground = ground * (1.0 - curb[..., None] * 0.85) + curb_stone * (curb[..., None] * 0.85)
    # 턱과 화단 사이 한 줄 어두운 틈(경계를 또렷하게)
    seam = np.clip(1.0 - np.abs(dist_bed - 0.8) / 1.6, 0.0, 1.0) * walk
    ground = ground * (1.0 - seam[..., None] * 0.55)
    # 턱 바깥 접지 그림자
    cast = np.clip(1.0 - np.abs(dist_bed - 16.0) / 10.0, 0.0, 1.0) * walk
    ground = ground * (1.0 - cast[..., None] * 0.20)
    # 화단에서 길로 흘러나온 이끼 펄
    fringe = np.clip(1.0 - dist_bed / 34.0, 0.0, 1.0) ** 1.6 * walk
    fringe *= (0.25 + 0.9 * blob_noise(size, 46.0, 41))
    fringe = np.clip(cv2.GaussianBlur(fringe, (0, 0), 1.6), 0.0, 0.8)
    ground = ground * (1.0 - fringe[..., None] * 0.85) + moss * (fringe[..., None] * 0.85)

    # ---------- 담장 밑 그늘
    walls = masks["walls"].astype(np.uint8)
    dist_wall = cv2.distanceTransform(1 - walls, cv2.DIST_L2, 5)
    wall_shade = np.clip(1.0 - dist_wall / 26.0, 0.0, 1.0) ** 1.3
    ground = ground * (1.0 - wall_shade[..., None] * 0.10)
    # 담장이 놓인 자리는 돌 대신 어두운 기단
    wall_base = cv2.GaussianBlur(walls.astype(np.float32), (0, 0), 1.2)
    ground = ground * (1.0 - wall_base[..., None] * 0.12)

    # ---------- 평상·마루(낮은 장애물): 어두운 네모 대신 나무 판자로 깐다.
    wood = np.array([0.325, 0.245, 0.165], np.float32)
    for rect in geometry.get("low", []):
        x, y, w, h = rect
        x0, y0 = int(round(x)), int(round(y))
        x1, y1 = int(round(x + w)), int(round(y + h))
        x0 = max(0, x0); y0 = max(0, y0); x1 = min(width, x1); y1 = min(height, y1)
        if x1 <= x0 or y1 <= y0:
            continue
        # 바닥 그림자
        pad = 5
        sx0, sy0 = max(0, x0 - pad), max(0, y0 - pad + 4)
        sx1, sy1 = min(width, x1 + pad), min(height, y1 + pad + 4)
        ground[sy0:sy1, sx0:sx1] *= 0.72
        plank = np.ones((y1 - y0, x1 - x0, 3), np.float32) * wood
        grain = blob_noise((x1 - x0, y1 - y0), 18.0, 51)
        plank *= (0.85 + 0.35 * grain)[..., None]
        # 판자 이음매
        for step in range(6, x1 - x0, 18):
            plank[:, step:step + 1] *= 0.72
        plank[-2:, :] *= 0.75
        plank[:2, :] *= 1.35
        ground[y0:y1, x0:x1] = plank
        # 마루 위로 내리쬐는 달빛
        ground[y0:y1, x0:x1] += np.array([0.05, 0.045, 0.038], np.float32)

    # ---------- 길의 마모(롤처럼 또렷한 동선)
    medallion = (float(geometry["medallion"][0]), float(geometry["medallion"][1]))
    buildings = {b["id"]: b for b in geometry["buildings"]}
    routes = []
    for bid, via in (("cheongwol", [(600, 700), (745, 760)]),
                     ("seogo", [(1190, 690), (1010, 700)]),
                     ("byeolchae", [(520, 1090), (690, 960), (785, 835)])):
        door = tuple(buildings[bid]["door"])
        routes.append([door] + via + [medallion])
    bridge_a = tuple(geometry["bridge"]["a"])
    bridge_b = tuple(geometry["bridge"]["b"])
    routes.append([medallion, bridge_a])
    routes.append([bridge_b, (1275, 690), (1330, 640)])
    routes.append([medallion, (1100, 800), (1330, 800), (1500, 820)])
    routes.append([medallion, (900, 900), (900, 1060), (860, 1180)])
    wear = np.zeros((height, width), np.float32)
    for route in routes:
        wear = np.maximum(wear, draw_polyline_band(size, route, 96, 27))
    wear = smoothstep(wear * walk, 0.05, 0.85)
    ground = ground + wear[..., None] * np.array([0.085, 0.070, 0.044], np.float32)
    ground = ground * (1.0 + wear[..., None] * 0.16)

    # ---------- 연못가 돌 테두리 (물 위로 고인 달빛)
    pond = masks["pond"]
    ring_band = np.clip(1.0 - dist_walk / 12.0, 0.0, 1.0) * walk
    rim_stone = np.clip(stone * 1.16 + 0.03, 0.0, 1.0)
    ground = ground * (1.0 - ring_band[..., None] * 0.6) + rim_stone * (ring_band[..., None] * 0.5)
    pond_soft = cv2.GaussianBlur(pond.astype(np.float32), (0, 0), 3.0)
    water = np.array([0.028, 0.060, 0.080], np.float32)
    ground = ground * (1.0 - pond_soft[..., None] * 0.9) + water * (pond_soft[..., None] * 0.9)

    # ---------- 담장 밖: 밤 숲 그늘(지도 가장자리)
    courtyard = masks["courtyard"]
    outside = np.clip(1.0 - cv2.GaussianBlur(courtyard.astype(np.float32), (0, 0), 6.0), 0.0, 1.0) ** 0.8
    forest = moss * 0.5 + np.array([0.020, 0.034, 0.030], np.float32)
    silhouettes = np.zeros((height, width), np.float32)
    gen = rng(77)
    for _ in range(260):
        x = gen.uniform(0, width)
        y = gen.uniform(0, height)
        if courtyard[int(y), int(x)]:
            continue
        stalk = gen.uniform(40, 130)
        lean = gen.uniform(-10, 10)
        cv2.line(silhouettes, (int(x), int(y)), (int(x + lean), int(y - stalk)), 1.0, int(gen.integers(1, 3)))
    silhouettes = cv2.GaussianBlur(silhouettes, (0, 0), 1.2)
    forest = forest + silhouettes[..., None] * np.array([0.05, 0.09, 0.06], np.float32)
    ground = ground * (1.0 - outside[..., None]) + forest * outside[..., None]

    # ---------- 등불·문간 빛웅덩이
    light = np.zeros((height, width, 3), np.float32)
    warm_light = np.array([1.0, 0.70, 0.38], np.float32)
    for lx, ly in geometry["lanterns"]:
        light += draw_blob(size, (lx, ly - 8), 128, 2.3)[..., None] * warm_light * 0.34
    for building in geometry["buildings"]:
        door = building["door"]
        light += draw_blob(size, (door[0], door[1] - 24), 240, 2.0)[..., None] * warm_light * 0.20
    light *= walk[..., None] * 0.9 + 0.10
    ground = ground + light

    # ---------- 달빛 그라데이션·밤 색보정
    moon = draw_blob(size, (width * 0.78, height * 0.08), width * 1.0, 1.2)
    ground = ground * (0.95 + 0.13 * moon[..., None])
    ground[..., 2] *= 1.04
    ground[..., 0] *= 1.02
    glow_center = draw_blob(size, (width * 0.5, height * 0.52), width * 0.92, 3.0)
    ground = ground * (0.55 + 0.45 * glow_center[..., None])

    # ---------- 결 디테일: 큰 붓터치 위에 잔결을 얹어 또렷하게
    fine = blob_noise(size, 90.0, 61, 2)
    ground = ground * (0.95 + 0.10 * fine[..., None])
    # ---------- 미세 입자로 띠(banding) 제거
    grain = (rng(99).random((height, width, 1)).astype(np.float32) - 0.5) * 0.022
    ground = np.clip(ground + grain, 0.0, 1.0)
    out = (ground ** 1.02 * 255.0).astype(np.uint8)
    image = cv2.cvtColor(out, cv2.COLOR_RGB2BGR)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(OUT), image, [int(cv2.IMWRITE_PNG_COMPRESSION), 9])
    cv2.imwrite(str(PREVIEW), cv2.resize(image, (900, 700), interpolation=cv2.INTER_AREA))
    print("saved", OUT, OUT.stat().st_size // 1024, "KiB")


if __name__ == "__main__":
    bake()
