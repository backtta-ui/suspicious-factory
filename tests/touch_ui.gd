extends SceneTree
## Real Input.parse_input_event -> Window stretch transform -> GUI -> signals -> scenes.
## Never calls Button.pressed.emit(), button callbacks or joystick._input().

var game: Node
var checks := 0
var failures := 0
var signals := {"down":0,"up":0,"pressed":0}

func _initialize() -> void:
	run.call_deferred()

func frames(count: int = 4) -> void:
	for i in range(count): await process_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func find_button(text: String, node: Node = null) -> Button:
	if node == null: node = game.ui
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := find_button(text,child)
		if found: return found
	return null

func wire(button: Button) -> void:
	signals = {"down":0,"up":0,"pressed":0}
	button.button_down.connect(func() -> void: signals.down += 1)
	button.button_up.connect(func() -> void: signals.up += 1)
	button.pressed.connect(func() -> void: signals.pressed += 1)

func touch(point: Vector2, pressed: bool, finger: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	# Input.parse_input_event takes native Window pixels, not logical GUI coordinates.
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(point: Vector2, finger: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = finger
	event.position = root.get_final_transform() * point
	event.relative = root.get_final_transform().basis_xform(Vector2(30,0))
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	touch(point,true)
	await frames(2)
	touch(point,false)
	await frames(5)

func worlds() -> int:
	var count := 0
	for child in game.get_children():
		if child is Node2D: count += 1
	return count

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(6)
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == true,"shipped configuration enables touch-to-mouse")
	check(Input.emulate_mouse_from_touch,"runtime touch-to-mouse enabled")
	# Negative control: old configuration must reproduce all three dead main buttons.
	Input.emulate_mouse_from_touch = false
	for text in ["공장 들어가기   →","캐릭터 꾸미기","설정"]:
		var button := find_button(text)
		wire(button)
		await tap(button)
		check(signals.pressed == 0 and game.screen_name == "menu" and not is_instance_valid(game.modal),"V0.1.0 negative control: no pressed signal for " + text)
	Input.emulate_mouse_from_touch = true
	# Physical landscape resolutions, letterboxing/scaling and reduced drawable area.
	for window_size in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(2340,1080),Vector2i(2280,1080),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size = window_size
		game.show_menu()
		await frames(6)
		var prefix := "%s " % window_size
		print("GEOMETRY window=",root.size," logical=",root.get_visible_rect()," transform=",root.get_final_transform())
		for text in ["공장 들어가기   →","캐릭터 꾸미기","설정"]:
			var button := find_button(text)
			check(not button.disabled and button.mouse_filter == Control.MOUSE_FILTER_STOP and button.get_global_rect().size.y >= 64,prefix+text+" enabled and touch-sized")
			check(root.get_visible_rect().encloses(button.get_global_rect()),prefix+text+" lies inside drawable viewport")
			check(button.get_theme_stylebox("normal").bg_color != button.get_theme_stylebox("pressed").bg_color,prefix+text+" pressed color differs from normal")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/touch-menu-%dx%d.png" % [window_size.x,window_size.y])
		# Settings: visible pressed feedback, release-only activation, return, Android back.
		var settings := find_button("설정")
		wire(settings)
		var center := settings.get_global_rect().get_center()
		touch(center,true)
		await frames(3)
		check(signals.down == 1 and settings.get_draw_mode() == BaseButton.DRAW_PRESSED,prefix+"settings press signal and visible pressed style")
		check(signals.pressed == 0 and not is_instance_valid(game.modal),prefix+"press alone does not activate")
		check(game.touch_debug.last_position.distance_to(center) < 0.05,prefix+"native pixel -> logical touch matches actual button center")
		touch(center,false)
		await frames(5)
		check(signals.up == 1 and signals.pressed == 1 and is_instance_valid(game.modal),prefix+"release activates settings exactly once")
		await tap(find_button("계속하기"))
		check(not is_instance_valid(game.modal) and game.screen_name == "menu",prefix+"settings continue returns to menu")
		await tap(find_button("설정"))
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames(4)
		check(not is_instance_valid(game.modal),prefix+"Android back closes settings")
		# Touch cancellation: releasing outside the button must not activate it.
		settings = find_button("설정")
		touch(settings.get_global_rect().get_center(),true)
		await frames(2)
		drag(Vector2(10,10))
		touch(Vector2(10,10),false)
		await frames(4)
		check(not is_instance_valid(game.modal),prefix+"release outside button cancels activation")
		# Actual GUI touches choose independent hat and vest buttons.
		await tap(find_button("캐릭터 꾸미기"))
		check(game.screen_name == "customize" and is_instance_valid(game.preview),prefix+"customization opens by touch")
		var rows: Array[Node] = []
		for node in game.ui.find_children("*","HBoxContainer",true,false):
			if node.get_child_count() == 3 and node.get_child(0) is Button:
				rows.append(node)
		check(rows.size() == 2,prefix+"independent hat and vest choices exist")
		if rows.size() == 2:
			await tap(rows[0].get_child(2))
			await tap(rows[1].get_child(1))
			check(game.hat == 2 and game.vest == 1 and game.preview.hat == 2 and game.preview.vest == 1,prefix+"green cap and blue vest selected through GUI")
			await tap(rows[0].get_child(1))
			await tap(rows[1].get_child(2))
			check(game.hat == 1 and game.vest == 2,prefix+"blue cap and green vest selected through GUI")
		await tap(find_button("← 메인 메뉴"))
		check(game.screen_name == "menu",prefix+"customization back button returns to menu")
		await tap(find_button("캐릭터 꾸미기"))
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames(4)
		check(game.screen_name == "menu",prefix+"Android back returns from customization")
		# Two rapid complete taps in one event cycle must not create two worlds.
		var enter := find_button("공장 들어가기   →")
		center = enter.get_global_rect().get_center()
		touch(center,true)
		touch(center,false)
		touch(center,true)
		touch(center,false)
		await frames(8)
		check(game.in_game and game.screen_name == "factory" and worlds() == 1,prefix+"rapid touches create exactly one factory world")
		check(is_instance_valid(game.player) and game.camera.is_current(),prefix+"worker spawned with tracking camera")
		# Real native touch and drag, alongside enabled emulated mouse events.
		var joystick: Control = game.joystick
		var origin: Vector2 = game.player.position
		center = joystick.get_global_rect().get_center()
		touch(center+Vector2(20,0),true)
		drag(center+Vector2(65,0))
		for i in range(20): await physics_frame
		check(joystick.finger == 0 and joystick.vector.x > 0.7 and not joystick.mouse_active,prefix+"native drag owns joystick; emulated mouse ignored")
		check(game.player.position.x > origin.x+25,prefix+"touch joystick moves worker")
		touch(center+Vector2(65,0),false)
		await frames(4)
		check(joystick.vector == Vector2.ZERO and joystick.finger == -1,prefix+"touch release clears joystick")
		# V0.2 map HUD and modal use the same native touch routing as buttons.
		check(game.mini_map.is_visible_in_tree(),prefix+"minimap automatically visible")
		check(not game.map_button.get_global_rect().intersects(joystick.get_global_rect()) and not game.map_button.get_global_rect().intersects(game.use_button.get_global_rect()),prefix+"minimap does not cover movement or task controls")
		check(not game.map_button.get_global_rect().intersects(find_button("설정  ☰").get_global_rect()),prefix+"minimap does not cover settings")
		check(game.mini_map.local_position.distance_to(game.player.position)<0.1,prefix+"blue local marker follows movement")
		check(game.mini_map.objectives == game.own_objectives() and game.mini_map.objectives.size()==1,prefix+"yellow markers contain only current personal objective")
		await tap(game.map_button)
		check(game.modal_kind == "map" and is_instance_valid(game.map_view),prefix+"touch minimap expands full floor plan")
		check(game.paused and not game.player.enabled and not joystick.input_enabled,prefix+"expanded map disables movement input")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/full-map-%dx%d.png" % [window_size.x,window_size.y])
		origin = game.player.position
		var key := InputEventKey.new()
		key.physical_keycode = KEY_D
		key.keycode = KEY_D
		key.pressed = true
		Input.parse_input_event(key)
		touch(center+Vector2(65,0),true)
		drag(center+Vector2(65,0))
		for i in range(8): await physics_frame
		check(game.player.position.distance_to(origin)<0.1 and joystick.vector == Vector2.ZERO,prefix+"map blocks native joystick and physical keyboard")
		key.pressed = false
		Input.parse_input_event(key)
		touch(center+Vector2(65,0),false)
		await tap(find_button("닫기  ×"))
		check(not is_instance_valid(game.modal) and not game.paused and joystick.input_enabled,prefix+"map close restores gameplay")
		touch(center+Vector2(65,0),true)
		drag(center+Vector2(65,0))
		for i in range(10): await physics_frame
		touch(center+Vector2(65,0),false)
		await frames(4)
		check(game.player.position.x > origin.x+10,prefix+"joystick works after map close")
		await tap(game.map_button)
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames(4)
		check(not is_instance_valid(game.modal) and not game.paused,prefix+"Android back closes expanded map")
		var old_guide: int = game.guide_index
		game.player.position = game.factory.stations[old_guide].position
		await frames(5)
		check(not game.use_button.disabled,prefix+"task button enabled near station")
		await tap(game.use_button)
		check(game.guide_index != old_guide and game.mini_map.objectives == game.own_objectives(),prefix+"task touch advances personal guide marker")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/factory-hud-%dx%d.png" % [window_size.x,window_size.y])
		# Modal must block joystick acquisition through the shade.
		await tap(find_button("설정  ☰"))
		origin = game.player.position
		touch(center+Vector2(65,0),true)
		drag(center+Vector2(65,0))
		for i in range(5): await physics_frame
		check(joystick.vector == Vector2.ZERO and game.player.position.distance_to(origin)<0.1,prefix+"settings shade blocks joystick movement")
		touch(center+Vector2(65,0),false)
		await tap(find_button("메인 메뉴로"))
		check(game.screen_name == "menu" and worlds() == 0,prefix+"settings menu return destroys old world")
	check(game.touch_debug.sequence > 0 and FileAccess.file_exists("user://touch-debug.log"),"touch diagnostics record coordinates, GUI, signals and screen transitions")
	print("TOUCH UI: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await frames(2)
	quit(0 if failures == 0 else 1)
