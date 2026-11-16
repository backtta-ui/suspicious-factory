class_name WooVillageLayout
extends RefCounted
const MAP_ID := "gyewol_village"
const REVISION := 3
const SIZE := Vector2(3400,1900)
# Keep the original entry and three villagers to preserve the player's bearings/save.
const SPAWN := Vector2(900,610)
const WELL := Vector2(860,510)
static var BOUNDS := PackedVector2Array([Vector2(68,480),Vector2(900,64),Vector2(2660,64),Vector2(3010,440),Vector2(3010,1320),Vector2(2700,1560),Vector2(600,1560),Vector2(68,1120)])
const ZONES := [
 {"id":"plaza","name":"중앙 벚꽃 광장","center":Vector2(1080,650),"color":Color("b89b9e")},
 {"id":"paintings","name":"신비로운 그림 장터","center":Vector2(1900,400),"color":Color("7977a6")},
 {"id":"shops","name":"조선 상점 거리","center":Vector2(1870,900),"color":Color("b3966d")},
 {"id":"garden","name":"벚꽃 정원과 연못","center":Vector2(1700,1300),"color":Color("628a78")},
 {"id":"training","name":"도술 수련소","center":Vector2(2640,400),"color":Color("a68c74")}
]
const PAINTINGS := [
 {"id":"fox_forest","name":"여우의 숲","position":Vector2(1690,340),"index":0,"intro":"안개 낀 대나무숲에서 여우의 발자취를 따라가는 이야기입니다.","status":"준비 중"},
 {"id":"magistrate","name":"탐관오리의 관아","position":Vector2(1900,320),"index":1,"intro":"경비병의 눈을 피해 관아에 숨겨진 진실을 찾는 이야기입니다.","status":"준비 중"},
 {"id":"goblin_night","name":"도깨비의 밤","position":Vector2(2110,340),"index":2,"intro":"붉은 달 아래 도깨비의 수수께끼를 풀어가는 이야기입니다.","status":"준비 중"}
]
const POND := Rect2(1480,1180,440,260)
const WATER_BLOCKS := [Rect2(1480,1180,440,94),Rect2(1480,1326,440,114)]
const ROADS := [
 [Vector2(900,610),Vector2(1190,680),Vector2(1460,900),Vector2(1840,900),Vector2(2260,900)],
 [Vector2(1080,650),Vector2(1080,1030),Vector2(1400,1300),Vector2(1980,1300),Vector2(2260,900)],
 [Vector2(1840,900),Vector2(1840,650),Vector2(1900,470),Vector2(2360,470),Vector2(2640,400)],
 [Vector2(900,610),Vector2(540,1000),Vector2(1080,1030)]
]
const SHOP_YARDS := [Vector2(1550,825),Vector2(1810,795),Vector2(2070,815),Vector2(2200,1085),Vector2(1930,1095),Vector2(1640,1095)]
const CORE_PROPS := [
 {"kind":"hanok","position":Vector2(710,350),"name":"달그림 다실"},
 {"kind":"hanok","position":Vector2(1330,440),"name":"마을 회관"},
 {"kind":"hanok","position":Vector2(680,730),"name":"벚꽃 사랑채"},
 {"kind":"hanok","position":Vector2(1400,720),"name":"서당"},
 {"kind":"market","position":Vector2(1260,540)},
 {"kind":"magic_shop","position":Vector2(1900,230),"name":"그림 보관소"},
 {"kind":"bench","position":Vector2(820,650)},
 {"kind":"bench","position":Vector2(1100,760)},
 {"kind":"cart","position":Vector2(1610,840)},
 {"kind":"jars","position":Vector2(1465,740)},
 {"kind":"jars","position":Vector2(1870,760)},
 {"kind":"market","position":Vector2(2240,720)},
 {"kind":"stone_lantern","position":Vector2(1575,420)},
 {"kind":"stone_lantern","position":Vector2(2225,420)},
 {"kind":"well","position":WELL},
 {"kind":"great_tree","position":Vector2(1050,600),"name":"천년 벚꽃나무"},
 {"kind":"lantern","position":Vector2(780,470)},
 {"kind":"lantern","position":Vector2(1030,450)},
 {"kind":"lantern","position":Vector2(900,700)},
 {"kind":"lantern","position":Vector2(1160,550)},
 {"kind":"lantern","position":Vector2(700,510)},
 {"kind":"tavern","position":Vector2(1550,780),"name":"달맞이 주막"},
 {"kind":"food","position":Vector2(1810,750),"name":"따끈한 먹거리"},
 {"kind":"magic_shop","position":Vector2(2070,770),"name":"금빛 부적방"},
 {"kind":"magic_shop","position":Vector2(2200,1040),"name":"도술 도구점","variant":1},
 {"kind":"tavern","position":Vector2(1930,1050),"name":"만복 잡화점","variant":1},
 {"kind":"hanok","position":Vector2(1640,1050),"name":"상단 창고","variant":1},
 {"kind":"pavilion","position":Vector2(1810,1530),"name":"달빛 정자"},
 {"kind":"bridge","position":Vector2(1700,1300)},
 {"kind":"shrine","position":Vector2(2760,460),"name":"도술 수련소"},
 {"kind":"dummy","position":Vector2(2580,380)},
 {"kind":"dummy","position":Vector2(2770,460)},
 {"kind":"dummy","position":Vector2(2570,540)},
 {"kind":"cart","position":Vector2(2150,1100)},
 {"kind":"jars","position":Vector2(1530,830)},
 {"kind":"jars","position":Vector2(1980,1080)},
 {"kind":"jars","position":Vector2(2120,800)},
 {"kind":"stone_lantern","position":Vector2(1380,1230)},
 {"kind":"stone_lantern","position":Vector2(1970,1370)},
 {"kind":"stone_lantern","position":Vector2(850,390)},
 {"kind":"stone_lantern","position":Vector2(990,390)},
 {"kind":"bamboo","position":Vector2(1440,1110)},
 {"kind":"bamboo","position":Vector2(2000,1440)},
 {"kind":"bamboo","position":Vector2(2840,580)}
]
static var PROPS: Array = build_props()
static func build_props() -> Array:
 var result: Array=CORE_PROPS.duplicate(true)
 for painting in PAINTINGS: result.append({"kind":"painting","position":painting.position,"variant":painting.index})
 for p in [Vector2(1570,510),Vector2(2230,530),Vector2(1690,890),Vector2(2210,930),Vector2(2080,590),Vector2(1350,1030),Vector2(1970,1180),Vector2(1460,1460)]:
  result.append({"kind":"lantern","position":p})
 for p in [Vector2(900,180),Vector2(820,230),Vector2(1270,340),Vector2(1360,420),Vector2(1470,510),Vector2(1490,600),Vector2(1390,940),Vector2(650,940),Vector2(500,650),Vector2(380,510),Vector2(510,380),Vector2(600,330),Vector2(1300,1140),Vector2(1350,1470),Vector2(2080,1510),Vector2(2140,1350),Vector2(1600,1540),Vector2(2900,1300),Vector2(2410,220),Vector2(2250,230),Vector2(1750,170),Vector2(1450,190),Vector2(600,1190),Vector2(780,1400)]:
  result.append({"kind":"tree","position":p})
 # A visible treeline outside the collision boundary closes every camera edge.
 for i in range(BOUNDS.size()):
  var a: Vector2=BOUNDS[i];var b: Vector2=BOUNDS[(i+1)%BOUNDS.size()]
  var n:=ceili(a.distance_to(b)/110)
  for j in range(n):
   var p:=a.lerp(b,float(j)/n)
   result.append({"kind":"tree","position":p,"border":true})
 return result
