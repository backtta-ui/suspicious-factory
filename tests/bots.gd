extends SceneTree
## 2.0.37 봇 AI 검증: 네 맵에서 봇이 뭉치지 않고 각자 순찰하며, 요괴는 둔갑한 도사의
## 움직임을 의심해 확인 타격하고, 도사·요괴 모두 자기 도술을 실제로 쓴다.
const R=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const Bot=preload("res://scripts/survival/bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("BOTS ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func arena_for(map_id: String) -> RefCounted:
 var arena:=preload("res://scripts/seal/arena.gd").new(map_id)
 arena.assets.clear();arena.cache.clear()
 return arena
func match_for(map_id: String,seed_value: int) -> Dictionary:
 var r:=R.new(seed_value)
 r.use_map(map_id)
 for i in range(8):
  r.add("human" if i==0 else "bot%d"%i,"참가%d"%i,C.catalog("daoist")[i%5].id,C.catalog("yokai")[i%5].id)
 for p in r.players.values():p.ready=true
 r.start()
 for p in r.players.values():
  if C.find(p.character).is_empty():p.character=C.catalog(p.role)[0].id
 r.phase="live";r.elapsed=20.0;r.build_walkers()
 return {"rules":r,"arena":arena_for(map_id),"nav":null}
func run() -> void:
 for map_id in Maps.ids():
  var setup: Dictionary=match_for(map_id,3700+Maps.ids().find(map_id))
  var r: RefCounted=setup.rules
  var nav:=preload("res://scripts/simulation/navigation.gd").new(setup.arena)
  await nav.build(self)
  var bots: Array=[]
  for key in r.players.keys():
   if String(key)=="human":continue
   bots.append(Bot.new(r,nav,String(key),r.players[key].color))
  var decision:=0.0
  var closest:=9999.0
  var close_samples:=0
  var total_samples:=0
  var spacing_total:=0.0
  var spacing_samples:=0
  var travelled: Dictionary={}
  var start_pos: Dictionary={}
  for bot in bots:start_pos[String(bot.id)]=(r.players[String(bot.id)].position as Vector2)
  for i in range(520):
   r.tick(.05)
   decision+=.05
   if decision>=.35 and r.phase=="live":
    for bot in bots:bot.think(decision)
    decision=0
    # 봇끼리 얼마나 떨어져 있는지(뭉침 감지)
    for a in range(bots.size()):
     for b in range(a+1,bots.size()):
      var pa: Vector2=r.players[String(bots[a].id)].position
      var pb: Vector2=r.players[String(bots[b].id)].position
      closest=minf(closest,pa.distance_to(pb))
    if bots.size()>1:
     total_samples+=1
     var near:=false
     var sum:=0.0
     for x in range(bots.size()):
      for y in range(x+1,bots.size()):
       var pa2: Vector2=r.players[String(bots[x].id)].position
       var pb2: Vector2=r.players[String(bots[y].id)].position
       sum+=pa2.distance_to(pb2)
       if pa2.distance_to(pb2)<44.0:near=true
     if near:close_samples+=1
     spacing_total+=sum/float(bots.size()-1);spacing_samples+=1
   if r.phase!="live":break
  for bot in bots:
   travelled[String(bot.id)]=(r.players[String(bot.id)].position as Vector2).distance_to(start_pos[String(bot.id)])
  var skills: Array=r.events.filter(func(e: Dictionary)->bool:return String(e.kind)=="skill")
  var daoist_skills:=0
  var yokai_skills:=0
  for e in skills:
   var actor:=String(e.get("actor",""))
   if not r.players.has(actor):continue
   if String(r.players[actor].role)=="daoist":daoist_skills+=1
   else:yokai_skills+=1
  var avg_spacing: float=spacing_total/float(maxi(1,spacing_samples))
  var near_ratio: float=float(close_samples)/float(maxi(1,total_samples))
  check(near_ratio<0.10,map_id+" bots do not stay clumped together (near-pair frames %.0f%%, closest %.0fpx)"%[near_ratio*100.0,closest])
  check(avg_spacing>80.0,map_id+" bots keep a player-like spread (average %.0fpx)"%avg_spacing)
  var movers:=0
  for key in travelled:
   if float(travelled[key])>90.0:movers+=1
  check(movers>=4,map_id+" most bots actually patrol the map (%d/7 moved 90px+)"%movers)
  check(daoist_skills>0,map_id+" daoist bots use their own skills (%d)"%daoist_skills)
  check(yokai_skills>0,map_id+" yokai bots use their own skills (%d)"%yokai_skills)
 # ---------------------------------------------------------------- 둔갑 의심·확인 타격
 # 이 장면만 따로: 도사 1 + 요괴 1 (다른 봇이 시야를 가리지 않게).
 var duel:=R.new(3999)
 duel.use_map("seowon")
 duel.add("runner","도사","daoist:woochi","yokai:gumiho")
 duel.add("hunter","요괴","daoist:woochi","yokai:gumiho")
 duel.players.runner.ready=true;duel.players.hunter.ready=true
 duel.start()
 duel.players.runner.character="daoist:woochi";duel.players.hunter.character="yokai:jangsanbeom"
 duel.players.runner.role="daoist";duel.players.hunter.role="yokai"
 duel.phase="live";duel.elapsed=20.0
 var nav_duel:=preload("res://scripts/simulation/navigation.gd").new(arena_for("seowon"))
 await nav_duel.build(self)
 var caster: Dictionary=duel.players.runner
 var hunter_state: Dictionary=duel.players.hunter
 var spot: Vector2=duel.circle().center+Vector2(320,0)
 caster.position=spot;caster.ground=spot;caster.form="jars";caster.buff.transform=duel.elapsed+30.0
 hunter_state.position=spot+Vector2(60,0);hunter_state.ground=hunter_state.position
 var hunter:=Bot.new(duel,nav_duel,"hunter",1)
 hunter.think(.35)
 var still_suspicion: float=hunter.suspicion
 # 둔갑한 채로 제자리면 의심하지 않는다.
 check(still_suspicion<=0.01,"a still disguise raises no suspicion (%.2f)"%still_suspicion)
 for i in range(5):
  caster.position=caster.position+Vector2(22,0)
  caster.ground=caster.position
  hunter.think(.35)
 check(hunter.suspicion>0.0,"a moving disguise raises the suspicion gauge (%.2f)"%hunter.suspicion)
 check(hunter.suspect.is_finite() or hunter.seal_checks>0,"the yokai locks onto the moving prop")
 # 계속 움직이면 요괴가 다가와 '확인' 타격으로 둔갑을 벗긴다.
 for i in range(20):
  caster.position=caster.position+Vector2(6,0)
  caster.ground=caster.position
  hunter_state.position=caster.position-Vector2(30,0)
  hunter_state.ground=hunter_state.position
  hunter_state.facing=0
  hunter.think(.35)
  if caster.form=="":break
 check(hunter.seal_checks>0 or caster.form=="","the yokai approaches and lands a confirm hit on the moving prop")
 # ---------------------------------------------------------------- 위협 앞에서 도사가 숨는다
 var duel2:=R.new(4111)
 duel2.use_map("seowon")
 duel2.add("coward","도사","daoist:woochi","yokai:gumiho")
 duel2.add("threat","요괴","daoist:woochi","yokai:gumiho")
 duel2.players.coward.ready=true;duel2.players.threat.ready=true
 duel2.start()
 duel2.players.coward.character="daoist:woochi";duel2.players.coward.role="daoist"
 duel2.players.threat.character="yokai:gumiho";duel2.players.threat.role="yokai"
 duel2.phase="live";duel2.elapsed=20.0
 var nav_duel2:=preload("res://scripts/simulation/navigation.gd").new(arena_for("seowon"))
 await nav_duel2.build(self)
 var hider: Dictionary=duel2.players.coward
 # 실제 둔갑 사물 옆에 세워야 둔갑술이 성립한다.
 var center2: Vector2=duel2.L.OBJECTS[0].p
 hider.position=center2;hider.ground=center2
 duel2.players.threat.position=center2+Vector2(120,0);duel2.players.threat.ground=duel2.players.threat.position
 var coward:=Bot.new(duel2,nav_duel2,"coward",1)
 for i in range(3):coward.think(.35)
 check(String(hider.form)!="" or coward.skill_uses>0 or (hider.intent as Vector2).length()>0.1,"a daoist hides or escapes when a yokai closes in (form=%s skills=%d intent=%.2f)"%[String(hider.form),coward.skill_uses,(hider.intent as Vector2).length()])
 print("BOTS RESULT checks=",checks," failures=",failures)
 quit(1 if failures>0 else 0)
