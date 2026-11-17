extends SceneTree
var rows: Array=[]
func frames(n: int) -> void:
 for i in range(n):await process_frame
func sample(label: String) -> void:
 await frames(30)
 var durations: Array=[];var last:=Time.get_ticks_usec()
 for i in range(180):
  await process_frame
  var now:=Time.get_ticks_usec();durations.append(float(now-last)/1000);last=now
 durations.sort();var sum:=0.0
 for value in durations:sum+=value
 rows.append({"scene":label,"frames":durations.size(),"mean_ms":sum/durations.size(),"p95_ms":durations[int(durations.size()*.95)],"max_ms":durations.back(),"engine_static_allocator_bytes":OS.get_static_memory_usage(),"nodes":get_node_count()})
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(8);game.start_game(false);await sample("plaza")
 game.enter_practice("smoke");await frames(12);game.practice.cast();await sample("practice-smoke")
 game.practice.leave();game.queue_free();await frames(8)
 var f:=FileAccess.open("res://builds/qa-performance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":OS.get_name(),"renderer":"Linux software OpenGL llvmpipe","viewport":[1280,720],"android_device":false,"phone_fps_claim":false,"notes":"Desktop software-renderer observation only. Run when local regression process has finished; not thermal/long-play/device certification.","samples":rows},"  "));f.close();print("DESKTOP SAMPLE RECORDED");quit()
