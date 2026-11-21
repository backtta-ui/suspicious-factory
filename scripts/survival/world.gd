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
## 2.0.35 서원 리뉴얼 11종: 항아리·대나무 화분·화로·책 궤짝·병풍 + 고양이·강아지 8방향 유지.
const PROPS={"jar":preload("res://assets/woo/seowon/prop_jar.png"),"bamboo_pot":preload("res://assets/woo/seowon/prop_bamboo_pot.png"),"book_chest":preload("res://assets/woo/seowon/prop_book_chest.png"),"brazier":preload("res://assets/woo/seowon/prop_brazier.png"),"folding_screen":preload("res://assets/woo/seowon/prop_folding_screen.png"),"crate":preload("res://assets/woo/seowon/prop_crate.png"),"stele":preload("res://assets/woo/seowon/prop_stele.png"),"lantern":preload("res://assets/woo/seowon/prop_lantern.png"),"cat":preload("res://assets/woo/seowon/prop_cat.png")}
const LANTERN_ON=preload("res://assets/woo/seowon/gimmicks/gimmick_lantern_on.png")
const LANTERN_OFF=preload("res://assets/woo/seowon/gimmicks/gimmick_lantern_off.png")
const PAVILION_PILLAR=preload("res://assets/woo/seowon/gimmicks/gimmick_pavilion_pillar.png")
const STONE_RAIL=preload("res://assets/woo/seowon/gimmicks/gimmick_stone_bridge.png")
const ENV_CHERRY=preload("res://assets/woo/seowon/env/env_cherry_tree.png")
const ENV_BAMBOO=preload("res://assets/woo/seowon/env/env_bamboo_clump.png")
## 2.0.27 맵을 실제로 걷는 고양이·강아지: 4행(front/left/right/back) x 4열 걷기 시트.
## 둔갑하면 이 시트와 같은 박자를 그대로 복사한다.
const C=preload("res://scripts/survival/characters.gd")
## 2.0.28: 맵 위 고양이·강아지를 사물 크기(22~26px)로 대폭 줄였다. 걷기 시트의
## 원화 키(sheet.height)로 배율을 계산하므로 시트를 바꿔도 크기가 유지된다.
const ANIMAL_HEIGHT={"cat":22.0,"dog":26.0}
const ANIMAL_SHADOW={"cat":5.0,"dog":6.0}
var animal_textures: Dictionary={}
var animal_nodes: Array=[]
var animal_shadows: Array=[]
## 등불끄기(어둑시니)·도깨비장난(도깨비)이 실제로 바꾸는 맵 오브젝트.
var lantern_holders: Array=[]
var prop_holders: Array=[]
var observer:=L.SPAWN
var roofs: Array=[]
var clock:=0.0
var rules: RefCounted
var aim:=Vector2.ZERO
var aim_active:=false
var aim_cancelled:=false
var ground: Node2D
var under: Node2D
## 2.0.30 바닥 경계 연출(돌 턱·연못 테두리·기단)과 캐릭터를 가리는 나무 목록.
var edge: Node2D
var occluders: Array=[]
var occluder_tick:=0.0
var water: Node2D
var effects: Node2D
## 캐릭터 발밑(액터 아래)에서 그리는 바닥 장치 레이어(덫·미끼).
var floor_fx: Node2D
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
 # 막힌 곳을 자연스럽게 보이게 하는 바닥 경계층(돌 턱·물가·기단).
 edge=Node2D.new();edge.name="Edges";edge.z_index=-89;edge.draw.connect(func()->void:Art.draw_edges(edge));add_child(edge)
 build_buildings()
 build_garden()
 water=Node2D.new();water.z_index=-88;water.draw.connect(func()->void:Art.draw_water_glints(water,L.POND,clock));add_child(water)
 # 2.0.28: 덫·보물함 같은 바닥 장치는 캐릭터(액터)보다 아래에 깔아 몸을 가리지 않는다.
 floor_fx=Node2D.new();floor_fx.name="FloorFx";floor_fx.z_index=-58;floor_fx.draw.connect(draw_floor);add_child(floor_fx)
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
 if L.MEDALLION_RADIUS<=0.0:return
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
 # 2.0.35 리뉴얼: 목교 양옆에 석조 난간을 세워 조선 서원다운 무게를 준다.
 var axis_n: Vector2=(L.BRIDGE_B-L.BRIDGE_A).normalized()
 var side_n:=Vector2(-axis_n.y,axis_n.x)
 for side in [-1.0,1.0]:
  for k in range(2):
   var t: float=(float(k)+.5)*.5
   var at: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,t)+side_n*side*(L.BRIDGE_HALF+3.0)
   var rail:=Sprite2D.new();rail.texture=STONE_RAIL;rail.centered=true;rail.z_index=-78
   rail.position=at;rail.rotation=angle
   rail.scale=Vector2((length*.5)/STONE_RAIL.get_width()*1.02,.40)
   rail.modulate=Color(.86,.88,.95,.95);rail.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   add_child(rail)
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
  var sprite:=Sprite2D.new();sprite.texture=ENV_CHERRY
  var s:=255.0/ENV_CHERRY.get_height();sprite.scale=Vector2(s,s);sprite.centered=false;sprite.position=Vector2(-ENV_CHERRY.get_width()*s*.5,-255.0+ENV_CHERRY.get_height()*s*.02)
  sprite.modulate=Color(.94,.90,.96)
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var holder:=Node2D.new();holder.position=p;holder.add_child(sprite);culled.append({"node":holder,"rect":Rect2(p-Vector2(190,360),Vector2(380,400))})
  occluders.append({"node":sprite,"base":p,"half":132.0,"top":248.0,"alpha":1.0,"applied":1.0})
  var glow_node:=Node2D.new();glow_node.z_index=-1;glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-90),135,Color(.85,.45,.7,.12)));holder.add_child(glow_node)
  add_child(holder)
 # 대나무 군락
 for rect in L.BAMBOO:
  var count:=maxi(1,int(rect.size.y/150))
  for i in range(count):
   var base:=Vector2(rect.position.x+rect.size.x*.5,rect.position.y+40+i*(rect.size.y-60)/maxf(1,count))
   shadow(base+Vector2(0,2),Vector2((rect.size.x+40)*.85,44),.7)
   var sprite:=Sprite2D.new();sprite.texture=ENV_BAMBOO
   var s: float=(rect.size.x+40.0)/ENV_BAMBOO.get_width()
   sprite.scale=Vector2(s,s);sprite.centered=false
   sprite.position=Vector2(-(rect.size.x+40)*.5,-ENV_BAMBOO.get_height()*s*.98)
   sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var holder:=Node2D.new();holder.position=base
   holder.add_child(sprite);add_child(holder);culled.append({"node":holder,"rect":Rect2(base-Vector2(130,320),Vector2(260,350))})
   occluders.append({"node":sprite,"base":base,"half":(rect.size.x+40.0)*.56,"top":300.0,"alpha":1.0,"applied":1.0})
 # 석등(장식): 부드러운 발밑 그림자 + 따뜻한 빛무리
 for p in Art.LANTERNS:
  shadow(p+Vector2(0,2),Vector2(72,30),.85)
  var on_sprite:=Sprite2D.new();on_sprite.texture=LANTERN_ON;var s:=78.0/LANTERN_ON.get_height()
  on_sprite.scale=Vector2(s,s);on_sprite.centered=false;on_sprite.position=Vector2(-LANTERN_ON.get_width()*s*.5,-78)
  on_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var off_sprite:=Sprite2D.new();off_sprite.texture=LANTERN_OFF
  var s_off:=78.0/LANTERN_OFF.get_height()
  off_sprite.scale=Vector2(s_off,s_off);off_sprite.centered=false;off_sprite.position=Vector2(-LANTERN_OFF.get_width()*s_off*.5,-78)
  off_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;off_sprite.visible=false
  var holder:=Node2D.new();holder.position=p;holder.add_child(on_sprite);holder.add_child(off_sprite)
  var glow_node:=Node2D.new();glow_node.draw.connect(func()->void:Art.glow(glow_node,Vector2(0,-46),96,Color(1,.68,.32,.26)));holder.add_child(glow_node)
  add_child(holder);culled.append({"node":holder,"rect":Rect2(p-Vector2(70,100),Vector2(140,120))})
  # 2.0.30: 등불끄기에서 '이 석등만' 꺼지도록 위치·불빛·연기를 함께 보관한다.
  var smoke:=Node2D.new();smoke.name="LanternSmoke";smoke.position=p;smoke.z_index=6
  smoke.draw.connect(func()->void:draw_lantern_smoke(smoke,p))
  add_child(smoke)
  lantern_holders.append({"node":holder,"glow":glow_node,"at":p,"smoke":smoke,"level":1.0,"on":on_sprite,"off":off_sprite})
 # 2.0.36 비대칭 마당: 팔각 돌마당을 없앴으므로 기둥도 그리지 않는다.
 for corner in ([] if L.STONE.size.x<=0.0 else [Vector2(L.STONE.position.x-18,L.STONE.position.y-14),Vector2(L.STONE.end.x+18,L.STONE.position.y-14),
  Vector2(L.STONE.position.x-18,L.STONE.end.y+14),Vector2(L.STONE.end.x+18,L.STONE.end.y+14)]):
  shadow(corner+Vector2(0,4),Vector2(74,30),.8)
  var pillar:=Sprite2D.new();pillar.texture=PAVILION_PILLAR
  var ps:=148.0/PAVILION_PILLAR.get_height()
  pillar.scale=Vector2(ps,ps);pillar.centered=false
  pillar.position=Vector2(-PAVILION_PILLAR.get_width()*ps*.5,-148.0)
  pillar.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var pillar_holder:=Node2D.new();pillar_holder.position=corner;pillar_holder.add_child(pillar)
  var pglow:=Node2D.new();pglow.draw.connect(func()->void:Art.glow(pglow,Vector2(0,-74),70,Color(1,.74,.42,.22)));pillar_holder.add_child(pglow)
  add_child(pillar_holder);culled.append({"node":pillar_holder,"rect":Rect2(corner-Vector2(60,170),Vector2(120,190))})
 # 둔갑 사물(군집): 같은 부드러운 그림자를 공유한다.
 for object_index in range(L.OBJECTS.size()):
  var data: Dictionary=L.OBJECTS[object_index]
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
  prop_holders.append({"node":holder,"index":object_index,"base":holder.rotation})
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
 update_occluders(delta)
 update_props()
 fx_tick+=delta
 var busy: bool=aim_active or (rules!=null and (not rules.effects.is_empty() or not rules.walkers.is_empty() or not rules.traps.is_empty() or not rules.marks.is_empty() or rules.dark_until>rules.elapsed or rules.map_dark_until>rules.elapsed)) or not String(L.door_near(observer)).is_empty() or not near.is_empty()
 if busy and fx_tick>=1.0/20.0:fx_tick=0;effects_dirty=true
 if effects_dirty:
  effects_dirty=false;effects.queue_redraw()
  if is_instance_valid(floor_fx):floor_fx.queue_redraw()
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
   var near:=observer.distance_to(entry.center)<92 or (rules!=null and float(rules.doors.get(entry.id,0.0))>clock)
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
  var shade:=Sprite2D.new();shade.texture=SHADOW_TEX;shade.centered=true
  shade.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;shade.modulate=Color(1,1,1,.72)
  under.add_child(shade)
  animal_shadows.append(shade)
 for i in range(animal_nodes.size()):
  var sprite: Sprite2D=animal_nodes[i]
  var shade: Sprite2D=animal_shadows[i] if i<animal_shadows.size() else null
  if i>=walkers.size():
   sprite.visible=false
   if shade!=null:shade.visible=false
   continue
  var entry: Dictionary=walkers[i]
  var kind: String=String(entry.kind)
  var sheet: Dictionary=C.animal_sheet(kind)
  if sheet.is_empty():
   sprite.visible=false
   if shade!=null:shade.visible=false
   continue
  var path: String=String(sheet.get("sheet",""))
  var texture: Texture2D=animal_textures.get(path)
  if texture==null:texture=load(path);animal_textures[path]=texture
  var cell: Array=sheet.get("cell",[300,260])
  var rows: Array=sheet.get("rows",["front","left","right","back"])
  var mapped: Dictionary=C.sheet_row(rows,int(entry.facing))
  var row: int=int(mapped.row)
  var cols: int=int(sheet.get("cols",4))
  var column: int=posmod(int(floor(float(entry.phase)/(PI*.62))),cols) if bool(entry.moving) else 0
  var extent:=Vector2(float(cell[0]),float(cell[1]))
  var height: float=float(ANIMAL_HEIGHT.get(kind,22.0))
  var scale_value: float=height/maxf(1.0,C.sheet_art_height(sheet))
  sprite.texture=texture;sprite.region_enabled=true
  sprite.region_rect=Rect2(Vector2(float(column)*extent.x,float(row)*extent.y),extent)
  sprite.scale=Vector2(scale_value,scale_value)
  var foot: Array=sheet.get("foot",[150.0,232.0])
  sprite.position=(entry.p as Vector2)-Vector2(float(foot[0]),float(foot[1]))*scale_value
  sprite.visible=true
  if shade!=null:
   var shadow_size: float=float(ANIMAL_SHADOW.get(kind,6.0))
   shade.position=(entry.p as Vector2)+Vector2(0,1)
   shade.scale=Vector2(shadow_size*2.4/SHADOW_TEX.get_width(),shadow_size*1.1/SHADOW_TEX.get_height())
   shade.visible=true
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
## 2.0.30 나무·대나무 뒤로 들어간 캐릭터·동물이 가려지지 않게 수관을 옅게 만든다.
## 나무 발치(y)보다 위(뒤)에 있고 수관 폭 안에 있으면 그 나무만 반투명해진다.
func update_occluders(delta: float) -> void:
 if rules==null or occluders.is_empty():return
 occluder_tick+=delta
 if occluder_tick<.05:return
 occluder_tick=0.0
 var actors: Array=[]
 for p in rules.players.values():
  if p.eliminated:continue
  actors.append(p.position)
 for entry in rules.walkers:actors.append(entry.p)
 for o in occluders:
  var base: Vector2=o.base
  var hidden:=false
  for a in actors:
   if absf((a as Vector2).x-base.x)>float(o.half):continue
   if (a as Vector2).y>base.y+12.0:continue
   if (a as Vector2).y<base.y-float(o.top):continue
   hidden=true;break
  var target:=.40 if hidden else 1.0
  var alpha: float=move_toward(float(o.alpha),target,delta*6.0)
  o.alpha=alpha
  if absf(alpha-float(o.applied))>.008:
   o.applied=alpha
   var node: CanvasItem=o.node
   if is_instance_valid(node):node.modulate.a=alpha
