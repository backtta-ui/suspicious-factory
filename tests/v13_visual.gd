extends SceneTree
var game: Node
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image();image.save_png("res://builds/v13-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(30)
 await shot("title")
 game.start_game(false);await frames(30);await shot("plaza")
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);await frames(30);await shot("painting")
 game.adventure.enter_painting();await create_timer(.75).timeout;await shot("portal")
 await create_timer(2).timeout;await frames(30);await shot("forest-entry")
 game.player.position=Vector2(600,650);game.camera.reset_smoothing();await frames(15);await shot("forest-combat")
 game.adventure.show_menu();await frames(10);await shot("rpg-menu")
 game.adventure.show_inventory();await frames(10);await shot("inventory")
 game.queue_free();await frames(5);quit()
