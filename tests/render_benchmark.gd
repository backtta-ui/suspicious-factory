extends SceneTree
var game: Node
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 game=load('res://scenes/main.tscn').instantiate();root.add_child(game)
 await process_frame
 game.start_game(false)
 for i in range(60): await process_frame
 var samples: Array[float]=[]
 var calls:=0.0
 var previous:=Time.get_ticks_usec()
 for i in range(180):
  await process_frame
  var now:=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
  calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 samples.sort()
 print('BENCHMARK ',JSON.stringify({'frames':samples.size(),'median_ms':samples[90],'p95_ms':samples[171],'draw_calls_mean':calls/180.0,'renderer':RenderingServer.get_video_adapter_name(),'resolution':str(root.size)}))
 game.queue_free();await process_frame;quit()
