class_name SealRules
extends RefCounted
## Pure server state. Public views are constructed independently for each recipient.
const C=preload("res://scripts/seal/catalog.gd")
const Map=preload("res://scripts/seal/map.gd")
var code: String
var players: Dictionary={}
var host:=""
var phase:="lobby"
var elapsed:=0.0
var phase_until:=0.0
var round_number:=0
var match_id:=""
var rewarded:=false
var resources:=0
var meetings:=0
var meeting_ready:=0.0
var votes: Dictionary={}
var missions: Array[Dictionary]=[]
var effects: Array[Dictionary]=[]
var channels: Dictionary={}
var winner:=""
var events: Array[Dictionary]=[]
var serial:=0
var nonce_serial:=0
var fallback_at:=0.0
var rng:=RandomNumberGenerator.new()
func _init(room_code: String="",seed_value: int=0) -> void:
 code=room_code
 if seed_value==0:rng.seed=Crypto.new().generate_random_bytes(8).decode_u64(0)
 else:rng.seed=seed_value
func event(message: String) -> void:
 serial+=1;events.append({"id":serial,"text":message})
 if events.size()>16:events.pop_front()
func add(uid: String,nick: String,loadout: Array) -> bool:
 if players.has(uid):players[uid].connected=true;players[uid].disconnected_at=0;return true
 if phase!="lobby" or players.size()>=8:return false
 var slots: Array=[]
 for s in loadout:
  if s is String and C.COMMON.has(s) and not slots.has(s) and slots.size()<2:slots.append(s)
 for s in ["transform","blink"]:
  if slots.size()<2 and not slots.has(s):slots.append(s)
 players[uid]={"cosmetic":preload("res://scripts/wardrobe/catalog.gd").DEFAULT.duplicate(),"career_wins":0,"uid":uid,"name":C.clean_name(nick),"role":"","connected":true,"ready":false,"position":Map.safe(Vector2(900+players.size()*24,680)),"facing":2,"intent":Vector2.ZERO,"slots":slots,"cd":{},"buff":{},"captured":false,"sealed":false,"penalty":0.0,"disconnected_at":0.0,"protected":0.0,"carry":"","fragments":[],"form_choice":"jar","fake_progress":{},"escape":1,"escape_until":0.0,"challenge":{},"trail":[],"trail_at":0.0,"chat_at":-10.0,"joined":players.size()}
 if host=="":host=uid
 event(players[uid].name+" 입장")
 return true
func mark_disconnected(uid: String) -> void:
 if not players.has(uid):return
 players[uid].connected=false;players[uid].disconnected_at=elapsed;players[uid].intent=Vector2.ZERO;players[uid].ready=false;channels.erase(uid)
 if host==uid:migrate_host()
func migrate_host() -> void:
 host=""
 for uid in players:
  if players[uid].connected and not players[uid].sealed:host=uid;break
func available(p: Dictionary) -> bool:return p.connected and not p.captured and not p.sealed and p.penalty<=elapsed
func roam(p: Dictionary) -> bool:return phase in ["prepare","roam"] and available(p) and not (phase=="prepare" and p.role=="yokai")
func near(p: Dictionary,point: Vector2,distance: float=78) -> bool:return p.position.distance_to(point)<=distance and Map.line(p.position,point)
func result(team: String,reason: String) -> void:
 if phase=="result":return
 phase="result";winner=team;channels.clear();event(reason)
