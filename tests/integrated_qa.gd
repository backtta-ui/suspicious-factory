extends SceneTree
const D=preload("res://scripts/ui/design.gd")
var results: Array=[]
var failures:=0
func check(ok: bool,id: String,detail: String,fixed: bool=false) -> void:
 results.append({"id":id,"status":("FIXED" if fixed else "PASS") if ok else "FAIL","detail":detail,"method":"Godot runtime"})
 if ok:print("PASS: "+id+" "+detail)
 else:failures+=1;push_error(id+" "+detail)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func find(text: String,node: Node) -> Button:
 if node is Button and node.text==text:return node
 for child in node.get_children():
  var b:=find(text,child)
  if b:return b
 return null
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 var anchor: Vector2=game.Layout.safe_position(Vector2(1900,350));game.player.position=anchor;game.player.facing=3;game.save_progress()
 var stick_rect: Rect2=game.joystick.get_global_rect();var hp_rect: Rect2=game.adventure.hp_bar.get_global_rect()
 check(stick_rect.size==D.STICK_SIZE,"HUD-STICK-PLAZA","plaza uses shared joystick size")
 for world in ["fox_forest","moon_palace","red_sea"]:
  game.show_painting_intro(["fox_forest","moon_palace","red_sea"].find(world));game.close_modal()
  check(game.adventure.load_world(world),"ENTRY-"+world,"actual world loads")
  await frames()
  check(game.joystick.get_global_rect()==stick_rect,"HUD-STICK-"+world,"same movement geometry across worlds")
  check(game.adventure.hp_bar.get_global_rect()==hp_rect,"HUD-HP-"+world,"same real HP bar geometry")
  check(game.player.cosmetic==game.wardrobe.data.appearance,"LOOK-"+world,"saved appearance retained")
  check(game.adventure.combat_buttons[0].visible==(world=="fox_forest"),"CAPABILITY-"+world,"combat capability follows existing world design")
  var saved: Vector2=game.player.position
  game.adventure.show_menu();await frames()
  var return_button:=find("광장으로 돌아가기",game.modal)
  check(return_button!=null,"RETURN-MENU-"+world,"direct return available far from entrance",true)
  game.close_modal();game.player.position=saved+Vector2(70,0)
  game.adventure.return_to_plaza();await create_timer(.1).timeout
  check(game.adventure.transition_layer.world_title==preload("res://scripts/worlds/catalog.gd").find(world).title,"TRANSITION-"+world,"transition uses actual world title",true)
  check(game.adventure.transition_layer.painting.resource_path==preload("res://scripts/worlds/catalog.gd").find(world).thumbnailAsset,"ART-"+world,"transition uses actual painting resource",true)
  await create_timer(2.5).timeout;await frames()
  check(not game.adventure.in_mission and game.player.position.distance_to(anchor)<.2,"RETURN-ANCHOR-"+world,"original plaza position restored")
 var child_count: int=game.ui.get_child_count()
 for i in range(12):
  game.adventure.show_menu();var old: Control=game.modal;var old_button:=find("돌아가기",old);game.close_modal()
  check(old_button.disabled and not old_button.usable(),"RETIRE-"+str(i),"retiring popup cannot activate stale controls",true)
 await create_timer(.25).timeout;await frames()
 check(game.ui.get_child_count()==child_count,"POPUP-CLEANUP","repeated fading popups retire without retained nodes")
 var stack: VBoxContainer=game.open_modal("qa_long_list");var activated:=[]
 for i in range(24):stack.add_child(game.button("긴 목록 항목 %d"%i,func()->void:activated.append(true)))
 await frames()
 var scroll: ScrollContainer=stack.get_parent();var origin:=scroll.get_global_rect().get_center()
 var touch:=InputEventScreenTouch.new();touch.index=8;touch.position=root.get_final_transform()*origin;touch.pressed=true;Input.parse_input_event(touch);Input.flush_buffered_events()
 var drag:=InputEventScreenDrag.new();drag.index=8;drag.position=root.get_final_transform()*(origin-Vector2(0,350));drag.relative=Vector2(0,-350);Input.parse_input_event(drag);Input.flush_buffered_events();await frames()
 touch=InputEventScreenTouch.new();touch.index=8;touch.position=root.get_final_transform()*(origin-Vector2(0,350));touch.pressed=false;Input.parse_input_event(touch);Input.flush_buffered_events();await frames()
 check(scroll.scroll_vertical>200 and activated.is_empty(),"POPUP-SCROLL","shared native touch scroll cancels button activation",true)
 scroll.scroll_vertical=100000;await frames()
 check(scroll.get_global_rect().has_point(stack.get_child(23).get_global_rect().get_center()),"POPUP-LAST","last common-menu button remains reachable",true)
 game.close_modal();await frames()
 var button: Button=game.spell_button;D.decorate(button,"jar");D.decorate(button,"jar")
 check(button.get_children().filter(func(n: Node)->bool:return n is WooSkillBadge).size()==1,"BADGE-IDEMPOTENT","repeated decoration creates no duplicate skill layer",true)
 var data: Dictionary=game.rpg.data.duplicate(true);var look: Dictionary=game.wardrobe.data.duplicate(true)
 game.enter_practice("track");game.enter_practice("smoke")
 check(game.content_loading,"LOAD-GUARD","loading is explicit and blocks duplicate entry",true)
 game.go_back();await frames(8)
 check(is_instance_valid(game.practice) and not game.content_loading,"LOAD-READY","practice starts once and clears loading state")
 var room: WooPracticeUI=game.practice
 check(room.stick.get_global_rect()==stick_rect,"HUD-STICK-PRACTICE","training and adventure joystick match",true)
 check(room.vitality.get_global_rect()==hp_rect,"HUD-HP-PRACTICE","training uses same HP component geometry",true)
 check(room.cast_button.size==D.ACTIONS.spell.size,"HUD-SPELL-PRACTICE","common spell dimensions override old minimum size",true)
 room.leave();await frames()
 check(game.rpg.data==data and game.wardrobe.data==look,"PRACTICE-ISOLATION","UI transitions preserve RPG and cosmetics")
 check(game.player.position.distance_to(anchor)<.2,"PRACTICE-ANCHOR","training restores same plaza node and location")
 game.queue_free();await frames()
 var file:=FileAccess.open("res://builds/integrated-qa.json",FileAccess.WRITE);file.store_string(JSON.stringify({"cases":results,"failures":failures,"android_device":false},"  "));file.close()
 print("INTEGRATED QA: %d cases / %d failures"%[results.size(),failures]);quit(1 if failures else 0)
