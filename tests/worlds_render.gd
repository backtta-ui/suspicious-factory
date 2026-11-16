extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(6):await process_frame
 game.start_game(false)
 for i in range(6):await process_frame
 var mode:="plaza"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--view="):mode=arg.trim_prefix("--view=")
 game.player.position=preload("res://scripts/worlds/catalog.gd").ENTRY+Vector2(0,75);game.camera.reset_smoothing()
 if mode!="plaza":
  var index:=0 if mode=="fox_forest" else (1 if mode in ["moon_palace","gallery"] else 2)
  game.show_painting_intro(index)
  if mode!="gallery":game.close_modal();game.adventure.load_world(preload("res://scripts/worlds/catalog.gd").WORLDS[index].id)
  if mode=="moon_palace":game.player.position=Vector2(900,700)
  if mode=="red_sea":game.player.position=Vector2(1000,800)
 game.camera.reset_smoothing()
 for i in range(12):await process_frame
 await RenderingServer.frame_post_draw
 var error:=root.get_texture().get_image().save_png("res://builds/worlds-"+mode+".png");print("WORLDS CAPTURE ",mode," ",error)
 game.show_menu(false);game.queue_free()
 for i in range(3):await process_frame
 quit(error)