## 등불끄기·도깨비장난이 실제로 만든 변화를 그림에 반영한다.
## 2.0.30: 석등은 불빛(노란 글로우)이 실제로 꺼지고, 꺼진 자리에서 연기·불씨가
## 조금씩 올라온다. 범위 밖의 석등은 그대로 켜져 있다.
func lantern_doused(at: Vector2) -> bool:
 if rules==null:return false
 var all_out: float=float(rules.lantern_until.get("all",0.0))
 if all_out<=rules.elapsed:return false
 # 등불끄기는 시전자 주변만 끈다. 범위 밖 석등은 계속 불을 밝힌다.
 if float(rules.dark_radius)>0.0 and at.distance_to(rules.dark_center)>float(rules.dark_radius)+50.0:return false
 return true
func update_props() -> void:
 if rules==null:return
 for entry in lantern_holders:
  var node: Node2D=entry.node
  if not is_instance_valid(node):continue
  var doused: bool=lantern_doused(entry.at)
  # 0.3초 정도에 걸쳐 불빛이 꺼지는 낙차를 준다(끊김 없이).
  var target:=0.0 if doused else 1.0
  var level: float=move_toward(float(entry.get("level",1.0)),target,.09)
  entry.level=level
  node.modulate=Color(.44,.42,.54,1.0).lerp(Color.WHITE,level)
  var glow: Node2D=entry.glow
  if is_instance_valid(glow):
   glow.visible=level>.02
   glow.modulate.a=clampf(level,0.0,1.0)
  var on_node: Sprite2D=entry.get("on")
  var off_node: Sprite2D=entry.get("off")
  if is_instance_valid(on_node):on_node.visible=level>.5
  if is_instance_valid(off_node):off_node.visible=level<=.5
  var smoke: Node2D=entry.smoke
  if is_instance_valid(smoke):
   smoke.visible=level<.98
   smoke.queue_redraw()
 for entry in prop_holders:
  var node: Node2D=entry.node
  if not is_instance_valid(node):continue
  var flipped: bool=float(rules.prop_flips.get(int(entry.index),0.0))>rules.elapsed
  node.rotation=(-1.08 if int(entry.index)%2==0 else 1.02) if flipped else float(entry.base)
