from PIL import Image
from pathlib import Path
from scipy.ndimage import label,find_objects
import numpy as np,json,hashlib
root=Path(__file__).resolve().parents[1];im=Image.open(root/'art_sources/mascot/diagonal-extension-original.png').convert('RGBA')
a=np.array(im)[:,:,3]>64;lab,n=label(a);boxes=[]
for box in find_objects(lab):
 if box:
  ys,xs=box
  if (ys.stop-ys.start)*(xs.stop-xs.start)>12000:boxes.append((xs.start,ys.start,xs.stop,ys.stop))
assert len(boxes)==16,boxes
boxes.sort(key=lambda b:(b[1],b[0]))
rows=[]
for r in range(4):
 group=sorted(boxes[r*4:r*4+4],key=lambda b:b[0]);rows.append(group)
manifest_path=root/'assets/woo/mascot/original/frames.json';manifest=json.loads(manifest_path.read_text());ids=['woochi','yeonhwa','muyeong','hongryeon'];dirs=['front_right','front_left','back_left','back_right']
for r,char in enumerate(ids):
 for c,d in enumerate(dirs):
  b=rows[r][c];box=(max(0,b[0]-4),max(0,b[1]-4),min(im.width,b[2]+4),min(im.height,b[3]+4));crop=im.crop(box);bounds=crop.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox();feet=crop.getchannel('A').crop((0,bounds[3]-10,crop.width,bounds[3])).point(lambda a:255 if a>64 else 0).getbbox();foot=[(feet[0]+feet[2])/2,bounds[3]]
  path=root/f'assets/woo/mascot/original/{char}-{d}.png';crop.save(path)
  manifest['characters'][char][d]={'path':'res://'+str(path.relative_to(root)),'foot':foot,'size':list(crop.size),'scale':54.0/(bounds[3]-bounds[1]),'source_rect':[box[0],box[1],crop.width,crop.height],'extension':True}
manifest['direction_order']=['front','back','left','right','front_right','front_left','back_left','back_right'];manifest['extension_source']='res://art_sources/mascot/diagonal-extension-original.png';manifest['extension_sha256']=hashlib.sha256((root/'art_sources/mascot/diagonal-extension-original.png').read_bytes()).hexdigest();manifest['extension_size']=list(im.size);manifest_path.write_text(json.dumps(manifest,indent=2)+'\n');print('16 authored diagonal extension sprites prepared; original cardinal PNGs unchanged.')
