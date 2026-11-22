extends RefCounted
## 대구 동성로 정적 배경(2.0.35): 네온 번화가·불규칙 골목.
## 좌표는 dongseongno_layout.gd를 그대로 쓴다.
## 어두운 아스팔트 + 보랏빛/시안 네온 + 붉은 벽돌 건물. 실제 상호 텍스트는 쓰지 않는다.
const L=preload("res://scripts/survival/dongseongno_layout.gd")
const Q=preload("res://scripts/survival/quality.gd")
const K=preload("res://scripts/survival/art_kit.gd")
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
  # 2.0.38 구역 이름은 zone_labels.gd가 실내 레이어 위에서 그린다.
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
 street_details(node)
## 번화가 거리 감성: 네온이 번지는 물웅덩이·분필 낙서·잔 쓰레기·바닥 조명.
static func street_details(node: Node2D) -> void:
 var puddles=[[Vector2(1330,980),86.0,34.0,NEON_PINK],[Vector2(2380,1330),74.0,28.0,NEON_CYAN],
  [Vector2(760,1560),66.0,24.0,WARM],[Vector2(1830,760),90.0,32.0,NEON_PURPLE],[Vector2(2900,1680),70.0,26.0,NEON_CYAN]]
 for p in puddles:
  var at: Vector2=p[0]
  var rx: float=p[1]
  var ry: float=p[2]
  var tint: Color=p[3]
  node.draw_set_transform(at,0,Vector2(1,ry/rx))
  node.draw_circle(Vector2.ZERO,rx+3.0,Color(.02,.03,.06,.35))
  node.draw_circle(Vector2.ZERO,rx,Color(.04,.05,.10,.62))
  node.draw_circle(Vector2.ZERO,rx*.84,Color(.07,.09,.16,.55))
  node.draw_arc(Vector2(-rx*.18,0),rx*.52,PI*.12,PI*.86,16,Color(tint.r,tint.g,tint.b,.42),3.0,true)
  node.draw_arc(Vector2(rx*.22,rx*.06),rx*.28,PI*1.08,PI*1.82,12,Color(tint.r,tint.g,tint.b,.22),2.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 네온이 바닥에 길게 번지는 빛
 for glow_spot in [[Vector2(1090,780),NEON_PINK],[Vector2(2160,780),NEON_CYAN],[Vector2(1900,1470),NEON_PURPLE],[Vector2(1250,2050),WARM]]:
  K_glow(node,glow_spot[0],150.0,Color(glow_spot[1].r,glow_spot[1].g,glow_spot[1].b,.10))
 # 바닥 분필 낙서·화살표
 for mark in [[Vector2(1520,1240),"→"],[Vector2(2300,1660),"↖"],[Vector2(820,1120),"★"]]:
  node.draw_string(TITLE_FONT,(mark[0] as Vector2)+Vector2(-10,8),String(mark[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color(.85,.95,1,.18))
 # 잔 쓰레기·담배꽁초·전단
 for trash_spot in [Vector2(1160,920),Vector2(1980,1220),Vector2(1420,1700),Vector2(2500,980),Vector2(640,1700)]:
  node.draw_circle(trash_spot,2.2,Color(.86,.84,.78,.55))
  node.draw_circle(trash_spot+Vector2(5,3),1.6,Color(.72,.36,.32,.5))
  node.draw_rect(Rect2(trash_spot+Vector2(-9,-6),Vector2(10,7)),Color(.88,.88,.84,.35))
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
## 2.0.38 구역 이름표는 scripts/survival/zone_labels.gd가 그린다(벽·건물에 가리지 않게).
## 건물: 위에서 본 지붕면 + 남쪽 외벽(쇼윈도·차양·네온 간판).
static func draw_walls(node: Node2D) -> void:
 var sign_words=["노래","포차","분식","네컷","오락","치킨","커피","화장","문구","의류","떡볶이","아케이드"]
 var neon_colors=[NEON_PINK,NEON_CYAN,NEON_PURPLE,WARM]
 var awnings=[Color("d9564e"),Color("e0a04a"),Color("4aa6b8"),Color("c85f92"),Color("6fb05e"),Color("7f7fd0")]
 # 1) 모든 건물의 바닥 그림자(남동쪽으로 번짐).
 for rect in L.BUILDINGS_RECTS:
  for i in range(3):
   node.draw_rect(Rect2(rect.position.x+6.0+float(i)*4.0,rect.end.y+float(i)*4.0,rect.size.x,12.0),Color(.01,.01,.03,.20-float(i)*.05))
 # 2) 건물: 지붕면 → 옥상 설비 → 남쪽 외벽(쇼윈도·차양·간판).
 for index in range(L.BUILDINGS_RECTS.size()):
  var rect2: Rect2=L.BUILDINGS_RECTS[index]
  var neon_c: Color=neon_colors[index%neon_colors.size()]
  var awning_c: Color=awnings[index%awnings.size()]
  var word: String=sign_words[index%sign_words.size()]
  var face_h: float=46.0
  var roof:=Rect2(rect2.position,Vector2(rect2.size.x,maxf(20.0,rect2.size.y-face_h)))
  # 외곽선 + 지붕
  node.draw_rect(rect2.grow(4),Color(.02,.02,.04,.92))
  if index%3==0:
   fill_texture(node,"brick",roof,Color(.52,.48,.56,.95))
  else:
   # 지붕 색을 골목마다 다르게(청기와·슬레이트·동판·먹기와) — 목표 원화의 지붕 변화.
   var roof_tint: Color=[Color("2f3a56"),Color("2f2a3e"),Color("2b4438"),Color("3a2e3a")][index%4]
   node.draw_rect(roof,roof_tint)
   var ry: float=roof.position.y
   while ry<roof.end.y:
    node.draw_line(Vector2(roof.position.x,ry),Vector2(roof.end.x,ry),Color(.08,.07,.12,.30),1.2)
    ry+=12.0
  node.draw_rect(Rect2(roof.position,Vector2(roof.size.x,4)),Color(1,1,1,.10))
  node.draw_rect(Rect2(roof.position,Vector2(roof.size.x,1.6)),Color(.62,.58,.72,.55))
  # 옥상 난간(톱니) + 설비
  node.draw_rect(roof.grow(-3),Color(.10,.09,.14,.20),false,2.0)
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.58,rect2.size.y*.26),Vector2(34,24)),Color(.16,.15,.20))
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.58,rect2.size.y*.26),Vector2(34,5)),Color(.34,.33,.42))
  node.draw_circle(rect2.position+Vector2(rect2.size.x*.28,rect2.size.y*.40),11,Color(.10,.09,.13))
  node.draw_circle(rect2.position+Vector2(rect2.size.x*.28,rect2.size.y*.40),6,Color(.28,.26,.34))
  if rect2.size.x>260.0:
   node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.78,rect2.size.y*.24),Vector2(20,20)),Color(.18,.17,.23))
   node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.78,rect2.size.y*.24),Vector2(20,4)),Color(.36,.35,.44))
  # 남쪽 외벽
  var face:=Rect2(Vector2(rect2.position.x,rect2.end.y-face_h),Vector2(rect2.size.x,face_h))
  if index%3!=1:fill_texture(node,"brick",face,Color(.66,.60,.68,.98))
  else:node.draw_rect(face,Color("332c48"))
  node.draw_rect(Rect2(face.position,Vector2(face.size.x,3)),Color(.03,.02,.05,.92))
  node.draw_rect(Rect2(face.position,Vector2(face.size.x,1.4)),Color(.70,.62,.78,.55))
  # 쇼윈도: 따뜻한 불빛 + 진열 실루엣
  var glass:=Rect2(Vector2(face.position.x+10,face.position.y+12),Vector2(face.size.x-20,face.size.y-20))
  node.draw_rect(glass.grow(2),Color(.03,.02,.05,.96))
  var pane_w:=34.0
  var px:=glass.position.x
  var pi:=0
  while px<glass.end.x-10.0:
   var lit: Color=WARM if pi%4!=3 else NEON_CYAN
   var pane:=Rect2(px,glass.position.y,minf(pane_w,glass.end.x-px),glass.size.y)
   node.draw_rect(pane,Color(.05,.04,.08,.98))
   node.draw_rect(pane.grow(-2.5),Color(lit.r,lit.g,lit.b,.72))
   node.draw_rect(Rect2(pane.position+Vector2(2.5,2.5),Vector2(pane.size.x-5,3)),Color(1,1,1,.30))
   # 진열/사람 실루엣
   if pi%3==0:
    node.draw_rect(Rect2(pane.position+Vector2(pane.size.x*.30,pane.size.y*.55),Vector2(pane.size.x*.22,pane.size.y*.36)),Color(.06,.05,.09,.55))
   px+=pane_w+4.0
   pi+=1
  # 출입문 + 손잡이 + 문턱
  var door_c:=Vector2(rect2.get_center().x,face.position.y+8)
  var door:=Rect2(door_c-Vector2(16,4),Vector2(32,face_h-10))
  node.draw_rect(door.grow(1.4),Color(.02,.02,.04,.98))
  node.draw_rect(door,Color(.24,.19,.30))
  node.draw_rect(door.grow(-3),Color(.36,.55,.68,.45))
  node.draw_circle(door.position+Vector2(door.size.x-6,door.size.y*.55),1.8,Color(.92,.86,.62,.95))
  node.draw_rect(Rect2(door.position.x-4,door.end.y-3,door.size.x+8,3),Color(.60,.56,.64,.7))
  # 차양(파사드 위쪽에 붙는다)
  K_awning(node,Rect2(rect2.position.x+3,face.position.y+2,rect2.size.x-6,13),awning_c)
  # 파사드 간판(작게, 벽에 붙임)
  var label_w:=24.0+FONT.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+14.0
  var board:=Rect2(Vector2(rect2.position.x+12,rect2.position.y+roof.size.y-face_h*0.42),Vector2(minf(label_w,rect2.size.x-24.0),24))
  node.draw_rect(Rect2(board.position+Vector2(2,3),board.size),Color(0,0,0,.5))
  node.draw_rect(board.grow(1.2),Color(.02,.02,.05,.95))
  node.draw_rect(board,Color(.06,.05,.09,.95))
  node.draw_rect(board,Color(neon_c.r,neon_c.g,neon_c.b,.85),false,1.8)
  node.draw_string(FONT,board.position+Vector2(7,17),word,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1,.96,1,.95))
  # 세로 돌출 간판(골목에서 읽히는 네온)
  if rect2.size.x>210.0:
   var vsign:=Rect2(Vector2(rect2.end.x-22,rect2.position.y+30),Vector2(16,72))
   node.draw_rect(vsign.grow(2),Color(0,0,0,.55))
   node.draw_rect(vsign,Color(.05,.04,.08,.95))
   node.draw_rect(vsign,Color(neon_c.r,neon_c.g,neon_c.b,.85),false,1.6)
   for k in range(3):
    node.draw_rect(Rect2(vsign.position+Vector2(4,8+float(k)*20),Vector2(8,9)),Color(neon_c.r,neon_c.g,neon_c.b,.85))
   for k in range(3):
    node.draw_line(Vector2(vsign.end.x-2,vsign.position.y+8+float(k)*14),Vector2(vsign.end.x+7,vsign.position.y+8+float(k)*14),Color(.10,.10,.14,.9),2.0)
  # 벽면 포스터·에어컨 실외기·배관
  if rect2.size.x>300.0:
   node.draw_rect(Rect2(rect2.position.x+rect2.size.x*.12,face.position.y+6,26,34),Color(.90,.86,.80))
   node.draw_rect(Rect2(rect2.position.x+rect2.size.x*.12,face.position.y+6,26,10),neon_c.darkened(.2))
   for k in range(3):
    node.draw_rect(Rect2(rect2.position.x+rect2.size.x*.12+3,face.position.y+20+float(k)*6,20,2.2),Color(.20,.20,.26,.5))
   var ac:=Rect2(rect2.position.x+rect2.size.x*.86,face.position.y+4,22,20)
   node.draw_rect(ac.grow(1.2),Color(.02,.02,.04,.9))
   node.draw_rect(ac,Color(.72,.74,.78))
   for k in range(3):
    node.draw_line(Vector2(ac.position.x+3,ac.position.y+5+float(k)*5),Vector2(ac.end.x-3,ac.position.y+5+float(k)*5),Color(.35,.36,.40,.8),1.4)
  if not Q.low:roof_furniture(node,rect2,roof,neon_c,index)
  # 상점 앞 도로에 따뜻한 불빛이 번진다(유리창 불빛 → 보도).
  K_glow(node,Vector2(rect2.get_center().x,rect2.end.y+34.0),118.0,Color(1,.76,.42,.12))
  K_glow(node,Vector2(rect2.position.x+rect2.size.x*.22,rect2.end.y+22.0),66.0,Color(1,.72,.40,.10))
  # 보도 화단(가게 앞 꽃 화분) — 세 채 중 한 채만.
  if not Q.low and index%3==0:
   for k in range(2):
    var bx:=rect2.position.x+rect2.size.x*(0.26+0.36*float(k))
    K.planter_box(node,Rect2(Vector2(bx,rect2.end.y+16.0),Vector2(46,26)))
  # 간판 빛 번짐: 벽 앞 바닥을 은은하게 밝힌다.
  K_glow(node,Vector2(rect2.get_center().x,rect2.end.y+16),72.0,Color(neon_c.r,neon_c.g,neon_c.b,.10))
 # 3) 골목 위 전선
 for wire in [[Vector2(190,760),Vector2(1090,760)],[Vector2(900,1450),Vector2(1700,1450)],[Vector2(1400,2050),Vector2(2100,2050)],[Vector2(2160,760),Vector2(3100,760)]]:
  node.draw_line(wire[0],wire[1],Color(.05,.05,.08,.55),2.0)
  for k in range(7):
   var t:=float(k+1)/8.0
   node.draw_circle(wire[0].lerp(wire[1],t)+Vector2(0,sin(t*PI)*10.0),1.7,Color(.09,.09,.13,.9))
