class_name WooForestLayout
extends RefCounted
const SIZE=Vector2(1500,1080)
const SPAWN=Vector2(260,780)
const EXIT=Vector2(230,800)
const POND=Rect2(950,200,340,220)
const SHALLOWS=Rect2(945,402,350,38)
const ROAD=[Vector2(230,800),Vector2(500,670),Vector2(700,650),Vector2(900,550),Vector2(1180,620)]
const GOBLINS=[Vector2(610,570),Vector2(870,730),Vector2(1170,570)]
const BAMBOO=[Vector2(400,450),Vector2(480,350),Vector2(800,300),Vector2(730,430),Vector2(560,850),Vector2(1050,890),Vector2(1300,730)]
const LANTERNS=[Vector2(330,740),Vector2(650,710),Vector2(900,480),Vector2(1300,560)]
const ROCKS=[Vector3(560,400,28),Vector3(760,800,33),Vector3(1020,780,28),Vector3(1180,470,24),Vector3(420,560,23)]
static func can_stand(p: Vector2,margin: float=7) -> bool:
 if not is_finite(p.x) or not is_finite(p.y) or not Rect2(110+margin,170+margin,1280-margin*2,740-margin*2).has_point(p):return false
 if POND.grow(margin).has_point(p):return false
 for trunk in BAMBOO:
  if p.distance_to(trunk)<14+margin:return false
 for light in LANTERNS:
  if p.distance_to(light)<8+margin:return false
 for rock in ROCKS:
  if p.distance_to(Vector2(rock.x,rock.y))<rock.z+margin:return false
 return true
static func safe(p: Vector2) -> Vector2:return p if can_stand(p) else SPAWN
static func surface(p: Vector2) -> String:
 if SHALLOWS.has_point(p):return "water"
 if Rect2(160,755,140,90).has_point(p):return "wood"
 for i in range(ROAD.size()-1):
  var d:=p.distance_to(Geometry2D.get_closest_point_to_segment(p,ROAD[i],ROAD[i+1]))
  if d<35:return "stone"
  if d<62:return "dirt"
 return "grass"
