extends SceneTree
const Layout=preload("res://scripts/worlds/plaza_layout.gd")
var Legacy=load(OS.get_environment("WOO_LEGACY_FIXTURE") if not OS.get_environment("WOO_LEGACY_FIXTURE").is_empty() else "res://tests/fixtures/legacy_v012_layout.gd")
const Save=preload("res://scripts/woo/save_game.gd")
var game: Node
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):
  await physics_frame
  await process_frame
func button_named(title: String,node: Node) -> Button:
 if node is Button and node.text==title:return node
 for child in node.get_children():
  var found:=button_named(title,child)
  if found:return found
 return null
func tap(button: Button) -> void:
 var p:=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event:=InputEventScreenTouch.new();event.position=p;event.pressed=pressed;event.index=0
  Input.parse_input_event(event);Input.flush_buffered_events();await frames(4)
func nearest_cell(p: Vector2,grid: AStarGrid2D) -> Vector2i:
 var cell:=Vector2i(((p-Vector2(0,20))/40).round())
 for r in range(5):
  for x in range(-r,r+1):
   for y in range(-r,r+1):
    var q:=cell+Vector2i(x,y)
    if grid.is_in_boundsv(q) and not grid.is_point_solid(q):return q
 return Vector2i(-1,-1)
func walk_to(p: Vector2,grid: AStarGrid2D) -> bool:
 var start:=nearest_cell(game.player.position,grid);var finish:=nearest_cell(p,grid)
 var path:=grid.get_point_path(start,finish)
 if path.is_empty():return false
 for point in path:
  var ticks:=0
  while game.player.position.distance_to(point)>10 and ticks<90:
   game.joystick.vector=(point-game.player.position).normalized();await physics_frame;ticks+=1
  if ticks>=90:print("WALK BLOCKED AT ",game.player.position," target=",point);game.joystick.reset();return false
 game.joystick.reset();return game.player.position.distance_to(p)<100
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(4)
 check(game.menu_motion!=null and game.menu_motion.mouse_filter==Control.MOUSE_FILTER_IGNORE,"animated entry artwork does not intercept touch")
 var before: float=game.menu_motion.elapsed;await frames(4)
 check(game.menu_motion.elapsed>before,"entry scene motion advances")
 check(game.sound.MUSIC.get_length()>60 and game.sound.music.stream.loop,"bundled Korean BGM has a valid looping stream")
 game.show_settings();await frames(3);var old_music: bool=game.settings.music
 await tap(button_named("배경음악: "+("켜짐" if old_music else "꺼짐"),game.ui))
 check(game.settings.music!=old_music and game.sound.music_requested==game.settings.music,"native touch toggles BGM independently")
 var effects: bool=game.settings.low_effects
 await tap(button_named("환경 효과: "+("간소화" if effects else "풍부하게"),game.ui))
 check(game.settings.low_effects!=effects and game.menu_motion.reduced==game.settings.low_effects,"quality setting reduces entry motion")
 game.close_modal();game.start_game(false);await frames(4)
 check(game.camera.zoom==Vector2(2,2),"map expansion retains character/camera scale")
 var old_count:=0;var new_count:=0
 var grid:=AStarGrid2D.new();grid.region=Rect2i(0,0,86,49);grid.cell_size=Vector2(40,40);grid.offset=Vector2(0,20);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
 for x in range(86):
  for y in range(49):
   var p:=Vector2(x*40,y*40)
   if Legacy.can_stand(p):old_count+=1
   if Layout.can_stand(p):new_count+=1
   grid.set_point_solid(Vector2i(x,y),not Layout.can_stand(p+Vector2(0,20),16))
 var ratio:=float(new_count)/old_count
 print("WALKABLE AREA: old=",old_count*1600," new=",new_count*1600," ratio=",ratio)
 check(ratio>=4 and ratio<=6.2,"walkable area is approximately four to six times larger")
 var start:=nearest_cell(Layout.SPAWN,grid)
 for zone in Layout.ZONES:
  check(not grid.get_point_path(start,nearest_cell(zone.center,grid)).is_empty(),"connected walkable route to "+zone.name)
 for painting in Layout.PAINTINGS:
  check(not grid.get_point_path(start,nearest_cell(painting.position+Vector2(0,55),grid)).is_empty(),"walkable approach to "+painting.name)
 Engine.time_scale=5;game.player.running=true
 for zone in Layout.ZONES:
  check(await walk_to(zone.center,grid),"actual character walks to "+zone.name)
 game.player.running=false;Engine.time_scale=1
 # The bridge has a genuine collision-free deck, with solid water above/below.
 check(not Layout.can_stand(Vector2(1700,1210)) and not Layout.can_stand(Vector2(1700,1380)),"pond rejects walking on water")
 check(Layout.can_stand(Vector2(1700,1300)),"stone bridge deck crosses the pond")
 game.player.position=Vector2(1440,1300);game.joystick.vector=Vector2.RIGHT;game.player.running=true
 Engine.time_scale=5;await frames(48);Engine.time_scale=1;game.joystick.reset();game.player.running=false
 check(game.player.position.x>1940,"physical character crosses the entire bridge")
 game.player.position=Vector2(1700,1160);game.joystick.vector=Vector2.DOWN;await frames(30);game.joystick.reset()
 check(game.player.position.y<1180,"pond collision stops the physical character")
 for i in range(1):
  game.player.position=preload("res://scripts/worlds/catalog.gd").ENTRY+Vector2(0,55);await frames(5)
  check(game.nearest_painting==i and game.interact_button.visible,"painting proximity detected "+str(i))
  var anchor: Vector2=game.player.position
  await tap(game.interact_button)
  check(game.modal_kind=="painting" and game.paused and not button_named("그림 속으로",game.ui).disabled,"painting intro matches implemented or locked stage "+str(i))
  await tap(button_named("닫기",game.ui))
  check(not game.paused and game.player.position.distance_to(anchor)<1,"painting close restores movement without teleport "+str(i))
  game.player.position=Layout.SPAWN
  check(game.restore_plaza_anchor() and game.player.position.distance_to(anchor)<1,"future return anchor restores entry position "+str(i))
 # Existing positions remain exact unless a new prop occupies that old location.
 game.set_paused(true);game.finish_save();game.save_elapsed=0
 var legacy: Dictionary={"schema":1,"map":Layout.MAP_ID,"position":[1050,600],"settings":{"smooth_camera":false},"unlocked":["jar"],"jar":true,"talked_to_elder":true,"time_of_day":0.4}
 check(Save.save_game(legacy)==OK,"original V0.1.2 save accepted before migration")
 var migrated:=Save.load_game()
 print("MIGRATED ",JSON.stringify(migrated))
 check(migrated.jar and migrated.talked_to_elder and migrated.unlocked.has("jar") and migrated.get("legacy_position",[]).size()==2 and Vector2(migrated.legacy_position[0],migrated.legacy_position[1])==Vector2(1050,600),"migration preserves role-free character state and original occupied position")
 check(Layout.can_stand(Vector2(migrated.position[0],migrated.position[1])) and Save.save_game(migrated)==OK,"migrated position is nearby, safe and can be saved again")
 migrated.completed_paintings=["fox_forest","goblin_night"]
 check(Save.save_game(migrated)==OK and Save.load_game().completed_paintings.size()==2,"future painting completion data persists")
 game.world.set_completed_stories(migrated.completed_paintings)
 check(game.world.great_tree.story_count==2,"tree growth reflects completion data without inventing a mission")
 migrated.completed_paintings=["fox_forest","fox_forest"]
 check(not Save.valid(migrated),"duplicate completion data rejected")
 for actor in game.actors.slice(1):check(Layout.can_stand(actor.position,0),"resident remains outside buildings and water")
 print("PLAZA V1.1: %d checks, %d failures" % [checks,failures])
 game.queue_free();await frames(3);quit(0 if failures==0 else 1)
