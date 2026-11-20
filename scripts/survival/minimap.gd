extends Control
## 원형 금테 미니맵. 탭하면 전체 지도가 열린다(상태 변화 시에만 다시 그린다).
## 2.0.30 표시 원칙: 지도에는 '맵 구조'와 '같은 팀원'만 그린다.
##  - 내가 도사면 도사만 파란색, 내가 요괴면 요괴만 빨간색.
##  - 적은 천문기계·귀문보기·발자국/청각사냥·야광가루 같은 '탐지 도술'이
##    켜져 있는 동안에만(그 지속시간 동안만) 팀 색 테두리로 나타난다.
## 덫·보물함 같은 설치물은 지도에 표시하지 않는다(화면의 월드 연출로만 보인다).
signal map_requested
const GOLD=Color("e2c07c")
const L=preload("res://scripts/survival/layout.gd")
const DAOIST=Color("63b0ff")
const YOKAI=Color("ff5f6d")
const WHITE_RIM=Color("f2f6ff")
var rules: RefCounted
var observer:="human"
var _dirty:=true
var _clock:=0.0
var _refresh:=0.0
var _pulse:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(func()->void:_dirty=true;queue_redraw())
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  map_requested.emit();accept_event()
func at(p: Vector2) -> Vector2:
 var box:=size-Vector2(44,44)
 return Vector2(22,22)+p/L.SIZE*box
## 지도 좌표 변환기(미니맵·전체 지도 공용).
func mapper() -> Dictionary:
 var center:=size*.5
 var radius:=minf(size.x,size.y)*.5-3
 var scale_factor: float=(radius*2*.82)/maxf(L.SIZE.x,L.SIZE.y)
 return {"center":center,"radius":radius,"scale":scale_factor,
  "origin":center-Vector2(L.SIZE.x,L.SIZE.y)*scale_factor*.5,
  "to_map":func(p: Vector2)->Vector2:return center-Vector2(L.SIZE.x,L.SIZE.y)*scale_factor*.5+p*scale_factor}
func dot_radius() -> float:
 return clampf(minf(size.x,size.y)/44.0,1.6,7.0)
func team_color(team: String) -> Color:
 return DAOIST if team=="daoist" else YOKAI
func _draw() -> void:
 var box: Dictionary=mapper()
 var center: Vector2=box.center
 var radius: float=box.radius
 var scale_factor: float=box.scale
 var to_map: Callable=box.to_map
 _pulse=.5+.5*sin(_clock*2.6)
 draw_circle(center+Vector2(0,3),radius,Color(.01,.02,.05,.5))
 draw_circle(center,radius,Color("0d1526"))
 draw_circle(center,radius*.94,Color("101a30"))
 if rules!=null:
  # --- 맵 구조: 담장·건물·길·연못·대나무
  for rect in L.HARD:
   var a: Vector2=to_map.call(rect.position);var b: Vector2=to_map.call(rect.end)
   draw_rect(Rect2(a,b-a),Color("3a4666"))
  for b in L.buildings():
   var r: Rect2=b.rect
   draw_rect(Rect2(to_map.call(r.position),(r.size)*scale_factor),Color("27324d"))
   draw_rect(Rect2(to_map.call(r.position),(r.size)*scale_factor),Color("4d5d80"),false,maxf(1.0,dot_radius()*.3))
  var pond:=L.POND
  draw_rect(Rect2(to_map.call(pond.position),pond.size*scale_factor),Color("1d4160"))
  draw_line(to_map.call(L.BRIDGE_A),to_map.call(L.BRIDGE_B),Color("c9ab74"),3.0)
  for rect in L.BAMBOO:draw_rect(Rect2(to_map.call(rect.position),rect.size*scale_factor),Color(.2,.38,.28,.75))
  for path in L.PATHS:
   var points: Array=path.p
   for i in range(points.size()-1):
    draw_line(to_map.call(points[i]),to_map.call(points[i+1]),Color(.62,.52,.36,.30),maxf(1.0,float(path.w)*scale_factor*.5))
  var circle: Dictionary=rules.circle()
  draw_arc(to_map.call(circle.center),circle.radius*scale_factor,0,TAU,48,Color(.55,.85,1,.4),1.2,true)
  draw_units(to_map,dot_radius())
 draw_arc(center,radius,0,TAU,64,Color("1b2438"),5,true)
 draw_arc(center,radius-1,0,TAU,64,GOLD,2.4,true)
 draw_arc(center,radius-5,0,TAU,64,Color(GOLD,.25),1,true)
 # 북쪽 표시와 장식
 draw_colored_polygon(PackedVector2Array([Vector2(center.x,3),Vector2(center.x-5,11),Vector2(center.x+5,11)]),GOLD)
 for i in range(8):
  var a:=i*TAU/8
  draw_circle(center+Vector2.from_angle(a)*(radius+2),1.6,Color(GOLD,.5))
