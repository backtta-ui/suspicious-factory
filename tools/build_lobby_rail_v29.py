#!/usr/bin/env python3
"""2.0.29: 로비 왼쪽 메뉴 레일의 중복 '캐릭터' 메달을 지우고 도감·업적·상점 3개만 남긴다.

원화(assets/woo/lobby_bg.png)에서 메달을 그대로 잘라 쓰므로 아이콘·글자·금테 두께가
100% 같다. 먼저 레일 안쪽(메달 네 칸 전부)을 메달 없는 패널로 비우고 -위·아래 패널 색
보간에 원화 입자만 얹는다- 그 위에 메달을 아래로 길게 녹여 얹어 이음매가 보이지 않게 한다.

사용: python3 tools/build_lobby_rail_v29.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets/woo/lobby_bg.png"

# 레일 기둥의 가로 범위(메달·금테·기둥 장식선 포함).
X0, X1 = 28, 154
# 메달 자르기: (원본 위, 원본 아래, 새 위치, 아래쪽 페이드 줄 수).
# 원본 상자에는 메달 아래 그림자(밝은 테)까지 넣고, 그 테를 아래로 부드럽게 녹인다.
PATCHES = (
    ("codex", 326, 456, 200, 12),
    ("achievements", 452, 582, 389, 12),
    ("shop", 578, 702, 578, 3),
)
# 메달이 있던 네 칸과, 칸을 비울 때 기준으로 삼을 위/아래 패널 줄.
SEGMENTS = (
    (200, 326, 199, 326),
    (326, 452, 325, 452),
    (452, 578, 451, 578),
    (578, 702, 577, 702),
)
# 메달이 없는 깨끗한 띠(캐릭터 메달 아래)에서 원화 입자를 뜬다.
STRIP = (X0, 313, X1, 328)
FEATHER = 8


def grain(source: Image.Image):
    """띠에서 열별 평균을 뺀 입자만 남긴다(패널의 세로 장식선은 평균 쪽에 남는다)."""
    width, height = STRIP[2] - STRIP[0], STRIP[3] - STRIP[1]
    pixels = [[source.getpixel((STRIP[0] + x, STRIP[1] + y)) for x in range(width)] for y in range(height)]
    residual = []
    for y in range(height):
        residual.append([])
        for x in range(width):
            column = [pixels[k][x] for k in range(height)]
            average = [sum(c[i] for c in column) / height for i in range(3)]
            residual[y].append(tuple(pixels[y][x][i] - average[i] for i in range(3)))
    return residual


def clear_band(base: Image.Image, y0: int, y1: int, top: int, bottom: int, residual) -> None:
    """메달 한 칸을 위·아래 패널 색 보간과 원화 입자로 비운다."""
    height, width = y1 - y0, X1 - X0
    for y in range(height):
        t = (y + 0.5) / height
        row = residual[y % len(residual)]
        for x in range(width):
            above = base.getpixel((X0 + x, top))
            below = base.getpixel((X0 + x, bottom))
            value = []
            for i in range(3):
                blend = above[i] + (below[i] - above[i]) * t
                value.append(max(0, min(255, int(round(blend + row[x][i] * 0.85)))))
            base.putpixel((X0 + x, y0 + y), tuple(value))


def plate_mask(size, bottom_feather: int) -> Image.Image:
    """메달을 감싸는 사각 마스크. 가운데는 불투명, 가장자리만 부드럽게 사라진다."""
    width, height = size
    mask = Image.new("L", size, 0)
    pixels = mask.load()
    for y in range(height):
        top = min(1.0, y / 3)
        bottom = min(1.0, (height - 1 - y) / max(1, bottom_feather))
        for x in range(width):
            side = min(1.0, min(x, width - 1 - x) / FEATHER)
            pixels[x, y] = int(255 * min(side, top, bottom))
    return mask


def main() -> None:
    source = Image.open(ART).convert("RGB")
    base = source.copy()
    residual = grain(source)
    for y0, y1, top, bottom in SEGMENTS:
        clear_band(base, y0, y1, top, bottom, residual)
    for name, sy0, sy1, dy, fade in PATCHES:
        patch = source.crop((X0, sy0, X1, sy1))
        base.paste(patch, (X0, dy), plate_mask(patch.size, fade))
    base.save(ART)
    print("LOBBY RAIL 3 BUTTONS:", ", ".join(f"{n}@{d}" for n, _, _, d, _ in PATCHES))


if __name__ == "__main__":
    main()
