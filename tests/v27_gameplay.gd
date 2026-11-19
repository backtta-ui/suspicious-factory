extends SceneTree
## 2.0.27 검증: 10인 로스터·3능력(대표/보조/궁극기)·진영 잠금·준비 카운트다운·
## 봉인 자리 부활·둔갑 표시·전체 지도 닫기·걷는 고양이·강아지·보행 애니메이션.
const App=preload("res://scenes/survival.tscn")
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const FX=preload("res://scripts/survival/fx.gd")
const Actor=preload("res://scripts/woo/actor.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V27 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
## 화면(viewport) 좌표를 실제 입력 창 좌표로 바꿔 보낸다. 20:9 처럼 창과
## 뷰포트 비율이 다를 때도 버튼을 정확히 누르기 위해서다.
func tap(position: Vector2,finger: int=71) -> void:
 var at: Vector2=root.get_screen_transform()*position
 var event:=InputEventScreenTouch.new();event.index=finger;event.pressed=true;event.position=at;Input.parse_input_event(event)
 await frames(2)
 event=InputEventScreenTouch.new();event.index=finger;event.pressed=false;event.position=at;Input.parse_input_event(event)
 await create_timer(.4).timeout
func named(node: Node,value: String) -> Button:
 for child in node.find_children("*","Button",true,false):
  if child.name==value:return child
 return null
func live_room(seed_value: int=3) -> RefCounted:
 var r:=Rules.new(seed_value)
 r.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):r.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in r.players.values():p.ready=true
 r.start()
 for p in r.players.values():
  if C.find(p.character).is_empty():p.character=C.catalog(p.role)[0].id
 r.phase="live";r.elapsed=1.0;r.build_walkers()
 return r
