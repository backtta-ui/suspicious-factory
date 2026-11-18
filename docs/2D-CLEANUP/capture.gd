extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/2D-CLEANUP/"+name+".png")
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/survival.tscn").instantiate();root.add_child(game);await shot("01-title")
 game.build("lobby");await shot("02-lobby")
 game.create_room("2.5D 생존전 · 오프라인",6,true);await create_timer(.4).timeout;await shot("03-room")
 game.rules.rng.seed=9;game.rules.players.human.ready=true;game.start_match();await shot("04-role-selection")
 game.rules.confirm_character("human")
 for i in range(60):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="loading":break
 await shot("05-vs-loading")
 for i in range(200):
  await process_frame
  if game.screen=="match" and not game.changing:break
 for i in range(31):game.rules.tick(.1)
 await shot("06-match")
 # Run an accelerated full match through the same actual authority/bot commands.
 var think:=0.0
 for i in range(12100):
  game.rules.tick(.05);think+=.05
  if think>=.35 and game.rules.phase=="live":
   for bot in game.bots:bot.think(think)
   think=0
  if game.rules.phase=="result":break
 await shot("07-result")
 game.cleanup_match();game.setup_participants();game.build("room");await shot("08-rematch")
 game.cleanup_match();game.room={};game.build("lobby");game.enter_practice();await shot("09-spell-test")
 game.practice.show_spells();await shot("10-spell-list")
 game.practice.select("clone");game.practice.cast();await shot("11-spell-clone")
 game.practice.request_leave();await create_timer(.4).timeout;await shot("12-return-lobby")
 game.queue_free();await frames();quit()