func start(uid: String) -> bool:
 if uid!=host or phase!="lobby" or players.size()<6 or players.size()>8:return false
 for p in players.values():
  if not p.connected or not p.ready:return false
 var ids: Array=players.keys()
 # Fisher-Yates uses server RNG; no client seed or role input is accepted.
 for i in range(ids.size()-1,0,-1):
  var j:=rng.randi_range(0,i);var swap=ids[i];ids[i]=ids[j];ids[j]=swap
 rewarded=false
 match_id=Crypto.new().generate_random_bytes(8).hex_encode()
 round_number+=1;elapsed=0;phase="prepare";phase_until=C.PREPARATION;resources=0;meetings=0;meeting_ready=0;fallback_at=0;votes.clear();effects.clear();channels.clear();winner=""
 for i in range(ids.size()):
  var p: Dictionary=players[ids[i]];p.role="yokai" if i<2 else "daoist";p.position=Map.safe(Vector2(900+i*25,690));p.captured=false;p.sealed=false;p.penalty=0;p.cd={};p.buff={};p.escape=1;p.escape_until=0;p.carry="";p.fragments=[];p.challenge={};p.intent=Vector2.ZERO;p.protected=0
 var points: Array=Map.STATIONS.duplicate()
 for i in range(points.size()-1,0,-1):
  var j:=rng.randi_range(0,i);var swap=points[i];points[i]=points[j];points[j]=swap
 missions=[]
 for i in range(4):
  missions.append({"id":i,"kind":["pillars","well","soul","fragments"][i],"name":["사당의 봉인","우물 정화","혼불 운반","부적 복원"][i],"position":Map.safe(points[i]),"step":0,"done":false,"pattern":[rng.randi_range(0,3),rng.randi_range(0,3),rng.randi_range(0,3)]})
 event("봉인의 밤 · 30초 준비. 봉인 미션으로 기회를 모으세요.")
 return true
func command(uid: String,data: Dictionary) -> Dictionary:
 if not players.has(uid):return {"error":"방에 참가하지 않았습니다"}
 var p: Dictionary=players[uid]
 var op: String=str(data.get("op",""))
 if op=="appearance":
  if phase!="lobby":return {"error":"대전 중 외형 변경은 제한됩니다"}
  p.cosmetic=preload("res://scripts/wardrobe/catalog.gd").normalize(data.get("appearance",{}))
  return {}
 if op=="ready" and phase=="lobby":
  if data.get("value",false) is bool:p.ready=data.get("value",false)
  return {}
 if op=="start":return {} if start(uid) else {"error":"방장 · 연결된 6~8명 전원 준비가 필요합니다"}
 if op=="rematch" and phase=="result" and uid==host:
  phase="lobby";winner="";channels.clear();effects.clear()
  var drop: Array=[]
  for id in players:
   if not players[id].connected:drop.append(id)
   else:players[id].ready=false;players[id].captured=false;players[id].sealed=false;players[id].role=""
  for id in drop:players.erase(id)
  return {}
 if op=="move":
  p.intent=C.vector(data.get("intent",[])) if roam(p) else Vector2.ZERO
  var f=data.get("facing",p.facing)
  if C.finite_number(f):p.facing=posmod(int(f),8)
  return {}
 if op=="vote":
  if phase!="vote" or not available(p) or votes.has(uid):return {"error":"지금 투표할 수 없습니다"}
  var target: String=str(data.get("target","skip"))
  if target!="skip" and (not players.has(target) or players[target].sealed):return {"error":"잘못된 대상"}
  votes[uid]=target;return {}
 if op=="chat":
  if phase not in ["discuss","vote"] or not available(p) or elapsed-p.chat_at<1.2:return {}
  p.chat_at=elapsed;event(p.name+": "+C.clean_text(data.get("text",""),72))
  return {}
 if op=="escape" and p.captured and p.escape>0 and elapsed<p.escape_until:
  if not channels.has(uid):channels[uid]={"kind":"escape","until":elapsed+5.0,"origin":p.position}
  return {"notice":"자력해봉 중 · 이동하지 말고 기다리세요"}
 if not roam(p):return {"error":"현재 상태에서는 사용할 수 없습니다"}
 if op=="meeting":
  if phase!="roam" or resources<1 or meetings>=6 or elapsed<meeting_ready or not near(p,Map.ALTAR,110):return {"error":"중앙 봉인진 · 봉인 자원1 · 회의 대기시간을 확인하세요"}
  resources-=1;meetings+=1;phase="discuss";phase_until=elapsed+C.DISCUSSION;votes.clear();channels.clear()
  for q in players.values():q.intent=Vector2.ZERO
  event("봉인 회의가 시작되었습니다");return {}
 if op=="cast":return cast(p,str(data.get("skill","")),str(data.get("target","")))
 if op=="rescue":
  var target: String=str(data.get("target",""))
  if not players.has(target) or not players[target].captured or not near(p,players[target].position,68):return {"error":"감옥의 동료 가까이 접근하세요"}
  if channels.has(uid) and channels[uid].kind=="rescue" and channels[uid].target==target:return {"notice":"구출 중입니다"}
  channels[uid]={"kind":"rescue","target":target,"until":elapsed+(1.2 if p.buff.get("rescue",0)>elapsed else 3.0),"origin":p.position};return {}
 if op=="fallback":
  if resources>0 or elapsed<fallback_at or not near(p,Map.ALTAR,100):return {"error":"중앙 봉인진에서 자원이 없을 때 기도할 수 있습니다"}
  if not channels.has(uid):channels[uid]={"kind":"fallback","until":elapsed+4,"origin":p.position}
  return {"notice":"봉인진 기도 중 · 잠시 기다리세요"}
 if op in ["task_open","task","collect"]:return task(p,data)
 return {}
