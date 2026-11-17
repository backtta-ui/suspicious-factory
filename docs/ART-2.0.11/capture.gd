extends SceneTree
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames();game.show_wardrobe();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/mascot-wardrobe.png")
 game.close_modal();await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/mascot-plaza.png")
 game.queue_free();await frames();quit()
