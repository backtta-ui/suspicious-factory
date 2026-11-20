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
  if r.phase=="ready":break
  r.tick(.1)
 check(r.phase=="ready" and r.ready_left>2.0 and r.ready_left<=3.0,"all confirmed wait for the short ready countdown")
 for i in range(35):r.tick(.1)
 check(r.phase=="loading","ready countdown hands over to map loading")
 r.ready_map();check(not r.command("human","move",{"vector":Vector2.RIGHT}),"countdown blocks input")
 for i in range(30):r.tick(.1)
 r.tick(.001);check(r.phase=="live" and r.elapsed<.01,"three seconds before ten-minute clock")
 var dao: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[0]
 var other: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[1]
 var evil: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 # 1) 시작 직후 요괴는 6초 유예를 받는다(같은 자리 봉인 방지).
 check(float(evil.cd.get("seal",0.0))-r.elapsed>5.9,"yokai starts with the six second seal grace")
 dao.position=L.SPAWN;dao.immune=0;evil.position=L.SPAWN+Vector2(24,0);evil.facing=0
 r.tick(.1)
 check(not dao.captured,"grace blocks the instant contact seal")
 # 2) 접촉 봉인: 버튼 없이 몸이 닿으면 즉시 봉인되고 요괴는 1.5초만 쉰다.
 evil.cd={};evil.stagger=0
 r.tick(.1)
 check(dao.captured,"touching an untransformed daoist seals without a button")
 check(is_equal_approx(float(evil.cd.get("seal",0.0))-r.elapsed,1.5),"seal recovery is one and a half seconds")
 check(is_equal_approx(dao.deadline-r.elapsed,10),"ten second deadline")
 check(not r.command(dao.id,"jump"),"captured cannot jump")
 # 3) 후딜 중에는 옆에 있는 다음 도사를 연속으로 잡지 못한다.
 other.position=dao.position+Vector2(0,20);other.immune=0
 r.tick(.1)
 check(not other.captured,"recovery blocks chain sealing")
 # 4) 둔갑한 도사는 접촉으로 잡히지 않고 '확인' 타격으로만 잡힌다.
 evil.cd={};evil.stagger=0
 other.form="jar";other.buff.transform=r.elapsed+9
 other.position=evil.position+Vector2(18,0);evil.facing=0
 r.tick(.1)
 check(other.form=="jar" and not other.captured,"contact cannot unmask a disguised daoist")
 check(r.command(evil.id,"seal") and other.captured and other.form=="","confirm strike unmasks and seals")
 check(is_equal_approx(float(evil.cd.get("seal",0.0))-r.elapsed,1.5),"confirm success also recovers in one and a half seconds")
 # 5) 빈 사물·허공을 확인하면 2초 헛방 후딜.
 evil.cd={};evil.stagger=0;evil.facing=6
 check(r.command(evil.id,"seal") and is_equal_approx(float(evil.cd.get("seal",0.0))-r.elapsed,2.0),"empty check costs two seconds")
 check(evil.stats.misses>=1,"empty check counts as a miss")
 # 6) 호신부는 접촉 봉인을 한 번 막고, 짧은 면역과 넉백만 준다.
 var shielded: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.captured)[0]
 shielded.form="";shielded.immune=0;shielded.buff.shield=r.elapsed+8
 evil.cd={};evil.stagger=0;shielded.position=evil.position+Vector2(20,0)
 r.tick(.1)
 check(not shielded.captured and not shielded.buff.has("shield"),"shield absorbs one contact seal")
 check(shielded.immune>r.elapsed,"shield grants short immunity")
 check(shielded.position.distance_to(evil.position)>40,"shield knocks the daoist back")
 evil.cd={};evil.stagger=0;shielded.position=evil.position+Vector2(20,0)
 r.tick(.1)
 check(not shielded.captured,"immunity blocks recapture")
 # 7) 구출: 동료가 2.5초 붙어 있으면 풀리고 3초 면역이 붙는다.
 var rescuer: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.captured and not p.eliminated and p.id!=dao.id)[0]
 rescuer.position=dao.position+Vector2(0,26);check(r.command(rescuer.id,"rescue",{"target":dao.id}),"ally rescue starts")
 for i in range(20):r.tick(.1)
 r.command(rescuer.id,"cancel_rescue");check(rescuer.progress==0 and dao.captured,"release cancels rescue")
 r.command(rescuer.id,"rescue",{"target":dao.id})
 var rescue_ticks:=0
 while dao.captured and rescue_ticks<80:
  r.tick(.1);rescue_ticks+=1
 check(not dao.captured,"rescue frees the sealed daoist")
 check(rescue_ticks==25,"rescue needs exactly two and a half seconds")
 check(is_equal_approx(dao.immune-r.elapsed,3.0),"rescue grants three seconds of immunity")
 check(dao.lives==3,"a rescued daoist keeps every life")
 # 7-1) 구조에 실패하면 10초 뒤 목숨 1개를 잃고 시작 자리에서 다시 일어난다.
 var martyr: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.captured and not p.eliminated and p.id!=dao.id and int(p.lives)==3)[0]
 martyr.form="";martyr.immune=0;evil.cd={};evil.stagger=0;martyr.position=evil.position+Vector2(20,0)
 r.tick(.1)
 check(martyr.captured and martyr.lives==3,"a seal alone does not cost a life")
 check(is_equal_approx(martyr.deadline-r.elapsed,10),"ten second deadline")
 dao.position=Vector2(800,2000)
 var wait:=0
 while martyr.captured and wait<140:r.tick(.1);wait+=1
 check(wait<=101,"deadline resolves after ten seconds")
 check(not martyr.captured and not martyr.eliminated and martyr.lives==2,"unrescued seal costs one life and revives")
 check(martyr.immune>r.elapsed,"revival immunity")
 check(martyr.position.distance_to(L.SPAWN)<400,"revived at the starting area")
 # 7-2) 목숨을 모두 잃으면 그때 최종 탈락한다.
 for round in range(2):
  martyr.immune=0;evil.cd={};evil.stagger=0;martyr.position=evil.position+Vector2(20,0)
  r.tick(.1)
  if not martyr.captured:check(false,"martyr was sealed again")
  var left:=0
  while martyr.captured and left<140:r.tick(.1);left+=1
 check(martyr.eliminated and martyr.lives==0,"third lost life eliminates for good")
 dao.position=L.SPAWN;dao.immune=r.elapsed+3
 evil.cd={};evil.stagger=0;dao.position=evil.position+Vector2(20,0)
 r.tick(.1)
 check(not dao.captured,"immunity blocks the instant re-seal")
 # 8) 둔갑한 채로도 걸을 수 있고, 속도만 사물답게 느려진다.
 var walker: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.captured and not p.eliminated)[0]
 walker.immune=99;walker.form="jar";walker.buff.transform=r.elapsed+9;walker.stamina=100;walker.exhausted=false
 walker.position=L.SPAWN;walker.intent=Vector2.ZERO
 r.command(walker.id,"run",{"held":false})
 r.command(walker.id,"move",{"vector":Vector2(1,0)})
 var before_walk: Vector2=walker.position
 for i in range(10):r.tick(.1)
 check(walker.form=="jar","disguise survives walking")
 var walked: float=walker.position.distance_to(before_walk)
 # 2.0.34: 둔갑 사물은 고정형 구분 없이 자유롭게 이동한다(감속 없음) → 걸은 거리가 그대로다.
 check(walked>125.0,"disguised walking keeps full movement (no fixed-prop penalty in 2.0.34)")
 check(r.command(walker.id,"interact") and walker.form=="","pressing again leaves the disguise")
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
   separated=separated and y.position.distance_to(d.position)>=L.SPAWN_SEPARATION
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
 r.elapsed=510;check(r.circle().radius>=600 and r.circle().radius<L.MEDALLION_RADIUS*5,"final zone still playable size")
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
