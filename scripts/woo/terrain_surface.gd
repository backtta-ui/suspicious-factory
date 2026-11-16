class_name WooTerrainSurface
extends RefCounted
const Layout=preload("res://scripts/woo/village_layout.gd")
static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))
static func ellipse(p: Vector2,c: Vector2,r: Vector2) -> bool:
 return ((p-c)/r).length()<=1.0
static func at(p: Vector2,map_id: String="gyewol_village") -> String:
 if map_id=="moon_palace":return "stone"
 if map_id=="red_sea":return "dirt"
 if map_id=="fox_forest":return preload("res://scripts/woo/forest_layout.gd").surface(p)
 # Match terrain.gd's actual baked paving and water.gd's STONE bridge.
 if Rect2(1480,1274,440,52).has_point(p):return "stone"
 for area in [[Vector2(1080,650),Vector2(440,250)],[Vector2(1900,410),Vector2(390,190)],[Vector2(1850,910),Vector2(510,165)]]:
  if ellipse(p,area[0],area[1]):return "stone"
 for yard in Layout.SHOP_YARDS:
  if ellipse(p,yard,Vector2(105,58)) or segment_distance(p,yard,Vector2(yard.x,910))<19:return "stone"
 for prop in Layout.PROPS:
  if prop.kind in ["hanok","tavern","magic_shop","food","market"] and not prop.get("border",false) and ellipse(p,prop.position+Vector2(0,28),Vector2(82,32)):return "stone"
 var dirt:=false
 for road in Layout.ROADS:
  for i in range(road.size()-1):
   var d:=segment_distance(p,road[i],road[i+1])
   if d<34:return "stone"
   if d<45:dirt=true
 return "dirt" if dirt else "grass"
