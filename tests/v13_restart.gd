extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_game(true);await process_frame
 var ok: bool=game.adventure.in_mission and game.rpg.data.claims==["fox_forest"] and game.rpg.data.coins==50 and game.rpg.data.session.defeated==[0,1,2] and not game.rpg.claim_fox_reward()
 print("PASS: fresh-process continuation preserves forest kills and prevents duplicate claimed rewards" if ok else "FAIL: fresh-process RPG continuation")
 game.queue_free();await process_frame;await process_frame;quit(0 if ok else 1)
