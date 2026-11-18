extends RefCounted
## 월하의 서원 · 2.5D 인게임 지도.
## 충돌·이동·표고·둔갑 대상이 모두 이 한 곳에서 정의되고,
## 화면(world.gd)은 같은 수치로 그림만 그린다.
const SIZE=Vector2(1800,1400)
const SPAWN=Vector2(860,720)
const POND=Rect2(950,680,300,230)
## 출입 가능한 한옥(청월당). 안쪽 바닥 254..586 x 274..566.
const HANOK=Rect2(240,260,360,320)
const INTERIOR=Rect2(254,274,332,292)
const NAMES=["청월당","강학당","학사동"]
## 연못을 비스듬히 가로지르는 아치 목교. 걸어서 오르면 표고가 오른다.
const BRIDGE_A=Vector2(885,965)
const BRIDGE_B=Vector2(1175,655)
const BRIDGE_HALF=36.0
const BRIDGE_RISE=27.0
## 담장·건물 벽. 문이 난 곳은 비워 실제로 걸어 들어간다.
const HARD=[
 Rect2(240,260,160,14),Rect2(470,260,130,14),
 Rect2(240,566,160,14),Rect2(470,566,130,14),
 Rect2(240,274,14,292),Rect2(586,274,14,292),
 Rect2(720,370,300,110),
 Rect2(210,1020,330,118),
 Rect2(60,120,820,14),Rect2(930,120,810,14),
 Rect2(60,120,14,1260),Rect2(1726,120,14,1260),
 Rect2(640,640,14,150),Rect2(654,640,150,14),
 Rect2(1040,470,14,150),Rect2(880,560,174,14),
 Rect2(1080,566,130,14),
 Rect2(1300,470,14,190),
 Rect2(360,900,180,14),Rect2(540,914,14,140),
 Rect2(1264,860,132,66)]
## 방 안의 병풍·서안·서가·화로. 문 사이 통로는 넉넉히 남긴다.
const FURNITURE=[Rect2(276,300,16,122),Rect2(432,376,96,50),Rect2(540,468,42,88),Rect2(300,486,36,32)]
## 뛰어넘을 수 있는 낮은 담·평상.
const LOW=[Rect2(640,560,140,14),Rect2(470,640,120,14),Rect2(660,1060,160,14),Rect2(900,520,120,14)]
## 마당을 나누는 기와 담장(충돌은 HARD에 포함, 그림은 이 목록을 쓴다).
const WALLS=[Rect2(640,640,14,150),Rect2(654,640,150,14),Rect2(1040,470,14,150),Rect2(880,560,174,14),Rect2(1080,566,130,14),Rect2(1300,470,14,190),Rect2(360,900,180,14),Rect2(540,914,14,140),Rect2(1264,860,132,66)]
## 대나무 숲: 시야를 가리고 추격로를 끊는 은신 지대.
const BAMBOO=[Rect2(1620,520,80,260),Rect2(1580,1080,90,240),Rect2(90,640,80,280),Rect2(680,980,80,150),Rect2(1450,380,70,160),Rect2(1180,1160,90,160)]
## 형상 추출(둔갑) 대상 5종. 항아리·나무 상자·등불·고양이·비석.
const OBJECTS=[
 # 마당 서남쪽 항아리 무리
 {"kind":"jar","p":Vector2(560,780)},
 {"kind":"jar","p":Vector2(598,792)},
 {"kind":"crate","p":Vector2(620,832)},
 {"kind":"lantern","p":Vector2(540,842)},
 # 강학당 처마 아래 상자·항아리·등불
 {"kind":"crate","p":Vector2(790,500)},
 {"kind":"crate","p":Vector2(828,512)},
 {"kind":"jar","p":Vector2(862,524)},
 {"kind":"lantern","p":Vector2(748,516)},
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
 {"kind":"crate","p":Vector2(420,700)},
 {"kind":"cat","p":Vector2(700,880)}]
const FORMS={
 "jar":{"name":"항아리","radius":7.0,"moving":false,"size":Vector2(20,26)},
 "crate":{"name":"나무 상자","radius":9.0,"moving":false,"size":Vector2(26,24)},
 "lantern":{"name":"등불","radius":7.0,"moving":false,"size":Vector2(22,34)},
 "cat":{"name":"고양이","radius":5.0,"moving":true,"size":Vector2(22,23)},
 "stele":{"name":"비석","radius":10.0,"moving":false,"size":Vector2(26,38)}}
const DOORS=[
 {"id":"front","center":Vector2(435,573),"axis":"x"},
 {"id":"back","center":Vector2(435,267),"axis":"x"}]
const STONE=Rect2(600,520,520,520)
const PATH=[Vector2(435,573),Vector2(435,760),Vector2(760,760),Vector2(860,720)]
static func door(id: String) -> Dictionary:
 for entry in DOORS:
  if entry.id==id:return entry
 return {}
static func door_near(p: Vector2,distance: float=62.0) -> String:
 var best:="";var gap:=distance
 for entry in DOORS:
  var d: float=p.distance_to(entry.center)
  if d<gap:gap=d;best=entry.id
 return best
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
 if INTERIOR.has_point(p) or HANOK.grow(4).has_point(p):return "wood"
 if POND.grow(10).has_point(p):return "water"
 if STONE.has_point(p):return "stone"
 return "grass"