func cast(p: Dictionary,skill: String,target: String) -> Dictionary:
 var uid: String=p.uid
 var evil:=C.EVIL.has(skill)
 if evil and p.role!="yokai":return {"error":"이 능력을 사용할 수 없습니다"}
 if not evil and not p.slots.has(skill):return {"error":"장착하지 않은 도술입니다"}
 if not C.COMMON.has(skill) and not evil:return {"error":"알 수 없는 도술"}
 if p.cd.get(skill,0)>elapsed:return {"error":"재사용 대기 중입니다"}
 var info: Dictionary=C.EVIL[skill] if evil else C.COMMON[skill]
 if skill=="capture":
  if not players.has(target):return {"error":"가까운 대상을 선택하세요"}
  var q: Dictionary=players[target]
  if q.role!="daoist" or not available(q) or not near(p,q.position,48) or q.protected>elapsed:return {"error":"포획 범위 또는 보호 상태를 확인하세요"}
  if q.buff.get("shield",0)>elapsed:q.buff.erase("shield");q.protected=elapsed+2;p.cd[skill]=elapsed+info.cd;return {"notice":"호신부가 포획을 막았습니다"}
  q.captured=true;q.position=Map.safe(Map.JAIL+Vector2(rng.randf_range(-24,24),rng.randf_range(-18,18)));q.intent=Vector2.ZERO;q.escape_until=elapsed+12 if q.escape>0 else 0;channels.erase(q.uid)
 elif skill in ["blink","shadow"]:
  p.position=Map.move(p.position,p.position+Vector2.from_angle(p.facing*PI/4)*(150 if skill=="shadow" else 110))
 elif skill in ["mask","mimic"]:
  if not players.has(target) or players[target].sealed or not near(p,players[target].position,220):return {"error":"가까운 복제 대상을 선택하세요"}
  p.buff[skill]=elapsed+info.duration;p.buff["appearance"]=target
 elif skill in ["clone","smoke","darkness","fake_flame"]:
  effects.append({"id":serial+effects.size()+1,"kind":skill,"owner":uid,"position":p.position,"until":elapsed+info.duration,"name":p.name,"facing":p.facing,"cosmetic":p.cosmetic.duplicate()})
 elif skill in ["transform","track","shield","rescue"]:p.buff[skill]=elapsed+info.duration
 if skill=="darkness":
  for m in missions:
   if not m.done and near(p,m.position,110):m.jammed=elapsed+8
 p.cd[skill]=elapsed+float(info.cd)
 # Everyone can show a generic spell flash; no public role or ability packet is broadcast.
 p.buff["casting"]=elapsed+.45
 return {}
