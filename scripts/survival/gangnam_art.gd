extends RefCounted
## 서울 강남역 정적 배경(2.0.38): 상용 2D 카툰 톤.
##
## 2.0.37까지는 바닥이 단색 사각형, 벽이 민짜 남색 상자여서 '프로그래머 아트'로 보였다.
## 2.0.38부터 바닥은 대리석 타일 텍스처 + 구역 색조 + 천장 조명 웅덩이,
## 벽은 금속 패널 텍스처 + 상판 하이라이트 + 시안 네온 몰딩 + 벽면 설비(포스터·환풍구·
## 소화전·안내도)로 그린다. 모든 사물은 art_kit의 그림자→몸통→하이라이트 순서를 따른다.
## 모든 좌표는 gangnam_layout.gd를 그대로 쓰므로 그림과 충돌이 어긋나지 않는다.
const L=preload("res://scripts/survival/gangnam_layout.gd")
const K=preload("res://scripts/survival/art_kit.gd")
const Q=preload("res://scripts/survival/quality.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const VOID=Color("05070d")
const FLOOR=Color("95a3b8")
const CORRIDOR=Color("8899b0")
const WALL_FILL=Color("151b29")
const WALL_TOP=Color("2b3650")
const WALL_EDGE=Color("05070d")
const NEON=Color("56e0ff")
const NEON_PINK=Color("ff5fa8")
const TACTILE=Color("ffd54a")
const TRACK=Color("0a0d16")
const RAIL=Color("4a5468")
## 천장 조명(바닥에 번지는 빛) — 바닥 조명 뎁스를 만든다.
const LAMP_WARM=Color("ffe9c0")
const LAMP_COOL=Color("cfe8ff")
static func shadow(node: Node2D,rect: Rect2,offset: Vector2,alpha: float=.42) -> void:
 node.draw_rect(Rect2(rect.position+offset,rect.size),Color(0,0,0,alpha))
## 바닥: 대리석 타일 → 복도 → 구역 색조 → 조명 웅덩이 → 바닥 표식.
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-160,-160),L.SIZE+Vector2(320,320)),VOID)
 # 1) 맵 전체 대리석. 타일 텍스처 1장을 GPU가 반복한다(모바일 1 draw call).
 K.tiled(node,K.TEX_GANGNAM_FLOOR,Rect2(110,140,3180,2320),Color(.80,.83,.90,1))
 node.draw_rect(Rect2(110,140,3180,2320),Color(.32,.38,.50,.16))
 # 2) 큰길(복도): 살짝 밝은 타일 + 중앙 시안 안내선.
 for path in L.PATHS:
  var w: float=float(path.w)
  var pts: Array=path.p
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var rect:=Rect2(Vector2(minf(a.x,b.x)-w*.5,minf(a.y,b.y)-w*.5),
    Vector2(absf(b.x-a.x)+w,absf(b.y-a.y)+w))
   K.tiled(node,K.TEX_GANGNAM_FLOOR,rect,Color(1.0,1.02,1.06,1))
   node.draw_rect(rect,Color(.55,.68,.86,.10))
   var along: Vector2=(b-a).normalized()
   var side:=Vector2(-along.y,along.x)*4.0
   K.neon(node,a+side,b+side,Color(NEON.r,NEON.g,NEON.b,.55),3.0,true)
   street_trim(node,rect,a.distance_to(b)>12.0 and absf(b.x-a.x)>absf(b.y-a.y))
 # 3) 구역 바닥: 색조 + 경계 인레이 + 가운데 조명.
 for zone in L.ZONES:
  var rect2: Rect2=zone.rect
  var accent: Color=zone.accent
  # 구역 바닥: 마름모 패턴 타일(대합실 톤)에 구역 색을 아주 옅게 입힌다.
  K.tiled(node,K.TEX_GANGNAM_DIAMOND,rect2,Color(0.86+accent.r*0.14,0.88+accent.g*0.12,0.94+accent.b*0.06,1))
  node.draw_rect(rect2,Color(accent.r,accent.g,accent.b,.045))
  var center: Vector2=rect2.get_center()
  var glow_radius: float=maxf(rect2.size.x,rect2.size.y)*.60
  # 조명 뎁스: 가운데는 밝고 가장자리는 어두워진다.
  for k in range(4):
   var t: float=float(k)/4.0
   node.draw_circle(center,glow_radius*(1.0-t),Color(accent.r,accent.g,accent.b,.035*(1.0-t)),true,-1.0,true)
  for k2 in range(3):
   var inset: float=26.0+float(k2)*26.0
   node.draw_rect(rect2.grow(-inset),Color(.02,.04,.08,.05),false,inset)
  # 구역 경계의 네온 인레이(두 겹)
  node.draw_rect(rect2.grow(-3),Color(accent.r,accent.g,accent.b,.34),false,3.0)
  node.draw_rect(rect2.grow(-8),Color(accent.r,accent.g,accent.b,.12),false,1.2)
  # 모서리 장식(금속 코너 브래킷)
  for corner in [rect2.position+Vector2(8,8),Vector2(rect2.end.x-8,rect2.position.y+8),Vector2(rect2.position.x+8,rect2.end.y-8),rect2.end-Vector2(8,8)]:
   node.draw_circle(corner,3.2,Color(accent.r,accent.g,accent.b,.55))
 # 4) 승강장: 스크린도어 앞 노란 안전선 + 선로.
 var platform:=Rect2(150,2150,3100,250)
 node.draw_rect(platform,Color(.18,.22,.32,.30))
 node.draw_rect(Rect2(150,2366,3100,6),Color(TACTILE.r,TACTILE.g,TACTILE.b,.85))
 node.draw_rect(Rect2(150,2380,3100,20),Color(TRACK.r,TRACK.g,TRACK.b,.9))
 node.draw_rect(Rect2(150,2420,3100,44),TRACK)
 for i in range(2):
  var y: float=2432.0+i*16.0
  node.draw_line(Vector2(160,y),Vector2(3240,y),RAIL,3.0)
 for i in range(26):
  var x:=190.0+float(i)*120.0
  node.draw_rect(Rect2(x,2412,12,8),Color(.30,.33,.40,.9))
 # 5) 점자블록(노란 점선) — 복도 중심과 존 출입구를 잇는다.
 for path in L.PATHS:
  var pts2: Array=path.p
  for i in range(pts2.size()-1):
   var a2: Vector2=pts2[i]
   var b2: Vector2=pts2[i+1]
   var length: float=a2.distance_to(b2)
   var steps:=maxi(1,int(length/34.0))
   for k in range(steps):
    if k%2==1:continue
    var p: Vector2=a2.lerp(b2,float(k)/steps)
    node.draw_rect(Rect2(p-Vector2(7,7),Vector2(14,14)),Color(TACTILE.r,TACTILE.g,TACTILE.b,.50))
    node.draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),Color(.55,.42,.06,.35))
 # 6) 천장 조명: 복도·존 가운데에 실제 조명기를 그리고 바닥에 빛을 깐다.
 ceiling_lights(node)
 # 7) 바닥 디테일(맨홀·배수구·틈·얼룩·유도 화살표·출구 표지). 낮음 화질은 생략.
 if not Q.low:floor_details(node)
 draw_decor(node)
