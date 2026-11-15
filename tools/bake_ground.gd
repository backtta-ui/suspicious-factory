extends SceneTree
## Bake procedural stone paths once during development, never on the phone.
func _initialize() -> void: bake.call_deferred()
func bake() -> void:
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(1800,960)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 root.add_child(viewport)
 var canvas:=Node2D.new()
 var village:=preload('res://scripts/woo/village.gd').new()
 canvas.draw.connect(village.draw_ground.bind(canvas))
 viewport.add_child(canvas)
 await RenderingServer.frame_post_draw
 var result:=viewport.get_texture().get_image().save_png('res://assets/woo/ground_baked.png')
 village.free();viewport.queue_free()
 print('GROUND BAKE: ',result)
 quit(result)
