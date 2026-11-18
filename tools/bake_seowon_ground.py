#!/usr/bin/env python3
"""월하의 서원 바닥 통 원화(assets/woo/seowon/seowon_ground.png) 베이크.

2.0.26 비주얼 개편판. 시안(달빛 아래 추격전 지도)처럼
  · 달빛 잔디·이끼 바닥  · 밝은 판석 순환 돌길  · 건물 앞 흙마당
  · 중앙 팔각 돌마당     · 부드러운 접지 그림자
를 3400x2600 **1:1 해상도**로 합성한다. 0.62배로 줄였다 늘리지 않는다.
길·건물·연못 수치는 layout.gd에서 내보낸 geometry JSON을 그대로 따른다.

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
MASK_OUT = ROOT / "assets" / "woo" / "seowon" / "seowon_ground_mask.png"
DETAIL_GRASS = ROOT / "assets" / "woo" / "seowon" / "seowon_detail_grass.png"
DETAIL_STONE = ROOT / "assets" / "woo" / "seowon" / "seowon_detail_stone.png"
DETAIL_YARD = ROOT / "assets" / "woo" / "seowon" / "seowon_detail_yard.png"
BASE_SCALE = 0.7   # 색·조명 베이스는 절반 해상도(결 디테일은 타일 셰이더가 맡는다)
SEED = 20261119


def rng(tag: int) -> np.random.Generator:
    return np.random.default_rng(SEED + tag)


# ---------------------------------------------------------------- 재질
def read_rgb(path: Path) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise SystemExit(f"cannot read {path}")
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)


def mirror_tile(source: np.ndarray, size: tuple[int, int], scale: float, offset: tuple[float, float]) -> np.ndarray:
    """거울 반복으로 이음매 없이 평면을 채운다. 텍셀 1개 = 월드 1px(1:1)."""
    width, height = size
    h, w = source.shape[:2]
    if abs(scale - 1.0) > 0.001:
        image = cv2.resize(source, (max(2, int(round(w * scale))), max(2, int(round(h * scale)))),
                           interpolation=cv2.INTER_AREA if scale < 1.0 else cv2.INTER_CUBIC)
    else:
        image = source
    ih, iw = image.shape[:2]
    xs = (np.arange(width) + int(round(offset[0]))) % (2 * iw)
    xs = np.where(xs < iw, xs, 2 * iw - 1 - xs)
    ys = (np.arange(height) + int(round(offset[1]))) % (2 * ih)
    ys = np.where(ys < ih, ys, 2 * ih - 1 - ys)
    return image[ys][:, xs].copy()



def rotate_image(source: np.ndarray, angle: float) -> np.ndarray:
    if abs(angle) < 0.01:
        return source
    h, w = source.shape[:2]
    matrix = cv2.getRotationMatrix2D((w * 0.5, h * 0.5), angle, 1.0)
    cos, sin = abs(matrix[0, 0]), abs(matrix[0, 1])
    nw, nh = int(h * sin + w * cos), int(h * cos + w * sin)
    matrix[0, 2] += nw * 0.5 - w * 0.5
    matrix[1, 2] += nh * 0.5 - h * 0.5
    return cv2.warpAffine(source, matrix, (nw, nh), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)


def texture_layer(source: np.ndarray, size: tuple[int, int], scale: float, angle: float,
                  offset: tuple[float, float]) -> np.ndarray:
    """원화를 회전·축소해 1:1 텍셀로 거울 반복한다(이음매·눈에 띄는 반복 없이)."""
    rotated = rotate_image(source, angle)
    return mirror_tile(rotated, size, scale, offset).astype(np.float32) / 255.0


def levels(arr: np.ndarray, lo: float, hi: float, out_lo: float, out_hi: float) -> None:
    """입력 밝기 구간을 출력 구간으로 늘린다(판석 줄눈·잔디 결의 대비)."""
    arr -= lo
    arr *= (out_hi - out_lo) / max(1e-6, hi - lo)
    arr += out_lo


def tint(arr: np.ndarray, color) -> None:
    arr *= np.array(color, np.float32)


def mix_layers(a: np.ndarray, b: np.ndarray, t: float = 0.45) -> None:
    a *= (1.0 - t)
    a += b * t


def blob_noise(size: tuple[int, int], cells: float, tag: int, octaves: int = 3) -> np.ndarray:
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


# ---------------------------------------------------------------- 도형
def fill_rect(mask: np.ndarray, rect, grow: float = 0.0, value: int = 1) -> None:
    height, width = mask.shape[:2]
    x, y, w, h = rect
    x0 = max(0, int(np.floor(x - grow)))
    y0 = max(0, int(np.floor(y - grow)))
    x1 = min(width, int(np.ceil(x + w + grow)))
    y1 = min(height, int(np.ceil(y + h + grow)))
    if x1 > x0 and y1 > y0:
        mask[y0:y1, x0:x1] = value


def smooth_polyline(points, step: float = 26.0):
    """Catmull-Rom으로 점 사이를 부드럽게 잇는다(길이 각지지 않게)."""
    if len(points) < 3:
        return list(points)
    pts = [list(p) for p in points]
    out = []
    for i in range(len(pts) - 1):
        p0 = pts[max(0, i - 1)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(len(pts) - 1, i + 2)]
        seg = np.hypot(p2[0] - p1[0], p2[1] - p1[1])
        n = max(2, int(seg / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(tuple(pts[-1]))
    return out


def stroke_polyline(mask: np.ndarray, points, width: float, value: int = 255) -> None:
    points = smooth_polyline(points, max(10.0, width * 0.35))
    pts = np.array([[int(round(p[0])), int(round(p[1]))] for p in points], np.int32)
    cv2.polylines(mask, [pts], False, value, max(1, int(round(width))), lineType=cv2.LINE_AA)
    radius = max(1, int(round(width * 0.5)))
    for p in pts:
        cv2.circle(mask, (int(p[0]), int(p[1])), radius, value, -1, lineType=cv2.LINE_AA)


def octagon(center, radius: float, flat: float = 0.0):
    """팔각형 꼭짓점. flat>0이면 변을 살짝 눌러 정원에 가깝게."""
    pts = []
    for i in range(8):
        a = math_pi_over_8 + i * (math_pi_over_4)
        r = radius * (1.0 - flat * (i % 2))
        pts.append((center[0] + np.cos(a) * r, center[1] + np.sin(a) * r * 0.94))
    return np.array([[int(x), int(y)] for x, y in pts], np.int32)


math_pi_over_8 = np.pi / 8.0
math_pi_over_4 = np.pi / 4.0


def ellipse_polygon(center, size, count: int = 48) -> np.ndarray:
    a = np.linspace(0, 2 * np.pi, count, endpoint=False)
    xs = center[0] + np.cos(a) * size[0] * 0.5
    ys = center[1] + np.sin(a) * size[1] * 0.5
    return np.array([[int(x), int(y)] for x, y in zip(xs, ys)], np.int32)


# ---------------------------------------------------------------- 메인
def scale_geometry(geometry: dict, k: float) -> dict:
    def r(rect):
        return [rect[0] * k, rect[1] * k, rect[2] * k, rect[3] * k]

    def v(point):
        return [point[0] * k, point[1] * k]

    out = json.loads(json.dumps(geometry))
    out["size"] = v(geometry["size"])
    out["walk"] = r(geometry["walk"])
    out["pond"] = r(geometry["pond"])
    out["stone"] = r(geometry["stone"])
    out["medallion"] = v(geometry["medallion"])
    out["medallion_radius"] = float(geometry["medallion_radius"]) * k
    for key in ("hard", "low", "bamboo", "furniture", "walls"):
        out[key] = [r(item) for item in geometry.get(key, [])]
    out["bridge"] = {"a": v(geometry["bridge"]["a"]), "b": v(geometry["bridge"]["b"]),
                     "half": float(geometry["bridge"]["half"]) * k, "rise": float(geometry["bridge"]["rise"])}
    out["buildings"] = []
    for b in geometry.get("buildings", []):
        entry = dict(b)
        entry["rect"] = r(b["rect"])
        entry["interior"] = r(b["interior"])
        entry["door"] = v(b["door"])
        out["buildings"].append(entry)
    out["lanterns"] = [v(p) for p in geometry.get("lanterns", [])]
    out["trees"] = [v(p) for p in geometry.get("trees", [])]
    out["objects"] = [{"kind": o["kind"], "p": v(o["p"])} for o in geometry.get("objects", [])]
    out["paths"] = [{"w": float(p["w"]) * k, "p": [v(q) for q in p["p"]]} for p in geometry.get("paths", [])]
    return out


def bake() -> None:
    geometry = json.loads(GEOMETRY.read_text())
    full_width, full_height = int(geometry["size"][0]), int(geometry["size"][1])
    bake_scale = float(os.environ.get("BAKE_SCALE", "1"))
    width, height = int(full_width * bake_scale), int(full_height * bake_scale)
    size = (width, height)
    if abs(bake_scale - 1.0) > 0.001:
        geometry = scale_geometry(geometry, bake_scale)
    overflow = [-int(width * .1), -int(height * .1), width + int(width * .1), height + int(height * .1)]
    print(f"ground {width}x{height} (scale {bake_scale})")

    # ---------- 재질: 잔디(이끼·풀), 판석 돌, 흙마당
    moss = read_rgb(SRC / "moss_src.png")
    stone = read_rgb(SRC / "stone_src.png")

    grass = texture_layer(moss, size, 0.62, 0.0, (0, 0))
    grass2 = texture_layer(moss, size, 0.95, 63.0, (521, 233))
    mix_layers(grass, grass2, 0.42)
    del grass2
    levels(grass, 0.04, 0.62, 0.040, 0.44)
    grass *= np.array([0.92, 1.42, 1.00], np.float32)
    grass += np.array([0.022, 0.040, 0.028], np.float32)
    variation = blob_noise(size, 5.0, 11)
    variation *= 0.42
    variation += 0.80
    grass *= variation[..., None]
    del variation
    np.clip(grass, 0, 1, out=grass)

    paving = texture_layer(stone, size, 0.38, 11.0, (0, 0))
    paving2 = texture_layer(stone, size, 0.62, 78.0, (803, 617))
    mix_layers(paving, paving2, 0.40)
    del paving2
    # 판석 대비를 세워 이음매(줄눈)를 또렷하게.
    levels(paving, 0.24, 0.60, 0.34, 0.84)
    paving *= np.array([1.12, 1.02, 0.87], np.float32)
    slab_var = blob_noise(size, 30.0, 13, 2)
    slab_var *= 0.18
    slab_var += 0.91
    paving *= slab_var[..., None]
    del slab_var
    np.clip(paving, 0, 1, out=paving)

    yard = texture_layer(stone, size, 0.30, 27.0, (917, 431))
    levels(yard, 0.24, 0.60, 0.26, 0.62)
    yard *= np.array([1.16, 1.02, 0.82], np.float32)
    yard += np.array([0.05, 0.035, 0.015], np.float32)
    np.clip(yard, 0, 1, out=yard)

    plaza = texture_layer(stone, size, 0.50, -8.0, (313, 707))
    levels(plaza, 0.24, 0.60, 0.34, 0.82)
    plaza *= np.array([1.14, 1.04, 0.90], np.float32)
    np.clip(plaza, 0, 1, out=plaza)
    print("materials ready")

    # ---------- 마스크: 순환 돌길
    path_mask = np.zeros((height, width), np.uint8)
    for path in geometry.get("paths", []):
        stroke_polyline(path_mask, path["p"], path["w"], 255)
    # 유기적인 경계: 저주파로 흔든 뒤 부드럽게
    wx = (blob_noise(size, 22.0, 31) - 0.5) * 7.0
    wy = (blob_noise(size, 22.0, 32) - 0.5) * 7.0
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    warped = cv2.remap(path_mask, xs + wx, ys + wy, interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    del wx, wy, xs, ys, path_mask
    path_mask = (warped > 127).astype(np.uint8)
    del warped
    path_soft = cv2.GaussianBlur(path_mask.astype(np.float32), (0, 0), 1.0)
    path_alpha = smoothstep(path_soft, 0.34, 0.72)
    del path_soft
    dist_in = cv2.distanceTransform(path_mask, cv2.DIST_L2, 5)
    dist_out = cv2.distanceTransform(1 - path_mask, cv2.DIST_L2, 5)

    # ---------- 마스크: 건물 앞 흙마당
    yard_mask = np.zeros((height, width), np.uint8)
    for b in geometry["buildings"]:
        dx, dy = b["door"]
        cv2.fillPoly(yard_mask, [ellipse_polygon((dx, dy + 40), (310, 185))], 255)
    yard_soft = cv2.GaussianBlur(yard_mask.astype(np.float32) / 255.0, (0, 0), 20.0)
    yard_alpha = smoothstep(yard_soft, 0.12, 0.60) * 0.82
    del yard_soft, yard_mask

    # ---------- 마스크: 중앙 팔각 돌마당
    plaza_mask = np.zeros((height, width), np.uint8)
    mx, my = geometry["medallion"]
    radius = float(geometry["stone"][2]) * 0.5
    cv2.fillPoly(plaza_mask, [octagon((mx, my), radius)], 255)
    plaza_soft = cv2.GaussianBlur(plaza_mask.astype(np.float32), (0, 0), 3.0)
    plaza_alpha = smoothstep(plaza_soft, 0.30, 0.70)
    del plaza_soft
    plaza_dist = cv2.distanceTransform(plaza_mask, cv2.DIST_L2, 5)
    del plaza_mask

    # ---------- 합성: 잔디 → 흙마당 → 돌길 → 팔각 마당
    canvas = grass
    del grass
    canvas *= (1.0 - yard_alpha[..., None])
    canvas += yard * yard_alpha[..., None]
    del yard
    canvas *= (1.0 - path_alpha[..., None])
    canvas += paving * path_alpha[..., None]
    canvas *= (1.0 - plaza_alpha[..., None])
    canvas += plaza * plaza_alpha[..., None]
    del plaza
    # 마스크(길·흙마당·팔각 마당)는 셰이더 결 타일이 어디에 깔릴지 알려 준다.
    mask_scale = 0.25
    mask_w, mask_h = max(2, int(width * mask_scale)), max(2, int(height * mask_scale))
    mask_path = cv2.resize(np.clip(path_alpha + plaza_alpha, 0.0, 1.0), (mask_w, mask_h), interpolation=cv2.INTER_AREA)
    mask_yard = cv2.resize(np.clip(yard_alpha, 0.0, 1.0), (mask_w, mask_h), interpolation=cv2.INTER_AREA)
    mask_image = np.zeros((mask_h, mask_w, 3), np.uint8)
    mask_image[..., 2] = (mask_path * 255).astype(np.uint8)
    mask_image[..., 1] = (mask_yard * 255).astype(np.uint8)
    cv2.imwrite(str(MASK_OUT), mask_image)
    del mask_path, mask_yard, mask_image, yard_alpha

    # ---------- 길 가장자리 마감: 밝은 화강석 턱 → 어두운 틈 → 바깥 접지 그림자
    curb = np.clip(1.0 - dist_in / 9.0, 0.0, 1.0) ** 0.85
    curb *= (dist_in > 0.5)
    curb_stone = np.clip(paving * 1.30 + 0.075, 0.0, 1.0)
    canvas *= (1.0 - (curb * 0.80)[..., None])
    canvas += curb_stone * (curb * 0.80)[..., None]
    del curb_stone
    seam = np.clip(1.0 - np.abs(dist_in - 1.4) / 1.6, 0.0, 1.0)
    canvas *= (1.0 - (seam * 0.38)[..., None])
    cast = np.clip(1.0 - dist_out / 12.0, 0.0, 1.0) ** 1.5
    canvas *= (1.0 - (cast * 0.22)[..., None])
    del seam, cast

    # 팔각 마당 턱(돌길과 다른 한 단 높은 느낌)
    plaza_rim = np.clip(1.0 - plaza_dist / 14.0, 0.0, 1.0) ** 0.8 * (plaza_dist > 0.5)
    rim_light = np.clip(paving * 1.22 + 0.06, 0.0, 1.0)
    canvas *= (1.0 - (plaza_rim * 0.75)[..., None])
    canvas += rim_light * (plaza_rim * 0.75)[..., None]
    del rim_light, plaza_rim, plaza_dist

    # 길 한가운데는 사람이 다녀 닳아 밝다.
    worn = smoothstep(np.clip(dist_in / 56.0, 0.0, 1.0), 0.25, 1.0) * (dist_in > 0)
    canvas *= (1.0 + 0.10 * worn)[..., None]
    canvas += np.array([0.018, 0.016, 0.012], np.float32) * worn[..., None]
    del worn, dist_in, dist_out, paving

    # ---------- 연못: 돌 테두리 + 어두운 물밑(물 원화가 위를 덮는다)
    px, py, pw, ph = geometry["pond"]
    pond_mask = np.zeros((height, width), np.uint8)
    fill_rect(pond_mask, (px, py, pw, ph), 2.0)
    pond_mask_f = cv2.GaussianBlur(pond_mask.astype(np.float32), (0, 0), 2.0)
    water = np.array([0.050, 0.105, 0.135], np.float32)
    canvas *= (1.0 - pond_mask_f[..., None] * 0.92)
    canvas += water * (pond_mask_f[..., None] * 0.92)
    rim = np.zeros((height, width), np.uint8)
    fill_rect(rim, (px, py, pw, ph), 14.0)
    rim = np.clip(rim.astype(np.float32) - pond_mask.astype(np.float32), 0, 1)
    rim = cv2.GaussianBlur(rim, (0, 0), 3.0)
    canvas *= (1.0 + rim[..., None] * 0.20)
    del rim, pond_mask, pond_mask_f

    # ---------- 담장 밑: 화강석 기단 + 아래로 번지는 그림자
    wall_base = np.zeros((height, width), np.uint8)
    for rect in geometry.get("walls", []):
        fill_rect(wall_base, rect, 3.0)
    for rect in geometry.get("hard", [])[:6]:
        fill_rect(wall_base, rect, 5.0)
    wall_shadow = np.zeros((height, width), np.uint8)
    for rect in geometry.get("walls", []) + geometry.get("hard", [])[:6]:
        x, y, w, h = rect
        if w >= h:
            fill_rect(wall_shadow, (x, y + h, w, 16), 4.0)
        else:
            fill_rect(wall_shadow, (x, y, w + 16, h), 4.0)
    wall_shadow = cv2.GaussianBlur(wall_shadow.astype(np.float32), (0, 0), 7.0)
    wall_shadow = np.clip(wall_shadow, 0.0, 1.0) * (1.0 - wall_base.astype(np.float32))
    canvas *= (1.0 - (wall_shadow * 0.30)[..., None])
    del wall_shadow
    granite = np.array([0.40, 0.38, 0.42], np.float32)
    wall_alpha = cv2.GaussianBlur(wall_base.astype(np.float32), (0, 0), 1.4)
    canvas *= (1.0 - (wall_alpha * 0.75)[..., None])
    canvas += granite * (wall_alpha * 0.75)[..., None]
    del granite, wall_alpha, wall_base

    # ---------- 담장 밖: 밤 숲 그늘(검정이 아니라 짙은 초록)
    walk_mask = np.zeros((height, width), np.uint8)
    fill_rect(walk_mask, geometry["walk"], -8.0)
    inside_soft = cv2.GaussianBlur(walk_mask.astype(np.float32), (0, 0), 8.0)
    outside = np.clip(1.0 - inside_soft, 0.0, 1.0) ** 0.9
    forest_tint = np.array([0.55, 0.72, 0.60], np.float32)
    canvas *= (1.0 - outside[..., None] * 0.34)
    canvas *= np.where(outside[..., None] > 0.5, forest_tint, 1.0)
    del outside, inside_soft, walk_mask

    # ---------- 등불·문간 빛웅덩이(따뜻한 달빛)
    light = np.zeros((height, width), np.float32)
    for lx, ly in geometry["lanterns"]:
        add_blob(light, (lx, ly - 10), 150, 2.2, 0.26)
    for b in geometry["buildings"]:
        dx, dy = b["door"]
        add_blob(light, (dx, dy - 20), 240, 2.0, 0.17)
    light *= 0.92
    canvas += light[..., None] * np.array([1.0, 0.66, 0.34], np.float32)
    del light

    # ---------- 벚꽃잎: 나무 밑 잔디에 흩어진 꽃잎
    petals = np.zeros((height, width), np.float32)
    for tx, ty in geometry.get("trees", []):
        add_blob(petals, (tx, ty + 30), 190, 1.4, 0.55)
    petal_noise = blob_noise(size, 90.0, 71, 1)
    petal_mask = np.clip(petals - (1.0 - petal_noise) * 0.62, 0.0, 1.0)
    del petals, petal_noise
    petal_mask *= (1.0 - np.clip(path_alpha + plaza_alpha, 0.0, 1.0))
    canvas *= (1.0 - petal_mask[..., None] * 0.10)
    canvas += petal_mask[..., None] * np.array([0.16, 0.055, 0.10], np.float32)
    del petal_mask, path_alpha, plaza_alpha

    # ---------- 달빛·밤 색보정
    moon = draw_blob(size, (width * 0.80, height * 0.06), width * 0.95, 1.1)
    canvas *= (0.96 + 0.12 * moon)[..., None]
    del moon
    center_glow = draw_blob(size, (mx, my), width * 0.62, 2.6)
    canvas *= (0.92 + 0.16 * center_glow)[..., None]
    del center_glow
    grain = (rng(99).random((height, width, 1)).astype(np.float32) - 0.5) * 0.020
    canvas += grain
    del grain
    np.clip(canvas, 0.0, 1.0, out=canvas)
    canvas -= 0.5
    canvas *= 1.10
    canvas += 0.5
    np.clip(canvas, 0.0, 1.0, out=canvas)
    out = (canvas ** 0.96 * 255.0).astype(np.uint8)
    del canvas
    base = cv2.resize(out, (max(2, int(out.shape[1] * BASE_SCALE)), max(2, int(out.shape[0] * BASE_SCALE))),
                      interpolation=cv2.INTER_AREA)
    del out
    image = cv2.cvtColor(base, cv2.COLOR_RGB2BGR)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(OUT), image, [int(cv2.IMWRITE_PNG_COMPRESSION), 9])
    cv2.imwrite(str(PREVIEW), cv2.resize(image, (1100, int(1100 * full_height / full_width)), interpolation=cv2.INTER_AREA))
    print("saved base", OUT, image.shape, OUT.stat().st_size // 1024, "KiB")


def add_blob(target: np.ndarray, center, radius: float, falloff: float = 2.2, amount: float = 1.0) -> None:
    """한 점에서 번지는 빛을 해당 영역에만 더한다(큰 배열을 새로 만들지 않는다)."""
    height, width = target.shape[:2]
    r = int(radius) + 2
    x0 = max(0, int(center[0]) - r)
    x1 = min(width, int(center[0]) + r)
    y0 = max(0, int(center[1]) - r)
    y1 = min(height, int(center[1]) + r)
    if x1 <= x0 or y1 <= y0:
        return
    ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    d = np.sqrt((xs - center[0]) ** 2 + (ys - center[1]) ** 2) / max(1.0, radius)
    target[y0:y1, x0:x1] += np.clip(1.0 - d, 0.0, 1.0) ** falloff * amount


def draw_blob(size, center, radius, falloff: float = 2.2) -> np.ndarray:
    out = np.zeros((size[1], size[0]), np.float32)
    add_blob(out, center, radius, falloff, 1.0)
    return out


def write_detail_tiles() -> None:
    """셰이더가 1:1로 반복해 쓸 결 타일(평균 1.0으로 정규화한 밝기 결)."""
    for src_name, out_path, crop in (
        ("moss_src.png", DETAIL_GRASS, (300, 300)),
        ("stone_src.png", DETAIL_STONE, (250, 420)),
        ("stone_src.png", DETAIL_YARD, (620, 90)),
    ):
        image = read_rgb(SRC / src_name)
        h, w = image.shape[:2]
        x, y = crop
        tile = image[y:y + 512, x:x + 512]
        if tile.shape[0] != 512 or tile.shape[1] != 512:
            tile = cv2.resize(tile, (512, 512), interpolation=cv2.INTER_CUBIC)
        f = tile.astype(np.float32) / 255.0
        # 돌 타일에 섞인 분홍 꽃잎은 회색으로 눕힌다(길 위 분홍 얼룩 방지).
        pink = (f[..., 0] > f[..., 1] + 0.06) & (f[..., 0] > 0.35)
        f[pink] = f[pink].mean(axis=1, keepdims=True)
        mean = f.reshape(-1, 3).mean(axis=0)
        detail = np.clip(f / np.maximum(mean, 1e-3), 0.55, 1.75)
        # 평균 1.0, 대비는 살짝 눌러 과한 얼룩을 막는다.
        detail = 1.0 + (detail - 1.0) * 0.85
        out = np.clip(detail / np.maximum(detail.reshape(-1, 3).mean(axis=0), 1e-3) * 128.0, 0, 255).astype(np.uint8)
        cv2.imwrite(str(out_path), cv2.cvtColor(out, cv2.COLOR_RGB2BGR))
        print("detail", out_path.name)


if __name__ == "__main__":
    write_detail_tiles()
    bake()
