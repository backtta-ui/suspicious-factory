extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(3):await process_frame
 var samples: Array=[]
 for i in range(3):
  var t:=Time.get_ticks_usec();game.start_game(false);samples.append((Time.get_ticks_usec()-t)/1000.0);game.show_menu(false)
  for j in range(3):await process_frame
 var f:=FileAccess.open("res://docs/loading-2.0.10/after_sync.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":"Linux headless; same warm-process synchronous operation as baseline","plaza_ms":samples},"  "));game.queue_free();await process_frame;quit()