## 같은 팀원(항상) + 탐지 중인 적(그 시간 동안만).
func draw_units(to_map: Callable,unit: float) -> void:
 var self_role: String=String(rules.players.get(observer,{}).get("role","daoist"))
 var team: Color=team_color(self_role)
 for a in rules.allies(observer):
  var p: Vector2=to_map.call(a.position)
  if bool(a.eliminated):
   # 탈락: 회색 X (팀 색 점은 지운다).
   var s:=unit*.85
   draw_line(p-Vector2(s,s),p+Vector2(s,s),Color(.52,.54,.62,.9),maxf(1.0,unit*.35),true)
   draw_line(p-Vector2(-s,s),p+Vector2(-s,s),Color(.52,.54,.62,.9),maxf(1.0,unit*.35),true)
   continue
  if bool(a.captured):
   # 봉인: 팀 색 마름모(속이 빈 형태)로 상태를 바로 읽게 한다.
   var d:=unit*1.4
   var diamond:=PackedVector2Array([p+Vector2(0,-d),p+Vector2(d,0),p+Vector2(0,d),p+Vector2(-d,0),p+Vector2(0,-d)])
   draw_colored_polygon(diamond,Color(team.r,team.g,team.b,.45))
   draw_polyline(diamond,Color(team.r,team.g,team.b,.95),maxf(1.0,unit*.3),true)
   continue
  if bool(a.self):
   # 자신: 팀 색 점 + 금빛 테두리(누가 나인지 한눈에).
   draw_circle(p,unit*(2.1+_pulse*.5),Color(team.r,team.g,team.b,.22))
   draw_circle(p,unit*1.25,team)
   draw_arc(p,unit*1.25,0,TAU,18,Color(1,.9,.55,.95),maxf(1.0,unit*.35),true)
   continue
  # 같은 팀원: 팀 색 채운 점 + 흰 테.
  draw_circle(p,unit*1.15,team)
  draw_arc(p,unit*1.15,0,TAU,16,WHITE_RIM,maxf(1.0,unit*.28),true)
  if String(a.get("rescuing",""))!="":
   draw_arc(p,unit*1.9,-PI*.5,-PI*.5+TAU*.6,18,Color(.68,1,.85,.9),maxf(1.0,unit*.3),true)
  if bool(a.get("hidden",false)):
   draw_arc(p,unit*1.9,0,TAU,18,Color(team.r,team.g,team.b,.5),1.0,true)
 # 탐지된 적: 팀 색 테두리 링 + 작은 점(아군의 채운 점과 구별된다).
 for c in rules.map_contacts(observer):
  var p2: Vector2=to_map.call(c.pos)
  var enemy:=team_color(String(c.team))
  draw_arc(p2,unit*(1.5+_pulse*.25),0,TAU,18,Color(enemy.r,enemy.g,enemy.b,.95),maxf(1.0,unit*.3),true)
  draw_circle(p2,unit*.42,enemy)
func refresh() -> void:
 if _dirty or rules==null:return
 _dirty=true;queue_redraw()
func _process(delta: float) -> void:
 if rules==null:return
 _clock+=delta
 _refresh+=delta
 # 위치·효과가 실제로 달라졌을 때만 5fps로 갱신(모바일 부하 최소화).
 if _refresh<.2:return
 _refresh=0;_dirty=false;queue_redraw()