func run() -> void:
 # ---------------------------------------------------------------- 1) 로스터
 var roster: Array=C.roster()
 check(roster.size()==10,"roster holds ten characters")
 check(C.catalog("daoist").size()==5 and C.catalog("yokai").size()==5,"five daoists and five yokai")
 var names: Array=[]
 for entry in roster:names.append(String(entry.name))
 for wanted in ["전우치","홍길동","장영실","바리공주","강림도령","구미호","장산범","도깨비","어둑시니","야광귀"]:
  check(names.has(wanted),"roster carries "+wanted)
 var slots_ok:=true
 var skill_ids: Array=[]
 for entry in roster:
  var slots: Array=[]
  for ability in entry.abilities:
   slots.append(String(ability.slot));skill_ids.append(String(ability.skill))
   if not C.SKILLS.has(String(ability.skill)):slots_ok=false
  if slots!=["main","sub","ult"]:slots_ok=false
  if String(entry.sprite)=="" or String(entry.portrait)=="":slots_ok=false
 check(slots_ok,"every character has main/sub/ult with real skill data and art")
 var distinct: Array=[]
 for id in skill_ids:
  if not distinct.has(id):distinct.append(id)
 check(distinct.size()==30,"thirty distinct abilities across the ten characters")
 check(String(C.ability("daoist:woochi","ult").skill)=="painting","woochi ultimate is 화중은신")
 check(String(C.ability("yokai:yagwangwi","ult").name)=="발자국지도","yagwangwi ultimate is 발자국지도")
 check(C.find("daoist:honggildong").sprite.ends_with("gildong-full.png") and C.find("yokai:eodubsimi").portrait.ends_with("eoduksini-portrait.png"),"new characters use their own v27 art")

 # ---------------------------------------------------------------- 2) 30능력 실행
 var r:=live_room()
 var caster: Dictionary=r.players.human
 var executed:=0
 var failed: Array=[]
 for entry in roster:
  var helper: Dictionary=r.players["bot-1"]
  helper.position=L.OBJECTS[0].p+Vector2(30,0);helper.ground=helper.position;helper.captured=false;helper.eliminated=false
  caster.character=String(entry.id);caster.role=String(entry.team)
  caster.position=L.OBJECTS[0].p+Vector2(20,0);caster.ground=caster.position
  caster.form="";caster.captured=false;caster.eliminated=false;caster.cd={};caster.ult=r.ULT_MAX
  caster.mark=Vector2(1700,1420)
  for slot in ["main","sub","ult"]:
   caster.cd={};caster.ult=r.ULT_MAX
   var path_aim:=Vector2.RIGHT
   var ok: bool=r.skill(caster,path_aim,slot)
   if ok:executed+=1
   else:failed.append(String(entry.id)+":"+slot)
 check(executed==30,"all thirty abilities execute (%d/30, failed %s)"%[executed,str(failed)])
 check(r.effects.size()>=20,"ability executions leave visible effects")
 check(r.traps.size()>=2,"trap abilities place real traps")
 check(r.marks.size()>=1,"soul mark leaves a real mark")
 check(r.walkers.size()==4 and r.walkers.any(func(w: Dictionary)->bool:return String(w.kind)=="dog"),"moving cats and dogs exist on the map")
 var start_pos: Vector2=r.walkers[0].p
 for i in range(20):r.tick(.05)
 check(r.walkers[0].p.distance_to(start_pos)>1.0,"animals really walk around the map")
 check(float(r.walkers[0].phase)>0.0,"animals advance their walk cycle")

 # ---------------------------------------------------------------- 3) 궁극기 기운
 var probe:=live_room(5)
 var p2: Dictionary=probe.players.human
 p2.character="daoist:woochi";p2.role="daoist";p2.ult=0.0;p2.cd={}
 check(not probe.skill(p2,Vector2.RIGHT,"ult"),"ultimate blocked below full charge")
 p2.ult=40.0
 for i in range(30):probe.tick(.1)
 check(float(p2.ult)>40.0,"ultimate charge fills over time")
 p2.ult=probe.ULT_MAX
 check(probe.skill(p2,Vector2.RIGHT,"ult") and p2.ult==0.0,"full charge fires the ultimate and empties it")

 # ---------------------------------------------------------------- 4) 진영 잠금 + 준비 카운트다운
 var room:=Rules.new(11)
 room.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):room.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in room.players.values():p.ready=true
 room.preferred_role="daoist"
 check(room.start() and room.players.human.role=="daoist","preferred daoist side assigned")
 room.select_character("human",C.catalog("daoist")[1].id)
 check(room.confirm_character("human"),"human confirms a daoist")
 check(room.phase=="selection","confirmation alone does not start the match")
 for i in range(400):
  if room.phase=="ready":break
  room.tick(.1)
 check(room.phase=="ready" and room.ready_left>=1.5 and room.ready_left<=3.0,"all confirmed enter a short ready countdown")
 var seen_loading:=false
 for i in range(40):
  room.tick(.1)
  if room.phase=="loading":seen_loading=true;break
 check(seen_loading,"ready countdown hands over to map loading")
 var refused:=Rules.new(12)
 refused.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):refused.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in refused.players.values():p.ready=true
 refused.preferred_role="daoist";refused.start()
 check(not refused.select_character("human",C.catalog("yokai")[0].id),"assigned role cannot pick the other team")

 # ---------------------------------------------------------------- 5) 봉인된 자리에서 부활
 var revive:=live_room(21)
 var dao: Dictionary=revive.players.values().filter(func(q: Dictionary)->bool:return q.role=="daoist")[0]
 var hunter: Dictionary=revive.players.values().filter(func(q: Dictionary)->bool:return q.role=="yokai")[0]
 var grave:=Vector2(2000,1300)
 dao.position=grave;dao.ground=grave;dao.form="";dao.immune=0;dao.lives=2
 hunter.position=grave-Vector2(0,20);hunter.cd={};revive.contact_seal()
 check(dao.captured,"contact seal lands on an undisguised daoist")
 dao.deadline=revive.elapsed-0.1
 revive.tick(.05)
 check(not dao.captured and dao.lives==1,"unrescued daoist loses one life")
 check(dao.position.distance_to(grave)<40.0,"revived at the sealed spot, not the spawn point")
 check(dao.immune>revive.elapsed,"revive still grants brief immunity")

 # ---------------------------------------------------------------- 6) 실기기 화면: 20:9 UI
 root.size=Vector2i(2340,1080)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 game.build("lobby");await frames(6)
 check(named(game.ui,"characters")!=null and named(game.ui,"codex")!=null,"lobby keeps one 도감 entry point")
 game.lobby_hotspots["characters"].emit_signal("pressed");await create_timer(.6).timeout
 check(game.screen=="characters","캐릭터 자리 opens the unified 도감")
 await tap(codex_back_for(game))
 await create_timer(.6).timeout
 game.lobby_hotspots["codex"].emit_signal("pressed");await create_timer(.6).timeout
 check(game.screen=="characters","도감 자리 opens the same unified screen")
 var codex: Node=find_codex(game)
 check(codex!=null and codex.cards.size()==10,"도감 shows all ten characters")
 check(named(game.ui,"CodexSkin_default")!=null and named(game.ui,"CodexSkin_moon")!=null,"도감 equips robes in place")
 await tap(named(game.ui,"CodexSkin_default").get_global_rect().get_center())
 check(String(game.storage.equipped("skin"))=="default","tapping a robe skin equips it")
 await tap(named(game.ui,"CodexTab_yokai").get_global_rect().get_center())
 await frames(4)
 print("V27 debug tab filter=",codex.filter," cards=",codex.cards.size()," tab_rect=",named(game.ui,"CodexTab_yokai").get_global_rect())
 check(codex.cards.size()==5,"yokai tab filters to five")
 for size in [Vector2i(960,540),Vector2i(2340,1080),Vector2i(2400,1080)]:
  root.size=size;await frames(8)
  var view:=game.get_viewport().get_visible_rect()
  var inside:=true
  for id in codex.cards:
   if not view.encloses(codex.cards[id].get_global_rect()):inside=false
  check(inside,"ten cards stay inside the viewport at "+str(size))
 await tap(codex.back_button.get_global_rect().get_center())
 await create_timer(.6).timeout
 check(game.screen=="lobby","도감 back returns to the lobby")

 # ---------------------------------------------------------------- 7) 빠른 매치: 진영 잠금 화면
 game.open_quick();await create_timer(.9).timeout
 game.finish_matching();await create_timer(.9).timeout
 check(game.screen=="selection","quick match goes straight to character select")
 var view_node: Node=game.selection_view
 check(view_node.role_locked,"quick match locks the other team tab")
 var own_team: String=String(game.rules.players.human.get("role","daoist"))
 var foe_tab:=named(game.ui,"SelectionTab_"+("yokai" if own_team=="daoist" else "daoist"))
 check(foe_tab!=null and foe_tab.disabled,"opposing tab is a disabled control")
 var before_pick: String=game.selection_id
 game.selection_view._pick(C.catalog("yokai" if own_team=="daoist" else "daoist")[0].id)
 await frames(2)
 check(String(game.selection_id)==before_pick,"opposing character cannot be picked in a quick match")
 game.close_popup()
 print("V27 debug confirm: screen=",game.screen," modal=",game.modal," disabled=",named(game.ui,"SelectionConfirm").disabled," phase=",game.rules.phase," rect=",named(game.ui,"SelectionConfirm").get_global_rect()," changing=",game.changing," selsize=",game.get_viewport().get_visible_rect())
 await tap(named(game.ui,"SelectionConfirm").get_global_rect().get_center())
 await frames(4)
 print("V27 debug after: screen=",game.screen," confirmed=",game.rules.players.human.confirmed," phase=",game.rules.phase)
 check(game.screen=="selection" and bool(game.rules.players.human.confirmed),"confirm stays on the selection screen")
 check(game.rules.phase in ["selection","ready","loading"],"confirm does not jump before the countdown")

 # ---------------------------------------------------------------- 8) 매치 HUD · 둔갑 표시 · 지도
 game.build("lobby");await frames(2)
 game.create_room("V27 검증",8,true);game.rules.players.human.ready=true
 game.start_match();await frames(4)
 game.rules.players.human.role="daoist"
 game.rules.players.human.character="daoist:woochi"
 for member in game.rules.players.values():member.confirmed=true
 for i in range(60):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
 game.rules.ready_map()
 for i in range(600):
  if game.screen=="match" and not game.changing:break
  await process_frame
  if game.rules.phase=="countdown":game.rules.tick(.1)
 print("V27 debug match: screen=",game.screen," phase=",game.rules.phase," changing=",game.changing," modal=",game.modal)
 check(game.screen=="match","real match reached for HUD checks")
 for i in range(400):
  if game.rules.phase=="live":break
  if game.rules.phase=="countdown":game.rules.tick(.05)
  await process_frame
 check(game.rules.phase=="live","match goes live after the start countdown")
 await frames(10)
 check(game.skill_buttons.has("main") and game.skill_buttons.has("sub") and game.skill_buttons.has("ult"),"HUD shows main, sub and ultimate buttons")
 var view:=game.get_viewport().get_visible_rect()
 check(view.encloses(game.skill_buttons["ult"].get_global_rect()) and view.encloses(game.skill_buttons["sub"].get_global_rect()),"all three skill buttons stay on screen at 20:9")
 game.rules.players.human.position=L.OBJECTS[0].p+Vector2(24,0)
 game.rules.players.human.form=""
 await frames(6)
 var context: Dictionary=game.interaction_context()
 check(String(context.get("label",""))=="둔갑 가능","disguise context reads 둔갑 가능 next to a prop")
 check(game.form_pulse!=null and game.form_pulse.visible,"action button glows while a disguise target is in reach")
 check(game.world.form_target().is_empty()==false,"world knows the disguise target for the gold ring")
 game.rules.players.human.position=L.SPAWN
 game.show_map();await frames(6)
 check(game.modal!=null and game.map_overlay!=null,"full map overlay opens as a modal")
 var close_button:=named(game.ui,"MapClose")
 check(close_button!=null,"map has a big close button")
 if close_button!=null:
  var box:=close_button.get_global_rect()
  check(view.encloses(box) and box.size.x>60,"close button is inside the screen and tappable")
  await tap(box.get_center())
  await frames(4)
  check(game.modal==null and game.map_overlay==null,"close button closes the map")
 game.show_map();await frames(4)
 await tap(Vector2(10,10))
 check(game.modal==null,"tapping outside the map closes it")
 game.show_map();await frames(4)
 game.back();await frames(4)
 check(game.modal==null,"back/Esc closes the map")
 for size in [Vector2i(2340,1080),Vector2i(1280,720),Vector2i(960,540)]:
  root.size=size;await frames(6)
  game.show_map();await frames(4)
  var map_close:=named(game.ui,"MapClose")
  var view2:=game.get_viewport().get_visible_rect()
  check(map_close!=null and view2.encloses(map_close.get_global_rect()),"map close stays inside at "+str(size))
  game.close_map();await frames(2)
 root.size=Vector2i(2340,1080);await frames(4)
 # 동물 둔갑: 걷기 원화 복사
 var walker: Dictionary=game.rules.walkers[0]
 game.rules.players.human.form=String(walker.kind)
 game.rules.players.human.position=walksafe(walker)+Vector2(0,0)
 await frames(10)
 var avatar: Node=game.avatars.get("human")
 check(avatar!=null and String(avatar.appearance_form).begins_with("seowon:"),"avatar renders the animal disguise")
 if avatar!=null:
  check(avatar.sprite.texture!=null and String(avatar.sprite.texture.resource_path).contains("animal_"),"animal disguise copies the walking animal art")
 # 보행 애니메이션: 두 걷기 프레임이 실제로 교체되는지
 var actor:=Actor.new();actor.ingame_art=true;actor.art_id="woochi";root.add_child(actor)
 await frames(2)
 var seen:= {}
 for i in range(40):
  actor.gait_weight=1.0;actor.gait_phase+=PI*0.5;actor.jump_height=0
  await process_frame
  var path: String=String(actor.last_texture.resource_path) if actor.last_texture!=null else ""
  seen[path]=true
 check(seen.size()>=2,"walk cycle swaps between walk1 and walk2 art")
 check(actor.ingame_sprite!=null and actor.ingame_sprite.legs!=null and actor.ingame_sprite.legs.visible,"legs are drawn as a separate articulated layer")
 actor.queue_free()
 game.queue_free();await frames(2)
 print("V27 GAMEPLAY: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
func find_codex(game: Node) -> Node:
 for node in game.ui.get_children():
  if node.get_script()!=null and String(node.get_script().resource_path).ends_with("codex.gd"):return node
 return null
func codex_back_for(game: Node) -> Vector2:
 for node in game.ui.get_children():
  if node.get_script()!=null and String(node.get_script().resource_path).ends_with("codex.gd"):
   return node.back_button.get_global_rect().get_center()
 return Vector2(60,30)
func walksafe(walker: Dictionary) -> Vector2:
 return (walker.p as Vector2)