## 복도 가장자리 금속 몰딩(가로/세로).
static func street_trim(node: Node2D,rect: Rect2,horizontal: bool) -> void:
 if horizontal:
  node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,3)),Color(.02,.03,.05,.35))
  node.draw_rect(Rect2(Vector2(rect.position.x,rect.end.y-3),Vector2(rect.size.x,3)),Color(1,1,1,.06))
 else:
  node.draw_rect(Rect2(rect.position,Vector2(3,rect.size.y)),Color(.02,.03,.05,.35))
  node.draw_rect(Rect2(Vector2(rect.end.x-3,rect.position.y),Vector2(3,rect.size.y)),Color(1,1,1,.06))
## 천장 조명기 + 바닥 조명 웅덩이.
static func ceiling_lights(node: Node2D) -> void:
 var spots: Array=[]
 for path in L.PATHS:
  var pts: Array=path.p
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var length:=a.distance_to(b)
   var count:=maxi(1,int(length/(420.0 if Q.low else 260.0)))
   for k in range(count):
    spots.append(a.lerp(b,(float(k)+0.5)/float(count)))
 for zone in L.ZONES:
  var rect: Rect2=zone.rect
  if rect.size.x>420.0 and rect.size.y>300.0:
   spots.append(rect.get_center()+Vector2(-rect.size.x*.22,-rect.size.y*.18))
   spots.append(rect.get_center()+Vector2(rect.size.x*.22,rect.size.y*.18))
 var seen: Dictionary={}
 for at in spots:
  var key: String="%d_%d"%[int(at.x/80.0),int(at.y/80.0)]
  if seen.has(key):continue
  seen[key]=true
  ceiling_fixture(node,at)
