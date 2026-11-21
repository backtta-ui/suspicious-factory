extends Control
## 2.0.36 실시간 CCTV — 도식이 아니라 진짜 카메라 화면.
## 강남역 관리실 모니터를 누르면 SubViewport + Camera2D가 실제 맵 구역을 비추고,
## 그 화면(맵·캐릭터·이펙트·기믹)이 그대로 모니터에 나온다. 벽 너머 상황도 보인다.
## 상태는 rules.gimmicks 한 곳에서만 읽는다(켜진 구역·남은 시간).
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
var rules: RefCounted
var observer:="human"
var clock:=0.0
## app.hud()가 만들어 넘기는 실제 카메라 피드.
var feed: SubViewport
var camera: Camera2D
var zone:=""
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 clock+=delta
 var active: bool=rules!=null and rules.gimmicks!=null and rules.gimmicks.cctv_until>rules.elapsed and rules.gimmicks.cctv_zone!=""
 if feed!=null:
  feed.render_target_update_mode=SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
 if not active:
  if visible:visible=false
  return
 if not visible:visible=true
 var g: RefCounted=rules.gimmicks
 if zone!=String(g.cctv_zone):
  zone=String(g.cctv_zone)
  focus_zone()
 queue_redraw()
## 감시 구역이 바뀌면 실제 카메라를 그 구역 중심으로 옮기고 구역이 꽉 차게 줌한다.
func focus_zone() -> void:
 if camera==null or rules==null:return
 if rules.gimmicks!=null and String(rules.gimmicks.cctv_zone)!="":zone=String(rules.gimmicks.cctv_zone)
 var rect: Rect2=rules.L.zone_rect(zone)
 if rect.size.x<=0.0:return
 camera.position=rect.get_center()
 var view:=feed.size if feed!=null else Vector2i(256,180)
 var fit:=minf(float(view.x)/maxf(1.0,rect.size.x),float(view.y)/maxf(1.0,rect.size.y))
 camera.zoom=Vector2(fit,fit)*1.08
func _draw() -> void:
 var g: RefCounted=rules.gimmicks
 var zone_info: Dictionary=rules.L.zone(g.cctv_zone)
 var left: float=maxf(0.0,g.cctv_until-rules.elapsed)
 var box:=Rect2(Vector2(4,22),size-Vector2(8,26))
 # 모니터 본체
 draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.025,.04,.96))
 draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(.30,.90,1,.72),false,2.0)
 # 실제 카메라 화면
 if feed!=null:
  draw_texture_rect(feed.get_texture(),box,false,Color(1,1,1,.98))
 else:
  draw_rect(box,Color(.06,.08,.11,.95))
 # 주사선·비네트(실제 화면 위에 얹는 모니터 질감)
 for y in range(int(box.position.y),int(box.end.y),3):
  draw_rect(Rect2(Vector2(box.position.x,float(y)),Vector2(box.size.x,1)),Color(0,0,0,.10))
 draw_rect(box,Color(.02,.04,.07,.30),false,2.0)
 # 상단 바: 구역 이름·REC 점·남은 시간
 draw_rect(Rect2(Vector2(0,0),Vector2(size.x,21)),Color(.03,.08,.12,.97))
 draw_string(TITLE_FONT,Vector2(8,16),"CCTV · %s"%String(zone_info.get("name","감시")),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.75,.97,1))
 var blink: bool=fmod(clock,1.0)<.6
 draw_circle(Vector2(size.x-72,10),4.5,Color(1,.25,.30,.95) if blink else Color(.35,.10,.12,.9))
 draw_string(FONT,Vector2(size.x-64,15),"REC",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(1,.55,.55,.95))
 draw_string(FONT,Vector2(size.x-38,15),"%.1fs"%left,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.85,.92,1,.85))
 # 하단 캡션
 draw_rect(Rect2(Vector2(0,size.y-18),Vector2(size.x,18)),Color(.02,.05,.08,.92))
 draw_string(FONT,Vector2(8,size.y-5),"실시간 · 벽 너머 관측 · 도사 파랑 / 요괴 빨강",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(.62,.82,.92,.85))
