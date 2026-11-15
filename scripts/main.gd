extends Node

const Worker = preload("res://scripts/worker.gd")
const Map = preload("res://scripts/factory.gd")
const Joystick = preload("res://scripts/joystick.gd")
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

func _ready() -> void:
	get_tree().auto_accept_quit = false
	load_profile()
	setup_theme()
	layer = CanvasLayer.new()
	add_child(layer)
	show_menu()

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
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = get_viewport().get_meta("game_theme")
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

func label(text: String, font_size: int = 22, color: Color = Color("edf1e5")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	return node

func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 60
	node.pressed.connect(callback)
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
	in_game = false
	paused = false
	if is_instance_valid(world):
		world.queue_free()
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
	header.add_child(label("개발 테스트 01   •   0.1.0",18,Color("92a6b2")))
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
	if nickname.is_empty(): nickname = "신입사원"
	save_profile()
	in_game = true
	paused = false
	visited.clear()
	walk_distance = 0
	world = Node2D.new()
	add_child(world)
	factory = Map.new()
	world.add_child(factory)
	player = Worker.new()
	player.position = Vector2(700,1120)
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
	camera.limit_right = 3200
	camera.limit_bottom = 2200
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
	position_label = label("방문한 구역  0 / 8",17)
	info.add_child(position_label)
	info.add_child(label("노란 표시 근처에서 ‘설비 확인’\nPC: WASD / 방향키 · E 확인 · Esc 설정",16,Color("b6c8cc")))
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

func _process(delta: float) -> void:
	if not in_game or not is_instance_valid(player): return
	player.input_vector = joystick.vector if is_instance_valid(joystick) and not paused else Vector2.ZERO
	player.enabled = not paused
	if paused: return
	var room := factory.room_at(player.position)
	visited[room] = true
	location_label.text = room
	walk_distance += player.position.distance_to(previous_position)
	previous_position = player.position
	position_label.text = "방문한 구역  %d / 8   ·   이동 %dm" % [visited.size(),int(walk_distance/80)]
	var station := factory.nearest_station(player.position)
	use_button.disabled = station.is_empty()
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0: toast.text = ""

func inspect_station() -> void:
	if paused: return
	var station := factory.nearest_station(player.position)
	if station.is_empty(): return
	show_toast("%s 설비입니다. 미션 미니게임은 3차 개발에서 추가됩니다." % station.name,5)

func show_toast(message: String, duration: float = 4) -> void:
	toast.text = message
	toast_time = duration

func show_settings() -> void:
	if is_instance_valid(modal): return
	paused = true
	if in_game:
		joystick.reset()
		player.input_vector = Vector2.ZERO
		player.enabled = false
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
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
	stack.add_child(label("0.1.0 • 로컬 테스트 • 네트워크 연결 없음",16,Color("90a8b4")))

func close_settings() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null
	paused = false
	if is_instance_valid(player): player.enabled = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(modal): close_settings()
			else: show_settings()
		elif event.keycode == KEY_E and in_game:
			inspect_station()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if in_game and not paused: show_settings()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(modal): close_settings()
		else: show_settings()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_profile()
		get_tree().quit()

func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("outfit","hat",hat)
	cfg.set_value("outfit","vest",vest)
	cfg.set_value("player","nickname",nickname)
	cfg.set_value("settings","smooth_camera",smooth_camera)
	cfg.save("user://profile.cfg")

func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://profile.cfg") != OK: return
	hat = clampi(int(cfg.get_value("outfit","hat",1)),0,2)
	vest = clampi(int(cfg.get_value("outfit","vest",0)),0,2)
	nickname = str(cfg.get_value("player","nickname","신입사원")).strip_edges().left(12)
	smooth_camera = bool(cfg.get_value("settings","smooth_camera",true))
