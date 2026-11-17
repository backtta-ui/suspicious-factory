class_name WooVitalBar
extends ProgressBar
const D=preload("res://scripts/ui/design.gd")
var mana:=false
func _ready() -> void:
 show_percentage=false;mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_theme_stylebox_override("fill",D.panel(D.MANA if mana else D.HP,3));add_theme_stylebox_override("background",D.panel(D.INK,3))