## 꺼진 석등에서 피어오르는 연기 사슬과 작은 불씨.
func draw_lantern_smoke(node: Node2D,at: Vector2) -> void:
 var t:=clock
 # 연기: 위로 흐르는 회색 덩어리(석등 등불 높이 -46).
 for i in range(7):
  var life: float=fmod(t*.34+float(i)*.37,1.0)
  var rise: float=8.0+life*54.0
  var sway: float=sin(t*1.1+float(i)*1.7)*6.0*life
  var alpha: float=(1.0-life)*.16
  var size: float=3.0+life*8.0
  node.draw_circle(Vector2(sway,-46.0-rise),size,Color(.14,.13,.18,alpha))
  node.draw_circle(Vector2(sway+2.5,-46.0-rise-3.0),size*.7,Color(.22,.20,.26,alpha*.8))
 # 불씨: 잠깐 반짝이며 사라지는 주홍 점.
 for i in range(5):
  var life2: float=fmod(t*.9+float(i)*.53,1.0)
  var spot:=Vector2(sin(t*2.3+float(i)*2.1)*3.0,-44.0-life2*26.0)
  node.draw_circle(spot,1.3*(1.0-life2)+.5,Color(1,.52,.22,(1.0-life2)*.55))
 # 꺼진 등불 잔해: 어두운 불투명 웅덩이와 식어 가는 잔불색 테두리.
 node.draw_circle(Vector2(0,-46),4.6,Color(.05,.04,.06,.75))
 node.draw_arc(Vector2(0,-46),5.6,0,TAU,16,Color(.45,.16,.10,.25),1.0,true)
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
 # 화면을 가리는 글자 상자는 쓰지 않는다. 둔갑은 상황 버튼(둔갑)이 알려 준다.
