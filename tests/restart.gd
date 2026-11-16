extends SceneTree
const Layout = preload("res://scripts/worlds/plaza_layout.gd")
const Save = preload("res://scripts/woo/save_game.gd")
var game: Node
var mode := "read"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
	run.call_deferred()
func frames(n: int = 4) -> void:
	for i in range(n): await physics_frame
func find_button(title: String, node: Node) -> Button:
	if node is Button and node.text==title: return node
	for child in node.get_children():
		var b:=find_button(title,child)
		if b: return b
	return null
func tap(button: Button) -> void:
	var p:=root.get_final_transform()*button.get_global_rect().get_center()
	for pressed in [true,false]:
		var e:=InputEventScreenTouch.new()
		e.index=0;e.position=p;e.pressed=pressed
		Input.parse_input_event(e);Input.flush_buffered_events()
		await frames(3)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await frames(5)
	if mode=="write":
		await tap(find_button("그림 속 모험",game.ui))
		game.player.position=Layout.SPAWN+Vector2(32,0)
		game.player.jar=true
		game.settings.smooth_camera=false
		Save.save_settings(game.settings)
		game.save_progress()
		if game.last_save_error!=OK: quit(1);return
		print("RESTART WRITE: position/map/settings/unlock/form saved; exiting actual game")
		game.quit_game()
	elif mode=="read":
		var b:=find_button("이어하기",game.ui)
		if b.disabled: push_error("Continue disabled after process restart");quit(1);return
		await tap(b)
		var valid: bool=game.player.position.distance_to(Layout.SPAWN+Vector2(32,0))<1 and game.player.jar and game.settings.smooth_camera==false and game.unlocked.has("jar")
		if not valid: push_error("Saved state failed across process restart");quit(1);return
		print("RESTART READ: persisted position, map, settings, spell and form restored")
		game.quit_game()
	elif mode=="exit":
		print("EXIT TEST: pressing main-menu exit through native touch")
		var p:=root.get_final_transform()*find_button("종료",game.ui).get_global_rect().get_center()
		var e:=InputEventScreenTouch.new()
		e.position=p;e.pressed=true;e.index=0
		Input.parse_input_event(e);Input.flush_buffered_events()
		await frames(3)
		e=InputEventScreenTouch.new()
		e.position=p;e.pressed=false;e.index=0
		Input.parse_input_event(e);Input.flush_buffered_events()
		# Do not leave an awaited coroutine alive while testing actual engine shutdown.
		var timeout:=Timer.new()
		timeout.one_shot=true
		timeout.wait_time=2
		timeout.timeout.connect(func() -> void: push_error("Exit button failed to quit process");quit(1))
		root.add_child(timeout)
		timeout.start()
