class_name WooPracticeSession
extends RefCounted
const Registry=preload("res://scripts/practice/catalog.gd")
const Rules=preload("res://scripts/practice/rules.gd")
const Arena=preload("res://scripts/practice/arena.gd")
const Appearance=preload("res://scripts/wardrobe/catalog.gd")
const Attack=preload("res://scripts/woo/action_config.gd")
const NPCS={"blue":{"name":"훈련 도사 청월","position":Vector2(520,555),"color":1},"red":{"name":"훈련 도사 홍매","position":Vector2(800,570),"color":0},"yokai":{"name":"훈련 요괴","position":Vector2(720,540),"color":4},"rescuee":{"name":"구출 수련 도사","position":Vector2(1080,720),"color":2}}
var rules: WooPracticeRules
var original: Dictionary
var selected:="transform"
var hp:=100
var blocks:=0
var hits:=0
var defenses:=0
var npc_mode:="patrol"
var stats: Dictionary={}
var message:="서버 없는 자유 체험 · 습득/장착/아이템/승리 기록은 바뀌지 않습니다"
var strikes: Array[Dictionary]=[]
func _init(look: Dictionary) -> void:original=Appearance.normalize(look);reset()
func reset() -> void:
 npc_mode="patrol"
 rules=Rules.new("OFFLINE",2004);rules.arena=Arena.new()
 for id in ["student"]+NPCS.keys():rules.add(id,"수련자" if id=="student" else NPCS[id].name,[])
 var self_p: Dictionary=rules.players.student;self_p.position=preload("res://scripts/practice/layout.gd").SPAWN;self_p.cosmetic=original.duplicate();self_p.color=3
 stats.clear()
 for id in NPCS:
  var p: Dictionary=rules.players[id];p.position=NPCS[id].position;p.color=NPCS[id].color;p.role="yokai" if id=="yokai" else "daoist"
  p.cosmetic=Appearance.DEFAULT.duplicate();p.cosmetic.character="yeonhwa" if id=="blue" else ("hongryeon" if id=="red" else "muyeong");p.cosmetic.hat="none" if id=="red" else "gat";p.cosmetic.hair="flower" if id=="blue" else "silver";p.cosmetic.color="purple" if id=="blue" else "red"
  stats[id]={"hp":100,"stun":0.0,"attack":0.0,"windup":0.0,"fired":false}
 rules.players.rescuee.captured=true;rules.players.rescuee.escape=0
 rules.phase="roam";rules.phase_until=1000000;hp=100;blocks=0;hits=0;defenses=0;strikes.clear()
 rules.missions.append({"id":0,"done":false,"position":rules.arena.altar,"jammed":0.0,"kind":"pillars","name":"수련 봉인 표적","step":0})
 select(selected);message="수련 상태 초기화 · 실제 저장 데이터에는 영향이 없습니다"
func self_player() -> Dictionary:return rules.players.student
func clear_effects() -> void:
 rules.effects.clear();rules.channels.clear()
 for p in rules.players.values():p.buff.clear();p.intent=Vector2.ZERO
 strikes.clear()
func select(id: String) -> bool:
 id=Registry.canonical(id)
 if not Registry.all().has(id):return false
 clear_effects();selected=id
 var p:=self_player();p.role="yokai" if Registry.Online.EVIL.has(id) else "daoist";p.owned_spells=Registry.Online.COMMON.keys();p.slots=[id] if Registry.Online.COMMON.has(id) else [];p.captured=false;p.sealed=false;p.protected=rules.elapsed+.5
 message=Registry.all()[id].description;return true
func nearest(distance: float=220,captured_only: bool=false) -> String:
 var result:="";var best:=distance
 for id in NPCS:
  var p: Dictionary=rules.players[id]
  if p.sealed or (captured_only and not p.captured) or (not captured_only and p.captured):continue
  var d: float=self_player().position.distance_to(p.position)
  if d<best and rules.arena.line(self_player().position,p.position):best=d;result=id
 return result
func nearest_asset() -> Dictionary:
 var found: Dictionary={};var best:=float(rules.options.extract_range)
 for asset in rules.arena.assets:
  var d: float=self_player().position.distance_to(rules.arena.asset_position(asset,rules.elapsed))
  if d<best and rules.arena.line(self_player().position,rules.arena.asset_position(asset,rules.elapsed)):best=d;found=asset
 return found
func reply(result: Dictionary) -> bool:
 message=str(result.get("error",result.get("notice","도술을 사용했습니다")));return not result.has("error")
func interact() -> bool:
 var p:=self_player()
 if p.captured:return reply(rules.command("student",{"op":"escape"}))
 if selected=="transform":
  var asset:=nearest_asset()
  if asset.is_empty():message="둔갑 대상 가까이에서 형상을 추출하세요";return false
  return reply(rules.command("student",{"op":"extract","asset":asset.id}))
 var ally:=nearest(68,true)
 if ally!="":return reply(rules.command("student",{"op":"rescue","target":ally}))
 var id:=nearest(85)
 message="가까운 훈련 NPC가 없습니다" if id=="" else str(NPCS[id].name)+" · 대기/산책/추적/공격 행동을 선택해 시험하세요"
 return id!=""
func cast() -> bool:
 if selected=="talisman":return attack(true)
 var target:=nearest(220)
 if selected=="mimic":
  target="";var best:=220.0
  for id in NPCS:
   var q: Dictionary=rules.players[id];var distance: float=self_player().position.distance_to(q.position)
   if q.role=="daoist" and not q.captured and distance<best and rules.arena.line(self_player().position,q.position):best=distance;target=id
 if selected=="capture":
  target=""
  for id in NPCS:
   var q: Dictionary=rules.players[id]
   if q.role=="daoist" and not q.captured and rules.near(self_player(),q.position,48):target=id;break
 return reply(rules.command("student",{"op":"cast","skill":selected,"target":target}))
