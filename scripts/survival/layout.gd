extends RefCounted
const SIZE=Vector2(1800,1400)
const SPAWN=Vector2(900,760)
const POND=Rect2(1190,940,300,180)
const LIBRARY=Rect2(310,270,300,260)
const ROOF_PATH=Rect2(1270,260,130,340)
const ROOMS=[LIBRARY,Rect2(760,220,300,210),Rect2(350,870,300,220)]
const NAMES=["서책고","강학당","학사동"]
const LOW=[Rect2(780,900,170,18),Rect2(1080,600,18,120),Rect2(220,690,180,18)]
const HARD=[Rect2(310,270,300,15),Rect2(310,270,15,260),Rect2(595,270,15,260),Rect2(310,515,115,15),Rect2(485,515,125,15),Rect2(760,220,300,15),Rect2(760,220,15,210),Rect2(1045,220,15,210),Rect2(760,415,110,15),Rect2(940,415,120,15),Rect2(350,870,300,15),Rect2(350,870,15,220),Rect2(635,870,15,220),Rect2(350,1075,115,15),Rect2(525,1075,125,15),Rect2(1270,260,12,300),Rect2(1388,260,12,300),Rect2(1270,260,130,12),Rect2(100,1180,570,18),Rect2(780,1180,300,18)]
const BAMBOO=[Rect2(1460,280,18,260),Rect2(1540,450,18,260),Rect2(1620,280,18,260)]
const OBJECTS=[{"kind":"jar","p":Vector2(660,570)},{"kind":"crate","p":Vector2(1130,800)},{"kind":"lantern","p":Vector2(430,650)},{"kind":"basket","p":Vector2(1080,1080)},{"kind":"jar","p":Vector2(500,380)},{"kind":"crate","p":Vector2(1430,800)}]
static func can_stand(p: Vector2,margin: float=9,jumping: bool=false) -> bool:
 if not p.is_finite() or not Rect2(Vector2(60,70),SIZE-Vector2(120,140)).grow(-margin).has_point(p):return false
 if POND.grow(margin).has_point(p):return false
 for rect in HARD+BAMBOO:
  if rect.grow(margin).has_point(p):return false
 if not jumping:
  for rect in LOW:
   if rect.grow(margin).has_point(p):return false
 return true
static func safe(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for radius in range(10,180,10):
  for i in range(16):
   var q:=p+Vector2.from_angle(i*TAU/16)*radius
   if can_stand(q):return q
 return SPAWN
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
  for rect in HARD+BAMBOO:
   if rect.has_point(p):return false
 return true
static func elevation(p: Vector2) -> float:
 if not ROOF_PATH.has_point(p):return 0.0
 return clampf((600-p.y)/90,0,1)*26
