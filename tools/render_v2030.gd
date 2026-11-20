extends SceneTree
## 2.0.30 검수 렌더: 같은 팀 미니맵·스킬 표기, 어둑시니 은신(본인/도사 화면),
## 시야 좁히기 화면, 개선된 등불끄기, 도술 이펙트, 구미호 인간둔갑 위장.
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2030.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
const C=preload("res://scripts/survival/characters.gd")
const Art=preload("res://scripts/survival/seowon_art.gd")
const OUT="/workspace/downloads/"
var game: Node

func _initialize() -> void:
 run.call_deferred()

func frames(n: int=4) -> void:
 for i in range(n):await process_frame

func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 var path:=OUT+name
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())

## 미니맵 위젯만 잘라 따로 남긴다.
func capture_region(name: String,rect: Rect2i) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 var crop:=image.get_region(rect)
 crop.save_png(OUT+name)
 print("RENDER SAVED ",OUT+name," ",crop.get_size())

func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return
 print("WAIT TIMEOUT ",target," screen ",game.screen)

func clear_states() -> void:
 if game.rules==null:return
 for p in game.rules.players.values():
  p.buff={};p.immune=0.0;p.stun=0.0;p.blind_until=0.0;p.slow_until=0.0;p.speed_until=0.0
  p.captured=false;p.form="";p.copy="";p.trail=[]
 game.rules.reveal_until=0.0;game.rules.map_dark_until=0.0;game.rules.dark_until=0.0
 game.rules.trail_all_until=0.0;game.rules.lantern_until.clear()
 game.rules.marks.clear();game.rules.pings=[];game.rules.traps=[];game.rules.effects.clear()
 game.rules.prop_flips.clear()

func start(role: String) -> void:
 game.cleanup_match()
 game.build("lobby");await frames(4)
 game.preferred_role=role
 game.start_practice_match()
 await wait_screen("match")
 game.rules.phase="live";game.rules.elapsed=120.0
 game.paused=true
 await frames(6)

func daoist_ids() -> Array:
 var out: Array=[]
 for p in game.rules.players.values():
  if p.role=="daoist" and not p.eliminated:out.append(p.id)
 return out

