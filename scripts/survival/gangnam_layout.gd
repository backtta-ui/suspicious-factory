extends RefCounted
## 서울 강남역 · 2.5D 탑뷰 지하철역 맵 (2.0.34).
## 어몽어스식 시인성: 두꺼운 어두운 벽면 + 밝은 이동 바닥(대리석·타일·네온 라인).
## 모든 충돌·이동·둔갑·기믹 좌표가 이 한 파일에 있고,
## gangnam_world.gd는 같은 수치로 그림만 그린다(그림과 이동이 어긋나지 않는다).
##
## 구역: 강남역 출구 · 카페 · 지하상가/팝업존 · 자판기 코너 · 중앙 대합실 ·
##       관리실(CCTV) · 에스컬레이터홀 · 개찰구 · 승강장(스크린도어)
## 순환로: 큰 순환로 2(대합실을 감싸는 사각 링 / 승강장~개찰구~복도 링)
##         + 작은 순환로 3(카페 카운터·대합실 안내도·팝업존 스탤·관리실 콘솔 주변)
const MAP_ID="gangnam"
const NAME="서울 강남역"
const SIZE=Vector2(3400,2600)
const SPAWN=Vector2(1650,1330)
const CAMERA_ZOOM=1.90
const CAMERA_LIFT=36.0
## 벽 두께(그림·충돌 공통). 어몽어스처럼 두껍게 그린다.
const WALL=26.0
const OUTER=Rect2(80,110,3240,2380)
const PLAY=Rect2(110,140,3180,2320)
## ---- 안전구역(배틀로얄) 설정 ----------------------------------------
## 시작 원은 맵 네 모서리를 모두 포함하는 최소 반경(맵 중심에서 모서리까지).
const CIRCLE_CENTER_START=Vector2(1700,1300)
## 최종 원 중심은 반드시 '걸어 다닐 수 있는' 대합실 안쪽으로 둔다.
const CIRCLE_CENTER_FINAL=Vector2(1650,1300)
const CIRCLE_RADII=[2140.0,1760.0,1160.0,620.0]
const CIRCLE_DUE=[180.0,360.0,480.0,600.0]
const STAGE_0_RADIUS=2140.0
## ---- 구역 ------------------------------------------------------------
const ZONES=[
 {"id":"exit","name":"강남역 출구","rect":Rect2(150,150,850,550),"accent":Color("8fe3b0")},
 {"id":"cafe","name":"카페 구역","rect":Rect2(1180,150,920,550),"accent":Color("ffcf8a")},
 {"id":"control","name":"관리실 · CCTV","rect":Rect2(2280,150,970,550),"accent":Color("9fc4ff")},
 {"id":"vending","name":"자판기 코너","rect":Rect2(150,880,850,420),"accent":Color("7fe4d6")},
 {"id":"escalator","name":"에스컬레이터홀","rect":Rect2(150,1300,850,450),"accent":Color("c9b6ff")},
 {"id":"lobby","name":"중앙 대합실","rect":Rect2(1180,880,920,870),"accent":Color("ffe6b0")},
 {"id":"popup","name":"지하상가 · 팝업존","rect":Rect2(2280,880,970,870),"accent":Color("ff9ee0")},
 {"id":"gate","name":"개찰구","rect":Rect2(150,1930,3100,220),"accent":Color("9fd6ff")},
 {"id":"platform","name":"승강장 · 스크린도어","rect":Rect2(150,2150,3100,250),"accent":Color("a8f0d0")}]
