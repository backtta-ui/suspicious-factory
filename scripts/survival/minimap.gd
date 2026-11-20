extends Control
## 원형 금테 미니맵(2.0.34). 탭하면 전체 지도가 열린다.
## 이번 버전의 핵심: 확대 지도도 '정지 스냅샷'이 아니라 매 틱 갱신되는 실시간 지도다
## (경기 시뮬레이션이 오버레이와 무관하게 계속 돌기 때문).
##  - 같은 팀원은 항상 보인다(도사=파랑, 요괴=빨강).
##  - 봉인된 도사는 같은 편에게 '구출 필요' 맥동 아이콘 + 남은 초로 보인다.
##  - 적은 탐지 도술이 켜져 있는 동안만 테두리 점으로 나타난다.
##  - 안전구역 원(현재·다음)을 맵 구조 위에 선명하게 그린다.
signal map_requested
const GOLD=Color("e2c07c")
const DAOIST=Color("63b0ff")
const YOKAI=Color("ff5f6d")
const WHITE_RIM=Color("f2f6ff")
const ORANGE=Color("ffb04a")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var rules: RefCounted
var observer:="human"
var L: Script=preload("res://scripts/survival/layout.gd")
var _dirty:=true
var _clock:=0.0
var _refresh:=0.0
var _pulse:=0.0
var _press_msec:=0
## 2.0.34 실시간 갱신 검증용: 지도가 실제로 다시 그려진 횟수.
var draws:=0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(func()->void:_dirty=true;queue_redraw())
func _gui_input(event: InputEvent) -> void:
 var pressed:=false
 if event is InputEventScreenTouch:
  pressed=event.pressed
 elif event is InputEventMouseButton:
  pressed=event.pressed and event.button_index==MOUSE_BUTTON_LEFT
 else:
  return
 if not pressed:return
 var now:=Time.get_ticks_msec()
 if now-_press_msec<150:accept_event();return
 _press_msec=now
 map_requested.emit()
 accept_event()
func sync_map() -> void:
 if rules!=null and rules.get("L")!=null:L=rules.L
func at(p: Vector2) -> Vector2:
 var box:=size-Vector2(44,44)
 return Vector2(22,22)+p/L.SIZE*box
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
 draws+=1
 sync_map()
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
  draw_structure(to_map,scale_factor)
  var circle: Dictionary=rules.circle()
  # 안전구역: 현재 원(굵은 금빛) + 다음 원(점선 느낌의 옅은 청록)
  draw_arc(to_map.call(circle.center),float(circle.radius)*scale_factor,0,TAU,64,Color(.35,1,1,.55),1.6,true)
  draw_arc(to_map.call(circle.center),float(circle.radius)*scale_factor,0,TAU,64,Color(.55,.85,1,.28),4.0,false)
  draw_arc(to_map.call(circle.next_center),float(circle.next_radius)*scale_factor,0,TAU,64,Color(.7,.9,1,.22),1.0,true)
  draw_units(to_map,dot_radius())
 draw_arc(center,radius,0,TAU,64,Color("1b2438"),5,true)
 draw_arc(center,radius-1,0,TAU,64,GOLD,2.4,true)
 draw_arc(center,radius-5,0,TAU,64,Color(GOLD,.25),1,true)
 draw_colored_polygon(PackedVector2Array([Vector2(center.x,3),Vector2(center.x-5,11),Vector2(center.x+5,11)]),GOLD)
 for i in range(8):
  var a:=i*TAU/8
  draw_circle(center+Vector2.from_angle(a)*(radius+2),1.6,Color(GOLD,.5))
## 맵 구조: 서원(담장·한옥·연못·대나무·길) / 강남역(구역·벽·스크린도어·선로).
func draw_structure(to_map: Callable,scale_factor: float) -> void:
 if String(L.map_id())=="gangnam":
  for zone in L.ZONES:
   var rect: Rect2=zone.rect
   var accent: Color=zone.accent
   draw_rect(Rect2(to_map.call(rect.position),rect.size*scale_factor),Color(accent.r,accent.g,accent.b,.16))
   draw_rect(Rect2(to_map.call(rect.position),rect.size*scale_factor),Color(accent.r,accent.g,accent.b,.42),false,maxf(1.0,dot_radius()*.22))
  for wall in L.HARD:
   var r: Rect2=wall
   draw_rect(Rect2(to_map.call(r.position),r.size*scale_factor),Color(.22,.28,.40,.95))
  var track: Rect2=L.TRACK
  draw_rect(Rect2(to_map.call(track.position),track.size*scale_factor),Color(.06,.07,.10,.95))
  for path in L.PATHS:
   var points: Array=path.p
   for i in range(points.size()-1):
    draw_line(to_map.call(points[i]),to_map.call(points[i+1]),Color(.62,.74,.88,.20),maxf(1.0,float(path.w)*scale_factor*.5))
  # 개찰구(기믹) 위치 표시
  for item in L.GIMMICKS:
   if String(item.kind)!="turnstile":continue
   var locked: bool=rules.gimmicks!=null and rules.gimmicks.turnstile_until>rules.elapsed
   draw_circle(to_map.call(item.pos),maxf(2.0,dot_radius()*.7),Color(1,.35,.35,.95) if locked else Color(.45,1,.9,.9))
  return
 for rect in L.HARD:
  var a: Vector2=to_map.call(rect.position);var b: Vector2=to_map.call(rect.end)
  draw_rect(Rect2(a,b-a),Color("3a4666"))
 for b2 in L.buildings():
  var r2: Rect2=b2.rect
  draw_rect(Rect2(to_map.call(r2.position),(r2.size)*scale_factor),Color("27324d"))
  draw_rect(Rect2(to_map.call(r2.position),(r2.size)*scale_factor),Color("4d5d80"),false,maxf(1.0,dot_radius()*.3))
 var pond: Rect2=L.POND
 draw_rect(Rect2(to_map.call(pond.position),pond.size*scale_factor),Color("1d4160"))
 draw_line(to_map.call(L.BRIDGE_A),to_map.call(L.BRIDGE_B),Color("c9ab74"),3.0)
 for rect2 in L.BAMBOO:draw_rect(Rect2(to_map.call(rect2.position),rect2.size*scale_factor),Color(.2,.38,.28,.75))
 for path2 in L.PATHS:
  var points2: Array=path2.p
  for i in range(points2.size()-1):
   draw_line(to_map.call(points2[i]),to_map.call(points2[i+1]),Color(.62,.52,.36,.30),maxf(1.0,float(path2.w)*scale_factor*.5))