func yokai_ids() -> Array:
 var out: Array=[]
 for p in game.rules.players.values():
  if p.role=="yokai":out.append(p.id)
 return out

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(16)
 game.build("lobby");await frames(6)

 # ---------------------------------------------------------------- 1) 미니맵: 같은 팀만(도사=파랑 / 요괴=빨강)
 # (a) 도사 시점: 아군 6명이 모두 보이고, 적은 한 명도 찍히지 않는다.
 await start("daoist")
 clear_states()
 var rules=game.rules
 var human: Dictionary=rules.players.human
 human.character="daoist:woochi"
 var ids:=daoist_ids()
 var base: Vector2=L.MEDALLION+Vector2(0,180)
 human.position=L.safe(base);human.ground=human.position;human.facing=2
 var ring_i:=0
 for id in ids:
  var q: Dictionary=rules.players[id]
  if String(id)==String(human.id):continue
  q.position=L.safe(base+Vector2.from_angle(ring_i*1.15)*(190+ring_i*22));q.ground=q.position
  q.captured=false;q.eliminated=false;q.buff={};q.character="daoist:honggildong" if ring_i%2==0 else "daoist:barigongju"
  ring_i+=1
 if ids.size()>=4:
  rules.players[ids[1]].captured=true
  rules.players[ids[2]].eliminated=true
  rules.players[ids[3]].position=L.safe(base+Vector2(-210,120));rules.players[ids[3]].ground=rules.players[ids[3]].position
  rules.players[ids[3]].rescue=String(ids[1])
 # 요괴는 화면 밖 외곽에 세워 두되, 미니맵에는 보이지 않는다.
 var outside_i:=0
 for id in yokai_ids():
  var q2: Dictionary=rules.players[id]
  q2.character="yokai:gumiho";q2.eliminated=false;q2.captured=false;q2.buff={}
  q2.position=L.safe(Vector2(400+outside_i*90,2260));q2.ground=q2.position
  outside_i+=1
 rules.traps.clear();rules.marks.clear();rules.pings=[]
 game.camera.position=base-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud()
 await frames(10)
 game.show_map();await frames(10)
 print("DAOIST MAP contacts=",rules.map_contacts("human").size()," allies=",rules.allies("human").size())
 await capture("v2030_minimap_daoist.png")
 game.close_map();await frames(6)

 # (b) 요괴 시점: 같은 팀 요괴(빨강)만 기본 표시 + 탐지 도술(발자국/야광가루) 동안만 적이 드러난다.
 await start("yokai")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="yokai:yagwangwi";human.cd={};human.ult=rules.ULT_MAX
 ids=daoist_ids()
 var mates:=yokai_ids()
 human.position=L.safe(base);human.ground=human.position;human.facing=2
 var mate_i:=0
 for id in mates:
  if String(id)==String(human.id):continue
  var q3: Dictionary=rules.players[id]
  q3.character="yokai:yagwangwi" if mate_i%2==0 else "yokai:dokkaebi"
  q3.position=L.safe(base+Vector2(-160-mate_i*80,160+mate_i*40));q3.ground=q3.position
  q3.eliminated=mate_i==1
  mate_i+=1
 var d_i:=0
 for id in ids:
  var q4: Dictionary=rules.players[id]
  q4.captured=false;q4.eliminated=false;q4.buff={}
  if d_i==0:
   q4.position=L.safe(base+Vector2(210,-40));q4.ground=q4.position
  else:
   q4.position=L.safe(Vector2(520+d_i*70,2200));q4.ground=q4.position
  d_i+=1
 rules.traps.clear();rules.marks.clear();rules.pings=[]
 var cast_ok: bool=rules.skill(human,Vector2.RIGHT,"main")   # 신발흔적
 var cast2: bool=rules.skill(human,Vector2.RIGHT,"sub")     # 야광가루
 print("YOKAI DETECT shoes=",cast_ok," powder=",cast2," contacts=",rules.map_contacts("human").size())
 game.camera.position=base-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud()
 await frames(10)
 game.show_map();await frames(10)
 await capture("v2030_minimap_yokai.png")
 game.close_map();await frames(6)

 # ---------------------------------------------------------------- 2) 어둑시니 은신: 본인 vs 도사
 # (a) 요괴 본인 화면: 무월야로 은신한 자기 모습(반투명 + 상태 뱃지).
 await start("yokai")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="yokai:eodubsimi";human.cd={};human.ult=rules.ULT_MAX
 var spot: Vector2=L.MEDALLION+Vector2(-40,150)
 human.position=L.safe(spot);human.ground=human.position;human.facing=2
 var daoist_list:=daoist_ids()
 var d0:=0
 for id in daoist_list:
  var q: Dictionary=rules.players[id]
  q.position=L.safe(spot+Vector2(220+d0*40,60+d0*30));q.ground=q.position;d0+=1
 game.build("match");await frames(4)
 human=rules.players.human
 rules.skill(human,Vector2.RIGHT,"ult")   # 무월야: 8초 암흑 + 은신
 game.update_avatars();game.update_hud()
 for i in range(40):await process_frame
 print("STEALTH SELF hidden=",rules.hidden(human)," actor=",game.avatars.has("human")," modulate=",game.avatars["human"].modulate if game.avatars.has("human") else "-")
 await capture("v2030_eoduk_stealth_self.png")
 # (b) 도사 화면: 요괴 봇이 무월야를 쓰면 도사 눈에는 완전히 사라진다.
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:honggildong"
 var stage2: Vector2=L.MEDALLION+Vector2(-40,150)
 human.position=L.safe(stage2);human.ground=human.position;human.facing=0
 var yok:=yokai_ids()
 if not yok.is_empty():
  var eo: Dictionary=rules.players[yok[0]]
  eo.character="yokai:eodubsimi";eo.cd={};eo.ult=rules.ULT_MAX
  eo.position=L.safe(stage2+Vector2(150,0));eo.ground=eo.position;eo.facing=4
  for id in yok:
   if String(id)==String(eo.id):continue
   var q: Dictionary=rules.players[id]
   q.position=L.safe(Vector2(3060,2360));q.ground=q.position
  rules.skill(eo,Vector2.LEFT,"ult")
  game.update_avatars();game.update_hud()
  for i in range(30):await process_frame
  var seen:=false
  for a in rules.visible("human"):
   if String(a.id)==String(eo.id):seen=true
  print("STEALTH ENEMY yokai_visible=",seen," avatar_keys=",game.avatars.keys()," overlay=",game.vision.visible)
  await capture("v2030_eoduk_stealth_enemy.png")

 # ---------------------------------------------------------------- 3) 시야 좁히기(검은시야)
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:honggildong"
 var stage3: Vector2=L.MEDALLION+Vector2(0,170)
 human.position=L.safe(stage3);human.ground=human.position;human.facing=0
 yok=yokai_ids()
 if not yok.is_empty():
  var far3:=0
  for id in daoist_ids():
   if String(id)==String(human.id):continue
   var q3: Dictionary=rules.players[id]
   q3.position=L.safe(Vector2(3060,2400)+Vector2(far3*18,far3*10));q3.ground=q3.position;far3+=1
  var eo2: Dictionary=rules.players[yok[0]]
  eo2.character="yokai:eodubsimi";eo2.cd={};eo2.ult=rules.ULT_MAX
  eo2.position=L.safe(stage3+Vector2(130,20));eo2.ground=eo2.position;eo2.facing=4
  rules.skill(eo2,Vector2.LEFT,"sub")   # 검은시야 → 가장 가까운 도사(사람)
  game.update_avatars();game.update_hud()
  for i in range(30):await process_frame
  print("BLIND narrow=",rules.vision_for("human").get("narrow",0.0)," blind_until=",human.blind_until," overlay=",game.vision.visible," shown=",game.vision.shown_narrow)
  await capture("v2030_eoduk_blind.png")

 # ---------------------------------------------------------------- 4) 등불끄기(전/후 비교)
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:honggildong"
 var lantern_area: Vector2=Art.LANTERNS[0] if not Art.LANTERNS.is_empty() else Vector2(1518,911)
 human.position=lantern_area+Vector2(6,100);human.ground=human.position;human.facing=6
 var hide:=0
 for id in daoist_ids():
  if String(id)==String(human.id):continue
  var q4: Dictionary=rules.players[id]
  q4.position=L.safe(Vector2(3060,2400)+Vector2(hide*18,hide*10));q4.ground=q4.position;hide+=1
 var yok_list:=yokai_ids()
 for id in yok_list:
  var q5: Dictionary=rules.players[id]
  if String(id)==String(yok_list[0]):
   q5.character="yokai:eodubsimi";q5.cd={};q5.ult=rules.ULT_MAX
   q5.position=lantern_area+Vector2(0,26);q5.ground=q5.position;q5.facing=2
  else:
   q5.position=L.safe(Vector2(3080,2400));q5.ground=q5.position
 game.update_avatars();game.update_hud()
 for i in range(20):await process_frame
 await capture("v2030_lantern_before.png")
 if not yok_list.is_empty():
  var eo3: Dictionary=rules.players[yok_list[0]]
  var cast: bool=rules.skill(eo3,Vector2.RIGHT,"main")
  print("DOUSE cast=",cast," dark=",rules.dark_until-rules.elapsed," center=",rules.dark_center)
  game.update_avatars();game.update_hud()
  for i in range(30):await process_frame
  var lit:=0
  var dark_count:=0
  for entry in game.world.lantern_holders:
   if float(entry.get("level",1.0))<.5:dark_count+=1
   else:lit+=1
  print("LANTERNS out=",dark_count," lit=",lit," overlay=",game.vision.visible," shown_dark=",game.vision.shown_dark)
  await capture("v2030_lantern_after.png")

 # ---------------------------------------------------------------- 5) 구미호 인간둔갑(도사로 완전 위장)
 # 도사(사람) 화면에서 요괴 봇 구미호가 '나(전우치)'로 둔갑한 장면. 완전히 구별되지 않아야 한다.
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:woochi";human.cd={};human.ult=rules.ULT_MAX
 var stage: Vector2=L.MEDALLION+Vector2(-60,180)
 human.position=L.safe(stage);human.ground=human.position;human.facing=0
 var dup_id:=""
 var tail:=0
 for id in daoist_ids():
  if String(id)==String(human.id):continue
  var q: Dictionary=rules.players[id]
  q.position=L.safe(stage+Vector2(-520-tail*70,-300-tail*40));q.ground=q.position;tail+=1
 var impostor_id:=""
 for id in yokai_ids():
  if impostor_id=="":impostor_id=String(id);continue
  var q2: Dictionary=rules.players[id]
  q2.position=L.safe(Vector2(3080,2400));q2.ground=q2.position
 if impostor_id!="":
  var imp: Dictionary=rules.players[impostor_id]
  imp.character="yokai:gumiho";imp.cd={};imp.ult=rules.ULT_MAX
  imp.position=L.safe(stage+Vector2(120,0));imp.ground=imp.position;imp.facing=4
  var cast: bool=rules.skill(imp,Vector2.LEFT,"main")
  print("MIMIC cast=",cast," copy=",imp.copy," remaining=",imp.buff.get("mimic",0.0)-rules.elapsed)
  game.update_avatars();game.update_hud()
  # 정지 상태에서는 elapsed가 멈춰 이펙트가 얼어붙으므로, 시간만 조금 넘겨 이펙트를 지운다.
  rules.elapsed+=1.2
  rules.effects.clear()
  game.update_avatars();game.update_hud()
  await frames(4)
  var real_actor: Node=game.avatars.get("human")
  var fake_actor: Node=game.avatars.get(impostor_id)
  print("MIMIC real art=",real_actor.art_id if real_actor!=null else "-"," name=",real_actor.get_node("Name").text if real_actor!=null else "-")
  print("MIMIC fake art=",fake_actor.art_id if fake_actor!=null else "-"," name=",fake_actor.get_node("Name").text if fake_actor!=null else "-"," mod=",fake_actor.modulate if fake_actor!=null else "-")
  var seen_role:=""
  for a in rules.visible("human"):
   if String(a.id)==impostor_id:seen_role=String(a.role)
  print("MIMIC daoist view role=",seen_role," inputs=",[game.avatars.keys()])
  await capture("v2030_mimic_daoist_view.png")
  # 둔갑 해제·시간 경과 뒤 원래 모습 복귀
  imp.buff.erase("mimic");imp.copy=""
  game.update_avatars();game.update_hud()
  await frames(8)
  print("MIMIC released art=",game.avatars[impostor_id].art_id if game.avatars.has(impostor_id) else "-","name=",game.avatars[impostor_id].get_node("Name").text if game.avatars.has(impostor_id) else "-")
  await capture("v2030_mimic_released.png")

 # ---------------------------------------------------------------- 5b) 나무 뒤 캐릭터 + 걸어서 출입하는 문
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:honggildong";human.cd={};human.ult=rules.ULT_MAX
 var tree: Vector2=Art.TREES[8] if Art.TREES.size()>8 else Vector2(1300,2360)
 var door_area: Vector2=L.buildings()[4].doors.front
 # 나무 발치보다 위(뒤)에 서서 수관이 옅어지는지 확인한다. 문도 화면 안에 둔다.
 human.position=L.safe(Vector2(tree.x+40,tree.y-70));human.ground=human.position;human.facing=2
 var mate2:=""
 for id in daoist_ids():
  if String(id)==String(human.id):continue
  mate2=String(id);break
 if mate2!="":
  var q: Dictionary=rules.players[mate2]
  q.character="daoist:barigongju"
  q.position=L.safe(Vector2(tree.x-30,tree.y-40));q.ground=q.position;q.facing=2;q.buff={}
 for id in daoist_ids():
  if String(id) in [String(human.id),mate2]:continue
  var far2: Dictionary=rules.players[id]
  far2.position=L.safe(Vector2(3060,2400));far2.ground=far2.position
 for id in yokai_ids():
  var q2: Dictionary=rules.players[id]
  q2.position=L.safe(Vector2(300,2400));q2.ground=q2.position
 game.camera.position=human.position-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud()
 for i in range(40):await process_frame
 var faded:=0
 for o in game.world.occluders:
  if float(o.alpha)<0.9:faded+=1
 print("TREE FADE occluders=",game.world.occluders.size()," faded=",faded," human=",human.position," tree=",tree," door=",door_area)
 await capture("v2030_tree_fade_and_door.png")

 # ---------------------------------------------------------------- 5c) 막힌 곳을 보여 주는 바닥 경계(돌 턱·연못 물가)
 var ledge: Rect2=L.LOW[4]
 human.position=L.safe(Vector2(ledge.get_center().x,ledge.end.y+90));human.ground=human.position;human.facing=6
 game.camera.position=human.position-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud()
 await frames(12)
 await capture("v2030_walk_ledge.png")
 human.position=L.safe(Vector2(L.POND.position.x-80,L.POND.end.y+120));human.ground=human.position;human.facing=0
 game.camera.position=human.position-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud()
 await frames(12)
 await capture("v2030_walk_pond.png")

 # ---------------------------------------------------------------- 6) 캐릭터별 이펙트 쇼케이스(10인 각각 한 장)
 await start("daoist")
 clear_states()
 rules=game.rules
 var stage_center: Vector2=L.MEDALLION+Vector2(0,150)
 var showcase: Array=[
  {"id":"daoist:woochi","slot":"main"},{"id":"daoist:honggildong","slot":"sub"},
  {"id":"daoist:jangyeongsil","slot":"ult"},{"id":"daoist:barigongju","slot":"main"},
  {"id":"daoist:gangnim","slot":"main"},{"id":"yokai:gumiho","slot":"ult"},
  {"id":"yokai:jangsanbeom","slot":"ult"},{"id":"yokai:dokkaebi","slot":"ult"},
  {"id":"yokai:eodubsimi","slot":"main"},{"id":"yokai:yagwangwi","slot":"main"}]
 for entry in showcase:
  var cid:=String(entry.id)
  var slot:=String(entry.slot)
  var human2: Dictionary=rules.players.human
  human2.role=String(C.find(cid).get("team","daoist"))
  human2.character=cid;human2.cd={};human2.ult=rules.ULT_MAX
  human2.form="";human2.buff={};human2.captured=false;human2.eliminated=false;human2.stun=0.0
  human2.position=L.safe(stage_center);human2.ground=human2.position;human2.facing=2
  rules.effects.clear();rules.traps.clear()
  rules.dark_until=0.0;rules.map_dark_until=0.0;rules.reveal_until=0.0;rules.trail_all_until=0.0
  # 다른 참가자는 화면 밖으로: 이펙트만 보이게 한다.
  var park_i:=0
  for q in rules.players.values():
   if q.id=="human":continue
   q.role="daoist" if q.role=="daoist" else "yokai"
   q.position=L.safe(Vector2(3060,2400)+Vector2(park_i*22,park_i*12));q.ground=q.position;q.buff={};q.captured=false;park_i+=1
  game.build("match")
  await frames(4)
  var target: Dictionary=rules.players.human
  if slot=="transform":
   rules.skill(target,Vector2.RIGHT,"sub")
  else:
   rules.skill(target,Vector2.RIGHT,slot)
  game.update_avatars();game.update_hud()
  await frames(3)
  var label:=String(C.find(cid).name)+"_"+String(C.ability(cid,slot).get("name",""))
  print("SHOWCASE ",cid," ",slot," effects=",rules.effects.size())
  await capture("v2030_fx_"+cid.replace(":","_")+".png")

 # ---------------------------------------------------------------- 7) 앱 피드백 확인(발동 배너·뱃지)
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 human.character="daoist:woochi";human.cd={};human.ult=rules.ULT_MAX
 game.paused=false
 rules.skill(human,Vector2.RIGHT,"ult")
 game.update_avatars();game.update_hud()
 await frames(3)
 print("BANNER '",game.hud_view.banner,"' cast=",game.hud_view.cast_name," buffs=",game.hud_view.buffs.size())
 await capture("v2030_cast_banner.png")
 print("V2030 RENDER DONE")
 quit()