func draw_effects() -> void:
 draw_shield_bubbles(effects)
 if aim_active:
  var origin: Vector2=rules.players.human.position
  effects.draw_line(origin,origin+aim*120,Color("e77b95") if aim_cancelled else Color("9fcaff"),3,true)
  effects.draw_arc(origin+aim*120,14,0,TAU,24,Color("e77b95") if aim_cancelled else Color("9fcaff"),2,true)
 if rules!=null:
  draw_safe_zone(effects)
  var human: Dictionary=rules.players.get("human",{})
  if not human.is_empty() and rules.hidden(human) and float(human.buff.get("painting",0.0))>rules.elapsed:
   # 화중은신: 본인 화면에서만 족자와 먹물 잔상이 감돈다(남에게는 그려지지 않는다).
   var at: Vector2=human.position
   var pulse: float=.5+.5*sin(clock*3.0)
   effects.draw_set_transform(at,0,Vector2(1,.45))
   effects.draw_arc(Vector2.ZERO,16+pulse*4,0,TAU,26,Color(.16,.1,.24,.32),2.0,true)
   effects.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   var box:=Rect2(at-Vector2(13,58+pulse*2.0),Vector2(26,54))
   effects.draw_rect(box,Color(.9,.84,.7,.16))
   effects.draw_rect(box,Color(.6,.45,.25,.35),false,1.2)
   for i in range(3):
    effects.draw_circle(at+Vector2(sin(clock*2.2+i*2.1)*10,-18-i*9),2.0,Color(.1,.08,.16,.35))
  if not human.is_empty() and human.buff.get("sense",0)>rules.elapsed:
   var marks: Array=[]
   for p in rules.players.values():
    if p.id=="human":continue
    if rules.hidden(p):continue
    for i in range(p.trail.size()):
     var mark: Dictionary=p.trail[i]
     if mark.position.distance_to(human.position)<float(rules.SENSE_RADIUS):marks.append([mark.position.x,mark.position.y,mark.facing*PI/4,i%2,rules.elapsed-mark.time])
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
   if rules.hidden(p):continue
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
## 바닥 장치(압력기관·가짜보물)는 액터보다 아래 층에서 그린다.
func draw_floor() -> void:
 if rules==null:return
 draw_gimmick_fx(floor_fx)
 # 도깨비 장난 지대: 바닥에서 춤추는 도깨비불 테두리와 갈라진 흙.
 # 등불끄기·무월야의 밤안개 연막: 캐릭터보다 아래층에 깔아 실루엣이 살아 있게 한다.
 if rules.dark_until>rules.elapsed:draw_douse_shade(floor_fx)
 if rules.map_dark_until>rules.elapsed:draw_moonless_shade(floor_fx)
 for z in rules.mischief_zones:
  if float(z.until)<=rules.elapsed:continue
  var left: float=clampf((float(z.until)-rules.elapsed)/6.0,0.0,1.0)
  var reach: float=float(z.radius)
  var center: Vector2=z.pos
  var pulse: float=.5+.5*sin(clock*3.4)
  floor_fx.draw_set_transform(center,0,Vector2(1.0,.44))
  floor_fx.draw_circle(Vector2.ZERO,reach,Color(.06,.10,.08,.16*left))
  floor_fx.draw_arc(Vector2.ZERO,reach,0,TAU,52,Color(.42,.98,.74,.30*left),3.0,true)
  floor_fx.draw_arc(Vector2.ZERO,reach*.72,0,TAU,40,Color(.30,.80,.60,.16*left),2.0,true)
  floor_fx.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  for i in range(14):
   var a:=float(i)*TAU/14.0+clock*.9
   var spot:=center+Vector2.from_angle(a)*reach*(.94+.04*sin(clock*3.0+float(i)))
   var size:=4.0+2.2*absf(sin(clock*4.0+float(i)*1.7))
   floor_fx.draw_circle(spot,size,Color(.40,.98,.74,.26*left))
   floor_fx.draw_circle(spot,size*.45,Color(.92,1,.98,.36*left))
  for i in range(9):
   var a2:=float(i)*TAU/9.0+0.4
   var crack:=center+Vector2.from_angle(a2)*reach*.8
   for k in range(3):
    var from:=center+Vector2.from_angle(a2)*(reach*.2*float(k))
    var to:=center+Vector2.from_angle(a2+0.12*sin(float(k)+float(i)))*(reach*.2*float(k+1))
    floor_fx.draw_line(from,to,Color(.16,.05,.18,.20*left),1.6,true)
 for t in rules.traps:
  var pulse: float=.5+.5*sin(clock*2.8+float(t.pos.x)*.01)
  var reach: float=float(t.radius)
  if String(t.kind)=="pressure":
   pressure_trap(floor_fx,t.pos,reach,pulse)
  else:
   treasure_trap(floor_fx,t.pos,reach,pulse)
