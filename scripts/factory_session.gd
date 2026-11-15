class_name FactorySession
extends Node
## Development movement transport. No roles, votes, missions, matchmaking or accounts.
## Server owns all positions. Client packets contain intent only; never a position.
signal status_changed(message: String)
signal snapshot_changed
const Layout = preload("res://scripts/map_layout.gd")
const MAX_PLAYERS := 8
var layout: FactoryLayout
var server_mode := false
var active := false
var ready_to_play := false
var players: Dictionary = {}
var public_peers: Dictionary = {}
var own_position := Vector2.ZERO
var local_intent := Vector2.ZERO
var own_id := 0
var sequence := 0
var snapshot_sequence := 0
var received_sequence := -1
var send_time := 0.0
var connection_age := 0.0
var status_message := "오프라인"
var outfit := {"hat":1,"vest":0,"nickname":"신입사원"}

func _ready() -> void:
	layout = Layout.new()
	multiplayer.peer_disconnected.connect(peer_left)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_lost)

func set_status(message: String) -> void:
	status_message = message
	status_changed.emit(message)

func host(port: int) -> Error:
	if active: return ERR_ALREADY_IN_USE
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port,MAX_PLAYERS)
	if error != OK: return error
	multiplayer.multiplayer_peer = peer
	server_mode = true
	active = true
	set_status("서버 실행 중")
	return OK

func join(hostname: String, port: int, appearance: Dictionary) -> Error:
	if active: return ERR_ALREADY_IN_USE
	if hostname.strip_edges().is_empty() or port<1 or port>65535: return ERR_INVALID_PARAMETER
	outfit = appearance.duplicate()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(hostname.strip_edges(),port)
	if error != OK: return error
	multiplayer.multiplayer_peer = peer
	active = true
	server_mode = false
	ready_to_play = false
	sequence = 0
	received_sequence = -1
	connection_age = 0
	send_time = 0
	set_status("서버 연결 중")
	return OK

func disconnect_session() -> void:
	active = false
	ready_to_play = false
	local_intent = Vector2.ZERO
	public_peers.clear()
	players.clear()
	if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	set_status("오프라인")

func connected() -> void:
	own_id = multiplayer.get_unique_id()
	register_player.rpc_id(1,layout.map_hash,int(outfit.hat),int(outfit.vest),str(outfit.nickname))

func connection_failed() -> void:
	disconnect_session()
	set_status("연결 실패: 주소·UDP 포트·서버 실행 상태를 확인하세요")

func server_lost() -> void:
	disconnect_session()
	set_status("서버 연결이 끊겼습니다. 오프라인으로 복귀했습니다")

func peer_left(id: int) -> void:
	if server_mode: players.erase(id)

@rpc("any_peer","call_remote","reliable",0)
func register_player(hash_value: String, hat: int, vest: int, nickname: String) -> void:
	if not server_mode: return
	var id := multiplayer.get_remote_sender_id()
	if id<=1 or players.has(id): return
	if hash_value != layout.map_hash or players.size()>=MAX_PLAYERS:
		reject_session.rpc_id(id,"맵 버전 불일치 또는 정원 초과")
		return
	var offset := Vector2((players.size()%4)*60-90,floori(players.size()/4.0)*50)
	var position := layout.spawn+offset
	if not layout.can_stand(position): position = layout.spawn
	players[id] = {"position":position,"intent":Vector2.ZERO,"hat":clampi(hat,0,2),"vest":clampi(vest,0,2),"nickname":nickname.strip_edges().replace("\n","").replace("\r","").left(12),"sequence":-1,"last_input":Time.get_ticks_msec(),"facing":1.0}

@rpc("authority","call_remote","reliable",0)
func reject_session(reason: String) -> void:
	if server_mode: return
	disconnect_session()
	set_status(reason)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func submit_input(intent: Vector2, input_sequence: int) -> void:
	if not server_mode: return
	var id := multiplayer.get_remote_sender_id()
	accept_intent(id,intent,input_sequence)

func accept_intent(id: int, intent: Vector2, input_sequence: int) -> void:
	if not players.has(id) or not is_finite(intent.x) or not is_finite(intent.y): return
	var player: Dictionary = players[id]
	if input_sequence<=int(player.sequence): return
	player.sequence = input_sequence
	player.intent = intent.limit_length()
	player.last_input = Time.get_ticks_msec()

func snapshot_for(id: int) -> Dictionary:
	if not players.has(id): return {}
	var result: Dictionary = {}
	var origin: Vector2 = players[id].position
	for other in players:
		var player: Dictionary = players[other]
		if other != id and not layout.visible_between(origin,player.position): continue
		# Whitelist public fields. Never send full server player records.
		result[other] = {"position":player.position,"hat":player.hat,"vest":player.vest,"nickname":player.nickname,"facing":player.facing}
	return result

@rpc("authority","call_remote","unreliable_ordered",0)
func receive_snapshot(tick: int, visible_players: Dictionary) -> void:
	if server_mode or tick<=received_sequence or not visible_players.has(own_id): return
	received_sequence = tick
	public_peers = visible_players
	own_position = public_peers[own_id].position
	if not ready_to_play:
		ready_to_play = true
		set_status("멀티 이동 테스트 연결됨")
	snapshot_changed.emit()

func _physics_process(delta: float) -> void:
	if not active: return
	if server_mode:
		for id in players:
			var player: Dictionary = players[id]
			var intent: Vector2 = player.intent if Time.get_ticks_msec()-int(player.last_input)<400 else Vector2.ZERO
			player.position = layout.move_validated(player.position,intent,delta)
			if absf(intent.x)>0.1: player.facing = signf(intent.x)
		send_time += delta
		if send_time>=0.05:
			send_time = fmod(send_time,0.05)
			snapshot_sequence += 1
			for id in players: receive_snapshot.rpc_id(id,snapshot_sequence,snapshot_for(id))
	else:
		connection_age += delta
		if not ready_to_play and connection_age>8:
			connection_failed()
			return
		var peer := multiplayer.multiplayer_peer
		if peer and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:
			send_time += delta
			if send_time>=0.05:
				send_time = fmod(send_time,0.05)
				sequence += 1
				submit_input.rpc_id(1,local_intent,sequence)
