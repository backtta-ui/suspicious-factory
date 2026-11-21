extends RefCounted
## 부산 해운대 · 2.5D 탑뷰 해변 맵 (2.0.35).
## 비대칭 해안선: 큰 중앙 광장·분수대 없이
##  좌상단 전통시장/포장마차 좁은 골목 · 중앙 구남로 · 우측 서핑샵/샤워장,
##  하단~우측 곡선 백사장과 밤바다, 우측 돌출 동백섬(다리 + 해안 데크 2갈래 우회로).
## 모든 충돌·이동·둔갑·기믹 좌표가 이 한 파일에 있고 world는 같은 수치로 그림만 그린다.
const MAP_ID="haeundae"
const NAME="부산 해운대"
const SIZE=Vector2(3400,2600)
const SPAWN=Vector2(1690,790)
const CAMERA_ZOOM=1.90
const CAMERA_LIFT=36.0
const WALL=26.0
const OUTER=Rect2(80,110,3240,2380)
const PLAY=Rect2(110,140,3180,2320)
## ---- 안전구역(배틀로얄) ------------------------------------------------
const CIRCLE_CENTER_START=Vector2(1700,1300)
const CIRCLE_CENTER_FINAL=Vector2(1680,1180)
const CIRCLE_RADII=[2140.0,1760.0,1160.0,620.0]
const CIRCLE_DUE=[180.0,360.0,480.0,600.0]
const STAGE_0_RADIUS=2140.0
## ---- 구역 --------------------------------------------------------------
const ZONES=[
 {"id":"market","name":"전통시장 골목","rect":Rect2(170,170,860,520),"accent":Color("ffb46b")},
 {"id":"gunam","name":"구남로","rect":Rect2(1150,170,900,560),"accent":Color("7fd4ff")},
 {"id":"surf","name":"서핑샵 · 샤워장","rect":Rect2(2200,170,1030,520),"accent":Color("8ff0d8")},
 {"id":"promenade","name":"해변 산책로","rect":Rect2(170,860,900,440),"accent":Color("ffd9a0")},
 {"id":"food","name":"포장마차 먹자골목","rect":Rect2(1150,860,900,440),"accent":Color("ff9ecb")},
 {"id":"dongbaek","name":"동백섬","rect":Rect2(2700,960,500,500),"accent":Color("ff8a7a")},
 {"id":"beach","name":"백사장","rect":Rect2(170,1600,2260,800),"accent":Color("ffe8b0")},
 {"id":"seashore","name":"밤바다","rect":Rect2(2450,1640,780,760),"accent":Color("6fc8ff")}]
## 물놀이 구역(파도 경보 감속 대상).
const COASTAL_ZONES=["beach","seashore","dongbaek"]
## ---- 담장·건물(충돌 + 그림) --------------------------------------------
const OUTER_WALLS=[Rect2(80,110,3240,26),Rect2(80,2464,3240,26),Rect2(80,110,26,2380),Rect2(3294,110,26,2380)]
## 시장·상점·포장마차 건물. 좁은 골목(80~120px)이 미로를 만든다.
const BUILDINGS_RECTS=[
 # 좌상단 전통시장
 Rect2(200,190,190,150),Rect2(480,190,150,150),Rect2(700,190,200,200),Rect2(930,200,90,240),
 Rect2(200,430,220,140),Rect2(510,420,180,150),Rect2(790,440,230,130),
 Rect2(250,650,180,70),Rect2(600,650,220,70),
 # 구남로
 Rect2(1250,200,130,130),Rect2(1600,220,150,120),Rect2(1900,200,120,100),
 Rect2(1250,470,200,160),Rect2(1750,480,180,150),
 # 서핑샵·샤워장
 Rect2(2240,190,280,210),Rect2(2600,200,170,140),Rect2(2900,230,300,210),
 Rect2(2300,470,210,150),Rect2(2680,500,190,120),
 # 해변 산책로
 Rect2(200,900,240,200),Rect2(540,960,180,160),Rect2(860,900,140,180),
 # 포장마차 먹자골목
 Rect2(1180,890,260,200),Rect2(1580,940,220,140),Rect2(1900,880,150,180),
 # 중앙 우측 상가
 Rect2(2250,900,180,160),
 # 동백섬 건물
 Rect2(2880,1040,170,140),
 # 해변 산책로 상가(탈의실·매점·횟집)
 Rect2(280,1180,200,150),Rect2(760,1200,180,140),Rect2(1330,1170,250,190),
 Rect2(1830,1200,170,140),Rect2(2260,1180,180,140),
 # 백사장 바위·파라솔 하우스
 Rect2(900,1760,160,90),Rect2(1500,1860,120,80),Rect2(600,2120,140,90),Rect2(1900,2210,160,80)]