## 어둠(등불끄기·무월야)은 화면 위 레이어에서 덮되, 단색 원이 아니라 여러 겹의
## 그라데이션 + 흘러가는 안개 + 꺼진 불씨로 겹쳐 그린다(2.0.30).
func draw_traps(node: Node2D) -> void:
 # 2.0.30: 밤안개·연막은 바닥층(draw_floor)에서 그린다. 캐릭터를 덮어 가리지 않고,
 # 화면 어둡기는 시야 연출(vision_overlay)이 담당한다.
 pass
## 등불끄기: 단색 원이 아니라 먹빛 연막이 소용돌이치며 번지고, 그림자 촉수가 뻗으며,
## 보랏빛 눈빛과 꺼진 등불의 불씨가 흩날린다(어둑시니 고유 연출).
func draw_douse_shade(node: Node2D) -> void:
 var fade: float=clampf((rules.dark_until-rules.elapsed)/9.0,0.0,1.0)
 var strength: float=.35+.65*clampf(fade*1.6,0.0,1.0)
 var reach: float=rules.dark_radius*(1.0+(1.0-fade)*.06)
 var center: Vector2=rules.dark_center
 var spin:=clock*1.2
 # 1) 바닥을 까는 옅은 밤 그림자(부드러운 다층 그라데이션)
 for i in range(14):
  var k: float=1.0-float(i)/14.0
  node.draw_circle(center,reach*k,Color(.014,.011,.038,.014*strength))
 # 2) 소용돌이치는 먹빛 연막 덩어리(여러 겹, 서로 다른 속도)
 FX.smoke(node,center,reach*.92,.18*strength,Color(.05,.035,.10,.55),10,spin)
 FX.smoke(node,center+Vector2(reach*.18,-reach*.10),reach*.62,.22*strength,Color(.11,.07,.19,.42),8,-spin*.7)
 FX.smoke(node,center+Vector2(-reach*.22,reach*.06),reach*.48,.26*strength,Color(.03,.02,.07,.55),6,spin*1.6)
 # 3) 가장자리에서 안으로 뻗는 그림자 촉수
 for i in range(14):
  var a:=float(i)*TAU/14.0+sin(clock*.4+float(i))*0.16
  var base: Vector2=center+Vector2.from_angle(a)*reach*.86
  var mid: Vector2=center+Vector2.from_angle(a+0.5)*(reach*.58)
  var tip: Vector2=center+Vector2.from_angle(a+0.9)*(reach*.34)
  node.draw_line(base,mid,Color(.05,.035,.10,.22*strength),7.0,true)
  node.draw_line(mid,tip,Color(.09,.06,.15,.14*strength),3.4,true)
 # 4) 연무 속 보랏빛 눈빛
 for i in range(5):
  var phase:=clock*.7+float(i)*1.9
  var spot: Vector2=center+Vector2(sin(phase)*reach*.52,cos(phase*.8)*reach*.34)
  var glow:=.45+.55*sin(clock*2.6+float(i)*2.1)
  node.draw_circle(spot,5.0,Color(.42,.24,.68,.16*glow*strength))
  node.draw_circle(spot,1.6,Color(.88,.74,1,.55*glow*strength))
 # 5) 꺼진 등불에서 떠오르는 불씨
 for i in range(10):
  var lift: float=fmod(clock*.5+float(i)*.31,1.0)
  var spot2: Vector2=center+Vector2(sin(clock*1.3+float(i)*2.3)*(reach*.30),cos(clock*.9+float(i))*reach*.16)-Vector2(0,lift*140.0)
  node.draw_circle(spot2,1.5*(1.0-lift)+.4,Color(1,.55,.24,(1.0-lift)*.30*strength))
