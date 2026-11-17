class_name WooStoryForest
extends Node2D
const Layout=preload("res://scripts/woo/forest_layout.gd")
const Prop=preload("res://scripts/woo/village_prop.gd")
var staged_loading:=false
var build_budget:=preload("res://scripts/ui/build_budget.gd").new()
var build_ready:=false
var atmosphere: Node2D
var navigation:=AStarGrid2D.new()
func _ready() -> void:
 build_budget.enabled=staged_loading;build_budget.slice_started=Time.get_ticks_usec()
 navigation.region=Rect2i(0,0,94,68);navigation.cell_size=Vector2(32,32);navigation.offset=Vector2(16,16);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 for y in range(68):
  for x in range(94):navigation.set_point_solid(Vector2i(x,y),not Layout.can_stand(Vector2(x*32+16,y*32+16),17))
  await build_budget.checkpoint(get_tree())
 y_sort_enabled=true;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var backdrop:=Polygon2D.new();backdrop.polygon=PackedVector2Array([Vector2(-16,-16),Vector2(3016,-16),Vector2(3016,2176),Vector2(-16,2176)]);backdrop.color=Color("1e3842");backdrop.z_index=-101;add_child(backdrop)
 var ground:=Sprite2D.new();ground.texture=load("res://assets/woo/worlds/forest_ground.png");ground.centered=false;ground.z_index=-100;add_child(ground)
 rect_collision(Rect2(0,0,3000,170));rect_collision(Rect2(0,1990,3000,170));rect_collision(Rect2(0,170,110,1820));rect_collision(Rect2(2890,170,110,1820));rect_collision(Layout.POND)
 for block in Layout.WATER_BLOCKS:rect_collision(block)
 rect_collision(Rect2(2390,485,180,100))
 add_prop("shrine",Vector2(2480,565),0)
 for r in Layout.ROCKS:
  var body:=StaticBody2D.new();body.position=Vector2(r.x,r.y);body.collision_layer=1;body.collision_mask=2|4
  var c:=CollisionShape2D.new();var shape:=CircleShape2D.new();shape.radius=r.z;c.shape=shape;body.add_child(c);add_child(body)
 # Independent reused HD art: wooded borders and sparse interior trunks, not a flat background.
 for i in range(36):
  add_prop("bamboo",Vector2(120+i*78,175),i)
  if i%2==0:add_prop("tree",Vector2(130+i*76,2010),i)
  await build_budget.checkpoint(get_tree())
 for i in range(Layout.EXTRA_BAMBOO.size()):
  add_prop("bamboo",Layout.EXTRA_BAMBOO[i],0)
  await build_budget.checkpoint(get_tree())
 for x in [120,2920]:
  for y in range(350,2000,160):add_prop("bamboo",Vector2(x,y),0)
 for p in Layout.TREES:add_prop("tree",p,0)
 for p in Layout.BAMBOO:add_prop("bamboo",p,0)
 for p in Layout.LANTERNS:add_prop("stone_lantern",p,0)
 atmosphere=preload("res://scripts/woo/forest_atmosphere.gd").new();atmosphere.z_index=20;add_child(atmosphere)
 build_ready=true
func add_prop(kind: String,p: Vector2,variant: int) -> void:
 var prop:=Prop.new();prop.kind=kind;prop.position=p;prop.variant=variant;add_child(prop)
 # Village props already own static footprints. Include combat actors in their masks.
 prop.collision_mask=2|4
func rect_collision(rect: Rect2) -> void:
 var body:=StaticBody2D.new();body.collision_layer=1;body.collision_mask=2|4
 var c:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=rect.size;c.shape=shape;body.position=rect.get_center();body.add_child(c);add_child(body)

func route(from: Vector2,to: Vector2) -> PackedVector2Array:
 var a:=Vector2i(from/32);var b:=Vector2i(to/32)
 if not navigation.is_in_boundsv(a) or not navigation.is_in_boundsv(b):return PackedVector2Array()
 if navigation.is_point_solid(a):a=nearest_cell(a)
 if navigation.is_point_solid(b):b=nearest_cell(b)
 if a.x<0 or b.x<0:return PackedVector2Array()
 var path:=navigation.get_point_path(a,b)
 if not path.is_empty():path.remove_at(0)
 return path

func nearest_cell(cell: Vector2i) -> Vector2i:
 for radius in range(1,4):
  for y in range(-radius,radius+1):
   for x in range(-radius,radius+1):
    var p:=cell+Vector2i(x,y)
    if navigation.is_in_boundsv(p) and not navigation.is_point_solid(p):return p
 return Vector2i(-1,-1)
