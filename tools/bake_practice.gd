extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var viewport:=SubViewport.new();viewport.size=Vector2i(1280,960);viewport.transparent_bg=false;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var painter:=preload("res://scripts/practice/world.gd").new()
 var canvas:=Node2D.new();canvas.draw.connect(func()->void:painter.draw_ground(canvas));viewport.add_child(canvas)
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 var error:=viewport.get_texture().get_image().save_png("res://assets/woo/practice_ground.png");print("PRACTICE GROUND BAKED ",error)
 viewport.queue_free();await process_frame;painter.free();quit(0 if error==OK else 1)
