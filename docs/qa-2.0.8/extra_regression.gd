extends SceneTree
var results: Array=[]
var failures:=0
func check(ok: bool,id: String) -> void:
 results.append({"id":id,"status":"FIXED" if ok else "FAIL","method":"Godot runtime after visual review"})
 if not ok:failures+=1;push_error(id)
func frames(n: int=7) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 check(game.adventure.hp_bar.size.y<=14,"COMPACT-HP-EXACT")
 game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for c in game.get_children():
  if c is WooWardrobeScreen:screen=c
 check(screen.save_button.get_global_rect().end.y<690,"WARDROBE-FOOTER-NOT-CLIPPED")
 screen.close();await frames()
 game.player.position=game.Layout.safe_position(Vector2(1900,350));await frames();var anchor: Vector2=game.player.position
 game.show_painting_intro(2);game.close_modal();game.adventure.load_world("red_sea");await frames()
 game.enter_practice("shield");await frames(12)
 check(game.practice.vitality.size.y<=14,"COMPACT-TRAINING-HP-EXACT")
 game.practice.exit_to_plaza();await create_timer(2.6).timeout;await frames()
 check(not game.adventure.in_mission and not is_instance_valid(game.practice),"NESTED-TRAINING-DIRECT-PLAZA")
 check(game.player.position.distance_to(anchor)<.2,"NESTED-TRAINING-PLAZA-ANCHOR")
 game.queue_free();await frames()
 var f:=FileAccess.open("res://builds/qa-extra.json",FileAccess.WRITE);f.store_string(JSON.stringify({"cases":results,"failures":failures},"  "));f.close();print("EXTRA QA: %d cases / %d failures"%[results.size(),failures]);quit(1 if failures else 0)
