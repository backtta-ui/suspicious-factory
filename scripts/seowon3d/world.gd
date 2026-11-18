extends Node3D
const SPAWN=Vector3(0,0,10)
const LIBRARY=Rect2(-14.5,-8,9,8)
var materials: Dictionary={}
var roof_materials: Array=[]
var roofs: Array=[]
var vegetation: Array=[]
var lights: Array=[]
var moonlight: DirectionalLight3D
var observer:=SPAWN
var clock:=0.0
var low_quality:=false
var water: MeshInstance3D
func material(name: String,color: Color,emission: float=0) -> StandardMaterial3D:
 if materials.has(name):return materials[name]
 var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.85;m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON;m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
 if emission>0:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=emission
 materials[name]=m;return m
func mesh(parent: Node,shape: Mesh,p: Vector3,m: Material) -> MeshInstance3D:
 var node:=MeshInstance3D.new();node.mesh=shape;node.material_override=m;node.position=p;node.visibility_range_end=70;parent.add_child(node);return node
func box(parent: Node,p: Vector3,size: Vector3,m: Material,solid: bool=false,layer: int=1) -> MeshInstance3D:
 var shape:=BoxMesh.new();shape.size=size;var visual:=mesh(parent,shape,p,m)
 if solid:collider(parent,p,size,layer)
 return visual
func collider(parent: Node,p: Vector3,size: Vector3,layer: int=1) -> StaticBody3D:
 var body:=StaticBody3D.new();body.position=p;body.collision_layer=layer;body.collision_mask=0;parent.add_child(body)
 var node:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;node.shape=shape;body.add_child(node);return body
func cylinder(parent: Node,p: Vector3,height: float,radius: float,m: Material) -> MeshInstance3D:
 var shape:=CylinderMesh.new();shape.height=height;shape.top_radius=radius*.9;shape.bottom_radius=radius;shape.radial_segments=10;return mesh(parent,shape,p,m)
func multimesh(shape: Mesh,m: Material,transforms: Array) -> MultiMeshInstance3D:
 var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=shape;multi.instance_count=transforms.size()
 for i in range(transforms.size()):multi.set_instance_transform(i,transforms[i])
 var node:=MultiMeshInstance3D.new();node.multimesh=multi;node.material_override=m;node.visibility_range_end=75;add_child(node);return node
func _ready() -> void:
 var env:=WorldEnvironment.new();var setting:=Environment.new();setting.background_mode=Environment.BG_SKY
 var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new();sky_mat.sky_top_color=Color("090e25");sky_mat.sky_horizon_color=Color("26314e");sky_mat.ground_bottom_color=Color("26344a");sky_mat.ground_horizon_color=Color("26314e");sky.sky_material=sky_mat;setting.sky=sky
 setting.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;setting.ambient_light_color=Color("b6c9e4");setting.ambient_light_energy=.38;setting.reflected_light_source=1;setting.tonemap_mode=Environment.TONE_MAPPER_FILMIC;setting.tonemap_exposure=.9;env.environment=setting;add_child(env)
 moonlight=DirectionalLight3D.new();moonlight.rotation_degrees=Vector3(-48,-30,0);moonlight.light_color=Color("b8ceff");moonlight.light_energy=.48;moonlight.shadow_enabled=true;moonlight.directional_shadow_max_distance=45;add_child(moonlight)
 var moon:=SphereMesh.new();moon.radius=3.4;moon.height=6.8;moon.radial_segments=24;moon.rings=12;mesh(self,moon,Vector3(-12,24,-47),material("moon",Color("e3e8fb"),1.3))
 var stone:=material("stone",Color("62677b"));var wood:=material("wood",Color("49362f"));var plaster:=material("plaster",Color("c7bca0"))
 box(self,Vector3(0,-.2,0),Vector3(48,.4,42),material("ground",Color("536453")),true)
 var stones: Array=[]
 for x in range(-18,19):
  for z in range(-15,17):
   if abs(x)>6 and z>1 and z<10:continue
   var p:=Vector3(x*1.15+.05*sin(z*7+x),.018,z*1.1);stones.append(Transform3D(Basis().rotated(Vector3.UP,sin(x*3+z)*.025),p))
 var slab:=BoxMesh.new();slab.size=Vector3(1.09,.035,1.04);multimesh(slab,stone,stones)
 for spec in [[Vector3(0,2,-21),Vector3(48,4,.35)],[Vector3(-24,2,0),Vector3(.35,4,42)],[Vector3(24,2,0),Vector3(.35,4,42)],[Vector3(0,2,21),Vector3(48,4,.35)]]:box(self,spec[0],spec[1],plaster,true)
 building("서책고",Vector3(-10,0,-4),Vector2(9,8),true)
 building("강학당",Vector3(5,0,-11),Vector2(12,7),false)
 building("한옥 교실",Vector3(15,0,1),Vector2(7,7),false)
 gate(Vector3(0,0,18));pond();trees();bamboo();mountains()
 for p in [Vector3(-5,0,3),Vector3(6,0,3),Vector3(-15,0,7),Vector3(12,0,-7)]:lantern(p)
 box(self,Vector3(0,.19,4),Vector3(2.8,.38,.3),material("fence",Color("725644")),true)
 # A 0.38m rail for real jump/collision verification, with paths on both sides.
 for p in [Vector3(-2,0,5.5),Vector3(2.8,0,-3)]:jar(p)
