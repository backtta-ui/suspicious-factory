class_name WooTerrainSurface
extends RefCounted
const Layout=preload("res://scripts/woo/village_layout.gd")
static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))
static func at(p: Vector2,map_id: String="gyewol_village") -> String:
 if map_id=="fox_forest":return preload("res://scripts/woo/forest_layout.gd").surface(p)
 if Rect2(1625,1274,150,52).has_point(p):return "wood"
 for yard in Layout.SHOP_YARDS:
  if Rect2(yard-Vector2(72,12),Vector2(144,24)).has_point(p):return "wood"
 for zone in [Vector3(1080,650,440),Vector3(1900,400,390),Vector3(1870,900,510)]:
  if Vector2((p.x-zone.x)/zone.z,(p.y-zone.y)/(zone.z*.53)).length()<1:return "stone"
 for road in Layout.ROADS:
  for i in range(road.size()-1):
   if segment_distance(p,road[i],road[i+1])<40:return "stone"
 for yard in Layout.SHOP_YARDS:
  if p.distance_to(yard)<115:return "dirt"
 return "grass"
