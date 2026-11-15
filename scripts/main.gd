extends Node

const Worker = preload("res://scripts/worker.gd")
const Map = preload("res://scripts/factory.gd")
const Joystick = preload("res://scripts/joystick.gd")
const Session = preload("res://scripts/factory_session.gd")
const MiniMap = preload("res://scripts/minimap.gd")
const DebugInput = preload("res://scripts/touch_debug.gd")
const INK := Color("0e1c29")
const GOLD := Color("f3ca59")
var hat := 1
var vest := 0
var nickname := "신입사원"
var world: Node2D
var factory: FactoryMap
var player: FactoryWorker
var camera: Camera2D
var ui: Control
var layer: CanvasLayer
var joystick: TouchJoystick
var location_label: Label
var position_label: Label
var use_button: Button
var toast: Label
var toast_time := 0.0
var paused := false
var preview: FactoryWorker
var modal: Control
var safe_margin := 36
var visited: Dictionary = {}
var walk_distance := 0.0
var previous_position := Vector2.ZERO
var smooth_camera := true
var in_game := false
var screen_name := "menu"
var ui_action_pending := false
var touch_debug: TouchDebug
var session: FactorySession
var remote_workers: Dictionary = {}
var network_host := ""
var network_port := 24560
var network_label: Label
var mini_map: FactoryMinimap
var map_view: FactoryMinimap
var map_button: Button
var modal_kind := ""
var guide_index := 0
var guide_label: Label
var app_version: String = ProjectSettings.get_setting("application/config/version", "0.1.1")

func _ready() -> void:
	get_tree().auto_accept_quit = false
	load_profile()
	setup_theme()
	session = Session.new()
	session.name = "FactorySession"
	add_child(session)
	session.status_changed.connect(on_session_status)
	session.snapshot_changed.connect(sync_remote_workers)
	layer = CanvasLayer.new()
	add_child(layer)
	show_menu()
	touch_debug = DebugInput.new()
	touch_debug.target = self
	add_child(touch_debug)

func setup_theme() -> void:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/NotoSansCJK-Regular.ttc")
	theme.default_font_size = 21
	for state in ["normal","hover","pressed","disabled","focus"]:
		var color := Color("243d4c")
		if state == "hover": color = Color("335569")
		if state == "pressed": color = Color("48768a")
		if state == "disabled": color = Color("1c2a35")
		var style := box(color,14)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = GOLD
			style.set_border_width_all(2)
		theme.set_stylebox(state,"Button",style)
	theme.set_stylebox("normal","LineEdit",box(Color("0b1824"),10))
	theme.set_color("font_color","Label",Color("edf1e5"))
	theme.set_color("font_color","Button",Color("edf1e5"))
	theme.set_constant("separation","VBoxContainer",14)
	theme.set_constant("separation","HBoxContainer",18)
	ThemeDB.get_default_theme().default_font = theme.default_font
	get_viewport().set_meta("game_theme",theme)

