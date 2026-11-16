extends Node2D
var color_id:=0
var actor: WooActor
func _process(_delta: float) -> void:
 visible=is_instance_valid(actor) and actor.appearance_form=="human" and not actor.jar and not actor.identity_concealed
 queue_redraw()
func _draw() -> void:
 var colors=preload("res://scripts/seal/settings.gd").COLORS
 draw_arc(Vector2(0,1),10,0,TAU,28,Color(colors[posmod(color_id,8)]),2,true)
