extends Control
## 대기실 아이콘 한 개를 그리는 노드. 그림 자체는 room_glyphs.gd가 맡는다.
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
var glyph:="lantern"
var tint:=Color("f0dcae")
var line:=1.8
var glow:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func set_icon(value: String,color: Color=Color("f0dcae")) -> void:
	glyph=value;tint=color
	queue_redraw()
func _draw() -> void:
	Glyphs.draw_glyph(self,glyph,Rect2(Vector2.ZERO,size),tint,line,glow)
