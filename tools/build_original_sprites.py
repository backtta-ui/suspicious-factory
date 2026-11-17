"""Lossless extraction of the existing approved turnaround; never redraw/recolor.
Rows are explicit because this illustration is NOT an evenly spaced sprite sheet.
"""
from pathlib import Path
from PIL import Image
import argparse,json,hashlib
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--characters',nargs='+',default=['woochi','yeonhwa','muyeong','hongryeon']);args=parser.parse_args()
source=root/'art_sources/mascot/turnaround-original.png';im=Image.open(source).convert('RGBA')
out=root/'assets/woo/mascot/original';out.mkdir(exist_ok=True)
ids=['woochi','yeonhwa','muyeong','hongryeon'];rows=[0,318,603,915,1246];directions=['front','left','back','right']
manifest={'source':'res://art_sources/mascot/turnaround-original.png','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_size':list(im.size),'characters':{}}
for character in args.characters:
 row=ids.index(character);frames={}
 for col,direction in enumerate(directions):
  left=round(col*im.width/4);right=round((col+1)*im.width/4)
  region=(left,rows[row],right,rows[row+1]);tile=im.crop(region)
  box=tile.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox();assert box
  box=(max(0,box[0]-4),max(0,box[1]-4),min(tile.width,box[2]+4),min(tile.height,box[3]+4))
  crop=tile.crop(box);alpha=crop.getchannel('A');solid=alpha.point(lambda a:255 if a>64 else 0).getbbox();assert solid
  feet=alpha.crop((0,max(0,solid[3]-10),crop.width,solid[3])).point(lambda a:255 if a>64 else 0).getbbox();assert feet
  foot=[(feet[0]+feet[2])/2,solid[3]]
  filename=character+'-'+direction+'.png';crop.save(out/filename)
  source_rect=[left+box[0],rows[row]+box[1],crop.width,crop.height]
  assert crop.tobytes()==im.crop((source_rect[0],source_rect[1],source_rect[0]+source_rect[2],source_rect[1]+source_rect[3])).tobytes()
  frames[direction]={'path':'res://assets/woo/mascot/original/'+filename,'source_rect':source_rect,'foot':foot,'size':list(crop.size),'rgba_sha256':hashlib.sha256(crop.tobytes()).hexdigest()}
 front=frames['front'];frames['scale']=54.0/(front['foot'][1]-4)
 manifest['characters'][character]=frames
(out/'frames.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Lossless original characters extracted:',', '.join(args.characters))
