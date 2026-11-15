class_name FactoryLayout
extends RefCounted
## Single authoritative geometry source shared by renderer, minimap and server.
const DATA_PATH := "res://assets/maps/factory_v2.json"
var map_id: String
var map_hash: String
var size: Vector2
var spawn: Vector2
var rooms: Array[Dictionary] = []
var corridors: Array[Dictionary] = []
var doors: Array[Dictionary] = []
var props: Array[Dictionary] = []
var stations: Array[Dictionary] = []
var floors: Array[Rect2] = []
var walls: Array[Rect2] = []
var solids: Array[Rect2] = []
var cell_size: int
var wall_thickness: float

func _init() -> void:
	var raw := FileAccess.get_file_as_string(DATA_PATH)
	var data: Dictionary = JSON.parse_string(raw)
	map_hash = raw.sha256_text()
	map_id = data.map_id
	size = point(data.size)
	spawn = point(data.spawn)
	cell_size = int(data.cell_size)
	wall_thickness = float(data.wall_thickness)
	for item in data.rooms:
		var room: Dictionary = item.duplicate(true)
		room.rect = rectangle(item.rect)
		room.color = Color(item.color)
		rooms.append(room)
		floors.append(room.rect)
	for item in data.corridors:
		var corridor: Dictionary = item.duplicate(true)
		corridor.rect = rectangle(item.rect)
		corridors.append(corridor)
		floors.append(corridor.rect)
	for item in data.doors:
		var door: Dictionary = item.duplicate(true)
		door.position = point(item.position)
		door.normal = point(item.normal)
		var dimensions := Vector2(160,item.width) if door.normal.x != 0 else Vector2(item.width,160)
		door.rect = Rect2(door.position-dimensions/2,dimensions)
		door.inside = door.position-door.normal*140
		door.outside = door.position+door.normal*140
		doors.append(door)
		floors.append(door.rect)
	for item in data.props:
		var prop: Dictionary = item.duplicate(true)
		prop.rect = rectangle(item.visual_rect)
		prop.collision_rect = rectangle(item.collision_rect)
		props.append(prop)
	for item in data.stations:
		var station: Dictionary = item.duplicate(true)
		station.position = point(item.position)
		stations.append(station)
	build_walls()
	solids.assign(walls)
	for prop in props: solids.append(prop.collision_rect)

static func point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func rectangle(value: Array) -> Rect2:
	return Rect2(value[0],value[1],value[2],value[3])

func zone_at(p: Vector2) -> int:
	for i in range(rooms.size()):
		if rooms[i].rect.has_point(p): return i+1
	for floor_rect in floors:
		if floor_rect.has_point(p): return 0
	return -1

func room_at(p: Vector2) -> String:
	for room in rooms:
		if room.rect.has_point(p): return room.name
	for corridor in corridors:
		if corridor.rect.has_point(p): return corridor.name
	return "연결 통로"

func is_door(p: Vector2) -> bool:
	for door in doors:
		if door.rect.has_point(p): return true
	return false

func build_walls() -> void:
	var horizontal: Dictionary = {}
	var vertical: Dictionary = {}
	var grid: Dictionary = {}
	for x in range(ceili(size.x/cell_size)):
		for y in range(ceili(size.y/cell_size)):
			var zone := zone_at(Vector2(x+0.5,y+0.5)*cell_size)
			if zone >= 0: grid[Vector2i(x,y)] = zone
	for key: Vector2i in grid:
		var zone: int = grid[key]
		for delta in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			var other: int = grid.get(key+delta,-1)
			if other == zone or (other >= 0 and other < zone): continue
			var midpoint := (Vector2(key)+Vector2(0.5,0.5)+Vector2(delta)*0.5)*cell_size
			if other >= 0 and is_door(midpoint): continue
			if delta.x != 0:
				var x := (key.x+(1 if delta.x > 0 else 0))*cell_size
				if not vertical.has(x): vertical[x] = []
				vertical[x].append(key.y*cell_size)
			else:
				var y := (key.y+(1 if delta.y > 0 else 0))*cell_size
				if not horizontal.has(y): horizontal[y] = []
				horizontal[y].append(key.x*cell_size)
	merge_edges(horizontal,true)
	merge_edges(vertical,false)

func merge_edges(lines: Dictionary, horizontal: bool) -> void:
	for axis in lines:
		var values: Array = lines[axis]
		values.sort()
		var start: float = values[0]
		var end := start+cell_size
		for value in values.slice(1):
			if value <= end:
				end = maxf(end,value+cell_size)
			else:
				add_wall_segment(start,end,float(axis),horizontal)
				start = value
				end = start+cell_size
		add_wall_segment(start,end,float(axis),horizontal)

func add_wall_segment(start: float, end: float, axis: float, horizontal: bool) -> void:
	var half := wall_thickness/2
	walls.append(Rect2(start-half,axis-half,end-start+wall_thickness,wall_thickness) if horizontal else Rect2(axis-half,start-half,wall_thickness,end-start+wall_thickness))

func can_stand(p: Vector2, radius: float = 17) -> bool:
	if zone_at(p) < 0: return false
	for rect in solids:
		var closest := p.clamp(rect.position,rect.end)
		if p.distance_squared_to(closest) < radius*radius: return false
	return true

func move_validated(p: Vector2, intent: Vector2, delta: float, speed: float = 230) -> Vector2:
	if not is_finite(intent.x) or not is_finite(intent.y) or not can_stand(p): return p
	var motion := intent.limit_length()*speed*clampf(delta,0,0.1)
	var steps := maxi(1,ceili(motion.length()/8))
	var step := motion/steps
	for i in range(steps):
		if can_stand(p+step): p += step
		else:
			if can_stand(p+Vector2(step.x,0)): p.x += step.x
			if can_stand(p+Vector2(0,step.y)): p.y += step.y
	return p

func visible_between(a: Vector2, b: Vector2, distance_limit: float = 620) -> bool:
	if a.distance_to(b)>distance_limit: return false
	for rect in solids:
		if rect.has_point(a) or rect.has_point(b): return false
		var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4]) != null:
				return false
	return true
