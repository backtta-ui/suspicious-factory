extends Node
const Actor = preload("res://scripts/woo/actor.gd")
const Village = preload("res://scripts/woo/village.gd")
const Layout = preload("res://scripts/woo/village_layout.gd")
const Save = preload("res://scripts/woo/save_game.gd")
const MobileButton = preload("res://scripts/woo/mobile_button.gd")
const Joystick = preload("res://scripts/joystick.gd")
const Ornament = preload("res://scripts/woo/ornament.gd")
const MiniMap = preload("res://scripts/woo/minimap.gd")
const TitleFont = preload("res://assets/fonts/WooTitle.otf")
const ArtFrames = preload("res://scripts/woo/art_frames.gd")
const DebugInput = preload("res://scripts/touch_debug.gd")
const FONT = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const INK := Color("191825")
const GOLD := Color("d8b87e")
var screen_name := "menu"
var active_context := "menu"
var ui_generation := 0
var action_pending := false
var layer: CanvasLayer
var ui: Control
var modal: Control
var modal_kind := ""
var world: WooVillage
var player: WooActor
var camera: Camera2D
var actors: Array[WooActor] = []
var joystick: TouchJoystick
var run_button: WooMobileButton
var interact_button: WooMobileButton
var spell_button: WooMobileButton
var hint: Label
var place_label: Label
var touch_debug: TouchDebug
var sound: WooSound
var settings := {"smooth_camera":true,"day_cycle":true,"sound":true}
var unlocked: Array = ["jar"]
var talked_to_elder := false
var quest_label: Label
var hud_map: WooLocalMinimap
var nearest_npc := -1
var near_well := false
var dialogue_index := 0
var dialogue_lines: Array = []
var dialogue_name := ""
var paused := false
var save_elapsed := 0.0
var saved_indicator := 0.0
var last_save_error := OK
var save_thread: Thread
var quitting := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	settings = Save.settings()
	sound = preload("res://scripts/woo/sound.gd").new()
	add_child(sound)
	sound.set_enabled(settings.sound)
	layer = CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	show_menu(false)
	touch_debug = DebugInput.new()
	touch_debug.target = self
	add_child(touch_debug)

func style(color: Color, radius: int = 5) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("8e744e")
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func text(value: String, font_size: int = 22, color: Color = Color("e8e1cc")) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	return label

func button(value: String, callback: Callable, primary: bool = false) -> WooMobileButton:
	var node := MobileButton.new()
	node.text = value
	var context := active_context
	var generation := ui_generation
	node.allowed = func() -> bool: return context==active_context and generation==ui_generation
	node.add_theme_stylebox_override("normal",style(Color("241e2b") if primary else Color("211d28")))
	node.add_theme_stylebox_override("hover",style(Color("403044")))
	node.add_theme_stylebox_override("pressed",style(Color("685057")))
	node.add_theme_stylebox_override("hover_pressed",style(Color("685057")))
	node.add_theme_stylebox_override("disabled",style(Color("1a2d34")))
	node.add_theme_color_override("font_color",Color("f4d99d") if primary else Color("e8e1cc"))
	node.add_theme_color_override("font_pressed_color",Color("fff4cd"))
	node.observed.connect(func(event: InputEvent) -> void:
		if is_instance_valid(touch_debug): touch_debug.observe(event,screen_name,ui))
	node.pressed.connect(func() -> void:
		if action_pending or quitting: return
		action_pending = true
		perform_action.call_deferred(weakref(node),callback))
	var ornament := Ornament.new()
	ornament.primary = primary
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.add_child(ornament)
	return node

func perform_action(source: WeakRef, callback: Callable) -> void:
	var node = source.get_ref()
	if is_instance_valid(node) and node.is_inside_tree() and node.usable():
		sound.play_clip("button")
		callback.call()
	action_pending = false

func new_ui() -> void:
	ui_generation += 1
	if is_instance_valid(ui):
		ui.hide()
		ui.queue_free()
	modal = null
	modal_kind = ""
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 22
	theme.set_constant("separation","VBoxContainer",12)
	theme.set_constant("separation","HBoxContainer",18)
	ui.theme = theme
	layer.add_child(ui)
	if is_instance_valid(touch_debug): touch_debug.record("SCREEN",screen_name)

