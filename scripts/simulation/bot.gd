extends RefCounted
## Human-paced decisions from this participant's filtered view; no enemy role lookup.
var session: Node
var uid: String
var index: int
var route:=PackedVector2Array()
var goal:=Vector2.INF
var stalled:=0.0
var previous:=Vector2.INF
var wait:=0.0
var challenge: Dictionary={}
var visits:=0
var action:="explore"
var examined: Dictionary={}
func _init(owner_node: Node,id: String,number: int) -> void:session=owner_node;uid=id;index=number
func send(data: Dictionary) -> Dictionary:return session.act(uid,data)
func move_to(p: Vector2,target: Vector2) -> bool:
 if p.distance_to(target)<42:send({"op":"move","intent":[0,0]});return true
 if previous.is_finite() and previous.distance_to(p)<2:stalled+=.35
 else:stalled=0
 previous=p
 if goal.distance_to(target)>35 or route.is_empty() or stalled>1.5:
  goal=target;route=session.nav.path(p,target);stalled=0
 while not route.is_empty() and p.distance_to(route[0])<17:route.remove_at(0)
 if route.is_empty():send({"op":"move","intent":[0,0]});goal=Vector2.INF;return false
 var v: Vector2=p.direction_to(route[0]);send({"op":"move","intent":[v.x,v.y],"facing":posmod(roundi(v.angle()/(PI/4)),8)})
 return false
func think(delta: float) -> void:
 var view: Dictionary=session.rules.view(uid);var me: Dictionary=view.self
 if me.sealed or me.captured or me.penalty>0:return
 if view.phase=="vote":
  var suspect:="skip"
  for id in session.watchers.get(uid,{}):
   for member in view.roster:
    if member.uid==id and not member.sealed:suspect=id
  send({"op":"vote","target":suspect});return
 if view.phase not in ["prepare","roam"]:return
 if view.phase=="prepare" and me.role=="yokai":return
 wait-=delta
 var p:=Vector2(me.position[0],me.position[1])
 var suspects: Dictionary=session.watchers.get(uid,{})
 # A witnessed capture is evidence; a private role list is never consulted.
 if me.role=="daoist" and not suspects.is_empty() and view.resources>0 and view.phase=="roam":
  action="meeting"
  if move_to(p,session.rules.arena.altar):send({"op":"meeting"})
  return
 var visible: Array=view.actors.filter(func(a: Dictionary)->bool:return a.uid!=uid)
 if me.role=="yokai":
  var targets: Array=visible.filter(func(a: Dictionary)->bool:
   if me.teammates.has(a.uid):return false
   for member in view.roster:
    if member.uid==a.uid:return not member.captured and not member.sealed
   return false)
  targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return p.distance_to(Vector2(a.position[0],a.position[1]))<p.distance_to(Vector2(b.position[0],b.position[1])))
  for effect in view.effects:
   if effect.kind!="clone" or examined.has(effect.id):continue
   var illusion:=Vector2(effect.position[0],effect.position[1])
   if targets.is_empty() or p.distance_to(illusion)<p.distance_to(Vector2(targets[0].position[0],targets[0].position[1])):
    action="inspect decoy"
    if move_to(p,illusion):examined[effect.id]=true;wait=1.0
    return
  if not targets.is_empty():
   var target: Dictionary=targets[0];var q:=Vector2(target.position[0],target.position[1]);action="hunt"
   if wait<=0 and p.distance_to(q)<210:send({"op":"cast","skill":"mimic","target":target.uid});wait=1.2
   if p.distance_to(q)<47:send({"op":"move","intent":[0,0]});send({"op":"cast","skill":"capture","target":target.uid});return
   if float(me.cooldowns.get("capture",0))<=0:move_to(p,q);return
   # Reposition after capture rather than camping the prison indefinitely.
  var stations: Array=session.rules.arena.data.stations
  var patrol: Vector2=stations[(index+visits)%stations.size()]
  action="patrol"
  if move_to(p,patrol):visits+=1
  use_spell(me,visible,p,false);return
 for actor in visible:
  if suspects.has(actor.uid) and p.distance_to(Vector2(actor.position[0],actor.position[1]))<145:
   action="flee";use_spell(me,visible,p,true)
   move_to(p,session.rules.arena.safe(p+(p-Vector2(actor.position[0],actor.position[1])).normalized()*210));return
 var prisoners: Array=view.roster.filter(func(r: Dictionary)->bool:return r.captured and not r.sealed and r.uid!=uid)
 if not prisoners.is_empty():
  action="rescue"
  var target: String=prisoners[(index-1)%prisoners.size()].uid
  if move_to(p,session.rules.arena.jail):
   if me.slots.has("rescue"):send({"op":"cast","skill":"rescue"})
   send({"op":"rescue","target":target})
  return
 use_spell(me,visible,p,false)
 for effect in view.effects:
  if effect.kind=="flame" and not examined.has(effect.id):
   action="inspect flame"
   if move_to(p,Vector2(effect.position[0],effect.position[1])):examined[effect.id]=true;wait=1.0
   return
 var pending: Array=view.missions.filter(func(m: Dictionary)->bool:return not m.done)
 if pending.is_empty():
  action="prayer"
  if move_to(p,session.rules.arena.altar):send({"op":"fallback"})
  return
 var m: Dictionary=pending[(index-1)%pending.size()];var dest:=Vector2(m.position[0],m.position[1]);action="task"
 if me.carry!="":m=view.missions[int(me.carry)];dest=session.rules.arena.altar
 if m.kind=="fragments" and me.fragments.size()<3:
  var piece:=0
  while me.fragments.has(piece):piece+=1
  dest=session.rules.arena.safe(dest+Vector2.from_angle(piece*TAU/3)*78)
  if move_to(p,dest):send({"op":"collect","mission":m.id,"piece":piece})
  return
 if not move_to(p,dest):challenge={};return
 if wait>0:return
 if not challenge.is_empty() and int(challenge.mission)==int(m.id):
  var answer: Variant=challenge.pattern if m.kind=="well" else challenge.pattern[int(challenge.step)]
  var reply:=send({"op":"task","mission":m.id,"nonce":challenge.nonce,"answer":answer});challenge={};wait=.7
 else:
  var reply:=send({"op":"task_open","mission":m.id});challenge=reply.get("challenge",{});wait=.75
func use_spell(me: Dictionary,visible: Array,p: Vector2,danger: bool) -> void:
 if wait>0:return
 for skill in me.slots:
  if skill=="" or float(me.cooldowns.get(skill,0))>0:continue
  if skill=="transform":
   if not me.forms.is_empty():send({"op":"cast","skill":skill});wait=2;return
   for asset in session.rules.arena.assets:
    if p.distance_to(session.rules.arena.asset_position(asset,session.rules.elapsed))<65:send({"op":"extract","asset":asset.id});return
  elif skill in ["shield","smoke","clone","blink"] and danger:
   send({"op":"cast","skill":skill});wait=1.4;return
  elif skill in ["track","mask"]:
   send({"op":"cast","skill":skill});wait=1.4;return
