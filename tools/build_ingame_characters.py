#!/usr/bin/env python3
"""인게임 2.5D 캐릭터 시트(초록 크로마키)를 4방향 알파 스프라이트로 분할한다.

`images`로 만든 시트는 가로 4칸(앞·뒤·좌·우)이고 단색 초록 배경이므로
칸마다 알파를 뽑고 내용 경계로 잘라 `assets/woo/ingame/<id>-<dir>.png` 로 저장한다.
세로 기준을 캐릭터별로 통일해 방향이 바뀌어도 크기가 튀지 않는다.
사용: python3 tools/build_ingame_characters.py
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art_sources" / "ingame"
OUT = ROOT / "assets" / "woo" / "ingame"
SHEET_MAX = 760          # 한 방향 스프라이트의 최대 변(모바일 텍스처 예산)
CHARACTERS = ["woochi", "yeonhwa", "muyeong", "hongryeon", "gumiho", "jangsanbeom", "dokkaebi", "haechi"]
DIRECTIONS = ["front", "back", "left", "right"]


def chroma(image: Image.Image) -> Image.Image:
    """단색 초록 배경을 알파로 바꾸고 초록 번짐을 제거한다."""
    data = np.asarray(image.convert("RGB")).astype(np.float32)
    r, g, b = data[..., 0], data[..., 1], data[..., 2]
    dominance = g - np.maximum(r, b)
    alpha = np.clip((58.0 - dominance) / 58.0, 0.0, 1.0)
    alpha[dominance < 16] = 1.0
    spill = np.clip((g - np.maximum(r, b)) * 0.85, 0, None)
    g = np.clip(g - spill, 0, 255)
    rgba = np.dstack([r, g, b, alpha * 255.0]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA")
    box = out.getbbox()
    return out.crop(box) if box else out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest: dict = {"source": "res://art_sources/ingame", "target_height": 56.0, "characters": {}}
    for character in CHARACTERS:
        sheet_path = SRC / f"{character}-sheet-raw.png"
        if not sheet_path.exists():
            raise SystemExit(f"missing sheet {sheet_path}")
        sheet = Image.open(sheet_path).convert("RGB")
        width, height = sheet.size
        cells = {}
        for index, direction in enumerate(DIRECTIONS):
            cell = sheet.crop((width * index // 4, 0, width * (index + 1) // 4, height))
            cells[direction] = chroma(cell)
        tallest = max(image.height for image in cells.values())
        ratio = min(1.0, SHEET_MAX / tallest)
        # 캐릭터별 공통 배율: 방향이 바뀌어도 키가 같다.
        scale = manifest["target_height"] / (tallest * ratio)
        entry = {"scale": round(scale, 6), "height": round(tallest * ratio, 2), "directions": {}}
        for direction, image in cells.items():
            if ratio < 1.0:
                image = image.resize((max(1, int(image.width * ratio)), max(1, int(image.height * ratio))), Image.LANCZOS)
            path = OUT / f"{character}-{direction}.png"
            image.save(path, optimize=True)
            entry["directions"][direction] = {
                "path": f"res://assets/woo/ingame/{path.name}",
                "size": [image.width, image.height],
                "scale": round(scale, 6),
                "foot": [round(image.width / 2.0, 2), float(image.height)],
            }
        manifest["characters"][character] = entry
        print(character, "->", [f"{d}:{entry['directions'][d]['size']}" for d in DIRECTIONS])
    (OUT / "frames.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print("wrote", OUT / "frames.json")


if __name__ == "__main__":
    main()
