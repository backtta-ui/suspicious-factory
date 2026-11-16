#!/usr/bin/env python3
"""Read-only sprite geometry audit. Writes metadata, never alters the source artwork."""
import json,hashlib
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import ConvexHull
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'scripts/wardrobe/directional_data.gd'
characters=['woochi','yeonhwa','muyeong','hongryeon']
jobs={}
for name in characters+['moon','night']:
 for kind,rows in [('core',4),('actions',6)]:jobs[name+'_'+kind]=rows
jobs.update(hair_front=6,hair_back=6,hats=6,accessories=8)
jobs.update({"d_"+name:rows for name,rows in list(jobs.items())})
data={}
for name,rows in jobs.items():
 path=ROOT/'assets/woo/characters'/f'{name}.png';im=np.array(Image.open(path).convert('RGBA'));height,width=im.shape[:2];cw,ch=width/4,height/rows
 alpha=im[:,:,3]>175
 labels,count=ndimage.label(alpha);areas=np.bincount(labels.ravel());areas[0]=0
 ids=np.argsort(areas)[-4*rows:]
 centers=np.array(ndimage.center_of_mass(alpha,labels,ids))
 def boundaries(v,n,coordinate,group):
  # Source artwork may have non-uniform rows. Detect actual complete sprites,
  # then put cuts in the transparent valley BETWEEN those sprites.
  ordered=np.sort(centers[:,coordinate]);medians=[np.median(ordered[i*group:(i+1)*group]) for i in range(n)]
  out=[0]
  for i in range(1,n):
   mid=(medians[i-1]+medians[i])/2;radius=(medians[i]-medians[i-1])*.22
   lo=max(out[-1]+1,int(mid-radius));hi=min(len(v),int(mid+radius))
   section=v[lo:hi];best=section.min();indices=np.where(section<=best+max(1,best*.03))[0]
   out.append(lo+int(np.median(indices)))
  return out+[len(v)]
 xb=boundaries(alpha.sum(0),4,1,rows);yb=boundaries(alpha.sum(1),rows,0,4)
 frames=[]
 for row in range(rows):
  for col in range(4):
   x0,x1=xb[col],xb[col+1];y0,y1=yb[row],yb[row+1];a=im[y0:y1,x0:x1]
   mask=a[:,:,3]>175;label,count=ndimage.label(mask);sizes=np.bincount(label.ravel());sizes[0]=0
   if not count or sizes.max()<40:raise RuntimeError(f'Empty directional frame {name}/{row}/{col}')
   # Actor frames: keep the actual connected body, exclude unrequested floating effects.
   if name.removeprefix('d_').split('_')[0] in characters:
    keep=[]
    for component in range(1,count+1):
     if sizes[component]<max(30,sizes.max()*.004):continue
     cy,cx=ndimage.center_of_mass(mask,label,component)
     if .2<a.shape[1] and (.2<cx/a.shape[1]<.8 or cy/a.shape[0]>.4):keep.append(component)
    valid=np.isin(label,keep)
   else:valid=mask & (sizes[label]>max(15,int(sizes.max()*.008)))
   ys,xs=np.where(valid);xmin,xmax=int(xs.min()),int(xs.max());ymin,ymax=int(ys.min()),int(ys.max())
   points=np.column_stack((xs,ys));hull=points[ConvexHull(points).vertices]
   if len(hull)>24:hull=hull[np.linspace(0,len(hull)-1,24,dtype=int)]
   bottom=xs[ys>ymax-max(4,(ymax-ymin)*.10)]
   foot=[float(np.median(bottom)),float(ymax)]
   rgb=a[:,:,:3].astype(float)/255
   skin=valid & (rgb[:,:,0]>rgb[:,:,1]*1.025) & (rgb[:,:,1]>rgb[:,:,2]*1.02) & (rgb[:,:,0]>.35)
   skin[int(ymin+(ymax-ymin)*.55):]=False
   sl,sc=ndimage.label(skin);ss=np.bincount(sl.ravel());ss[0]=0
   if sc and ss.max()>50:
    sy,sx=np.where(sl==int(ss.argmax()));head=[max(0,float(sx.min())-3),max(0,float(sy.min())-3),min(a.shape[1]-1,float(sx.max())+3),min(a.shape[0]-1,float(sy.max())+2)]
   else:head=[xmin,ymin,xmax,ymin+(ymax-ymin)*.36]
   # Skin-colored palms can touch the cheek in action poses. A head anchor
   # must exclude the connected hand/neck instead of changing face scale.
   head[3]=min(head[3],head[1]+(head[2]-head[0])*1.08)
   # Collar/root anchor for genuinely headless garment frames.
   cx0,cx1=round(a.shape[1]*.38),round(a.shape[1]*.62)
   yy,xx=np.where(valid[:,cx0:cx1]);collar=[float(np.median(xx[yy<yy.min()+5])+cx0) if len(yy) else foot[0],float(yy.min()) if len(yy) else float(ymin)]
   norm=lambda p:[round(float(p[0])/a.shape[1],6),round(float(p[1])/a.shape[0],6)]
   frames.append({'region':[x0/width,y0/height,(x1-x0)/width,(y1-y0)/height],'box':[xmin/a.shape[1],ymin/a.shape[0],(xmax-xmin+1)/a.shape[1],(ymax-ymin+1)/a.shape[0]],'foot':norm(foot),'head':[head[0]/a.shape[1],head[1]/a.shape[0],(head[2]-head[0])/a.shape[1],(head[3]-head[1])/a.shape[0]],'collar':norm(collar),'hull':[norm(p) for p in hull]})
 data[name]={'rows':rows,'source_size':[width,height],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'frames':frames}
OUT.write_text('class_name WooDirectionalData\nextends RefCounted\n# Offline source image measurements; no image scanning during gameplay.\nconst SHEETS='+json.dumps(data,separators=(',',':'))+'\n')
print('Measured',sum(len(v['frames']) for v in data.values()),'actual directional frames in',len(data),'atlases')
