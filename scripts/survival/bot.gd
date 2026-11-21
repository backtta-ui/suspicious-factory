extends RefCounted
## 2.0.37 봇 AI 전면 개편.
## - 4맵 모두에서 그 맵의 구역·사물 좌표로 순찰한다(맵마다 고정 좌표를 쓰지 않는다).
## - 개체별 분산 목표 + 반발력(separation)으로 한곳에 뭉치지 않고, 끼면 옆으로 비켜 다시 경로를 잡는다.
## - 요괴: 둔갑한 도사라도 '움직이면' 의심 게이지가 올라 추적·확인 타격한다.
## - 도사: 위협 거리·쿨타임에 따라 둔갑·분신·도약·덫·보호막·귀문·혼길표식 등을 실제로 쓴다.
## - 요괴: 자기 고유 3도술(인간둔갑·여우향·소리추적·가짜보물·등불끄기·무월야 등)을 상황에 맞게 쓴다.
var rules: RefCounted
var nav: RefCounted
var id: String
var index: int
var route:=PackedVector2Array()
var goal:=Vector2.INF
var patrol:=0
var wait:=0.0
var previous:=Vector2.INF
var stuck:=0.0
var inspected: Dictionary={}
## 둔갑한 사물의 움직임을 기억해 의심 게이지를 쌓는다(요괴 전용).
var form_memory: Array=[]
var suspicion:=0.0
var suspect:=Vector2.INF
## 마지막으로 쓴 도술(테스트·디버그용).
var last_cast:=""
var skill_uses:=0
var seal_checks:=0
func _init(authority: RefCounted,pathfinder: RefCounted,uid: String,number: int) -> void:rules=authority;nav=pathfinder;id=uid;index=number
func command(op: String,data: Dictionary={}) -> bool:return rules.command(id,op,data)
func me() -> Dictionary:return rules.players.get(id,{})
func live() -> bool:
 var p: Dictionary=me()
 return not p.is_empty() and rules.available(p)
## ---------------------------------------------------------------- 이동
## 같은 자리에 뭉치지 않도록 가까운 동료·적에게서 밀려나는 힘을 더한다.
func separation(p: Vector2) -> Vector2:
 var push:=Vector2.ZERO
 var count:=0
 for other in rules.players.values():
  if String(other.id)==id or other.eliminated or other.captured:continue
  var gap: Vector2=p-other.position
  var dist: float=gap.length()
  if dist<150.0 and dist>0.5:
   push+=gap.normalized()*pow((150.0-dist)/150.0,1.4)
   count+=1
 if count==0:return Vector2.ZERO
 return push/float(count)
func go(p: Vector2,target: Vector2) -> void:
 if previous.is_finite() and previous.distance_to(p)<1.0:stuck+=.35
 else:stuck=0
 previous=p
 var nudge:=separation(p)*64.0
 var wanted: Vector2=target+nudge
 if wanted.distance_to(goal)>35 or route.is_empty() or stuck>1.5:
  # 끼면 목표를 옆으로 비틀어 우회한다(같은 길로 계속 밀어붙이지 않는다).
  if stuck>1.5:
   var side:=Vector2.from_angle(float(index)*2.1+float(patrol))*120.0
   wanted=rules.L.safe(wanted+side)
  goal=wanted
  route=nav.path(p,goal)
  stuck=0
 while not route.is_empty() and p.distance_to(route[0])<18:route.remove_at(0)
 var v: Vector2=p.direction_to(route[0]) if not route.is_empty() else Vector2.ZERO
 # 반발력을 실제 이동 벡터에도 섞어, 같은 목적지로 가더라도 서로 비켜 간다.
 if v.length()>.05:
  v=(v+separation(p)*2.2).limit_length(1.0)
 elif not route.is_empty():
  v=separation(p).limit_length(1.0)
 command("move",{"vector":v})
 command("run",{"held":v.length()>0 and float(me().get("stamina",0.0))>30})
## ---------------------------------------------------------------- 도술
func slot_of(skill_id: String) -> String:
 var character:=String(me().get("character",""))
 for slot in ["main","sub","ult"]:
  var spec: Dictionary=rules.C.ability(character,slot)
  if String(spec.get("skill",""))==skill_id:return slot
 return ""
func ready(skill_id: String) -> bool:
 var slot:=slot_of(skill_id)
 if slot=="":return false
 if slot=="ult" and float(me().get("ult",0.0))<rules.ULT_MAX:return false
 return float(me().get("cd",{}).get(skill_id,0.0))<=rules.elapsed
