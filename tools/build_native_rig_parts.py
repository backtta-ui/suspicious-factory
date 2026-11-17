"""Derive skinning joints and separate boot pixels from unchanged native art."""
from PIL import Image
from pathlib import Path
import json,numpy as np,colorsys
from scipy.ndimage import label,find_objects
root=Path(__file__).resolve().parents[1];path=root/'assets/woo/mascot/original/frames.json';m=json.loads(path.read_text())
for char,data in m['characters'].items():
 for direction,frame in data.items():
  if not isinstance(frame,dict) or 'path' not in frame:continue
  p=root/frame['path'].removeprefix('res://');im=Image.open(p).convert('RGBA');arr=np.array(im);height,width=arr.shape[:2];skin=np.zeros((height,width),bool)
  frame['neck']={'woochi':.68,'yeonhwa':.62,'muyeong':.70,'hongryeon':.70}[char]
  for y in range(int(height*frame['neck']),int(height*.92)):
   for x in range(width):
    r,g,b,a=arr[y,x];h,s,v=colorsys.rgb_to_hsv(float(r)/255,float(g)/255,float(b)/255)
    if a>100 and h<.12 and .10<s<.55 and v>.50:skin[y,x]=True
  lab,n=label(skin);hands=[]
  for sl in find_objects(lab):
   if sl:
    ys,xs=sl
    if skin[sl].sum()>=15:hands.append([(xs.start+xs.stop)/2,(ys.start+ys.stop)/2])
  hands=sorted(hands,key=lambda v:v[0]);frame['hands']=hands[:1]+hands[-1:] if len(hands)>1 else hands
  cutoff=int(height*.94);boots=np.zeros((height,width),bool);boots[cutoff:,int(width*.25):int(width*.75)]=arr[cutoff:,int(width*.25):int(width*.75),3]>0
  body=arr.copy();body[boots,3]=0
  body_path=p.with_name(p.stem+'-rig-body.png');Image.fromarray(body).save(body_path);frame['motion_body']='res://'+str(body_path.relative_to(root))
  # Split the two visible boots at the foot origin; ignore detached edge noise.
  center=int(frame['foot'][0]);parts=[]
  for left,right in [(int(width*.25),center),(center,int(width*.75))]:
   mask=boots[:,left:right];ys,xs=np.where(mask)
   if len(xs)>10:parts.append([int(xs.min()+left),int(ys.min()),int(xs.max()+left+1),int(ys.max()+1)])
  lab,n=label(boots);unused=[]
  for sl in find_objects(lab):
   if sl:
    ys,xs=sl
    if (ys.stop-ys.start)*(xs.stop-xs.start)>10:unused.append([xs.start,ys.start,xs.stop,ys.stop])
  parts=sorted(parts,key=lambda b:(b[2]-b[0])*(b[3]-b[1]),reverse=True)[:2];parts.sort(key=lambda b:b[0])
  if not parts:raise RuntimeError((char,direction,'no footwear pixels'))
  copied=len(parts)==1
  if copied:parts=parts*2
  frame['feet']=[]
  for i,box in enumerate(parts):
   foot_path=p.with_name(p.stem+f'-foot-{i}.png');im.crop(tuple(box)).save(foot_path)
   frame['feet'].append({'path':'res://'+str(foot_path.relative_to(root)),'rect':box,'derived_occluded':copied})
path.write_text(json.dumps(m,indent=2)+'\n');print('32 native rigs: hand joints, original body skin and two boot layers prepared.')
