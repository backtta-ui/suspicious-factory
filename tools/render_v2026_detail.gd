extends SceneTree
## 2.0.26 비주얼 검수용 근접 컷: 길·마당·연못·건물 앞을 줌 1.90으로 찍는다.
## 사용: DISPLAY=:99 godot --path . --script res://tools/_render_detail.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
const OUT="/workspace/downloads/_detail_"
var game: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(OUT+name+".png")
	print("DETAIL ",name," ",image.get_size())

func wait_screen(target: String) -> void:
	for i in range(600):
		await process_frame
		if game.screen==target and not game.changing:return
	print("WAIT TIMEOUT ",target)

func run() -> void:
	root.size=Vector2i(1200,1000)
	game=App.instantiate();root.add_child(game);await frames(16)
	game.build("lobby");await frames(6)
	game.preferred_role="daoist"
	game.start_practice_match()
	await wait_screen("match")
	await frames(24)
	game.set_process(false)
	game.rules.phase="live"
	game.ui.visible=false
	root.size=Vector2i(1400,900)
	await frames(4)
	game.camera.zoom=Vector2(L.CAMERA_ZOOM,L.CAMERA_ZOOM)
	game.camera.limit_left=-2000;game.camera.limit_top=-2000
	game.camera.limit_right=int(L.SIZE.x)+2000;game.camera.limit_bottom=int(L.SIZE.y)+2000
	game.update_avatars()
	for entry in [["path",Vector2(1300,880)],["yard",Vector2(640,1010)],["plaza",Vector2(1700,1180)],["pond",Vector2(2600,1400)],["door",Vector2(3000,2120)]]:
		game.camera.position=entry[1]+Vector2(0,-L.CAMERA_LIFT)
		await frames(6)
		await capture(String(entry[0]))
	print("DETAIL DONE")
	quit()
