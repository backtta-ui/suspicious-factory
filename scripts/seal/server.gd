extends SceneTree
## Dedicated process. JSON commands never include client-authoritative state.
const Rules=preload("res://scripts/seal/rules.gd")
const Catalog=preload("res://scripts/seal/catalog.gd")
var tcp:=TCPServer.new()
var sockets: Dictionary={}
var identities: Dictionary={}
var tickets: SealProgressTicket
const CAREER_PATH="user://seal_server_career.json"
func save_careers() -> void:
 var file:=FileAccess.open(CAREER_PATH+".tmp",FileAccess.WRITE)
 if file==null:return
 file.store_string(JSON.stringify(identities));file.flush();file.close()
 DirAccess.rename_absolute(ProjectSettings.globalize_path(CAREER_PATH+".tmp"),ProjectSettings.globalize_path(CAREER_PATH))
func settle(room: SealRules) -> void:
 if room.phase!="result" or room.rewarded:return
 room.rewarded=true
 for identity in identities:
  var entry: Dictionary=identities[identity]
  if not room.players.has(entry.uid):continue
  var p: Dictionary=room.players[entry.uid]
  if p.role==room.winner and p.connected:entry.wins=int(entry.get("wins",0))+1
  p.career_wins=int(entry.get("wins",0))
 save_careers()
 for conn in sockets.values():
  if conn.identity!="" and room.players.has(conn.uid):send_account(conn)
var studies: Dictionary={}
const Study=preload("res://scripts/seal/study.gd")
const Loadout=preload("res://scripts/seal/loadout.gd")
func account_for(identity: String) -> Dictionary:
 var entry: Dictionary=identities[identity]
 var tier: String=str(entry.get("tier","free")) if OS.get_environment("SEAL_TEST_ENTITLEMENTS")=="1" else "free"
 if tier not in ["free","paid","vip","pass"]:tier="free"
 return {"owned_spells":Loadout.known(entry.get("owned_spells",[])),"tier":tier,"reserve":str(entry.get("reserve",""))}
func send_account(conn: Dictionary) -> void:
 var account:=account_for(conn.identity);account.career_wins=int(identities[conn.identity].get("wins",0))
 if tickets!=null:account.ticket=tickets.issue(identities[conn.identity])
 send(conn,{"op":"account","account":account})
var rooms: Dictionary={}
var rng:=RandomNumberGenerator.new()
var crypto:=Crypto.new()
var clock:=0.0
var accumulator:=0.0
var broadcast_left:=0.0
var next_socket:=1
var room_limit:=2
func _initialize() -> void:
 rng.randomize();Engine.max_fps=30
 var signing_key:=OS.get_environment("SEAL_PROGRESS_KEY")
 if signing_key.length()<32:
  if FileAccess.file_exists("user://seal_progress.key"):signing_key=FileAccess.get_file_as_string("user://seal_progress.key")
  if signing_key.length()<32:
   signing_key=Crypto.new().generate_random_bytes(32).hex_encode()
   var key_file:=FileAccess.open("user://seal_progress.key",FileAccess.WRITE)
   if key_file!=null:key_file.store_string(signing_key);key_file.flush();key_file.close()
 tickets=preload("res://scripts/seal/progress_ticket.gd").new(signing_key)
 if FileAccess.file_exists(CAREER_PATH):
  var raw=JSON.parse_string(FileAccess.get_file_as_string(CAREER_PATH))
  if raw is Dictionary and raw.size()<=2048:
   for id in raw:
    var p=raw[id]
    if valid_hex(id,32) and p is Dictionary and valid_hex(p.get("hash",""),64) and valid_hex(p.get("uid",""),16) and Catalog.whole(p.get("wins",0),0,100000):identities[id]=p
 if not OS.get_environment("MAX_ROOMS").is_empty():room_limit=clampi(int(OS.get_environment("MAX_ROOMS")),1,8)
 var port:=int(OS.get_environment("PORT")) if not OS.get_environment("PORT").is_empty() else Catalog.PORT
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--port="):port=int(arg.trim_prefix("--port="))
 var err:=tcp.listen(port,"0.0.0.0")
 if err!=OK:push_error("Seal server listen failed: "+str(err));quit(1);return
 print("SEAL SERVER READY protocol=",Catalog.PROTOCOL," port=",port)
