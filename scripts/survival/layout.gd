extends RefCounted
## 월하의 서원 · 2.5D 인게임 지도.
## 충돌·이동·표고·둔갑 대상이 모두 이 한 곳에서 정의되고,
## 화면(world.gd)은 같은 수치로 그림만 그린다.
##
## 출입 한옥은 외관 원화(hanok_exterior.png)의 문 위치(DOOR_ANCHOR)에서
## 외곽·실내·충돌·문 좌표를 역산한다. 그래서 문 앞에 서면 그림의 문과
## 충돌 문이 정확히 같은 자리이고, 건물을 키워도 어긋나지 않는다.
##
## 2.0.26: 《도망가 친구들》처럼 넓게 돌며 따돌리는 추격전을 위해
## 1800x1400 → 3400x2600(면적 약 3.5배)으로 확장했다.
## 2.0.26 비주얼 개편: 목표 시안처럼 순환 돌길(외곽 링)·중앙 팔각 마당·
## 건물 앞 흙마당·달빛 잔디 구획을 PATHS 한 목록으로 정의하고,
## 바닥 원화(tools/bake_seowon_ground.py)가 이 중심선을 따라 판석을 깐다.
const SIZE=Vector2(3400,2600)
const SPAWN=Vector2(1700,1420)
## 인게임 기본 시점(2.5D 줌). 카메라는 내 캐릭터를 화면 중앙보다 아래에 둔다.
## 2.0.23 사용자 피드백("좀 더 가까워야지 어몽어스처럼"): 20:9 와이드에서
## 캐릭터·한옥·동료가 큼직하고 밀도 있게 보이도록 1.68 → 1.90으로 더 당긴다.
const CAMERA_ZOOM=1.90
const CAMERA_LIFT=36.0
## 시작 배치. 도사는 중앙 마당 6곳, 요괴는 서북·동남 외곽 2곳에서 시작한다.
const DAOIST_SPAWN_POINTS=[Vector2(1650,1260),Vector2(1755,1345),Vector2(1600,1355),Vector2(1790,1245),Vector2(1680,1170),Vector2(1725,1430)]
const YOKAI_SPAWN_POINTS=[Vector2(320,320),Vector2(3120,2340)]
## 외곽 스폰이 구조물에 걸리더라도 도사 무리와 이만큼은 떨어지게 잡는다.
const SPAWN_SEPARATION=900.0
static var _spawn_cache: Dictionary={}
const POND=Rect2(2520,1180,460,320)
## 연못을 비스듬히 가로지르는 아치 목교. 걸어서 오르면 표고가 오른다.
const BRIDGE_A=Vector2(2490,1340)
const BRIDGE_B=Vector2(2830,1120)
const BRIDGE_HALF=36.0
const BRIDGE_RISE=27.0
## 중앙 팔각 마당(돌마당). MEDALLION을 가운데 두고 여덟 변으로 길이 이어진다.
const STONE=Rect2(1340,940,720,720)
const MEDALLION=Vector2(1700,1300)
const MEDALLION_RADIUS=210.0
## hanok_exterior.png 안에서 문(계단 끝, 걸어 들어가는 지점)이 있는 비율.
const DOOR_ANCHOR=Vector2(.80,.965)
const HANOK_ART=Vector2(760,727)
const WALL=16.0
const DOOR_WIDTH=104.0
## 출입 한옥 6채: 청월당·서고·서당·별채·약방·행랑채.
## 모두 바깥 담장을 등지고 마당 쪽으로 문을 낸다.
const BUILDING_SPECS=[
 {"id":"cheongwol","name":"청월당","sub":"서원의 큰 강당","door":Vector2(640,1000),"width":640.0,"warmth":Color(1,.86,.68)},
 {"id":"seogo","name":"서고","sub":"오래된 책의 방","door":Vector2(2280,720),"width":500.0,"warmth":Color(.9,.9,.8)},
 {"id":"byeolchae","name":"별채","sub":"손님의 방","door":Vector2(700,1660),"width":520.0,"warmth":Color(1,.82,.72)},
 {"id":"gaeksa","name":"행랑채","sub":"먼 길손의 숙소","door":Vector2(3000,2180),"width":500.0,"warmth":Color(1,.88,.7)},
 {"id":"yakbang","name":"약방","sub":"약초와 탕약","door":Vector2(1400,2220),"width":460.0,"warmth":Color(.96,.9,.74)},
 {"id":"seodang","name":"서당","sub":"아이들의 글방","door":Vector2(2900,920),"width":460.0,"warmth":Color(1,.84,.68)}]
