extends SceneTree
func _initialize() -> void:run.call_deferred()
func frames(n: int=6) -> void:
 for i in range(n):await process_frame
func run() -> void:
 root.size=Vector2i(1280,720)
 var scene=load("res://scenes/survival.tscn")
 if scene==null:push_error("Pack entry missing");quit(1);return
 var game=scene.instantiate();root.add_child(game);await frames()
 print("PACK TITLE ",game.screen)
 game.build("lobby");game.enter_practice();await frames(12);game.practice.select("clone");game.practice.cast();await frames(8)
 print("PACK PRACTICE CLONES ",game.practice.clones.size());game.practice.request_leave();await create_timer(.4).timeout
 game.create_room("pack",6,true);await create_timer(.4).timeout;game.rules.players.human.ready=true;game.start_match();game.rules.confirm_character("human")
 for i in range(200):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 print("PACK WORLD ",game.screen," avatars ",game.avatars.size())
 if game.screen!="match":push_error("Pack match failed");quit(1);return
 game.queue_free();await frames();print("PACK SMOKE PASSED");quit()