func task(p: Dictionary,data: Dictionary) -> Dictionary:
 var id=data.get("mission",-1)
 if not C.whole(id,0,missions.size()-1):return {"error":"잘못된 미션"}
 var m: Dictionary=missions[int(id)]
 if m.done:return {"error":"완료한 봉인은 초기화할 수 없습니다"}
 var target: Vector2=m.position
 var op: String=str(data.get("op",""))
 if m.kind=="soul" and p.carry==str(m.id):target=Map.ALTAR
 if m.kind=="fragments" and op=="collect":
  var piece=data.get("piece",-1)
  if not C.whole(piece,0,2):return {"error":"잘못된 조각"}
  target=Map.safe(m.position+Vector2.from_angle(int(piece)*TAU/3)*78)
  if not near(p,target):return {"error":"조각 가까이 접근하세요"}
  if not p.fragments.has(int(piece)):p.fragments.append(int(piece))
  return {"notice":"부적 조각 %d/3" % p.fragments.size()}
 if float(m.get("jammed",0))>elapsed:return {"error":"어둠의 방해 · 잠시 후 다시 시도하세요"}
 if not near(p,target):return {"error":"미션 지점 가까이 접근하세요"}
 if m.kind=="soul":
  if p.carry==str(m.id):
   p.carry="";complete_task(p,m);return {"notice":"혼불을 제단에 운반했습니다"}
  p.carry=str(m.id);return {"notice":"혼불을 들었습니다. 중앙 제단으로 운반하세요"}
 if m.kind=="fragments" and p.fragments.size()<3:return {"error":"주변 세 조각을 먼저 모으세요"}
 if op=="task_open":
  nonce_serial+=1;p.challenge={"mission":int(id),"nonce":str(nonce_serial)+":"+str(rng.randi()),"opened":elapsed}
  return {"challenge":{"mission":int(id),"kind":m.kind,"pattern":m.pattern.duplicate(),"step":m.step if p.role=="daoist" else int(p.fake_progress.get(str(m.id),0)),"nonce":p.challenge.nonce}}
 var challenge: Dictionary=p.challenge
 if challenge.get("mission",-1)!=int(id) or data.get("nonce","")!=challenge.get("nonce","missing") or elapsed-float(challenge.get("opened",elapsed))<.35:return {"error":"미션 화면을 다시 열고 문양을 확인하세요"}
 p.challenge={}
 var correct:=false
 var answer=data.get("answer",null)
 if m.kind=="well":correct=answer is Array and answer.size()==3 and C.whole(answer[0],0,3) and C.whole(answer[1],0,3) and C.whole(answer[2],0,3) and int(answer[0])==m.pattern[0] and int(answer[1])==m.pattern[1] and int(answer[2])==m.pattern[2]
 else:
  var step: int=m.step if p.role=="daoist" else int(p.fake_progress.get(str(m.id),0))
  correct=C.whole(answer,0,3) and int(answer)==int(m.pattern[step])
 if not correct:p.buff["warning"]=elapsed+2;return {"error":"문양이 맞지 않습니다. 경고빛이 발생했습니다"}
 if p.role!="daoist":p.buff["working"]=elapsed+2;p.fake_progress[str(m.id)]=(int(p.fake_progress.get(str(m.id),0))+1)%3;return {"notice":"부적을 살펴보았습니다 · 위장 행동"}
 m.step+=1
 if m.kind=="well" or m.step>=3:complete_task(p,m)
 return {"notice":"봉인 진행 %d/3" % m.step}
func complete_task(p: Dictionary,m: Dictionary) -> void:
 if p.role!="daoist" or m.done:return
 m.done=true;m.step=3;resources+=1;p.fragments=[];event(m.name+" 완료 · 봉인 기회 +1")
