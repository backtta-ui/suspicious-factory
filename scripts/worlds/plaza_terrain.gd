class_name WooStoryTerrain
extends Node2D
## Offline material baking; runtime still uses one ground texture.
const GRASS=preload("res://assets/woo/v11/meadow.png")
const Layout=preload("res://scripts/worlds/plaza_layout.gd")
func _draw() -> void:draw_ground(self)
static func pave(c: Node2D,center: Vector2,r: Vector2,rng: RandomNumberGenerator,tint: Color) -> void:
 preload("res://scripts/worlds/edges.gd").lawn_border(c,center,r,rng)
 var outline:=PackedVector2Array()
 for i in range(64):outline.append(center+Vector2(cos(i*TAU/64),sin(i*TAU/64))*r)
 c.draw_colored_polygon(outline,tint.darkened(0.26))
 var row:=0
 for y in range(int(center.y-r.y),int(center.y+r.y),12):
  row+=1
  for x in range(int(center.x-r.x),int(center.x+r.x),23):
   var p:=Vector2(x+(row%2)*11+rng.randf_range(-5,5),y+rng.randf_range(-4,4))
   if ((p-center)/r).length()<0.97:
    stone(c,p,Vector2(rng.randf_range(10,13),rng.randf_range(5,7)),tint.darkened(rng.randf_range(0.0,0.12)))
static func draw_ground(c: Node2D) -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=1202026
 c.draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color("30464a"))
 for x in range(7):
  for y in range(4):c.draw_texture_rect(GRASS,Rect2(x*512,y*512,512,512),false,Color("b4b8a6"))
 for road in Layout.ROADS:
  preload("res://scripts/worlds/edges.gd").ribbon(c,road,90,rng)
  var points:=PackedVector2Array(road)
  c.draw_polyline(points,Color("7c7867"),90,true)
  c.draw_polyline(points,Color("9e927d"),68,true)
  for p in road:c.draw_circle(p,34,Color("9e927d"))
  for j in range(road.size()-1):
   var a: Vector2=road[j];var b: Vector2=road[j+1];var n:=ceili(a.distance_to(b)/14)
   var side: Vector2=(b-a).normalized().orthogonal()
   for k in range(n):
    for lane in [-1,0,1]:
     var p: Vector2=a.lerp(b,float(k)/n)+side*(lane*18+rng.randf_range(-3,3))
     stone(c,p,Vector2(rng.randf_range(7,11),rng.randf_range(4,7)),Color("b1a897").darkened(rng.randf()*0.18))
 # A continuous broad civic square replaces the former grass-centered paths.
 pave(c,Vector2(1080,650),Vector2(440,250),rng,Color("a29896"))
 pave(c,Vector2(1900,410),Vector2(390,190),rng,Color("898798"))
 pave(c,Vector2(1850,910),Vector2(510,165),rng,Color("a59a8b"))
 for yard in Layout.SHOP_YARDS:
  pave(c,yard,Vector2(105,58),rng,Color("b0a28f"))
  var access:=PackedVector2Array([yard,Vector2(yard.x,910)])
  c.draw_polyline(access,Color("8d8578"),38,true)
  var n:=ceili(absf(yard.y-910)/12)
  for i in range(n+1):
   var q: Vector2=yard.lerp(Vector2(yard.x,910),float(i)/maxi(n,1))
   for side in [-1,1]:stone(c,q+Vector2(side*8,0),Vector2(8,5),Color("aaa08d"))
 # Front yards and individual entrances make the old hanok part of the square.
 for prop in Layout.PROPS:
  if prop.kind in ["hanok","tavern","magic_shop","food","market"] and not prop.get("border",false):
   pave(c,prop.position+Vector2(0,28),Vector2(82,32),rng,Color("aaa194"))
 # Painting-market threshold and restrained traditional glyphs are baked.
 c.draw_arc(Vector2(1900,410),185,0.15,PI-0.15,64,Color("c4ac73"),2,true)
 for x in range(1610,2211,48):
  c.draw_polyline(PackedVector2Array([Vector2(x,505),Vector2(x+5,510),Vector2(x,515),Vector2(x-5,510),Vector2(x,505)]),Color("bba77a"),1)
 for p in [Vector2(700,870),Vector2(1260,855),Vector2(1480,655),Vector2(1360,1450),Vector2(2020,1480),Vector2(2380,650)]:
  for i in range(70):
   var q: Vector2=p+Vector2(rng.randfn()*24,rng.randfn()*13)
   c.draw_circle(q,1.4,Color("cb879d") if i%3 else Color("ead6af"))
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
 var poly:=PackedVector2Array([p+Vector2(-r.x,-1),p+Vector2(-r.x*.3,-r.y),p+Vector2(r.x*.8,-r.y*.6),p+Vector2(r.x,1),p+Vector2(r.x*.2,r.y),p+Vector2(-r.x*.9,r.y*.6)])
 c.draw_colored_polygon(poly,color)
 var edge:=poly.duplicate();edge.append(poly[0]);c.draw_polyline(edge,color.darkened(.32),.8,true)
 c.draw_line(p+Vector2(-r.x*.3,-r.y),p+Vector2(r.x*.8,-r.y*.6),color.lightened(.16),.7)