## 차양(줄무늬 + 물결 밑단).
static func K_awning(node: Node2D,rect: Rect2,color: Color) -> void:
 var stripes:=maxi(2,int(rect.size.x/24.0))
 for i in range(stripes):
  var x:=rect.position.x+rect.size.x*float(i)/float(stripes)
  var w:=rect.size.x/float(stripes)
  node.draw_rect(Rect2(x,rect.position.y,w,rect.size.y),color if i%2==0 else Color(.95,.94,.90))
 node.draw_rect(rect,Color(.02,.02,.04,.85),false,1.4)
 for i in range(stripes):
  var cx:=rect.position.x+rect.size.x*(float(i)+0.5)/float(stripes)
  node.draw_set_transform(Vector2(cx,rect.end.y),0,Vector2(1,.55))
  node.draw_circle(Vector2.ZERO,rect.size.x/float(stripes)*0.5,color if i%2==0 else Color(.95,.94,.90))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_rect(Rect2(rect.position.x,rect.end.y,rect.size.x,6),Color(.01,.01,.03,.35))
static func K_glow(node: Node2D,center: Vector2,radius: float,color: Color) -> void:
 for i in range(4):
  var k:=1.0-float(i)*0.2
  node.draw_circle(center,radius*k,Color(color.r,color.g,color.b,color.a*(0.30-float(i)*0.05)))

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
 street_props(node)
