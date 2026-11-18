class_name TouchJoystick
extends Control

var vector := Vector2.ZERO
var input_enabled := true
var finger := -1
var mouse_active := false
const RADIUS := 73.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	get_viewport().size_changed.connect(arrange)
	arrange.call_deferred()

func _input(event: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree(): return
	# UI receives Godot's emulated mouse; joystick owns only the native touch.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var center := global_position + size / 2
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and event.position.distance_to(center) < RADIUS + 30:
			finger = event.index
			update_vector(event.position - center)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			reset()
	elif event is InputEventScreenDrag and event.index == finger:
		update_vector(event.position - center)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.distance_to(center) < RADIUS + 30:
			mouse_active = true
			update_vector(event.position - center)
		elif not event.pressed and mouse_active:
			reset()
	elif event is InputEventMouseMotion and mouse_active:
		update_vector(event.position - center)

func update_vector(offset: Vector2) -> void:
	# 데드존을 0.12 → 0.08로 낮춰 살짝 미는 터치도 바로 부드럽게 들어가게 한다.
	var raw := offset.limit_length(RADIUS) / RADIUS
	vector = Vector2.ZERO if raw.length() < 0.08 else raw
	queue_redraw()

func reset() -> void:
	finger = -1
	mouse_active = false
	vector = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()

func _draw() -> void:
	var center := size/2
	draw_circle(center,RADIUS+6,Color(0.1,0.07,0.13,0.8))
	draw_arc(center,RADIUS+5,0,TAU,64,Color("bb9b68"),3,true)
	draw_circle(center,RADIUS,Color(0.34,0.27,0.37,0.25))
	draw_arc(center,RADIUS-3,0,TAU,64,Color("746252"),1,true)
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var p: Vector2=center+direction*56
		var side:=Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*4+side*4,p-direction*4-side*4]),Color("b6a2a7"))
	var knob:=center+vector*49
	draw_circle(knob+Vector2(0,4),30,Color(0,0,0,0.28))
	draw_circle(knob,29,Color("82758a"))
	draw_arc(knob,29,0,TAU,48,Color("b8a8b5"),2,true)
	draw_circle(knob+Vector2(-3,-4),23,Color("92859a"))

func arrange() -> void:
	preload("res://scripts/ui/design.gd").position_stick(self)
