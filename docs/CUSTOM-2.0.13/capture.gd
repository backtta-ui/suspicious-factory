extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
func _initialize() -> void:run.call_deferred()
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames();game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.draft=C.base_appearance("woochi");screen.refresh();await frames()
 await RenderingServer.frame_post_draw
 var baseline:=root.get_texture().get_image()
 baseline.save_png("res://docs/CUSTOM-2.0.13/native-baseline.png")
 screen.draft.accessory="ribbon";screen.refresh();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/CUSTOM-2.0.13/ribbon-reproduction-fixed.png")
 screen.draft.hair="silver";screen.draft.hat="bamboo";screen.draft.color="green";screen.refresh();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/CUSTOM-2.0.13/unsupported-look-explicit.png")
 screen.slot="hat";screen.refresh();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/CUSTOM-2.0.13/headwear-compatibility.png")
 var saved_look:=screen.draft.duplicate()
 game.close_modal();await frames();game.player.cosmetic=saved_look;game.player.update_sprite();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/CUSTOM-2.0.13/plaza-saved-look.png")
 var reference:=Image.load_from_file("res://docs/CUSTOM-2.0.13/native-baseline.png")
 var area:=Rect2i(200,220,140,132)
 var comparisons: Dictionary={}
 for path in ["ribbon-reproduction-fixed.png","unsupported-look-explicit.png"]:
  var actual:=Image.load_from_file("res://docs/CUSTOM-2.0.13/"+path)
  comparisons[path]=actual.get_region(area).get_data()==reference.get_region(area).get_data()
 var report:=FileAccess.open("res://docs/CUSTOM-2.0.13/render-comparison.json",FileAccess.WRITE);report.store_string(JSON.stringify({"area":[200,220,140,132],"head_hat_pixels_identical":comparisons},"  "));report.close()
 game.queue_free();await frames();quit(0 if comparisons.values().all(func(value: bool)->bool:return value) else 1)
