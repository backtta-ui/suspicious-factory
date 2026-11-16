extends SceneTree
const Rules=preload("res://scripts/seal/rules.gd")
const C=preload("res://scripts/seal/catalog.gd")
const Map=preload("res://scripts/seal/map.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func room(count: int=8) -> SealRules:
 var r:=Rules.new("123456",321)
 for i in range(count):r.add("p%d"%i,"도사%d"%i,["transform","blink"]);r.command("p%d"%i,{"op":"ready","value":true})
 r.start("p0");return r
func advance(r: SealRules,seconds: float) -> void:
 for i in range(ceili(seconds/.05)):r.tick(.05)
func teams(r: SealRules,role: String) -> Array:
 return r.players.values().filter(func(p: Dictionary)->bool:return p.role==role).map(func(p: Dictionary)->String:return p.uid)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 for count in [6,7,8]:
  var r:=room(count)
  check(teams(r,"yokai").size()==2 and teams(r,"daoist").size()==count-2,"fixed two secret yokai at %d players"%count)
 var r:=room();var evils:=teams(r,"yokai");var daos:=teams(r,"daoist");var evil: Dictionary=r.players[evils[0]];var dao: Dictionary=r.players[daos[0]]
 var view:=r.view(dao.uid)
 check(view.self.role=="daoist" and view.self.teammates.is_empty(),"dao receives only own private role")
 check(view.roster.all(func(p: Dictionary)->bool:return not p.has("role") and not p.has("position")),"public roster has neither roles nor world positions")
 check(r.view(evil.uid).self.teammates==[evils[1]],"yokai sees exactly its own teammate")
 r.command(dao.uid,{"op":"set_role","role":"yokai"});check(dao.role=="daoist","client role injection ignored")
 var old: Vector2=evil.position;r.command(evil.uid,{"op":"move","intent":[1,0]});advance(r,1)
 check(evil.position==old,"yokai cannot move during 30-second preparation")
 advance(r,30)
 check(r.phase=="roam","server transitions into roaming")
 old=dao.position;r.command(dao.uid,{"op":"move","intent":[999,0],"position":[0,0]});advance(r,1);dao.intent=Vector2.ZERO
 check(dao.position.distance_to(old)<=89 and Map.can_stand(dao.position),"server normalizes input and rejects authoritative position injection")
 var denied:=r.command(dao.uid,{"op":"cast","skill":"capture","target":evil.uid});check(denied.has("error"),"dao cannot forge yokai capture ability")
 # Fake work never adds sealing resources.
 var m: Dictionary=r.missions[0];evil.position=m.position
 var ch: Dictionary=r.command(evil.uid,{"op":"task_open","mission":0}).challenge;advance(r,.4)
 r.command(evil.uid,{"op":"task","mission":0,"nonce":ch.nonce,"answer":m.pattern[0]})
 check(r.resources==0 and m.step==0,"yokai fake mission cannot advance real seal progress")
 dao.position=m.position
 for i in range(3):
  ch=r.command(dao.uid,{"op":"task_open","mission":0}).challenge;advance(r,.4)
  r.command(dao.uid,{"op":"task","mission":0,"nonce":ch.nonce,"answer":m.pattern[i]})
 check(m.done and r.resources==1,"three glyph interactions grant one server-owned sealing chance")
 r.command(evil.uid,{"op":"task_open","mission":0});check(m.done,"completed mission cannot be reset by yokai")
 var well: Dictionary=r.missions[1];dao.position=well.position
 ch=r.command(dao.uid,{"op":"task_open","mission":1}).challenge
 var wrong:=r.command(dao.uid,{"op":"task","mission":1,"nonce":ch.nonce,"answer":well.pattern})
 check(wrong.has("error"),"instant puzzle replay fails server minimum interaction time")
 advance(r,.4)
 r.command(dao.uid,{"op":"task","mission":1,"nonce":ch.nonce,"answer":well.pattern})
 check(well.done and r.resources==2,"well rotation puzzle grants real resources")
 var soul: Dictionary=r.missions[2];dao.position=soul.position;r.command(dao.uid,{"op":"task_open","mission":2})
 check(dao.carry=="2","soul transport pickup is real carrying state")
 dao.position=Map.ALTAR;r.command(dao.uid,{"op":"task_open","mission":2});check(soul.done and dao.carry=="","soul must reach central altar to count")
 # Capture, shield, rescue and last-chance escape.
 evil.position=Map.safe(Vector2(1160,730));dao.position=Map.safe(Vector2(1185,730));dao.buff.shield=r.elapsed+8
 r.command(evil.uid,{"op":"cast","skill":"capture","target":dao.uid})
 check(not dao.captured and not dao.buff.has("shield"),"protective talisman consumes exactly one capture defense")
 evil.cd.capture=0;dao.protected=0
 r.command(evil.uid,{"op":"cast","skill":"capture","target":dao.uid})
 check(dao.captured and dao.position.distance_to(Map.JAIL)<60,"capture teleports to actual sealing prison")
 var helper: Dictionary=r.players[daos[1]];helper.position=Map.safe(Map.JAIL+Vector2(-35,0))
 r.command(helper.uid,{"op":"rescue","target":dao.uid});advance(r,3.2)
 check(not dao.captured and dao.protected>r.elapsed,"channelled ally rescue restores play and protection")
 evil.cd.capture=0;evil.position=dao.position+Vector2(10,0);r.command(evil.uid,{"op":"cast","skill":"capture","target":dao.uid})
 check(not dao.captured,"post-rescue protection rejects immediate recapture")
 # Common spells are server validated, have cooldowns and collide with walls.
 helper.slots=["blink","clone"];helper.position=Map.safe(Vector2(900,700));old=helper.position
 r.command(helper.uid,{"op":"cast","skill":"blink"})
 check(Map.can_stand(helper.position) and helper.position.distance_to(old)<=111,"blink endpoint obeys server collision")
 old=helper.position;r.command(helper.uid,{"op":"cast","skill":"blink"});check(helper.position==old,"cooldown prevents repeated blink")
 r.command(helper.uid,{"op":"cast","skill":"clone"});check(r.effects.any(func(e: Dictionary)->bool:return e.kind=="clone"),"clone creates timed decoy state")
 var before_role: String=evil.role;evil.cd.mimic=0;evil.position=helper.position+Vector2(20,0)
 r.command(evil.uid,{"op":"cast","skill":"mimic","target":helper.uid})
 check(evil.uid==evils[0] and evil.role==before_role and evil.buff.get("appearance","")==helper.uid,"identity disguise changes appearance only, never actual ID or role")
 # Exercise every implemented common and role ability on authoritative state.
 helper.position=Map.safe(Vector2(1160,730));evil.position=Map.safe(Vector2(1190,730))
 for skill in ["transform","track","rescue"]:
  helper.slots=[skill,"blink"];helper.cd[skill]=0
  var reply:=r.command(helper.uid,{"op":"cast","skill":skill})
  check(not reply.has("error") and helper.buff.get(skill,0)>r.elapsed,"common ability has real timed state: "+skill)
 helper.slots=["smoke","mask"];helper.cd.smoke=0
 r.command(helper.uid,{"op":"cast","skill":"smoke"})
 check(r.effects.any(func(e: Dictionary)->bool:return e.kind=="smoke"),"smoke creates an actual visibility-limiting area")
 helper.cd.mask=0;r.command(helper.uid,{"op":"cast","skill":"mask","target":evil.uid})
 check(helper.buff.get("appearance","")==evil.uid and helper.role=="daoist","common mask works for daoists without assigning yokai role")
 for skill in ["darkness","fake_flame"]:
  evil.cd[skill]=0;r.command(evil.uid,{"op":"cast","skill":skill})
  check(r.effects.any(func(e: Dictionary)->bool:return e.kind==skill),"role ability creates timed world state: "+skill)
 evil.cd.shadow=0;old=evil.position;r.command(evil.uid,{"op":"cast","skill":"shadow"})
 check(Map.can_stand(evil.position) and evil.position.distance_to(old)>1,"shadow movement is real collision-checked travel")
 var rendered_effects: Array=r.view(helper.uid).effects
 check(rendered_effects.all(func(e: Dictionary)->bool:return not e.has("owner")),"world effects never reveal a private attacker owner/role binding")
 # Observer cannot scrape far-away player coordinates.
 dao.position=Map.safe(Vector2(800,950));helper.position=Map.safe(Vector2(2700,500))
 check(not r.view(dao.uid).actors.any(func(p: Dictionary)->bool:return p.uid==helper.uid),"per-recipient snapshots omit distant players entirely")
 # Secret voting and two actual yokai seals determine victory.
 r=room();advance(r,31);evils=teams(r,"yokai");daos=teams(r,"daoist");r.resources=2
 for target in evils:
  var caller: Dictionary=r.players[daos[0]];caller.position=Map.ALTAR;r.meeting_ready=0
  r.command(caller.uid,{"op":"meeting"});advance(r,C.DISCUSSION+.1)
  check(r.phase=="vote","meeting transitions discussion into timed vote")
  for uid in r.players:
   if not r.players[uid].sealed:r.command(uid,{"op":"vote","target":target})
  check(not r.view(daos[0]).has("votes"),"unresolved ballots never leak in public snapshots")
  advance(r,C.VOTE+.1)
 check(r.winner=="daoist" and r.phase=="result","sealing both real yokai wins for daoists")
 r.command(r.host,{"op":"rematch"});check(r.phase=="lobby" and r.players.size()==8,"same room returns to ready lobby for rematch")
 r=room();advance(r,31);daos=teams(r,"daoist");r.resources=1;r.players[daos[0]].position=Map.ALTAR
 r.command(daos[0],{"op":"meeting"});advance(r,C.DISCUSSION+.1)
 for uid in r.players:r.command(uid,{"op":"vote","target":daos[0]})
 advance(r,C.VOTE+.1)
 check(not r.players[daos[0]].sealed and r.players[daos[0]].penalty>r.elapsed,"wrongly accusing a daoist applies temporary penalty, never kills them")
 check(r.resources==0 and r.meeting_ready>r.elapsed,"wrong accusation consumes limited resource and enforces meeting cooldown")
 r.players[daos[1]].position=Map.ALTAR;r.command(daos[1],{"op":"fallback"});advance(r,4.2)
 check(r.resources==1,"altar channel provides a real fallback when sealing resources run out")
 r=room();advance(r,31);evils=teams(r,"yokai");daos=teams(r,"daoist")
 for uid in daos:r.players[uid].captured=true;r.players[uid].escape=1;r.players[uid].escape_until=r.elapsed+10
 r.check_win();check(r.phase!="result","all captured does not win while rescue/escape opportunity remains")
 r.command(daos[0],{"op":"escape"});advance(r,5.2);check(not r.players[daos[0]].captured,"last chance escape can actually free a daoist")
 for uid in daos:r.players[uid].captured=true;r.players[uid].escape=0
 r.check_win();check(r.winner=="yokai","all captured without remaining rescue opportunity wins for yokai")
 r=room();r.phase="roam";r.elapsed=C.MATCH_TIME;r.check_win();check(r.winner=="yokai","server enforces overall timeout win")
 r=room();var previous_host: String=r.host;r.mark_disconnected(previous_host)
 check(r.host!=previous_host and r.host!="","host disconnect migrates control to a connected participant")
 check(r.add(previous_host,"",[]) and r.players[previous_host].connected,"authenticated reconnect retains same participant and role")
 print("SEAL RULES: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
