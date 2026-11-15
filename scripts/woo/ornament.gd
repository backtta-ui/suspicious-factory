class_name WooOrnament
extends Control
var circular := false
var icon := ""
var primary := false
var previous_mode := -1
const FONT = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _process(_delta: float) -> void:
	if get_parent() is BaseButton:
		var mode: int = get_parent().get_draw_mode()
		if mode!=previous_mode: previous_mode=mode;queue_redraw()
func _draw() -> void:
	var gold := Color("d9b678")
	if get_parent() is BaseButton and get_parent().disabled: gold=gold.darkened(0.5)
	if previous_mode in [BaseButton.DRAW_PRESSED,BaseButton.DRAW_HOVER_PRESSED]: gold=Color("ffe4a0")
	if circular:
		var center:=size/2
		var r:=minf(size.x,size.y)/2-4
		draw_arc(center,r,0,TAU,80,Color("3a2930"),7,true)
		draw_arc(center,r,0,TAU,80,gold,2,true)
		draw_arc(center,r-5,0,TAU,80,Color("786449"),1,true)
		if icon=="spell":
			var points:=PackedVector2Array([center+Vector2(-13,-27),center+Vector2(13,-22),center+Vector2(6,10),center+Vector2(-20,5)])
			draw_colored_polygon(points,Color("f5ca75"))
			draw_string(FONT,center+Vector2(-14,0),"符",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ae3d36"))
		elif icon=="talk":
			var box:=Rect2(center+Vector2(-21,-25),Vector2(42,27))
			draw_style_box(bubble_style(),box)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-6,0),center+Vector2(1,8),center+Vector2(7,0)]),Color("e9dfc6"))
			for x in [-10,0,10]: draw_circle(center+Vector2(x,-12),2.3,Color("4a3c40"))
		elif icon=="run":
			draw_circle(center+Vector2(8,-27),5,Color("e9dfc6"))
			for line in [[Vector2(6,-20),Vector2(-5,-7)],[Vector2(-5,-7),Vector2(9,-3)],[Vector2(9,-3),Vector2(15,8)],[Vector2(-5,-7),Vector2(-15,7)],[Vector2(3,-17),Vector2(-8,-22)],[Vector2(-8,-22),Vector2(-18,-15)],[Vector2(3,-17),Vector2(15,-13)]]:
				draw_line(center+line[0],center+line[1],Color("e9dfc6"),4,true)
	else:
		var w:=size.x;var h:=size.y
		var points:=PackedVector2Array([Vector2(16,3),Vector2(w-16,3),Vector2(w-3,16),Vector2(w-3,h-16),Vector2(w-16,h-3),Vector2(16,h-3),Vector2(3,h-16),Vector2(3,16),Vector2(16,3)])
		draw_polyline(points,gold,2,true)
		draw_line(Vector2(23,8),Vector2(w-23,8),Color(gold,0.4),1,true)
		draw_line(Vector2(23,h-8),Vector2(w-23,h-8),Color(gold,0.4),1,true)
		for center in [Vector2(15,h/2),Vector2(w-15,h/2)]:
			draw_polyline(PackedVector2Array([center+Vector2(0,-6),center+Vector2(6,0),center+Vector2(0,6),center+Vector2(-6,0),center+Vector2(0,-6)]),gold,1,true)
func bubble_style() -> StyleBoxFlat:
	var b:=StyleBoxFlat.new();b.bg_color=Color("e9dfc6");b.set_corner_radius_all(8);return b
