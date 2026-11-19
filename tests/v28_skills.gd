extends SceneTree
## 2.0.28 검증: 10인 전원 해금 · 도술 30종의 실제 판정/시야/렌더 · 서명 이펙트 ·
## 상황 버튼(문 열기/구출/둔갑/확인) · 동물 크기 축소 · 8방향 걷기 시트 로더.
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const FX=preload("res://scripts/survival/fx.gd")
const App=preload("res://scenes/survival.tscn")
const Storage=preload("res://scripts/survival/storage.gd")
const Market=preload("res://scripts/survival/market.gd")
const Actor=preload("res://scripts/woo/actor.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V28 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func base_position() -> Vector2:
 return L.SPAWN+Vector2(0,-40)
## 살아 있는 매치 하나를 만든다. 사람은 human, 나머지는 봇 자리다.
func live(seed_value: int=9) -> RefCounted:
 var r:=Rules.new(seed_value)
 r.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):r.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in r.players.values():p.ready=true
 r.start()
 for p in r.players.values():
  if C.find(p.character).is_empty():p.character=C.catalog(p.role)[0].id
 r.phase="live";r.elapsed=10.0;r.build_walkers()
 # 시험에 쓰지 않는 봇은 멀리 치워 두어 최근접 판정이 흔들리지 않게 한다.
 var index:=0
 for q in r.players.values():
  if q.id=="human":continue
  q.position=Vector2(3260,2460)+Vector2(index*10,index*6);q.ground=q.position
  q.captured=false;q.eliminated=false;q.form="";q.buff={};q.cd={};q.intent=Vector2.ZERO
  index+=1
 return r
## 시전자 한 명을 준비하고, 지정한 팀·캐릭터로 바꾼다.
func caster(r: RefCounted,character_id: String,at: Vector2=Vector2.INF) -> Dictionary:
 # 시험에 쓰지 않는 참가자는 멀리 치워 최근접 판정이 흔들리지 않게 한다.
 var index:=0
 for q in r.players.values():
  if q.id=="human":continue
  q.position=Vector2(3260,2460)+Vector2(index*10,index*6);q.ground=q.position
  q.captured=false;q.eliminated=false;q.form="";q.buff={};q.cd={};q.intent=Vector2.ZERO
  index+=1
 var p: Dictionary=r.players.human
 var spec:=C.find(character_id)
 p.character=character_id;p.role=String(spec.get("team","daoist"))
 p.position=at if at!=Vector2.INF else base_position();p.ground=p.position;p.origin=p.position
 p.captured=false;p.eliminated=false;p.form="";p.buff={};p.cd={};p.ult=r.ULT_MAX
 p.stun=0.0;p.slow_until=0.0;p.speed_until=0.0;p.blind_until=0.0;p.immune=0.0;p.mark=Vector2.INF
 p.trail=[]
 return p
func helper(r: RefCounted,id: String,role: String,character_id: String,at: Vector2) -> Dictionary:
 var q: Dictionary=r.players[id]
 q.role=role;q.character=character_id
 q.position=at;q.ground=at;q.captured=false;q.eliminated=false;q.form="";q.buff={};q.cd={}
 q.stun=0.0;q.slow_until=0.0;q.speed_until=0.0;q.blind_until=0.0;q.immune=0.0;q.trail=[]
 return q
func has_sig(r: RefCounted,skill_id: String) -> bool:
 for e in r.effects:
  if String(e.kind)=="fx_sig" and String(e.get("skill",""))==skill_id:return true
 return false
