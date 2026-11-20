extends Control
## 2.0.34 구출 필요 아이콘.
## 봉인된 도사는 같은 편(도사)에게만 보이도록, 머리 위에 맥동하는 주황·금빛 구조 뱃지와
## 남은 봉인 시간 게이지를 그리고, 화면 밖에 있으면 화면 가장자리에 방향 화살표를 띄운다.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const ORANGE=Color("ffb04a")
const GOLD=Color("ffe6a8")
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
func badge(at: Vector2,pulse: float,left: float) -> void:
 var scale_value: float=1.0+.10*pulse
 draw_circle(at,15.0*scale_value,Color(ORANGE.r,ORANGE.g,ORANGE.b,.22+.18*pulse))
 draw_arc(at,15.0*scale_value,0,TAU,26,Color(ORANGE.r,ORANGE.g,ORANGE.b,.95),2.4,true)
 # 구조(십자) 아이콘
 draw_rect(Rect2(at-Vector2(6,2),Vector2(12,4)),ON_RESCUE())
 draw_rect(Rect2(at-Vector2(2,6),Vector2(4,12)),ON_RESCUE())
 # 남은 봉인 시간 게이지(10초 기준)
 var ratio: float=clampf(left/10.0,0.0,1.0)
 var bar:=Rect2(at+Vector2(-18,19),Vector2(36,5))
 draw_rect(bar,Color(.05,.04,.06,.85))
 draw_rect(Rect2(bar.position,Vector2(bar.size.x*ratio,bar.size.y)),ORANGE)
 draw_string(FONT,at+Vector2(-20,35),"구출 %.0f초"%left,HORIZONTAL_ALIGNMENT_CENTER,40,11,GOLD)
func ON_RESCUE() -> Color:return Color(1,.94,.78,.98)
func arrow(at: Vector2,dir: Vector2,pulse: float,left: float,name_value: String) -> void:
 var angle: float=dir.angle()
 draw_set_transform(at,0,Vector2.ONE)
 draw_circle(Vector2.ZERO,15.0,Color(ORANGE.r,ORANGE.g,ORANGE.b,.20+.16*pulse))
 draw_arc(Vector2.ZERO,15.0,0,TAU,24,Color(ORANGE.r,ORANGE.g,ORANGE.b,.85),2.0,true)
 draw_circle(Vector2.ZERO,7.0,Color(1,.93,.72,.95))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var tip:=at+dir*24.0
 var pts:=PackedVector2Array([tip+dir*12.0,tip+dir.rotated(PI*.5)*8.0,tip+dir.rotated(-PI*.5)*8.0])
 draw_colored_polygon(pts,Color(ORANGE.r,ORANGE.g,ORANGE.b,.92))
 draw_string(FONT,at+Vector2(-30,32),"구출 %.0f초"%left,HORIZONTAL_ALIGNMENT_CENTER,60,11,GOLD)
