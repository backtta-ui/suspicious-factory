#!/usr/bin/env python3
"""2.0.39 카툰 타일/건물 아틀라스 생성기.

네 맵의 지붕·벽·바닥에 쓰는 512px 타일 12종을 그려
`assets/woo/v39/atlas_v39.png`(2048x1536, 512 격자 4x3)로 묶고,
같은 그림을 `assets/woo/v39/tiles/<name>.png`로도 저장한다.

- 아틀라스: 원화 원본·프레임 목록(atlas_v39.json)
- 개별 타일: Godot에서 draw_texture_rect(tile=true) 1 draw call로 반복
모든 타일은 이음새 없이 반복되도록 가장자리를 감아 그린다.
"""
import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "woo", "v39")
TILES = os.path.join(OUT, "tiles")
S = 512          # 최종 타일 크기
R = 2            # 슈퍼샘플 배수
C = S * R        # 작업 캔버스
rng = random.Random(2039)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def rgb(hexstr):
    h = hexstr.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def periodic_noise(size, cells, amp, seed):
    """타일 경계에서도 이어지는 부드러운 노이즈(0..1)."""
    r = np.random.RandomState(seed)
    grid = r.rand(cells, cells)
    grid = np.vstack([grid, grid[:1]])
    grid = np.hstack([grid, grid[:, :1]])
    ys = np.linspace(0, cells, size, endpoint=False)
    xs = np.linspace(0, cells, size, endpoint=False)
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = grid[y0][:, x0]
    b = grid[y0][:, x0 + 1]
    c = grid[y0 + 1][:, x0]
    d = grid[y0 + 1][:, x0 + 1]
    out = (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy
    return (out * amp)


def grain(size, amp, seed):
    r = np.random.RandomState(seed)
    return (r.rand(size, size) - 0.5) * amp


def base_layer(color, seed, noise=10, blotch=0.0, blotch_cells=3):
    arr = np.zeros((C, C, 3), dtype=np.float32)
    for i in range(3):
        arr[:, :, i] = color[i]
    if blotch > 0:
        n = periodic_noise(C, blotch_cells, 1.0, seed + 7)
        arr += (n[:, :, None] - 0.5) * blotch
    arr += grain(C, noise, seed)[:, :, None]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


def wrap_xy(x, y):
    for dx in (0, -C, C):
        for dy in (0, -C, C):
            yield x + dx, y + dy


def finish(img, blur=0.6):
    img = img.filter(ImageFilter.GaussianBlur(blur)) if blur else img
    return img.resize((S, S), Image.LANCZOS)


def shade_edges(img, strength=0.10):
    """타일 안쪽 가장자리를 살짝 어둡게(AO) — 반복해도 깊이가 남는다."""
    arr = np.asarray(img).astype(np.float32)
    yy, xx = np.mgrid[0:C, 0:C]
    d = np.minimum(np.minimum(xx, C - 1 - xx), np.minimum(yy, C - 1 - yy)) / C
    v = 1.0 - strength * np.exp(-d * 26.0)
    arr *= v[:, :, None]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


# ---------------------------------------------------------------- 지붕 기와
def roof_giwa():
    img = base_layer((50, 61, 86), 11, noise=6, blotch=14, blotch_cells=3)
    d = ImageDraw.Draw(img, "RGBA")
    rows = 8
    cols = 8
    row_h = C // rows
    tile_w = C // cols
    for row in range(rows):
        y = row * row_h
        off = (tile_w // 2) if row % 2 else 0
        # 기와 골(행 사이 그늘)
        d.rectangle([0, y + row_h - row_h * 0.16, C, y + row_h], fill=(9, 13, 23, 170))
        for i in range(cols + 1):
            x = i * tile_w + off
            for px, py in wrap_xy(x, y):
                top = py + row_h * 0.06
                bot = py + row_h * 0.94
                # 볼록 기와 몸통: 왼쪽 밝고 오른쪽 어두운 원통
                steps = 14
                for k in range(steps):
                    t = k / (steps - 1.0)
                    x0 = px + 3 + (tile_w - 6) * (k / steps)
                    x1 = px + 3 + (tile_w - 6) * ((k + 1) / steps)
                    lit = 1.0 - abs(t - 0.32) * 1.55
                    col = lerp((36, 45, 66), (128, 144, 178), max(0.0, lit))
                    d.rectangle([x0, top + row_h * 0.10, x1, bot - row_h * 0.12], fill=col + (255,))
                # 기와 머리(둥근 끝, 수막새)
                cx = px + tile_w * 0.5
                cy = bot - row_h * 0.20
                rr = tile_w * 0.34
                d.ellipse([cx - rr, cy - rr * .9, cx + rr, cy + rr * .9], fill=(38, 47, 68, 245), outline=(12, 16, 27, 240), width=4)
                d.arc([cx - rr + 5, cy - rr * .9 + 5, cx + rr - 5, cy + rr * .9 - 5], 195, 330, fill=(150, 168, 202, 200), width=4)
                d.ellipse([cx - rr * .26, cy - rr * .26, cx + rr * .26, cy + rr * .26], fill=(20, 26, 40, 245))
                # 기와 사이 골 그림자
                d.line([(px + 2, top + row_h * 0.08), (px + 2, bot)], fill=(9, 12, 20, 210), width=3)
                d.line([(px + tile_w - 2, top + row_h * 0.08), (px + tile_w - 2, bot)], fill=(9, 12, 20, 210), width=3)
        # 행 이음 하이라이트
        d.line([(0, y + 3), (C, y + 3)], fill=(156, 172, 204, 95), width=2)
    for _ in range(60):
        x, y = rng.randrange(C), rng.randrange(C)
        rr = rng.uniform(2, 8) * R
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(72, 94, 76, rng.randrange(18, 55)))
    img = shade_edges(img, 0.08)
    return finish(img, 0.7)


def roof_slate():
    img = base_layer((45, 50, 66), 21, noise=6, blotch=8, blotch_cells=4)
    d = ImageDraw.Draw(img, "RGBA")
    row_h = C // 21
    sh_w = C // 8
    for row in range(21):
        y = row * row_h
        off = (sh_w // 2) if row % 2 else 0
        for i in range(9):
            x = i * sh_w + off
            tone = rng.uniform(-14, 14)
            col = tuple(int(max(0, min(255, c + tone))) for c in (62, 69, 90))
            for px, py in wrap_xy(x, y):
                d.rectangle([px + 1, py, px + sh_w - 2, py + row_h - 1], fill=col + (255,))
                d.line([(px + 1, py + 1), (px + sh_w - 2, py + 1)], fill=(126, 138, 166, 120), width=2)
                d.line([(px + 1, py + row_h - 2), (px + sh_w - 2, py + row_h - 2)], fill=(12, 15, 24, 200), width=3)
                d.line([(px + 1, py + 2), (px + 1, py + row_h - 3)], fill=(20, 24, 36, 160), width=2)
        d.line([(0, y), (C, y)], fill=(140, 152, 180, 70), width=2)
    for _ in range(40):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(4, 14) * R, y + rng.uniform(2, 6) * R], fill=(24, 27, 38, rng.randrange(30, 70)))
    return finish(shade_edges(img, 0.07), 0.6)


