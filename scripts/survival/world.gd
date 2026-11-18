extends Node2D
## 월하의 서원 인게임 월드. 정적 배경은 시작 시 한 번만 그리고,
## 물결·이펙트·문·지붕만 상태가 바뀔 때 다시 그린다(모바일 60fps 기준).
const L=preload("res://scripts/survival/layout.gd")
const Art=preload("res://scripts/survival/seowon_art.gd")
const Env=preload("res://scripts/seal/environment_asset.gd")
const FX=preload("res://scripts/survival/fx.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const GOLD=Color("e8c98b")
var observer:=L.SPAWN
var roofs: Array=[]
var clock:=0.0
var rules: RefCounted
var aim:=Vector2.ZERO
var aim_active:=false
var aim_cancelled:=false
var ground: Node2D
var water: Node2D
var effects: Node2D
var roof: Node2D
var roof_alpha:=1.0
var doors: Dictionary={}
var door_open: Dictionary={"front":0.0,"back":0.0}
var water_tick:=0.0
var fx_tick:=0.0
var effects_dirty:=true
var sign_nodes: Array=[]
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;y_sort_enabled=true
 ground=Node2D.new();ground.z_index=-100;ground.draw.connect(draw_ground);add_child(ground)
 water=Node2D.new();water.z_index=-92;water.draw.connect(draw_water);add_child(water)
 var bridge:=Node2D.new();bridge.z_index=-80;bridge.draw.connect(func()->void:Art.draw_bridge(bridge));add_child(bridge)
 build_hanok()
 build_facades()
 build_garden()
 for data in L.OBJECTS:
  var shadow:=Node2D.new();shadow.z_index=-2;shadow.position=data.p;shadow.draw.connect(func()->void:
   var side: float=18.0 if data.kind!="cat" else 13.0
   shadow.draw_set_transform(Vector2(0,1),0,Vector2(1,.36));shadow.draw_circle(Vector2.ZERO,side,Color(.01,.01,.03,.45));shadow.draw_set_transform(Vector2.ZERO,0,Vector2.ONE))
  add_child(shadow)
  var asset:=Env.new();asset.kind=data.kind;asset.position=data.p
  var display: float={"cat":1.1,"jar":1.35,"crate":1.45,"lantern":1.45,"stele":1.4}.get(data.kind,1.3)
  asset.scale=Vector2(display,display);add_child(asset)
 roof=Node2D.new();roof.z_index=24;roof.position=L.HANOK.get_center()+Vector2(0,L.HANOK.size.y*.5-2);roof.draw.connect(draw_roof);add_child(roof)
 var roof_sprite:=Sprite2D.new();roof_sprite.texture=Art.ATLAS;roof_sprite.region_enabled=true;roof_sprite.region_rect=Rect2(44,12,470,188)
 roof_sprite.centered=false;roof_sprite.scale=Vector2(404.0/470.0,300.0/188.0);roof_sprite.position=Vector2(-202,-296)
 roof_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;roof.add_child(roof_sprite)
 effects=Node2D.new();effects.z_index=8;effects.draw.connect(draw_effects);add_child(effects)
func draw_ground() -> void:
 Art.draw_base(ground)
 Art.draw_interior(ground)
 draw_hanok_walls(ground)
func draw_water() -> void:Art.draw_water(water,clock)
func draw_roof() -> void:
 # 처마 아래 그늘과 낙수선
 roof.draw_rect(Rect2(-196,-6,392,12),Color(.06,.07,.12,.5))
 roof.draw_line(Vector2(-198,4),Vector2(198,4),Color(.08,.08,.14,.8),3)
 for i in range(9):
  var x: float=-180+i*45
  roof.draw_circle(Vector2(x,6),1.6,Color(1,.85,.55,.5))
func build_hanok() -> void:
 for id in ["front","back"]:
  var entry: Dictionary=L.door(id)
  var hinge:=Node2D.new();hinge.z_index=18;hinge.position=entry.center+Vector2(-35,0)
  hinge.draw.connect(func()->void:draw_door_leaf(hinge));add_child(hinge)
  var leaf:=Node2D.new();leaf.z_index=18;leaf.position=entry.center+Vector2(35,0);leaf.rotation=PI
  leaf.draw.connect(func()->void:draw_door_leaf(leaf));add_child(leaf)
  doors[id]=[hinge,leaf]
 # 문틀
 var frame:=Node2D.new();frame.z_index=17;frame.draw.connect(func()->void:
  for entry in L.DOORS:
   frame.draw_rect(Rect2(entry.center+Vector2(-42,-9),Vector2(84,18)),Color(.12,.09,.07));frame.draw_rect(Rect2(entry.center+Vector2(-40,-7),Vector2(80,14)),Color(.3,.26,.34)));add_child(frame)
func draw_door_leaf(node: Node2D) -> void:
 node.draw_rect(Rect2(0,-7,35,14),Color(.35,.24,.16))
 node.draw_rect(Rect2(1,-6,33,12),Color(.62,.44,.26))
 for i in range(4):node.draw_line(Vector2(4+i*8,-5),Vector2(4+i*8,5),Color(.32,.22,.14,.8),1)
 node.draw_circle(Vector2(30,0),2.4,Color(.85,.72,.45))
func build_facades() -> void:
 for spec in [[Art.HANOK_CELL,Vector2(870,480),320],[Art.HANOK_B_CELL,Vector2(375,1138),300]]:
  var sprite:=Sprite2D.new();sprite.texture=Art.ATLAS;sprite.region_enabled=true;sprite.region_rect=spec[0]
  var width: float=spec[2];var s:=width/512.0
  sprite.scale=Vector2(s,s);sprite.centered=false
  sprite.position=Vector2(-width/2,-470*s)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=spec[1];holder.add_child(sprite)
  var lamp:=Node2D.new();lamp.draw.connect(func()->void:Art.glow(lamp,Vector2(0,-40),90,Color(1,.64,.3,.28)));holder.add_child(lamp)
  add_child(holder)
  var sign:=Label.new();sign.text=L.NAMES[1] if spec[1].x>600 else L.NAMES[2]
  sign.add_theme_font_override("font",FONT);sign.add_theme_font_size_override("font_size",15)
  sign.add_theme_color_override("font_color",Color("f0dcae"));sign.add_theme_color_override("font_outline_color",Color(.05,.05,.1));sign.add_theme_constant_override("outline_size",3)
  sign.position=spec[1]+Vector2(-40,-58);sign.size=Vector2(80,20);sign.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  add_child(sign);sign_nodes.append(sign)
func build_garden() -> void:
 for p in Art.TREES:
  var sprite:=Sprite2D.new();sprite.texture=Art.ATLAS;sprite.region_enabled=true;sprite.region_rect=Art.CHERRY_CELL
  var s:=260.0/512.0;sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-130,-470*s)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite)
  var glow_node:=Node2D.new();glow_node.z_index=-1;glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-90),150,Color(.85,.45,.7,.16)));holder.add_child(glow_node)
  add_child(holder)
  var petals:=Node2D.new();petals.z_index=1;petals.draw.connect(func()->void:
   for i in range(10):
    var t:=fmod(clock*.12+i*.37,1.0)
    petals.draw_circle(Vector2(-60+shade_petal(p,i)*120,-30-t*90),1.8,Color(.98,.66,.82,.5)));holder.add_child(petals)
 # 연못 동쪽 정자: 시야를 끊고 뺑뺑이 동선을 만든다.
 var pavilion:=Sprite2D.new();pavilion.texture=Art.ATLAS;pavilion.region_enabled=true;pavilion.region_rect=Art.PAVILION_CELL
 var pav_scale:=210.0/512.0;pavilion.scale=Vector2(pav_scale,pav_scale);pavilion.centered=false
 pavilion.position=Vector2(-105,-470*pav_scale);pavilion.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var pav_holder:=Node2D.new();pav_holder.position=Vector2(1330,930);pav_holder.add_child(pavilion)
 var pav_glow:=Node2D.new();pav_glow.draw.connect(func()->void:Art.glow(pav_glow,Vector2(0,-60),110,Color(1,.66,.32,.22)));pav_holder.add_child(pav_glow)
 add_child(pav_holder)
 for rect in L.BAMBOO:
  var count:=maxi(2,int(rect.size.y/90))
  for i in range(count):
   var sprite:=Sprite2D.new();sprite.texture=Art.ATLAS;sprite.region_enabled=true;sprite.region_rect=Art.BAMBOO_CELL
   var s:=(74.0+Art.shade(i,92)*26.0)/512.0;sprite.scale=Vector2(s,s);sprite.centered=false
   sprite.position=Vector2(-220*s,-460*s+rect.position.y*i*0.0)
   sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var holder:=Node2D.new();holder.position=Vector2(rect.position.x+rect.size.x*.5,rect.position.y+30+i*(rect.size.y-40)/maxf(1,count-1));holder.add_child(sprite)
   add_child(holder)
 for p in Art.LANTERNS:
  var sprite:=Sprite2D.new();sprite.texture=Art.DECOR;sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2(2,1)*Art.DECOR_CELL,Art.DECOR_CELL)
  var s:=52.0/Art.DECOR_CELL.x;sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-26,-58)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite)
  var lamp:=Node2D.new();lamp.draw.connect(func()->void:Art.glow(lamp,Vector2(0,-38),86,Color(1,.68,.32,.4)));holder.add_child(lamp)
  add_child(holder)
 # 오브젝트 이름표(가까울 때만)
 for data in L.OBJECTS:
  var tag:=Label.new();var form: Dictionary=L.form(data.kind)
  tag.text=String(form.name)
  tag.add_theme_font_override("font",FONT);tag.add_theme_font_size_override("font_size",13)
  tag.add_theme_color_override("font_color",Color("f4e4bf"));tag.add_theme_color_override("font_outline_color",Color(.04,.04,.09));tag.add_theme_constant_override("outline_size",3)
  tag.position=data.p+Vector2(-40,-98);tag.size=Vector2(80,18);tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  tag.visible=false;add_child(tag);sign_nodes.append(tag);tag.set_meta("object",data.kind)
