extends SceneTree
# Build complete native atlases through the SAME renderer used by gameplay.
const C=preload("res://scripts/wardrobe/catalog.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const Direction=preload("res://scripts/wardrobe/direction.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 for character in C.CHARACTERS:
  for kind in ["core","actions"]:
   var rows:=4 if kind=="core" else 6
   var viewport:=SubViewport.new();viewport.size=Vector2i(640,160*rows);viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
   for row in range(rows):
    for col in range(4):
     var actor:=Actor.new();actor.draw_ground=false;actor.cosmetic=C.base_appearance(character);actor.facing=Direction.FACING[col];actor.position=Vector2(col*160+80,row*160+140);actor.scale=Vector2.ONE*(160.0/96.0);viewport.add_child(actor);actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0;actor.update_sprite()
     actor.wardrobe_visual.force_modular=true;actor.wardrobe_visual.pose_override=kind;actor.wardrobe_visual.row_override=row
   for frame in range(4):await process_frame
   await RenderingServer.frame_post_draw
   var error:=viewport.get_texture().get_image().save_png("res://assets/woo/characters/base_"+character+"_"+kind+".png")
   print("BAKE ",character,"/",kind," ",error)
   if error!=OK:quit(1);return
   viewport.queue_free()
   for frame in range(3):await process_frame
 quit()