def roof_slate2():
    """한옥 기와: 이엉 + 수막새 + 가래목 + 끝기와."""
    img = base_layer((47, 56, 78), 12, noise=6, blotch=16, blotch_cells=3)
    d = ImageDraw.Draw(img, "RGBA")
    rows = 7          # 이엉 줄
    cols = 8
    row_h = C // rows
    col_w = C // cols
    # 1) 바탕: 이엉 흙과 가래목(나무 판)
    for row in range(rows):
        y = row * row_h
        d.rectangle([0, y, C, y + row_h], fill=(70, 62, 46, 255))
        # 가래목 결
        for k in range(3):
            gy = y + row_h * (0.2 + 0.3 * k)
            d.line([(0, gy), (C, gy)], fill=(56, 48, 36, 220), width=3)
            d.line([(0, gy + 2), (C, gy + 2)], fill=(88, 76, 56, 120), width=2)
        for k in range(3):
            gx = rng.uniform(0, C)
            d.ellipse([gx, gy - 3 * R, gx + 5 * R, gy + 3 * R], fill=(46, 40, 30, 200))
    # 2) 기와 덮개(각 칸에 반원 오목 곡면, 위-아래가 겹치는 이엉)
    for row in range(rows + 1):
        y = row * row_h - row_h // 2
        for i in range(cols + 1):
            x = i * col_w
            for px, py in wrap_xy(x, y):
                # 반원 곡면: 세로 단면이 포물선
                steps = 12
                for k in range(steps):
                    t = k / (steps - 1.0)
                    yy = py + row_h * t
                    # 곡률: 양끝 어둡고 가운데 밝다
                    curve = 1.0 - abs(t - 0.45) * 1.9
                    col = lerp((26, 33, 50), (128, 146, 182), max(0.0, curve))
                    d.rectangle([px - col_w * 0.42, yy, px + col_w * 0.42, yy + row_h / steps + 1], fill=col + (255,))
                # 기와 이음 세로 골
                d.line([(px - col_w * 0.42, py), (px - col_w * 0.42, py + row_h)], fill=(10, 14, 24, 200), width=3)
                d.line([(px + col_w * 0.42, py), (px + col_w * 0.42, py + row_h)], fill=(10, 14, 24, 200), width=3)
                # 수막새(끝이 내린 기와 머리)
                cx = px
                cy = py + row_h * 0.98
                rw = col_w * 0.44
                rh = row_h * 0.24
                d.chord([cx - rw, cy - rh, cx + rw, cy + rh], 0, 180, fill=(50, 62, 90, 255), outline=(10, 13, 22, 240), width=3)
                d.arc([cx - rw + 4, cy - rh + 2, cx + rw - 4, cy + rh], 190, 350, fill=(148, 166, 200, 170), width=3)
    # 3) 이끼
    for _ in range(60):
        x, y = rng.randrange(C), rng.randrange(C)
        rr = rng.uniform(2, 7) * R
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(64, 88, 70, rng.randrange(16, 48)))
    return finish(shade_edges(img, 0.07), 0.6)


