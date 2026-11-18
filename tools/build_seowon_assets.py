#!/usr/bin/env python3
"""월하의 서원 2.5D 원화 에셋의 크로마키·크롭·분할.

`images`로 만든 원화는 단색 초록 배경이므로 알파를 뽑고,
사물 시트는 5칸으로 잘라 개별 스프라이트로 저장한다.
사용: python3 tools/build_seowon_assets.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "woo" / "seowon"
ORIGINALS = ROOT / "art_sources" / "seowon"


def chroma(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGB")
    data = np.asarray(image).astype(np.float32)
    r, g, b = data[..., 0], data[..., 1], data[..., 2]
    dominance = g - np.maximum(r, b)
    alpha = np.clip((60.0 - dominance) / 60.0, 0.0, 1.0)
    alpha[dominance < 18] = 1.0
    # 초록 번짐 제거
    spill = np.clip((g - np.maximum(r, b)) * 0.8, 0, None)
    g = np.clip(g - spill, 0, 255)
    rgba = np.dstack([r, g, b, alpha * 255.0]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA")
    box = out.getbbox()
    return out.crop(box) if box else out


def main() -> None:
    ORIGINALS.mkdir(parents=True, exist_ok=True)
    for path in SRC.glob("*.png"):
        if path.name.startswith("prop_"):
            continue
        original = ORIGINALS / path.name
        if not original.exists():
            original.write_bytes(path.read_bytes())
    ground = Image.open(SRC / "ground_night.png").convert("RGB")
    ground.save(SRC / "ground_night.png", optimize=True)
    ground.resize((512, 512), Image.LANCZOS).save(SRC / "ground_tile.png", optimize=True)
    for name in ["hanok_exterior.png", "hanok_interior.png", "wall_h.png", "bamboo_cluster.png"]:
        sprite = chroma(ORIGINALS / name)
        longest = max(sprite.size)
        if longest > 760:
            ratio = 760.0 / longest
            sprite = sprite.resize((int(sprite.size[0] * ratio), int(sprite.size[1] * ratio)), Image.LANCZOS)
        sprite.save(SRC / name, optimize=True)
        print(name, sprite.size)
    # 사물 시트(5칸) 분할
    sheet = Image.open(ORIGINALS / "props_atlas.png").convert("RGB")
    width, height = sheet.size
    names = ["jar", "crate", "stele", "lantern", "cat"]
    for index, label in enumerate(names):
        cell = sheet.crop((width * index // 5, 0, width * (index + 1) // 5, height))
        cell.save(ORIGINALS / f"cell_{label}.png")
        sprite = chroma(ORIGINALS / f"cell_{label}.png")
        ratio = min(1.0, 360.0 / max(sprite.size))
        if ratio < 1.0:
            sprite = sprite.resize((int(sprite.size[0] * ratio), int(sprite.size[1] * ratio)), Image.LANCZOS)
        sprite.save(SRC / f"prop_{label}.png", optimize=True)
        print(f"prop_{label}.png", sprite.size)


if __name__ == "__main__":
    main()