func shade_petal(p: Vector2,i: int) -> float:return Art.shade(int(p.x)+i*13,int(p.y)+i*7,3)
func draw_hanok_walls(node: Node2D) -> void:
 for rect in L.HARD.slice(0,6):
  node.draw_rect(rect.grow(2),Color(.05,.03,.03,.55))
  node.draw_rect(rect,Color("5a3f2b"))
  node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,maxf(3,rect.size.y*.4))),Color("7d5c3d"))
  if rect.size.x>rect.size.y:
   for x in range(int(rect.position.x)+6,int(rect.end.x)-4,34):node.draw_line(Vector2(x,rect.position.y+2),Vector2(x,rect.end.y-2),Color(.3,.2,.13,.55),2)
  else:
   for y in range(int(rect.position.y)+6,int(rect.end.y)-4,34):node.draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color(.3,.2,.13,.55),2)
 # 창호지 창문(따뜻한 불빛)
 for spec in [[Rect2(258,300,12,90),true],[Rect2(258,410,12,90),true],[Rect2(590,300,10,90),true],[Rect2(590,410,10,90),true]]:
  var rect: Rect2=spec[0]
  node.draw_rect(rect,Color(.92,.72,.36,.85))
  for y in range(int(rect.position.y)+6,int(rect.end.y)-4,14):node.draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color(.36,.24,.14,.9),1)
  for x in range(int(rect.position.x)+4,int(rect.end.x)-2,8):node.draw_line(Vector2(x,rect.position.y+4),Vector2(x,rect.end.y-4),Color(.36,.24,.14,.7),1)
  Art.glow(node,rect.get_center(),60,Color(1,.7,.35,.3))
 # 대청마루 기둥
 for p in [Vector2(262,286),Vector2(578,286),Vector2(262,554),Vector2(578,554)]:
  node.draw_circle(p,7,Color("3a2819"));node.draw_circle(p+Vector2(-2,-2),4,Color("6b4a2e"))
