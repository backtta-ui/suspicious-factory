extends SceneTree
const C=preload("res://scripts/seal/catalog.gd")
var peers: Array[Dictionary]=[]
var room_code:=""
var checks:=0
var failures:=0
var crypto:=Crypto.new()
var address:="ws://127.0.0.1:18771"
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func send(p: Dictionary,data: Dictionary) -> void:
 if p.ws.get_ready_state()==WebSocketPeer.STATE_OPEN:p.ws.send_text(JSON.stringify(data))
func poll() -> void:
 for p in peers:
  p.ws.poll()
  while p.ws.get_available_packet_count()>0:
   var wire: PackedByteArray=p.ws.get_packet()
   var packet=preload("res://scripts/seal/codec.gd").decode(wire)
   if not packet is Dictionary:continue
   match packet.get("op",""):
    "hello":p.uid=packet.uid;p.authenticated=true
    "joined":p.room=packet.room
    "state":p.state=packet.state;p.snapshots+=1;p.bytes+=JSON.stringify(packet).length();p.wire_bytes=int(p.get("wire_bytes",0))+wire.size()
    "error","reply":p.reply=packet
    "account":p.account=packet.account
    "study":p.study=packet.study
    "study_reply":p.study_reply=packet
    "study_ended":p.study_ended=true
func wait_for(predicate: Callable,seconds: float=5.0) -> bool:
 var until:=Time.get_ticks_msec()+int(seconds*1000)
 while Time.get_ticks_msec()<until:
  poll()
  if predicate.call():return true
  await process_frame
 return false
func connect_peer(identity: String="",secret: String="",resume: String="") -> Dictionary:
 var ws:=WebSocketPeer.new();ws.connect_to_url(address)
 var p: Dictionary={"ws":ws,"id":crypto.generate_random_bytes(16).hex_encode() if identity=="" else identity,"secret":crypto.generate_random_bytes(32).hex_encode() if secret=="" else secret,"uid":"","room":"","state":{},"reply":{},"snapshots":0,"bytes":0,"authenticated":false}
 peers.append(p)
 if not await wait_for(func()->bool:return ws.get_ready_state()==WebSocketPeer.STATE_OPEN):return p
 send(p,{"op":"hello","protocol":3,"identity":p.id,"proof":p.secret,"room":resume})
 await wait_for(func()->bool:return p.authenticated or not p.reply.is_empty())
 return p
