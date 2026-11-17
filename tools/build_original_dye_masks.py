"""Derive cloth-only dye masks without changing approved source pixels."""
from PIL import Image
from pathlib import Path
import json,colorsys
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'assets/woo/mascot/original/frames.json').read_text())
for char,frames in data['characters'].items():
 for direction in ['front','back','left','right']:
  p=root/frames[direction]['path'].removeprefix('res://');im=Image.open(p).convert('RGBA');mask=Image.new('RGBA',im.size)
  start={'woochi':.68,'yeonhwa':.62,'muyeong':.70,'hongryeon':.70}[char]
  for y in range(int(im.height*start),im.height):
   for x in range(im.width):
    r,g,b,a=im.getpixel((x,y));h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
    cloth=(.52<h<.88) if char in ['woochi','muyeong'] else (h>.83 or h<.07)
    if a>0 and cloth and s>.12 and v>.15:mask.putpixel((x,y),(255,255,255,a))
  mask.save(p.with_name(p.stem+'-dye.png'))
print('16 cloth dye masks; approved art unchanged.')
