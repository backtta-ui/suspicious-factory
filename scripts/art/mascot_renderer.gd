extends WooWardrobeVisual
## All saved combinations retain the approved character. Never return to the
## unrelated bald-body / low-resolution hair / oversized hat compositor.
var original_sprite: Sprite2D
var original_frames: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/original/frames.json")).characters
var original_direction:="front"
var uses_original:=true
var locomotion: Polygon2D
var current_frame: Dictionary={}
var motion_key:=""
const IDS=["woochi","yeonhwa","muyeong","hongryeon"]
func _ready() -> void:
 super._ready()
 original_sprite=Sprite2D.new();original_sprite.name="OriginalCharacter";original_sprite.centered=false;original_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;add_child(original_sprite)
 locomotion=preload("res://scripts/art/locomotion_rig.gd").new();locomotion.name="OriginalLocomotion";add_child(locomotion)
func rebuild() -> void:
 clear();effective=Art.effective(appearance);uses_baked=false;uses_original=true
 actor.sprite.hide();original_sprite.show()
 original_direction=["front","back","left","right","front_right","front_left","back_left","back_right"][direction]
 var data: Dictionary=original_frames[effective.character]
 var frame: Dictionary=data[original_direction];current_frame=frame
 original_sprite.texture=load(frame.path)
 original_sprite.offset=-Vector2(frame.foot[0],frame.foot[1])
 original_sprite.scale=Vector2.ONE*float(frame.get("scale",data.scale))
 locomotion.configure(original_sprite.texture,frame,float(frame.get("scale",data.scale)))
 var mat: ShaderMaterial=original_sprite.material
 if mat==null:
  mat=ShaderMaterial.new();mat.shader=preload("res://scripts/art/original_dye.gdshader");original_sprite.material=mat
 mat.set_shader_parameter("cloth_mask",load(str(frame.path).replace(".png","-dye.png")))
 mat.set_shader_parameter("dye_enabled",appearance.get("color_override",false))
 mat.set_shader_parameter("dye",C.COLORS[appearance.color])
 locomotion.material=mat
 # Position and jump height belong to the shared parent; skin identity and size
 # are independent of action state, input timing, or any selected cosmetic.
 if effective.accessory!="none" and effective.accessory!=C.base_appearance(effective.character).accessory:
  accessory()
func accessory() -> void:
 var saved_direction:=direction
 var anchor: Vector2=preload("res://scripts/art/attachments.gd").rest(effective.character,"back" if effective.accessory in ["scroll","sigil"] else "waist",saved_direction)
 equipment("accessory","accessories",Art.ACCESSORIES[effective.accessory],5,anchor,Vector2(.5,.5),0)
 pieces.accessory.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 if effective.accessory in ["scroll","sigil"] and direction==0:move_child(pieces.accessory,0)
 direction=saved_direction

func _process(delta: float) -> void:
 super._process(delta)
 if not visible:return
 locomotion.animate(actor.gait_phase,actor.gait_weight,actor.running or actor.velocity.length()>110,actor.facing)
 locomotion.visible=actor.gait_weight>.01 and actor.jump_height<=0 and actor.action_left<=0
 original_sprite.visible=not locomotion.visible
 if pieces.accessory.visible:
  var point: Vector2=preload("res://scripts/art/attachments.gd").rest(effective.character,"back" if effective.accessory in ["scroll","sigil"] else "waist",direction)
  pieces.accessory.position=locomotion.deform(point)-point if locomotion.visible else Vector2.ZERO
