class_name WooWardrobeVisual
extends Node2D
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/directional_art.gd")
const Direction=preload("res://scripts/wardrobe/direction.gd")
const SHADER=preload("res://scripts/wardrobe/directional.gdshader")
var actor: WooActor
var pieces: Dictionary={}
var appearance: Dictionary=C.DEFAULT.duplicate()
var effective: Dictionary=C.DEFAULT.duplicate()
var cache:=""
var direction:=0
var pose_set:="core"
var pose_row:=0
var pose_override:=""
var row_override:=-1
var force_modular:=false
var head_rect:=Rect2()
var uses_baked:=false
var rendered_layers: Array=[]
func custom_body() -> bool:return true
func custom_head() -> bool:return true
func _ready() -> void:
 for name in ["body","outfit","hair_back","hair_front","hat","accessory"]:
  var node:=Polygon2D.new();node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  var material:=ShaderMaterial.new();material.shader=SHADER;node.material=material;add_child(node);pieces[name]=node
func choose_pose() -> void:
 pose_set="core";pose_row=0
 if row_override>=0:pose_set=pose_override;pose_row=row_override;return
 if actor.hurt_left>0 or actor.defeated or actor.landing_left>0:pose_set="actions";pose_row=5
 elif actor.action_left>0:
  var phase:=clampf(1-actor.action_left/maxf(actor.pose_duration,.001),0,1)
  if phase>.12 and phase<.9:pose_set="actions";pose_row=clampi(actor.action_pose,0,4) if actor.action_pose!=5 else 4
 elif actor.jump_height>0 or actor.jump_preparation>0:pose_row=3
 elif actor.gait_weight>.15:pose_row=[1,0,2,0][posmod(int(actor.gait_phase/(TAU/4)),4)]
func clear() -> void:
 for node in pieces.values():node.hide()
 rendered_layers.clear()
func add_mesh(key: String,sheet: String,row: int,points: PackedVector2Array,uv: PackedVector2Array,component: int=0,palette: int=-1) -> void:
 var node: Polygon2D=pieces[key];node.texture=Art.texture(sheet);node.polygon=points;node.uv=uv;node.show();move_child(node,get_child_count()-1)
 var mat: ShaderMaterial=node.material;mat.set_shader_parameter("head_rect",Vector4(head_rect.position.x,head_rect.position.y,head_rect.size.x,head_rect.size.y));mat.set_shader_parameter("direction",direction);mat.set_shader_parameter("component",component)
 mat.set_shader_parameter("hat_seat",head_rect.position.y+head_rect.size.y*.19 if effective.hat not in ["none","fox"] else -999.0);mat.set_shader_parameter("hood",effective.hat!="fox")
 mat.set_shader_parameter("dye_enabled",palette>=0);mat.set_shader_parameter("palette",maxi(0,palette));mat.set_shader_parameter("dye",C.COLORS[effective.color])
 rendered_layers.append({"texture":node.texture,"points":points,"uv":uv})
func raw_mesh(key: String,sheet: String,row: int,foot: Vector2,scale_value: Vector2,offset: Vector2=Vector2.ZERO,component: int=0,palette: int=-1,head_only: bool=false) -> void:
 var meta:=Art.frame(sheet,row,direction);var size:=Art.cell(sheet,row,direction);var points:=PackedVector2Array();var uvs:=PackedVector2Array()
 var raw_hull: Array=meta.hull
 if head_only:
  var r:=Art.rect(meta.head);raw_hull=[[r.position.x,r.position.y],[r.end.x,r.position.y],[r.end.x,r.end.y],[r.position.x,r.end.y]]
 for value in raw_hull:
  var p:=Art.vec(value);points.append((p-foot)*size*scale_value+offset);uvs.append((Art.rect(meta.region).position+p*Art.rect(meta.region).size)*Vector2(Art.texture(sheet).get_size()))
 add_mesh(key,sheet,row,points,uvs,component,palette)
func equipment(key: String,sheet: String,row: int,width: float,anchor: Vector2,pivot: Vector2,component: int) -> void:
 var meta:=Art.frame(sheet,row,direction);var size:=Art.cell(sheet,row,direction);var box:=Art.rect(meta.box);var factor:=width/(box.size.x*size.x)
 var scale_value:=Vector2.ONE*factor
 if key=="hair_back" and effective.hair in ["long","silver","flower","tied"]:scale_value.y*=1.25
 raw_mesh(key,sheet,row,pivot,scale_value,anchor,component)
func hair(back: bool) -> void:
 var id: String=effective.hair;var key: String="hair_back" if back else "hair_front"
 var width:=head_rect.size.x*(1.35 if id in ["black","short"] else 1.45)
 equipment(key,key,Art.HAIRS[id],width,head_rect.position+head_rect.size*Vector2(.5,.35),Vector2(.5,.35),2 if back else 1)
