extends SceneTree
## 2.0.37 검증 캡처(20:9 1600×720): 4맵 이펙트 가시성 + 선택창 캐릭터별 등장 모션.
## 결과는 /workspace/downloads/v2037_*.png
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node
var L: Script
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(name: String) -> void:
 for i in range(3):await process_frame
 var image:=root.get_texture().get_image()
 if image==null or image.is_empty():print("EMPTY ",name);return
 image.save_png(OUT+name);print("RENDER SAVED ",OUT+name," ",image.get_size())
func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return
func start(id: String) -> void:
 game.cleanup_match();game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("2.0.37 화면",8,true,"",2,id)
 for i in range(240):
  await process_frame
  if game.screen=="room" and not game.changing:break
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(300):
  if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
  if game.rules.phase=="loading":break
  await process_frame
 await wait_screen("match")
 for i in range(80):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 L=game.L
 game.rules.elapsed=120.0
 # 검증 컷에서는 내가 봉인당하지 않게 하고, 봇들이 몰려오지 않게 한다.
 game.rules.players.human.immune=game.rules.elapsed+300.0
 game.banner_left=0.0
func place(at: Vector2,zoom: float=1.45) -> void:
 var human: Dictionary=game.rules.players.human
 human.position=at;human.ground=at;human.captured=false;human.eliminated=false
 game.update_avatars()
 game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(zoom,zoom)
 await frames(4)
 game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(zoom,zoom)
 await frames(2)
## 내 캐릭터를 바꾸고 그 자리에서 도술을 실제로 쓴다.
func be(character: String) -> Dictionary:
 var human: Dictionary=game.rules.players.human
 human.character=character;human.cd={};human.ult=game.rules.ULT_MAX
 human.form="";human.buff.erase("transform")
 game.update_avatars()
 return human
## 화면에 필요한 인물만 남기고 나머지 봇은 멀리 치워 깨끗한 검증 컷을 만든다.
func clear_area(keep: Array=[]) -> void:
 for p in game.rules.players.values():
  if String(p.id)=="human" or keep.has(String(p.id)):continue
  var far: Vector2=L.SPAWN+Vector2(60,60)
  p.position=far;p.ground=far;p.intent=Vector2.ZERO
  p.captured=false;p.eliminated=true
  var actor: Node=game.avatars.get(String(p.id))
  if actor!=null:actor.visible=false
 game.update_avatars()
## 사람만 남기고 모든 봇을 제거 상태로 치운다(검증 컷 전용).
func clear_area_bots_only() -> void:
 for p in game.rules.players.values():
  if String(p.id)=="human":continue
  var far: Vector2=L.SPAWN+Vector2(60,60)
  p.position=far;p.ground=far;p.intent=Vector2.ZERO;p.captured=false;p.eliminated=true
 game.update_avatars()
