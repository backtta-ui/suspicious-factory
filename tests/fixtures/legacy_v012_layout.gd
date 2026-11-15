extends RefCounted
const MAP_ID := "gyewol_village"
const SIZE := Vector2(1800,960)
const SPAWN := Vector2(900,610)
static var BOUNDS := PackedVector2Array([Vector2(68,480),Vector2(900,64),Vector2(1732,480),Vector2(900,896)])
const PROPS := [
	{"kind":"hanok","position":Vector2(710,350)},
	{"kind":"hanok","position":Vector2(1110,380)},
	{"kind":"hanok","position":Vector2(650,610)},
	{"kind":"hanok","position":Vector2(1210,640)},
	{"kind":"market","position":Vector2(1050,560)},
	{"kind":"well","position":Vector2(860,510)},
	{"kind":"lantern","position":Vector2(780,470)},
	{"kind":"lantern","position":Vector2(1030,450)},
	{"kind":"lantern","position":Vector2(900,700)},
	{"kind":"lantern","position":Vector2(1160,550)},
	{"kind":"lantern","position":Vector2(700,510)},
	{"kind":"tree","position":Vector2(900,180)},
	{"kind":"tree","position":Vector2(820,230)},
	{"kind":"tree","position":Vector2(1270,340)},
	{"kind":"tree","position":Vector2(1360,420)},
	{"kind":"tree","position":Vector2(1470,510)},
	{"kind":"tree","position":Vector2(1320,670)},
	{"kind":"tree","position":Vector2(1050,790)},
	{"kind":"tree","position":Vector2(760,780)},
	{"kind":"tree","position":Vector2(500,650)},
	{"kind":"tree","position":Vector2(380,510)},
	{"kind":"tree","position":Vector2(510,380)},
	{"kind":"tree","position":Vector2(600,330)}
]
const NPCS := [
	{"id":"herbalist","name":"약초꾼 서연","position":Vector2(950,535),"tint":Color(0.8,1.0,0.94),"lines":["낯선 도사님이시군요. 계월촌에 오신 걸 환영해요.","오른쪽 도술을 쓰면 항아리로 둔갑할 수 있어요. 움직임이 느려지니 조심하세요.","달빛 아래 우물에는 오래된 이야기가 잠들어 있답니다."]},
	{"id":"merchant","name":"장돌뱅이 만복","position":Vector2(1085,620),"tint":Color(1.0,0.9,0.78),"lines":["전우치? 그 소문난 도사가 자네인가!", "이 장터엔 세상에 없는 물건도 있다네. 오늘은 구경만 하시게."]},
	{"id":"elder","name":"마을 어른","position":Vector2(770,570),"tint":Color(0.84,0.91,1.0),"lines":["빛이 기울면 마을의 다른 얼굴이 드러나지.","도술은 숨는 재주이기도 하지만, 세상을 새롭게 보는 눈이기도 하네."]}
]
static func footprint(kind: String) -> PackedVector2Array:
	if kind=="hanok": return PackedVector2Array([Vector2(-64,-20),Vector2(0,-52),Vector2(64,-20),Vector2(0,12)])
	if kind=="market": return PackedVector2Array([Vector2(-44,-12),Vector2(0,-32),Vector2(44,-12),Vector2(0,8)])
	return PackedVector2Array()
static func radius(kind: String) -> float:
	if kind=="well": return 18
	if kind=="tree": return 9
	return 5
static func can_stand(p: Vector2, margin: float = 6) -> bool:
	if not is_finite(p.x) or not is_finite(p.y): return false
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not Geometry2D.is_point_in_polygon(p+offset*margin,BOUNDS): return false
	for prop in PROPS:
		var polygon := footprint(prop.kind)
		if polygon.is_empty():
			if p.distance_to(prop.position)<radius(prop.kind)+margin: return false
		else:
			var local: Vector2 = p-prop.position
			if Geometry2D.is_point_in_polygon(local,polygon): return false
			for i in range(polygon.size()):
				if local.distance_to(Geometry2D.get_closest_point_to_segment(local,polygon[i],polygon[(i+1)%polygon.size()]))<margin: return false
	return true
