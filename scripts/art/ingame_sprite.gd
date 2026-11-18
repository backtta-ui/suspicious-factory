extends Node2D
## 인게임 2.5D 원화 캐릭터: 8방향(앞·뒤·옆 + 대각선) 스프라이트와
## 점프 포물선·착지 스쿼시·보행 흔들림·도술 시전 모션을 한 곳에서 연결한다.
## 방향은 rules.gd / actor.facing(0=동,1=남동,2=남,3=남서,4=서,5=북서,6=북,7=북동)을
## 그대로 따른다. 점프나 시전 중에도 facing을 바꾸지 않는다.
##
## 정지 원화 한 장이 미끄러지는 느낌을 없애기 위해, 걸음마다
## (1) 2박자 수직 바운스, (2) 닿는 순간의 스쿼시-스트레치, (3) 진행 방향 기울기,
## (4) 발밑 흙먼지, (5) 달릴 때의 바람 자국, (6) 방향 전환 탄성을 함께 그린다.
const MANIFEST_PATH="res://assets/woo/ingame/frames.json"
const SHADOW=Color(.01,.02,.05,.42)
## 2.5D 걷기 프레임(walk1·idle·walk2)을 쓰면서 2.0.21에 보행 바운스·기울기·
## 스쿼시를 발이 땅에 붙는 수준으로 낮췄다. 예전 정지 원화 시절 값(5.5/9.0,
## 1.07↔0.92)은 프레임이 바뀔 때 젤리처럼 통통 튀어 보였다.
const WALK_BOUNCE=1.2
const RUN_BOUNCE=2.2
const WALK_TILT=.03
const RUN_TILT=.07
## 8방향 → (원화 시트 방향, 좌우 반전). 남/남서/남동은 정면, 북/북서/북동은 뒷모습,
## 동/서는 측면이다. 대각선은 정면·뒷모습을 좌우 반전해 이동 벡터 쪽으로 기울인다.
## 걷기 4박자: 왼발 앞 → 정지 → 오른발 앞 → 정지. 방향별 walk1·walk2 원화를 쓴다.
const GAIT_CYCLE=["walk1","idle","walk2","idle"]
const VIEW={0:"right",1:"front",2:"front",3:"front",4:"left",5:"back",6:"back",7:"back"}
const FLIP={0:false,1:true,2:false,3:false,4:false,5:false,6:false,7:true}
## 이동 방향별 상체 기울기 부호(오른쪽 +, 왼쪽 -). 정면/뒷면은 기울이지 않는다.
const LEAN={0:1.0,1:0.55,2:0.0,3:-0.55,4:-1.0,5:-0.55,6:0.0,7:0.55}
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
## 발걸음 흙먼지와 질주 바람 자국(가벼운 배열 파티클).
var dust: Array=[]
var wind: Array=[]
var step_phase:=0.0
var previous_facing:=-1
var turn:=0.0
var textures: Dictionary={}
var pose_name:="idle"
var current_pose:=""
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
## 방향별 정지/걷기 프레임 항목을 고른다(걷기 원화가 없으면 정지로 돌아간다).
func frame_entry(data: Dictionary,entry: Dictionary,pose: String) -> Dictionary:
 if pose=="idle":return entry
 var walk: Array=entry.get("walk",[])
 if pose=="walk1" and walk.size()>0:return walk[0]
 if pose=="walk2" and walk.size()>1:return walk[1]
 return entry
func set_pose(facing: int,id: String,pose: String="idle") -> void:
 var data:=data_for(id)
 if data.is_empty():sprite.visible=false;return
 var view: String=VIEW.get(posmod(facing,8),"front")
 var directions: Dictionary=data.get("directions",{})
 var entry: Dictionary=directions.get(view,{})
 if entry.is_empty():sprite.visible=false;return
 var frame: Dictionary=frame_entry(data,entry,pose)
 # current_key는 "id:view" 형식을 유지한다(테스트·다른 코드가 방향 판별에 쓴다).
 var key: String="%s:%s" % [id,view]
 var cache_key: String="%s:%s" % [key,pose]
 if cache_key!=current_pose:
  current_pose=cache_key;current_key=key
  var texture: Texture2D=textures.get(cache_key)
  if texture==null:
   texture=load(String(frame.path))
   textures[cache_key]=texture
  sprite.texture=texture;last_texture=texture
  var height: float=float(frame.size[1])
  var scale_value: float=float(frame.get("scale",data.get("scale",1.0)))
  sprite.scale=Vector2(scale_value,scale_value)
  sprite.offset=Vector2(0,-height/2.0)
  base_scale=scale_value
 pose_name=pose
 sprite.flip_h=bool(FLIP.get(posmod(facing,8),false))
 sprite.modulate=actor.skin_tint if actor!=null else Color.WHITE
 sprite.visible=true

