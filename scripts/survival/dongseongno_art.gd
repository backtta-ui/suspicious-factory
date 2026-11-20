extends RefCounted
## 대구 동성로 정적 배경(2.0.35): 네온 번화가·불규칙 골목.
## 좌표는 dongseongno_layout.gd를 그대로 쓴다.
## 어두운 아스팔트 + 보랏빛/시안 네온 + 붉은 벽돌 건물. 실제 상호 텍스트는 쓰지 않는다.
const L=preload("res://scripts/survival/dongseongno_layout.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const ASPHALT=Color("3f4049")
const PLAZA=Color("5c5566")
const WALL_FILL=Color("2a2434")
const WALL_TOP=Color("453a56")
const BRICK=Color("6d3d3a")
const NEON_PINK=Color("ff5fa8")
const NEON_CYAN=Color("5fe6ff")
const NEON_PURPLE=Color("a97bff")
const WARM=Color("ffb85c")
const TEX={
 "asphalt":"res://assets/woo/dongseongno/tiles/tile_asphalt.png",
 "plaza":"res://assets/woo/dongseongno/tiles/tile_plaza.png",
 "neon":"res://assets/woo/dongseongno/tiles/tile_neon_floor.png",
 "brick":"res://assets/woo/dongseongno/tiles/wall_brick.png"}
static var _tex: Dictionary={}
static func tex(key: String) -> Texture2D:
 if _tex.has(key):return _tex[key]
 var path: String=String(TEX.get(key,""))
 var texture: Texture2D=load(path) if path!="" and ResourceLoader.exists(path) else null
 _tex[key]=texture
 return texture
static func fill_texture(node: Node2D,key: String,rect: Rect2,tint: Color) -> void:
 var texture:=tex(key)
 if texture!=null:node.draw_texture_rect(texture,rect,true,tint)
 else:node.draw_rect(rect,tint)
## 바닥: 아스팔트 → 큰길(보도블록) → 아케이드 네온 바닥 → 구역 색조·이름.
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-300,-300),L.SIZE+Vector2(600,600)),Color("04050a"))
 fill_texture(node,"asphalt",Rect2(150,140,3090,2320),Color(.72,.72,.78,.98))
 node.draw_rect(Rect2(150,140,3090,2320),Color(ASPHALT.r,ASPHALT.g,ASPHALT.b,.35))
 # 큰길: 넓은 보도블록 + 차선
 for path in L.PATHS:
  var w: float=float(path.w)
  var pts: Array=path.p
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var rect:=Rect2(Vector2(minf(a.x,b.x)-w*.5,minf(a.y,b.y)-w*.5),Vector2(absf(b.x-a.x)+w,absf(b.y-a.y)+w))
   fill_texture(node,"plaza",rect,Color(.94,.94,1,.9))
   node.draw_rect(rect,Color(.55,.48,.62,.22),false,2.0)
   lane_marks(node,rect,a,b)
 # 구역 바닥: 아케이드 계열은 네온 인레이 타일
 for zone in L.ZONES:
  var rect2: Rect2=zone.rect
  var accent: Color=zone.accent
  var arcade:=String(zone.id) in ["arcade","fourcut","arcadehall"]
  if arcade:fill_texture(node,"neon",rect2,Color(1,1,1,.42))
  var center:=rect2.get_center()
  var radius:=maxf(rect2.size.x,rect2.size.y)*.60
  for k in range(5):
   var t:=float(k)/5.0
   node.draw_circle(center,radius*(1.0-t),Color(accent.r,accent.g,accent.b,.045*(1.0-t)),true,-1.0,true)
  node.draw_rect(rect2.grow(-6),Color(accent.r,accent.g,accent.b,.20),false,2.4)
  zone_label(node,rect2,String(zone.name),accent)
 # 크로스워크(주요 교차점) + 맨홀
 for spot in [Vector2(1090,760),Vector2(2140,760),Vector2(1090,1450),Vector2(2140,1450),Vector2(1600,760)]:
  for k in range(6):
   node.draw_rect(Rect2(spot+Vector2(-60+float(k)*21,-26),Vector2(12,52)),Color(1,.92,.72,.30))
 for spot2 in [Vector2(1420,1440),Vector2(2060,760),Vector2(1090,1000),Vector2(2600,1450),Vector2(480,1600)]:
  node.draw_set_transform(spot2,0,Vector2(1,.55))
  node.draw_circle(Vector2.ZERO,17,Color(.20,.21,.26,.95))
  node.draw_circle(Vector2.ZERO,17,Color(.42,.44,.52,.7),false,2.0)
  for k in range(3):
   node.draw_line(Vector2(-11,-6+k*6),Vector2(11,-6+k*6),Color(.14,.15,.19,.9),2.0)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
