class_name TouchDebug
extends CanvasLayer
## Opt-in diagnostics. No touch-time file IO in normal APK sessions. Observes only: never consumes input.
## Bounded local log; contains coordinates/UI state only, never nickname/chat/keys.

var enabled := OS.is_debug_build() and (OS.get_environment("WOO_TOUCH_LOG")=="1" or OS.get_environment("WOO_TOUCH_OVERLAY")=="1")
var target: Node
var last_drag_msec := -1000
var status: Label
var marker: Control
var last_position := Vector2(-100,-100)
var sequence := 0
var log_path := "user://touch-debug.log"
const MAX_LOG_BYTES := 262144

func _ready() -> void:
	layer = 20
	if not enabled:
		set_process_input(false)
		return
	var overlay := Control.new()
	overlay.name = "NonBlockingTouchDiagnostics"
	overlay.visible = OS.get_environment("WOO_TOUCH_OVERLAY")=="1"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	marker = Control.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.draw.connect(func() -> void:
		marker.draw_arc(last_position,12,0,TAU,32,Color("ffdc70"),3,true))
	overlay.add_child(marker)
	status = Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.clip_text = true
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 230
	status.offset_right = -270
	status.offset_top = -28
	status.offset_bottom = -4
	status.add_theme_font_size_override("font_size",13)
	status.add_theme_color_override("font_color",Color("ffe7a0"))
	status.add_theme_color_override("font_outline_color",Color("0a1724"))
	status.add_theme_constant_override("outline_size",4)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(status)
	record("READY", "V%s touch→mouse=%s" % [ProjectSettings.get_setting("application/config/version"),Input.emulate_mouse_from_touch])

func _input(event: InputEvent) -> void:
	# This node is registered after the UI layer, before its joystick consumes events.
	if is_instance_valid(target): observe(event,target.screen_name,target.ui)

func record(kind: String, details: String) -> void:
	if not enabled: return
	sequence += 1
	var line := "[TOUCH %04d] %s %s" % [sequence,kind,details]
	print(line)
	if is_instance_valid(status): status.text = line
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE
	var file := FileAccess.open(log_path,mode)
	if file:
		if file.get_length() >= MAX_LOG_BYTES:
			file.close()
			file = FileAccess.open(log_path,FileAccess.WRITE)
		if file:
			file.seek_end()
			file.store_line(line)

func observe(event: InputEvent, screen: String, ui: Control) -> void:
	if not enabled: return
	if event is InputEventScreenTouch:
		last_position = event.position
		marker.queue_redraw()
		var candidates: Array[String] = []
		collect_buttons(ui,event.position,candidates)
		var viewport := get_viewport()
		record("DOWN" if event.pressed else "UP", "id=%d xy=%s window=%s view=%s screen=%s buttons=%s" % [event.index,event.position,viewport.get_final_transform()*event.position,viewport.get_visible_rect().size,screen,",".join(candidates)])
	elif event is InputEventScreenDrag:
		last_position = event.position
		marker.queue_redraw()
		var now := Time.get_ticks_msec()
		if now-last_drag_msec >= 100:
			last_drag_msec = now
			record("DRAG","id=%d xy=%s screen=%s" % [event.index,event.position,screen])
	elif event is InputEventMouseButton:
		record("MOUSE", "pressed=%s xy=%s emulated=%s screen=%s" % [event.pressed,event.position,event.device == InputEvent.DEVICE_ID_EMULATION,screen])

func collect_buttons(node: Node, point: Vector2, found: Array[String]) -> void:
	if not is_instance_valid(node): return
	if node is BaseButton and node.is_visible_in_tree() and node.get_global_rect().has_point(point):
		found.append("%s:%s" % [node.text,"disabled" if node.disabled else "enabled"])
	for child in node.get_children(): collect_buttons(child,point,found)
