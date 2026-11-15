class_name FactoryMap
extends Node2D

const Layout = preload("res://scripts/map_layout.gd")
const MAP_SIZE := Vector2(5120,3360)
var layout: FactoryLayout
var walls: Array[Rect2] = []
var props: Array[Dictionary] = []
var stations: Array[Dictionary] = []
var rooms: Array[Dictionary] = []

func _ready() -> void:
	z_index = -1
	layout = Layout.new()
	walls = layout.walls
	props = layout.props
	stations = layout.stations
	rooms = layout.rooms
	for rect in layout.solids: add_collision(rect)

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
	return layout.room_at(point)

func nearest_station(point: Vector2) -> Dictionary:
	for station in stations:
		if point.distance_to(station.position) < 115: return station
	return {}

func plate(rect: Rect2, color: Color, radius: int = 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("17212c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0,0,0,0.32)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0,8)
	draw_style_box(style,rect)

func floor_tiles(rect: Rect2, color: Color) -> void:
	draw_rect(rect,color)
	for x in range(int(rect.position.x),int(rect.end.x),80):
		draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),Color(0.9,0.87,0.8,0.065))
	for y in range(int(rect.position.y),int(rect.end.y),80):
		draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),Color(0.9,0.87,0.8,0.065))

func _draw() -> void:
	if not layout: return
	for corridor in layout.corridors: floor_tiles(corridor.rect,Color("646060"))
	for door in layout.doors: floor_tiles(door.rect,Color("69635b"))
	for room in rooms: floor_tiles(room.rect,room.color)
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	for room in rooms:
		var r: Rect2 = room.rect
		var text_size := font.get_string_size(room.name,HORIZONTAL_ALIGNMENT_LEFT,-1,32)
		var p := Vector2(r.get_center().x-text_size.x/2,r.position.y+90)
		plate(Rect2(p+Vector2(-18,-39),text_size+Vector2(36,12)),Color("252a32"),12)
		draw_string(font,p,room.name,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("f0eddf"))
		# Independent visual pipes/lights; collision comes only from layout.solids.
		draw_line(r.position+Vector2(24,24),r.position+Vector2(r.size.x-24,24),Color("27303a"),24)
		draw_line(r.position+Vector2(24,21),r.position+Vector2(r.size.x-24,21),Color("65727a"),9)
		draw_line(r.position+Vector2(r.size.x*0.3,12),r.position+Vector2(r.size.x*0.7,12),Color("e7d4a2"),8,true)
	for x in range(240,4160,140):
		draw_line(Vector2(x,1700),Vector2(x+60,1700),Color("c8a64d"),5)
		draw_line(Vector2(x,1910),Vector2(x+60,1910),Color("c8a64d"),5)
	for door in layout.doors:
		var side := Vector2(-door.normal.y,door.normal.x)
		for i in range(-100,101,40):
			var p: Vector2 = door.position+side*i
			draw_line(p-side*9-door.normal*24,p+side*9+door.normal*24,Color("e4b845"),9)
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
				plate(Rect2(r.position+Vector2(minf(270,r.size.x-90),32),Vector2(70,65)),Color("b99c6b"),2)
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
			"table", "desk", "sink", "shelf", "vending":
				draw_rect(r.grow(-10),Color("bca77e"))
				plate(Rect2(r.position+Vector2(30,20),Vector2(65,45)),Color("264551"),3)
				draw_rect(Rect2(r.position+Vector2(120,22),Vector2(35,40)),Color("e4e1d1"))
			"plant":
				draw_circle(r.get_center(),37,Color("426745"))
				for leaf in [Vector2(-20,-8),Vector2(16,-20),Vector2(13,16)]:
					draw_circle(r.get_center()+leaf,21,Color("679858"))
			"toilet":
				draw_circle(r.get_center(),31,Color("d5ddda"))
				draw_circle(r.get_center(),18,Color("6c8c92"))
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
