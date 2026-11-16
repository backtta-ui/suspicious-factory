extends SceneTree
func _initialize() -> void: bake.call_deferred()
func bake() -> void:
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(3400,1900)
 viewport.transparent_bg=false
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 root.add_child(viewport)
 viewport.add_child(preload("res://scripts/worlds/plaza_terrain.gd").new())
 await RenderingServer.frame_post_draw
 var image:=viewport.get_texture().get_image()
 if image.get_pixel(300,800).g<image.get_pixel(300,800).r*1.15:
  push_error("Ground material missing or lost before render");quit(1);return
 var error:=image.save_png("res://assets/woo/worlds/plaza_ground.png")
 viewport.queue_free()
 print("GROUND BAKE: ",error," size=",image.get_size())
 if error!=OK:quit(error);return
 var bridge_view:=SubViewport.new();bridge_view.size=Vector2i(480,90);bridge_view.transparent_bg=true;bridge_view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(bridge_view)
 var canvas:=Node2D.new();canvas.position=Vector2(-1460,-1255)
 var renderer:=preload("res://scripts/woo/water.gd").new()
 canvas.draw.connect(renderer.draw_bridge.bind(canvas));bridge_view.add_child(canvas)
 await RenderingServer.frame_post_draw
 error=bridge_view.get_texture().get_image().save_png("res://assets/woo/v11/stone_bridge.png")
 renderer.free();bridge_view.queue_free()
 print("BRIDGE BAKE: ",error)
 quit(error)