def roof_metal():
    img = base_layer((66, 76, 92), 31, noise=5, blotch=6, blotch_cells=3)
    d = ImageDraw.Draw(img, "RGBA")
    panel = C // 7
    for i in range(8):
        x = i * panel
        d.rectangle([x, 0, x + panel - 1, C], fill=(58, 67, 84, 255))
        d.rectangle([x + 4, 0, x + panel - 10, C], fill=(78, 90, 110, 255))
        # sheen
        d.rectangle([x + panel * .28, 0, x + panel * .40, C], fill=(118, 134, 158, 70))
        # standing seam
        d.line([(x, 0), (x, C)], fill=(26, 31, 44, 235), width=4)
        d.line([(x + 3, 0), (x + 3, C)], fill=(150, 166, 196, 120), width=2)
        # screws
        for k in range(6):
            sy = k * (C // 6) + C // 12
            d.ellipse([x + panel * .70, sy, x + panel * .70 + 6 * R, sy + 6 * R], fill=(34, 40, 54, 220))
    for _ in range(26):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(6, 20) * R, y + rng.uniform(4, 12) * R], fill=(96, 74, 58, rng.randrange(18, 45)))
    return finish(shade_edges(img, 0.06), 0.6)


def roof_shingle():
    img = base_layer((74, 55, 47), 41, noise=7, blotch=12, blotch_cells=4)
    d = ImageDraw.Draw(img, "RGBA")
    rib = C // 16
    for i in range(17):
        x = i * rib
        for px, _ in wrap_xy(x, 0):
            d.rectangle([px - rib * .16, 0, px + rib * .16, C], fill=(38, 27, 25, 210))
            d.rectangle([px + rib * .16, 0, px + rib * .40, C], fill=(112, 84, 66, 190))
            d.rectangle([px - rib * .40, 0, px - rib * .16, C], fill=(98, 72, 56, 120))
    # 가로 골
    for row in range(8):
        y = row * (C // 8)
        d.line([(0, y), (C, y)], fill=(32, 22, 20, 130), width=3)
        d.line([(0, y + 3), (C, y + 3)], fill=(132, 100, 78, 60), width=2)
    for _ in range(46):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(4, 16) * R, y + rng.uniform(3, 9) * R], fill=(120, 74, 46, rng.randrange(20, 50)))
    return finish(shade_edges(img, 0.07), 0.6)


