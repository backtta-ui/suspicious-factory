#!/usr/bin/env python3
"""2.0.30 검수 이미지 합성: 미니맵 두 장과 등불끄기 전/후를 한 장씩으로 묶는다."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

DL = Path("/workspace/downloads")
FONT = Path("/workspace/repo/assets/fonts/NotoSansCJK-Regular.ttc")
BG = (18, 22, 34)
GOLD = (226, 192, 124)
INK = (235, 232, 240)


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT), size)
    except Exception:
        return ImageFont.load_default()


def panel(path: Path, size: tuple[int, int], box: tuple[int, int, int, int] | None = None) -> Image.Image:
    im = Image.open(path).convert("RGB")
    if box is not None:
        im = im.crop(box)
    scale = min(size[0] / im.width, size[1] / im.height)
    fitted = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGB", size, BG)
    canvas.paste(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
    return canvas


def compose(left: Path, right: Path, out: Path, left_label: str, right_label: str,
            title: str, box: tuple[int, int, int, int] | None = None) -> None:
    cell = (1060, 930)
    margin, header = 30, 92
    width = margin * 2 + cell[0] * 2 + margin
    height = header + cell[1] + margin
    canvas = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    draw.text((margin, 26), title, font=font(38), fill=GOLD)
    for i, (path, label) in enumerate(((left, left_label), (right, right_label))):
        x = margin + i * (cell[0] + margin)
        canvas.paste(panel(path, cell, box), (x, header))
        draw.rectangle([x, header, x + cell[0] - 1, header + cell[1] - 1], outline=(70, 84, 116), width=2)
        strip = Image.new("RGB", (cell[0], 44), (12, 15, 24))
        canvas.paste(strip, (x, header))
        draw.text((x + 14, header + 8), label, font=font(28), fill=INK)
    canvas.save(out)
    print("COMPOSED", out, canvas.size)


def main() -> None:
    compose(DL / "v2030_minimap_daoist.png", DL / "v2030_minimap_yokai.png",
            DL / "v2030_minimap_skills.png",
            "도사 시점 · 같은 팀(파랑)만", "요괴 시점 · 같은 팀(빨강) + 탐지 도술 동안만 적",
            "2.0.30 미니맵 · 맵 구조 + 같은 팀만, 적은 탐지 도술 동안만",
            box=(700, 180, 1660, 1010))
    showcase()
    compose(DL / "v2030_lantern_before.png", DL / "v2030_lantern_after.png",
            DL / "v2030_lantern_off.png",
            "등불끄기 전 · 석등 불빛 켜짐", "등불끄기 후 · 불빛 꺼짐 + 먹빛 연막·불씨",
            "2.0.30 등불끄기 · 단색 원이 아닌 연막 안개 연출", box=(360, 140, 1980, 1010))


def showcase() -> None:
    names = [
        ("daoist_woochi", "전우치 · 분신술"), ("daoist_honggildong", "홍길동 · 바람발"),
        ("daoist_jangyeongsil", "장영실 · 천문기계"), ("daoist_barigongju", "바리공주 · 생명등불"),
        ("daoist_gangnim", "강림도령 · 귀문보기"), ("yokai_gumiho", "구미호 · 구미환몽"),
        ("yokai_jangsanbeom", "장산범 · 산군의 울음"), ("yokai_dokkaebi", "도깨비 · 도깨비잔치"),
        ("yokai_eodubsimi", "어둑시니 · 등불끄기"), ("yokai_yagwangwi", "야광귀 · 신발흔적"),
    ]
    cell = (420, 300)
    margin, header, gap = 24, 70, 12
    width = margin * 2 + cell[0] * 5 + gap * 4
    height = header + (cell[1] + 34) * 2 + gap + margin
    canvas = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    draw.text((margin, 18), "2.0.30 캐릭터별 도술 연출 · 10인 30종 고유 이펙트", font=font(30), fill=GOLD)
    for i, (key, label) in enumerate(names):
        col, row = i % 5, i // 5
        x = margin + col * (cell[0] + gap)
        y = header + row * (cell[1] + 34 + gap)
        path = DL / f"v2030_fx_{key}.png"
        if not path.exists():
            continue
        canvas.paste(panel(path, cell, (640, 150, 1740, 900)), (x, y))
        draw.text((x + 6, y + cell[1] + 4), label, font=font(20), fill=INK)
    canvas.save(DL / "v2030_fx_showcase.png")
    print("COMPOSED", DL / "v2030_fx_showcase.png", canvas.size)


if __name__ == "__main__":
    main()
