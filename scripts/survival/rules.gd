extends RefCounted
const L=preload("res://scripts/survival/layout.gd")
const C=preload("res://scripts/survival/characters.gd")
var players: Dictionary={}
var rng:=RandomNumberGenerator.new()
var phase:="room"
var elapsed:=0.0
var countdown:=3.0
var winner:=""
var effects: Array=[]
var events: Array=[]
var circle_penalty_after:=INF
var circle_speed_factor:=1.0
var serial:=0
## 2.0.27: 캐릭터마다 대표 스킬·보조 스킬·궁극기 3개를 쓰고, 궁극기는 기운(ult)을
## 모아야 한다. 아래 값은 그 기운의 초당 충전량과 최대치다.
const ULT_MAX=100.0
const ULT_RATE=1.55
## 기력 회복 구슬 상태({p, ready}). ready<=elapsed 이면 다시 생긴 구슬이다.
var orbs: Array=[]
var selection_left:=25.0
## 자동 배정이 고를 수 있는 캐릭터 목록(참가자별). 비어 있으면 전체 로스터.
var restricted: Dictionary={}
func restrict_choices(id: String,ids: Array) -> void:
 restricted[id]=ids.duplicate()
## 요괴 수(기본 2). 8인 방에서 도사2:요괴6 구성을 고르면 6이 된다.
var yokai_count:=2
## 플레이어(휴먼)의 희망 진영: any / daoist / yokai. 비율(도사6:요괴2)은 그대로 두고
## 자리만 바꿔 배정한다.
var preferred_role:="any"
var selection_elapsed:=0.0
## 전원 확정 뒤 짧은 준비 카운트다운(2.0.27: 확정 즉시 시작하지 않는다).
const READY_SECONDS=3.0
const READY_ALL_BONUS=1.0
var ready_left:=0.0
## 문이 열린 시각(초). world.gd는 이 값으로 문짝과 지붕을 움직인다.
var doors: Dictionary={"front":0.0,"back":0.0}
## 2.0.27 능력이 남기는 것들 — 덫·미끼·표식·표적 표식·전역 효과.
var traps: Array=[]
var marks: Array=[]
var pings: Array=[]
var dark_until:=0.0
var dark_center:=Vector2.ZERO
var dark_radius:=0.0
var map_dark_until:=0.0
var reveal_until:=0.0
var trail_all_until:=0.0
var lantern_until: Dictionary={}
func burst(at: Vector2,kind: String,duration: float,extra: Dictionary={}) -> void:
 serial+=1
 var entry:={"id":serial,"kind":kind,"position":at,"born":elapsed,"until":elapsed+duration}
 entry.merge(extra,true)
 effects.append(entry)
func _init(seed_value: int=0) -> void:
 if seed_value==0:rng.randomize()
 else:rng.seed=seed_value
func add(id: String,name: String,daoist: String,yokai: String) -> bool:
 if phase!="room" or players.size()>=8 or C.find(daoist).is_empty() or C.find(yokai).is_empty():return false
 players[id]={"id":id,"name":name,"choices":{"daoist":daoist,"yokai":yokai},"role":"","character":"","position":L.SPAWN,"home":L.SPAWN,"sealed_pos":L.SPAWN,"facing":2,"intent":Vector2.ZERO,"running":false,"stamina":100.0,"exhausted":false,"wobble":0.0,"form_origin":L.SPAWN,"jump":0.0,"height":0.0,"ground":L.SPAWN,"cd":{},"buff":{},"captured":false,"deadline":0.0,"eliminated":false,"immune":0.0,"rescue":"","progress":0.0,"origin":L.SPAWN,"outside":0.0,"form":"","copy":"","trail":[],"stride":0.0,"alive_seconds":0.0,"stagger":0.0,"lives":3,"stats":{"seals":0,"misses":0,"rescues":0,"lost":0},"confirmed":false,"ready":id!="human","color":players.size(),
  "ult":0.0,"stun":0.0,"slow_until":0.0,"slow_factor":1.0,"speed_until":0.0,"speed_factor":1.0,"seal_bonus":0.0,"mark":Vector2.INF,"last_hurt":0.0,"blind_until":0.0,"hint":""}
 return true
