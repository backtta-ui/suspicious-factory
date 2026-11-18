extends SceneTree
## 2.0.21 검수 렌더: 인게임 시점(20:9·16:9), 상점(20:9·16:9), 도감(20:9).
## 2.0.20까지는 1280×720 버퍼를 늘려 뿌렸기 때문에 실기기 해상도로 캡처하면
## 글자가 뭉개졌다. 2.0.21은 canvas_items 스트레치라 창 크기 그대로(네이티브 해상도)로
## 그려지므로, 캡처도 실제 기기 크기(2340×1080 / 1920×1080)로 뽑는다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2021.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())
func settle(camera_at: Vector2,count: int=20) -> void:
 for i in range(count):
  game.update_avatars();game.update_hud()
  if is_instance_valid(game.camera):
   game.camera.position=camera_at;game.camera.reset_smoothing()
  await process_frame
func start_match() -> void:
 game.create_room("달빛 모의전",8,true)
 await create_timer(.4).timeout
 var ids: Array=game.rules.players.keys()
 var looks: Array=[["daoist","woochi"],["yokai","gumiho"],["yokai","dokkaebi"],["daoist","yeonhwa"],["daoist","muyeong"],["daoist","hongryeon"],["yokai","jangsanbeom"],["yokai","haechi"]]
 for i in range(ids.size()):
  var p: Dictionary=game.rules.players[ids[i]]
  p.ready=true
  p.role=looks[i][0];p.character=looks[i][0]+":"+looks[i][1]
 game.rules.phase="loading";game.screen="selection"
 game.load_match(1)
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 game.rules.ready_map()
 game.bots.clear()
 for i in range(40):game.rules.tick(.05)
 game.rules.phase="live";game.rules.elapsed=2.0
 var me: Dictionary=game.rules.players.human
 me.captured=false;me.eliminated=false;me.deadline=0;me.form="";me.invisible_until=0
 var front: Vector2=(L.buildings()[0].doors as Dictionary).front
 me.position=front+Vector2(24,58);me.facing=2
func run() -> void:
 # 1) 인게임 20:9 (갤럭시 2340×1080)
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(10)
 game.storage.data.coins=2400
 await start_match()
 await settle(game.rules.players.human.position+Vector2(0,-L.CAMERA_LIFT),24)
 await capture("/workspace/downloads/v2021_ingame_wide.png")
 # 2) 인게임 16:9 (1920×1080)
 root.size=Vector2i(1920,1080)
 await frames(14)
 await settle(game.rules.players.human.position+Vector2(0,-L.CAMERA_LIFT),16)
 await capture("/workspace/downloads/v2021_ingame_16x9.png")
 # 3) 캐릭터·스킨 상점 20:9 / 16:9
 game.cleanup_match();game.room={};game.build("market");await frames(10)
 var items: Array=game.shop._items()
 for item in items:
  if String(item.id).ends_with("yeonhwa"):game.shop.select_item(String(item.id))
 await frames(8)
 root.size=Vector2i(2340,1080)
 await frames(14)
 await capture("/workspace/downloads/v2021_shop_wide.png")
 root.size=Vector2i(1920,1080)
 await frames(14)
 await capture("/workspace/downloads/v2021_shop_16x9.png")
 # 4) 도감(글씨 선명도 확인) 20:9
 root.size=Vector2i(2340,1080)
 await frames(10)
 game.build("characters")
 await frames(12)
 await capture("/workspace/downloads/v2021_codex_wide.png")
 print("V2021 RENDER DONE")
 quit()
