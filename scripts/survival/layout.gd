extends RefCounted
## 조선(내부 id seowon) · 2.5D 인게임 지도.
## 충돌·이동·표고·둔갑 대상이 모두 이 한 곳에서 정의되고,
## 화면(world.gd)은 같은 수치로 그림만 그린다.
##
## 2.0.36 전면 리디자인: 대칭 팔각 마당 구조를 버리고 비대칭 순환 동선으로 다시 지었다.
##   서당 → 서책방 → 대나무 숲길 → 연못 정자 → 약재실 → 장독대 뒤뜰 → (다시 서당)
## 길은 한 방향으로 크게 휘어 돌고, 건물은 서로 다른 크기·방향으로 흩어져 있다.
## 출입 구조물 6채(서당·서책방·청월당·약재실·연못 정자·장독대 뒤뜰)는
## 모두 앞문·뒷문 2개를 갖고, 들어가면 지붕이 자동으로 사라져 꾸며진 실내가 보인다.
const SIZE=Vector2(3400,2600)
const SPAWN=Vector2(1700,1500)
const CAMERA_ZOOM=1.90
const CAMERA_LIFT=36.0
## 시작 배치. 도사는 중앙 마당, 요괴는 남서·북동 외곽에서 시작한다.
const DAOIST_SPAWN_POINTS=[Vector2(1640,1450),Vector2(1745,1535),Vector2(1590,1545),Vector2(1780,1435),Vector2(1670,1360),Vector2(1715,1620)]
const YOKAI_SPAWN_POINTS=[Vector2(320,2350),Vector2(3140,300)]
const SPAWN_SEPARATION=900.0
static var _spawn_cache: Dictionary={}
## 연못: 정자 동쪽의 긴 못. 아치 목교가 가로지른다.
const POND=Rect2(2540,1720,460,300)
const BRIDGE_A=Vector2(2500,2000)
const BRIDGE_B=Vector2(3060,1970)
const BRIDGE_HALF=36.0
const BRIDGE_RISE=27.0
## 중앙 마당: 팔각 문양을 없애고 작은 흙마당만 남긴다(비대칭 동선의 교차점).
const STONE=Rect2(0,0,0,0)
const MEDALLION=Vector2(1700,1500)
const MEDALLION_RADIUS=0.0
const DOOR_ANCHOR=Vector2(.80,.965)
const HANOK_ART=Vector2(760,727)
const WALL=16.0
const DOOR_WIDTH=104.0
## 6채: 서로 다른 크기와 방향으로 흩어진 비대칭 배치. 모두 앞문(남)과 뒷문(북).
const BUILDING_SPECS=[
 {"id":"seodang","name":"서당","sub":"아이들의 글방","door":Vector2(760,980),"width":520.0,"warmth":Color(1,.86,.68)},
 {"id":"seochaek","name":"서책방","sub":"오래된 책의 방","door":Vector2(2680,880),"width":540.0,"warmth":Color(.92,.9,.82)},
 {"id":"cheongwol","name":"청월당","sub":"조선의 큰 강당","door":Vector2(1700,780),"width":600.0,"warmth":Color(1,.88,.7)},
 {"id":"yakjae","name":"약재실","sub":"약초와 탕약","door":Vector2(1050,2180),"width":460.0,"warmth":Color(.96,.9,.74)},
 {"id":"jeongja","name":"연못 정자","sub":"물 위의 쉼터","door":Vector2(2350,2150),"width":450.0,"warmth":Color(.88,.92,1.0)},
 {"id":"jangdok","name":"장독대 뒤뜰","sub":"장맛이 익는 뒤뜰","door":Vector2(520,1600),"width":440.0,"warmth":Color(1,.82,.66)}]