## 우선순위 목록에서 지금 쓸 수 있는 첫 도술을 시전한다.
func cast_first(skill_ids: Array,aim: Vector2) -> bool:
 for skill_id in skill_ids:
  if not ready(String(skill_id)):continue
  var slot:=slot_of(String(skill_id))
  if command("skill",{"aim":aim,"slot":slot}):
   last_cast=String(skill_id);skill_uses+=1;wait=1.2
   return true
 return false
## 궁극기 기운이 차 있으면 궁극기, 아니면 대표/보조 스킬을 번갈아 쓴다(호환용).
func prepare_skill(aim: Vector2) -> void:
 var p: Dictionary=me()
 var slot: String="main"
 if float(p.get("ult",0.0))>=rules.ULT_MAX:slot="ult"
 elif wait<-0.6:slot="sub"
 if command("skill",{"aim":aim,"slot":slot}):skill_uses+=1;last_cast=String(rules.C.ability(String(p.character),slot).get("skill",""))
## ---------------------------------------------------------------- 맵 순찰 지점
## 네 맵의 구역 중심 + 사물 좌표를 섞어 개체마다 다른 동선을 만든다.
func waypoints() -> Array:
 var points: Array=[]
 for zone in rules.L.zones():
  points.append((zone.rect as Rect2).get_center())
 for object in rules.L.OBJECTS:
  points.append(object.p)
 if points.is_empty():points.append(rules.L.SPAWN)
 return points
func roam_target(p: Vector2,zone: Dictionary) -> Vector2:
 var points:=waypoints()
 var target: Vector2=points[(index*3+patrol)%points.size()]
 # 다른 봇이 같은 지점을 향하고 있으면 옆으로 비켜 각자 다른 곳을 돈다.
 for other in rules.players.values():
  if String(other.id)==id or other.eliminated or other.captured:continue
  if (other.position as Vector2).distance_to(target)<150.0:
   target+=Vector2.from_angle(float(index)*TAU/7.0+float(patrol)*.9)*130.0
   break
 # 내 자리에서 너무 멀거나 가까우면 목표를 조금 흔들어 한 줄로 늘어서지 않게 한다.
 if target.distance_to(zone.center)>zone.radius-80:
  target=zone.center+Vector2.from_angle(float(index)*TAU/8.0+float(patrol)*.7)*zone.radius*.55
 return rules.L.safe(target)
## ---------------------------------------------------------------- 판단
func think(delta: float) -> void:
 if not live():return
 var p: Dictionary=me()
 if String(p.get("rescue",""))!="":
  command("move",{"vector":Vector2.ZERO})
  return
 wait-=delta
 var at: Vector2=p.position
 var zone: Dictionary=rules.circle()
 # 안전구역(자기장) 밖이면 먼저 안으로 들어온다. 네 맵 모두 같은 규칙.
 if at.distance_to(zone.center)>zone.radius-70:
  go(at,rules.L.safe(zone.center))
  return
 if String(p.role)=="daoist":daoist_think(delta,at,zone)
 else:yokai_think(delta,at,zone)