## ---- 벽(충돌 + 그림) --------------------------------------------------
## 바깥 담장 4면.
const OUTER_WALLS=[Rect2(80,110,3240,26),Rect2(80,2464,3240,26),Rect2(80,110,26,2380),Rect2(3294,110,26,2380)]
## 가로 벽: RowA/복도1(700) · 복도1/RowB(880) · RowB/복도2(1750) ·
##          복도2/개찰구(1930) · 개찰구/승강장(2150) · 승강장/선로(2400)
const WALLS=[
 Rect2(150,700,230,26),Rect2(620,700,400,26),Rect2(1160,700,360,26),Rect2(1780,700,335,26),Rect2(2265,700,385,26),Rect2(2900,700,350,26),
 Rect2(150,880,180,26),Rect2(580,880,440,26),Rect2(1160,880,290,26),Rect2(1720,880,395,26),Rect2(2265,880,235,26),Rect2(2760,880,490,26),
 Rect2(150,1750,180,26),Rect2(580,1750,440,26),Rect2(1160,1750,260,26),Rect2(1700,1750,415,26),Rect2(2265,1750,285,26),Rect2(2820,1750,430,26),
 Rect2(150,1930,150,26),Rect2(520,1930,500,26),Rect2(1160,1930,120,26),Rect2(1720,1930,395,26),Rect2(2265,1930,495,26),Rect2(2980,1930,270,26),
 Rect2(150,2150,230,26),Rect2(700,2150,320,26),Rect2(1160,2150,90,26),Rect2(1850,2150,265,26),Rect2(2265,2150,335,26),Rect2(2900,2150,350,26),
 Rect2(150,2400,3100,20),
 ## 세로 벽 RowA(x=1000·1180·2100·2280) — 구역 사이 출입구를 남긴다.
 Rect2(1000,150,26,180),Rect2(1000,520,26,180),
 Rect2(1180,150,26,110),Rect2(1180,500,26,200),
 Rect2(2100,150,26,150),Rect2(2100,520,26,180),
 Rect2(2280,150,26,190),Rect2(2280,560,26,140),
 ## 세로 벽 RowB
 Rect2(1000,880,26,170),Rect2(1000,1250,26,200),Rect2(1000,1650,26,100),
 Rect2(1180,880,26,70),Rect2(1180,1150,26,230),Rect2(1180,1560,26,190),
 Rect2(2100,880,26,120),Rect2(2100,1220,26,280),Rect2(2100,1700,26,50),
 Rect2(2280,880,26,200),Rect2(2280,1300,26,220),Rect2(2280,1720,26,30),
 ## 자판기 코너 / 에스컬레이터홀 사이 벽
 Rect2(150,1300,150,26),Rect2(560,1300,440,26)]
## 가운데 섬(카운터·안내도·스탤·콘솔·승강장 기둥). 주위를 돌 수 있어 작은 순환로가 된다.
const ISLANDS=[
 Rect2(1450,250,280,100),Rect2(1440,1160,180,120),Rect2(2520,1120,260,120),Rect2(2720,280,240,110),
 Rect2(700,2230,70,70),Rect2(1800,2230,70,70),Rect2(2750,2230,70,70)]
