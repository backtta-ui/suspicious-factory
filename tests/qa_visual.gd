extends SceneTree
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa208-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();await shot("title")
 game.start_game(false);await frames();game.player.position=Vector2(1900,350);await frames();await shot("plaza")
 for world in ["fox_forest","moon_palace","red_sea"]:
  game.show_painting_intro(["fox_forest","moon_palace","red_sea"].find(world));game.close_modal();game.adventure.load_world(world);await frames();await shot(world)
  game.adventure.show_menu();await frames();await shot(world+"-menu");game.close_modal()
  game.adventure.return_to_plaza();await create_timer(2.6).timeout
 game.enter_practice("shield");await process_frame;await shot("loading");await frames(12);await shot("practice")
 game.practice.show_spells();await frames();await shot("spells");game.close_modal();game.practice.leave();await frames()
 game.show_settings();await frames();await shot("settings");game.close_modal();game.show_wardrobe();await frames();await shot("wardrobe")
 game.show_menu(false);game.queue_free();await frames();quit()
