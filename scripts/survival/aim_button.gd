extends "res://scripts/survival/skill_button.gd"
signal ability(direction: Vector2)
signal tip_requested
signal aimed(direction: Vector2,cancelled: bool)
var directional:=false
var origin:=Vector2.ZERO
var aim:=Vector2.ZERO
var elapsed:=0.0
var explained:=false
var dragged:=false
var abort:=false
func down() -> void:
 super.down();elapsed=0;explained=false;dragged=false;abort=false;aim=Vector2.ZERO;origin=get_global_rect().get_center()
func _process(delta: float) -> void:
 if not held:return
 elapsed+=delta
 if elapsed>.65 and not dragged and not explained:explained=true;tip_requested.emit()
func up(inside: bool) -> void:
 var active:=held;cancel()
 scale=Vector2.ONE
 if not active or explained or abort:return
 if directional:
  ability.emit(aim)
 elif inside:ability.emit(Vector2.ZERO)
func _input(event: InputEvent) -> void:
 if held and directional and event is InputEventScreenDrag and event.index==owner_finger:
  var delta: Vector2=event.position-origin;dragged=delta.length()>12;aim=delta.normalized() if dragged else Vector2.ZERO;abort=delta.y< -165 or delta.length()>340;aimed.emit(aim,abort);get_viewport().set_input_as_handled();return
 if held and directional and event is InputEventScreenTouch and event.index==owner_finger and not event.pressed:
  if event.canceled:abort=true
  up(true);get_viewport().set_input_as_handled();return
 super._input(event)