## 무월야: 밤하늘이 내려앉되 먹구름이 흐르고, 달이 잠식되는 연출.
func draw_moonless_shade(node: Node2D) -> void:
 var fade: float=clampf((rules.map_dark_until-rules.elapsed)/8.0,0.0,1.0)
 var alpha: float=.30+.18*clampf(fade*1.5,0.0,1.0)
 var camera:=get_viewport().get_camera_2d()
 var center: Vector2=camera.get_screen_center_position() if camera!=null else rules.players.human.position
 var view: Vector2=get_viewport().get_visible_rect().size/(camera.zoom if camera!=null else Vector2.ONE)
 var far: float=view.length()*.62
 for i in range(12):
  var k: float=1.0-float(i)/12.0
  node.draw_circle(center,far*k,Color(.010,.010,.028,.075*alpha))
 FX.smoke(node,center,far*.55,.30*alpha,Color(.04,.04,.09,.40),9,clock*.7)
 FX.smoke(node,center+Vector2(far*.3,far*.2),far*.34,.34*alpha,Color(.06,.05,.12,.34),7,-clock*.5)
 # 잠식되는 달
 var moon:=center+Vector2(far*.42,-far*.36)
 node.draw_circle(moon,34.0,Color(.82,.86,.96,.16*alpha))
 node.draw_circle(moon+Vector2(10.0,0),33.0,Color(.02,.02,.05,.30*alpha))
## 압력기관: 바닥 그림자 위에 청동 톱니 테두리·팔각 압력판·나사 핀·옥빛 맥동.
func pressure_trap(node: Node2D,at: Vector2,radius: float,pulse: float) -> void:
 var bronze:=Color(.78,.60,.32)
 var bronze_dark:=Color(.36,.27,.14)
 var jade:=Color(.62,.94,.78)
 # 1) 바닥 그림자
 node.draw_set_transform(at+Vector2(0,3),0,Vector2(1,.45))
 node.draw_circle(Vector2.ZERO,radius*1.06,Color(.01,.02,.04,.42))
 node.draw_circle(Vector2.ZERO,radius*.86,Color(.02,.03,.06,.35))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_set_transform(at,0,Vector2(1,.45))
 # 2) 바깥 청동 테
 node.draw_circle(Vector2.ZERO,radius,Color(.10,.09,.08,.92))
 node.draw_arc(Vector2.ZERO,radius,0,TAU,44,bronze,3.4,true)
 node.draw_arc(Vector2.ZERO,radius-3.0,0,TAU,44,bronze_dark,1.6,true)
 # 3) 돌아가는 톱니 12개
 for i in range(12):
  var a:=i*TAU/12+clock*.7
  var inner:=Vector2.from_angle(a)*(radius-1.0)
  var outer:=Vector2.from_angle(a)*(radius+5.0)
  node.draw_line(inner,outer,bronze,3.0,true)
  node.draw_circle(outer,1.5,Color(1,.86,.52,.85))
 # 4) 안쪽 청동 고리와 팔각 압력판
 node.draw_circle(Vector2.ZERO,radius*.62,Color(.09,.10,.09,.9))
 node.draw_arc(Vector2.ZERO,radius*.62,0,TAU,36,bronze_dark,2.0,true)
 var plate: Array=PackedVector2Array()
 for i in range(8):
  plate.append(Vector2.from_angle(i*TAU/8+PI/8)*radius*.44)
 node.draw_colored_polygon(plate,Color(.16,.18,.18,.95))
 for i in range(8):
  var a0:=Vector2.from_angle(i*TAU/8+PI/8)*radius*.44
  var a1:=Vector2.from_angle((i+1)*TAU/8+PI/8)*radius*.44
  node.draw_line(a0,a1,bronze,.0+2.2,true)
 # 5) 중심 옥빛 맥동 + 나사 핀
 node.draw_circle(Vector2.ZERO,radius*.17,Color(.04,.06,.06,.95))
 node.draw_circle(Vector2.ZERO,radius*.13+pulse*1.6,Color(jade.r,jade.g,jade.b,.55+.35*pulse))
 node.draw_arc(Vector2.ZERO,radius*.3+pulse*3.0,0,TAU,26,Color(jade.r,jade.g,jade.b,.18+.16*(1.0-pulse)),1.6,true)
 for i in range(4):
  var a:=i*TAU/4+PI/4
  var pin:=Vector2.from_angle(a)*radius*.5
  node.draw_circle(pin,2.2,bronze)
  node.draw_circle(pin,.9,Color(.12,.10,.07))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 6) 은은한 황금 기운
 Art.glow(node,at,radius*1.5,Color(1,.82,.45,.10+.06*pulse))
