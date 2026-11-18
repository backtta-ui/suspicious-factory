"""Blender 4.3+: reproducible original temporary Woochi mesh, skin and clips.
Run: blender --background --python tools/build_woochi_3d.py
No external assets, services or generated textures.
"""
import bpy, math
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
colors={'skin':(.91,.66,.49,1),'ivory':(.86,.87,.82,1),'navy':(.065,.13,.3,1),'blue':(.12,.27,.49,1),'black':(.025,.025,.045,1),'gold':(.85,.57,.15,1),'hair':(.035,.025,.045,1),'eye':(.045,.025,.04,1),'white':(.96,.94,.9,1),'jade':(.13,.55,.43,1),'paper':(.96,.77,.3,1)}
mats={}
for name,c in colors.items():
 mat=bpy.data.materials.new(name);mat.diffuse_color=c;mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=c;bs.inputs['Roughness'].default_value=.85;mats[name]=mat
bones=[('hips',(0,0,.85),(0,0,1.02),None),('spine',(0,0,1.02),(0,0,1.4),'hips'),('head',(0,0,1.4),(0,0,1.8),'spine'),('coat_front',(0,-.10,.96),(0,-.14,.48),'hips'),('coat_back',(0,.10,.96),(0,.14,.45),'hips')]
for side,sign in [('L',1),('R',-1)]:
 bones += [(f'arm_{side}',(sign*.22,0,1.35),(sign*.38,0,1.05),'spine'),(f'forearm_{side}',(sign*.38,0,1.05),(sign*.4,-.035,.83),f'arm_{side}'),(f'thigh_{side}',(sign*.12,0,.86),(sign*.12,0,.48),'hips'),(f'shin_{side}',(sign*.12,0,.48),(sign*.12,0,.13),f'thigh_{side}')]
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='WoochiRig';bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
for name,head,tail,parent in bones:
 b=rig.data.edit_bones.new(name);b.head=head;b.tail=tail
 if parent:b.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');parts=[]
def finish(obj,name,color,bone):
 obj.name=name;obj.data.materials.append(mats[color]);bpy.context.view_layer.objects.active=obj
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 for p in obj.data.polygons:p.use_smooth=True
 group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE');parts.append(obj);return obj
def oval(name,p,s,color,bone):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,location=p);o=bpy.context.object;o.scale=s;return finish(o,name,color,bone)
def box(name,p,s,color,bone,bevel=.03):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('soft edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,name,color,bone)
def cone(name,p,r1,r2,depth,color,bone):
 bpy.ops.mesh.primitive_cone_add(vertices=20,radius1=r1,radius2=r2,depth=depth,location=p);return finish(bpy.context.object,name,color,bone)
# Five-head anime proportions; separate robe, collar, sleeves, hands and articulated boots.
oval('Body',(0,0,1.15),(.245,.155,.31),'navy','spine')
cone('Blue vest',(0,0,1.13),.23,.26,.46,'blue','spine')
for side,sign in [('L',1),('R',-1)]:
 oval('Upper sleeve '+side,(sign*.3,0,1.18),(.145,.14,.25),'ivory',f'arm_{side}')
 oval('Wide cuff '+side,(sign*.39,-.005,.94),(.13,.13,.20),'navy',f'forearm_{side}')
 oval('Hand '+side,(sign*.405,-.035,.805),(.075,.065,.09),'skin',f'forearm_{side}')
 oval('Trouser '+side,(sign*.12,0,.60),(.105,.105,.27),'ivory',f'thigh_{side}')
 oval('Shin '+side,(sign*.12,0,.29),(.085,.09,.22),'ivory',f'shin_{side}')
 box('Boot '+side,(sign*.12,-.065,.095),(.17,.31,.16),'black',f'shin_{side}')
# Split coat panels have their own bones and swing away from the legs.
for back in [False,True]:
 name='coat_back' if back else 'coat_front';y=.09 if back else -.10
 verts=[(-.22,y,.98),(.22,y,.98),(-.34,y*1.7,.42),(.34,y*1.7,.42),(-.22,y+.025,.98),(.22,y+.025,.98),(-.34,y*1.7+.025,.42),(.34,y*1.7+.025,.42)]
 faces=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);finish(o,name,'navy',name)
box('Gold belt',(0,-.005,.99),(.48,.34,.065),'gold','hips')
# Crossed ivory Korean collar, not a Western lapel.
for sign in [-1,1]:
 bpy.ops.mesh.primitive_cube_add(size=1,location=(sign*.06,-.167,1.34));o=bpy.context.object;o.scale=(.055,.035,.26);o.rotation_euler[1]=sign*math.radians(30);finish(o,'Cross collar','ivory','spine')
oval('Neck',(0,0,1.43),(.08,.08,.115),'skin','head')
oval('Face',(0,-.008,1.64),(.215,.195,.245),'skin','head')
oval('Hair cap',(0,.025,1.77),(.225,.19,.15),'hair','head')
oval('Back hair',(0,.15,1.67),(.2,.075,.17),'hair','head')
for i in range(5):
 x=(i-2)*.078;o=oval('Sculpted fringe',(x,-.165,1.81-abs(x)*.12),(.062,.05,.10),'hair','head')
