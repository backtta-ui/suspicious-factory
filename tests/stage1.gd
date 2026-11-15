extends SceneTree

var failures := 0
var checks := 0
var game: Node

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func walk(vector: Vector2, count: int) -> void:
	game.joystick.vector = vector
	await frames(count)
	game.joystick.reset()
	await frames(2)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	check(game.ui.get_child_count() > 0,"main menu loads")
	game.show_customize()
	await frames(3)
	for h in range(3):
		for v in range(3):
			game.hat = h
			game.vest = v
			game.update_outfit()
			check(game.preview.hat == h and game.preview.vest == v,"outfit %d / %d" % [h,v])
	game.start_game()
	await frames(5)
	check(game.player.position.distance_to(game.factory.layout.spawn) < 1,"spawn in clear corridor")
	check(game.factory.rooms.size() == 12,"twelve reference-layout rooms")
	check(game.camera.is_current(),"player follow camera active")
	var origin: Vector2 = game.player.position
	await walk(Vector2.RIGHT,30)
	check(game.player.position.x > origin.x+80,"joystick moves worker")
	game.player.position = Vector2(260,1840)
	await walk(Vector2.LEFT,35)
	check(game.player.position.x >= 224,"outer wall blocks player")
	game.player.position = Vector2(1800,1740)
	await walk(Vector2.UP,40)
	check(game.player.position.y >= 1624,"room wall blocks player")
	game.player.position = Vector2(2000,1740)
	await walk(Vector2.UP,45)
	check(game.player.position.y < 1600,"door admits player into production")
	game.player.position = Vector2(2000,1320)
	await walk(Vector2.UP,40)
	check(game.player.position.y >= 1256,"conveyor collision blocks player")
	game.player.position = game.factory.layout.spawn
	game.show_settings()
	await frames(3)
	origin = game.player.position
	await walk(Vector2.RIGHT,20)
	check(game.player.position.distance_to(origin) < 0.1,"settings freeze movement")
	game.close_settings()
	await frames(2)
	await walk(Vector2.RIGHT,15)
	check(game.player.position.x > origin.x+20,"resume restores movement")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.joystick.vector == Vector2.ZERO,"background resets touch and pauses")
	game.close_settings()
	await frames(2)
	# Touch ownership: a second finger cannot steal or release the joystick.
	var j: Control = game.joystick
	var center: Vector2 = j.global_position+j.size/2
	var touch := InputEventScreenTouch.new()
	touch.index = 1
	touch.pressed = true
	touch.position = center+Vector2(60,0)
	j._input(touch)
	check(j.finger == 1 and j.vector.x > 0.5,"touch acquires joystick")
	touch = InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = false
	touch.position = center
	j._input(touch)
	check(j.finger == 1,"unrelated finger release ignored")
	touch.index = 1
	j._input(touch)
	check(j.finger == -1 and j.vector == Vector2.ZERO,"release clears movement")
	# Every door can be traversed; machines do not obstruct the entrance.
	for door in game.factory.layout.doors:
		game.player.position = door.outside
		await walk(-door.normal,45)
		check(game.player.position.distance_to(door.outside) > 145,"door traversable for %s at %s" % [door.room,door.position])
	game.show_menu()
	await frames(4)
	check(not game.in_game,"return to main menu")
	game.start_game()
	await frames(3)
	check(game.player.position == game.factory.layout.spawn,"fresh game respawns")
	print("STAGE 1: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await frames(2)
	quit(0 if failures == 0 else 1)
