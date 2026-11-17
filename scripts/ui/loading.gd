class_name WooLoadingOverlay
extends Control
const D=preload("res://scripts/ui/design.gd")
var title:="공간을 준비하고 있습니다"
var clock:=0.0
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=110
func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.04,.07,.94))
 var center:=size/2
 for i in range(5):
  var p:=center+Vector2.from_angle(clock+i*TAU/5)*35
  draw_set_transform(p,sin(clock+i)*.12);draw_rect(Rect2(-5,-12,10,24),D.GOLD);draw_line(Vector2(-2,-6),Vector2(2,6),D.INK,2)
 draw_set_transform(Vector2.ZERO)
 draw_string(D.FONT,center+Vector2(-260,82),title,HORIZONTAL_ALIGNMENT_CENTER,520,22,D.TEXT)
