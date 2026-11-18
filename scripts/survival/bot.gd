extends RefCounted
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
func _init(authority: RefCounted,pathfinder: RefCounted,uid: String,number: int) -> void:rules=authority;nav=pathfinder;id=uid;index=number
func command(op: String,data: Dictionary={}) -> bool:return rules.command(id,op,data)
func go(p: Vector2,target: Vector2) -> void:
 if previous.is_finite() and previous.distance_to(p)<1:stuck+=.35
 else:stuck=0
 previous=p
 if target.distance_to(goal)>35 or route.is_empty() or stuck>1.5:goal=target;route=nav.path(p,target);stuck=0
 while not route.is_empty() and p.distance_to(route[0])<18:route.remove_at(0)
 var v: Vector2=p.direction_to(route[0]) if not route.is_empty() else Vector2.ZERO
 command("move",{"vector":v});command("run",{"held":v.length()>0 and rules.players[id].stamina>30})
func think(delta: float) -> void:
 var me: Dictionary=rules.players[id]
 if not rules.available(me):return
 if me.rescue!="":command("move",{"vector":Vector2.ZERO});return
 wait-=delta
 var p: Vector2=me.position;var zone: Dictionary=rules.circle();var actors: Array=rules.visible(id)
 if p.distance_to(zone.center)>zone.radius-75:go(p,rules.L.safe(zone.center));return
 if me.role=="daoist":
  var threats: Array=actors.filter(func(a: Dictionary)->bool:return a.id!=id and a.role=="yokai" and a.form=="")
  if not threats.is_empty():
   var threat: Vector2=threats[0].position
   var away: Vector2=(p-threat).normalized()
   go(p,rules.L.safe(p+away*230+away.orthogonal()*60*sin(index)))
   if wait<=0:command("skill",{"aim":away});wait=1.1
   return
  var prisoners: Array=actors.filter(func(a: Dictionary)->bool:return a.captured and a.id!="")
  if not prisoners.is_empty():
   var q: Dictionary=prisoners[0]
   if p.distance_to(q.position)<55:command("move",{"vector":Vector2.ZERO});command("rescue",{"target":q.id})
   else:go(p,q.position)
   return
  if wait<=0 and rules.C.find(me.character).active=="transform":
   if command("skill"):wait=5;command("move",{"vector":Vector2.ZERO});return
  var points: Array=[Vector2(435,700),Vector2(860,720),Vector2(1260,1010),Vector2(620,1000),Vector2(1040,520),Vector2(480,1100),Vector2(1250,880)]
  var target: Vector2=rules.L.safe(points[(index+patrol)%points.size()])
  if target.distance_to(zone.center)>zone.radius-70:target=rules.L.safe(zone.center+Vector2.from_angle(index*TAU/8)*zone.radius*.55)
  if p.distance_to(target)<50:patrol+=1
  go(p,target)
 else:
  var targets: Array=actors.filter(func(a: Dictionary)->bool:return a.id!=id and a.role=="daoist" and not a.captured and a.form=="")
  targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return p.distance_to(a.position)<p.distance_to(b.position))
  if not targets.is_empty():
   var q: Dictionary=targets[0];go(p,q.position)
   if p.distance_to(q.position)<58:
    command("move",{"vector":p.direction_to(q.position)});command("seal")
   elif wait<=0:command("skill",{"aim":p.direction_to(q.position)});wait=1.1
   return
  # Search real props/decoys without consulting hidden transformed player IDs.
  var objects: Array=rules.L.OBJECTS
  var target: Vector2=objects[(index+patrol)%objects.size()].p
  for e in rules.effects:
   if e.kind=="clone" and p.distance_to(e.position)<200 and not inspected.has(e.id):target=e.position
  if p.distance_to(target)<55:
   command("move",{"vector":p.direction_to(target)});command("seal");patrol+=1
   for e in rules.effects:
    if e.kind=="clone" and p.distance_to(e.position)<70:inspected[e.id]=true
  else:go(p,target)
