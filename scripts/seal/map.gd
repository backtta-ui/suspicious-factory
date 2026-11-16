class_name SealMap
extends RefCounted
const Village=preload("res://scripts/woo/village_layout.gd")
const ALTAR=Vector2(1140,670)
const JAIL=Vector2(2380,1210)
const STATIONS=[Vector2(900,700),Vector2(1180,950),Vector2(1840,650),Vector2(2260,900),Vector2(2640,560),Vector2(1440,1300),Vector2(2200,1120),Vector2(780,980)]
static func safe(p: Vector2) -> Vector2:return Village.safe_position(p)
static var move_cache: Dictionary={}
static var sight_cache: Dictionary={}
static func can_stand(p: Vector2) -> bool:
 var cell:=Vector2i(floori(p.x/4),floori(p.y/4))
 if not move_cache.has(cell):move_cache[cell]=Village.can_stand(Vector2(cell)*4+Vector2(2,2),9)
 return move_cache[cell]
static func visible_cell(p: Vector2) -> bool:
 var cell:=Vector2i(floori(p.x/4),floori(p.y/4))
 if not sight_cache.has(cell):sight_cache[cell]=Village.can_stand(Vector2(cell)*4+Vector2(2,2),3)
 return sight_cache[cell]
static func line(a: Vector2,b: Vector2) -> bool:
 var n:=maxi(1,ceili(a.distance_to(b)/8))
 for i in range(1,n):
  if not visible_cell(a.lerp(b,float(i)/n)):return false
 return true
static func move(from: Vector2,to: Vector2) -> Vector2:
 var distance:=from.distance_to(to);var n:=maxi(1,ceili(distance/3))
 var current:=from
 var step: Vector2=(to-from)/n
 for i in range(n):
  var next:=current+step
  if can_stand(next):current=next
  elif can_stand(Vector2(next.x,current.y)):current.x=next.x
  elif can_stand(Vector2(current.x,next.y)):current.y=next.y
  else:break
 return current
