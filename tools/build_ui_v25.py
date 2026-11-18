#!/usr/bin/env python3
"""2.0.25 UI 텍스처 베이커 — ChatGPT 시안(6종) 복제용.

조선 다크 판타지 UI의 실제 재질(보랏빛 판 · 황동 테두리 · 금빛 촉 버튼 · 한지 · 나무 문패 ·
부적 고리 · 금관 화환)을 고해상도로 구워 `assets/ui/v25/`에 저장한다.
화면 코드는 이 텍스처를 9-slice 또는 TextureRect로 늘려 쓴다.

사용: python3 tools/build_ui_v25.py
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "v25")
S = 4  # 슈퍼샘플 배율

GOLD_TOP = (255, 240, 198)
GOLD = (240, 194, 101)
GOLD_MID = (214, 158, 74)
GOLD_DEEP = (150, 100, 32)
GOLD_DARK = (92, 60, 18)
INK = (26, 18, 10)

DARK_TOP = (46, 36, 70)
DARK_BOT = (17, 13, 28)
DARK_EDGE = (128, 104, 168)


def ensure() -> None:
    os.makedirs(OUT, exist_ok=True)


def new(size):
    w, h = int(size[0] * S), int(size[1] * S)
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def save(img: Image.Image, name: str) -> None:
    w, h = img.size
    out = img.resize((w // S, h // S), Image.LANCZOS)
    out.save(os.path.join(OUT, name))
    print(name, out.size)


def rgba(color, alpha=None):
    c = tuple(int(v) for v in color[:3])
    a = color[3] if len(color) > 3 else 255
    if alpha is not None:
        a = int(alpha)
    return c + (a,)


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(len(a)))


def ramp(stops, t):
    """stops: [(pos, color), ...] pos 오름차순."""
    if t <= stops[0][0]:
        return stops[0][1]
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]
        p1, c1 = stops[i + 1]
        if p0 <= t <= p1:
            k = 0.0 if p1 == p0 else (t - p0) / (p1 - p0)
            return lerp(c0, c1, k)
    return stops[-1][1]


def vgrad(w, h, stops):
    arr = np.zeros((h, w, 4), dtype=np.float32)
    for y in range(h):
        c = ramp(stops, y / max(1, h - 1))
        arr[y, :] = c
    return arr


def hgrad(w, h, stops):
    arr = np.zeros((h, w, 4), dtype=np.float32)
    for x in range(w):
        c = ramp(stops, x / max(1, w - 1))
        arr[x * 0 + 0, x] = c  # placeholder, filled below
    for x in range(w):
        c = ramp(stops, x / max(1, w - 1))
        arr[:, x] = c
    return arr


def mask_from(draw_fn, size):
    """size(실좌표) 위에 그린 흰 도형을 S배 마스크로."""
    img = Image.new("L", (int(size[0] * S), int(size[1] * S)), 0)
    d = ImageDraw.Draw(img)
    draw_fn(d, S)
    return img


def apply(arr, mask):
    out = arr.copy()
    a = np.asarray(mask, dtype=np.float32) / 255.0
    out[:, :, 3] *= a
    return out


def overlay_rgb(arr, grad, strength=1.0):
    """알파로 가중한 색 가산(불투명도 0인 곳은 더하지 않는다)."""
    out = arr.copy()
    k = (grad[:, :, 3:4] / 255.0) * strength
    out[:, :, :3] = np.clip(out[:, :, :3] + grad[:, :, :3] * k, 0, 255)
    return out


def to_img(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def noise(size, amount=8.0, scale=2.2, seed=20261125):
    w, h = int(size[0] * S), int(size[1] * S)
    rng = np.random.default_rng(seed)
    small = rng.normal(0, 1, (max(2, int(h / (scale * 2))), max(2, int(w / (scale * 2)))))
    span = float(small.max() - small.min()) + 1e-6
    img = Image.fromarray(((small - small.min()) / span * 255).astype(np.uint8), "L")
    img = img.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(0.8 * S))
    return (np.asarray(img, dtype=np.float32) / 255.0 - 0.5) * amount


def grain(arr, amount=7.0, scale=2.2, seed=20261125):
    out = arr.copy()
    n = noise((arr.shape[1] / S, arr.shape[0] / S), amount, scale, seed)
    for c in range(3):
        out[:, :, c] = np.clip(out[:, :, c] + n, 0, 255)
    return out


def rounded_rect(d, s, size, radius, inset=0.0, fill=None, outline=None, width=1):
    x0, y0 = inset * s, inset * s
    x1, y1 = size[0] * s - inset * s, size[1] * s - inset * s
    d.rounded_rectangle([x0, y0, x1 - 1, y1 - 1], radius=radius * s, fill=fill,
                        outline=outline, width=max(1, int(width * s)))


def glow_layer(img, color, radius=8, strength=0.7):
    a = img.split()[3].filter(ImageFilter.GaussianBlur(radius * S))
    arr = np.asarray(img, dtype=np.float32).copy()
    g = np.asarray(a, dtype=np.float32) / 255.0 * strength
    for c in range(3):
        arr[:, :, c] = np.clip(arr[:, :, c] + color[c] * 0.0, 0, 255)
    out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    layers = []
    halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ha = np.asarray(a, dtype=np.float32) / 255.0 * strength
    harr = np.zeros((img.size[1], img.size[0], 4), dtype=np.float32)
    harr[:, :, 0] = color[0]
    harr[:, :, 1] = color[1]
    harr[:, :, 2] = color[2]
    harr[:, :, 3] = ha * 255
    halo = Image.fromarray(np.clip(harr, 0, 255).astype(np.uint8), "RGBA")
    return Image.alpha_composite(halo, out)


def bevel(arr, mask, radius, light=(255, 246, 222), dark=(20, 10, 4), up=2.0, down=3.0):
    """위/왼쪽 밝은 선, 아래/오른쪽 어두운 선(9-slice에서도 자연스럽게)."""
    m = np.asarray(mask, dtype=np.float32) / 255.0
    shifted = lambda dx, dy: np.asarray(
        mask.transform(mask.size, Image.AFFINE, (1, 0, -dx * S, 0, 1, -dy * S), resample=Image.BILINEAR),
        dtype=np.float32) / 255.0
    top = np.clip(m - shifted(0, up), 0, 1)
    left = np.clip(m - shifted(up, 0), 0, 1)
    bot = np.clip(m - shifted(0, -down), 0, 1)
    right = np.clip(m - shifted(-down, 0), 0, 1)
    out = arr.copy()
    for c in range(3):
        out[:, :, c] = out[:, :, c] * (1 - top * 0.85) + light[c] * (top * 0.85)
        out[:, :, c] = out[:, :, c] * (1 - left * 0.55) + light[c] * (left * 0.55)
        out[:, :, c] = out[:, :, c] * (1 - bot * 0.75) + dark[c] * (bot * 0.75)
        out[:, :, c] = out[:, :, c] * (1 - right * 0.55) + dark[c] * (right * 0.55)
    return out


def corner_curl(d, s, x, y, dx, dy, extent, color, width, curl=0.55):
    """모서리 필리그리: 바깥으로 뻗는 두 줄과 안쪽으로 말리는 곡선."""
    w = max(1, int(width * s))
    a = extent * s
    cx, cy = x * s, y * s
    # 긴 두 줄
    d.line([(cx, cy + dy * a * 0.30), (cx, cy + dy * a)], fill=color, width=w)
    d.line([(cx + dx * a * 0.30, cy), (cx + dx * a, cy)], fill=color, width=w)
    # 안쪽으로 말리는 1/4 곡선(모서리에서 안쪽으로 볼록)
    pts = []
    r = a * curl
    for i in range(13):
        t = i / 12.0
        ang = t * math.pi * 0.5
        pts.append((cx + dx * (a * 0.30 - r * math.sin(ang) * 0.0 + r * (1 - math.cos(ang)) - r * 0.0),
                    cy + dy * (a * 0.30 - r * (1 - math.cos(ang)))))
    # 단순화: 두 줄 사이를 잇는 부드러운 사선(오목)
    d.line([(cx + dx * a * 0.30, cy), (cx + dx * a * 0.12, cy + dy * a * 0.12),
            (cx, cy + dy * a * 0.30)], fill=color, width=w, joint="curve")
    # 끝 장식 다이아몬드
    r2 = 2.1 * s
    for px, py in [(cx + dx * a, cy), (cx, cy + dy * a)]:
        d.polygon([(px, py - r2), (px + r2, py), (px, py + r2), (px - r2, py)], fill=color)


# --------------------------------------------------------------------- panel
def panel(name="panel.png", size=(384, 384), margin=58, fill_top=DARK_TOP, fill_bot=DARK_BOT,
          edge=(214, 178, 120), glow=0.0, ornate=True):
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, margin * 0.42, fill=255), size)
    arr = vgrad(w, h, [(0.0, rgba(fill_top)), (0.55, rgba(lerp(fill_top, fill_bot, 0.62))),
                       (1.0, rgba(fill_bot))])
    # 위쪽 은은한 보랏빛 하이라이트
    band = vgrad(w, int(h * 0.32), [(0, (150, 130, 200, 40)), (1, (150, 130, 200, 0))])
    arr[:band.shape[0], :] = overlay_rgb(arr[:band.shape[0], :], band, 1.0)
    arr = grain(arr, 11.0, 2.0)
    arr = grain(arr, 4.0, 0.9, 991)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    # 안쪽 위 베벨 하이라이트
    d.line([(8 * S, 9 * S), (w - 8 * S, 9 * S)], fill=rgba((255, 236, 198), 46), width=max(1, int(1.2 * S)))
    d.line([(8 * S, 10.4 * S), (w - 8 * S, 10.4 * S)], fill=rgba((0, 0, 0), 90), width=max(1, int(1.0 * S)))
    # 바깥 그림자 + 테두리
    b = margin * 0.42
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=b * S,
                        outline=rgba((10, 8, 18), 210), width=int(1.6 * S))
    d.rounded_rectangle([3 * S, 3 * S, w - 3 * S, h - 3 * S], radius=b * S,
                        outline=rgba(edge, 200), width=max(1, int(1.15 * S)))
    d.rounded_rectangle([6.5 * S, 6.5 * S, w - 6.5 * S, h - 6.5 * S], radius=(b - 3) * S,
                        outline=rgba(edge, 70), width=max(1, int(0.8 * S)))
    # 안쪽 어두운 테두리(깊이감)
    d.rounded_rectangle([8 * S, 8 * S, w - 8 * S, h - 8 * S], radius=(b - 4) * S,
                        outline=rgba((0, 0, 0), 90), width=max(1, int(1.0 * S)))
    if ornate:
        arm = 24.0
        for (cx, cy, dx, dy) in [(9, 9, 1, 1), (size[0] - 9, 9, -1, 1),
                                 (9, size[1] - 9, 1, -1), (size[0] - 9, size[1] - 9, -1, -1)]:
            corner_curl(d, S, cx, cy, dx, dy, arm, rgba(GOLD, 205), 1.0)
        # 위/아래 중앙 장식
        for cy, dy in [(3.5, 1), (size[1] - 3.5, -1)]:
            cx = size[0] / 2
            r = 3.0 * S
            d.polygon([(cx * S, cy * S - dy * r), (cx * S + r, cy * S), (cx * S, cy * S + dy * r),
                       (cx * S - r, cy * S)], fill=rgba(GOLD, 220))
    img = glow_layer(img, (255, 196, 110), 6, 0.35) if glow > 0 else img
    save(img, name)


# --------------------------------------------------------------------- card
def card(name="card.png", lit=False):
    size = (256, 128)
    margin = 22
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 10.0, fill=255), size)
    if lit:
        arr = vgrad(w, h, [(0.0, (86, 56, 52, 250)), (0.42, (62, 40, 46, 250)),
                           (1.0, (40, 26, 34, 252))])
    else:
        arr = vgrad(w, h, [(0.0, (54, 38, 58, 240)), (0.5, (42, 29, 50, 244)),
                           (1.0, (28, 20, 38, 248))])
    arr = grain(arr, 9.0, 1.6, 771)
    arr = grain(arr, 3.5, 0.8, 773)
    # 아래쪽 따뜻한 빛
    warm = vgrad(w, h, [(0.45, (255, 190, 120, 0)), (1.0, (255, 186, 116, 46 if lit else 16))])
    arr = overlay_rgb(arr, warm)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.line([(10 * S, 5.2 * S), (w - 10 * S, 5.2 * S)], fill=rgba((255, 240, 210), 34), width=max(1, int(1.0 * S)))
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=10 * S,
                        outline=rgba((8, 6, 14), 200), width=int(1.6 * S))
    line = rgba((255, 214, 140), 255) if lit else rgba((198, 160, 106), 190)
    d.rounded_rectangle([3 * S, 3 * S, w - 3 * S, h - 3 * S], radius=8 * S,
                        outline=line, width=max(1, int((2.0 if lit else 1.1) * S)))
    d.rounded_rectangle([6 * S, 6 * S, w - 6 * S, h - 6 * S], radius=6 * S,
                        outline=rgba((255, 220, 150), 90 if lit else 40), width=max(1, int(0.7 * S)))
    for (cx, cy, dx, dy) in [(5, 5, 1, 1), (size[0] - 5, 5, -1, 1),
                             (5, size[1] - 5, 1, -1), (size[0] - 5, size[1] - 5, -1, -1)]:
        corner_curl(d, S, cx, cy, dx, dy, 11.0, rgba((255, 216, 150), 230 if lit else 150), 0.9)
    if lit:
        img = glow_layer(img, (255, 196, 110), 7, 0.55)
    save(img, name)


# --------------------------------------------------------------------- button
def button_shape(s, size, inset=4.0, tip=0.30):
    """양 끝이 뾰족한 육각 판(디자인의 금빛 CTA)."""
    w, h = size[0] * s, size[1] * s
    pad = inset * s
    cy = h / 2
    notch = size[1] * tip * s
    return [(pad, cy), (pad + notch, pad), (w - pad - notch, pad),
            (w - pad, cy), (w - pad - notch, h - pad), (pad + notch, h - pad)]


def button(name="btn_gold.png", dark=False, disabled=False, pressed=False):
    size = (360, 120)
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: d.polygon(button_shape(s, size, 6.0), fill=255), size)
    if dark:
        stops = [(0.0, (46, 36, 62, 250)), (0.5, (28, 22, 42, 252)), (1.0, (14, 11, 24, 252))]
    elif disabled:
        stops = [(0.0, (128, 108, 78, 245)), (0.5, (104, 86, 60, 248)), (1.0, (74, 60, 40, 250))]
    else:
        stops = [(0.0, (255, 233, 168, 255)), (0.28, (247, 205, 116, 255)),
                 (0.62, (226, 168, 78, 255)), (0.86, (244, 197, 108, 255)),
                 (1.0, (198, 138, 52, 255))]
    if pressed:
        stops = [(0.0, (226, 192, 118, 255)), (0.5, (204, 148, 64, 255)), (1.0, (170, 116, 40, 255))]
    arr = vgrad(w, h, stops)
    arr = grain(arr, 8.0, 1.4, 313)
    # 브러시 메탈 결(가로로 아주 가는 줄)
    rng = np.random.default_rng(77)
    for i in range(90):
        y = int(rng.integers(0, h))
        k = float(rng.normal(0, 1)) * (4.0 if not dark else 5.0)
        arr[y, :, :3] = np.clip(arr[y, :, :3] + k, 0, 255)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    rim = (255, 226, 160) if not dark else (222, 194, 150)
    inner = (255, 246, 214) if not dark else (255, 236, 200)
    poly = button_shape(S, size, 6.0)
    d.line(poly + [poly[0]], fill=rgba(rim, 255), width=max(1, int(1.5 * S)), joint="curve")
    poly2 = button_shape(S, size, 9.5)
    d.line(poly2 + [poly2[0]], fill=rgba(inner, 120 if not dark else 90),
           width=max(1, int(0.8 * S)), joint="curve")
    # 위쪽 안쪽 하이라이트(판이 눌린 느낌)
    d.line([(w * 0.24, 13 * S), (w * 0.76, 13 * S)],
           fill=rgba((255, 250, 226), 70 if not dark else 45), width=max(1, int(1.1 * S)))
    # 위쪽 반사광 띠(모양 안쪽만)
    gloss_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss_img)
    gloss = [(11 * S, h * 0.22), (w - 11 * S, h * 0.22), (w - 20 * S, h * 0.40), (20 * S, h * 0.40)]
    gd.polygon(gloss, fill=rgba((255, 250, 226), 40 if dark else 66))
    ga = np.asarray(gloss_img, dtype=np.float32)
    ga[:, :, 3] *= np.asarray(mask, dtype=np.float32) / 255.0
    img = Image.alpha_composite(img, to_img(ga))
    d = ImageDraw.Draw(img)
    # 끝 장식 다이아몬드
    for px in (11.0, size[0] - 11.0):
        cy = h / 2
        r = 4.2 * S
        d.polygon([(px * S, cy - r), (px * S + r, cy), (px * S, cy + r), (px * S - r, cy)],
                  outline=rgba(rim, 220), fill=rgba((90, 60, 20), 120 if not dark else 150))
    if not dark and not disabled:
        img = glow_layer(img, (255, 190, 96), 8, 0.38)
    save(img, name)


# --------------------------------------------------------------------- tab
def tab(name="tab.png", lit=False):
    size = (300, 110)
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 14.0, fill=255), size)
    if lit:
        arr = vgrad(w, h, [(0.0, (196, 126, 56, 255)), (0.28, (232, 166, 86, 255)),
                           (0.55, (188, 120, 52, 255)), (1.0, (126, 78, 32, 255))])
    else:
        arr = vgrad(w, h, [(0.0, (40, 31, 58, 236)), (0.5, (26, 20, 40, 240)),
                           (1.0, (15, 12, 26, 244))])
    # 좌우 가장자리 밝은 띠
    side = hgrad(w, h, [(0.0, (255, 220, 160, 40)), (0.10, (255, 220, 160, 0)),
                        (0.90, (255, 220, 160, 0)), (1.0, (255, 220, 160, 40))])
    arr = overlay_rgb(arr, side)
    arr = grain(arr, 5.0, 1.6, 907)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    b = 13
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=b * S,
                        outline=rgba((8, 6, 14), 180), width=int(1.4 * S))
    line = rgba((255, 226, 168), 250) if lit else rgba((206, 176, 148), 120)
    d.rounded_rectangle([3 * S, 3 * S, w - 3 * S, h - 3 * S], radius=(b - 1) * S,
                        outline=line, width=max(1, int((1.9 if lit else 1.0) * S)))
    d.rounded_rectangle([6.5 * S, 6.5 * S, w - 6.5 * S, h - 6.5 * S], radius=(b - 3) * S,
                        outline=rgba((255, 230, 180), 80 if lit else 34), width=max(1, int(0.7 * S)))
    # 모서리 톱니 장식
    for cx, dx in [(7, 1), (size[0] - 7, -1)]:
        for cy, dy in [(7, 1), (size[1] - 7, -1)]:
            d.line([(cx * S, cy * S + dy * 8 * S), (cx * S + dx * 8 * S, cy * S)],
                   fill=rgba((255, 228, 176), 150 if lit else 90), width=max(1, int(0.9 * S)))
    if lit:
        img = glow_layer(img, (255, 176, 70), 9, 0.75)
    save(img, name)


# --------------------------------------------------------------------- pill
def pill(name="pill.png"):
    size = (260, 92)
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 46.0, fill=255), size)
    arr = vgrad(w, h, [(0.0, (44, 32, 58, 216)), (0.5, (26, 19, 38, 226)), (1.0, (16, 12, 26, 232))])
    arr = grain(arr, 4.0, 1.4, 55)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=45 * S,
                        outline=rgba((240, 196, 170), 170), width=max(1, int(1.2 * S)))
    d.rounded_rectangle([4.5 * S, 4.5 * S, w - 4.5 * S, h - 4.5 * S], radius=41 * S,
                        outline=rgba((255, 226, 200), 60), width=max(1, int(0.7 * S)))
    save(img, name)


# --------------------------------------------------------------------- parchment
def parchment(name="parchment.png"):
    size = (512, 512)
    w, h = size[0] * S, size[1] * S
    rng = np.random.default_rng(4821)

    def shape(d, s):
        # 살짝 삐뚤빼뚤한 한지 윤곽(9-slice 중앙은 곧게).
        pts = []
        step = 6
        top_y = 10 + rng.normal(0, 0.9, 40)
        for i, x in enumerate(range(0, int(size[0]) + step, step)):
            pts.append((x * s, (10 + float(top_y[min(i, 39)])) * s))
        for i, y in enumerate(range(int(size[1]) - 10, -step, -step)):
            pts.append((size[0] * s, y * s))
        for i, x in enumerate(range(int(size[0]), -step, -step)):
            pass
        # 단순 사각(모서리만 살짝) — 위/아래 가장자리는 직선 유지
        d.polygon(pts + [(size[0] * s, size[1] * s)], fill=255)

    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([8 * S, 8 * S, w - 8 * S, h - 8 * S], radius=7 * S, fill=255)
    arr = vgrad(w, h, [(0.0, (247, 233, 209, 255)), (0.35, (241, 224, 196, 255)),
                       (1.0, (222, 200, 166, 255))])
    # 섬유 결
    fib = np.zeros((h, w), dtype=np.float32)
    small = rng.normal(0, 1, (h // (3 * S), w // (3 * S)))
    fim = Image.fromarray(((small - small.min()) / ((small.max()-small.min()) + 1e-6) * 255).astype(np.uint8), "L")
    fim = fim.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(1.2 * S))
    fib = (np.asarray(fim, dtype=np.float32) / 255.0 - 0.5) * 14.0
    for c in range(3):
        arr[:, :, c] = np.clip(arr[:, :, c] + fib, 0, 255)
    # 오래된 얼룩
    stain = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(stain)
    for i in range(7):
        cx, cy = rng.integers(0, size[0]) * S, rng.integers(0, size[1]) * S
        rx, ry = rng.integers(30, 90) * S, rng.integers(20, 70) * S
        sd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=int(rng.integers(18, 46)))
    stain = stain.filter(ImageFilter.GaussianBlur(16 * S))
    sa = np.asarray(stain, dtype=np.float32) / 255.0
    for c, k in enumerate([0.55, 0.42, 0.28]):
        arr[:, :, c] = arr[:, :, c] * (1 - sa * 0.5) + (150 * k + 60) * sa * 0.5
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([9 * S, 9 * S, w - 9 * S, h - 9 * S], radius=6 * S,
                        outline=rgba((150, 112, 62), 120), width=max(1, int(1.1 * S)))
    d.rounded_rectangle([15 * S, 15 * S, w - 15 * S, h - 15 * S], radius=4 * S,
                        outline=rgba((150, 112, 62), 60), width=max(1, int(0.7 * S)))
    # 모서리의 옅은 무늬
    for (cx, cy, dx, dy) in [(20, 20, 1, 1), (size[0] - 20, 20, -1, 1),
                             (20, size[1] - 20, 1, -1), (size[0] - 20, size[1] - 20, -1, -1)]:
        corner_curl(d, S, cx, cy, dx, dy, 14.0, rgba((150, 112, 62), 90), 0.9)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sa2 = np.asarray(img.split()[3]).astype(np.float32)
    sh = Image.fromarray((sa2 * 0.35).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(7 * S))
    sharr = np.zeros((h, w, 4), dtype=np.float32)
    sharr[:, :, 3] = np.asarray(sh, dtype=np.float32) * 0.55
    shadow = Image.fromarray(sharr.astype(np.uint8), "RGBA")
    img = Image.alpha_composite(shadow, img)
    save(img, name)


# --------------------------------------------------------------------- wood plaque
def plaque(name="plaque_wood.png"):
    size = (512, 256)
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 16.0, fill=255), size)
    arr = vgrad(w, h, [(0.0, (64, 40, 32, 252)), (0.35, (48, 29, 24, 252)),
                       (1.0, (28, 16, 14, 254))])
    # 나뭇결
    rng = np.random.default_rng(77)
    for i in range(60):
        y = int(rng.integers(0, h))
        amp = rng.normal(0, 2.0)
        xs = np.arange(w)
        ys = np.clip(y + np.sin(xs / (rng.integers(40, 130))) * amp * S, 0, h - 1)
        for x, yy in zip(xs[::4], ys[::4]):
            arr[int(yy), int(x), :3] *= 0.93
    arr = grain(arr, 7.0, 1.8, 12)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2 * S, 2 * S, w - 2 * S, h - 2 * S], radius=15 * S,
                        outline=rgba((18, 10, 8), 235), width=int(2.0 * S))
    d.rounded_rectangle([6 * S, 6 * S, w - 6 * S, h - 6 * S], radius=12 * S,
                        outline=rgba((212, 168, 96), 220), width=max(1, int(1.8 * S)))
    d.rounded_rectangle([10 * S, 10 * S, w - 10 * S, h - 10 * S], radius=9 * S,
                        outline=rgba((255, 226, 160), 70), width=max(1, int(0.8 * S)))
    # 네 모서리 못 장식
    for cx, cy in [(24, 24), (size[0] - 24, 24), (24, size[1] - 24), (size[0] - 24, size[1] - 24)]:
        r = 7.0 * S
        d.ellipse([cx * S - r, cy * S - r, cx * S + r, cy * S + r], fill=rgba((176, 132, 66), 240),
                  outline=rgba((255, 232, 176), 200), width=max(1, int(0.8 * S)))
        d.ellipse([cx * S - r * .45, cy * S - r * .45, cx * S + r * .45, cy * S + r * .45],
                  fill=rgba((96, 66, 26), 220))
    save(img, name)


# --------------------------------------------------------------------- circle frames
def medallion(name="medallion.png", size=(256, 256), thick=1.0, glyph_ring=True):
    w, h = size[0] * S, size[1] * S
    c = (w / 2, h / 2)
    r = w * 0.42
    img = new(size)
    d = ImageDraw.Draw(img)
    # 바깥 광
    for i in range(10):
        rr = r + (1.0 + i * 1.4) * S * thick
        d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr],
                  outline=rgba((236, 178, 92), int(46 - i * 4)), width=max(1, int(1.6 * S)))
    # 어두운 원판
    arr = vgrad(w, h, [(0.0, (52, 40, 70, 250)), (0.5, (32, 24, 46, 252)), (1.0, (18, 14, 28, 252))])
    circle = Image.new("L", (w, h), 0)
    ImageDraw.Draw(circle).ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=255)
    arr = apply(arr, circle)
    base = to_img(arr)
    d = ImageDraw.Draw(base)
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=rgba((255, 236, 186), 255),
              width=max(1, int(2.2 * S * thick)))
    rr = r - 4 * S * thick
    d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], outline=rgba(GOLD, 230),
              width=max(1, int(1.4 * S * thick)))
    # 8방향 못/장식
    if glyph_ring:
        for i in range(8):
            a = i * math.pi / 4
            px, py = c[0] + math.cos(a) * r, c[1] + math.sin(a) * r
            rad = 3.0 * S * thick
            d.polygon([(px, py - rad), (px + rad, py), (px, py + rad), (px - rad, py)],
                      fill=rgba((255, 228, 168), 235))
    img = glow_layer(base, (255, 190, 100), 7, 0.45)
    save(img, name)


def slot(name="slot.png",hollow=False):
    size = (256, 256)
    w, h = size[0] * S, size[1] * S
    c = (w / 2, h / 2)
    r = w * 0.40
    img = new(size)
    d = ImageDraw.Draw(img)
    for i in range(12):
        rr = r + (1.0 + i * 1.6) * S
        d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr],
                  outline=rgba((250, 196, 108), int(72 - i * 5)), width=max(1, int(1.8 * S)))
    if hollow:
        base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    else:
        arr = vgrad(w, h, [(0.0, (44, 34, 56, 252)), (0.55, (30, 23, 40, 252)), (1.0, (18, 14, 28, 254))])
        circle = Image.new("L", (w, h), 0)
        ImageDraw.Draw(circle).ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=255)
        arr = apply(arr, circle)
        base = to_img(arr)
    d = ImageDraw.Draw(base)
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=rgba((255, 236, 190), 255),
              width=max(1, int(2.4 * S)))
    d.ellipse([c[0] - r + 4 * S, c[1] - r + 4 * S, c[0] + r - 4 * S, c[1] + r - 4 * S],
              outline=rgba(GOLD, 220), width=max(1, int(1.2 * S)))
    # 황동 테두리에 박힌 작은 장식 12개
    for i in range(12):
        a = i * math.pi / 6
        px, py = c[0] + math.cos(a) * (r + 1.6 * S), c[1] + math.sin(a) * (r + 1.6 * S)
        rad = 2.6 * S
        d.polygon([(px, py - rad), (px + rad, py), (px, py + rad), (px - rad, py)],
                  fill=rgba((255, 232, 180), 240))
    img = glow_layer(base, (255, 190, 100), 8, 0.5)
    save(img, name)


def ring(name="ring.png"):
    """빠른 매치 중앙의 부적 고리: 금빛 원 + 8개 홈 + 룬 눈금."""
    size = (1024, 1024)
    w, h = size[0] * S // 2, size[1] * S // 2
    S2 = 2
    c = (w / 2, h / 2)
    r = w * 0.40
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i in range(18):
        rr = r + (1.0 + i * 1.5) * S2
        d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr],
                  outline=rgba((196, 140, 240), int(58 - i * 3)), width=max(1, int(1.6 * S2)))
    # 고리 띠
    band = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    ring_w = 16.0 * S2
    bd.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=rgba((236, 184, 104), 210),
               width=int(ring_w))
    bd.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=rgba((255, 238, 196), 230),
               width=int(1.6 * S2))
    bd.ellipse([c[0] - r + ring_w, c[1] - r + ring_w, c[0] + r - ring_w, c[1] + r - ring_w],
               outline=rgba((150, 100, 46), 200), width=int(1.6 * S2))
    img = Image.alpha_composite(img, band)
    d = ImageDraw.Draw(img)
    # 룬 눈금(작은 달·다이아)
    for i in range(48):
        a = i * math.tau / 48
        px, py = c[0] + math.cos(a) * r, c[1] + math.sin(a) * r
        rad = (4.2 if i % 6 == 0 else 2.4) * S2
        d.polygon([(px, py - rad), (px + rad * .7, py), (px, py + rad), (px - rad * .7, py)],
                  fill=rgba((255, 240, 206), 220))
    # 8개 홈(플레이어 인장 자리)
    for i in range(8):
        a = -math.pi / 2 + i * math.tau / 8
        px, py = c[0] + math.cos(a) * r, c[1] + math.sin(a) * r
        rr = 15.0 * S2
        d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=rgba((24, 18, 36), 235),
                  outline=rgba((255, 226, 168), 235), width=int(1.6 * S2))
    img = glow_layer(img, (214, 164, 255), 10, 0.6)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def _leaf(d, cx, cy, ang, length, width, fill, outline=None):
    """각도 ang 를 따라 놓인 잎 하나(타원 다각형)."""
    pts = []
    for i in range(24):
        t = i / 23.0 * math.tau
        ex = math.cos(t) * length
        ey = math.sin(t) * width
        pts.append((cx + ex * math.cos(ang) - ey * math.sin(ang),
                    cy + ex * math.sin(ang) + ey * math.cos(ang)))
    d.polygon(pts, fill=fill, outline=outline)


def laurel(name="laurel.png"):
    """금관 화환(업적·도감 요약의 큰 메달)."""
    size = (512, 512)
    w, h = size[0], size[1]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (w / 2, h / 2)
    r = w * 0.395
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=rgba((226, 172, 92), 210), width=3)
    rr = r - 8
    d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], outline=rgba((255, 232, 176), 70), width=2)
    # 잎 두 줄기: 아래(90도)에서 위 좌우로 감긴다.
    for side in (-1, 1):
        for i in range(11):
            t = i / 10.0
            ang = math.radians(90 + side * (18 + t * 105))
            px = c[0] + math.cos(ang) * (r + 6)
            py = c[1] + math.sin(ang) * (r + 6)
            length = 15.0 - t * 5.0
            width = 6.4 - t * 1.8
            _leaf(d, px, py, ang + math.radians(18 * side), length, width,
                  rgba((230, 178, 98), 240), rgba((255, 236, 188), 150))
            ang2 = math.radians(90 + side * (24 + t * 100))
            px2 = c[0] + math.cos(ang2) * (r - 12)
            py2 = c[1] + math.sin(ang2) * (r - 12)
            _leaf(d, px2, py2, ang2 - math.radians(22 * side), length * 0.85, width * 0.85,
                  rgba((204, 148, 74), 225), rgba((255, 232, 176), 110))
    img = glow_layer(img, (255, 196, 116), 5, 0.35)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def ribbon(name="ribbon.png"):
    """업적 머리글의 붉은 제목 리본(양 끝이 접혀 내려온다)."""
    size = (768, 224)
    w, h = size[0] * 2, size[1] * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cy = h / 2
    bh = 104
    tail = 26
    inset = 74
    # 뒤로 접힌 꼬리
    for side in (-1, 1):
        x_out = 24 if side < 0 else w - 24
        x_in = inset if side < 0 else w - inset
        d.polygon([(x_in, cy - bh / 2 + 6), (x_out, cy - bh / 2 - 18),
                   (x_out, cy + bh / 2 + 18), (x_in, cy + bh / 2 - 6)],
                  fill=rgba((86, 16, 24), 250))
        d.line([(x_out, cy - bh / 2 - 18), (x_out, cy + bh / 2 + 18)],
               fill=rgba((214, 166, 112), 160), width=3)
    # 몸통(가운데가 살짝 볼록한 띠)
    arr = vgrad(w, h, [(0.30, (150, 40, 48, 255)), (0.48, (176, 56, 60, 255)),
                       (0.62, (150, 40, 48, 255)), (0.80, (104, 24, 32, 255))])
    band = Image.new("L", (w, h), 0)
    bd = ImageDraw.Draw(band)
    bd.polygon([(inset, cy - bh / 2), (w - inset, cy - bh / 2),
                (w - inset, cy + bh / 2), (inset, cy + bh / 2)], fill=255)
    arr = apply(arr, band)
    img = Image.alpha_composite(img, to_img(arr))
    d = ImageDraw.Draw(img)
    # 위아래 금빛 테와 안쪽 어두운 홈
    for py, dy in [(cy - bh / 2, 1), (cy + bh / 2, -1)]:
        d.line([(inset, py), (w - inset, py)], fill=rgba((246, 200, 128), 235), width=4)
        d.line([(inset, py + dy * 7), (w - inset, py + dy * 7)], fill=rgba((92, 16, 22), 200), width=3)
    # 좌우 세로 테
    for px in (inset, w - inset):
        d.line([(px, cy - bh / 2), (px, cy + bh / 2)], fill=rgba((246, 200, 128), 200), width=3)
    # 가운데 다이아 장식
    for dx in (-1, 1):
        d.polygon([(w / 2 + dx * 18, cy - 10), (w / 2 + dx * 30, cy),
                   (w / 2 + dx * 18, cy + 10), (w / 2 + dx * 6, cy)],
                  outline=rgba((255, 226, 168), 220), width=2)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img = glow_layer(img, (210, 80, 70), 3, 0.28)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def vs(name="vs.png"):
    """도사 : 요괴 대결의 금빛 VS 휘장(금속 그라데이션 + 날개 장식)."""
    size = (512, 288)
    w, h = size[0] * 2, size[1] * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for side in (-1, 1):
        for i in range(4):
            cx = w / 2 + side * (86 + i * 20)
            d.arc([cx - 130, h / 2 - 96 - i * 10, cx + 130, h / 2 + 96 + i * 10],
                  start=210 if side > 0 else -30, end=330 if side > 0 else 150,
                  fill=rgba((242, 192, 110), max(20, 120 - i * 26)), width=5)
    from PIL import ImageFont
    fpath = "/workspace/repo/assets/fonts/NotoSansCJK-Regular.ttc"
    font = ImageFont.truetype(fpath, 330)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.text((w / 2, h / 2), "VS", font=font, anchor="mm", fill=255,
            stroke_width=10, stroke_fill=255)
    garr = vgrad(w, h, [(0.0, (255, 246, 214, 255)), (0.30, (252, 214, 130, 255)),
                        (0.55, (226, 168, 82, 255)), (0.72, (255, 236, 176, 255)),
                        (1.0, (184, 124, 44, 255))])
    garr = apply(garr, mask)
    gold = to_img(garr)
    img = Image.alpha_composite(img, gold)
    edge = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ed = ImageDraw.Draw(edge)
    ed.text((w / 2, h / 2), "VS", font=font, anchor="mm", fill=(0, 0, 0, 0),
            stroke_width=10, stroke_fill=rgba((70, 40, 10), 255))
    img = Image.alpha_composite(edge, img)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img = glow_layer(img, (255, 200, 120), 6, 0.55)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def letter(name="letter.png"):
    """봉인된 편지 아이콘(목록 카드용)."""
    size = (256, 168)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = 14, 30, w - 14, h - 26
    d.rounded_rectangle([x0, y0, x1, y1], radius=8, fill=rgba((226, 205, 174), 255),
                        outline=rgba((132, 100, 62), 255), width=4)
    d.polygon([(x0, y0 + 6), ((x0 + x1) / 2, (y0 + y1) / 2 - 6), (x1, y0 + 6)],
              fill=rgba((240, 224, 198), 255), outline=rgba((150, 116, 72), 220))
    # 접힌 선
    d.line([(x0 + 4, y1 - 4), (w / 2, (y0 + y1) / 2 + 6), (x1 - 4, y1 - 4)],
           fill=rgba((176, 146, 106), 200), width=3)
    # 붉은 밀랍 인장
    cx, cy, r = w / 2, (y0 + y1) / 2 + 4, 22
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgba((150, 34, 32), 255),
              outline=rgba((238, 196, 160), 170), width=3)
    d.ellipse([cx - r * .62, cy - r * .62, cx + r * .62, cy + r * .62],
              outline=rgba((96, 18, 18), 230), width=3)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def tassel(name="tassel.png"):
    size = (128, 320)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = w / 2
    # 매듭
    d.ellipse([cx - 26, 10, cx + 26, 74], fill=rgba((158, 38, 44), 255),
              outline=rgba((248, 206, 168), 170), width=3)
    d.arc([cx - 20, 22, cx + 20, 62], 0, 360, fill=rgba((110, 20, 26), 220), width=4)
    # 술
    for i in range(9):
        x = cx - 22 + i * 5.5
        d.line([(x, 70), (x - 4 + i * 1.0, h - 12)], fill=rgba((152, 34, 42), 240),
               width=3)
    d.arc([cx - 26, 56, cx + 26, 86], 0, 180, fill=rgba((255, 214, 176), 150), width=3)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def divider(name="divider.png"):
    size = (512, 40)
    w, h = size[0] * 2, size[1] * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cy = h / 2
    for x in range(40, w - 40):
        t = 1.0 - abs((x - w / 2) / (w / 2))
        a = int(20 + t * 60)
        d.line([(x, cy), (x, cy + 1)], fill=rgba((232, 190, 120), a))
    for dx in (-1, 1):
        d.polygon([(w / 2 + dx * 26, cy - 9), (w / 2 + dx * 40, cy),
                   (w / 2 + dx * 26, cy + 9), (w / 2 + dx * 13, cy)],
                  outline=rgba((240, 200, 130), 200), width=2)
    d.polygon([(w / 2, cy - 6), (w / 2 + 8, cy), (w / 2, cy + 6), (w / 2 - 8, cy)],
              fill=rgba((255, 226, 170), 220))
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def gauge(name="gauge_fill.png", fill=True):
    size = (256, 44)
    w, h = size[0] * S, size[1] * S
    if fill:
        arr = vgrad(w, h, [(0.0, (255, 240, 190, 255)), (0.35, (250, 206, 122, 255)),
                           (0.7, (226, 166, 74, 255)), (1.0, (176, 118, 40, 255))])
    else:
        arr = vgrad(w, h, [(0.0, (18, 14, 30, 240)), (0.5, (10, 8, 18, 244)),
                           (1.0, (6, 5, 12, 246))])
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 20.0, fill=255), size)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=19 * S,
                        outline=rgba((255, 236, 190), 220) if fill else rgba((212, 176, 120), 150),
                        width=max(1, int(1.3 * S)))
    d.rounded_rectangle([4 * S, 3 * S, w - 4 * S, h * 0.42 * S], radius=12 * S,
                        fill=rgba((255, 250, 226), 70 if fill else 12))
    if fill:
        img = glow_layer(img, (255, 190, 100), 5, 0.35)
    save(img, name)


def badge(name="badge.png"):
    size = (96, 96)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 6, w - 6, h - 6], fill=rgba((196, 40, 44), 255),
              outline=rgba((255, 226, 196), 200), width=5)
    d.ellipse([16, 16, w - 16, h - 16], outline=rgba((120, 18, 24), 200), width=3)
    img = glow_layer(img, (255, 90, 80), 4, 0.5)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)



def branch(name="branch.png"):
    """한지 모서리에 얹는 매화 가지(투명 배경)."""
    size = (420, 260)
    w, h = size[0] * 2, size[1] * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(9182)
    # 굵은 가지 하나 + 잔가지
    stem = [(w * 1.02, h * 0.06), (w * 0.72, h * 0.24), (w * 0.50, h * 0.44), (w * 0.30, h * 0.62)]
    for i in range(len(stem) - 1):
        d.line([stem[i], stem[i + 1]], fill=rgba((78, 52, 40), 235),
               width=int((13 - i * 3) * 2))
    twigs = [[(w * 0.62, h * 0.32), (w * 0.52, h * 0.12)],
             [(w * 0.44, h * 0.50), (w * 0.30, h * 0.30)],
             [(w * 0.36, h * 0.58), (w * 0.16, h * 0.70)]]
    for a, b in twigs:
        d.line([a, b], fill=rgba((82, 55, 42), 220), width=6)
    # 꽃잎 다발
    spots = [(0.95, 0.10), (0.86, 0.22), (0.74, 0.16), (0.66, 0.30), (0.55, 0.22),
             (0.50, 0.42), (0.40, 0.36), (0.33, 0.52), (0.25, 0.64), (0.16, 0.70),
             (0.60, 0.46), (0.80, 0.06), (0.45, 0.62)]
    for sx, sy in spots:
        cx, cy = sx * w, sy * h
        r = float(rng.uniform(13, 21)) * 2
        for k in range(5):
            a = k * math.tau / 5 + rng.uniform(-0.2, 0.2)
            px = cx + math.cos(a) * r * 0.62
            py = cy + math.sin(a) * r * 0.62
            _leaf(d, px, py, a, r * 0.62, r * 0.40,
                  rgba((236, 138, 186), 240) if k % 2 == 0 else rgba((248, 178, 212), 240),
                  rgba((255, 226, 240), 120))
        d.ellipse([cx - r * 0.20, cy - r * 0.20, cx + r * 0.20, cy + r * 0.20],
                  fill=rgba((252, 226, 158), 245))
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img = glow_layer(img, (255, 170, 210), 4, 0.25)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def reward_tile(name="tile.png"):
    """동봉 보상 타일(어두운 황동 테 + 안쪽 광)."""
    size = (192, 192)
    w, h = size[0] * S, size[1] * S
    mask = mask_from(lambda d, s: rounded_rect(d, s, size, 14.0, fill=255), size)
    arr = vgrad(w, h, [(0.0, (74, 54, 38, 250)), (0.5, (52, 37, 30, 252)), (1.0, (34, 24, 22, 252))])
    arr = grain(arr, 5.0, 1.6, 617)
    arr = apply(arr, mask)
    img = to_img(arr)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1 * S, 1 * S, w - 1 * S, h - 1 * S], radius=13 * S,
                        outline=rgba((16, 10, 8), 220), width=int(1.6 * S))
    d.rounded_rectangle([3 * S, 3 * S, w - 3 * S, h - 3 * S], radius=11 * S,
                        outline=rgba((236, 190, 122), 220), width=max(1, int(1.4 * S)))
    d.rounded_rectangle([7 * S, 7 * S, w - 7 * S, h - 7 * S], radius=8 * S,
                        outline=rgba((255, 226, 170), 60), width=max(1, int(0.7 * S)))
    for (cx, cy, dx, dy) in [(6, 6, 1, 1), (size[0] - 6, 6, -1, 1),
                             (6, size[1] - 6, 1, -1), (size[0] - 6, size[1] - 6, -1, -1)]:
        corner_curl(d, S, cx, cy, dx, dy, 10.0, rgba((255, 226, 170), 190), 0.9)
    save(img, name)



def scene_round(name="scene_round.png"):
    """업적 요약의 달빛 정자 — 게임 배경을 원형으로 부드럽게 잘라 낸다."""
    size = (384, 384)
    src = Image.open(os.path.join(os.path.dirname(__file__), "..", "assets", "woo", "codex", "codex_bg.jpg")).convert("RGB")
    w, h = src.size
    side = min(w, h)
    crop = src.crop(((w - side) // 2, int((h - side) * 0.30), (w + side) // 2, int((h - side) * 0.30) + side))
    crop = crop.resize(size, Image.LANCZOS)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([6, 6, size[0] - 6, size[1] - 6], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(3))
    img = crop.convert("RGBA")
    img.putalpha(mask)
    # 따뜻한 달빛
    warm = Image.new("RGBA", size, (255, 214, 150, 26))
    img = Image.alpha_composite(img, warm)
    img = glow_layer(img, (255, 190, 110), 5, 0.35)
    img.save(os.path.join(OUT, name))
    print(name, img.size)



def roof(name="roof.png"):
    """방 만들기 판 위에 얹는 기와 지붕 장식(깊은 남색 기와 + 금테 처마)."""
    size = (420, 200)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def top_y(t):
        return int(h * 0.46 - math.sin(math.pi * min(1.0, max(0.0, t))) * h * 0.20)

    def x_at(t):
        return int(14 + t * (w - 28))

    # 지붕 본체(두꺼운 처마)
    top = [(x_at(i / 60.0), top_y(i / 60.0)) for i in range(61)]
    bottom = [(x, y + int(h * 0.26)) for x, y in top]
    d.polygon(top + bottom[::-1], fill=rgba((22, 20, 32), 255))
    # 기와 줄
    for i in range(0, 61, 2):
        x, y = top[i]
        d.line([(x, y + 5), (x, y + int(h * 0.26) - 5)], fill=rgba((52, 50, 74), 190), width=4)
    # 기와 마루(위)
    d.line(top, fill=rgba((60, 58, 84), 255), width=int(h * 0.055), joint="curve")
    d.line(top, fill=rgba((232, 190, 120), 235), width=4, joint="curve")
    # 처마 금테와 그림자
    d.line(bottom, fill=rgba((236, 196, 126), 235), width=6, joint="curve")
    d.line([(x, y + 8) for x, y in bottom], fill=rgba((10, 8, 14), 200), width=6, joint="curve")
    # 양 끝 처마 장식
    for x, y in [top[0], top[-1]]:
        d.ellipse([x - 12, y - 12, x + 12, y + 12], fill=rgba((232, 188, 112), 245))
        d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=rgba((60, 40, 20), 240))
    # 가운데 마루 장식
    cx = w / 2
    d.polygon([(cx, top_y(0.5) - int(h * 0.10)), (cx + 22, top_y(0.5) - 4),
               (cx, top_y(0.5) + 12), (cx - 22, top_y(0.5) - 4)],
              fill=rgba((240, 196, 124), 240), outline=rgba((90, 60, 24), 240))
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img = glow_layer(img, (255, 190, 100), 4, 0.28)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def lantern(name="lantern.png"):
    """매다는 등롱(따뜻한 빛 + 붉은 술)."""
    size = (170, 320)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = w / 2
    d.line([(cx, 4), (cx, h * 0.16)], fill=rgba((150, 116, 70), 235), width=6)
    # 위 갓
    d.polygon([(cx - w * 0.24, h * 0.20), (cx + w * 0.24, h * 0.20),
               (cx + w * 0.13, h * 0.10), (cx - w * 0.13, h * 0.10)],
              fill=rgba((44, 32, 30), 255), outline=rgba((236, 190, 116), 235))
    # 몸통
    body = [(cx - w * 0.30, h * 0.22), (cx + w * 0.30, h * 0.22),
            (cx + w * 0.36, h * 0.34), (cx + w * 0.34, h * 0.60),
            (cx + w * 0.24, h * 0.72), (cx - w * 0.24, h * 0.72),
            (cx - w * 0.34, h * 0.60), (cx - w * 0.36, h * 0.34)]
    d.polygon(body, fill=rgba((255, 188, 96), 250))
    d.polygon(body, outline=rgba((96, 54, 24), 245), width=6)
    # 안쪽 빛
    d.ellipse([cx - w * 0.22, h * 0.28, cx + w * 0.22, h * 0.62], fill=rgba((255, 226, 150), 200))
    # 창살
    for i in range(1, 4):
        x = cx - w * 0.30 + i * w * 0.15
        d.line([(x, h * 0.24), (x, h * 0.70)], fill=rgba((110, 60, 28), 210), width=4)
    d.line([(cx - w * 0.34, h * 0.45), (cx + w * 0.34, h * 0.45)], fill=rgba((110, 60, 28), 200), width=4)
    # 아래 갓과 술
    d.polygon([(cx - w * 0.26, h * 0.72), (cx + w * 0.26, h * 0.72),
               (cx + w * 0.16, h * 0.80), (cx - w * 0.16, h * 0.80)],
              fill=rgba((44, 32, 30), 255), outline=rgba((236, 190, 116), 230))
    for i in range(5):
        d.line([(cx - 12 + i * 6, h * 0.80), (cx - 16 + i * 8, h * 0.95)],
               fill=rgba((190, 46, 44), 235), width=5)
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img = glow_layer(img, (255, 172, 78), 10, 0.6)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def tassel(name="tassel.png"):
    """붉은 매듭 술(한지·낙관 장식)."""
    size = (120, 300)
    w, h = size[0] * 3, size[1] * 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = w / 2
    # 매듭 구슬
    d.ellipse([cx - w * 0.24, h * 0.03, cx + w * 0.24, h * 0.16], fill=rgba((150, 32, 38), 255),
              outline=rgba((250, 208, 170), 190), width=4)
    d.ellipse([cx - w * 0.12, h * 0.065, cx + w * 0.12, h * 0.125], fill=rgba((196, 60, 58), 235))
    # 맺은 실
    d.arc([cx - w * 0.30, h * 0.12, cx + w * 0.30, h * 0.26], 0, 180, fill=rgba((212, 74, 68), 220), width=6)
    # 술(굵은 다발)
    d.polygon([(cx - w * 0.16, h * 0.17), (cx + w * 0.16, h * 0.17),
               (cx + w * 0.20, h * 0.94), (cx - w * 0.20, h * 0.94)], fill=rgba((160, 36, 44), 245))
    for i in range(9):
        x = cx - w * 0.18 + i * w * 0.045
        d.line([(x, h * 0.20), (x - 3, h * 0.93)], fill=rgba((118, 22, 30), 200), width=3)
    # 위 묶음 띠
    d.rectangle([cx - w * 0.17, h * 0.20, cx + w * 0.17, h * 0.25], fill=rgba((236, 190, 140), 210))
    img = img.resize((size[0], size[1]), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, img.size)


def main() -> None:
    ensure()
    panel("panel.png")
    panel("panel_soft.png", margin=44, fill_top=(34, 26, 50), fill_bot=(15, 12, 24), ornate=False)
    card("card.png", False)
    card("card_lit.png", True)
    button("btn_gold.png")
    button("btn_gold_pressed.png", pressed=True)
    button("btn_gold_off.png", disabled=True)
    button("btn_dark.png", dark=True)
    button("btn_dark_pressed.png", dark=True, pressed=True)
    tab("tab.png", False)
    tab("tab_lit.png", True)
    pill("pill.png")
    parchment("parchment.png")
    plaque("plaque_wood.png")
    medallion("medallion.png")
    medallion("medallion_small.png", size=(192, 192), thick=0.9)
    slot("slot.png")
    slot("ring_frame.png", hollow=True)
    ring("ring.png")
    laurel("laurel.png")
    ribbon("ribbon.png")
    vs("vs.png")
    letter("letter.png")
    tassel("tassel.png")
    divider("divider.png")
    gauge("gauge_fill.png", True)
    gauge("gauge_track.png", False)
    badge("badge.png")
    branch("branch.png")
    reward_tile("tile.png")
    scene_round("scene_round.png")
    roof("roof.png")
    lantern("lantern.png")


if __name__ == "__main__":
    main()