## 바다·물길(진입 차단). 동백섬을 둘러싸고 다리·데크 두 갈래만 남긴다.
const WATER=[
 Rect2(2560,960,140,200),Rect2(2560,1250,140,210),
 Rect2(2680,860,80,120),Rect2(2840,860,360,120),
 Rect2(2560,1460,340,140),Rect2(2980,1460,220,140),
 Rect2(3200,960,94,500),
 Rect2(2450,2050,780,350)]
## 밀물 때 잠기는 지름길(동백섬 서쪽 다리). 데크 두 갈래는 늘 열려 있다.
const TIDE_RECT=Rect2(2556,1160,150,90)
const TIDE_BRIDGE=Rect2(2560,1180,140,70)
## ---- 둔갑 사물 7종(전부 자유 이동) -------------------------------------
const OBJECTS=[
 # 전통시장 골목
 {"kind":"pocha_stall","p":Vector2(420,380)},{"kind":"plastic_chair","p":Vector2(470,405)},
 {"kind":"cooler","p":Vector2(660,300)},{"kind":"plastic_chair","p":Vector2(740,440)},
 {"kind":"pocha_stall","p":Vector2(240,620)},{"kind":"cooler","p":Vector2(320,600)},
 {"kind":"plastic_chair","p":Vector2(520,620)},{"kind":"beach_ball","p":Vector2(880,640)},
 # 구남로
 {"kind":"surfboard","p":Vector2(1180,380)},{"kind":"tube","p":Vector2(1420,340)},
 {"kind":"beach_ball","p":Vector2(1560,420)},{"kind":"cooler","p":Vector2(1700,430)},
 {"kind":"surfboard","p":Vector2(1880,420)},{"kind":"parasol","p":Vector2(1450,300)},
 # 서핑샵·샤워장
 {"kind":"surfboard","p":Vector2(2200,630)},{"kind":"tube","p":Vector2(2560,640)},
 {"kind":"cooler","p":Vector2(2850,640)},{"kind":"parasol","p":Vector2(3050,640)},
 {"kind":"plastic_chair","p":Vector2(2380,660)},{"kind":"beach_ball","p":Vector2(2640,640)},
 # 해변 산책로
 {"kind":"parasol","p":Vector2(300,850)},{"kind":"plastic_chair","p":Vector2(380,850)},
 {"kind":"cooler","p":Vector2(560,850)},{"kind":"surfboard","p":Vector2(760,850)},
 {"kind":"tube","p":Vector2(900,850)},{"kind":"pocha_stall","p":Vector2(480,1160)},
 # 포장마차 먹자골목
 {"kind":"pocha_stall","p":Vector2(1250,850)},{"kind":"plastic_chair","p":Vector2(1350,860)},
 {"kind":"pocha_stall","p":Vector2(1700,850)},{"kind":"cooler","p":Vector2(1860,850)},
 {"kind":"pocha_stall","p":Vector2(2180,850)},{"kind":"beach_ball","p":Vector2(2140,1240)},
 # 동백섬·중앙 상가
 {"kind":"parasol","p":Vector2(2760,1200)},{"kind":"plastic_chair","p":Vector2(2830,1230)},
 {"kind":"tube","p":Vector2(3120,1160)},{"kind":"cooler","p":Vector2(3080,1400)},
 {"kind":"surfboard","p":Vector2(2600,1180)},
 # 백사장
 {"kind":"parasol","p":Vector2(400,1720)},{"kind":"plastic_chair","p":Vector2(480,1740)},
 {"kind":"parasol","p":Vector2(760,1900)},{"kind":"tube","p":Vector2(820,1910)},
 {"kind":"beach_ball","p":Vector2(1050,1880)},{"kind":"parasol","p":Vector2(1180,1730)},
 {"kind":"plastic_chair","p":Vector2(1260,1750)},{"kind":"cooler","p":Vector2(1400,1900)},
 {"kind":"surfboard","p":Vector2(1700,1760)},{"kind":"beach_ball","p":Vector2(1820,1900)},
 {"kind":"parasol","p":Vector2(2050,1760)},{"kind":"plastic_chair","p":Vector2(2130,1780)},
 {"kind":"tube","p":Vector2(2180,1950)},{"kind":"cooler","p":Vector2(2250,2150)},
 {"kind":"beach_ball","p":Vector2(1000,2150)},{"kind":"parasol","p":Vector2(1350,2200)},
 {"kind":"plastic_chair","p":Vector2(1430,2220)},{"kind":"surfboard","p":Vector2(1650,2250)},
 {"kind":"tube","p":Vector2(2350,1750)},{"kind":"parasol","p":Vector2(2320,2250)},
 # 해안 산책로~백사장 사이 빈 구간을 채우는 해변 소품
 {"kind":"pocha_stall","p":Vector2(320,1400)},{"kind":"plastic_chair","p":Vector2(400,1430)},
 {"kind":"cooler","p":Vector2(620,1410)},{"kind":"parasol","p":Vector2(880,1400)},
 {"kind":"plastic_chair","p":Vector2(950,1430)},{"kind":"surfboard","p":Vector2(1230,1400)},
 {"kind":"tube","p":Vector2(1400,1430)},{"kind":"beach_ball","p":Vector2(1600,1400)},
 {"kind":"pocha_stall","p":Vector2(1820,1430)},{"kind":"cooler","p":Vector2(1980,1400)},
 {"kind":"plastic_chair","p":Vector2(2150,1420)},
 # 백사장 파라솔·튜브·공
 {"kind":"parasol","p":Vector2(340,1650)},{"kind":"cooler","p":Vector2(420,1670)},
 {"kind":"plastic_chair","p":Vector2(600,1640)},{"kind":"beach_ball","p":Vector2(700,1680)},
 {"kind":"tube","p":Vector2(880,1650)},{"kind":"surfboard","p":Vector2(1120,1640)},
 {"kind":"parasol","p":Vector2(1300,1660)},{"kind":"plastic_chair","p":Vector2(1380,1680)},
 {"kind":"cooler","p":Vector2(1580,1640)},{"kind":"beach_ball","p":Vector2(1680,1670)},
 {"kind":"parasol","p":Vector2(1900,1650)},{"kind":"tube","p":Vector2(2020,1670)},
 {"kind":"surfboard","p":Vector2(2220,1650)},
 {"kind":"parasol","p":Vector2(420,1870)},{"kind":"plastic_chair","p":Vector2(500,1890)},
 {"kind":"tube","p":Vector2(760,1880)},{"kind":"cooler","p":Vector2(1020,1890)},
 {"kind":"beach_ball","p":Vector2(1180,1890)},{"kind":"parasol","p":Vector2(1420,1870)},
 {"kind":"plastic_chair","p":Vector2(1420,1910)},{"kind":"surfboard","p":Vector2(1720,1860)},
 {"kind":"cooler","p":Vector2(1880,1890)},{"kind":"beach_ball","p":Vector2(2060,1870)},
 {"kind":"parasol","p":Vector2(320,2070)},{"kind":"tube","p":Vector2(560,2090)},
 {"kind":"cooler","p":Vector2(780,2070)},{"kind":"plastic_chair","p":Vector2(1080,2090)},
 {"kind":"parasol","p":Vector2(1280,2070)},{"kind":"beach_ball","p":Vector2(1520,2090)},
 {"kind":"surfboard","p":Vector2(1750,2070)},{"kind":"tube","p":Vector2(2000,2090)},
 {"kind":"cooler","p":Vector2(2200,2070)},
 {"kind":"parasol","p":Vector2(430,2290)},{"kind":"plastic_chair","p":Vector2(510,2310)},
 {"kind":"beach_ball","p":Vector2(880,2300)},{"kind":"tube","p":Vector2(1180,2290)},
 {"kind":"parasol","p":Vector2(1480,2310)},{"kind":"cooler","p":Vector2(1760,2290)},
 {"kind":"surfboard","p":Vector2(2020,2310)},
 # 서핑샵 앞
 {"kind":"surfboard","p":Vector2(2430,720)},{"kind":"tube","p":Vector2(2700,720)},
 {"kind":"cooler","p":Vector2(3000,720)},
 # 동백섬
 {"kind":"parasol","p":Vector2(2830,1100)},{"kind":"plastic_chair","p":Vector2(2760,1150)},
 {"kind":"tube","p":Vector2(3150,1100)},{"kind":"cooler","p":Vector2(3070,1270)},
 {"kind":"beach_ball","p":Vector2(2820,1350)}]
