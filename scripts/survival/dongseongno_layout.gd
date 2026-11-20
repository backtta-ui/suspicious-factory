extends RefCounted
## 대구 동성로 · 2.5D 탑뷰 도심 번화가 맵 (2.0.35).
## 큰 중앙 원형 광장 없이 불규칙한 도심 격자 골목 미로:
##  좌상단 별빛랜드(대관람차) · 하단 반월당 지하상가 출입구 · 아케이드 쇼핑거리 ·
##  떡볶이/납작만두 먹자골목 · 네컷/오락실 교차 골목.
## 상표권 안전: 실제 상호 대신 패러디 명칭(별빛랜드·도술네컷)만 쓴다.
const MAP_ID="dongseongno"
const NAME="대구 동성로"
const SIZE=Vector2(3400,2600)
const SPAWN=Vector2(1600,1400)
const CAMERA_ZOOM=1.90
const CAMERA_LIFT=36.0
const WALL=26.0
const OUTER=Rect2(80,110,3240,2380)
const PLAY=Rect2(110,140,3180,2320)
## ---- 안전구역(배틀로얄) ------------------------------------------------
const CIRCLE_CENTER_START=Vector2(1700,1300)
const CIRCLE_CENTER_FINAL=Vector2(1660,1420)
const CIRCLE_RADII=[2140.0,1760.0,1160.0,620.0]
const CIRCLE_DUE=[180.0,360.0,480.0,600.0]
const STAGE_0_RADIUS=2140.0
## ---- 구역 --------------------------------------------------------------
const ZONES=[
 {"id":"sparkland","name":"별빛랜드","rect":Rect2(170,170,860,520),"accent":Color("ff9ee0")},
 {"id":"arcade","name":"아케이드 쇼핑거리","rect":Rect2(1140,170,920,520),"accent":Color("8ff0ff")},
 {"id":"food","name":"먹자골목","rect":Rect2(2170,170,1060,520),"accent":Color("ffb46b")},
 {"id":"shopping","name":"쇼핑거리","rect":Rect2(170,850,860,520),"accent":Color("c9b6ff")},
 {"id":"fourcut","name":"도술네컷 교차골목","rect":Rect2(1140,850,920,520),"accent":Color("ffd166")},
 {"id":"arcadehall","name":"오락실 골목","rect":Rect2(2170,850,1060,520),"accent":Color("7fe4d6")},
 {"id":"busking","name":"버스킹 거리","rect":Rect2(1700,1450,900,450),"accent":Color("ff8a7a")},
 {"id":"banwoldang","name":"반월당 지하상가","rect":Rect2(1140,1900,600,450),"accent":Color("9fc4ff")},
 {"id":"backalley","name":"뒷골목","rect":Rect2(170,1450,600,900),"accent":Color("b8c0d8")}]
