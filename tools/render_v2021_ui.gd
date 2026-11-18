extends SceneTree
## 2.0.21 회귀 검수: 스트레치 모드를 canvas_items로 바꾼 뒤 타이틀·로비·대기실·
## 업적 화면이 20:9(2340×1080)에서 그대로인지 캡처한다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2021_ui.gd
const App=preload("res://scenes/survival.tscn")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())
func run() -> void:
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(10)
 await capture("/workspace/downloads/v2021_title_wide.png")
 game.build("lobby");await frames(10)
 await capture("/workspace/downloads/v2021_lobby_wide.png")
 game.create_room("달빛 모의전",8,true)
 await create_timer(.4).timeout
 for p in game.rules.players.values():p.ready=true
 game.build("room");await frames(12)
 await capture("/workspace/downloads/v2021_room_wide.png")
 game.build("achievements");await frames(10)
 await capture("/workspace/downloads/v2021_achievements_wide.png")
 print("V2021 UI RENDER DONE")
 quit()
