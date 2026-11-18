extends RefCounted
## 월하의 서원 · 2.5D 인게임 지도.
## 충돌·이동·표고·둔갑 대상이 모두 이 한 곳에서 정의되고,
## 화면(world.gd)은 같은 수치로 그림만 그린다.
##
## 출입 한옥은 외관 원화(hanok_exterior.png)의 문 위치(DOOR_ANCHOR)에서
## 외곽·실내·충돌·문 좌표를 역산한다. 그래서 문 앞에 서면 그림의 문과
## 충돌 문이 정확히 같은 자리이고, 건물을 키워도 어긋나지 않는다.
const SIZE=Vector2(1800,1400)
const SPAWN=Vector2(860,760)
## 인게임 기본 시점(2.5D 줌). 카메라는 내 캐릭터를 화면 중앙보다 아래에 둔다.
const CAMERA_ZOOM=1.75
const CAMERA_LIFT=56.0
const POND=Rect2(950,680,300,230)
## 연못을 비스듬히 가로지르는 아치 목교. 걸어서 오르면 표고가 오른다.
const BRIDGE_A=Vector2(885,965)
const BRIDGE_B=Vector2(1175,655)
const BRIDGE_HALF=36.0
const BRIDGE_RISE=27.0
const STONE=Rect2(700,600,440,400)
const MEDALLION=Vector2(860,720)
const MEDALLION_RADIUS=118.0
## hanok_exterior.png 안에서 문(계단 끝, 걸어 들어가는 지점)이 있는 비율.
const DOOR_ANCHOR=Vector2(.80,.965)
const HANOK_ART=Vector2(760,727)
const WALL=16.0
const DOOR_WIDTH=104.0
const BUILDING_SPECS=[
 {"id":"cheongwol","name":"청월당","sub":"서원의 큰 강당","door":Vector2(560,650),"width":540.0,"warmth":Color(1,.86,.68)},
 {"id":"seogo","name":"서고","sub":"오래된 책의 방","door":Vector2(1300,590),"width":470.0,"warmth":Color(.9,.9,.8)},
 {"id":"byeolchae","name":"별채","sub":"손님의 방","door":Vector2(470,1200),"width":470.0,"warmth":Color(1,.82,.72)}]
const NAMES=["청월당","서고","별채"]
## 대표 한옥(하위 호환). 세부는 buildings()가 계산한다.
static var BUILDINGS: Array=_make_buildings()
static var DOORS: Array=_make_doors()
static var HARD: Array=_make_hard()
## 뛰어넘을 수 있는 낮은 담·평상.
const LOW=[Rect2(760,700,140,14),Rect2(620,690,120,14),Rect2(660,1060,160,14),Rect2(760,860,110,14)]
## 마당을 나누는 기와 담장(충돌은 HARD에 포함, 그림은 이 목록을 쓴다).
const WALLS=[Rect2(700,330,200,100),Rect2(980,560,150,14),Rect2(1560,600,14,150),Rect2(1560,600,130,14),Rect2(330,700,180,14),Rect2(600,760,14,110),Rect2(1240,980,174,14),Rect2(1660,700,14,180),Rect2(600,1240,150,14),Rect2(900,1180,170,14)]
## 대나무 숲: 시야를 가리고 추격로를 끊는 은신 지대.
const BAMBOO=[Rect2(1620,520,80,260),Rect2(1580,1080,90,240),Rect2(90,560,80,200),Rect2(680,980,80,150),Rect2(1580,240,70,160),Rect2(1180,1160,90,160)]
## 형상 추출(둔갑) 대상 5종. 항아리·나무 상자·등불·고양이·비석.
const OBJECTS=[
 # 마당 서남쪽 항아리 무리
 {"kind":"jar","p":Vector2(646,742)},
 {"kind":"jar","p":Vector2(680,754)},
 {"kind":"crate","p":Vector2(708,798)},
 {"kind":"lantern","p":Vector2(640,808)},
 # 청월당 처마 아래 상자·항아리·등불
 {"kind":"crate","p":Vector2(790,500)},
 {"kind":"crate","p":Vector2(828,512)},
 {"kind":"jar","p":Vector2(862,524)},
 {"kind":"lantern","p":Vector2(748,516)},
 # 서고 문 앞
 {"kind":"crate","p":Vector2(1150,600)},
 {"kind":"jar","p":Vector2(1430,556)},
 {"kind":"lantern","p":Vector2(1206,600)},
 # 별채 문 앞
 {"kind":"jar","p":Vector2(486,1250)},
 {"kind":"crate","p":Vector2(536,1250)},
 # 연못 남쪽 둔갑 군집
 {"kind":"jar","p":Vector2(980,975)},
 {"kind":"jar","p":Vector2(1018,985)},
 {"kind":"stele","p":Vector2(1056,957)},
 {"kind":"lantern","p":Vector2(1130,980)},
 # 동쪽 담장 아래 비석·항아리
 {"kind":"stele","p":Vector2(980,620)},
 {"kind":"stele","p":Vector2(1016,634)},
 {"kind":"jar","p":Vector2(950,646)},
 {"kind":"cat","p":Vector2(1040,662)},
 {"kind":"lantern","p":Vector2(820,800)},
 {"kind":"crate","p":Vector2(432,724)},
 {"kind":"cat","p":Vector2(700,880)},
 # 방 안의 둔갑 사물
 {"kind":"jar","p":Vector2(360,540)},
 {"kind":"crate","p":Vector2(1150,470)}]