## ---- 담장·건물(충돌 + 그림) --------------------------------------------
const OUTER_WALLS=[Rect2(80,110,3240,26),Rect2(80,2464,3240,26),Rect2(80,110,26,2380),Rect2(3294,110,26,2380)]
const BUILDINGS_RECTS=[
 # 좌측 열(별빛랜드·쇼핑·뒷골목)
 Rect2(190,200,250,160),Rect2(510,190,230,170),Rect2(810,200,190,160),
 Rect2(190,440,220,200),Rect2(480,430,250,190),Rect2(800,450,200,190),
 Rect2(190,930,250,200),Rect2(510,900,210,250),Rect2(790,930,210,190),
 Rect2(190,1210,180,180),Rect2(440,1190,250,200),Rect2(760,1200,240,190),
 Rect2(190,1580,280,190),Rect2(540,1570,230,230),Rect2(850,1600,150,190),
 Rect2(190,1900,230,200),Rect2(500,1880,250,220),Rect2(820,1950,180,170),
 Rect2(190,2210,280,150),Rect2(540,2200,240,150),
 # 중앙 열(아케이드·네컷·반월당)
 Rect2(1150,200,250,170),Rect2(1470,190,210,180),Rect2(1750,200,300,170),
 Rect2(1150,470,230,190),Rect2(1450,460,250,190),Rect2(1760,470,290,180),
 Rect2(1150,900,250,180),Rect2(1470,880,230,200),Rect2(1770,900,280,190),
 Rect2(1150,1160,220,180),Rect2(1440,1140,260,200),Rect2(1770,1150,280,180),
 Rect2(1150,1580,230,190),Rect2(1450,1560,230,230),Rect2(1750,1590,290,190),
 Rect2(1150,1900,240,180),Rect2(1470,1890,240,200),Rect2(1790,1900,250,180),
 Rect2(1150,2170,290,160),Rect2(1510,2180,230,150),
 # 우측 열(먹자골목·오락실·버스킹)
 Rect2(2190,200,250,180),Rect2(2510,190,220,180),Rect2(2800,200,380,170),
 Rect2(2190,470,220,180),Rect2(2480,460,250,190),Rect2(2800,470,390,180),
 Rect2(2190,900,240,190),Rect2(2500,880,240,200),Rect2(2810,900,370,190),
 Rect2(2190,1180,230,180),Rect2(2490,1170,250,180),Rect2(2810,1170,370,190),
 Rect2(2190,1600,250,190),Rect2(2510,1580,210,240),Rect2(2800,1620,390,190),
 Rect2(2190,1900,250,190),Rect2(2510,1880,210,220),Rect2(2800,1950,390,160),
 Rect2(2190,2200,270,160),Rect2(2530,2200,250,150),Rect2(2850,2180,330,170)]
## ---- 둔갑 사물 6종(전부 자유 이동) -------------------------------------
const OBJECTS=[
 # 별빛랜드
 {"kind":"neon_sign","p":Vector2(470,390)},{"kind":"shopping_bags","p":Vector2(770,400)},
 {"kind":"neon_sign","p":Vector2(240,400)},{"kind":"claw_machine","p":Vector2(1040,300)},
 # 아케이드 쇼핑거리
 {"kind":"photobooth","p":Vector2(1110,420)},{"kind":"neon_sign","p":Vector2(1420,400)},
 {"kind":"claw_machine","p":Vector2(1720,420)},{"kind":"shopping_bags","p":Vector2(2100,300)},
 # 먹자골목
 {"kind":"tteokbokki_stall","p":Vector2(2160,420)},{"kind":"tteokbokki_stall","p":Vector2(2450,400)},
 {"kind":"speaker","p":Vector2(2765,395)},{"kind":"neon_sign","p":Vector2(3200,400)},
 # 쇼핑거리
 {"kind":"claw_machine","p":Vector2(450,1430)},{"kind":"shopping_bags","p":Vector2(710,1430)},
 {"kind":"photobooth","p":Vector2(260,1440)},{"kind":"neon_sign","p":Vector2(1020,1160)},
 # 도술네컷 교차골목
 {"kind":"photobooth","p":Vector2(1420,1110)},{"kind":"photobooth","p":Vector2(1960,870)},
 {"kind":"neon_sign","p":Vector2(1110,1110)},{"kind":"shopping_bags","p":Vector2(1670,1420)},
 # 오락실 골목
 {"kind":"claw_machine","p":Vector2(2440,1110)},{"kind":"claw_machine","p":Vector2(2760,860)},
 {"kind":"neon_sign","p":Vector2(2230,1400)},{"kind":"speaker","p":Vector2(3220,1400)},
 # 버스킹 거리
 {"kind":"speaker","p":Vector2(1740,1420)},{"kind":"shopping_bags","p":Vector2(1820,1460)},
 {"kind":"speaker","p":Vector2(2260,1460)},{"kind":"tteokbokki_stall","p":Vector2(2640,1460)},
 {"kind":"photobooth","p":Vector2(1960,1850)},
 # 반월당 지하상가
 {"kind":"neon_sign","p":Vector2(1120,1860)},{"kind":"claw_machine","p":Vector2(1450,1860)},
 {"kind":"shopping_bags","p":Vector2(1760,1860)},{"kind":"photobooth","p":Vector2(1900,2100)},
 {"kind":"speaker","p":Vector2(1430,2130)},
 # 뒷골목
 {"kind":"neon_sign","p":Vector2(230,1560)},{"kind":"speaker","p":Vector2(510,1550)},
 {"kind":"claw_machine","p":Vector2(820,1860)},{"kind":"photobooth","p":Vector2(460,2130)},
 {"kind":"shopping_bags","p":Vector2(820,2150)},{"kind":"neon_sign","p":Vector2(1000,2210)},
 # 골목 사이 대로
 {"kind":"tteokbokki_stall","p":Vector2(1110,760)},{"kind":"speaker","p":Vector2(1420,760)},
 {"kind":"shopping_bags","p":Vector2(2060,760)},{"kind":"neon_sign","p":Vector2(2160,760)},
 {"kind":"claw_machine","p":Vector2(2750,760)},{"kind":"speaker","p":Vector2(3200,760)},
 {"kind":"tteokbokki_stall","p":Vector2(1110,1450)},{"kind":"neon_sign","p":Vector2(2160,1450)}]
