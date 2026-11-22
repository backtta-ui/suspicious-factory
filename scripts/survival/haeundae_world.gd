extends Node2D
## 부산 해운대 인게임 월드(2.0.35). world.gd(서원)·gangnam_world.gd와 같은 공개
## 인터페이스(rules·observer·aim·aim_active·aim_cancelled)를 제공하고,
## 충돌·사물·기믹 좌표는 haeundae_layout.gd 한 곳에서만 가져온다.
## 밤바다의 청록 물빛 + 백사장 + 포장마차 등불. 기믹 상태를 그대로 그린다.
const L=preload("res://scripts/survival/haeundae_layout.gd")
const Art=preload("res://scripts/survival/haeundae_art.gd")
const FX=preload("res://scripts/survival/fx.gd")
## 2.0.37 네 맵 공통 이펙트 렌더러(함정·장판·연막·감지).
const MapFx=preload("res://scripts/survival/map_fx.gd")
const C=preload("res://scripts/survival/characters.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const GOLD=Color("8ff0ff")
const PROP_DIR="res://assets/woo/haeundae/"
const PROP_TEX={
 "parasol":"props/parasol.png",
 "tube":"props/tube.png",
 "surfboard":"props/surfboard.png",
 "cooler":"props/cooler.png",
 "pocha_stall":"props/pocha_stall.png",
 "plastic_chair":"props/plastic_chair.png",
 "beach_ball":"props/beach_ball.png",
 "seagull":"moving/seagull.png",
 "crab":"moving/crab.png"}
const GIMMICK_TEX={
 "telescope":"gimmicks/telescope.png",
 "tent":"gimmicks/pocha_tent.png",
 "tent_sway":"gimmicks/pocha_tent_sway_2f.png",
 "lighthouse":"gimmicks/lighthouse.png",
 "beam":"gimmicks/lighthouse_beam_2f.png"}
const ANIMAL_HEIGHT={"seagull":24.0,"crab":18.0}
var rules: RefCounted
var observer:=L.SPAWN
var clock:=0.0
## 2.0.36 들어가면 지붕이 사라지는 실내 레이어.
var interior_layer: Node2D
var zone_labels: Node2D
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
var water: Node2D
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 y_sort_enabled=true
 ground=Node2D.new();ground.name="Ground";ground.z_index=-100
 ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 ground.draw.connect(func()->void:Art.draw_base(ground))
 add_child(ground)
 # 2.0.38 밤바다 물결·거품(동적). 바닥과 벽 사이에 깔린다.
 water=Node2D.new();water.name="Sea";water.z_index=-94
 water.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 water.draw.connect(func()->void:Art.draw_water(water,clock))
 add_child(water)
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
 interior_layer=preload("res://scripts/survival/interior_layer.gd").new()
 interior_layer.name="Interiors"
 interior_layer.layout=L
 add_child(interior_layer)
 # 2.0.38 구역 바닥 표지판(실내·백 레이어 위, 액터 아래).
 zone_labels=preload("res://scripts/survival/zone_labels.gd").new()
 zone_labels.name="ZoneLabels"
 add_child(zone_labels)
 zone_labels.setup(L)

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
  culled.append({"node":holder,"rect":Rect2(data.p-Vector2(90,130),Vector2(180,170))})
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
    var height: float=float(ANIMAL_HEIGHT.get(kind,24.0))
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
 if is_instance_valid(interior_layer):interior_layer.observer=observer
 update_cull()
 update_walkers()
 tick+=delta
 if is_instance_valid(water):water.queue_redraw()
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
    var height: float=float(ANIMAL_HEIGHT.get(String(walker.kind),24.0))
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
 draw_wave_surge(floor_fx)
 draw_tide(floor_fx)
 draw_zone_fog(floor_fx)
 draw_safe_zone(floor_fx)
 MapFx.floor_layer(floor_fx,rules,clock,MapFx.TONE_BRIGHT)
## 파도 경보: 해안 구역 가장자리를 따라 밀려오는 물결 띠.
func draw_wave_surge(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null or not g.wave_active():return
 var pulse: float=.5+.5*sin(clock*3.2)
 for zone_id in g.wave_zones:
  var rect: Rect2=L.zone_rect(String(zone_id))
  if rect.size.x<=0.0:continue
  var wave_h: float=40.0+28.0*pulse
  # 남쪽 가장자리부터 밀려오는 물결
  var y: float=rect.end.y-wave_h
  node.draw_rect(Rect2(Vector2(rect.position.x,y),Vector2(rect.size.x,wave_h)),Color(.16,.52,.72,.20))
  for k in range(6):
   var yy: float=y+float(k)*wave_h/6.0
   node.draw_line(Vector2(rect.position.x,yy),Vector2(rect.end.x,yy+sin(clock*4.0+k)*4.0),Color(.72,.94,1,.20),2.0)
  for k2 in range(int(rect.size.x/60.0)):
   var xx: float=rect.position.x+float(k2)*60.0+sin(clock*2.0+k2)*10.0
   node.draw_circle(Vector2(xx,y+wave_h*.7),4.0,Color(.85,.97,1,.30))
  node.draw_string(FONT,rect.position+Vector2(rect.size.x-210,wave_h+26),"파도 경보",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(.72,.94,1,.85))
## 밀물: 지름길(다리)이 잠기면 물이 차오르고, 평소에는 나무 다리로 보인다.
func draw_tide(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null or g.tide_rect.size.x<=0.0:return
 var rect: Rect2=g.tide_rect
 var flooded: bool=g.tide_active()
 if flooded:
  node.draw_rect(rect,Color(.10,.38,.56,.92))
  node.draw_rect(rect,Color(.55,.88,1,.35),false,2.0)
  for k in range(4):
   var yy: float=rect.position.y+float(k)*rect.size.y/4.0+sin(clock*3.0+k)*3.0
   node.draw_line(Vector2(rect.position.x+4,yy),Vector2(rect.end.x-4,yy),Color(.78,.96,1,.28),1.6)
  countdown_tag(node,Vector2(rect.get_center().x,rect.position.y-26),g.tide_until-rules.elapsed,"밀물",Color(.6,.9,1))
 else:
  # 나무 다리 널판
  var y2: float=rect.position.y+10.0
  while y2<rect.end.y-6.0:
   node.draw_rect(Rect2(Vector2(rect.position.x+6,y2),Vector2(rect.size.x-12,7)),Color(.42,.29,.18,.95))
   y2+=13.0
  node.draw_rect(rect,Color(.72,.52,.32,.55),false,1.6)
## 암전 구역과 물안개·연기.
func draw_zone_fog(node: Node2D) -> void:
 var g: RefCounted=rules.gimmicks
 if g==null:return
 for zone_id in g.lit_zones().keys():
  var rect: Rect2=L.zone_rect(String(zone_id))
  if rect.size.x<=0.0:continue
  node.draw_rect(rect,Color(.02,.02,.05,.42))
  node.draw_rect(rect,Color(.30,.46,.80,.20),false,3.0)
  node.draw_string(FONT,rect.position+Vector2(26,rect.size.y-18),"암전 · LIGHTS OUT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.55,.70,1,.65))
 if g.mist_active():
  var center: Vector2=g.mist_pos
  for k in range(7):
   var a:=clock*.5+float(k)*TAU/7.0
   var at: Vector2=center+Vector2.from_angle(a)*(float(g.mist_radius)*.42)
   for j in range(3):
    node.draw_circle(at+Vector2(sin(clock+k+j)*10.0,cos(clock*1.3+k-j)*8.0),float(g.mist_radius)*(.30+.06*j),Color(.82,.92,1,.055))
  node.draw_arc(center,float(g.mist_radius),0,TAU,48,Color(.78,.92,1,.28),3.0,false)
  countdown_tag(node,center-Vector2(0,float(g.mist_radius)+16),float(g.mist_until)-rules.elapsed,"물안개",Color(.8,.95,1))
 if g.fog_active():
  for k in range(6):
   var a2:=clock*.4+float(k)*TAU/6.0
   node.draw_circle(g.smoke_pos+Vector2.from_angle(a2)*float(g.smoke_radius)*.4,float(g.smoke_radius)*.42,Color(.72,.70,.78,.10))
  node.draw_arc(g.smoke_pos,float(g.smoke_radius),0,TAU,42,Color(.80,.80,.86,.22),2.6,false)
  countdown_tag(node,g.smoke_pos-Vector2(0,g.smoke_radius+14),g.smoke_until-rules.elapsed,"연기",Color(.85,.85,.9))
## 안전구역(비상통제구역): 청록/붉은 네온 경고 링 + 원 밖 붉은 해저드 빗금.
## 2.0.36 해운대 자기장: 밀물침식. 안전구역 밖은 물이 차오르고, 경계는 하얀 거품 파도.
## 원이 줄어들수록 물이 안쪽까지 밀려 들어오는 것이 화면에서 그대로 읽힌다.
func draw_safe_zone(node: Node2D) -> void:
 var zone: Dictionary=rules.circle()
 var center: Vector2=zone.center
 var radius: float=float(zone.radius)
 var pulse: float=.5+.5*sin(clock*2.2)
 var wave: float=sin(clock*1.1)*14.0
 # 원 밖: 차오르는 바닷물(링 밴드마다 물빛·거품)
 for i in range(16):
  var inner: float=radius+float(i)*58.0
  var band:=Color(.04,.18,.32,.040+.010*float(16-i))
  node.draw_arc(center,inner+29.0,0,TAU,110,band,58.0,false)
 # 물결선: 원 밖을 따라 흐르는 파도
 for i in range(4):
  var rr: float=radius+40.0+float(i)*78.0+wave
  for k in range(36):
   var a0: float=float(k)*TAU/36.0+clock*.18*float(i+1)
   node.draw_arc(center,rr,a0,a0+TAU/36.0*.62,8,Color(.62,.90,1,.16+.05*float(4-i)),3.0,true)
 # 경계: 하얀 거품 + 청록 물빛 이중 링
 node.draw_arc(center,radius,0,TAU,128,Color(.78,.95,1,.90),7.0,true)
 node.draw_arc(center,radius-5.0,0,TAU,128,Color(.35,.85,1,.55+.20*pulse),3.0,true)
 for i in range(48):
  var a:=float(i)*TAU/48.0+clock*.25
  var foam:=center+Vector2.from_angle(a)*(radius+6.0+sin(clock*3.0+float(i))*4.0)
  node.draw_circle(foam,2.2+.8*pulse,Color(.90,1,1,.55+.30*pulse))
 # 모래가 물에 잠식되는 안쪽 물결
 node.draw_arc(center,radius-24.0-wave*.3,0,TAU,96,Color(.95,.85,.60,.22),10.0,false)
 node.draw_arc(center,radius-52.0,0,TAU,96,Color(.95,.85,.60,.10),6.0,false)
 # 다음 원 미리보기(물빛 점선)
 var next_radius: float=float(zone.get("next_radius",radius))
 var next_center: Vector2=zone.get("next_center",center)
 for i in range(64):
  if i%3!=0:continue
  var a1: float=float(i)*TAU/64.0
  node.draw_arc(next_center,next_radius,a1,a1+TAU/64.0*.55,5,Color(.72,.95,1,.24),2.0,true)
 node.draw_string(FONT,center+Vector2(-150,-radius-18),"밀물 침식 · 이 안쪽으로",HORIZONTAL_ALIGNMENT_CENTER,300,20,Color(.86,.97,1,.75))
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
   "wave":
    var active: bool=g.wave_active()
    node.draw_circle(pos+Vector2(0,-26),13,Color(.55,.85,1,.85) if active else Color(.35,.55,.72,.5))
    node.draw_circle(pos+Vector2(0,-26),22,Color(.55,.85,1,.15+.20*(0.5+0.5*sin(clock*4.0))))
    countdown_tag(node,pos-Vector2(0,64),g.wave_until-now if active else maxf(0.0,g.wave_next-now),"파도" if active else "파도 경보",Color(.62,.9,1))
   "tide":
    if g.tide_active():countdown_tag(node,pos+Vector2(0,-6),g.tide_until-now,"밀물",Color(.62,.9,1))
   "light":
    var off: bool=g.zone_dark(String(item.zone))
    node.draw_rect(Rect2(pos-Vector2(4,30),Vector2(8,30)),Color(.20,.24,.30,.95))
    node.draw_circle(pos+Vector2(0,-34),8,Color(.4,.55,.7,.9) if off else Color(1,1,1,.95))
    node.draw_circle(pos+Vector2(0,-34),16,Color(.6,.85,1,.05) if off else Color(1,.95,.75,.22))
    if off:countdown_tag(node,pos+Vector2(0,-62),float(g.lights.get(String(item.zone),0.0))-now,"암전",Color(.6,.7,1))
   "mist":
    var mtex:=prop_texture("cooler")
    node.draw_circle(pos+Vector2(0,-18),16,Color(.35,.6,.7,.85))
    node.draw_circle(pos+Vector2(0,-18),9,Color(.75,.92,1,.9))
    if g.mist_active():countdown_tag(node,pos+Vector2(0,-52),g.mist_until-now,"샤워기",Color(.8,.95,1))
   "telescope":
    var ttex:=tex(String(GIMMICK_TEX["telescope"]))
    if ttex!=null:
     var ts: float=70.0/ttex.get_height()
     node.draw_set_transform(pos+Vector2(0,-8),0,Vector2(ts,ts))
     node.draw_texture(ttex,-Vector2(ttex.get_width()*.5,ttex.get_height()),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    if g.telescope_active():countdown_tag(node,pos+Vector2(0,-92),g.telescope_until-now,"관측",Color(.8,.95,1))
   "bell":
    var btex:=prop_texture("pocha_stall")
    if btex!=null:
     var bs: float=58.0/btex.get_height()
     node.draw_set_transform(pos+Vector2(0,-6),0,Vector2(bs,bs))
     node.draw_texture(btex,-Vector2(btex.get_width()*.5,btex.get_height()),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    node.draw_circle(pos+Vector2(0,-64),6,Color(1,.82,.45,.9))
    if g.noise_kind==String(item.id) and g.noise_until>now:
     draw_noise_rings(node,pos+Vector2(0,-30),g.noise_until-now)
   "lighthouse":
    var ltex:=tex(String(GIMMICK_TEX["lighthouse"]))
    if ltex!=null:
     var ls: float=190.0/ltex.get_height()
     node.draw_set_transform(pos+Vector2(0,-4),0,Vector2(ls,ls))
     node.draw_texture(ltex,-Vector2(ltex.get_width()*.5,ltex.get_height()),Color(1,1,1,.98))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    var beam:=tex(String(GIMMICK_TEX["beam"]))
    if beam!=null:
     var frame: int=int(clock*1.1)%2
     var angle: float=clock*.55
     node.draw_set_transform(pos+Vector2(0,-150),angle,Vector2(1.5,1.5))
     node.draw_texture_rect_region(beam,Rect2(Vector2(-128,-256),Vector2(256,256)),Rect2(Vector2(float(frame)*256,0),Vector2(256,256)),Color(1,1,1,.34))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   "tent":
    var sway:=tex(String(GIMMICK_TEX["tent_sway"]))
    if sway!=null:
     var frame2: int=int(clock*1.6)%2
     node.draw_set_transform(pos+Vector2(0,-4),0,Vector2(1.3,1.3))
     node.draw_texture_rect_region(sway,Rect2(Vector2(-96,-96),Vector2(192,192)),Rect2(Vector2(float(frame2)*192,0),Vector2(192,192)),Color(1,1,1,.96))
     node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    else:
     var tent:=tex(String(GIMMICK_TEX["tent"]))
     if tent!=null:
      var ts2: float=120.0/tent.get_height()
      node.draw_set_transform(pos+Vector2(0,-4),0,Vector2(ts2,ts2))
      node.draw_texture(tent,-Vector2(tent.get_width()*.5,tent.get_height()),Color(1,1,1,.96))
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
## 요괴의 감지(발자국·탐지·핑) — 서원과 같은 규칙, 해변 바닥 색만 다르다.
func draw_detection(node: Node2D) -> void:
 MapFx.detection(node,rules,clock,MapFx.TONE_BRIGHT)

func draw_orbs() -> void:
 if rules==null:return
 var pulse:=.5+.5*sin(clock*2.0)
 for orb in rules.orbs:
  if float(orb.ready)>rules.elapsed:continue
  var at: Vector2=orb.p+Vector2(0,-16-sin(clock*1.6+orb.p.x*.01)*3)
  orbs.draw_circle(at,16,Color(.55,.9,1,.18+pulse*.12))
  orbs.draw_circle(at,7.0,Color(.72,.96,1,.95))
  orbs.draw_circle(at,3.4,Color(1,1,1,.92))
  orbs.draw_arc(at,11+pulse*3,0,TAU,18,Color(.62,.95,1,.34),1.4,true)
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
