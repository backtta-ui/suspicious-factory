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
import os
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
    # 마을 안쪽(걸을 수 있는 범위)만 달빛 마당으로 밝히고 바깥은 밤 숲 그늘.
    fill_rect(courtyard, geometry["walk"])
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
def scale_geometry(geometry: dict, k: float) -> dict:
    """월드 좌표계 geometry를 베이크 픽셀 좌표로 줄인다(메모리 절약용)."""
    def r(rect):
        return [rect[0] * k, rect[1] * k, rect[2] * k, rect[3] * k]

    def v(point):
        return [point[0] * k, point[1] * k]

    out = json.loads(json.dumps(geometry))
    out["size"] = v(geometry["size"])
    out["walk"] = r(geometry["walk"])
    out["pond"] = r(geometry["pond"])
    out["stone"] = r(geometry["stone"])
    out["stand_margin"] = float(geometry.get("stand_margin", 9.0)) * k
    for key in ("hard", "low", "bamboo", "furniture", "walls"):
        out[key] = [r(item) for item in geometry.get(key, [])]
    out["bridge"] = {"a": v(geometry["bridge"]["a"]), "b": v(geometry["bridge"]["b"]),
                     "half": float(geometry["bridge"]["half"]) * k, "rise": float(geometry["bridge"]["rise"])}
    out["medallion"] = v(geometry["medallion"])
    out["medallion_radius"] = float(geometry["medallion_radius"]) * k
    out["buildings"] = []
    for b in geometry.get("buildings", []):
        entry = dict(b)
        entry["rect"] = r(b["rect"])
        entry["interior"] = r(b["interior"])
        entry["door"] = v(b["door"])
        entry["back"] = v(b["back"])
        entry["painted_door"] = v(b["painted_door"])
        out["buildings"].append(entry)
    out["doors"] = [{"id": d["id"], "center": v(d["center"]), "side": d["side"]} for d in geometry.get("doors", [])]
    out["lanterns"] = [v(p) for p in geometry.get("lanterns", [])]
    out["trees"] = [v(p) for p in geometry.get("trees", [])]
    out["objects"] = [{"kind": o["kind"], "p": v(o["p"])} for o in geometry.get("objects", [])]
    out["path"] = [v(p) for p in geometry.get("path", [])]
    return out