## 옥상 디테일: 난간·옥상 간판·텃밭·위성 접시·건조대.
static func roof_furniture(node: Node2D,rect: Rect2,roof: Rect2,neon: Color,index: int) -> void:
 # 옥상 테두리 난간
 var rail:=Color(.24,.21,.30,.9)
 node.draw_line(Vector2(roof.position.x+3,roof.position.y+3),Vector2(roof.end.x-3,roof.position.y+3),rail,2.0)
 node.draw_line(Vector2(roof.position.x+3,roof.position.y+3),Vector2(roof.position.x+3,roof.end.y-3),rail,2.0)
 for k in range(int(roof.size.x/40.0)):
  var x:=roof.position.x+10.0+float(k)*40.0
  node.draw_line(Vector2(x,roof.position.y+3),Vector2(x,roof.position.y+9),Color(.30,.27,.36,.8),1.6)
 # 옥상 간판(지붕 위에 세운 판 + 지지대 + 빛)
 if index%2==0 and roof.size.x>200.0:
  var board:=Rect2(Vector2(roof.position.x+roof.size.x*0.18,roof.position.y+roof.size.y*0.18),Vector2(minf(150.0,roof.size.x*0.5),26))
  node.draw_rect(Rect2(board.position+Vector2(4,5),board.size),Color(0,0,0,.45))
  node.draw_rect(board.grow(1.5),Color(.02,.02,.05,.95))
  node.draw_rect(board,Color(.06,.05,.10,.96))
  node.draw_rect(board,Color(neon.r,neon.g,neon.b,.9),false,2.0)
  node.draw_string(FONT,board.position+Vector2(10,18),["별빛랜드","노래방","24시","분식","네컷"][index%5],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(1,.97,1,.96))
  for rod in [board.position.x+12,board.end.x-12]:
   node.draw_line(Vector2(rod,board.end.y),Vector2(rod,board.end.y+14),Color(.12,.12,.16,.9),2.2)
  K_glow(node,board.get_center(),70.0,Color(neon.r,neon.g,neon.b,.10))
 # 옥상 텃밭(화단 상자 + 잎)
 if index%3==2 and roof.size.x>240.0:
  for k in range(2):
   var box:=Rect2(Vector2(roof.position.x+roof.size.x*0.55+float(k)*54.0,roof.position.y+roof.size.y*0.55),Vector2(46,24))
   node.draw_rect(box,Color(.28,.20,.16))
   node.draw_rect(box,Color(.42,.32,.24),false,1.4)
   for j in range(4):
    node.draw_circle(box.get_center()+Vector2(-14.0+float(j)*9.0,-6.0),5.0,Color(.22,.44,.28,.9))
 # 위성 접시
 if index%4==1:
  var at:=Vector2(roof.position.x+roof.size.x*0.75,roof.position.y+roof.size.y*0.62)
  node.draw_line(at+Vector2(0,6),at+Vector2(0,-2),Color(.30,.30,.36),2.0)
  node.draw_set_transform(at+Vector2(0,-6),-0.5,Vector2(1,.7))
  node.draw_circle(Vector2.ZERO,9.0,Color(.78,.80,.84))
  node.draw_circle(Vector2.ZERO,5.0,Color(.56,.58,.64))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 건조대(빨래)
 if index%5==3 and roof.size.x>260.0:
  var y:=roof.position.y+roof.size.y*0.42
  node.draw_line(Vector2(roof.position.x+30,y),Vector2(roof.position.x+150,y),Color(.40,.40,.46,.8),1.6)
  for k in range(4):
   var c: Color=[Color(.86,.40,.42),Color(.42,.62,.86),Color(.90,.86,.70),Color(.62,.78,.60)][k]
   node.draw_rect(Rect2(Vector2(roof.position.x+42.0+float(k)*26.0,y+1),Vector2(16,18)),Color(c.r,c.g,c.b,.92))