func show_menu(save_before: bool = true) -> void:
	if save_before and screen_name=="playing": save_progress()
	if is_instance_valid(world):
		world.queue_free()
		world = null
	player = null
	camera = null
	actors.clear()
	paused = false
	screen_name = "menu"
	active_context = "menu"
	new_ui()
	var bg := TextureRect.new()
	bg.texture = preload("res://assets/woo/hd/title.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.04,0.025,0.07,0.14)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(shade)
	var title := text("도사",106,Color("f5e5c7"))
	title.add_theme_font_override("font",TitleFont)
	title.add_theme_color_override("font_outline_color",Color("3a2432"))
	title.add_theme_constant_override("outline_size",7)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.position=Vector2(790,78)
	title.size=Vector2(390,170)
	ui.add_child(title)
	var subtitle:=text("전우치",36,GOLD)
	subtitle.add_theme_font_override("font",TitleFont)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position=Vector2(790,228);subtitle.size.x=390
	ui.add_child(subtitle)
	var motto:=text("달빛에 숨고, 도술로 길을 열다",17,Color("ddd0bb"))
	motto.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	motto.position=Vector2(790,291);motto.size.x=390
	ui.add_child(motto)
	var menu:=VBoxContainer.new()
	menu.position=Vector2(795,342)
	menu.size=Vector2(380,284)
	ui.add_child(menu)
	menu.add_child(button("게임 시작",start_game.bind(false),true))
	var resume:=button("이어하기",start_game.bind(true))
	resume.disabled=Save.load_game().is_empty()
	menu.add_child(resume)
	menu.add_child(button("설정",show_settings))
	menu.add_child(button("종료",quit_game))
	var chapter:=text("第一章  ·  계월촌",16,GOLD)
	chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	chapter.position=Vector2(790,656);chapter.size.x=390
	ui.add_child(chapter)
	var version:=text("V%s   ·   싱글플레이 / 오프라인 저장" % ProjectSettings.get_setting("application/config/version"),14,Color("c3b7bc"))
	version.position=Vector2(30,676)
	ui.add_child(version)

func start_game(continue_existing: bool = false) -> void:
	if screen_name=="playing": return
	var saved := Save.load_game() if continue_existing else {}
	if continue_existing and saved.is_empty(): return
	screen_name = "playing"
	active_context = "hud"
	paused = false
	world = Village.new()
	add_child(world)
	world.cycle_enabled = settings.day_cycle
	if saved.has("time_of_day"): world.time_of_day = clampf(float(saved.time_of_day),0,1)
	player = Actor.new()
	player.name = "JeonWoochi"
	player.position = Vector2(saved.position[0],saved.position[1]) if not saved.is_empty() else Layout.SPAWN
	player.jar = bool(saved.get("jar",false))
	unlocked = saved.get("unlocked",["jar"])
	talked_to_elder = bool(saved.get("talked_to_elder",false))
	world.add_child(player)
	actors.append(player)
	for data in Layout.NPCS:
		var npc := Actor.new()
		npc.npc = true
		npc.npc_name = data.name
		npc.position = data.position
		npc.tint = Color.WHITE
		npc.npc_variant = actors.size()-1
		world.add_child(npc)
		actors.append(npc)
	camera = Camera2D.new()
	camera.zoom = Vector2(2,2)
	camera.offset = Vector2(0,-60)
	camera.position_smoothing_enabled = settings.smooth_camera
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(Layout.SIZE.x)
	camera.limit_bottom = int(Layout.SIZE.y)
	player.add_child(camera)
	camera.make_current()
	build_hud()
	save_elapsed = 0
	save_progress()

func build_hud() -> void:
	new_ui()
	var header:=PanelContainer.new()
	header.position=Vector2(26,16)
	header.add_theme_stylebox_override("panel",style(Color(0.10,0.07,0.13,0.92),8))
	ui.add_child(header)
	var row:=HBoxContainer.new();header.add_child(row)
	var portrait:=TextureRect.new()
	var atlas:=AtlasTexture.new()
	atlas.atlas=preload("res://assets/woo/hd/hero.png")
	var frame: Array=ArtFrames.HERO[34]
	atlas.region=Rect2(frame[0],frame[1],frame[2],frame[3])
	portrait.texture=atlas
	portrait.custom_minimum_size=Vector2(65,76)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var lines:=VBoxContainer.new();row.add_child(lines)
	lines.add_child(text("전우치",23,GOLD))
	place_label=text("계월촌 · 밤",15)
	lines.add_child(place_label)
	var quest:=PanelContainer.new()
	quest.position=Vector2(26,133)
	quest.add_theme_stylebox_override("panel",style(Color(0.10,0.065,0.12,0.9),6))
	ui.add_child(quest)
	var quest_lines:=VBoxContainer.new();quest.add_child(quest_lines)
	quest_lines.add_child(text("첫걸음",19,GOLD))
	quest_label=text("",16)
	quest_lines.add_child(quest_label)
	var settings_button:=button("메뉴  ☰",show_settings)
	settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	settings_button.offset_left=-280;settings_button.offset_right=-162
	settings_button.offset_top=24;settings_button.offset_bottom=88
	settings_button.add_theme_font_size_override("font_size",16)
	ui.add_child(settings_button)
	hud_map=MiniMap.new()
	hud_map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hud_map.offset_left=-150;hud_map.offset_right=-18
	hud_map.offset_top=10;hud_map.offset_bottom=142
	ui.add_child(hud_map)
	hint=text("주민에게 다가가 대화해 보세요",16,Color("e0cfbe"))
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left=350;hint.offset_right=-320;hint.offset_top=30
	hint.add_theme_color_override("font_outline_color",Color("211722"))
	hint.add_theme_constant_override("outline_size",4)
	ui.add_child(hint)
	joystick=Joystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position=Vector2(44,-210)
	joystick.size=Vector2(174,174)
	ui.add_child(joystick)
	run_button=button("달리기",func() -> void: pass)
	run_button.name="RunButton"
	place_action(run_button,-396,"run")
	run_button.button_down.connect(func() -> void: if is_instance_valid(player): player.running=true)
	run_button.button_up.connect(func() -> void: if is_instance_valid(player): player.running=false)
	spell_button=button("둔갑술",cast_spell,true)
	spell_button.name="SpellButton"
	place_action(spell_button,-148,"spell")
	interact_button=button("대화",interact)
	interact_button.name="InteractButton"
	place_action(interact_button,-272,"talk")

func place_action(node: WooMobileButton, top: int, icon: String) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	node.offset_left=-146;node.offset_right=-34
	node.offset_top=top;node.offset_bottom=top+112
	node.add_theme_font_size_override("font_size",18)
	for mode in ["normal","hover","pressed","hover_pressed","disabled"]:
		var box:=style(Color(0.12,0.08,0.13,0.92) if mode!="pressed" and mode!="hover_pressed" else Color("695056"),56)
		box.content_margin_left=8;box.content_margin_right=8
		box.content_margin_top=54;box.content_margin_bottom=8
		box.set_border_width_all(0)
		node.add_theme_stylebox_override(mode,box)
	for child in node.get_children():
		if child is WooOrnament: child.circular=true;child.icon=icon
	ui.add_child(node)

func set_paused(value: bool) -> void:
	paused = value
	for actor in actors:
		actor.enabled = not value
		actor.intent = Vector2.ZERO
		actor.velocity = Vector2.ZERO
	if is_instance_valid(player): player.running = false
	if is_instance_valid(joystick):
		joystick.reset()
		joystick.input_enabled = not value
	if is_instance_valid(run_button): run_button.cancel()

func open_modal(kind: String) -> VBoxContainer:
	if is_instance_valid(modal): return null
	if screen_name=="playing": set_paused(true)
	active_context = "modal"
	modal_kind = kind
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.06,0.08,0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 620
	card.add_theme_stylebox_override("panel",style(Color("1b343b"),10))
	center.add_child(card)
	var stack := VBoxContainer.new()
	card.add_child(stack)
	return stack

func close_modal() -> void:
	if is_instance_valid(modal):
		modal.hide()
		modal.queue_free()
	modal = null
	modal_kind = ""
	active_context = "hud" if screen_name=="playing" else "menu"
	if screen_name=="playing": set_paused(false)

func show_settings() -> void:
	var stack := open_modal("settings")
	if not stack: return
	stack.add_child(text("잠시 쉬어가기",30,GOLD))
	stack.add_child(button("카메라: "+("부드럽게" if settings.smooth_camera else "즉시 추적"),toggle_setting.bind("smooth_camera")))
	stack.add_child(button("낮과 밤 변화: "+("켜짐" if settings.day_cycle else "꺼짐"),toggle_setting.bind("day_cycle")))
	stack.add_child(button("효과음: "+("켜짐" if settings.sound else "꺼짐"),toggle_setting.bind("sound")))
	stack.add_child(button("돌아가기",close_modal,true))
	if screen_name=="playing":
		stack.add_child(button("저장하고 메인으로",func() -> void: close_modal(); show_menu()))
	stack.add_child(text("자동 저장  ·  계정과 서버 연결 없음",16,Color("9db3ac")))

func toggle_setting(key: String) -> void:
	settings[key] = not settings[key]
	Save.save_settings(settings)
	sound.set_enabled(settings.sound)
	if is_instance_valid(camera): camera.position_smoothing_enabled = settings.smooth_camera
	if is_instance_valid(world): world.cycle_enabled = settings.day_cycle
	close_modal()
	show_settings()

func cast_spell() -> void:
	if screen_name!="playing" or paused or not unlocked.has("jar"): return
	if player.begin_transform(): sound.play_clip("spell")

func interact() -> void:
	if screen_name!="playing" or paused: return
	if nearest_npc>=0:
		var data: Dictionary = Layout.NPCS[nearest_npc]
		if nearest_npc==2:
			talked_to_elder=true
			save_progress()
		dialogue_lines = data.lines
		dialogue_name = data.name
	elif near_well:
		dialogue_lines = ["차가운 우물물에 달빛이 흔들린다. 멀리서 방울 소리가 들려온다."]
		dialogue_name = "오래된 우물"
	else: return
	dialogue_index = 0
	show_dialogue()

func show_dialogue() -> void:
	sound.play_clip("dialogue")
	var stack := open_modal("dialogue")
	if not stack: return
	stack.add_child(text(dialogue_name,26,GOLD))
	var body := text(str(dialogue_lines[dialogue_index]),23)
	body.custom_minimum_size = Vector2(660,120)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	var row := HBoxContainer.new()
	stack.add_child(row)
	var next := button("다음" if dialogue_index<dialogue_lines.size()-1 else "대화 마치기",next_dialogue,true)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(next)
	row.add_child(button("닫기",close_modal))

func next_dialogue() -> void:
	close_modal()
	dialogue_index += 1
	if dialogue_index<dialogue_lines.size(): show_dialogue()

func finish_save() -> void:
	if save_thread != null:
		last_save_error = save_thread.wait_to_finish()
		save_thread = null

func _exit_tree() -> void:
	finish_save()

func save_progress(background: bool = false) -> void:
	if screen_name!="playing" or not is_instance_valid(player): return
	var data := {"schema":1,"map":Layout.MAP_ID,"position":[player.position.x,player.position.y],"settings":settings.duplicate(),"unlocked":unlocked.duplicate(),"jar":player.jar,"time_of_day":world.time_of_day,"talked_to_elder":talked_to_elder}
	# Serialize all writes. Exit/background/manual saves join any pending auto-save.
	finish_save()
	if background:
		save_thread = Thread.new()
		var error := save_thread.start(func() -> Error: return Save.save_game(data))
		if error != OK:
			save_thread = null
			last_save_error = error
	else:
		last_save_error = Save.save_game(data)
	saved_indicator = 2
	save_elapsed = 0

func quit_game() -> void:
	if quitting: return
	quitting=true
	save_progress()
	Save.save_settings(settings)
	sound.shutdown()
	# Let the audio server release a just-played button voice before engine shutdown.
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()

func _physics_process(_delta: float) -> void:
	# Sample touch on every movement tick, including frames delayed by HD texture upload.
	if screen_name=="playing" and is_instance_valid(player) and is_instance_valid(joystick):
		player.intent=joystick.vector if not paused else Vector2.ZERO
		player.enabled=not paused
		sound.update_steps(player.position,not paused and player.velocity.length()>2 and player.transforming<=0,player.jar)

func _process(delta: float) -> void:
	if save_thread != null and not save_thread.is_alive(): finish_save()
	if screen_name!="playing" or not is_instance_valid(player): return
	if is_instance_valid(hud_map): hud_map.update_local(player.position,talked_to_elder)
	if is_instance_valid(quest_label): quest_label.text="마을 어른과 대화하기 (%d/1)" % (1 if talked_to_elder else 0)
	spell_button.disabled = paused or player.cooldown>0 or player.transforming>0 or not unlocked.has("jar")
	spell_button.text = ("둔갑 %.1f" % player.cooldown) if player.cooldown>0 else ("인간 복귀" if player.jar else "둔갑술")
	run_button.disabled = player.jar or paused
	place_label.text = "계월촌  ·  "+("밤" if world.time_of_day>0.3 and world.time_of_day<0.7 else "낮")
	if paused: return
	nearest_npc = -1
	var nearest_distance := 58.0
	for i in range(Layout.NPCS.size()):
		var npc := actors[i+1]
		npc.highlighted = false
		var distance := player.position.distance_to(npc.position)
		if distance<nearest_distance:
			nearest_distance = distance
			nearest_npc = i
	if nearest_npc>=0: actors[nearest_npc+1].highlighted = true
	near_well = player.position.distance_to(Vector2(860,510))<60
	interact_button.visible = nearest_npc>=0 or near_well
	interact_button.text = "대화" if nearest_npc>=0 else "우물 조사"
	hint.text = (str(Layout.NPCS[nearest_npc].name)+" · 대화 가능") if nearest_npc>=0 else ("항아리 둔갑 중 · 이동 속도 감소" if player.jar else "주민과 대화하거나 마을을 탐험하세요")
	if saved_indicator>0:
		saved_indicator -= delta
		if last_save_error != OK: hint.text = "저장 실패: 기기 저장 공간을 확인하세요"
	save_elapsed += delta
	if save_elapsed>=8: save_progress(true)

func go_back() -> void:
	if is_instance_valid(modal): close_modal()
	elif screen_name=="playing": show_settings()
	else: show_settings()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE: go_back()
		elif event.keycode==KEY_SPACE: cast_spell()
		elif event.keycode==KEY_E: interact()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
		if screen_name=="playing":
			save_progress()
			if not is_instance_valid(modal): show_settings()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST: go_back()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()
