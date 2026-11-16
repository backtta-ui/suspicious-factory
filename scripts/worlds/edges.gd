class_name WooTerrainEdges
extends RefCounted
# Deterministic edge dressing is baked once; no per-frame grass nodes or particles.
static func ribbon(c: Node2D,points: Array,width: float,rng: RandomNumberGenerator) -> void:
 for i in range(points.size()-1):
  var a: Vector2=points[i];var b: Vector2=points[i+1];var normal: Vector2=(b-a).normalized().orthogonal()
  var n:=ceili(a.distance_to(b)/9)
  c.draw_line(a,b,Color("666953"),width+18,true)
  for k in range(n+1):
   var center: Vector2=a.lerp(b,float(k)/maxi(1,n))
   for side in [-1,1]:
    var p: Vector2=center+normal*side*(width*.5+rng.randf_range(-4,14))
    c.draw_circle(p,rng.randf_range(2,5),Color("68705a").darkened(rng.randf()*.14))
    if k%2==0:
     c.draw_line(p,p+Vector2(-2,-rng.randf_range(2,6)),Color("778367"),1)
     c.draw_line(p+Vector2(2,0),p+Vector2(3,-3),Color("879074"),1)
static func lawn_border(c: Node2D,center: Vector2,radius: Vector2,rng: RandomNumberGenerator) -> void:
 for i in range(360):
  var angle:=i*TAU/360;var edge:=Vector2(cos(angle),sin(angle))
  var p:=center+edge*radius* rng.randf_range(.98,1.06)
  c.draw_circle(p,rng.randf_range(3,8),Color("777963").darkened(rng.randf()*.15))
  if i%2==0:c.draw_line(p,p+Vector2(-2,-4),Color("7c876c"),1)
