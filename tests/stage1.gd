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
	check(game.player.position.distance_to(Vector2(700,1120)) < 1,"spawn in clear corridor")
	check(game.factory.rooms.size() == 7,"seven factory rooms plus corridor")
	check(game.camera.is_current(),"player follow camera active")
	var origin: Vector2 = game.player.position
	await walk(Vector2.RIGHT,30)
	check(game.player.position.x > origin.x+80,"joystick moves worker")
	game.player.position = Vector2(110,1100)
	await walk(Vector2.LEFT,35)
	check(game.player.position.x >= 76,"outer wall blocks player")
	game.player.position = Vector2(400,1020)
	await walk(Vector2.UP,40)
	check(game.player.position.y >= 976,"room wall blocks player")
	game.player.position = Vector2(700,1030)
	await walk(Vector2.UP,45)
	check(game.player.position.y < 930,"door admits player into production")
	game.player.position = Vector2(480,530)
	await walk(Vector2.UP,40)
	check(game.player.position.y >= 471,"conveyor collision blocks player")
	game.player.position = Vector2(700,1120)
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
	for door in [Vector2(700,1030),Vector2(1900,1030),Vector2(2700,1030),Vector2(450,1170),Vector2(1200,1170),Vector2(1950,1170),Vector2(2700,1170)]:
		game.player.position = door
		var direction := Vector2.UP if door.y < 1100 else Vector2.DOWN
		await walk(direction,45)
		check(absf(game.player.position.y-door.y) > 145,"door traversable at %s" % door)
	game.show_menu()
	await frames(4)
	check(not game.in_game,"return to main menu")
	game.start_game()
	await frames(3)
	check(game.player.position == Vector2(700,1120),"fresh game respawns")
	print("STAGE 1: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await frames(2)
	quit(0 if failures == 0 else 1)