const FORMS={
 "parasol":{"name":"비치 파라솔","radius":10.0,"moving":true,"size":Vector2(36,36)},
 "tube":{"name":"튜브","radius":7.0,"moving":true,"size":Vector2(26,26)},
 "surfboard":{"name":"서핑보드","radius":6.0,"moving":true,"size":Vector2(24,40)},
 "cooler":{"name":"아이스박스","radius":8.0,"moving":true,"size":Vector2(26,26)},
 "pocha_stall":{"name":"포장마차 매대","radius":10.0,"moving":true,"size":Vector2(34,32)},
 "plastic_chair":{"name":"플라스틱 의자","radius":6.0,"moving":true,"size":Vector2(22,26)},
 "beach_ball":{"name":"비치볼","radius":5.0,"moving":true,"size":Vector2(20,20)}}
const FORM_VISUALS={
 "parasol":{"height":96.0,"shadow":26.0},
 "tube":{"height":30.0,"shadow":10.0},
 "surfboard":{"height":64.0,"shadow":12.0},
 "cooler":{"height":40.0,"shadow":12.0},
 "pocha_stall":{"height":66.0,"shadow":18.0},
 "plastic_chair":{"height":44.0,"shadow":10.0},
 "beach_ball":{"height":22.0,"shadow":6.0}}
