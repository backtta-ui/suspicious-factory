extends SceneTree
const Main=preload("res://scenes/main.tscn")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/OFFLINE-BOTS-1.1/"+name+".png")
func run() -> void:
 root.size=Vector2i(1280,720);game=Main.instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.player.position=preload("res://scripts/simulation/entrance.gd").DOOR+Vector2(0,25);await shot("plaza-entrance")
 game.enter_simulation();await frames();var client=game.seal_client;client.connection.set_process(false);client.connection.seed_value=9;client.connection.rebuild();client.connection.publish();await shot("lobby")
 client.show_loadout();await shot("spells")
 var scroll: ScrollContainer=client.popup.find_children("*","ScrollContainer",true,false)[0];scroll.scroll_vertical=10000;await shot("spells-last");client.close_popup()
 client.connection.configure_size(8,3);await shot("lobby-eight");client.connection.configure_size(6,2)
 client.show_characters();await shot("characters");client.close_popup()
 client.connection.send({"op":"ready","value":true});client.connection.send({"op":"start"})
 for i in range(61):client.connection.step(.05)
 client.connection.publish()
 await shot("map-loading")
 for i in range(200):
  await process_frame
  if client.screen=="game" and not client.entering:break
 await shot("role-and-game")
 for i in range(2000):client.connection.step(.05)
 client.connection.publish();await shot("match-progress")
 var spectator_recorded:=false
 for i in range(8000):
  client.connection.step(.05)
  if client.connection.rules.players[client.connection.uid].sealed and client.connection.rules.phase!="result" and not spectator_recorded:
   spectator_recorded=true;client.connection.publish();await shot("spectator")
  if client.connection.rules.phase=="result":break
 client.connection.publish();await shot("result")
 client.close_popup();client.connection.send({"op":"rematch"});await shot("rematch")
 client.exit_to_main();await shot("plaza-return")
 game.queue_free();await frames();quit()