const FORMS={
 "photobooth":{"name":"네컷 포토부스","radius":10.0,"moving":true,"size":Vector2(34,34)},
 "claw_machine":{"name":"인형뽑기 기계","radius":10.0,"moving":true,"size":Vector2(32,36)},
 "tteokbokki_stall":{"name":"떡볶이 매대","radius":10.0,"moving":true,"size":Vector2(34,30)},
 "neon_sign":{"name":"네온 입간판","radius":7.0,"moving":true,"size":Vector2(24,30)},
 "speaker":{"name":"버스킹 스피커","radius":7.0,"moving":true,"size":Vector2(22,30)},
 "shopping_bags":{"name":"쇼핑백 더미","radius":7.0,"moving":true,"size":Vector2(26,26)}}
const FORM_VISUALS={
 "photobooth":{"height":76.0,"shadow":20.0},
 "claw_machine":{"height":84.0,"shadow":20.0},
 "tteokbokki_stall":{"height":64.0,"shadow":18.0},
 "neon_sign":{"height":58.0,"shadow":12.0},
 "speaker":{"height":52.0,"shadow":10.0},
 "shopping_bags":{"height":38.0,"shadow":10.0}}
## ---- 기믹 --------------------------------------------------------------
##  flash(도술네컷 플래시) claw(인형뽑기 소음) speaker(버스킹 발소리 교란)
##  shutter(아케이드 셔터) smoke(환풍기 연기) + 별빛랜드·네온 2프레임 연출
const GIMMICKS=[
 {"id":"flash","kind":"flash","zone":"fourcut","pos":Vector2(1440,1120),"radius":280.0,
  "label":"도술네컷","hint":"플래시가 터지면 근처 요괴가 1초 눈부십니다"},
 {"id":"claw","kind":"claw","zone":"arcadehall","pos":Vector2(2450,1100),"radius":280.0,
  "label":"인형뽑기","hint":"동전을 넣으면 소음이 퍼집니다"},
 {"id":"speaker","kind":"speaker","zone":"busking","pos":Vector2(2050,1420),"radius":300.0,
  "label":"버스킹 스피커","hint":"일정 범위의 발소리를 교란합니다"},
 {"id":"shutter","kind":"shutter","zone":"arcadehall","pos":Vector2(2436,1260),"rect":Rect2(2424,1160,24,200),
  "label":"아케이드 셔터","hint":"5초 동안 통로를 막습니다"},
 {"id":"smoke","kind":"smoke","zone":"food","pos":Vector2(2500,780),"radius":230.0,
  "label":"먹자골목 환풍기","hint":"연기가 시야를 막습니다"},
 {"id":"sparkland","kind":"wheel","zone":"sparkland","pos":Vector2(420,170),
  "label":"별빛랜드 대관람차","hint":"조명이 돌아갑니다"},
 {"id":"arcadegate","kind":"arcade_gate","zone":"arcade","pos":Vector2(1600,185),
  "label":"아케이드 게이트","hint":"네온 아치가 맥동합니다"},
 {"id":"stairs","kind":"stairs","zone":"banwoldang","pos":Vector2(1270,1870),
  "label":"반월당 지하상가","hint":"지하상가로 내려가는 계단"},
 {"id":"neon","kind":"neon","zone":"shopping","pos":Vector2(470,1420),
  "label":"네온 입간판","hint":"불빛이 맥동합니다"}]
