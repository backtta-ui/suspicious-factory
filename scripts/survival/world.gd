extends Node2D
## 월하의 서원 인게임 월드: 2.5D 원화 스프라이트 + 상태 변화만 다시 그리는 경량 레이어.
## 출입 한옥 6채의 외관·실내·지붕 크로스페이드·실내 안개가
## layout.gd의 rect/interior/doors 수치를 그대로 사용한다.
## 2.0.26 비주얼 개편: 검은 사각 그림자를 없애고, 모든 사물·건물·나무가
## 부드러운 접지 그림자(shadow_soft)를 공유한다. 담장은 벽 길이에 맞춰
## 기와 띠를 그려서 줌 1.90에서도 결이 살아 있다.
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
const SHADOW_TEX=preload("res://assets/woo/seowon/shadow_soft.png")
const GROUND_SHADER=preload("res://assets/woo/seowon/ground_detail.gdshader")
const GROUND_MASK=preload("res://assets/woo/seowon/seowon_ground_mask.png")
const DETAIL_GRASS=preload("res://assets/woo/seowon/seowon_detail_grass.png")
const DETAIL_STONE=preload("res://assets/woo/seowon/seowon_detail_stone.png")
const DETAIL_YARD=preload("res://assets/woo/seowon/seowon_detail_yard.png")
const PROPS={"jar":preload("res://assets/woo/seowon/prop_jar.png"),"crate":preload("res://assets/woo/seowon/prop_crate.png"),"stele":preload("res://assets/woo/seowon/prop_stele.png"),"lantern":preload("res://assets/woo/seowon/prop_lantern.png"),"cat":preload("res://assets/woo/seowon/prop_cat.png")}
## 2.0.27 맵을 실제로 걷는 고양이·강아지: 4행(front/left/right/back) x 4열 걷기 시트.
## 둔갑하면 이 시트와 같은 박자를 그대로 복사한다.
const C=preload("res://scripts/survival/characters.gd")
const ANIMAL_HEIGHT={"cat":44.0,"dog":46.0}
const ANIMAL_SHADOW={"cat":9.0,"dog":12.0}
var animal_textures: Dictionary={}
var animal_nodes: Array=[]
var observer:=L.SPAWN
var roofs: Array=[]
var clock:=0.0
var rules: RefCounted
var aim:=Vector2.ZERO
var aim_active:=false
var aim_cancelled:=false
var ground: Node2D
var under: Node2D
var water: Node2D
var effects: Node2D
var orbs: Node2D
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
 build_ground()
 ground=Node2D.new();ground.z_index=-99;ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;ground.draw.connect(draw_ground);add_child(ground)
 # 그림자·물빛처럼 바닥 위, 사물 아래에 깔리는 층.
 under=Node2D.new();under.z_index=-95;under.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;add_child(under)
 build_medallion()
 build_pond()
 build_bridge()
 build_buildings()
 build_garden()
 water=Node2D.new();water.z_index=-88;water.draw.connect(func()->void:Art.draw_water_glints(water,L.POND,clock));add_child(water)
 effects=Node2D.new();effects.z_index=8;effects.draw.connect(draw_effects);add_child(effects)
 orbs=Node2D.new();orbs.z_index=-70;orbs.draw.connect(draw_orbs);add_child(orbs)
## 부드러운 접지 그림자 한 장. (center=발밑, size=가로세로 지름)
func shadow(center: Vector2,size: Vector2,alpha: float=1.0,z: int=-94) -> Sprite2D:
 var sprite:=Sprite2D.new();sprite.texture=SHADOW_TEX;sprite.centered=true
 sprite.z_index=z;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 sprite.position=center
 sprite.scale=Vector2(size.x/SHADOW_TEX.get_width(),size.y/SHADOW_TEX.get_height())
 sprite.modulate=Color(1,1,1,alpha)
 under.add_child(sprite)
 return sprite
