class_name WooExplorationMap
extends Node2D
const Layout=preload("res://scripts/worlds/layout.gd")
const ART=preload("res://assets/woo/worlds/props.png")
var staged_loading:=false
var build_budget:=preload("res://scripts/ui/build_budget.gd").new()
var build_ready:=false
var map_id:="moon_palace"
var clock:=0.0
var fx: Node2D
var progress:=0
var low_effects:=false
var use_baked_ground:=true
func _ready() -> void:
 build_budget.enabled=staged_loading;build_budget.slice_started=Time.get_ticks_usec()
 y_sort_enabled=true;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var ground_path: String="res://assets/woo/worlds/"+map_id+"_ground.png"
 if use_baked_ground and ResourceLoader.exists(ground_path):
  var ground:=Sprite2D.new();ground.texture=load(ground_path);ground.centered=false;ground.z_index=-100;add_child(ground)
 else:
  var floor_layer:=Node2D.new();floor_layer.z_index=-100;floor_layer.draw.connect(draw_floor.bind(floor_layer));add_child(floor_layer)
 var boundary:=StaticBody2D.new();boundary.collision_layer=1;boundary.collision_mask=2|4
 var points:=Layout.bounds(map_id)
 for i in range(points.size()):
  var shape:=SegmentShape2D.new();shape.a=points[i];shape.b=points[(i+1)%points.size()];var collider:=CollisionShape2D.new();collider.shape=shape;boundary.add_child(collider)
 add_child(boundary)
 var count:=0
 for object in Layout.objects(map_id):
  var body:=StaticBody2D.new();body.collision_layer=1;body.collision_mask=2|4;body.position=object.p;add_child(body)
  var collision:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Layout.footprint(object).size;collision.shape=shape;body.add_child(collision)
  var sprite:=Sprite2D.new();sprite.texture=ART;sprite.region_enabled=true;var cell:=Vector2(ART.get_width()/4.0,ART.get_height()/2.0);sprite.region_rect=Rect2(Vector2(object.index%4,floori(float(object.index)/4))*cell,cell);sprite.scale=Vector2.ONE*float(object.width)/cell.x;sprite.offset=Vector2(0,-cell.y*.36);body.add_child(sprite)
  count+=1
  await build_budget.checkpoint(get_tree())
 for p in ([Vector2(540,780),Vector2(1260,780),Vector2(700,480),Vector2(1100,480),Vector2(200,1000),Vector2(1600,1000)] if map_id=="moon_palace" else [Vector2(350,900),Vector2(600,650),Vector2(930,850),Vector2(980,460)]):
  var prop:=preload("res://scripts/woo/village_prop.gd").new();prop.kind="stone_lantern";prop.position=p;add_child(prop)
 fx=Node2D.new();fx.z_index=-90;fx.draw.connect(draw_motion.bind(fx));add_child(fx)
 build_ready=true
func _process(delta: float) -> void:
 if not build_ready:return
 clock+=delta
 if int(clock*(10 if low_effects else 20))!=int((clock-delta)*(10 if low_effects else 20)):fx.queue_redraw()
func draw_floor(c: Node2D) -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=2061116
 c.draw_rect(Rect2(Vector2(-180,-180),Layout.SIZE+Vector2(360,360)),Color("15283d") if map_id=="moon_palace" else Color("201c37"))
 if map_id=="red_sea":
  for y in range(0,1300,10):
   var color:=Color("28344b").lerp(Color("503147"),.4+.25*sin(y*.008))
   c.draw_rect(Rect2(0,y,1800,10),color)
  for i in range(3200):
   var p:=Vector2(rng.randf_range(900,1800),rng.randf_range(0,1300))
   c.draw_line(p,p+Vector2(rng.randf_range(3,16),0),Color(.49,.52,.65,.18),1)
  for y in range(270,1000,8):
   var x:=1320+sin(y*.11)*15;var w:=30+sin(y*.05)*24
   c.draw_line(Vector2(x-w,y),Vector2(x+w,y),Color(.78,.35,.43,.24),2)
 var border:=Layout.bounds(map_id);c.draw_colored_polygon(border,Color("686579") if map_id=="moon_palace" else Color("827478"))
 if map_id=="moon_palace":
  for y in range(120,1190,24):
   for x in range(80,1730,40):
    var p:=Vector2(x+(12 if y%48==0 else 0),y)+Vector2(rng.randf_range(-3,3),rng.randf_range(-2,2));preload("res://scripts/woo/terrain.gd").stone(c,p,Vector2(17,10),Color("96909b").darkened(rng.randf()*.15))
  for p in [Vector2(300,700),Vector2(1500,700)]:
   c.draw_rect(Rect2(p-Vector2(120,140),Vector2(240,280)),Color("344c4b"))
   for i in range(65):c.draw_circle(p+Vector2(rng.randf_range(-110,110),rng.randf_range(-130,130)),rng.randf_range(1,3),Color("a884a4"))
  c.draw_arc(Vector2(900,700),140,0,TAU,64,Color("baa980"),2)
 else:
  for i in range(2400):
   var p:=Vector2(rng.randf_range(80,1400),rng.randf_range(100,1200))
   if Geometry2D.is_point_in_polygon(p,border):c.draw_line(p,p+Vector2(rng.randf_range(2,8),1),Color("c2a6a0").darkened(rng.randf()*.3),1)
  for i in range(70):
   var p:=Vector2(360,1020).lerp(Vector2(780,380),float(i)/70)+Vector2(sin(i*.14)*100,0)
   preload("res://scripts/woo/terrain.gd").stone(c,p,Vector2(19,10),Color("867c81"))
 for site in Layout.sites(map_id):
  c.draw_arc(site.p,25,0,TAU,32,Color("c6b681"),2);c.draw_line(site.p-Vector2(10,0),site.p+Vector2(10,0),Color("9dd1e0"),2)
func draw_motion(c: Node2D) -> void:
 if map_id=="red_sea":
  # World-space local ripples. The walkable coast and its independent colliders stay fixed.
  for i in range(32):
   var y:=90+i*38.0
   for j in range(5):
    var x:=1130+j*130+sin(clock*.5+i)*9
    if Geometry2D.is_point_in_polygon(Vector2(x,y),Layout.bounds(map_id)):continue
    c.draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+35,y-3+sin(clock+i)*2),Vector2(x+70,y)]),Color(.64,.57,.69,.19+.08*sin(clock+i)),1)
  var shore:=Layout.bounds(map_id)
  for i in range(1,7):
   var a: Vector2=shore[i];var b: Vector2=shore[i+1]
   c.draw_line(a+Vector2(sin(clock+i)*4,0),b+Vector2(sin(clock+i+1)*4,0),Color(1,.79,.77,.4+.15*sin(clock*1.2+i)),3)
  c.draw_circle(Vector2(1320,250),65,Color(.85,.25,.28,.18));c.draw_circle(Vector2(1320,250),49,Color("c2676f"))
 else:
  for i in range(6 if low_effects else 18):
   var p:=Vector2(900,700)+Vector2(sin(clock*.2+i*2)*190,cos(clock*.3+i)*140);c.draw_circle(p,1.5,Color(.6,.78,1,.35))
