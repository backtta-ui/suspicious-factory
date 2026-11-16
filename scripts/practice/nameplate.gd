class_name WooPracticeNameplate
extends Node2D
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var title:=""
var hp:=100
var focused:=false
var color:=Color("d2c4a6")
func _draw() -> void:
 var width:=36.0
 draw_string_outline(FONT,Vector2(-45,-6),title,HORIZONTAL_ALIGNMENT_CENTER,90,9,2,Color("111b2c"))
 draw_string(FONT,Vector2(-45,-6),title,HORIZONTAL_ALIGNMENT_CENTER,90,9,color)
 if focused:
  draw_style_box(box(Color("162230")),Rect2(-width/2,0,width,4))
  draw_rect(Rect2(-width/2+.5,.5,(width-1)*clampf(hp/100.0,0,1),3),Color("77c5a0"))
func box(c: Color) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=c;style.border_color=Color("c7ab76");style.set_border_width_all(1);return style