static func ceiling_fixture(node: Node2D,at: Vector2) -> void:
 # 바닥에 떨어지는 빛(가장 먼저 깔아 사물이 그 위에 서게 한다).
 K.light_pool(node,at,96.0,Color(LAMP_COOL.r,LAMP_COOL.g,LAMP_COOL.b,.13))
 # 조명기: 얇은 금속 하우징 + 두 줄의 젖빛 발광부. 바닥에 놓인 종이처럼 보이지 않게
 # 어두운 테두리와 바닥 그림자를 함께 준다.
 var body:=Rect2(at-Vector2(26,9),Vector2(52,18))
 node.draw_set_transform(at+Vector2(0,14),0,Vector2(1,.30))
 node.draw_circle(Vector2.ZERO,32,Color(.02,.03,.05,.30))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_rect(body.grow(1.6),Color(.02,.03,.05,.9))
 node.draw_rect(body,Color(.13,.17,.25))
 node.draw_rect(Rect2(body.position+Vector2(4,4),Vector2(body.size.x-8,5)),Color(.58,.70,.86,.55))
 node.draw_rect(Rect2(body.position+Vector2(6,11),Vector2(body.size.x-12,3)),Color(.42,.56,.72,.40))
 node.draw_rect(Rect2(body.position+Vector2(5,5),Vector2(4,3)),Color(.92,.97,1,.70))
## 바닥 장식: 맨홀·배수구·틈·얼룩·유도 화살표·출구 표지.
static func floor_details(node: Node2D) -> void:
 for at in [Vector2(1420,1180),Vector2(2100,1500),Vector2(900,1050),Vector2(2500,1150),Vector2(1750,1850)]:
  K.manhole(node,at,15.0,Color(.36,.46,.40))
 for grate in [Vector2(760,760),Vector2(1560,760),Vector2(2400,1900),Vector2(1100,1990),Vector2(2960,1980)]:
  var rect:=Rect2(grate-Vector2(26,14),Vector2(52,28))
  node.draw_rect(rect.grow(1.2),Color(.03,.04,.06,.7))
  node.draw_rect(rect,Color(.17,.20,.26))
  for i in range(5):
   node.draw_line(Vector2(rect.position.x+4,rect.position.y+4+float(i)*5),Vector2(rect.end.x-4,rect.position.y+4+float(i)*5),Color(.02,.03,.05,.8),1.6)
 for crack in [[Vector2(1300,980),90.0,0.3],[Vector2(2300,1620),70.0,1.9],[Vector2(600,1620),80.0,0.9],[Vector2(2700,960),60.0,2.4]]:
  K.crack(node,crack[0],crack[1],crack[2])
 # 커피 얼룩·발자국 같은 생활감.
 for stain in [Vector2(1180,1420),Vector2(2050,1080),Vector2(820,1520)]:
  node.draw_set_transform(stain,0,Vector2(1,.5))
  node.draw_circle(Vector2.ZERO,22,Color(.18,.13,.10,.10))
  node.draw_circle(Vector2(7,-4),12,Color(.18,.13,.10,.08))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 유도 화살표
 for arrow in [[Vector2(1090,1200),PI*.5],[Vector2(2190,1500),PI*.5],[Vector2(1500,2040),0.0],[Vector2(2600,2040),PI]]:
  K.floor_arrow(node,arrow[0],arrow[1],Color(1,1,1,.9))
