extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func frames(n: int=5) -> void:
	for i in range(n): await physics_frame
func find_button(value: String,node: Node) -> Button:
	if node is Button and node.text==value:return node
	for child in node.get_children():
		var found:=find_button(value,child)
		if found:return found
	return null
func touch(p: Vector2,pressed: bool,index: int=0) -> void:
	var event:=InputEventScreenTouch.new()
	event.position=root.get_final_transform()*p;event.pressed=pressed;event.index=index
	Input.parse_input_event(event);Input.flush_buffered_events()
func tap(button: Button,index: int=0) -> void:
	var p:=button.get_global_rect().get_center()
	touch(p,true,index);await frames(2);touch(p,false,index);await frames(5)
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	assert(image!=null and image.get_width()>500)
	assert(image.save_png("res://builds/visual-"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await frames(6);await capture("menu")
	await tap(find_button("그림 속 모험",game.ui))
	assert(game.screen_name=="playing")
	await frames(10);await capture("village")
	var p: Vector2=game.joystick.get_global_rect().get_center()+Vector2(60,0)
	var origin: Vector2=game.player.position
	print("MOVE BEFORE paused=",game.paused," modal=",game.modal_kind," enabled=",game.joystick.input_enabled," finger=",game.joystick.finger)
	touch(p,true,0);await frames(15)
	print("MOVE AFTER origin=",origin," actual=",game.player.position," vector=",game.joystick.vector," finger=",game.joystick.finger," paused=",game.paused)
	if game.player.position.x<=origin.x+8:
		push_error("FAIL: packaged joystick movement");game.queue_free();await frames(3);quit(1);return
	await tap(game.spell_button,1)
	touch(p,false,0);await frames(30)
	assert(game.player.jar);await capture("jar")
	game.player.position=game.actors[3].position+Vector2(0,30)
	await frames(6)
	# Proximity is a visible UI state: wait for rendered UI frames after teleport setup.
	for i in range(3): await process_frame
	assert(game.interact_button.visible and game.nearest_npc==2)
	await tap(game.interact_button)
	assert(game.modal_kind=="dialogue" and game.talked_to_elder)
	await capture("dialogue")
	print("VISUAL PACKAGED SMOKE: PASS (menu, movement, two-finger spell, jar, elder dialogue, objective)")
	game.queue_free();await frames(3);quit()
