extends Control
## 2.0.34 강남역 관리실 CCTV 실시간 미니 뷰.
## 상호작용한 순간부터 8초 동안, 고른 구역(대합실·카페·승장장·개찰구)의 실제 인원을
## 벽과 무관하게 실시간으로 보여 준다. 상태는 rules.gimmicks 한 곳에서만 읽는다.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
var rules: RefCounted
var observer:="human"
var clock:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 clock+=delta
 if rules==null or rules.gimmicks==null or rules.gimmicks.cctv_until<=rules.elapsed:
  if visible:visible=false
  return
 if not visible:visible=true
 queue_redraw()
func _draw() -> void:
 if rules==null or rules.gimmicks==null:return
 var g: RefCounted=rules.gimmicks
 var zone: Dictionary=rules.L.zone(g.cctv_zone)
 if zone.is_empty():return
 var rect: Rect2=zone.rect
 var left: float=maxf(0.0,g.cctv_until-rules.elapsed)
 var box:=Rect2(Vector2.ZERO,size)
 # 본체(검은 모니터)
 draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color(.02,.03,.05,.92))
 draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color(.35,.95,1,.75),false,2.0)
 var header: float=22.0
 draw_rect(Rect2(Vector2(4,4),Vector2(size.x-8,header)),Color(.05,.10,.15,.95))
 draw_string(TITLE_FONT,Vector2(10,21),"CCTV · %s"%String(zone.name),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.72,.96,1))
 draw_circle(Vector2(size.x-18,15),4.5,Color(1,.25,.30,.9) if fmod(clock,1.0)<.6 else Color(.3,.1,.12,.9))
 draw_string(FONT,Vector2(size.x-58,20),"%.1fs"%left,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.85,.92,1,.8))
 # 구역 지도(구역 사각형을 화면에 맞춰 축소)
 var body:=Rect2(Vector2(8,header+8),Vector2(size.x-16,size.y-header-14))
 var scale_factor: float=minf(body.size.x/rect.size.x,body.size.y/rect.size.y)
 var origin: Vector2=body.position+Vector2((body.size.x-rect.size.x*scale_factor)*.5,(body.size.y-rect.size.y*scale_factor)*.5)
 draw_rect(Rect2(origin,rect.size*scale_factor),Color(.10,.16,.22,.95))
 # 벽(충돌 사각형)을 흐린 선으로 그려 구역 형태가 읽히게 한다.
 for wall in rules.L.HARD:
  var r: Rect2=wall
  if not r.intersects(rect.grow(80)):continue
  var p1:=origin+(r.position-rect.position)*scale_factor
  draw_rect(Rect2(p1,r.size*scale_factor),Color(.30,.42,.55,.55))
 draw_rect(Rect2(origin,rect.size*scale_factor),Color(.55,1,1,.35),false,1.0)
 # 인원: 벽과 무관하게 이 구역 안의 모든 플레이어를 점으로.
 var blink: float=.5+.5*sin(clock*4.0)
 for p in rules.players.values():
  if p.eliminated:continue
  if not rect.has_point(p.position):continue
  var at: Vector2=origin+(p.position-rect.position)*scale_factor
  var color: Color=Color(.42,.70,1) if String(p.role)=="daoist" else Color(1,.36,.42)
  if p.captured:color=Color(1,.72,.25)
  draw_circle(at,5.0,Color(color.r,color.g,color.b,.30+.25*blink))
  draw_circle(at,2.8,color)
  if String(p.get("id",""))==observer:draw_arc(at,5.6,0,TAU,16,Color(1,.9,.55,.95),1.4,true)
 draw_string(FONT,Vector2(9,size.y-5),"실시간 · 벽 너머 관측",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(.6,.8,.9,.7))