## 정적 소품: 벤치·화분·기둥·쓰레기통·안내 표지·출구 표지.
static func draw_decor(node: Node2D) -> void:
 for spot in [Vector2(640,1210),Vector2(640,1390),Vector2(2680,640),Vector2(2250,760),Vector2(1450,2250),Vector2(2650,2080)]:
  K.bench(node,spot,120.0,Color("4a5d78"))
 for spot2 in [Vector2(1200,760),Vector2(2080,760),Vector2(2300,1000),Vector2(1180,1680),Vector2(2100,1620),Vector2(1700,700)]:
  K.planter(node,spot2,1.0)
 for bin in [Vector2(980,1020),Vector2(2260,1200),Vector2(1300,1880),Vector2(2760,1600)]:
  K.trash(node,bin,Color("3b4658"))
 # 사각 화단(대합실·통로) — 잎과 꽃이 있는 돌 화단.
 for box in [Vector2(1450,1120),Vector2(1840,1120),Vector2(1450,1700),Vector2(1840,1700),Vector2(900,1180),Vector2(2550,1400)]:
  K.planter_box(node,Rect2(box-Vector2(34,24),Vector2(68,48)))
 # 원통형 광고 키오스크(은은한 네온 광고).
 K.ad_kiosk(node,Vector2(1260,1380),Color("ffb0d0"))
 K.ad_kiosk(node,Vector2(2020,1380),Color("8fd8ff"))
 K.ad_kiosk(node,Vector2(2650,1050),Color("c9b6ff"))
 # 자판기 코너의 자판기 3대 + 사물함(관리실)
 K.vending_row(node,Vector2(760,980),3)
 K.locker_bank(node,Rect2(2450,760,150,34),Color(.28,.34,.44))
 # 대합실 기둥(구조물): 네온 띠가 켜진 남색 기둥.
 for at in [Vector2(1290,1010),Vector2(1990,1010),Vector2(1290,1620),Vector2(1990,1620)]:
  K.pillar(node,at,52.0,52.0,Color("ffd98a"))
 # 출구·승강장 안내 표지
 for entry in [{"at":Vector2(470,180),"text":"3번 출구 EXIT","color":Color("8fe3b0")},
  {"at":Vector2(1730,180),"text":"카페 · CAFE","color":Color("ffcf8a")},
  {"at":Vector2(2860,180),"text":"관리실 · STAFF","color":Color("9fc4ff")},
  {"at":Vector2(1500,2170),"text":"승강장 PLATFORM","color":Color("a8f0d0")}]:
  var at2: Vector2=entry.at
  var text: String=entry.text
  var color: Color=entry.color
  var width:=18.0+FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x+18.0
  var rect:=Rect2(Vector2(at2.x-width*.5,at2.y-24),Vector2(width,48))
  K.sign(node,rect,text,color,Color(.04,.06,.10,.90),color,20)
  K.neon(node,Vector2(rect.position.x+6,rect.end.y+4),Vector2(rect.end.x-6,rect.end.y+4),color,2.0,true)
 # 출구 계단(3번 출구)
 K.stairs(node,Rect2(300,230,240,210),true,Color("8fe3b0"))
 node.draw_rect(Rect2(300,230,240,210),Color(.72,.86,.78,.18))
 # 벤치 위 안내 스탠드(작은 기둥 + 표지)
 for stand in [Vector2(1650,1080),Vector2(1450,1600),Vector2(2600,1250)]:
  K.street_lamp(node,stand,44.0,Color("cfe8ff"))