for sign in [-1,1]:
 oval('Side hair',(sign*.194,.005,1.62),(.045,.10,.15),'hair','head')
 oval('Ear',(sign*.21,0,1.62),(.035,.042,.06),'skin','head')
 oval('Anime eye white',(sign*.079,-.181,1.665),(.047,.024,.062),'white','head')
 oval('Iris',(sign*.079,-.204,1.665),(.026,.013,.047),'eye','head')
 oval('Eye shine',(sign*.071,-.215,1.683),(.009,.005,.012),'white','head')
box('Mouth',(0,-.196,1.535),(.053,.012,.012),'eye','head',.006)
oval('Nose',(0,-.194,1.59),(.025,.025,.026),'skin','head')
cone('Gat brim',(0,0,1.89),.43,.43,.025,'black','head');cone('Gat crown',(0,.015,2.005),.205,.16,.23,'black','head');cone('Gat golden seam',(0,0,1.909),.219,.219,.018,'gold','head')
box('Forehead talisman',(0,-.205,1.94),(.075,.018,.20),'paper','head',.004)
for z in [1.89,1.94,1.99]:box('Talisman motif',(0,-.217,z),(.045,.006,.009),'gold','head',0)
box('Belt talisman',(.22,-.195,.86),(.10,.022,.25),'paper','coat_front',.005)
oval('Jade knot',(-.24,-.15,.96),(.045,.035,.06),'jade','hips')
# Merge into one weighted mesh; Godot receives a real Skeleton3D/skinned ArrayMesh.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();body=bpy.context.object;body.name='WoochiSkinnedMesh';body.parent=rig
mod=body.modifiers.new('Woochi skin','ARMATURE');mod.object=rig
for p in rig.pose.bones:p.rotation_mode='XYZ'
rig.animation_data_create()
def action(name,seconds,loop=True):
 act=bpy.data.actions.new(name);rig.animation_data.action=act;last=int(seconds*30)+1
 for f in range(1,last+1,2):
  t=(f-1)/30;phase=t/seconds*math.tau
  for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
  if name in ['walk','run']:
   amp=.5 if name=='walk' else .83
   for side,sign in [('L',1),('R',-1)]:
    wave=math.sin(phase)*sign
    rig.pose.bones['thigh_'+side].rotation_euler.x=wave*amp
    rig.pose.bones['shin_'+side].rotation_euler.x=-max(0,-wave)*amp*.9
    rig.pose.bones['arm_'+side].rotation_euler.x=-wave*amp*.8
    rig.pose.bones['forearm_'+side].rotation_euler.x=-.25 if name=='run' else -.08
   rig.pose.bones['hips'].location.z=abs(math.cos(phase))*(.035 if name=='run' else .018)
   rig.pose.bones['spine'].rotation_euler.x=.10 if name=='run' else .025
   rig.pose.bones['coat_back'].rotation_euler.x=-.1+math.sin(phase)*.12
   rig.pose.bones['coat_front'].rotation_euler.x=.08+math.sin(phase+1)*.11
  elif name in ['jump_start','air']:
   rig.pose.bones['thigh_L'].rotation_euler.x=-.28;rig.pose.bones['thigh_R'].rotation_euler.x=.22
   rig.pose.bones['arm_L'].rotation_euler.y=.20;rig.pose.bones['arm_R'].rotation_euler.y=-.20
   rig.pose.bones['coat_back'].rotation_euler.x=-.3
  elif name=='land':
   bend=(1-min(1,t/seconds))*.45
   rig.pose.bones['hips'].location.z=-bend*.18
   for side in ['L','R']:rig.pose.bones['thigh_'+side].rotation_euler.x=bend;rig.pose.bones['shin_'+side].rotation_euler.x=-bend
  elif name in ['interact','rescue']:
   rig.pose.bones['arm_L'].rotation_euler.x=-1.0;rig.pose.bones['forearm_L'].rotation_euler.x=-.45
   rig.pose.bones['arm_R'].rotation_euler.x=-1.1;rig.pose.bones['forearm_R'].rotation_euler.x=-.35
   rig.pose.bones['spine'].rotation_euler.x=.15
  elif name=='sealed':
   rig.pose.bones['hips'].location.z=-.20
   for side in ['L','R']:rig.pose.bones['thigh_'+side].rotation_euler.x=.5;rig.pose.bones['shin_'+side].rotation_euler.x=-.8
  else:
   rig.pose.bones['spine'].rotation_euler.x=math.sin(phase)*.015;rig.pose.bones['head'].rotation_euler.z=math.sin(phase)*.012
  for b in rig.pose.bones:
   b.keyframe_insert('rotation_euler',frame=f);b.keyframe_insert('location',frame=f)
 track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,act);strip.action_frame_end=last
 for curve in act.fcurves:
  for point in curve.keyframe_points:point.interpolation='LINEAR'
 return act
for name,seconds,loop in [('idle',2,True),('walk',.85,True),('run',.55,True),('jump_start',.2,False),('air',.6,True),('land',.25,False),('interact',1.2,False),('sealed',1.8,True),('rescue',1.4,True)]:action(name,seconds,loop)
rig.animation_data.action=None
for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
(root/'art_sources/seowon3d').mkdir(parents=True,exist_ok=True);(root/'assets/seowon3d').mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art_sources/seowon3d/woochi-prototype.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/seowon3d/woochi-prototype.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_yup=True,export_cameras=False,export_lights=False)
print('Original temporary Woochi: skinned mesh, 13 bones, 9 real animation tracks.')
