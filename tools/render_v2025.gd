extends SceneTree
## 2.0.25 여섯 화면(우편·업적·친구·빠른 매치·매치 로딩·도감) 검수 렌더.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2025.gd
const App=preload("res://scenes/survival.tscn")
const OUT="/workspace/work/v25render/"
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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(14)
	game.storage.data.coins=2400
	game.storage.data.gems=120
	var only: String=OS.get_environment("V25_ONLY")
	if only=="" or only=="mail":
		game.build("mail");await frames(10)
		var b: Node=game.ui.find_child("LobbyBack",true,false)
		if b!=null:
			print("BACK size=",b.size," font=",b.get("font_size")," tex=",b.get("kind")," minsize=",b.get_global_rect())
		print("TEX sizes ",b.get("kind") if b!=null else "", "dark=",load("res://assets/ui/v25/btn_dark.png").get_size(), "gold=",load("res://assets/ui/v25/btn_gold.png").get_size())
		for child in game.ui.get_children():
			print("UI ",child.name," ",child.get_class()," pos=",child.position," size=",child.size)
			for sub in child.get_children():
				print("   - ",sub.name," ",sub.get_class()," pos=",sub.position," size=",sub.size)
		await capture(OS.get_environment("V25_NAME") if OS.get_environment("V25_NAME")!="" else "v2025_mail_wide.png")
		await capture("v2025_mail_16x9.png") if false else null
	if only=="" or only=="friends":
		game.build("friends");await frames(10)
		await capture("v2025_coop_wide.png")
	if only=="" or only=="achievements":
		game.build("achievements");await frames(10)
		await capture("v2025_achievements_wide.png")
	if only=="" or only=="matching":
		game.preferred_role="daoist"
		game.open_quick();await wait_screen("quick")
		game.matching=6.75
		game.match_slots=3
		if is_instance_valid(game.quick):game.quick.set_slots(3)
		game.set_process(false)
		await frames(3)
		await capture("v2025_matching_wide.png")
		game.set_process(true)
	if only=="" or only=="loading":
		game.build("lobby");await frames(2)
		game.room={"name":"연습 · 월하의 서원 봇전","count":8,"fill":true,"code":"달빛-2319","yokai":2,"practice":true}
		game.setup_participants()
		for p in game.rules.players.values():p.ready=true
		game.rules.start()
		game.build("loading");await frames(6)
		var bar: ProgressBar=game.ui.find_child("ResourceProgress",true,false)
		if bar!=null:bar.value=82
		game.status_label.text="달빛이 서원을 비춥니다… 82%"
		await frames(4)
		await capture("v2025_loading_wide.png")
	if only=="" or only=="codex":
		game.cleanup_match();game.build("characters");await frames(12)
		await capture("v2025_codex_wide.png")
		root.size=Vector2i(1920,1080);await frames(8)
		await capture("v2025_codex_16x9.png")
	print("V2025 RENDER DONE")
	quit()
