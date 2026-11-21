extends Control
## 2.0.34 구출 필요 아이콘.
## 봉인된 도사는 같은 편(도사)에게만 보이도록, 머리 위에 맥동하는 주황·금빛 구조 뱃지와
## 남은 봉인 시간 게이지를 그리고, 화면 밖에 있으면 화면 가장자리에 방향 화살표를 띄운다.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const ORANGE=Color("ffb04a")
const GOLD=Color("ffe6a8")
## 2.0.36 시인성: 머리 위 큰 진행 링과 26px 숫자(작은 아이콘 금지).
const BADGE_RADIUS=25.0
const NUMBER_SIZE=26
var rules: RefCounted
var observer:="human"
var camera: Camera2D
var clock:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
 clock+=delta
 if rules==null or camera==null or rules.players.get(observer,{}).get("role","")!="daoist":
  if visible:visible=false
  return
 if not visible:visible=true
 queue_redraw()
func _draw() -> void:
 if rules==null or camera==null:return
 var view:=get_viewport().get_visible_rect().size
 var xform:=get_viewport().get_canvas_transform()
 var pulse: float=.5+.5*sin(clock*4.2)
 for ally in rules.allies(observer):
  if not bool(ally.captured) or bool(ally.eliminated):continue
  var p: Dictionary=rules.players.get(String(ally.id),{})
  if p.is_empty():continue
  var world_pos: Vector2=(p.position as Vector2)+Vector2(0,-66)
  var screen: Vector2=xform*world_pos
  var left: float=maxf(0.0,float(p.deadline)-float(rules.elapsed))
  var onscreen: bool=screen.x>=0 and screen.y>=0 and screen.x<=view.x and screen.y<=view.y
  if onscreen:
   badge(screen,pulse,left)
  else:
   # 화면 밖: 가장자리로 붙여 방향 화살표 + 남은 시간.
   var center:=view*.5
   var dir: Vector2=(screen-center)
   if dir.length()<1.0:dir=Vector2.RIGHT
   dir=dir.normalized()
   var edge:=center+dir*minf((view.x*.5-46.0)/maxf(.001,absf(dir.x)),(view.y*.5-52.0)/maxf(.001,absf(dir.y)))
   arrow(edge,dir,pulse,left,String(ally.get("name","동료")))
## 2.0.36 시인성 개편: 작은 아이콘 대신 '큰 원형 진행 링 + 남은 초 숫자'를 머리 위에 띄운다.
## 링이 줄어들수록 구조가 급하다는 것이 한눈에 읽히고, 숫자는 외곽선으로 어떤 바닥에서도 선명하다.
func badge(at: Vector2,pulse: float,left: float) -> void:
 var ratio: float=clampf(left/10.0,0.0,1.0)
 var radius: float=BADGE_RADIUS+3.0*pulse
 # 바닥 그림자와 주황 광
 draw_circle(at+Vector2(0,3),radius+4.0,Color(.02,.01,.03,.55))
 draw_circle(at,radius+2.0,Color(ORANGE.r,ORANGE.g,ORANGE.b,.16+.12*pulse))
 draw_circle(at,radius,Color(.08,.03,.01,.92))
 # 전체 트랙 + 남은 시간 진행 링(12시 방향에서 시계 반대? 구조까지 남은 비율)
 draw_arc(at,radius,0,TAU,40,Color(.30,.14,.03,.95),6.0,false)
 draw_arc(at,radius,-PI*.5,-PI*.5+TAU*ratio,48,ORANGE,6.0,true)
 draw_arc(at,radius+3.0,-PI*.5,-PI*.5+TAU*ratio,48,Color(1,.88,.55,.55),1.6,true)
 # 큰 숫자(남은 초) — 선명한 외곽선
 var seconds: String="%d"%maxi(0,int(ceil(left)))
 var number_size: int=NUMBER_SIZE
 var number_width: float=FONT.get_string_size(seconds,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size).x
 draw_string_outline(FONT,at+Vector2(-number_width*.5,9),seconds,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size,6,Color(.02,.01,.03,.95))
 draw_string(FONT,at+Vector2(-number_width*.5,9),seconds,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size,Color(1,.97,.86,.98))
 # '구조' 라벨과 꼬리
 draw_string_outline(FONT,at+Vector2(-26,-radius-14),"구조 필요",HORIZONTAL_ALIGNMENT_CENTER,52,13,4,Color(.02,.01,.03,.9))
 draw_string(FONT,at+Vector2(-26,-radius-14),"구조 필요",HORIZONTAL_ALIGNMENT_CENTER,52,13,GOLD)
 draw_colored_polygon(PackedVector2Array([at+Vector2(0,radius+1),at+Vector2(-6,radius-7),at+Vector2(6,radius-7)]),Color(ORANGE.r,ORANGE.g,ORANGE.b,.95))
func ON_RESCUE() -> Color:return Color(1,.94,.78,.98)
func arrow(at: Vector2,dir: Vector2,pulse: float,left: float,name_value: String) -> void:
 var radius: float=21.0+2.0*pulse
 draw_circle(at,radius+2.0,Color(ORANGE.r,ORANGE.g,ORANGE.b,.16+.12*pulse))
 draw_circle(at,radius,Color(.08,.03,.01,.92))
 var ratio: float=clampf(left/10.0,0.0,1.0)
 draw_arc(at,radius,0,TAU,36,Color(.30,.14,.03,.95),4.0,false)
 draw_arc(at,radius,-PI*.5,-PI*.5+TAU*ratio,40,ORANGE,4.0,true)
 var seconds: String="%d"%maxi(0,int(ceil(left)))
 draw_string_outline(FONT,at+Vector2(-16,-1),seconds,HORIZONTAL_ALIGNMENT_CENTER,32,20,5,Color(.02,.01,.03,.95))
 draw_string(FONT,at+Vector2(-16,-1),seconds,HORIZONTAL_ALIGNMENT_CENTER,32,20,Color(1,.97,.86,.98))
 var tip:=at+dir*(radius+8.0)
 var pts:=PackedVector2Array([tip+dir*14.0,tip+dir.rotated(PI*.5)*9.0,tip+dir.rotated(-PI*.5)*9.0])
 draw_colored_polygon(pts,Color(ORANGE.r,ORANGE.g,ORANGE.b,.95))
 draw_string_outline(FONT,at+Vector2(-46,radius+24),name_value+" · 구조",HORIZONTAL_ALIGNMENT_CENTER,92,12,4,Color(.02,.01,.03,.9))
 draw_string(FONT,at+Vector2(-46,radius+24),name_value+" · 구조",HORIZONTAL_ALIGNMENT_CENTER,92,12,GOLD)