# ---------------------------------------------------------------- 벽
def wall_brick():
    img = base_layer((96, 54, 48), 51, noise=9, blotch=8, blotch_cells=5)
    d = ImageDraw.Draw(img, "RGBA")
    row_h = C // 16
    bw = C // 6
    mortar = (58, 46, 44, 255)
    d.rectangle([0, 0, C, C], fill=mortar)
    for row in range(16):
        y = row * row_h
        off = (bw // 2) if row % 2 else 0
        for i in range(7):
            x = i * bw + off
            tone = rng.uniform(-16, 16)
            base = (124, 66, 56)
            col = tuple(int(max(0, min(255, c + tone))) for c in base)
            for px, py in wrap_xy(x, y):
                box = [px + 5 * R, py + 4 * R, px + bw - 5 * R, py + row_h - 5 * R]
                d.rounded_rectangle(box, radius=3 * R, fill=col + (255,))
                # 벽돌 윗면 하이라이트 / 아래 그림자
                d.line([(box[0] + 2, box[1] + 2), (box[2] - 2, box[1] + 2)], fill=(196, 132, 112, 110), width=3)
                d.line([(box[0] + 2, box[3] - 1), (box[2] - 2, box[3] - 1)], fill=(52, 30, 28, 190), width=3)
                d.line([(box[0], box[1] + 3), (box[0], box[3] - 3)], fill=(168, 110, 96, 70), width=2)
    # 균열·얼룩
    for _ in range(10):
        x, y = rng.randrange(C), rng.randrange(C)
        pts = [(x, y)]
        for k in range(rng.randrange(3, 7)):
            x += rng.uniform(-18, 18) * R
            y += rng.uniform(6, 22) * R
            pts.append((x, y))
        d.line(pts, fill=(44, 30, 28, 130), width=2)
    for _ in range(28):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(8, 30) * R, y + rng.uniform(4, 14) * R], fill=(40, 34, 32, rng.randrange(14, 40)))
    return finish(shade_edges(img, 0.05), 0.5)


def wall_plaster():
    img = base_layer((188, 168, 136), 61, noise=8, blotch=20, blotch_cells=3)
    d = ImageDraw.Draw(img, "RGBA")
    # 물얼룩·바랜 자리
    for _ in range(24):
        x, y = rng.randrange(C), rng.randrange(C)
        w = rng.uniform(30, 90) * R
        h = rng.uniform(20, 60) * R
        d.ellipse([x, y, x + w, y + h], fill=(150, 130, 102, rng.randrange(10, 28)))
    # 잔 균열
    for _ in range(7):
        x, y = rng.randrange(C), rng.randrange(C)
        pts = [(x, y)]
        for k in range(rng.randrange(4, 9)):
            x += rng.uniform(-14, 14) * R
            y += rng.uniform(8, 26) * R
            pts.append((x, y))
        d.line(pts, fill=(120, 102, 82, 110), width=2)
    # 아래쪽 때(그런지) — 반복 시 위아래가 이어지도록 주기 함수로
    arr = np.asarray(img).astype(np.float32)
    yy = np.mgrid[0:C, 0:C][0] / C
    grime = 0.90 + 0.10 * (0.5 + 0.5 * np.cos(yy * math.tau))
    arr *= grime[:, :, None]
    return finish(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB"), 0.8)


def wall_concrete():
    img = base_layer((126, 134, 148), 71, noise=7, blotch=10, blotch_cells=4)
    d = ImageDraw.Draw(img, "RGBA")
    pw, ph = C // 2, C // 3
    for i in range(2):
        for j in range(3):
            x, y = i * pw, j * ph
            d.rectangle([x + 3, y + 3, x + pw - 3, y + ph - 3], outline=(92, 99, 112, 200), width=3)
            d.line([(x + 4, y + 4), (x + pw - 4, y + 4)], fill=(176, 184, 198, 110), width=3)
            for k in range(2):
                bx = x + 14 * R + k * (pw - 28 * R)
                d.ellipse([bx, y + 14 * R, bx + 7 * R, y + 21 * R], fill=(96, 102, 114, 220))
    # 세로 물자국
    for _ in range(18):
        x = rng.randrange(C)
        w = rng.uniform(4, 16) * R
        d.rectangle([x, 0, x + w, C], fill=(80, 88, 102, rng.randrange(8, 22)))
    for _ in range(20):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(10, 40) * R, y + rng.uniform(5, 16) * R], fill=(70, 76, 88, rng.randrange(10, 30)))
    return finish(shade_edges(img, 0.05), 0.6)


