extends SceneTree
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/wardrobe-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 game.wardrobe.refresh({"completed":["fox_forest"],"loot_claims":["shrine_seal"]})
 game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for c in game.get_children():
  if c is WooWardrobeScreen:screen=c
 await shot("woochi")
 for id in ["yeonhwa","muyeong","hongryeon"]:
  screen.slot="character";screen.select(id);await frames();await shot(id)
 screen.slot="hat";screen.select("bamboo");screen.slot="outfit";screen.select("night");screen.slot="accessory";screen.select("orb");screen.pose="walk";await frames();await shot("layers")
 screen.close();await frames();game.start_game(false);await frames();game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
 var fx: WooCombatEffects=game.adventure.combat
 for i in range(4):fx.swing(game.player.position+Vector2((i-1.5)*90,0),Vector2.RIGHT,i+1,"ground",110)
 await create_timer(.14).timeout;await shot("vfx")
 game.show_menu(false);game.queue_free();await frames();quit()