## 거리 소품: 포장마차·간이 테이블·상자·자전거·현수막·에어컨 실외기.
static func street_props(node: Node2D) -> void:
 # 포장마차/노점(따뜻한 등불 + 김)
 for stall in [Vector2(980,1080),Vector2(2380,1620),Vector2(1350,1860),Vector2(2860,1080)]:
  var aw: Color=Color("c8443c")
  var body:=Rect2(stall-Vector2(58,0),Vector2(116,34))
  node.draw_rect(body,Color(.22,.16,.14,.95))
  node.draw_rect(body,Color(.34,.26,.22),false,1.6)
  node.draw_rect(Rect2(body.position-Vector2(0,6),Vector2(body.size.x,10)),Color(.92,.90,.84,.9))
  for k in range(4):
   node.draw_rect(Rect2(body.position+Vector2(float(k)*29,-14),Vector2(15,14)),aw if k%2==0 else Color(.90,.88,.82))
  node.draw_rect(Rect2(body.position+Vector2(6,-20),Vector2(body.size.x-12,4)),Color(.14,.10,.10,.95))
  node.draw_circle(stall+Vector2(0,-24),20,Color(1,.74,.36,.18))
  node.draw_circle(stall+Vector2(0,-26),5,Color(1,.88,.62,.95))
  # 김
  for k in range(3):
   var t:=fmod(float(k)*0.33+float(int(stall.x))*.01,1.0)
   node.draw_circle(stall+Vector2(-8.0+float(k)*9.0,-30.0-t*26.0),4.0+t*5.0,Color(.86,.88,.92,.06))
 # 간이 테이블 + 의자
 for spot in [Vector2(1060,1150),Vector2(2440,1690),Vector2(1420,1930),Vector2(2920,1140)]:
  node.draw_set_transform(spot,0,Vector2(1,.6))
  node.draw_circle(Vector2.ZERO,22,Color(.06,.05,.08,.35))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  node.draw_circle(spot,16,Color(.36,.26,.20,.98))
  node.draw_circle(spot,13,Color(.52,.38,.28,.98))
  node.draw_circle(spot+Vector2(-22,0),5,Color(.30,.24,.20))
  node.draw_circle(spot+Vector2(22,0),5,Color(.30,.24,.20))
  node.draw_circle(spot+Vector2(-4,-3),4,Color(.86,.30,.26,.9))
  node.draw_circle(spot+Vector2(5,2),3.4,Color(.92,.84,.60,.9))
 # 쌓인 상자·쓰레기 더미
 for stack in [Vector2(760,1250),Vector2(2080,1780),Vector2(3060,1520)]:
  node.draw_rect(Rect2(stack-Vector2(16,12),Vector2(32,24)),Color(.48,.36,.24))
  node.draw_rect(Rect2(stack-Vector2(16,12),Vector2(32,24)),Color(.72,.58,.40),false,1.4)
  node.draw_line(stack-Vector2(16,0),stack+Vector2(16,0),Color(.40,.30,.20),1.4)
  node.draw_rect(Rect2(stack+Vector2(-10,-30),Vector2(24,18)),Color(.44,.32,.22))
  node.draw_rect(Rect2(stack+Vector2(-10,-30),Vector2(24,18)),Color(.68,.54,.36),false,1.2)
 # 자전거 거치대(바퀴 두 개 + 프레임)
 for bike in [Vector2(1230,760),Vector2(1960,1460),Vector2(2560,2050)]:
  node.draw_arc(bike+Vector2(-16,0),9,0,TAU,16,Color(.10,.10,.14,.95),2.6,true)
  node.draw_arc(bike+Vector2(16,0),9,0,TAU,16,Color(.10,.10,.14,.95),2.6,true)
  node.draw_line(bike+Vector2(-16,0),bike+Vector2(0,-16),Color("e05a5a"),3.0)
  node.draw_line(bike+Vector2(0,-16),bike+Vector2(16,0),Color("e05a5a"),3.0)
  node.draw_line(bike+Vector2(-16,0),bike+Vector2(0,2),Color("e05a5a"),2.4)
  node.draw_line(bike+Vector2(0,-16),bike+Vector2(4,-24),Color(.12,.12,.16),2.4)
 # 현수막(건물 사이 끈)
 for banner in [[Vector2(1150,905),Vector2(1450,905),Color("ff8ac8")],[Vector2(1750,1470),Vector2(2050,1470),Color("7fe4ff")]]:
  var a: Vector2=banner[0]
  var b: Vector2=banner[1]
  var c: Color=banner[2]
  node.draw_rect(Rect2(a+Vector2(0,-3),Vector2(b.x-a.x,18)),Color(.06,.05,.09,.92))
  node.draw_rect(Rect2(a+Vector2(0,-3),Vector2(b.x-a.x,18)),Color(c.r,c.g,c.b,.9),false,1.4)
  for k in range(6):
   node.draw_rect(Rect2(a+Vector2(10.0+float(k)*46.0,1),Vector2(30,8)),Color(c.r,c.g,c.b,.55))

## 사물 발밑 그림자.
static func draw_prop_shadows(node: Node2D) -> void:
 for object in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(object.kind))
  var side: float=float(visual.get("shadow",10.0))
  node.draw_set_transform(object.p,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,side*1.35,Color(0,0,0,.34))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
