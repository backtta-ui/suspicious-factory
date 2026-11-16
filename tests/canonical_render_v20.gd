extends SceneTree
var actor: WooActor
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/v20-canonical-"+name+".png")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var background:=ColorRect.new();background.size=Vector2(1280,720);background.color=Color("172132");root.add_child(background)
 actor=preload("res://scripts/woo/actor.gd").new();actor.position=Vector2(640,450);actor.scale=Vector2(2,2);actor.facing=2;root.add_child(actor);actor.set_physics_process(false);actor.update_sprite();await frames();await shot("idle")
 for i in range(4):
  actor.action_pose=i;actor.action_left=.22;actor.pose_duration=.4;actor.update_sprite();await frames();await shot("attack%d"%i)
 actor.queue_free();background.queue_free();await frames();quit()
