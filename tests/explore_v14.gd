extends SceneTree
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_game(false);await process_frame
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await physics_frame
 for n in game.adventure.actions.enemies():n.set_physics_process(false)
 Engine.time_scale=10
 for zone in WooForestLayout.ZONES:
  var path: PackedVector2Array=game.adventure.forest.route(game.player.position,WooForestLayout.safe(zone.center))
  for point in path:
   var guard:=0
   while game.player.position.distance_to(point)>12 and guard<100:
    game.joystick.vector=(point-game.player.position).normalized();game.player.running=true
    await physics_frame;guard+=1
  game.joystick.reset();game.player.running=false
  check(game.player.position.distance_to(WooForestLayout.safe(zone.center))<60,"actual collision-body walks into "+zone.name)
 Engine.time_scale=1
 check(WooForestLayout.can_stand(game.player.position),"all-zone traversal finishes on legal ground")
 game.queue_free();await process_frame;await process_frame;print("EXPLORE V1.4: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