def bake() -> None:
    geometry = load_geometry()
    full_width, full_height = int(geometry["size"][0]), int(geometry["size"][1])
    # 메모리가 좁은 환경에서도 베이크되도록 축소 픽셀로 합성한 뒤 마지막에 원래 크기로 늘린다.
    bake_scale = float(os.environ.get("BAKE_SCALE", "1"))
    width, height = int(full_width * bake_scale), int(full_height * bake_scale)
    size = (width, height)
    if abs(bake_scale - 1.0) > 0.001:
        geometry = scale_geometry(geometry, bake_scale)
    print(f"ground {width}x{height} (scale {bake_scale})")

    stone_src = read_rgb(SRC / "stone_src.png")
    stone_warm = read_rgb(SRC / "stone_warm_src.png")
    moss_src = read_rgb(SRC / "moss_src.png")

    # 재질: 서로 다른 돌 원화를 큰 배율로 깔고 저주파 얼룩으로 섞는다.
    # 3채널 float 배열 한 장이 100MB가 넘으므로 모두 in-place로 합성한다.
    stone = cover(stone_src, size, angle=0.0, zoom=1.45)
    stone_b = cover(stone_warm, size, angle=17.0, zoom=1.22)
    mix = smoothstep(blob_noise(size, 2.6, 11), 0.22, 0.78)[..., None]
    tmp = stone_b * mix
    del stone_b
    stone *= (1.0 - mix)
    stone += tmp
    del tmp, mix
    shade_noise = blob_noise(size, 4.0, 12)
    shade_noise *= 0.26
    shade_noise += 0.90
    stone *= shade_noise[..., None]
    del shade_noise
    stone *= 1.40
    stone += np.array([0.040, 0.040, 0.046], np.float32)
    np.clip(stone, 0.0, 1.0, out=stone)

    moss = cover(moss_src, size, angle=0.0, zoom=1.0)
    moss_b = cover(moss_src, size, angle=-24.0, zoom=1.1)
    moss_mix = smoothstep(blob_noise(size, 3.0, 21), 0.25, 0.75)[..., None]
    tmp = moss_b * moss_mix
    del moss_b
    moss *= (1.0 - moss_mix)
    moss += tmp
    del tmp, moss_mix
    # 화단은 밤 그늘: 어둡고 차갑게, 초록은 살짝 남긴다.
    moss *= np.array([0.26, 0.36, 0.30], np.float32)
    moss += np.array([0.010, 0.024, 0.026], np.float32)
    moss_noise = blob_noise(size, 6.0, 22)
    moss_noise *= 0.45
    moss_noise += 0.70
    moss *= moss_noise[..., None]
    del moss_noise
    np.clip(moss, 0.0, 1.0, out=moss)
    del moss_src, stone_src, stone_warm
    print(f"materials ready")

    masks = build_masks(geometry, size)
    walk = masks["walk"].astype(np.float32)

    # 경계를 노이즈로 흔들고 부드럽게: 20px 칸 같은 각진 계단이 남지 않게.
    warp_x = (blob_noise(size, 26.0, 31) - 0.5) * 9.0
    warp_y = (blob_noise(size, 26.0, 32) - 0.5) * 9.0
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    warped = cv2.remap(walk, (xs + warp_x).astype(np.float32), (ys + warp_y).astype(np.float32),
                       interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    del xs, ys, warp_x, warp_y, walk
    warped = cv2.GaussianBlur(warped, (0, 0), 2.2)
    soft = smoothstep(warped, 0.36, 0.64)
    del warped

    # 3채널 float 배열은 한 장이 100MB가 넘는다. 임시 배열을 바로 비우며 in-place로 합성한다.
    def over(base: np.ndarray, top: np.ndarray, alpha: np.ndarray) -> None:
        """base = base*(1-alpha) + top*alpha (alpha는 3채널 float32)."""
        tmp = top * alpha
        base *= (1.0 - alpha)
        base += tmp
        del tmp

    ground = stone
    # soft = 걸을 수 있는 돌마당(1) / 화단(0). 화단 쪽에만 이끼를 섞는다.
    moss_alpha = (1.0 - soft)[..., None]
    over(ground, moss, moss_alpha)
    del soft, moss_alpha

    # ---------- 화단(대나무·연못) 경계: 돌 턱 → 그림자 → 이끼
    beds = masks["beds"].astype(np.uint8)
    dist_bed = cv2.distanceTransform(1 - beds, cv2.DIST_L2, 5)      # 화단에서 떨어진 거리(화단=0)
    dist_walk = cv2.distanceTransform(masks["walk"].astype(np.uint8), cv2.DIST_L2, 5)
    bed_soft = cv2.GaussianBlur(beds.astype(np.float32), (0, 0), 2.0)
    bed_alpha = (bed_soft * 0.55)[..., None]
    over(ground, moss, bed_alpha)
    del bed_alpha
    ground *= (1.0 - bed_soft[..., None] * 0.22)

    # 화단 바로 바깥(걸을 수 있는 쪽)을 밝은 화강석 턱으로 세운다.
    curb = np.clip(1.0 - dist_bed / 11.0, 0.0, 1.0) ** 0.8 * masks["walk"]
    curb_stone = np.clip(stone * 1.22 + 0.055, 0.0, 1.0)
    over(ground, curb_stone, (curb * 0.85)[..., None])
    del curb_stone
    # 턱과 화단 사이 한 줄 어두운 틈(경계를 또렷하게)
    seam = np.clip(1.0 - np.abs(dist_bed - 0.8) / 1.6, 0.0, 1.0) * masks["walk"]
    ground *= (1.0 - (seam * 0.55)[..., None])
    # 턱 바깥 접지 그림자
    cast = np.clip(1.0 - np.abs(dist_bed - 16.0) / 10.0, 0.0, 1.0) * masks["walk"]
    ground *= (1.0 - (cast * 0.20)[..., None])
    # 화단에서 길로 흘러나온 이끼 펄
    fringe = np.clip(1.0 - dist_bed / 34.0, 0.0, 1.0) ** 1.6 * masks["walk"]
    fringe *= (0.25 + 0.9 * blob_noise(size, 46.0, 41))
    fringe = np.clip(cv2.GaussianBlur(fringe, (0, 0), 1.6), 0.0, 0.8)
    over(ground, moss, (fringe * 0.85)[..., None])
    del fringe, curb, seam, cast, dist_bed

    # ---------- 담장 밑 그늘
    walls = masks["walls"].astype(np.uint8)
    dist_wall = cv2.distanceTransform(1 - walls, cv2.DIST_L2, 5)
    wall_shade = np.clip(1.0 - dist_wall / 26.0, 0.0, 1.0) ** 1.3
    ground *= (1.0 - (wall_shade * 0.10)[..., None])
    wall_base = cv2.GaussianBlur(walls.astype(np.float32), (0, 0), 1.2)
    ground *= (1.0 - (wall_base * 0.12)[..., None])
    del dist_wall, wall_shade, wall_base, walls

    # ---------- 평상·마루(낮은 장애물): 어두운 네모 대신 나무 판자로 깐다.
    wood = np.array([0.325, 0.245, 0.165], np.float32)
    for rect in geometry.get("low", []):
        x, y, w, h = rect
        x0, y0 = int(round(x)), int(round(y))
        x1, y1 = int(round(x + w)), int(round(y + h))
        x0 = max(0, x0); y0 = max(0, y0); x1 = min(width, x1); y1 = min(height, y1)
        if x1 <= x0 or y1 <= y0:
            continue
        pad = 5
        sx0, sy0 = max(0, x0 - pad), max(0, y0 - pad + 4)
        sx1, sy1 = min(width, x1 + pad), min(height, y1 + pad + 4)
        ground[sy0:sy1, sx0:sx1] *= 0.72
        plank = np.ones((y1 - y0, x1 - x0, 3), np.float32) * wood
        grain = blob_noise((x1 - x0, y1 - y0), 18.0, 51)
        plank *= (0.85 + 0.35 * grain)[..., None]
        for step in range(6, x1 - x0, 18):
            plank[:, step:step + 1] *= 0.72
        plank[-2:, :] *= 0.75
        plank[:2, :] *= 1.35
        ground[y0:y1, x0:x1] = plank
        ground[y0:y1, x0:x1] += np.array([0.05, 0.045, 0.038], np.float32)
        del plank, grain

    # ---------- 길의 마모(롤처럼 또렷한 동선)
    medallion = (float(geometry["medallion"][0]), float(geometry["medallion"][1]))
    routes = []
    for building in geometry["buildings"]:
        routes.append([tuple(building["door"]), medallion])
    bridge_a = tuple(geometry["bridge"]["a"])
    bridge_b = tuple(geometry["bridge"]["b"])
    routes.append([medallion, bridge_a])
    routes.append([bridge_b, (3000, 1000), (2900, 1080)])
    routes.append([medallion, (1700, 1040), (1700, 990)])
    routes.append([medallion, (1700, 1700), (1700, 1780)])
    routes.append([medallion, (1100, 1360), (1040, 1360)])
    routes.append([medallion, (2300, 1360), (2420, 1360)])
    routes.append([(1700, 990), (2420, 990), (2420, 500)])
    routes.append([(1700, 1780), (2420, 1780), (2420, 2200)])
    routes.append([(1040, 1360), (700, 1360), (620, 1000)])
    wear = np.zeros((height, width), np.float32)
    for route in routes:
        band = draw_polyline_band(size, route, 92, 34)
        np.maximum(wear, band, out=wear)
        del band
    wear = smoothstep(wear * masks["walk"], 0.10, 0.90)
    ground += wear[..., None] * np.array([0.055, 0.046, 0.030], np.float32)
    ground *= (1.0 + wear[..., None] * 0.10)
    del wear

    # ---------- 연못가 돌 테두리 (물 위로 고인 달빛)
    pond = masks["pond"]
    ring_band = (np.clip(1.0 - dist_walk / 12.0, 0.0, 1.0) * masks["walk"] * 0.6)[..., None]
    rim_stone = np.clip(stone * 1.16 + 0.03, 0.0, 1.0)
    over(ground, rim_stone, ring_band)
    del rim_stone, ring_band, dist_walk
    pond_soft = cv2.GaussianBlur(pond.astype(np.float32), (0, 0), 3.0)
    water = np.array([0.028, 0.060, 0.080], np.float32)
    over(ground, np.broadcast_to(water, ground.shape).copy(), (pond_soft * 0.9)[..., None])
    del pond_soft

    # ---------- 담장 밖: 밤 숲 그늘(지도 가장자리)
    courtyard = masks["courtyard"]
    outside = np.clip(1.0 - cv2.GaussianBlur(courtyard.astype(np.float32), (0, 0), 6.0), 0.0, 1.0) ** 0.8
    forest = moss * 0.72 + np.array([0.030, 0.046, 0.040], np.float32)
    del moss
    silhouettes = np.zeros((height, width), np.float32)
    gen = rng(77)
    for _ in range(420):
        x = gen.uniform(0, width)
        y = gen.uniform(0, height)
        if courtyard[int(y), int(x)]:
            continue
        stalk = gen.uniform(40, 130)
        lean = gen.uniform(-10, 10)
        cv2.line(silhouettes, (int(x), int(y)), (int(x + lean), int(y - stalk)), 1.0, int(gen.integers(1, 3)))
    silhouettes = cv2.GaussianBlur(silhouettes, (0, 0), 1.2)
    forest += silhouettes[..., None] * np.array([0.05, 0.09, 0.06], np.float32)
    del silhouettes
    over(ground, forest, outside[..., None])
    del forest, outside, courtyard

    # ---------- 등불·문간 빛웅덩이
    light = np.zeros((height, width), np.float32)
    for lx, ly in geometry["lanterns"]:
        light += draw_blob(size, (lx, ly - 8), 150, 2.3) * 0.34
    for building in geometry["buildings"]:
        door = building["door"]
        light += draw_blob(size, (door[0], door[1] - 24), 260, 2.0) * 0.20
    light *= masks["walk"] * 0.9 + 0.10
    ground += light[..., None] * np.array([1.0, 0.70, 0.38], np.float32)
    del light

    # ---------- 달빛 그라데이션·밤 색보정
    moon = draw_blob(size, (width * 0.78, height * 0.08), width * 1.0, 1.2)
    ground *= (0.95 + 0.13 * moon)[..., None]
    del moon
    ground[..., 2] *= 1.04
    ground[..., 0] *= 1.02
    glow_center = draw_blob(size, (width * 0.5, height * 0.52), width * 0.92, 3.0)
    ground *= (0.74 + 0.28 * glow_center)[..., None]
    del glow_center

    # ---------- 결 디테일: 큰 붓터치 위에 잔결을 얹어 또렷하게
    fine = blob_noise(size, 120.0, 61, 2)
    ground *= (0.95 + 0.10 * fine)[..., None]
    del fine
    # ---------- 미세 입자로 띠(banding) 제거
    grain = (rng(99).random((height, width, 1)).astype(np.float32) - 0.5) * 0.022
    ground += grain
    del grain
    np.clip(ground, 0.0, 1.0, out=ground)
    out = (ground ** 1.02 * 255.0).astype(np.uint8)
    del ground
    if (width, height) != (full_width, full_height):
        out = cv2.resize(out, (full_width, full_height), interpolation=cv2.INTER_LANCZOS4)
    image = cv2.cvtColor(out, cv2.COLOR_RGB2BGR)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(OUT), image, [int(cv2.IMWRITE_PNG_COMPRESSION), 9])
    cv2.imwrite(str(PREVIEW), cv2.resize(image, (900, 700), interpolation=cv2.INTER_AREA))
    print("saved", OUT, OUT.stat().st_size // 1024, "KiB")


if __name__ == "__main__":
    bake()
