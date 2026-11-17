extends SceneTree
const Worlds=preload("res://scripts/worlds/catalog.gd")
const Layout=preload("res://scripts/worlds/layout.gd")
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func frames(n: int=4) -> void:
 await preload("res://tests/loading_wait.gd").settle(self,n)
func swipe(a: Vector2,b: Vector2) -> void:
 var event:=InputEventScreenTouch.new();event.index=5;event.position=root.get_final_transform()*a;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
 event=InputEventScreenTouch.new();event.index=5;event.position=root.get_final_transform()*b;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func gallery() -> WooPaintingGallery:
 for child in game.modal.get_children():
  if child is WooPaintingGallery:return child
 return null
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 check(game.Layout.PROPS.filter(func(p: Dictionary)->bool:return p.kind=="painting").size()==1,"exactly one actual painting prop, old records retained")
 # A previously valid revision4 coordinate can be occupied by the new frame.
 var legacy: Dictionary={"schema":1,"map":game.Layout.MAP_ID,"map_revision":4,"position":[1900,350],"settings":{},"unlocked":["jar"],"jar":false,"time_of_day":.4,"talked_to_elder":true,"completed_paintings":["fox_forest"],"return_anchor":{},"rpg":game.rpg.data.duplicate(true)}
 game.finish_save()
 check(game.Save.save_game(legacy)==OK,"revision4 occupied painting position is accepted for migration")
 var migrated: Dictionary=game.Save.load_game()
 check(not migrated.is_empty() and migrated.talked_to_elder and migrated.completed_paintings==["fox_forest"] and migrated.rpg.inventory==game.rpg.data.inventory and game.Layout.can_stand(Vector2(migrated.position[0],migrated.position[1])) and Vector2(migrated.legacy_position[0],migrated.legacy_position[1])==Vector2(1900,350),"revision5 relocates only occupied position without losing progress")
 check(preload("res://scripts/woo/village_layout.gd").REVISION==4 and game.Layout.REVISION==5 and preload("res://scripts/woo/village_layout.gd").PROPS.filter(func(p: Dictionary)->bool:return p.kind=="painting").size()==3,"multiplayer retains original layout while story uses isolated revision5")
 check(Worlds.WORLDS.size()==3 and Worlds.WORLDS.all(func(w: Dictionary)->bool:return w.unlocked and not w.mapId.is_empty()),"three data-driven real open maps")
 var look: Dictionary=game.player.cosmetic.duplicate();var inventory: Dictionary=game.rpg.data.inventory.duplicate();var xp: int=game.rpg.data.xp
 game.player.position=Worlds.ENTRY+Vector2(0,65);await frames(6);check(game.nearest_painting==0 and game.interact_button.visible,"single entrance reached through actual plaza proximity")
 game.interact();await frames();var ui:=gallery();check(is_instance_valid(ui) and game.paused,"full-screen selector pauses local controls")
 check(ui.get_rect().size==game.get_viewport().get_visible_rect().size,"selector covers landscape viewport")
 await swipe(Vector2(800,270),Vector2(300,270));await create_timer(.3).timeout;check(ui.selected==1 and game.adventure.selected_world=="moon_palace","native left swipe selects palace")
 await swipe(Vector2(300,270),Vector2(800,270));await create_timer(.3).timeout;check(ui.selected==0,"native right swipe selects previous painting")
 ui.change(1);ui.change(1);ui.change(-1);await create_timer(.3).timeout;check(ui.selected==1 and not ui.busy,"rapid input cannot skip or select stale slide")
 game.go_back();await frames();check(not is_instance_valid(game.modal) and not game.paused,"Android back closes selector and restores movement")
 for index in range(3):
  game.player.position=Worlds.ENTRY+Vector2(0,65);game.player.facing=4;game.camera.zoom=Vector2(2.1,2.1);game.camera.rotation=.02
  var origin: Vector2=game.player.position
  game.show_painting_intro(index);await frames();ui=gallery();check(ui.selected==index,"correct painting selected "+Worlds.WORLDS[index].id)
  ui.enter();game.adventure.enter_painting();await create_timer(2.7).timeout;await frames()
  var adv: WooAdventure=game.adventure;var id: String=Worlds.WORLDS[index].id
  check(adv.in_mission and adv.active_world==id and game.player.get_parent()==adv.forest and not game.world.visible and not adv.transitioning,"actual transition loads unique playable map "+id)
  check(game.player.cosmetic==look and game.Save.valid(game.Save.load_game()),"appearance and saved schema valid in "+id)
  if index>0:
   check(not adv.can_fight() and adv.combat_buttons.all(func(b: Button)->bool:return not b.visible),"exploration does not invent combat "+id)
   var grid:=AStarGrid2D.new();grid.region=Rect2i(0,0,90,65);grid.cell_size=Vector2(20,20);grid.offset=Vector2(10,10);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
   for y in range(65):
    for x in range(90):
     var p:=Vector2(x*20+10,y*20+10);var solid:=not Geometry2D.is_point_in_polygon(p,Layout.bounds(id))
     for object in Layout.objects(id):
      if Layout.footprint(object).grow(18).has_point(p):solid=true
     grid.set_point_solid(Vector2i(x,y),solid)
   for site in Layout.sites(id):
    var path:=grid.get_point_path(Vector2i(Layout.spawn(id)/20),Vector2i(site.p/20));check(not path.is_empty(),"connected walkable route to "+site.id)
    game.player.position=site.p;await frames();game.interact();await frames();check(game.modal_kind=="world_glyph","real world interaction "+site.id);game.close_modal()
   game.player.position=Vector2(100,1100);game.joystick.vector=Vector2.LEFT;await create_timer(.65).timeout;game.joystick.reset();check(game.player.position.x>=79 if id=="red_sea" else game.player.position.x>=69,"physical boundary prevents water/outside escape "+id)
   game.save_progress();check(game.last_save_error==OK and game.Save.load_game().rpg.session.map==id,"new map session durably stored "+id)
   game.enter_practice("blink");await frames();check(game.screen_name=="practice","codex practice retained inside "+id);game.practice.leave();await frames();check(adv.active_world==id and game.player.get_parent()==adv.forest,"practice returns to same exploration instance")
  check(game.rpg.data.inventory==inventory and game.rpg.data.xp==xp,"no invented rewards or erased inventory "+id)
  adv.return_to_plaza();await create_timer(2.7).timeout;await frames()
  check(not adv.in_mission and game.player.get_parent()==game.world and game.player.position.distance_to(origin)<1 and game.player.facing==4,"exact plaza position and facing restored "+id)
  check(game.camera.zoom==Vector2(2.1,2.1) and is_equal_approx(game.camera.rotation,.02),"camera state restored "+id)
 check(game.rpg.data.inventory==inventory and game.player.cosmetic==look,"all three trips preserve inventory and wardrobe")
 game.show_menu(false);game.queue_free();await frames();print("PAINTING WORLDS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