def wall_wood():
    img = base_layer((92, 66, 48), 81, noise=6, blotch=8, blotch_cells=5)
    d = ImageDraw.Draw(img, "RGBA")
    plank = C // 8
    for i in range(8):
        x = i * plank
        tone = rng.uniform(-12, 12)
        col = tuple(int(max(0, min(255, c + tone))) for c in (108, 78, 56))
        d.rectangle([x + 3, 0, x + plank - 3, C], fill=col + (255,))
        d.line([(x, 0), (x, C)], fill=(34, 22, 16, 220), width=5)
        d.line([(x + 5, 0), (x + 5, C)], fill=(156, 118, 86, 90), width=2)
        # 나뭇결
        for k in range(5):
            gx = x + plank * (0.18 + 0.16 * k)
            d.line([(gx, 0), (gx + rng.uniform(-6, 6) * R, C)], fill=(70, 48, 34, 70), width=2)
        for k in range(3):
            ny = k * (C // 3) + C // 6
            d.ellipse([x + plank * .5 - 3 * R, ny, x + plank * .5 + 3 * R, ny + 6 * R], fill=(40, 30, 22, 220))
    for _ in range(20):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(6, 22) * R, y + rng.uniform(3, 10) * R], fill=(58, 40, 28, rng.randrange(20, 50)))
    return finish(shade_edges(img, 0.06), 0.6)


# ---------------------------------------------------------------- 바닥
def floor_paving():
    img = base_layer((150, 146, 138), 91, noise=8, blotch=12, blotch_cells=4)
    d = ImageDraw.Draw(img, "RGBA")
    cell = C // 4
    joint = (74, 72, 68, 255)
    d.rectangle([0, 0, C, C], fill=joint)
    for j in range(4):
        for i in range(4):
            jx = rng.uniform(-8, 8) * R * .5
            jy = rng.uniform(-8, 8) * R * .5
            x = i * cell + jx
            y = j * cell + jy
            tone = rng.uniform(-16, 16)
            col = tuple(int(max(0, min(255, c + tone))) for c in (166, 160, 148))
            for px, py in wrap_xy(x, y):
                box = [px + 6 * R, py + 6 * R, px + cell - 6 * R, py + cell - 6 * R]
                # 둥글고 불규칙한 판석
                d.rounded_rectangle(box, radius=10 * R, fill=col + (255,))
                d.arc(box, 200, 330, fill=(206, 200, 186, 120), width=4)
                d.line([(box[0] + 10, box[3] - 2), (box[2] - 10, box[3] - 2)], fill=(104, 100, 94, 160), width=3)
                # 표면 결
                for k in range(2):
                    sx = px + cell * (0.25 + 0.4 * rng.random())
                    sy = py + cell * (0.25 + 0.4 * rng.random())
                    d.line([(sx, sy), (sx + rng.uniform(18, 60) * R, sy + rng.uniform(-10, 10) * R)], fill=(126, 120, 112, 60), width=2)
    # 이음새 이끼·자갈
    for _ in range(60):
        x, y = rng.randrange(C), rng.randrange(C)
        if (x % cell < 12 * R) or (y % cell < 12 * R):
            d.ellipse([x, y, x + rng.uniform(3, 9) * R, y + rng.uniform(2, 6) * R], fill=(84, 100, 74, rng.randrange(40, 110)))
    return finish(shade_edges(img, 0.08), 0.6)


def floor_asphalt():
    arr = np.zeros((C, C, 3), np.float32)
    for i, v in enumerate((62, 64, 72)):
        arr[:, :, i] = v
    arr += periodic_noise(C, 6, 12, 101)[:, :, None]
    arr += grain(C, 26, 102)[:, :, None]
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(11):
        x, y = rng.randrange(C), rng.randrange(C)
        pts = [(x, y)]
        for k in range(rng.randrange(3, 8)):
            x += rng.uniform(-26, 26) * R
            y += rng.uniform(8, 34) * R
            pts.append((x, y))
        d.line(pts, fill=(34, 36, 44, 150), width=3)
    for _ in range(80):
        x, y = rng.randrange(C), rng.randrange(C)
        rr = rng.uniform(1, 3) * R
        col = (120, 122, 130, rng.randrange(30, 90)) if rng.random() < .5 else (40, 42, 50, 120)
        d.ellipse([x, y, x + rr, y + rr], fill=col)
    for _ in range(5):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(40, 100) * R, y + rng.uniform(24, 60) * R], fill=(28, 30, 38, 60))
    return finish(img, 0.5)


