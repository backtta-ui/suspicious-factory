extends Node2D
const DOOR=Vector2(1120,980)
func _ready() -> void:
 position=DOOR
 var gate:=preload("res://scripts/worlds/plaza_prop.gd").new();gate.kind="stone_lantern";gate.position=Vector2(-45,-22);add_child(gate)
 var other:=preload("res://scripts/worlds/plaza_prop.gd").new();other.kind="stone_lantern";other.position=Vector2(45,-22);add_child(other)
 var label:=Label.new();label.text="도술 모의전\n오프라인 봇 6~8인";label.position=Vector2(-65,-86);label.size.x=130;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJK-Regular.ttc"));label.add_theme_font_size_override("font_size",12);add_child(label)
 var talisman:=preload("res://scripts/woo/skill_badge.gd").new();talisman.skill="talisman";talisman.position=Vector2(-20,-28);talisman.size=Vector2(40,40);add_child(talisman)
