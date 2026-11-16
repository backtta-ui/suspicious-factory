class_name WooWardrobeVisual
extends Node2D
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/art.gd")
const DYE=preload("res://scripts/wardrobe/dye.gdshader")
var actor: WooActor
var pieces: Dictionary={}
var cache:=""
var appearance: Dictionary=C.DEFAULT.duplicate()
func custom_body() -> bool:return appearance.character!="woochi" or appearance.outfit!="basic" or appearance.color!="navy"
func custom_head() -> bool:return appearance.character!="woochi" or appearance.hair!="black" or appearance.hat!="gat"
func add_piece(key: String,cell: int,rect: Rect2,dye: bool=false,part: Rect2=Rect2(0,0,1,1)) -> void:
 var sprite:=Sprite2D.new();sprite.texture=Art.SHEET;sprite.region_enabled=true;sprite.centered=false
 var r:=Art.region(cell);sprite.region_rect=Rect2(r.position+r.size*part.position,r.size*part.size)
 sprite.position=rect.position;sprite.scale=rect.size/sprite.region_rect.size;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if dye:
  var mat:=ShaderMaterial.new();mat.shader=DYE;mat.set_shader_parameter("enabled",appearance.color!=C.OUTFITS[appearance.outfit].colors[0] or appearance.outfit=="basic");mat.set_shader_parameter("dye",C.COLORS[appearance.color]);sprite.material=mat
 add_child(sprite);pieces[key]=sprite
func rebuild() -> void:
 for p in pieces.values():p.queue_free()
 pieces.clear()
 if custom_body():
  var cell: int=C.OUTFITS[appearance.outfit].cell
  add_piece("tail",cell,Rect2(-13,-12,26,10),true,Rect2(0,.62,1,.38))
  add_piece("torso",cell,Rect2(-7,-20,14,14),true,Rect2(.27,0,.46,.64))
  add_piece("left",cell,Rect2(-16,-20,9,16),true,Rect2(0,0,.28,.7))
  add_piece("right",cell,Rect2(7,-20,9,16),true,Rect2(.72,0,.28,.7))
 if custom_head():
  add_piece("hair",C.HAIRS[appearance.hair].cell,Rect2(-12,-39,24,27))
  add_piece("face",C.CHARACTERS[appearance.character].cell,Rect2(-8,-33,16,18),false,Rect2(.22,.32,.58,.62))
  # Hair overlays have transparent face openings; shrink under a hat to avoid protrusion.
  add_piece("fringe",C.HAIRS[appearance.hair].cell,Rect2(-11,-40,22,10) if appearance.hat=="none" else Rect2(-9,-38,18,8),false,Rect2(0,0,1,.42))
  if appearance.hat!="none":
   var hats: Dictionary={"gat":Rect2(-20,-44,40,25),"bamboo":Rect2(-20,-44,40,25),"hood":Rect2(-15,-42,30,30),"crown":Rect2(-17,-43,34,20),"fox":Rect2(-13,-42,26,20),"gold":Rect2(-18,-45,36,24)}
   add_piece("hat",C.HATS[appearance.hat].cell,hats[appearance.hat])
 if appearance.accessory!="none":add_piece("accessory",C.ACCESSORIES[appearance.accessory].cell,Rect2(5,-12,8,11))
func _process(_delta: float) -> void:
 if not is_instance_valid(actor):return
 visible=not actor.npc and not actor.jar and actor.appearance_form=="human"
 if not visible:return
 var normalized:=C.normalize(actor.cosmetic)
 var key:=JSON.stringify(normalized)
 if key!=cache:appearance=normalized;cache=key;rebuild()
 position=Vector2(0,-actor.jump_height);modulate=actor.sprite.modulate;rotation=actor.sprite.rotation
 var phase:=clampf(1-actor.action_left/maxf(actor.pose_duration,.001),0,1)
 var stride:=sin(actor.gait_phase)*actor.gait_weight
 var pulse:=sin(phase*PI) if actor.action_left>0 else 0.0
 if pieces.has("left"):
  pieces.left.rotation=stride*.05-pulse*(.55 if actor.action_pose!=1 else -.6)
  pieces.right.rotation=-stride*.05+pulse*(1.0 if actor.action_pose in [0,3,5] else -.8)
  pieces.tail.rotation=stride*.025;pieces.tail.position.y=-12+absf(stride)*.35
 var back:=actor.facing in [5,6,7]
 if pieces.has("face"):pieces.face.visible=not back;pieces.face.flip_h=actor.facing in [3,4,5]
 if pieces.has("accessory"):pieces.accessory.rotation=sin(actor.animation_time*.8)*.09+stride*.12
 queue_redraw()
func _draw() -> void:
 if custom_head() and actor.facing in [5,6,7]:
  var c:=Color("c8c7d5") if appearance.hair=="silver" or appearance.character=="muyeong" else Color("342b35")
  draw_circle(Vector2(0,-29),9,c)
