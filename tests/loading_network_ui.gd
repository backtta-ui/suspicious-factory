extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.show_seal();await frames()
 var client=game.seal_client;var original: Dictionary=game.Save.load_game().duplicate(true)
 client.address_input.text="invalid-address";client.connect_server();await frames()
 check(not is_instance_valid(client.connection_overlay),"invalid server address clears connection overlay")
 check(client.status_label.text.contains("확인"),"connection failure remains as visible actionable status")
 check(not game.content_loading,"network connection never masquerades as local map preparation")
 client.address_input.text="ws://127.0.0.1:1";client.connect_server()
 check(is_instance_valid(client.connection_overlay) and client.connection_overlay.title.contains("다른 도사들과 연결"),"valid connection attempt uses shared animated art and network message")
 var cancel: Button
 for child in client.connection_overlay.get_children():
  if child is Button:cancel=child
 cancel.pressed.emit();await frames()
 check(not client.connection.desired and not is_instance_valid(client.connection_overlay),"cancel stops actual connection and removes waiting overlay")
 client.address_input.text="ws://127.0.0.1:1";client.connect_server();client.back();await frames()
 check(game.screen_name=="menu" and not is_instance_valid(game.seal_client),"Android back exits connection UI safely")
 check(game.Save.load_game()==original,"connection errors and cancellation preserve single-player save")
 game.queue_free();await frames();print("LOADING NETWORK UI: %d checks / %d failures"%[checks,failures]);quit(1 if failures else 0)
