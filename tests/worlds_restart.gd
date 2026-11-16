extends SceneTree
var mode:="read"
func _initialize() -> void:run.call_deferred()
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(5):await process_frame
 var id: String=mode.trim_prefix("write-") if mode.begins_with("write-") else mode.trim_prefix("read-")
 game.start_game(mode.begins_with("read-"))
 for i in range(6):await process_frame
 var ok:=true
 if mode.begins_with("write-"):
  game.player.position=Vector2(1900,425);game.player.facing=4;game.show_painting_intro(1 if id=="moon_palace" else 2);game.close_modal();ok=game.adventure.load_world(id)
  game.player.position=Vector2(900,700) if id=="moon_palace" else Vector2(600,850);game.player.facing=6;game.save_progress();ok=ok and game.last_save_error==OK
 else:
  ok=game.adventure.in_mission and game.adventure.active_world==id and game.player.get_parent()==game.adventure.forest and game.player.facing==6 and game.player.position.distance_to(Vector2(900,700) if id=="moon_palace" else Vector2(600,850))<1
 game.show_menu(false);game.queue_free()
 for i in range(3):await process_frame
 print("WORLD PROCESS ",mode,": ","PASS" if ok else "FAIL");quit(0 if ok else 1)
