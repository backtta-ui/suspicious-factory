extends SceneTree
## 2.0.38 검증 캡처(20:9 1600×720): 4맵 바닥·벽·사물·표지판과 도술 이펙트.
## 결과는 /workspace/downloads/v2038_*.png
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
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
	image.save_png(OUT+name);print("RENDER SAVED ",OUT+name," ",image.get_size())
func wait_screen(target: String) -> void:
	for i in range(900):
		await process_frame
		if game.screen==target and not game.changing:return
func start(id: String) -> void:
	game.cleanup_match();game.build("lobby");await frames(4)
	game.preferred_role="daoist"
	game.create_room("2.0.38 화면",8,true,"",2,id)
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
	# ── 강남역: 자판기 코너(라벨 버그), 중앙 대합실, 카페
	await start("gangnam")
	clear_area()
	for shot in [{"p":Vector2(560,1090),"z":1.35,"n":"vending_corner"},
			{"p":Vector2(1650,1330),"z":1.15,"n":"lobby"},
			{"p":Vector2(1640,420),"z":1.35,"n":"cafe"}]:
		await place(shot.p,shot.z)
		await capture("v2038_map_gangnam_%s.png"%shot.n)
	# ── 동성로
	await start("dongseongno")
	clear_area()
	for shot in [{"p":Vector2(1600,1400),"z":1.15,"n":"center"},
			{"p":Vector2(1600,600),"z":1.35,"n":"arcade"},
			{"p":Vector2(1400,2100),"z":1.35,"n":"banwoldang"}]:
		await place(shot.p,shot.z)
		await capture("v2038_map_dongseongno_%s.png"%shot.n)
	# ── 해운대
	await start("haeundae")
	clear_area()
	for shot in [{"p":Vector2(1500,1750),"z":1.05,"n":"beach"},
			{"p":Vector2(2750,1900),"z":1.15,"n":"sea"},
			{"p":Vector2(600,1100),"z":1.35,"n":"promenade"}]:
		await place(shot.p,shot.z)
		await capture("v2038_map_haeundae_%s.png"%shot.n)
	# ── 조선 한양(서원)
	await start("seowon")
	clear_area()
	for shot in [{"p":Vector2(1650,1300),"z":1.15,"n":"yard"},
			{"p":Vector2(1200,700),"z":1.35,"n":"hanok"},
			{"p":Vector2(2350,1750),"z":1.35,"n":"pond"}]:
		await place(shot.p,shot.z)
		await capture("v2038_map_seowon_%s.png"%shot.n)
	print("V2038 MAPS RENDER DONE")
	quit(0)
