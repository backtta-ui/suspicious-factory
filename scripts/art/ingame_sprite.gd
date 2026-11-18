extends Node2D
## 인게임 2.5D 원화 캐릭터: 8방향(앞·뒤·옆 + 대각선) 스프라이트와
## 점프 포물선·착지 스쿼시·보행 흔들림·도술 시전 모션을 한 곳에서 연결한다.
## 방향은 rules.gd / actor.facing(0=동,1=남동,2=남,3=남서,4=서,5=북서,6=북,7=북동)을
## 그대로 따른다. 점프나 시전 중에도 facing을 바꾸지 않는다.
const MANIFEST_PATH="res://assets/woo/ingame/frames.json"
const SHADOW=Color(.01,.02,.05,.42)
## 8방향 → (원화 시트 방향, 좌우 반전). 남/남서/남동은 정면, 북/북서/북동은 뒷모습,
## 동/서는 측면이다. 대각선은 정면·뒷모습을 좌우 반전해 이동 벡터 쪽으로 기울인다.
const VIEW={0:"right",1:"front",2:"front",3:"front",4:"left",5:"back",6:"back",7:"back"}
const FLIP={0:false,1:true,2:false,3:false,4:false,5:false,6:false,7:true}
static var manifest: Dictionary={}
var actor: WooActor
var sprite: Sprite2D
var current_key:=""
var landing:=0.0
var previous_height:=0.0
var cast:=0.0
var breath:=0.0
var last_texture: Texture2D
var base_scale:=1.0
func _ready() -> void:
 sprite=Sprite2D.new();sprite.name="IngameArt";sprite.centered=true;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(sprite)
 if manifest.is_empty():load_manifest()
func load_manifest() -> void:
 if not FileAccess.file_exists(MANIFEST_PATH):return
 var raw=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
 if raw is Dictionary:manifest=raw
func data_for(id: String) -> Dictionary:
 var characters: Dictionary=manifest.get("characters",{})
 for key in characters:
  if key==id:return characters[key]
 return {}
func set_pose(facing: int,id: String) -> void:
 var data:=data_for(id)
 if data.is_empty():sprite.visible=false;return
 var view: String=VIEW.get(posmod(facing,8),"front")
 var directions: Dictionary=data.get("directions",{})
 var entry: Dictionary=directions.get(view,{})
 if entry.is_empty():sprite.visible=false;return
 var key: String="%s:%s" % [id,view]
 if key!=current_key:
  current_key=key
  var texture: Texture2D=load(String(entry.path))
  sprite.texture=texture;last_texture=texture
  var height: float=float(entry.size[1])
  var scale_value: float=float(entry.get("scale",data.get("scale",1.0)))
  sprite.scale=Vector2(scale_value,scale_value)
  sprite.offset=Vector2(0,-height/2.0)
  base_scale=scale_value
 sprite.flip_h=bool(FLIP.get(posmod(facing,8),false))
 sprite.modulate=actor.skin_tint if actor!=null else Color.WHITE
 sprite.visible=true
func _process(delta: float) -> void:
 if actor==null:return
 breath+=delta
 var id: String=String(actor.art_id)
 if id=="":id=String(actor.cosmetic.get("character","woochi"))
 set_pose(actor.facing,id)
 var height: float=actor.jump_height
 if previous_height>4.0 and height<=.01:landing=.24
 previous_height=height
 landing=maxf(0,landing-delta)
 cast=maxf(0,cast-delta)
 if actor.action_left>0:cast=maxf(cast,.001)
 var weight: float=clampf(actor.gait_weight,0,1)
 var bob: float=-absf(sin(actor.gait_phase))*1.7*weight
 var tilt: float=sin(actor.gait_phase)*.055*weight
 # 점프: 상승은 살짝 길게, 하강은 기본, 착지는 눌렸다가 돌아온다.
 var stretch:=1.0
 var width:=1.0
 if height>2.0:stretch=1.06 if actor.jump_velocity>0 else 1.01
 if landing>0.0:
  var t:=landing/.24
  stretch=1.0-.16*sin(t*PI);width=1.0+.16*sin(t*PI)
 var cast_amount: float=clampf(cast/.3,0,0.999)
 if cast>0.0:
  stretch*=1.04;width*=1.03;tilt-=0.10*cast_amount
 var idle: float=1.0+.006*sin(breath*2.1)*(1.0-weight)
 sprite.position=Vector2(0,bob-height)
 sprite.rotation=tilt
 # 배율은 텍스처 기준값을 유지한 채 스쿼시·호흡만 곱한다.
 sprite.scale=Vector2(base_scale*width*idle,base_scale*stretch*idle)
 queue_redraw()
## 발밑 그림자: 점프 높이에 따라 작아지고 옅어진다.
func _draw() -> void:
 var height: float=maxf(0.0,actor.jump_height) if actor!=null else 0.0
 var scale_down: float=clampf(1.0-height/110.0,.42,1.0)
 var alpha: float=0.34*scale_down+0.08
 draw_set_transform(Vector2(0,0),0,Vector2(scale_down,scale_down*.42))
 draw_circle(Vector2.ZERO,12.0,Color(SHADOW.r,SHADOW.g,SHADOW.b,alpha))
 draw_circle(Vector2(1,0),7.0,Color(SHADOW.r,SHADOW.g,SHADOW.b,alpha*.45))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if cast>0.0:
  var t:=1.0-cast/.3
  for i in range(3):
   var radius:=10.0+t*26.0+i*4.0
   draw_arc(Vector2(0,-1),radius,0,TAU,28,Color(.72,.86,1,.42*(1.0-t)*(1.0-i*.25)),2.0,true)