func _initialize() -> void:run.call_deferred()
func run() -> void:
 Engine.max_fps=60
 if not OS.get_environment("SEAL_TEST_URL").is_empty():address=OS.get_environment("SEAL_TEST_URL")
 var host:=await connect_peer()
 check(host.authenticated,"real WebSocket authentication handshake")
 send(host,{"op":"create","name":"연결0","slots":["shield","blink"]})
 check(await wait_for(func()->bool:return host.room!=""),"real server creates six-digit room code")
 room_code=host.room;check(room_code.length()==6 and room_code.is_valid_int(),"room code is exactly six digits")
 for i in range(1,8):
  var p:=await connect_peer();send(p,{"op":"join","room":room_code,"name":"연결%d"%i,"slots":["transform","blink"]})
 check(await wait_for(func()->bool:return not host.state.is_empty() and host.state.roster.size()==8),"eight real socket clients share one room")
 var appearance: Dictionary=preload("res://scripts/wardrobe/catalog.gd").DEFAULT.duplicate();appearance.character="yeonhwa";appearance.hair="flower";appearance.color="purple";appearance.color_override=true;appearance.hat="none"
 send(host,{"op":"appearance","appearance":appearance})
 check(await wait_for(func()->bool:return host.state.roster[0].cosmetic==appearance),"real socket lobby synchronizes independent costume IDs")
 var forbidden: Dictionary=appearance.duplicate();forbidden.outfit="dragon";forbidden.color="black_gold";forbidden.color_override=true;host.reply={}
 send(host,{"op":"appearance","appearance":forbidden})
 check(await wait_for(func()->bool:return host.state.roster[0].cosmetic==forbidden),"all cosmetic IDs accepted without payment or win requirement")
 appearance=forbidden
 host.reply={}
 check(host.state.self.has("career_wins"),"server supplies authoritative career count, never client win input")
 for p in peers:send(p,{"op":"ready","value":true})
 check(await wait_for(func()->bool:return host.state.roster.all(func(row: Dictionary)->bool:return row.ready)),"ready state synchronizes across actual connections")
 send(host,{"op":"start"})
 check(await wait_for(func()->bool:return peers.all(func(p: Dictionary)->bool:return not p.state.is_empty() and p.state.phase=="prepare")),"server starts real 8-client match")
 send(host,{"op":"appearance","appearance":preload("res://scripts/wardrobe/catalog.gd").DEFAULT})
 check(await wait_for(func()->bool:return host.reply.has("error")),"real server rejects midmatch appearance change")
 check(host.state.roster[0].cosmetic==appearance,"midmatch appearance remains synchronized after rejected change")
 check(peers.all(func(p: Dictionary)->bool:return p.state.map_id==host.state.map_id),"all eight socket clients receive the same server-selected registered map")
 var colors: Array=host.state.roster.map(func(row: Dictionary)->int:return int(row.color))
 check(colors.all(func(c: int)->bool:return colors.count(c)==1),"eight socket clients receive unique immutable identity colors")
 var roles: Array=[]
 for p in peers:
  roles.append(p.state.self.role)
  check(p.state.roster.all(func(row: Dictionary)->bool:return not row.has("role") and not row.has("position")),"socket snapshot does not expose other private roles/positions")
 check(roles.count("yokai")==2 and roles.count("daoist")==6,"private role packets yield exactly two yokai across eight clients")
 var extra:=await connect_peer();send(extra,{"op":"join","room":room_code,"name":"초과"})
 check(await wait_for(func()->bool:return extra.reply.has("error")),"ninth real client cannot enter full match")
 var bad:=await connect_peer(host.id,crypto.generate_random_bytes(32).hex_encode())
 check(not bad.authenticated and bad.reply.has("error"),"wrong identity proof cannot hijack participant")
 check(await wait_for(func()->bool:return host.state.phase=="roam",34.0),"30-second preparation completes over real server clock")
 var mover: Dictionary=peers.filter(func(p: Dictionary)->bool:return not p.state.is_empty() and p.state.self.role=="daoist")[0]
 var before:=Vector2(mover.state.self.position[0],mover.state.self.position[1]);send(mover,{"op":"move","intent":[1,0],"position":[0,0],"role":"yokai"})
 var move_until:=Time.get_ticks_msec()+900
 while Time.get_ticks_msec()<move_until:poll();await process_frame
 send(mover,{"op":"move","intent":[0,0]})
 check(await wait_for(func()->bool:return Vector2(mover.state.self.position[0],mover.state.self.position[1]).distance_to(before)>3),"actual network movement changes server-owned position")
 var distance:=Vector2(mover.state.self.position[0],mover.state.self.position[1]).distance_to(before)
 check(distance<105 and mover.state.self.role=="daoist","movement/role injection never becomes authoritative state")
 var original_uid: String=host.uid;var original_role: String=host.state.self.role;host.ws.close()
 check(await wait_for(func()->bool:return peers[1].state.host!=original_uid),"real host socket disconnect migrates host")
 var resumed:=await connect_peer(host.id,host.secret,room_code)
 check(await wait_for(func()->bool:return not resumed.state.is_empty()),"same identity reconnects to live room")
 check(resumed.uid==original_uid and resumed.state.self.role==original_role and resumed.state.phase=="roam","reconnect retains private role and live match progress")
 # A separate six-client room uses real sockets as well, without adding test bots to production rooms.
 send(extra,{"op":"create","name":"여섯방"})
 check(await wait_for(func()->bool:return extra.room!="" and extra.room!=room_code),"second independent real room can be created")
 var six: Array=[extra]
 for i in range(5):
  var p:=await connect_peer();six.append(p);send(p,{"op":"join","room":extra.room,"name":"여섯%d"%i})
 check(await wait_for(func()->bool:return not extra.state.is_empty() and extra.state.roster.size()==6),"six real socket clients share second room")
 for p in six:send(p,{"op":"ready","value":true})
 await wait_for(func()->bool:return extra.state.roster.all(func(row: Dictionary)->bool:return row.ready))
 send(extra,{"op":"start"})
 check(await wait_for(func()->bool:return six.all(func(p: Dictionary)->bool:return not p.state.is_empty() and p.state.phase=="prepare")),"six-client match starts with private server roles")
 check(six.filter(func(p: Dictionary)->bool:return p.state.self.role=="yokai").size()==2,"six-client match has exactly two yokai")
 var samples:=0;var bytes:=0;var wire_bytes:=0
 for p in peers:samples+=p.snapshots;bytes+=p.bytes;wire_bytes+=int(p.get("wire_bytes",0))
 var report={"checks":checks,"failures":failures,"transport":"real localhost TCP WebSocket connections","real_android_devices":false,"human_players":false,"clients_in_match":8,"snapshot_packets":samples,"snapshot_bytes":bytes,"mean_snapshot_bytes":float(bytes)/maxi(samples,1),"mean_wire_snapshot_bytes":float(wire_bytes)/maxi(samples,1)}
 var f:=FileAccess.open("res://builds/v20-network-measurements.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 for p in peers:p.ws.close()
 await process_frame;print("SEAL NETWORK: %d checks, %d failures; real sockets, automated clients, no Android-device claim" % [checks,failures]);quit(0 if failures==0 else 1)
