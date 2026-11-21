class_name WooTerrainSurface
extends RefCounted
## 2.0.37 바닥 재질 판정: 발소리(실제 CC0 녹음)를 재질별로 고르는 기준.
## 네 맵의 레이아웃이 이미 사물·충돌·기믹 좌표를 알고 있으므로, 재질도 같은 표를 본다.
## 돌려주는 값은 sound.gd의 STEP_LIBRARY 키와 정확히 같다:
## grass_dirt / stone / wood / tile_indoor / asphalt / sand / water / escalator / jar
const Layout=preload("res://scripts/woo/village_layout.gd")
const Seowon=preload("res://scripts/survival/layout.gd")
const Gangnam=preload("res://scripts/survival/gangnam_layout.gd")
const Haeundae=preload("res://scripts/survival/haeundae_layout.gd")
const Dongseongno=preload("res://scripts/survival/dongseongno_layout.gd")
const Forest=preload("res://scripts/woo/forest_layout.gd")
static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))
static func ellipse(p: Vector2,c: Vector2,r: Vector2) -> bool:
 return ((p-c)/r).length()<=1.0
static func at(p: Vector2,map_id: String="seowon") -> String:
 match map_id:
  "seowon":
   var surface: String=Seowon.surface(p)
   return "grass_dirt" if surface=="grass" or surface=="dirt" else surface
  "gangnam":
   for entry in Gangnam.GIMMICKS:
    if String(entry.kind)=="escalator" and (entry.rect as Rect2).has_point(p):return "escalator"
   return "tile_indoor"
  "haeundae":
   return "sand" if Haeundae.surface(p)=="sand" else "stone"
  "dongseongno":
   return "tile_indoor" if Dongseongno.surface(p)=="neon" else "asphalt"
  "fox_forest":
   var woods: String=Forest.surface(p)
   return "grass_dirt" if woods=="grass" or woods=="dirt" else woods
## 서원 이전 버전의 마을 map에서 쓰던 기본 판정(호환용).
 if map_id=="moon_palace":return "stone"
 if map_id=="red_sea":return "asphalt"
 if Rect2(1480,1274,440,52).has_point(p):return "stone"
 for area in [[Vector2(1080,650),Vector2(440,250)],[Vector2(1900,410),Vector2(390,190)],[Vector2(1850,910),Vector2(510,165)]]:
  if ellipse(p,area[0],area[1]):return "stone"
 for yard in Layout.SHOP_YARDS:
  if ellipse(p,yard,Vector2(105,58)) or segment_distance(p,yard,Vector2(yard.x,910))<19:return "stone"
 for prop in Layout.PROPS:
  if prop.kind in ["hanok","tavern","magic_shop","food","market"] and not prop.get("border",false) and ellipse(p,prop.position+Vector2(0,28),Vector2(82,32)):return "stone"
 for road in Layout.ROADS:
  for i in range(road.size()-1):
   if segment_distance(p,road[i],road[i+1])<34:return "stone"
 return "grass_dirt"