const NAMES=["서당","서책방","청월당","약재실","연못 정자","장독대 뒤뜰"]
static var BUILDINGS: Array=_make_buildings()
static var DOORS: Array=_make_doors()
static var HARD: Array=_make_hard()
## 비대칭 순환 동선. 서당 → 서책방 → 대나무 숲길 → 연못 정자 → 약재실 → 장독대 뒤뜰.
const PATHS=[
 # 서당 남문 → 중앙 마당 → 서책방 남문
 {"w":170.0,"p":[Vector2(760,980),Vector2(1000,1040),Vector2(1350,1120),Vector2(1700,1180),Vector2(2050,1150),Vector2(2300,1080),Vector2(2500,1000),Vector2(2620,930),Vector2(2680,880)]},
 # 서책방 남문 → 동쪽 대나무 숲길 → 연못 정자 남문
 {"w":160.0,"p":[Vector2(2680,880),Vector2(2820,1000),Vector2(2950,1180),Vector2(3050,1400),Vector2(3120,1600),Vector2(3120,1800),Vector2(3060,2000),Vector2(2900,2080),Vector2(2700,2120),Vector2(2500,2140),Vector2(2350,2150)]},
 # 연못 정자 → 약재실
 {"w":160.0,"p":[Vector2(2350,2150),Vector2(2100,2180),Vector2(1800,2130),Vector2(1500,2080),Vector2(1250,2110),Vector2(1180,2150),Vector2(1120,2190),Vector2(1050,2180)]},
 # 약재실 → 장독대 뒤뜰 남문
 {"w":150.0,"p":[Vector2(1050,2180),Vector2(1050,2240),Vector2(900,2260),Vector2(700,2240),Vector2(600,2140),Vector2(560,1980),Vector2(560,1820),Vector2(540,1700),Vector2(520,1600)]},
 # 장독대 뒤뜰 → 서당 남문
 {"w":150.0,"p":[Vector2(520,1600),Vector2(650,1550),Vector2(700,1450),Vector2(720,1350),Vector2(760,1240),Vector2(820,1120),Vector2(820,1020),Vector2(760,980)]},
 # 청월당 진입로(중앙 마당에서 북으로)
 {"w":140.0,"p":[Vector2(1700,1180),Vector2(1700,980),Vector2(1700,860),Vector2(1700,780)]},
 # 장독대 뒤뜰 북문(뒷길)
 {"w":120.0,"p":[Vector2(520,1213),Vector2(520,1150),Vector2(560,1080),Vector2(650,1040),Vector2(760,1000)]},
 # 서책방 북문(뒷길)
 {"w":120.0,"p":[Vector2(2680,403),Vector2(2680,340),Vector2(2500,300),Vector2(2200,300),Vector2(1900,340)]}]
const LOW=[Rect2(1210,1315,120,14),Rect2(1990,1210,120,14),Rect2(1420,1620,110,14),Rect2(2270,1880,100,14)]
## 정원 담장(기와 담장). 순환 동선을 끊지 않도록 안쪽 화단에만 짧게 둔다.
const WALLS=[
 Rect2(1080,1220,220,14),Rect2(1900,1320,240,14),Rect2(1350,1000,14,160),
 Rect2(2450,1200,14,200),Rect2(3000,700,14,180),Rect2(1000,300,180,14),
 Rect2(1900,1900,180,14),Rect2(200,2000,180,14),Rect2(3100,2200,140,14)]
## 대나무 숲길: 동쪽 순환로 안쪽을 따라 길게 이어지는 은신 지대.
const BAMBOO=[
 Rect2(2880,1080,70,180),Rect2(2960,1280,70,160),Rect2(2850,1460,80,180),
 Rect2(2900,1660,70,140),Rect2(1900,300,90,160),Rect2(2050,900,80,150),
 Rect2(1050,1450,80,160),Rect2(1300,1600,90,160),Rect2(2380,960,70,110)]