def floor_marble():
    img = base_layer((156, 165, 180), 111, noise=5, blotch=10, blotch_cells=3)
    d = ImageDraw.Draw(img, "RGBA")
    cell = C // 2
    for j in range(2):
        for i in range(2):
            x, y = i * cell, j * cell
            tone = rng.uniform(-8, 8)
            col = tuple(int(max(0, min(255, c + tone))) for c in (172, 180, 194))
            d.rectangle([x + 4, y + 4, x + cell - 4, y + cell - 4], fill=col + (255,))
            # 대리석 결
            for k in range(3):
                sx = x + rng.uniform(10, cell * .7)
                sy = y + rng.uniform(10, cell * .7)
                pts = [(sx, sy)]
                for _ in range(rng.randrange(4, 8)):
                    sx += rng.uniform(8, 26) * R
                    sy += rng.uniform(-10, 16) * R
                    pts.append((sx, sy))
                d.line(pts, fill=(214, 220, 232, rng.randrange(50, 110)), width=3)
            d.rectangle([x + 4, y + 4, x + cell - 4, y + cell - 4], outline=(120, 128, 142, 130), width=3)
            d.line([(x + 6, y + 6), (x + cell - 6, y + 6)], fill=(226, 232, 242, 90), width=3)
    for _ in range(40):
        x, y = rng.randrange(C), rng.randrange(C)
        rr = rng.uniform(1, 2.4) * R
        d.ellipse([x, y, x + rr, y + rr], fill=(110, 118, 132, rng.randrange(20, 60)))
    return finish(shade_edges(img, 0.04), 0.5)


def floor_boardwalk():
    img = base_layer((122, 92, 66), 121, noise=6, blotch=10, blotch_cells=5)
    d = ImageDraw.Draw(img, "RGBA")
    plank = C // 11
    for i in range(11):
        y = i * plank
        tone = rng.uniform(-14, 14)
        col = tuple(int(max(0, min(255, c + tone))) for c in (140, 106, 76))
        d.rectangle([0, y + 3, C, y + plank - 3], fill=col + (255,))
        d.line([(0, y), (C, y)], fill=(52, 36, 26, 220), width=4)
        d.line([(0, y + 4), (C, y + 4)], fill=(186, 148, 112, 70), width=2)
        for k in range(4):
            gx = rng.uniform(0, C)
            d.line([(gx, y + 6), (gx + rng.uniform(-16, 16) * R, y + plank - 6)], fill=(96, 70, 50, 90), width=2)
        for k in range(6):
            nx = k * (C // 6) + C // 12
            d.ellipse([nx - 2 * R, y + plank * .45, nx + 2 * R, y + plank * .45 + 4 * R], fill=(60, 44, 32, 200))
    for _ in range(40):
        x, y = rng.randrange(C), rng.randrange(C)
        d.ellipse([x, y, x + rng.uniform(4, 14) * R, y + rng.uniform(3, 8) * R], fill=(196, 176, 142, rng.randrange(20, 60)))
    return finish(shade_edges(img, 0.07), 0.6)


TILE_FUNCS = [
    ("roof_giwa", roof_giwa),
    ("roof_slate", roof_slate),
    ("roof_metal", roof_metal),
    ("roof_shingle", roof_shingle),
    ("wall_brick", wall_brick),
    ("wall_plaster", wall_plaster),
    ("wall_concrete", wall_concrete),
    ("wall_wood", wall_wood),
    ("floor_paving", floor_paving),
    ("floor_asphalt", floor_asphalt),
    ("floor_marble", floor_marble),
    ("floor_boardwalk", floor_boardwalk),
]


def main():
    os.makedirs(TILES, exist_ok=True)
    atlas = Image.new("RGB", (S * 4, S * 3), (0, 0, 0))
    frames = {}
    for index, (name, func) in enumerate(TILE_FUNCS):
        tile = func()
        col = index % 4
        row = index // 4
        # 아틀라스 안에서도 심리스가 보이도록 2x2로 붙인다.
        atlas.paste(tile, (col * S, row * S))
        tile.save(os.path.join(TILES, name + ".png"))
        frames[name] = {"x": col * S, "y": row * S, "w": S, "h": S}
        print("tile", name)
    atlas.save(os.path.join(OUT, "atlas_v39.png"))
    with open(os.path.join(OUT, "atlas_v39.json"), "w", encoding="utf-8") as f:
        json.dump({"texture": "atlas_v39.png", "cell": S, "frames": frames}, f, ensure_ascii=False, indent=1)
    print("saved", os.path.join(OUT, "atlas_v39.png"))


if __name__ == "__main__":
    main()