## 발이 땅에 닿는 순간마다 발밑 먼지를 뿌린다(걷기 1~2개, 달리기 3~4개).
func _spawn_dust(running: bool) -> void:
 var count:=3 if running else 1
 var lean:=float(LEAN.get(posmod(actor.facing,8),0.0))
 var back:=Vector2(-lean,0.0)
 for i in range(count):
  dust.append({
   "p":Vector2(randf_range(-6.0,6.0),0.0),
   "v":Vector2(back.x*randf_range(10.0,26.0)+randf_range(-8.0,8.0),randf_range(-14.0,-4.0)),
   "age":0.0,
   "life":randf_range(.32,.5) if running else randf_range(.26,.4),
   "size":randf_range(4.5,7.5) if running else randf_range(3.0,5.2)})
## 달릴 때 등 뒤로 바람 자국을 남긴다.
func _spawn_wind() -> void:
 var lean:=float(LEAN.get(posmod(actor.facing,8),0.0))
 wind.append({"p":Vector2(-lean*randf_range(8.0,20.0),randf_range(-34.0,-14.0)),"v":Vector2(-lean*randf_range(120.0,190.0),randf_range(-6.0,6.0)),"age":0.0,"life":randf_range(.18,.3),"len":randf_range(12.0,22.0)})

func _process(delta: float) -> void:
 if actor==null:return
 breath+=delta
 var id: String=String(actor.art_id)
 if id=="":id=String(actor.cosmetic.get("character","woochi"))
 var height: float=actor.jump_height
 # 걷기·달리기: 이동 거리로 4박자 사이클(왼발·정지·오른발·정지)을 돌린다.
 # 점프 중에는 다리 그림이 바뀌지 않도록 정지 포즈를 유지한다.
 var pose: String="idle"
 var below: float=actor.gait_weight
 if below>=.1 and height<=2.0:
  # gait_phase는 22px마다 PI씩 오른다 → 박자마다 한 프레임.
  var index: int=posmod(int(floor(actor.gait_phase/PI)),GAIT_CYCLE.size())
  pose=String(GAIT_CYCLE[index])
 set_pose(actor.facing,id,pose)
 var height_moved: bool=absf(height-previous_height)>0.01
 if previous_height>4.0 and height<=.01:landing=.24
 previous_height=height
 landing=maxf(0,landing-delta)
 cast=maxf(0,cast-delta)
 if actor.action_left>0:cast=maxf(cast,.001)
 var weight: float=clampf(actor.gait_weight,0,1)
 var running: bool=bool(actor.running) and weight>.35
 var phase: float=actor.gait_phase
 var swing: float=sin(phase)
 var bounce: float=(RUN_BOUNCE if running else WALK_BOUNCE)*weight
 # 1) 2박자 수직 바운스: 딛는 순간 바닥, 뜨는 순간 위로.
 var bob: float=-absf(swing)*bounce
 # 2) 닿는 순간(cos=±1)은 눌리고, 뜨는 순간(cos=0)은 길게 편다.
 var contact: float=absf(cos(phase))*weight
 var breathe: float=1.0+0.015*sin(breath*2.1)*(1.0-weight)
 var stretch: float=float(lerpf(1.015,0.985,contact))
 var width: float=float(lerpf(0.99,1.015,contact))
 # 3) 진행 방향 기울기(달리면 더 크게).
 var lean: float=float(LEAN.get(posmod(actor.facing,8),0.0))
 var tilt: float=lean*bob*0.012+lean*(RUN_TILT if running else WALK_TILT)*weight+swing*0.02*weight
 # 4) 발걸음마다 흙먼지·바람 자국. phase가 PI를 넘길 때가 딛는 순간이다.
 if weight>.45 and height<=2.0:
  var step: float=fmod(phase,PI)
  if step<step_phase and previous_facing>=0:
   _spawn_dust(running)
   if running:_spawn_wind()
  step_phase=step
 else:
  step_phase=fmod(phase,PI)
 # 6) 방향 전환 탄성: 뻣뻣하게 돌아서지 않고 0.1초 눌렸다 펴진다.
 if previous_facing>=0 and actor.facing!=previous_facing:turn=.1
 previous_facing=actor.facing
 if turn>0.0:
  turn=maxf(0.0,turn-delta)
  var t: float=turn/.1
  width*=1.0+0.10*sin(t*PI)
  stretch*=1.0-0.07*sin(t*PI)
  tilt+=float(LEAN.get(posmod(actor.facing,8),0.0))*0.05*sin(t*PI)
 # 점프: 상승은 살짝 길게, 하강은 기본, 착지는 눌렸다가 돌아온다.
 if height>2.0:stretch=1.06 if actor.jump_velocity>0 else 1.01
 if landing>0.0:
  var t: float=landing/.24
  stretch=1.0-.16*sin(t*PI);width=1.0+.16*sin(t*PI)
 var cast_amount: float=clampf(cast/.3,0,0.999)
 if cast>0.0:
  stretch*=1.04;width*=1.03;tilt-=0.10*cast_amount
 sprite.position=Vector2(0,bob-height)
 sprite.rotation=tilt
 # 배율은 텍스처 기준값을 유지한 채 스쿼시·호흡만 곱한다.
 sprite.scale=Vector2(base_scale*width*breathe,base_scale*stretch*breathe)
 var animated_particles: bool=not dust.is_empty() or not wind.is_empty()
 _tick_particles(delta)
 # 안드로이드 발열·렉 방지: _draw() 내용(그림자·먼지·바람·시전 원)이 실제로
 # 변할 때만 다시 그린다. 스프라이트 변환은 노드 프로퍼티라 재드로우가 필요 없다.
 if animated_particles or not dust.is_empty() or not wind.is_empty() or cast>0.0 or landing>0.0 or height_moved or height>0.0:
  queue_redraw()