## 바닥: 베이크한 색·조명(저해상도) + 결 타일 셰이더(1:1) + 담장·잔디 장식(벡터).
func build_ground() -> void:
 var void_back:=Node2D.new();void_back.z_index=-110
 void_back.draw.connect(func()->void:void_back.draw_rect(Rect2(Vector2(-200,-200),L.SIZE+Vector2(400,400)),Color("04070d")))
 add_child(void_back)
 var back:=Sprite2D.new();back.name="GroundBack";back.centered=false
 back.texture=Art.GROUND_ART;back.z_index=-100
 back.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 back.scale=Vector2(L.SIZE.x/back.texture.get_width(),L.SIZE.y/back.texture.get_height())
 var material:=ShaderMaterial.new()
 material.shader=GROUND_SHADER
 material.set_shader_parameter("mask_tex",GROUND_MASK)
 material.set_shader_parameter("grass_tex",DETAIL_GRASS)
 material.set_shader_parameter("stone_tex",DETAIL_STONE)
 material.set_shader_parameter("yard_tex",DETAIL_YARD)
 material.set_shader_parameter("world_size",L.SIZE)
 material.set_shader_parameter("stone_tile",180.0)
 material.set_shader_parameter("grass_tile",200.0)
 material.set_shader_parameter("strength",0.80)
 back.material=material
 add_child(back)
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
 sprite.scale=Vector2(s,s*1.02);sprite.position=L.MEDALLION+Vector2(0,10)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.modulate=Color(.95,.94,.98,.97)
 add_child(sprite)
func build_pond() -> void:
 var sprite:=Sprite2D.new();sprite.texture=POND_TEX;sprite.centered=false;sprite.z_index=-92
 sprite.position=L.POND.position-Vector2(6,6)
 sprite.scale=Vector2((L.POND.size.x+12)/POND_TEX.get_width(),(L.POND.size.y+12)/POND_TEX.get_height())
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.modulate=Color(.94,.96,1)
 add_child(sprite)