func tick(delta: float) -> void:
 elapsed+=clampf(delta,0,.1)
 var remove: Array=[]
 for uid in players:
  var p: Dictionary=players[uid]
  if not p.connected and elapsed-p.disconnected_at>C.RECONNECT:
   if phase=="lobby":remove.append(uid)
   else:p.sealed=true;p.escape=0
  if p.captured and elapsed>=p.escape_until:p.escape=0
  if roam(p):p.position=Map.move(p.position,p.position+p.intent*(64 if p.carry!="" else C.MOVE_SPEED)*delta)
  if p.intent.length()>.1 and elapsed-p.trail_at>.4:
   p.trail_at=elapsed;p.trail.append({"p":p.position,"time":elapsed})
   while p.trail.size()>12:p.trail.pop_front()
 for uid in remove:players.erase(uid)
 if host=="" or not players.has(host) or not players[host].connected:migrate_host()
 for i in range(effects.size()-1,-1,-1):
  if effects[i].until<=elapsed:effects.remove_at(i)
 for uid in channels.keys():
  if not players.has(uid):channels.erase(uid);continue
  var p: Dictionary=players[uid];var channel: Dictionary=channels[uid]
  if not p.connected or p.position.distance_to(channel.origin)>10 or (p.captured and channel.kind!="escape") or p.sealed:channels.erase(uid);continue
  if elapsed<channel.until:continue
  if channel.kind=="escape" and p.captured and p.escape>0:
   p.escape=0;p.captured=false;p.position=Map.safe(Map.JAIL+Vector2(-90,0));p.protected=elapsed+4
  elif channel.kind=="rescue" and p.role=="daoist" and players.has(channel.target):
   var q: Dictionary=players[channel.target]
   if q.captured and near(p,q.position,75):q.captured=false;q.position=Map.safe(Map.JAIL+Vector2(-90,0));q.protected=elapsed+4;q.buff["casting"]=elapsed+.8
  elif channel.kind=="fallback" and p.role=="daoist" and resources==0 and elapsed>=fallback_at:resources+=1;fallback_at=elapsed+65;event("봉인진 기도로 기회 +1")
  channels.erase(uid)
 if phase=="prepare" and elapsed>=phase_until:phase="roam";event("요괴의 이동 제한이 풀렸습니다")
 elif phase=="discuss" and elapsed>=phase_until:phase="vote";phase_until=elapsed+C.VOTE;event("지목할 대상을 투표하세요")
 elif phase=="vote" and elapsed>=phase_until:resolve_vote()
 if phase in ["prepare","roam","discuss","vote"]:check_win()
func resolve_vote() -> void:
 var counts: Dictionary={"skip":0}
 for uid in votes:
  var choice: String=votes[uid];counts[choice]=int(counts.get(choice,0))+1
 var best:=0;var selected:="skip";var tied:=false
 for id in counts:
  if counts[id]>best:best=counts[id];selected=id;tied=false
  elif counts[id]==best:tied=true
 if best>0 and not tied and selected!="skip" and players.has(selected):
  var p: Dictionary=players[selected]
  if p.role=="yokai":p.sealed=true;event(p.name+" · 진짜 요괴를 봉인했습니다")
  else:p.penalty=elapsed+35;event(p.name+" · 무고한 도사입니다. 35초 활동 제한")
 else:event("기권 또는 동점 · 봉인하지 않았습니다")
 phase="roam";meeting_ready=elapsed+45;votes.clear()
func check_win() -> void:
 var evil:=0;var rescuable:=false;var free_dao:=0
 for p in players.values():
  if p.role=="yokai" and not p.sealed:evil+=1
  if p.role=="daoist" and not p.sealed:
   if not p.captured:free_dao+=1
   elif p.escape>0 and elapsed<p.escape_until:rescuable=true
 if evil==0:result("daoist","요괴 두 명이 모두 봉인되었습니다")
 elif free_dao==0 and not rescuable:result("yokai","모든 도사가 포획되고 남은 구출 기회가 없습니다")
 elif elapsed>=C.MATCH_TIME:result("yokai","제한 시간 동안 최종 봉인을 막았습니다")