const NAMES=["청월당","서고","별채","행랑채","약방","서당"]
static var BUILDINGS: Array=_make_buildings()
static var DOORS: Array=_make_doors()
static var HARD: Array=_make_hard()
## 바닥 원화가 따라 까는 돌길 중심선. w=길 폭, p=점 목록(부드럽게 잇는다).
## 외곽 순환 골목 → 중앙 대로(북문~남문) → 마당에서 뻗는 지름길·건물 진입로.
const PATHS=[
 {"w":170.0,"p":[Vector2(700,1070),Vector2(900,980),Vector2(1150,905),Vector2(1450,835),Vector2(1700,800),Vector2(1980,810),Vector2(2250,845),Vector2(2450,950),Vector2(2620,1000),Vector2(2780,1010),Vector2(2960,1010),Vector2(3110,1080),Vector2(3170,1200),Vector2(3170,1450),Vector2(3170,1700),Vector2(3140,1950),Vector2(3080,2170),Vector2(2900,2280),Vector2(2600,2330),Vector2(2250,2345),Vector2(1900,2350),Vector2(1600,2345),Vector2(1350,2330),Vector2(1100,2300),Vector2(960,2230),Vector2(890,2080),Vector2(880,1850),Vector2(875,1600),Vector2(875,1350),Vector2(830,1200),Vector2(760,1120),Vector2(700,1070)]},
 {"w":190.0,"p":[Vector2(1650,130),Vector2(1650,400),Vector2(1655,700),Vector2(1670,1000),Vector2(1700,1300),Vector2(1680,1600),Vector2(1660,1900),Vector2(1650,2150),Vector2(1650,2400),Vector2(1645,2480)]},
 {"w":160.0,"p":[Vector2(2050,1300),Vector2(2200,1325),Vector2(2400,1338),Vector2(2490,1340)]},
 {"w":150.0,"p":[Vector2(2830,1120),Vector2(2900,1080),Vector2(2960,1010)]},
 {"w":150.0,"p":[Vector2(1340,1300),Vector2(1180,1290),Vector2(1000,1270),Vector2(880,1260)]},
 {"w":130.0,"p":[Vector2(760,1120),Vector2(660,1010)]},
 {"w":130.0,"p":[Vector2(2250,845),Vector2(2280,760)]},
 {"w":130.0,"p":[Vector2(2790,1010),Vector2(2880,940)]},
 {"w":130.0,"p":[Vector2(875,1650),Vector2(770,1660)]},
 {"w":130.0,"p":[Vector2(1330,2320),Vector2(1385,2245)]},
 {"w":120.0,"p":[Vector2(3070,2170),Vector2(3010,2180)]}]
## 뛰어넘을 수 있는 낮은 담·평상. 반드시 바닥에 '돌 던틱'으로 그려 보이게 한다(world.build_low).
## 그림자와 높이 차가 있는 돌 평상이라 '막힌 곳'임이 한눈에 보인다.
const LOW=[Rect2(1210,1715,140,14),Rect2(2205,1715,130,14),Rect2(1470,720,120,14),Rect2(940,720,120,14),Rect2(1150,1000,130,14)]
## 정원 담장(기와 담장). 길을 막지 않도록 화단 안쪽에만 짧게 둔다.
## 충돌은 HARD에 포함되고, 그림은 이 목록을 쓴다.
const WALLS=[
 Rect2(1040,700,300,14),Rect2(2400,300,14,300),Rect2(2760,200,280,14),
 Rect2(150,1740,14,220),Rect2(1050,1450,14,200),Rect2(2150,950,14,200),
 Rect2(520,2130,240,14),Rect2(1180,560,240,14),Rect2(3150,600,14,220),
 Rect2(2140,1700,260,14),Rect2(2980,2380,240,14)]