func roof(parent: Node,center: Vector3,width: float,depth: float,fade: bool) -> void:
 var m:=material("roof_"+str(roofs.size()),Color("263b58")).duplicate() as StandardMaterial3D
 if fade:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rows:=12
 for i in range(rows):
  var x1: float=-width*.5+width*i/rows;var x2: float=-width*.5+width*(i+1)/rows
  var y1:=1.5*(1-absf(x1)/(width*.5))+.20*pow(absf(x1)/(width*.5),5)
  var y2:=1.5*(1-absf(x2)/(width*.5))+.20*pow(absf(x2)/(width*.5),5)
  var a:=Vector3(x1,y1,-depth*.5);var b:=Vector3(x2,y2,-depth*.5);var c:=Vector3(x2,y2,depth*.5);var d:=Vector3(x1,y1,depth*.5)
  for point in [a,c,b,a,d,c]:tool.add_vertex(point)
 tool.generate_normals();var node:=mesh(parent,tool.commit(),center,m);roofs.append(node)
 var ridge:=CylinderMesh.new();ridge.height=depth+.3;ridge.top_radius=.10;ridge.bottom_radius=.10;ridge.radial_segments=8
 var cap:=mesh(parent,ridge,center+Vector3(0,.98,0),m);cap.rotation.x=PI/2
 if fade:roof_materials.append(m)
 # Batched ceramic ridge tiles follow the actual curved roof geometry.
 var tile:=BoxMesh.new();tile.size=Vector3(.10,.06,.43);var transforms: Array=[]
 for x in range(ceili(width/.25)):
  var xx: float=-width/2+x*.25;var yy:=1.5*(1-absf(xx)/(width*.5))+.20*pow(absf(xx)/(width*.5),5)
  for z in range(ceili(depth/.45)):transforms.append(Transform3D(Basis(),center+Vector3(xx,yy+.025,-depth/2+z*.45)))
 var tiles:=multimesh(tile,m,transforms)
 if parent!=self:tiles.reparent(parent,false)