## 아치 목교: 원화를 다리 축에 맞춰 눕히고, 물 위 그림자를 따로 깐다.
func build_bridge() -> void:
 var axis:=L.BRIDGE_B-L.BRIDGE_A;var length:=axis.length();var angle:=axis.angle()
 var shadow_node:=Sprite2D.new();shadow_node.texture=SHADOW_TEX;shadow_node.centered=true;shadow_node.z_index=-86
 shadow_node.position=L.BRIDGE_A.lerp(L.BRIDGE_B,.5)+Vector2(0,12)
 shadow_node.rotation=angle;shadow_node.scale=Vector2(length/SHADOW_TEX.get_width()*1.3,58.0/SHADOW_TEX.get_height())
 shadow_node.modulate=Color(1,1,1,.55);shadow_node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(shadow_node)
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
  # 건물 발치의 부드러운 그림자(사각 상자가 아니라 건물 폭을 따라 번진다).
  shadow(Vector2(rect.get_center().x,rect.end.y-6),Vector2(rect.size.x*.92,rect.size.y*.34),.85)
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
  sign.add_theme_color_override("font_color",Color("f6e0a8"));sign.add_theme_color_override("font_outline_color",Color(.03,.03,.06))
  sign.add_theme_constant_override("outline_size",4)
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
 # 벚꽃나무: 줄기 밑에 부드러운 그림자와 떨어진 꽃잎.
 for p in Art.TREES:
  shadow(p+Vector2(0,6),Vector2(200,78),.9)
  var sprite:=Sprite2D.new();sprite.texture=Art.ATLAS;sprite.region_enabled=true;sprite.region_rect=Art.CHERRY_CELL
  var s:=255.0/512.0;sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-127.5,-470*s)
  sprite.modulate=Color(.94,.90,.96)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite);culled.append({"node":holder,"rect":Rect2(p-Vector2(190,360),Vector2(380,400))})
  var glow_node:=Node2D.new();glow_node.z_index=-1;glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-90),135,Color(.85,.45,.7,.12)));holder.add_child(glow_node)
  add_child(holder)
 # 대나무 군락
 for rect in L.BAMBOO:
  var count:=maxi(1,int(rect.size.y/150))
  for i in range(count):
   var base:=Vector2(rect.position.x+rect.size.x*.5,rect.position.y+40+i*(rect.size.y-60)/maxf(1,count))
   shadow(base+Vector2(0,2),Vector2((rect.size.x+40)*.85,44),.7)
   var sprite:=Sprite2D.new();sprite.texture=BAMBOO
   var s: float=(rect.size.x+40.0)/BAMBOO.get_width()
   sprite.scale=Vector2(s,s);sprite.centered=false
   sprite.position=Vector2(-(rect.size.x+40)*.5,-BAMBOO.get_height()*s*.98)
   sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var holder:=Node2D.new();holder.position=base
   holder.add_child(sprite);add_child(holder);culled.append({"node":holder,"rect":Rect2(base-Vector2(130,320),Vector2(260,350))})
 # 석등(장식): 부드러운 발밑 그림자 + 따뜻한 빛무리
 for p in Art.LANTERNS:
  shadow(p+Vector2(0,2),Vector2(72,30),.85)
  var sprite:=Sprite2D.new();sprite.texture=PROPS.lantern;var s:=78.0/PROPS.lantern.get_height()
  sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-PROPS.lantern.get_width()*s*.5,-78)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite)
  var glow_node:=Node2D.new();glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-46),96,Color(1,.68,.32,.26)));holder.add_child(glow_node)
  add_child(holder);culled.append({"node":holder,"rect":Rect2(p-Vector2(70,100),Vector2(140,120))})
 # 둔갑 사물(군집): 같은 부드러운 그림자를 공유한다.
 for data in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(data.kind))
  var shadow_side: float=float(visual.shadow)
  shadow(data.p+Vector2(0,1),Vector2(shadow_side*2.6,shadow_side*1.15),.9)
  var texture: Texture2D=PROPS.get(data.kind,PROPS.jar)
  var sprite:=Sprite2D.new();sprite.texture=texture
  var target_height: float=float(visual.height)
  var s: float=target_height/texture.get_height()
  sprite.scale=Vector2(s,s);sprite.centered=false
  sprite.position=Vector2(-texture.get_width()*s*.5,-target_height)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=data.p;holder.add_child(sprite);add_child(holder);culled.append({"node":holder,"rect":Rect2(data.p-Vector2(40,70),Vector2(80,90))})
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
 if water_tick>=.1:water_tick=0;water.queue_redraw();if is_instance_valid(orbs):orbs.queue_redraw()
 update_buildings(delta)
 var near:=L.object_near(observer,150)
 update_animals()
 fx_tick+=delta
 var busy: bool=aim_active or (rules!=null and (not rules.effects.is_empty() or not rules.walkers.is_empty() or not rules.traps.is_empty() or not rules.marks.is_empty() or rules.dark_until>rules.elapsed or rules.map_dark_until>rules.elapsed)) or not String(L.door_near(observer)).is_empty() or not near.is_empty()
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
## 기력 회복 구슬(영혼불): 푸른 빛덩이와 옅은 고리. 다시 생긴 구슬만 그린다.
func draw_orbs() -> void:
 if rules==null:return
 var pulse:=.5+.5*sin(clock*2.0)
 for orb in rules.orbs:
  if float(orb.ready)>rules.elapsed:continue
  var at: Vector2=orb.p+Vector2(0,-16-sin(clock*1.6+orb.p.x*.01)*3)
  Art.glow(orbs,at,26,Color(.55,.85,1,.30+pulse*.18))
  orbs.draw_circle(at,7.0,Color(.72,.94,1,.95))
  orbs.draw_circle(at,3.4,Color(1,1,1,.92))
  orbs.draw_arc(at,11+pulse*3,0,TAU,18,Color(.62,.9,1,.34),1.4,true)
## 걷는 동물: rules.walkers의 위치를 그대로 그린다(4방향 x 4프레임 걷기 시트).
func update_animals() -> void:
 if rules==null:return
 var walkers: Array=rules.walkers
 while animal_nodes.size()<walkers.size():
  var sprite:=Sprite2D.new();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  sprite.centered=false;sprite.z_index=0
  add_child(sprite)
  animal_nodes.append(sprite)
 for i in range(animal_nodes.size()):
  var sprite: Sprite2D=animal_nodes[i]
  if i>=walkers.size():sprite.visible=false;continue
  var entry: Dictionary=walkers[i]
  var kind: String=String(entry.kind)
  var sheet: Dictionary=C.animal_sheet(kind)
  if sheet.is_empty():sprite.visible=false;continue
  var path: String=String(sheet.get("sheet",""))
  var texture: Texture2D=animal_textures.get(path)
  if texture==null:texture=load(path);animal_textures[path]=texture
  var cell: Array=sheet.get("cell",[300,260])
  var rows: Array=sheet.get("rows",["front","left","right","back"])
  var direction: int=int(entry.facing)
  var view: String="front"
  if direction==0 or direction==1 or direction==7:view="right"
  elif direction==3 or direction==4 or direction==5:view="left"
  elif direction==6:view="back"
  var row: int=maxi(0,rows.find(view))
  var cols: int=int(sheet.get("cols",4))
  var column: int=posmod(int(floor(float(entry.phase)/(PI*.62))),cols) if bool(entry.moving) else 0
  var extent:=Vector2(float(cell[0]),float(cell[1]))
  var height: float=float(ANIMAL_HEIGHT.get(kind,44.0))
  var scale_value: float=height/maxf(1.0,float(sheet.get("target_height",44.0)))
  sprite.texture=texture;sprite.region_enabled=true
  sprite.region_rect=Rect2(Vector2(float(column)*extent.x,float(row)*extent.y),extent)
  sprite.scale=Vector2(scale_value,scale_value)
  var foot: Array=sheet.get("foot",[150.0,232.0])
  sprite.position=(entry.p as Vector2)-Vector2(float(foot[0]),float(foot[1]))*scale_value
  sprite.visible=true
