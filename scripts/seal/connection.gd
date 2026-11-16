class_name SealConnection
extends Node
signal packet(data: Dictionary)
signal status(message: String)
const C=preload("res://scripts/seal/catalog.gd")
var profile: Dictionary
var ws: WebSocketPeer
var uid:=""
var room:=""
var endpoint:=""
var authenticated:=false
var desired:=false
var last_receive:=0.0
var clock:=0.0
var ping_left:=0.0
var retry_left:=0.0
var tries:=0
var attempt_time:=0.0
var was_open:=false
var latency_ms:=0
func connect_to(address: String) -> Error:
 if not address.begins_with("wss://") and not address.begins_with("ws://"):return ERR_INVALID_PARAMETER
 if address.length()>240 or "@" in address or " " in address:return ERR_INVALID_PARAMETER
 if address.begins_with("ws://"):
  var host:=address.trim_prefix("ws://").split("/")[0].split(":")[0]
  var private_host:=host=="localhost" or host.begins_with("127.") or host.begins_with("192.168.") or host.begins_with("10.") or host.ends_with(".local")
  if host.begins_with("172."):
   var parts:=host.split(".")
   if parts.size()==4:private_host=int(parts[1])>=16 and int(parts[1])<=31
  if not private_host:return ERR_UNAUTHORIZED
 endpoint=address;desired=true;tries=0;return begin()
func begin() -> Error:
 if is_instance_valid(ws):ws.close()
 ws=WebSocketPeer.new();ws.inbound_buffer_size=262144;ws.outbound_buffer_size=32768;ws.max_queued_packets=64
 var err:=ws.connect_to_url(endpoint)
 authenticated=false;was_open=false;attempt_time=clock;last_receive=clock
 status.emit("무료 서버를 깨우는 중일 수 있습니다 · 최대75초 대기")
 if err!=OK:retry_left=3;status.emit("연결을 시작하지 못했습니다. 주소와 네트워크를 확인하세요")
 return err
func send(data: Dictionary) -> bool:
 if ws==null or ws.get_ready_state()!=WebSocketPeer.STATE_OPEN:return false
 return ws.send_text(JSON.stringify(data))==OK
func stop() -> void:
 desired=false;authenticated=false
 if ws!=null:ws.close()
func _process(delta: float) -> void:
 clock+=delta
 if not desired or ws==null:return
 ws.poll()
 var state:=ws.get_ready_state()
 if state==WebSocketPeer.STATE_OPEN:
  if not was_open:
   was_open=true;tries=0
   send({"op":"hello","protocol":C.PROTOCOL,"identity":profile.id,"proof":profile.secret,"room":room,"ticket":profile.get("progress_tickets",{}).get(endpoint,"")})
  while ws.get_available_packet_count()>0:
   var bytes:=ws.get_packet()
   if bytes.size()>131072:ws.close(1009);break
   var value=preload("res://scripts/seal/codec.gd").decode(bytes)
   if not value is Dictionary:continue
   last_receive=clock
   if value.get("op","")=="hello":uid=value.uid;authenticated=true;status.emit("서버 연결 완료")
   if value.get("op","")=="joined":room=value.room
   if value.get("op","")=="left" or value.get("room_expired",false):room=""
   if value.get("op","")=="pong":latency_ms=int((Time.get_ticks_msec()-float(value.get("stamp",Time.get_ticks_msec()))))
   packet.emit(value)
   if value.get("op","")=="error" and not authenticated:desired=false;ws.close()
  ping_left-=delta
  if ping_left<=0 and authenticated:ping_left=4;send({"op":"ping","stamp":Time.get_ticks_msec()})
  if clock-last_receive>20:ws.close(1001,"Timeout");status.emit("응답 지연 · 재접속을 시도합니다")
 elif state==WebSocketPeer.STATE_CLOSED:
  authenticated=false;retry_left-=delta
  if retry_left<=0:
   tries+=1;retry_left=minf(15,2+tries*2)
   if tries>8:status.emit("연결할 수 없습니다. 서버 주소/절전 상태를 확인하고 다시 연결하세요");desired=false;return
   status.emit("연결 끊김 · 재접속 %d/8" % tries);begin()
 elif clock-attempt_time>80:ws.close(1001,"Cold start timeout")
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_RESUMED or what==NOTIFICATION_APPLICATION_FOCUS_IN:
  if desired and ws!=null and ws.get_ready_state()==WebSocketPeer.STATE_CLOSED:retry_left=0