## ---- 기믹 --------------------------------------------------------------
##  wave(파도 경보) tide(밀물) mist(샤워기 물안개) light(서핑샵 조명)
##  telescope(전망대 망원경) bell(포장마차 주문벨) lighthouse·tent(2프레임 연출)
const GIMMICKS=[
 {"id":"wave","kind":"wave","zone":"beach","pos":Vector2(1690,1600),
  "label":"파도 경보","hint":"주기적으로 해안가 이동이 느려집니다","period":26.0,"duration":6.0,"slow":0.74,
  "zones":["beach","seashore","dongbaek"]},
 {"id":"tide","kind":"tide","zone":"dongbaek","pos":Vector2(2630,1210),"rect":Rect2(2556,1160,150,90),
  "label":"밀물","hint":"다리 지름길이 잠깐 잠깁니다 · 데크 두 갈래로 우회","period":34.0,"duration":8.0},
 {"id":"mist","kind":"mist","zone":"surf","pos":Vector2(2210,540),"radius":250.0,
  "label":"샤워기 물안개","hint":"5초 동안 앞이 흐려집니다"}]
const CCTV_ZONES=[]
## ---- 기력 구슬 ----------------------------------------------------------
const ORBS=[Vector2(560,720),Vector2(1080,600),Vector2(1450,700),Vector2(1850,720),
 Vector2(2150,650),Vector2(2450,720),Vector2(2860,760),Vector2(3140,820),
 Vector2(1080,1050),Vector2(1080,1400),Vector2(2140,1020),Vector2(2140,1380),
 Vector2(300,1450),Vector2(700,1480),Vector2(1300,1500),Vector2(1900,1500),
 Vector2(2200,1560),Vector2(2600,1660),Vector2(3130,1680),
 Vector2(600,1700),Vector2(1200,1700),Vector2(1750,1700),Vector2(2300,1700),
 Vector2(1000,2000),Vector2(1600,2050),Vector2(2150,2050),Vector2(900,2300),
 Vector2(1500,2320),Vector2(2000,2320),Vector2(300,1900)]
