extends SceneTree
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/loading210-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 game.request_start();await frames(2);await shot("initial")
 while game.content_loading:await process_frame
 game.loading.begin("moon_palace");await frames(25);await shot("talisman-a");await frames(25);await shot("talisman-b");game.loading.complete()
 game.loading.begin("practice");await game.loading.prepare(["res://missing-loading-visual.png"]);await frames(12);await shot("failure");game.go_back()
 game.queue_free();await frames();quit()
