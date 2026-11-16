extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func touch(p: Vector2,on: bool,id: int) -> void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=root.get_final_transform()*p;e.pressed=on;Input.parse_input_event(e);Input.flush_buffered_events()
func tap(button: Button) -> void:
 var p:=button.get_global_rect().get_center();touch(p,true,1);await frames(1);touch(p,false,1);await frames()
func find(label: String,node: Node) -> Button:
 if node is Button and node.text==label:return node
 for child in node.get_children():
  var b:=find(label,child)
  if b:return b
 return null
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 for size in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(2340,1080),Vector2i(960,540)]:
  root.size=size;await frames();game.start_game(false);await frames();game.enter_practice("clone");await frames()
  var room: WooPracticeUI=game.practice;var prefix:=str(size)+" "
  var buttons: Array=[]
  for child in game.ui.get_children():
   if child is Button:buttons.append(child)
  check(buttons.all(func(b: Button)->bool:return Rect2(Vector2.ZERO,game.ui.size).encloses(b.get_global_rect())),prefix+"all practice touch bounds visible")
  var overlap:=false
  for i in range(buttons.size()):
   for j in range(i):
    if buttons[i].get_global_rect().intersection(buttons[j].get_global_rect()).get_area()>1:overlap=true
  check(not overlap,prefix+"right action targets never overlap")
  var center:=room.stick.get_global_rect().get_center();touch(center+Vector2(55,0),true,0);await frames()
  var start: Vector2=room.hero.position;await tap(room.cast_button);await create_timer(.16).timeout
  check(room.stick.finger==0 and room.hero.position.x>start.x and not room.clones.is_empty(),prefix+"native movement and simultaneous skill touch work")
  touch(center,false,0);await tap(find("도술 목록",game.ui));check(game.modal_kind=="practice_spells" and room.stick.finger==-1,prefix+"native skill menu clears movement capture")
  var menu: WooPracticeSpellList
  for child in game.modal.get_children():
   if child is WooPracticeSpellList:menu=child
  var scroll_center:=menu.scroll.get_global_rect().get_center();var selected_before:=menu.selected
  touch(scroll_center,true,4)
  var drag:=InputEventScreenDrag.new();drag.index=4;drag.position=root.get_final_transform()*(scroll_center-Vector2(0,500));drag.relative=Vector2(0,-500);Input.parse_input_event(drag);Input.flush_buffered_events();await frames()
  touch(scroll_center-Vector2(0,500),false,4);await frames()
  check(menu.scroll.scroll_vertical>100 and menu.selected==selected_before,prefix+"touch swipe scrolls without accidentally selecting card")
  menu.scroll.scroll_vertical=100000;await frames()
  var last: Control=menu.cards.talisman;var last_center:=last.get_global_rect().get_center()
  check(menu.scroll.get_global_rect().has_point(last_center),prefix+"last registered spell is fully reachable above fixed footer")
  touch(last_center,true,5);touch(last_center,false,5);await frames()
  check(menu.selected=="talisman" and room.session.selected=="clone",prefix+"selection preview does not cast or mutate active spell")
  game.go_back();await frames();check(game.active_context=="practice" and room.stick.input_enabled,prefix+"back restores practice input context")
  await tap(find("수련 설정",game.ui));await tap(find("수련 초기화",game.ui));check(room.session.rules.effects.is_empty(),prefix+"native reset removes active skill effects")
  await tap(find("광장 복귀",game.ui));check(game.screen_name=="playing" and not is_instance_valid(game.practice),prefix+"native exit restores preserved plaza")
  game.show_menu(false);await frames()
 game.queue_free();await frames();print("PRACTICE TOUCH: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
