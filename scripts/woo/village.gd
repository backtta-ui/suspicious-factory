class_name WooVillage
extends Node2D
const Layout=preload("res://scripts/woo/village_layout.gd")
const Prop=preload("res://scripts/woo/village_prop.gd")
var ambience: CanvasModulate
var lanterns: Array[Sprite2D]=[]
var time_of_day:=0.4
var cycle_enabled:=true
var low_effects:=false
var petals: Node2D
var water: Node2D
var great_tree: WooVillageProp
func _ready() -> void:
 y_sort_enabled=true;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var ground:=Sprite2D.new();ground.texture=preload("res://assets/woo/ground_baked.png");ground.centered=false;ground.z_index=-100;add_child(ground)
 add_child(preload("res://scripts/woo/scenery.gd").new())
 water=preload("res://scripts/woo/water.gd").new();add_child(water)
 petals=preload("res://scripts/woo/petals.gd").new();add_child(petals)
 for data in Layout.PROPS:
  var prop:=Prop.new();prop.kind=data.kind;prop.position=data.position;prop.variant=int(data.get("variant",0));prop.display_name=str(data.get("name",""));add_child(prop)
  if is_instance_valid(prop.light):lanterns.append(prop.light)
  if prop.kind=="great_tree":great_tree=prop
 var boundary:=StaticBody2D.new();boundary.collision_layer=1;boundary.collision_mask=2
 for i in range(Layout.BOUNDS.size()):
  var shape:=SegmentShape2D.new();shape.a=Layout.BOUNDS[i];shape.b=Layout.BOUNDS[(i+1)%Layout.BOUNDS.size()]
  var collider:=CollisionShape2D.new();collider.shape=shape;boundary.add_child(collider)
 add_child(boundary)
 ambience=CanvasModulate.new();add_child(ambience)
func set_completed_stories(ids: Array) -> void:
 if is_instance_valid(great_tree):great_tree.set_stories(ids.size())
func _process(delta: float) -> void:
 if cycle_enabled:time_of_day=fposmod(time_of_day+delta/150.0,1.0)
 var night: float=(sin(time_of_day*TAU-PI/2)+1)/2
 ambience.color=Color("fff0d7").lerp(Color("a2a5dc"),night*0.62)
 for light in lanterns:light.modulate.a=0.1+night*0.28
 if is_instance_valid(petals):petals.low_effects=low_effects;petals.night=night
 if is_instance_valid(water):water.set_process(not low_effects)
func draw_ground(canvas: Node2D) -> void:
 preload("res://scripts/woo/terrain.gd").draw_ground(canvas)
