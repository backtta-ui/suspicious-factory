class_name FactoryMinimap
extends Control
## Privacy boundary: accepts only static layout, LOCAL position and LOCAL objectives.
## No scene-tree player enumeration, network snapshots, roles or remote-player inputs.
var layout: FactoryLayout
var local_position := Vector2.ZERO
var objectives := PackedVector2Array()
var expanded := false
const FONT = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func update_local(position_value: Vector2, own_objectives: PackedVector2Array) -> void:
	if local_position != position_value or objectives != own_objectives:
		local_position = position_value
		objectives = own_objectives
		queue_redraw()

func projection() -> Transform2D:
	if not layout: return Transform2D.IDENTITY
	var padding := 12.0 if not expanded else 20.0
	var ratio := minf((size.x-padding*2)/layout.size.x,(size.y-padding*2)/layout.size.y)
	return Transform2D(Vector2(ratio,0),Vector2(0,ratio),(size-layout.size*ratio)/2)

func map_point(world_position: Vector2) -> Vector2:
	return projection()*world_position

func mapped(rect: Rect2) -> Rect2:
	var t := projection()
	return Rect2(t*rect.position,rect.size*t.x.x)

func _draw() -> void:
	if not layout: return
	for corridor in layout.corridors: draw_rect(mapped(corridor.rect),Color("657075"))
	for door in layout.doors: draw_rect(mapped(door.rect),Color("657075"))
	for room in layout.rooms:
		draw_rect(mapped(room.rect),room.color.lightened(0.15))
	for wall in layout.walls:
		draw_rect(mapped(wall),Color("b0bec0"))
	if expanded:
		for prop in layout.props: draw_rect(mapped(prop.rect),Color(0.1,0.15,0.2,0.6))
	for room in layout.rooms:
		var text: String = room.name if expanded else room.short_name
		var font_size := 18 if expanded else 11
		var center := mapped(room.rect).get_center()
		var text_size := FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
		var p := center+Vector2(-text_size.x/2,-4)
		draw_string_outline(FONT,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color("111c29"))
		draw_string(FONT,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("e6e8de"))
	for objective in objectives:
		var p := map_point(objective)
		draw_circle(p,7 if expanded else 4,Color("ffd05a"))
	var p := map_point(local_position)
	draw_circle(p,10 if expanded else 6,Color("13283b"))
	draw_circle(p,7 if expanded else 4,Color("4d9fff"))
	draw_arc(p,11 if expanded else 7,0,TAU,24,Color("dfedff"),1,true)
