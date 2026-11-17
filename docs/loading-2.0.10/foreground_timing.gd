extends SceneTree
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func wait_ready(game: Node) -> void:
 while game.content_loading or game.adventure.transitioning:await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 var samples: Array=[]
 for i in range(3):
  game.request_start();await wait_ready(game);samples.append(game.loading.history[-1].duplicate(true))
  if i<2:game.show_menu(false);await frames()
 for id in ["fox_forest","moon_palace","red_sea"]:
  for i in range(2):
   game.request_gallery(0);await wait_ready(game);game.adventure.selected_world=id;game.adventure.enter_painting();await wait_ready(game);samples.append(game.loading.history[-1].duplicate(true))
   game.adventure.return_to_plaza();await wait_ready(game);samples.append(game.loading.history[-1].duplicate(true))
 game.enter_practice("shield");await wait_ready(game);samples.append(game.loading.history[-1].duplicate(true));game.practice.request_leave();await wait_ready(game);samples.append(game.loading.history[-1].duplicate(true))
 var f:=FileAccess.open("res://docs/loading-2.0.10/foreground-timing.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":"Linux headless; warm process; foreground; no other local Godot jobs during sample; not Android","requests":samples},"  "))
 game.queue_free();await frames();quit()
