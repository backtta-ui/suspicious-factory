extends SceneTree
## godot --headless --path . --script res://tools/server.gd -- --port=24560
func _initialize() -> void:
	start.call_deferred()
func start() -> void:
	var game := Node.new()
	game.name = "SuspiciousFactory"
	root.add_child(game)
	var session := preload("res://scripts/factory_session.gd").new()
	session.name = "FactorySession"
	game.add_child(session)
	var port := 24560
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="): port = arg.trim_prefix("--port=").to_int()
	var error := session.host(port)
	if error != OK:
		push_error("Server bind failed: "+error_string(error))
		quit(1)
	else:
		print("FACTORY SERVER READY port=%d map=%s max_players=8" % [port,session.layout.map_hash])
