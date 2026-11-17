class_name WooVitalBar
extends ProgressBar
const D=preload("res://scripts/ui/design.gd")
var mana:=false
func _ready() -> void:
 show_percentage=false;mouse_filter=Control.MOUSE_FILTER_IGNORE
 var fill:=D.panel(D.MANA if mana else D.HP,3);var background:=D.panel(D.INK,3)
 fill.set_content_margin_all(0);background.set_content_margin_all(0)
 add_theme_stylebox_override("fill",fill);add_theme_stylebox_override("background",background)
 size=D.VITALS_RECT.size
