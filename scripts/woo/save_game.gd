class_name WooSaveGame
extends RefCounted
const Layout = preload("res://scripts/woo/village_layout.gd")
const PATH := "user://jeonwoochi_save.json"
const SETTINGS := "user://jeonwoochi_settings.cfg"
static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.get("schema",0)!=1 or data.get("map","")!=Layout.MAP_ID: return false
	var p = data.get("position",null)
	if not p is Array or p.size()!=2: return false
	if not (p[0] is float or p[0] is int) or not (p[1] is float or p[1] is int): return false
	if not Layout.can_stand(Vector2(float(p[0]),float(p[1]))): return false
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
		if not data.is_empty(): return data
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
	return {"smooth_camera":bool(config.get_value("view","smooth_camera",true)),"day_cycle":bool(config.get_value("view","day_cycle",true))}
static func save_settings(data: Dictionary) -> Error:
	var config := ConfigFile.new()
	for key in ["smooth_camera","day_cycle"]: config.set_value("view",key,bool(data[key]))
	return config.save(SETTINGS)
