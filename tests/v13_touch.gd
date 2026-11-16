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
 var e:=InputEventScreenTouch.new();e.position=root.get_final_transform()*p;e.index=id;e.pressed=on;Input.parse_input_event(e)
func tap(button: Control,id: int) -> void:
 var p:=button.get_global_rect().get_center();touch(p,true,id);await frames(2);touch(p,false,id);await frames(3)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 for dimensions in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(2340,1080),Vector2i(2280,1080),Vector2i(960,540)]:
  root.size=dimensions;await frames();game.start_game(false);await frames()
  game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
  var prefix: String="%dx%d: " % [dimensions.x,dimensions.y]
  var rect:=Rect2(Vector2.ZERO,game.ui.size)
  var buttons: Array=game.adventure.combat_buttons
  check(buttons.all(func(b: Button)->bool:return rect.encloses(b.get_global_rect())),prefix+"all combat targets inside logical safe viewport")
  var overlap:=false
  for i in range(buttons.size()):
   for j in range(i):
    if buttons[i].get_global_rect().intersection(buttons[j].get_global_rect()).get_area()>1:overlap=true
  check(not overlap,prefix+"attack dodge and skill targets do not overlap")
  check(buttons.all(func(b: Button)->bool:return not b.get_global_rect().intersects(game.joystick.get_global_rect())),prefix+"combat controls clear joystick")
  var center: Vector2=game.joystick.get_global_rect().get_center()
  touch(center+Vector2(60,0),true,0);await frames()
  await tap(buttons[0],1)
  check(game.joystick.finger==0 and game.adventure.attack_cd>0,prefix+"native move and attack multitouch")
  game.adventure.talisman_cd=0
  await tap(buttons[2],1);await create_timer(.55).timeout
  check(game.joystick.finger==0 and game.rpg.data.mp==38,prefix+"native move and skill multitouch")
  await tap(buttons[1],1)
  check(game.joystick.finger==0 and game.adventure.dodge_cd>0,prefix+"native move and dodge multitouch")
  touch(center,false,0);await frames()
  game.adventure.show_map();await frames();var before: Vector2=game.player.position
  touch(center+Vector2(65,0),true,0);await frames(5)
  check(game.paused and game.player.position.distance_to(before)<.1 and game.joystick.finger==-1,prefix+"expanded map blocks movement")
  touch(center,false,0);game.go_back();await frames()
  check(not game.paused,prefix+"Android back closes map and restores input")
  game.show_menu();await frames(5)
 game.queue_free();await frames()
 print("V1.3 TOUCH: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
