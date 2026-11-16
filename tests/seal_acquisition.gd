extends "res://tests/seal_network.gd"
const Study=preload("res://scripts/seal/study.gd")
func walk_to(p: Dictionary,target: Vector2) -> bool:
 var until:=Time.get_ticks_msec()+15000
 while Time.get_ticks_msec()<until:
  poll()
  var position:=Vector2(p.study.position[0],p.study.position[1])
  if position.distance_to(target)<35:send(p,{"op":"study_move","intent":[0,0]});return true
  var move:=position.direction_to(target);send(p,{"op":"study_move","intent":[move.x,move.y]})
  await create_timer(.1).timeout
 send(p,{"op":"study_move","intent":[0,0]});return false
func learn_first(p: Dictionary) -> bool:
 send(p,{"op":"study_start"})
 if not await wait_for(func()->bool:return p.has("study")):return false
 if not await walk_to(p,Study.POINTS[0]):return false
 p.study_reply={};send(p,{"op":"study_open","skill":"transform"})
 if not await wait_for(func()->bool:return p.study_reply.has("study_challenge")):return false
 var challenge: Dictionary=p.study_reply.study_challenge
 for step in range(3):
  await create_timer(.47).timeout;poll();send(p,{"op":"study_answer","skill":"transform","nonce":challenge.nonce,"answer":challenge.pattern[step]})
 if not await wait_for(func()->bool:return p.account.owned_spells.has("transform")):return false
 send(p,{"op":"study_end"});return await wait_for(func()->bool:return p.get("study_ended",false))
func walk_match(p: Dictionary,target: Vector2) -> bool:
 var until:=Time.get_ticks_msec()+12000
 while Time.get_ticks_msec()<until:
  poll();var position:=Vector2(p.state.self.position[0],p.state.self.position[1])
  if position.distance_to(target)<15:send(p,{"op":"move","intent":[0,0]});return true
  var move:=position.direction_to(target);send(p,{"op":"move","intent":[move.x,move.y],"facing":posmod(roundi(move.angle()/(PI/4)),8)})
  await create_timer(.1).timeout
 send(p,{"op":"move","intent":[0,0]});return false
