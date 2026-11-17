extends WooWardrobeVisual
const CARDINAL=preload("res://assets/woo/mascot/bodies-cardinal.png")
const DIAGONAL=preload("res://assets/woo/mascot/bodies-diagonal.png")
const HAIR=preload("res://assets/woo/mascot/hair.png")
const HATS=preload("res://assets/woo/mascot/hats.png")
var motion_key:=""
var original_sprite: Sprite2D
var original_frames: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/original/frames.json")).characters
var original_direction:="front"
var uses_original:=false
const IDS=["woochi","yeonhwa","muyeong","hongryeon"]
func _ready() -> void:
 super._ready()
 original_sprite=Sprite2D.new();original_sprite.name="OriginalCharacter";original_sprite.centered=false;original_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;add_child(original_sprite)
 for key in ["sd_head","sd_left_arm","sd_right_arm","sd_left_foot","sd_right_foot"]:
  var node:=Polygon2D.new();node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;var material:=ShaderMaterial.new();material.shader=SHADER;node.material=material;add_child(node);pieces[key]=node
func patch(key: String,source: Rect2,offset: Vector2=Vector2.ZERO,angle: float=0,pivot: Vector2=Vector2.ZERO) -> void:
 var texture: Texture2D=CARDINAL if direction<4 else DIAGONAL
 var col: int=[0,2,1,3][direction] if direction<4 else [1,0,2,3][direction-4]
 var row: int=IDS.find(effective.character);var origin:=Vector2(col,row)*64
 var points:=PackedVector2Array();var uvs:=PackedVector2Array()
 for corner in [source.position,source.position+Vector2(source.size.x,0),source.end,source.position+Vector2(0,source.size.y)]:
  var p: Vector2=corner-Vector2(32,60);points.append((p-pivot).rotated(angle)+pivot+offset);uvs.append(origin+corner)
 var node: Polygon2D=pieces[key];node.texture=texture;node.polygon=points;node.uv=uvs;node.show();move_child(node,get_child_count()-1)
 var mat: ShaderMaterial=node.material;mat.set_shader_parameter("head_rect",Vector4(head_rect.position.x,head_rect.position.y,head_rect.size.x,head_rect.size.y));mat.set_shader_parameter("component",0);mat.set_shader_parameter("direction",direction);mat.set_shader_parameter("dye_enabled",effective.color!=C.base_appearance(effective.character).color);mat.set_shader_parameter("palette",1 if effective.character in ["yeonhwa","hongryeon"] else (2 if effective.character=="muyeong" else 0));mat.set_shader_parameter("dye",C.COLORS[effective.color])
 rendered_layers.append({"texture":texture,"points":points,"uv":uvs})
func rebuild() -> void:
 clear();effective=Art.effective(appearance);uses_baked=false
 uses_original=original_frames.has(effective.character) and appearance==C.base_appearance(effective.character)
 original_sprite.visible=uses_original
 if uses_original:
  actor.sprite.hide()
  original_direction=["front","back","left","right","right","left","back","back"][direction]
  var data: Dictionary=original_frames[effective.character]
  var frame: Dictionary=data[original_direction]
  original_sprite.texture=load(frame.path)
  original_sprite.offset=-Vector2(frame.foot[0],frame.foot[1])
  original_sprite.scale=Vector2.ONE*float(data.scale)
  return
 head_rect=Rect2(-14,-40,28,22)
 var walking: bool=actor.gait_weight>.15 or (actor.npc and actor.npc_walking)
 var phase: float=actor.npc_stride*.22 if actor.npc else actor.gait_phase
 var stride: float=sin(phase)*1.5 if walking else 0.0
 var bob:=Vector2(0,-absf(stride)*.22)
 var attack: float=sin(clampf(1-actor.action_left/maxf(actor.pose_duration,.01),0,1)*PI) if actor.action_left>0 else 0.0
 var arm_angle: float=attack*[-.8,1.1,-1.4,-.5,.8,.9][clampi(actor.action_pose,0,5)]
 if direction not in [1,6,7]:hair(true)
 patch("sd_left_foot",Rect2(0,56,32,8),Vector2(0,-maxf(0,stride)))
 patch("sd_right_foot",Rect2(32,56,32,8),Vector2(0,-maxf(0,-stride)))
 patch("body",Rect2(23,41,18,16),bob)
 patch("sd_left_arm",Rect2(0,41,23,15),bob,-arm_angle+stride*.08,Vector2(-9,-18))
 patch("sd_right_arm",Rect2(41,41,23,15),bob,arm_angle-stride*.08,Vector2(9,-18))
 if effective.outfit!="basic":
  var sheet: String=effective.outfit+"_"+pose_set;var meta:=Art.frame(sheet,pose_row,direction);var cell:=Art.cell(sheet,pose_row,direction);var region:=Art.rect(meta.region);var collar: Vector2=Art.vec(meta.collar);var foot: Vector2=Art.vec(meta.foot)
  var rect:=Rect2(Vector2(region.position.x,region.position.y+region.size.y*collar.y),Vector2(region.size.x,region.size.y*(foot.y-collar.y)))
  var points:=PackedVector2Array([Vector2(-17,-18),Vector2(17,-18),Vector2(17,0),Vector2(-17,0)])
  var tex:=Art.texture(sheet,direction);var uvs:=PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
  for i in range(uvs.size()):uvs[i]*=Vector2(tex.get_size())
  add_mesh("outfit",sheet,pose_row,points,uvs,0,-1 if effective.color==C.OUTFITS[effective.outfit].colors[0] else (3 if effective.outfit=="moon" else 2))
 patch("sd_head",Rect2(0,0,64,41),bob)
 head_rect.position+=bob
 if direction in [1,6,7]:hair(true)
 else:hair(false)
 hat();accessory()
func gear(key: String,texture: Texture2D,row: int,width: float,anchor: Vector2) -> void:
 var col: int=[0,1,2,3,3,2,2,3][direction]
 var node: Polygon2D=pieces[key]
 var factor: float=width/54.0
 node.texture=texture
 node.polygon=PackedVector2Array([Vector2(-32,-54),Vector2(32,-54),Vector2(32,10),Vector2(-32,10)])
 for i in range(4):node.polygon[i]=node.polygon[i]*factor+anchor
 var origin:=Vector2(col,row)*64
 node.uv=PackedVector2Array([origin,origin+Vector2(64,0),origin+Vector2(64,64),origin+Vector2(0,64)])
 node.material=null;node.show();move_child(node,get_child_count()-1)
 rendered_layers.append({"texture":texture,"points":node.polygon,"uv":node.uv})
func hair(back: bool) -> void:
 if back and direction not in [1,6,7]:return
 if not back and direction in [1,6,7]:return
 var rows: Dictionary={"black":0,"long":1,"tied":2,"silver":3,"short":4,"flower":5}
 gear("hair_back" if back else "hair_front",HAIR,rows.get(effective.hair,0),32,Vector2(0,-18))
func hat() -> void:
 if effective.hat=="none":return
 var rows: Dictionary={"gat":0,"bamboo":1,"hood":2,"crown":3,"fox":4,"gold":5}
 gear("hat",HATS,rows.get(effective.hat,0),44 if effective.hat in ["gat","bamboo"] else 32,Vector2(0,-26 if effective.hat!="fox" else -18))
func _process(delta: float) -> void:
 super._process(delta)
 # Limb poses are continuous and tied to actual distance, not a whole-sprite wobble.
 if visible:
  var key: String="%d:%d"%[int(actor.gait_phase*8/TAU),int(actor.action_left*20)]
  if key!=motion_key:motion_key=key;rebuild()
