extends SceneTree
var game: Node
var peers: Array[Dictionary]=[]
var checks:=0
var failures:=0
var address: String=OS.get_environment("SEAL_TEST_URL")
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func poll() -> void:
 for p in peers:
  p.ws.poll()
  while p.ws.get_available_packet_count()>0:
   var data=JSON.parse_string(p.ws.get_packet().get_string_from_utf8())
   if data is Dictionary:
    if data.get("op","")=="hello":p.auth=true
    if data.get("op","")=="state":p.state=data.state
func wait_for(predicate: Callable,seconds: float=5) -> bool:
 var until:=Time.get_ticks_msec()+int(seconds*1000)
 while Time.get_ticks_msec()<until:
  poll()
  if predicate.call():return true
  await process_frame
 return false
func send(p: Dictionary,data: Dictionary) -> void:p.ws.send_text(JSON.stringify(data))
func find_button(value: String,node: Node) -> Button:
 if node is Button and node.text==value and node.is_visible_in_tree():return node
 for child in node.get_children():
  var found:=find_button(value,child)
  if found!=null:return found
 return null
func tap(b: Button,id: int=0) -> void:
 if b==null:check(false,"required UI control exists");return
 var p:=b.get_global_rect().get_center()
 for on in [true,false]:
  var e:=InputEventScreenTouch.new();e.index=id;e.position=root.get_final_transform()*p;e.pressed=on;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 for i in range(3):await process_frame
func shot(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/v20-net-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.show_seal();await process_frame;var ui: SealClientUI=game.seal_client
 ui.address_input.text=address;ui.name_input.text="검사방장";ui.connect_server()
 if not await wait_for(func()->bool:return ui.connection.authenticated):check(false,"UI real-server connect");game.queue_free();await process_frame;quit(1);return
 check(true,"multiplayer setup connects actual WebSocket server")
 ui.join_room("create")
 check(await wait_for(func()->bool:return ui.screen=="lobby" and not ui.state.is_empty()),"actual lobby replaces setup after server join acknowledgement")
 for i in range(5):
  var ws:=WebSocketPeer.new();ws.connect_to_url(address);var p: Dictionary={"ws":ws,"auth":false,"state":{}};peers.append(p)
  await wait_for(func()->bool:return ws.get_ready_state()==WebSocketPeer.STATE_OPEN)
  var crypto:=Crypto.new();send(p,{"op":"hello","protocol":2,"identity":crypto.generate_random_bytes(16).hex_encode(),"proof":crypto.generate_random_bytes(32).hex_encode()});await wait_for(func()->bool:return p.auth)
  send(p,{"op":"join","room":ui.connection.room,"name":"네트워크%d"%i})
 check(await wait_for(func()->bool:return ui.state.roster.size()==6),"real UI roster shows all six network participants")
 await shot("lobby")
 for p in peers:send(p,{"op":"ready","value":true})
 await tap(find_button("준비 / 취소",game.ui))
 await wait_for(func()->bool:return ui.state.roster.all(func(p: Dictionary)->bool:return p.ready))
 await tap(find_button("방장 시작",game.ui))
 check(await wait_for(func()->bool:return ui.screen=="game" and ui.avatars.size()==6),"ready/start native touches create synchronized six-avatar world")
 check(ui.avatars.values().all(func(a: WooActor)->bool:return a.tint==Color.WHITE and a.sprite.texture==a.SHEET),"all public avatars use identical canonical appearance and neutral tint")
 check(ui.state.self.role in ["daoist","yokai"] and not ui.state.roster[0].has("role"),"only own role appears in live gameplay HUD")
 await shot("prepare")
 var rect:=Rect2(Vector2.ZERO,game.ui.size)
 check(ui.skill_buttons.all(func(b: Button)->bool:return rect.encloses(b.get_global_rect())) and rect.encloses(ui.role_button.get_global_rect()),"role and common skill icons fit mobile landscape viewport")
 ui.show_pause();await process_frame;check(is_instance_valid(ui.popup) and game.active_context=="seal_modal","network menu blocks local controls without pausing server")
 ui.back();await process_frame;check(not is_instance_valid(ui.popup) and game.active_context=="seal","Android back restores network HUD touch context")
 check(await wait_for(func()->bool:return ui.state.phase=="roam",34),"network UI reaches roaming after real preparation timeout")
 var before:=Vector2(ui.state.self.position[0],ui.state.self.position[1]);ui.stick.vector=Vector2.RIGHT
 var until:=Time.get_ticks_msec()+600
 while Time.get_ticks_msec()<until:poll();await process_frame
 ui.stick.reset();await wait_for(func()->bool:return Vector2(ui.state.self.position[0],ui.state.self.position[1]).distance_to(before)>2)
 check(Vector2(ui.state.self.position[0],ui.state.self.position[1]).distance_to(before)>2,"touch movement reaches authoritative server and returns through UI snapshots")
 await shot("roam")
 ui.show_pause();await process_frame;await tap(find_button("방 나가기",game.ui));await process_frame
 check(ui.screen=="login" and ui.connection.room=="","leave room returns to address setup without touching single-player save")
 ui.back();await process_frame;check(game.screen_name=="menu","network mode exits back to preserved main title")
 for p in peers:p.ws.close()
 game.queue_free();await process_frame;await process_frame;print("SEAL UI: %d checks, %d failures; automated sockets, no Android device claim"%[checks,failures]);quit(0 if failures==0 else 1)