## 선로(승강장 남쪽, 진입 차단). 스크린도어 벽(2400) 뒤라 걸어 들어갈 수 없다.
const TRACK=Rect2(150,2420,3100,44)
const LOW=[]
const BAMBOO=[]
const FURNITURE=[]
## ---- 둔갑 사물 ---------------------------------------------------------
## 강남역 전용 6종 + 기존 서원 사물 호환(항아리·상자 금지, 맵마다 프로퍼티로 일반화).
const OBJECTS=[
 # 강남역 출구
 {"kind":"luggage","p":Vector2(300,300)},{"kind":"luggage","p":Vector2(420,300)},
 {"kind":"banner","p":Vector2(300,430)},{"kind":"kiosk","p":Vector2(600,260)},
 {"kind":"vending","p":Vector2(860,300)},{"kind":"hydrant","p":Vector2(860,440)},
 {"kind":"iced_coffee","p":Vector2(250,640)},
 # 카페 구역
 {"kind":"iced_coffee","p":Vector2(1300,250)},{"kind":"iced_coffee","p":Vector2(1360,272)},
 {"kind":"iced_coffee","p":Vector2(2000,300)},{"kind":"banner","p":Vector2(1900,250)},
 {"kind":"luggage","p":Vector2(1900,600)},{"kind":"hydrant","p":Vector2(1300,620)},
 # 관리실
 {"kind":"hydrant","p":Vector2(2350,620)},{"kind":"banner","p":Vector2(3150,620)},
 {"kind":"kiosk","p":Vector2(2600,600)},{"kind":"banner","p":Vector2(3100,460)},
 # 자판기 코너
 {"kind":"iced_coffee","p":Vector2(700,1000)},{"kind":"hydrant","p":Vector2(860,1250)},
 {"kind":"luggage","p":Vector2(250,1250)},
 # 에스컬레이터홀
 {"kind":"banner","p":Vector2(300,1690)},{"kind":"luggage","p":Vector2(900,1690)},
 {"kind":"iced_coffee","p":Vector2(500,1660)},
 # 중앙 대합실
 {"kind":"kiosk","p":Vector2(1300,940)},{"kind":"banner","p":Vector2(2000,960)},
 {"kind":"luggage","p":Vector2(1300,1700)},{"kind":"hydrant","p":Vector2(1980,1700)},
 {"kind":"iced_coffee","p":Vector2(1300,1250)},{"kind":"iced_coffee","p":Vector2(2000,1300)},
 # 지하상가·팝업존
 {"kind":"banner","p":Vector2(2350,950)},{"kind":"banner","p":Vector2(3150,950)},
 {"kind":"luggage","p":Vector2(2350,1700)},{"kind":"luggage","p":Vector2(3150,1700)},
 {"kind":"kiosk","p":Vector2(3000,1300)},{"kind":"vending","p":Vector2(2400,1400)},
 # 개찰구
 {"kind":"hydrant","p":Vector2(400,2000)},{"kind":"banner","p":Vector2(900,2080)},
 {"kind":"banner","p":Vector2(2400,2080)},{"kind":"hydrant","p":Vector2(3000,2000)},
 {"kind":"iced_coffee","p":Vector2(560,2070)},
 # 승강장
 {"kind":"vending","p":Vector2(300,2320)},{"kind":"iced_coffee","p":Vector2(1200,2320)},
 {"kind":"luggage","p":Vector2(1500,2320)},{"kind":"iced_coffee","p":Vector2(2500,2320)},
 {"kind":"hydrant","p":Vector2(3100,2320)},{"kind":"banner","p":Vector2(2000,2330)}]
const FORMS={
 "iced_coffee":{"name":"아이스 커피컵","radius":5.0,"moving":false,"size":Vector2(16,26)},
 "vending":{"name":"음료 자판기","radius":12.0,"moving":false,"size":Vector2(34,52)},
 "kiosk":{"name":"무인 키오스크","radius":12.0,"moving":false,"size":Vector2(32,56)},
 "banner":{"name":"배너 입간판","radius":10.0,"moving":false,"size":Vector2(28,46)},
 "luggage":{"name":"캐리어·택배상자","radius":10.0,"moving":false,"size":Vector2(30,40)},
 "hydrant":{"name":"소화전","radius":8.0,"moving":false,"size":Vector2(22,34)},
 "delivery_robot":{"name":"배달 로봇","radius":8.0,"moving":true,"size":Vector2(28,26)},
 "kickboard":{"name":"공유 전동킥보드","radius":6.0,"moving":true,"size":Vector2(24,30)}}
## 둔갑 그림이 실제 사물과 100% 같은 크기가 되도록 한 값만 본다.
const FORM_VISUALS={
 "iced_coffee":{"height":44.0,"shadow":9.0},
 "vending":{"height":86.0,"shadow":22.0},
 "kiosk":{"height":92.0,"shadow":22.0},
 "banner":{"height":78.0,"shadow":16.0},
 "luggage":{"height":66.0,"shadow":18.0},
 "hydrant":{"height":56.0,"shadow":12.0},
 "delivery_robot":{"height":40.0,"shadow":10.0},
 "kickboard":{"height":48.0,"shadow":10.0}}
