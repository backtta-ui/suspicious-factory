extends SceneTree
## 걷기 프레임 눈 검수: 정지 · walk1 · walk2 를 크게 나란히 그린다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_walk_check.gd
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const IDS=["woochi","yeonhwa","muyeong","hongryeon","gumiho","jangsanbeom","dokkaebi","haechi"]
var stage: Node2D
func _initialize() -> void:run.call_deferred()
func capture(path: String) -> void:
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("WALK RENDER ",path," ",image.get_size())
func make_actor(id: String,pose: String,at: Vector2,scale_value: float) -> Node2D:
 var actor:=Actor.new()
 actor.cosmetic=Looks.base_appearance(id)
 actor.ingame_art=true;actor.art_id=id
 actor.position=at;actor.scale=Vector2(scale_value,scale_value)
 actor.set_physics_process(false)
 stage.add_child(actor)
 actor.update_sprite()
 match pose:
  "walk1":actor.gait_weight=1.0;actor.gait_phase=0.0
  "walk2":actor.gait_weight=1.0;actor.gait_phase=PI*2.0
  _:actor.gait_weight=0.0;actor.gait_phase=0.0
 for i in range(3):actor.ingame_sprite._process(0.016)
 return actor
func run() -> void:
 root.size=Vector2i(1280,720)
 var back:=ColorRect.new();back.color=Color(.06,.07,.1);back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(back)
 stage=Node2D.new();root.add_child(stage)
 var poses=["idle","walk1","walk2"]
 var labels=["정지","walk1","walk2"]
 for c in range(3):
  make_actor("woochi",poses[c],Vector2(300+c*300,470),4.2)
  var label:=Label.new();label.text=labels[c];label.position=Vector2(300+c*300-60,540);label.size=Vector2(120,40)
  label.add_theme_color_override("font_color",Color.WHITE);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  stage.add_child(label)
 await capture("res://builds/v2019_walk_poses.png")
 stage.queue_free();stage=Node2D.new();root.add_child(stage)
 for i in range(IDS.size()):
  make_actor(IDS[i],"walk1" if i%2==0 else "walk2",Vector2(90+i*157,560),2.1)
  var label:=Label.new();label.text=IDS[i];label.position=Vector2(90+i*157-70,600);label.size=Vector2(140,30)
  label.add_theme_color_override("font_color",Color(0.85,0.85,0.9));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  stage.add_child(label)
 await capture("res://builds/v2019_walk_roster.png")
 print("WALK CHECK DONE")
 quit()
