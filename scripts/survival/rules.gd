extends RefCounted
## 2.0.34: 맵은 Maps가 정한다. L은 지금 맵의 레이아웃 스크립트(서원/강남역)이며,
## 충돌·스폰·둔갑 사물·기믹이 모두 그 맵 기준으로 움직인다.
const Maps=preload("res://scripts/survival/maps.gd")
const Gimmicks=preload("res://scripts/survival/gimmicks.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
const C=preload("res://scripts/survival/characters.gd")
var L: Script=Maps.SEOWON
var map_id: String="seowon"
var gimmicks: RefCounted
## 안전구역 밖 체류시간을 3초까지는 유지해 경계를 들락날락하는 악용을 막는다.
const OUTSIDE_GRACE=3.0
const OUTSIDE_REVEAL=2.0
const OUTSIDE_SLOW_DAOIST=5.0
const OUTSIDE_SLOW_YOKAI=0.0
const OUTSIDE_LIFE_START=10.0
const OUTSIDE_LIFE_EVERY=15.0
const OUTSIDE_WEAK_DETECT=3.0
const OUTSIDE_CD_PENALTY=5.0
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
## 2.0.30 도감 설명과 실제 판정을 맞춘 반경 값(문구는 characters.gd SKILLS가 권한자).
const FOXSCENT_RADIUS=220.0
const MOUNTAIN_RADIUS=320.0
const GOBLINFEST_RADIUS=200.0
const DOUSE_RADIUS=300.0
## 인간둔갑이 겉모습을 훔칠 수 있는 거리(도감: "가까이 있는 도사").
const MIMIC_RADIUS=420.0
const SENSE_RADIUS=420.0
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
## 2.0.28 도깨비장난으로 옮겨 눕힌 사물(사물 인덱스 → 되돌아오는 시각).
var prop_flips: Dictionary={}
## 2.0.30 도깨비장난 지대: 이 안에서는 둔갑이 풀리고 새 둔갑도 막힌다(수색용 장판).
var mischief_zones: Array=[]
## 2.0.30: 마지막으로 발동한 도술의 이름·슬롯을 남겨 HUD 배너·미니맵·시야 연출이
## 같은 값에서 출발하게 한다.
const CAST_FEED_LIMIT=6
var cast_feed: Array=[]
func burst(at: Vector2,kind: String,duration: float,extra: Dictionary={}) -> void:
 serial+=1
 var entry:={"id":serial,"kind":kind,"position":at,"born":elapsed,"until":elapsed+duration}
 entry.merge(extra,true)
 effects.append(entry)
## 도술 하나가 발동됐을 때 그 도술 고유의 서명 연출을 남긴다. fx.gd가 `skill` 키로
## 그림·여우 가면·부적·도깨비방망이·달·발자국 같은 전용 모션을 그린다.
func signature(p: Dictionary,skill_id: String,aim: Vector2=Vector2.ZERO) -> void:
 var extra:={"skill":skill_id,"facing":p.facing,"cosmetic":C.look(p.character)}
 if aim!=Vector2.ZERO:extra["aim"]=aim
 ## 스킨 전용 이펙트가 있으면 스킨 아트를, 없으면 그 캐릭터·도술의 기본 손그림 이펙트를 쓴다.
 ## 2.0.36: 장영실(기관·천문)을 비롯한 10인 기본 이펙트가 실제 경기에서도 반드시 터진다.
 var skin_fx: String=SkillFX.file_for(p.get("character",""),skill_id,p.get("skin",""))
 var base_fx: String=SkillFX.file_for(p.get("character",""),skill_id,"")
 if String(p.get("skin",""))=="":
  burst(p.position,"fx_sig",0.85,extra)
 var fx_file: String=skin_fx if skin_fx!="" else base_fx
 if fx_file!="":
  ## 2.0.34 피드백: 이펙트가 캐릭터를 너무 크게 가리지 않도록 크기·투명도를 낮춰
  ## 발밑에서 펼쳐지게 한다.
  var fx_size: float=96.0 if fx_file.contains("kimchijeon") else 124.0
  burst(p.position,"fx_png",1.2,{"file":fx_file,"texture":load(fx_file),"facing":p.facing,"size":fx_size,"alpha":.86 if skin_fx!="" else .72})
func _init(seed_value: int=0) -> void:
 if seed_value==0:rng.randomize()
 else:rng.seed=seed_value
 use_map(Maps.current_id)
## 맵을 적용한다. 경기 시작 전에 호출하면 스폰·사물·기믹이 그 맵으로 바뀐다.
func use_map(id: String) -> void:
 map_id=Maps.set_current(id)
 L=Maps.layout()
 gimmicks=Gimmicks.new()
 gimmicks.setup(self)
func add(id: String,name: String,daoist: String,yokai: String) -> bool:
 if phase!="room" or players.size()>=8 or C.find(daoist).is_empty() or C.find(yokai).is_empty():return false
 players[id]={"id":id,"name":name,"choices":{"daoist":daoist,"yokai":yokai},"role":"","character":"","position":L.SPAWN,"home":L.SPAWN,"sealed_pos":L.SPAWN,"facing":2,"intent":Vector2.ZERO,"running":false,"stamina":100.0,"exhausted":false,"wobble":0.0,"form_origin":L.SPAWN,"jump":0.0,"height":0.0,"ground":L.SPAWN,"cd":{},"buff":{},"captured":false,"deadline":0.0,"eliminated":false,"immune":0.0,"rescue":"","progress":0.0,"origin":L.SPAWN,"outside":0.0,"form":"","copy":"","trail":[],"stride":0.0,"alive_seconds":0.0,"stagger":0.0,"lives":3,"stats":{"seals":0,"misses":0,"rescues":0,"lost":0},"confirmed":false,"ready":id!="human","color":players.size(),
  "skin":"","inside_reset":0.0,"outside_life":0,"ult":0.0,"stun":0.0,"slow_until":0.0,"slow_factor":1.0,"speed_until":0.0,"speed_factor":1.0,"seal_bonus":0.0,"mark":Vector2.INF,"last_hurt":0.0,"blind_until":0.0,"hint":"","last_skill":"","last_skill_name":"","last_skill_slot":"","last_skill_until":0.0}
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
## 2.0.33 봇 닉네임: 인게임 이름표·대기실·참가자 목록이 '요괴 1' 같은 임시 이름 대신
## 이용자 닉네임과 같은 자리에 자연스러운 이름을 쓴다(중복 없이 배정).
const BOT_NICKNAMES=["조선지킴이","밤도깨비","달빛여우","한옥탐정","부적장인","새벽바람","월하검객","청사초롱","별빛도사","구름나그네","먹빛도령","은하수비","호롱불지기","산그림자","해질녘손님","새벽종소리"]
static func bot_nicknames(count: int,seed_value: int=0) -> Array:
 var pool: Array=BOT_NICKNAMES.duplicate()
 var rng:=RandomNumberGenerator.new()
 if seed_value==0:rng.randomize()
 else:rng.seed=seed_value
 for i in range(pool.size()-1,0,-1):
  var j:=rng.randi_range(0,i)
  var swap: String=pool[i];pool[i]=pool[j];pool[j]=swap
 var out: Array=[]
 for i in range(maxi(0,count)):
  out.append(String(pool[i%pool.size()]) if i<pool.size() else "%s %d" % [pool[i%pool.size()],i/pool.size()+1])
 return out
## 2.0.33 겉으로 보이는 정체성(이름표): 시전자 또는 인간둔갑한 상대의 닉네임·캐릭터·목숨.
func apparent_identity(p: Dictionary) -> Dictionary:
 var mimicking: bool=float(p.buff.get("mimic",0.0))>elapsed and players.has(String(p.copy))
 var source: Dictionary=players[String(p.copy)] if mimicking else p
 var spec: Dictionary=C.find(String(source.get("character","")))
 # 2.0.36 스킨 동기화: 분신·인간둔갑도 대상이 실제 장착 중인 스킨을 그대로 쓴다.
 var skin: String=String(source.get("skin",""))
 if not SkillFX.skin_allows(skin,String(source.get("character",""))):skin=""
 return {"name":String(source.get("name","")),"character":String(source.get("character","")),
  "character_name":String(spec.get("name","")),"lives":int(source.get("lives",LIVES)),
  "role":String(source.get("role","")),"color":int(source.get("color",0)),"skin":skin}
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
 traps=[];marks=[];pings=[];dark_until=0.0;map_dark_until=0.0;reveal_until=0.0;trail_all_until=0.0;lantern_until.clear();prop_flips.clear()
 for p in players.values():p.outside=0.0;p.inside_reset=0.0;p.outside_life=0
 if gimmicks!=null:gimmicks.reset()
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
func event(kind: String,actor: String,target: String="",extra: Dictionary={}) -> void:
 var entry:={"kind":kind,"actor":actor,"target":target,"time":elapsed}
 entry.merge(extra,true)
 events.append(entry)
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
 if op=="gimmick":
  if gimmicks==null:return false
  var used: bool=gimmicks.interact(p)
  if used:event("gimmick_use",p.id)
  return used
 if op=="interact":
  if p.form!="":
   p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
  var door: String=L.door_near(p.position,70)
  if door!="":doors[door]=elapsed+1.4;burst(L.door(door).center,"fx_door",.6);event("door",p.id,door);return true
  var near: Dictionary=L.object_near(p.position,84)
  if near.is_empty():near=animal_near(p.position,84)
  if near.is_empty():return false
  # 형상 추출: 누구나 사물·동물 무리에 섞여 숨을 수 있는 공용 둔갑.
  if float(p.get("outside",0.0))>0.0:return false
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
   # 구미환몽의 환영은 요괴 본인도 칠 수 없는 허상이다(진짜 미끼만 친다).
   if bool(e.get("phantom",false)):continue
   e.until=0.0;p.cd.seal=elapsed+MISS_RECOVER;p.stats.misses+=1
   burst(e.position,"fx_poof",.6);event("miss",p.id);return true
 var q: Dictionary={};var best:=CONFIRM_REACH;var forward:=Vector2.from_angle(p.facing*PI/4)
 for candidate in players.values():
  if candidate.role!="daoist" or candidate.captured or candidate.eliminated or candidate.immune>elapsed:continue
  if float(candidate.buff.get("stealth",0.0))>elapsed:continue
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
## 그림 속·무월야로 완전히 사라진 상태인지(다른 시점·AI·시야 판정 공통).
func hidden(p: Dictionary) -> bool:return float((p.get("buff",{}) as Dictionary).get("stealth",0.0))>elapsed
## 몸이 닿은 미둔갑 도사를 버튼 입력 없이 즉시 봉인한다.
func contact_seal() -> void:
 for p in players.values():
  if p.role!="yokai" or not available(p):continue
  if float(p.cd.get("seal",0))>elapsed:continue
  var q: Dictionary={};var best:=CONTACT_RADIUS
  for candidate in players.values():
   if candidate.role!="daoist" or candidate.captured or candidate.eliminated or candidate.immune>elapsed:continue
   # 그림 속·무월야로 숨은 도사는 몸이 스쳐도 잡히지 않는다.
   if float(candidate.buff.get("stealth",0.0))>elapsed:continue
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
  # 생명등불도 '봉인 한 번'만 막는다. 막은 뒤에는 두 보호 효과를 함께 지운다.
  q.buff.erase("shield");q.buff.erase("lifelamp");q.immune=elapsed+SHIELD_IMMUNE;q.intent=Vector2.ZERO
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
 # 둔갑술(transform)은 쿨타임 중에도 '풀기'는 언제든 된다(한 버튼으로 둔갑·해제).
 var untoggle: bool=id=="transform" and p.form!=""
 if slot=="ult":
  if float(p.get("ult",0.0))<ULT_MAX or p.cd.get(id,0)>elapsed:return false
 elif not untoggle:
  if p.cd.get(id,0)>elapsed:return false
 if not aim.is_finite():return false
 if aim.length()<.01:aim=Vector2.from_angle(p.facing*PI/4)
 aim=aim.normalized();p.facing=posmod(roundi(aim.angle()/(PI/4)),8)
 if p.stun>elapsed:return false
 if not _effect(p,id,aim):
  # 왜 안 됐는지 바로 알 수 있게 실패 사유를 남긴다(HUD 배너·상태 라벨).
  event("skill_fail",p.id,id,{"name":String(spec.get("name",id)),"reason":_fail_reason(id,p)})
  return false
 signature(p,id,aim)
 var cooldown: float=float(spec.get("cd",12.0))
 # 2.0.34: 안전구역 밖 요괴는 5초 뒤 새 스킬 쿨타임이 25% 길어진다(복귀하면 즉시 원래대로).
 cooldown*=outside_cooldown_factor(p)
 p.cd[id]=elapsed+cooldown
 if slot=="ult":p.ult=0.0
 # 시전 순간을 HUD 배너·상태 뱃지·미니맵·시야 연출이 함께 읽는다.
 var skill_name: String=String(spec.get("name",C.SKILLS.get(id,{}).get("name",id)))
 p.last_skill=id;p.last_skill_name=skill_name;p.last_skill_slot=slot;p.last_skill_until=elapsed+1.6
 serial+=1
 var feed:={"id":serial,"actor":p.id,"skill":id,"name":skill_name,"slot":slot,"team":p.role,"at":p.position,"born":elapsed}
 cast_feed.append(feed)
 while cast_feed.size()>CAST_FEED_LIMIT:cast_feed.pop_front()
 event("skill",p.id,id,{"slot":slot,"name":skill_name,"team":p.role});event("skill_slot",p.id,slot)
 return true
## 능력 하나의 실제 도술. 성공하면 true(쿨타임 소모).
## 실패 사유 문구: 버튼을 눌렀는데 아무 일도 안 일어나는 것처럼 보이지 않게 한다.
## 도깨비 장난 지대 안인지(둔갑 금지 구역).
func in_mischief(pos: Vector2) -> bool:
 for z in mischief_zones:
  if float(z.until)<=elapsed:continue
  if pos.distance_to(z.pos)<=float(z.radius):return true
 return false
func _fail_reason(id: String,p: Dictionary) -> String:
 match id:
  "mimic":return "가까이에 둔갑할 도사가 없습니다"
  "transform","disguise":
   if in_mischief(p.position):return "도깨비 장난 지대에서는 둔갑할 수 없습니다"
   if float(p.get("outside",0.0))>0.0:return "안전구역 밖에서는 둔갑할 수 없습니다"
   return "가까이에 둔갑할 사물이 없습니다"
  "underworldgate":return "혼길표식을 먼저 세워야 합니다"
  "returnpath":return "위기에 빠진 동료가 없습니다"
  "wallhop":return "그 방향으로 넘어갈 수 없습니다"
 return "지금은 대상이 없어 발동할 수 없습니다"
func _effect(p: Dictionary,id: String,aim: Vector2) -> bool:
 match id:
  "transform","disguise":
   if p.form=="":
    # 도깨비 장난 지대·안전구역 밖에서는 새로 둔갑할 수 없다(해제는 언제나 가능).
    if in_mischief(p.position):return false
    if float(p.get("outside",0.0))>0.0:return false
   if p.form!="":
    p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
   var nearest: Dictionary=L.object_near(p.position,90)
   if nearest.is_empty():nearest=animal_near(p.position,90)
   if nearest.is_empty():return false
   p.form=nearest.kind;p.form_origin=nearest.p;p.wobble=0;p.buff.transform=elapsed+9
   burst(p.position,"fx_poof",.6,{"facing":p.facing});event("transform",p.id,nearest.kind);return true
  "clone":
   burst(p.position,"fx_ink",.5)
   serial+=1;effects.append({"id":serial,"kind":"clone","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"character":p.character,"identity":apparent_identity(p),"born":elapsed,"until":elapsed+8})
   burst(p.position,"fx_shadow",.55,{"facing":p.facing});return true
  "painting":
   # 화중은신: 족자를 펼쳐 그림 속 차원으로 들어간다. 무적·벽 통과에 더해
   # 다른 시점에서는 이름표·그림자·기운·발자국까지 전부 사라진다(완전 은신).
   p.buff.painting=elapsed+4.0;p.immune=maxf(p.immune,elapsed+4.0)
   p.buff.stealth=elapsed+4.0;p.trail=[]
   burst(p.position,"fx_ink",1.0,{"big":true});burst(p.position,"fx_scroll",1.1,{"facing":p.facing})
   event("painting",p.id);return true
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
   serial+=1;effects.append({"id":serial,"kind":"decoy","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"character":p.character,"identity":apparent_identity(p),"born":elapsed,"until":elapsed+9})
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
    # 도감 설명 그대로 8초: 동료도 나와 같은 시간·같은 효과(이속·봉인 1회 방어)를 받는다.
    q.buff.lifelamp=elapsed+8.0;q.speed_until=elapsed+8.0;q.speed_factor=1.25
    q.buff.shield=maxf(float(q.buff.get("shield",0.0)),elapsed+8.0)
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
   # 인간둔갑은 '도사'의 겉모습만 훔친다. 같은 요괴 편의 모습을 쓰면 기만이 성립하지 않는다.
   var targets:=visible(p.id).filter(func(a: Dictionary)->bool:return a.id!="" and a.id!=p.id and String(a.role)=="daoist")
   if targets.is_empty():
    # 벽너머라도 바로 옆이면 겉모습은 훔칠 수 있다(대상은 역시 도사뿐).
    for q in players.values():
     if q.id==p.id or q.eliminated or q.captured or q.role!="daoist":continue
     if (q.position as Vector2).distance_to(p.position)<=MIMIC_RADIUS and L.line(p.position,q.position):targets.append({"id":q.id,"position":q.position})
   targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return p.position.distance_to(a.position)<p.position.distance_to(b.position))
   if targets.is_empty():return false
   p.copy=targets[0].id;p.buff.mimic=elapsed+9
   burst(p.position,"fx_foxfire",.8);return true
  "foxscent":
   var charmed:=0
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    # 도감 표기(반경 220)와 같은 사거리.
    if q.position.distance_to(p.position)>FOXSCENT_RADIUS:continue
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
    serial+=1;effects.append({"id":serial,"kind":"decoy","owner":p.id,"position":L.safe(phantom),"facing":q.facing,"cosmetic":C.look(p.character),"character":p.character,"identity":apparent_identity(p),"born":elapsed,"until":elapsed+4.0,"phantom":true})
    burst(q.position,"fx_foxfire",1.2)
   burst(p.position,"fx_mist",1.4);return true
  "voicemimic":
   var decoy_at: Vector2=L.safe(p.position+aim*180.0)
   serial+=1;effects.append({"id":serial,"kind":"fake_rescue","owner":p.id,"position":decoy_at,"born":elapsed,"until":elapsed+6.0})
   burst(decoy_at,"fx_sound",1.4)
   event("fakerescue",p.id)
   var near:=_nearest_role(p,"daoist")
   if not near.is_empty():
    near.buff.revealed=elapsed+3.0
    pings.append({"pos":near.position,"until":elapsed+3.0,"color":Color("ffd08a"),"target":near.id})
   return true
  "soundhunt":
   p.buff.sense=elapsed+4.0
   event("sense",p.id)
   burst(p.position,"fx_ghost",.9);return true
  "mountaingrowl":
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    # 도감 표기(반경 320)와 같은 사거리.
    if q.position.distance_to(p.position)>MOUNTAIN_RADIUS:continue
    var push: Vector2=q.position-p.position
    if push.length()<1.0:push=Vector2.from_angle(rng.randf()*TAU)
    q.position=L.move(q.position,q.position+push.normalized()*110.0);q.ground=q.position
    q.stun=elapsed+.6;q.intent=Vector2.ZERO
    burst(q.position,"fx_howl",.9)
   p.speed_until=elapsed+6.0;p.speed_factor=1.5
   burst(p.position,"fx_howl",1.6,{"big":true});return true
  "mischief":
   # 도깨비장난: 반경 260의 사물을 뒤엉키게 흔들고, 둔갑한 도사를 강제로 드러낸 뒤
   # 6초 동안 둔갑이 불가능한 '장난 지대'를 만든다(수색·추격용 실전 스킬).
   var zone_radius:=260.0
   mischief_zones=mischief_zones.filter(func(z: Dictionary)->bool:return float(z.until)>elapsed)
   mischief_zones.append({"pos":p.position,"radius":zone_radius,"until":elapsed+6.0})
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    if q.position.distance_to(p.position)>zone_radius:continue
    # 위치를 잠깐 드러내고(3.5초) 느려지게 한다 — 둔갑이 아니어도 대응 가치가 있다.
    q.buff.revealed=elapsed+3.5
    q.slow_until=elapsed+3.5;q.slow_factor=.62
    if q.form!="":
     q.form="";q.buff.erase("transform");q.stun=elapsed+.45
     burst(q.position,"fx_goblinfire",.9);event("untransform",q.id)
   # 반경 안의 실제 사물을 크게 뒤엉키게 한다.
   for i in range(L.OBJECTS.size()):
    if p.position.distance_to((L.OBJECTS[i] as Dictionary).p)<=zone_radius:prop_flips[i]=elapsed+7.0
   burst(p.position,"fx_goblinfire",1.2,{"big":true})
   event("mischief_zone",p.id)
   return true
  "faketreasure":
   traps.append({"kind":"treasure","owner":p.id,"pos":p.position,"until":elapsed+30.0,"radius":44.0,"armed":true})
   burst(p.position,"fx_goldwave",.8);return true
  "goblinfest":
   for q in players.values():
    if q.role!="daoist" or q.captured or q.eliminated:continue
    # 도감 표기(반경 200)와 같은 사거리.
    if q.position.distance_to(p.position)>GOBLINFEST_RADIUS:continue
    if q.form!="":q.form="";q.buff.erase("transform");event("untransform",q.id)
    var push: Vector2=q.position-p.position
    if push.length()<1.0:push=Vector2.from_angle(rng.randf()*TAU)
    q.position=L.move(q.position,q.position+push.normalized()*90.0);q.ground=q.position
    q.stun=elapsed+.4;burst(q.position,"fx_goblinfire",1.0)
   burst(p.position,"fx_goblinfire",1.8,{"big":true});return true
  "douse":
   # 도감 표기(주변 300의 석등을 9초)와 같은 범위. 범위 안의 석등만 실제로 꺼진다.
   dark_until=elapsed+9.0;dark_center=p.position;dark_radius=DOUSE_RADIUS
   lantern_until["all"]=elapsed+9.0
   event("douse",p.id)
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
  # 그림 속 차원(화중은신)·무월야로 완전히 사라진 상대는 위치를 짚을 수 없다.
  if q.id!=p.id and float(q.buff.get("stealth",0.0))>elapsed:continue
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
 ## 2.0.34 개편: 시작 원은 맵 네 모서리를 '딱' 포함하는 최소 반경이어야 한다.
 ## (예전에는 2700으로 맵 밖 한참에서 시작해 초반 안전구역이 의미가 없었다.)
 var radii: Array=L.circle_radii()
 var due: Array=L.circle_due()
 var corners: float=L.corner_radius()
 var start: Vector2=L.circle_center_start()
 var last: Vector2=L.circle_final_center()
 var centers: Array=[start,start.lerp(last,.34),start.lerp(last,.68),last]
 var stage:=0
 if elapsed>=float(due[0]) and elapsed<float(due[1]):stage=1
 elif elapsed>=float(due[1]) and elapsed<float(due[2]):stage=2
 elif elapsed>=float(due[2]):stage=3
 var next:=mini(3,stage+1)
 var blend:=1.0
 if stage>0:blend=clampf((elapsed-float(due[stage-1]))/30.0,0.0,1.0)
 var from_center: Vector2=centers[stage-1] if stage>0 else centers[0]
 var to_center: Vector2=centers[stage]
 var from_radius: float=minf(float(radii[maxi(0,stage-1)]),corners) if stage>0 else minf(float(radii[0]),corners)
 var to_radius: float=minf(float(radii[stage]),corners)
 var center: Vector2=from_center.lerp(to_center,blend)
 var radius: float=lerpf(from_radius,to_radius,blend)
 var until: float=maxf(0.0,float(due[stage])-elapsed) if stage<3 else 0.0
 return {"stage":stage,"center":center,"radius":radius,
  "next_center":centers[next],"next_radius":minf(float(radii[next]),corners),"until":until,
  "corner_radius":corners,"final_center":last}
## 안전구역 밖인가(그리고 얼마나 오래 있었는가).
func outside_state(p: Dictionary) -> Dictionary:
 var zone:=circle()
 var out: float=maxf(0.0,float(p.get("outside",0.0)))
 var dist: float=(p.position as Vector2).distance_to(zone.center)
 return {"outside":dist>float(zone.radius),"distance":dist,"radius":float(zone.radius),
  "time":out,"dark":float(p.get("outside",0.0))>=OUTSIDE_SLOW_DAOIST}
## 안전구역 밖 불이익(역할별 차등). 매 틱 호출해도 같은 결과가 나오게 만든다.
func _outside_penalties(delta: float) -> void:
 var zone:=circle()
 var radius: float=float(zone.radius)
 var center: Vector2=zone.center
 for p in players.values():
  if p.eliminated or p.role=="":continue
  var outside: bool=(p.position as Vector2).distance_to(center)>radius
  if outside:
   p.outside=float(p.get("outside",0.0))+delta
   p.inside_reset=0.0
  elif float(p.get("outside",0.0))>0.0:
   # 3초 이내 들락날락은 누적 시간을 유지한다(경계 악용 방지).
   p.inside_reset=float(p.get("inside_reset",0.0))+delta
   if p.inside_reset>=OUTSIDE_GRACE:
    p.outside=0.0;p.inside_reset=0.0;p.outside_life=0
  var t: float=float(p.get("outside",0.0))
  if t<=0.0:continue
  if p.role=="daoist":
   # 즉시: 둔갑 강제 해제(둔갑 금지는 _effect가 outside를 보고 막는다).
   if p.form!="":
    p.form="";p.buff.erase("transform");p.wobble=0
    burst(p.position,"fx_poof",.5);event("untransform",p.id,"",{"reason":"outside"})
   # 2초: 요괴의 미니맵·시야에 위치가 드러난다.
   if t>=OUTSIDE_REVEAL:p.buff.revealed=maxf(float(p.buff.get("revealed",0.0)),elapsed+.4)
   # 10초: 목숨 1개, 이후 15초마다 추가 차감.
   if t>=OUTSIDE_LIFE_START:
    var expected: int=1+int(floor((t-OUTSIDE_LIFE_START)/OUTSIDE_LIFE_EVERY))
    if int(p.get("outside_life",0))<expected:
     var gap: int=expected-int(p.get("outside_life",0))
     p.outside_life=expected
     for i in range(gap):
      if p.eliminated:break
      _outside_life_loss(p)
  else:
   # 요괴: 3초 후 탐지 약화(visible/map_contacts가 이 값을 읽는다).
   if t>=OUTSIDE_WEAK_DETECT:p.slow_until=maxf(float(p.slow_until),elapsed+.2)
## 안전구역 밖 이동 감속 배율(도사 5초 뒤 10%, 요괴는 즉시 15%).
func outside_speed_factor(p: Dictionary) -> float:
 var t: float=float(p.get("outside",0.0))
 if t<=0.0:return 1.0
 if String(p.get("role",""))=="yokai":return .85
 return .90 if t>=OUTSIDE_SLOW_DAOIST else 1.0
## 안전구역 밖 요괴의 새 스킬 쿨타임 배율(5초 뒤 1.25배, 복귀하면 1.0).
func outside_cooldown_factor(p: Dictionary) -> float:
 if String(p.get("role",""))!="yokai":return 1.0
 return 1.25 if float(p.get("outside",0.0))>=OUTSIDE_CD_PENALTY else 1.0
## 안전구역 밖에서 목숨을 잃는다(봉인과 별개로 즉시 차감).
func _outside_life_loss(p: Dictionary) -> void:
 if p.eliminated:return
 p.lives=maxi(0,int(p.get("lives",LIVES))-1)
 p.stats.lost=maxi(0,int(p.stats.get("lost",0)))+1
 burst(p.position,"fx_darkness",1.0,{"big":true})
 event("outside_damage",p.id,"",{"lives":int(p.lives)})
 if int(p.lives)<=0:
  p.eliminated=true;p.captured=false;event("eliminate",p.id)
 else:
  p.immune=maxf(p.immune,elapsed+1.2)

## 맵을 걷는 고양이·강아지. rules가 위치의 권한자이며 world가 그린다.
var walkers: Array=[]
func build_walkers() -> void:
 walkers=[]
 ## 맵마다 다른 순찰로(서원: 고양이·강아지 / 강남역: 배달 로봇·전동킥보드).
 var routes: Array=L.walker_routes()
 for i in range(routes.size()):
  var route: Dictionary=routes[i]
  var path: Array=route.path
  var kind: String=String(route.kind)
  walkers.append({"id":"walker-%d"%i,"kind":kind,"p":path[0],"path":path,"next":1,"facing":0,
   "phase":0.0,"speed":float(route.get("speed",31.0)),"moving":true,"wait":0.0})
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
  # 둔갑한 그 자체는 다른 시점에 사라지고, 본인에게만 남는다.
  if String(p.get("copy",""))!="" and float(p.buff.get("mimic",0.0))<=elapsed:p.copy=""
  var previous: Vector2=p.position
  p.outside=p.outside+delta if p.position.distance_to(zone.center)>zone.radius else 0.0
  if p.exhausted and p.stamina>=25:p.exhausted=false
  var fast: bool=p.running and p.stamina>0 and not p.exhausted and p.intent.length()>.05
  p.stamina=clampf(p.stamina+(-25 if fast else 18)*delta,0,100)
  if p.stamina<=0:p.exhausted=true
  if p.jump>0:
   p.jump=maxf(0,p.jump-delta);p.height=sin((.8-p.jump)/.8*PI)*36
  else:p.height=0
  # 캐릭터가 아직 비어 있는 참가자(테스트·복구 중)도 기본 이동 성능으로 계속 움직인다.
  var piece: Dictionary=C.find(p.character)
  var walk_speed: float=float(piece.get("speed",135.0))
  var dash_speed: float=float(piece.get("run_speed",210.0))
  var speed: float=dash_speed if fast else walk_speed
  if p.stagger>elapsed or p.stun>elapsed:speed=0.0
  if p.slow_until>elapsed:speed*=float(p.slow_factor)
  if p.speed_until>elapsed:speed*=float(p.speed_factor)
  if p.outside>circle_penalty_after:speed*=circle_speed_factor
  # 2.0.34: 모든 둔갑 사물은 고정형 구분 없이 자유롭게 이동한다(감속 없음).
  ## 안전구역 밖 실제 불이익: 도사는 5초 뒤 10% 감속, 요괴는 즉시 15% 감속.
  speed*=outside_speed_factor(p)
  ## 에스컬레이터: 작동 방향으로 타면 가속, 반대로 걸으면 느려지고 살짝 밀린다.
  var escalator: Dictionary=gimmicks.on_escalator(p.position) if gimmicks!=null else {}
  ## 2.0.35: 파도 경보(해운대) 같은 맵 기믹 감속.
  if gimmicks!=null:speed*=gimmicks.speed_factor(p)
  if not escalator.is_empty():
   var flow:=Vector2(0,-1.0 if gimmicks.escalator_dir>0 else 1.0)
   var along: float=p.intent.dot(flow)
   if along>.12:speed*=1.45
   elif along<-.12:speed*=.80
  if p.buff.get("painting",0)>elapsed:
   # 그림 속 차원: 벽을 통과해 곧장 이동한다(맵 밖으로는 못 나간다).
   p.position+=(p.intent*speed*1.15*delta)
   p.position=Vector2(clampf(p.position.x,90,L.SIZE.x-90),clampf(p.position.y,100,L.SIZE.y-100))
  else:
   p.position=L.move(p.position,p.position+p.intent*speed*delta,p.height>12)
   if p.jump<=0 and not L.can_stand(p.position):p.position=L.safe(p.position)
   # 잠긴 개찰구·내려온 셔터는 실제로 막는다(그림과 판정이 같다).
   if gimmicks!=null and gimmicks.blocked(p.position):
    p.position=previous
    if gimmicks.blocked(p.position):p.position=L.safe(previous)
   if not escalator.is_empty():
    # 2.0.36 실제 탑승형: 서 있어도 작동 방향으로 105px/s 실려 간다(걸으면 그 위에 더해진다).
    var drift: Vector2=Vector2(0,-1.0 if gimmicks.escalator_dir>0 else 1.0)*105.0*delta
    var moved: Vector2=L.move(p.position,p.position+drift)
    if not gimmicks.blocked(moved):p.position=moved
  if L.can_stand(p.position):p.ground=p.position
  var distance: float=p.position.distance_to(previous);p.stride+=distance
  var muted_footsteps: bool=gimmicks!=null and gimmicks.trail_blocked(p.position)
  if distance>0 and not muted_footsteps and float(p.buff.get("stealth",0.0))<=elapsed and (p.trail.is_empty() or p.position.distance_to(p.trail[-1].position)>=18):p.trail.append({"position":p.position,"time":elapsed,"facing":p.facing})
  while not p.trail.is_empty() and elapsed-p.trail[0].time>6:p.trail.pop_front()
 _outside_penalties(delta)
 if gimmicks!=null:gimmicks.tick(delta)
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
 # 도깨비 장난 지대: 안에 있는 도사는 계속 느려지고 둔갑이 풀린다.
 mischief_zones=mischief_zones.filter(func(z: Dictionary)->bool:return float(z.until)>elapsed)
 for z in mischief_zones:
  for q in players.values():
   if q.role!="daoist" or q.captured or q.eliminated:continue
   if (q.position as Vector2).distance_to(z.pos)>float(z.radius):continue
   q.slow_until=maxf(float(q.slow_until),elapsed+.3);q.slow_factor=minf(float(q.slow_factor),.80)
   if q.form!="":
    q.form="";q.buff.erase("transform");burst(q.position,"fx_goblinfire",.6);event("untransform",q.id)
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
 ## 2.0.34: 요괴가 안전구역 밖에 3초 이상 있으면 탐지 반경이 줄어든다.
 if viewer.role=="yokai" and float(viewer.get("outside",0.0))>=OUTSIDE_WEAK_DETECT:reach=minf(reach,220.0)
 if viewer.role=="yokai" and float(viewer.get("outside",0.0))>0.0:reach=minf(reach,280.0)
 ## 2.0.35: 물안개 낀 구역 안에서는 앞이 흐려 탐지 거리가 줄어든다(해운대 샤워기).
 if gimmicks!=null and gimmicks.zone_mist(String(L.zone_at(viewer.position).get("id",""))):reach=minf(reach,190.0)
 # 귀문보기: 한옥 한 채 너머까지 투시하는 사거리(벽은 그대로 통과).
 if see_through:reach=760.0
 # 천문기계는 "서원 전역을 꿰뚫어" 본다: 사거리뿐 아니라 벽·한옥도 통과한다.
 if reveal_until>elapsed and viewer.role=="daoist":reach=9999.0;see_through=true
 if foot_scope(viewer) and viewer.role=="yokai":reach=9999.0
 for p in players.values():
  if p.eliminated:continue
  var distance: float=viewer.position.distance_to(p.position)
  if p.id!=id and float(p.buff.get("stealth",0.0))>elapsed:continue
  if p.id!=id and distance>reach:continue
  if p.id!=id and not see_through and not L.line(viewer.position,p.position):continue
  # 2.0.34: 내려온 셔터는 시야도 막는다.
  if p.id!=id and gimmicks!=null and not see_through and gimmicks.line_blocked(viewer.position,p.position):continue
  # 암전 구역(조명 끔)의 대상은 멀리서 식별되지 않는다(도사 은신에 유리).
  if p.id!=id and gimmicks!=null and distance>240.0:
   var target_zone: String=String(L.zone_at(p.position).get("id",""))
   if gimmicks.zone_obscured(target_zone):continue
  var blocked:=false
  for e in effects:
   if e.kind=="smoke" and distance>85 and Geometry2D.get_closest_point_to_segment(e.position,viewer.position,p.position).distance_to(e.position)<115:blocked=true
  if blocked and p.id!=id:continue
  # 인간둔갑: 겉모습·이름표·팀 색·미니맵 점까지 복제한 도사의 것을 그대로 쓴다.
  var mimicking: bool=float(p.buff.get("mimic",0.0))>elapsed and players.has(String(p.copy))
  var source: Dictionary=players[p.copy] if mimicking else p
  var source_spec: Dictionary=C.find(String(source.character))
  var shown_name: String=String(source.name)
  if mimicking and not source_spec.is_empty():shown_name=String(source_spec.get("name",source.name))
  result.append({"id":"" if p.form!="" and p.id!=id else p.id,"position":p.position,"form":p.form,"name":shown_name,"player_name":source.name,"role":source.role,"color":source.color,"cosmetic":C.look(source.character),"character":source.character,"character_name":String(source_spec.get("name","")),"lives":int(source.get("lives",LIVES)),"facing":p.facing,"height":p.height,"moving":p.intent.length()>.05 and not p.captured,"captured":p.captured,"immune":p.immune>elapsed,"shield":p.buff.get("shield",0)>elapsed or p.buff.get("lifelamp",0)>elapsed,"revealed":float(p.buff.get("glowing",0.0))>elapsed or float(p.buff.get("revealed",0.0))>elapsed,"disguised":p.form!="","mimic":mimicking,
  # 2.0.37 스킨은 그 캐릭터 전용일 때만 유효하다(다른 캐릭터는 기본 이름표·기본 모습).
  "skin":String(source.get("skin","")) if SkillFX.skin_allows(String(source.get("skin","")),String(source.get("character",""))) else ""})
 return result
## 발자국·동선을 전부 비추는 효과가 켜져 있는지(요괴 시점).
func foot_scope(p: Dictionary) -> bool:
 return trail_all_until>elapsed

## ---------------------------------------------------------------- 2.0.30 미니맵·시야 공용
## 같은 팀 아군은 언제나 보인다(은신 중인 아군도 자기 편 지도에는 남는다).
## 생존·봉인·구조(구조 중)·탈락을 구분해 돌려준다.
func allies(id: String) -> Array:
 var out: Array=[]
 if not players.has(id):return out
 var viewer: Dictionary=players[id]
 for p in players.values():
  if p.role!=viewer.role:continue
  out.append({"id":p.id,"name":p.name,"character":p.character,"position":p.position,
   "self":p.id==id,"captured":bool(p.captured),"eliminated":bool(p.eliminated),
   "lives":int(p.get("lives",LIVES)),"rescuing":String(p.get("rescue","")),
   "progress":float(p.get("progress",0.0)),"hidden":hidden(p)})
 return out
## 미니맵에는 맵 구조와 같은 팀만 보인다. 적은 '탐지 도술'이 켜져 있는 동안만
## 그 위치가 드러난다(평상시에는 어떤 적도 지도에 찍히지 않는다).
func map_contacts(id: String) -> Array:
 var out: Array=[]
 if not players.has(id):return out
 var viewer: Dictionary=players[id]
 var seeing:=false
 var label:=""
 if viewer.role=="daoist":
  if reveal_until>elapsed:seeing=true;label="천문기계"
  if float(viewer.buff.get("ghostgate",0.0))>elapsed:seeing=true;label="귀문보기"
 else:
  ## 2.0.34: 안전구역 밖 요괴는 3초 뒤 탐지 도술이 약해진다.
  var weak: bool=float(viewer.get("outside",0.0))>=OUTSIDE_WEAK_DETECT
  if not weak and trail_all_until>elapsed:seeing=true;label="발자국"
  if not weak and float(viewer.buff.get("sense",0.0))>elapsed:seeing=true;label="청각사냥"
 # 요괴 진영이 찍어 둔 야광가루·목소리흉내 표식도 탐지 시간 동안만 유지된다.
 for m in marks:
  if String(m.get("kind",""))!="glow":continue
  var q: Dictionary=players.get(String(m.get("target","")),{})
  if q.is_empty() or hidden(q) or q.eliminated:continue
  if viewer.role=="yokai":out.append({"id":q.id,"pos":q.position,"team":"daoist","source":"야광가루"})
 for q in players.values():
  if q.eliminated or q.role==viewer.role or hidden(q):continue
  if float(q.buff.get("revealed",0.0))>elapsed and viewer.role=="yokai":
   out.append({"id":q.id,"pos":q.position,"team":q.role,"source":"위치 노출"})
  if not seeing:continue
  # 같은 id가 이미 담겼으면 한 번만.
  var dup:=false
  for entry in out:
   if String(entry.id)==String(q.id):dup=true
  if dup:continue
  out.append({"id":q.id,"pos":q.position,"team":q.role,"source":label})
 return out
## 관측자 픽셀 시점에서 화면에 입힐 어둡·시야 좁히기 강도(0~1).
func vision_for(id: String) -> Dictionary:
 var out:={"narrow":0.0,"dark":0.0,"fog":0.0,"source":"","center":Vector2.ZERO,"radius":0.0}
 if not players.has(id):return out
 var me: Dictionary=players[id]
 var blind: float=float(me.get("blind_until",0.0))-elapsed
 if blind>0.0:
  out.narrow=clampf(blind/6.0,.32,1.0);out.source="blind"
 if float(me.buff.get("painting",0.0))>elapsed:
  out.narrow=maxf(float(out.narrow),.55);out.fog=maxf(float(out.fog),.5);out.source="painting"
 if map_dark_until>elapsed and me.role=="daoist":
  out.dark=maxf(float(out.dark),.55);out.fog=maxf(float(out.fog),.35)
  if String(out.source)=="":out.source="moonless"
 ## 2.0.34: 조명이 꺼진 구역은 안이 어둡고, 구역 밖에서도 경계가 어둡게 보인다.
 if gimmicks!=null:
  var zone_id: String=String(L.zone_at(me.position).get("id",""))
  if gimmicks.zone_dark(zone_id):
   out.dark=maxf(float(out.dark),.46);out.fog=maxf(float(out.fog),.28)
   if String(out.source)=="":out.source="lights"
  ## 2.0.35: 물안개는 화면을 뿌옇게 만들고 시야를 줄인다.
  if gimmicks.zone_mist(zone_id) or (gimmicks.smoke_until>elapsed and (me.position as Vector2).distance_to(gimmicks.smoke_pos)<=gimmicks.smoke_radius):
   out.fog=maxf(float(out.fog),.62);out.narrow=maxf(float(out.narrow),.30)
   if String(out.source)=="":out.source="mist"
 ## 안전구역 밖 경고: 화면 테두리가 맵 색으로 맥동한다(서원=보랏빛/강남=붉은 비상).
 var outside: float=float(me.get("outside",0.0))
 if outside>0.0:
  out.warning=clampf(.35+outside*.12,0.0,1.0)
  out.warning_color="7a4bff" if map_id=="seowon" else "ff3b4a"
 if dark_until>elapsed:
  var gap: float=(me.position as Vector2).distance_to(dark_center)
  if me.role=="daoist":
   var inside: float=clampf(1.0-gap/maxf(1.0,dark_radius),0.0,1.0)
   if inside>0.0:
    out.dark=maxf(float(out.dark),.25+.5*inside);out.fog=maxf(float(out.fog),.5*inside)
    out.center=dark_center;out.radius=dark_radius
    if String(out.source)=="":out.source="douse"
 return out
## HUD 상태 뱃지·지도 범례가 함께 쓰는 활성 효과 목록.
## 2.0.31: 인간둔갑은 '누구 모습인지'까지 뱃지에 적어 준다(예: 인간둔갑 · 전우치 모습).
func mimic_label(p: Dictionary) -> String:
 var target: String=String(p.get("copy",""))
 if target=="" or not players.has(target):return ""
 var spec: Dictionary=C.find(String(players[target].get("character","")))
 var shown: String=String(spec.get("name",""))
 if shown=="":shown=String(players[target].get("name",""))
 return "" if shown=="" else " · "+shown+" 모습"
func active_effects(id: String) -> Array:
 var out: Array=[]
 if not players.has(id):return out
 var p: Dictionary=players[id]
 var now:=elapsed
 var add_effect:=func(key: String,name: String,left: float,color: String,good: bool) -> void:
  if left>0.0:out.append({"key":key,"name":name,"left":left,"color":color,"good":good})
 add_effect.call("mimic","인간둔갑"+mimic_label(p),float(p.buff.get("mimic",0.0))-now,"ff9ee0",true)
 if String(p.get("form",""))!="":add_effect.call("transform","둔갑 · "+String(L.form(String(p.form)).get("name","사물")),float(p.buff.get("transform",0.0))-now,"c2a8ff",true)
 add_effect.call("painting","화중은신",float(p.buff.get("painting",0.0))-now,"f0d79b",true)
 if hidden(p) and float(p.buff.get("painting",0.0))<=now:add_effect.call("stealth","은신",float(p.buff.get("stealth",0.0))-now,"b48cf0",true)
 add_effect.call("shield","보호막",float(p.buff.get("shield",0.0))-now,"ffd9a0",true)
 add_effect.call("lifelamp","생명등불",float(p.buff.get("lifelamp",0.0))-now,"ffd08a",true)
 add_effect.call("deathflower","저승꽃",float(p.buff.get("deathflower",0.0))-now,"d9c0ff",true)
 add_effect.call("ghostgate","귀문보기",float(p.buff.get("ghostgate",0.0))-now,"c9b6ff",true)
 add_effect.call("sense","발자국 감지",float(p.buff.get("sense",0.0))-now,"8fd8ff",true)
 add_effect.call("speed","가속",float(p.get("speed_until",0.0))-now,"a8f0d0",true)
 add_effect.call("glowing","야광 표식",float(p.buff.get("glowing",0.0))-now,"a8ffe8",false)
 add_effect.call("revealed","위치 노출",float(p.buff.get("revealed",0.0))-now,"ffd08a",false)
 add_effect.call("blind","시야 좁아짐",float(p.get("blind_until",0.0))-now,"9a8fd0",false)
 add_effect.call("slow","느려짐",float(p.get("slow_until",0.0))-now,"7fe4d6",false)
 add_effect.call("stun","꼼짝 못함",float(p.get("stun",0.0))-now,"ff9a5a",false)
 add_effect.call("mark","혼길표식",1.0 if (p.mark as Vector2).is_finite() else 0.0,"ffd98a",true)
 return out
