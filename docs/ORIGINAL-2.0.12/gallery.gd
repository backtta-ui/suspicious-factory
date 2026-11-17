extends SceneTree
const Actor=preload("res://scripts/woo/actor.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const D=preload("res://scripts/wardrobe/direction.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var bg:=ColorRect.new();bg.color=Color("172333");bg.size=Vector2(1280,720);root.add_child(bg)
 var chars: Array=["woochi","yeonhwa","muyeong","hongryeon"]
 for row in range(4):
  for col in range(4):
   var actor:=Actor.new();actor.cosmetic=C.base_appearance(chars[row]);actor.position=Vector2(160+col*320,160+row*170);actor.facing=D.FACING[col];root.add_child(actor);actor.set_physics_process(false);actor.scale=Vector2.ONE*2
 for i in range(12):await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ORIGINAL-2.0.12/four-characters-four-directions.png")
 quit()