## 대나무 숲: 시야를 가리고 추격로를 끊는 은신 지대.
const BAMBOO=[Rect2(1000,250,90,240),Rect2(1160,180,90,200),Rect2(2420,180,90,200),Rect2(3050,300,90,220),Rect2(960,760,80,170),Rect2(150,1450,80,160),Rect2(400,2200,90,190),Rect2(2000,1950,90,200),Rect2(2700,1540,80,160),Rect2(2850,300,80,170)]
## 형상 추출(둔갑) 대상 5종. 항아리·나무 상자·등불·고양이·비석.
## 문 앞·길가·골목마다 고르게 두어 어디서든 숨을 수 있게 한다.
const OBJECTS=[
 # 청월당 문 앞
 {"kind":"jar","p":Vector2(490,1030)},{"kind":"crate","p":Vector2(530,1046)},
 {"kind":"lantern","p":Vector2(760,1026)},{"kind":"jar","p":Vector2(805,1040)},
 # 서고 문 앞
 {"kind":"jar","p":Vector2(2130,750)},{"kind":"crate","p":Vector2(2170,766)},
 {"kind":"lantern","p":Vector2(2400,746)},{"kind":"jar","p":Vector2(2445,760)},
 # 별채 문 앞
 {"kind":"jar","p":Vector2(550,1690)},{"kind":"crate","p":Vector2(590,1706)},
 {"kind":"lantern","p":Vector2(820,1686)},{"kind":"jar","p":Vector2(865,1700)},
 # 행랑채 문 앞
 {"kind":"jar","p":Vector2(2850,2210)},{"kind":"crate","p":Vector2(2890,2226)},
 {"kind":"lantern","p":Vector2(3120,2206)},{"kind":"jar","p":Vector2(3165,2220)},
 # 약방 문 앞
 {"kind":"jar","p":Vector2(1250,2250)},{"kind":"crate","p":Vector2(1290,2266)},
 {"kind":"lantern","p":Vector2(1520,2246)},{"kind":"jar","p":Vector2(1565,2260)},
 # 서당 문 앞
 {"kind":"jar","p":Vector2(2750,950)},{"kind":"crate","p":Vector2(2790,966)},
 {"kind":"lantern","p":Vector2(3020,946)},{"kind":"jar","p":Vector2(3065,960)},
 # 순환 골목 길가
 {"kind":"jar","p":Vector2(940,831)},{"kind":"crate","p":Vector2(1298,1005)},
 {"kind":"lantern","p":Vector2(1545,689)},{"kind":"cat","p":Vector2(2401,1071)},
 {"kind":"lantern","p":Vector2(3039,1297)},{"kind":"stele","p":Vector2(3039,1603)},
 {"kind":"cat","p":Vector2(3275,1925)},{"kind":"jar","p":Vector2(2984,2075)},
 {"kind":"crate","p":Vector2(2795,2430)},{"kind":"lantern","p":Vector2(2464,2205)},
 {"kind":"stele","p":Vector2(2167,2215)},{"kind":"cat","p":Vector2(1870,2218)},
 {"kind":"lantern","p":Vector2(909,2351)},{"kind":"stele","p":Vector2(1015,1943)},
 {"kind":"cat","p":Vector2(1007,1646)},{"kind":"jar","p":Vector2(998,1304)},
 {"kind":"lantern","p":Vector2(1792,430)},{"kind":"lantern","p":Vector2(1518,1927)},
 {"kind":"cat","p":Vector2(2360,1209)},
 # 북쪽 화단(테스트가 찾는 자리)
 {"kind":"jar","p":Vector2(1430,556)}]
const FORMS={
 "jar":{"name":"항아리","radius":7.0,"moving":false,"size":Vector2(20,26)},
 "crate":{"name":"나무 상자","radius":9.0,"moving":false,"size":Vector2(26,24)},
 "lantern":{"name":"등불","radius":7.0,"moving":false,"size":Vector2(22,34)},
 "cat":{"name":"고양이","radius":5.0,"moving":true,"size":Vector2(22,23)},
 "dog":{"name":"강아지","radius":7.0,"moving":true,"size":Vector2(30,25)},
 "stele":{"name":"비석","radius":10.0,"moving":false,"size":Vector2(26,38)}}
