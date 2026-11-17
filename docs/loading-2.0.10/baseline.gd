extends SceneTree
var samples: Array=[]
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 for pass_id in range(3):
  var t:=Time.get_ticks_usec();game.start_game(false);var plaza_ms: float=(Time.get_ticks_usec()-t)/1000.0;await frames()
  game.return_anchor={"map":game.Layout.MAP_ID,"position":[1900,550],"facing":2};var worlds: Dictionary={}
  for id in ["fox_forest","moon_palace","red_sea"]:
   t=Time.get_ticks_usec();game.adventure.load_world(id);worlds[id]=(Time.get_ticks_usec()-t)/1000.0;await frames()
   game.player.reparent(game.world);game.adventure.forest.queue_free();game.adventure.in_mission=false;game.world.show();game.world.process_mode=Node.PROCESS_MODE_INHERIT
  samples.append({"pass":pass_id,"plaza_ms":plaza_ms,"world_ms":worlds})
  game.show_menu(false);await frames()
 var f:=FileAccess.open("res://docs/loading-2.0.10/baseline.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":"Linux headless; warm process, not Android or cold boot","samples":samples},"  "));game.queue_free();await frames();quit()
