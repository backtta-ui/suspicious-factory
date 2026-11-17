extends SceneTree
func frames(n: int=12) -> void:
 for i in range(n):await process_frame
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/ui209-"+id+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.adventure.show_menu();await frames();await shot("menu");game.close_modal();await frames()
 game.show_wardrobe();await frames();await shot("wardrobe");game.close_modal();await frames()
 game.adventure.show_spells();await frames();await shot("codex");game.close_modal();await frames()
 game.queue_free();await frames();quit()
