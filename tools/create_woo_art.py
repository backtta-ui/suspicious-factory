#!/usr/bin/env python3
"""Original low-resolution pixel assets. No factory images reused."""
from PIL import Image, ImageDraw
from pathlib import Path
import math, random
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/woo';OUT.mkdir(parents=True,exist_ok=True)
INK='#151d23'
def character(villager=False):
 sheet=Image.new('RGBA',(32*6,48*8))
 for direction,(dx,dy) in enumerate([(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1),(0,-1),(1,-1)]):
  for frame in range(6):
   im=Image.new('RGBA',(32,48));d=ImageDraw.Draw(im)
   walk=frame<4;step=[0,2,0,-2][frame%4] if walk else 0;bob=1 if walk and frame%2 else 0
   robe='#667d79' if not villager else '#8c6b51';highlight='#abb3a1' if not villager else '#c2a37b'
   d.rectangle((10,40+min(step,0),14,46+min(step,0)),fill=INK)
   d.rectangle((19,40-min(step,0),23,46-min(step,0)),fill=INK)
   d.line((10,46+min(step,0),15,46+min(step,0)),fill='#506064')
   d.polygon([(11,23+bob),(21,23+bob),(26,41),(22,44),(7,42)],fill=INK)
   d.polygon([(12,24+bob),(20,24+bob),(24,40),(19,42),(9,40)],fill=robe)
   d.line((15,27+bob,12,40),fill=highlight,width=2)
   d.line((19,29+bob,21,40),fill='#354b50',width=2)
   d.polygon([(10,24+bob),(7,29+bob+step//2),(8,34+bob),(12,32+bob),(15,27+bob)],fill=robe)
   d.polygon([(21,24+bob),(25,29+bob-step//2),(25,34+bob),(21,33+bob),(18,27+bob)],fill=robe)
   d.rectangle((8,31+bob+step//2,10,34+bob+step//2),fill='#bca58b')
   d.rectangle((22,31+bob-step//2,24,34+bob-step//2),fill='#d4b99a')
   d.line((11,30+bob,22,30+bob),fill='#85474b',width=2)
   d.line((19,31+bob,21,39+bob),fill='#b4765c')
   d.rectangle((12,16+bob,20,23+bob),fill='#d6b79a')
   if dy<0:
    d.rectangle((12,16+bob,20,23+bob),fill='#242b2e');d.line((14,21+bob,18,23+bob),fill='#495356')
   else:
    d.rectangle((12,17+bob,13,22+bob),fill='#ad896e')
    ex=16+dx*2
    if frame==5:d.line((ex-2,19+bob,ex+2,19+bob),fill=INK)
    else:d.point((ex-2,19+bob),fill=INK);d.point((ex+2,19+bob),fill=INK)
    d.point((ex,22+bob),fill='#7f5550')
   if not villager:
    d.rectangle((3,13+bob,28,16+bob),fill=INK)
    d.line((4,13+bob,27,13+bob),fill='#536066')
    d.rectangle((11,6+bob,20,13+bob),fill=INK)
    d.line((12,6+bob,19,6+bob),fill='#566063')
    d.line((13,7+bob,13,12+bob),fill='#293a40')
    d.line((9,17+bob,11,25+bob),fill='#334449')
    d.line((23,17+bob,21,25+bob),fill='#334449')
   else:
    d.rectangle((11,13+bob,21,17+bob),fill='#3f3330')
    d.rectangle((14,10+bob,19,14+bob),fill=INK)
   sheet.alpha_composite(im,(frame*32,direction*48))
 return sheet
character().save(OUT/'woo_sheet.png');character(True).save(OUT/'villager_sheet.png')
# Hanok: tile roof, two visible facades, timber frames and paper lattice windows.
im=Image.new('RGBA',(192,160));d=ImageDraw.Draw(im)
d.polygon([(29,105),(96,139),(165,105),(167,112),(96,150),(27,115)],fill='#343c3e')
d.polygon([(30,74),(96,108),(96,139),(30,105)],fill='#b5a88c')
d.polygon([(96,108),(162,74),(162,105),(96,139)],fill='#8b8b78')
for x,y in [(34,78),(61,91),(91,107)]:
 d.line((x,y,x,y+28),fill='#4d443e',width=4)
for x,y in [(100,109),(130,94),(158,80)]:d.line((x,y,x,y+27),fill='#403e38',width=4)
d.polygon([(44,85),(77,102),(77,123),(44,106)],fill='#d8c4a0',outline='#655547')
for i in range(1,5):
 x=44+i*6;y=85+i*3;d.line((x,y,x,y+21),fill='#7b6a51')
for i in range(1,4):d.line((44,85+i*5,77,102+i*5),fill='#7b6a51')
d.polygon([(108,109),(145,90),(145,116),(108,135)],fill='#b3b19a',outline='#4e4a3e')
for i in range(1,5):d.line((108+i*7,109-i*3.5,108+i*7,135-i*3.5),fill='#77735d')
d.line((108,122,145,103),fill='#77735d');d.rectangle((118,120,120,122),fill='#554b43')
d.polygon([(9,65),(96,20),(183,65),(96,112)],fill=INK)
d.polygon([(16,61),(96,24),(176,61),(96,103)],fill='#525f66')
d.polygon([(16,61),(96,24),(96,67),(96,103)],fill='#69747a')
for j in range(7):
 y=34+j*6;extent=16+j*11
 d.line((96-extent,y+extent//2-8,96,y-8),fill='#8a9090')
 d.line((96,y-8,96+extent,y+extent//2-8),fill='#374850',width=2)
for i in range(-5,6):
 x=96+i*13
 d.line((x,65+abs(i)*0.5,x-32,85+abs(i)*0.5),fill='#2d414b')
d.line((10,64,96,107),fill='#acaca0',width=3);d.line((96,107,182,64),fill='#77868a',width=3)
d.line((14,60,96,19,177,60),fill='#9caaa8',width=2)
d.rectangle((8,55,13,65),fill='#65747b');d.rectangle((177,55,183,65),fill='#65747b')
d.line((92,18,99,18),fill='#acb1a7',width=3)
im.save(OUT/'hanok.png')
# Pixel tree with small clusters and restrained highlights.
im=Image.new('RGBA',(64,88));d=ImageDraw.Draw(im)
d.polygon([(27,50),(38,50),(38,79),(43,83),(24,83),(28,76)],fill='#45413b')
d.line((30,54,30,78),fill='#7c6c50',width=3)
random.seed(712)
for cx,cy,r,c in [(26,35,23,'#243c39'),(39,33,20,'#2e4940'),(24,22,17,'#385745'),(38,17,14,'#466449'),(18,42,14,'#324d3d')]:
 for y in range(cy-r,cy+r):
  w=int(math.sqrt(max(0,r*r-(y-cy)**2)))//2*2
  if w:d.rectangle((cx-w,y,cx+w,y),fill=c)
for i in range(65):
 x=random.randrange(10,53);y=random.randrange(7,49)
 if im.getpixel((x,y))[3]: d.rectangle((x,y,x+2,y+1),fill=random.choice(['#567052','#6c8059','#213c39']))
im.save(OUT/'tree.png')
im=Image.new('RGBA',(64,56));d=ImageDraw.Draw(im)
d.polygon([(6,34),(32,22),(58,35),(32,49)],fill='#4b5553',outline=INK)
d.polygon([(6,25),(32,12),(58,25),(32,39)],fill='#8e9690',outline=INK)
d.polygon([(14,25),(32,17),(50,25),(32,33)],fill='#263e46')
d.line((7,26,7,38,32,51,58,38,58,26),fill='#6d7978',width=3)
d.rectangle((11,3,15,27),fill='#65503b');d.rectangle((49,3,53,27),fill='#65503b')
d.line((9,4,54,4),fill='#9f8462',width=4);d.line((32,4,32,26),fill='#aa9570')
d.rectangle((27,22,36,30),fill='#796447',outline=INK)
im.save(OUT/'well.png')
im=Image.new('RGBA',(112,96));d=ImageDraw.Draw(im)
d.rectangle((14,35,18,84),fill='#5a4e3d');d.rectangle((91,31,95,75),fill='#5a4e3d')
d.polygon([(10,31),(61,7),(105,28),(54,52)],fill='#934d49',outline=INK)
for x in range(15,100,14):d.line((x,31,x+37,14),fill='#be8569',width=5)
d.polygon([(13,58),(58,78),(102,57),(58,37)],fill='#a18860',outline=INK)
d.polygon([(13,58),(58,78),(58,91),(13,71)],fill='#655440')
d.polygon([(58,78),(102,57),(102,70),(58,91)],fill='#7a6249')
for x,y in [(34,54),(53,59),(73,52)]:
 d.rectangle((x,y,x+12,y+8),fill='#5a684b',outline='#c0a875');d.rectangle((x+2,y-4,x+9,y),fill='#b18d57')
im.save(OUT/'market.png')
im=Image.new('RGBA',(32,72));d=ImageDraw.Draw(im)
d.rectangle((14,20,17,67),fill='#4c4339');d.line((12,66,20,66),fill='#86745b',width=4)
d.rectangle((8,8,24,29),fill='#50372d');d.rectangle((10,10,22,26),fill='#e6ad61')
d.rectangle((13,11,19,25),fill='#ffdb90');d.line((8,17,24,17),fill='#8b5e3b');d.line((16,8,16,28),fill='#a87644')
d.polygon([(5,8),(16,2),(27,8)],fill='#536168');d.line((8,29,24,29),fill='#222e33',width=3)
im.save(OUT/'lantern.png')
im=Image.new('RGBA',(24,32));d=ImageDraw.Draw(im)
for y in range(9,29):
 w=int(10*math.sqrt(max(0,1-((y-18)/12)**2)))
 d.rectangle((12-w,y,12+w,y),fill='#483f48' if y<22 else '#35323b')
d.rectangle((5,5,19,9),fill=INK);d.rectangle((6,4,18,6),fill='#8d7970')
d.rectangle((4,10,20,13),fill='#7b665f');d.line((5,19,20,19),fill='#8d7b68',width=2)
d.line((7,14,7,24),fill='#a18a75',width=2);d.line((7,29,18,29),fill='#232b31',width=2)
im.save(OUT/'jar.png')
# Small soft light texture used by five shadowless 2D lights.
im=Image.new('RGBA',(64,64))
for y in range(64):
 for x in range(64):
  v=max(0,1-math.hypot(x-31.5,y-31.5)/32)**1.7
  im.putpixel((x,y),(255,255,255,int(v*255)))
im.save(OUT/'light.png')
icon=Image.new('RGBA',(128,128),'#17282e');d=ImageDraw.Draw(icon)
d.ellipse((9,9,119,119),fill='#243c42',outline='#beaa79',width=3)
fig=character().crop((4*32,2*48,5*32,3*48)).resize((64,96),Image.Resampling.NEAREST)
icon.alpha_composite(fig,(32,12));icon.resize((512,512),Image.Resampling.NEAREST).save(ROOT/'assets/icon.png')
icon.resize((256,256),Image.Resampling.NEAREST).save(ROOT/'assets/splash.png')
print('Original pixel assets generated')
