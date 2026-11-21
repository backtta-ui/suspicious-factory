extends Node2D
## 서울 강남역 인게임 월드(2.0.34). world.gd(서원)와 같은 공개 인터페이스
## (rules·observer·aim·aim_active·aim_cancelled)를 제공하고, 충돌·사물·기믹 좌표는
## gangnam_layout.gd 한 곳에서만 가져온다.
## 어몽어스식 시인성: 밝은 대리석 바닥 · 두꺼운 어두운 벽 · 시안/핑크 네온 라인.
const L=preload("res://scripts/survival/gangnam_layout.gd")
const Art=preload("res://scripts/survival/gangnam_art.gd")
const FX=preload("res://scripts/survival/fx.gd")
## 2.0.37 네 맵 공통 이펙트 렌더러(함정·장판·연막·감지).
const MapFx=preload("res://scripts/survival/map_fx.gd")
const C=preload("res://scripts/survival/characters.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const SHADOW_TEX=preload("res://assets/woo/seowon/shadow_soft.png")
const GOLD=Color("8fe6ff")
const PROP_DIR="res://assets/woo/gangnam/"
const PROP_TEX={
 "iced_coffee":"props/prop_iced_coffee.png",
 "vending":"props/prop_vending_machine.png",
 "kiosk":"props/prop_kiosk.png",
 "banner":"props/prop_banner.png",
 "luggage":"props/prop_luggage.png",
 "hydrant":"props/prop_hydrant.png",
 "delivery_robot":"props/prop_delivery_robot.png",
 "kickboard":"props/prop_kickboard.png"}
const GIMMICK_TEX={
 "turnstile_open":"gimmicks/gimmick_turnstile_open.png",
 "turnstile_closed":"gimmicks/gimmick_turnstile_closed.png",
 "escalator":"gimmicks/gimmick_escalator.png",
 "cctv":"gimmicks/gimmick_cctv_console.png",
 "light":"gimmicks/gimmick_light_switch.png",
 "shutter":"gimmicks/gimmick_shutter.png",
 "door":"gimmicks/gimmick_screen_door.png"}
var rules: RefCounted
var observer:=L.SPAWN
var clock:=0.0
## 2.0.36 들어가면 지붕이 사라지는 실내 레이어.
var interior_layer: Node2D
var aim:=Vector2.ZERO
var aim_active:=false
var aim_cancelled:=false
var ground: Node2D
var under: Node2D
var walls: Node2D
var effects: Node2D
var floor_fx: Node2D
var dynamic: Node2D
var orbs: Node2D
var prop_nodes: Array=[]
var gimmick_nodes: Dictionary={}
var walker_nodes: Array=[]
var textures: Dictionary={}
var culled: Array=[]
var cull_rect:=Rect2()
var tick:=0.0
var buildings: Array=[]
const ANIMAL_HEIGHT={"delivery_robot":40.0,"kickboard":48.0,"cat":22.0,"dog":26.0}
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 y_sort_enabled=true
 ground=Node2D.new();ground.name="Ground";ground.z_index=-100
 ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 ground.draw.connect(func()->void:Art.draw_base(ground))
 add_child(ground)
 walls=Node2D.new();walls.name="Walls";walls.z_index=-92
 walls.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 walls.draw.connect(func()->void:Art.draw_walls(walls))
 add_child(walls)
 under=Node2D.new();under.name="Shadows";under.z_index=-88
 under.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 under.draw.connect(func()->void:Art.draw_prop_shadows(under))
 add_child(under)
 floor_fx=Node2D.new();floor_fx.name="FloorFx";floor_fx.z_index=-84
 floor_fx.draw.connect(draw_floor)
 add_child(floor_fx)
 orbs=Node2D.new();orbs.name="Orbs";orbs.z_index=-70;orbs.draw.connect(draw_orbs);add_child(orbs)
 build_props()
 build_walkers()
 dynamic=Node2D.new();dynamic.name="Dynamic";dynamic.z_index=6;dynamic.draw.connect(draw_dynamic);add_child(dynamic)
 effects=Node2D.new();effects.name="Effects";effects.z_index=9;effects.draw.connect(draw_effects);add_child(effects)
 interior_layer=preload("res://scripts/survival/interior_layer.gd").new()
 interior_layer.name="Interiors"
 interior_layer.layout=L
 add_child(interior_layer)

func tex(path: String) -> Texture2D:
 if textures.has(path):return textures[path]
 var full: String=path if path.begins_with("res://") else PROP_DIR+path
 var texture: Texture2D=load(full) if ResourceLoader.exists(full) else null
 textures[path]=texture
 return texture
func prop_texture(kind: String) -> Texture2D:
 var path: String=String(PROP_TEX.get(kind,""))
 return tex(path) if path!="" else null
## 둔갑 사물: 맵 사물과 100% 같은 크기·위치로 그린다(액터 둔갑도 같은 form_visual 사용).
func build_props() -> void:
 for index in range(L.OBJECTS.size()):
  var data: Dictionary=L.OBJECTS[index]
  var kind: String=String(data.kind)
  var texture:=prop_texture(kind)
  var holder:=Node2D.new();holder.name="Prop_%d"%index;holder.position=data.p
  if texture!=null:
   var sprite:=Sprite2D.new();sprite.texture=texture;sprite.centered=false
   sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var height: float=float(L.form_visual(kind).get("height",50.0))
   var s: float=height/texture.get_height()
   sprite.scale=Vector2(s,s)
   sprite.position=Vector2(-texture.get_width()*s*.5,-height)
   holder.add_child(sprite)
  add_child(holder)
  prop_nodes.append({"node":holder,"index":index,"kind":kind})
  culled.append({"node":holder,"rect":Rect2(data.p-Vector2(80,120),Vector2(160,150))})
func build_walkers() -> void:
 for route in L.WALKER_ROUTES:
  var kind: String=String(route.kind)
  var holder:=Node2D.new();holder.name="Walker_%s"%kind
  var sprite:=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  # 8방향 주행 시트가 있으면 시트를, 없으면 대표 정지 원화를 쓴다.
  var sheet: Dictionary=C.prop_sheet(kind)
  if sheet.is_empty():
   var texture:=prop_texture(kind)
   if texture!=null:
    sprite.texture=texture
    var height: float=float(L.form_visual(kind).get("height",40.0))
    var s: float=height/texture.get_height()
    sprite.scale=Vector2(s,s)
    sprite.position=Vector2(-texture.get_width()*s*.5,-height)
  holder.add_child(sprite)
  add_child(holder)
  walker_nodes.append({"node":holder,"sprite":sprite,"kind":kind,"sheet":sheet})
func update_cull() -> void:
 var camera:=get_viewport().get_camera_2d()
 if camera==null:return
 var view: Vector2=get_viewport().get_visible_rect().size/camera.zoom
 var rect:=Rect2(camera.get_screen_center_position()-view*.5,view).grow(220)
 if rect==cull_rect:return
 cull_rect=rect
 for entry in culled:
  var node: Node2D=entry.node
  if is_instance_valid(node):node.visible=rect.intersects(entry.rect)
func _process(delta: float) -> void:
 clock+=delta
 if is_instance_valid(interior_layer):interior_layer.observer=observer
 update_cull()
 update_walkers()
 tick+=delta
 if tick>=1.0/20.0:
  tick=0
  if is_instance_valid(floor_fx):floor_fx.queue_redraw()
  if is_instance_valid(dynamic):dynamic.queue_redraw()
  if is_instance_valid(effects):effects.queue_redraw()
  if is_instance_valid(orbs):orbs.queue_redraw()
## 움직이는 둔갑(배달 로봇·킥보드): rules.walkers의 위치를 그대로 따라간다.
func update_walkers() -> void:
 if rules==null:return
 for i in range(walker_nodes.size()):
  var entry: Dictionary=walker_nodes[i]
  var node: Node2D=entry.node
  var sprite: Sprite2D=entry.sprite
  if not is_instance_valid(node):continue
  if i>=rules.walkers.size():
   node.visible=false;continue
  var walker: Dictionary=rules.walkers[i]
  var p: Vector2=walker.p
  node.visible=cull_rect.has_point(p) if cull_rect.size.x>0 else true
  node.position=p+Vector2(0,-2.0*absf(sin(clock*4.0+i)))
  # 진행 방향으로 살짝 기울여 움직임을 읽게 한다.
  var facing: int=int(walker.get("facing",0))
  var sheet: Dictionary=entry.get("sheet",{})
  if sprite!=null and not sheet.is_empty():
   # 8행(방향) x 4열(주행 프레임) 시트: 정지 그림이 미끄러지지 않게 박자를 재생한다.
   var texture: Texture2D=tex(String(sheet.get("sheet","")))
   if texture!=null:
    var cell: Array=sheet.get("cell",[256,256])
    var rows: Array=sheet.get("rows",C.DIRECTIONS8)
    var mapped: Dictionary=C.sheet_row(rows,facing)
    var columns: int=int(sheet.get("cols",4))
    var frame: int=posmod(int(floor(float(walker.get("phase",0.0)))),columns) if bool(walker.get("moving",true)) else 0
    var extent:=Vector2(float(cell[0]),float(cell[1]))
    var height: float=float(ANIMAL_HEIGHT.get(String(walker.kind),40.0))
    var scale_value: float=height/maxf(1.0,C.sheet_art_height(sheet))
    sprite.texture=texture;sprite.region_enabled=true
    sprite.region_rect=Rect2(Vector2(float(frame)*extent.x,float(int(mapped.row))*extent.y),extent)
    sprite.scale=Vector2(scale_value,scale_value)
    var foot: Array=sheet.get("foot",[128.0,232.0])
    sprite.position=-Vector2(float(foot[0]),float(foot[1]))*scale_value
    sprite.skew=0.0
    sprite.modulate=Color(1,1,1,1)
  elif sprite!=null:
   var dir:=Vector2.from_angle(facing*PI/4.0)
   sprite.skew=(dir.x)*0.10
   sprite.modulate=Color(1,1,1,1) if bool(walker.get("moving",true)) else Color(1,1,1,.9)
## ---------------------------------------------------------------- 바닥층(동적)
func draw_floor() -> void:
 if rules==null:return
 draw_escalator(floor_fx)
 draw_zone_lights(floor_fx)
 draw_safe_zone(floor_fx)
 MapFx.floor_layer(floor_fx,rules,clock,MapFx.TONE_BRIGHT)
func draw_zone_lights(node: Node2D) -> void:
 if rules.gimmicks==null:return
 for zone_id in rules.gimmicks.lit_zones().keys():
  var rect: Rect2=L.zone_rect(String(zone_id))
  if rect.size.x<=0.0:continue
  var pulse: float=.5+.5*sin(clock*4.0)
  node.draw_rect(rect,Color(.02,.02,.05,.42))
  node.draw_rect(rect,Color(.30,.46,.80,.20+.10*pulse),false,3.0)
  node.draw_string(FONT,rect.position+Vector2(26,rect.size.y-18),"암전 · LIGHTS OUT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.55,.70,1,.65))
## 안전구역(비상통제구역): 청록/붉은 네온 경고 링 + 원 밖 붉은 해저드 빗금.
func draw_safe_zone(node: Node2D) -> void:
 var zone: Dictionary=rules.circle()
 var center: Vector2=zone.center
 var radius: float=float(zone.radius)
 var pulse: float=.5+.5*sin(clock*2.6)
 # 원 밖 붉은 음영(링 밴드로만 칠해 원 안은 밝게 유지)
 for i in range(14):
  var inner: float=radius+float(i)*64.0
  node.draw_arc(center,inner+32.0,0,TAU,110,Color(.55,.05,.10,.030),64.0,false)
 # 해저드 빗금(원 밖 경계를 따라)
 for i in range(72):
  if i%2==1:continue
  var a0: float=float(i)*TAU/72.0
  node.draw_arc(center,radius+16.0,a0,a0+TAU/72.0,10,Color(1,.22,.28,.42),18.0,false)
 # 경고 링: 시안 → 붉은 이중 링
 node.draw_arc(center,radius,0,TAU,128,Color(.10,.60,.78,.85),7.0,true)
 node.draw_arc(center,radius-8.0,0,TAU,128,Color(.35,1,1,.55+.25*pulse),3.0,true)
 node.draw_arc(center,radius+9.0,0,TAU,128,Color(1,.26,.32,.55+.30*pulse),4.0,true)
 # 레이더 스윕
 var sweep: float=clock*.8
 node.draw_arc(center,radius-3.0,sweep,sweep+0.5,12,Color(.55,1,1,.45),4.0,true)
 # 다음 원 미리보기(점선)
 var next_radius: float=float(zone.get("next_radius",radius))
 var next_center: Vector2=zone.get("next_center",center)
 for i in range(64):
  if i%3!=0:continue
  var a1: float=float(i)*TAU/64.0
  node.draw_arc(next_center,next_radius,a1,a1+TAU/64.0*.55,5,Color(.55,.90,1,.22),2.0,true)
 node.draw_set_transform(center,0,Vector2(1,.5))
 node.draw_circle(Vector2.ZERO,radius,Color(0,0,0,0))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## ---------------------------------------------------------------- 기믹·연출
func draw_dynamic() -> void:
 if rules==null:return
 draw_gimmick_objects(dynamic)
 var target:=form_target()
 if not target.is_empty():
  var human: Dictionary=rules.players.get("human",{})
  var ready: bool=String(human.get("character",""))!="" and float(human.buff.get("transform",0.0))<=rules.elapsed and String(human.get("form",""))==""
  if ready:draw_form_target(dynamic,target)
 draw_detection(dynamic)
## 기믹 6종: 실제 상태(잠김·방향·암전·셔터·CCTV)를 그대로 그린다.
func draw_gimmick_objects(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null:return
 var now: float=rules.elapsed
 for item in L.GIMMICKS:
  var kind: String=String(item.kind)
  var id: String=String(item.id)
  var pos: Vector2=item.pos
  # 2.0.36: 에스컬레이터는 바닥 장치다. 캐릭터 위층(dynamic)에 그리면 탄 사람이 가려지므로
  # draw_floor의 draw_escalator가 액터 아래에서 그린다.
  if kind=="escalator":continue
  match kind:
   "turnstile":
    var rect: Rect2=item.rect
    var locked: bool=g.turnstile_until>now
    # 3개 게이트 기둥
    for k in range(3):
     var x: float=rect.position.x+40.0+float(k)*150.0
     node.draw_rect(Rect2(Vector2(x,rect.position.y-26),Vector2(30,72)),Color("2c3852"))
     node.draw_rect(Rect2(Vector2(x,rect.position.y-26),Vector2(30,10)),Color("6c86b2"))
     node.draw_circle(Vector2(x+15,rect.position.y-34),6,Color(1,.35,.38) if locked else Color(.35,1,.9))
    var texture:=tex(String(GIMMICK_TEX["turnstile_closed" if locked else "turnstile_open"]))
    if texture!=null:
     # 512 원화를 개찰구 폭(440)에 맞추되 높이는 70px로 눌러 바닥에 눕힌다.
     var s: float=minf(rect.size.x/texture.get_width(),70.0/texture.get_height())
     node.draw_set_transform(Vector2(rect.get_center().x,rect.position.y+18),0,Vector2(s*1.85,s*1.85))
     node.draw_texture(texture,-Vector2(texture.get_width()*.5,-texture.get_height()*.5),Color(1,1,1,.95))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if locked:countdown_tag(node,Vector2(rect.get_center().x,rect.position.y-52),g.turnstile_until-now,"개찰구 잠김",Color(1,.45,.45))
    elif g.turnstile_ready>now:countdown_tag(node,Vector2(rect.get_center().x,rect.position.y-52),g.turnstile_ready-now,"재가동",Color(.6,.9,1))
   "escalator":
    var esc_tex:=tex(String(GIMMICK_TEX["escalator"]))
    var er: Rect2=item.rect
    if esc_tex!=null:
     # 에스컬레이터는 홀 바닥을 채우는 장치라 홀 크기에 맞춰 눕힌다.
     var es: float=minf(er.size.x/esc_tex.get_width(),er.size.y/esc_tex.get_height())
     node.draw_set_transform(Vector2(er.get_center().x,er.get_center().y),0,Vector2(es,es))
     node.draw_texture(esc_tex,-esc_tex.get_size()*.5*0.0-Vector2(esc_tex.get_width()*.5,esc_tex.get_height()*.5),Color(1,1,1,.92))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    # 흐르는 화살표(작동 방향)
    var dir: float=-1.0 if g.escalator_dir>0 else 1.0
    for k in range(6):
     var t: float=fmod(clock*1.4+float(k)/6.0,1.0)
     var y: float=er.position.y+er.size.y*(t if dir<0.0 else 1.0-t)
     var x: float=er.position.x+er.size.x*.5
     node.draw_colored_polygon(PackedVector2Array([Vector2(x-16,y-6*dir),Vector2(x+16,y-6*dir),Vector2(x,y+8*dir)]),Color(.45,1,1,.35+.25*(1.0-t)))
    countdown_tag(node,Vector2(er.get_center().x,er.position.y-24),maxf(0.0,g.escalator_flip_until-now),"방향 전환" if g.escalator_flip_until>now else ("▲ 위로" if g.escalator_dir>0 else "▼ 아래로"),Color(.55,1,1))
   "vending":
    var vtex:=prop_texture("vending")
    if vtex!=null:
     var vh: float=92.0
     var vs: float=vh/vtex.get_height()
     node.draw_set_transform(pos+Vector2(0,-vh+6),0,Vector2(vs,vs))
     node.draw_texture(vtex,Vector2(-vtex.get_width()*.5,0),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if g.noise_kind==id and g.noise_until>now:
     var life: float=clampf((g.noise_until-now)/3.0,0.0,1.0)
     for k in range(3):
      var rr: float=(1.0-life)*160.0+float(k)*46.0
      node.draw_set_transform(pos+Vector2(0,-30),0,Vector2(1,.5))
      node.draw_arc(Vector2.ZERO,rr,0,TAU,32,Color(1,.85,.4,.30*life),3.0,true)
      node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   "cctv":
    var ctex:=tex(String(GIMMICK_TEX["cctv"]))
    if ctex!=null:
     var cs: float=96.0/ctex.get_height()
     node.draw_set_transform(pos+Vector2(0,-6),0,Vector2(cs,cs))
     node.draw_texture(ctex,-Vector2(ctex.get_width()*.5,ctex.get_height()),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    var active: bool=g.cctv_until>now
    node.draw_circle(pos+Vector2(0,-104),7,Color(1,.30,.35) if active else Color(.35,.6,.7,.6))
    if active:countdown_tag(node,pos+Vector2(0,-140),g.cctv_until-now,String(L.zone(g.cctv_zone).get("name","CCTV")),Color(.6,.95,1))
   "light":
    var off: bool=g.zone_dark(String(item.zone))
    var ltex:=tex(String(GIMMICK_TEX["light"]))
    if ltex!=null:
     var ls: float=46.0/ltex.get_height()
     node.draw_set_transform(pos+Vector2(0,-4),0,Vector2(ls,ls))
     node.draw_texture(ltex,-Vector2(ltex.get_width()*.5,ltex.get_height()),Color(.55,.6,.7,1) if off else Color(1,1,1,1))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if off:countdown_tag(node,pos+Vector2(0,-84),float(g.lights.get(String(item.zone),0.0))-now,"암전",Color(.6,.7,1))
   "shutter":
    var rect2: Rect2=item.rect
    var open: bool=g.shutter_until<=now
    var stex:=tex(String(GIMMICK_TEX["shutter"]))
    if stex!=null:
     # 셔터: 통로 폭(rect.size.x)보다 넓게, 높이는 통로 길이에 맞춘다.
     var sx: float=(rect2.size.y*1.15)/stex.get_width()
     var sy: float=(rect2.size.y if not open else rect2.size.y*.16)/stex.get_height()
     node.draw_set_transform(Vector2(rect2.get_center().x,rect2.position.y),0,Vector2(sx,sy))
     node.draw_texture(stex,-Vector2(stex.get_width()*.5,0),Color(1,1,1,.96))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if not open:countdown_tag(node,Vector2(rect2.get_center().x,rect2.position.y-30),g.shutter_until-now,"셔터",Color(1,.8,.4))
    else:countdown_tag(node,Vector2(rect2.get_center().x,rect2.position.y-30),maxf(0.0,g.cooldown.get(id,0.0)-now),"셔터",Color(.6,.8,.9))
 # 스크린도어(승강장 가장자리, 장식 + 통행 차단은 벽이 담당)
 var door_tex:=tex(String(GIMMICK_TEX["door"]))
 if door_tex!=null:
  for k in range(10):
   var x: float=320.0+float(k)*300.0
   var ds: float=150.0/door_tex.get_width()
   node.draw_set_transform(Vector2(x,2370),0,Vector2(ds,ds))
   node.draw_texture(door_tex,Vector2(-door_tex.get_width()*.5,-door_tex.get_height()),Color(1,1,1,.55))
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func countdown_tag(node: Node2D,at: Vector2,left: float,text: String,color: Color) -> void:
 if left<=0.0:return
 var label: String="%s %.1f초"%[text,maxf(0.0,left)]
 var width: float=28.0+label.length()*13.0
 var rect:=Rect2(Vector2(at.x-width*.5,at.y-13),Vector2(width,24))
 node.draw_rect(Rect2(rect.position+Vector2(0,2),rect.size),Color(0,0,0,.45))
 node.draw_rect(rect,Color(.03,.05,.09,.86))
 node.draw_rect(rect,Color(color.r,color.g,color.b,.75),false,1.4)
 node.draw_string(FONT,rect.position+Vector2(0,16),label,HORIZONTAL_ALIGNMENT_CENTER,width,13,color)
## 둔갑 가능 표시(맵 사물·움직이는 로봇/킥보드).
func form_target() -> Dictionary:
 if rules==null:return {}
 var human: Dictionary=rules.players.get("human",{})
 if human.is_empty() or String(human.get("role",""))!="daoist" or String(human.get("form",""))!="":return {}
 if float(human.get("outside",0.0))>0.0:return {}
 var p: Vector2=observer
 var best: Dictionary={};var gap:=98.0
 for object in L.OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best={"kind":String(object.kind),"p":object.p,"animal":false}
 for entry in rules.walkers:
  var d2: float=p.distance_to(entry.p)
  if d2<gap:gap=d2;best={"kind":String(entry.kind),"p":entry.p,"animal":true}
 return best
func draw_form_target(node: Node2D,target: Dictionary) -> void:
 var pulse: float=.5+.5*sin(clock*3.4)
 var base: Vector2=target.p
 var gold:=Color(1,.84,.42)
 var height: float=float(L.form_visual(String(target.kind)).get("height",48.0))
 node.draw_set_transform(base,0,Vector2(1,.42))
 node.draw_arc(Vector2.ZERO,24+pulse*4,0,TAU,32,Color(gold.r,gold.g,gold.b,.85),2.6,true)
 node.draw_arc(Vector2.ZERO,32+pulse*10,0,TAU,36,Color(gold.r,gold.g,gold.b,.20+.18*(1-pulse)),3.2,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(6):
  var a:=i*TAU/6+clock*1.6
  var spark:=base+Vector2.from_angle(a)*(26+height*.36)+Vector2(0,-height*.5)
  node.draw_circle(spark,1.7,Color(1,.94,.72,.55+.35*pulse))
## 요괴의 감지(발자국·탐지·핑) — 서원과 같은 규칙, 강남 바닥에 맞춘 색만 다르다.
func draw_detection(node: Node2D) -> void:
 MapFx.detection(node,rules,clock,MapFx.TONE_BRIGHT)

func draw_orbs() -> void:
 if rules==null:return
 var pulse:=.5+.5*sin(clock*2.0)
 for orb in rules.orbs:
  if float(orb.ready)>rules.elapsed:continue
  var at: Vector2=orb.p+Vector2(0,-16-sin(clock*1.6+orb.p.x*.01)*3)
  orbs.draw_circle(at,16,Color(.55,.85,1,.18+pulse*.12))
  orbs.draw_circle(at,7.0,Color(.72,.94,1,.95))
  orbs.draw_circle(at,3.4,Color(1,1,1,.92))
  orbs.draw_arc(at,11+pulse*3,0,TAU,18,Color(.62,.9,1,.34),1.4,true)
func draw_effects() -> void:
 if rules==null:return
 draw_shield_bubbles(effects)
 MapFx.dash_trails(effects,rules,clock)
 if aim_active and rules.players.has("human"):
  var origin: Vector2=rules.players.human.position
  effects.draw_line(origin,origin+aim*120,Color("e77b95") if aim_cancelled else Color("9fcaff"),3,true)
  effects.draw_arc(origin+aim*120,14,0,TAU,24,Color("e77b95") if aim_cancelled else Color("9fcaff"),2,true)
 for e in rules.effects:FX.draw(effects,e,clock)
 var target:=form_target()
 if not target.is_empty():
  var human: Dictionary=rules.players.get("human",{})
  var ready: bool=String(human.get("character",""))!="" and float(human.buff.get("transform",0.0))<=rules.elapsed and String(human.get("form",""))==""
  if ready:draw_form_target(effects,target)
func door_at(p: Vector2) -> String:return L.door_near(p,64)

## 2.0.36 보호막 시인성: shield·생명등불·저승꽃이 켜진 캐릭터는 몸을 감싸는 방어막이 보인다.
func draw_shield_bubbles(node: Node2D) -> void:
 MapFx.shield_bubbles(node,rules,clock,L)

func draw_escalator(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 var item: Dictionary={}
 for entry in L.GIMMICKS:
  if String(entry.kind)=="escalator":item=entry;break
 if item.is_empty():return
 var rect: Rect2=item.rect
 var now: float=rules.elapsed
 # 계단 몸체
 node.draw_rect(rect,Color(.10,.12,.17,.96))
 node.draw_rect(rect.grow(-6),Color(.16,.19,.26,.96))
 var step_h:=22.0
 var count:=int(rect.size.y/step_h)
 for i in range(count):
  var y: float=rect.position.y+float(i)*step_h
  var tone: float=.20+.06*sin(clock*2.0+float(i)*.5)
  node.draw_rect(Rect2(rect.position.x+34,y,rect.size.x-68,3.0),Color(.42,.48,.60,tone))
 # 좌우 손잡이
 for side in [rect.position.x+9.0,rect.end.x-15.0]:
  node.draw_rect(Rect2(side,rect.position.y,6,rect.size.y),Color(.55,.62,.74,.9))
  node.draw_rect(Rect2(side-2,rect.position.y,10,4),Color(.80,.86,.95,.9))
 # 흐르는 화살표(작동 방향)
 var dir: float=-1.0 if g.escalator_dir>0 else 1.0
 for k in range(7):
  var t: float=fmod(clock*1.4+float(k)/7.0,1.0)
  var y: float=rect.position.y+rect.size.y*(t if dir<0.0 else 1.0-t)
  var x: float=rect.get_center().x
  node.draw_colored_polygon(PackedVector2Array([Vector2(x-18,y-7*dir),Vector2(x+18,y-7*dir),Vector2(x,y+9*dir)]),Color(.55,1,1,.32+.30*(1.0-t)))
 # 방향 안내판
 node.draw_rect(Rect2(rect.position.x+70,rect.end.y-36,rect.size.x-140,26),Color(.03,.05,.08,.92))
 node.draw_rect(Rect2(rect.position.x+70,rect.end.y-36,rect.size.x-140,26),Color(.35,.9,1,.55),false,1.2)
 node.draw_string(FONT,Vector2(rect.position.x+80,rect.end.y-17),("▲ 위로 · 타면 실려 갑니다" if g.escalator_dir>0 else "▼ 아래로 · 타면 실려 갑니다"),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.7,.95,1))