func run() -> void:
 Engine.max_fps=60
 address=OS.get_environment("SEAL_TEST_URL")
 var p:=await connect_peer()
 check(await wait_for(func()->bool:return p.has("account")),"authenticated server supplies acquisition account")
 check(p.account.tier=="free" and p.account.owned_spells.is_empty(),"new live account has no free spells or paid entitlement")
 send(p,{"op":"unlock","owned_spells":C.COMMON.keys(),"tier":"vip"})
 send(p,{"op":"account"});await create_timer(.15).timeout;poll()
 check(p.account.owned_spells.is_empty() and p.account.tier=="free","forged account/unlock packets do not grant spells or VIP")
 send(p,{"op":"study_start"})
 check(await wait_for(func()->bool:return p.has("study")),"actual socket enters existing forest discovery adventure")
 for i in range(2):
  var skill: String=C.COMMON.keys()[i]
  check(await walk_to(p,Study.POINTS[i]),"authoritative walking reaches actual "+skill+" discovery point")
  p.study_reply={};send(p,{"op":"study_open","skill":skill})
  check(await wait_for(func()->bool:return p.study_reply.has("study_challenge")),"real discovery challenge opens only at nearby shrine")
  var challenge: Dictionary=p.study_reply.study_challenge
  for step in range(3):
   await create_timer(.47).timeout;poll();send(p,{"op":"study_answer","skill":skill,"nonce":challenge.nonce,"answer":challenge.pattern[step]})
  check(await wait_for(func()->bool:return p.account.owned_spells.has(skill)),"server persists acquisition only after actual ordered adventure interactions")
 send(p,{"op":"study_end"});check(await wait_for(func()->bool:return p.get("study_ended",false)),"adventure returns safely to multiplayer setup")
 send(p,{"op":"create","name":"습득 도사","slots":["smoke","mask"],"owned_spells":C.COMMON.keys(),"tier":"vip","reserve":"shield"})
 check(await wait_for(func()->bool:return not p.state.is_empty()),"learned profile can create actual multiplayer room")
 check(p.state.self.tier=="free" and p.state.self.reserve=="" and p.state.self.slots==["",""] and p.state.self.owned_spells.has("transform") and p.state.self.owned_spells.has("blink"),"free lobby preserves acquired book while deferring final random slots until role preparation")
 var original: Array=p.state.self.slots.duplicate();p.reply={};send(p,{"op":"loadout","slots":["mask","smoke"]})
 check(await wait_for(func()->bool:return p.reply.has("error")) and p.state.self.slots==original,"free ready-lobby cannot reroll or directly select new spells")
 send(p,{"op":"leave"});await create_timer(.15).timeout;poll();p.ws.close();await create_timer(.15).timeout
 var resumed:=await connect_peer(p.id,p.secret)
 check(await wait_for(func()->bool:return resumed.has("account")) and resumed.account.owned_spells.has("transform") and resumed.account.owned_spells.has("blink"),"reconnect preserves authoritative acquired spells and anonymous identity")
 send(resumed,{"op":"create","name":"수련 방장"})
 check(await wait_for(func()->bool:return resumed.room!="" and not resumed.state.is_empty()),"acquired reconnect identity opens six-person live test room")
 var group: Array=[resumed]
 for i in range(5):
  var friend:=await connect_peer();check(await learn_first(friend),"independent peer %d actually learns transformation in server adventure"%i)
  group.append(friend);send(friend,{"op":"join","room":resumed.room,"name":"수련%d"%i})
 check(await wait_for(func()->bool:return resumed.state.roster.size()==6),"six separately acquired accounts join same real online room")
 for friend in group:send(friend,{"op":"ready","value":true})
 await wait_for(func()->bool:return resumed.state.roster.all(func(row: Dictionary)->bool:return row.ready))
 send(resumed,{"op":"start"})
 check(await wait_for(func()->bool:return group.all(func(friend: Dictionary)->bool:return friend.state.phase=="prepare")),"role-filtered loadouts finalize once before active round")
 check(group.all(func(friend: Dictionary)->bool:return friend.state.self.role!="yokai" or not friend.state.self.slots.has("transform")),"actual yokai never receives object transformation in random slots")
 check(group.all(func(friend: Dictionary)->bool:return friend.state.self.role!="daoist" or friend.state.self.slots.has("transform")),"acquired daoists actually equip their known transformation")
 check(await wait_for(func()->bool:return resumed.state.phase=="roam",34),"real game reaches active phase after preparation")
 var dao: Dictionary=group.filter(func(friend: Dictionary)->bool:return friend.state.self.role=="daoist")[0]
 var evil: Dictionary=group.filter(func(friend: Dictionary)->bool:return friend.state.self.role=="yokai")[0]
 var arena:=preload("res://scripts/seal/arena.gd").new(dao.state.map_id)
 var origin:=Vector2(dao.state.self.position[0],dao.state.self.position[1]);var chosen: Dictionary={};var best:=INF
 for asset in dao.state.assets:
  var position:=Vector2(asset.position[0],asset.position[1]);var distance:=origin.distance_to(position)
  if asset.type=="object" and distance<best and arena.line(origin,position):chosen=asset;best=distance
 check(not chosen.is_empty(),"actual selected map provides reachable, supported nearby extraction target")
 if not chosen.is_empty():
  var asset_position:=Vector2(chosen.position[0],chosen.position[1]);var target:=arena.safe(asset_position+asset_position.direction_to(origin)*38)
  check(await walk_match(dao,target),"live daoist walks to environment object through authoritative collision")
  send(dao,{"op":"extract","asset":chosen.id})
  check(await wait_for(func()->bool:return dao.state.self.forms.has(chosen.kind)),"actual extraction channel synchronizes stored object form")
  send(dao,{"op":"cast","skill":"transform"})
  check(await wait_for(func()->bool:return dao.state.actors.any(func(actor: Dictionary)->bool:return actor.uid==dao.uid and actor.form=="asset:"+chosen.kind)),"actual transformed avatar uses the same asset kind as its environment target")
  send(dao,{"op":"cast","skill":"transform"})
  check(await wait_for(func()->bool:return dao.state.actors.any(func(actor: Dictionary)->bool:return actor.uid==dao.uid and actor.form=="human")),"live transformation can return to human without waiting cooldown")
  var dao_position:=Vector2(dao.state.self.position[0],dao.state.self.position[1]);await walk_match(evil,arena.safe(dao_position+Vector2(28,0)))
  send(evil,{"op":"cast","skill":"mimic","target":dao.uid})
  check(await wait_for(func()->bool:return evil.state.actors.any(func(actor: Dictionary)->bool:return actor.uid==evil.uid and int(actor.color)==int(dao.state.self.color))),"actual yokai mimic copies daoist color while retaining true own ID")
  check(evil.state.self.role=="yokai" and evil.state.self.uid==evil.uid,"mimic never changes authoritative role or voting identity")
 for peer in peers:peer.ws.close()
 print("SEAL ACQUISITION: %d checks, %d failures; actual WebSocket server adventure, not Android"%[checks,failures]);quit(1 if failures else 0)