## 둔갑 사물. 각 장소 앞과 순환로 곳곳에 고르게 둔다.
const OBJECTS=[
 # 서당 앞
 {"kind":"jar","p":Vector2(680,1020)},{"kind":"book_chest","p":Vector2(720,1036)},
 {"kind":"brazier","p":Vector2(860,1010)},{"kind":"bamboo_pot","p":Vector2(900,1026)},
 {"kind":"cat","p":Vector2(600,1080)},
 # 서책방 앞
 {"kind":"jar","p":Vector2(2560,920)},{"kind":"book_chest","p":Vector2(2600,936)},
 {"kind":"brazier","p":Vector2(2780,910)},{"kind":"bamboo_pot","p":Vector2(2820,926)},
 {"kind":"folding_screen","p":Vector2(2450,980)},
 # 청월당 앞
 {"kind":"jar","p":Vector2(1600,820)},{"kind":"book_chest","p":Vector2(1640,836)},
 {"kind":"brazier","p":Vector2(1800,810)},{"kind":"bamboo_pot","p":Vector2(1840,826)},
 # 중앙 마당
 {"kind":"brazier","p":Vector2(1300,1200)},{"kind":"book_chest","p":Vector2(1500,1250)},
 {"kind":"cat","p":Vector2(1700,1300)},{"kind":"jar","p":Vector2(1900,1240)},
 {"kind":"folding_screen","p":Vector2(2100,1180)},{"kind":"brazier","p":Vector2(1250,1400)},
 {"kind":"bamboo_pot","p":Vector2(2150,1420)},{"kind":"cat","p":Vector2(1620,1650)},
 # 대나무 숲길
 {"kind":"jar","p":Vector2(2900,1150)},{"kind":"bamboo_pot","p":Vector2(2950,1350)},
 {"kind":"brazier","p":Vector2(3000,1550)},{"kind":"book_chest","p":Vector2(2950,1750)},
 {"kind":"cat","p":Vector2(2850,1900)},{"kind":"folding_screen","p":Vector2(3020,1900)},
 # 연못 정자
 {"kind":"jar","p":Vector2(2120,2210)},{"kind":"book_chest","p":Vector2(2260,2225)},
 {"kind":"brazier","p":Vector2(2470,2000)},{"kind":"bamboo_pot","p":Vector2(2600,2150)},
 {"kind":"cat","p":Vector2(2700,2000)},
 # 약재실 앞
 {"kind":"jar","p":Vector2(950,2120)},{"kind":"book_chest","p":Vector2(1000,2140)},
 {"kind":"brazier","p":Vector2(1150,2100)},{"kind":"bamboo_pot","p":Vector2(800,2050)},
 {"kind":"folding_screen","p":Vector2(700,1950)},
 # 장독대 뒤뜰
 {"kind":"jar","p":Vector2(500,1500)},{"kind":"jar","p":Vector2(450,1400)},
 {"kind":"bamboo_pot","p":Vector2(600,1300)},{"kind":"book_chest","p":Vector2(400,1250)},
 {"kind":"brazier","p":Vector2(350,1550)},{"kind":"cat","p":Vector2(650,1650)},
 # 뒷길
 {"kind":"jar","p":Vector2(1500,900)},{"kind":"brazier","p":Vector2(2200,340)},
 {"kind":"cat","p":Vector2(2400,340)}]
const FORMS={
 "jar":{"name":"장독 항아리","radius":7.0,"moving":true,"size":Vector2(24,30)},
 "bamboo_pot":{"name":"대나무 화분","radius":8.0,"moving":true,"size":Vector2(26,32)},
 "book_chest":{"name":"책 궤짝","radius":8.0,"moving":true,"size":Vector2(28,24)},
 "brazier":{"name":"화로","radius":7.0,"moving":true,"size":Vector2(24,28)},
 "folding_screen":{"name":"병풍","radius":9.0,"moving":true,"size":Vector2(34,40)},
 "cat":{"name":"고양이","radius":5.0,"moving":true,"size":Vector2(22,23)},
 "dog":{"name":"강아지","radius":7.0,"moving":true,"size":Vector2(30,25)},
 "lantern":{"name":"등불","radius":7.0,"moving":false,"size":Vector2(22,34)},
 "crate":{"name":"나무 상자","radius":9.0,"moving":false,"size":Vector2(26,24)},
 "stele":{"name":"비석","radius":10.0,"moving":false,"size":Vector2(26,38)}}