## ---- 기믹 6종 ----------------------------------------------------------
## kind: turnstile(개찰구) / escalator(에스컬레이터) / vending(자판기)
##       cctv(관리실 모니터) / light(조명 스위치) / shutter(팝업존 셔터)
const GIMMICKS=[
 {"id":"turnstile","kind":"turnstile","zone":"gate","pos":Vector2(1500,1930),
  "rect":Rect2(1280,1912,440,36),"label":"개찰구","hint":"도사가 지나가면 4초 잠깁니다"},
 {"id":"escalator","kind":"escalator","zone":"escalator","pos":Vector2(560,1520),
  "rect":Rect2(280,1380,560,280),"label":"에스컬레이터","hint":"작동 방향으로 타면 빨라집니다"},
 {"id":"vending_a","kind":"vending","zone":"vending","pos":Vector2(300,1000),"label":"자판기","hint":"눌러서 소음 파동을 냅니다"},
 {"id":"vending_b","kind":"vending","zone":"vending","pos":Vector2(430,1000),"label":"자판기","hint":"눌러서 소음 파동을 냅니다"},
 {"id":"vending_c","kind":"vending","zone":"vending","pos":Vector2(560,1000),"label":"자판기","hint":"눌러서 소음 파동을 냅니다"},
 {"id":"cctv","kind":"cctv","zone":"control","pos":Vector2(2840,430),"label":"CCTV 모니터","hint":"다른 구역을 실시간으로 감시합니다"},
 {"id":"light_cafe","kind":"light","zone":"cafe","pos":Vector2(1250,320),"label":"조명 스위치","hint":"도사는 끄고, 요괴는 다시 켭니다"},
 {"id":"light_lobby","kind":"light","zone":"lobby","pos":Vector2(1250,1000),"label":"조명 스위치","hint":"도사는 끄고, 요괴는 다시 켭니다"},
 {"id":"light_popup","kind":"light","zone":"popup","pos":Vector2(2340,1000),"label":"조명 스위치","hint":"도사는 끄고, 요괴는 다시 켭니다"},
 {"id":"light_platform","kind":"light","zone":"platform","pos":Vector2(1500,2205),"label":"조명 스위치","hint":"도사는 끄고, 요괴는 다시 켭니다"},
 {"id":"shutter","kind":"shutter","zone":"popup","pos":Vector2(2320,1620),
  "rect":Rect2(2266,1520,28,200),"label":"팝업존 셔터","hint":"5초 동안 시야와 통로를 막습니다"}]
## CCTV로 볼 수 있는 구역(누를 때마다 다음 구역으로 넘어간다).
const CCTV_ZONES=["lobby","cafe","platform","gate"]
## ---- 기력 구슬 ---------------------------------------------------------
const ORBS=[Vector2(400,790),Vector2(1090,600),Vector2(1500,790),Vector2(1980,790),
 Vector2(2190,760),Vector2(2700,790),Vector2(3000,790),Vector2(1090,1100),
 Vector2(1090,1450),Vector2(1090,1820),Vector2(2190,1000),Vector2(2190,1350),
 Vector2(2190,1700),Vector2(700,1840),Vector2(1500,1840),Vector2(2300,1840),
 Vector2(3000,1840),Vector2(700,2040),Vector2(2000,2040),Vector2(2900,2040),
 Vector2(1000,2270),Vector2(2200,2270)]
const ORB_RADIUS=22.0
const ORB_RESPAWN=14.0
## ---- 바닥 타일 안내선(그림·미니맵 공용) --------------------------------
const PATHS=[
 {"w":190.0,"p":[Vector2(170,790),Vector2(3230,790)]},
 {"w":190.0,"p":[Vector2(170,1840),Vector2(3230,1840)]},
 {"w":190.0,"p":[Vector2(1090,170),Vector2(1090,2380)]},
 {"w":190.0,"p":[Vector2(2190,170),Vector2(2190,2380)]},
 {"w":230.0,"p":[Vector2(170,2040),Vector2(3230,2040)]}]
## ---- 시작 지점 ---------------------------------------------------------
const DAOIST_SPAWN_POINTS=[Vector2(1620,1330),Vector2(1720,1420),Vector2(1560,1460),
 Vector2(1780,1290),Vector2(1650,1220),Vector2(1700,1520)]