## 가짜보물: 금빛 보물함·자물쇠·반짝이는 별빛 입자.
func treasure_trap(node: Node2D,at: Vector2,radius: float,pulse: float) -> void:
 var gold:=Color(.96,.78,.36)
 var wood:=Color(.30,.21,.11)
 # 바닥 그림자와 금빛 웅덩이
 node.draw_set_transform(at+Vector2(0,2),0,Vector2(1,.45))
 node.draw_circle(Vector2.ZERO,radius*.95,Color(.01,.02,.04,.40))
 node.draw_circle(Vector2.ZERO,radius*.7,Color(gold.r,gold.g,gold.b,.10+.05*pulse))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var box:=Rect2(at-Vector2(radius*.78,radius*.62),Vector2(radius*1.56,radius*.92))
 node.draw_rect(box,wood)
 node.draw_rect(Rect2(box.position,Vector2(box.size.x,box.size.y*.34)),Color(.38,.27,.13))
 node.draw_rect(box,gold,false,2.2)
 node.draw_line(Vector2(box.position.x,box.position.y+box.size.y*.34),Vector2(box.end.x,box.position.y+box.size.y*.34),gold,1.6,true)
 # 금빛 테두리 장식과 자물쇠
 for i in range(3):
  var x:=box.position.x+box.size.x*(.22+.28*float(i))
  node.draw_line(Vector2(x,box.position.y+2),Vector2(x,box.end.y-2),Color(gold.r,gold.g,gold.b,.55),1.4,true)
 var lock:=Rect2(at-Vector2(4,4),Vector2(8,9))
 node.draw_rect(lock,gold)
 node.draw_rect(lock,Color(.35,.24,.08),false,1.0)
 node.draw_arc(Vector2(at.x,lock.position.y),3.4,PI,TAU,10,gold,1.4,true)
 node.draw_circle(Vector2(at.x,lock.position.y+4),1.4,Color(.25,.16,.05))
 # 반짝이는 별빛
 for i in range(7):
  var a:=i*TAU/7+clock*1.3
  var r: float=radius*(.75+.35*(float((i*37)%11)/11.0))+pulse*3.0
  var star:=at+Vector2.from_angle(a)*r+Vector2(0,-radius*.55)
  var size:=1.4+1.3*pulse
  node.draw_line(star-Vector2(size,0),star+Vector2(size,0),Color(1,.95,.72,.85),1.0,true)
  node.draw_line(star-Vector2(0,size),star+Vector2(0,size),Color(1,.95,.72,.85),1.0,true)
  node.draw_circle(star,.8,Color(1,1,.94,.95))
 Art.glow(node,at+Vector2(0,-6),radius*1.6,Color(1,.86,.48,.14+.08*pulse))
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

