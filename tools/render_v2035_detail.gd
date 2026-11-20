extends SceneTree
const App=preload("res://scenes/survival.tscn")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func cap(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/workspace/downloads/"+name)
 print("SAVED ",name)
func start(map_id: String) -> void:
 game.cleanup_match();game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("detail",8,true,"",2,map_id)
 for i in range(220):
  await process_frame
  if game.screen=="room" and not game.changing:break
 game.rules.players.human.ready=true;game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(260):
  if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
  if game.rules.phase=="loading":break
 for i in range(900):
  await process_frame
  if game.screen=="match" and not game.changing:break
 for i in range(60):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 wait_frames.call_deferred()
func wait_frames() -> void:pass
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game)
 await frames(10)
 await start("haeundae")
 var h: Dictionary=game.rules.players.human
 h.role="daoist";h.character="daoist:woochi";game.rules.elapsed=60.0;h.outside=0.0
 var g: RefCounted=game.rules.gimmicks
 # 시장 골목 + 주문벨 + 천막
 h.position=Vector2(470,560);game.camera.position=Vector2(470,540);game.camera.zoom=Vector2(1.5,1.5);await frames(8)
 g.tide_until=0.0
 await cap("v2035_haeundae_market.png")
 # 동백섬 다리 + 밀물 + 등대
 h.position=Vector2(2650,1210);game.camera.position=Vector2(2650,1180);game.camera.zoom=Vector2(1.35,1.35)
 g.tide_until=game.rules.elapsed+6.0
 await frames(8)
 await cap("v2035_haeundae_island.png")
 await start("dongseongno")
 var h2: Dictionary=game.rules.players.human
 h2.role="daoist";h2.character="daoist:woochi";game.rules.elapsed=60.0;h2.outside=0.0
 h2.position=Vector2(1600,760);game.camera.position=Vector2(1600,740);game.camera.zoom=Vector2(1.5,1.5)
 game.rules.gimmicks.smoke_until=game.rules.elapsed+5.0;game.rules.gimmicks.smoke_pos=Vector2(1500,760);game.rules.gimmicks.smoke_radius=220.0
 await frames(8)
 await cap("v2035_dongseongno_street.png")
 await start("seowon")
 var h3: Dictionary=game.rules.players.human
 h3.role="daoist";h3.character="daoist:woochi";game.rules.elapsed=60.0;h3.outside=0.0
 h3.position=Vector2(1250,1100);game.camera.position=Vector2(1250,1080);game.camera.zoom=Vector2(1.5,1.5)
 await frames(8)
 await cap("v2035_seowon_props.png")
 quit(0)
