extends SealConnection
## In-process authority. No sockets, account tickets, rewards or persistence.
const Rules=preload("res://scripts/seal/rules.gd")
const Bot=preload("res://scripts/simulation/bot.gd")
const Nav=preload("res://scripts/simulation/navigation.gd")
var rules: SealRules
var brains: Dictionary={}
var nav: RefCounted
var count:=6
var test_slots:=2
var countdown:=-1.0
var accumulator:=0.0
var broadcast:=0.0
var decisions:=0.0
var history: Array=[]
var tally: Dictionary={}
var action_index:=0
var watchers: Dictionary={}
var spectate:=""
var suspended:=false
var selected: Array=["blink","shield"]
var appearance: Dictionary={}
var seed_value:=0
var staged_start:=false
func _ready() -> void:
 uid="local-human";room="오프라인";endpoint="local-simulation";authenticated=true
 rebuild()
func rebuild() -> void:
 action_index=0;decisions=0;broadcast=0;accumulator=0
 var previous_round: int=rules.round_number if rules!=null else 0
 rules=Rules.new("모의전",seed_value+previous_round if seed_value!=0 else 0,{"map_pool":preload("res://scripts/simulation/maps.gd").playable()});rules.round_number=previous_round;brains.clear();history.clear();tally.clear();watchers.clear();spectate="";countdown=-1
 var chars: Array=["woochi","yeonhwa","muyeong","hongryeon"]
 for i in range(count):
  var id: String=uid if i==0 else "bot-%d"%i
  var slots: Array=preload("res://scripts/seal/loadout.gd").known(selected) if i==0 else [C.COMMON.keys()[i%8],C.COMMON.keys()[(i+3)%8]]
  if test_slots==3 and slots.size()<3:slots.append("track" if not slots.has("track") else "smoke")
  rules.add(id,"나" if i==0 else "수련 도사 %d · 봇"%i,slots,{"owned_spells":C.COMMON.keys(),"tier":"pass" if test_slots==3 else "paid"})
  rules.command(id,{"op":"appearance","appearance":appearance if i==0 else preload("res://scripts/wardrobe/catalog.gd").base_appearance(chars[i%4])})
  rules.command(id,{"op":"ready","value":i!=0})
  tally[id]={"tasks":0,"captures":0,"rescues":0}
  if i>0:brains[id]=Bot.new(self,id,i)
 nav=null
func configure_size(value: int,slots: int) -> void:
 if rules.phase!="lobby" or countdown>=0:return
 count=clampi(value,6,8);test_slots=clampi(slots,2,3);rebuild();publish()
func send(data: Dictionary) -> bool:
 if not authenticated:return false
 var op: String=str(data.get("op",""))
 if countdown>=0 and op in ["loadout","appearance","ready"]:return false
 if op=="start":
  if countdown>=0 or rules.phase!="lobby":return false
  for p in rules.players.values():
   if not p.ready:status.emit("준비 완료를 먼저 누르세요");return false
  countdown=3.0;status.emit("3초 후 시작 · 맵과 역할은 시작할 때 무작위 선정");return true
 if op=="rematch" and rules.phase=="result":rebuild();publish();return true
 if op=="spectate":
  var target: String=str(data.get("target",""))
  if rules.players[uid].sealed and rules.players.has(target) and not rules.players[target].sealed:spectate=target
  publish();return true
 var reply:=act(uid,data)
 if op=="loadout" and not reply.has("error"):selected=rules.players[uid].slots.duplicate()
 if op=="appearance" and not reply.has("error"):appearance=rules.players[uid].cosmetic.duplicate(true)
 if not reply.is_empty():packet.emit({"op":"reply"}.merged(reply))
 publish();return not reply.has("error")
func act(id: String,data: Dictionary) -> Dictionary:
 var target_id: String=str(data.get("target",""))
 var already_captured: bool=rules.players.get(target_id,{}).get("captured",false)
 var captures: Array=[]
 if data.get("op","")=="cast" and data.get("skill","")=="capture":
  for watcher in rules.players:
   if rules.can_observe(watcher,id):captures.append(watcher)
 var reply:=rules.command(id,data)
 if not reply.has("error") and data.get("op","")=="cast" and data.get("skill","")=="capture":
  var target: String=str(data.get("target",""))
  if rules.players.has(target) and rules.players[target].captured and not already_captured:
   for watcher in captures:
    if not watchers.has(watcher):watchers[watcher]={}
    watchers[watcher][id]=true
 consume_actions()
 return reply
func step(delta: float) -> void:
 if suspended:return
 if countdown>=0:
  countdown-=delta
  if countdown<=0:
   countdown=-1
   if rules.start(uid):
    if not staged_start:nav=Nav.new(rules.arena)
    status.emit("선정 맵: "+rules.arena.data.name+" · 오프라인 모의전")
  return
 if rules.phase in ["lobby","result"] or nav==null:return
 rules.tick(delta)
 consume_actions()
 decisions+=delta
 if decisions>=.35:
  var spent:=decisions;decisions=0
  for brain in brains.values():brain.think(spent)
func consume_actions() -> void:
 while action_index<rules.actions.size():
  var action: Dictionary=rules.actions[action_index];action_index+=1;history.append(action.duplicate(true))
  var actor: String=action.get("actor","")
  if not tally.has(actor):continue
  if action.kind=="task":tally[actor].tasks+=1
  elif action.kind=="capture":tally[actor].captures+=1
  elif action.kind=="rescue":tally[actor].rescues+=1
func publish() -> void:
 if rules==null:return
 var snapshot:=rules.view(uid)
 if rules.players[uid].sealed:
  var live: Array=rules.players.keys().filter(func(id: String)->bool:return not rules.players[id].sealed)
  if not live.has(spectate):spectate=str(live[0]) if not live.is_empty() else uid
  if spectate!=uid:
   var observer:=rules.view(spectate);snapshot.actors=observer.actors;snapshot.effects=observer.effects;snapshot.self.position=observer.self.position
 snapshot.simulation=true;snapshot.countdown=maxf(0,countdown);snapshot.spectate=spectate;snapshot.stats=tally.duplicate(true)
 if rules.phase=="result":
  snapshot.history=history.duplicate(true)
  for member in snapshot.roster:member.role=rules.players[member.uid].role
 packet.emit({"op":"state","state":snapshot})
func stop() -> void:authenticated=false;set_process(false)
func _process(delta: float) -> void:
 accumulator+=minf(delta,.25)
 var n:=0
 while accumulator>=.05 and n<5:step(.05);accumulator-=.05;n+=1
 broadcast+=delta
 if broadcast>=.1:broadcast=0;publish()
