extends Node2D
## 월하의 서원 인게임 월드: 2.5D 원화 스프라이트 + 상태 변화만 다시 그리는 경량 레이어.
## 출입 한옥 3채(청월당·서고·별채)의 외관·실내·지붕 크로스페이드·실내 안개가
## layout.gd의 rect/interior/doors 수치를 그대로 사용한다.
const L=preload("res://scripts/survival/layout.gd")
const Art=preload("res://scripts/survival/seowon_art.gd")
const FX=preload("res://scripts/survival/fx.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const GOLD=Color("e8c98b")
const HANOK_OUT=preload("res://assets/woo/seowon/hanok_exterior.png")
const HANOK_IN=preload("res://assets/woo/seowon/hanok_interior.png")
const BAMBOO=preload("res://assets/woo/seowon/bamboo_cluster.png")
const POND_TEX=preload("res://assets/woo/seowon/pond_night.png")
const BRIDGE_TEX=preload("res://assets/woo/seowon/bridge_wood.png")
const MEDALLION_TEX=preload("res://assets/woo/seowon/medallion_octagon.png")
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
var buildings: Array=[]
var door_open: Dictionary={}
var water_tick:=0.0
var fx_tick:=0.0
var effects_dirty:=true
var tags: Array=[]
var culled: Array=[]
var cull_rect:=Rect2()
var current_interior:=""
var fog_strength:=0.0
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;y_sort_enabled=true
 ground=Node2D.new();ground.z_index=-100;ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;ground.draw.connect(draw_ground);add_child(ground)
 build_medallion()
 build_pond()
 build_bridge()
 build_buildings()
 build_garden()
 water=Node2D.new();water.z_index=-88;water.draw.connect(func()->void:Art.draw_water_glints(water,L.POND,clock));add_child(water)
 effects=Node2D.new();effects.z_index=8;effects.draw.connect(draw_effects);add_child(effects)
func draw_ground() -> void:
 Art.draw_base(ground)
 Art.draw_walls(ground)
 Art.draw_ground_decor(ground)
## 마당 팔각 문양은 원화 한 장으로 깔고, 돌바닥 위에 자연스럽게 얹는다.
func build_medallion() -> void:
 var sprite:=Sprite2D.new();sprite.texture=MEDALLION_TEX;sprite.centered=true;sprite.z_index=-96
 var diameter:=L.MEDALLION_RADIUS*2.0
 var side: float=maxf(MEDALLION_TEX.get_width(),MEDALLION_TEX.get_height())
 var s:=diameter/side
 sprite.scale=Vector2(s,s*1.02);sprite.position=L.MEDALLION+Vector2(0,14)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.modulate=Color(.92,.92,1,.96)
 add_child(sprite)
func build_pond() -> void:
 var shadow:=Node2D.new();shadow.z_index=-93;shadow.draw.connect(func()->void:
  for i in range(3):
   var grow:=6+i*7
   Art.round_rect(shadow,L.POND.grow(grow),Color(.02,.03,.07,.16),20+grow*.4));add_child(shadow)
 var sprite:=Sprite2D.new();sprite.texture=POND_TEX;sprite.centered=false;sprite.z_index=-92
 sprite.position=L.POND.position-Vector2(6,6)
 sprite.scale=Vector2((L.POND.size.x+12)/POND_TEX.get_width(),(L.POND.size.y+12)/POND_TEX.get_height())
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.modulate=Color(.94,.96,1)
 add_child(sprite)
## 아치 목교: 원화를 다리 축에 맞춰 눕히고, 물 위 그림자를 따로 깐다.
func build_bridge() -> void:
 var axis:=L.BRIDGE_B-L.BRIDGE_A;var length:=axis.length();var angle:=axis.angle()
 var shadow:=Sprite2D.new();shadow.texture=BRIDGE_TEX;shadow.centered=true;shadow.z_index=-86
 shadow.position=L.BRIDGE_A.lerp(L.BRIDGE_B,.5)+Vector2(0,10)
 shadow.rotation=angle;shadow.scale=Vector2(length/BRIDGE_TEX.get_width()*.98,.42)
 shadow.modulate=Color(.02,.04,.09,.55);shadow.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(shadow)
 var deck:=Sprite2D.new();deck.texture=BRIDGE_TEX;deck.centered=true;deck.z_index=-80
 deck.position=L.BRIDGE_A.lerp(L.BRIDGE_B,.5)
 deck.rotation=angle
 # 원화는 정면 뷰이므로 세로를 눌러 2.5D 평면에 맞춘다.
 deck.scale=Vector2(length/BRIDGE_TEX.get_width(),.52)
 deck.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(deck)
 for end in [L.BRIDGE_A,L.BRIDGE_B]:
  var stone:=Node2D.new();stone.position=end;stone.z_index=-79
  stone.draw.connect(func()->void:
   stone.draw_circle(Vector2(0,4),26,Color(.05,.05,.09,.45))
   stone.draw_circle(Vector2.ZERO,22,Color("3d3c4c"));stone.draw_arc(Vector2.ZERO,22,0,TAU,20,Color(.12,.11,.16,.8),2.5,true))
  add_child(stone)
func build_buildings() -> void:
 for data in L.buildings():
  var rect: Rect2=data.rect
  var interior_rect: Rect2=data.interior
  var door: Vector2=(data.doors as Dictionary).front
  var anchor: Vector2=data.anchor
  var holder:=Node2D.new();holder.name="Hanok_"+String(data.id);holder.position=door
  var exterior:=Sprite2D.new();exterior.texture=HANOK_OUT;exterior.centered=false
  var s: float=rect.size.x/HANOK_OUT.get_width()
  exterior.scale=Vector2(s,s);exterior.position=Vector2(-anchor.x*HANOK_OUT.get_width()*s,-anchor.y*HANOK_OUT.get_height()*s)
  exterior.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  holder.add_child(exterior)
  var glow_node:=Node2D.new();var warmth: Color=data.warmth
  glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-110),rect.size.x*.36,Color(warmth.r*.9,warmth.g*.66,warmth.b*.32,.16)));holder.add_child(glow_node)
  add_child(holder)
  var interior:=Sprite2D.new();interior.texture=HANOK_IN;interior.centered=true;interior.z_index=-60
  var ins: float=rect.size.x*1.02/HANOK_IN.get_width()
  interior.scale=Vector2(ins,ins*1.04);interior.position=interior_rect.get_center()
  interior.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;interior.modulate=Color(1,1,1,0);interior.visible=false
  add_child(interior)
  var fog:=Node2D.new();fog.name="Fog_"+String(data.id);fog.z_index=45;fog.visible=false
  fog.draw.connect(func()->void:draw_interior_fog(fog,interior_rect))
  add_child(fog)
  # 현판: 문 위에 금빛 이름패
  var sign:=Label.new();sign.text=String(data.name);sign.name="Sign_"+String(data.id)
  sign.add_theme_font_override("font",TITLE_FONT);sign.add_theme_font_size_override("font_size",22)
  sign.add_theme_color_override("font_color",Color("f6e0a8"));sign.add_theme_color_override("font_outline_color",Color(.03,.03,.06));sign.add_theme_constant_override("outline_size",4)
  sign.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sign.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  var sign_width:=44.0+String(data.name).length()*15.0
  var painted: Vector2=data.painted_door
  sign.position=Vector2(painted.x-sign_width-18,painted.y-24);sign.size=Vector2(sign_width,26)
  sign.z_index=30
  var plaque:=StyleBoxFlat.new();plaque.bg_color=Color(.05,.04,.07,.9);plaque.border_color=Color(GOLD,.75)
  plaque.set_border_width_all(2);plaque.set_corner_radius_all(4);plaque.content_margin_top=2;plaque.content_margin_bottom=2
  sign.add_theme_stylebox_override("normal",plaque)
  add_child(sign)
  buildings.append({"data":data,"holder":holder,"exterior":exterior,"interior":interior,"fog":fog,"sign":sign,"alpha":1.0,"door":0.0})
  culled.append({"node":holder,"rect":Rect2(Vector2(rect.position.x-40,rect.position.y-260),Vector2(rect.size.x+80,rect.size.y+280))})
  for entry in L.building_doors(String(data.id)):door_open[entry.id]=0.0
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
  # 사물 이름 라벨은 화면을 가려 쓰지 않는다. 가까우면 옅은 빛테만 남긴다.
