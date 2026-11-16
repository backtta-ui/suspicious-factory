extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var view:=SubViewport.new();view.size=Vector2i(3000,2160);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var terrain:=preload("res://scripts/woo/forest_ground.gd").new();view.add_child(terrain)
 await process_frame;await RenderingServer.frame_post_draw
 var image:=view.get_texture().get_image()
 var error:=image.save_png("res://assets/woo/v13/forest_ground.png")
 print("Forest ground bake: ",error);quit(error)
