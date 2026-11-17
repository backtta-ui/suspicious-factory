extends SceneTree
const Layout = preload("res://scripts/worlds/plaza_layout.gd")
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func frames(n: int = 4) -> void:
	for i in range(n): await physics_frame
	await preload("res://tests/loading_wait.gd").settle(self,0)
func check(ok: bool, detail: String) -> void:
	checks += 1
	if ok: print("PASS: "+detail)
	else:
		failures += 1
		push_error("FAIL: "+detail)
func find_button(value: String, node: Node = null) -> Button:
	if node==null: node=game.ui
	if node is Button and node.text==value: return node
	for child in node.get_children():
		var result := find_button(value,child)
		if result: return result
	return null
func touch(point: Vector2, down: bool, finger: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.position=root.get_final_transform()*point
	e.index=finger
	e.pressed=down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func drag(point: Vector2, finger: int = 0) -> void:
	var e := InputEventScreenDrag.new()
	e.position=root.get_final_transform()*point
	e.index=finger
	e.relative=Vector2(30,0)
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func tap(button: Button, finger: int = 0) -> void:
	var p:=button.get_global_rect().get_center()
	touch(p,true,finger)
	await frames(2)
	touch(p,false,finger)
	await frames(5)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/woo-"+name+".png")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	for dimensions in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(2340,1080),Vector2i(2280,1080),Vector2i(960,540)]:
		root.size=dimensions
		game.show_menu(false)
		await frames(6)
		var prefix := str(dimensions)+" "
		for title in ["봉인의 밤 · 온라인","그림 속 모험","이어하기","설정","종료"]:
			var button:=find_button(title)
			check(root.get_visible_rect().encloses(button.get_global_rect()),prefix+title+" touch bounds visible")
		await capture("menu-%dx%d" % [dimensions.x,dimensions.y])
		var settings:=find_button("설정")
		var p:=settings.get_global_rect().get_center()
		touch(p,true)
		await frames(2)
		check(settings.get_draw_mode() in [BaseButton.DRAW_PRESSED,BaseButton.DRAW_HOVER_PRESSED] and not is_instance_valid(game.modal),prefix+"pressed feedback without premature activation")
		touch(p,false)
		await frames(5)
		check(game.modal_kind=="settings",prefix+"release opens settings")
		var old_smooth: bool=game.settings.smooth_camera
		await tap(find_button("카메라: "+("부드럽게" if old_smooth else "즉시 추적")))
		check(game.settings.smooth_camera!=old_smooth,prefix+"camera preference changes through touch")
		var old_day: bool=game.settings.day_cycle
		await tap(find_button("낮과 밤 변화: "+("켜짐" if old_day else "꺼짐")))
		check(game.settings.day_cycle!=old_day,prefix+"day/night preference changes through touch")
		var old_sound: bool=game.settings.sound
		var sound_button:=find_button("효과음: "+("켜짐" if old_sound else "꺼짐"))
		check(root.get_visible_rect().encloses(sound_button.get_global_rect()),prefix+"sound control fits viewport")
		await tap(sound_button)
		check(game.settings.sound!=old_sound and game.sound.enabled==game.settings.sound,prefix+"native touch changes sound preference")
		await tap(find_button("돌아가기"))
		check(not is_instance_valid(game.modal),prefix+"settings touch close works")
		# Releasing outside cancels. Emulated mouse may not cause a second callback.
		settings=find_button("설정")
		touch(settings.get_global_rect().get_center(),true)
		drag(Vector2(10,10))
		touch(Vector2(10,10),false)
		await frames(3)
		check(not is_instance_valid(game.modal),prefix+"release outside cancels settings")
		var start:=find_button("그림 속 모험")
		p=start.get_global_rect().get_center()
		touch(p,true);touch(p,false);touch(p,true);touch(p,false)
		await frames(8)
		var worlds:=0
		for child in game.get_children():
			if child is WooStoryPlaza: worlds+=1
		check(game.screen_name=="playing" and worlds==1,prefix+"rapid touch starts exactly one world")
		await capture("village-%dx%d" % [dimensions.x,dimensions.y])
		var stick: Control=game.joystick
		var center:=stick.get_global_rect().get_center()
		var origin: Vector2=game.player.position
		touch(center+Vector2(35,0),true,0)
		drag(center+Vector2(68,0),0)
		await frames(20)
		check(game.player.position.x>origin.x+15 and stick.finger==0,prefix+"native joystick moves player")
		# Second finger can hold run while first finger keeps moving.
		var run_center: Vector2=game.run_button.get_global_rect().get_center()
		touch(run_center,true,1)
		await frames(5)
		check(game.player.running and stick.finger==0,prefix+"two-finger running while steering")
		touch(run_center,false,1)
		await frames(3)
		check(not game.player.running and stick.finger==0,prefix+"run release does not steal joystick finger")
		# Native second-finger spell touch must work even with mouse emulation owned by finger 0.
		await tap(game.spell_button,1)
		check(game.player.transforming>0 or game.player.jar,prefix+"second-finger spell while steering")
		touch(center+Vector2(68,0),false,0)
		await frames(30)
		check(stick.vector==Vector2.ZERO and game.player.jar,prefix+"release stops steering and completes jar transformation")
		await capture("jar-%dx%d" % [dimensions.x,dimensions.y])
		await tap(find_button("메뉴  ☰"))
		origin=game.player.position
		touch(center+Vector2(68,0),true,0)
		drag(center+Vector2(68,0),0)
		await frames(6)
		check(game.player.position.distance_to(origin)<0.1 and stick.vector==Vector2.ZERO,prefix+"modal blocks underlying controls")
		touch(center,false,0)
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames(3)
		check(not game.paused,prefix+"Android back resumes gameplay")
		# Nearby actor yields dialogue button; dialog next and close are native touches.
		game.player.position=game.actors[1].position+Vector2(0,28)
		await frames(5)
		await tap(game.interact_button)
		check(game.modal_kind=="dialogue" and game.paused,prefix+"NPC interaction opens dialogue")
		await capture("dialogue-%dx%d" % [dimensions.x,dimensions.y])
		await tap(find_button("다음"))
		check(game.dialogue_index==1 and game.modal_kind=="dialogue",prefix+"dialogue next works")
		await tap(find_button("닫기"))
		check(not game.paused,prefix+"dialogue close restores movement")
		await tap(find_button("메뉴  ☰"))
		await tap(find_button("저장하고 메인으로"))
		check(game.screen_name=="menu" and not find_button("이어하기").disabled,prefix+"save/menu return enables continue")
		await tap(find_button("이어하기"))
		check(game.screen_name=="playing" and game.player.jar,prefix+"continue restores saved map and form")
		game.show_menu()
		await frames(4)
	print("WOO TOUCH: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await frames(3)
	quit(0 if failures==0 else 1)