func building(name_value: String,p: Vector3,extent: Vector2,enterable: bool) -> void:
 var root:=Node3D.new();root.name=name_value;root.position=p;add_child(root)
 var wood:=material("wood",Color("49362f"));var plaster:=material("plaster",Color("c7bca0"))
 box(root,Vector3(0,.015,0),Vector3(extent.x,.025,extent.y),material("floorboards",Color("8a6d50")))
 box(root,Vector3(0,1.5,-extent.y/2),Vector3(extent.x,3,.24),plaster,true)
 for side in [-1,1]:
  box(root,Vector3(side*extent.x/2,1.5,0),Vector3(.24,3,extent.y),plaster,true)
  box(root,Vector3(side*(extent.x/4+.55),1.5,extent.y/2),Vector3(extent.x/2-1.1,3,.24),plaster,true)
 box(root,Vector3(0,2.85,extent.y/2),Vector3(2.2,.4,.28),wood,true)
 if not enterable:box(root,Vector3(0,1.25,extent.y/2),Vector3(2.2,2.5,.20),wood,true)
 for x in [-extent.x/2,extent.x/2]:
  for z in [-extent.y/2,extent.y/2]:
   cylinder(root,Vector3(x,1.55,z),3.1,.14,wood)
   box(root,Vector3(x,1.5,z),Vector3(.28,3,.28),wood,true)
 # Door frame, raised eaves, actual collision ceiling.
 box(root,Vector3(0,3.1,0),Vector3(extent.x+.4,.24,extent.y+.4),wood)
 collider(root,Vector3(0,3.14,0),Vector3(extent.x+.2,.18,extent.y+.2))
 roof(root,Vector3(0,3.32,0),extent.x+1.2,extent.y+1.4,enterable)
 for side in [-1,1]:
  var x: float=side*(extent.x/4+.55)
  box(root,Vector3(x,1.8,extent.y/2+.14),Vector3(1.25,1.2,.07),material("window_glow",Color("e2aa62"),.55))
  for offset in [-.42,0,.42]:box(root,Vector3(x+offset,1.8,extent.y/2+.20),Vector3(.04,1.25,.04),wood)
  for y in [1.3,1.8,2.3]:box(root,Vector3(x,y,extent.y/2+.20),Vector3(1.3,.04,.04),wood)
 var plaque:=Label3D.new();plaque.text=name_value;plaque.position=Vector3(0,2.82,extent.y/2+.2);plaque.font=preload("res://assets/fonts/NotoSansCJK-Regular.ttc");plaque.font_size=40;plaque.pixel_size=.012;plaque.outline_size=4;plaque.modulate=Color("ffe0a1");root.add_child(plaque)
 if enterable:
  for pos in [Vector3(-3,.6,-2),Vector3(3,.6,-2)]:
   box(root,pos,Vector3(.7,1.2,2.3),wood,true)
   for i in range(3):box(root,pos+Vector3(0,-.35+i*.3,0),Vector3(.8,.045,2.4),material("booktrim",Color("b28c58")))
  box(root,Vector3(0,.48,-2.6),Vector3(2.3,.1,1.2),wood,true)
func gate(p: Vector3) -> void:
 for side in [-1,1]:box(self,p+Vector3(side*2,1.6,0),Vector3(.32,3.2,.32),material("wood",Color("49362f")),true)
 roof(self,p+Vector3(0,3.3,0),5.2,2,false)
func pond() -> void:
 var pond_center:=Vector3(9,0,9)
 collider(self,pond_center+Vector3(0,2,0),Vector3(7,4,4),2)
 var plane:=PlaneMesh.new();plane.size=Vector2(7,4)
 var shader:=Shader.new();shader.code="shader_type spatial; render_mode diffuse_burley; void vertex(){VERTEX.y+=sin(VERTEX.x*2.5+TIME)*cos(VERTEX.z*3.0+TIME*.7)*.025;} void fragment(){ ALBEDO=vec3(.07,.22,.33)+sin(UV.x*55.0+TIME)*.015; ROUGHNESS=.2; METALLIC=.3; }"
 var m:=ShaderMaterial.new();m.shader=shader;water=mesh(self,plane,pond_center+Vector3(0,.035,0),m)
 for side in [-1,1]:
  box(self,pond_center+Vector3(side*3.6,.18,0),Vector3(.25,.36,4.4),material("pond_edge",Color("7d8790")),true)
  box(self,pond_center+Vector3(0,.18,side*2.1),Vector3(7.4,.36,.25),material("pond_edge",Color("7d8790")),true)
func trees() -> void:
 var trunks: Array=[];var crowns: Array=[]
 for p in [Vector3(-19,0,3),Vector3(-17,0,-13),Vector3(19,0,-13),Vector3(18,0,15),Vector3(-17,0,14)]:
  trunks.append(Transform3D(Basis(),p+Vector3(0,1.9,0)));collider(self,p+Vector3(0,1.8,0),Vector3(.55,3.6,.55))
  for i in range(7):
   var basis:=Basis().scaled(Vector3(1.6,1,1.3));crowns.append(Transform3D(basis,p+Vector3(sin(i*2.4)*1.4,3.8+cos(i)*.6,cos(i*2.4)*1.4)))
 var stem:=CylinderMesh.new();stem.height=3.8;stem.top_radius=.15;stem.bottom_radius=.33;stem.radial_segments=8;multimesh(stem,material("bark",Color("5c4146")),trunks)
 var leaf:=SphereMesh.new();leaf.radius=1.1;leaf.height=2.2;leaf.radial_segments=10;leaf.rings=5
 var crown:=multimesh(leaf,material("sakura",Color("df9fbd")),crowns);vegetation.append(crown)
