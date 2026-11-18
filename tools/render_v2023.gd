extends SceneTree
## 2.0.23 UI 상업 퀄리티 검수 렌더: 20:9(갤럭시 S26+ 2340×1080) 및 16:9(1920×1080).
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2023.gd
const App=preload("res://scenes/survival.tscn")
var game: Node
var only:=""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
	run.call_deferred()

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(path)
	print("RENDER SAVED ",path," ",image.get_size())

func wait_screen(target: String) -> void:
	for i in range(200):
		await process_frame
		if game.screen==target and not game.changing:return

## 도사 진영 8인 방을 만들고 캐릭터 선택까지 간다.
func prepare_room(yokai_first: bool=false) -> void:
	game.create_room("월하의 모의전",8,true,"달빛-2319",2)
	await wait_screen("room")
	for p in game.rules.players.values():p.ready=true
	game.rules.start()
	game.selection_id=String(game.storage.data[game.rules.players.human.role])
	game.build("selection")
	await wait_screen("selection")
	# 봇들이 1.2초 뒤부터 차례로 캐릭터를 확정한다 → 실제 플레이처럼 8/8 상태로 렌더.
	for i in range(45):game.rules.tick(.1)
	game.rules.select_character("human",game.selection_id)
	game.rules.selection_elapsed=0.0
	game.build("selection")
	await wait_screen("selection")

func run() -> void:
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(12)
	game.storage.data.coins=2400
	if only=="ingame":
		game.build("lobby")
		await frames(4)
		# 시안과 같은 도사 시점으로 렌더(요괴 외곽 스폰은 밤 지대라 화면이 어둡다).
		game.preferred_role="daoist"
		game.start_practice_match()
		await wait_screen("match")
		await frames(20)
		# 캐릭터를 남서쪽으로 걷게 해 보행 프레임·먼지·카메라 추적을 함께 확인한다.
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
		await capture("/workspace/downloads/v2023_ingame_wide.png")
		game.set_process(true)
		root.size=Vector2i(1920,1080)
		await frames(12)
		await capture("/workspace/downloads/v2023_ingame_16x9.png")
		print("V2023 RENDER DONE")
		quit()
		return
	if only=="wide16":
		root.size=Vector2i(1920,1080)
		await frames(8)
		for spec in [["market","shop"],["achievements","achievements"],["mail","mail"],["friends","coop"],["quick","matching"]]:
			game.build(String(spec[0]))
			await frames(6)
			if String(spec[0])=="quick":game.open_quick();await wait_screen("quick");await frames(4)
			await capture("/workspace/downloads/v2023_%s_16x9.png"%String(spec[1]))
		game.create_room("월하의 모의전",8,true,"달빛-2319",2)
		await wait_screen("room");await frames(6)
		await capture("/workspace/downloads/v2023_room_16x9.png")
		game.rules.start()
		for entry in game.rules.players.values():
			var role: String=String(entry.get("role","daoist"))
			if String(entry.get("character",""))=="":entry.character=String(entry.get("choices",{}).get(role,""))
		game.build("loading");await frames(8)
		await capture("/workspace/downloads/v2023_loading_16x9.png")
		print("V2023 RENDER DONE")
		quit()
		return
	if only=="" or only=="selection":
		await prepare_room()
		await frames(8)
		if game.rules.players.human.role=="yokai":
			game.rules.players.human.role="daoist"
			game.selection_id="daoist:woochi"
			game.build("selection")
			await frames(8)
		await capture("/workspace/downloads/v2023_char_select_wide.png")
		# 전체 탭(둘러보기)
		if is_instance_valid(game.selection_view):game.selection_view._set_tab("all");await frames(6)
		await capture("/workspace/downloads/v2023_char_select_all_wide.png")
		if is_instance_valid(game.selection_view):game.selection_view._set_tab("daoist");await frames(4)
		root.size=Vector2i(1920,1080)
		await frames(10)
		await capture("/workspace/downloads/v2023_char_select_16x9.png")
		root.size=Vector2i(2340,1080)
		await frames(8)
	if only=="" or only=="shop":
		game.build("market");await frames(8)
		await capture("/workspace/downloads/v2023_shop_wide.png")
	if only=="" or only=="achievements":
		game.build("achievements");await frames(8)
		await capture("/workspace/downloads/v2023_achievements_wide.png")
	if only=="" or only=="mail":
		game.build("mail");await frames(8)
		await capture("/workspace/downloads/v2023_mail_wide.png")
	if only=="" or only=="quick":
		game.open_quick();await wait_screen("quick");await frames(8)
		for i in range(30):game.advance_matching(.2);await frames(1)
		await capture("/workspace/downloads/v2023_matching_wide.png")
	if only=="" or only=="friends":
		game.build("friends");await frames(8)
		await capture("/workspace/downloads/v2023_coop_wide.png")
	if only=="" or only=="room":
		game.create_room("월하의 모의전",8,true,"달빛-2319",2)
		await wait_screen("room");await frames(8)
		await capture("/workspace/downloads/v2023_room_wide.png")
	if only=="" or only=="loading":
		if game.rules==null:
			game.create_room("월하의 모의전",8,true,"달빛-2319",2)
			await wait_screen("room")
		game.rules.start()
		for entry in game.rules.players.values():
			var role: String=String(entry.get("role","daoist"))
			if String(entry.get("character",""))=="":entry.character=String(entry.get("choices",{}).get(role,""))
		for p in game.rules.players.values():p.ready=true
		game.rules.start()
		game.build("loading");await frames(10)
		await capture("/workspace/downloads/v2023_loading_wide.png")
	print("V2023 RENDER DONE")
	quit()
