"""Deterministic atlas slicing/normalization; original generated artwork is preserved.
This is asset preparation, not an illustrated screenshot used as a game map.
"""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1];src=root/'art_sources/mascot';out=root/'assets/woo/mascot';out.mkdir(exist_ok=True)
def extract(name,cols,rows,cell,extent,baseline):
 im=Image.open(src/name).convert('RGBA');sheet=Image.new('RGBA',(cols*cell,rows*cell));bounds=[]
 for y in range(rows):
  for x in range(cols):
   piece=im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))
   # Alpha threshold removes only isolated transparent fringe, never paints new shapes.
   alpha=piece.getchannel('A').point(lambda a:255 if a>160 else 0);box=alpha.getbbox();assert box,(name,x,y)
   piece=piece.crop(box);scale=min(extent[0]/piece.width,extent[1]/piece.height);size=(max(1,round(piece.width*scale)),max(1,round(piece.height*scale)))
   piece=piece.resize(size,Image.Resampling.NEAREST);piece=piece.quantize(colors=48,method=Image.Quantize.FASTOCTREE).convert('RGBA')
   px=x*cell+(cell-piece.width)//2;py=y*cell+baseline-piece.height;sheet.alpha_composite(piece,(px,py));bounds.append([px,py,piece.width,piece.height])
 return sheet,bounds
for suffix in ['cardinal','diagonal']:
 sheet,b=extract('bodies-'+suffix+'-original.png',4,4,64,(40,40),60);sheet.save(out/('bodies-'+suffix+'.png'))
sheet,b=extract('turnaround-original.png',4,4,96,(86,84),90);sheet.save(out/'portraits.png')
sheet,b=extract('props-original.png',4,4,160,(150,146),154);sheet.save(out/'props.png');(out/'prop_bounds.json').write_text(json.dumps(b))
for name in ['hair','hats']:
 sheet,b=extract(name+'-original.png',4,6,64,(54,44),54);sheet.save(out/(name+'.png'))
(out/'spec.json').write_text(json.dumps({'body_cell':[64,64],'body_foot':[32,60],'body_height':40,'directions':8,'prop_cell':[160,160],'prop_foot':[80,154],'pixel_filter':'nearest','source_art':'art_sources/mascot','gameplay_geometry_changed':False},indent=2)+'\n')
print('Built normalized mascot runtime atlases; originals retained.')