func _process(delta: float) -> void:
 clock+=delta
 # 물결은 10fps로만 갱신해 GPU/CPU를 아낀다.
 water_tick+=delta
 if water_tick>=.1:water_tick=0;water.queue_redraw()
 update_doors(delta)
 var inside: bool=L.INTERIOR.grow(14).has_point(observer)
 var target:=.05 if inside else 1.0
 if absf(target-roof_alpha)>.01:
  roof_alpha=move_toward(roof_alpha,target,delta*5)
  roof.modulate.a=roof_alpha
 # 근접 오브젝트 이름표
 var near:=L.object_near(observer,150)
 for tag in sign_nodes:
  if not tag.has_meta("object"):continue
  tag.visible=not near.is_empty() and tag.get_meta("object")==near.kind and observer.distance_to(near.p)<150
  if tag.visible:tag.modulate.a=.7+.3*sin(clock*3)
 # 이펙트 레이어는 실제로 움직일 때만 다시 그린다.
 fx_tick+=delta
 var busy: bool=aim_active or (rules!=null and not rules.effects.is_empty()) or not String(L.door_near(observer)).is_empty() or not near.is_empty()
 if busy and fx_tick>=1.0/20.0:
  fx_tick=0;effects_dirty=true
 if effects_dirty:
  effects_dirty=false;effects.queue_redraw()