## 시작 직후 요괴가 바로 봉인하지 못하도록 주는 유예(초).
const SEAL_GRACE=6.0
## ---------------------------------------------------------------- 봉인 판정
## 《도망가 친구들》 방식: 미둔갑 도사는 몸이 닿는 순간 봉인되고(버튼 없음),
## 사물로 둔갑한 도사만 요괴의 '확인' 타격으로 잡힌다.
const CONTACT_RADIUS=27.0
const CONFIRM_REACH=62.0
const SEAL_RECOVER=1.5
const MISS_RECOVER=2.0
const SHIELD_IMMUNE=1.2
const SHIELD_KNOCK=62.0
const SEAL_DEADLINE=10.0
const RESCUE_TIME=2.5
const LIVES=3
const REVIVE_IMMUNE=2.5
func start() -> bool:
 if phase!="room" or players.size() not in [6,8]:return false
 if not players.values().all(func(p: Dictionary)->bool:return p.ready):return false
 var ids: Array=players.keys()
 for i in range(ids.size()-1,0,-1):
  var j:=rng.randi_range(0,i);var value=ids[i];ids[i]=ids[j];ids[j]=value
 var daoist_index:=0;var yokai_index:=0
 for i in range(ids.size()):
  var p: Dictionary=players[ids[i]];p.role="yokai" if i<yokai_count else "daoist";p.character=""
  var seat:=yokai_index if p.role=="yokai" else daoist_index
  var spot: Vector2=L.spawns_for(p.role,seat)
  if p.role=="yokai":yokai_index+=1
  else:daoist_index+=1
  p.position=spot;p.ground=spot;p.origin=spot;p.home=spot;p.form_origin=spot;p.intent=Vector2.ZERO;p.facing=6 if p.role=="daoist" else 2
 apply_preference()
 orbs=[]
 for spot in L.ORBS:orbs.append({"p":spot,"ready":0.0})
 traps=[];marks=[];pings=[];dark_until=0.0;map_dark_until=0.0;reveal_until=0.0;trail_all_until=0.0;lantern_until.clear()
 phase="selection";selection_left=25;selection_elapsed=0;ready_left=0.0;return true
## 희망 진영이 있으면 휴먼과 반대편 한 명의 역할·자리를 맞바꾼다(구성 비율 유지).
func apply_preference() -> void:
 if not players.has("human") or preferred_role not in ["daoist","yokai"]:return
 var human: Dictionary=players["human"]
 if human.role==preferred_role:return
 for p in players.values():
  if p.id=="human" or p.role!=preferred_role:continue
  var role: String=human.role
  human.role=p.role;p.role=role
  for key in ["position","ground","origin","form_origin","facing"]:
   var value=human[key];human[key]=p[key];p[key]=value
  return

func select_character(id: String,character_id: String) -> bool:
 if phase!="selection" or not players.has(id) or players[id].confirmed:return false
 var spec:=C.find(character_id)
 if spec.is_empty() or spec.team!=players[id].role:return false
 players[id].character=character_id;return true
func confirm_character(id: String) -> bool:
 if phase!="selection" or not players.has(id) or players[id].confirmed:return false
 if C.find(players[id].character).is_empty():return false
 players[id].confirmed=true
 _check_ready()
 return true
## 2.0.27: 전원 확정이어도 곧바로 맵으로 점프하지 않고 짧은 준비 카운트다운을 둔다.
func _check_ready() -> void:
 if phase!="selection":return
 if not players.values().all(func(p: Dictionary)->bool:return p.confirmed):return
 phase="ready";ready_left=READY_SECONDS;event("readyprompt","")
func ready_remaining() -> float:
 return maxf(0.0,ready_left) if phase=="ready" else 0.0
func selection_view(id: String) -> Array:
 if not players.has(id):return []
 var out: Array=[]
 for p in players.values():
  if p.role==players[id].role:out.append({"id":p.id,"name":p.name,"character":p.character,"confirmed":p.confirmed})
 return out
func ready_map() -> void:
 if phase=="loading":phase="countdown";countdown=3
func available(p: Dictionary) -> bool:return phase=="live" and not p.captured and not p.eliminated
func event(kind: String,actor: String,target: String="") -> void:
 events.append({"kind":kind,"actor":actor,"target":target,"time":elapsed})
func command(id: String,op: String,data: Dictionary={}) -> bool:
 if not players.has(id):return false
 var p: Dictionary=players[id]
 if op=="cancel_rescue":p.rescue="";p.progress=0;return true
 if not available(p):return false
 if op=="move":
  var v: Vector2=data.get("vector",Vector2.ZERO)
  if not v.is_finite():return false
  p.intent=v.limit_length(1)
  if v.length()>.06:p.facing=preload("res://scripts/wardrobe/direction.gd").quantize(v.normalized(),p.facing)
  if v.length()>.05:p.rescue="";p.progress=0
  return true
 if op=="run":p.running=bool(data.get("held",false));return true
 if op=="jump":
  if p.jump>0 or not p.rescue.is_empty():return false
  if p.form!="":p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.4)
  p.jump=.8;p.ground=p.position;return true
 if op=="seal":return seal(p)
 if op=="interact":
  if p.form!="":
   p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
  var door:=L.door_near(p.position,70)
  if door!="":doors[door]=elapsed+1.4;burst(L.door(door).center,"fx_door",.6);event("door",p.id,door);return true
  var near:=L.object_near(p.position,84)
  if near.is_empty():near=animal_near(p.position,84)
  if near.is_empty():return false
  # 형상 추출: 누구나 사물·동물 무리에 섞여 숨을 수 있는 공용 둔갑.
  if float(p.cd.get("disguise",0))>elapsed:return false
  p.form=near.kind;p.form_origin=near.p;p.wobble=0;p.buff.transform=elapsed+9;p.cd.disguise=elapsed+12
  burst(p.position,"fx_poof",.6);event("transform",p.id,near.kind);return true
 if op=="rescue":
  var target: String=data.get("target","")
  if p.role!="daoist" or not players.has(target):return false
  var q: Dictionary=players[target]
  if not q.captured or q.eliminated or p.position.distance_to(q.position)>58 or not L.line(p.position,q.position):return false
  if p.rescue!=target:p.rescue=target;p.progress=0;p.origin=p.position
  p.intent=Vector2.ZERO;return true
 if op=="skill":return skill(p,data.get("aim",Vector2.from_angle(p.facing*PI/4)),String(data.get("slot","main")))
 return false
