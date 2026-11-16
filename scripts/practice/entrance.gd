class_name WooPracticeEntrance
extends Node2D
const L=preload("res://scripts/practice/layout.gd")
var clock:=0.0
func _ready() -> void:
 position=L.ENTRANCE;z_index=2
 var panel:=PanelContainer.new();panel.position=Vector2(-48,-89);panel.custom_minimum_size=Vector2(96,25)
 var box:=StyleBoxFlat.new();box.bg_color=Color("382d32");box.border_color=Color("bd9d69");box.set_border_width_all(1);panel.add_theme_stylebox_override("panel",box);add_child(panel)
 var plaque:=Label.new();plaque.text="도술 익히기";plaque.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;plaque.add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJK-Regular.ttc"));plaque.add_theme_font_size_override("font_size",11);plaque.add_theme_color_override("font_color",Color("ffe0a1"));panel.add_child(plaque)

func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 for x in [-44,44]:
  draw_rect(Rect2(x-4,-44+sin(clock+x)*1.2,8,18),Color("e5c98d"));draw_line(Vector2(x-1,-41),Vector2(x+1,-30),Color("ba594d"),1)
 for i in range(6):
  var p:=Vector2.from_angle(clock*.4+i*TAU/6)*Vector2(50,15)+Vector2(0,50)
  draw_circle(p,1.5,Color(.4,.8,1,.45))
 draw_arc(Vector2(0,57),28,0,TAU,40,Color(.4,.75,1,.4),1.3,true)