const NPCS := [
 {"id":"herbalist","role":"resident","patrol":[Vector2(930,660),Vector2(1130,730),Vector2(1270,650),Vector2(1080,850)],"name":"약초꾼 서연","position":Vector2(1020,630),"tint":Color.WHITE,"lines":["천년 벚꽃나무 아래에 오신 걸 환영해요.","남쪽 돌길을 따라가면 연못과 정자가 나와요. 다리는 건널 수 있어요."]},
 {"id":"merchant","role":"merchant","patrol":[Vector2(1190,620),Vector2(1300,615),Vector2(1240,690)],"name":"장돌뱅이 만복","position":Vector2(1085,620),"tint":Color.WHITE,"lines":["동쪽으로 길이 새로 열렸다네! 주막, 부적방, 잡화점도 구경하시게.","장터의 그림들은 아직 봉인이 풀리지 않았어. 준비가 되면 새로운 세계로 이어질 거야."]},
 {"id":"elder","role":"elder","patrol":[Vector2(770,570),Vector2(870,680),Vector2(990,720),Vector2(840,780)],"name":"마을 어른","position":Vector2(770,570),"tint":Color.WHITE,"lines":["이 벚꽃나무는 그림 속 이야기를 기억하지.","그림의 임무를 끝내면 금빛 기억이 하나씩 피어날 걸세. 아직은 그 날을 기다리고 있네."]},
 {"id":"keeper","role":"merchant","patrol":[Vector2(1750,460),Vector2(1900,440),Vector2(2050,465)],"name":"그림지기 연화","position":Vector2(1830,440),"tint":Color.WHITE,"variant":0,"lines":["여우의 숲, 탐관오리의 관아, 도깨비의 밤… 세 이야기가 잠들어 있어요.","그림에 다가가 소개를 읽어 보세요. 그림 속 임무는 아직 준비 중이에요."]},
 {"id":"innkeeper","role":"merchant","patrol":[Vector2(1510,865),Vector2(1620,890),Vector2(1580,920)],"name":"주모 단이","position":Vector2(1550,865),"tint":Color.WHITE,"variant":0,"lines":["달맞이 주막에 잘 오셨어요. 길이 넓어졌으니 잠깐 쉬어 가세요."]},
 {"id":"seller","role":"merchant","patrol":[Vector2(2010,870),Vector2(2130,870),Vector2(2060,940)],"name":"부적 상인","position":Vector2(2080,860),"tint":Color.WHITE,"variant":1,"lines":["붉은 먹으로 마음을 모으는 게 부적의 시작이지. 물건 판매는 아직 준비 중일세."]},
 {"id":"gardener","role":"resident","patrol":[Vector2(1400,1410),Vector2(1400,1280),Vector2(1280,1160),Vector2(1360,1490)],"name":"정원지기","position":Vector2(1400,1410),"tint":Color.WHITE,"variant":2,"lines":["이 돌다리는 건너도 되지만 연못으로 들어갈 수는 없네. 밤엔 반딧불이가 모이지."]},
 {"id":"master","role":"master","patrol":[Vector2(2650,360),Vector2(2650,480),Vector2(2510,460)],"name":"도술 스승","position":Vector2(2650,360),"tint":Color.WHITE,"variant":2,"lines":["이 수련 마당에선 항아리 둔갑을 익혀 보게.","분신술과 축지법을 익힐 자리는 비워 두었네. 지금은 아직 쓸 수 없는 도술일세."]}
]
static func footprint(kind: String) -> PackedVector2Array:
 if kind in ["hanok","tavern","magic_shop","shrine","pavilion"]: return PackedVector2Array([Vector2(-64,-20),Vector2(0,-52),Vector2(64,-20),Vector2(0,12)])
 if kind in ["market","food"]: return PackedVector2Array([Vector2(-44,-12),Vector2(0,-32),Vector2(44,-12),Vector2(0,8)])
 if kind=="painting": return PackedVector2Array([Vector2(-27,-8),Vector2(27,-8),Vector2(27,5),Vector2(-27,5)])
 return PackedVector2Array()
