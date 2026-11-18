extends Node2D
## 월하의 서원 인게임 월드: 2.5D 원화 스프라이트 + 상태 변화만 다시 그리는 경량 레이어.
const L=preload("res://scripts/survival/layout.gd")
const Art=preload("res://scripts/survival/seowon_art.gd")
const FX=preload("res://scripts/survival/fx.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const GOLD=Color("e8c98b")
const HANOK_OUT=preload("res://assets/woo/seowon/hanok_exterior.png")
const HANOK_IN=preload("res://assets/woo/seowon/hanok_interior.png")
const BAMBOO=preload("res://assets/woo/seowon/bamboo_cluster.png")
const PROPS={"jar":preload("res://assets/woo/seowon/prop_jar.png"),"crate":preload("res://assets/woo/seowon/prop_crate.png"),"stele":preload("res://assets/woo/seowon/prop_stele.png"),"lantern":preload("res://assets/woo/seowon/prop_lantern.png"),"cat":preload("res://assets/woo/seowon/prop_cat.png")}
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
var exterior: Sprite2D
var interior: Sprite2D
var exterior_alpha:=1.0
var door_open: Dictionary={"front":0.0,"back":0.0}
var water_tick:=0.0
var fx_tick:=0.0
var effects_dirty:=true
var tags: Array=[]
var culled: Array=[]
var cull_rect:=Rect2()
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;y_sort_enabled=true
 ground=Node2D.new();ground.z_index=-100;ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;ground.draw.connect(draw_ground);add_child(ground)
 water=Node2D.new();water.z_index=-92;water.draw.connect(func()->void:Art.draw_water(water,clock));add_child(water)
 var bridge:=Node2D.new();bridge.z_index=-80;bridge.draw.connect(func()->void:Art.draw_bridge(bridge));add_child(bridge)
 build_hanok()
 build_facades()
 build_garden()
 effects=Node2D.new();effects.z_index=8;effects.draw.connect(draw_effects);add_child(effects)
func draw_ground() -> void:
 Art.draw_base(ground)
 Art.draw_walls(ground)
func build_hanok() -> void:
 var holder:=Node2D.new();holder.position=Vector2(392,590);add_child(holder)
 exterior=Sprite2D.new();exterior.texture=HANOK_OUT;exterior.centered=false
 var scale_value:=470.0/HANOK_OUT.get_width();exterior.scale=Vector2(scale_value,scale_value)
 exterior.position=Vector2(-235,-HANOK_OUT.get_height()*scale_value*.985)
 exterior.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;holder.add_child(exterior)
 var glow_node:=Node2D.new();glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-120),150,Color(1,.62,.28,.16)));holder.add_child(glow_node)
 interior=Sprite2D.new();interior.texture=HANOK_IN;interior.centered=true
 var inside_scale:=388.0/HANOK_IN.get_width();interior.scale=Vector2(inside_scale,inside_scale)
 interior.position=Vector2(420,424);interior.modulate.a=0.0
 interior.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;add_child(interior)
func build_facades() -> void:
 for spec in [[Vector2(870,500),330,L.NAMES[1]],[Vector2(375,1150),300,L.NAMES[2]]]:
  var sprite:=Sprite2D.new();sprite.texture=HANOK_OUT;var s: float=spec[1]/HANOK_OUT.get_width()
  sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-spec[1]*.5,-HANOK_OUT.get_height()*s*.985)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=spec[0];holder.add_child(sprite)
  var glow_node:=Node2D.new();glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-80),110,Color(1,.64,.3,.18)));holder.add_child(glow_node)
  add_child(holder)
  var sign:=Label.new();sign.text=spec[2]
  sign.add_theme_font_override("font",FONT);sign.add_theme_font_size_override("font_size",14)
  sign.add_theme_color_override("font_color",Color("f0dcae"));sign.add_theme_color_override("font_outline_color",Color(.05,.05,.1));sign.add_theme_constant_override("outline_size",3)
  sign.position=spec[0]+Vector2(-40,-52);sign.size=Vector2(80,18);sign.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  add_child(sign)
