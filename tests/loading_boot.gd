extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var boot=load("res://scenes/bootstrap.tscn").instantiate();root.add_child(boot);current_scene=boot
 if not boot.content_loading or boot.loading.overlay==null:push_error("boot loader missing");quit(1);return
 print("PASS: configured bootstrap immediately displays common loading")
 boot._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
 var deadline:=Time.get_ticks_msec()+30000
 var above_title:=false
 while is_instance_valid(boot) and Time.get_ticks_msec()<deadline:
  if current_scene!=boot and current_scene!=null:above_title=boot.layer.layer>current_scene.layer.layer
  await process_frame
 if is_instance_valid(boot) or current_scene==null or not current_scene.has_method("request_start"):push_error("bootstrap did not hand over to original Main");quit(1);return
 print("PASS: threaded bootstrap hands over to existing title scene")
 if current_scene.screen_name!="menu":push_error("bootstrap bypassed title or started gameplay");quit(1);return
 print("PASS: title menu remains the first playable screen")
 if not above_title:push_error("bootstrap fade was hidden behind title canvas");quit(1);return
 print("PASS: bootstrap fade stays above the ready title canvas")
 if not current_scene.sound.backgrounded:push_error("bootstrap lost background audio state");quit(1);return
 print("PASS: background state carries from bootstrap into original title audio")
 var f:=FileAccess.open("res://builds/loading-boot.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":"Linux headless, engine initialization before bootstrap excluded","requests":current_scene.get_meta("bootstrap_metrics",[])},"  "))
 current_scene.queue_free();await process_frame;print("LOADING BOOT: 5 checks / 0 failures");quit()
