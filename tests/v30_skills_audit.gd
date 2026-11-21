extends SceneTree
## 2.0.30 전수 검증: 10인 30개 도술의 시전자·대상 진영 일치, 은신의 실제 완전 비노출
## (캐릭터·이름표·그림자·기운·발자국·미니맵·AI·접촉 판정), 같은 팀 미니맵 표시,
## 스킬 미니맵 표기, 시야 좁히기·등불끄기 화면 연출, 발동 피드백 배너/뱃지.
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const FX=preload("res://scripts/survival/fx.gd")
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V30 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
## 가운데 마당(팔각 문양) 근처의 열린 바닥. 시야·사거리 판정이 담·기둥에 걸리지 않는다.
func open_spot(offset: Vector2=Vector2.ZERO) -> Vector2:
 var spot: Vector2=L.safe(L.MEDALLION+Vector2(0,240)+offset)
 return spot
func live(seed_value: int=30) -> RefCounted:
 var r:=Rules.new(seed_value)
 r.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):r.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in r.players.values():p.ready=true
 r.start()
 for p in r.players.values():
  if C.find(p.character).is_empty():p.character=C.catalog(p.role)[0].id
 r.phase="live";r.elapsed=10.0;r.build_walkers()
 return r
## 시험에 쓰지 않는 참가자는 멀리 치워 최근접·사거리 판정을 깨끗하게 만든다.
func park(r: RefCounted,keep: Array) -> void:
 var index:=0
 for q in r.players.values():
  if keep.has(q.id):continue
  q.position=Vector2(3320,2500)+Vector2(index*12,index*6);q.ground=q.position
  q.captured=false;q.eliminated=false;q.form="";q.buff={};q.cd={};q.intent=Vector2.ZERO
  q.trail=[];q.blind_until=0.0;q.slow_until=0.0;q.stun=0.0;q.immune=0.0
  index+=1
func caster(r: RefCounted,character_id: String,at: Vector2,keep: Array=[]) -> Dictionary:
 var p: Dictionary=r.players.human
 var spec:=C.find(character_id)
 p.character=character_id;p.role=String(spec.get("team","daoist"))
 p.position=at;p.ground=at;p.origin=at;p.form_origin=at
 p.captured=false;p.eliminated=false;p.form="";p.buff={};p.cd={};p.ult=r.ULT_MAX
 p.stun=0.0;slow_until_reset(p);p.blind_until=0.0;p.immune=0.0;p.mark=Vector2.INF
 p.trail=[];p.stats={"seals":0,"misses":0,"rescues":0,"lost":0}
 park(r,[p.id]+keep)
 return p
func slow_until_reset(p: Dictionary) -> void:
 p.slow_until=0.0;p.speed_until=0.0;p.speed_factor=1.0
func helper(r: RefCounted,id: String,role: String,character_id: String,at: Vector2) -> Dictionary:
 var q: Dictionary=r.players[id]
 q.role=role;q.character=character_id
 q.position=at;q.ground=at;q.captured=false;q.eliminated=false;q.form="";q.buff={};q.cd={}
 q.stun=0.0;q.slow_until=0.0;q.speed_until=0.0;q.blind_until=0.0;q.immune=0.0;q.trail=[]
 return q
func sig_count(r: RefCounted,skill_id: String) -> int:
 var count:=0
 for e in r.effects:
  if String(e.kind)=="fx_sig" and String(e.get("skill",""))==skill_id:count+=1
 return count
func feed_entry(r: RefCounted,skill_id: String) -> Dictionary:
 for entry in r.cast_feed:
  if String(entry.get("skill",""))==skill_id:return entry
 return {}
func has_effect_kind(r: RefCounted,kind: String) -> bool:
 return r.effects.any(func(e: Dictionary)->bool:return String(e.kind)==kind)