## 실내에 들어가면 방 바깥을 어두운 밤안개로 덮어 시야를 차단한다.
func draw_interior_fog(node: Node2D,rect: Rect2) -> void:
 var step:=46.0
 for i in range(1,11):
  var outer:=rect.grow(step*i)
  var inner:=rect.grow(step*(i-1))
  var alpha:=.13 + .035*i
  var color:=Color(.015,.02,.05,alpha)
  node.draw_rect(Rect2(outer.position.x,outer.position.y,outer.size.x,step),color)
  node.draw_rect(Rect2(outer.position.x,outer.end.y-step,outer.size.x,step),color)
  node.draw_rect(Rect2(outer.position.x,inner.position.y,step,inner.size.y),color)
  node.draw_rect(Rect2(outer.end.x-step,inner.position.y,step,inner.size.y),color)
 var mist:=Color(.16,.22,.4,.05)
 node.draw_rect(rect.grow(step*10),mist,false,step*8)
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
 update_cull()
 water_tick+=delta
 if water_tick>=.1:water_tick=0;water.queue_redraw()
 update_buildings(delta)
 var near:=L.object_near(observer,150)
 fx_tick+=delta
 var busy: bool=aim_active or (rules!=null and not rules.effects.is_empty()) or not String(L.door_near(observer)).is_empty() or not near.is_empty()
 if busy and fx_tick>=1.0/20.0:fx_tick=0;effects_dirty=true
 if effects_dirty:effects_dirty=false;effects.queue_redraw()