## 2.0.34 안전구역(월식결계): 금빛·보랏빛 발광 링 + 흐르는 부적, 원 밖 보랏빛 안개.
## 시작 원은 맵 네 모서리를 포함하는 최소 반경이라 첫 단계부터 경계가 화면에 보인다.
func draw_safe_zone(node: Node2D) -> void:
 var zone: Dictionary=rules.circle()
 var center: Vector2=zone.center
 var radius: float=float(zone.radius)
 var pulse: float=.5+.5*sin(clock*2.4)
 # 원 밖: 보랏빛 밤안개(링 밴드로만 칠해 원 안은 밝게 둔다)
 for i in range(14):
  node.draw_arc(center,radius+float(i)*64.0+32.0,0,TAU,112,Color(.14,.05,.26,.032),64.0,false)
 # 흐르는 부적: 링 위를 따라 도는 금빛 조각
 for i in range(30):
  var a: float=float(i)*TAU/30.0+clock*.35
  var at:=center+Vector2.from_angle(a)*radius
  node.draw_set_transform(at,a,Vector2(1,.62))
  node.draw_rect(Rect2(-4,-7,8,14),Color(1,.86,.52,.42+.30*pulse))
  node.draw_rect(Rect2(-4,-7,8,14),Color(.55,.30,.10,.45),false,1.0)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 발광 이중 링: 금빛 바깥 + 보랏빛 안쪽
 node.draw_arc(center,radius,0,TAU,128,Color(1,.82,.45,.85),6.0,true)
 node.draw_arc(center,radius-8.0,0,TAU,128,Color(.62,.42,1,.50+.28*pulse),3.0,true)
 node.draw_arc(center,radius+8.0,0,TAU,128,Color(1,.92,.66,.28+.16*pulse),2.0,true)
 # 팔각 문양 회전 링(원 안쪽에 옅게)
 for i in range(8):
  var a0: float=float(i)*TAU/8.0+clock*.12
  var p0: Vector2=center+Vector2.from_angle(a0)*radius*.985
  var p1: Vector2=center+Vector2.from_angle(a0+TAU/8.0)*radius*.985
  node.draw_line(p0,p1,Color(.85,.70,1,.16),1.4,true)
 # 다음 단계 원은 점선으로 미리 보여 준다.
 var next_radius: float=float(zone.get("next_radius",radius))
 var next_center: Vector2=zone.get("next_center",center)
 for i in range(72):
  if i%3!=0:continue
  var a1: float=float(i)*TAU/72.0
  node.draw_arc(next_center,next_radius,a1,a1+TAU/72.0*.55,5,Color(.68,.56,1,.22),2.0,true)

## 2.0.36 보호막 시인성: shield·생명등불·저승꽃이 켜진 캐릭터는 몸을 감싸는 방어막이 보인다.
func draw_shield_bubbles(node: Node2D) -> void:
 if rules==null:return
 for p in rules.players.values():
  if p.eliminated or p.captured:continue
  var shield: bool=float(p.buff.get("shield",0.0))>rules.elapsed
  var flower: bool=float(p.buff.get("deathflower",0.0))>rules.elapsed
  var lamp: bool=float(p.buff.get("lifelamp",0.0))>rules.elapsed
  if not shield and not flower and not lamp:continue
  var tint: Color=Color("d9c0ff") if flower else (Color("ffd08a") if lamp else Color("ffb9cf"))
  var at: Vector2=(p.position as Vector2)-Vector2(0,L.elevation(p.position))
  FX.shield_bubble(node,at,clock,tint,1.0 if shield else .6)

## 2.0.36 서원 기믹 3종(석등 암전·연못 물안개·장독대 방울)의 실제 상태를 바닥에 그린다.
## 위치에 금빛 표식을 두어 '누를 수 있는 것'이 눈에 보이게 한다.
func draw_gimmick_fx(node: Node2D) -> void:
 if rules==null or rules.gimmicks==null:return
 var g: RefCounted=rules.gimmicks
 var now: float=rules.elapsed
 for item in L.GIMMICKS:
  var at: Vector2=item.pos
  var pulse: float=.5+.5*sin(clock*3.0+at.x*.01)
  node.draw_set_transform(at,0,Vector2(1,.42))
  node.draw_arc(Vector2.ZERO,16.0+pulse*3.0,0,TAU,24,Color(1,.86,.52,.42+.22*pulse),1.6,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  if observer.distance_to(at)<260.0:
   node.draw_string(FONT,at+Vector2(-60,-44),String(item.get("label","기믹")),HORIZONTAL_ALIGNMENT_CENTER,120,12,Color(.98,.90,.70,.9))
 for zone_id in g.lit_zones().keys():
  var rect: Rect2=L.zone_rect(String(zone_id))
  if rect.size.x<=0.0:continue
  node.draw_rect(rect,Color(.02,.02,.05,.40))
  node.draw_rect(rect,Color(.30,.46,.80,.22),false,3.0)
  node.draw_string(FONT,rect.position+Vector2(24,rect.size.y-18),"암전 · LIGHTS OUT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.62,.76,1,.60))
 if g.mist_active():
  var center: Vector2=g.mist_pos
  for i in range(6):
   var radius: float=g.mist_radius*(.30+float(i)*.14)
   node.draw_circle(center,radius,Color(.62,.74,.86,.035+.02*float(6-i)))
  FX.smoke(node,center,g.mist_radius*.9,.35,Color(.70,.80,.92,.20),7,clock*.4)
  node.draw_string(FONT,center+Vector2(-90,-g.mist_radius*.5),"물안개",HORIZONTAL_ALIGNMENT_CENTER,180,15,Color(.82,.92,1,.8))
 if g.noise_until>now:
  var left: float=clampf((g.noise_until-now)/3.0,0.0,1.0)
  node.draw_set_transform(g.noise_pos,0,Vector2(1,.42))
  for i in range(3):
   node.draw_arc(Vector2.ZERO,(1.0-left)*160.0+float(i)*46.0,0,TAU,40,Color(1,.85,.4,.30*left),3.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