func box(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func new_ui() -> void:
	if is_instance_valid(ui):
		layer.remove_child(ui)
		ui.queue_free()
	modal = null
	modal_kind = ""
	map_view = null
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = get_viewport().get_meta("game_theme")
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	if is_instance_valid(touch_debug): touch_debug.record("SCREEN",screen_name)

func label(text: String, font_size: int = 22, color: Color = Color("edf1e5")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	return node

func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.name = "Action_" + str(text.hash())
	node.custom_minimum_size = Vector2(100,64)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node.button_down.connect(func() -> void: trace_button("BUTTON_DOWN",node))
	node.button_up.connect(func() -> void: trace_button("BUTTON_UP",node))
	node.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			trace_button("GUI",node))
	node.pressed.connect(func() -> void: activate_button(node,callback))
	if primary:
		node.add_theme_stylebox_override("normal",box(GOLD,14))
		node.add_theme_stylebox_override("hover",box(GOLD.lightened(0.12),14))
		node.add_theme_stylebox_override("pressed",box(GOLD.darkened(0.12),14))
		node.add_theme_color_override("font_color",INK)
		node.add_theme_color_override("font_hover_color",INK)
		node.add_theme_color_override("font_pressed_color",INK)
	return node

func panel(parent: Node, color: Color = Color("162a38")) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel",box(color,22))
	parent.add_child(node)
	return node

func screen_stack() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:
		margin.add_theme_constant_override("margin_"+side,48)
	for side in ["top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,26)
	ui.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	return stack

func show_menu() -> void:
	if is_instance_valid(session) and session.active: session.disconnect_session()
	remote_workers.clear()
	screen_name = "menu"
	in_game = false
	paused = false
	if is_instance_valid(world):
		world.queue_free()
		world = null
	new_ui()
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bg)
	var stack := screen_stack()
	var header := HBoxContainer.new()
	stack.add_child(header)
	var tag := label("SF  /  SUSPICIOUS FACTORY",18,Color("86b6b5"))
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(tag)
	header.add_child(label("공장 지도 테스트   •   " + app_version,18,Color("92a6b2")))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.25
	body.add_child(left)
	left.add_spacer(false)
	left.add_child(label("야간 근무에 오신 것을 환영합니다",20,Color("85c5b5")))
	left.add_child(label("수상한 공장",70))
	left.add_child(label("평범한 작업장, 수상한 동료들.",25,GOLD))
	left.add_child(label("첫 출근입니다. 공장을 둘러보세요.\n현재 버전은 혼자 걷는 1차 이동 테스트입니다.",20,Color("b5c6cb")))
	left.add_spacer(false)
	left.add_child(button("공장 들어가기   →",start_game,true))
	var row := HBoxContainer.new()
	left.add_child(row)
	var customize := button("캐릭터 꾸미기",show_customize)
	customize.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(customize)
	row.add_child(button("설정",show_settings))
	left.add_spacer(false)
	var right := panel(body)
	right.custom_minimum_size.x = 380
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card := VBoxContainer.new()
	right.add_child(card)
	card.add_child(label("EMPLOYEE  /  001",16,Color("85c5b5")))
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(300,270)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(stage)
	add_preview(stage,2.5)
	var name_label := label(nickname,27)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var status := label("●  출근 준비 완료",18,GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(status)
	stack.add_child(label("OFFLINE BUILD     /     모자·조끼 자유 조합     /     Android 가로 화면",16,Color("8299a5")))

func add_preview(parent: Control, zoom: float) -> void:
	preview = Worker.new()
	preview.hat = hat
	preview.vest = vest
	preview.nickname = ""
	preview.enabled = false
	preview.scale = Vector2.ONE * zoom
	parent.add_child(preview)
	var worker := preview
	var place := func() -> void:
		worker.position = Vector2(parent.size.x/2,parent.size.y/2+100)
	parent.resized.connect(place)
	place.call_deferred()

func show_customize() -> void:
	screen_name = "customize"
	new_ui()
	var stack := screen_stack()
	stack.add_child(button("← 메인 메뉴",show_menu))
	stack.add_child(label("나의 작업복",38))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(row)
	var card := panel(row)
	card.custom_minimum_size.x = 380
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stage := Control.new()
	card.add_child(stage)
	add_preview(stage,2.8)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(choices)
	choices.add_child(label("닉네임 (최대 12자)",18))
	var name_edit := LineEdit.new()
	name_edit.text = nickname
	name_edit.max_length = 12
	name_edit.custom_minimum_size.y = 56
	name_edit.virtual_keyboard_enabled = true
	name_edit.text_changed.connect(func(value: String) -> void:
		nickname = value.strip_edges().replace("\n","").replace("\r","")
		save_profile())
	choices.add_child(name_edit)
	choices.add_child(label("모자",22,GOLD))
	add_choices(choices,["없음","파랑","초록"],hat,func(index: int) -> void: hat = index; update_outfit())
	choices.add_child(label("조끼",22,GOLD))
	add_choices(choices,["기본 작업복","파랑","초록"],vest,func(index: int) -> void: vest = index; update_outfit())
	choices.add_child(label("외형은 역할과 무관합니다.\n선택한 작업복은 기기에 저장됩니다.",17,Color("99b3bf")))
	stack.add_child(button("이 작업복으로 출근하기   →",start_game,true))

func add_choices(parent: Node, names: Array, selected: int, callback: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var group := ButtonGroup.new()
	for i in range(names.size()):
		var b := button(names[i],callback.bind(i))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == selected
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("pressed",box(Color("397c80"),14))
		row.add_child(b)

func update_outfit() -> void:
	if is_instance_valid(preview):
		preview.hat = hat
		preview.vest = vest
		preview.queue_redraw()
	save_profile()

func start_game() -> void:
	if in_game: return
	screen_name = "factory"
	if nickname.is_empty(): nickname = "신입사원"
	save_profile()
	in_game = true
	paused = false
	visited.clear()
	guide_index = 0
	walk_distance = 0
	world = Node2D.new()
	add_child(world)
	factory = Map.new()
	world.add_child(factory)
	player = Worker.new()
	player.position = factory.layout.spawn
	player.hat = hat
	player.vest = vest
	player.nickname = nickname
	world.add_child(player)
	previous_position = player.position
	camera = Camera2D.new()
	camera.position_smoothing_enabled = smooth_camera
	camera.position_smoothing_speed = 7
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(factory.layout.size.x)
	camera.limit_bottom = int(factory.layout.size.y)
	player.add_child(camera)
	camera.make_current()
	build_hud()
	show_toast("왼쪽 조이스틱을 밀어 이동하세요. 노란 ! 표시는 설비 안내입니다.",7)

func build_hud() -> void:
	new_ui()
	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = safe_margin
	header.offset_right = -safe_margin
	header.offset_top = 22
	ui.add_child(header)
	var room_panel := panel(header,Color(0.04,0.09,0.14,0.93))
	var lines := VBoxContainer.new()
	room_panel.add_child(lines)
	lines.add_child(label("야간 순찰  /  1차 이동 테스트",16,Color("7cc5b5")))
	location_label = label("중앙 복도",29)
	lines.add_child(location_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(button("설정  ☰",show_settings))
	var info := VBoxContainer.new()
	info.position = Vector2(safe_margin,155)
	ui.add_child(info)
	info.add_child(label("공장 둘러보기",20,GOLD))
	position_label = label("방문한 방  0 / 12",17)
	info.add_child(position_label)
	guide_label = label("",16,Color("f5ce63"))
	info.add_child(guide_label)
	info.add_child(label("노란 표시 근처에서 ‘설비 확인’\nPC: WASD / 방향키 · E 확인 · Esc 설정",16,Color("b6c8cc")))
	build_minimap()
	joystick = Joystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(safe_margin+12,-208)
	joystick.size = Vector2(174,174)
	ui.add_child(joystick)
	use_button = button("설비 확인",inspect_station,true)
	use_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	use_button.offset_left = -230-safe_margin
	use_button.offset_right = -safe_margin
	use_button.offset_top = -126
	use_button.offset_bottom = -42
	ui.add_child(use_button)
	toast = label("",20,GOLD)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_left = 235
	toast.offset_right = -285
	toast.offset_top = -85
	toast.offset_bottom = -25
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(toast)

func own_objectives() -> PackedVector2Array:
	# Offline factory tour; real mission assignment is not implemented yet.
	return PackedVector2Array([factory.stations[guide_index].position])

func build_minimap() -> void:
	map_button = button("",open_map)
	map_button.name = "OpenFactoryMap"
	map_button.tooltip_text = "전체 지도 열기"
	map_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_button.offset_left = -safe_margin-264
	map_button.offset_right = -safe_margin
	map_button.offset_top = 145
	map_button.offset_bottom = 345
	ui.add_child(map_button)
	var caption := label("공장 지도   +",14,Color("d4e3d8"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	map_button.add_child(caption)
	mini_map = MiniMap.new()
	mini_map.name = "LocalOnlyMinimap"
	mini_map.layout = factory.layout
	mini_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mini_map.offset_top = 22
	mini_map.offset_bottom = -18
	map_button.add_child(mini_map)
	var legend := label("파랑: 나   ·   노랑: 안내 목표",11,Color("c2d0d0"))
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	legend.offset_top = -20
	map_button.add_child(legend)
	update_maps()

func update_maps() -> void:
	var points := own_objectives()
	if is_instance_valid(mini_map): mini_map.update_local(player.position,points)
	if is_instance_valid(map_view): map_view.update_local(player.position,points)
	if is_instance_valid(guide_label):
		guide_label.text = "안내 목표: " + str(factory.stations[guide_index].name)

func open_map() -> void:
	if not in_game or is_instance_valid(modal): return
	modal_kind = "map"
	paused = true
	joystick.reset()
	joystick.input_enabled = false
	player.enabled = false
	player.input_vector = Vector2.ZERO
	player.velocity = Vector2.ZERO
	modal = Control.new()
	modal.name = "ExpandedFactoryMap"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.025,0.04,0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var card := panel(center)
	var stack := VBoxContainer.new()
	card.add_child(stack)
	var heading := HBoxContainer.new()
	stack.add_child(heading)
	var title := label("공장 전체 지도",26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := button("닫기  ×",close_settings,true)
	close.name = "CloseFactoryMap"
	heading.add_child(close)
	map_view = MiniMap.new()
	map_view.name = "ExpandedLocalOnlyMap"
	map_view.layout = factory.layout
	map_view.expanded = true
	map_view.custom_minimum_size = Vector2(860,440)
	stack.add_child(map_view)
	stack.add_child(label("파랑: 나   ·   노랑: 설비 안내 목표   ·   지도 확인 중 이동 정지",16,Color("b8c9c7")))
	update_maps()
	if is_instance_valid(touch_debug): touch_debug.record("MODAL","open factory map")

func _process(delta: float) -> void:
	if not in_game or not is_instance_valid(player): return
	player.input_vector = joystick.vector if is_instance_valid(joystick) and not paused else Vector2.ZERO
	player.enabled = not paused
	if session.ready_to_play:
		player.authoritative = true
		player.server_target = session.own_position
	session.local_intent = player.desired_direction() if session.ready_to_play and not paused else Vector2.ZERO
	update_maps()
	if paused: return
	var room := factory.room_at(player.position)
	var zone := factory.layout.zone_at(player.position)
	if zone > 0: visited[factory.rooms[zone-1].id] = true
	location_label.text = room
	walk_distance += player.position.distance_to(previous_position)
	previous_position = player.position
	position_label.text = "방문한 방  %d / %d   ·   이동 %dm" % [visited.size(),factory.rooms.size(),int(walk_distance/80)]
	var station := factory.nearest_station(player.position)
	use_button.disabled = station.is_empty()
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0: toast.text = ""

func inspect_station() -> void:
	if paused: return
	var station := factory.nearest_station(player.position)
	if station.is_empty(): return
	show_toast("%s 설비를 확인했습니다. 미션 미니게임은 다음 단계에서 추가됩니다." % station.name,5)
	if station.id == factory.stations[guide_index].id:
		guide_index = (guide_index+1)%factory.stations.size()
	update_maps()

func show_toast(message: String, duration: float = 4) -> void:
	toast.text = message
	toast_time = duration

func show_settings() -> void:
	if is_instance_valid(modal): return
	modal_kind = "settings"
	paused = true
	if in_game:
		joystick.reset()
		joystick.input_enabled = false
		player.input_vector = Vector2.ZERO
		player.enabled = false
		player.velocity = Vector2.ZERO
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	if is_instance_valid(touch_debug): touch_debug.record("MODAL","open settings")
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.025,0.04,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var card := panel(center)
	card.custom_minimum_size.x = 530
	var stack := VBoxContainer.new()
	card.add_child(stack)
	stack.add_child(label("휴식 시간",32))
	stack.add_child(label("앱을 벗어나면 이동이 멈춥니다.",19,Color("a9bec5")))
	var toggle := CheckButton.new()
	toggle.text = "부드러운 카메라 이동"
	toggle.button_pressed = smooth_camera
	toggle.custom_minimum_size.y = 60
	toggle.toggled.connect(func(value: bool) -> void:
		smooth_camera = value
		if is_instance_valid(camera): camera.position_smoothing_enabled = value
		save_profile())
	stack.add_child(toggle)
	stack.add_child(button("계속하기",close_settings,true))
	if in_game: stack.add_child(button("메인 메뉴로",func() -> void: close_settings(); show_menu()))
	if in_game: build_network_settings(stack)
	stack.add_child(label(app_version + " • 개발 테스트",16,Color("90a8b4")))

func build_network_settings(stack: VBoxContainer) -> void:
	stack.add_child(label("멀티 이동 · 개발 서버 (선택)",16,Color("8dbab8")))
	var row := HBoxContainer.new()
	stack.add_child(row)
	var host := LineEdit.new()
	host.placeholder_text = "직접 실행한 서버 주소"
	host.text = network_host
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.custom_minimum_size.y = 48
	host.max_length = 253
	host.text_changed.connect(func(value: String) -> void: network_host = value.strip_edges(); save_profile())
	row.add_child(host)
	var port := LineEdit.new()
	port.text = str(network_port)
	port.custom_minimum_size = Vector2(92,48)
	port.max_length = 5
	port.text_changed.connect(func(value: String) -> void:
		if value.is_valid_int() and value.to_int()>0 and value.to_int()<=65535:
			network_port = value.to_int()
			save_profile())
	row.add_child(port)
	var buttons := HBoxContainer.new()
	stack.add_child(buttons)
	var connect_button := button("서버 연결",func() -> void:
		if network_host.is_empty():
			on_session_status("직접 실행한 서버 주소를 입력하세요")
			return
		var error := session.join(network_host,network_port,{"hat":hat,"vest":vest,"nickname":nickname})
		if error != OK: on_session_status("연결 요청 실패: "+error_string(error)))
	connect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(connect_button)
	buttons.add_child(button("연결 해제",session.disconnect_session))
	network_label = label(session.status_message,14,Color("b6c8c9"))
	network_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(network_label)

func on_session_status(message: String) -> void:
	if is_instance_valid(network_label): network_label.text = message
	if not in_game or not is_instance_valid(player): return
	if not session.ready_to_play:
		player.authoritative = false
		for worker in remote_workers.values(): worker.queue_free()
		remote_workers.clear()
		if is_instance_valid(joystick): joystick.reset()
	if is_instance_valid(toast): show_toast(message,5)

func sync_remote_workers() -> void:
	if not in_game or not is_instance_valid(player): return
	player.authoritative = true
	player.server_target = session.own_position
	for id in remote_workers.keys():
		if not session.public_peers.has(id):
			remote_workers[id].queue_free()
			remote_workers.erase(id)
	for id in session.public_peers:
		if id == session.own_id: continue
		var data: Dictionary = session.public_peers[id]
		if not remote_workers.has(id):
			var worker := Worker.new()
			worker.position = data.position
			worker.authoritative = true
			worker.server_target = data.position
			worker.hat = data.hat
			worker.vest = data.vest
			worker.nickname = data.nickname
			world.add_child(worker)
			remote_workers[id] = worker
		remote_workers[id].server_target = data.position
		remote_workers[id].facing = data.facing

func close_settings() -> void:
	if is_instance_valid(touch_debug): touch_debug.record("MODAL","close " + modal_kind)
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null
	modal_kind = ""
	map_view = null
	paused = false
	if is_instance_valid(player): player.enabled = true
	if in_game and is_instance_valid(joystick): joystick.input_enabled = true

func trace_button(kind: String, node: Button) -> void:
	if is_instance_valid(touch_debug):
		touch_debug.record(kind,"button=%s rect=%s screen=%s" % [node.text,node.get_global_rect(),screen_name])

func activate_button(node: Button, callback: Callable) -> void:
	trace_button("PRESSED",node)
	if ui_action_pending: return
	ui_action_pending = true
	run_ui_action.call_deferred(weakref(node),callback)

func run_ui_action(source: WeakRef, callback: Callable) -> void:
	var node = source.get_ref()
	if is_instance_valid(node) and node.is_inside_tree() and node.is_visible_in_tree():
		callback.call()
	ui_action_pending = false

func navigate_back() -> void:
	if is_instance_valid(modal): close_settings()
	elif screen_name == "customize": show_menu()
	else: show_settings()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			navigate_back()
		elif event.keycode == KEY_E and in_game:
			inspect_station()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if in_game and not paused: show_settings()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		navigate_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_profile()
		get_tree().quit()

func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("outfit","hat",hat)
	cfg.set_value("outfit","vest",vest)
	cfg.set_value("player","nickname",nickname)
	cfg.set_value("settings","smooth_camera",smooth_camera)
	cfg.set_value("network","host",network_host)
	cfg.set_value("network","port",network_port)
	cfg.save("user://profile.cfg")

func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://profile.cfg") != OK: return
	hat = clampi(int(cfg.get_value("outfit","hat",1)),0,2)
	vest = clampi(int(cfg.get_value("outfit","vest",0)),0,2)
	nickname = str(cfg.get_value("player","nickname","신입사원")).strip_edges().left(12)
	smooth_camera = bool(cfg.get_value("settings","smooth_camera",true))
	network_host = str(cfg.get_value("network","host","")).left(253)
	network_port = clampi(int(cfg.get_value("network","port",24560)),1,65535)
