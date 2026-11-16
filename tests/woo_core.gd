extends SceneTree
const Layout = preload("res://scripts/worlds/plaza_layout.gd")
const Save = preload("res://scripts/woo/save_game.gd")
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func frames(n: int = 4) -> void:
	for i in range(n): await physics_frame
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
func touch(position: Vector2, down: bool, finger: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.position = root.get_final_transform()*position
	e.pressed = down
	e.index = finger
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func tap(button: Button) -> void:
	var p := button.get_global_rect().get_center()
	touch(p,true)
	await frames(2)
	touch(p,false)
	await frames(5)
func run() -> void:
	root.size = Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(6)
	check(ProjectSettings.get_setting("application/config/name")=="도사: 전우치","new game application title")
	check(Input.emulate_mouse_from_touch,"touch emulation kept enabled")
	for title in ["봉인의 밤 · 온라인","그림 속 모험","이어하기","설정","종료"]:
		check(find_button(title)!=null,"main menu button: "+title)
	await tap(find_button("그림 속 모험"))
	check(game.screen_name=="playing" and is_instance_valid(game.player),"native touch starts playable game")
	check(game.actors.size()==Layout.NPCS.size()+1,"one taoist and all village residents")
	check(Layout.PROPS.filter(func(p: Dictionary)->bool:return p.kind=="hanok").size()>=4,"original hanok buildings retained")
	check(game.player.sprite.texture!=null,"pixel character texture loaded")
	check(game.camera.is_current() and game.camera.zoom==Vector2(2,2),"quarter-view follow camera active")
	check(game.world.y_sort_enabled,"world depth sorts props and characters")
	check(game.hud_map.is_visible_in_tree(),"live local minimap visible")
	check(game.hud_map.local_position.distance_to(game.player.position)<1,"minimap reflects actual local position")
	check(not game.talked_to_elder and "0/1" in game.quest_label.text,"first-step objective starts incomplete")
	check(preload("res://scripts/woo/art_frames.gd").HERO.size()==48,"HD hero has eight directions and six animation phases")
	for direction in [Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1),Vector2.UP,Vector2(1,-1)]:
		game.player.position=Layout.SPAWN
		game.joystick.vector=direction.normalized()
		await frames(22)
		check(game.player.position.distance_to(Layout.SPAWN)>20,"movement direction "+str(direction))
	game.joystick.reset()
	await frames(2)
	game.player.position=Layout.SPAWN
	game.player.running=false
	game.joystick.vector=Vector2.RIGHT
	await frames(30)
	var walked: float = game.player.position.distance_to(Layout.SPAWN)
	game.player.position=Layout.SPAWN
	game.player.running=true
	await frames(30)
	check(game.player.position.distance_to(Layout.SPAWN)>walked*1.35,"running is faster than walking")
	game.player.running=false
	game.joystick.reset()
	game.player.position=Vector2(860,560)
	game.joystick.vector=Vector2.UP
	await frames(50)
	check(game.player.position.distance_to(Vector2(860,510))>=23.9,"well collision blocks movement")
	game.joystick.reset()
	game.player.position=Vector2(710,390)
	game.joystick.vector=Vector2.UP
	await frames(40)
	check(game.player.position.y>=367,"hanok footprint blocks movement")
	game.joystick.reset()
	game.player.position=Layout.SPAWN
	await frames(3)
	await tap(game.spell_button)
	check(game.player.transforming>0,"spell starts visible transformation animation")
	await frames(30)
	check(game.player.jar and game.player.cooldown>0,"transformed into jar with cooldown")
	check(not game.player.begin_transform(),"cooldown rejects repeated spell")
	game.joystick.vector=Vector2.RIGHT
	var start: Vector2=game.player.position
	await frames(30)
	check(game.player.position.distance_to(start)<walked*0.75,"jar movement slower than human")
	game.joystick.reset()
	await frames(160)
	await tap(game.spell_button)
	await frames(30)
	check(not game.player.jar,"spell returns jar to human")
	for i in range(3):
		game.player.position=game.actors[i+1].position+Vector2(0,30)
		await frames(5)
		check(game.interact_button.visible and game.nearest_npc==i,"proximity dialogue available for NPC %d" % i)
		await tap(game.interact_button)
		check(game.modal_kind=="dialogue" and game.paused,"NPC dialogue opens and stops movement")
		await tap(find_button("닫기"))
		check(not game.paused and not is_instance_valid(game.modal),"dialogue closes cleanly")
	check(game.talked_to_elder and "1/1" in game.quest_label.text,"elder dialogue completes actual first-step objective")
	game.player.position=Layout.SPAWN+Vector2(32,0)
	await frames(2)
	game.save_progress()
	check(game.last_save_error==OK and Save.valid(Save.load_game()),"atomic local save contains valid map and position")
	var saved: Dictionary=Save.load_game()
	check(saved.unlocked.has("jar") and saved.settings.has("smooth_camera"),"save stores spell unlock and settings")
	check(saved.talked_to_elder,"objective completion persisted")
	await tap(find_button("메뉴  ☰"))
	await tap(find_button("저장하고 메인으로"))
	check(game.screen_name=="menu" and not find_button("이어하기").disabled,"saved game enables continue")
	await tap(find_button("이어하기"))
	check(game.player.position.distance_to(Vector2(saved.position[0],saved.position[1]))<2,"continue restores position")
	var before: Vector2=game.player.position
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(3)
	check(game.paused and game.joystick.vector==Vector2.ZERO,"background saves and cancels movement")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	check(not game.paused,"Android back closes pause menu")
	check(not Save.valid({"schema":1,"map":"bad","position":[900,610],"unlocked":[]}),"save rejects unknown map")
	check(not Save.valid({"schema":1,"map":Layout.MAP_ID,"position":[INF,0],"unlocked":[]}),"save rejects nonfinite/outside coordinates")
	check(game.world.lanterns.size()>=13,"expanded lantern network created")
	var old_time: float=game.world.time_of_day
	await frames(5)
	check(game.world.time_of_day!=old_time,"day-night atmosphere advances")
	print("WOO CORE: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await frames(3)
	quit(0 if failures==0 else 1)
