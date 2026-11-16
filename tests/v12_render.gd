extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=6) -> void:
 for i in range(n):await process_frame
func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://builds/v12-"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(15)
 game.menu_motion.elapsed=1;await frames(2);await capture("title-a")
 game.menu_motion.elapsed=3;await frames(2);await capture("title-b")
 game.start_game(false);await frames(20)
 var actor=game.actors[2];actor.set_physics_process(false);actor.position=Vector2(1060,700);actor.facing=2;actor.npc_walking=true;actor.npc_driver.state="walk"
 game.player.position=Vector2(1030,780);game.camera.reset_smoothing();await frames(6)
 for i in range(4):
  actor.npc_stride=i*6.0;actor.update_npc_art();await frames(2);await capture("gait-%d"%i)
 actor.set_physics_process(true)
 for zone in preload("res://scripts/worlds/plaza_layout.gd").ZONES:
  game.player.position=zone.center;game.camera.reset_smoothing();await frames(12);await capture(zone.id)
 print("V1.2 RENDER: PASS (local title effects, four gait poses, five revised zones)")
 game.queue_free();await frames(4);quit()
