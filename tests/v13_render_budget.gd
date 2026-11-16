extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_game(false);await process_frame
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false)
 var results: Array=[]
 for p in [Vector2(260,780),Vector2(700,650),Vector2(1110,530)]:
  game.player.position=p;game.camera.reset_smoothing()
  for i in range(30):await process_frame
  var calls:=0.0;var objects:=0.0;var times: Array=[];var before:=Time.get_ticks_usec()
  for i in range(90):
   await process_frame
   var now:=Time.get_ticks_usec();times.append((now-before)/1000.0);before=now
   calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);objects+=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
  times.sort();results.append({"position":[p.x,p.y],"mean_draw_calls":calls/90,"mean_objects":objects/90,"median_ms":times[45],"p95_ms":times[85]})
 var report={"renderer":RenderingServer.get_video_adapter_name(),"android_device_test":false,"samples_per_position":90,"results":results}
 var file:=FileAccess.open("res://builds/v13-render-budget.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 var ok: bool=results.all(func(v: Dictionary)->bool:return v.mean_draw_calls<350)
 print("PASS: forest render draw-call budget under 350" if ok else "FAIL: forest render budget")
 game.queue_free();await process_frame;await process_frame;quit(0 if ok else 1)
