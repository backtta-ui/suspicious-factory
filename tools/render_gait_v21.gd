extends SceneTree
## 2.0.21 걷기 바운스 눈 검수: 같은 캐릭터를 걷기 사이클 8박자로 나란히 세워
## 발이 땅에서 뜨지 않고 젤리처럼 튀지 않는지 한 장으로 확인한다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_gait_v21.gd
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const Actor=preload("res://scripts/woo/actor.gd")
var stage: Node2D
func _initialize() -> void:run.call_deferred()
func capture(path: String) -> void:
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("GAIT RENDER ",path," ",image.get_size())
func run() -> void:
 root.size=Vector2i(1600,900)
 var back:=ColorRect.new();back.color=Color(.07,.08,.11);back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(back)
 stage=Node2D.new();root.add_child(stage)
 var ground:=ColorRect.new();ground.color=Color(.16,.14,.12);ground.position=Vector2(0,700);ground.size=Vector2(1600,4);root.add_child(ground)
 for i in range(8):
  var actor:=Actor.new()
  actor.cosmetic=Looks.base_appearance("woochi")
  actor.ingame_art=true;actor.art_id="woochi"
  actor.position=Vector2(90+i*195,694)
  actor.scale=Vector2(3.2,3.2)
  actor.set_physics_process(false)
  stage.add_child(actor)
  actor.update_sprite()
  actor.gait_weight=1.0
  actor.gait_phase=TAU*float(i)/8.0
  for k in range(3):actor.ingame_sprite._process(0.016)
  var label:=Label.new();label.text=str(i)
  label.position=Vector2(90+i*195-30,714);label.size=Vector2(60,30)
  label.add_theme_color_override("font_color",Color.WHITE)
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  stage.add_child(label)
 await capture("/workspace/downloads/v2021_gait_strip.png")
 print("GAIT CHECK DONE")
 quit()
