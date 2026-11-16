extends SceneTree
var game: Node
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/v20-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(20);await shot("title")
 game.start_game(false);await frames(15);game.player.facing=2;game.player.set_physics_process(false);game.player.update_sprite();await frames(3);await shot("base")
 for pose in range(4):
  game.player.action_pose=pose;game.player.action_left=.22;game.player.pose_duration=.4;game.player.update_sprite();await frames(4);await shot("combo%d"%(pose+1))
 game.player.action_left=0;game.player.jump_height=35;game.player.jump_phase="apex";game.player.update_sprite();await frames(4);await shot("jump")
 game.player.jump_height=0;game.show_menu();await frames();game.show_seal();await frames(12);await shot("multiplayer-setup")
 game.queue_free();await frames();quit()
