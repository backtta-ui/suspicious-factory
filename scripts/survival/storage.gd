extends RefCounted
const PATH="user://survival_v13.json"
var error:=""
var data: Dictionary={"version":1,"daoist":"daoist:woochi","yokai":"yokai:woochi","music":.7,"sfx":.8,"vibration":false,"quality":"보통"}
func _init() -> void:
 backup_legacy()
 if FileAccess.file_exists(PATH):
  var raw=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if raw is Dictionary:
   for key in data:
    if raw.has(key) and typeof(raw[key])==typeof(data[key]):data[key]=raw[key]
 var roster: RefCounted=preload("res://scripts/survival/characters.gd")
 for team in ["daoist","yokai"]:
  # A save written before a roster change falls back to that team's first entry.
  if roster.find(data[team]).is_empty():data[team]=roster.catalog(team)[0].id
 data.music=clampf(data.music,0,1);data.sfx=clampf(data.sfx,0,1)
func backup_legacy() -> void:
 var dir:="user://legacy-backup-v13"
 if FileAccess.file_exists(dir+"/manifest.json"):return
 if DirAccess.make_dir_recursive_absolute(dir)!=OK:error="기존 저장 백업 폴더를 만들 수 없습니다.";return
 var manifest: Dictionary={}
 for name in DirAccess.get_files_at("user://"):
  if name.begins_with("survival_v13"):continue
  var from:="user://"+name;var to:=dir+"/"+name
  if DirAccess.copy_absolute(from,to)!=OK:error="기존 저장 백업에 실패했습니다.";return
  manifest[name]={"sha256":FileAccess.get_sha256(from),"bytes":FileAccess.get_file_as_bytes(from).size()}
 var f:=FileAccess.open(dir+"/manifest.json",FileAccess.WRITE)
 if f==null:error="백업 기록을 저장하지 못했습니다.";return
 f.store_string(JSON.stringify(manifest,"  "))
func save() -> Error:
 var f:=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if f==null:return FileAccess.get_open_error()
 f.store_string(JSON.stringify(data));f.flush();var result:=f.get_error();f.close()
 if result!=OK:return result
 return DirAccess.rename_absolute(PATH+".tmp",PATH)
