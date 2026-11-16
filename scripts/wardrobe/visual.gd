class_name WooWardrobeVisual
extends Node2D
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/art.gd")
const Fit=preload("res://scripts/wardrobe/compatibility.gd")
const DYE=preload("res://scripts/wardrobe/dye.gdshader")
const MASK=preload("res://scripts/wardrobe/hair_mask.gdshader")
var actor: WooActor
var pieces: Dictionary={}
var cache:=""
var appearance: Dictionary=C.DEFAULT.duplicate()
func custom_body() -> bool:return appearance.character!="woochi" or appearance.outfit!="basic" or appearance.color!="navy"
func custom_head() -> bool:return appearance.character!="woochi" or appearance.hair!="black" or appearance.hat!="gat"
func piece(key: String,texture: Texture2D,source: Rect2,rect: Rect2,behind: bool=false,pivot: Vector2=Vector2.ZERO) -> Sprite2D:
 var sprite:=Sprite2D.new();sprite.texture=texture;sprite.region_enabled=true;sprite.centered=false;sprite.region_rect=source
 sprite.scale=rect.size/source.size;sprite.position=pivot;sprite.offset=(rect.position-pivot)/sprite.scale
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if behind:actor.appearance_back.add_child(sprite)
 else:add_child(sprite)
 pieces[key]=sprite;return sprite
func add_piece(key: String,cell: int,rect: Rect2,dye: bool=false,part: Rect2=Rect2(0,0,1,1),pivot: Vector2=Vector2.ZERO,behind: bool=false) -> void:
 var r:=Art.region(cell)
 var sprite:=piece(key,Art.SHEET,Rect2(r.position+r.size*part.position,r.size*part.size),rect,behind,pivot)
 if dye:
  var mat:=ShaderMaterial.new();mat.shader=DYE;mat.set_shader_parameter("enabled",appearance.color!=C.OUTFITS[appearance.outfit].colors[0] or appearance.outfit=="basic");mat.set_shader_parameter("dye",C.COLORS[appearance.color]);sprite.material=mat
func coverage(sprite: Sprite2D,rect: Rect2,front: bool,headwear: bool=false) -> void:
 var source: Rect2=sprite.region_rect;var size:=Vector2(sprite.texture.get_size())
 var hat: Dictionary=Fit.HATS[appearance.hat]
 var mat:=ShaderMaterial.new();mat.shader=MASK
 mat.set_shader_parameter("source_uv",Vector4(source.position.x/size.x,source.position.y/size.y,source.size.x/size.x,source.size.y/size.y))
 mat.set_shader_parameter("target_rect",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
 mat.set_shader_parameter("seat",hat.seat+Fit.HEADS[appearance.character].hat.y)
 mat.set_shader_parameter("hood",hat.mode=="hood");mat.set_shader_parameter("front",front);mat.set_shader_parameter("headwear",headwear)
 sprite.material=mat
func hair_piece(key: String,cell: int,behind: bool) -> void:
 var rect:=Fit.hair_rect(appearance.character)
 var sprite:=piece(key,Art.HEAD_PARTS,Art.head_region(cell),rect,behind)
 coverage(sprite,rect,not behind)
func rebuild() -> void:
 for p in pieces.values():p.get_parent().remove_child(p);p.queue_free()
 pieces.clear()
 if custom_head():hair_piece("hair_back",4+Fit.HAIR_INDEX[appearance.hair],true)
 if appearance.accessory!="none" and Fit.accessory_behind(appearance.accessory):
  add_piece("accessory",C.ACCESSORIES[appearance.accessory].cell,Fit.accessory_rect(appearance.accessory),false,Rect2(0,0,1,1),Vector2.ZERO,true)
 if custom_body():
  var cell: int=C.OUTFITS[appearance.outfit].cell
  var shift: Vector2=Fit.OUTFITS[appearance.outfit]
  add_piece("tail",cell,Rect2(Vector2(-13,-12)+shift,Vector2(26,10)),true,Rect2(0,.62,1,.38),Vector2(0,-12))
  add_piece("torso",cell,Rect2(Vector2(-7,-25)+shift,Vector2(14,19)),true,Rect2(.27,0,.46,.64))
  add_piece("left",cell,Rect2(Vector2(-16,-25)+shift,Vector2(9,18)),true,Rect2(0,0,.28,.7),Vector2(-8,-23)+shift)
  add_piece("right",cell,Rect2(Vector2(7,-25)+shift,Vector2(9,18)),true,Rect2(.72,0,.28,.7),Vector2(8,-23)+shift)
 if custom_head():
  piece("face",Art.HEAD_PARTS,Art.head_region(C.CHARACTERS[appearance.character].cell),Fit.HEADS[appearance.character].face)
  hair_piece("hair_front",10+Fit.HAIR_INDEX[appearance.hair],false)
  if appearance.hat!="none":
   add_piece("hat",C.HATS[appearance.hat].cell,Fit.hat_rect(appearance.character,appearance.hat))
   if appearance.hat!="fox":coverage(pieces.hat,Fit.hat_rect(appearance.character,appearance.hat),false,true)
 if appearance.accessory!="none" and not Fit.accessory_behind(appearance.accessory):add_piece("accessory",C.ACCESSORIES[appearance.accessory].cell,Fit.accessory_rect(appearance.accessory),false,Rect2(0,0,1,1),Vector2(7,-12))
func _process(_delta: float) -> void:
 if not is_instance_valid(actor):return
 visible=not actor.npc and not actor.jar and actor.appearance_form=="human"
 actor.appearance_back.visible=visible
 if not visible:return
 var normalized:=C.normalize(actor.cosmetic)
 var key:=JSON.stringify(normalized)
 if key!=cache:appearance=normalized;cache=key;rebuild()
 position=Vector2(0,-actor.jump_height);modulate=actor.sprite.modulate;rotation=actor.sprite.rotation
 actor.appearance_back.position=position;actor.appearance_back.modulate=modulate;actor.appearance_back.rotation=rotation
 var phase:=clampf(1-actor.action_left/maxf(actor.pose_duration,.001),0,1)
 var stride:=sin(actor.gait_phase)*actor.gait_weight
 var pulse:=sin(phase*PI) if actor.action_left>0 else 0.0
 if pieces.has("left"):
  pieces.left.rotation=stride*.12-pulse*(.55 if actor.action_pose!=1 else -.6)
  pieces.right.rotation=-stride*.12+pulse*(1.0 if actor.action_pose in [0,3,5] else -.8)
  var spread:=.2 if actor.jump_height>0 else 0.0
  pieces.left.rotation-=spread;pieces.right.rotation+=spread
  pieces.tail.rotation=stride*.025
 var back:=actor.facing in [5,6,7]
 var mirrored:=actor.facing in [3,4,5]
 for key_part in ["face","hair_back","hair_front","hat"]:
  if pieces.has(key_part):pieces[key_part].flip_h=mirrored
 if pieces.has("face"):pieces.face.visible=not back
 if pieces.has("hair_front"):pieces.hair_front.visible=not back
 if pieces.has("hat"):
  pieces.hat.visible=not (back and appearance.hat=="fox")
  if pieces.hat.material:pieces.hat.material.set_shader_parameter("rear",back)
 if pieces.has("accessory"):pieces.accessory.rotation=sin(actor.animation_time*.8)*.04+stride*.08
