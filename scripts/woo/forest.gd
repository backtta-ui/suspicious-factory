class_name WooForest
extends Node2D
const Layout=preload("res://scripts/woo/forest_layout.gd")
const Prop=preload("res://scripts/woo/village_prop.gd")
const GROUND=preload("res://assets/woo/v13/forest_ground.png")
var atmosphere: Node2D
var navigation:=AStarGrid2D.new()
func _ready() -> void:
 navigation.region=Rect2i(0,0,47,34);navigation.cell_size=Vector2(32,32);navigation.offset=Vector2(16,16);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 for y in range(34):
  for x in range(47):navigation.set_point_solid(Vector2i(x,y),not Layout.can_stand(Vector2(x*32+16,y*32+16),17))
 y_sort_enabled=true;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var backdrop:=Polygon2D.new();backdrop.polygon=PackedVector2Array([Vector2(-16,-16),Vector2(1516,-16),Vector2(1516,1096),Vector2(-16,1096)]);backdrop.color=Color("1e3842");backdrop.z_index=-101;add_child(backdrop)
 var ground:=Sprite2D.new();ground.texture=GROUND;ground.centered=false;ground.z_index=-100;add_child(ground)
 rect_collision(Rect2(0,0,1500,170));rect_collision(Rect2(0,910,1500,170));rect_collision(Rect2(0,170,110,740));rect_collision(Rect2(1390,170,110,740));rect_collision(Layout.POND)
 for r in Layout.ROCKS:
  var body:=StaticBody2D.new();body.position=Vector2(r.x,r.y);body.collision_layer=1;body.collision_mask=2|4
  var c:=CollisionShape2D.new();var shape:=CircleShape2D.new();shape.radius=r.z;c.shape=shape;body.add_child(c);add_child(body)
 # Independent reused HD art: wooded borders and sparse interior trunks, not a flat background.
 for i in range(17):
  add_prop("bamboo",Vector2(120+i*78,175),i)
  if i%2==0:add_prop("tree",Vector2(130+i*76,930),i)
 for p in [Vector2(105,360),Vector2(90,580),Vector2(1420,400),Vector2(1430,650),Vector2(1400,800)]:add_prop("bamboo",p,0)
 for p in Layout.BAMBOO:add_prop("bamboo",p,0)
 for p in Layout.LANTERNS:add_prop("stone_lantern",p,0)
 atmosphere=preload("res://scripts/woo/forest_atmosphere.gd").new();atmosphere.z_index=20;add_child(atmosphere)
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
 if navigation.is_point_solid(a) or navigation.is_point_solid(b):return PackedVector2Array()
 var path:=navigation.get_point_path(a,b)
 if not path.is_empty():path.remove_at(0)
 return path
