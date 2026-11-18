#!/usr/bin/env python3
"""발밑 접지 그림자 원화(assets/woo/seowon/shadow_soft.png) 생성.

검은 사각형 대신, 형태를 따라 부드럽게 번지는 타원 그림자를 스프라이트로 쓴다.
한 장을 늘려 쓰므로 사물·건물·나무 어디에나 같은 결로 깔린다.
"""
from pathlib import Path

import cv2
import numpy as np

OUT = Path(__file__).resolve().parents[1] / "assets" / "woo" / "seowon" / "shadow_soft.png"
SIZE = 256
PEAK = 0.62


def main() -> None:
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
    cx, cy = SIZE * 0.5, SIZE * 0.5
    d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / (SIZE * 0.5)
    falloff = np.clip(1.0 - d, 0.0, 1.0) ** 1.9
    # 중심을 살짝 진하게, 바깥은 완전히 사라지게.
    alpha = (falloff * PEAK * 255.0).astype(np.uint8)
    image = np.zeros((SIZE, SIZE, 4), np.uint8)
    image[..., 0] = 10
    image[..., 1] = 12
    image[..., 2] = 22
    image[..., 3] = alpha
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(OUT), image)
    print("saved", OUT, OUT.stat().st_size // 1024, "KiB")


if __name__ == "__main__":
    main()