const FORM_VISUALS={
 "jar":{"height":52.0,"shadow":17.0},
 "bamboo_pot":{"height":54.0,"shadow":16.0},
 "book_chest":{"height":44.0,"shadow":15.0},
 "brazier":{"height":48.0,"shadow":15.0},
 "folding_screen":{"height":64.0,"shadow":18.0},
 "cat":{"height":22.0,"shadow":5.0},
 "dog":{"height":26.0,"shadow":6.0},
 "lantern":{"height":46.0,"shadow":16.0},
 "crate":{"height":46.0,"shadow":16.0},
 "stele":{"height":52.0,"shadow":16.0}}
static func form_visual(kind: String) -> Dictionary:return FORM_VISUALS.get(kind,FORM_VISUALS.jar)
## 기력 회복 구슬(영혼불): 순환 동선을 따라 배치한다.
const ORBS=[Vector2(900,1040),Vector2(1200,1100),Vector2(1550,1160),Vector2(1900,1150),
 Vector2(2200,1100),Vector2(2500,990),Vector2(2850,1060),Vector2(2980,1220),Vector2(3090,1450),
 Vector2(3120,1700),Vector2(3060,1980),Vector2(2850,2070),Vector2(2600,2120),Vector2(2200,2150),
 Vector2(1800,2120),Vector2(1450,2080),Vector2(1150,2140),Vector2(1000,2260),Vector2(750,2240),
 Vector2(580,2050),Vector2(550,1850),Vector2(600,1620),Vector2(700,1450),Vector2(790,1220),
 Vector2(820,1040),Vector2(1450,1350),Vector2(1950,1500),Vector2(1450,1750),Vector2(2200,1750),
 Vector2(1700,900)]
const ORB_RADIUS=20.0
const ORB_RESPAWN=14.0
## 청월당 실내 가구.
const FURNITURE=[Rect2(1280,330,130,46),Rect2(1450,330,120,40),Rect2(1280,560,46,140),Rect2(1620,560,40,130)]
const PATH=[Vector2(760,980),Vector2(1000,1040),Vector2(1350,1120)]
static func _make_buildings() -> Array:
 var out: Array=[]
 for spec in BUILDING_SPECS:
  var door: Vector2=spec.door
  var width: float=float(spec.width)
  var height: float=width*HANOK_ART.y/HANOK_ART.x*.94
  var rect:=Rect2(Vector2(door.x-DOOR_ANCHOR.x*width,door.y-height),Vector2(width,height))
  var interior:=rect.grow(-WALL-10)
  var doors: Dictionary={"front":door,"back":Vector2(door.x,rect.position.y+8)}
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
static func _make_hard() -> Array:
 var out: Array=[
  Rect2(80,110,1460,14),Rect2(1760,110,1540,14),
  Rect2(80,110,14,2400),Rect2(3306,110,14,2400),
  Rect2(80,2480,1460,14),Rect2(1760,2480,1540,14)]
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
static func buildings() -> Array:return BUILDINGS
static func painted_door(id: String) -> Vector2:
 var entry:=building(id)
 return entry.painted_door if not entry.is_empty() else Vector2.ZERO
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
static func interior_at(p: Vector2,pad: float=10.0) -> Dictionary:
 for entry in BUILDINGS:
  if (entry.interior as Rect2).grow(pad).has_point(p):return entry
 return {}
static func inside(p: Vector2) -> bool:return not interior_at(p).is_empty()
static func object_near(p: Vector2,distance: float=74.0) -> Dictionary:
 var best: Dictionary={};var gap:=distance
 for object in OBJECTS:
  var d: float=p.distance_to(object.p)
  if d<gap:gap=d;best=object
 return best
