#!/usr/bin/env python3
"""인게임 캐릭터 걷기 2프레임을 알파 스프라이트로 잘라 frames.json에 등록한다.

`images --edit`로 만든 2칸 시트(초록 배경)를 칸별로 크로마키·크롭한 뒤,
정지 원화와 같은 발바닥 기준선·키로 정렬한다. 저장 해상도는 60%로 줄이고
프레임별 scale을 키워 월드 크기를 정지 원화와 똑같이 유지한다(APK 용량 절감).
사용: python3 tools/build_ingame_walk.py
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art_sources" / "ingame_walk"
OUT = ROOT / "assets" / "woo" / "ingame"
MANIFEST = OUT / "frames.json"
CHARACTERS = ["woochi", "yeonhwa", "muyeong", "hongryeon", "gumiho", "jangsanbeom", "dokkaebi", "haechi"]
DIRECTIONS = ["front", "back", "left", "right"]
STORE = 0.6


def chroma(image: Image.Image) -> Image.Image:
    """단색 초록 배경을 알파로 바꾸고 초록 번짐을 제거한다."""
    data = np.asarray(image.convert("RGB")).astype(np.float32)
    r, g, b = data[..., 0], data[..., 1], data[..., 2]
    dominance = g - np.maximum(r, b)
    alpha = np.clip((60.0 - dominance) / 60.0, 0.0, 1.0)
    alpha[dominance < 16] = 1.0
    spill = np.clip((g - np.maximum(r, b)) * 0.85, 0, None)
    g = np.clip(g - spill, 0, 255)
    rgba = np.dstack([r, g, b, alpha * 255.0]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA")
    box = out.getbbox()
    return out.crop(box) if box else out


def place_on_baseline(sprite: Image.Image, height: int, width: int) -> Image.Image:
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = (width - sprite.width) // 2
    y = height - sprite.height
    canvas.alpha_composite(sprite, (max(0, x), max(0, y)))
    return canvas


def main() -> None:
    manifest = json.loads(MANIFEST.read_text())
    made = 0
    for character in CHARACTERS:
        entry = manifest["characters"].get(character)
        if entry is None:
            continue
        for direction in DIRECTIONS:
            sheet_path = SRC / f"{character}-{direction}.png"
            if not sheet_path.exists():
                continue
            direction_entry = entry["directions"].get(direction)
            if direction_entry is None:
                continue
            idle_height = int(direction_entry["size"][1])
            idle_scale = float(direction_entry.get("scale", entry.get("scale", 1.0)))
            sheet = Image.open(sheet_path).convert("RGB")
            width, height = sheet.size
            cells = []
            for index in range(2):
                cell = sheet.crop((width * index // 2, 0, width * (index + 1) // 2, height))
                cells.append(chroma(cell))
            widest = max(cell.width for cell in cells)
            frames = []
            # 두 칸의 평균 높이를 정지 원화 키에 맞춘다(걷기 자세의 높이 차이는 남긴다).
            reference = float(np.mean([cell.height for cell in cells]))
            ratio = idle_height / max(1.0, reference)
            for index, cell in enumerate(cells):
                scaled = cell.resize((max(1, int(round(cell.width * ratio))), max(1, int(round(cell.height * ratio)))), Image.LANCZOS)
                canvas_w = max(1, int(round(widest * ratio)))
                canvas = place_on_baseline(scaled, idle_height, canvas_w)
                stored = canvas.resize((max(1, int(round(canvas.width * STORE))), max(1, int(round(canvas.height * STORE)))), Image.LANCZOS)
                path = OUT / f"{character}-{direction}-walk{index + 1}.png"
                stored.save(path, optimize=True)
                frames.append({
                    "path": f"res://assets/woo/ingame/{path.name}",
                    "size": [stored.width, stored.height],
                    "scale": round(idle_scale * idle_height / stored.height, 6),
                })
            direction_entry["walk"] = frames
            made += 1
            print(f"{character}-{direction} walk {frames[0]['size']} / {frames[1]['size']}")
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print("walk directions:", made, "manifest:", MANIFEST)


if __name__ == "__main__":
    main()
