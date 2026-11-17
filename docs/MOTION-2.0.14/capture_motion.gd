extends SceneTree
const Actor=preload("res://scripts/woo/actor.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const D=preload("res://scripts/wardrobe/direction.gd")
var actors: Array=[]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var bg:=ColorRect.new();bg.color=Color("172333");bg.size=Vector2(1280,720);root.add_child(bg)
 for row in range(4):
  for col in range(8):
   var actor:=Actor.new();actor.cosmetic=C.base_appearance(["woochi","yeonhwa","muyeong","hongryeon"][row]);actor.position=Vector2(80+col*160,155+row*172);actor.facing=D.FACING[col];root.add_child(actor);actor.set_physics_process(false);actor.scale=Vector2.ONE*2;actors.append(actor)
 for mode in ["walk","run"]:
  for frame in range(12):
   for actor in actors:
    actor.running=mode=="run";actor.velocity=Vector2.from_angle(actor.facing*PI/4)*(142 if actor.running else 88);actor.gait_phase=frame*TAU/12;actor.gait_weight=1;actor.wardrobe_visual._process(0)
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/MOTION-2.0.14/"+mode+"-%02d.png"%frame)
 for actor in actors:actor.queue_free()
 await process_frame;quit()