## 진행 방향 기울기 부호(오른쪽 +, 왼쪽 -).
func _lean() -> float:
 if actor==null:return 0.0
 return float(LEAN.get(posmod(actor.facing,8),0.0))

func _tick_particles(delta: float) -> void:
 for i in range(dust.size()-1,-1,-1):
  var d: Dictionary=dust[i]
  d.age+=delta
  if d.age>=d.life:dust.remove_at(i);continue
  d.p=(d.p as Vector2)+(d.v as Vector2)*delta
  d.v=(d.v as Vector2)*0.9
 for i in range(wind.size()-1,-1,-1):
  var w: Dictionary=wind[i]
  w.age+=delta
  if w.age>=w.life:wind.remove_at(i);continue
  w.p=(w.p as Vector2)+(w.v as Vector2)*delta

## 발밑 그림자: 점프 높이에 따라 작아지고 옅어진다.
func _draw() -> void:
 var height: float=maxf(0.0,actor.jump_height) if actor!=null else 0.0
 var scale_down: float=clampf(1.0-height/110.0,.42,1.0)
 var alpha: float=0.34*scale_down+0.08
 # 5) 질주 바람 자국: 캐릭터 뒤로 짧은 선이 흐르며 사라진다.
 for w in wind:
  var t: float=float(w.age)/maxf(.01,float(w.life))
  var length: float=float(w.len)*(1.0-t*.4)
  var p: Vector2=w.p
  draw_line(p,p+Vector2(-length*_lean(),0),Color(.86,.92,1.0,.30*(1.0-t)),2.0,true)
 # 4) 발밑 흙먼지: 퍼지며 옅어진다.
 for d in dust:
  var t: float=float(d.age)/maxf(.01,float(d.life))
  var radius: float=float(d.size)*(1.0+t*1.6)
  draw_set_transform(d.p,0,Vector2(1,.5))
  draw_circle(Vector2.ZERO,radius,Color(.72,.66,.54,.22*(1.0-t)))
  draw_circle(Vector2.ZERO,radius*.6,Color(.80,.75,.64,.16*(1.0-t)))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_set_transform(Vector2(0,0),0,Vector2(scale_down,scale_down*.42))
 draw_circle(Vector2.ZERO,12.0,Color(SHADOW.r,SHADOW.g,SHADOW.b,alpha))
 draw_circle(Vector2(1,0),7.0,Color(SHADOW.r,SHADOW.g,SHADOW.b,alpha*.45))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if cast>0.0:
  var t:=1.0-cast/.3
  for i in range(3):
   var radius:=10.0+t*26.0+i*4.0
   draw_arc(Vector2(0,-1),radius,0,TAU,28,Color(.72,.86,1,.42*(1.0-t)*(1.0-i*.25)),2.0,true)
