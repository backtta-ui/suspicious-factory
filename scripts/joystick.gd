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
	vector = offset.limit_length(RADIUS) / RADIUS
	if vector.length() < 0.12:
		vector = Vector2.ZERO
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
	var center := size / 2
	draw_circle(center, RADIUS + 6, Color(0.05,0.09,0.14,0.65))
	draw_circle(center, RADIUS, Color(0.7,0.81,0.86,0.16))
	draw_arc(center, RADIUS, 0, TAU, 64, Color(0.8,0.9,1,0.38), 2, true)
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_circle(center + direction * 57, 3, Color(1,1,1,0.45))
	draw_circle(center + vector * 54, 29, Color("cbd9dc"))
	draw_circle(center + vector * 54 + Vector2(-4,-5), 21, Color("eaf0e8"))