func update_buildings(delta: float) -> void:
 var room:=L.interior_at(observer,6)
 current_interior=String(room.get("id",""))
 for building in buildings:
  var data: Dictionary=building.data
  var inside: bool=String(data.id)==current_interior
  var target:=0.0 if inside else 1.0
  var alpha: float=move_toward(float(building.alpha),target,delta*4.5)
  building.alpha=alpha
  var exterior: Sprite2D=building.exterior
  if is_instance_valid(exterior):exterior.modulate.a=lerp(.06,1.0,alpha)
  var sign: Label=building.sign
  if is_instance_valid(sign):sign.modulate.a=alpha
  var interior: Sprite2D=building.interior
  if is_instance_valid(interior):
   interior.modulate.a=1.0-alpha
   interior.visible=alpha<.99
  var fog: Node2D=building.fog
  if is_instance_valid(fog):
   fog.modulate.a=1.0-alpha
   fog.visible=alpha<.99
 # 열린 문은 문틀이 밝아지고 지붕 그림자가 옅어진다.
 for building in buildings:
  var data: Dictionary=building.data
  var open:=0.0
  for entry in L.building_doors(String(data.id)):
   var near:=observer.distance_to(entry.center)<64 or (rules!=null and float(rules.doors.get(entry.id,0.0))>clock)
   door_open[entry.id]=move_toward(float(door_open.get(entry.id,0.0)),1.0 if near else 0.0,delta*4)
   open=maxf(open,float(door_open[entry.id]))
  building.door=open
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
  for entry in L.DOORS:
   var open: float=float(door_open.get(entry.id,0.0))
   if open<=.02:continue
   var center: Vector2=entry.center
   if entry.side=="front":center=L.painted_door(String(entry.building))
   elif not L.building(String(entry.building)).is_empty():center=L.building(String(entry.building)).rect.position+Vector2((entry.center as Vector2).x-L.building(String(entry.building)).rect.position.x,18)
   var pulse: float=.5+.5*sin(clock*3.4)
   var frame:=Rect2(center-Vector2(L.DOOR_WIDTH*.5,18),Vector2(L.DOOR_WIDTH,36))
   for i in range(4):
    effects.draw_rect(frame.grow(4+i*4),Color(1,.8,.42,.44*open*(1-i*.2)),false,2)
   effects.draw_rect(Rect2(frame.position+Vector2(0,-2),Vector2(frame.size.x,5)),Color(1,.9,.58,.34*open*pulse))
   Art.glow(effects,center,74,Color(1,.68,.3,.24*open))
  # 화면을 가리던 월드 팝업(문 열기·둔갑 가능·손 아이콘·사물 이름)은 없앴다.
  # 둔갑 가능 여부는 도사에게만, 가까운 사물에 옅은 빛테로만 알린다.
  var near:=L.object_near(observer,96)
  if not near.is_empty() and not human.is_empty() and String(human.get("role",""))=="daoist":
   var ready: bool=String(human.get("character",""))!="" and float(human.buff.get("transform",0.0))<=rules.elapsed and String(human.get("form",""))==""
   if ready:
    var pulse: float=.5+.5*sin(clock*3.2)
    Art.glow(effects,near.p+Vector2(0,-14),30,Color(.75,.9,1,.10+.05*pulse))
    effects.draw_arc(near.p+Vector2(0,-2),20,.15*PI,.85*PI,18,Color(.82,.92,1,.34+.16*pulse),2.0,true)
func hand(_node: Node2D,_at: Vector2) -> void:
 # 월드 위 손 아이콘은 쓰지 않는다(화면을 가림).
 pass
func tag(node: Node2D,at: Vector2,text: String,color: Color) -> void:
 var width: float=54.0+text.length()*11.0
 var rect:=Rect2(at-Vector2(width*.5,15),Vector2(width,24))
 node.draw_rect(Rect2(rect.position+Vector2(0,2),rect.size),Color(.01,.02,.05,.55))
 node.draw_rect(rect,Color(.04,.05,.1,.86))
 node.draw_rect(rect,Color(.85,.7,.42,.55),false,1)
 node.draw_string(FONT,rect.position+Vector2(0,16),text,HORIZONTAL_ALIGNMENT_CENTER,width,12,color)
func door_at(p: Vector2) -> String:return L.door_near(p,64)
