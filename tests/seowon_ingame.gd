extends SceneTree
## 2단계-A 검증: 아치 목교·출입 한옥·5종 둔갑·상호작용 HUD·사운드.
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func live_room(count: int=8,seed_value: int=17) -> RefCounted:
 var r:=Rules.new(seed_value)
 for i in range(count):r.add("human" if i==0 else "bot-%d"%i,"참가자%d"%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[i%4].id)
 for p in r.players.values():p.ready=true
 r.start()
 for i in range(300):
  if r.phase!="selection":break
  r.tick(.1)
 r.ready_map()
 for i in range(31):r.tick(.1)
 return r
func _initialize() -> void:run.call_deferred()
func run() -> void:
 # 1) 지도: 아치 목교·연못 우회·출입 한옥·담장·대나무
 var bridge_mid: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,.5)
 check(L.on_bridge(bridge_mid) and L.elevation(bridge_mid)>20,"arched bridge carries elevation")
 check(L.can_stand(bridge_mid) and not L.can_stand(L.POND.get_center(),9,true),"bridge crossable, pond not")
 var walked: Vector2=L.move(L.BRIDGE_A,L.BRIDGE_B)
 check(walked.distance_to(L.BRIDGE_B)<2,"walk the bridge end to end")
 check(not L.can_stand(bridge_mid+(L.BRIDGE_B-L.BRIDGE_A).normalized().orthogonal()*60),"bridge rails/pond block stepping off the side")
 check(L.can_stand(Vector2(435,573)) and L.can_stand(Vector2(435,500)) and L.can_stand(Vector2(435,267)),"hanok front door, room and back door")
 check(not L.can_stand(Vector2(247,400),9,true) and not L.can_stand(Vector2(647,700),9,true),"hanok and courtyard walls block")
 check(L.can_stand(Vector2(435,600)) and L.can_stand(Vector2(420,790)),"courtyard and alleys walkable")
 check(L.WALLS.size()>=8 and L.BAMBOO.size()>=5,"tiled walls and bamboo groves divide the map")
 var five: Array=[]
 for object in L.OBJECTS:
  if not five.has(object.kind):five.append(object.kind)
 check(five.size()==5 and L.OBJECTS.size()>=15,"five disguisable prop kinds in dense clusters")
 check(L.FORMS.has("cat") and L.FORMS.cat.moving and not L.FORMS.jar.moving,"cat walks, fixed props hide")
 for kind in ["jar","crate","lantern","cat","stele"]:
  check(not L.form(kind).is_empty(),"form data "+kind)
 check(L.surface(L.BRIDGE_A.lerp(L.BRIDGE_B,.5))=="wood","bridge uses wood footstep surface")
 # 2) 규칙: 공용 형상 추출(둔갑)·해제·이동 판정·문 열기
 var r:=live_room()
 var human: Dictionary=r.players.human
 var partner: Dictionary=r.players["bot-1"]
 human.position=Vector2(560,780);human.facing=2
 check(r.command("human","interact"),"disguise near jar cluster")
 check(human.form=="jar" and human.buff.transform>r.elapsed,"jar disguise active")
 var seen: Array=r.visible("bot-1")
 check(not seen.any(func(a: Dictionary)->bool:return a.id=="human"),"disguised daoist hidden from others")
 r.command("human","move",{"vector":Vector2(1,0)})
 for i in range(8):r.tick(.1)
 check(human.form=="","fixed disguise breaks when moving")
 human.form="";human.buff.erase("transform");human.wobble=0
 human.position=Vector2(700,880);human.cd.erase("transform");r.command("human","move",{"vector":Vector2.ZERO})
 check(r.command("human","interact"),"cat disguise near cat")
 check(human.form=="cat","cat form")
 var before: Vector2=human.position
 r.command("human","move",{"vector":Vector2(1,0)})
 for i in range(5):r.tick(.1)
 check(human.position.distance_to(before)>4 and human.form=="cat","cat disguise can move while hidden")
 check(r.command("human","interact") and human.form=="","press again cancels disguise")
 check(not r.command("human","interact") and human.cd.get("transform",0)>r.elapsed,"disguise cooldown after reuse")
 human.position=Vector2(435,600);human.form="";human.cd.erase("transform")
 check(r.command("human","interact") and r.doors.front>r.elapsed,"front door opens by interaction")
 check(r.events.any(func(e: Dictionary)->bool:return e.kind=="door"),"door event for sound")
 # 둔갑한 도사는 아주 가까이에서만 봉인된다
 var evil: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 human.position=Vector2(560,780);human.form="";human.captured=false;human.immune=0;human.cd.erase("transform")
 r.command("human","interact")
 evil.position=human.position+Vector2(52,0);evil.facing=0;evil.cd.erase("seal")
 check(r.command(evil.id,"seal") and human.captured==false,"disguised target not sealed from afar")
 evil.cd.erase("seal");evil.position=human.position+Vector2(18,0);evil.facing=4
 check(r.command(evil.id,"seal") and human.captured,"close seal reveals disguised target")
 # 3) 앱: 카메라·HUD·문 열기·둔갑 표시·전체 지도
 root.size=Vector2i(1280,720);var game:=App.instantiate();root.add_child(game);await frames(8)
 game.create_room("QA 술래잡기",8,true);await create_timer(.4).timeout
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 var index:=0
 for p in game.rules.players.values():
  if p.id=="human":p.role="daoist";p.character="daoist:woochi";continue
  index+=1
  if p.role=="":p.role="yokai" if index<3 else "daoist"
  p.character=("yokai:gumiho" if p.role=="yokai" else "daoist:yeonhwa")
 game.selection_id="daoist:woochi";game.selection_team="daoist";game.build("selection");game.rules.phase="loading"
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 game.rules.phase="live";game.rules.elapsed=2.0
 check(game.screen=="match" and is_instance_valid(game.camera),"match world with camera")
 check(is_instance_valid(game.camera) and game.camera.zoom.x>=1.35,"camera zoom keeps 2.5D ratio")
 for name in ["Menu","Settings","Spectator"]:
  check(game.ui.find_child(name,true,false)!=null,"HUD control "+name)
 check(game.ui.find_children("*","Button",true,false).size()>=6,"HUD buttons present")
 check(game.seal_label.text=="봉인 0 / 5" and game.survivor_label.text.contains("생존 도사"),"seal counter and survivors line")
 check(game.timer_label.text.contains("월하의 서원 · "),"title timer line")
 for button in [game.run_button,game.jump_button,game.skill_button,game.action_button]:
  check(button.get_node_or_null("Caption")!=null and button.get_node_or_null("Badge")!=null,"caption and icon on "+button.name)
 var me: Dictionary=game.rules.players.human
 me.position=Vector2(435,600);game.update_avatars();game.update_hud();await frames(3)
 check(game.action_button.get_node("Caption").text=="문 열기","door context label")
 me.position=Vector2(560,780);game.rules.players.human.cd.erase("transform")
 game.update_avatars();game.update_hud();await frames(3)
 check(game.action_button.get_node("Caption").text=="둔갑","prop context label")
 var disguised: bool=game.rules.command("human","interact")
 game.update_hud();await frames(3)
 check(game.form_label.visible and game.form_label.text.contains("둔갑"),"disguise status bar shown")
 game.show_map();await frames(2);check(game.modal!=null,"minimap opens full map")
 game.close_popup();await frames(1)
 game.show_settings();await frames(2)
 check(game.modal!=null and game.modal.find_children("*","CheckBox",true,false).size()>=3,"settings with mute and vibration")
 game.close_popup();game.pause_menu();await frames(2)
 check(game.modal!=null and "10분" in str(game.modal.find_children("*","Label",true,false).map(func(l: Label)->String:return l.text)),"pause rules explain the hunt")
 game.resume_match()
 # 4) 사운드: 인게임 BGM·효과음이 실제로 로드되고 문맥이 바뀐다
 for path in ["res://assets/audio/jump.wav","res://assets/audio/door.wav","res://assets/audio/seal.wav","res://assets/audio/rescue.wav","res://assets/audio/transform.wav","res://assets/audio/seowon_ingame.wav"]:
  check(ResourceLoader.exists(path),"audio "+path)
 check(game.sound.CLIPS.has("door") and game.sound.CLIPS.has("transform") and game.sound.CLIPS.has("seal"),"in-game sfx registered")
 check(game.sound.context=="match" and game.sound.music.stream==game.sound.ingame,"tense Korean BGM in match")
 game.cleanup_match();game.queue_free();await frames(6)
 print("SEOWON INGAME: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
