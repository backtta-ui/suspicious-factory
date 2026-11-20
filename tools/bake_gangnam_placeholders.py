#!/usr/bin/env python3
"""강남역 맵 에셋 플레이스홀더 베이커 (2.0.34).

병렬 에셋 작업(work/v34_gangnam_assets/out)이 도착하기 전까지 게임이 실제로
돌아가도록, 같은 파일 이름·같은 픽셀 규격의 깔끔한 임시 원화를 만든다.
에셋이 도착하면 같은 이름으로 덮어쓰기만 하면 게임 코드는 그대로 둔다.

    python3 tools/bake_gangnam_placeholders.py
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "woo", "gangnam")
SS = 4  # 슈퍼샘플 배율


def canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def finish(img: Image.Image, w: int, h: int, name: str) -> None:
    img = img.resize((w, h), Image.LANCZOS)
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", os.path.relpath(path, os.path.join(os.path.dirname(__file__), "..")))


def rr(d: ImageDraw.ImageDraw, box, radius, fill=None, outline=None, width=1):
    d.rounded_rectangle([v * SS for v in box], radius=radius * SS, fill=fill, outline=outline, width=width * SS)


def rect(d: ImageDraw.ImageDraw, box, fill=None, outline=None, width=1):
    d.rectangle([v * SS for v in box], fill=fill, outline=outline, width=width * SS)


def poly(d: ImageDraw.ImageDraw, points, fill=None, outline=None, width=1):
    d.polygon([(x * SS, y * SS) for x, y in points], fill=fill, outline=outline, width=width * SS)


def ellipse(d: ImageDraw.ImageDraw, box, fill=None, outline=None, width=1):
    d.ellipse([v * SS for v in box], fill=fill, outline=outline, width=width * SS)


def line(d: ImageDraw.ImageDraw, points, fill, width=2):
    d.line([(x * SS, y * SS) for x, y in points], fill=fill, width=width * SS)


def glow(img: Image.Image, blur=6, alpha=150) -> Image.Image:
    layer = img.filter(ImageFilter.GaussianBlur(blur * SS / 4))
    # 알파만 남겨 겹친다
    a = layer.split()[3].point(lambda v: min(255, int(v * alpha / 255)))
    layer.putalpha(a)
    return Image.alpha_composite(layer, img)


NAVY = (18, 24, 38, 255)
NAVY_L = (34, 46, 68, 255)
STEEL = (96, 112, 138, 255)
WHITE = (236, 243, 252, 255)
CYAN = (86, 224, 255, 255)
PINK = (255, 95, 168, 255)
YELLOW = (255, 213, 74, 255)
RED = (232, 66, 72, 255)
MINT = (120, 232, 196, 255)
BROWN = (120, 82, 56, 255)


def prop_iced_coffee():
    w, h = 120, 176
    img, d = canvas(w, h)
    # 컵
    poly(d, [(34, 62), (88, 62), (80, 158), (42, 158)], fill=(246, 249, 255, 255), outline=(198, 212, 232, 255), width=2)
    poly(d, [(34, 62), (88, 62), (84, 96), (38, 96)], fill=(216, 232, 248, 255))
    # 커피
    ellipse(d, (40, 52, 82, 78), fill=(96, 60, 40, 255), outline=(150, 106, 78, 255), width=2)
    ellipse(d, (46, 56, 76, 70), fill=(70, 42, 28, 255))
    # 얼음
    for x, y, s in ((52, 64, 12), (66, 70, 10), (58, 78, 9)):
        rr(d, (x, y, x + s, y + s), 2, fill=(226, 240, 255, 210), outline=(180, 206, 234, 220), width=1)
    # 빨대
    line(d, [(64, 58), (78, 8)], (255, 120, 150, 255), 6)
    line(d, [(66, 58), (80, 10)], (255, 186, 204, 255), 2)
    finish(img, w, h, "props/prop_iced_coffee.png")


def prop_vending_machine():
    w, h = 190, 300
    img, d = canvas(w, h)
    rr(d, (10, 8, 180, 292), 10, fill=NAVY, outline=(58, 74, 104, 255), width=3)
    rr(d, (22, 22, 168, 150), 6, fill=(28, 40, 60, 255), outline=CYAN, width=2)
    # 진열된 음료
    colors = [(255, 120, 120), (255, 205, 96), (140, 220, 255), (150, 240, 190), (255, 160, 220)]
    for i in range(5):
        x = 30 + i * 28
        rr(d, (x, 44, x + 18, 92), 4, fill=(*colors[i % len(colors)], 255), outline=(255, 255, 255, 120), width=1)
        rect(d, (x + 2, 92, x + 16, 100), (60, 74, 96, 255))
    # 버튼 패널·배출구
    rr(d, (24, 160, 96, 210), 4, fill=(22, 32, 50, 255), outline=(90, 120, 160, 255), width=1)
    for i in range(3):
        ellipse(d, (32 + i * 20, 166, 44 + i * 20, 178), fill=(255, 220, 120, 255))
    rr(d, (116, 160, 164, 232), 4, fill=(16, 24, 38, 255), outline=(80, 104, 140, 255), width=1)
    rect(d, (46, 240, 148, 276), (10, 16, 28, 255), outline=(80, 104, 140, 255), width=2)
    # 네온 라인
    line(d, [(228, 24), (228, 280)], CYAN, 3)
    img = glow(img, 5, 90)
    finish(img, w, h, "props/prop_vending_machine.png")


def prop_kiosk():
    w, h = 180, 300
    img, d = canvas(w, h)
    rr(d, (24, 30, 156, 120), 8, fill=(30, 40, 58, 255), outline=(90, 116, 152, 255), width=3)
    rr(d, (34, 40, 146, 110), 4, fill=(120, 226, 255, 255))
    rr(d, (46, 56, 118, 66), 4, fill=(24, 46, 66, 230))
    rr(d, (46, 74, 134, 82), 4, fill=(24, 46, 66, 180))
    rr(d, (46, 90, 100, 98), 4, fill=(24, 46, 66, 180))
    rect(d, (58, 120, 122, 268), fill=(22, 30, 46, 255), outline=(70, 90, 120, 255), width=2)
    rect(d, (74, 132, 106, 250), fill=(16, 22, 36, 255), outline=(56, 72, 100, 255), width=1)
    rr(d, (40, 262, 140, 284), 6, fill=(40, 54, 78, 255))
    line(d, [(24, 120), (156, 120)], CYAN, 2)
    finish(img, w, h, "props/prop_kiosk.png")


def prop_banner():
    w, h = 150, 260
    img, d = canvas(w, h)
    # A자 스탠드
    line(d, [(30, 250), (66, 30)], STEEL, 5)
    line(d, [(120, 250), (84, 30)], STEEL, 5)
    rr(d, (26, 18, 126, 196), 6, fill=(28, 22, 46, 255), outline=PINK, width=3)
    rect(d, (34, 30, 118, 40), fill=(255, 120, 190, 230))
    rect(d, (34, 52, 100, 60), fill=(220, 236, 255, 200))
    rect(d, (34, 68, 112, 76), fill=(220, 236, 255, 160))
    rr(d, (46, 96, 106, 150), 6, fill=(255, 214, 138, 255), outline=(255, 240, 200, 255), width=2)
    line(d, [(58, 112), (94, 112)], (120, 70, 30, 220), 4)
    line(d, [(58, 128), (86, 128)], (120, 70, 30, 200), 4)
    rr(d, (40, 206, 110, 226), 6, fill=(40, 34, 60, 255), outline=(120, 100, 160, 255), width=1)
    img = glow(img, 5, 80)
    finish(img, w, h, "props/prop_banner.png")


def prop_luggage():
    w, h = 170, 220
    img, d = canvas(w, h)
    # 택배상자
    rr(d, (10, 110, 96, 210), 4, fill=(196, 152, 104, 255), outline=(150, 110, 70, 255), width=2)
    line(d, [(53, 110), (53, 210)], (170, 128, 84, 255), 2)
    rect(d, (22, 122, 82, 132), fill=(236, 226, 200, 210))
    # 캐리어
    rr(d, (84, 40, 160, 208), 10, fill=(48, 62, 92, 255), outline=(96, 118, 156, 255), width=3)
    rect(d, (94, 56, 150, 196), fill=(36, 48, 74, 255), outline=(84, 104, 138, 255), width=1)
    line(d, [(98, 74), (146, 74)], (120, 200, 240, 220), 4)
    rr(d, (108, 16, 136, 42), 6, fill=None, outline=(150, 168, 196, 255), width=4)
    ellipse(d, (94, 196, 110, 212), fill=(20, 26, 40, 255))
    ellipse(d, (136, 196, 152, 212), fill=(20, 26, 40, 255))
    finish(img, w, h, "props/prop_luggage.png")


def prop_hydrant():
    w, h = 120, 190
    img, d = canvas(w, h)
    rr(d, (26, 150, 94, 182), 6, fill=(150, 40, 44, 255))
    rr(d, (32, 54, 88, 156), 12, fill=RED, outline=(255, 120, 120, 255), width=2)
    ellipse(d, (30, 34, 90, 74), fill=(238, 84, 88, 255), outline=(255, 150, 150, 255), width=2)
    rr(d, (52, 18, 68, 40), 4, fill=(190, 56, 60, 255))
    # 옆 배관
    rr(d, (10, 86, 34, 116), 5, fill=(200, 60, 64, 255))
    rr(d, (86, 86, 110, 116), 5, fill=(200, 60, 64, 255))
    ellipse(d, (14, 90, 30, 106), fill=(120, 26, 30, 255))
    ellipse(d, (90, 90, 106, 106), fill=(120, 26, 30, 255))
    rect(d, (40, 116, 80, 128), fill=(250, 236, 200, 230))
    img = glow(img, 4, 60)
    finish(img, w, h, "props/prop_hydrant.png")


def prop_robot():
    w, h = 150, 150
    img, d = canvas(w, h)
    # 몸통
    rr(d, (16, 44, 134, 124), 20, fill=WHITE, outline=(170, 190, 214, 255), width=3)
    rr(d, (26, 54, 124, 92), 14, fill=(232, 244, 255, 255))
    # 눈
    ellipse(d, (44, 62, 62, 84), fill=(40, 70, 110, 255))
    ellipse(d, (88, 62, 106, 84), fill=(40, 70, 110, 255))
    ellipse(d, (48, 66, 58, 79), fill=CYAN)
    ellipse(d, (92, 66, 102, 79), fill=CYAN)
    # 화물칸
    rr(d, (34, 94, 116, 122), 8, fill=(90, 214, 190, 255), outline=(40, 140, 120, 255), width=2)
    line(d, [(75, 96), (75, 120)], (36, 120, 104, 255), 2)
    # 바퀴
    ellipse(d, (22, 116, 52, 144), fill=(40, 52, 72, 255))
    ellipse(d, (98, 116, 128, 144), fill=(40, 52, 72, 255))
    # 센서 불빛
    ellipse(d, (68, 26, 82, 40), fill=(255, 210, 120, 255))
    line(d, [(75, 40), (75, 46)], (170, 190, 214, 255), 4)
    img = glow(img, 4, 70)
    finish(img, w, h, "props/prop_delivery_robot.png")


def prop_kickboard():
    w, h = 130, 180
    img, d = canvas(w, h)
    # 발판
    rr(d, (18, 128, 112, 150), 8, fill=(84, 222, 190, 255), outline=(30, 130, 108, 255), width=2)
    # 앞바퀴·뒷바퀴
    ellipse(d, (8, 122, 30, 152), fill=(28, 38, 54, 255))
    ellipse(d, (100, 122, 122, 152), fill=(28, 38, 54, 255))
    # 핸들 기둥
    line(d, [(100, 132), (74, 40)], (208, 224, 240, 255), 6)
    line(d, [(100, 132), (76, 42)], (140, 160, 186, 255), 2)
    rr(d, (56, 26, 96, 44), 8, fill=(60, 78, 104, 255), outline=(150, 170, 200, 255), width=2)
    ellipse(d, (64, 32, 74, 42), fill=(255, 240, 150, 255))
    # 소형 배터리 표시
    rr(d, (30, 138, 60, 150), 3, fill=(30, 44, 64, 255))
    img = glow(img, 4, 60)
    finish(img, w, h, "props/prop_kickboard.png")


def gimmick_turnstile(closed: bool):
    w, h = 260, 140
    img, d = canvas(w, h)
    for x in (30, 150):
        rr(d, (x, 40, x + 30, 128), 6, fill=(44, 56, 78, 255), outline=(120, 140, 172, 255), width=2)
        ellipse(d, (x + 6, 46, x + 24, 64), fill=(120, 224, 255, 255) if not closed else (255, 110, 110, 255))
    if closed:
        rr(d, (60, 66, 150, 84), 6, fill=(232, 92, 92, 255), outline=(255, 170, 170, 255), width=2)
        line(d, [(66, 70), (144, 80)], (255, 210, 210, 160), 2)
    else:
        rr(d, (60, 100, 120, 114), 6, fill=(120, 224, 255, 255), outline=(200, 245, 255, 255), width=2)
    line(d, [(20, 134), (240, 134)], (150, 170, 200, 160), 3)
    img = glow(img, 4, 90)
    finish(img, w, h, "gimmicks/gimmick_turnstile_closed.png" if closed else "gimmicks/gimmick_turnstile_open.png")


def gimmick_escalator():
    w, h = 220, 300
    img, d = canvas(w, h)
    rr(d, (14, 6, 206, 294), 8, fill=(38, 46, 64, 255), outline=(110, 128, 160, 255), width=3)
    for i in range(9):
        y = 18 + i * 30
        rr(d, (26, y, 194, y + 22), 4, fill=(58, 70, 94, 255), outline=(140, 160, 190, 255), width=1)
        line(d, [(38, y + 16), (66, y + 6), (94, y + 16)], CYAN, 3)
    line(d, [(20, 12), (20, 288)], (255, 214, 90, 255), 4)
    img = glow(img, 5, 100)
    finish(img, w, h, "gimmicks/gimmick_escalator.png")


def gimmick_cctv():
    w, h = 240, 200
    img, d = canvas(w, h)
    rr(d, (14, 116, 226, 190), 8, fill=(28, 36, 52, 255), outline=(96, 116, 148, 255), width=3)
    # 모니터 4분할
    for i in range(4):
        x = 26 + (i % 2) * 100
        y = 16 + (i // 2) * 48
        rr(d, (x, y, x + 88, y + 40), 4, fill=(16, 26, 40, 255), outline=(110, 200, 240, 255), width=2)
        line(d, [(x + 10, y + 30), (x + 30, y + 12), (x + 52, y + 26), (x + 76, y + 10)], (150, 255, 210, 220), 2)
    rr(d, (26, 132, 120, 178), 4, fill=(20, 28, 42, 255), outline=(80, 100, 130, 255), width=1)
    for i in range(3):
        ellipse(d, (36 + i * 26, 142, 52 + i * 26, 158), fill=(255, 210, 120, 255))
    rr(d, (140, 132, 214, 178), 4, fill=(20, 28, 42, 255), outline=(80, 100, 130, 255), width=1)
    line(d, [(148, 168), (160, 146), (176, 158), (204, 138)], (255, 140, 140, 220), 2)
    img = glow(img, 5, 90)
    finish(img, w, h, "gimmicks/gimmick_cctv_console.png")


def gimmick_light_switch():
    w, h = 100, 150
    img, d = canvas(w, h)
    rr(d, (16, 10, 84, 140), 8, fill=(30, 38, 54, 255), outline=(110, 130, 160, 255), width=3)
    rr(d, (28, 26, 72, 70), 6, fill=(255, 232, 160, 255), outline=(255, 250, 220, 255), width=2)
    rr(d, (28, 84, 72, 124), 6, fill=(70, 84, 108, 255), outline=(150, 170, 200, 255), width=2)
    for i in range(3):
        ellipse(d, (40, 94 + i * 10, 60, 100 + i * 10), fill=(190, 210, 235, 160))
    img = glow(img, 4, 80)
    finish(img, w, h, "gimmicks/gimmick_light_switch.png")


def gimmick_shutter():
    w, h = 220, 260
    img, d = canvas(w, h)
    rr(d, (6, 4, 214, 256), 4, fill=(58, 66, 82, 255), outline=(130, 146, 170, 255), width=3)
    for i in range(9):
        y = 12 + i * 27
        rr(d, (14, y, 206, y + 21), 3, fill=(84, 94, 112, 255), outline=(150, 164, 186, 255), width=1)
        line(d, [(20, y + 6), (200, y + 6)], (168, 182, 204, 120), 2)
    rect(d, (6, 238, 214, 256), fill=(255, 206, 90, 255))
    line(d, [(6, 238), (214, 238)], (60, 50, 20, 255), 2)
    finish(img, w, h, "gimmicks/gimmick_shutter.png")


def gimmick_screen_door():
    w, h = 200, 220
    img, d = canvas(w, h)
    rr(d, (10, 6, 190, 214), 4, fill=(150, 210, 235, 90), outline=(190, 226, 244, 200), width=3)
    for x in (68, 132):
        line(d, [(x, 10), (x, 210)], (210, 240, 255, 200), 3)
    line(d, [(16, 70), (184, 70)], (230, 246, 255, 150), 2)
    rect(d, (10, 196, 190, 214), fill=(255, 214, 90, 235))
    img = glow(img, 6, 80)
    finish(img, w, h, "gimmicks/gimmick_screen_door.png")


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    prop_iced_coffee()
    prop_vending_machine()
    prop_kiosk()
    prop_banner()
    prop_luggage()
    prop_hydrant()
    prop_robot()
    prop_kickboard()
    gimmick_turnstile(True)
    gimmick_turnstile(False)
    gimmick_escalator()
    gimmick_cctv()
    gimmick_light_switch()
    gimmick_shutter()
    gimmick_screen_door()


if __name__ == "__main__":
    main()
