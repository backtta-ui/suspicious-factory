extends SceneTree
## 로비 하위 화면(상점·빠른 매치·업적·우편·친구)을 실제 Godot 렌더러로 캡처한다.
## 사용: xvfb-run -a godot --path . --script res://tools/render_lobby_ui.gd
const App=preload("res://scenes/survival.tscn")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=6) -> void:
	for i in range(n):await process_frame
func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(path)
	print("RENDER SAVED ",path," ",image.get_size())
func run() -> void:
	root.size=Vector2i(1280,720)
	game=App.instantiate()
	root.add_child(game)
	await frames(10)
	game.storage.data.coins=2400
	game.storage.data.gems=120
	game.build("lobby")
	await frames(4)
	game.build("market")
	await frames(14)
	await capture("res://builds/ui_v2_market.png")
	game.shop.set_tab("skin")
	await frames(6)
	await capture("res://builds/ui_v2_market_skin.png")
	game.shop.set_tab("aura")
	await frames(6)
	await capture("res://builds/ui_v2_market_aura.png")
	game.build("lobby");await frames(3)
	game.open_quick()
	for i in range(90):
		await process_frame
		if game.quick!=null and game.screen=="quick":break
	await frames(4)
	game.set_process(false)
	game.match_slots=6
	game.quick.set_slots(6)
	await frames(30)
	await capture("res://builds/ui_v2_matching.png")
	game.set_process(true)
	game.finish_matching()
	await frames(12)
	await capture("res://builds/ui_v2_room.png")
	game.storage.data.stats={"matches":4,"wins":2,"seals":1,"rescues":0,"doors":2,"disguises":1}
	game.build("achievements")
	await frames(10)
	await capture("res://builds/ui_v2_achievements.png")
	game.build("mail")
	await frames(10)
	await capture("res://builds/ui_v2_mail.png")
	game.build("alerts")
	await frames(8)
	await capture("res://builds/ui_v2_alerts.png")
	game.build("friends")
	await frames(8)
	await capture("res://builds/ui_v2_friends.png")
	game.build("lobby");await frames(4)
	game.show_settings()
	await frames(8)
	await capture("res://builds/ui_v2_settings.png")
	print("RENDER DONE")
	quit()