func update_doors(delta: float) -> void:
 for entry in L.DOORS:
  var id: String=entry.id
  var near:=observer.distance_to(entry.center)<64 or float(rules.doors.get(id,0.0) if rules!=null else 0.0)>clock
  var target:=1.0 if near else 0.0
  door_open[id]=move_toward(float(door_open[id]),target,delta*4)
  if doors.has(id):
   var hinge: Node2D=doors[id][0];var leaf: Node2D=doors[id][1]
   hinge.rotation=-door_open[id]*1.15
   leaf.rotation=PI+door_open[id]*1.15
func draw_effects() -> void:
 if aim_active:
  var origin: Vector2=rules.players.human.position
  effects.draw_line(origin,origin+aim*120,Color("e77b95") if aim_cancelled else Color("9fcaff"),3,true)
  effects.draw_arc(origin+aim*120,14,0,TAU,24,Color("e77b95") if aim_cancelled else Color("9fcaff"),2,true)
 if rules!=null:
  var circle: Dictionary=rules.circle()
  effects.draw_arc(circle.center,circle.radius,0,TAU,128,Color(.9,.78,.5,.22),2,true)
  effects.draw_arc(circle.next_center,circle.next_radius,0,TAU,128,Color(.6,.72,1,.16),1,true)
  var human: Dictionary=rules.players.get("human",{})
  if not human.is_empty() and human.buff.get("sense",0)>rules.elapsed:
   var marks: Array=[]
   for p in rules.players.values():
    if p.id=="human":continue
    for i in range(p.trail.size()):
     var mark: Dictionary=p.trail[i]
     if mark.position.distance_to(human.position)<220:marks.append([mark.position.x,mark.position.y,mark.facing*PI/4,i%2,rules.elapsed-mark.time])
   preload("res://scripts/spells/effects.gd").footprints(effects,marks)
  for e in rules.effects:FX.draw(effects,e,clock)
  # 상호작용 안내
  var door:=L.door_near(observer,64)
  if door!="":
   var entry: Dictionary=L.door(door)
   var frame:=Rect2(entry.center-Vector2(38,10),Vector2(76,20))
   for i in range(3):
    effects.draw_rect(frame.grow(2+i*2),Color(1,.82,.45,.22-i*.06),false,2)
   tag(effects,entry.center+Vector2(0,-40),("뒷문 열기" if door=="back" else "문 열기"),Color("ffe9b8"))
  var near:=L.object_near(observer,150)
  if not near.is_empty():
   var my: Dictionary=rules.players.get("human",{})
   var ready: bool=not my.is_empty() and my.character!="" and my.buff.get("transform",0)<=rules.elapsed and String(my.get("form",""))==""
   if ready:tag(effects,near.p+Vector2(0,-150),"둔갑 가능",Color("9fe8ff"))
   hand(effects,near.p+Vector2(-46,-96))
func hand(node: Node2D,at: Vector2) -> void:
 node.draw_circle(at+Vector2(0,5),6.5,Color(1,.92,.72,.85))
 for k in range(4):node.draw_line(at+Vector2(-5+k*3.4,0),at+Vector2(-6+k*3.4,-8),Color(1,.92,.72,.8),2)
 node.draw_line(at+Vector2(-7,4),at+Vector2(-13,0),Color(1,.92,.72,.8),2.4)
func tag(node: Node2D,at: Vector2,text: String,color: Color) -> void:
 var width: float=54.0+text.length()*11.0
 var rect:=Rect2(at-Vector2(width*.5,15),Vector2(width,24))
 node.draw_rect(Rect2(rect.position+Vector2(0,2),rect.size),Color(.01,.02,.05,.55))
 node.draw_rect(rect,Color(.04,.05,.1,.86))
 node.draw_rect(rect,Color(.85,.7,.42,.55),false,1)
 node.draw_string(FONT,rect.position+Vector2(0,16),text,HORIZONTAL_ALIGNMENT_CENTER,width,12,color)
func door_at(p: Vector2) -> String:return L.door_near(p,64)