## 벽: 금속 패널 몸통 + 상판 하이라이트 + 시안 네온 몰딩 + 벽면 설비.
static func draw_walls(node: Node2D) -> void:
 for rect in L.HARD:
  if L.ISLANDS.has(rect):continue
  shadow(node,rect,Vector2(0,12),.50)
  shadow(node,rect,Vector2(0,6),.35)
 for island in L.ISLANDS:
  shadow(node,island,Vector2(0,10),.45)
 for island in L.ISLANDS:
  draw_island(node,island)
 # 긴 벽부터 그려 짧은 벽이 위에 얹히게 한다.
 var ordered: Array=L.HARD.duplicate()
 ordered.sort_custom(func(a: Rect2,b: Rect2)->bool:return a.size.x*a.size.y>b.size.x*b.size.y)
 for rect in ordered:
  if L.ISLANDS.has(rect):continue
  draw_wall_block(node,rect)
 # 쇼윈도·상점 앞면: 카페·팝업존·관리실 쪽 벽.
 storefronts(node)
## 벽 한 칸: 두꺼운 금속 패널 + 네온 몰딩 + 카메라 쪽 벽면(2.5D 두께).
static func draw_wall_block(node: Node2D,rect: Rect2) -> void:
 var horizontal:=rect.size.x>=rect.size.y
 var face_depth:=13.0
 # 1) 벽이 바닥에 내리깔리는 그림자(남/동쪽으로 번짐).
 for i in range(3):
  var grow:=4.0+float(i)*4.0
  node.draw_rect(Rect2(rect.position.x+4.0,rect.end.y+float(i)*4.0,rect.size.x,face_depth),Color(.01,.02,.04,.20-float(i)*.05))
 # 2) 벽면(카메라 쪽으로 보이는 두께) — 위는 밝고 아래는 어두운 수직 그라데이션.
 var face:=Rect2(Vector2(rect.position.x,rect.end.y),Vector2(rect.size.x,face_depth))
 node.draw_rect(face.grow(1.4),Color(.02,.02,.04,.92))
 node.draw_rect(face,Color(.10,.13,.20))
 node.draw_rect(Rect2(face.position,Vector2(face.size.x,4)),Color(.19,.24,.34))
 node.draw_rect(Rect2(Vector2(face.position.x,face.end.y-3),Vector2(face.size.x,3)),Color(.03,.04,.06,.95))
 # 3) 상판(벽 위 면): 금속 패널 텍스처 + 밝은 앞모서리 + 어두운 뒤모서리.
 node.draw_rect(rect.grow(4),Color(.02,.02,.04,.75))
 node.draw_rect(rect.grow(1.5),Color(.03,.04,.07,.95))
 K.tiled(node,K.TEX_GANGNAM_PANEL,rect,Color(.74,.79,.90,1))
 node.draw_rect(rect,Color(WALL_FILL.r,WALL_FILL.g,WALL_FILL.b,.30))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,6)),Color(.21,.27,.40,.95))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,2.0)),Color(.58,.72,.98,.70))
 # 4) 네온 몰딩: 벽면 위쪽에 시안 한 줄, 상판 앞모서리에 핑크 포인트.
 if horizontal and rect.size.x>120.0:
  K.neon(node,Vector2(face.position.x+4,face.position.y+5),Vector2(face.end.x-4,face.position.y+5),Color(NEON.r,NEON.g,NEON.b,.55),2.0,false)
  if rect.size.x>320.0:
   K.neon(node,Vector2(rect.position.x+8,rect.end.y-4),Vector2(rect.end.x-8,rect.end.y-4),Color(NEON_PINK.r,NEON_PINK.g,NEON_PINK.b,.25),1.4,false)
 elif not horizontal and rect.size.y>120.0:
  var face_v:=Rect2(Vector2(rect.end.x,rect.position.y),Vector2(face_depth,rect.size.y))
  node.draw_rect(face_v.grow(1.4),Color(.02,.02,.04,.92))
  node.draw_rect(face_v,Color(.10,.13,.20))
  node.draw_rect(Rect2(face_v.position,Vector2(4,face_v.size.y)),Color(.19,.24,.34))
  K.neon(node,Vector2(face_v.position.x+5,face_v.position.y+4),Vector2(face_v.position.x+5,face_v.end.y-4),Color(NEON.r,NEON.g,NEON.b,.45),2.0,false)
 # 5) 벽면 설비: 벽면 띠 위에 붙인다(떠 보이지 않게).
 if horizontal and rect.size.x>=300.0:
  wall_fixtures(node,rect,face)
 # 벽 끝 기둥 캡
 for corner in [rect.position,Vector2(rect.end.x-6,rect.position.y),Vector2(rect.position.x,rect.end.y-6),Vector2(rect.end.x-6,rect.end.y-6)]:
  node.draw_rect(Rect2(corner,Vector2(6,6)),Color(.10,.13,.20,.9))