func hat() -> void:
 if effective.hat=="none":return
 var id: String=effective.hat;var row: int=Art.HATS[id];var meta:=Art.frame("hats",row,direction);var box:=Art.rect(meta.box);var size:=Art.cell("hats",row,direction)
 var widths: Dictionary={"gat":2.05,"bamboo":2.0,"hood":1.4,"crown":1.65,"fox":1.4,"gold":1.8}
 var factor: float=head_rect.size.x*widths[id]/(box.size.x*size.x)
 var pivot:=Vector2(box.get_center().x,box.position.y+box.size.y*(.46 if id in ["gat","bamboo"] else .43))
 var anchor:=head_rect.position+head_rect.size*Vector2(.5,.22)
 var scale_value:=Vector2.ONE*factor
 scale_value.y=minf(scale_value.y,12.0/maxf(1,(pivot.y-box.position.y)*size.y))
 if id=="fox":pivot=box.get_center();anchor=head_rect.get_center();scale_value=Vector2.ONE*head_rect.size.y*.95/(box.size.y*size.y)
 raw_mesh("hat","hats",row,pivot,scale_value,anchor,3)
func accessory() -> void:
 if effective.accessory=="none":return
 var anchor:=Vector2(6,-12)
 if direction==1:anchor.x=-6
 if direction in [2,3]:anchor.x=0
 if effective.accessory in ["scroll","sigil"]:anchor=Vector2(0,-17)
 equipment("accessory","accessories",Art.ACCESSORIES[effective.accessory],8,anchor,Vector2(.5,.5),0)
func rebuild() -> void:
 clear();effective=Art.effective(appearance)
 var sheet: String=effective.character+"_"+pose_set;var meta:=Art.frame(sheet,pose_row,direction);var size:=Art.cell(sheet,pose_row,direction)
 # Offline source frames have different canvas densities. Normalize anatomy to
 # the native idle head, then bake native complete frames at one runtime scale.
 var idle:=Art.frame(effective.character+"_core",0,direction)
 var idle_cell:=Art.cell(effective.character+"_core",0,direction)
 var factor:=46.0/Art.idle_height(effective.character,direction)
 factor*=float(idle.head[2])*idle_cell.x/maxf(1,float(meta.head[2])*size.x)
 var foot:=Art.vec(meta.foot)
 head_rect=Art.rect(meta.head);head_rect.position=(head_rect.position-foot)*size*factor;head_rect.size*=size*factor
 var baked: String="base_"+effective.character+"_"+pose_set
 uses_baked=not force_modular and effective==C.base_appearance(effective.character) and Art.texture(baked)!=null
 if uses_baked:
  var texture:=Art.texture(baked);var rows:=4 if pose_set=="core" else 6;var cell:=Vector2(texture.get_size())/Vector2(4,rows)
  var p:=PackedVector2Array([Vector2(-48,-84),Vector2(48,-84),Vector2(48,12),Vector2(-48,12)])
  var uv:=PackedVector2Array([Vector2(direction,pose_row)*cell,Vector2(direction+1,pose_row)*cell,Vector2(direction+1,pose_row+1)*cell,Vector2(direction,pose_row+1)*cell])
  add_mesh("body",baked,pose_row,p,uv);return
 var custom: bool=effective.outfit!="basic"
 var head_offset:=Vector2.ZERO;var garment_sheet: String=effective.outfit+"_"+pose_set;var garment_factor:=Vector2.ONE;var garment_foot:=Vector2.ZERO
 if custom:
  var gear:=Art.frame(garment_sheet,pose_row,direction);var gear_size:=Art.cell(garment_sheet,pose_row,direction);garment_foot=Art.vec(gear.foot)
  var native_neck:=head_rect.position+head_rect.size*Vector2(.5,1)
  var collar:=Art.vec(gear.collar);var gfactor: float=absf(native_neck.y)/maxf(1,(garment_foot.y-collar.y)*gear_size.y)
  garment_factor=Vector2(gfactor*.96 if effective.character in ["yeonhwa","hongryeon"] else gfactor,gfactor)
  var neck: Vector2=(collar-garment_foot)*gear_size*garment_factor
  head_offset=neck-native_neck;head_rect.position+=head_offset
 if direction!=1:hair(true)
 if effective.accessory in ["scroll","sigil"] and direction==0:accessory()
 raw_mesh("body",sheet,pose_row,foot,Vector2.ONE*factor,head_offset,0,-1 if custom or effective.color==C.base_appearance(effective.character).color else (1 if effective.character=="hongryeon" else (2 if effective.character=="muyeong" else 0)),custom)
 if custom:raw_mesh("outfit",garment_sheet,pose_row,garment_foot,garment_factor,Vector2.ZERO,0,-1 if effective.color==C.OUTFITS[effective.outfit].colors[0] else (3 if effective.outfit=="moon" else 2))
 if direction==1:hair(true)
 else:hair(false)
 hat()
 if effective.accessory!="none" and not (effective.accessory in ["scroll","sigil"] and direction==0):accessory()
func _process(_delta: float) -> void:
 if not is_instance_valid(actor):return
 visible=not actor.npc and not actor.jar and actor.appearance_form=="human"
 actor.appearance_back.visible=false
 if not visible:return
 position=Vector2(0,-actor.jump_height);modulate=actor.sprite.modulate;rotation=actor.sprite.rotation
 appearance=C.normalize(actor.cosmetic);direction=Direction.resolve(actor.facing,direction);choose_pose()
 var key:=JSON.stringify(appearance)+str(direction)+pose_set+str(pose_row)+str(force_modular)
 if key!=cache:cache=key;rebuild()
