extends RefCounted
## 서울 강남역 정적 배경(2.0.34): 어몽어스식 시인성.
## 바닥은 밝은 대리석·타일 + 노란 점자블록, 벽은 두껍고 어두운 남색 면 + 시안 네온 테두리.
## 모든 좌표는 gangnam_layout.gd를 그대로 쓰므로 그림과 충돌이 어긋나지 않는다.
const L=preload("res://scripts/survival/gangnam_layout.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const VOID=Color("05070d")
const FLOOR=Color("95a3b8")
const FLOOR_DARK=Color("93a2b8")
const CORRIDOR=Color("8899b0")
const TILE_LINE=Color(.26,.32,.42,.35)
const WALL_FILL=Color("151b29")
const WALL_TOP=Color("2b3650")
const WALL_EDGE=Color("05070d")
const NEON=Color("56e0ff")
const NEON_PINK=Color("ff5fa8")
const TACTILE=Color("ffd54a")
const TRACK=Color("0a0d16")
const RAIL=Color("4a5468")
static func shadow(node: Node2D,rect: Rect2,offset: Vector2,alpha: float=.42) -> void:
 node.draw_rect(Rect2(rect.position+offset,rect.size),Color(0,0,0,alpha))
## 바닥: 존별 타일 + 복도 + 점자블록 + 네온 인레이 + 구역 이름.
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-160,-160),L.SIZE+Vector2(320,320)),VOID)
 # 복도(가로·세로)를 먼저 깔고 그 위에 존 바닥을 얹는다.
 for path in L.PATHS:
  var w: float=float(path.w)
  var pts: Array=path.p
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var rect:=Rect2(Vector2(minf(a.x,b.x)-w*.5,minf(a.y,b.y)-w*.5),
    Vector2(absf(b.x-a.x)+w,absf(b.y-a.y)+w))
   node.draw_rect(rect,CORRIDOR)
   tile_lines(node,rect,90.0,Color(.34,.42,.54,.26))
   # 복도 중앙의 시안 네온 안내선
   node.draw_line(a,b,Color(.36,.88,1.0,.20),3.0,true)
 # 존 바닥: 구역마다 고유 색조를 섞어 한눈에 구역이 구분되게 한다.
 for zone in L.ZONES:
  var rect: Rect2=zone.rect
  var zone_accent: Color=zone.accent
  var floor_tone:=FLOOR.lerp(zone_accent,.30)
  node.draw_rect(rect,floor_tone)
  # 벽에 붙은 쪽은 어둡게(앰비언트 오클루전) — 어몽어스처럼 벽이 두껍고 바닥이 또렷하다.
  for side in [0,1,2,3]:
   var band_w:=54.0
   var shade:=Color(.03,.05,.09,.20)
   match side:
    0:node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,band_w)),shade)
    1:node.draw_rect(Rect2(Vector2(rect.position.x,rect.end.y-band_w),Vector2(rect.size.x,band_w)),shade)
    2:node.draw_rect(Rect2(rect.position,Vector2(band_w,rect.size.y)),shade)
    3:node.draw_rect(Rect2(Vector2(rect.end.x-band_w,rect.position.y),Vector2(band_w,rect.size.y)),shade)
  tile_lines(node,rect,110.0,Color(.24,.30,.40,.40))
  ## 2.0.34 피드백: 구역마다 은은한 조명 뎁스를 더해 바닥이 밋밋하지 않게 한다.
  ## 가운데는 밝고 가장자리는 어두워지며, 바닥 타일 색조가 구역 색을 머금는다.
  var center: Vector2=rect.get_center()
  var glow_radius: float=maxf(rect.size.x,rect.size.y)*.60
  for k in range(4):
   var t: float=float(k)/4.0
   node.draw_circle(center,glow_radius*(1.0-t),Color(zone_accent.r,zone_accent.g,zone_accent.b,.040*(1.0-t)),true,-1.0,true)
  for k2 in range(3):
   var inset: float=26.0+float(k2)*26.0
   node.draw_rect(rect.grow(-inset),Color(.02,.04,.08,.055),false,inset)
  var accent: Color=zone.accent
  # 존 경계의 옅은 네온 인레이
  node.draw_rect(rect.grow(-3),Color(zone_accent.r,zone_accent.g,zone_accent.b,.24),false,3.0)
  node.draw_rect(rect.grow(-9),Color(zone_accent.r,zone_accent.g,zone_accent.b,.09),false,1.0)
 # 승강장: 스크린도어 앞 노란 안전선 + 선로
 var platform:=Rect2(150,2150,3100,250)
 node.draw_rect(Rect2(150,2366,3100,6),Color(TACTILE.r,TACTILE.g,TACTILE.b,.85))
 node.draw_rect(Rect2(150,2380,3100,20),Color(TRACK.r,TRACK.g,TRACK.b,.9))
 node.draw_rect(Rect2(150,2420,3100,44),TRACK)
 for i in range(2):
  var y: float=2432.0+i*16.0
  node.draw_line(Vector2(160,y),Vector2(3240,y),RAIL,3.0)
 # 점자블록(노란 점선) — 복도 중심과 존 출입구를 잇는다.
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
    node.draw_rect(Rect2(p-Vector2(7,7),Vector2(14,14)),Color(TACTILE.r,TACTILE.g,TACTILE.b,.55))
 # 구역 이름(벽 위가 아니라 바닥 안쪽에 크게, 어몽어스식 표지판 느낌).
 for zone2 in L.ZONES:
  var rect2: Rect2=zone2.rect
  var label: String=String(zone2.name)
  var at:=rect2.position+Vector2(30,54)
  if String(zone2.id)=="gate":at=Vector2(rect2.position.x+2350,rect2.position.y+152)
  if String(zone2.id)=="platform":at=Vector2(rect2.position.x+2050,rect2.position.y+196)
  var width: float=26.0+label.length()*26.0
  # 2.0.36: 바닥 글씨가 벽에 반쯤 가려지지 않도록, 벽과 겹치면 아래/오른쪽으로 밀어낸다.
  for attempt in range(8):
   var box:=Rect2(at-Vector2(16,38),Vector2(width,58))
   var blocked:=false
   for wall in L.HARD:
    if (wall as Rect2).intersects(box):blocked=true;break
   if not blocked:break
   at+=Vector2(26 if attempt%2==0 else 0,30 if attempt%2==1 else 0)
  # 구역 밖으로 넘치지 않게
  at.x=clampf(at.x,rect2.position.x+20,rect2.end.x-width-10)
  at.y=clampf(at.y,rect2.position.y+70,rect2.end.y-20)
  node.draw_rect(Rect2(at-Vector2(16,38),Vector2(width,58)),Color(.03,.04,.08,.46))
  node.draw_rect(Rect2(at-Vector2(16,38),Vector2(width,58)),Color(zone2.accent.r,zone2.accent.g,zone2.accent.b,.45),false,2.0)
  node.draw_string(TITLE_FONT,at-Vector2(2,36),label,HORIZONTAL_ALIGNMENT_LEFT,-1,40,Color(0,0,0,.45))
  node.draw_string(TITLE_FONT,at-Vector2(4,40),label,HORIZONTAL_ALIGNMENT_LEFT,-1,38,Color(1,1,1,.95))
  node.draw_rect(Rect2(at-Vector2(16,38),Vector2(6,58)),zone2.accent)
