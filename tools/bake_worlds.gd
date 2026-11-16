extends SceneTree
const Map=preload("res://scripts/worlds/map.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 for id in ["moon_palace","red_sea"]:
  var viewport:=SubViewport.new();viewport.size=Vector2i(1800,1300);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
  var map:=Map.new();map.map_id=id
  var floor_layer:=Node2D.new();floor_layer.draw.connect(map.draw_floor.bind(floor_layer));viewport.add_child(floor_layer)
  await process_frame;await RenderingServer.frame_post_draw
  var error:=viewport.get_texture().get_image().save_png("res://assets/woo/worlds/"+id+"_ground.png");print("WORLD FLOOR ",id," ",error)
  floor_layer.queue_free();await process_frame;map.free()
  map=Map.new();map.map_id=id;map.use_baked_ground=false;viewport.add_child(map)
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  error=viewport.get_texture().get_image().save_png("res://assets/woo/worlds/"+id+".png");print("WORLD THUMBNAIL ",id," ",error)
  viewport.queue_free();await process_frame
 quit()
