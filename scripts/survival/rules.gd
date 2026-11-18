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
var selection_left:=25.0
var selection_elapsed:=0.0
func _init(seed_value: int=0) -> void:
 if seed_value==0:rng.randomize()
 else:rng.seed=seed_value
func add(id: String,name: String,daoist: String,yokai: String) -> bool:
 if phase!="room" or players.size()>=8 or C.find(daoist).is_empty() or C.find(yokai).is_empty():return false
 players[id]={"id":id,"name":name,"choices":{"daoist":daoist,"yokai":yokai},"role":"","character":"","position":L.SPAWN,"facing":2,"intent":Vector2.ZERO,"running":false,"stamina":100.0,"exhausted":false,"jump":0.0,"height":0.0,"ground":L.SPAWN,"cd":{},"buff":{},"captured":false,"deadline":0.0,"eliminated":false,"immune":0.0,"rescue":"","progress":0.0,"origin":L.SPAWN,"outside":0.0,"form":"","copy":"","trail":[],"stride":0.0,"alive_seconds":0.0,"stats":{"seals":0,"misses":0,"rescues":0},"confirmed":false,"ready":id!="human","color":players.size()}
 return true
func start() -> bool:
 if phase!="room" or players.size() not in [6,8]:return false
 if not players.values().all(func(p: Dictionary)->bool:return p.ready):return false
 var ids: Array=players.keys()
 for i in range(ids.size()-1,0,-1):
  var j:=rng.randi_range(0,i);var value=ids[i];ids[i]=ids[j];ids[j]=value
 for i in range(ids.size()):
  var p: Dictionary=players[ids[i]];p.role="yokai" if i<2 else "daoist";p.character=""
  p.position=L.safe(L.SPAWN+Vector2.from_angle(i*TAU/ids.size())*150);p.ground=p.position
 phase="selection";selection_left=25;selection_elapsed=0;return true
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
  p.jump=.8;p.ground=p.position;return true
 if op=="seal":return seal(p)
 if op=="rescue":
  var target: String=data.get("target","")
  if p.role!="daoist" or not players.has(target):return false
  var q: Dictionary=players[target]
  if not q.captured or q.eliminated or p.position.distance_to(q.position)>58 or not L.line(p.position,q.position):return false
  if p.rescue!=target:p.rescue=target;p.progress=0;p.origin=p.position
  p.intent=Vector2.ZERO;return true
 if op=="skill":return skill(p,data.get("aim",Vector2.from_angle(p.facing*PI/4)))
 return false
func seal(p: Dictionary) -> bool:
 if p.role!="yokai" or float(p.cd.get("seal",0))>elapsed:return false
 var q: Dictionary={};var best:=61.0;var forward:=Vector2.from_angle(p.facing*PI/4)
 for candidate in players.values():
  var delta: Vector2=candidate.position-p.position;var distance:=delta.length()
  if candidate.role!="daoist" or candidate.captured or candidate.eliminated or candidate.immune>elapsed:continue
  if distance<best and (distance<5 or forward.dot(delta.normalized())>.64) and L.line(p.position,candidate.position):q=candidate;best=distance
 if not q.is_empty() and q.buff.get("shield",0)>elapsed:q.buff.erase("shield");q={}
 serial+=1;effects.append({"id":serial,"kind":"seal" if not q.is_empty() else "miss","position":p.position,"until":elapsed+.5,"cosmetic":C.look(p.character),"facing":p.facing})
 p.cd.seal=elapsed+(12.0 if not q.is_empty() else 6.0)
 if q.is_empty():p.stats.misses+=1;event("miss",p.id);return true
 q.captured=true;q.deadline=elapsed+45;q.intent=Vector2.ZERO;q.running=false;q.jump=0;q.height=0;q.rescue="";q.progress=0;p.stats.seals+=1;event("seal",p.id,q.id);return true
func skill(p: Dictionary,aim: Vector2) -> bool:
 var spec: Dictionary=C.find(p.character);var id: String=spec.active
 if id=="transform" and p.buff.get(id,0)>elapsed:p.buff.erase(id);p.form="";return true
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
  var nearest: Dictionary={};var dist:=70.0
  for object in L.OBJECTS:
   if p.position.distance_to(object.p)<dist:dist=p.position.distance_to(object.p);nearest=object
  if nearest.is_empty():return false
  p.form=nearest.kind;p.buff.transform=elapsed+9
 elif id in ["sense","shield"]:p.buff[id]=elapsed+(4 if id=="sense" else 8)
 elif id in ["clone","smoke"]:
  serial+=1;effects.append({"id":serial,"kind":id,"owner":p.id,"position":p.position,"facing":p.facing,"cosmetic":C.look(p.character),"until":elapsed+(8 if id=="clone" else 6)})
 p.cd[id]=elapsed+spec.skill.cd;event("skill",p.id,id);return true
func circle() -> Dictionary:
 var centers: Array[Vector2]=[Vector2(900,700),Vector2(900,700),Vector2(950,700),Vector2(910,720)]
 var radii: Array[float]=[1200,760,520,360]
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
    if C.find(p.character).is_empty():p.character=C.catalog(p.role)[rng.randi_range(0,C.catalog(p.role).size()-1)].id
    confirm_character(p.id)
  return
 if phase=="countdown":
  countdown=maxf(0,countdown-delta)
  if countdown<=0:phase="live"
  return
 if phase!="live":return
 elapsed=minf(600,elapsed+delta)
 var zone:=circle()
 for p in players.values():
  if p.eliminated:continue
  p.alive_seconds=elapsed
  if p.captured and elapsed>=p.deadline:p.captured=false;p.eliminated=true;p.rescue="";event("eliminate",p.id);continue
  if p.captured:continue
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
  if p.outside>circle_penalty_after:speed*=circle_speed_factor
  if p.buff.get("transform",0)>elapsed:speed*=.65
  else:p.form=""
  p.position=L.move(p.position,p.position+p.intent*speed*delta,p.height>12)
  if p.jump<=0 and not L.can_stand(p.position):p.position=L.safe(p.position)
  if L.can_stand(p.position):p.ground=p.position
  var distance: float=p.position.distance_to(previous);p.stride+=distance
  if distance>0 and (p.trail.is_empty() or p.position.distance_to(p.trail[-1].position)>=18):p.trail.append({"position":p.position,"time":elapsed,"facing":p.facing})
  while not p.trail.is_empty() and elapsed-p.trail[0].time>6:p.trail.pop_front()
 for p in players.values():
  if p.rescue=="":continue
  var q: Dictionary=players.get(p.rescue,{})
  if not available(p) or q.is_empty() or not q.captured or q.eliminated or p.position.distance_to(p.origin)>.5 or p.position.distance_to(q.position)>58:p.rescue="";p.progress=0;continue
  p.progress+=delta
  if p.progress>=4-0.00001:q.captured=false;q.immune=elapsed+3;p.stats.rescues+=1;event("rescue",p.id,q.id);p.rescue="";p.progress=0
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
  result.append({"id":"" if p.form!="" and p.id!=id else p.id,"position":p.position,"form":p.form,"name":source.name,"role":source.role,"color":source.color,"cosmetic":C.look(source.character),"facing":p.facing,"height":p.height,"moving":p.intent.length()>.05 and not p.captured,"captured":p.captured,"immune":p.immune>elapsed,"shield":p.buff.get("shield",0)>elapsed})
 return result
