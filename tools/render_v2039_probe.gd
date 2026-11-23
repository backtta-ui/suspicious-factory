extends SceneTree
## 2.0.39 화풍 점검용 빠른 캡처(맵 1~4, 도술 1~2컷). 결과: /workspace/downloads/v2039_probe_*.png
const App=preload("res://scenes/survival.tscn")
const OUT="/workspace/downloads/"
var game: Node
var L: Script
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func capture(name: String) -> void:
	for i in range(3):await process_frame
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty():print("EMPTY ",name);return
	image.save_png(OUT+name);print("RENDER SAVED ",name)
func wait_screen(target: String) -> void:
	for i in range(900):
		await process_frame
		if game.screen==target and not game.changing:return
func start(id: String) -> void:
	game.cleanup_match();game.build("lobby");await frames(4)
	game.preferred_role="daoist"
	game.create_room("2.0.39 점검",8,true,"",2,id)
	for i in range(240):
		await process_frame
		if game.screen=="room" and not game.changing:break
	game.rules.players.human.ready=true
	game.start_match();await frames(6)
	game.rules.confirm_character("human")
	for i in range(300):
		if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
		if game.rules.phase=="loading":break
		await process_frame
	await wait_screen("match")
	for i in range(80):
		if game.rules.phase=="live":break
		game.rules.tick(.2)
	L=game.L
	game.rules.elapsed=120.0
	game.rules.players.human.immune=game.rules.elapsed+300.0
	game.banner_left=0.0
func place(at: Vector2,zoom: float=1.45) -> void:
	var human: Dictionary=game.rules.players.human
	human.position=at;human.ground=at;human.captured=false;human.eliminated=false
	game.update_avatars()
	game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
	game.camera.zoom=Vector2(zoom,zoom)
	await frames(4)
	game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
	game.camera.zoom=Vector2(zoom,zoom)
	await frames(2)
func clear_area() -> void:
	for p in game.rules.players.values():
		if String(p.id)=="human":continue
		var far: Vector2=L.SPAWN+Vector2(60,60)
		p.position=far;p.ground=far;p.intent=Vector2.ZERO;p.captured=false;p.eliminated=true
		var actor: Node=game.avatars.get(String(p.id))
		if actor!=null:actor.visible=false
	game.update_avatars()
func run() -> void:
	root.size=Vector2i(1600,720)
	game=App.instantiate();root.add_child(game);await frames(10)
	var only:=OS.get_environment("V39_MAPS")
	var maps: Array=["gangnam","dongseongno","haeundae","seowon"] if only=="" else only.split(",")
	var spots={"gangnam":Vector2(560,1090),"dongseongno":Vector2(1600,1400),"haeundae":Vector2(2100,1850),"seowon":Vector2(1650,1300)}

	for map_id in maps:
		await start(map_id)
		clear_area()
		var at: Vector2=spots[map_id]
		var at_env:=OS.get_environment("V39_AT")
		if at_env!="":
			var parts:=at_env.split(",")
			at=Vector2(float(parts[0]),float(parts[1]))
		await place(at,float(OS.get_environment("V39_Z")) if OS.get_environment("V39_Z")!="" else 1.20)
		await capture("v2039_probe_%s.png"%map_id)
	print("V2039 PROBE DONE zoom=",game.camera.zoom," pos=",game.rules.players.human.position," map=",game.rules.map_id)
	quit(0)
