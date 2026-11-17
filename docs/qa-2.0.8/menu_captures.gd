extends SceneTree
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa208-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames();await shot("plaza")
 for page in ["inventory","character","spells","journal","map"]:
  game.adventure.call("show_"+page);await frames();await shot("menu-"+page);game.close_modal();await frames()
 game.show_credits();await frames();await shot("credits");game.close_modal()
 game.player.position=game.Layout.safe_position(Vector2(1900,350));game.show_painting_intro(0);await frames();await shot("gallery");game.close_modal()
 game.show_menu(false);await frames();game.show_seal();await frames();await shot("online-login")
 game.seal_client.exit_to_main();game.queue_free();await frames();quit()