const CCTV_ZONES=[]
## ---- 기력 구슬 ----------------------------------------------------------
const ORBS=[Vector2(470,660),Vector2(780,700),Vector2(1100,400),Vector2(1420,700),
 Vector2(2060,400),Vector2(2210,700),Vector2(2700,700),Vector2(3250,700),
 Vector2(1090,1000),Vector2(1090,1350),Vector2(1420,1420),Vector2(2060,1000),
 Vector2(2720,1400),Vector2(3250,1000),Vector2(470,1460),Vector2(1090,1850),
 Vector2(1420,1850),Vector2(2060,1850),Vector2(1090,2250),Vector2(2060,2250),
 Vector2(2720,1850),Vector2(3250,2250),Vector2(495,2300),Vector2(700,1830),
 Vector2(1600,2380),Vector2(2495,2320),Vector2(2600,1550),Vector2(3250,1600),
 Vector2(1435,1050),Vector2(755,1050)]
const ORB_RADIUS=22.0
const ORB_RESPAWN=14.0
## ---- 바닥 안내선 --------------------------------------------------------
const PATHS=[
 {"w":200.0,"p":[Vector2(170,760),Vector2(3230,760)]},
 {"w":190.0,"p":[Vector2(170,1450),Vector2(3230,1450)]},
 {"w":170.0,"p":[Vector2(1090,170),Vector2(1090,2400)]},
 {"w":170.0,"p":[Vector2(2140,170),Vector2(2140,2400)]},
 {"w":190.0,"p":[Vector2(170,2050),Vector2(1090,2050)]}]
## ---- 시작 지점 ----------------------------------------------------------
const DAOIST_SPAWN_POINTS=[Vector2(1560,1400),Vector2(1660,1360),Vector2(1500,1470),
 Vector2(1700,1460),Vector2(1600,1380),Vector2(1620,1520)]
const YOKAI_SPAWN_POINTS=[Vector2(320,2410),Vector2(3240,320)]
const SPAWN_SEPARATION=900.0
## ---- 움직이는 둔갑(인형탈·배달카트) 순찰로 ----------------------------
const WALKER_ROUTES=[
 {"kind":"mascot","speed":62.0,"path":[Vector2(1200,760),Vector2(1550,780),Vector2(1900,760),
  Vector2(2080,760),Vector2(2080,900),Vector2(2080,1400),Vector2(1900,1440),Vector2(1500,1460),
  Vector2(1090,1430),Vector2(1090,1100),Vector2(1120,900)]},
 {"kind":"delivery_cart","speed":66.0,"path":[Vector2(2210,760),Vector2(2600,760),Vector2(3100,760),
  Vector2(3250,860),Vector2(3250,1400),Vector2(3100,1450),Vector2(2600,1450),Vector2(2210,1450),
  Vector2(2150,1450),Vector2(2150,1100),Vector2(2170,900)]},
 {"kind":"mascot","speed":58.0,"path":[Vector2(1110,1850),Vector2(1400,1850),Vector2(1750,1850),
  Vector2(2060,1850),Vector2(2100,2100),Vector2(1800,2160),Vector2(1470,2160),Vector2(1110,2100),
  Vector2(1090,1980)]},
 {"kind":"delivery_cart","speed":60.0,"path":[Vector2(300,1520),Vector2(700,1490),Vector2(1000,1520),
  Vector2(1050,1700),Vector2(1050,1900),Vector2(1050,2100),Vector2(1000,2180),Vector2(1050,2100),
  Vector2(1050,1900),Vector2(1050,1700),Vector2(1000,1520),Vector2(700,1490)]}]
