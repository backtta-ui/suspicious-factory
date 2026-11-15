extends SceneTree
const Layout = preload("res://scripts/map_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: "+text)
	else:
		failures += 1
		push_error("FAIL: "+text)
func run() -> void:
	var layout := Layout.new()
	check(layout.rooms.size() == 12,"all twelve requested rooms in data")
	check(layout.can_stand(layout.spawn),"spawn clear of walls and machinery")
	check(layout.map_hash == Layout.new().map_hash,"all instances share identical map fingerprint")
	check(layout.doors.all(func(door: Dictionary) -> bool: return door.width >= 240),"doors provide 240 px clearance for multiple workers")
	# Flood fill with swept collision checks, not only destination membership.
	var frontier: Array[Vector2i] = [Vector2i(layout.spawn/40)]
	var reached := {frontier[0]:true}
	var index := 0
	while index < frontier.size():
		var cell := frontier[index]
		index += 1
		var p := Vector2(cell)*40
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+delta
			if reached.has(next): continue
			var target := Vector2(next)*40
			if not layout.can_stand(target): continue
			var walked := p
			for step in range(5): walked = layout.move_validated(walked,Vector2(delta),8.0/230)
			if walked.distance_to(target)<0.1:
				reached[next] = true
				frontier.append(next)
	check(reached.size()>1000,"connected playable floor graph contains over 1000 navigable cells")
	for room in layout.rooms:
		var accessible := false
		for cell in reached:
			if room.rect.has_point(Vector2(cell)*40):
				accessible = true
				break
		check(accessible,"spawn can reach "+str(room.name))
	for station in layout.stations:
		check(layout.can_stand(station.position),"objective position clear: "+str(station.name))
		var accessible := false
		for cell in reached:
			if (Vector2(cell)*40).distance_to(station.position)<100:
				accessible = true
				break
		check(accessible,"spawn can reach objective: "+str(station.name))
	for door in layout.doors:
		check(layout.can_stand(door.inside) and layout.can_stand(door.outside),"door approaches clear: "+str(door.room))
	# Server-validation primitives: impossible inputs/teleport-size dt cannot bypass walls.
	check(layout.move_validated(layout.spawn,Vector2(INF,0),1)==layout.spawn,"nonfinite movement rejected")
	check(layout.move_validated(layout.spawn,Vector2(9999,0),99).distance_to(layout.spawn)<=23.01,"speed and timestep capped")
	var p := Vector2(1800,1740)
	for i in range(100): p = layout.move_validated(p,Vector2.UP,0.1)
	check(p.y>=1624,"shared server geometry blocks room wall")
	print("MAP NAVIGATION: %d checks, %d failures; reachable cells=%d" % [checks,failures,reached.size()])
	quit(0 if failures==0 else 1)