func bamboo() -> void:
 var transforms: Array=[]
 for i in range(42):
  var p:=Vector3(-21+(i%7)*.48,1.7,-10+(i/7)*.7);transforms.append(Transform3D(Basis(),p))
 var stem:=CylinderMesh.new();stem.height=3.4;stem.top_radius=.045;stem.bottom_radius=.055;stem.radial_segments=6
 vegetation.append(multimesh(stem,material("bamboo",Color("466f51")),transforms))
 var leaves: Array=[]
 for t in transforms:leaves.append(Transform3D(Basis().scaled(Vector3(.38,.15,.5)),t.origin+Vector3(.15,1,0)))
 var leaf:=SphereMesh.new();leaf.radius=1;leaf.height=2;leaf.radial_segments=6;leaf.rings=3;vegetation.append(multimesh(leaf,material("bamboo_leaf",Color("5d8d65")),leaves))
func mountains() -> void:
 for i in range(7):
  var shape:=CylinderMesh.new();shape.top_radius=.1;shape.bottom_radius=10+i%3*3;shape.height=8+i%3*3;shape.radial_segments=7
  var mountain:=mesh(self,shape,Vector3(-45+i*15,1,-65),material("mountain",Color("34445e")));mountain.visibility_range_end=0;mountain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func lantern(p: Vector3) -> void:
 var wood:=material("wood",Color("49362f"));box(self,p+Vector3(0,1,0),Vector3(.13,2,.13),wood,true)
 box(self,p+Vector3(0,2.15,0),Vector3(.45,.65,.45),material("lantern",Color("f9b664"),1.6))
 for x in [-.24,.24]:
  for z in [-.24,.24]:box(self,p+Vector3(x,2.15,z),Vector3(.04,.72,.04),wood)
 box(self,p+Vector3(0,2.53,0),Vector3(.62,.10,.62),wood)
 var light:=OmniLight3D.new();light.position=p+Vector3(0,2.1,0);light.light_color=Color("ffc27c");light.light_energy=1.25;light.omni_range=5;light.shadow_enabled=false;add_child(light);lights.append(light)
func jar(p: Vector3) -> void:
 var shape:=SphereMesh.new();shape.radius=.38;shape.height=.8;shape.radial_segments=12;shape.rings=8;mesh(self,shape,p+Vector3(0,.4,0),material("jar",Color("795347")))
 cylinder(self,p+Vector3(0,.78,0),.1,.26,material("jar",Color("795347")));collider(self,p+Vector3(0,.4,0),Vector3(.65,.8,.65))
func inside(p: Vector3) -> bool:return LIBRARY.has_point(Vector2(p.x,p.z))
func indoor_distance(pivot: Vector3,direction: Vector3,maximum: float) -> float:
 if not inside(pivot):return maximum
 var distance:=maximum
 for axis in [0,2]:
  if absf(direction[axis])<.001:continue
  var boundary: float=(LIBRARY.end.x-.15 if axis==0 else LIBRARY.end.y-.15) if direction[axis]>0 else (LIBRARY.position.x+.15 if axis==0 else LIBRARY.position.y+.15)
  distance=minf(distance,maxf(.25,(boundary-pivot[axis])/direction[axis]))
 return distance
func _process(delta: float) -> void:
 clock+=delta
 var alpha:=.14 if inside(observer) else 1.0
 for m in roof_materials:
  var color: Color=m.albedo_color;color.a=move_toward(color.a,alpha,delta*3);m.albedo_color=color
 for node in vegetation:node.rotation.z=sin(clock*.6)*(.004 if not low_quality else 0)
 for light in lights:light.visible=observer.distance_squared_to(light.position)<225;light.light_energy=1.2+sin(clock*2+light.position.x)*.05
 moonlight.shadow_enabled=not low_quality
