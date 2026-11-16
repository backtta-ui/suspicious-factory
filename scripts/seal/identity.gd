class_name SealIdentity
extends RefCounted
const PATH="user://seal_identity.json"
static func load_profile() -> Dictionary:
 var data=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
 if not data is Dictionary or str(data.get("id","")).length()!=32 or str(data.get("secret","")).length()!=64:
  var crypto:=Crypto.new()
  data={"id":crypto.generate_random_bytes(16).hex_encode(),"secret":crypto.generate_random_bytes(32).hex_encode(),"nickname":"도사","endpoint":"","slots":["transform","blink"],"played":0,"wins":0,"cosmetics":[]}
 save_profile(data)
 return data
static func save_profile(data: Dictionary) -> Error:
 var f:=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if f==null:return FileAccess.get_open_error()
 f.store_string(JSON.stringify(data));f.flush();f.close()
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