## 요괴의 '확인' 타격: 근처 사물 중 둔갑한 도사를 쳐서 잡는다.
func seal(p: Dictionary) -> bool:
 if p.role!="yokai" or float(p.cd.get("seal",0))>elapsed:return false
 # 기관인형·가짜 미끼를 먼저 친다.
 for e in effects:
  if e.kind in ["decoy","fake_rescue"] and e.get("owner","")!=p.id and p.position.distance_to(e.position)<CONFIRM_REACH+8:
   e.until=0.0;p.cd.seal=elapsed+MISS_RECOVER;p.stats.misses+=1
   burst(e.position,"fx_poof",.6);event("miss",p.id);return true
 var q: Dictionary={};var best:=CONFIRM_REACH;var forward:=Vector2.from_angle(p.facing*PI/4)
 for candidate in players.values():
  if candidate.role!="daoist" or candidate.captured or candidate.eliminated or candidate.immune>elapsed:continue
  if candidate.form=="":continue
  var delta: Vector2=candidate.position-p.position;var distance:=delta.length()
  if distance>best:continue
  if distance>=8 and forward.dot(delta.normalized())<.5:continue
  if not L.line(p.position,candidate.position):continue
  q=candidate;best=distance
 if q.is_empty():
  p.cd.seal=elapsed+MISS_RECOVER;p.stagger=elapsed+.25;p.stats.misses+=1
  serial+=1;effects.append({"id":serial,"kind":"miss","position":p.position,"born":elapsed,"until":elapsed+.5,"cosmetic":C.look(p.character),"facing":p.facing})
  event("miss",p.id);return true
 serial+=1;effects.append({"id":serial,"kind":"seal","position":q.position,"born":elapsed,"until":elapsed+.5,"cosmetic":C.look(p.character),"facing":p.facing})
 seal_hit(p,q);return true
## 몸이 닿은 미둔갑 도사를 버튼 입력 없이 즉시 봉인한다.
func contact_seal() -> void:
 for p in players.values():
  if p.role!="yokai" or not available(p):continue
  if float(p.cd.get("seal",0))>elapsed:continue
  var q: Dictionary={};var best:=CONTACT_RADIUS
  for candidate in players.values():
   if candidate.role!="daoist" or candidate.captured or candidate.eliminated or candidate.immune>elapsed:continue
   if candidate.form!="":continue
   var distance: float=p.position.distance_to(candidate.position)
   if distance>best or not L.line(p.position,candidate.position):continue
   q=candidate;best=distance
  if q.is_empty():continue
  serial+=1;effects.append({"id":serial,"kind":"seal","position":q.position,"born":elapsed,"until":elapsed+.5,"cosmetic":C.look(p.character),"facing":p.facing})
  seal_hit(p,q)
## 봉인 1회 공통 처리: 호신부 방어 → 둔갑 해제 → 봉인 + 요괴 후딜.
func seal_hit(p: Dictionary,q: Dictionary) -> bool:
 p.cd.seal=elapsed+SEAL_RECOVER;p.stagger=elapsed+.35
 if q.buff.get("shield",0)>elapsed or q.buff.get("lifelamp",0)>elapsed:
  q.buff.erase("shield");q.immune=elapsed+SHIELD_IMMUNE;q.intent=Vector2.ZERO
  var push: Vector2=q.position-p.position
  if push.length()<.01:push=Vector2.from_angle(p.facing*PI/4)
  q.position=L.move(q.position,q.position+push.normalized()*SHIELD_KNOCK);q.ground=q.position
  burst(q.position,"fx_talisman",.6,{"facing":q.facing});event("blocked",p.id,q.id)
  return false
 if q.form!="":q.form="";q.buff.erase("transform");burst(q.position,"fx_poof",.45)
 q.intent=Vector2.ZERO;q.running=false;q.jump=0;q.height=0;q.rescue="";q.progress=0
 q.form="";q.buff.erase("transform")
 q.sealed_pos=q.position
 p.stats.seals+=1;event("seal",p.id,q.id)
 q.captured=true;q.deadline=elapsed+SEAL_DEADLINE+float(q.get("seal_bonus",0.0));q.seal_bonus=0.0
 return true
## ---------------------------------------------------------------- 능력
## 슬롯(main/sub/ult)을 받아 그 캐릭터의 실제 능력을 실행한다.
func skill(p: Dictionary,aim: Vector2,slot: String="main") -> bool:
 var spec: Dictionary=C.ability(p.character,slot)
 if spec.is_empty():return false
 var id: String=String(spec.get("skill",""))
 if id=="":return false
 if slot=="ult":
  if float(p.get("ult",0.0))<ULT_MAX or p.cd.get(id,0)>elapsed:return false
 else:
  if p.cd.get(id,0)>elapsed:return false
 if not aim.is_finite():return false
 if aim.length()<.01:aim=Vector2.from_angle(p.facing*PI/4)
 aim=aim.normalized();p.facing=posmod(roundi(aim.angle()/(PI/4)),8)
 if p.stun>elapsed:return false
 if not _effect(p,id,aim):return false
 p.cd[id]=elapsed+float(spec.get("cd",12.0))
 if slot=="ult":p.ult=0.0
 event("skill",p.id,id);event("skill_slot",p.id,slot)
 return true
