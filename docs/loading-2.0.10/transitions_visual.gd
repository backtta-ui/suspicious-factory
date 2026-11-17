extends SceneTree
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/loading210-"+name+".png")
func wait_ready(game: Node) -> void:
 while game.content_loading or game.adventure.transitioning:await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var boot=load("res://scenes/bootstrap.tscn").instantiate();root.add_child(boot);current_scene=boot;await frames(2);await shot("boot")
 while is_instance_valid(boot):await process_frame
 var game=current_scene;game.request_start();await frames(6);await shot("plaza-loading");await wait_ready(game)
 game.request_gallery(0);await wait_ready(game);game.adventure.enter_painting();await frames(8);await shot("painting-entry")
 while game.content_loading and game.loading.overlay.portal_intro:await process_frame
 await shot("forest-loading-a");await frames(3);await shot("forest-loading-b");await wait_ready(game);await shot("forest-ready")
 game.adventure.return_to_plaza();await frames(6);await shot("return-entry");await wait_ready(game)
 game.queue_free();await frames();quit()