const ORB_RADIUS=22.0
const ORB_RESPAWN=14.0
## ---- 바닥 안내선 --------------------------------------------------------
const PATHS=[
 {"w":230.0,"surface":"stone","p":[Vector2(170,790),Vector2(3230,790)]},
 {"w":170.0,"surface":"stone","p":[Vector2(1090,170),Vector2(1090,2400)]},
 {"w":170.0,"surface":"stone","p":[Vector2(2150,170),Vector2(2150,1560)]},
 {"w":260.0,"surface":"wood","p":[Vector2(170,1560),Vector2(2450,1560)]},
 {"w":150.0,"surface":"wood","p":[Vector2(2700,790),Vector2(2800,900),Vector2(2800,1040)]},
 {"w":150.0,"surface":"wood","p":[Vector2(2940,1440),Vector2(2940,1620)]}]
## ---- 시작 지점 ----------------------------------------------------------
const DAOIST_SPAWN_POINTS=[Vector2(1640,760),Vector2(1740,740),Vector2(1560,820),
 Vector2(1800,820),Vector2(1690,690),Vector2(1700,860)]
const YOKAI_SPAWN_POINTS=[Vector2(360,2350),Vector2(3150,780)]
const SPAWN_SEPARATION=900.0
## ---- 움직이는 둔갑(갈매기·꽃게) 순찰로 --------------------------------
const WALKER_ROUTES=[
 {"kind":"seagull","speed":62.0,"path":[Vector2(500,1680),Vector2(900,1690),Vector2(1300,1660),
  Vector2(1750,1690),Vector2(2150,1660),Vector2(2280,1750),Vector2(1900,1780),Vector2(1400,1760),
  Vector2(900,1700),Vector2(600,1740),Vector2(480,1720)]},
 {"kind":"seagull","speed":58.0,"path":[Vector2(2400,780),Vector2(2750,760),Vector2(2800,820),
  Vector2(2800,940),Vector2(2800,1000),Vector2(2760,1000),Vector2(2800,1100),Vector2(2800,1250),
  Vector2(2820,1400),Vector2(2900,1430),Vector2(3100,1430),Vector2(3160,1380),Vector2(3160,1150),
  Vector2(3160,1010),Vector2(3060,1000),Vector2(2950,1000),Vector2(2850,1000),Vector2(2760,1000),
  Vector2(2720,1210),Vector2(2600,1200),Vector2(2450,1200),Vector2(2340,1150),Vector2(2200,1050),
  Vector2(2200,960),Vector2(2260,860),Vector2(2400,780)]},
 {"kind":"crab","speed":44.0,"path":[Vector2(300,2080),Vector2(600,2040),Vector2(900,2050),
  Vector2(1050,2110),Vector2(980,2160),Vector2(820,2160),Vector2(760,2100),Vector2(500,2080)]},
 {"kind":"crab","speed":40.0,"path":[Vector2(2760,1210),Vector2(2900,1210),Vector2(2970,1210),
  Vector2(2980,1400),Vector2(2900,1420),Vector2(2820,1380),Vector2(2760,1300),Vector2(2740,1240)]}]