func yokai_bot(character: String) -> Dictionary:
 for p in game.rules.players.values():
  if String(p.role)!="yokai":continue
  p.character=character;p.cd={};p.ult=game.rules.ULT_MAX
  game.update_avatars()
  return p
 return {}
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game);await frames(10)
 # ---------------------------------------------------------------- 선택창: 캐릭터별 등장 모션
 for id in ["daoist:woochi","daoist:honggildong","daoist:gangnim","yokai:eodubsimi"]:
  game.build("lobby");await frames(3)
  game.create_room("2.0.37 선택",8,true,"",2,"seowon");await create_timer(.3).timeout
  game.rules.players.human.ready=true
  game.rules.players.human.role="daoist"
  game.start_match();await create_timer(.35).timeout
  game.selection_id=id;game.selection_team=String(C.find(id).get("team","daoist"))
  game.build("selection");await frames(4)
  # 앱이 저장값으로 선택을 다시 계산하므로, 캡처는 화면에 보여 줄 캐릭터를 직접 고정한다.
  if is_instance_valid(game.selection_view):
   game.selection_view.selection_id=id
   game.selection_view.build()
  await frames(4)
  await create_timer(.55).timeout;await frames(4)
  await capture("v2037_selection_%s.png"%id.split(":")[1])
  game.cleanup_match();await frames(3)
 # ---------------------------------------------------------------- 강남역: 장영실 압력기관 + 도깨비 가짜보물·장난
 await start("gangnam")
 var human=be("daoist:jangyeongsil")
 var stop: Vector2=Vector2(1500,1500)
 await place(stop,1.40)
 human.position=stop;human.ground=stop
 game.rules.skill(human,Vector2.DOWN,"sub")          # 압력기관
 human.position=stop+Vector2(-70,0);human.ground=human.position
 var dok:=yokai_bot("yokai:dokkaebi")
 if not dok.is_empty():
  dok.position=stop+Vector2(150,0);dok.ground=dok.position;dok.cd={}
  game.rules.skill(dok,Vector2.LEFT,"sub")            # 가짜보물
  dok.cd={}
  game.rules.skill(dok,Vector2.LEFT,"main")           # 도깨비장난 장판
 clear_area_bots_only()
 await place(stop,1.55)
 clear_area([] if dok.is_empty() else [String(dok.id)])
 game.update_avatars();await frames(3)
 await capture("v2037_gangnam_trap.png")
 # ---------------------------------------------------------------- 홍길동: 바람발 달리기 잔상
 await start("haeundae")
 var runner=be("daoist:honggildong")
 var beach: Vector2=Vector2(1600,1750)
 runner.position=beach;runner.ground=beach
 game.rules.skill(runner,Vector2.RIGHT,"sub")          # 바람발
 runner.intent=Vector2.RIGHT;runner.running=true
 game.set_process(false)
 game.update_avatars()
 clear_area([])
 await place(beach,1.65)
 for i in range(10):
  runner.intent=Vector2.RIGHT
  game.rules.tick(.05)
  game.update_avatars()
  await process_frame
 await capture("v2037_hong_dash.png")
 game.set_process(true)
 print("DASH speed=",runner.get("speed_factor",1.0)," until=",runner.get("speed_until",0.0)," elapsed=",game.rules.elapsed)
 # ---------------------------------------------------------------- 해운대: 모래 위 스킬·함정 가시성
 var jang=be("daoist:jangyeongsil")
 jang.position=beach+Vector2(-40,-10);jang.ground=jang.position;jang.cd={}
 game.rules.skill(jang,Vector2.DOWN,"sub")             # 압력기관
 var gob:=yokai_bot("yokai:dokkaebi")
 if not gob.is_empty():
  gob.position=beach+Vector2(-260,60);gob.ground=gob.position;gob.cd={}
  game.rules.skill(gob,Vector2.RIGHT,"sub")           # 가짜보물(함정 옆)
  gob.cd={}
  game.rules.skill(gob,Vector2.RIGHT,"main")          # 도깨비장난
 var bari=be("daoist:barigongju")
 bari.position=beach+Vector2(150,60);bari.ground=bari.position;bari.cd={};bari.ult=game.rules.ULT_MAX
 game.rules.skill(bari,Vector2.RIGHT,"main")          # 생명등불 보호막
 var keep: Array=[] if gob.is_empty() else [String(gob.id)]
 clear_area(keep)
 await place(beach,1.55)
 game.update_avatars();await frames(3)
 await capture("v2037_haeundae_fx.png")
 # ---------------------------------------------------------------- 동성로: 어둑시니 등불끄기·무월야 공포
 await start("dongseongno")
 var alley: Vector2=Vector2(1700,1500)
 var eoduk=yokai_bot("yokai:eodubsimi")
 if not eoduk.is_empty():
  eoduk.position=alley;eoduk.ground=alley;eoduk.cd={};eoduk.ult=game.rules.ULT_MAX
  game.update_avatars()
  game.rules.skill(eoduk,Vector2.DOWN,"main")         # 등불끄기(밤안개)
  eoduk.cd={}
  await frames(2)
  game.rules.skill(eoduk,Vector2.DOWN,"ult")          # 무월야(맵 전체 암전)
 print("DARK until=",game.rules.dark_until," map=",game.rules.map_dark_until," elapsed=",game.rules.elapsed," center=",game.rules.dark_center)
 clear_area([])
 for p in game.rules.players.values():
  if String(p.id)=="human":
   var mine: Node=game.avatars.get(String(p.id))
   if mine!=null:mine.visible=true
 if not eoduk.is_empty():
  eoduk.eliminated=false;eoduk.captured=false
  eoduk.position=alley+Vector2(90,0);eoduk.ground=eoduk.position;eoduk.intent=Vector2.ZERO
  game.rules.skill(eoduk,Vector2.DOWN,"main")
 await place(alley+Vector2(0,40),1.25)
 # 암전·연막이 화면에 자리 잡을 시간을 준다(시야 연출이 부드럽게 따라온다).
 await create_timer(1.4).timeout
 game.update_avatars();await frames(3)
 await capture("v2037_eoduk_horror.png")
 print("V2037 RENDER DONE")
 quit(0)