## 타일 격자: 큰 사각 타일과 그 안의 미세 이음선.
static func tile_lines(node: Node2D,rect: Rect2,step: float,color: Color) -> void:
 var x: float=rect.position.x
 while x<rect.end.x:
  node.draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),color,1.0)
  x+=step
 var y: float=rect.position.y
 while y<rect.end.y:
  node.draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),color,1.0)
  y+=step
## 벽: 두꺼운 어두운 면 + 위쪽 밝은 상면 + 아래 그림자 + 시안 네온 테두리.
static func draw_walls(node: Node2D) -> void:
 for rect in L.HARD:
  shadow(node,rect,Vector2(0,10),.45)
 for island in L.ISLANDS:
  shadow(node,island,Vector2(0,8),.40)
 for island in L.ISLANDS:
  node.draw_rect(island.grow(3),Color(.06,.07,.11,.9))
  node.draw_rect(island,Color("c3cfdd"))
  node.draw_rect(Rect2(island.position,Vector2(island.size.x,6)),Color("e6eef8"))
  node.draw_rect(island,Color(.30,.38,.50,.85),false,2.0)
  node.draw_rect(island.grow(-6),Color(.42,.52,.66,.25),false,1.0)
 for rect in L.HARD:
  if L.ISLANDS.has(rect):continue
  # 두꺼운 벽면: 바깥 먹색 테두리 + 본체 + 밝은 상면(2.5D 두께감)
  node.draw_rect(rect.grow(11),Color(.02,.02,.04,.42))
  node.draw_rect(rect.grow(4),Color(.03,.04,.07,.75))
  node.draw_rect(rect,WALL_FILL)
  node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,11)),WALL_TOP)
  node.draw_rect(Rect2(Vector2(rect.position.x,rect.position.y+11),Vector2(rect.size.x,3)),Color(.06,.08,.13,.9))
  node.draw_rect(Rect2(rect.position,Vector2(5,rect.size.y)),Color(.09,.11,.17))
  node.draw_rect(Rect2(Vector2(rect.position.x,rect.end.y-4),Vector2(rect.size.x,4)),WALL_EDGE)
 for rect in L.HARD:
  if L.ISLANDS.has(rect):continue
  node.draw_rect(rect.grow(-1),Color(NEON.r,NEON.g,NEON.b,.34),false,2.0)
  node.draw_rect(Rect2(rect.position+Vector2(0,-1),Vector2(rect.size.x,2)),Color(.45,.85,1.0,.20))
