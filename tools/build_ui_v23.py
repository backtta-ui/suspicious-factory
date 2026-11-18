#!/usr/bin/env python3
"""2.0.23 UI 텍스처 베이커.

조선 다크 판타지 UI(황동 베벨 버튼 · 보랏빛 판 · 금테 카드)를 고해상도로 구워
`assets/ui/v23/`에 저장한다. 화면 코드는 이 텍스처를 9-slice로 늘려 쓴다.
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "v23")
S = 4  # 슈퍼샘플 배율


def ensure() -> None:
    os.makedirs(OUT, exist_ok=True)


def lerp(a, b, t):
    return a + (b - a) * t


def ramp(stops, t):
    """stops = [(pos, (r,g,b,a)), ...] pos 0..1"""
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]
        p1, c1 = stops[i + 1]
        if p0 <= t <= p1:
            k = 0.0 if p1 == p0 else (t - p0) / (p1 - p0)
            return tuple(int(round(lerp(c0[j], c1[j], k))) for j in range(4))
    return stops[-1][1] if t > stops[-1][0] else stops[0][1]


def vgrad(w, h, stops):
    arr = np.zeros((h, w, 4), dtype=np.float32)
    for y in range(h):
        arr[y, :] = ramp(stops, y / max(1, h - 1))
    return arr


def rounded_mask(w, h, r):
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    return img


def inner_mask(w, h, r, inset):
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([inset, inset, w - 1 - inset, h - 1 - inset],
                        radius=max(0, r - inset), fill=255)
    return img


def shifted(mask, dx, dy):
    return mask.transform(mask.size, Image.AFFINE, (1, 0, -dx, 0, 1, -dy), resample=Image.BILINEAR)


def compose(size, base: np.ndarray, mask: Image.Image) -> Image.Image:
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGBA")
    a = np.asarray(mask, dtype=np.float32) / 255.0
    arr = np.asarray(img, dtype=np.float32)
    arr[:, :, 3] *= a
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def bevel(img: Image.Image, mask: Image.Image, r: int, top=(255, 248, 226, 210),
          bottom=(20, 12, 4, 210), light=2, dark=3) -> Image.Image:
    """위쪽은 밝고 아래쪽은 어두운 1~3px 베벨을 얹는다(9-slice에서도 자연스럽게)."""
    base = np.asarray(img, dtype=np.float32).copy()
    m_in = inner_mask(*img.size, r, 2)
    # 위 하이라이트: 안쪽 마스크를 아래로 민 것과의 차이
    up = np.asarray(shifted(m_in, 0, light), dtype=np.float32) / 255.0
    left = np.asarray(shifted(m_in, light, 0), dtype=np.float32) / 255.0
    top_band = np.clip(np.asarray(m_in, dtype=np.float32) / 255.0 - up, 0, 1)
    left_band = np.clip(np.asarray(m_in, dtype=np.float32) / 255.0 - left, 0, 1)
    down = np.asarray(shifted(m_in, 0, -dark), dtype=np.float32) / 255.0
    bottom_band = np.clip(np.asarray(m_in, dtype=np.float32) / 255.0 - down, 0, 1)
    mfull = np.asarray(mask, dtype=np.float32) / 255.0
    band = (top_band + left_band) * 0.85
    for c in range(3):
        base[:, :, c] = base[:, :, c] * (1 - band) + top[c] * band
    for c in range(3):
        base[:, :, c] = base[:, :, c] * (1 - bottom_band * 0.9) + bottom[c] * (bottom_band * 0.9)
    base[:, :, 3] = np.maximum(base[:, :, 3], mfull * 255)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGBA")


def noise_layer(w, h, amount=9.0, scale=2.0):
    rng = np.random.default_rng(20261119)
    small = rng.normal(0, 1, (max(2, h // int(scale * 2)), max(2, w // int(scale * 2))))
    span=float(small.max()-small.min())+1e-6
    img = Image.fromarray(((small - small.min()) / span * 255).astype(np.uint8), "L")
    img = img.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(0.6))
    return (np.asarray(img, dtype=np.float32) / 255.0 - 0.5) * amount


def outline(img: Image.Image, mask: Image.Image, r: int, color, width=2, inset=0) -> Image.Image:
    base = np.asarray(img, dtype=np.float32).copy()
    outer = mask if inset == 0 else inner_mask(*img.size, r, inset)
    inner = inner_mask(*img.size, max(0, r - inset), inset + width)
    ring = np.clip((np.asarray(outer, dtype=np.float32) - np.asarray(inner, dtype=np.float32)) / 255.0, 0, 1)
    for c in range(3):
        base[:, :, c] = base[:, :, c] * (1 - ring) + color[c] * ring
    base[:, :, 3] = np.maximum(base[:, :, 3], np.asarray(outer, dtype=np.float32))
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGBA")


def glow_around(img: Image.Image, color, radius=6, strength=0.55) -> Image.Image:
    alpha = img.split()[3].filter(ImageFilter.GaussianBlur(radius))
    a = np.asarray(alpha, dtype=np.float32) / 255.0 * strength
    base = np.asarray(img, dtype=np.float32).copy()
    pad = img.size
    out = np.zeros_like(base)
    out[:, :, 0] = color[0]
    out[:, :, 1] = color[1]
    out[:, :, 2] = color[2]
    out[:, :, 3] = a * 255
    return Image.alpha_composite(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA"), img)


def ornament(draw: ImageDraw.ImageDraw, x, y, sx, sy, color, w):
    """모서리 필리그리: ㄱ자 황동 팔 + 말림 + 다이아몬드."""
    ax = x + sx * 34
    ay = y + sy * 34
    draw.line([(x, y), (ax, y)], fill=color, width=w)
    draw.line([(x, y), (x, ay)], fill=color, width=w)
    draw.arc([ax - 7, y - 7, ax + 7, y + 7], 0, 360, fill=color, width=max(1, w - 1))
    draw.arc([x - 7, ay - 7, x + 7, ay + 7], 0, 360, fill=color, width=max(1, w - 1))
    d = 5
    draw.polygon([(x, y - d), (x + d, y), (x, y + d), (x - d, y)], fill=color)


def save(img: Image.Image, name: str) -> None:
    img = img.resize((img.size[0] // S, img.size[1] // S), Image.LANCZOS)
    path = os.path.join(OUT, name)
    img.save(path)
    print("baked", path, img.size)


# ---------------------------------------------------------------- 금빛 베벨 버튼
def bake_gold(name: str, pressed=False, disabled=False) -> None:
    w, h = 340 * S, 96 * S
    r = int(h * 0.30)
    if disabled:
        stops = [(0, (44, 40, 36, 255)), (0.5, (30, 28, 25, 255)), (1, (18, 17, 16, 255))]
    elif pressed:
        stops = [(0, (86, 58, 16, 255)), (0.18, (150, 106, 40, 255)), (0.55, (196, 150, 66, 255)),
                 (0.85, (140, 96, 34, 255)), (1, (74, 48, 12, 255))]
    else:
        stops = [(0.0, (122, 82, 24, 255)), (0.10, (196, 148, 68, 255)), (0.30, (246, 220, 160, 255)),
                 (0.44, (233, 197, 122, 255)), (0.62, (196, 150, 70, 255)), (0.86, (146, 100, 36, 255)),
                 (1.0, (86, 56, 14, 255))]
    base = vgrad(w, h, stops)
    # 좌우로 살짝 어두운 원통 느낌
    xs = np.linspace(-1, 1, w)[None, :, None]
    shade = 1.0 - 0.16 * np.abs(xs) ** 1.6
    base[:, :, :3] *= shade
    base[:, :, :3] += noise_layer(w, h, 7.0, 3.0)[:, :, None]
    mask = rounded_mask(w, h, r)
    img = compose((w, h), base, mask)
    # 금속 테두리와 베벨
    img = outline(img, mask, r, (46, 28, 6, 255), width=int(3 * S))
    img = outline(img, mask, r, (252, 238, 200, 235), width=max(1, int(1.0 * S)), inset=int(3 * S))
    img = bevel(img, mask, r, top=(255, 250, 236, 235), bottom=(58, 34, 6, 235),
                light=int(2.0 * S), dark=int(3.0 * S))
    # 위쪽 유리 광택
    d = ImageDraw.Draw(img)
    gloss_h = int(h * 0.40)
    gloss = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss)
    gd.rounded_rectangle([int(6 * S), int(4 * S), w - int(6 * S), gloss_h],
                         radius=int(r * 0.8), fill=(255, 252, 240, 70))
    gloss = gloss.filter(ImageFilter.GaussianBlur(1.4 * S))
    gm = np.asarray(rounded_mask(w, h, r), dtype=np.float32) / 255.0
    garr = np.asarray(gloss, dtype=np.float32).copy()
    garr[:, :, 3] *= gm
    gloss = Image.fromarray(np.clip(garr, 0, 255).astype(np.uint8), "RGBA")
    img = Image.alpha_composite(img, gloss)
    if not disabled:
        # 양끝 다이아몬드 장식
        o = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        od = ImageDraw.Draw(o)
        cy = h // 2
        for side in (0, 1):
            cx = int((18 if side == 0 else w - 18) * 1.0)
            cx = int(16 * S) if side == 0 else w - int(16 * S)
            s = 5 * S
            od.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)], fill=(60, 36, 8, 200))
            s2 = int(s * 0.62)
            od.polygon([(cx, cy - s2), (cx + s2, cy), (cx, cy + s2), (cx - s2, cy)],
                       fill=(255, 238, 198, 240))
        img = Image.alpha_composite(img, o.filter(ImageFilter.GaussianBlur(0.4 * S)))
    save(img, name)


# ---------------------------------------------------------------- 철제 보조 버튼
def bake_iron(name: str, pressed=False) -> None:
    w, h = 340 * S, 96 * S
    r = int(h * 0.30)
    stops = [(0, (58, 62, 82, 255)), (0.16, (40, 44, 62, 255)), (0.5, (26, 30, 46, 255)),
             (0.86, (18, 21, 33, 255)), (1, (12, 14, 22, 255))]
    if pressed:
        stops = [(0, (24, 26, 38, 255)), (0.5, (16, 18, 28, 255)), (1, (10, 11, 18, 255))]
    base = vgrad(w, h, stops)
    base[:, :, :3] += noise_layer(w, h, 5.0, 2.4)[:, :, None]
    mask = rounded_mask(w, h, r)
    img = compose((w, h), base, mask)
    img = outline(img, mask, r, (8, 8, 14, 255), width=int(3 * S))
    img = outline(img, mask, r, (201, 158, 88, 225), width=max(1, int(1.2 * S)), inset=int(3.4 * S))
    img = bevel(img, mask, r, top=(150, 156, 186, 150), bottom=(4, 4, 8, 235),
                light=int(2.0 * S), dark=int(3.0 * S))
    save(img, name)


# ---------------------------------------------------------------- 보랏빛 판
def bake_panel(name: str, w=360, h=260, r=20, gold=True) -> None:
    W, H = w * S, h * S
    R = r * S
    stops = [(0.00, (38, 36, 74, 246)), (0.30, (28, 27, 58, 246)), (0.68, (18, 18, 40, 250)),
             (1.00, (11, 11, 26, 252))]
    base = vgrad(W, H, stops)
    # 위쪽 은은한 광
    yy = np.linspace(0, 1, H)[:, None]
    glow = np.clip(1.0 - yy / 0.45, 0, 1) ** 2
    base[:, :, 0] += glow[:, :] * 22
    base[:, :, 1] += glow[:, :] * 20
    base[:, :, 2] += glow[:, :] * 30
    base[:, :, :3] += noise_layer(W, H, 4.0, 4.0)[:, :, None]
    mask = rounded_mask(W, H, R)
    img = compose((W, H), base, mask)
    img = outline(img, mask, R, (5, 5, 10, 255), width=int(3 * S))
    img = outline(img, mask, R, (196, 155, 89, 240) if gold else (120, 120, 150, 220),
                  width=max(1, int(1.6 * S)), inset=int(3.2 * S))
    img = outline(img, mask, R, (196, 155, 89, 90), width=max(1, int(0.8 * S)), inset=int(8 * S))
    img = bevel(img, mask, R, top=(255, 238, 200, 60), bottom=(0, 0, 0, 150),
                light=int(2 * S), dark=int(4 * S))
    if gold:
        o = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(o)
        c = (232, 199, 138, 235)
        for sx, sy, x, y in ((1, 1, 6 * S, 6 * S), (-1, 1, W - 6 * S, 6 * S),
                             (1, -1, 6 * S, H - 6 * S), (-1, -1, W - 6 * S, H - 6 * S)):
            od2 = ImageDraw.Draw(o)
            ax = x + sx * int(26 * S) if False else x
            # ㄱ자 팔
            end_x = x + sx * int(30 * S)
            end_y = y + sy * int(30 * S)
            od2.line([(x, y), (end_x, y)], fill=c, width=int(1.6 * S))
            od2.line([(x, y), (x, end_y)], fill=c, width=int(1.6 * S))
            # 말림
            rr = int(4.4 * S)
            od2.arc([end_x - rr, y - rr, end_x + rr, y + rr], 0, 360, fill=c, width=int(1.0 * S))
            od2.arc([x - rr, end_y - rr, x + rr, end_y + rr], 0, 360, fill=c, width=int(1.0 * S))
            d = int(3.2 * S)
            od2.polygon([(x, y - d), (x + d, y), (x, y + d), (x - d, y)], fill=(255, 236, 188, 250))
        # 위·아래 가운데 장식
        for cy, dy in ((4 * S, 1), (H - 4 * S, -1)):
            d = int(3.6 * S)
            od.polygon([(W // 2, cy - d * dy), (W // 2 + d, cy), (W // 2, cy + d * dy), (W // 2 - d, cy)],
                       fill=(246, 214, 152, 240))
            od.line([(W // 2 - int(20 * S), cy), (W // 2 + int(20 * S), cy)], fill=(196, 155, 89, 120),
                    width=int(0.9 * S))
        img = Image.alpha_composite(img, o.filter(ImageFilter.GaussianBlur(0.35 * S)))
    save(img, name)


def bake_card(name: str, lit=False, w=220, h=220, r=14) -> None:
    W, H = w * S, h * S
    R = r * S
    if lit:
        stops = [(0.00, (54, 44, 30, 248)), (0.26, (34, 30, 28, 250)), (0.72, (20, 19, 22, 252)),
                 (1.00, (12, 12, 17, 253))]
    else:
        stops = [(0.00, (34, 34, 62, 244)), (0.40, (24, 24, 46, 250)), (1.00, (12, 13, 26, 252))]
    base = vgrad(W, H, stops)
    base[:, :, :3] += noise_layer(W, H, 4.0, 3.0)[:, :, None]
    mask = rounded_mask(W, H, R)
    img = compose((W, H), base, mask)
    img = outline(img, mask, R, (4, 4, 8, 255), width=int(2.4 * S))
    edge = (255, 233, 176, 255) if lit else (186, 150, 92, 210)
    img = outline(img, mask, R, edge, width=max(1, int((2.6 if lit else 1.6) * S)), inset=int(2.6 * S))
    img = outline(img, mask, R, (edge[0], edge[1], edge[2], 150 if lit else 80), width=max(1, int(1.0 * S)), inset=int(7 * S))
    img = bevel(img, mask, R, top=(255, 240, 205, 90 if lit else 45), bottom=(0, 0, 0, 150),
                light=int(1.6 * S), dark=int(3 * S))

    o = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(o)
    c = (255, 236, 186, 250) if lit else (176, 142, 88, 190)
    for sx, sy, x, y in ((1, 1, 5 * S, 5 * S), (-1, 1, W - 5 * S, 5 * S),
                         (1, -1, 5 * S, H - 5 * S), (-1, -1, W - 5 * S, H - 5 * S)):
        end_x, end_y = x + sx * int(14 * S), y + sy * int(14 * S)
        od.line([(x, y), (end_x, y)], fill=c, width=int(1.3 * S))
        od.line([(x, y), (x, end_y)], fill=c, width=int(1.3 * S))
        d = int(2.6 * S)
        od.polygon([(x, y - d), (x + d, y), (x, y + d), (x - d, y)], fill=(255, 240, 200, 250))
    img = Image.alpha_composite(img, o.filter(ImageFilter.GaussianBlur(0.3 * S)))
    save(img, name)


def bake_tab(name: str, lit=False, w=150, h=84, r=12) -> None:
    W, H = w * S, h * S
    R = r * S
    if lit:
        stops = [(0.00, (72, 58, 40, 250)), (0.35, (44, 38, 34, 252)), (1.00, (20, 18, 22, 253))]
    else:
        stops = [(0.00, (30, 30, 54, 246)), (0.45, (20, 21, 40, 250)), (1.00, (11, 12, 24, 252))]
    base = vgrad(W, H, stops)
    base[:, :, :3] += noise_layer(W, H, 4.0, 3.0)[:, :, None]
    mask = rounded_mask(W, H, R)
    img = compose((W, H), base, mask)
    img = outline(img, mask, R, (4, 4, 8, 255), width=int(2.4 * S))
    edge = (255, 232, 178, 255) if lit else (150, 128, 92, 190)
    img = outline(img, mask, R, edge, width=max(1, int((2.2 if lit else 1.5) * S)), inset=int(2.2 * S))
    img = bevel(img, mask, R, top=(255, 240, 205, 80 if lit else 40), bottom=(0, 0, 0, 150),
                light=int(1.6 * S), dark=int(2.6 * S))

    save(img, name)


def bake_plaque(name: str, w=260, h=64, r=14) -> None:
    W, H = w * S, h * S
    R = r * S
    stops = [(0.00, (56, 46, 30, 250)), (0.35, (40, 33, 22, 252)), (0.72, (26, 22, 16, 252)),
             (1.00, (16, 14, 11, 253))]
    base = vgrad(W, H, stops)
    base[:, :, :3] += noise_layer(W, H, 4.0, 2.4)[:, :, None]
    mask = rounded_mask(W, H, R)
    img = compose((W, H), base, mask)
    img = outline(img, mask, R, (4, 3, 3, 255), width=int(2.2 * S))
    img = outline(img, mask, R, (206, 166, 98, 235), width=max(1, int(1.4 * S)), inset=int(2.2 * S))
    img = bevel(img, mask, R, top=(255, 238, 200, 70), bottom=(0, 0, 0, 150),
                light=int(1.4 * S), dark=int(2.4 * S))
    save(img, name)


def bake_slot(name: str, w=96, h=96, r=10) -> None:
    W, H = w * S, h * S
    R = r * S
    stops = [(0.0, (46, 40, 58, 250)), (0.6, (24, 22, 36, 252)), (1.0, (12, 12, 22, 253))]
    base = vgrad(W, H, stops)
    mask = rounded_mask(W, H, R)
    img = compose((W, H), base, mask)
    img = outline(img, mask, R, (4, 4, 8, 255), width=int(2.0 * S))
    img = outline(img, mask, R, (198, 158, 92, 220), width=max(1, int(1.3 * S)), inset=int(2.0 * S))
    img = bevel(img, mask, R, top=(255, 240, 205, 60), bottom=(0, 0, 0, 160),
                light=int(1.2 * S), dark=int(2.2 * S))
    save(img, name)


def main() -> None:
    ensure()
    bake_gold("btn_gold.png")
    bake_gold("btn_gold_pressed.png", pressed=True)
    bake_gold("btn_gold_disabled.png", disabled=True)
    bake_iron("btn_iron.png")
    bake_iron("btn_iron_pressed.png", pressed=True)
    bake_panel("panel_large.png")
    bake_panel("panel_soft.png", w=300, h=200, r=16, gold=False)
    bake_card("card_normal.png")
    bake_card("card_lit.png", lit=True)
    bake_tab("tab_normal.png")
    bake_tab("tab_lit.png", lit=True)
    bake_plaque("plaque.png")
    bake_slot("slot.png")
    print("UI V23 TEXTURES DONE")


if __name__ == "__main__":
    main()