## ---------------------------------------------------------------- 도사 봇
func daoist_think(delta: float,at: Vector2,zone: Dictionary) -> void:
 var actors: Array=rules.visible(id)
 var threats: Array=actors.filter(func(a: Dictionary)->bool:return a.id!=id and a.role=="yokai" and not a.captured)
 threats.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return at.distance_to(a.position)<at.distance_to(b.position))
 var nearest: Dictionary=threats[0] if not threats.is_empty() else {}
 var gap: float=at.distance_to(nearest.position) if not nearest.is_empty() else 9999.0
 var away: Vector2=at.direction_to(nearest.position) if not nearest.is_empty() else Vector2.RIGHT
 # 1) 붙잡힌 동료 구조는 최우선(위협이 멀 때).
 var prisoners: Array=actors.filter(func(a: Dictionary)->bool:return a.captured and a.id!="")
 if not prisoners.is_empty() and gap>240.0:
  var q: Dictionary=prisoners[0]
  if at.distance_to(q.position)<55.0:
   command("move",{"vector":Vector2.ZERO})
   if command("rescue",{"target":q.id}):wait=.6
  else:go(at,q.position)
  return
 # 2) 위협이 가까우면: 둔갑 > 도약/가속 > 보호막 > 덫 순으로 대응한다.
 if gap<230.0:
  if gap<150.0:
   # 둔갑 중이면 멈춰 서서 사물처럼 위장한다(움직이면 들킨다).
   if String(me().get("form",""))!="":
    command("move",{"vector":Vector2.ZERO})
    return
   if cast_first(["transform","painting"],away):command("move",{"vector":Vector2.ZERO});return
  if gap<260.0:
   if cast_first(["wallhop","eightleap","windstep"],away):return
   if cast_first(["lifelamp","deathflower"],away):return
  go(at,rules.L.safe(at+away*260.0+away.orthogonal()*70.0*sin(float(index))))
  return
 # 3) 위협이 중간 거리면 덫·표식·탐지로 판을 깐다.
 if gap<460.0:
  if cast_first(["trap","soulmark","ghostgate","astrolabe","clone"],away):return
 # 4) 평소: 가짜 구조 신호에 유인되고, 없으면 맵 구역을 순찰한다.
 var lure:=Vector2.INF
 for e in rules.effects:
  if String(e.kind) not in ["fake_rescue","rescue_call"]:continue
  if at.distance_to(e.position)>320:continue
  if lure.is_finite() and at.distance_to(lure)<=at.distance_to(e.position):continue
  lure=e.position
 if lure.is_finite():
  go(at,rules.L.safe(lure))
  return
 if wait<=0 and cast_first(["clone","puppet"],at.direction_to(zone.center)):
  return
 var target:=roam_target(at,zone)
 if at.distance_to(target)<50.0:patrol+=1
 go(at,target)
## ---------------------------------------------------------------- 요괴 봇
func yokai_think(delta: float,at: Vector2,zone: Dictionary) -> void:
 var actors: Array=rules.visible(id)
 # 1) 둔갑한 사물 감시: 같은 자리에 있던 사물이 움직이면 의심한다.
 var seen_now: Array=[]
 for a in actors:
  if String(a.get("form",""))=="" or a.role!="daoist":continue
  var spot: Vector2=a.position
  var known:=false
  for memory in form_memory:
   if (memory.p as Vector2).distance_to(spot)<44.0:
    if (memory.p as Vector2).distance_to(spot)>8.0:suspicion=minf(3.0,suspicion+.55)
    memory.p=spot;memory.t=rules.elapsed;known=true;break
  if not known:form_memory.append({"p":spot,"t":rules.elapsed})
  seen_now.append(spot)
  if suspicion>=0.6:suspect=spot
 form_memory=form_memory.filter(func(m: Dictionary)->bool:return rules.elapsed-float(m.t)<14.0)
 if suspicion>0.0:suspicion=maxf(0.0,suspicion-delta*.12)
 # 2) 드러난 도사가 있으면 곧장 추격하고, 가까우면 고유 도술로 막는다.
 var targets: Array=actors.filter(func(a: Dictionary)->bool:return a.id!=id and a.role=="daoist" and not a.captured and String(a.get("form",""))=="" and String(rules.players.get(String(a.id),{}).get("role","daoist"))=="daoist")
 targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return at.distance_to(a.position)<at.distance_to(b.position))
 if not targets.is_empty():
  var q: Dictionary=targets[0]
  var aim: Vector2=at.direction_to(q.position)
  var gap: float=at.distance_to(q.position)
  if gap<300.0 and cast_first(["foxscent","mischief","faketreasure","goblinfest","mountaingrowl","voicemimic"],aim):
   return
  go(at,q.position)
  return
 # 3) 의심 지점이 있으면 다가가 '확인' 타격으로 둔갑을 벗긴다.
 if suspect.is_finite():
  if at.distance_to(suspect)<58.0:
   command("move",{"vector":Vector2.ZERO})
   if command("seal"):seal_checks+=1;suspicion=0.0;suspect=Vector2.INF;patrol+=1
  else:go(at,suspect)
  return
 # 4) 추적 정보가 없을 때: 자기 고유 탐지·암전 도술을 상황에 맞게 쓴다.
 if wait<=0:
  if cast_first(["soundhunt","shoeprints","footprintmap","astrolabe","mimic","foxdream","douse","moonlessnight","blackvision"],Vector2.from_angle(float(index)*TAU/5.0)):
   return
 var target:=roam_target(at,zone)
 if at.distance_to(target)<50.0:
  patrol+=1
  # 사물·구역을 확인 타격하며 둔갑 도사를 찾는다.
  command("move",{"vector":at.direction_to(target)})
  if command("seal"):seal_checks+=1
 else:go(at,target)
