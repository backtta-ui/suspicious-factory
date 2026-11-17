extends WooWardrobeVisual
## All saved combinations retain the approved character. Never return to the
## unrelated bald-body / low-resolution hair / oversized hat compositor.
var original_sprite: Sprite2D
var original_frames: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/original/frames.json")).characters
var original_direction:="front"
var uses_original:=true
const IDS=["woochi","yeonhwa","muyeong","hongryeon"]
func _ready() -> void:
 super._ready()
 original_sprite=Sprite2D.new();original_sprite.name="OriginalCharacter";original_sprite.centered=false;original_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;add_child(original_sprite)
func rebuild() -> void:
 clear();effective=Art.effective(appearance);uses_baked=false;uses_original=true
 actor.sprite.hide();original_sprite.show()
 original_direction=["front","back","left","right","right","left","back","back"][direction]
 var data: Dictionary=original_frames[effective.character]
 var frame: Dictionary=data[original_direction]
 original_sprite.texture=load(frame.path)
 original_sprite.offset=-Vector2(frame.foot[0],frame.foot[1])
 original_sprite.scale=Vector2.ONE*float(data.scale)
 var mat: ShaderMaterial=original_sprite.material
 if mat==null:
  mat=ShaderMaterial.new();mat.shader=preload("res://scripts/art/original_dye.gdshader");original_sprite.material=mat
 mat.set_shader_parameter("cloth_mask",load(str(frame.path).replace(".png","-dye.png")))
 mat.set_shader_parameter("dye_enabled",appearance.color!=C.base_appearance(effective.character).color)
 mat.set_shader_parameter("dye",C.COLORS[appearance.color])
 # Position and jump height belong to the shared parent; skin identity and size
 # are independent of action state, input timing, or any selected cosmetic.
 if effective.accessory!="none" and effective.accessory!=C.base_appearance(effective.character).accessory:
  accessory()
func accessory() -> void:
 var saved_direction:=direction
 direction=[0,1,2,3,3,2,1,1][direction]
 var anchor:=Vector2(7,-12)
 if direction==1:anchor.x=-7
 if direction in [2,3]:anchor.x=3 if direction==3 else -3
 if effective.accessory in ["scroll","sigil"]:anchor=Vector2(0,-15)
 equipment("accessory","accessories",Art.ACCESSORIES[effective.accessory],5,anchor,Vector2(.5,.5),0)
 pieces.accessory.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 if effective.accessory in ["scroll","sigil"] and direction==0:move_child(pieces.accessory,0)
 direction=saved_direction