## 같은 팀원(항상) + 탐지 중인 적(그 시간 동안만) + 봉인된 동료의 구출 아이콘.
func draw_units(to_map: Callable,unit: float) -> void:
 var self_role: String=String(rules.players.get(observer,{}).get("role","daoist"))
 var team: Color=team_color(self_role)
 for a in rules.allies(observer):
  var p: Vector2=to_map.call(a.position)
  if bool(a.eliminated):
   var s:=unit*.85
   draw_line(p-Vector2(s,s),p+Vector2(s,s),Color(.52,.54,.62,.9),maxf(1.0,unit*.35),true)
   draw_line(p-Vector2(-s,s),p+Vector2(s,-s),Color(.52,.54,.62,.9),maxf(1.0,unit*.35),true)
   continue
  if bool(a.captured):
   # 2.0.34 구출 필요 아이콘: 맥동하는 주황 뱃지 + 남은 초.
   var r: Dictionary=rules.players.get(String(a.id),{})
   var left: float=maxf(0.0,float(r.get("deadline",0.0))-float(rules.elapsed))
   var beat: float=.5+.5*sin(_clock*4.2)
   draw_circle(p,unit*(2.6+beat*.7),Color(ORANGE.r,ORANGE.g,ORANGE.b,.30+.22*beat))
   draw_arc(p,unit*(2.0+beat*.45),0,TAU,18,Color(ORANGE.r,ORANGE.g,ORANGE.b,.95),maxf(1.0,unit*.32),true)
   draw_line(p-Vector2(unit*.75,0),p+Vector2(unit*.75,0),Color(1,.95,.8,.98),maxf(1.0,unit*.34),true)
   draw_line(p-Vector2(0,unit*.75),p+Vector2(0,unit*.75),Color(1,.95,.8,.98),maxf(1.0,unit*.34),true)
   if size.x>180.0:
    draw_string(FONT,p+Vector2(unit*2.6,-unit*.6),"%.0f"%left,HORIZONTAL_ALIGNMENT_LEFT,-1,int(maxf(9.0,unit*1.5)),ORANGE)
   continue
  if bool(a.self):
   draw_circle(p,unit*(2.1+_pulse*.5),Color(team.r,team.g,team.b,.22))
   draw_circle(p,unit*1.25,team)
   draw_arc(p,unit*1.25,0,TAU,18,Color(1,.9,.55,.95),maxf(1.0,unit*.35),true)
   continue
  draw_circle(p,unit*1.15,team)
  draw_arc(p,unit*1.15,0,TAU,16,WHITE_RIM,maxf(1.0,unit*.28),true)
  if String(a.get("rescuing",""))!="":
   draw_arc(p,unit*1.9,-PI*.5,-PI*.5+TAU*.6,18,Color(.68,1,.85,.9),maxf(1.0,unit*.3),true)
  if bool(a.get("hidden",false)):
   draw_arc(p,unit*1.9,0,TAU,18,Color(team.r,team.g,team.b,.5),1.0,true)
 for c in rules.map_contacts(observer):
  var p2: Vector2=to_map.call(c.pos)
  var enemy:=team_color(String(c.team))
  draw_arc(p2,unit*(1.5+_pulse*.25),0,TAU,18,Color(enemy.r,enemy.g,enemy.b,.95),maxf(1.0,unit*.3),true)
  draw_circle(p2,unit*.42,enemy)
func refresh() -> void:
 _dirty=true;queue_redraw()
func _process(delta: float) -> void:
 if rules==null:return
 _clock+=delta
 _refresh+=delta
 # 위치·효과가 실제로 달라졌을 때만 5fps로 갱신(모바일 부하 최소화). 확대 지도도 같은 경로.
 if _refresh<.2:return
 _refresh=0;_dirty=false;queue_redraw()