func build_garden() -> void:
 for p in Art.TREES:
  var sprite:=Sprite2D.new();sprite.texture=Art.ATLAS;sprite.region_enabled=true;sprite.region_rect=Art.CHERRY_CELL
  var s:=280.0/512.0;sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-140,-470*s)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite);culled.append({"node":holder,"rect":Rect2(p-Vector2(160,320),Vector2(320,340))})
  var glow_node:=Node2D.new();glow_node.z_index=-1;glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-90),150,Color(.85,.45,.7,.14)));holder.add_child(glow_node)
  add_child(holder)
 # 대나무 군락
 for rect in L.BAMBOO:
  var count:=maxi(1,int(rect.size.y/150))
  for i in range(count):
   var sprite:=Sprite2D.new();sprite.texture=BAMBOO
   var s: float=(rect.size.x+40.0)/BAMBOO.get_width()
   sprite.scale=Vector2(s,s);sprite.centered=false
   sprite.position=Vector2(-(rect.size.x+40)*.5,-BAMBOO.get_height()*s*.98)
   sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var holder:=Node2D.new();holder.position=Vector2(rect.position.x+rect.size.x*.5,rect.position.y+40+i*(rect.size.y-60)/maxf(1,count))
   holder.add_child(sprite);add_child(holder);culled.append({"node":holder,"rect":Rect2(holder.position-Vector2(120,300),Vector2(240,330))})
 # 연못 동쪽 정자
 var pavilion:=Sprite2D.new();pavilion.texture=Art.ATLAS;pavilion.region_enabled=true;pavilion.region_rect=Art.PAVILION_CELL
 var pav_scale:=220.0/512.0;pavilion.scale=Vector2(pav_scale,pav_scale);pavilion.centered=false
 pavilion.position=Vector2(-110,-470*pav_scale);pavilion.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var pav_holder:=Node2D.new();pav_holder.position=Vector2(1330,930);pav_holder.add_child(pavilion)
 var pav_glow:=Node2D.new();pav_glow.draw.connect(func()->void:Art.glow(pav_glow,Vector2(0,-60),110,Color(1,.66,.32,.2)));pav_holder.add_child(pav_glow)
 add_child(pav_holder)
 # 석등(장식)
 for p in Art.LANTERNS:
  var sprite:=Sprite2D.new();sprite.texture=PROPS.lantern;var s:=64.0/PROPS.lantern.get_height()
  sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-PROPS.lantern.get_width()*s*.5,-64)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite)
  var glow_node:=Node2D.new();glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-40),90,Color(1,.68,.32,.3)));holder.add_child(glow_node)
  add_child(holder);culled.append({"node":holder,"rect":Rect2(p-Vector2(60,90),Vector2(120,110))})
 # 둔갑 사물(군집)
 for data in L.OBJECTS:
  var shadow:=Node2D.new();shadow.z_index=-2;shadow.position=data.p;shadow.draw.connect(func()->void:
   var side: float=16.0 if data.kind!="cat" else 11.0
   shadow.draw_set_transform(Vector2(0,1),0,Vector2(1,.36));shadow.draw_circle(Vector2.ZERO,side,Color(.01,.01,.03,.45));shadow.draw_set_transform(Vector2.ZERO,0,Vector2.ONE))
  add_child(shadow)
  var texture: Texture2D=PROPS.get(data.kind,PROPS.jar)
  var sprite:=Sprite2D.new();sprite.texture=texture
  var target_height: float=44.0 if data.kind=="cat" else (52.0 if data.kind=="stele" else 46.0)
  var s: float=target_height/texture.get_height()
  sprite.scale=Vector2(s,s);sprite.centered=false
  sprite.position=Vector2(-texture.get_width()*s*.5,-target_height)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=data.p;holder.add_child(sprite);add_child(holder);culled.append({"node":holder,"rect":Rect2(data.p-Vector2(40,70),Vector2(80,90))})
  var tag:=Label.new();tag.text=String(L.form(data.kind).get("name","사물"))
  tag.add_theme_font_override("font",FONT);tag.add_theme_font_size_override("font_size",12)
  tag.add_theme_color_override("font_color",Color("f4e4bf"));tag.add_theme_color_override("font_outline_color",Color(.04,.04,.09));tag.add_theme_constant_override("outline_size",3)
  tag.position=data.p+Vector2(-40,-76);tag.size=Vector2(80,16);tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  tag.visible=false;add_child(tag);tag.set_meta("object",data.kind);tags.append(tag)