## 정적 소품: 벤치·화분·안내 표지·바닥 화살표·출구 표지.
static func draw_decor(node: Node2D) -> void:
 # 벤치
 for spot in [Vector2(640,1210),Vector2(640,1390),Vector2(2680,640),Vector2(2250,760),Vector2(1450,2250),Vector2(2650,2080)]:
  node.draw_rect(Rect2(spot+Vector2(0,6),Vector2(120,34)),Color(0,0,0,.28))
  node.draw_rect(Rect2(spot-Vector2(60,18),Vector2(120,36)),Color("3c4a63"))
  node.draw_rect(Rect2(spot-Vector2(58,14),Vector2(116,12)),Color("7186a6"))
 # 화분
 for spot2 in [Vector2(1200,760),Vector2(2080,760),Vector2(2300,1000),Vector2(1180,1680),Vector2(2100,1620),Vector2(1700,700)]:
  node.draw_circle(spot2+Vector2(0,10),18,Color(0,0,0,.30))
  node.draw_rect(Rect2(spot2-Vector2(16,4),Vector2(32,26)),Color("5a4a3c"))
  node.draw_circle(spot2-Vector2(0,24),22,Color(.24,.46,.34,.95))
  node.draw_circle(spot2-Vector2(8,32),15,Color(.32,.58,.42,.92))
 # 바닥 유도 화살표
 for arrow in [[Vector2(1090,1200),PI*.5],[Vector2(2190,1500),PI*.5],[Vector2(1500,2040),0.0],[Vector2(2600,2040),PI]]:
  var at: Vector2=arrow[0]
  var angle: float=arrow[1]
  node.draw_set_transform(at,angle,Vector2(1,1))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-26,-12),Vector2(6,-12),Vector2(6,-24),Vector2(30,0),Vector2(6,24),Vector2(6,12),Vector2(-26,12)]),Color(1,1,1,.24))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 출구·승강장 안내 표지판
 for sign in [{"at":Vector2(470,180),"text":"3번 출구 EXIT","color":Color("8fe3b0")},
  {"at":Vector2(1730,180),"text":"카페 · CAFE","color":Color("ffcf8a")},
  {"at":Vector2(2860,180),"text":"관리실 · STAFF","color":Color("9fc4ff")},
  {"at":Vector2(1500,2170),"text":"승강장 PLATFORM","color":Color("a8f0d0")}]:
  var at2: Vector2=sign.at
  var text: String=sign.text
  var color: Color=sign.color
  node.draw_rect(Rect2(at2-Vector2(150,20),Vector2(300,44)),Color(.04,.06,.10,.72))
  node.draw_rect(Rect2(at2-Vector2(150,20),Vector2(300,44)),Color(color.r,color.g,color.b,.65),false,2.0)
  node.draw_string(FONT,at2-Vector2(140,10),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
## 목업 그림자(사물 발밑).
static func draw_prop_shadows(node: Node2D) -> void:
 for object in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(object.kind))
  var side: float=float(visual.get("shadow",10.0))
  node.draw_set_transform(object.p,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,side*1.4,Color(0,0,0,.34))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
