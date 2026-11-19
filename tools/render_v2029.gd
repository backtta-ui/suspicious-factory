extends SceneTree
## 2.0.29 검수 렌더: 왼쪽 레일에서 캐릭터 메달을 지운 메인 로비(도감·업적·상점 3개).
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2029.gd
const App=preload("res://scenes/survival.tscn")
const OUT="/workspace/downloads/"
var game: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT+name
	image.save_png(path)
	print("RENDER SAVED ",path," ",image.get_size())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(16)
	game.build("lobby");await frames(10)
	for key in ["codex","achievements","shop"]:
		var target: Control=game.lobby_hotspots.get(key)
		print("RAIL ",key," rect=",target.get_global_rect() if target!=null else Rect2())
	print("RAIL count=",game.lobby_hotspots.size()," has_characters=",game.lobby_hotspots.has("characters"))
	await capture("v2029_lobby_3buttons.png")
	# 도감 자리가 통합 도감을 여는지 같은 실행에서 눈으로 남긴다.
	game.lobby_hotspots["codex"].emit_signal("pressed")
	for i in range(120):
		await process_frame
		if game.screen=="characters" and not game.changing:break
	await frames(10)
	await capture("v2029_lobby_codex_from_rail.png")
	print("V2029 RENDER DONE screen=",game.screen)
	quit()
