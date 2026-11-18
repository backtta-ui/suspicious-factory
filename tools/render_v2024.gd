extends SceneTree
## 2.0.24 로비 화풍 통일 8인 원화 검수 렌더 (도감·캐릭터 선택·상점·인게임).
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2024.gd
const App=preload("res://scenes/survival.tscn")
const OUT="/workspace/work/lobby_style_chars/render/"
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
	for i in range(240):
		await process_frame
		if game.screen==target and not game.changing:return

func prepare_selection() -> void:
	game.create_room("월하의 모의전",8,true,"달빛-2319",2)
	await wait_screen("room")
	for p in game.rules.players.values():p.ready=true
	game.rules.start()
	game.selection_id=String(game.storage.data[game.rules.players.human.role])
	game.build("selection")
	await wait_screen("selection")
	for i in range(45):game.rules.tick(.1)
	game.rules.select_character("human",game.selection_id)
	game.rules.selection_elapsed=0.0
	game.build("selection")
	await wait_screen("selection")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(14)
	game.storage.data.coins=2400

	game.build("lobby");await frames(10)
	await capture("v2024_lobby_wide.png")

	game.build("characters");await frames(10)
	await capture("v2024_codex_wide.png")

	game.build("market");await frames(10)
	await capture("v2024_shop_wide.png")

	await prepare_selection()
	await frames(10)
	await capture("v2024_selection_wide.png")
	root.size=Vector2i(1920,1080)
	await frames(10)
	await capture("v2024_selection_16x9.png")
	root.size=Vector2i(2340,1080)
	await frames(8)

	game.build("lobby")
	await frames(4)
	game.preferred_role="daoist"
	game.start_practice_match()
	await wait_screen("match")
	await frames(20)
	game.set_process(false)
	var me: Dictionary=game.rules.players.human
	me.position=Vector2(830,730)
	me.ground=me.position
	game.update_avatars()
	await frames(4)
	for i in range(40):
		game.rules.phase="live"
		game.rules.command("human","move",{"vector":Vector2(-.4,0)})
		game.rules.tick(1.0/60.0)
		game.update_avatars()
		await process_frame
	await frames(6)
	await capture("v2024_ingame_wide.png")
	game.set_process(true)

	game.build("characters");await frames(8)
	root.size=Vector2i(1920,1080)
	await frames(10)
	await capture("v2024_codex_16x9.png")
	print("V2024 RENDER DONE")
	quit()