static func lane_marks(node: Node2D,rect: Rect2,from: Vector2,to: Vector2) -> void:
 var along: Vector2=(to-from).normalized()
 var length: float=from.distance_to(to)
 if length<1.0:return
 var steps:=maxi(1,int(length/60.0))
 for k in range(steps):
  if k%2==1:continue
  var p: Vector2=from+along*(float(k)/steps*length)
  var side:=Vector2(-along.y,along.x)
  node.draw_line(p-side*6,p+side*6,Color(1,.86,.5,.26),2.4)
static func zone_label(node: Node2D,rect: Rect2,text: String,accent: Color) -> void:
 var at:=rect.position+Vector2(26,50)
 var width: float=22.0+text.length()*26.0
 node.draw_rect(Rect2(at-Vector2(14,32),Vector2(width,50)),Color(.02,.02,.06,.52))
 node.draw_rect(Rect2(at-Vector2(14,32),Vector2(width,50)),Color(accent.r,accent.g,accent.b,.55),false,2.0)
 node.draw_rect(Rect2(at-Vector2(14,32),Vector2(6,50)),accent)
 node.draw_string(TITLE_FONT,at-Vector2(2,30),text,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color(0,0,0,.5))
 node.draw_string(TITLE_FONT,at-Vector2(4,34),text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color(1,1,1,.95))
## 건물: 붉은 벽돌·남색 상가 + 네온 간판 + 옥상 설비 + 1층 쇼윈도.
static func draw_walls(node: Node2D) -> void:
 var sign_words=["노래","포차","분식","네컷","오락","치킨","커피","화장","문구","의류","떡볶이","아케이드"]
 for index in range(L.BUILDINGS_RECTS.size()):
  var rect: Rect2=L.BUILDINGS_RECTS[index]
  node.draw_rect(Rect2(rect.position+Vector2(9,13),rect.size),Color(0,0,0,.5))
 var neon_colors=[NEON_PINK,NEON_CYAN,NEON_PURPLE,WARM]
 for index2 in range(L.BUILDINGS_RECTS.size()):
  var rect2: Rect2=L.BUILDINGS_RECTS[index2]
  var use_brick: bool=index2%3!=1
  if use_brick:fill_texture(node,"brick",rect2,Color(1,.98,1,.95))
  else:node.draw_rect(rect2,Color("3a3350"))
  node.draw_rect(Rect2(rect2.position,Vector2(rect2.size.x,13)),WALL_TOP)
  node.draw_rect(Rect2(rect2.position+Vector2(0,13),Vector2(rect2.size.x,5)),Color(.03,.02,.05,.9))
  node.draw_rect(rect2,Color(.04,.03,.07,.8),false,2.5)
  # 1층 쇼윈도(따뜻한 불빛) + 출입문
  var wy: float=rect2.end.y-44.0
  node.draw_rect(Rect2(Vector2(rect2.position.x+10,wy),Vector2(rect2.size.x-20,30)),Color(.04,.05,.09,.94))
  var wx: float=rect2.position.x+16.0
  var wi: int=0
  while wx<rect2.end.x-34.0:
   var lit: Color=WARM if wi%3!=2 else NEON_CYAN
   node.draw_rect(Rect2(Vector2(wx,wy+3),Vector2(24,24)),Color(lit.r,lit.g,lit.b,.80))
   node.draw_rect(Rect2(Vector2(wx,wy+3),Vector2(24,24)),Color(1,1,1,.18),false,1.0)
   if wi%3==1:
    node.draw_rect(Rect2(Vector2(wx+6,wy+15),Vector2(12,12)),Color(.03,.03,.05,.9))
   wx+=36.0
   wi+=1
  # 네온 간판(건물 위쪽 띠 + 세로 간판)
  var neon_c: Color=neon_colors[index2%neon_colors.size()]
  var word: String=sign_words[index2%sign_words.size()]
  var board_w: float=minf(rect2.size.x-30.0,132.0)
  var board:=Rect2(Vector2(rect2.position.x+16,rect2.end.y-86),Vector2(board_w,22))
  node.draw_rect(board,Color(0,0,0,.62))
  node.draw_rect(board,Color(neon_c.r,neon_c.g,neon_c.b,.9),false,2.0)
  node.draw_string(FONT,board.position+Vector2(6,17),word,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1,.96,1,.95))
  if rect2.size.x>250.0:
   var vsign:=Rect2(Vector2(rect2.end.x-26,rect2.position.y+34),Vector2(18,72))
   node.draw_rect(vsign,Color(0,0,0,.6))
   node.draw_rect(vsign,Color(neon_c.r,neon_c.g,neon_c.b,.75),false,1.6)
   for k in range(3):
    node.draw_rect(Rect2(vsign.position+Vector2(4,8+float(k)*20),Vector2(10,10)),Color(neon_c.r,neon_c.g,neon_c.b,.75))
  # 옥상 설비
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.66,rect2.size.y*.30),Vector2(32,22)),Color(.09,.08,.13,.95))
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.66,rect2.size.y*.30),Vector2(32,4)),Color(.26,.24,.32,.95))
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.30,rect2.size.y*.24),Vector2(22,22)),Color(.08,.07,.11,.9))
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.30,rect2.size.y*.24),Vector2(22,3)),Color(.22,.20,.28,.9))
 # 골목 위 전선
 for wire in [[Vector2(190,760),Vector2(1090,760)],[Vector2(900,1450),Vector2(1700,1450)],[Vector2(1400,2050),Vector2(2100,2050)],[Vector2(2160,760),Vector2(3100,760)]]:
  node.draw_line(wire[0],wire[1],Color(.05,.05,.08,.6),2.0)
  for k in range(7):
   var t:=float(k+1)/8.0
   node.draw_circle(wire[0].lerp(wire[1],t)+Vector2(0,sin(t*PI)*10.0),1.7,Color(.09,.09,.13,.9))
