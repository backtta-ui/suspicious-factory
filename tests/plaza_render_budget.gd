extends SceneTree
const Layout=preload("res://scripts/worlds/plaza_layout.gd")
var game: Node
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if DisplayServer.get_name()=="headless":push_error("Requires an actual renderer");quit(1);return
 root.size=Vector2i(1280,720);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_game(false)
 var results:=[];var failed:=false
 for zone in Layout.ZONES:
  game.player.position=Layout.safe_position(zone.center);game.camera.reset_smoothing()
  for i in range(60):await process_frame
  var samples: Array[float]=[];var calls:=0.0;var previous:=Time.get_ticks_usec()
  for i in range(180):
   await process_frame
   var now:=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
   calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
  samples.sort()
  var record: Dictionary={"zone":zone.id,"frames":180,"median_ms":samples[90],"p95_ms":samples[171],"mean_draw_calls":calls/180}
  results.append(record);print("ZONE RENDER ",JSON.stringify(record))
  if calls/180>500 or calls<1:failed=true
 var report: Dictionary={"status":"failed" if failed else "passed","renderer":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"device_test":"not_performed","max_mean_draw_calls":500,"zones":results}
 var f:=FileAccess.open("res://builds/plaza-render-budget.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("PLAZA RENDER BUDGET: ",report.status)
 game.queue_free();await process_frame;quit(1 if failed else 0)
