class_name WooMobileButton
extends Button
## Native multi-touch ownership, also supports a real PC mouse.
## BaseButton mouse handling is disabled to avoid touch + emulated-mouse double fire.
signal observed(event: InputEvent)
var allowed: Callable
var owner_finger := -1
var owns_mouse := false
var held := false
func _ready() -> void:
	button_mask = 0
	toggle_mode = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(112,64) if custom_minimum_size==Vector2.ZERO else custom_minimum_size.max(Vector2(64,56))
func usable() -> bool:
	return is_visible_in_tree() and not disabled and (not allowed.is_valid() or allowed.call())
func cancel() -> void:
	owner_finger = -1
	owns_mouse = false
	if held:
		held = false
		set_pressed_no_signal(false)
		button_up.emit()
func down() -> void:
	held = true
	set_pressed_no_signal(true)
	button_down.emit()
func up(inside: bool) -> void:
	var was_held := held
	cancel()
	if was_held and inside and usable(): pressed.emit()
func _input(event: InputEvent) -> void:
	if not usable():
		cancel()
		return
	var rect := get_global_rect()
	if event is InputEventScreenTouch:
		if event.pressed and owner_finger==-1 and rect.has_point(event.position):
			owner_finger = event.index
			observed.emit(event)
			down()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==owner_finger:
			observed.emit(event)
			up(rect.has_point(event.position) and not event.canceled)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==owner_finger:
		set_pressed_no_signal(rect.has_point(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and rect.has_point(event.position):
			owns_mouse = true
			down()
			get_viewport().set_input_as_handled()
		elif not event.pressed and owns_mouse:
			up(rect.has_point(event.position))
			get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: cancel()
