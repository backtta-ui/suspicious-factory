class_name WooTerrain
extends Node2D
## Development-time ground renderer; gameplay loads baked chunks, not these draw calls.
const GRASS=preload("res://assets/woo/v11/meadow.png")
const Layout=preload("res://scripts/woo/village_layout.gd")
func _draw() -> void:
 draw_ground(self)
static func draw_ground(c: Node2D) -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=1102026
 c.draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color("30464a"))
 # A detailed small-scale material is repeated only as ground, not as a world image.
 var grass: Texture2D=GRASS
 for x in range(7):
  for y in range(4):
   c.draw_texture_rect(grass,Rect2(x*512,y*512,512,512),false,Color("b4b8a6"))
 # Separate region courtyards, connected by broad walkable paths.
 for zone in Layout.ZONES:
  var radius:=Vector2(240,150) if zone.id=="plaza" else Vector2(210,130)
  var polygon:=PackedVector2Array()
  for i in range(64):polygon.append(zone.center+Vector2(cos(i*TAU/64),sin(i*TAU/64))*radius)
  c.draw_colored_polygon(polygon,Color(zone.color,0.13))
 for road in Layout.ROADS:
  var points:=PackedVector2Array(road)
  c.draw_polyline(points,Color(0.52,0.43,0.32,0.22),96,true)
  c.draw_polyline(points,Color(0.58,0.49,0.37,0.55),72,true)
  c.draw_polyline(points,Color(0.60,0.54,0.46,0.45),52,true)
  for p in road:c.draw_circle(p,36,Color(0.58,0.49,0.37,0.3))
  for j in range(road.size()-1):
   var a: Vector2=road[j];var b: Vector2=road[j+1]
   var n:=ceili(a.distance_to(b)/13)
   var side: Vector2=(b-a).normalized().orthogonal()
   for k in range(n):
    for lane in [-1,0,1]:
     var p: Vector2=a.lerp(b,float(k)/n)+side*(lane*17+rng.randf_range(-3,3))+Vector2(rng.randf_range(-3,3),rng.randf_range(-3,3))
     stone(c,p,Vector2(rng.randf_range(6,10),rng.randf_range(3,6)),Color("9c9586").darkened(rng.randf()*0.2))
 # Central circular stone mosaic, offset irregular pavers and petal beds.
 var center:=Vector2(940,570)
 for r in range(25,211,14):
  var n:=int(r/3)
  for i in range(n):
   var angle:=i*TAU/n+float(r)*0.017
   stone(c,center+Vector2(cos(angle)*r,sin(angle)*r*0.65),Vector2(9,4),Color("ac9b9b").darkened(rng.randf()*0.2))
 for p in [Vector2(770,410),Vector2(1070,410),Vector2(825,660),Vector2(1020,665),Vector2(1350,1420),Vector2(2010,1460),Vector2(2470,580)]:
  for i in range(55):
   var q: Vector2=p+Vector2(rng.randfn()*20,rng.randfn()*10)
   c.draw_circle(q,1.3,Color("cb879d") if i%3 else Color("edd6b5"))
 for i in range(4000):
  var p:=Vector2(rng.randf_range(40,3360),rng.randf_range(40,1860))
  c.draw_line(p,p+Vector2(1,-rng.randf_range(2,4)),Color("6a805c"),1)
 # Rock edging, a fence and forest mark the actual collision perimeter.
 for i in range(Layout.BOUNDS.size()):
  var a: Vector2=Layout.BOUNDS[i];var b: Vector2=Layout.BOUNDS[(i+1)%Layout.BOUNDS.size()]
  var n:=ceili(a.distance_to(b)/28)
  for j in range(n):
   var p: Vector2=a.lerp(b,float(j)/n)
   stone(c,p,Vector2(12,6),Color("535e60"))
   if j%2==0:
    c.draw_line(p,p+Vector2(0,-14),Color("8c7a61"),3)
    c.draw_line(p+Vector2(0,-9),p+(b-a).normalized()*56+Vector2(0,-9),Color("8c7a61"),2)
static func stone(c: Node2D,p: Vector2,r: Vector2,color: Color) -> void:
 var poly:=PackedVector2Array([p+Vector2(-r.x,-1),p+Vector2(-r.x*0.3,-r.y),p+Vector2(r.x*0.8,-r.y*0.6),p+Vector2(r.x,1),p+Vector2(r.x*0.2,r.y),p+Vector2(-r.x*0.9,r.y*0.6)])
 c.draw_colored_polygon(poly,color)
 var edge:=poly.duplicate();edge.append(poly[0]);c.draw_polyline(edge,color.darkened(0.32),0.8,true)
 c.draw_line(p+Vector2(-r.x*0.3,-r.y),p+Vector2(r.x*0.8,-r.y*0.6),color.lightened(0.16),0.7)
