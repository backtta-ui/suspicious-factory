extends SceneTree
## 2.0.20 검수: 상업 UI로 올린 친구 방 대기실을 16:9(1280×720)와 20:9(1600×720)로 캡처한다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2020.gd
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
func ready_room() -> void:
 for p in game.rules.players.values():p.ready=true
func run() -> void:
 root.size=Vector2i(1280,720)
 game=App.instantiate();root.add_child(game);await frames(8)
 game.create_room("달빛 모의전",8,true)
 await create_timer(.35).timeout
 game.build("room")
 await frames(10)
 ready_room()
 game.build("room")
 await frames(12)
 await capture("/workspace/downloads/v2020_room_16x9.png")
 # 희망 진영을 바꾼 상태도 한 장(선택 강조 확인)
 game.set_preferred_role("yokai")
 await frames(10)
 await capture("/workspace/downloads/v2020_room_side.png")
 game.set_preferred_role("any")
 # 20:9 와이드
 root.size=Vector2i(1600,720)
 await frames(12)
 game.build("room")
 await frames(12)
 await capture("/workspace/downloads/v2020_room_wide.png")
 # 빈 자리 카드 확인(봇 채우기 없이 혼자 입장)
 root.size=Vector2i(1280,720)
 await frames(8)
 game.create_room("빈 방 확인",8,false)
 await create_timer(.4).timeout
 await frames(12)
 await capture("/workspace/downloads/v2020_room_empty.png")
 print("V2020 RENDER DONE")
 quit()