## 긴 벽에 붙는 설비(포스터·환풍구·소화전·노선도·광고). 벽 밖으로 조금만 튀어나온다.
static func wall_fixtures(node: Node2D,rect: Rect2,face: Rect2) -> void:
 var length:=rect.size.x
 var count:=maxi(1,int(length/420.0))
 for i in range(count):
  var t: float=(float(i)+0.5)/float(count)
  var x: float=rect.position.x+length*t
  var kind:=i%4
  match kind:
   0:
    # 매달린 안내판: 벽 위로 걸린 판 + 지지봉 + 그림자
    var board:=Rect2(Vector2(x-46,rect.position.y-36),Vector2(92,30))
    node.draw_rect(Rect2(board.position+Vector2(3,4),board.size),Color(0,0,0,.40))
    K.sign(node,board,"노선도",Color(.90,.95,1),Color(.05,.07,.12,.96),Color(.45,.72,1,.9),15)
    for rod in [board.position.x+10,board.end.x-10]:
     node.draw_line(Vector2(rod,board.end.y),Vector2(rod,rect.end.y+4),Color(.06,.07,.10,.9),2.0)
   1:
    # 벽면 포스터(벽 띠 안에 붙인다)
    K.poster(node,Rect2(Vector2(x-28,rect.position.y+3),Vector2(56,20)),Color("7fd4ff"),2)
   2:
    # 환풍구
    K.vent(node,Rect2(Vector2(x-22,rect.position.y+5),Vector2(44,16)),Color(.16,.20,.28))
   _:
    # 네온 광고 상자
    var box:=Rect2(Vector2(x-34,rect.position.y+4),Vector2(68,18))
    node.draw_rect(box.grow(1.2),Color(.02,.03,.05,.95))
    node.draw_rect(box,Color(.10,.14,.22,.95))
    for k in range(3):
     node.draw_rect(Rect2(box.position+Vector2(8+float(k)*18,5),Vector2(12,8)),Color("ff8ac8") if k%2==0 else Color("7fe6ff"))
    K.light_pool(node,box.get_center(),26,Color(1,.55,.8,.12))
