class_name FactoryMap
extends Node2D

const MAP_SIZE := Vector2(3200, 2200)
var walls: Array[Rect2] = []
var props: Array[Dictionary] = []
var stations: Array[Dictionary] = []
var rooms: Array[Dictionary] = [
	{"name":"생산라인", "rect":Rect2(70,70,1430,870), "color":Color("263c46")},
	{"name":"조립실", "rect":Rect2(1500,70,800,870), "color":Color("304047")},
	{"name":"창고", "rect":Rect2(2300,70,830,870), "color":Color("3c3f40")},
	{"name":"전기실", "rect":Rect2(70,1260,780,870), "color":Color("2d394b")},
	{"name":"기계실", "rect":Rect2(850,1260,750,870), "color":Color("34424a")},
	{"name":"휴게실", "rect":Rect2(1600,1260,750,870), "color":Color("34483f")},
	{"name":"사무실", "rect":Rect2(2350,1260,780,870), "color":Color("3e3c49")}
]

func _ready() -> void:
	z_index = -1
	wall(Rect2(0,0,3200,60))
	wall(Rect2(0,2140,3200,60))
	wall(Rect2(0,0,60,2200))
	wall(Rect2(3140,0,60,2200))
	for x in [1500,2300]:
		wall(Rect2(x,60,24,880))
	for x in [850,1600,2350]:
		wall(Rect2(x,1260,24,880))
	# Door openings are 180 px wide; all rooms join the central corridor.
	for pair in [[60,610],[790,1810],[1990,2610],[2790,3140]]:
		wall(Rect2(pair[0],930,pair[1]-pair[0],30))
	for pair in [[60,360],[540,1110],[1290,1860],[2040,2610],[2790,3140]]:
		wall(Rect2(pair[0],1240,pair[1]-pair[0],30))
	for x in [250, 850]:
		prop(Rect2(x,320,460,135), "belt")
		prop(Rect2(x+80,600,150,140), "robot")
	prop(Rect2(1640,300,210,160), "machine")
	prop(Rect2(1980,580,210,160), "machine")
	for point in [Vector2(2430,260),Vector2(2690,260),Vector2(2860,570),Vector2(2440,660)]:
		prop(Rect2(point,Vector2(140,130)), "boxes")
	for x in [170,400,630]:
		prop(Rect2(x,1550,130,190), "electric")
	prop(Rect2(1020,1580,360,230), "generator")
	prop(Rect2(1740,1500,190,100), "table")
	prop(Rect2(2070,1780,190,100), "table")
	prop(Rect2(1720,1950,180,90), "sofa")
	prop(Rect2(2490,1500,210,120), "desk")
	prop(Rect2(2820,1820,210,120), "desk")
	stations = [
		{"name":"기계 버튼", "position":Vector2(480,490)},
		{"name":"생산 설비", "position":Vector2(1080,490)},
		{"name":"불량품 분류", "position":Vector2(1745,500)},
		{"name":"상자 정리", "position":Vector2(2510,825)},
		{"name":"전기 스위치", "position":Vector2(470,1780)},
		{"name":"전선 연결", "position":Vector2(1200,1850)}
	]

func wall(rect: Rect2) -> void:
	walls.append(rect)
	add_collision(rect)

func prop(rect: Rect2, kind: String) -> void:
	props.append({"rect":rect, "kind":kind})
	add_collision(rect)

