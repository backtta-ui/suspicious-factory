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
## 문이 열린 시각(초). world.gd는 이 값으로 문짝과 지붕을 움직인다.
var doors: Dictionary={"front":0.0,"back":0.0}
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
 players[id]={"id":id,"name":name,"choices":{"daoist":daoist,"yokai":yokai},"role":"","character":"","position":L.SPAWN,"home":L.SPAWN,"facing":2,"intent":Vector2.ZERO,"running":false,"stamina":100.0,"exhausted":false,"wobble":0.0,"form_origin":L.SPAWN,"jump":0.0,"height":0.0,"ground":L.SPAWN,"cd":{},"buff":{},"captured":false,"deadline":0.0,"eliminated":false,"immune":0.0,"rescue":"","progress":0.0,"origin":L.SPAWN,"outside":0.0,"form":"","copy":"","trail":[],"stride":0.0,"alive_seconds":0.0,"stagger":0.0,"lives":3,"stats":{"seals":0,"misses":0,"rescues":0,"lost":0},"confirmed":false,"ready":id!="human","color":players.size()}
 return true
## 시작 직후 요괴가 바로 봉인하지 못하도록 주는 유예(초).
const SEAL_GRACE=6.0
## ---------------------------------------------------------------- 봉인 판정
## 《도망가 친구들》 방식: 미둔갑 도사는 몸이 닿는 순간 봉인되고(버튼 없음),
## 사물로 둔갑한 도사만 요괴의 '확인' 타격으로 잡힌다.
## 접촉 봉인 반경(px). 몸이 겹치는 거리라야 추격이 성립한다.
const CONTACT_RADIUS=27.0
## '확인' 타격 사거리(px). 근처 사물/둔갑 도사에 닿는 거리.
const CONFIRM_REACH=62.0
## 봉인 1명 직후 요괴의 짧은 후딜(초). 연속 싹쓸이를 막되 다음 추격은 바로 가능하다.
const SEAL_RECOVER=1.5
## 빈 사물·허공을 확인했을 때의 헛방 후딜(초).
const MISS_RECOVER=2.0
## 호신부가 막아준 뒤 도사가 받는 짧은 재봉인 면역(초)과 밀려나는 거리(px).
const SHIELD_IMMUNE=1.2
const SHIELD_KNOCK=62.0
## 봉인되면 이 시간(초) 안에 구조받아야 하고, 지나면 목숨 1개를 잃는다.
## 구조 시간(초). 10초 안에 들어오도록 짧게 잡는다.
const SEAL_DEADLINE=10.0
const RESCUE_TIME=2.5
## 도사는 목숨 3개. 세 번째 봉인은 기다림 없이 즉시 탈락이다.
const LIVES=3
## 목숨을 잃고 시작 자리로 돌아왔을 때 주는 재봉인 면역(초).
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
  # 도사는 중앙~서남 안전 지대, 요괴는 600px 이상 떨어진 외곽에서 시작한다.
  var seat:=yokai_index if p.role=="yokai" else daoist_index
  var spot: Vector2=L.spawns_for(p.role,seat)
  if p.role=="yokai":yokai_index+=1
  else:daoist_index+=1
  p.position=spot;p.ground=spot;p.origin=spot;p.home=spot;p.form_origin=spot;p.intent=Vector2.ZERO;p.facing=6 if p.role=="daoist" else 2
 apply_preference()
 orbs=[]
 for spot in L.ORBS:orbs.append({"p":spot,"ready":0.0})
 phase="selection";selection_left=25;selection_elapsed=0;return true
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
 if players.values().all(func(p: Dictionary)->bool:return p.confirmed):phase="loading"
 return true
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
  # 둔갑 해제는 어디서든 다시 누르면 풀린다(사물 근처일 필요 없음).
  if p.form!="":
   p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
  var door:=L.door_near(p.position,70)
  if door!="":doors[door]=elapsed+1.4;burst(L.door(door).center,"fx_door",.6);event("door",p.id,door);return true
  var near:=L.object_near(p.position,84)
  if near.is_empty():return false
  # 형상 추출: 누구나 사물 무리에 섞여 숨을 수 있는 공용 둔갑.
  if float(p.cd.get("transform",0))>elapsed:return false
  p.form=near.kind;p.form_origin=near.p;p.wobble=0;p.buff.transform=elapsed+9;p.cd.transform=elapsed+12
  burst(p.position,"fx_poof",.6);event("transform",p.id,near.kind);return true
 if op=="rescue":
  var target: String=data.get("target","")
  if p.role!="daoist" or not players.has(target):return false
  var q: Dictionary=players[target]
  if not q.captured or q.eliminated or p.position.distance_to(q.position)>58 or not L.line(p.position,q.position):return false
  if p.rescue!=target:p.rescue=target;p.progress=0;p.origin=p.position
  p.intent=Vector2.ZERO;return true
 if op=="skill":return skill(p,data.get("aim",Vector2.from_angle(p.facing*PI/4)))
 return false