func run() -> void:
 # ---------------------------------------------------------------- 1) 10인 전원 해금
 var storage:=Storage.new()
 var all_owned:=true
 for entry in C.roster():
  if not storage.owns_character(String(entry.id)):all_owned=false
 check(all_owned,"a fresh save owns all ten characters")
 check(Market.CHARACTERS.size()==10,"the market lists the ten-character roster")
 var market_ok:=true
 for item in Market.CHARACTERS:
  if int(item.price)!=0 or not C.find(String(item.id)).get("team","") in ["daoist","yokai"]:market_ok=false
 check(market_ok,"every character is free while the trial build is open")
 var fresh_ok:=true
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   if not storage.owns_character(String(entry.id)):fresh_ok=false
 check(fresh_ok,"both teams' full rosters are selectable")

 # ---------------------------------------------------------------- 2) 서명 연출 표
 var sig_complete:=true
 for entry in C.roster():
  for ability in entry.abilities:
   if not FX.SIG.has(String(ability.skill)):sig_complete=false
 check(sig_complete,"every one of the thirty skills has its own signature effect")
 check(FX.SIG.size()==30,"signature table covers exactly thirty skills")

 # ---------------------------------------------------------------- 3) 30도술 실제 판정
 var r:=live()
 var practiced: Array=[]
 # --- 전우치: 분신술·둔갑술·화중은신
 var p:=caster(r,"daoist:woochi",L.OBJECTS[0].p+Vector2(22,0))
 var other:=helper(r,"bot-1","yokai","yokai:gumiho",L.OBJECTS[0].p+Vector2(140,0))
 check(r.skill(p,Vector2.RIGHT,"main") and r.effects.any(func(e: Dictionary)->bool:return e.kind=="clone" and String(e.get("owner",""))=="human"),"분신술 leaves a moving clone")
 var clone_position: Vector2=r.effects.filter(func(e: Dictionary)->bool:return e.kind=="clone")[0].position
 for i in range(10):r.tick(.05)
 var clone_after: Vector2=r.effects.filter(func(e: Dictionary)->bool:return e.kind=="clone")[0].position
 check(clone_after.distance_to(clone_position)>4.0,"the clone actually walks")
 check(r.skill(p,Vector2.RIGHT,"sub") and p.form=="jar","둔갑술 turns the caster into the nearby jar")
 p.form="";p.cd={};p.ult=r.ULT_MAX
 var before_paint: Vector2=p.position
 check(r.skill(p,Vector2.RIGHT,"ult") and r.hidden(p),"화중은신 hides the caster completely")
 var seen_by_yokai: Array=r.visible("bot-1").filter(func(a: Dictionary)->bool:return a.id=="human")
 check(seen_by_yokai.is_empty(),"a hidden painting caster is not visible to other players")
 # 벽을 통과해 움직이고, 발자국도 남기지 않는다.
 p.position=L.buildings()[0].rect.get_center();p.form="";p.cd={};p.ult=r.ULT_MAX
 r.skill(p,Vector2.RIGHT,"ult")
 p.intent=Vector2.RIGHT
 for i in range(20):r.tick(.05)
 check(p.position.distance_to(L.buildings()[0].rect.get_center())>40.0 and p.trail.is_empty(),"painting moves through walls without footprints")
 p.intent=Vector2.ZERO
 # 스치는 것만으로 봉인되지 않는다.
 other.position=p.position+Vector2(4,0);other.form="";other.cd={}
 var lives_before: int=int(p.lives)
 for i in range(6):r.tick(.05)
 check(not p.captured and int(p.lives)==lives_before,"contact cannot seal a hidden painting caster")
 practiced.append("daoist:woochi")
 # --- 홍길동: 담장넘기·바람발·팔방도약
 p=caster(r,"daoist:honggildong")
 var start: Vector2=p.position
 check(r.skill(p,Vector2.RIGHT,"main") and p.position.distance_to(start)>110.0,"담장넘기 leaps the aimed distance")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and p.speed_until>r.elapsed and is_equal_approx(p.speed_factor,1.7),"바람발 raises movement speed for five seconds")
 p.cd={};p.ult=r.ULT_MAX
 var leap_start: Vector2=p.position
 check(r.skill(p,Vector2.RIGHT,"ult") and p.position.distance_to(leap_start)>60.0,"팔방도약 makes three real leaps")
 check(r.effects.any(func(e: Dictionary)->bool:return e.kind=="afterimage"),"팔방도약 leaves afterimages")
 practiced.append("daoist:honggildong")
 # --- 장영실: 기관인형·압력기관·천문기계
 p=caster(r,"daoist:jangyeongsil")
 other=helper(r,"bot-1","yokai","yokai:gumiho",p.position+Vector2(40,0))
 check(r.skill(p,Vector2.RIGHT,"main") and r.effects.any(func(e: Dictionary)->bool:return e.kind=="decoy"),"기관인형 places a decoy")
 other.cd={}
 var decoy: Dictionary=r.effects.filter(func(e: Dictionary)->bool:return e.kind=="decoy")[0]
 other.position=decoy.position+Vector2(-30,0);other.facing=0
 var struck: bool=r.command("bot-1","seal")
 check(struck and float(decoy.until)<=r.elapsed and not p.captured,"striking the 기관인형 destroys the decoy instead of a daoist")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and not r.traps.is_empty(),"압력기관 installs a real pressure trap")
 other.position=r.traps[0].pos;other.cd={}
 r.tick(.05)
 check(other.slow_until>r.elapsed and other.slow_factor<.6,"the trap slows a yokai that steps on it")
 p.cd={};p.ult=r.ULT_MAX
 other.position=p.position+Vector2(700,0)
 check(r.skill(p,Vector2.RIGHT,"ult") and r.reveal_until>r.elapsed,"천문기계 reveals yokai across the map")
 check(r.visible("human").any(func(a: Dictionary)->bool:return a.id=="bot-1"),"revealed yokai show on the daoist screen")
 practiced.append("daoist:jangyeongsil")
 # --- 바리공주: 생명등불·저승꽃·귀환의 길
 p=caster(r,"daoist:barigongju")
 var ally:=helper(r,"bot-2","daoist","daoist:woochi",p.position+Vector2(90,0))
 other=helper(r,"bot-1","yokai","yokai:gumiho",p.position+Vector2(30,0))
 check(r.skill(p,Vector2.RIGHT,"main") and p.buff.get("shield",0)>r.elapsed and ally.buff.get("lifelamp",0)>r.elapsed,"생명등불 shields the caster and speeds a nearby ally")
 check(not r.seal_hit(other,p) and p.buff.get("shield",0)<=r.elapsed,"the lamp blocks one seal")
 p.position=ally.position+Vector2(0,20);p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and p.seal_bonus>=6.0,"저승꽃 adds six seconds of rescue time")
 var deadline_before: float=r.elapsed
 p.form="jar";other.cd={};p.buff.erase("lifelamp")
 r.seal_hit(other,p)
 check(not p.captured and p.buff.get("shield",0)<=r.elapsed,"the flower's shield absorbs the first seal")
 other.cd={}
 r.seal_hit(other,p)
 check(p.captured and p.deadline>=deadline_before+r.SEAL_DEADLINE+5.5,"the flower really extends the seal deadline")
 p.captured=false;p.cd={};p.ult=r.ULT_MAX;p.immune=0;p.buff={}
 ally.captured=true;ally.deadline=r.elapsed+8
 var from: Vector2=p.position
 check(r.skill(p,Vector2.RIGHT,"ult") and p.position.distance_to(from)>10.0,"귀환의 길 warps to the distressed ally")
 check(ally.buff.get("shield",0)>r.elapsed,"귀환의 길 shares a shield with the ally")
 practiced.append("daoist:barigongju")
 # --- 강림도령: 귀문보기·혼길표식·저승문
 p=caster(r,"daoist:gangnim")
 var wall: Rect2=L.buildings()[0].rect
 other=helper(r,"bot-1","yokai","yokai:gumiho",Vector2(wall.position.x+wall.size.x*.5,wall.position.y-40))
 p.position=Vector2(wall.position.x+wall.size.x*.5,wall.end.y+40)
 check(not L.line(p.position,other.position),"a hanok wall really blocks the line of sight")
 check(not r.visible("human").any(func(a: Dictionary)->bool:return a.id=="bot-1"),"the yokai is hidden behind the wall")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"main") and p.buff.get("ghostgate",0)>r.elapsed,"귀문보기 opens wall sight")
 check(r.visible("human").any(func(a: Dictionary)->bool:return a.id=="bot-1"),"hidden yokai becomes visible through the wall")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and (p.mark as Vector2).is_finite() and not r.marks.is_empty(),"혼길표식 plants a real return mark")
 var mark_at: Vector2=p.position
 p.position=L.SPAWN+Vector2(300,0);p.cd={};p.ult=r.ULT_MAX
 check(r.skill(p,Vector2.RIGHT,"ult") and p.position.distance_to(mark_at)<80.0,"저승문 returns to the mark")
 check(p.immune>r.elapsed,"저승문 grants brief invulnerability")
 practiced.append("daoist:gangnim")
 # --- 구미호: 인간둔갑·여우향·구미환몽
 p=caster(r,"yokai:gumiho")
 ally=helper(r,"bot-2","daoist","daoist:honggildong",p.position+Vector2(40,0))
 helper(r,"bot-3","daoist","daoist:woochi",p.position+Vector2(-120,0))
 check(r.skill(p,Vector2.RIGHT,"main") and p.copy=="bot-2" and p.buff.get("mimic",0)>r.elapsed,"인간둔갑 copies the nearest daoist")
 var mirror: Array=r.visible("bot-3").filter(func(a: Dictionary)->bool:return a.id=="human")
 check(not mirror.is_empty() and String(mirror[0].name)==String(ally.name) and String(mirror[0].role)=="daoist","the copied gumiho reads as that daoist to others")
 p.cd={}
 ally.position=p.position+Vector2(200,0)
 check(r.skill(p,Vector2.RIGHT,"sub") and ally.slow_until>r.elapsed and ally.slow_factor<.6,"여우향 slows daoists in range")
 p.cd={};p.ult=r.ULT_MAX
 check(r.skill(p,Vector2.RIGHT,"ult") and ally.blind_until>r.elapsed,"구미환몽 blinds nearby daoists with phantoms")
 check(r.effects.any(func(e: Dictionary)->bool:return e.kind=="decoy" and bool(e.get("phantom",false))),"구미환몽 leaves phantom shapes")
 practiced.append("yokai:gumiho")
 # --- 장산범: 목소리흉내·청각사냥·산군의 울음
 p=caster(r,"yokai:jangsanbeom")
 ally=helper(r,"bot-2","daoist","daoist:woochi",p.position+Vector2(240,0))
 check(r.skill(p,Vector2.RIGHT,"main") and r.effects.any(func(e: Dictionary)->bool:return e.kind=="fake_rescue"),"목소리흉내 plants a fake rescue sound")
 check(ally.buff.get("revealed",0)>r.elapsed,"목소리흉내 reveals the nearest daoist")
 check(r.events.any(func(e: Dictionary)->bool:return String(e.kind)=="fakerescue"),"the fake rescue is a real sound event")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and p.buff.get("sense",0)>r.elapsed,"청각사냥 turns on real footprint tracking")
 p.cd={};p.ult=r.ULT_MAX
 ally.position=p.position+Vector2(120,0)
 var ally_before: Vector2=ally.position
 check(r.skill(p,Vector2.RIGHT,"ult") and ally.position.distance_to(ally_before)>60.0,"산군의 울음 knocks daoists back")
 check(ally.stun>r.elapsed and p.speed_until>r.elapsed,"the howl stuns the prey and speeds the yokai")
 practiced.append("yokai:jangsanbeom")
 # --- 도깨비: 도깨비장난·가짜보물·도깨비잔치
 p=caster(r,"yokai:dokkaebi")
 ally=helper(r,"bot-2","daoist","daoist:woochi",p.position+Vector2(90,0))
 ally.position=L.OBJECTS[0].p+Vector2(8,0);ally.form="jar";ally.buff.transform=r.elapsed+9
 p.position=ally.position+Vector2(40,0)
 check(r.skill(p,Vector2.RIGHT,"main") and ally.form=="","도깨비장난 exposes a disguised daoist nearby")
 check(not r.prop_flips.is_empty(),"도깨비장난 really tips nearby props over")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and not r.traps.is_empty(),"가짜보물 plants a real lure trap")
 var lure: Dictionary=r.traps[r.traps.size()-1]
 p.position=L.SPAWN+Vector2(300,0);p.ground=p.position
 ally.captured=false;ally.eliminated=false
 ally.position=lure.pos;ally.ground=ally.position
 r.tick(.05)
 check(ally.stun>r.elapsed and not ally.captured,"a daoist stepping on the fake treasure is rooted")
 p.cd={};p.ult=r.ULT_MAX
 p.position=L.SPAWN+Vector2(0,-30);p.ground=p.position
 ally.position=p.position+Vector2(80,0);ally.ground=ally.position
 ally.form="jar";ally.buff.transform=r.elapsed+9;ally.stun=0.0
 var push_from: Vector2=ally.position
 check(r.skill(p,Vector2.RIGHT,"ult") and ally.form=="" and ally.position.distance_to(push_from)>40.0,"도깨비잔치 unmasks and pushes daoists")
 practiced.append("yokai:dokkaebi")
 # --- 어둑시니: 등불끄기·검은시야·무월야
 p=caster(r,"yokai:eodubsimi")
 ally=helper(r,"bot-2","daoist","daoist:woochi",p.position+Vector2(120,0))
 check(r.skill(p,Vector2.RIGHT,"main") and r.dark_until>r.elapsed and float(r.lantern_until.get("all",0.0))>r.elapsed,"등불끄기 darkens the area and puts lanterns out")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and ally.blind_until>r.elapsed,"검은시야 narrows the nearest daoist's sight")
 p.cd={};p.ult=r.ULT_MAX
 check(r.skill(p,Vector2.RIGHT,"ult") and r.map_dark_until>r.elapsed and r.hidden(p),"무월야 darkens the map and hides the yokai")
 var daoist_view: Array=r.visible("bot-2").filter(func(a: Dictionary)->bool:return a.id=="human")
 check(daoist_view.is_empty(),"a moonless yokai is invisible to daoists")
 practiced.append("yokai:eodubsimi")
 # --- 야광귀: 신발흔적·야광가루·발자국지도
 p=caster(r,"yokai:yagwangwi")
 ally=helper(r,"bot-2","daoist","daoist:woochi",p.position+Vector2(160,0))
 ally.trail=[{"position":ally.position,"time":r.elapsed-1.0,"facing":0}]
 check(r.skill(p,Vector2.RIGHT,"main") and r.trail_all_until>r.elapsed,"신발흔적 lights up footprints")
 p.cd={}
 check(r.skill(p,Vector2.RIGHT,"sub") and ally.buff.get("glowing",0)>r.elapsed,"야광가루 marks the nearest daoist")
 check(r.marks.any(func(m: Dictionary)->bool:return String(m.get("kind",""))=="glow"),"the glow mark is tracked on the map")
 p.cd={};p.ult=r.ULT_MAX
 check(r.skill(p,Vector2.RIGHT,"ult") and r.trail_all_until>r.elapsed and p.buff.get("sense",0)>r.elapsed,"발자국지도 draws every daoist trail")
 practiced.append("yokai:yagwangwi")
 check(practiced.size()==10,"all ten characters were exercised ("+str(practiced.size())+")")
 # ---------------------------------------------------------------- 4) 30도술 서명 이펙트
 var r2:=live(11)
 var missing: Array=[]
 var executed:=0
 for entry in C.roster():
  var caster_player:=caster(r2,String(entry.id))
  var partner:=helper(r2,"bot-2","daoist","daoist:woochi",caster_player.position+Vector2(50,0))
  partner.captured=(String(entry.team)=="daoist")
  for slot in ["main","sub","ult"]:
   caster_player.cd={};caster_player.ult=r2.ULT_MAX;caster_player.form="";caster_player.mark=L.SPAWN
   caster_player.position=L.OBJECTS[0].p+Vector2(20,0)
   partner.position=caster_player.position+Vector2(45,0)
   r2.effects.clear()
   var skill_id:=String(C.ability(String(entry.id),slot).get("skill",""))
   if r2.skill(caster_player,Vector2.RIGHT,slot):
    executed+=1
    if not has_sig(r2,skill_id):missing.append(skill_id)
   else:missing.append(entry.id+":"+slot+"(fail)")
 check(executed==30,"all thirty skills fire in the live rules (%d/30)"%executed)
 check(missing.is_empty(),"every fired skill leaves its signature effect "+str(missing))
 # ---------------------------------------------------------------- 5) 상황 버튼 · 도감/동물 크기
 root.size=Vector2i(2340,1080)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("V28 검증",8,true);await create_timer(.5).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(600):
  if game.rules.phase in ["selection","ready"]:game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 game.rules.phase="live";game.rules.elapsed=5.0
 for i in range(4):game.rules.tick(.05)
 await frames(4)
 check(game.screen=="match","a real match is running for HUD checks")
 var me: Dictionary=game.rules.players.human
 # 도사 시점 HUD(둔갑·구출·문)를 검사한다. 배정이 요괴였다면 도사로 바꿔 HUD를 다시 그린다.
 # 둔갑술을 가진 전우치 대신, 공용 둔갑 버튼을 쓰는 홍길동으로 검사한다(2.0.28 통합).
 me.role="daoist";me.character="daoist:honggildong"
 if game.disguise_button==null:
  game.build("match");await frames(4)
  me=game.rules.players.human
 me.position=L.SPAWN;me.form="";me.role="daoist";me.character="daoist:honggildong";me.cd={}
 game.update_avatars();game.update_hud();await frames(3)
 check(game.interaction_context().is_empty(),"no action context in an empty courtyard")
 var visible_actions:=0
 for key in game.action_buttons:
  if game.action_buttons[key].visible:visible_actions+=1
 check(visible_actions==0,"no idle 상호작용 button is on screen")
 check(not game.action_buttons.has("interact"),"the generic interaction button is gone")
 check(not game.action_buttons.has("confirm"),"daoists never get the yokai confirm button")
 me.position=L.OBJECTS[0].p+Vector2(6,0)
 game.update_hud()
 check(game.disguise_button.visible and not game.door_button.visible,"둔갑 button appears beside a prop")
 # 전우치는 같은 자리에서 공용 둔갑 버튼이 뜨지 않고, 윗줄 둔갑술 버튼 하나로 둔갑한다.
 me.character="daoist:woochi";me.cd={}
 game.update_hud()
 check(not game.disguise_button.visible,"a transform-skill daoist has no duplicate 둔갑 button")
 check(game.skill_buttons["sub"].get_node("Caption").text=="둔갑술","the merged 둔갑술 button stays on screen")
 check(game.rules.skill(me,Vector2.RIGHT,"sub") and me.form=="jar","둔갑술 disguises on the prop with one button")
 check(game.rules.skill(me,Vector2.RIGHT,"sub") and me.form=="","pressing 둔갑술 again releases the disguise even on cooldown")
 me.form="";me.character="daoist:honggildong";me.cd={}
 game.update_hud()
 check(game.form_pulse.visible,"the disguise button still glows")
 var front: Vector2=(L.buildings()[0].doors as Dictionary).front
 me.position=front+Vector2(0,16)
 game.update_hud()
 check(game.door_button.visible and game.door_button.get_node("Caption").text=="문 열기","문 열기 appears only at a door")
 check(not game.disguise_button.visible,"the disguise button hides when a door takes priority")
 me.form="jar";me.buff.transform=game.rules.elapsed+9;me.position=L.SPAWN
 game.update_hud()
 check(game.disguise_button.visible and game.disguise_button.get_node("Caption").text=="둔갑 해제","a disguised daoist gets 둔갑 해제")
 me.form=""
 # 요괴 HUD: 확인은 의심 사물 앞에서만.
 me.role="yokai";me.character="yokai:gumiho";me.cd={}
 game.build("match");await frames(4)
 me=game.rules.players.human
 me.position=L.OBJECTS[0].p+Vector2(10,0);me.form="";me.cd={}
 game.update_hud()
 check(game.confirm_button!=null and game.confirm_button.visible,"the yokai gets 확인 next to a suspicious prop")
 me.position=L.SPAWN
 game.update_hud()
 check(not game.confirm_button.visible,"확인 disappears away from props")
 # 동물 크기: 맵·둔갑 모두 22~26px.
 check(float(game.world.ANIMAL_HEIGHT.get("cat",99.0))<=24.0 and float(game.world.ANIMAL_HEIGHT.get("dog",99.0))<=28.0,"map animals shrink to prop scale")
 check(float(L.form_visual("cat").height)<=24.0 and float(L.form_visual("dog").height)<=28.0,"cat and dog disguise use the same small size")
 if game.rules.walkers.is_empty():game.rules.build_walkers()
 await frames(8)
 game.update_avatars();await frames(4)
 var walker_sheet: Dictionary=C.animal_sheet(String(game.rules.walkers[0].kind))
 check(not game.world.animal_nodes.is_empty(),"walking animals are drawn on the map")
 var drawn:=999.0
 if not game.world.animal_nodes.is_empty():
  drawn=float(game.world.animal_nodes[0].scale.y)*C.sheet_art_height(walker_sheet)
 check(drawn<=30.0,"an animal really draws under 30px tall (%d)"%int(drawn))
 # 8방향 시트 로더: 8행이 있으면 그 행, 4행이면 옆모습 폴백.
 var eight: Array=C.DIRECTIONS8
 var four: Array=["front","left","right","back"]
 check(int(C.sheet_row(eight,1).row)==1 and String(C.sheet_row(eight,1).view)=="front_right","front-right diagonal picks its own row")
 check(int(C.sheet_row(eight,7).row)==3 and int(C.sheet_row(eight,3).row)==7,"back-right and front-left diagonals map correctly")
 check(int(C.sheet_row(eight,0).row)==2 and int(C.sheet_row(eight,6).row)==4,"east and north keep right/back rows")
 check(int(C.sheet_row(four,1).row)==2 and String(C.sheet_row(four,1).view)=="right","four-row sheets still fall back to the side row")
 check(int(C.sheet_row(four,5).row)==1 and String(C.sheet_row(four,5).view)=="left","four-row sheets map north-west to the left row")
 check(C.eight_direction(eight) and not C.eight_direction(four),"eight-direction sheets are detected")
 var walker_rows: Array=(C.walk_sheet("woochi").get("rows",[]) as Array)
 check(C.eight_direction(walker_rows) or walker_rows.size()==4,"current walk sheet loads with the shared row resolver")
 game.cleanup_match();game.queue_free();await frames(2)
 print("V28 SKILLS: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