static func form(kind: String) -> Dictionary:return FORMS.get(kind,{})
static func bridge_axis() -> Vector2:return (BRIDGE_B-BRIDGE_A).normalized()
static func bridge_length() -> float:return BRIDGE_A.distance_to(BRIDGE_B)
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
 if not p.is_finite() or not Rect2(Vector2(94,124),Vector2(3212,2356)).grow(-margin).has_point(p):return false
 if POND.grow(margin).has_point(p) and not on_bridge(p,margin):return false
 for rect in HARD+FURNITURE+BAMBOO:
  if rect.grow(margin).has_point(p):return false
 if not jumping:
  for rect in LOW:
   if rect.grow(margin).has_point(p):return false
 return true
static func safe(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for radius in range(10,220,10):
  for i in range(16):
   var q:=p+Vector2.from_angle(i*TAU/16)*radius
   if can_stand(q):return q
 return SPAWN
static func _settle(candidates: Array,keep: Array=[]) -> Array:
 var out: Array=[]
 for candidate in candidates:
  var spot:=safe(candidate)
  for attempt in range(24):
   var clear:=true
   for other in out+keep:
    if spot.distance_to(other)<46:clear=false;break
   if clear:break
   spot=safe(spot+Vector2.from_angle(attempt*TAU/16+0.4)*(28.0+attempt*6.0))
  out.append(spot)
 return out
static func daoist_spawns() -> Array:
 if not _spawn_cache.has("daoist"):_spawn_cache["daoist"]=_settle(DAOIST_SPAWN_POINTS)
 return _spawn_cache["daoist"]
static func yokai_spawns() -> Array:
 if not _spawn_cache.has("yokai"):
  var daoists:=daoist_spawns()
  var out: Array=[]
  for candidate in YOKAI_SPAWN_POINTS:
   var spot:=safe(candidate)
   for attempt in range(40):
    var near:=false
    for daoist in daoists:
     if spot.distance_to(daoist)<SPAWN_SEPARATION:near=true;break
    if not near:break
    var away: Vector2=spot-SPAWN
    if away.length()<1.0:away=Vector2(1,0)
    spot=safe(spot+away.normalized()*(40.0+attempt*10.0))
   out.append(spot)
  _spawn_cache["yokai"]=_settle(out,daoists)
 return _spawn_cache["yokai"]
static func spawns_for(role: String,index: int) -> Vector2:
 var spots: Array=daoist_spawns() if role=="daoist" else yokai_spawns()
 if spots.is_empty():return safe(SPAWN)
 return spots[posmod(index,spots.size())]
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
static func path_gap(p: Vector2) -> float:
 var best:=1e9
 for path in PATHS:
  var half: float=float(path["w"])*.5
  var pts: Array=path["p"]
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var ab:=b-a
   var length_sq:=ab.length_squared()
   var t: float=0.0
   if length_sq>.0001:t=clampf((p-a).dot(ab)/length_sq,0.0,1.0)
   best=minf(best,p.distance_to(a+ab*t)-half)
 return best
static func surface(p: Vector2) -> String:
 if on_bridge(p):return "wood"
 if not interior_at(p,4).is_empty():return "wood"
 if POND.grow(10).has_point(p):return "water"
 if STONE.has_point(p):return "stone"
 return "grass"
static func HANOK() -> Rect2:return (BUILDINGS[0].rect as Rect2)
static func INTERIOR() -> Rect2:return (BUILDINGS[0].interior as Rect2)
static func FRONT_DOOR() -> Vector2:return (BUILDINGS[0].doors as Dictionary).front

## ---------------------------------------------------------------- 맵 공용 API
const MAP_ID="seowon"
const NAME="조선"
const CIRCLE_CENTER_START=Vector2(1700,1300)
const CIRCLE_CENTER_FINAL=Vector2(1700,1450)
const CIRCLE_RADII=[2140.0,1750.0,1150.0,620.0]
const CIRCLE_DUE=[180.0,360.0,480.0,600.0]
## 비대칭 동선의 일곱 장소(미니맵 구역 이름).
const ZONES=[
 {"id":"seodang","name":"서당","rect":Rect2(150,250,950,800),"accent":Color("e8c98b")},
 {"id":"seochaek","name":"서책방","rect":Rect2(2150,250,1050,800),"accent":Color("cfd8ff")},
 {"id":"madang","name":"중앙 마당","rect":Rect2(1100,830,1000,850),"accent":Color("ffe0a8")},
 {"id":"bamboo","name":"대나무 숲길","rect":Rect2(2700,1050,550,760),"accent":Color("9fe0b0")},
 {"id":"jeongja","name":"연못 정자","rect":Rect2(1900,1600,795,700),"accent":Color("8fd8ff")},
 {"id":"yakjae","name":"약재실","rect":Rect2(400,1650,900,700),"accent":Color("ffcf9a")},
 {"id":"jangdok","name":"장독대 뒤뜰","rect":Rect2(100,1000,650,660),"accent":Color("ffb46b")}]
static func map_id() -> String:return MAP_ID
static func map_name() -> String:return NAME
static func has_interiors() -> bool:return true
static func zones() -> Array:return ZONES
static func zone(id: String) -> Dictionary:
 for entry in ZONES:
  if String(entry.id)==id:return entry
 return {}
static func zone_at(p: Vector2) -> Dictionary:
 for entry in ZONES:
  if (entry.rect as Rect2).has_point(p):return entry
 return {}
static func zone_name_at(p: Vector2) -> String:
 var entry:=zone_at(p)
 return String(entry.get("name",NAME))
static func zone_rect(id: String) -> Rect2:
 var entry:=zone(id)
 return entry.rect if not entry.is_empty() else Rect2()
## 2.0.36 기믹은 핵심 3개만: 석등(암전) · 연못 물안개 · 장독대 방울(소음).
const GIMMICKS=[
 {"id":"lantern_seodang","kind":"light","zone":"seodang","pos":Vector2(900,1000),"label":"석등","hint":"도사는 끄고, 요괴는 다시 켭니다"},
 {"id":"pond_mist","kind":"mist","zone":"jeongja","pos":Vector2(2500,1720),"radius":250.0,"label":"연못 물안개","hint":"5초 동안 연못가 시야가 흐려집니다"},
 {"id":"jangdok_bell","kind":"bell","zone":"jangdok","pos":Vector2(500,1500),"label":"장독대 방울","hint":"눌러서 소음으로 요괴를 유인합니다"}]
static func gimmicks() -> Array:return GIMMICKS
static func circle_radii() -> Array:return CIRCLE_RADII
static func circle_due() -> Array:return CIRCLE_DUE
static func circle_center_start() -> Vector2:return CIRCLE_CENTER_START
static func circle_final_center() -> Vector2:return CIRCLE_CENTER_FINAL if can_stand(CIRCLE_CENTER_FINAL,12) else safe(CIRCLE_CENTER_FINAL)
static func corner_radius() -> float:return Vector2(SIZE.x*.5,SIZE.y*.5).length()
static func walker_routes() -> Array:
 return [
  {"kind":"cat","speed":31.0,"path":[Vector2(900,1040),Vector2(1200,1120),Vector2(1550,1180),Vector2(1900,1160),Vector2(2200,1100),Vector2(2350,1200),Vector2(2050,1350),Vector2(1700,1400),Vector2(1300,1320),Vector2(1000,1200)]},
  {"kind":"dog","speed":42.0,"path":[Vector2(1150,2140),Vector2(1500,2080),Vector2(1800,2130),Vector2(2100,2180),Vector2(2350,2150),Vector2(2280,2000),Vector2(2000,1950),Vector2(1700,1900),Vector2(1400,1950),Vector2(1200,2020)]},
  {"kind":"cat","speed":31.0,"path":[Vector2(2820,1000),Vector2(2950,1180),Vector2(3050,1400),Vector2(3120,1600),Vector2(3120,1800),Vector2(3060,2000),Vector2(2900,2080),Vector2(2700,2120)]},
  {"kind":"dog","speed":42.0,"path":[Vector2(650,1550),Vector2(700,1450),Vector2(720,1350),Vector2(760,1240),Vector2(820,1120),Vector2(820,1020),Vector2(760,980),Vector2(680,1040)]}]
