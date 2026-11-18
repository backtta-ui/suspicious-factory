#!/usr/bin/env python3
"""캐릭터 도감 초상화·전신 원화를 인게임 원화에서 다시 만들어 외형을 1:1로 통일한다.

`images --edit`로 인게임 정면 원화를 레퍼런스로 만든 초록 배경 시트를
크로마키·크롭해 assets/woo/codex/<id>-portrait.png / <id>-full.png 로 저장한다.
사용: python3 tools/build_codex_art.py
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art_sources" / "codex_art"
OUT = ROOT / "assets" / "woo" / "codex"
CHARACTERS = ["woochi", "yeonhwa", "muyeong", "hongryeon", "gumiho", "jangsanbeom", "dokkaebi", "haechi"]
MAX_SIDE = 760


def chroma(path: Path) -> Image.Image:
    data = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    r, g, b = data[..., 0], data[..., 1], data[..., 2]
    dominance = g - np.maximum(r, b)
    alpha = np.clip((60.0 - dominance) / 60.0, 0.0, 1.0)
    alpha[dominance < 16] = 1.0
    spill = np.clip((g - np.maximum(r, b)) * 0.85, 0, None)
    g = np.clip(g - spill, 0, 255)
    rgba = np.dstack([r, g, b, alpha * 255.0]).astype(np.uint8)
    image = Image.fromarray(rgba, "RGBA")
    box = image.getbbox()
    return image.crop(box) if box else image


def fit(image: Image.Image) -> Image.Image:
    longest = max(image.size)
    if longest <= MAX_SIDE:
        return image
    ratio = MAX_SIDE / longest
    return image.resize((max(1, int(image.width * ratio)), max(1, int(image.height * ratio))), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for character in CHARACTERS:
        for kind in ("portrait", "full"):
            path = SRC / f"{character}-{kind}.png"
            if not path.exists():
                print("skip", path.name)
                continue
            image = fit(chroma(path))
            image.save(OUT / f"{character}-{kind}.png", optimize=True)
            print(character, kind, image.size)


if __name__ == "__main__":
    main()