## 둔갑 사물의 월드 크기(스프라이트 높이·발밑 그림자). world의 사물 그림과
## actor의 둔갑 그림이 이 한 값만 보므로, 둔갑하면 같은 사물과 100% 같은 크기가 된다.
const FORM_VISUALS={
 "jar":{"height":46.0,"shadow":16.0},
 "crate":{"height":46.0,"shadow":16.0},
 "lantern":{"height":46.0,"shadow":16.0},
 "cat":{"height":22.0,"shadow":5.0},
 "dog":{"height":26.0,"shadow":6.0},
 "stele":{"height":52.0,"shadow":16.0}}
static func form_visual(kind: String) -> Dictionary:return FORM_VISUALS.get(kind,FORM_VISUALS.jar)
## 기력 회복 구슬(영혼불): 스쳐 지나가면 달리기 기력이 가득 차고 잠시 뒤 다시 생긴다.
## 순환 골목·마당·외곽 길목에 두어 끊임없이 달릴 수 있게 한다.
const ORBS=[Vector2(1071,840),Vector2(1518,911),Vector2(1929,893),Vector2(2303,969),Vector2(2743,1093),Vector2(3056,1163),Vector2(3255,1539),Vector2(3056,1935),Vector2(2951,2348),Vector2(2482,2250),Vector2(2064,2433),Vector2(1642,2261),Vector2(1211,2399),Vector2(974,2059),Vector2(791,1674),Vector2(928,1231),Vector2(1558,556),Vector2(1788,1404),Vector2(1571,1813),Vector2(2475,1260)]
const ORB_RADIUS=20.0
## 구슬 하나를 먹은 뒤 다시 생기는 시간(초).
const ORB_RESPAWN=14.0
const FURNITURE=[Rect2(190,470,16,150),Rect2(240,560,110,54),Rect2(560,430,46,130),Rect2(300,650,40,36)]
const PATH=[Vector2(640,1010),Vector2(780,1090),Vector2(1100,1200),Vector2(1400,1290)]
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
  # 그림 속 문(문틀) 위치: 계단 끝(anchor)에서 위로 올라간 점.
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
 # 경계는 눈에 보이는 담장 '안쪽 모서리'와 정확히 맞춘다(담 뒤 막다른 틘을 없앤다).
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
## 서로 겹치지 않게 주어진 지점을 안전한 자리로 옮긴다(앞 지점과 46px 이상).
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
## 도사 6명 시작 지점(중앙 마당 안전 지대).
static func daoist_spawns() -> Array:
 if not _spawn_cache.has("daoist"):_spawn_cache["daoist"]=_settle(DAOIST_SPAWN_POINTS)
 return _spawn_cache["daoist"]
## 요괴 시작 지점(도사 무리와 SPAWN_SEPARATION 이상 떨어진 서북·동남 외곽).
static func yokai_spawns() -> Array:
 if not _spawn_cache.has("yokai"):
  var daoists:=daoist_spawns()
  var out: Array=[]
  for candidate in YOKAI_SPAWN_POINTS:
   var spot:=safe(candidate)
   # 안전 지대로 당겨져 도사와 너무 가까워지면 지도 바깥쪽으로 다시 밀어낸다.
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
## 팀별 시작 지점(순환 배치). 요괴가 2명을 넘는 특수 설정도 같은 목록을 돌려 쓴다.
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
## 길 중심선까지의 거리에서 길 반폭을 뺀 값. 음수면 길 위(가장자리 안쪽)다.
## 바닥 원화·잔디 장식이 같은 길 수치를 보므로 그림과 이동이 어긋나지 않는다.
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
## 하위 호환: 대표 한옥의 외곽/실내/앞문.
static func HANOK() -> Rect2:return (BUILDINGS[0].rect as Rect2)
static func INTERIOR() -> Rect2:return (BUILDINGS[0].interior as Rect2)
static func FRONT_DOOR() -> Vector2:return (BUILDINGS[0].doors as Dictionary).front
