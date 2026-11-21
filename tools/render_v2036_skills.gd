extends SceneTree
## 2.0.36 캐릭터별 스킬 발동 실제 인게임 캡처.
## 10인 × 대표/보조/궁극기 30장을 4개 맵에 나눠 찍어, 맵이 바뀌어도 같은 스킬 연출이
## 적용되는 것을 한 번에 보여 준다. 결과: /workspace/downloads/v2036_skill_<id>_<slot>.png
## 사용: godot --headless --rendering-driver opengl3 --path . --script res://tools/render_v2036_skills.gd
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node
var map_id:="seowon"
var L: Script
func _initialize() -> void:
 run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(name: String) -> void:
 for i in range(3):await process_frame
 var image:=root.get_texture().get_image()
 if image==null or image.is_empty():
  print("CAPTURE EMPTY ",name);return
 image.save_png(OUT+name)
 print("RENDER SAVED ",OUT+name," ",image.get_size())
func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if i%90==0:print("WAIT ",target," screen=",game.screen," changing=",game.changing," phase=",game.rules.phase if game.rules!=null else "?"," frame=",i)
  if game.screen==target and not game.changing:return
func start(id: String) -> void:
 map_id=id
 game.cleanup_match()
 game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("2.0.36 스킬 렌더",8,true,"",2,id)
 for i in range(240):
  await process_frame
  if game.screen=="room" and not game.changing:break
 game.rules.players.human.ready=true
 print("ROOM READY ",game.screen)
 game.start_match();await frames(6)
 print("AFTER START ",game.screen," ",game.rules.phase)
 game.rules.confirm_character("human")
 for i in range(300):
  if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
  if game.rules.phase=="loading":break
  await process_frame
 await wait_screen("match")
 print("MATCH REACHED ",game.screen," ",game.rules.phase)
 for i in range(80):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 L=game.L
 game.ui.visible=false
func prepare(id: String,role: String) -> Dictionary:
 var human: Dictionary=game.rules.players.human
 human.role=role;human.character=id
 human.position=L.SPAWN;human.ground=L.SPAWN;human.origin=L.SPAWN
 human.captured=false;human.eliminated=false;human.form="";human.intent=Vector2.ZERO
 human.cd={};human.ult=game.rules.ULT_MAX;human.buff={};human.immune=0.0;human.stun=0.0
 human.speed_until=0.0;human.slow_until=0.0;human.lives=3
 human.skin=String(game.storage.equipped("skin"))
 game.rules.effects.clear();game.rules.traps.clear();game.rules.marks.clear();game.rules.pings.clear()
 game.rules.mischief_zones.clear();game.rules.dark_until=0.0;game.rules.map_dark_until=0.0
 game.rules.elapsed=30.0
 # 대상이 필요한 스킬을 위한 도우미(같은 편 도사 1명, 요괴 1명).
 var daoist: Dictionary={};var yokai: Dictionary={}
 for p in game.rules.players.values():
  if p.id=="human":continue
  if String(p.role)=="daoist" and daoist.is_empty():daoist=p
  if String(p.role)=="yokai" and yokai.is_empty():yokai=p
 if not daoist.is_empty():
  daoist.position=L.SPAWN+Vector2(150,40);daoist.ground=daoist.position;daoist.captured=false;daoist.eliminated=false
  daoist.form="";daoist.buff={};daoist.character="daoist:honggildong"
 if not yokai.is_empty():
  yokai.position=L.SPAWN+Vector2(-220,-120);yokai.ground=yokai.position;yokai.eliminated=false;yokai.captured=false
 # 나·도우미 2명만 남기고 나머지는 화면 밖으로 치워 이름표가 이펙트를 가리지 않게 한다.
 for p in game.rules.players.values():
  if p.id=="human" or p==daoist or p==yokai:continue
  p.position=Vector2(-700,-700);p.ground=p.position
 game.update_avatars()
 for key in game.avatars:
  var node: Node=game.avatars[key]
  var plate: Node=node.get_node_or_null("Name")
  if plate!=null:plate.visible=(String(key)=="human" or String(key)==String(daoist.get("id","")))
 return human
