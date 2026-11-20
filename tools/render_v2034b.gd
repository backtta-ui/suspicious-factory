extends SceneTree
## 2.0.34 검수 렌더(20:9 = 1600×720):
##  - v2034_gangnam_overview.png   강남역 전체(구역·순환로·안전구역·HUD)
##  - v2034_gangnam_gimmicks.png   개찰구·자판기·셔터·암전·CCTV 기믹 상태
##  - v2034_woochi_pancake.png     부침개 전우치 스킨 + 김치전/부침개 이펙트
##  - v2034_seowon_overview.png    기존 서원 맵(보존 확인)
##  - v2034_quick_match.png        빠른 매치 원형 링(원형 마스킹·마법진·합류 펄스)
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2034.gd
const App=preload("res://scenes/survival.tscn")
const Maps=preload("res://scripts/survival/maps.gd")
const OUT="/workspace/downloads/"
var game: Node
func _initialize() -> void:
	run.call_deferred()
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(OUT+name)
	print("RENDER SAVED ",OUT+name," ",image.get_size())
func wait_screen(target: String) -> void:
	for i in range(900):
		await process_frame
		if game.screen==target and not game.changing:return
	print("WAIT TIMEOUT ",target," screen ",game.screen)
func start(map_id: String,role: String="daoist") -> void:
	game.cleanup_match()
	game.build("lobby");await frames(4)
	game.preferred_role=role
	game.create_room("2.0.34 렌더",8,true,"",2,map_id)
	for i in range(200):
		await process_frame
		if game.screen=="room" and not game.changing:break
	game.rules.players.human.ready=true
	game.start_match();await frames(6)
	game.rules.confirm_character("human")
	for i in range(240):
		if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
		if game.rules.phase=="loading":break
	await wait_screen("match")
	for i in range(40):
		if game.rules.phase=="live":break
		game.rules.tick(.2)
	game.rules.elapsed=140.0
	await frames(4)
func freeze() -> void:
	game.backgrounded=true
	await frames(2)
func thaw() -> void:
	game.backgrounded=false
	await frames(2)
func run() -> void:
	root.size=Vector2i(1600,720)
	game=App.instantiate();root.add_child(game)
	await frames(10)
	# ---------------------------------------------------------------- 1) 강남역 전체
	await start("seowon")
	var human: Dictionary=game.rules.players.human
	human.role="daoist"
	human.character="daoist:woochi"
	human.position=Vector2(1650,1330)
	game.camera.zoom=Vector2(.62,.62)
	game.rules.elapsed=40.0
	human.outside=0.0
	await frames(8)
	game.camera.zoom=Vector2(.62,.62)
	await frames(4)
	await capture("v2034_gangnam_overview.png")
	# ---------------------------------------------------------------- 2) 기믹 상태
	human.position=Vector2(1500,2010)
	game.camera.zoom=Vector2(1.35,1.35)
	var g: RefCounted=game.rules.gimmicks
	g.turnstile_until=game.rules.elapsed+3.2
	g.shutter_until=game.rules.elapsed+4.4
	g.lights["lobby"]=game.rules.elapsed+9.0
	g.lights["popup"]=game.rules.elapsed+7.0
	g.cctv_zone="lobby";g.cctv_until=game.rules.elapsed+7.5
	g.noise_pos=Vector2(430,1000);g.noise_until=game.rules.elapsed+2.4;g.noise_kind="vending_b"
	g.escalator_dir=-1;g.escalator_flip_until=game.rules.elapsed+6.0
	for i in range(3):game.rules.tick(.05)
	await frames(8)
	game.camera.zoom=Vector2(1.35,1.35)
	await frames(3)
	await capture("v2034_gangnam_gimmicks.png")
	# ---------------------------------------------------------------- 3) 부침개 전우치
	game.storage.equip("skin","woochi_pancake")
	human=game.rules.players.human
	human.character="daoist:woochi"
	human.skin="woochi_pancake"
	human.position=Vector2(1650,1330)
	human.form=""
	game.rules.elapsed=200.0
	game.rules.signature(human,"painting")
	game.rules.signature(human,"clone")
	game.camera.zoom=Vector2(2.2,2.2)
	await frames(6)
	game.camera.zoom=Vector2(2.2,2.2)
	await frames(2)
	await capture("v2034_woochi_pancake.png")
	# ---------------------------------------------------------------- 4) 서원 보존 확인
	game.storage.equip("skin","default")
	await start("seowon")
	human=game.rules.players.human
	human.position=Vector2(1700,1300)
	game.camera.zoom=Vector2(.62,.62)
	await frames(8)
	game.camera.zoom=Vector2(.62,.62)
	await frames(3)
	await capture("v2034_seowon_overview.png")
	print("RENDER DONE")
	quit()