func add_collision(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 2
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func room_at(point: Vector2) -> String:
	for room in rooms:
		if room.rect.has_point(point):
			return room.name
	return "중앙 복도"

func nearest_station(point: Vector2) -> Dictionary:
	for station in stations:
		if point.distance_to(station.position) < 115:
			return station
	return {}

func plate(rect: Rect2, color: Color, radius: int = 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("15232f")
	style.set_border_width_all(4)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0,0,0,0.25)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0,8)
	draw_style_box(style,rect)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,MAP_SIZE), Color("485158"))
	for room in rooms:
		draw_rect(room.rect, room.color)
	for x in range(60,3140,80):
		draw_line(Vector2(x,60),Vector2(x,2140),Color(0.7,0.8,0.85,0.06))
	for y in range(60,2140,80):
		draw_line(Vector2(60,y),Vector2(3140,y),Color(0.7,0.8,0.85,0.06))
	for x in range(100,3100,85):
		draw_line(Vector2(x,995),Vector2(x+40,995),Color("c4a74b"),5)
		draw_line(Vector2(x,1205),Vector2(x+40,1205),Color("c4a74b"),5)
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	for room in rooms:
		var p: Vector2 = room.rect.position + Vector2(55,85)
		draw_string(font,p,room.name,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color(0.85,0.92,0.92,0.65))
		# Overhead pipes and bracket supports.
		draw_line(p+Vector2(-10,70),p+Vector2(room.rect.size.x-120,70),Color("172c36"),18)
		draw_line(p+Vector2(-10,66),p+Vector2(room.rect.size.x-120,66),Color("5a747b"),8)
	for item in props:
		var r: Rect2 = item.rect
		# Yellow safety footprint around machinery.
		if item.kind in ["belt","machine","generator","robot","electric"]:
			draw_rect(r.grow(18),Color("a3914c"),false,3)
		plate(r, Color("62777c") if item.kind != "boxes" else Color("a48359"))
		match item.kind:
			"belt":
				draw_rect(r.grow(-15), Color("23343d"))
				for x in range(int(r.position.x+22),int(r.end.x-15),25):
					draw_line(Vector2(x,r.position.y+18),Vector2(x,r.end.y-18),Color("7c9293"),7)
				plate(Rect2(r.position+Vector2(90,32),Vector2(70,65)),Color("b99c6b"),2)
				plate(Rect2(r.position+Vector2(270,32),Vector2(70,65)),Color("b99c6b"),2)
			"robot":
				draw_circle(r.get_center(),44,Color("263840"))
				draw_line(r.get_center(),r.get_center()+Vector2(35,-50),Color("e3b64d"),22,true)
				draw_line(r.get_center()+Vector2(35,-50),r.get_center()+Vector2(70,-20),Color("e3b64d"),18,true)
				draw_circle(r.get_center()+Vector2(35,-50),13,Color("314955"))
			"machine", "electric", "generator":
				plate(Rect2(r.position+Vector2(16,18),Vector2(r.size.x-32,55)), Color("1b303c"),4)
				for i in range(3):
					draw_circle(r.position+Vector2(30+i*25,44),6,Color("6de0b0") if i != 2 else Color("e9bd57"))
				for y in range(int(r.position.y+90),int(r.end.y-10),16):
					draw_line(Vector2(r.position.x+24,y),Vector2(r.end.x-24,y),Color("324650"),5)
			"boxes":
				draw_line(r.position+Vector2(r.size.x/2,4),Vector2(r.get_center().x,r.end.y-4),Color("d9bd85"),14)
				draw_rect(Rect2(r.position+Vector2(16,32),Vector2(36,26)),Color("e4d4a6"))
			"table", "desk":
				draw_rect(r.grow(-10),Color("bca77e"))
				plate(Rect2(r.position+Vector2(30,20),Vector2(65,45)),Color("264551"),3)
				draw_rect(Rect2(r.position+Vector2(120,22),Vector2(35,40)),Color("e4e1d1"))
			"sofa":
				plate(r.grow(-10),Color("5d9580"))
				draw_line(r.get_center()+Vector2(0,-25),r.get_center()+Vector2(0,25),Color("334a43"),3)
	for r in walls:
		plate(r,Color("243240"),2)
		draw_rect(Rect2(r.position,r.size.min(Vector2(r.size.x,8))), Color("657782"))
	for station in stations:
		var p: Vector2 = station.position
		draw_circle(p,17,Color("eec75a"))
		draw_string(font,p+Vector2(-5,6),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("243240"))