func view(uid: String) -> Dictionary:
 if not players.has(uid):return {}
 var self_p: Dictionary=players[uid]
 var snapshot={"room":code,"host":host,"phase":phase,"round":round_number,"match":match_id,"time":maxf(0,C.MATCH_TIME-elapsed),"phase_time":maxf(0,phase_until-elapsed),"resources":resources,"meetings":meetings,"winner":winner,"events":events.duplicate(true),"roster":[],"actors":[],"missions":[],"effects":[],"self":{},"footprints":[]}
 for p in players.values():
  snapshot.roster.append({"cosmetic":p.cosmetic.duplicate(),"uid":p.uid,"name":p.name,"ready":p.ready,"connected":p.connected,"captured":p.captured,"sealed":p.sealed,"restricted":p.penalty>elapsed})
  var distance: float=self_p.position.distance_to(p.position)
  var visible_player: bool=p.uid==uid or (not p.sealed and distance<(210 if self_p.captured else C.VISIBILITY) and Map.line(self_p.position,p.position))
  for effect in effects:
   if effect.kind in ["darkness","smoke"] and effect.position.distance_to(self_p.position)<130 and distance>85 and p.uid!=uid:visible_player=false
  if visible_player:
   var display: String=p.name
   var outfit: Dictionary=p.cosmetic
   if p.buff.get("mask",0)>elapsed or p.buff.get("mimic",0)>elapsed:
    var copied: String=p.buff.get("appearance","")
    if players.has(copied):display=players[copied].name;outfit=players[copied].cosmetic
   snapshot.actors.append({"cosmetic":outfit.duplicate(),"uid":p.uid,"name":display,"position":[p.position.x,p.position.y],"facing":p.facing,"moving":p.intent.length()>.1 and roam(p),"form":(p.form_choice if p.buff.get("transform",0)>elapsed else "human"),"casting":p.buff.get("casting",0)>elapsed or p.buff.get("working",0)>elapsed or channels.has(p.uid),"carry":p.carry!="","protected":p.protected>elapsed})
 for m in missions:snapshot.missions.append({"id":m.id,"kind":m.kind,"name":m.name,"position":[m.position.x,m.position.y],"step":m.step,"done":m.done})
 for e in effects:
  if e.position.distance_to(self_p.position)<C.VISIBILITY:snapshot.effects.append({"id":e.id,"kind":"flame" if e.kind=="fake_flame" else e.kind,"position":[e.position.x,e.position.y],"name":e.name,"facing":e.facing,"cosmetic":e.get("cosmetic",{}).duplicate()})
 var remaining: Dictionary={}
 for s in self_p.cd:remaining[s]=maxf(0,float(self_p.cd[s])-elapsed)
 var buddies: Array=[]
 if self_p.role=="yokai":
  for p in players.values():
   if p.role=="yokai" and p.uid!=uid:buddies.append(p.uid)
 snapshot.self={"career_wins":self_p.career_wins,"uid":uid,"role":self_p.role,"teammates":buddies,"position":[self_p.position.x,self_p.position.y],"facing":self_p.facing,"slots":self_p.slots.duplicate(),"cooldowns":remaining,"captured":self_p.captured,"sealed":self_p.sealed,"penalty":maxf(0,self_p.penalty-elapsed),"protection":maxf(0,self_p.protected-elapsed),"carry":self_p.carry,"fragments":self_p.fragments.duplicate(),"escape":self_p.escape,"escape_time":maxf(0,self_p.escape_until-elapsed),"channel":maxf(0,float(channels.get(uid,{}).get("until",elapsed))-elapsed),"voted":votes.has(uid)}
 if self_p.buff.get("track",0)>elapsed:
  for p in players.values():
   if p.uid!=uid:
    for mark in p.trail:
     if elapsed-mark.time<6 and mark.p.distance_to(self_p.position)<240:snapshot.footprints.append([snappedf(mark.p.x,4),snappedf(mark.p.y,4)])
 return snapshot
