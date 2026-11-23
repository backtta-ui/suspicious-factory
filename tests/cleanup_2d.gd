extends SceneTree
const App=preload("res://scenes/survival.tscn")
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("QA ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func tap_at(position: Vector2,finger: int=41) -> void:
 var event:=InputEventScreenTouch.new();event.index=finger;event.pressed=true;event.position=position;Input.parse_input_event(event);await frames(2)
 event=InputEventScreenTouch.new();event.index=finger;event.pressed=false;event.position=position;Input.parse_input_event(event);await create_timer(.4).timeout
func named_button(node: Node,value: String) -> Button:
 for child in node.find_children("*","Button",true,false):
  if child.text==value:return child
 return null
func run() -> void:
 check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/survival.tscn","2D active scene; 3D cancelled")
 var old:=FileAccess.open("user://legacy-original.json",FileAccess.WRITE);old.store_string('{"level":17,"items":["keep"]}');old.close()
 root.size=Vector2i(1280,720);var game:=App.instantiate();root.add_child(game);await frames(8)
 # 2.0.32: 최초 실행은 닉네임 설정이 먼저다. 이 테스트는 이미 닉네임이 있는 상태를 검사한다.
 game.storage.set_nickname("점검도사");game.storage.save();game.build("title");await frames(3)
 check(game.screen=="title" and game.world==null,"title without old plaza")
 check(FileAccess.get_file_as_string("user://legacy-original.json")==FileAccess.get_file_as_string("user://legacy-backup-v13/legacy-original.json"),"old saves byte-preserved in backup")
 var settings_button:=named_button(game.ui,"설정");await tap_at(settings_button.get_global_rect().get_center())
 check(game.screen=="title" and game.modal!=null,"title settings touch does not start game")
 game.close_popup();await frames();await tap_at(Vector2(800,640))
 check(game.screen=="lobby","native full-screen start reaches lobby once")
 var forbidden: Array=["가방","꾸미기","의상","장신구","인벤토리","상점","어드벤처","투표","회의"]
 check(game.ui.find_children("*","Button",true,false).all(func(b: Button)->bool:return forbidden.all(func(word: String)->bool:return not word in b.text)),"removed feature menu entries absent")
 game.create_room("오프라인 회귀",6,true);await create_timer(.4).timeout
 check(game.rules.players.size()==6,"one human plus five marked bots")
 game.rules.players.human.ready=true;game.start_match();await frames()
 check(game.screen=="selection" and game.rules.players.human.role in ["daoist","yokai"],"random team then character screen")
 var own: String=game.rules.players.human.role
 check(not game.rules.select_character("human",C.catalog("daoist" if own=="yokai" else "yokai")[0].id),"opposing character not selectable")
 game.rules.confirm_character("human");check(not game.rules.select_character("human",C.catalog(own)[1].id),"confirmed character cannot change")
 # 2.0.39: 지붕·벽 타일 아틀라스 12장이 로딩에 얹히므로 대기 프레임을 600으로 넓힌다.
 for i in range(600):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match" and game.world is Node2D and game.camera is Camera2D,"existing 2.5D map and camera used")
 game.bots.clear()
 for i in range(61):game.rules.tick(.05)
 await frames()
 for size in [Vector2i(1280,720),Vector2i(960,540),Vector2i(2400,1080)]:
  root.size=size;await frames(8)
  var view:=game.get_viewport().get_visible_rect()
  for b in [game.run_button,game.jump_button,game.skill_buttons["main"],game.skill_buttons["sub"],game.skill_buttons["ult"]]:check(view.encloses(b.get_global_rect()),"HUD inside viewport "+str(size))
  for key in game.action_buttons:
   var context_button: Button=game.action_buttons[key]
   if context_button.visible:check(view.encloses(context_button.get_global_rect()),"context action inside viewport "+key+str(size))
 root.size=Vector2i(1280,720);await frames(8)
 var down:=InputEventScreenTouch.new();down.index=51;down.pressed=true;down.position=game.stick.global_position+game.stick.size/2+Vector2(50,0);Input.parse_input_event(down)
 var second:=InputEventScreenTouch.new();second.index=52;second.pressed=true;second.position=game.run_button.get_global_rect().get_center();Input.parse_input_event(second);await frames(8)
 check(game.stick.finger==51 and game.rules.players.human.running,"native move and run multitouch")
 for finger in [51,52]:
  var up:=InputEventScreenTouch.new();up.index=finger;up.pressed=false;up.position=Vector2(0,0);Input.parse_input_event(up)
 game.rules.phase="live"
 game.pause_menu();var at: float=game.rules.elapsed;await frames(12);check(game.rules.elapsed>at,"menu overlay keeps the match timer running (2.0.34)")
 game.resume_match()
 check(not game.rules.has_method("task") and not game.rules.has_method("resolve_vote") and not game.rules.has_method("meeting"),"survival authority has no mission/vote handlers")
 var p: Dictionary=game.rules.players.human
 p.position=Vector2(70,80);p.outside=100;p.stamina=50;p.running=false;p.intent=Vector2.ZERO;game.rules.elapsed=520;game.rules.tick(.1)
 check(game.rules.circle_speed_factor==1 and is_inf(game.rules.circle_penalty_after) and p.stamina>50,"unconfirmed outside penalty not applied")
 game.cleanup_match();game.room={};game.build("lobby");await frames();var before: Dictionary=game.storage.data.duplicate(true)
 game.enter_practice();await frames(12)
 check(game.screen=="practice" and is_instance_valid(game.practice) and game.practice.session!=null,"existing spell sandbox available without RPG")
 game.practice.show_spells();await frames();check(game.modal!=null,"all registered spell list opens")
 game.practice.select("clone");game.practice.cast();await frames(12);check(not game.practice.clones.is_empty(),"real clone execution preserved")
 check(game.practice.session.rules.command("student",{"op":"meeting"}).has("error") and game.practice.session.rules.command("student",{"op":"task_open","mission":0}).has("error"),"sandbox rejects meeting and task commands")
 game.practice.request_leave();await create_timer(.4).timeout
 check(game.screen=="lobby" and game.storage.data==before,"sandbox returns without ownership/progress change")
 check(FileAccess.get_file_as_string("user://legacy-original.json")=='{"level":17,"items":["keep"]}',"cleanup never resets old save bytes")
 game.queue_free();await frames()
 # Timed auto-assignment, choice privacy and both 6/8 compositions.
 for count in [6,8]:
  var r:=Rules.new(count)
  for i in range(count):r.add(str(i),"참가자",C.catalog("daoist")[0].id,C.catalog("yokai")[0].id)
  for p2 in r.players.values():p2.ready=true
  r.start();check(r.players.values().filter(func(p2: Dictionary)->bool:return p2.role=="yokai").size()==2,"two yokai at %d players"%count)
  check(r.selection_view("0").all(func(p2: Dictionary)->bool:return r.players[p2.id].role==r.players["0"].role),"only own-team selections published")
  var saw_ready:=false
  for i in range(320):
   if r.phase=="ready":saw_ready=true
   if r.phase=="loading":break
   r.tick(.1)
  check(saw_ready,"confirmations pass through the 3 second ready countdown")
  check(r.phase=="loading" and r.players.values().all(func(p2: Dictionary)->bool:return p2.confirmed and C.find(p2.character).team==p2.role),"25 seconds auto assign valid characters")
 print("2D CLEANUP: ",checks," checks / ",failures," failures");quit(1 if failures else 0)
