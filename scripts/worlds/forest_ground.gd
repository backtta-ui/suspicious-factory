## Offline terrain bake. Physical layout lives independently in forest_layout.gd.
extends Node2D
const Layout=preload("res://scripts/woo/forest_layout.gd")
const BRIDGE=preload("res://assets/woo/v11/stone_bridge.png")
const GRASS=preload("res://assets/woo/v11/meadow.png")
var rng:=RandomNumberGenerator.new()
func _draw() -> void:
 rng.seed=130031
 for x in range(6):
  for y in range(5):draw_texture_rect(GRASS,Rect2(x*512,y*512,512,512),false,Color(.42,.58,.63))
 draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color(.04,.08,.15,.23))
 for branch in Layout.BRANCHES:
  preload("res://scripts/worlds/edges.gd").ribbon(self,branch,50,rng)
  draw_line(branch[0],branch[1],Color("80766a"),50,true)
 preload("res://scripts/worlds/edges.gd").ribbon(self,Layout.ROAD,112,rng)
 for p in Layout.ROAD:draw_circle(p,56,Color("716c5c"))
 for i in range(Layout.ROAD.size()-1):
  draw_line(Layout.ROAD[i],Layout.ROAD[i+1],Color("716c5c"),112,true)
 for p in Layout.ROAD:draw_circle(p,35,Color("8a8174"))
 for i in range(Layout.ROAD.size()-1):draw_line(Layout.ROAD[i],Layout.ROAD[i+1],Color("8a8174"),69,true)
 for y in range(180,2000,10):
  for x in range(110,2890,14):
   var p:=Vector2(x+rng.randf_range(-4,4),y+rng.randf_range(-3,3))
   if Layout.surface(p)=="stone":
    var w:=rng.randf_range(9,14);var h:=rng.randf_range(5,8)
    var c:=Color("a49b85").darkened(rng.randf_range(0,.26))
    draw_colored_polygon(PackedVector2Array([p+Vector2(-w/2,-h/2+2),p+Vector2(w/2-2,-h/2),p+Vector2(w/2,h/2),p+Vector2(-w/2+2,h/2)]),c)
 draw_rect(Layout.NEW_POND.grow(8),Color("3d5e68"));draw_rect(Layout.NEW_POND,Color("294f68"))
 draw_texture_rect(BRIDGE,Rect2(1480,1062,580,94),false)
 draw_rect(Layout.POND.grow(8),Color("3d5e68"));draw_rect(Layout.POND,Color("294f68"));draw_rect(Layout.SHALLOWS,Color("497685"))
 draw_set_transform(Vector2(1200,245),0,Vector2(1,.38));draw_circle(Vector2.ZERO,22,Color(.75,.8,.95,.4));draw_set_transform(Vector2.ZERO)
 for i in range(12):
  var p:=Vector2(1550+(i%6)*80,970+floori(i/6.0)*270)
  draw_set_transform(p,0,Vector2(1,.5));draw_circle(Vector2.ZERO,10,Color("537e77"));draw_circle(Vector2(0,-3),3,Color("d2a1bc"));draw_set_transform(Vector2.ZERO)
 for i in range(35):
  var p:=Layout.POND.position+Vector2(rng.randf_range(12,320),rng.randf_range(12,205))
  draw_line(p,p+Vector2(rng.randf_range(6,22),0),Color(.48,.67,.73,.35),1)
 for r in Layout.ROCKS:
  var p:=Vector2(r.x,r.y);draw_set_transform(p,0,Vector2(1,.6));draw_circle(Vector2.ZERO,r.z+3,Color("253b43"));draw_circle(Vector2(0,-7),r.z,Color("64747c"));draw_line(Vector2(-r.z*.6,-9),Vector2(r.z*.4,-r.z*.65),Color("8f989d"),3);draw_set_transform(Vector2.ZERO)
 for y in range(757,842,9):draw_line(Vector2(160,y),Vector2(300,y),Color("7d6a62"),7)
 # Forest edge covers the full camera range; no void or missing tiles.
 for i in range(65):
  var p:=Vector2(rng.randf_range(0,3000),rng.randf_range(0,2160))
  if p.y>160 and p.y<2010 and p.x>100 and p.x<2900:continue
  draw_set_transform(p,0,Vector2(1,.52));draw_circle(Vector2.ZERO,rng.randf_range(35,85),Color("1e3842"));draw_set_transform(Vector2.ZERO)