const YOKAI_SPAWN_POINTS=[Vector2(360,2300),Vector2(3120,320)]
const SPAWN_SEPARATION=900.0
## ---- 움직이는 둔갑(배달 로봇·전동킥보드) 순찰로 -------------------------
const WALKER_ROUTES=[
 {"kind":"delivery_robot","speed":56.0,"path":[Vector2(1650,1050),Vector2(2000,1000),Vector2(2120,1080),
  Vector2(2190,950),Vector2(2190,800),Vector2(1950,790),Vector2(1450,790),Vector2(1500,860),
  Vector2(1520,1000),Vector2(1450,1120),Vector2(1560,1080)]},
 {"kind":"delivery_robot","speed":52.0,"path":[Vector2(1150,2000),Vector2(1500,2000),Vector2(1550,2060),Vector2(1450,2120),Vector2(1400,2200),Vector2(1300,2340),Vector2(900,2340),Vector2(500,2340),Vector2(430,2250),Vector2(460,2120),Vector2(380,2010),Vector2(520,1880),Vector2(900,1830),Vector2(1050,1930),Vector2(1100,2000)]},
 {"kind":"kickboard","speed":66.0,"path":[Vector2(2400,1000),Vector2(2650,950),Vector2(2950,980),
  Vector2(3130,1060),Vector2(3160,1320),Vector2(3100,1620),Vector2(2900,1710),Vector2(2600,1710),
  Vector2(2400,1650),Vector2(2330,1500),Vector2(2330,1300),Vector2(2330,1120)]},
 {"kind":"delivery_robot","speed":50.0,"path":[Vector2(1300,220),Vector2(1700,210),Vector2(2000,240),
  Vector2(2050,420),Vector2(2000,590),Vector2(1700,620),Vector2(1400,600),Vector2(1250,460),
  Vector2(1250,300)]}]
## ---- 레이아웃 스크립트 API ---------------------------------------------
const POND=Rect2(-600,-600,10,10)
const BRIDGE_A=Vector2.ZERO
const BRIDGE_B=Vector2.ZERO
const BRIDGE_HALF=0.0
const BRIDGE_RISE=0.0
const STONE=Rect2(1180,880,920,870)
const MEDALLION=Vector2(1650,1330)
const MEDALLION_RADIUS=120.0
const DOOR_WIDTH=0.0
const DOORS=[]
const BUILDINGS=[]
static var HARD: Array=_make_hard()
static var _spawn_cache: Dictionary={}
static func _make_hard() -> Array:
 var out: Array=[]
 out.append_array(OUTER_WALLS)
 out.append_array(WALLS)
 out.append_array(ISLANDS)
 out.append(TRACK)
 return out
static func map_id() -> String:return MAP_ID
static func map_name() -> String:return NAME
static func has_interiors() -> bool:return false
static func zones() -> Array:return ZONES
static func zone(id: String) -> Dictionary:
 for entry in ZONES:
  if String(entry.id)==id:return entry
 return {}
## 지금 서 있는 구역(가장 좁게 감싸는 구역). 복도는 gate/platform으로 이어진다.
static func zone_at(p: Vector2) -> Dictionary:
 for entry in ZONES:
  if (entry.rect as Rect2).has_point(p):return entry
 return {}
static func zone_name_at(p: Vector2) -> String:
 var entry:=zone_at(p)
 return String(entry.get("name","지하 복도"))
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
static func form_visual(kind: String) -> Dictionary:return FORM_VISUALS.get(kind,FORM_VISUALS.iced_coffee)
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
 if entry.is_empty():return "marble"
 return "tile"
## 하위 호환: 서원 전용 호출부가 있어도 터지지 않게 빈 값을 돌려준다.
static func HANOK() -> Rect2:return Rect2()
static func INTERIOR() -> Rect2:return Rect2()
static func FRONT_DOOR() -> Vector2:return SPAWN