## 정적 소품: 가로등·전봇대·게시판·화분·입간판·쓰레기통·볼라드.
static func draw_decor(node: Node2D) -> void:
 for spot in [Vector2(470,740),Vector2(1100,740),Vector2(1560,740),Vector2(2080,740),Vector2(2560,740),Vector2(3100,740),
  Vector2(470,1430),Vector2(1100,1430),Vector2(1600,1430),Vector2(2100,1430),Vector2(2600,1430),Vector2(3150,1430),
  Vector2(470,2010),Vector2(1100,2010),Vector2(1600,2010),Vector2(2100,2010),Vector2(2600,2010),Vector2(3100,2010)]:
  node.draw_circle(spot+Vector2(0,6),8,Color(0,0,0,.34))
  node.draw_line(spot,spot+Vector2(0,-54),Color(.09,.09,.13,.95),4.0)
  node.draw_circle(spot+Vector2(0,-58),6.5,Color(1,.88,.60,.95))
  node.draw_circle(spot+Vector2(0,-58),14,Color(1,.78,.42,.16))
 # 전봇대
 for pole in [Vector2(1080,760),Vector2(2140,1450),Vector2(1040,2050),Vector2(2140,760)]:
  node.draw_rect(Rect2(pole-Vector2(5,0),Vector2(10,66)),Color(.15,.14,.18,.95))
  node.draw_line(pole-Vector2(28,58),pole+Vector2(28,58),Color(.15,.14,.18,.95),4.0)
  node.draw_line(pole-Vector2(24,62),pole+Vector2(24,62),Color(.20,.18,.24,.8),2.0)
 # 게시판·현수막
 for board in [Vector2(1750,1720),Vector2(2400,1150),Vector2(600,1180)]:
  node.draw_rect(Rect2(board-Vector2(56,30),Vector2(112,40)),Color(.06,.05,.09,.9))
  node.draw_rect(Rect2(board-Vector2(56,30),Vector2(112,40)),Color(NEON_CYAN.r,NEON_CYAN.g,NEON_CYAN.b,.5),false,2.0)
  node.draw_line(board-Vector2(46,28),board-Vector2(46,-8),Color(.55,.75,.9,.5),2.0)
  node.draw_line(board-Vector2(10,28),board-Vector2(10,-8),Color(.55,.75,.9,.5),2.0)
 # 화분
 for pot in [Vector2(1090,900),Vector2(2060,1180),Vector2(1470,1450),Vector2(2600,1600),Vector2(900,2200)]:
  node.draw_circle(pot+Vector2(0,6),10,Color(0,0,0,.3))
  node.draw_rect(Rect2(pot-Vector2(12,2),Vector2(24,20)),Color(.30,.20,.18,.95))
  node.draw_circle(pot-Vector2(0,20),15,Color(.16,.36,.24,.95))
  node.draw_circle(pot-Vector2(6,26),10,Color(.22,.44,.30,.9))
 # A형 입간판·쓰레기통·볼라드
 for a_board in [Vector2(1350,1420),Vector2(2100,1000),Vector2(700,900),Vector2(2400,1900)]:
  node.draw_rect(Rect2(a_board-Vector2(16,26),Vector2(32,34)),Color(.07,.06,.10,.92))
  node.draw_rect(Rect2(a_board-Vector2(16,26),Vector2(32,34)),Color(NEON_PINK.r,NEON_PINK.g,NEON_PINK.b,.55),false,1.6)
 for bin in [Vector2(1180,980),Vector2(2200,1320),Vector2(1600,1900),Vector2(600,2000)]:
  node.draw_rect(Rect2(bin-Vector2(10,14),Vector2(20,26)),Color(.18,.20,.24,.95))
  node.draw_rect(Rect2(bin-Vector2(10,14),Vector2(20,5)),Color(.34,.38,.44,.95))
 for bollard in [Vector2(1090,1600),Vector2(1090,1760),Vector2(2140,1600),Vector2(2140,1760)]:
  node.draw_circle(bollard+Vector2(0,4),6,Color(0,0,0,.3))
  node.draw_rect(Rect2(bollard-Vector2(4,18),Vector2(8,22)),Color(.30,.32,.38,.95))
  node.draw_rect(Rect2(bollard-Vector2(4,14),Vector2(8,4)),Color(.85,.72,.36,.9))
 # 공유 킥보드·자전거·벤치
 for scooter in [Vector2(1180,700),Vector2(2000,700),Vector2(500,1400),Vector2(2200,1400),Vector2(1600,1800)]:
  node.draw_circle(scooter+Vector2(-13,0),5.5,Color(.05,.05,.07,.92))
  node.draw_circle(scooter+Vector2(13,0),5.5,Color(.05,.05,.07,.92))
  node.draw_line(scooter+Vector2(-13,3),scooter+Vector2(0,-15),Color(.72,.50,.90,.95),3.6)
  node.draw_line(scooter+Vector2(0,-15),scooter+Vector2(15,-2),Color(.72,.50,.90,.95),3.6)
  node.draw_line(scooter+Vector2(0,-15),scooter+Vector2(6,-24),Color(.72,.50,.90,.95),2.6)
 for bench in [Vector2(700,820),Vector2(1500,820),Vector2(2300,1450),Vector2(1200,1700)]:
  node.draw_rect(Rect2(bench-Vector2(38,9),Vector2(76,15)),Color(.22,.18,.24,.95))
  node.draw_rect(Rect2(bench-Vector2(38,15),Vector2(76,8)),Color(.36,.28,.38,.95))
  node.draw_rect(Rect2(bench-Vector2(38,15),Vector2(76,8)),Color(NEON_PURPLE.r,NEON_PURPLE.g,NEON_PURPLE.b,.25),false,1.0)
 # 네온 아치 줄(골목 입구)
 for arch in [Vector2(1090,900),Vector2(2140,900),Vector2(1090,1600),Vector2(2140,1600)]:
  node.draw_line(arch-Vector2(40,0),arch-Vector2(40,-46),Color(.16,.14,.20,.95),4.0)
  node.draw_line(arch+Vector2(40,0),arch+Vector2(40,-46),Color(.16,.14,.20,.95),4.0)
  node.draw_line(arch-Vector2(40,-46),arch+Vector2(40,-46),Color(.16,.14,.20,.95),3.0)
  for k in range(5):
   node.draw_circle(arch-Vector2(32-float(k)*16,-44),2.6,Color(NEON_CYAN.r,NEON_CYAN.g,NEON_CYAN.b,.9))
 # 버스킹 거리 무대 표시
 var stage:=Rect2(1780,1520,240,150)
 node.draw_rect(stage,Color(.10,.08,.14,.55))
 node.draw_rect(stage,Color(NEON_PURPLE.r,NEON_PURPLE.g,NEON_PURPLE.b,.6),false,3.0)
 node.draw_rect(stage.grow(-8),Color(NEON_PURPLE.r,NEON_PURPLE.g,NEON_PURPLE.b,.20),false,1.4)
## 사물 발밑 그림자.
static func draw_prop_shadows(node: Node2D) -> void:
 for object in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(object.kind))
  var side: float=float(visual.get("shadow",10.0))
  node.draw_set_transform(object.p,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,side*1.35,Color(0,0,0,.34))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
