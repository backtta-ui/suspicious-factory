extends SceneTree
var failures:=0
var checks:=0
var records: Array=[]
func check(ok: bool,text: String) -> void:
 checks+=1
 if ok:print("PASS: "+text)
 else:failures+=1;push_error(text)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func ready_game(game: Node) -> void:
 var end:=Time.get_ticks_msec()+30000
 while (game.content_loading or (is_instance_valid(game.adventure) and game.adventure.transitioning)) and Time.get_ticks_msec()<end:await process_frame
 check(not game.content_loading and not game.adventure.transitioning,"transition reaches ready state")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var nav=preload("res://scripts/worlds/plaza_navigation.gd").new();var same:=true
 for edge in nav.Data.EDGES:
  if nav.graph.are_points_connected(edge[0],edge[1])!=nav.segment_clear(nav.Data.POINTS[edge[0]],nav.Data.POINTS[edge[1]]):same=false
 check(same,"baked story graph matches every original geometry-validated connection")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 var persisted: Dictionary=game.Save.load_game().duplicate(true)
 game.request_start();var generation: int=game.loading.generation
 check(game.content_loading and is_instance_valid(game.loading.overlay),"initial input immediately creates shared loading overlay")
 game.request_start();game.go_back();check(game.loading.generation==generation and game.modal==null,"duplicate start and Android back cannot create or expose another scene")
 game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
 await ready_game(game)
 check(game.world.build_ready and game.camera.is_current() and game.player!=null,"world, actor and camera ready before input resumes")
 check(game.paused,"backgrounded load keeps player paused")
 game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);check(not game.paused,"foreground resumes loaded world without a stuck pause")
 var count:=0
 for child in game.get_children():
  if child is WooStoryPlaza:count+=1
 check(count==1 and game.loading.held_resources.is_empty(),"one plaza exists and temporary resource holds are released")
 var anchor: Vector2=game.player.position;var look: Dictionary=game.player.cosmetic.duplicate();var rpg: Dictionary=game.rpg.data.duplicate(true)
 for id in ["fox_forest","moon_palace","red_sea"]:
  for repeat_id in range(2):
   game.request_gallery(0);await ready_game(game);check(game.modal_kind=="painting","gallery prepares before displaying UI")
   if id=="fox_forest" and repeat_id==0:check(game.Save.load_game().get("return_anchor",{}).get("position",[])==[anchor.x,anchor.y],"gallery commits its completed return anchor before world entry")
   game.adventure.selected_world=id;game.adventure.enter_painting();game.adventure.enter_painting();await ready_game(game)
   check(game.adventure.in_mission and game.adventure.active_world==id and game.adventure.forest.build_ready,id+" actual first/repeat destination ready")
   check(game.player.cosmetic==look and game.camera.is_current(),id+" appearance and camera retained")
   if id=="fox_forest" and repeat_id==0:
    game.rpg.data.hp=0;game.adventure.request_retry();await ready_game(game)
    check(game.rpg.data.hp==game.rpg.max_hp() and game.adventure.forest.build_ready,"actual retry route prepares a fresh mission before restoring controls")
   game.adventure.return_to_plaza();await ready_game(game);check(not game.adventure.in_mission and game.player.position.distance_to(anchor)<.2,id+" return restores plaza anchor")
 game.request_gallery(0);await ready_game(game);game.adventure.selected_world="moon_palace";game.adventure.enter_painting();await ready_game(game);game.save_progress()
 var resumed_position: Vector2=game.player.position;game.show_menu(false);await frames();game.request_start(true);await ready_game(game)
 check(game.adventure.in_mission and game.adventure.active_world=="moon_palace" and game.adventure.forest.build_ready,"continue waits for both plaza and saved adventure preparation")
 check(game.player.position.distance_to(resumed_position)<.2,"continue restores saved adventure position")
 game.adventure.return_to_plaza();await ready_game(game)
 game.enter_practice("shield");game.enter_practice("smoke");await ready_game(game)
 check(game.practice.session.selected=="shield","duplicate training entry cannot replace selected skill")
 var before: Dictionary=game.rpg.data.duplicate(true);game.practice.request_leave();await ready_game(game);check(game.practice==null and game.rpg.data==before,"training return does not mutate real progression")
 var last_save: Dictionary=game.Save.load_game().duplicate(true)
 game.loading.begin("practice");game.save_progress();check(game.Save.load_game()==last_save,"saving during preparation preserves the last committed save");game.loading.complete()
 var retry_count: Array=[0]
 game.loading.begin("practice",func()->void:retry_count[0]+=1)
 var clock: float=game.loading.overlay.clock;await frames(12)
 check(game.loading.overlay.clock>clock+.05,"overlay animation continues across waiting frames")
 var ok: bool=await game.loading.prepare(["res://missing-loading-test-resource.png"])
 check(not ok and game.loading.failed and game.content_loading,"missing resource produces explicit recoverable failure")
 var retry: Button
 for node in game.loading.overlay.get_children():
  for b in node.get_children():
   if b is Button and b.text=="다시 시도":retry=b
 retry.pressed.emit();await frames();check(retry_count[0]==1 and not game.content_loading,"failure retry releases old request and runs once")
 game.loading.begin("practice");await game.loading.prepare(["res://missing-loading-test-resource.png"]);game.go_back();check(not game.content_loading and not game.paused,"Android back exits failure to preserved safe scene")
 check(game.player.cosmetic==look and game.rpg.data.slots==rpg.slots,"error recovery preserves appearance and equipment")
 game.loading.begin("return",Callable(),game.adventure.abort_world_load);game.camera.free();game.loading.failure("카메라 테스트 오류")
 check(is_instance_valid(game.camera) and game.camera.is_current() and not game.adventure.in_mission,"missing camera recovery recreates a safe plaza camera")
 game.go_back();check(not game.content_loading and not game.paused,"camera failure can return to safe playable plaza")
 var f:=FileAccess.open("res://builds/loading-system.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"platform":"Linux headless; not Android hardware","requests":game.loading.history},"  "))
 game.queue_free();await frames();print("LOADING SYSTEM: %d checks / %d failures"%[checks,failures]);quit(1 if failures else 0)