## ---- 레이아웃 API ------------------------------------------------------
const POND=Rect2(-900,-900,10,10)
const BRIDGE_A=Vector2.ZERO
const BRIDGE_B=Vector2.ZERO
const BRIDGE_HALF=0.0
const BRIDGE_RISE=0.0
const STONE=Rect2(0,0,0,0)
const MEDALLION=Vector2(1600,1400)
const MEDALLION_RADIUS=0.0
const DOOR_WIDTH=0.0
const DOORS=[]
const BUILDINGS=[]
static var HARD: Array=_make_hard()
static var _spawn_cache: Dictionary={}
static func _make_hard() -> Array:
 var out: Array=[]
 out.append_array(OUTER_WALLS)
 out.append_array(BUILDINGS_RECTS)
 return out
static func map_id() -> String:return MAP_ID
static func map_name() -> String:return NAME
static func has_interiors() -> bool:return false
static func zones() -> Array:return ZONES
static func zone(id: String) -> Dictionary:
 for entry in ZONES:
  if String(entry.id)==id:return entry
 return {}
static func zone_at(p: Vector2) -> Dictionary:
 for entry in ZONES:
  if (entry.rect as Rect2).has_point(p):return entry
 return {}
static func zone_name_at(p: Vector2) -> String:
 var entry:=zone_at(p)
 return String(entry.get("name","동성로 골목"))
static func zone_rect(id: String) -> Rect2:
 var entry:=zone(id)
 return entry.rect if not entry.is_empty() else Rect2()
static func gimmicks() -> Array:return GIMMICKS
static func walker_routes() -> Array:return WALKER_ROUTES
static func circle_radii() -> Array:return CIRCLE_RADII
static func circle_due() -> Array:return CIRCLE_DUE
static func circle_center_start() -> Vector2:return CIRCLE_CENTER_START
static func circle_final_center() -> Vector2:
 return CIRCLE_CENTER_FINAL if can_stand(CIRCLE_CENTER_FINAL,12) else safe(CIRCLE_CENTER_FINAL)
static func corner_radius() -> float:
 return Vector2(SIZE.x*.5,SIZE.y*.5).length()
static func buildings() -> Array:return BUILDINGS
static func painted_door(_id: String) -> Vector2:return Vector2.ZERO
static func building(_id: String) -> Dictionary:return {}
static func door(_id: String) -> Dictionary:return {}
static func building_doors(_id: String) -> Array:return []
static func door_near(_p: Vector2,_distance: float=62.0) -> String:return ""
static func interior_at(_p: Vector2,_pad: float=10.0) -> Dictionary:return {}
static func inside(_p: Vector2) -> bool:return false
static func object_near(p: Vector2,distance: float=74.0) -> Dictionary:
 var best: Dictionary={};var gap:=distance
 for object in OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best=object
 return best
static func form(kind: String) -> Dictionary:return FORMS.get(kind,{})
static func form_visual(kind: String) -> Dictionary:return FORM_VISUALS.get(kind,FORM_VISUALS.shopping_bags)
static func bridge_axis() -> Vector2:return Vector2.RIGHT
static func bridge_length() -> float:return 0.0
static func bridge_local(_p: Vector2) -> Dictionary:return {"t":99.0,"offset":999.0}
static func on_bridge(_p: Vector2,_margin: float=0.0) -> bool:return false
static func bridge_height(_t: float) -> float:return 0.0
static func elevation(_p: Vector2) -> float:return 0.0
static func can_stand(p: Vector2,margin: float=9,jumping: bool=false) -> bool:
 if not p.is_finite() or not PLAY.grow(-margin).has_point(p):return false
 for rect in HARD:
  if (rect as Rect2).grow(margin).has_point(p):return false
 return true