## 대합실 섬(안내도·키오스크): 대리석 상판 + 황동 테두리 + 위에 놓인 안내물.
static func draw_island(node: Node2D,rect: Rect2) -> void:
 node.draw_rect(rect.grow(3),Color(.02,.03,.05,.85))
 K.tiled(node,K.TEX_GANGNAM_FLOOR,rect.grow(-2),Color(1.05,1.06,1.10,1))
 node.draw_rect(rect.grow(-2),Color(.62,.52,.32,.35),false,3.0)
 node.draw_rect(rect.grow(-6),Color(1,1,1,.10),false,1.4)
 var c:=rect.get_center()
 if rect.size.x>rect.size.y:
  # 안내 데스크: 모니터·팜플릿·작은 조명
  node.draw_rect(Rect2(c-Vector2(38,16),Vector2(76,32)),Color(.10,.12,.18))
  node.draw_rect(Rect2(c-Vector2(30,10),Vector2(60,20)),Color(.30,.55,.72))
  node.draw_rect(Rect2(c-Vector2(26,6),Vector2(52,12)),Color(.62,.86,1,.9))
  K.sign(node,Rect2(c+Vector2(-44,20),Vector2(88,20)),"안내",Color(.06,.08,.12),Color(.92,.90,.84),Color(.80,.66,.38),15)
 else:
  node.draw_rect(Rect2(c-Vector2(16,34),Vector2(32,46)),Color(.10,.12,.18))
  node.draw_rect(Rect2(c-Vector2(12,30),Vector2(24,20)),Color(.55,.80,1,.85))
  node.draw_rect(Rect2(c-Vector2(10,4),Vector2(20,12)),Color(.22,.26,.34))
## 상점 앞면: 유리 + 따뜻한 불빛 + 차양 + 매달린 간판.
static func storefronts(node: Node2D) -> void:
 var shops=[
  {"rect":Rect2(1210,676,360,24),"name":"카페","accent":Color("ffcf8a"),"awning":Color("d9705a")},
  {"rect":Rect2(1600,676,300,24),"name":"베이커리","accent":Color("ffd9a0"),"awning":Color("7fb0d8")},
  {"rect":Rect2(2050,856,420,24),"name":"편의점","accent":Color("8fe3b0"),"awning":Color("5fb0a0")},
  {"rect":Rect2(2330,856,380,24),"name":"문구","accent":Color("ff9ee0"),"awning":Color("d888c0")},
  {"rect":Rect2(1210,856,300,24),"name":"약국","accent":Color("9fd6ff"),"awning":Color("6f9fd8")},
  {"rect":Rect2(2900,676,300,24),"name":"관리","accent":Color("9fc4ff"),"awning":Color("5d78a8")}]
 for shop in shops:
  var rect: Rect2=shop.rect
  var accent: Color=shop.accent
  # 유리창: 벽 안쪽에 따뜻한 불빛 + 진열 실루엣.
  var glass:=Rect2(rect.position+Vector2(4,8),Vector2(rect.size.x-8,rect.size.y+10))
  node.draw_rect(glass.grow(2),Color(.02,.03,.05,.95))
  node.draw_rect(glass,Color(accent.r*.35,accent.g*.35,accent.b*.35,.95))
  K.window_row(node,glass,accent,true,44.0)
  # 진열대 실루엣
  for i in range(int(glass.size.x/70.0)):
   var x:=glass.position.x+24.0+float(i)*70.0
   node.draw_rect(Rect2(x,glass.position.y+14,16,10),Color(.35,.22,.14,.75))
   node.draw_rect(Rect2(x+2,glass.position.y+8,8,6),Color(accent.r,accent.g,accent.b,.55))
  # 차양(벽 앞쪽으로 22px 튀어나온다)
  K.awning(node,Rect2(rect.position.x+2,rect.position.y+rect.size.y-2,rect.size.x-4,18),shop.awning,0.35)
  # 상점 간판: 차양 위 벽 띠에 붙는 파사드 간판(떠 있지 않다).
  var label:=String(shop.name)
  var width:=20.0+FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+18.0
  K.sign(node,Rect2(Vector2(rect.position.x+12,rect.position.y-2),Vector2(width,26)),label,Color(.06,.07,.10),Color(accent.r,accent.g,accent.b,.92),Color(1,.96,.86,.85),17)
## 사물 발밑 그림자 + 바닥에 놓인 정적 소품(그림자 레이어).
static func draw_prop_shadows(node: Node2D) -> void:
 for object in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(object.kind))
  var side: float=float(visual.get("shadow",10.0))
  node.draw_set_transform(object.p,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,side*1.4,Color(0,0,0,.34))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