const FORMS={
 "jar":{"name":"항아리","radius":7.0,"moving":false,"size":Vector2(20,26)},
 "crate":{"name":"나무 상자","radius":9.0,"moving":false,"size":Vector2(26,24)},
 "lantern":{"name":"등불","radius":7.0,"moving":false,"size":Vector2(22,34)},
 "cat":{"name":"고양이","radius":5.0,"moving":true,"size":Vector2(22,23)},
 "stele":{"name":"비석","radius":10.0,"moving":false,"size":Vector2(26,38)}}
const FURNITURE=[Rect2(190,300,16,150),Rect2(250,430,110,54),Rect2(560,240,46,130),Rect2(300,520,40,36)]
const PATH=[Vector2(560,620),Vector2(560,700),Vector2(760,760),Vector2(860,760)]
## 방 안의 병풍·서안·서가·화로는 대표 한옥(청월당) 실내에만 둔다.
static func _make_buildings() -> Array:
 var out: Array=[]
 for spec in BUILDING_SPECS:
  var door: Vector2=spec.door
  var width: float=float(spec.width)
  var height: float=width*HANOK_ART.y/HANOK_ART.x*.94
  var rect:=Rect2(Vector2(door.x-DOOR_ANCHOR.x*width,door.y-height),Vector2(width,height))
  var interior:=rect.grow(-WALL-10)
  var doors: Dictionary={"front":door,"back":Vector2(door.x,rect.position.y+8)}
  # 그림 속 문(문틀) 위치: 계단 끝(anchor)에서 위로 올라간 지점.
  var painted:=door+Vector2(-.05*width,-.315*height)
  out.append({"id":spec.id,"name":spec.name,"sub":spec.sub,"warmth":spec.warmth,
   "rect":rect,"interior":interior,"doors":doors,"anchor":DOOR_ANCHOR,"art":HANOK_ART,"painted_door":painted})
 return out
static func _make_doors() -> Array:
 var out: Array=[]
 for building in _make_buildings():
  var doors: Dictionary=building.doors
  out.append({"id":String(building.id)+":front","building":String(building.id),"side":"front","center":doors.front,"axis":"x","label":String(building.name)+" 정문"})
  out.append({"id":String(building.id)+":back","building":String(building.id),"side":"back","center":doors.back,"axis":"x","label":String(building.name)+" 뒷문"})
 return out
## 담장·건물 벽. 문이 난 곳은 비워 실제로 걸어 들어간다.
static func _make_hard() -> Array:
 var out: Array=[
  Rect2(60,120,820,14),Rect2(930,120,810,14),
  Rect2(60,120,14,1220),Rect2(1726,120,14,1220)]
 for rect in WALLS:out.append(rect)
 for building in _make_buildings():
  var rect: Rect2=building.rect
  var door: Vector2=(building.doors as Dictionary).front
  var left:=rect.position.x;var right:=rect.end.x
  var top:=rect.position.y;var bottom:=rect.end.y
  var half:=DOOR_WIDTH*.5
  out.append(Rect2(left,top,door.x-half-left,WALL))
  out.append(Rect2(door.x+half,top,right-door.x-half,WALL))
  out.append(Rect2(left,bottom-WALL,door.x-half-left,WALL))
  out.append(Rect2(door.x+half,bottom-WALL,right-door.x-half,WALL))
  out.append(Rect2(left,top,WALL,rect.size.y))
  out.append(Rect2(right-WALL,top,WALL,rect.size.y))
 return out
static func buildings() -> Array:
 return BUILDINGS
## 외관 원화에 그려진 문틀의 월드 좌표(계단 끝에서 위로).
static func painted_door(id: String) -> Vector2:
 var entry:=building(id)
 if entry.is_empty():return Vector2.ZERO
 return entry.painted_door