static func safe(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for radius in range(10,240,10):
  for i in range(16):
   var q:=p+Vector2.from_angle(i*TAU/16)*radius
   if can_stand(q):return q
 return SPAWN
static func _settle(candidates: Array,keep: Array=[]) -> Array:
 var out: Array=[]
 for candidate in candidates:
  var spot:=safe(candidate)
  for attempt in range(24):
   var clear:=true
   for other in out+keep:
    if spot.distance_to(other)<46:clear=false;break
   if clear:break
   spot=safe(spot+Vector2.from_angle(attempt*TAU/16+0.4)*(28.0+attempt*6.0))
  out.append(spot)
 return out
static func daoist_spawns() -> Array:
 if not _spawn_cache.has("daoist"):_spawn_cache["daoist"]=_settle(DAOIST_SPAWN_POINTS)
 return _spawn_cache["daoist"]
static func yokai_spawns() -> Array:
 if not _spawn_cache.has("yokai"):
  var daoists:=daoist_spawns()
  var out: Array=[]
  for candidate in YOKAI_SPAWN_POINTS:
   var spot:=safe(candidate)
   for attempt in range(40):
    var near:=false
    for daoist in daoists:
     if spot.distance_to(daoist)<SPAWN_SEPARATION:near=true;break
    if not near:break
    var away: Vector2=spot-SPAWN
    if away.length()<1.0:away=Vector2(1,0)
    spot=safe(spot+away.normalized()*(40.0+attempt*10.0))
   out.append(spot)
  _spawn_cache["yokai"]=_settle(out,daoists)
 return _spawn_cache["yokai"]
static func spawns_for(role: String,index: int) -> Vector2:
 var spots: Array=daoist_spawns() if role=="daoist" else yokai_spawns()
 if spots.is_empty():return safe(SPAWN)
 return spots[posmod(index,spots.size())]
static func move(a: Vector2,b: Vector2,jumping: bool=false) -> Vector2:
 var steps:=maxi(1,ceili(a.distance_to(b)/4));var delta: Vector2=(b-a)/steps;var p:=a
 for i in range(steps):
  var next:=p+delta
  if can_stand(next,9,jumping):p=next
  elif can_stand(Vector2(next.x,p.y),9,jumping):p.x=next.x
  elif can_stand(Vector2(p.x,next.y),9,jumping):p.y=next.y
 return p
static func line(a: Vector2,b: Vector2) -> bool:
 var n:=maxi(1,ceili(a.distance_to(b)/8))
 for i in range(n+1):
  var p:=a.lerp(b,float(i)/n)
  for rect in HARD:
   if (rect as Rect2).has_point(p):return false
 return true
static func path_gap(p: Vector2) -> float:
 var best:=1e9
 for path in PATHS:
  var half: float=float(path["w"])*.5
  var pts: Array=path["p"]
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var ab:=b-a
   var length_sq:=ab.length_squared()
   var t: float=0.0
   if length_sq>.0001:t=clampf((p-a).dot(ab)/length_sq,0.0,1.0)
   best=minf(best,p.distance_to(a+ab*t)-half)
 return best
static func surface(p: Vector2) -> String:
 var entry:=zone_at(p)
 if entry.is_empty():return "asphalt"
 return "neon" if String(entry.id) in ["arcade","fourcut","arcadehall"] else "asphalt"
static func HANOK() -> Rect2:return Rect2()
static func INTERIOR() -> Rect2:return Rect2()
static func FRONT_DOOR() -> Vector2:return SPAWN