func release() -> void:
 var p:=self_player();p.buff.erase("transform");p.buff.erase("mimic");p.buff.erase("appearance");p.buff.erase("mask");message="원래 외형으로 복귀했습니다"
func attack(talisman: bool=false) -> bool:
 var p:=self_player();var key: String="talisman" if talisman else "training_attack"
 if p.captured or p.cd.get(key,0)>rules.elapsed:return false
 p.cd[key]=rules.elapsed+(Attack.TALISMAN_COOLDOWN if talisman else .45);p.buff.casting=rules.elapsed+.34
 var aim:=Vector2.from_angle(p.facing*PI/4);var damage: int=Attack.TALISMAN_DAMAGE if talisman else Attack.DAMAGE[0];var distance: float=Attack.TALISMAN_RANGE if talisman else Attack.RANGES[0]
 # Same combat cone, range, damage and sealing constants as the adventure controller.
 for id in NPCS:
  var q: Dictionary=rules.players[id]
  if q.captured or not Attack.in_cone(p.position,aim,q.position,distance) or not rules.arena.line(p.position,q.position):continue
  stats[id].hp=maxi(0,stats[id].hp-damage);stats[id].stun=rules.elapsed+(Attack.TALISMAN_SEAL_SECONDS if talisman else .3);hits+=1
  q.position=rules.arena.move(q.position,q.position+aim*12)
  strikes.append({"position":q.position,"damage":damage,"gold":talisman})
  if stats[id].hp==0:stats[id].hp=100;stats[id].stun=rules.elapsed+2;message=NPCS[id].name+" · 표적 자동 회복 (실제 보상 없음)"
 # Solid training dummy is a real damageable target independent of NPCs.
 for asset in rules.arena.assets:
  if asset.kind=="dummy" and Attack.in_cone(p.position,aim,asset.origin,distance) and rules.arena.line(p.position,asset.origin):hits+=1;strikes.append({"position":asset.origin,"damage":damage,"gold":talisman})
 return true
func tick(delta: float,intent: Vector2) -> void:
 delta=clampf(delta,0,.05)
 var p:=self_player()
 var facing: int=posmod(roundi(intent.angle()/(PI/4)),8) if intent.length()>.1 else int(p.facing)
 rules.command("student",{"op":"move","intent":[intent.x,intent.y],"facing":facing})
 for id in NPCS:
  var q: Dictionary=rules.players[id];var s: Dictionary=stats[id];q.intent=Vector2.ZERO
  if q.captured or s.stun>rules.elapsed:continue
  var goal: Vector2=NPCS[id].position+Vector2(sin(rules.elapsed*.5+q.color)*62,cos(rules.elapsed*.4+q.color)*32)
  if npc_mode in ["chase","attack"] and rules.can_observe(id,"student") and (p.buff.get("mask",0)<=rules.elapsed or q.position.distance_to(p.position)<80):goal=p.position
  for effect in rules.effects:
   if effect.kind in ["clone","fake_flame"] and q.position.distance_to(effect.position)<260:goal=effect.position;break
  var offset: Vector2=goal-q.position
  if npc_mode!="idle" and offset.length()>24:q.intent=offset.normalized()*.55;q.facing=posmod(roundi(offset.angle()/(PI/4)),8)
  if npc_mode=="attack" and id=="yokai" and rules.can_observe(id,"student") and q.position.distance_to(p.position)<48 and rules.elapsed>=s.attack and not p.captured:
   if s.windup==0:s.windup=rules.elapsed+.42;s.fired=false;q.buff.casting=rules.elapsed+.42
   q.intent=Vector2.ZERO
   if rules.elapsed>=s.windup and not s.fired:
    s.fired=true;s.windup=0.0;s.attack=rules.elapsed+1.6
    if rules.near(q,p.position,48) and p.protected<=rules.elapsed:
     if rules.consume_shield(p,rules.elapsed):blocks+=1;defenses+=1;message="호신부 방어 성공 · 짧은 보호 시간"
     else:hp=maxi(0,hp-15);p.protected=rules.elapsed+.5;p.position=rules.arena.move(p.position,p.position+(p.position-q.position).normalized()*12);message="훈련 공격 적중 · 체력 -15"
     if hp==0:hp=100;p.position=preload("res://scripts/practice/layout.gd").SPAWN;message="훈련용 체력 회복 · 실제 HP/아이템 변화 없음"
  else:s.windup=0.0
 var channel: Dictionary=rules.channels.get("student",{}).duplicate()
 var was_transformed: bool=p.buff.get("transform",0)>rules.elapsed
 var was_mimicked: bool=p.buff.get("mimic",0)>rules.elapsed
 rules.tick(delta)
 if not channel.is_empty() and not rules.channels.has("student"):
  if channel.kind=="extract":
   var asset:=rules.arena.find_asset(channel.asset)
   message=(rules.arena.KINDS[asset.kind].name+" 형상 추출 완료 · 도술 사용을 누르세요") if not asset.is_empty() and p.selected_form==asset.kind and rules.elapsed>=channel.until else "이동으로 형상 추출이 취소되었습니다"
  elif channel.kind=="rescue":message="구출 완료 · 보호 시간 적용" if not rules.players[channel.target].captured else "구출이 취소되었습니다"
 if was_transformed and p.buff.get("transform",0)<=rules.elapsed:message="둔갑 시간이 끝나 원래 모습으로 돌아왔습니다"
 if was_mimicked and p.buff.get("mimic",0)<=rules.elapsed:message="타인 둔갑이 끝나 원래 외형과 색상으로 돌아왔습니다"
 for effect in rules.effects:
  if not effect.has("born"):effect.born=rules.elapsed
