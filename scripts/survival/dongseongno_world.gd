extends Node2D
## 대구 동성로 인게임 월드(2.0.35). world.gd(서원)·gangnam_world.gd와 같은 공개
## 인터페이스(rules·observer·aim·aim_active·aim_cancelled)를 제공한다.
## 네온 번화가의 마젠타/시안 조명 아래, 도술네컷·오락실·버스킹 기믹이 실제 상태대로 그려진다.
const L=preload("res://scripts/survival/dongseongno_layout.gd")
const Art=preload("res://scripts/survival/dongseongno_art.gd")
const FX=preload("res://scripts/survival/fx.gd")
const C=preload("res://scripts/survival/characters.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const GOLD=Color("ff9ee0")
const PROP_DIR="res://assets/woo/dongseongno/"
const PROP_TEX={
 "photobooth":"props/photobooth.png",
 "claw_machine":"props/claw_machine.png",
 "tteokbokki_stall":"props/tteokbokki_stall.png",
 "neon_sign":"props/neon_sign.png",
 "speaker":"props/speaker.png",
 "shopping_bags":"props/shopping_bags.png",
 "mascot":"moving/mascot.png",
 "delivery_cart":"moving/delivery_cart.png"}
const GIMMICK_TEX={
 "sparkland_gate":"gimmicks/sparkland_gate.png",
 "wheel":"gimmicks/sparkland_wheel_2f.png",
 "stairs":"gimmicks/banwoldang_stairs.png",
 "arcade_gate":"gimmicks/arcade_gate.png",
 "arcade_glow":"gimmicks/arcade_gate_glow_2f.png",
 "neon_glow":"gimmicks/neon_sign_glow_2f.png"}
const ANIMAL_HEIGHT={"mascot":46.0,"delivery_cart":42.0}
var rules: RefCounted
var observer:=L.SPAWN
var clock:=0.0
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
var walker_nodes: Array=[]
var textures: Dictionary={}
var culled: Array=[]
var cull_rect:=Rect2()
var tick:=0.0
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
 under.draw.connect(func()->void:Art.draw_prop_shadows(under))
 add_child(under)
 var decor:=Node2D.new();decor.name="Decor";decor.z_index=-95
 decor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 decor.draw.connect(func()->void:Art.draw_decor(decor))
 add_child(decor)
 floor_fx=Node2D.new();floor_fx.name="FloorFx";floor_fx.z_index=-84
 floor_fx.draw.connect(draw_floor)
 add_child(floor_fx)
 orbs=Node2D.new();orbs.name="Orbs";orbs.z_index=-70;orbs.draw.connect(draw_orbs);add_child(orbs)
 build_props()
 build_walkers()
 dynamic=Node2D.new();dynamic.name="Dynamic";dynamic.z_index=6;dynamic.draw.connect(draw_dynamic);add_child(dynamic)
 effects=Node2D.new();effects.name="Effects";effects.z_index=9;effects.draw.connect(draw_effects);add_child(effects)
func tex(path: String) -> Texture2D:
 if textures.has(path):return textures[path]
 var full: String=path if path.begins_with("res://") else PROP_DIR+path
 var texture: Texture2D=load(full) if ResourceLoader.exists(full) else null
 textures[path]=texture
 return texture
func prop_texture(kind: String) -> Texture2D:
 var path: String=String(PROP_TEX.get(kind,""))
 return tex(path) if path!="" else null
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
  var sheet: Dictionary=C.prop_sheet(kind)
  if sheet.is_empty():
   var texture:=prop_texture(kind)
   if texture!=null:
    sprite.texture=texture
    var height: float=float(ANIMAL_HEIGHT.get(kind,40.0))
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
 var rect:=Rect2(camera.get_screen_center_position()-view*.5,view).grow(240)
 if rect==cull_rect:return
 cull_rect=rect
 for entry in culled:
  var node: Node2D=entry.node
  if is_instance_valid(node):node.visible=rect.intersects(entry.rect)
func _process(delta: float) -> void:
 clock+=delta
 update_cull()
 update_walkers()
 tick+=delta
 if tick>=1.0/20.0:
  tick=0
  if is_instance_valid(floor_fx):floor_fx.queue_redraw()
  if is_instance_valid(dynamic):dynamic.queue_redraw()
  if is_instance_valid(effects):effects.queue_redraw()
  if is_instance_valid(orbs):orbs.queue_redraw()
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
  var facing: int=int(walker.get("facing",0))
  var sheet: Dictionary=entry.get("sheet",{})
  if sprite!=null and not sheet.is_empty():
   var texture: Texture2D=tex(String(sheet.get("sheet","")))
   if texture!=null:
    var cell: Array=sheet.get("cell",[192,192])
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
    var foot: Array=sheet.get("foot",[96.0,176.0])
    sprite.position=-Vector2(float(foot[0]),float(foot[1]))*scale_value
    sprite.skew=0.0
    sprite.modulate=Color(1,1,1,1)
  elif sprite!=null:
   var dir:=Vector2.from_angle(facing*PI/4.0)
   sprite.skew=(dir.x)*0.10
## ---------------------------------------------------------------- 바닥층
func draw_floor() -> void:
 if rules==null:return
 draw_zone_fog(floor_fx)
 draw_safe_zone(floor_fx)
func draw_zone_fog(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null:return
 for zone_id in g.lit_zones().keys():
  var rect: Rect2=L.zone_rect(String(zone_id))
  if rect.size.x<=0.0:continue
  node.draw_rect(rect,Color(.02,.02,.05,.44))
  node.draw_rect(rect,Color(.30,.46,.80,.20),false,3.0)
  node.draw_string(FONT,rect.position+Vector2(26,rect.size.y-18),"암전 · LIGHTS OUT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.55,.70,1,.65))
 if g.fog_active():
  for k in range(7):
   var a:=clock*.5+float(k)*TAU/7.0
   var at: Vector2=g.smoke_pos+Vector2.from_angle(a)*(float(g.smoke_radius)*.45)
   for j in range(3):
    node.draw_circle(at+Vector2(sin(clock+k+j)*12.0,cos(clock*1.2+k-j)*9.0),float(g.smoke_radius)*(.28+.06*j),Color(.52,.52,.58,.045))
  node.draw_arc(g.smoke_pos,float(g.smoke_radius),0,TAU,44,Color(.85,.82,.9,.28),3.0,false)
  countdown_tag(node,g.smoke_pos-Vector2(0,float(g.smoke_radius)+14),float(g.smoke_until)-rules.elapsed,"환풍기 연기",Color(.9,.88,.95))
 if g.speaker_active():
  var left: float=float(g.speaker_until)-rules.elapsed
  var life: float=clampf(left/7.0,0.0,1.0)
  node.draw_arc(g.speaker_pos,float(g.speaker_radius),0,TAU,64,Color(.9,.6,1,.16+.16*life),3.0,false)
  for k in range(3):
   node.draw_arc(g.speaker_pos,float(g.speaker_radius)*(.35+float(k)*.22),0,TAU,48,Color(.85,.55,1,.10*life),2.0,false)
## 안전구역: 네온 번화가에 맞춘 마젠타/시안 경고 링.
func draw_safe_zone(node: Node2D) -> void:
 var zone: Dictionary=rules.circle()
 var center: Vector2=zone.center
 var radius: float=float(zone.radius)
 var pulse: float=.5+.5*sin(clock*2.6)
 for i in range(14):
  var inner: float=radius+float(i)*64.0
  node.draw_arc(center,inner+32.0,0,TAU,110,Color(.45,.05,.30,.030),64.0,false)
 for i in range(72):
  if i%2==1:continue
  var a0: float=float(i)*TAU/72.0
  node.draw_arc(center,radius+16.0,a0,a0+TAU/72.0,10,Color(1,.28,.55,.40),18.0,false)
 node.draw_arc(center,radius,0,TAU,128,Color(.62,.20,.80,.85),7.0,true)
 node.draw_arc(center,radius-8.0,0,TAU,128,Color(1,.45,.85,.55+.25*pulse),3.0,true)
 node.draw_arc(center,radius+9.0,0,TAU,128,Color(.35,.95,1,.55+.30*pulse),4.0,true)
 var sweep: float=clock*.8
 node.draw_arc(center,radius-3.0,sweep,sweep+0.5,12,Color(1,.55,.9,.45),4.0,true)
 var next_radius: float=float(zone.get("next_radius",radius))
 var next_center: Vector2=zone.get("next_center",center)
 for i in range(64):
  if i%3!=0:continue
  var a1: float=float(i)*TAU/64.0
  node.draw_arc(next_center,next_radius,a1,a1+TAU/64.0*.55,5,Color(.6,.9,1,.22),2.0,true)
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
func draw_gimmick_objects(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null:return
 var now: float=rules.elapsed
 for item in L.GIMMICKS:
  var kind: String=String(item.kind)
  var pos: Vector2=item.pos
  match kind:
   "flash":
    if g.flash_active():
     var pulse: float=.5+.5*sin(clock*10.0)
     node.draw_circle(g.flash_pos,220,Color(1,1,1,.10+.12*pulse))
     node.draw_circle(g.flash_pos,120,Color(1,1,1,.16+.18*pulse))
     node.draw_circle(g.flash_pos,44,Color(1,1,1,.35*pulse))
    node.draw_rect(Rect2(pos-Vector2(22,58),Vector2(44,58)),Color(.10,.09,.15,.95))
    node.draw_rect(Rect2(pos-Vector2(20,56),Vector2(40,30)),Color(1,.62,.85,.75))
    node.draw_circle(pos+Vector2(0,-30),7,Color(1,.92,1,.9))
   "claw":
    node.draw_rect(Rect2(pos-Vector2(26,58),Vector2(52,58)),Color(.10,.09,.15,.95))
    node.draw_rect(Rect2(pos-Vector2(22,54),Vector2(44,34)),Color(.55,.9,1,.35))
    for k in range(3):
     node.draw_circle(pos+Vector2(-12+float(k)*12,-30),5,Color(1,.7,.85,.85))
    if g.noise_kind==String(item.id) and g.noise_until>now:draw_noise_rings(node,pos+Vector2(0,-40),g.noise_until-now)
   "speaker":
    var stex:=prop_texture("speaker")
    if stex!=null:
     var ss: float=56.0/stex.get_height()
     node.draw_set_transform(pos+Vector2(0,-4),0,Vector2(ss,ss))
     node.draw_texture(stex,-Vector2(stex.get_width()*.5,stex.get_height()),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if g.speaker_active():countdown_tag(node,pos+Vector2(0,-70),g.speaker_until-now,"발소리 교란",Color(.9,.6,1))
   "shutter":
    var rect2: Rect2=item.rect
    var open: bool=g.shutter_until<=now
    node.draw_rect(Rect2(Vector2(rect2.position.x-6,rect2.position.y),Vector2(rect2.size.x+12,rect2.size.y)),Color(.14,.13,.2,.95))
    for k in range(int(rect2.size.y/14.0)):
     var h: float=0.0 if open else 1.0
     node.draw_rect(Rect2(Vector2(rect2.position.x,rect2.position.y+float(k)*14.0),Vector2(rect2.size.x,12.0*h+2.0)),Color(.48,.44,.58,.95))
    if not open:countdown_tag(node,Vector2(rect2.get_center().x,rect2.position.y-26),g.shutter_until-now,"셔터",Color(1,.8,.4))
   "smoke":
    node.draw_circle(pos+Vector2(0,-6),12,Color(.35,.34,.40,.9))
    node.draw_circle(pos+Vector2(0,-6),26,Color(.75,.73,.80,.14))
    if g.fog_active():countdown_tag(node,pos+Vector2(0,-46),g.smoke_until-now,"환풍기",Color(.9,.88,.95))
   "wheel":
    var gate:=tex(String(GIMMICK_TEX["sparkland_gate"]))
    if gate!=null:
     var gs: float=120.0/gate.get_height()
     node.draw_set_transform(pos+Vector2(0,150),0,Vector2(gs,gs))
     node.draw_texture(gate,-Vector2(gate.get_width()*.5,gate.get_height()),Color(1,1,1,.95))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    var wheel:=tex(String(GIMMICK_TEX["wheel"]))
    if wheel!=null:
     var frame: int=int(clock*1.4)%2
     var wscale: float=1.8
     node.draw_set_transform(pos+Vector2(0,-40),0,Vector2(wscale,wscale))
     node.draw_texture_rect_region(wheel,Rect2(Vector2(-128,-128),Vector2(256,256)),Rect2(Vector2(float(frame)*256,0),Vector2(256,256)),Color(1,1,1,.96))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   "arcade_gate":
    var glow:=tex(String(GIMMICK_TEX["arcade_glow"]))
    if glow!=null:
     var frame2: int=int(clock*1.7)%2
     node.draw_set_transform(pos+Vector2(0,20),0,Vector2(1.35,1.35))
     node.draw_texture_rect_region(glow,Rect2(Vector2(-128,-128),Vector2(256,256)),Rect2(Vector2(float(frame2)*256,0),Vector2(256,256)),Color(1,1,1,.92))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   "stairs":
    var stairs:=tex(String(GIMMICK_TEX["stairs"]))
    if stairs!=null:
     var ss2: float=120.0/stairs.get_height()
     node.draw_set_transform(pos+Vector2(0,4),0,Vector2(ss2,ss2))
     node.draw_texture(stairs,-Vector2(stairs.get_width()*.5,stairs.get_height()),Color(1,1,1,.97))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   "neon":
    var neon:=tex(String(GIMMICK_TEX["neon_glow"]))
    if neon!=null:
     var frame3: int=int(clock*2.2)%2
     node.draw_set_transform(pos+Vector2(0,16),0,Vector2(1.1,1.1))
     node.draw_texture_rect_region(neon,Rect2(Vector2(-96,-96),Vector2(192,192)),Rect2(Vector2(float(frame3)*192,0),Vector2(192,192)),Color(1,1,1,.85))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_noise_rings(node: Node2D,at: Vector2,left: float) -> void:
 var life: float=clampf(left/3.0,0.0,1.0)
 for k in range(3):
  var rr: float=(1.0-life)*170.0+float(k)*46.0
  node.draw_set_transform(at,0,Vector2(1,.5))
  node.draw_arc(Vector2.ZERO,rr,0,TAU,32,Color(1,.85,.4,.30*life),3.0,true)
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
func draw_detection(node: Node2D) -> void:
 var human: Dictionary=rules.players.get("human",{})
 var sense: bool=rules.trail_all_until>rules.elapsed or (human.get("role","")=="daoist" and float(human.buff.get("sense",0.0))>rules.elapsed)
 if sense:
  for p in rules.players.values():
   if p.role!="daoist" or p.eliminated or p.id=="human":continue
   if rules.hidden(p):continue
   for i in range(p.trail.size()):
    var mark: Dictionary=p.trail[i]
    if rules.gimmicks!=null and rules.gimmicks.trail_blocked(mark.position):continue
    var age: float=rules.elapsed-float(mark.time)
    var alpha: float=clampf(1.0-age/6.0,0,1)*.55
    var facing: float=float(mark.facing)*PI/4
    node.draw_set_transform(mark.position,0,Vector2(1,.5))
    node.draw_arc(Vector2.ZERO,7,0,TAU,12,Color(1,.7,.9,alpha*.5),1.4,true)
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    node.draw_line(mark.position-Vector2.from_angle(facing)*5,mark.position+Vector2.from_angle(facing)*5,Color(1,.8,.95,alpha*.7),1.6,true)
 for mark in rules.marks:
  if String(mark.get("kind",""))=="glow":
   var target: Dictionary=rules.players.get(String(mark.get("target","")),{})
   if target.is_empty():continue
   var pulse: float=.5+.5*sin(clock*3.0)
   node.draw_set_transform(target.position,0,Vector2(1,.45))
   node.draw_arc(Vector2.ZERO,20+pulse*6,0,TAU,26,Color(.85,1,.92,.5+.3*pulse),2.2,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  else:
   var pulse2: float=.5+.5*sin(clock*2.4)
   node.draw_set_transform(mark.pos,0,Vector2(1,.42))
   node.draw_arc(Vector2.ZERO,14+pulse2*5,0,TAU,24,Color(1,.9,.6,.5),2.0,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for ping in rules.pings:
  var t: float=clampf((float(ping.until)-rules.elapsed)/3.0,0,1)
  node.draw_set_transform(ping.pos,0,Vector2(1,.45))
  node.draw_arc(Vector2.ZERO,18+(1.0-t)*50,0,TAU,30,Color(1,.85,.55,.34*t+.14),2.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_orbs() -> void:
 if rules==null:return
 var pulse:=.5+.5*sin(clock*2.0)
 for orb in rules.orbs:
  if float(orb.ready)>rules.elapsed:continue
  var at: Vector2=orb.p+Vector2(0,-16-sin(clock*1.6+orb.p.x*.01)*3)
  orbs.draw_circle(at,16,Color(1,.66,.88,.18+pulse*.12))
  orbs.draw_circle(at,7.0,Color(1,.86,.96,.95))
  orbs.draw_circle(at,3.4,Color(1,1,1,.92))
  orbs.draw_arc(at,11+pulse*3,0,TAU,18,Color(1,.7,.9,.34),1.4,true)
func draw_effects() -> void:
 if rules==null:return
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
