extends SceneTree
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func touch(p: Vector2,on: bool,id: int) -> void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=root.get_final_transform()*p;e.pressed=on;Input.parse_input_event(e)
func quick(button: Control,id: int) -> void:
 var p:=button.get_global_rect().get_center();touch(p,true,id);Input.flush_buffered_events();touch(p,false,id);Input.flush_buffered_events()
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 for dimensions in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(2340,1080),Vector2i(2280,1080),Vector2i(960,540)]:
  root.size=dimensions;await frames();game.start_game(false);await frames()
  game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
  var adv: WooAdventure=game.adventure
  var prefix: String="%dx%d: " % [dimensions.x,dimensions.y]
  var targets: Array=adv.combat_buttons.duplicate();targets.append(adv.jump_button)
  var bounds:=Rect2(Vector2.ZERO,game.ui.size)
  check(targets.all(func(b: Button)->bool:return bounds.encloses(b.get_global_rect())),prefix+"jump and combat buttons remain on-screen")
  var overlaps:=false
  for i in range(targets.size()):
   for j in range(i):
    if targets[i].get_global_rect().intersection(targets[j].get_global_rect()).get_area()>1:overlaps=true
  check(not overlaps,prefix+"jump attack skills and dodge targets never overlap")
  var center: Vector2=game.joystick.get_global_rect().get_center();touch(center+Vector2(60,0),true,0);await frames()
  for i in range(4):quick(adv.combat_buttons[0],1)
  check(adv.actions.active and adv.actions.queue.size()==3 and game.joystick.finger==0,prefix+"four same-frame native taps reserve combo while steering")
  adv.actions.cancel();quick(adv.jump_button,1);await create_timer(.14).timeout;await frames(2)
  check(game.player.jump_height>0 and game.joystick.finger==0,prefix+"native moving jump keeps joystick ownership")
  quick(adv.combat_buttons[0],1);await frames()
  check(adv.actions.mode=="air",prefix+"native jump then attack enters aerial combat")
  touch(center,false,0);adv.actions.cancel();await create_timer(.8).timeout
  adv.show_inventory();await frames()
  var bundle: WooBundleUI=game.modal.get_child(game.modal.get_child_count()-1)
  check(game.paused and bundle.slot_count==30,prefix+"bundle pauses game and creates 30 real slots")
  var slot: Control=bundle.slots.get_child(4);var p:=slot.get_global_rect().get_center();touch(p,true,2);await create_timer(.65).timeout;touch(p,false,2);await frames()
  check(is_instance_valid(bundle.inspector),prefix+"native long press opens large item appreciation")
  game.go_back();await frames();check(not is_instance_valid(bundle.inspector) and game.paused,prefix+"back closes appreciation without leaking input")
  var inv: Dictionary=game.rpg.data.inventory.duplicate();bundle.category="재료";bundle.rebuild();await frames()
  check(game.rpg.data.inventory==inv,prefix+"category does not mutate inventory")
  game.go_back();await frames();check(not game.paused and game.joystick.finger==-1,prefix+"bundle close restores clean touch state")
  game.show_menu();await frames(5)
 game.queue_free();await frames();print("TOUCH V1.4: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
