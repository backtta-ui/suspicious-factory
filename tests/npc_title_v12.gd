extends SceneTree
const Layout=preload("res://scripts/woo/village_layout.gd")
const Save=preload("res://scripts/woo/save_game.gd")
var game: Node
var checks:=0
var failures:=0
var patrol_measurements:=[]
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):await physics_frame
func find_button(title: String,node: Node) -> Button:
 if node is Button and node.text==title:return node
 for child in node.get_children():
  var b:=find_button(title,child)
  if b:return b
 return null
func touch(p: Vector2,down: bool) -> void:
 var event:=InputEventScreenTouch.new();event.position=root.get_final_transform()*p;event.pressed=down;event.index=0
 Input.parse_input_event(event);Input.flush_buffered_events()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(5):await process_frame
 var settings:=find_button("설정",game.ui);var ornament: Control
 for child in settings.get_children():
  if child is WooOrnament:ornament=child
 touch(settings.get_global_rect().get_center(),true);await frames(6)
 check(ornament.glow>.05,"native press raises the gold-border glow")
 touch(settings.get_global_rect().get_center(),false);await frames(16)
 check(game.modal_kind=="settings" and ornament.glow<.01,"release opens settings once and border glow fades")
 game.close_modal();game.start_game(false);await frames(5)
 for actor in game.actors.slice(1,4):
  actor.set_physics_process(false);actor.facing=2;actor.npc_walking=true;actor.npc_driver.state="walk"
  var head_positions:=[];var heads:=[];var feet:=[];var leads:=[]
  for stride in [0.0,6.0,12.0,18.0]:
   actor.npc_stride=stride;actor.update_npc_art()
   head_positions.append(actor.sprite.position);heads.append(actor.sprite.region_rect);feet.append(actor.npc_left_foot.region_rect)
   leads.append(actor.npc_left_foot.position.x+actor.npc_right_foot.position.x)
  check(head_positions.all(func(p: Vector2)->bool:return p==head_positions[0]) and heads.all(func(r: Rect2)->bool:return r==heads[0]),actor.npc_name+" head/torso origin stays fixed across gait frames")
  check(feet[0]!=feet[1] and feet[1]!=feet[2] and feet[2]!=feet[3],actor.npc_name+" uses four distinct foot/leg art frames")
  actor.npc_stride=6;actor.update_npc_art();var left_a: float=actor.npc_left_foot.position.y;var right_a: float=actor.npc_right_foot.position.y
  actor.npc_stride=18;actor.update_npc_art()
  check(actor.npc_left_foot.position.y>left_a and actor.npc_right_foot.position.y<right_a,actor.npc_name+" left/right contact and swing phases alternate")
  actor.npc_walking=false;actor.update_npc_art();var still: Vector2=actor.npc_left_foot.position;actor.update_npc_art()
  check(actor.npc_left_foot.position==still,actor.npc_name+" idle foot positions do not accumulate drift")
  actor.set_physics_process(true)
 var resident=game.actors[1]
 game.player.position=Layout.safe_position(resident.position+Vector2(350,300))
 resident.npc_driver.begin_wait(10);resident.npc_attention=false
 var anchor: Vector2=resident.position
 Engine.time_scale=2
 var max_idle_delta:=0.0
 for i in range(90):
  await physics_frame;max_idle_delta=maxf(max_idle_delta,resident.position.distance_to(anchor))
 check(max_idle_delta<.001,"idle NPC root remains exactly still instead of chasing a moving target")
 Engine.time_scale=8
 for actor in game.actors.slice(1):
  var observer: Vector2=actor.npc_origin+Vector2(430,350);observer.x=minf(observer.x,2820);observer.y=minf(observer.y,1460)
  game.player.position=Layout.safe_position(observer)
  actor.npc_attention=false;actor.npc_driver.begin_wait(.1)
  var before: float=actor.npc_driver.travelled
  var extent:=0.0;var origin: Vector2=actor.position
  for i in range(180):
   await physics_frame
   extent=maxf(extent,actor.position.distance_to(origin))
  patrol_measurements.append({"name":actor.npc_name,"travelled":actor.npc_driver.travelled-before,"extent":extent})
  print("PATROL ",JSON.stringify(patrol_measurements[-1]))
  check(actor.npc_driver.travelled-before>45 and extent>24,actor.npc_name+" actually patrols beyond the former tiny ellipse")
  check(Layout.can_stand(actor.position,0),actor.npc_name+" stays out of static obstacles and water")
 var queries: int=game.world.navigation.queries
 check(queries<1000,"cached route queries are event-driven, not run for every NPC every frame")
 # Deliberately aim at a wall to exercise the blocked-path fallback.
 game.player.position=Vector2(1000,700);resident.position=Vector2(710,390);resident.npc_attention=false
 resident.npc_driver.state="walk";resident.npc_driver.path=PackedVector2Array([Vector2(710,310)]);resident.npc_driver.cursor=0;resident.npc_driver.blocked_time=0
 Engine.time_scale=4;await frames(30)
 check(resident.npc_driver.state!="walk" and resident.velocity.length()<.01,"blocked NPC stops and waits instead of vibrating against a wall")
 var stopped: Vector2=resident.position;await frames(5)
 check(resident.position.distance_to(stopped)<.01,"blocked fallback preserves a stationary root")
 game.player.position=Layout.ZONES[4].center;await frames(2)
 var position: Vector2=resident.position;var timer: float=resident.npc_driver.timer;var plans: int=resident.npc_driver.replans
 await frames(35)
 check(not resident.enabled and resident.position==position and resident.npc_driver.timer==timer and resident.npc_driver.replans==plans,"distant NPC does not animate, move or replan")
 Engine.time_scale=1
 # Preserve a V1.1 save even when a relocated shop occupies its old walkable point.
 game.set_paused(true);game.finish_save()
 var old: Dictionary={"schema":1,"map":Layout.MAP_ID,"map_revision":2,"position":[1640,1050],"settings":{"smooth_camera":true},"unlocked":["jar"],"jar":true,"talked_to_elder":true,"completed_paintings":["fox_forest"],"return_anchor":{"map":Layout.MAP_ID,"position":[1900,400]},"time_of_day":.4}
 check(Save.save_game(old)==OK,"V1.1 revision-2 save is accepted without wiping progress")
 var migrated:=Save.load_game()
 check(migrated.jar and migrated.talked_to_elder and migrated.completed_paintings==["fox_forest"] and migrated.return_anchor.position.size()==2 and migrated.map_revision==3,"V1.1 position migration retains spell, quest, painting and return-anchor state")
 check(Layout.can_stand(Vector2(migrated.position[0],migrated.position[1])) and migrated.has("legacy_position"),"occupied old position is relocated nearby with original coordinates retained")
 var report: Dictionary={"status":"failed" if failures else "passed","checks":checks,"idle_max_drift":max_idle_delta,"route_queries":queries,"patrols":patrol_measurements,"device_test":"not_performed"}
 var file:=FileAccess.open("res://builds/v12-npc-measurements.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("NPC/TITLE V1.2: %d checks, %d failures; route queries=%d" % [checks,failures,queries])
 game.queue_free();await frames(3);quit(1 if failures else 0)