func update_cull() -> void:
 var camera:=get_viewport().get_camera_2d()
 if camera==null:return
 var view: Vector2=get_viewport().get_visible_rect().size/camera.zoom
 var rect:=Rect2(camera.get_screen_center_position()-view*.5,view).grow(180)
 if rect==cull_rect:return
 cull_rect=rect
 for entry in culled:
  var node: Node2D=entry.node
  if is_instance_valid(node):node.visible=rect.intersects(entry.rect)
func _process(delta: float) -> void:
 clock+=delta
 if clock>=0.0:update_cull()
 water_tick+=delta
 if water_tick>=.1:water_tick=0;water.queue_redraw()
 var inside: bool=L.INTERIOR.grow(10).has_point(observer)
 var target:=0.0 if inside else 1.0
 if absf(target-exterior_alpha)>.01:
  exterior_alpha=move_toward(exterior_alpha,target,delta*5)
  if is_instance_valid(exterior):exterior.modulate.a=lerp(.08,1.0,exterior_alpha)
  if is_instance_valid(interior):interior.modulate.a=1.0-exterior_alpha
 for entry in L.DOORS:
  var id: String=entry.id
  var near:=observer.distance_to(entry.center)<64 or float(rules.doors.get(id,0.0) if rules!=null else 0.0)>clock
  door_open[id]=move_toward(float(door_open[id]),1.0 if near else 0.0,delta*4)
 var near:=L.object_near(observer,150)
 for tag in tags:
  if not tag.has_meta("object"):continue
  tag.visible=not near.is_empty() and tag.get_meta("object")==near.kind and observer.distance_to(near.p)<150
  if tag.visible:tag.modulate.a=.7+.3*sin(clock*3)
 fx_tick+=delta
 var busy: bool=aim_active or (rules!=null and not rules.effects.is_empty()) or not String(L.door_near(observer)).is_empty() or not near.is_empty()
 if busy and fx_tick>=1.0/20.0:fx_tick=0;effects_dirty=true
 if effects_dirty:effects_dirty=false;effects.queue_redraw()
func draw_effects() -> void:
 if aim_active:
  var origin: Vector2=rules.players.human.position
  effects.draw_line(origin,origin+aim*120,Color("e77b95") if aim_cancelled else Color("9fcaff"),3,true)
  effects.draw_arc(origin+aim*120,14,0,TAU,24,Color("e77b95") if aim_cancelled else Color("9fcaff"),2,true)
 if rules!=null:
  var circle: Dictionary=rules.circle()
  for i in range(96):
   if i%2==0:effects.draw_arc(circle.center,circle.radius,i*TAU/96,(i+1)*TAU/96,4,Color(.9,.78,.5,.2),2,true)
  for i in range(72):
   if i%2==0:effects.draw_arc(circle.next_center,circle.next_radius,i*TAU/72,(i+1)*TAU/72,4,Color(.6,.72,1,.1),1,true)
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
  var door:=L.door_near(observer,64)
  if door!="":
   var entry: Dictionary=L.door(door)
   var frame:=Rect2(entry.center-Vector2(40,12),Vector2(80,24))
   for i in range(3):effects.draw_rect(frame.grow(2+i*2),Color(1,.82,.45,.22-i*.06),false,2)
   tag(effects,entry.center+Vector2(0,-42),("뒷문 열기" if door=="back" else "문 열기"),Color("ffe9b8"))
  var near:=L.object_near(observer,150)
  if not near.is_empty():
   var my: Dictionary=rules.players.get("human",{})
   var ready: bool=not my.is_empty() and my.character!="" and my.buff.get("transform",0)<=rules.elapsed and String(my.get("form",""))==""
   if ready:tag(effects,near.p+Vector2(0,-118),"둔갑 가능",Color("9fe8ff"))
   hand(effects,near.p+Vector2(-44,-86))
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