## ---- 레이아웃 API ------------------------------------------------------
const POND=Rect2(-900,-900,10,10)
const BRIDGE_A=Vector2.ZERO
const BRIDGE_B=Vector2.ZERO
const BRIDGE_HALF=0.0
const BRIDGE_RISE=0.0
const STONE=Rect2(0,0,0,0)
const MEDALLION=Vector2(1690,790)
const MEDALLION_RADIUS=0.0
const DOOR_WIDTH=0.0
const DOORS=[]
const BUILDINGS=[]
## 2.0.36 실제로 들어가는 실내 4곳: 겉만 있는 빈 상자를 없애고 앞문·뒷문이 있는 가게로 만든다.
const INTERIOR_DEFS=[
 {"id":"market_shop","name":"전통시장 상점","sub":"건어물과 그릇","rect":Rect2(700,190,200,200),"kind":"shop","accent":Color("ffb46b")},
 {"id":"food_house","name":"포장마차 식당","sub":"국수와 어묵","rect":Rect2(1180,890,260,200),"kind":"food","accent":Color("ff9ecb")},
 {"id":"surf_shop","name":"서핑샵","sub":"보드와 슈트","rect":Rect2(2240,190,280,210),"kind":"shop","accent":Color("8ff0d8")},
 {"id":"beach_store","name":"해변 매점","sub":"음료와 튜브","rect":Rect2(1330,1170,250,190),"kind":"shop","accent":Color("ffd9a0")}]
static var INTERIORS: Array=_make_interiors()
static var HARD: Array=_make_hard()
static var _spawn_cache: Dictionary={}
static func _make_interiors() -> Array:
 var out: Array=[]
 for spec in INTERIOR_DEFS:
  out.append(preload("res://scripts/survival/interiors.gd").make_entry(String(spec.id),String(spec.name),spec.rect as Rect2,String(spec.kind),spec.accent as Color,String(spec.get("sub",""))))
 return out
static func _make_hard() -> Array:
 var out: Array=[]
 out.append_array(OUTER_WALLS)
 var rooms:=_make_interiors()
 for rect in BUILDINGS_RECTS:
  var is_room:=false
  for entry in rooms:
   if (entry.rect as Rect2).is_equal_approx(rect):is_room=true;break
  if is_room:continue
  out.append(rect)
 for entry in rooms:preload("res://scripts/survival/interiors.gd").add_walls(out,entry)
 out.append_array(WATER)
 return out
static func map_id() -> String:return MAP_ID
static func map_name() -> String:return NAME
static func has_interiors() -> bool:return true
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
 return String(entry.get("name","해변 골목"))
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
static func buildings() -> Array:return INTERIORS
static func painted_door(id: String) -> Vector2:
 var entry:=building(id)
 return entry.get("painted_door",Vector2.ZERO) if not entry.is_empty() else Vector2.ZERO
static func building(id: String) -> Dictionary:
 for entry in INTERIORS:
  if String(entry.id)==id:return entry
 return {}
static func door(id: String) -> Dictionary:
 for entry in INTERIORS:
  for side in ["front","back"]:
   if String(entry.id)+":"+side==id:return {"id":id,"building":entry.id,"side":side,"center":entry.doors[side],"label":String(entry.name)+(" 정문" if side=="front" else " 뒷문")}
 return {}
static func building_doors(id: String) -> Array:
 var out: Array=[]
 for side in ["front","back"]:
  var entry:=door(id+":"+side)
  if not entry.is_empty():out.append(entry)
 return out
static func door_near(p: Vector2,distance: float=62.0) -> String:
 var best:="";var gap:=distance
 for entry in INTERIORS:
  for side in ["front","back"]:
   var center: Vector2=entry.doors[side]
   var d: float=p.distance_to(center)
   if d<gap:gap=d;best=String(entry.id)+":"+side
 return best
static func interior_at(p: Vector2,pad: float=10.0) -> Dictionary:
 for entry in INTERIORS:
  if (entry.interior as Rect2).grow(pad).has_point(p):return entry
 return {}
static func inside(p: Vector2) -> bool:return not interior_at(p).is_empty()
static func object_near(p: Vector2,distance: float=74.0) -> Dictionary:
 var best: Dictionary={};var gap:=distance
 for object in OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best=object
 return best
static func form(kind: String) -> Dictionary:return FORMS.get(kind,{})
static func form_visual(kind: String) -> Dictionary:return FORM_VISUALS.get(kind,FORM_VISUALS.beach_ball)
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
 if entry.is_empty():return "promenade"
 return "sand" if String(entry.id)in ["beach","seashore","dongbaek"] else "promenade"
static func HANOK() -> Rect2:return Rect2()
static func INTERIOR() -> Rect2:return Rect2()
static func FRONT_DOOR() -> Vector2:return SPAWN
