extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(8):await process_frame
 game.start_game(false)
 for i in range(8):await process_frame
 var mode:="room"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--view="):mode=arg.trim_prefix("--view=")
 game.player.position=preload("res://scripts/practice/layout.gd").DOOR;game.camera.reset_smoothing()
 if mode!="entrance":game.enter_practice("transform")
 for i in range(12):await process_frame
 if mode=="list":game.practice.show_spells()
 if mode=="codex":game.practice.leave();game.adventure.show_spells()
 if mode=="clone":game.practice.select("clone");game.practice.cast()
 if mode=="mimic":game.practice.select("mimic");game.practice.session.self_player().position=game.practice.session.rules.players.blue.position+Vector2(25,0);game.practice.cast()
 if mode=="cat":
  var s: WooPracticeSession=game.practice.session;s.self_player().position=s.rules.arena.find_asset("practice_cat").origin+Vector2(22,0);s.interact()
  for i in range(40):s.tick(.05,Vector2.ZERO)
  game.practice.cast()
 for i in range(10):await process_frame
 await RenderingServer.frame_post_draw
 var err:=root.get_texture().get_image().save_png("res://builds/practice-"+mode+".png");print("PRACTICE CAPTURE ",mode," ",err)
 if is_instance_valid(game.practice):game.practice.leave()
 game.show_menu(false);game.queue_free()
 for i in range(4):await process_frame
 quit(0 if err==OK else 1)