## 요괴의 '확인' 타격: 근처 사물 중 둔갑한 도사를 쳐서 잡는다.
## 미둔갑 도사는 접촉 판정(contact_seal)이 담당하므로 이 타격으로는 잡히지 않는다.
func seal(p: Dictionary) -> bool:
 if p.role!="yokai" or float(p.cd.get("seal",0))>elapsed:return false
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
  # 빈 사물·허공을 쳤다: 2초 헛방 후딜과 이펙트.
  p.cd.seal=elapsed+MISS_RECOVER;p.stagger=elapsed+.25;p.stats.misses+=1
  serial+=1;effects.append({"id":serial,"kind":"miss","position":p.position,"born":elapsed,"until":elapsed+.5,"cosmetic":C.look(p.character),"facing":p.facing})
  event("miss",p.id);return true
 # 둔갑한 도사를 맞혔다: 즉시 둔갑 해제 + 봉인.
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
   # 둔갑 중인 도사는 스쳐 지나가도 잡히지 않는다(확인 타격 대상).
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
 if q.buff.get("shield",0)>elapsed:
  # 호신부가 한 번 막아낸다: 버프 소멸 + 짧은 면역 + 넉백.
  q.buff.erase("shield");q.immune=elapsed+SHIELD_IMMUNE;q.intent=Vector2.ZERO
  var push: Vector2=q.position-p.position
  if push.length()<.01:push=Vector2.from_angle(p.facing*PI/4)
  q.position=L.move(q.position,q.position+push.normalized()*SHIELD_KNOCK);q.ground=q.position
  burst(q.position,"fx_talisman",.6,{"facing":q.facing});event("blocked",p.id,q.id)
  return false
 if q.form!="":q.form="";q.buff.erase("transform");burst(q.position,"fx_poof",.45)
 q.intent=Vector2.ZERO;q.running=false;q.jump=0;q.height=0;q.rescue="";q.progress=0
 q.form="";q.buff.erase("transform")
 p.stats.seals+=1;event("seal",p.id,q.id)
 # 목숨은 봉인 순간이 아니라 구조에 실패한 순간에 줄어든다.
 q.captured=true;q.deadline=elapsed+SEAL_DEADLINE;return true
