extends SceneTree
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
var matches: Array=[]
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func room(count: int=6,seed_value: int=5) -> RefCounted:
 var r:=Rules.new(seed_value)
 for i in range(count):r.add("human" if i==0 else "bot-%d"%i,"도사%d"%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[i%4].id)
 r.players.human.ready=true;return r
func run() -> void:
 var r:=room();check(r.start(),"start six-player room")
 check(r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==2,"two random yokai")
 check(not r.command("human","jump"),"loading blocks gameplay")
 check(r.phase=="selection" and r.selection_left==25,"role assignment precedes timed selection")
 var role: String=r.players.human.role
 check(not r.select_character("human",C.catalog("yokai" if role=="daoist" else "daoist")[0].id),"other-team choice rejected")
 check(r.select_character("human",C.catalog(role)[0].id) and r.confirm_character("human"),"own-team confirmation")
 check(not r.select_character("human",C.catalog(role)[1].id),"confirmed choice locks")
 check(r.selection_view("human").all(func(p: Dictionary)->bool:return r.players[p.id].role==role),"opponent selection private")
 for i in range(250):
  if r.phase=="loading":break
  r.tick(.1)
 r.ready_map();check(not r.command("human","move",{"vector":Vector2.RIGHT}),"countdown blocks input")
 for i in range(30):r.tick(.1)
 r.tick(.001);check(r.phase=="live" and r.elapsed<.01,"three seconds before ten-minute clock")
 var dao: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[0]
 var other: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[1]
 var evil: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 # 시작 직후 요괴는 6초 유예를 받는다(같은 자리 봉인 방지).
 check(float(evil.cd.get("seal",0.0))-r.elapsed>5.9,"yokai starts with the six second seal grace")
 dao.position=L.SPAWN;evil.position=L.SPAWN+Vector2(30,0);evil.facing=0
 check(not r.command(evil.id,"seal") and not dao.captured,"grace blocks the instant seal")
 evil.cd={}
 check(r.command(evil.id,"seal") and not dao.captured,"wrong-facing seal misses")
 check(is_equal_approx(evil.cd.seal-r.elapsed,6),"miss cooldown six")
 evil.cd={};evil.facing=4;check(r.command(evil.id,"seal") and dao.captured,"forward cone seals")
 check(is_equal_approx(dao.deadline-r.elapsed,45) and is_equal_approx(evil.cd.seal-r.elapsed,12),"45 deadline and 12 success cooldown")
 check(not r.command(dao.id,"jump"),"captured cannot jump")
 other.position=dao.position+Vector2(0,15);check(r.command(other.id,"rescue",{"target":dao.id}),"ally rescue starts")
 for i in range(20):r.tick(.1)
 r.command(other.id,"cancel_rescue");check(other.progress==0 and dao.captured,"release cancels rescue")
 r.command(other.id,"rescue",{"target":dao.id})
 for i in range(40):r.tick(.1)
 check(not dao.captured and dao.immune-r.elapsed>2.9,"four-second rescue and immunity")
 evil.cd={};check(r.command(evil.id,"seal") and not dao.captured,"immunity blocks recapture")
 check(not r.command(dao.id,"seal"),"daoist cannot seal")
 dao.position=L.SPAWN;dao.intent=Vector2.ZERO;r.command(dao.id,"move",{"vector":Vector2(1,1)});var before: Vector2=dao.position;r.tick(.1)
 print("diagonal distance ",dao.position.distance_to(before));check(absf(dao.position.distance_to(before)-13.5)<.02,"diagonal normalized")
 r.command(dao.id,"run",{"held":true});before=dao.position;r.tick(.1);check(dao.position.distance_to(before)>20.9 and dao.stamina<100,"running faster and drains stamina")
 dao.stamina=.1;r.tick(.1);check(dao.exhausted,"stamina exhaustion latch")
 dao.intent=Vector2.ZERO;r.command(dao.id,"run",{"held":false})
 for i in range(20):r.tick(.1)
 check(not dao.exhausted and dao.stamina>=25,"stamina recovery")
 # 6) 시작 배치: 도사는 중앙~서남, 요괴는 600px 이상 떨어진 외곽
 var spawn_room:=room()
 for p in spawn_room.players.values():p.ready=true
 check(spawn_room.start(),"spawn split room starts")
 var daoists: Array=spawn_room.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")
 var yokai: Array=spawn_room.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")
 var legal:=true;var separated:=true;var spread:=true
 for p in spawn_room.players.values():
  legal=legal and L.can_stand(p.position)
  if p.role=="daoist":legal=legal and p.position.distance_to(L.SPAWN)<520
  else:legal=legal and p.position.distance_to(L.SPAWN)>520
 for y in yokai:
  for d in daoists:
   separated=separated and y.position.distance_to(d.position)>=600
 for i in range(daoists.size()):
  for j in range(i+1,daoists.size()):
   spread=spread and (daoists[i].position as Vector2).distance_to(daoists[j].position)>=40
 check(legal,"every starter stands on legal ground inside the courtyard")
 check(separated,"yokai spawn at least 600px away from every daoist")
 check(spread,"daoists do not stack on the same tile")
 print("SPAWN daoists ",daoists.map(func(p: Dictionary)->String:return str(p.position))," yokai ",yokai.map(func(p: Dictionary)->String:return str(p.position)))
 var obstacle: Rect2=L.LOW[0];var a:=Vector2(obstacle.position.x+50,obstacle.position.y-35);var b:=a+Vector2(0,85)
 check(L.move(a,b).y<obstacle.end.y,"low obstacle blocks ground walk")
 check(L.move(a,b,true).distance_to(b)<1,"jump crosses low obstacle")
 var hall: Dictionary=L.buildings()[0]
 var hall_wall: Vector2=(hall.rect as Rect2).position+Vector2(8,60)
 check(not L.can_stand(hall_wall,9,true),"jump cannot cross building wall")
 check(not L.can_stand(L.POND.get_center(),9,true),"jump cannot enter pond")
 var doors_ok:=true
 for building in L.buildings():
  var front: Vector2=(building.doors as Dictionary).front
  var back: Vector2=(building.doors as Dictionary).back
  doors_ok=doors_ok and L.can_stand(front+Vector2(0,12)) and L.can_stand(front+Vector2(0,-40)) and L.can_stand((building.interior as Rect2).get_center()) and L.can_stand(back+Vector2(0,-12))
 check(doors_ok,"every hanok front door, room and back door passable")
 for time in [0,180,360,480]:r.elapsed=time;check(r.circle().stage==[0,180,360,480].find(time),"circle stage %d"%time)
 r.elapsed=510;check(is_equal_approx(r.circle().radius,360),"final zone still playable size")
 for p in r.players.values():p.intent=Vector2.ZERO;p.captured=false;p.eliminated=false;p.deadline=0
 r.elapsed=599.9;r.tick(.1);check(r.phase=="result" and r.winner=="daoist","surviving daoist wins ten minutes")
 var elapsed: float=r.elapsed;r.tick(.1);check(r.elapsed==elapsed and not r.command(evil.id,"seal"),"result freezes time and actions")
 r=room();r.start()
 for i in range(251):r.tick(.1)
 r.ready_map();r.phase="live"
 for p in r.players.values():
  if p.role=="daoist":p.eliminated=true
 r.tick(.1);check(r.winner=="yokai","all permanently eliminated yields yokai win")
 # A fresh setting path backs up old bytes without invoking any RPG loader.
 var f:=FileAccess.open("user://legacy-qa.txt",FileAccess.WRITE);f.store_string("retain-progress");f.close()
 var store:=preload("res://scripts/survival/storage.gd").new();check(FileAccess.get_file_as_string("user://legacy-qa.txt")=="retain-progress","legacy bytes preserved")
 check(FileAccess.file_exists("user://legacy-backup-v13/manifest.json"),"legacy backup manifest")
 root.size=Vector2i(1280,720);var game:=App.instantiate();root.add_child(game);await frames(8)
 check(game.screen=="title" and game.world==null,"new title with no RPG world")
 game.show_settings();await frames();check(game.screen=="title" and game.modal!=null,"settings separate from starting")
 game.close_popup();game.build("lobby");check(game.ui.find_children("*","WooMobileButton",true,false).size()>=4,"lobby actual controls")
 game.build("rooms");check(game.room.is_empty(),"empty real local room list")
 game.create_room("QA",6,true);await create_timer(.4).timeout
 check(game.screen=="room" and game.rules.players.size()==6,"real room with five bots")
 game.start_match();check(game.screen=="room" and game.modal!=null,"unready start explains failure")
 game.close_popup();game.rules.players.human.ready=true;game.start_match();game.rules.confirm_character("human")
 for i in range(650):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match" and is_instance_valid(game.world) and is_instance_valid(game.camera),"VS hands over to actual seowon")
 check(game.rules.phase=="countdown","countdown after map ready")
 game.pause_menu();var time: float=game.rules.elapsed;await frames(20);check(game.rules.elapsed==time,"pause freezes full offline world")
 game.resume_match();game.cleanup_match();game.queue_free();await frames()
 print("SURVIVAL V1.3: ",checks," checks / ",failures," failures");quit(1 if failures else 0)