func cast_shot(id: String,role: String,slot: String,label: String) -> void:
 var human:=prepare(id,role)
 var aim:=Vector2.RIGHT
 # 스킬별 준비
 match slot:
  "sub":
   if String(C.ability(id,"sub").get("skill","")) in ["underworldgate"]:
    game.rules.skill(human,aim,"sub")
    await frames(2)
   if String(C.ability(id,"sub").get("skill",""))=="trap":
    human.position=L.SPAWN
  "ult":
   if String(C.ability(id,"ult").get("skill",""))=="underworldgate":
    game.rules.skill(human,aim,"sub")
    await frames(1)
 # 둔갑은 근처 사물로 이동
 var skill:=String(C.ability(id,slot).get("skill",""))
 if skill=="transform":
  var near: Dictionary=L.OBJECTS[0]
  human.position=(near.p as Vector2)+Vector2(0,26);human.ground=human.position
  game.rules.elapsed=30.0;human.cd={};human.ult=game.rules.ULT_MAX
  game.update_avatars()
 # 귀환의 길: 봉인된 동료가 있어야 발동한다.
 if skill=="returnpath":
  var mate: Dictionary={}
  for p in game.rules.players.values():
   if p.id!="human" and String(p.role)=="daoist":mate=p;break
  if not mate.is_empty():
   mate.position=human.position+Vector2(120,60);mate.ground=mate.position
   mate.captured=true;mate.deadline=game.rules.elapsed+9.0;mate.sealed_by="helper"
 var ok: bool=game.rules.skill(human,aim,slot)
 if not ok:
  print("CAST FAILED ",id," ",slot," ",skill)
 # 상태형 스킬은 변신/보호막이 완성된 뒤, 즉발형은 이펙트가 피어난 순간을 잡는다.
 var late: Array=["transform","mimic","painting","lifelamp","deathflower","windstep","foxscent",
  "foxdream","soundhunt","shoeprints","glowpowder","footprintmap","astrolabe","ghostgate","moonlessnight",
  "blackvision","douse","returnpath","faketreasure","trap","soulmark","clone"]
 var seconds: float=.75 if skill=="clone" else (.42 if late.has(skill) else .18)
 var steps:=maxi(1,int(seconds/.045))
 for i in range(steps):
  game.rules.tick(.045)
 game.set_process(false)
 game.update_avatars();game.update_hud()
 hide_names()
 var wide: Array=["eightleap","mountaingrowl","goblinfest","mischief","moonlessnight","astrolabe","footprintmap","shoeprints","returnpath"]
 var z: float=1.75 if wide.has(skill) else 2.45
 game.camera.position=human.position+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(z,z)
 await frames(3)
 game.camera.position=human.position+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(z,z)
 await frames(2)
 await capture("v2036_skill_%s_%s.png"%[id.split(":")[1],slot])
 game.set_process(true)
 print("SHOT ",id," ",slot," ",skill," map=",map_id)
 if id=="yokai:eodubsimi" and slot=="sub":await blackvision_demo()
## 아바타 갱신이 이름표를 다시 켜므로 캡처 직전에 한 번 더 숨긴다.
func hide_names() -> void:
 for key in game.avatars:
  var node: Node=game.avatars[key]
  var plate: Node=node.get_node_or_null("Name")
  if plate!=null:plate.visible=(String(key)=="human")
func blackvision_demo() -> void:
 # 피해자(도사) 화면에서 실제로 시야가 좁아지고 미니맵 팀원이 사라지는 장면.
 var human: Dictionary=game.rules.players.human
 human.role="daoist";human.character="daoist:honggildong";human.blind_until=game.rules.elapsed+6.0
 human.captured=false;human.eliminated=false;human.skin="default"
 game.set_process(true);game.ui.visible=true
 game.update_avatars();game.show_map()
 await frames(8)
 game.set_process(false)
 await frames(3)
 await capture("v2036_blackvision_map.png")
 game.ui.visible=false;game.set_process(true);game.close_map()
 await frames(2)
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game)
 await frames(10)
 game.storage.equip("skin","default")
 var plan: Array=[
  ["seowon",["daoist:woochi","daoist:gangnim","yokai:eodubsimi"]],
  ["gangnam",["daoist:jangyeongsil","yokai:gumiho","yokai:yagwangwi"]],
  ["haeundae",["daoist:honggildong","yokai:jangsanbeom"]],
  ["dongseongno",["daoist:barigongju","yokai:dokkaebi"]]]
 for entry in plan:
  await start(String(entry[0]))
  for character in entry[1]:
   var id: String=String(character)
   var role: String=String(C.find(id).get("team","daoist"))
   for slot in ["main","sub","ult"]:
    await cast_shot(id,role,slot,String(C.ability(id,slot).get("name","")))
 print("V2036 SKILL RENDER DONE")
 quit(0)