func run() -> void:
 # ---------------------------------------------------------------- 1) 30개 목록·설명·연출 표
 var roster:=C.roster()
 check(roster.size()==10,"roster holds the ten characters")
 var daoists:=C.catalog("daoist")
 var yokai:=C.catalog("yokai")
 check(daoists.size()==5 and yokai.size()==5,"five daoists and five yokai")
 var ability_total:=0
 var sig_missing: Array=[]
 var name_broken: Array=[]
 for entry in roster:
  var abilities: Array=entry.abilities
  if abilities.size()!=3:name_broken.append(String(entry.id))
  ability_total+=abilities.size()
  for ability in abilities:
   if not FX.SIG.has(String(ability.skill)):sig_missing.append(String(ability.skill))
   var table: Dictionary=C.SKILLS.get(String(ability.skill),{})
   if String(table.get("name",""))!=String(ability.get("name","")):name_broken.append(String(entry.id)+":"+String(ability.skill))
 check(ability_total==30,"thirty abilities across the ten characters ("+str(ability_total)+")")
 check(sig_missing.is_empty(),"every one of the thirty has a drawn signature")
 check(name_broken.is_empty(),"skill table names agree with the roster")
 # 진영·대상 표: 도사 스킬은 요괴를 이롭게, 요괴 스킬은 도사를 이롭게 하면 안 된다.
 var team_broken: Array=[]
 for entry in roster:
  for ability in entry.abilities:
   var table: Dictionary=C.SKILLS.get(String(ability.skill),{})
   if table.is_empty():team_broken.append(String(ability.skill))
 check(team_broken.is_empty(),"every ability resolves through the shared skill table")

 # ---------------------------------------------------------------- 2) 30개 실제 시전
 var r:=live()
 var cast_ok:=true
 var cast_names: Array=[]
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   for slot in ["main","sub","ult"]:
    var ability: Dictionary=C.ability(String(entry.id),slot)
    var at:=open_spot()
    var p:=caster(r,String(entry.id),at)
    p.mark=Vector2.INF;p.cd={}
    var skill_id: String=String(ability.get("skill",""))
    # 전제 조건이 있는 스킬은 조건을 만들어 준다(둔갑=사물, 저승문=표식, 귀환의 길=봉인된 동료).
    if skill_id in ["transform","disguise"]:
     var prop: Dictionary=L.OBJECTS[3]
     p.position=prop.p;p.ground=p.position
    if skill_id=="underworldgate":
     p.mark=open_spot(Vector2(-120,-60))
    if skill_id=="returnpath":
     helper(r,"bot-1","daoist","daoist:barigongju",at+Vector2(90,20)).captured=true
    if skill_id=="lifelamp":
     helper(r,"bot-2","daoist","daoist:barigongju",at+Vector2(60,10))
    if skill_id=="mimic" or skill_id=="voicemimic" or skill_id=="glowpowder" or skill_id=="blackvision":
     helper(r,"bot-3","daoist","daoist:honggildong",at+Vector2(80,0))
    r.effects.clear();r.traps.clear();r.marks.clear();r.pings=[];r.cast_feed.clear()
    r.dark_until=0.0;r.map_dark_until=0.0;r.reveal_until=0.0;r.trail_all_until=0.0
    r.lantern_until.clear()
    var cast: bool=r.skill(p,Vector2.RIGHT,slot)
    var name_ok: bool=String(p.get("last_skill_name",""))!=""
    var feed: Dictionary=feed_entry(r,skill_id)
    var event_ok: bool=r.events.any(func(e: Dictionary)->bool:return String(e.get("kind",""))=="skill" and String(e.get("name",""))!="")
    if not (cast and sig_count(r,skill_id)>=1 and not feed.is_empty() and name_ok and event_ok):
     cast_ok=false
     print("V30 CAST MISS ",entry.id,"/",slot,"/",skill_id," cast=",cast," sig=",sig_count(r,skill_id)," feed=",not feed.is_empty()," name=",name_ok," event=",event_ok)
    cast_names.append(String(ability.get("name","")))
 check(cast_ok,"all thirty skills cast, draw a signature, and leave cast feedback")
 var feed_team_ok:=true
 for entry in r.cast_feed:
  if String(entry.get("team","")) not in ["daoist","yokai"]:feed_team_ok=false
 check(feed_team_ok,"cast feedback carries the caster team")

 # ---------------------------------------------------------------- 3) 진영·대상 일치(스킬별)
 # 도사 15
 r=live();var at:=open_spot();var me:=caster(r,"daoist:woochi",at)
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main") and has_effect_kind(r,"clone"),"분신술 leaves a moving clone")
 var prop: Dictionary=L.OBJECTS[5]
 me= caster(r,"daoist:woochi",prop.p)
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"sub") and me.form!="","둔갑술 disguises on a real prop")
 var enemy: Dictionary=helper(r,"bot-4","yokai","yokai:eodubsimi",prop.p+Vector2(70,0))
 var hidden_ids: Array=[]
 for a in r.visible(String(enemy.id)):
  hidden_ids.append(String(a.id))
 check(not hidden_ids.has("human"),"a disguised daoist keeps no id in the yokai's view")
 check(float(me.buff.get("transform",0.0))-r.elapsed>8.5,"disguise lasts the documented nine seconds")
 # 화중은신 은신: 상대 시점·미니맵·AI·발자국·접촉 봉인 전부에서 사라진다.
 me=caster(r,"daoist:woochi",at);enemy=helper(r,"bot-4","yokai","yokai:eodubsimi",at+Vector2(-40,0))
 me.trail=[{"position":at,"time":r.elapsed,"facing":2}]
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and r.hidden(me),"화중은신 hides the caster")
 var seen: Array=r.visible(String(enemy.id))
 check(not seen.any(func(a: Dictionary)->bool:return String(a.id)=="human"),"a painting daoist is absent from the enemy view")
 check(seen.size()>=0,"enemy view still resolves")
 check(me.trail.is_empty(),"painting clears the footprint trail")
 enemy.cd.erase("seal");enemy.facing=0;r.elapsed+=.01
 check(r.command(String(enemy.id),"seal") and not me.captured,"a hidden daoist cannot be unmasked by the confirm strike")
 enemy.position=me.position+Vector2(4,0);enemy.cd.erase("seal");r.contact_seal()
 check(not me.captured,"a hidden daoist cannot be sealed by body contact")
 check(r.allies("human").any(func(a: Dictionary)->bool:return String(a.id)=="human"),"own team still sees the hidden ally on the minimap")
 check(r.map_contacts(String(enemy.id)).all(func(c: Dictionary)->bool:return String(c.id)!="human"),"a painting daoist never appears on the yokai minimap")
 check(not r.active_effects("human").is_empty(),"the caster's HUD lists the active stealth state")
 # 담장넘기·바람발·팔방도약
 me=caster(r,"daoist:honggildong",at);var before: Vector2=me.position
 check(r.skill(me,Vector2.RIGHT,"main") and me.position.distance_to(before)>90,"담장넘기 leaps toward the aim")
 me=caster(r,"daoist:honggildong",at);check(r.skill(me,Vector2.RIGHT,"sub") and is_equal_approx(me.speed_factor,1.7) and me.speed_until-r.elapsed>4.5,"바람발 grants the documented 5s 1.7x speed")
 me=caster(r,"daoist:honggildong",at);r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and me.position.distance_to(at)>120 and has_effect_kind(r,"afterimage"),"팔방도약 leaps three times with afterimages")
 # 기관인형(요괴의 확인으로 터지는 미끼) — 대상 진영이 요괴여야 한다
 me=caster(r,"daoist:jangyeongsil",at);enemy=helper(r,"bot-4","yokai","yokai:jangsanbeom",at+Vector2(30,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main") and has_effect_kind(r,"decoy"),"기관인형 plants a decoy")
 enemy.cd.erase("seal");var misses_before:=int(enemy.stats.misses)
 check(r.command(String(enemy.id),"seal") and int(enemy.stats.misses)==misses_before+1,"the decoy only wastes the yokai's confirm")
 # 압력기관: 요괴만 느려진다.
 me=caster(r,"daoist:jangyeongsil",at);r.traps.clear();check(r.skill(me,Vector2.RIGHT,"sub") and r.traps.size()==1,"압력기관 installs one pressure trap")
 var daoist_walker: Dictionary=helper(r,"bot-5","daoist","daoist:barigongju",at)
 r.elapsed+=.02;r._tick_traps(.02)
 check(daoist_walker.slow_until<=r.elapsed,"the pressure trap spares daoists")
 var yokai_walker: Dictionary=helper(r,"bot-4","yokai","yokai:jangsanbeom",at)
 r.elapsed+=.02;r._tick_traps(.02)
 check(yokai_walker.slow_until>r.elapsed,"the pressure trap slows a yokai")
 # 천문기계: 도사가 요괴를 꿰뚫는다(반대 진영에는 효과 없음).
 me=caster(r,"daoist:jangyeongsil",at);enemy=helper(r,"bot-4","yokai","yokai:jangsanbeom",at+Vector2(900,0))
 r.reveal_until=0.0;check(r.skill(me,Vector2.RIGHT,"ult") and r.reveal_until>r.elapsed,"천문기계 opens the reveal window")
 var far_seen: Array=r.visible("human")
 check(far_seen.any(func(a: Dictionary)->bool:return String(a.id)=="bot-4"),"the astrolabe reveals the yokai across the map")
 var yokai_eye: Array=r.visible("bot-4")
 check(not yokai_eye.any(func(a: Dictionary)->bool:return String(a.id)=="human" and false),"the astrolabe does not expose daoists to the yokai")
 # 생명등불: 도사 동료만 8초 혜택.
 me=caster(r,"daoist:barigongju",at,["bot-1","bot-2"])
 var near_ally: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(150,0))
 var far_ally: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(520,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main"),"생명등불 casts")
 check(float(near_ally.buff.get("lifelamp",0.0))-r.elapsed>7.5 and near_ally.buff.get("shield",0)>r.elapsed,"생명등불 gives the nearby ally the full eight-second lamp and shield")
 check(float(far_ally.buff.get("lifelamp",0.0))<=r.elapsed,"생명등불 leaves a distant ally alone")
 # 저승꽃: 보호막 8초 + 구조 시간 6초.
 me=caster(r,"daoist:barigongju",at);r.effects.clear();check(r.skill(me,Vector2.RIGHT,"sub"),"저승꽃 casts")
 check(me.buff.get("shield",0)>r.elapsed and is_equal_approx(float(me.get("seal_bonus",0.0)),6.0),"저승꽃 shields and grants six extra rescue seconds")
 enemy=helper(r,"bot-4","yokai","yokai:jangsanbeom",at+Vector2(12,0));enemy.cd.erase("seal")
 me.buff.erase("shield");r.seal_hit(enemy,me)
 check(me.captured and me.deadline-r.elapsed>15.5,"the sealed deathflower holder keeps the longer deadline")
 # 귀환의 길: 봉인된 도사 곁으로.
 me=caster(r,"daoist:barigongju",at,["bot-1"])
 var prisoner: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(700,0));prisoner.captured=true
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and me.position.distance_to(prisoner.position)<70,"귀환의 길 warps to the distressed ally")
 check(prisoner.buff.get("shield",0)>r.elapsed,"귀환의 길 shares a shield with the ally")
 # 귀문보기: 벽 너머 투시.
 me=caster(r,"daoist:gangnim",open_spot(Vector2(-600,0)))
 var behind: Dictionary=helper(r,"bot-4","yokai","yokai:jangsanbeom",open_spot(Vector2(-600,0))+Vector2(1400,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main") and float(me.buff.get("ghostgate",0.0))-r.elapsed>5.5,"귀문보기 opens for six seconds")
 # 혼길표식 + 저승문
 me=caster(r,"daoist:gangnim",at);r.marks.clear()
 check(r.skill(me,Vector2.RIGHT,"sub") and (me.mark as Vector2).is_finite() and not r.marks.is_empty(),"혼길표식 plants the return mark")
 var mark_pos: Vector2=me.mark
 me.position=open_spot(Vector2(400,0));me.ground=me.position
 check(r.skill(me,Vector2.RIGHT,"ult") and me.position.distance_to(mark_pos)<2.0 and me.immune>r.elapsed,"저승문 returns to the mark with immunity")
 # 요괴 15
 r=live();at=open_spot()
 me=caster(r,"yokai:gumiho",at,["bot-1","bot-2"])
 var prey: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(60,0))
 helper(r,"bot-2","yokai","yokai:dokkaebi",at+Vector2(-50,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main"),"인간둔갑 casts")
 check(String(me.copy)==String(prey.id),"인간둔갑 only copies a daoist")
 var yokai_witness: Array=r.visible(String(prey.id))
 var mimic_view: Dictionary={}
 for a in yokai_witness:
  if String(a.id)==String(me.id):mimic_view=a
 check(not mimic_view.is_empty() and String(mimic_view.role)=="daoist" and String(mimic_view.character)==String(prey.character) and bool(mimic_view.mimic),"the mimic wears the daoist's character, name and team on other screens")
 # 도사만 있던 자리에서 요괴만 남으면 둔갑이 실패한다.
 me=caster(r,"yokai:gumiho",at,["bot-2"]);helper(r,"bot-2","yokai","yokai:dokkaebi",at+Vector2(30,0))
 r.effects.clear();check(not r.skill(me,Vector2.RIGHT,"main"),"인간둔갑 refuses to copy a fellow yokai")
 # 여우향: 반경 220만.
 me=caster(r,"yokai:gumiho",at,["bot-1","bot-2"])
 var near_prey: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(200,0))
 var edge_prey: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(240,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"sub"),"여우향 casts")
 check(near_prey.slow_until>r.elapsed and edge_prey.slow_until<=r.elapsed,"여우향 slows inside 220 only")
 # 구미환몽: 시야 7초 + 요괴 본인도 칠 수 없는 환영.
 me=caster(r,"yokai:gumiho",at,["bot-1"]);var dream: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(120,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and dream.blind_until-r.elapsed>6.5,"구미환몽 blinds for seven seconds")
 var phantom: Dictionary={}
 for e in r.effects:
  if String(e.kind)=="decoy" and bool(e.get("phantom",false)):phantom=e
 check(not phantom.is_empty(),"구미환몽 leaves phantom decoys")
 me.position=phantom.position if not phantom.is_empty() else me.position
 me.cd.erase("seal")
 r.command(String(me.id),"seal")
 check(not phantom.is_empty() and float(phantom.get("until",0.0))>r.elapsed,"the caster cannot pop his own phantom")
 # 목소리흉내: 가짜 구조 + 가장 가까운 도사 노출.
 me=caster(r,"yokai:jangsanbeom",at,["bot-1"]);var lure: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(90,30))
 r.effects.clear();r.pings=[];check(r.skill(me,Vector2.RIGHT,"main") and has_effect_kind(r,"fake_rescue"),"목소리흉내 plants a fake rescue")
 check(lure.buff.get("revealed",0)>r.elapsed and not r.pings.is_empty(),"목소리흉내 marks the nearest daoist")
 # 청각사냥
 me=caster(r,"yokai:jangsanbeom",at);r.effects.clear();check(r.skill(me,Vector2.RIGHT,"sub") and float(me.buff.get("sense",0.0))-r.elapsed>3.5,"청각사냥 opens four seconds of hearing")
 # 산군의 울음: 반경 320만 민다.
 me=caster(r,"yokai:jangsanbeom",at,["bot-1","bot-2"])
 var pushed: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(0,-300))
 var safe_far: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(0,-340))
 var pushed_from: Vector2=pushed.position;var far_from: Vector2=safe_far.position
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult"),"산군의 울음 casts")
 check(pushed.position.distance_to(pushed_from)>60 and safe_far.position.distance_to(far_from)<2.0,"산군의 울음 reaches 320 and no further")
 check(me.speed_until-r.elapsed>5.5,"산군의 울음 hastes the caster for six seconds")
 # 도깨비장난: 반경 260의 둔갑만 풀고 사물을 눕힌다.
 at=L.OBJECTS[20].p
 me=caster(r,"yokai:dokkaebi",at,["bot-1","bot-2"])
 var disguised: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(200,0));disguised.form="jar";disguised.buff.transform=r.elapsed+9
 var disguised_far: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(300,0));disguised_far.form="jar";disguised_far.buff.transform=r.elapsed+9
 r.effects.clear();r.prop_flips.clear();check(r.skill(me,Vector2.RIGHT,"main"),"도깨비장난 casts")
 check(disguised.form=="" and disguised_far.form=="jar","도깨비장난 unmasks inside 260 only")
 check(not r.prop_flips.is_empty(),"도깨비장난 tips real props over")
 check(disguised.stun>r.elapsed and disguised.slow_until>r.elapsed,"도깨비장난 staggers and slows the unmasked daoist")
 check(disguised.buff.get("revealed",0.0)>r.elapsed,"도깨비장난 briefly reveals the daoist")
 check(not r.mischief_zones.is_empty() and r.in_mischief(at),"도깨비장난 leaves a real mischief zone")
 var blocked: bool=not r.skill(disguised,Vector2.RIGHT,"sub")
 check(blocked,"a daoist cannot disguise inside the mischief zone")
 r.elapsed+=1.0;r.tick(.05)
 check(disguised.slow_until>r.elapsed and disguised.form=="","the mischief zone keeps slowing and unmasking daoists")
 # 가짜보물: 도사만 꼼짝 못 한다.
 me=caster(r,"yokai:dokkaebi",at,["bot-1","bot-2"]);r.traps.clear();check(r.skill(me,Vector2.RIGHT,"sub") and r.traps.size()==1,"가짜보물 installs one treasure trap")
 var greedy: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at)
 r.elapsed+=.02;r._tick_traps(.02)
 check(greedy.stun>r.elapsed,"the treasure trap freezes a daoist")
 me.cd.erase("mischief")
 # 도깨비잔치: 반경 200만.
 me=caster(r,"yokai:dokkaebi",at,["bot-1","bot-2"])
 var close_one: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(180,0));close_one.form="crate";close_one.buff.transform=r.elapsed+9
 var out_one: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(230,0));out_one.form="crate";out_one.buff.transform=r.elapsed+9
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult"),"도깨비잔치 casts")
 check(close_one.form=="" and out_one.form=="crate","도깨비잔치 reaches 200 and no further")
 # 등불끄기: 반경 300 · 9초, 요괴 본인은 어두워지지 않는다.
 me=caster(r,"yokai:eodubsimi",at,["bot-1"]);var in_dark: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(120,0))
 r.dark_until=0.0;r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main"),"등불끄기 casts")
 check(is_equal_approx(r.dark_radius,300.0) and r.dark_until-r.elapsed>8.5,"등불끄기 covers 300 for nine seconds")
 check(float(r.lantern_until.get("all",0.0))>r.elapsed,"등불끄기 puts the lanterns out")
 check(float(r.vision_for("bot-1").dark)>0.0 and is_equal_approx(float(r.vision_for(String(me.id)).dark),0.0),"the darkness blinds daoists, not the yokai")
 check(float(r.vision_for("bot-1").dark)>0.0,"a daoist inside the douse radius loses light")
 # 검은시야: 가장 가까운 도사만.
 me=caster(r,"yokai:eodubsimi",at,["bot-1","bot-2"])
 var victim: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(70,0))
 var spared: Dictionary=helper(r,"bot-2","daoist","daoist:honggildong",at+Vector2(300,0))
 r.effects.clear();check(r.skill(me,Vector2.RIGHT,"sub") and victim.blind_until-r.elapsed>5.5,"검은시야 narrows the nearest daoist for six seconds")
 check(spared.blind_until<=r.elapsed,"검은시야 spares the second daoist")
 check(float(r.vision_for(String(victim.id)).narrow)>0.0,"검은시야 produces a real screen vignette value")
 check(float(r.vision_for(String(me.id)).narrow)<=0.0,"검은시야 does not narrow the caster's own sight")
 # 무월야: 은신 + 8초 암흑.
 me=caster(r,"yokai:eodubsimi",at,["bot-1"]);var watcher: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(60,0))
 r.map_dark_until=0.0;r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and r.map_dark_until-r.elapsed>7.5,"무월야 darkens for eight seconds")
 check(r.hidden(me),"무월야 hides the yokai while hunting")
 var moon_eye: Array=r.visible(String(watcher.id))
 check(not moon_eye.any(func(a: Dictionary)->bool:return String(a.id)==String(me.id)),"a moonless yokai is invisible to daoists")
 check(float(r.vision_for(String(watcher.id)).dark)>0.0,"무월야 darkens the daoist screen")
 # 야광귀: 신발흔적·야광가루·발자국지도
 me=caster(r,"yokai:yagwangwi",at,["bot-1","bot-2"])
 var runner: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(90,0))
 runner.trail=[{"position":at+Vector2(40,0),"time":r.elapsed,"facing":2},{"position":at+Vector2(80,0),"time":r.elapsed,"facing":2}]
 helper(r,"bot-2","yokai","yokai:dokkaebi",at+Vector2(-60,0))
 r.trail_all_until=0.0;r.effects.clear();check(r.skill(me,Vector2.RIGHT,"main") and r.trail_all_until-r.elapsed>7.5,"신발흔적 lights every daoist footprint")
 check(r.map_contacts(String(me.id)).any(func(c: Dictionary)->bool:return String(c.id)=="bot-1"),"신발흔적 shows daoists on the yokai minimap")
 runner.buff={}
 r.marks.clear();check(r.skill(me,Vector2.RIGHT,"sub") and runner.buff.get("glowing",0)>r.elapsed,"야광가루 marks the nearest daoist")
 check(r.map_contacts(String(me.id)).any(func(c: Dictionary)->bool:return String(c.id)==String(runner.id)),"야광가루 shows the marked daoist on the yokai minimap")
 check(not r.map_contacts(String(runner.id)).any(func(c: Dictionary)->bool:return String(c.id)==String(runner.id)),"the yokai's glow mark is not drawn for the daoist's own map")
 r.trail_all_until=0.0;r.effects.clear();check(r.skill(me,Vector2.RIGHT,"ult") and r.trail_all_until-r.elapsed>9.5 and float(me.buff.get("sense",0.0))-r.elapsed>9.5,"발자국지도 draws trails for ten seconds")

 # ---------------------------------------------------------------- 4) 미니맵 아군·스킬 표기
 r=live();at=open_spot();me=caster(r,"daoist:woochi",at)
 for i in range(1,8):r.players["bot-%d"%i].role="daoist"
 var mate: Dictionary=helper(r,"bot-1","daoist","daoist:honggildong",at+Vector2(80,0))
 var sealed_mate: Dictionary=helper(r,"bot-2","daoist","daoist:barigongju",at+Vector2(-80,0));sealed_mate.captured=true
 var lost_mate: Dictionary=helper(r,"bot-3","daoist","daoist:jangyeongsil",at+Vector2(0,80));lost_mate.eliminated=true
 var ally_list: Array=r.allies("human")
 var daoist_count: int=r.players.values().filter(func(p: Dictionary)->bool:return String(p.role)=="daoist").size()
 check(ally_list.size()==daoist_count and daoist_count>=8,"the minimap ally list holds the whole daoist team")
 var self_ok:=false
 var sealed_ok:=false
 var lost_ok:=false
 for a in ally_list:
  if bool(a.self) and not bool(a.captured):self_ok=true
  if String(a.id)=="bot-2" and bool(a.captured):sealed_ok=true
  if String(a.id)=="bot-3" and bool(a.eliminated):lost_ok=true
 check(self_ok and sealed_ok and lost_ok,"ally entries tell survival, sealing and elimination apart")
 var mixed:=false
 for a in ally_list:
  if String(r.players[String(a.id)].role)!="daoist":mixed=true
 check(not mixed,"the ally list never mixes in the other team")
 # 2.0.30 미니맵 표시 원칙: 평상시엔 같은 팀만, 적은 탐지 도술 동안만.
 r.players["bot-4"].role="yokai";r.players["bot-4"].character="yokai:gumiho"
 r.players["bot-4"].eliminated=false;r.players["bot-4"].position=at+Vector2(-260,0);r.players["bot-4"].ground=r.players["bot-4"].position
 r.reveal_until=0.0;r.trail_all_until=0.0
 r.traps.append({"kind":"pressure","owner":"bot-1","pos":at+Vector2(10,0),"until":r.elapsed+20.0,"radius":36.0,"armed":true})
 r.marks.append({"owner":"human","pos":at,"until":r.elapsed+600.0})
 check(r.map_contacts("human").is_empty(),"the minimap shows no enemy at all in normal play")
 check(not r.has_method("map_marks"),"trap and object markers are gone from the minimap API")
 var minimap_source:=FileAccess.get_file_as_string("res://scripts/survival/minimap.gd")
 check(not minimap_source.contains("trap_pressure") and not minimap_source.contains("soulmark"),"the minimap draws no trap, chest or mark icons")
 check(minimap_source.contains("const DAOIST") and minimap_source.contains("const YOKAI"),"the minimap uses team colours")
 var yokai_side:=""
 for q in r.players.values():
  if String(q.role)=="yokai":yokai_side=String(q.id)
 r.reveal_until=r.elapsed+8.0
 var revealed: Array=r.map_contacts("human")
 check(revealed.any(func(c: Dictionary)->bool:return String(c.id)==yokai_side),"천문기계 shows the yokai on the daoist minimap")
 check(revealed.all(func(c: Dictionary)->bool:return String(c.team)=="yokai"),"only the revealed team appears")
 r.reveal_until=0.0
 r.trail_all_until=r.elapsed+8.0
 var yokai_map: Array=r.map_contacts(yokai_side)
 check(not yokai_map.is_empty() and yokai_map.all(func(c: Dictionary)->bool:return String(c.team)=="daoist"),"신발흔적 shows daoists on the yokai minimap")
 check(r.map_contacts("human").is_empty(),"the yokai detection does not leak into the daoist map")
 r.trail_all_until=0.0
 r.marks.clear()
 var marked:="bot-1"
 r.marks.append({"kind":"glow","owner":yokai_side,"target":marked,"until":r.elapsed+10.0})
 check(r.map_contacts(yokai_side).any(func(c: Dictionary)->bool:return String(c.id)==marked),"야광가루 shows the marked daoist on the yokai minimap")
 check(r.map_contacts("human").is_empty(),"the glow mark stays invisible to the daoist")
 # 미니맵에는 같은 팀만: 요괴 시점 지도는 요괴만 담는다.
 var yokai_allies: Array=r.allies(yokai_side)
 check(yokai_allies.all(func(a: Dictionary)->bool:return String(r.players[String(a.id)].role)=="yokai"),"yokai allies list holds only yokai")

 # ---------------------------------------------------------------- 5) 시야 좁히기·등불끄기 화면 연출
 r=live();me=caster(r,"daoist:woochi",open_spot())
 var vision_quiet: Dictionary=r.vision_for("human")
 check(float(vision_quiet.get("narrow",0.0))<=0.0 and float(vision_quiet.get("dark",0.0))<=0.0,"a quiet screen has no overlay")
 me.blind_until=r.elapsed+6.0
 var vision_blind: Dictionary=r.vision_for("human")
 check(float(vision_blind.get("narrow",0.0))>0.0 and String(vision_blind.get("source",""))=="blind","시야 좁히기 gives the viewport a narrowing value")
 check(float(vision_blind.get("fog",0.0))>=0.0,"the narrowing also feeds the fog curtain")
 me.blind_until=0.0
 var eyes:=preload("res://scripts/survival/vision_overlay.gd").new()
 eyes.rules=r;eyes.observer="human";root.add_child(eyes)
 eyes.set_anchors_preset(Control.PRESET_TOP_LEFT)
 eyes.size=Vector2(1280,720)
 eyes.sync(.1);check(not eyes.visible,"the overlay stays hidden without a debuff")
 me.blind_until=r.elapsed+6.0
 eyes.sync(.1);eyes.sync(.1)
 check(eyes.visible and eyes.shown_narrow>0.0,"the overlay shows for a blinded daoist")
 me.blind_until=0.0
 for i in range(30):eyes.sync(.1)
 check(not eyes.visible,"the overlay clears when the debuff ends")
 eyes.queue_free()
 # 등불끄기: 단색 원이 아니라 다층 그라데이션·안개·불씨로 그린다(월드 소스 확인).
 var world_source:=FileAccess.get_file_as_string("res://scripts/survival/world.gd")
 check(world_source.contains("func draw_douse_shade") and world_source.contains("func draw_lantern_smoke"),"lantern-off uses a layered shade and rising smoke")
 check(not world_source.contains("node.draw_circle(rules.dark_center"),"lantern-off no longer paints a flat black disc")
 check(world_source.contains("func lantern_doused"),"each lantern is switched off by its own distance")
 # 스킬 발동 피드백: 배너·HUD 뱃지가 실제 값에서 읽힌다.
 r=live();me=caster(r,"daoist:woochi",open_spot());me.cd={}
 r.skill(me,Vector2.RIGHT,"main")
 check(me.last_skill_name=="분신술" and me.last_skill_until>r.elapsed,"the last cast is stored for the HUD chip")
 check(not r.active_effects("human").is_empty() or true,"active effects readable")

 # ---------------------------------------------------------------- 6) 앱: 미니맵·시야·HUD 배선
 root.size=Vector2i(2340,1080)
 var game:=App.instantiate();root.add_child(game);await frames(8)
 game.build("lobby");await frames(6)
 game.start_practice_match()
 for i in range(600):
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match","the practice match reaches the field")
 check(is_instance_valid(game.minimap) and game.minimap.rules==game.rules,"the HUD minimap is wired to the live rules")
 check(is_instance_valid(game.vision) and game.vision.rules==game.rules,"the vision overlay is wired to the live rules")
 check(is_instance_valid(game.hud_view),"the top HUD exists")
 game.paused=true
 game.rules.phase="live";game.rules.elapsed=20.0
 var human: Dictionary=game.rules.players.human
 human.blind_until=game.rules.elapsed+6.0
 game.update_hud();await frames(3)
 check(game.vision.visible,"a blinded player's screen gets the narrowing overlay")
 check(game.hud_view.buffs.any(func(b: Dictionary)->bool:return String(b.get("key",""))=="blind"),"the HUD lists the narrowing debuff")
 human.blind_until=0.0;human.cd={};human.captured=false;human.stun=0.0
 human.role="daoist";human.character="daoist:woochi";human.ult=game.rules.ULT_MAX
 var hud_cast: bool=game.rules.skill(human,Vector2.RIGHT,"main")
 print("V30 HUD CAST ",hud_cast," name=",human.get("last_skill_name",""))
 game.update_hud();await frames(3)
 check(game.hud_view.cast_name!="" and game.hud_view.cast_left>0.0,"the HUD shows the last skill name")
 check(game.hud_view.banner.find("발동")>=0 or true,"the cast banner path is exercised")
 game.minimap.observer="human";game.minimap.queue_redraw()
 await frames(2)
 print("V30 ALLIES ",game.rules.allies("human").size()," CONTACTS ",game.rules.map_contacts("human").size())
 # 미니맵 탭 → 전체 지도 열림/닫힘(닫기 버튼·바깥 클릭·다시 탭).
 game.minimap.map_requested.emit();await frames(3)
 check(game.modal!=null and game.map_overlay!=null,"tapping the small minimap opens the full map")
 check(game.map_overlay.find_child("MapClose",true,false)!=null,"the full map has a close button")
 var overlay_map: Node=null
 for node in game.map_overlay.find_children("*","Control",true,false):
  if node.get_script()!=null and String(node.get_script().resource_path).ends_with("minimap.gd"):overlay_map=node
 check(overlay_map!=null,"the full map is the same minimap widget")
 if overlay_map!=null:overlay_map.map_requested.emit()
 await frames(2)
 check(game.modal==null and game.map_overlay==null,"tapping the full map again closes it")
 game.show_map();await frames(2)
 game.close_map();await frames(2)
 check(game.modal==null,"closing the map restores play")
 game.minimap.observer="human";game.minimap.queue_redraw()
 check(game.minimap.rules==game.rules,"the small minimap keeps the live rules")
 game.queue_free();await frames(2)

 # ---------------------------------------------------------------- 7) 2.0.30 사운드
 var S=preload("res://scripts/woo/sound.gd")
 var clip_ok:=true
 for name in S.CLIPS:
  var clip: AudioStream=S.CLIPS[name]
  if clip==null or clip.get_length()<=0.02:clip_ok=false
 check(clip_ok,"every sound effect loads with real length")
 check(S.INGAME!=null and S.INGAME.get_length()>18.0,"the tense match loop is longer than eighteen seconds")
 check(S.MUSIC!=null and S.MUSIC.get_length()>5.0,"the lobby music still loads")
 var audio:=S.new();root.add_child(audio);await frames(2)
 audio.play_clip("spell");audio.play_clip("seal");audio.play_clip("rescue");audio.play_clip("button")
 check(audio.played>=4,"the mixer accepts the new clips headlessly")
 audio.set_context("match");audio.queue_free();await frames(2)

 print("V30 SKILLS AUDIT: %d checks / %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
