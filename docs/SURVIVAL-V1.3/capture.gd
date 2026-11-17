extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/SURVIVAL-V1.3/"+name+".png")
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/survival.tscn").instantiate();root.add_child(game);await shot("01-title")
 game.show_settings();await shot("02-settings");game.close_popup();game.build("lobby");await shot("03-lobby")
 game.build("rooms");await shot("04-room-list");game.room_dialog();await shot("05-create-room");game.close_popup()
 game.create_room("월하의 서원 · 테스트",6,true);await create_timer(.4).timeout;await shot("06-room")
 game.selection_return="room";game.selection_id=game.storage.data.daoist;game.build("characters");await shot("07-character")
 game.build("room");game.rules.players.human.ready=true;game.start_match();await shot("08-vs")
 for i in range(200):
  await process_frame
  if game.screen=="match" and not game.changing:break
 await shot("09-countdown");await create_timer(3.5).timeout;await shot("10-match")
 # Accelerated authority simulation; normal rules and commands, no forced winner.
 var decision:=0.0
 for i in range(12100):
  game.rules.tick(.05);decision+=.05
  if decision>=.35 and game.rules.phase=="live":
   for bot in game.bots:bot.think(decision)
   decision=0
  if game.rules.phase=="result":break
 await frames();await shot("11-result")
 game.cleanup_match();game.setup_participants();game.build("room");await shot("12-rematch")
 game.queue_free();await frames();quit()