static func building(id: String) -> Dictionary:
 for entry in BUILDINGS:
  if entry.id==id:return entry
 return {}
static func door(id: String) -> Dictionary:
 for entry in DOORS:
  if entry.id==id:return entry
 return {}
static func building_doors(id: String) -> Array:
 var out: Array=[]
 for entry in DOORS:
  if entry.building==id:out.append(entry)
 return out
static func door_near(p: Vector2,distance: float=62.0) -> String:
 var best:="";var gap:=distance
 for entry in DOORS:
  var d: float=p.distance_to(entry.center)
  if d<gap:gap=d;best=entry.id
 return best
## 지금 서 있는 방(한옥)을 돌려준다. 바깥이면 빈 사전.
static func interior_at(p: Vector2,pad: float=10.0) -> Dictionary:
 for entry in BUILDINGS:
  if (entry.interior as Rect2).grow(pad).has_point(p):return entry
 return {}
static func inside(p: Vector2) -> bool:
 return not interior_at(p).is_empty()
static func object_near(p: Vector2,distance: float=74.0) -> Dictionary:
 var best: Dictionary={};var gap:=distance
 for object in OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best=object
 return best
static func form(kind: String) -> Dictionary:return FORMS.get(kind,{})
static func bridge_axis() -> Vector2:return (BRIDGE_B-BRIDGE_A).normalized()
static func bridge_length() -> float:return BRIDGE_A.distance_to(BRIDGE_B)
## t = 0(남서 입구) .. 1(북동 입구), offset = 다리 중심선에서 옆으로 떨어진 거리.
static func bridge_local(p: Vector2) -> Dictionary:
 var axis:=BRIDGE_B-BRIDGE_A;var length:=axis.length()
 if length<.001:return {"t":0.0,"offset":999.0}
 var rel:=p-BRIDGE_A
 var t:=rel.dot(axis)/(length*length)
 var offset:=absf(rel.cross(axis)/length)
 return {"t":t,"offset":offset}
static func on_bridge(p: Vector2,margin: float=0.0) -> bool:
 var local:=bridge_local(p)
 return local.t>=0.0 and local.t<=1.0 and local.offset<=BRIDGE_HALF-margin
static func bridge_height(t: float) -> float:return sin(clampf(t,0,1)*PI)*BRIDGE_RISE
static func can_stand(p: Vector2,margin: float=9,jumping: bool=false) -> bool:
 if not p.is_finite() or not Rect2(Vector2(60,70),SIZE-Vector2(120,140)).grow(-margin).has_point(p):return false
 if POND.grow(margin).has_point(p) and not on_bridge(p,margin):return false
 for rect in HARD+FURNITURE+BAMBOO:
  if rect.grow(margin).has_point(p):return false
 if not jumping:
  for rect in LOW:
   if rect.grow(margin).has_point(p):return false
 return true
static func safe(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for radius in range(10,180,10):
  for i in range(16):
   var q:=p+Vector2.from_angle(i*TAU/16)*radius
   if can_stand(q):return q
 return SPAWN
static func move(a: Vector2,b: Vector2,jumping: bool=false) -> Vector2:
 var steps:=maxi(1,ceili(a.distance_to(b)/4));var delta: Vector2=(b-a)/steps;var p:=a
 for i in range(steps):
  var next:=p+delta
  if can_stand(next,9,jumping):p=next
  elif can_stand(Vector2(next.x,p.y),9,jumping):p.x=next.x
  elif can_stand(Vector2(p.x,next.y),9,jumping):p.y=next.y
 return p
static func line(a: Vector2,b: Vector2) -> bool:
 var n:=maxi(1,ceili(a.distance_to(b)/8))
 for i in range(n+1):
  var p:=a.lerp(b,float(i)/n)
  for rect in HARD+FURNITURE:
   if rect.has_point(p):return false
 return true
static func elevation(p: Vector2) -> float:
 var local:=bridge_local(p)
 if local.t>=0.0 and local.t<=1.0 and local.offset<=BRIDGE_HALF:return bridge_height(local.t)
 return 0.0
static func surface(p: Vector2) -> String:
 if on_bridge(p):return "wood"
 if not interior_at(p,4).is_empty():return "wood"
 if POND.grow(10).has_point(p):return "water"
 if STONE.has_point(p):return "stone"
 return "grass"
## 하위 호환: 대표 한옥의 외곽/실내/앞문.
static func HANOK() -> Rect2:return (BUILDINGS[0].rect as Rect2)
static func INTERIOR() -> Rect2:return (BUILDINGS[0].interior as Rect2)
static func FRONT_DOOR() -> Vector2:return (BUILDINGS[0].doors as Dictionary).front
