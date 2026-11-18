extends Control
## 원형 금테 미니맵. 탭하면 전체 지도가 열린다(상태 변화 시에만 다시 그린다).
signal map_requested
const GOLD=Color("e2c07c")
const L=preload("res://scripts/survival/layout.gd")
var rules: RefCounted
var observer:="human"
var _dirty:=true
var _clock:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(func()->void:_dirty=true;queue_redraw())
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  map_requested.emit();accept_event()
func at(p: Vector2) -> Vector2:
 var box:=size-Vector2(44,44)
 return Vector2(22,22)+p/L.SIZE*box
func _draw() -> void:
 var center:=size*.5;var radius:=minf(size.x,size.y)*.5-3
 draw_circle(center+Vector2(0,3),radius,Color(.01,.02,.05,.5))
 draw_circle(center,radius,Color("0d1526"))
 draw_circle(center,radius*.94,Color("101a30"))
 var scale_factor: float=(radius*2*.82)/maxf(L.SIZE.x,L.SIZE.y)
 var origin:=center-Vector2(L.SIZE.x,L.SIZE.y)*scale_factor*.5
 if rules!=null:
  var to_map:=func(p: Vector2)->Vector2:return origin+p*scale_factor
  for rect in L.HARD+[L.HANOK]:
   var a: Vector2=to_map.call(rect.position);var b: Vector2=to_map.call(rect.end)
   draw_rect(Rect2(a,b-a),Color("3a4666"))
  var pond:=L.POND
  draw_rect(Rect2(to_map.call(pond.position),pond.size*scale_factor),Color("1d4160"))
  draw_line(to_map.call(L.BRIDGE_A),to_map.call(L.BRIDGE_B),Color("c9ab74"),3.0)
  for rect in L.BAMBOO:draw_rect(Rect2(to_map.call(rect.position),rect.size*scale_factor),Color(.2,.38,.28,.75))
  var circle: Dictionary=rules.circle()
  draw_arc(to_map.call(circle.center),circle.radius*scale_factor,0,TAU,48,Color(.55,.85,1,.4),1.2,true)
  for a in rules.visible(observer):
   if a.id=="":continue
   var p: Vector2=to_map.call(a.position)
   var color:=Color("ffe392") if a.id==observer else (Color("ff8f8f") if a.role=="yokai" else Color("9fb4e0"))
   draw_circle(p,2.8 if a.id==observer else 2.2,color)
  var selfp: Dictionary=rules.players.get(observer,{})
  if not selfp.is_empty():
   var p: Vector2=to_map.call(selfp.position)
   draw_circle(p,4,Color(1,.9,.55,.28))
   draw_circle(p,2.4,Color("fff3c4"))
 draw_arc(center,radius,0,TAU,64,Color("1b2438"),5,true)
 draw_arc(center,radius-1,0,TAU,64,GOLD,2.4,true)
 draw_arc(center,radius-5,0,TAU,64,Color(GOLD,.25),1,true)
 # 북쪽 표시와 장식
 draw_colored_polygon(PackedVector2Array([Vector2(center.x,3),Vector2(center.x-5,11),Vector2(center.x+5,11)]),GOLD)
 for i in range(8):
  var a:=i*TAU/8
  draw_circle(center+Vector2.from_angle(a)*(radius+2),1.6,Color(GOLD,.5))
func refresh() -> void:
 if _dirty or rules==null:return
 _dirty=true;queue_redraw()
func _process(delta: float) -> void:
 if rules==null:return
 _clock+=delta
 # 위치가 실제로 달라졌을 때만 5fps로 갱신(모바일 부하 최소화).
 if _clock<.2:return
 _clock=0;_dirty=false;queue_redraw()
