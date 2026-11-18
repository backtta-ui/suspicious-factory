extends RefCounted
const PATH="user://survival_v13.json"
var error:=""
var data: Dictionary={"version":1,"daoist":"daoist:woochi","yokai":"yokai:woochi","music":.7,"sfx":.8,"music_mute":false,"sfx_mute":false,"vibration":false,"quality":"보통","sensitivity":1.0,
 "coins":0,"gems":0,
 "stats":{"matches":0,"wins":0,"seals":0,"rescues":0,"doors":0,"disguises":0},
 "market":{"owned":["default"],"equipped":{"skin":"default","title":"","effect":""}},
 "characters":{"owned":["daoist:woochi","daoist:yeonhwa","yokai:gumiho","yokai:jangsanbeom"]},
 "achievements":{"claimed":[]},
 "mail":{"read":[],"claimed":[]},
 "alerts":{"read":[]},
 "room_codes":[]}
func _init() -> void:
 backup_legacy()
 if FileAccess.file_exists(PATH):
  var raw=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if raw is Dictionary:
   for key in data:
    if not raw.has(key):continue
    if typeof(raw[key])!=typeof(data[key]):continue
    if raw[key] is Dictionary:
     # A save written before a new field existed keeps the new default for it.
     var merged: Dictionary=data[key].duplicate(true)
     merged.merge(raw[key],true)
     data[key]=merged
    else:data[key]=raw[key]
 var roster: RefCounted=preload("res://scripts/survival/characters.gd")
 for team in ["daoist","yokai"]:
  # A save written before a roster change falls back to that team's first entry.
  if roster.find(data[team]).is_empty():data[team]=roster.catalog(team)[0].id
 data.music=clampf(data.music,0,1);data.sfx=clampf(data.sfx,0,1);data.sensitivity=clampf(data.sensitivity,.6,1.5)
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
## 마켓·업적·우편에서 쓰는 재화/통계 갱신. 저장은 호출한 쪽이 결정한다.
func add_coins(value: int) -> void:data.coins=maxi(0,int(data.coins)+value)
func stat(key: String) -> int:return int((data.stats as Dictionary).get(key,0))
func bump(key: String,value: int=1) -> void:data.stats[key]=stat(key)+value
func owns(item: String) -> bool:return (data.market.owned as Array).has(item)
func own(item: String) -> void:
 if not owns(item):(data.market.owned as Array).append(item)
func equip(kind: String,id: String) -> void:data.market.equipped[kind]=id
func equipped(kind: String) -> String:return String((data.market.equipped as Dictionary).get(kind,""))
## 캐릭터 해금 상태. 무료 캐릭터는 처음부터 보유한다.
func owns_character(id: String) -> bool:return (data.characters.owned as Array).has(id)
func own_character(id: String) -> void:
 if not owns_character(id):(data.characters.owned as Array).append(id)
