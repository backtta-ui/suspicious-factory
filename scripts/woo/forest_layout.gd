class_name WooForestLayout
extends RefCounted
const SIZE=Vector2(3000,2160)
const SPAWN=Vector2(260,780)
const EXIT=Vector2(230,800)
const POND=Rect2(950,200,340,220)
const SHALLOWS=Rect2(945,402,350,38)
const FINISH=Vector2(2680,1720)
const ZONES=[{"id":"entry","name":"안개 낀 숲 입구","center":Vector2(400,750)},{"id":"bamboo","name":"대나무숲","center":Vector2(1000,700)},{"id":"pond","name":"연못과 돌다리","center":Vector2(1700,1110)},{"id":"shrine","name":"오래된 사당","center":Vector2(2450,650)},{"id":"deep","name":"숲 깊은 곳","center":FINISH}]
const NEW_POND=Rect2(1510,920,520,420)
const WATER_BLOCKS=[Rect2(1510,920,520,160),Rect2(1510,1140,520,200)]
const LOOT=[{"id":"bamboo_chest","position":Vector2(1080,470),"item":"potion","amount":2,"name":"대나무숲 보물상자"},{"id":"pond_leaf","position":Vector2(2040,1380),"item":"leaf","amount":3,"name":"물가에 숨겨진 신비한 잎"},{"id":"shrine_seal","position":Vector2(2550,650),"item":"seal","amount":2,"name":"사당의 봉인된 물건"}]
const BRANCHES=[[Vector2(900,690),Vector2(1080,470)],[Vector2(2100,1100),Vector2(2040,1380)]]
const ROAD=[Vector2(230,800),Vector2(500,670),Vector2(700,650),Vector2(900,550),Vector2(1180,620),Vector2(1350,1100),Vector2(2100,1100),Vector2(2450,700),Vector2(2600,1250),Vector2(2680,1720)]
const GOBLINS=[Vector2(800,700),Vector2(2350,780),Vector2(2640,1650)]
const BAMBOO=[Vector2(400,450),Vector2(480,350),Vector2(800,300),Vector2(730,430),Vector2(560,850),Vector2(1050,890),Vector2(1300,730),Vector2(1420,650),Vector2(1450,1480),Vector2(2100,1450),Vector2(2320,1240),Vector2(2750,1000),Vector2(2500,1830),Vector2(2200,1670),Vector2(1900,660),Vector2(2700,1550)]
const TREES=[Vector2(1370,1320),Vector2(2130,1520),Vector2(2170,850),Vector2(2710,680)]
const LANTERNS=[Vector2(330,740),Vector2(650,710),Vector2(900,480),Vector2(1300,560)]
const ROCKS=[Vector3(560,400,28),Vector3(760,800,33),Vector3(1020,780,28),Vector3(1180,470,24),Vector3(420,560,23),Vector3(1500,800,30),Vector3(2200,600,28),Vector3(2730,1450,34),Vector3(2350,1720,25)]
static func can_stand(p: Vector2,margin: float=7) -> bool:
 if not is_finite(p.x) or not is_finite(p.y) or not Rect2(110+margin,170+margin,2780-margin*2,1820-margin*2).has_point(p):return false
 if POND.grow(margin).has_point(p):return false
 for block in WATER_BLOCKS:
  if block.grow(margin).has_point(p):return false
 if Rect2(2390,485,180,100).grow(margin).has_point(p):return false
 for tree in TREES:
  if p.distance_to(tree)<9+margin:return false
 for trunk in BAMBOO:
  if p.distance_to(trunk)<14+margin:return false
 for light in LANTERNS:
  if p.distance_to(light)<8+margin:return false
 for rock in ROCKS:
  if p.distance_to(Vector2(rock.x,rock.y))<rock.z+margin:return false
 return true
static func safe(p: Vector2) -> Vector2:return p if can_stand(p) else SPAWN
static func surface(p: Vector2) -> String:
 if Rect2(1510,1080,520,60).has_point(p):return "stone"
 if SHALLOWS.has_point(p):return "water"
 if Rect2(160,755,140,90).has_point(p):return "wood"
 for branch in BRANCHES:
  if p.distance_to(Geometry2D.get_closest_point_to_segment(p,branch[0],branch[1]))<25:return "dirt"
 for i in range(ROAD.size()-1):
  var d:=p.distance_to(Geometry2D.get_closest_point_to_segment(p,ROAD[i],ROAD[i+1]))
  if d<35:return "stone"
  if d<62:return "dirt"
 return "grass"

static func zone_at(p: Vector2) -> Dictionary:
 var chosen: Dictionary=ZONES[0];var distance:=INF
 for zone in ZONES:
  var d:=p.distance_squared_to(zone.center)
  if d<distance:distance=d;chosen=zone
 return chosen