static func radius(kind: String) -> float:
 match kind:
  "well": return 18
  "great_tree": return 28
  "tree": return 9
  "bamboo": return 14
  "cart": return 17
  "bench": return 14
  "jars","dummy": return 10
  "bridge": return 0
 return 5
static func can_stand(p: Vector2, margin: float = 6) -> bool:
 if not is_finite(p.x) or not is_finite(p.y): return false
 for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
  if not Geometry2D.is_point_in_polygon(p+offset*margin,BOUNDS): return false
 for rect in WATER_BLOCKS:
  if rect.grow(margin).has_point(p): return false
 for prop in PROPS:
  var polygon:=footprint(prop.kind)
  if polygon.is_empty():
   var r:=radius(prop.kind)
   if r>0 and p.distance_to(prop.position)<r+margin:return false
  else:
   var local: Vector2=p-prop.position
   if Geometry2D.is_point_in_polygon(local,polygon):return false
   for i in range(polygon.size()):
    if local.distance_to(Geometry2D.get_closest_point_to_segment(local,polygon[i],polygon[(i+1)%polygon.size()]))<margin:return false
 return true
static func safe_position(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for r in range(16,257,16):
  for i in range(16):
   var candidate:=p+Vector2.from_angle(i*TAU/16)*r
   if can_stand(candidate):return candidate
 return SPAWN
static func zone_at(p: Vector2) -> String:
 var nearest:=0;var distance:=INF
 for i in range(ZONES.size()):
  var d:=p.distance_squared_to(ZONES[i].center)
  if d<distance:nearest=i;distance=d
 return ZONES[nearest].name