## 능력 하나의 실제 도술. 성공하면 true(쿨타임 소모).
func _effect(p: Dictionary,id: String,aim: Vector2) -> bool:
 match id:
  "transform","disguise":
   if p.form!="":
    p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
   var nearest: Dictionary=L.object_near(p.position,90)
   if nearest.is_empty():nearest=animal_near(p.position,90)
   if nearest.is_empty():return false
   p.form=nearest.kind;p.form_origin=nearest.p;p.wobble=0;p.buff.transform=elapsed+9
   burst(p.position,"fx_poof",.6,{"facing":p.facing});event("transform",p.id,nearest.kind);return true
  "clone":
   burst(p.position,"fx_ink",.5)
   serial+=1;effects.append({"id":serial,"kind":"clone","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"character":p.character,"born":elapsed,"until":elapsed+8})
   burst(p.position,"fx_shadow",.55,{"facing":p.facing});return true
  "painting":
   p.buff.painting=elapsed+4.0;p.immune=maxf(p.immune,elapsed+4.0)
   p.buff.stealth=elapsed+4.0
   burst(p.position,"fx_ink",1.0,{"big":true});burst(p.position,"fx_talisman",.8,{"facing":p.facing});return true
  "wallhop":
   if not _leap(p,aim,190.0):return false
   burst(p.position,"fx_goldwave",.6);return true
  "windstep":
   p.speed_until=elapsed+5.0;p.speed_factor=1.7
   burst(p.position,"fx_wind",.8,{"facing":p.facing});return true
  "eightleap":
   var landed:=true
   for i in range(3):
    var direction:=aim.rotated(i*PI/4)
    burst(p.position,"fx_shadow",.5,{"facing":p.facing})
    serial+=1;effects.append({"id":serial,"kind":"afterimage","position":p.position,"facing":p.facing,"born":elapsed,"until":elapsed+.5,"cosmetic":C.look(p.character),"character":p.character})
    if not _leap(p,direction,130.0):landed=false
   p.immune=maxf(p.immune,elapsed+.6)
   burst(p.position,"fx_goldwave",.8);return landed
  "puppet":
   serial+=1;effects.append({"id":serial,"kind":"decoy","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"character":p.character,"born":elapsed,"until":elapsed+9})
   burst(p.position,"fx_gear",.9);return true
  "trap":
   traps.append({"kind":"pressure","owner":p.id,"pos":p.position,"until":elapsed+30.0,"radius":36.0,"armed":true})
   burst(p.position,"fx_trap",.7);return true
  "astrolabe":
   reveal_until=elapsed+8.0
   burst(p.position,"fx_astrolabe",1.4,{"big":true});return true
  "lifelamp":
   p.buff.lifelamp=elapsed+8.0
   for q in players.values():
    if q.role!="daoist" or q.eliminated or q.id==p.id:continue
    if q.position.distance_to(p.position)>280:continue
    q.buff.lifelamp=elapsed+4.0;q.speed_until=elapsed+4.0;q.speed_factor=1.25
    burst(q.position,"fx_lotus",.8)
   burst(p.position,"fx_lotus",1.1);
   # 선한 기운은 봉인 한 번을 막는 보호막도 겸한다.
   p.buff.shield=maxf(float(p.buff.get("shield",0.0)),elapsed+8.0)
   return true
  "deathflower":
   p.buff.shield=elapsed+8.0;p.buff.deathflower=elapsed+12.0;p.seal_bonus=maxf(float(p.seal_bonus),6.0)
   burst(p.position,"fx_chain",1.0);return true
  "returnpath":
   var target: Dictionary=_distressed_ally(p)
   if target.is_empty():return false
   var spot: Vector2=target.position
   burst(p.position,"fx_goldwave",.7)
   p.position=L.safe(spot+Vector2.from_angle(rng.randf()*TAU)*48.0);p.ground=p.position;p.origin=p.position
   p.immune=maxf(p.immune,elapsed+2.0);p.buff.shield=elapsed+4.0
   if target.role=="daoist":
    target.buff.shield=elapsed+3.0
    if target.captured:target.deadline+=3.0
   burst(p.position,"fx_lotus",1.2);event("warp",p.id);return true
  "ghostgate":
   p.buff.ghostgate=elapsed+6.0
   burst(p.position,"fx_ghostgate",1.2);return true
  "soulmark":
   p.mark=p.position
   marks=marks.filter(func(m: Dictionary)->bool:return String(m.owner)!=p.id)
   marks.append({"owner":p.id,"pos":p.position,"until":elapsed+600.0})
   burst(p.position,"fx_soulmark",1.2,{"owner":p.id});return true
  "underworldgate":
   if not (p.mark as Vector2).is_finite():return false
   var destination: Vector2=p.mark
   burst(p.position,"fx_darkness",.8)
   p.position=L.safe(destination);p.ground=p.position;p.origin=p.position;p.immune=maxf(p.immune,elapsed+2.0)
   burst(p.position,"fx_ghostgate",1.0);event("warp",p.id);return true
  "mimic":
   var targets:=visible(p.id).filter(func(a: Dictionary)->bool:return a.id!="" and a.id!=p.id)
   if targets.is_empty():
    # 벽너머라도 바로 옆이면 겉모습은 훔칠 수 있다.
    for q in players.values():
     if q.id==p.id or q.eliminated or q.captured:continue
     if q.position.distance_to(p.position)<=140:targets.append({"id":q.id,"position":q.position})
   targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return p.position.distance_to(a.position)<p.position.distance_to(b.position))
   if targets.is_empty():return false
   p.copy=targets[0].id;p.buff.mimic=elapsed+9
   burst(p.position,"fx_foxfire",.8);return true
  "foxscent":
   var charmed:=0
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    if q.position.distance_to(p.position)>240:continue
    q.slow_until=elapsed+4.0;q.slow_factor=.55;charmed+=1
    burst(q.position,"fx_foxfire",.9)
   burst(p.position,"fx_foxfire",1.2)
   return true
  "foxdream":
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    if q.position.distance_to(p.position)>340:continue
    q.blind_until=elapsed+7.0
    var phantom: Vector2=q.position+Vector2.from_angle(rng.randf()*TAU)*90.0
    serial+=1;effects.append({"id":serial,"kind":"decoy","owner":p.id,"position":L.safe(phantom),"facing":q.facing,"cosmetic":C.look(p.character),"character":p.character,"born":elapsed,"until":elapsed+4.0,"phantom":true})
    burst(q.position,"fx_foxfire",1.2)
   burst(p.position,"fx_mist",1.4);return true
  "voicemimic":
   var decoy_at:=L.safe(p.position+aim*180.0)
   serial+=1;effects.append({"id":serial,"kind":"fake_rescue","owner":p.id,"position":decoy_at,"born":elapsed,"until":elapsed+6.0})
   burst(decoy_at,"fx_sound",1.4)
   var near:=_nearest_role(p,"daoist")
   if not near.is_empty():
    near.buff.revealed=elapsed+3.0
    pings.append({"pos":near.position,"until":elapsed+3.0,"color":Color("ffd08a"),"target":near.id})
   return true
  "soundhunt":
   p.buff.sense=elapsed+4.0
   burst(p.position,"fx_ghost",.9);return true
  "mountaingrowl":
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    if q.position.distance_to(p.position)>340:continue
    var push: Vector2=q.position-p.position
    if push.length()<1.0:push=Vector2.from_angle(rng.randf()*TAU)
    q.position=L.move(q.position,q.position+push.normalized()*110.0);q.ground=q.position
    q.stun=elapsed+.6;q.intent=Vector2.ZERO
    burst(q.position,"fx_howl",.9)
   p.speed_until=elapsed+6.0;p.speed_factor=1.5
   burst(p.position,"fx_howl",1.6,{"big":true});return true
  "mischief":
   var flipped:=0
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated or q.form=="":continue
    if q.position.distance_to(p.position)>280:continue
    q.form="";q.buff.erase("transform");q.stun=elapsed+.5;flipped+=1
    burst(q.position,"fx_goblinfire",.8);event("untransform",q.id)
   burst(p.position,"fx_goblinfire",1.0)
   return true
  "faketreasure":
   traps.append({"kind":"treasure","owner":p.id,"pos":p.position,"until":elapsed+30.0,"radius":44.0,"armed":true})
   burst(p.position,"fx_goldwave",.8);return true
  "goblinfest":
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    if q.position.distance_to(p.position)>210:continue
    if q.form!="":q.form="";q.buff.erase("transform");event("untransform",q.id)
    var push: Vector2=q.position-p.position
    if push.length()<1.0:push=Vector2.from_angle(rng.randf()*TAU)
    q.position=L.move(q.position,q.position+push.normalized()*90.0);q.ground=q.position
    q.stun=elapsed+.4;burst(q.position,"fx_goblinfire",1.0)
   burst(p.position,"fx_goblinfire",1.8,{"big":true});return true
  "douse":
   dark_until=elapsed+9.0;dark_center=p.position;dark_radius=330.0
   lantern_until["all"]=elapsed+9.0
   burst(p.position,"fx_darkness",1.2,{"big":true});return true
  "blackvision":
   var victim:=_nearest_role(p,"daoist")
   if victim.is_empty():return false
   victim.blind_until=elapsed+6.0
   burst(victim.position,"fx_mist",1.2);return true
  "moonlessnight":
   map_dark_until=elapsed+8.0;p.buff.stealth=elapsed+8.0
   burst(p.position,"fx_darkness",2.0,{"big":true});return true
  "shoeprints":
   p.buff.sense=elapsed+8.0;trail_all_until=elapsed+8.0
   burst(p.position,"fx_ghost",1.0);return true
  "glowpowder":
   var prey:=_nearest_role(p,"daoist")
   if prey.is_empty():return false
   prey.buff.glowing=elapsed+10.0
   marks=marks.filter(func(m: Dictionary)->bool:return String(m.get("kind","mark"))!="glow" or String(m.owner)!=p.id)
   marks.append({"kind":"glow","owner":p.id,"target":prey.id,"until":elapsed+10.0})
   burst(prey.position,"fx_powder",1.2);return true
  "footprintmap":
   trail_all_until=elapsed+10.0;p.buff.sense=elapsed+10.0
   burst(p.position,"fx_astrolabe",1.4);return true
 return false
## 담장·장애물을 넘는 도약. 착지할 수 있는 가장 먼 지점으로 옮긴다.
func _leap(p: Dictionary,aim: Vector2,distance: float) -> bool:
 var landed:=false
 var step:=distance
 while step>24:
  var spot: Vector2=p.position+aim*step
  if L.can_stand(spot):
   burst(p.position,"fx_wind",.5,{"facing":p.facing})
   p.position=spot;p.ground=spot;p.jump=.5;p.height=26
   landed=true;break
  step-=18
 if not landed:
  p.position=L.move(p.position,p.position+aim*distance*.6);p.ground=p.position
 return landed or true
func _nearest_role(p: Dictionary,role: String) -> Dictionary:
 var best: Dictionary={};var gap:=1e9
 for q in players.values():
  if q.role!=role or q.eliminated or q.id==p.id:continue
  var d: float=p.position.distance_to(q.position)
  if d<gap:gap=d;best=q
 return best
func _distressed_ally(p: Dictionary) -> Dictionary:
 var best: Dictionary={};var score: float=-1e9
 for q in players.values():
  if q.role!="daoist" or q.eliminated or q.id==p.id:continue
  var value: float=0.0
  if q.captured:value=300.0
  elif q.lives<int(LIVES):value=100.0-float(q.lives)*10.0
  elif q.last_hurt>elapsed-8.0:value=40.0
  if value<=0.0:continue
  value-=p.position.distance_to(q.position)*.01
  if value>score:score=value;best=q
 return best
## 둔갑 대상 동물(맵을 걷는 고양이·강아지) 근처인지.
func animal_near(p: Vector2,distance: float=84.0) -> Dictionary:
 var best: Dictionary={};var gap:=distance
 for entry in walkers:
  var d: float=p.distance_to(entry.p)
  if d<gap:gap=d;best={"kind":String(entry.kind),"p":entry.p}
 return best
func circle() -> Dictionary:
 var centers: Array[Vector2]=[Vector2(1700,1360),Vector2(1700,1360),Vector2(1700,1370),Vector2(1710,1380)]
 var radii: Array[float]=[2700,1750,1150,620]
 var stage:=0 if elapsed<180 else (1 if elapsed<360 else (2 if elapsed<480 else 3))
 var next:=mini(3,stage+1);var due:=180.0 if stage==0 else (360.0 if stage==1 else (480.0 if stage==2 else 600.0))
 var blend:=clampf((elapsed-([0,180,360,480][stage]))/30.0,0,1) if stage>0 else 1.0
 return {"stage":stage,"center":centers[stage-1].lerp(centers[stage],blend) if stage>0 else centers[0],"radius":lerpf(radii[stage-1],radii[stage],blend) if stage>0 else radii[0],"next_center":centers[next],"next_radius":radii[next],"until":maxf(0,due-elapsed)}
## 맵을 걷는 고양이·강아지. rules가 위치의 권한자이며 world가 그린다.
var walkers: Array=[]
func build_walkers() -> void:
 walkers=[]
 var routes: Array=[
  {"kind":"cat","path":[Vector2(690,1060),Vector2(980,900),Vector2(1300,880),Vector2(1620,860),Vector2(1900,900),Vector2(2200,960),Vector2(2400,1100),Vector2(2100,1240),Vector2(1700,1240),Vector2(1300,1200),Vector2(1000,1140)]},
  {"kind":"dog","path":[Vector2(1560,1800),Vector2(1900,1960),Vector2(2200,2100),Vector2(2520,2200),Vector2(2820,2020),Vector2(2600,1800),Vector2(2200,1740),Vector2(1860,1660)]},
  {"kind":"cat","path":[Vector2(2750,980),Vector2(2960,1120),Vector2(3080,1360),Vector2(2920,1600),Vector2(2660,1500),Vector2(2580,1240)]},
  {"kind":"dog","path":[Vector2(600,1900),Vector2(880,2050),Vector2(1150,2250),Vector2(900,2380),Vector2(640,2200)]}]
 for i in range(routes.size()):
  var route: Dictionary=routes[i]
  var path: Array=route.path
  walkers.append({"id":"animal-%d"%i,"kind":String(route.kind),"p":path[0],"path":path,"next":1,"facing":0,"phase":0.0,"speed":31.0 if route.kind=="cat" else 42.0,"moving":true,"wait":0.0})
func _tick_walkers(delta: float) -> void:
 for entry in walkers:
  if float(entry.wait)>0.0:
   entry.wait=float(entry.wait)-delta;entry.moving=false;continue
  var path: Array=entry.path
  var goal: Vector2=path[int(entry.next)%path.size()]
  var step: Vector2=(goal-entry.p)
  if step.length()<6.0:
   entry.next=(int(entry.next)+1)%path.size()
   if rng.randf()<.22:entry.wait=rng.randf_range(.8,2.6)
   continue
  var direction:=step.normalized()
  entry.facing=posmod(roundi(direction.angle()/(PI/4)),8)
  entry.p=(entry.p as Vector2)+direction*float(entry.speed)*delta
  entry.phase=float(entry.phase)+delta*6.0
  entry.moving=true
## 둔갑한 도사가 동물이면 그 동물의 걷기 박자를 그대로 쓴다(1이면 걷기 프레임).
func animal_gait(kind: String,seed_phase: float) -> float:
 return .5+.5*sin(seed_phase)
func tick(delta: float) -> void:
 delta=clampf(delta,0,.1)
 if phase=="selection":
  selection_elapsed+=delta;selection_left=maxf(0,25-selection_elapsed)
  for p in players.values():
   if p.confirmed:continue
   if selection_left<=.00001 or (p.id!="human" and selection_elapsed>=1.2+p.color*.35):
    if C.find(p.character).is_empty():
     var pool: Array=restricted.get(p.id,[])
     if pool.is_empty():p.character=C.catalog(p.role)[rng.randi_range(0,C.catalog(p.role).size()-1)].id
     else:p.character=String(pool[rng.randi_range(0,pool.size()-1)])
    confirm_character(p.id)
  return
 if phase=="ready":
  ready_left=maxf(0,ready_left-delta)
  if ready_left<=0:phase="loading"
  return
 if phase=="countdown":
  countdown=maxf(0,countdown-delta)
  if countdown<=0:
   phase="live"
   build_walkers()
   for p in players.values():
    if p.role=="yokai":p.cd["seal"]=maxf(float(p.cd.get("seal",0.0)),elapsed+SEAL_GRACE)
  return
 if phase!="live":return
 elapsed=minf(600,elapsed+delta)
 var zone:=circle()
 _tick_walkers(delta)
 for p in players.values():
  if p.eliminated:continue
  p.alive_seconds=elapsed
  # 궁극기 기운 충전
  p.ult=minf(ULT_MAX,float(p.get("ult",0.0))+ULT_RATE*delta)
  if p.captured and elapsed>=p.deadline:
   p.captured=false;p.deadline=0.0;p.rescue="";p.progress=0
   p.lives=maxi(0,int(p.lives)-1);p.stats.lost=maxi(0,int(p.stats.get("lost",0)))+1;event("lose_life",p.id)
   if p.lives<=0:
    p.eliminated=true;event("eliminate",p.id);continue
   # 2.0.27: 시작 지점이 아니라 봉인됐던 바로 그 자리에서 다시 일어난다.
   var sealed_spot: Vector2=p.sealed_pos
   p.position=sealed_spot if L.can_stand(sealed_spot) else L.safe(sealed_spot)
   p.ground=p.position;p.origin=p.position;p.immune=elapsed+REVIVE_IMMUNE
   p.intent=Vector2.ZERO;p.running=false;p.jump=0;p.height=0;p.stamina=100;p.exhausted=false
   burst(p.position,"fx_lotus",1.0)
   event("revive",p.id);continue
  if p.captured:continue
  if p.form!="" and p.buff.get("transform",0)<=elapsed:
   p.form="";p.buff.erase("transform");event("untransform",p.id)
  var previous: Vector2=p.position
  p.outside=p.outside+delta if p.position.distance_to(zone.center)>zone.radius else 0.0
  if p.exhausted and p.stamina>=25:p.exhausted=false
  var fast: bool=p.running and p.stamina>0 and not p.exhausted and p.intent.length()>.05
  p.stamina=clampf(p.stamina+(-25 if fast else 18)*delta,0,100)
  if p.stamina<=0:p.exhausted=true
  if p.jump>0:
   p.jump=maxf(0,p.jump-delta);p.height=sin((.8-p.jump)/.8*PI)*36
  else:p.height=0
  var speed: float=C.find(p.character).run_speed if fast else C.find(p.character).speed
  if p.stagger>elapsed or p.stun>elapsed:speed=0.0
  if p.slow_until>elapsed:speed*=float(p.slow_factor)
  if p.speed_until>elapsed:speed*=float(p.speed_factor)
  if p.outside>circle_penalty_after:speed*=circle_speed_factor
  if p.form!="":speed*=(.98 if String(p.form) in ["cat","dog"] else .88)
  if p.buff.get("painting",0)>elapsed:
   # 그림 속 차원: 벽을 통과해 곧장 이동한다(맵 밖으로는 못 나간다).
   p.position+=(p.intent*speed*1.15*delta)
   p.position=Vector2(clampf(p.position.x,90,L.SIZE.x-90),clampf(p.position.y,100,L.SIZE.y-100))
  else:
   p.position=L.move(p.position,p.position+p.intent*speed*delta,p.height>12)
   if p.jump<=0 and not L.can_stand(p.position):p.position=L.safe(p.position)
  if L.can_stand(p.position):p.ground=p.position
  var distance: float=p.position.distance_to(previous);p.stride+=distance
  if distance>0 and (p.trail.is_empty() or p.position.distance_to(p.trail[-1].position)>=18):p.trail.append({"position":p.position,"time":elapsed,"facing":p.facing})
  while not p.trail.is_empty() and elapsed-p.trail[0].time>6:p.trail.pop_front()
 contact_seal()
 _tick_traps(delta)
 for orb in orbs:
  if float(orb.ready)>elapsed:continue
  for p in players.values():
   if not available(p) or p.position.distance_to(orb.p)>L.ORB_RADIUS:continue
   p.stamina=100.0;p.exhausted=false;orb.ready=elapsed+L.ORB_RESPAWN
   burst(orb.p,"fx_ghost",.7);event("orb",p.id);break
 for p in players.values():
  if p.rescue=="":continue
  var q: Dictionary=players.get(p.rescue,{})
  if not available(p) or q.is_empty() or not q.captured or q.eliminated or p.position.distance_to(p.origin)>.5 or p.position.distance_to(q.position)>58:p.rescue="";p.progress=0;continue
  p.progress+=delta
  if p.progress>=RESCUE_TIME-0.00001:
   q.captured=false;q.immune=elapsed+3;p.stats.rescues+=1;event("rescue",p.id,q.id);p.rescue="";p.progress=0
   burst(q.position,"fx_lotus",.9)
 for e in effects:
  if e.kind in ["clone","decoy"]:e.position=L.move(e.position,e.position+Vector2.from_angle(float(e.facing)*PI/4)*(0 if e.kind=="decoy" else 36)*delta)
 effects=effects.filter(func(e: Dictionary)->bool:return e.until>elapsed)
 traps=traps.filter(func(t: Dictionary)->bool:return float(t.until)>elapsed and bool(t.armed))
 marks=marks.filter(func(m: Dictionary)->bool:return float(m.get("until",0.0))>elapsed)
 pings=pings.filter(func(m: Dictionary)->bool:return float(m.until)>elapsed)
 var alive:=players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.eliminated).size()
 if alive==0:finish("yokai")
 elif elapsed>=600:finish("daoist")
## 덫: 요괴는 압력기관, 도사는 가짜 보물에 걸린다.
func _tick_traps(delta: float) -> void:
 for t in traps:
  if not bool(t.armed):continue
  for p in players.values():
   if not available(p):continue
   if t.kind=="pressure" and p.role!="yokai":continue
   if t.kind=="treasure" and p.role!="daoist":continue
   if p.position.distance_to(t.pos)>float(t.radius):continue
   t.armed=false
   if t.kind=="pressure":
    p.slow_until=elapsed+3.0;p.slow_factor=.45
    burst(t.pos,"fx_trap",1.0);event("trap",String(t.owner),p.id)
   else:
    p.stun=elapsed+3.0;p.intent=Vector2.ZERO
    burst(t.pos,"fx_goldwave",1.0);event("treasure",String(t.owner),p.id)
   break
func finish(team: String) -> void:
 phase="result";winner=team
 for p in players.values():p.intent=Vector2.ZERO;p.running=false;p.rescue="";p.progress=0
func visible(id: String) -> Array:
 if not players.has(id):return []
 var viewer: Dictionary=players[id];var result: Array=[]
 var see_through: bool=float(viewer.buff.get("ghostgate",0.0))>elapsed
 var blind: bool=float(viewer.get("blind_until",0.0))>elapsed
 var reach: float=360.0
 if blind:reach=150.0
 if reveal_until>elapsed and viewer.role=="daoist":reach=9999.0
 if foot_scope(viewer) and viewer.role=="yokai":reach=9999.0
 for p in players.values():
  if p.eliminated:continue
  var distance: float=viewer.position.distance_to(p.position)
  if p.id!=id and float(p.buff.get("stealth",0.0))>elapsed:continue
  if p.id!=id and distance>reach:continue
  if p.id!=id and not see_through and not L.line(viewer.position,p.position):continue
  var blocked:=false
  for e in effects:
   if e.kind=="smoke" and distance>85 and Geometry2D.get_closest_point_to_segment(e.position,viewer.position,p.position).distance_to(e.position)<115:blocked=true
  if blocked and p.id!=id:continue
  var source: Dictionary=players.get(p.copy,p) if p.buff.get("mimic",0)>elapsed else p
  result.append({"id":"" if p.form!="" and p.id!=id else p.id,"position":p.position,"form":p.form,"name":source.name,"role":source.role,"color":source.color,"cosmetic":C.look(source.character),"character":source.character,"facing":p.facing,"height":p.height,"moving":p.intent.length()>.05 and not p.captured,"captured":p.captured,"immune":p.immune>elapsed,"shield":p.buff.get("shield",0)>elapsed or p.buff.get("lifelamp",0)>elapsed,"revealed":float(p.buff.get("glowing",0.0))>elapsed or float(p.buff.get("revealed",0.0))>elapsed,"disguised":p.form!=""})
 return result
## 발자국·동선을 전부 비추는 효과가 켜져 있는지(요괴 시점).
func foot_scope(p: Dictionary) -> bool:
 return trail_all_until>elapsed
