extends SceneTree
var game: Node
const Layout=preload("res://scripts/woo/village_layout.gd")
func _initialize() -> void:run.call_deferred()
func wait_frames(n: int=5) -> void:
 for i in range(n):await process_frame
func capture(label: String) -> void:
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://builds/v11-"+label+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await wait_frames(15)
 await capture("menu-a");await create_timer(2).timeout;await capture("menu-b")
 game.start_game(false);await wait_frames(12)
 for zone in Layout.ZONES:
  game.player.position=Layout.safe_position(zone.center)
  game.camera.reset_smoothing();await wait_frames(12);await capture(zone.id)
 for edge in [Vector2(100,700),Vector2(900,100),Vector2(2980,1000),Vector2(1500,1530)]:
  game.player.position=Layout.safe_position(edge);game.camera.reset_smoothing();await wait_frames(10)
  await capture("edge-%d" % int(edge.x+edge.y))
 root.size=Vector2i(2400,1080);await wait_frames(8)
 game.player.position=Layout.SPAWN;game.camera.reset_smoothing();await wait_frames(10);await capture("wide-screen")
 game.player.position=Layout.PAINTINGS[0].position+Vector2(0,50)
 game.camera.reset_smoothing();await wait_frames(5);game.interact();await wait_frames(6);await capture("painting-intro")
 assert(game.modal_kind=="painting")
 print("PLAZA VISUAL: PASS (animated menu, five zones, boundary cameras, painting intro)")
 game.queue_free();await wait_frames(3);quit()
