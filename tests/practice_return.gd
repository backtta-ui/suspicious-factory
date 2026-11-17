extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func frames(n: int=4) -> void:
 await preload("res://tests/loading_wait.gd").settle(self,n)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
 var forest: Node=game.adventure.forest;game.player.facing=5;game.camera.rotation=.02;game.camera.zoom=Vector2(2.2,2.2)
 var origin: Vector2=game.player.position;var direction: int=game.player.facing;var rpg: Dictionary=game.rpg.data.duplicate(true)
 game.adventure.show_spells();game.enter_practice("blink");await frames();var during: Dictionary=game.rpg.data.duplicate(true)
 check(game.screen_name=="practice" and not forest.visible,"adventure codex opens training and freezes old forest")
 game.practice.session.self_player().position=Vector2(850,800);game.practice.session.hp=30;game.practice.session.select("shield");game.practice.cast();await frames()
 check(game.rpg.data==during,"practice health, casts and local positions cannot mutate mission progress")
 game.practice.leave();await frames()
 check(game.player.get_parent()==forest and forest.visible and game.adventure.in_mission,"returns to same real adventure instance")
 check(game.player.position==origin and game.player.facing==direction and game.camera.zoom==Vector2(2.2,2.2) and is_equal_approx(game.camera.rotation,.02),"mission return preserves player and camera pose")
 check(game.rpg.data.inventory==rpg.inventory and game.rpg.data.hp==rpg.hp and game.rpg.data.mp==rpg.mp and game.rpg.data.claims==rpg.claims,"mission inventory, HP, MP and rewards remain intact")
 game.show_menu(false);game.queue_free();await frames();print("PRACTICE RETURN: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