func _process(delta: float) -> bool:
 clock+=delta
 while tcp.is_connection_available():
  var stream:=tcp.take_connection();stream.set_no_delay(true)
  if sockets.size()>=64:stream.disconnect_from_host();continue
  var ws:=WebSocketPeer.new();ws.inbound_buffer_size=32768;ws.outbound_buffer_size=131072;ws.max_queued_packets=64
  if ws.accept_stream(stream)==OK:
   sockets[next_socket]={"ws":ws,"uid":"","identity":"","room":"","opened":clock,"window":clock,"count":0,"last":clock};next_socket+=1
 var drop: Array=[]
 for id in sockets:
  var conn: Dictionary=sockets[id];var ws: WebSocketPeer=conn.ws;ws.poll()
  if ws.get_ready_state()==WebSocketPeer.STATE_CLOSED:drop.append(id);continue
  if clock-conn.last>95 or (conn.uid=="" and clock-conn.opened>15):ws.close();drop.append(id);continue
  if ws.get_ready_state()!=WebSocketPeer.STATE_OPEN:continue
  while ws.get_available_packet_count()>0:
   var packet:=ws.get_packet()
   if packet.size()>8192:ws.close(1009);break
   if clock-conn.window>=1:conn.window=clock;conn.count=0
   conn.count+=1
   if conn.count>80:ws.close(1008);break
   var data=JSON.parse_string(packet.get_string_from_utf8())
   if not data is Dictionary:continue
   conn.last=clock
   dispatch(id,conn,data)
 for id in drop:remove_socket(id)
 accumulator+=minf(delta,.15)
 while accumulator>=.05:
  accumulator-=.05
  for study in studies.values():study.tick(.05)
  for room in rooms.values():
   room.tick(.05);settle(room)
 broadcast_left-=delta
 if broadcast_left<=0:
  broadcast_left=.1
  var stale_studies: Array=[]
  for uid in studies:
   if studies[uid].idle>120:stale_studies.append(uid)
  for uid in stale_studies:studies.erase(uid)
  for conn in sockets.values():
   if studies.has(conn.uid):send(conn,{"op":"study","study":studies[conn.uid].view()})
   if conn.room!="" and rooms.has(conn.room) and rooms[conn.room].players.has(conn.uid):send(conn,{"op":"state","state":rooms[conn.room].view(conn.uid)})
  var expired: Array=[]
  for code in rooms:
   var room: SealRules=rooms[code]
   if room.players.is_empty() or room.players.values().all(func(p: Dictionary)->bool:return not p.connected and room.elapsed-p.disconnected_at>Catalog.RECONNECT):expired.append(code)
  for code in expired:rooms.erase(code)
 return false
func remove_socket(id: int) -> void:
 if not sockets.has(id):return
 var conn: Dictionary=sockets[id]
 if rooms.has(conn.room):rooms[conn.room].mark_disconnected(conn.uid)
 if studies.has(conn.uid):studies[conn.uid].intent=Vector2.ZERO
 sockets.erase(id)
func send(conn: Dictionary,data: Dictionary) -> void:
 var ws: WebSocketPeer=conn.ws
 if ws.get_ready_state()==WebSocketPeer.STATE_OPEN:
  var payload:=JSON.stringify(data).to_utf8_buffer()
  var err:=ws.put_packet(payload.compress(FileAccess.COMPRESSION_GZIP)) if payload.size()>256 else ws.send_text(payload.get_string_from_utf8())
  if err!=OK:ws.close(1013,"Connection busy; reconnect")
func valid_hex(value: Variant,length: int) -> bool:
 if not value is String or value.length()!=length:return false
 for c in value:
  if not c in "0123456789abcdef":return false
 return true
