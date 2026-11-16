extends SceneTree
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/training-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames();game.enter_practice("smoke");await frames()
 game.practice.cast();await create_timer(.2).timeout;await shot("smoke")
 game.practice.show_spells();await frames();await shot("list");game.close_modal()
 game.practice.leave();game.show_menu(false);game.queue_free();await frames()
 var scene:=Node2D.new();root.add_child(scene)
 for row in range(4):
  for col in range(8):
   var actor:=preload("res://scripts/woo/actor.gd").new();actor.cosmetic=preload("res://scripts/wardrobe/catalog.gd").base_appearance(["woochi","yeonhwa","muyeong","hongryeon"][row]);actor.facing=preload("res://scripts/wardrobe/direction.gd").FACING[col];actor.position=Vector2(100+col*150,155+row*160);actor.scale=Vector2.ONE*2;scene.add_child(actor);actor.set_physics_process(false);actor.update_sprite()
 await frames();await shot("eight-directions");scene.queue_free();quit()
