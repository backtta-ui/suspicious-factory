class_name WooWardrobe
extends RefCounted
const C=preload("res://scripts/wardrobe/catalog.gd")
const PATH="user://dosa_wardrobe.json"
var data: Dictionary
func _init() -> void:
 data={"version":1,"appearance":C.DEFAULT.duplicate(),"owned":[],"verified_wins":0,"server_wins":{}}
 var raw=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
 if not raw is Dictionary and FileAccess.file_exists(PATH+".bak"):raw=JSON.parse_string(FileAccess.get_file_as_string(PATH+".bak"))
 if raw is Dictionary:
  data.appearance=C.normalize(raw.get("appearance",{}))
  if raw.get("owned",null) is Array:
   for id in raw.owned:
    if id is String and id.length()<60 and not data.owned.has(id):data.owned.append(id)
  if raw.get("server_wins",null) is Dictionary:
   for key in raw.server_wins:
    var n=raw.server_wins[key]
    if n is float or n is int:
     if is_finite(float(n)) and n>=0 and n<=100000:data.server_wins[str(key).left(240)]=int(n)
  for n in data.server_wins.values():data.verified_wins=maxi(data.verified_wins,int(n))
 refresh({})
func refresh(rpg: Dictionary) -> void:
 for slot in ["character","hair","outfit","hat","accessory"]:
  var table: Dictionary=C.table(slot)
  for id in table:
   var rule: String=table[id].rule
   var earned: bool=rule=="free" or (rule in ["forest","goblin"] and rpg.get("completed",[]).has("fox_forest")) or (rule=="shrine" and rpg.get("loot_claims",[]).has("shrine_seal")) or (rule=="wins10" and data.verified_wins>=10) or (rule=="wins30" and data.verified_wins>=30)
   var key: String=slot+":"+id
   if earned and not data.owned.has(key):data.owned.append(key)
func owned(slot: String,id: String) -> bool:return slot=="color" or data.owned.has(slot+":"+id)
func valid_selection(raw: Dictionary) -> bool:
 if C.normalize(raw)!=raw:return false
 for slot in ["character","hair","outfit","hat","accessory"]:
  if not owned(slot,str(raw[slot])):return false
 return true
func equip(raw: Dictionary) -> Error:
 if not valid_selection(raw):return ERR_UNAUTHORIZED
 var before: Dictionary=data.appearance.duplicate();data.appearance=raw.duplicate()
 var err:=save()
 if err!=OK:data.appearance=before
 return err
func record_server_wins(endpoint: String,wins: int) -> void:
 if wins<0 or wins>100000:return
 data.server_wins[endpoint]=maxi(int(data.server_wins.get(endpoint,0)),wins)
 data.verified_wins=0
 for n in data.server_wins.values():data.verified_wins=maxi(data.verified_wins,int(n))
 refresh({});save()
func save() -> Error:
 var file:=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if file==null:return FileAccess.get_open_error()
 file.store_string(JSON.stringify(data));file.flush();file.close()
 if FileAccess.file_exists(PATH):DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH),ProjectSettings.globalize_path(PATH+".bak"))
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
