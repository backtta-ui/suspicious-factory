class_name WooSaveGame
extends RefCounted
const Layout = preload("res://scripts/woo/village_layout.gd")
const PATH := "user://jeonwoochi_save.json"
const SETTINGS := "user://jeonwoochi_settings.cfg"
static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if not preload("res://scripts/woo/rpg_state.gd").valid(data.get("rpg",{})):return false
	if data.get("schema",0)!=1 or data.get("map","")!=Layout.MAP_ID: return false
	var p = data.get("position",null)
	if not p is Array or p.size()!=2: return false
	if not (p[0] is float or p[0] is int) or not (p[1] is float or p[1] is int): return false
	var point:=Vector2(float(p[0]),float(p[1]))
	if not is_finite(point.x) or not is_finite(point.y): return false
	var revision=data.get("map_revision",1)
	if not (revision is int or revision is float) or not is_finite(float(revision)) or float(revision)!=floorf(float(revision)) or revision<1 or revision>Layout.REVISION:return false
	if not Layout.can_stand(point):
		var legacy:=PackedVector2Array([Vector2(68,480),Vector2(900,64),Vector2(1732,480),Vector2(900,896)])
		if revision>=Layout.REVISION:return false
		if not Geometry2D.is_point_in_polygon(point,legacy if revision<2 else Layout.BOUNDS):return false
	var completed=data.get("completed_paintings",[])
	if not completed is Array:return false
	var known: Array=Layout.PAINTINGS.map(func(v: Dictionary)->String:return v.id)
	var seen:=[]
	for id in completed:
		if not id is String or not known.has(id) or seen.has(id):return false
		seen.append(id)
	var anchor=data.get("return_anchor",{})
	if not anchor is Dictionary:return false
	if not anchor.is_empty():
		if anchor.get("map","")!=Layout.MAP_ID:return false
		if not preload("res://scripts/woo/rpg_state.gd").integer(anchor.get("facing",2),0,7):return false
		var q=anchor.get("position",[])
		if not q is Array or q.size()!=2:return false
		for n in q:
			if not (n is int or n is float) or not is_finite(float(n)):return false
		if not Geometry2D.is_point_in_polygon(Vector2(q[0],q[1]),Layout.BOUNDS):return false
	if not data.get("unlocked",null) is Array: return false
	for spell in data.unlocked:
		if not spell is String or spell!="jar": return false
	if not data.get("settings",{}) is Dictionary: return false
	if not data.get("jar",false) is bool: return false
	if not data.get("talked_to_elder",false) is bool: return false
	var time = data.get("time_of_day",0.22)
	if not (time is float or time is int) or not is_finite(float(time)) or float(time)<0 or float(time)>1: return false
	return true
static func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))==OK and valid(parser.data): return parser.data
	return {}
static func load_game() -> Dictionary:
	for path in [PATH,PATH+".bak"]:
		var data := read_valid(path)
		if not data.is_empty():
			var point:=Vector2(data.position[0],data.position[1])
			if int(data.get("map_revision",1))<Layout.REVISION and not Layout.can_stand(point):
				if not data.has("legacy_position"):data.legacy_position=data.position.duplicate()
				else:data.last_migration_position=data.position.duplicate()
				var safe:=Layout.safe_position(point)
				data.position=[safe.x,safe.y]
			if data.has("rpg"):data.rpg=preload("res://scripts/woo/rpg_state.gd").new(data.rpg).data
			data.map_revision=Layout.REVISION
			return data
	return {}
static func save_game(data: Dictionary) -> Error:
	if not valid(data): return ERR_INVALID_DATA
	var file := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if not file: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return error
	var target := ProjectSettings.globalize_path(PATH)
	if not read_valid(PATH).is_empty():
		var copy_error := DirAccess.copy_absolute(target,target+".bak")
		if copy_error != OK: return copy_error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),target)
static func settings() -> Dictionary:
	var config := ConfigFile.new()
	config.load(SETTINGS)
	return {"smooth_camera":bool(config.get_value("view","smooth_camera",true)),"day_cycle":bool(config.get_value("view","day_cycle",true)),"sound":bool(config.get_value("view","sound",true)),"music":bool(config.get_value("view","music",true)),"low_effects":bool(config.get_value("view","low_effects",false))}
static func save_settings(data: Dictionary) -> Error:
	var config := ConfigFile.new()
	for key in ["smooth_camera","day_cycle","sound","music","low_effects"]: config.set_value("view",key,bool(data.get(key,key!="low_effects")))
	return config.save(SETTINGS)