func skill(p: Dictionary,aim: Vector2) -> bool:
 var spec: Dictionary=C.find(p.character);var id: String=spec.active
 if id=="transform" and p.form!="":
  p.form="";p.buff.erase("transform");p.wobble=0;burst(p.position,"fx_poof",.5);event("untransform",p.id);return true
 if p.cd.get(id,0)>elapsed or not aim.is_finite():return false
 if aim.length()<.01:aim=Vector2.from_angle(p.facing*PI/4)
 aim=aim.normalized();p.facing=posmod(roundi(aim.angle()/(PI/4)),8)
 if id in ["blink","dash"]:p.position=L.move(p.position,p.position+aim*(120 if id=="blink" else 160));p.ground=p.position
 elif id=="mimic":
  var targets:=visible(p.id).filter(func(a: Dictionary)->bool:return a.id!="" and a.id!=p.id)
  targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return p.position.distance_to(a.position)<p.position.distance_to(b.position))
  if targets.is_empty():return false
  p.copy=targets[0].id;p.buff.mimic=elapsed+9
 elif id=="transform":
  var nearest: Dictionary=L.object_near(p.position,86)
  if nearest.is_empty():return false
  p.form=nearest.kind;p.form_origin=nearest.p;p.wobble=0;p.buff.transform=elapsed+9
  burst(p.position,"fx_poof",.6);event("transform",p.id,nearest.kind)
 elif id in ["sense","shield"]:p.buff[id]=elapsed+(4 if id=="sense" else 8)
 elif id=="clone":
  serial+=1;effects.append({"id":serial,"kind":"clone","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"character":p.character,"born":elapsed,"until":elapsed+8})
 elif id=="smoke":
  serial+=1;effects.append({"id":serial,"kind":"smoke","owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"born":elapsed,"until":elapsed+6})
 if id in ["blink","shield"]:burst(p.position,"fx_talisman",.6,{"facing":p.facing})
 elif id in ["dash","clone"]:burst(p.position,"fx_shadow",.55,{"facing":p.facing})
 elif id=="mimic":burst(p.position,"fx_foxfire",.8)
 elif id=="sense":burst(p.position,"fx_ghost",.9)
 elif id=="smoke":burst(p.position,"fx_flame",.7)
 p.cd[id]=elapsed+spec.skill.cd;event("skill",p.id,id);return true
func circle() -> Dictionary:
 var centers: Array[Vector2]=[Vector2(1700,1360),Vector2(1700,1360),Vector2(1700,1370),Vector2(1710,1380)]
 var radii: Array[float]=[2700,1750,1150,620]
 var stage:=0 if elapsed<180 else (1 if elapsed<360 else (2 if elapsed<480 else 3))
 var next:=mini(3,stage+1);var due:=180.0 if stage==0 else (360.0 if stage==1 else (480.0 if stage==2 else 600.0))
 var blend:=clampf((elapsed-([0,180,360,480][stage]))/30.0,0,1) if stage>0 else 1.0
 return {"stage":stage,"center":centers[stage-1].lerp(centers[stage],blend) if stage>0 else centers[0],"radius":lerpf(radii[stage-1],radii[stage],blend) if stage>0 else radii[0],"next_center":centers[next],"next_radius":radii[next],"until":maxf(0,due-elapsed)}
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
 if phase=="countdown":
  countdown=maxf(0,countdown-delta)
  if countdown<=0:
   phase="live"
   # 시작 신호와 동시에 요괴가 바로 앞 도사를 봉인하던 문제: 6초 유예를 준다.
   for p in players.values():
    if p.role=="yokai":p.cd["seal"]=maxf(float(p.cd.get("seal",0.0)),elapsed+SEAL_GRACE)
  return
 if phase!="live":return
 elapsed=minf(600,elapsed+delta)
 var zone:=circle()
 for p in players.values():
  if p.eliminated:continue
  p.alive_seconds=elapsed
  if p.captured and elapsed>=p.deadline:
   # 10초 안에 구조받지 못했다: 목숨 1개 차감.
   p.captured=false;p.deadline=0.0;p.rescue="";p.progress=0
   p.lives=maxi(0,int(p.lives)-1);p.stats.lost=maxi(0,int(p.stats.get("lost",0)))+1;event("lose_life",p.id)
   if p.lives<=0:
    p.eliminated=true;event("eliminate",p.id);continue
   # 목숨이 남았으면 시작한 자리로 풀려나 잠시 재봉인 면역을 받는다.
   p.position=p.home if L.can_stand(p.home) else L.safe(L.SPAWN)
   p.ground=p.position;p.origin=p.position;p.immune=elapsed+REVIVE_IMMUNE
   p.intent=Vector2.ZERO;p.running=false;p.jump=0;p.height=0;p.stamina=100;p.exhausted=false
   event("revive",p.id);continue
  if p.captured:continue
  if p.form!="" and p.buff.get("transform",0)<=elapsed:
   p.form="";p.buff.erase("transform");event("untransform",p.id)
  # 2.0.26: 사물로 둔갑한 채로도 걸어 다닐 수 있다. 둔갑은 지속시간·다시 누르기·
  # 점프·봉인으로만 풀린다(움직여도 풀리지 않는다).
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
  if p.stagger>elapsed:speed=0.0
  if p.outside>circle_penalty_after:speed*=circle_speed_factor
  # 둔갑 중 이동: 사물답게 조금 느리게(고양이는 가장 빠름).
  if p.form!="":speed*=(.95 if String(p.form)=="cat" else .87)
  p.position=L.move(p.position,p.position+p.intent*speed*delta,p.height>12)
  if p.jump<=0 and not L.can_stand(p.position):p.position=L.safe(p.position)
  if L.can_stand(p.position):p.ground=p.position
  var distance: float=p.position.distance_to(previous);p.stride+=distance
  if distance>0 and (p.trail.is_empty() or p.position.distance_to(p.trail[-1].position)>=18):p.trail.append({"position":p.position,"time":elapsed,"facing":p.facing})
  while not p.trail.is_empty() and elapsed-p.trail[0].time>6:p.trail.pop_front()
 contact_seal()
 # 기력 구슬: 스쳐 지나가면 자동으로 달리기 기력이 회복된다.
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
  if p.progress>=RESCUE_TIME-0.00001:q.captured=false;q.immune=elapsed+3;p.stats.rescues+=1;event("rescue",p.id,q.id);p.rescue="";p.progress=0
 for e in effects:
  if e.kind=="clone":e.position=L.move(e.position,e.position+Vector2.from_angle(e.facing*PI/4)*36*delta)
 effects=effects.filter(func(e: Dictionary)->bool:return e.until>elapsed)
 var alive:=players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.eliminated).size()
 if alive==0:finish("yokai")
 elif elapsed>=600:finish("daoist")
func finish(team: String) -> void:
 phase="result";winner=team
 for p in players.values():p.intent=Vector2.ZERO;p.running=false;p.rescue="";p.progress=0
func visible(id: String) -> Array:
 var viewer: Dictionary=players[id];var result: Array=[]
 for p in players.values():
  if p.eliminated:continue
  var distance: float=viewer.position.distance_to(p.position)
  if p.id!=id and (distance>360 or not L.line(viewer.position,p.position)):continue
  var blocked:=false
  for e in effects:
   if e.kind=="smoke" and distance>85 and Geometry2D.get_closest_point_to_segment(e.position,viewer.position,p.position).distance_to(e.position)<115:blocked=true
  if blocked and p.id!=id:continue
  var source: Dictionary=players.get(p.copy,p) if p.buff.get("mimic",0)>elapsed else p
  result.append({"id":"" if p.form!="" and p.id!=id else p.id,"position":p.position,"form":p.form,"name":source.name,"role":source.role,"color":source.color,"cosmetic":C.look(source.character),"character":source.character,"facing":p.facing,"height":p.height,"moving":p.intent.length()>.05 and not p.captured,"captured":p.captured,"immune":p.immune>elapsed,"shield":p.buff.get("shield",0)>elapsed})
 return result
