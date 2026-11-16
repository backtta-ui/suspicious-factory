extends SceneTree
var game: Node
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/v14-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(20);game.start_game(false);await frames(15)
 game.adventure.show_inventory();await frames(20);await shot("bundle")
 var bundle=game.modal.get_child(game.modal.get_child_count()-1)
 bundle.select("key");await frames(20);await shot("key")
 bundle.inspect_item("seal");await frames(20);await shot("inspect");game.close_modal()
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false)
 for zone in WooForestLayout.ZONES:
  game.player.position=WooForestLayout.safe(zone.center);game.camera.reset_smoothing();await frames(20);await shot(zone.id)
 game.player.position=Vector2(780,770);game.camera.reset_smoothing();game.adventure.basic_attack();await create_timer(.12).timeout;await shot("attack")
 game.adventure.jump();await create_timer(.2).timeout;await shot("jump")
 game.queue_free();await frames(4);quit()