func dispatch(socket_id: int,conn: Dictionary,data: Dictionary) -> void:
 var op: String=str(data.get("op",""))
 if op=="hello":
  if not Catalog.whole(data.get("protocol",0),Catalog.PROTOCOL,Catalog.PROTOCOL):send(conn,{"op":"error","error":"앱/서버 버전이 맞지 않습니다"});return
  var identity=data.get("identity","");var proof=data.get("proof","")
  if not valid_hex(identity,32) or not valid_hex(proof,64):send(conn,{"op":"error","error":"익명 식별 정보가 올바르지 않습니다"});return
  if conn.uid!="" and conn.identity!=identity:conn.ws.close(1008);return
  if identities.has(identity) and identities[identity].hash!=proof.sha256_text():send(conn,{"op":"error","error":"익명 플레이어 인증 실패"});return
  if not identities.has(identity):
   if identities.size()>2048:send(conn,{"op":"error","error":"서버가 혼잡합니다"});return
   identities[identity]={"hash":proof.sha256_text(),"uid":identity.sha256_text().left(16),"wins":0,"owned_spells":[]}
   save_careers()
  var uid: String=identities[identity].uid
  # Only one active connection may control this identity.
  for id in sockets:
   if id!=socket_id and sockets[id].uid==uid:sockets[id].ws.close(1000,"Reconnected");sockets[id].room=""
  conn.uid=uid;conn.identity=identity
  if tickets.restore(data.get("ticket",""),identities[identity]):save_careers()
  send(conn,{"op":"hello","uid":uid,"protocol":Catalog.PROTOCOL})
  send_account(conn)
  var requested: String=str(data.get("room",""))
  if rooms.has(requested) and rooms[requested].players.has(uid):
   conn.room=requested;rooms[requested].add(uid,"",[]);rooms[requested].players[uid].career_wins=int(identities[identity].get("wins",0));send(conn,{"op":"joined","room":requested})
  elif requested!="":send(conn,{"op":"error","error":"이전 방이 종료되었거나 서버가 재시작되었습니다. 새 방에 참가하세요","room_expired":true})
  return
 if conn.uid=="":send(conn,{"op":"error","error":"먼저 익명 인증이 필요합니다"});return
 if op=="ping":send(conn,{"op":"pong","stamp":data.get("stamp",0)});return
 if op=="account":send_account(conn);return
 if op=="study_start":
  if conn.room!="":send(conn,{"op":"error","error":"먼저 방에서 나와 그림 수련을 시작하세요"});return
  if not studies.has(conn.uid):
   if studies.size()>=16:send(conn,{"op":"error","error":"동시 그림 수련 한도입니다. 잠시 후 다시 입장하세요"});return
   studies[conn.uid]=Study.new(account_for(conn.identity).owned_spells)
  send(conn,{"op":"study","study":studies[conn.uid].view()});return
 if op=="study_end":studies.erase(conn.uid);send_account(conn);send(conn,{"op":"study_ended"});return
 if op in ["study_move","study_open","study_answer"]:
  if not studies.has(conn.uid):
   if op!="study_move":send(conn,{"op":"error","error":"그림 수련에 먼저 입장하세요"})
   return
  var reply: Dictionary=studies[conn.uid].command(data)
  if reply.has("learned"):
   identities[conn.identity].owned_spells=studies[conn.uid].owned.duplicate();save_careers();send_account(conn)
  if not reply.is_empty():reply.op="study_reply";send(conn,reply)
  return
 if op in ["create","join","quick"]:
  if conn.room!="" and rooms.has(conn.room):send(conn,{"op":"error","error":"먼저 현재 방에서 나가세요"});return
  var code: String=str(data.get("room",""))
  if op=="quick":
   code=""
   for candidate in rooms:
    var room: SealRules=rooms[candidate]
    if room.phase=="lobby" and room.players.size()<8:code=candidate;break
  if op=="create" or (op=="quick" and code==""):
   if rooms.size()>=room_limit:send(conn,{"op":"error","error":"생성 가능한 방이 가득 찼습니다"});return
   for i in range(100):
    code="%06d"%rng.randi_range(0,999999)
    if not rooms.has(code):break
   rooms[code]=Rules.new(code)
  if not rooms.has(code):send(conn,{"op":"error","error":"해당 방 코드를 찾을 수 없습니다"});return
  if studies.has(conn.uid):send(conn,{"op":"error","error":"그림 수련에서 먼저 돌아오세요"});return
  var loadout=data.get("slots",[])
  if not loadout is Array:loadout=[]
  var account:=account_for(conn.identity)
  account.reserve=str(data.get("reserve",""))
  if not rooms[code].add(conn.uid,Catalog.clean_name(data.get("name","도사")),loadout,account):send(conn,{"op":"error","error":"게임 중이거나 방이 가득 찼습니다"});return
  rooms[code].players[conn.uid].form_choice="cat" if data.get("forest_mastery",false) and data.get("form","")=="cat" else "jar"
  var player: Dictionary=rooms[code].players[conn.uid]
  player.career_wins=int(identities[conn.identity].get("wins",0))
  var outfit: Dictionary=preload("res://scripts/wardrobe/catalog.gd").normalize(data.get("appearance",{}))
  player.cosmetic=outfit
  conn.room=code;send(conn,{"op":"joined","room":code});return
 if op=="leave":
  if rooms.has(conn.room):rooms[conn.room].mark_disconnected(conn.uid)
  conn.room="";send(conn,{"op":"left"});return
 if not rooms.has(conn.room):send(conn,{"op":"error","error":"서버의 방이 종료되었습니다","room_expired":true});return
 # Cosmetic acquisition is free; Rules.command still enforces lobby-only changes.
 var reply: Dictionary=rooms[conn.room].command(conn.uid,data)
 if not reply.is_empty():reply.op="reply";send(conn,reply)