## 둔갑 가능 표시: 대상 사물·동물 주위의 금빛 링과 '둔갑 가능' 표시.
func form_target() -> Dictionary:
 if rules==null:return {}
 var human: Dictionary=rules.players.get("human",{})
 if human.is_empty() or String(human.get("role",""))!="daoist" or String(human.get("form",""))!="":return {}
 var p: Vector2=observer
 var best: Dictionary={};var gap:=96.0
 for object in L.OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best={"kind":String(object.kind),"p":object.p,"animal":false}
 for entry in rules.walkers:
  var d: float=p.distance_to(entry.p)
  if d<gap:gap=d;best={"kind":String(entry.kind),"p":entry.p,"animal":true}
 return best
func draw_form_target(node: Node2D,target: Dictionary) -> void:
 var pulse: float=.5+.5*sin(clock*3.4)
 var base: Vector2=target.p
 var gold:=Color(1,.84,.42)
 var height: float=float(ANIMAL_HEIGHT.get(String(target.kind),48.0)) if bool(target.animal) else float(L.form_visual(String(target.kind)).height)
 # 바닥의 금빛 외곽선과 펄스 링
 node.draw_set_transform(base,0,Vector2(1,.42))
 node.draw_arc(Vector2.ZERO,22+pulse*4,0,TAU,32,Color(gold.r,gold.g,gold.b,.85),2.6,true)
 node.draw_arc(Vector2.ZERO,30+pulse*10,0,TAU,36,Color(gold.r,gold.g,gold.b,.22+.18*(1-pulse)),3.2,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 사물 실루엣을 따라 도는 밝은 테두리(위→아래 두 겹)
 for i in range(2):
  var radius: float=14.0+height*.42+i*4.0
  var alpha: float=(.30 if i==0 else .16)+pulse*.20
  node.draw_arc(base-Vector2(0,height*.45),radius,PI*1.08,PI*1.92,24,Color(gold.r,gold.g,gold.b,alpha),2.2-i*.6,true)
 for i in range(6):
  var a:=i*TAU/6+clock*1.6
  var spark:=base+Vector2.from_angle(a)*(24+height*.36)+Vector2(0,-height*.5)
  node.draw_circle(spark,1.7,Color(1,.94,.72,.55+.35*pulse))
 # 선명한 '둔갑 가능' 표시(사물 위)
 var label:="둔갑 가능"
 var width: float=112.0
 var box:=Rect2(base-Vector2(width*.5,height+34.0+pulse*3.0),Vector2(width,26))
 node.draw_rect(box,Color(.05,.04,.02,.86))
 node.draw_rect(box,Color(gold.r,gold.g,gold.b,.9),false,1.6)
 node.draw_string(TITLE_FONT,box.position+Vector2(0,19),label,HORIZONTAL_ALIGNMENT_CENTER,width,17,Color(1,.92,.68))
 node.draw_colored_polygon(PackedVector2Array([Vector2(base.x-6,box.end.y),Vector2(base.x+6,box.end.y),Vector2(base.x,box.end.y+7)]),Color(gold.r,gold.g,gold.b,.9))
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
  # 둔갑 가능 표시: 사물·동물 주위 금빛 링 + 떠 있는 안내(2.0.27).
  var target:=form_target()
  if not target.is_empty():
   var ready: bool=String(human.get("character",""))!="" and float(human.buff.get("transform",0.0))<=rules.elapsed and String(human.get("form",""))==""
   if ready:draw_form_target(effects,target)
  draw_detection(effects)
  draw_traps(effects)
## 요괴의 감지(발자국·표식·탐지)와 어둠을 바닥에 그린다.
func draw_detection(node: Node2D) -> void:
 var human: Dictionary=rules.players.get("human",{})
 var sense: bool=rules.trail_all_until>rules.elapsed or (human.get("role","")=="daoist" and float(human.buff.get("sense",0.0))>rules.elapsed)
 if sense:
  for p in rules.players.values():
   if p.role!="daoist" or p.eliminated or p.id=="human":continue
   for i in range(p.trail.size()):
    var mark: Dictionary=p.trail[i]
    var age: float=rules.elapsed-float(mark.time)
    var alpha: float=clampf(1.0-age/6.0,0,1)*.55
    var facing: float=float(mark.facing)*PI/4
    node.draw_set_transform(mark.position,0,Vector2(1,.5))
    node.draw_arc(Vector2.ZERO,7,0,TAU,12,Color(.55,.9,1,alpha*.5),1.4,true)
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    node.draw_line(mark.position-Vector2.from_angle(facing)*5,mark.position+Vector2.from_angle(facing)*5,Color(.7,.95,1,alpha*.7),1.6,true)
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
 for mark in rules.pings:
  var t: float=clampf((float(mark.until)-rules.elapsed)/3.0,0,1)
  node.draw_set_transform(mark.pos,0,Vector2(1,.45))
  node.draw_arc(Vector2.ZERO,18+(1.0-t)*50,0,TAU,30,Color(1,.85,.55,.34*t+.14),2.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 덫·어둠 표시.
func draw_traps(node: Node2D) -> void:
 for t in rules.traps:
  var pulse: float=.5+.5*sin(clock*2.8+float(t.pos.x)*.01)
  node.draw_set_transform(t.pos,0,Vector2(1,.45))
  var color:=Color(1,.8,.4,.55) if String(t.kind)=="pressure" else Color(1,.9,.55,.65)
  node.draw_arc(Vector2.ZERO,float(t.radius),0,TAU,28,color,2.0,true)
  node.draw_arc(Vector2.ZERO,float(t.radius)*(.6+pulse*.3),0,TAU,24,Color(color.r,color.g,color.b,.32),1.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 등불끄기·무월야: 화면 전체와 주변을 어둡게 덮는다.
 var dark_alpha:=0.0
 if rules.map_dark_until>rules.elapsed:dark_alpha=maxf(dark_alpha,.42)
 if rules.dark_until>rules.elapsed:
  var t: float=clampf((rules.dark_until-rules.elapsed)/9.0,0,1)
  var radius: float=rules.dark_radius*(1.0+(1.0-t)*.1)
  Art.glow(node,rules.dark_center,radius,Color(.02,.01,.06,.55))
  node.draw_circle(rules.dark_center,radius*.5,Color(.02,.015,.05,.42))
 if dark_alpha>0.01:
  var camera:=get_viewport().get_camera_2d()
  var center: Vector2=camera.get_screen_center_position() if camera!=null else rules.players.human.position
  var view: Vector2=get_viewport().get_visible_rect().size/(camera.zoom if camera!=null else Vector2.ONE)
  Art.glow(node,center,view.length()*.72,Color(.01,.01,.03,dark_alpha))
func hand(_node: Node2D,_at: Vector2) -> void:
 pass
func tag(node: Node2D,at: Vector2,text: String,color: Color) -> void:
 var width: float=54.0+text.length()*11.0
 var rect:=Rect2(at-Vector2(width*.5,15),Vector2(width,24))
 node.draw_rect(Rect2(rect.position+Vector2(0,2),rect.size),Color(.01,.02,.05,.55))
 node.draw_rect(rect,Color(.04,.05,.1,.86))
 node.draw_rect(rect,Color(.85,.7,.42,.55),false,1)
 node.draw_string(FONT,rect.position+Vector2(0,16),text,HORIZONTAL_ALIGNMENT_CENTER,width,12,color)
func door_at(p: Vector2) -> String:return L.door_near(p,64)
