class_name WooLocalMinimap
extends Control
const Layout = preload("res://scripts/woo/village_layout.gd")
var mission:=false
var local_position := Vector2.ZERO
var elder_done := false
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_local(p: Vector2, done: bool) -> void:
	if p!=local_position or elder_done!=done:
		local_position=p;elder_done=done;queue_redraw()
func point(p: Vector2) -> Vector2:
	var bounds:=Vector2(3000,2160) if mission else Layout.SIZE
	return size/2+(p-bounds/2)*(minf(size.x,size.y)-16)/bounds.x
func _draw() -> void:
	var center:=size/2;var radius:=minf(size.x,size.y)/2-3
	draw_circle(center,radius,Color("1a1929"))
	if mission:
		var forest=preload("res://scripts/woo/forest_layout.gd")
		draw_rect(Rect2(point(Vector2(110,170)),point(Vector2(2890,1990))-point(Vector2(110,170))),Color("355155"))
		draw_rect(Rect2(point(forest.POND.position),point(forest.POND.end)-point(forest.POND.position)),Color("527ca0"))
		draw_rect(Rect2(point(forest.NEW_POND.position),point(forest.NEW_POND.end)-point(forest.NEW_POND.position)),Color("527ca0"))
		for z in forest.ZONES:draw_circle(point(z.center),2,Color("8dada0"))
		for p in forest.GOBLINS:draw_circle(point(p),2,Color("f1d480"))
		draw_circle(point(forest.EXIT),3,Color("d5b8ff"));draw_circle(point(local_position),3,Color("8ac9ff"))
		draw_arc(center,radius,0,TAU,72,Color("c8ad7d"),2,true)
		return
	var polygon:=PackedVector2Array()
	for p in Layout.BOUNDS: polygon.append(point(p))
	draw_colored_polygon(polygon,Color("484049"))
	for prop in Layout.PROPS:
		var p:=point(prop.position)
		if prop.kind=="hanok": draw_rect(Rect2(p-Vector2(4,2),Vector2(8,4)),Color("aa9778"))
		elif prop.kind=="tree": draw_circle(p,2,Color("a66e94"))
		elif prop.kind=="lantern": draw_circle(p,1.4,Color("eeb365"))
	for painting in Layout.PAINTINGS:draw_circle(point(painting.position),2,Color("c7a0f0"))
	for zone in Layout.ZONES:draw_circle(point(zone.center),2.5,Color(zone.color,0.8))
	if not elder_done: draw_circle(point(Layout.NPCS[2].position),3,Color("f7d474"))
	var p:=point(local_position)
	draw_circle(p,4,Color("151b2d"));draw_circle(p,2.8,Color("8ac9ff"))
	draw_arc(center,radius,0,TAU,72,Color("c8ad7d"),2,true)
	draw_arc(center,radius-4,0,TAU,72,Color("69513e"),1,true)
