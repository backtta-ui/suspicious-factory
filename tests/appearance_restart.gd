extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const P=preload("res://scripts/wardrobe/profile.gd")
func _initialize() -> void:
 var mode:="read"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
 var look:=C.DEFAULT.duplicate();look.character="yeonhwa";look.hair="silver";look.hat="hood";look.accessory="gourd";look.color="purple";look.color_override=true
 if mode=="write":
  var p:=P.new();p.data.owned.append("outfit:future_earned_item");p.equip(look)
  var woo:=C.base_appearance("woochi");woo.hat="bamboo";p.equip(woo);p.equip(look)
  var file:=FileAccess.open("user://unrelated_progress.json",FileAccess.WRITE);file.store_string('{"level":17,"coins":4321,"inventory":{"key":2}}');file.close()
 var restored:=P.new()
 var ok: bool=restored.data.appearance==look and restored.appearance_for("woochi").hat=="bamboo" and restored.appearance_for("yeonhwa")==look and restored.data.owned.has("outfit:future_earned_item") and restored.owned("outfit","dragon") and FileAccess.get_file_as_string("user://unrelated_progress.json")=='{"level":17,"coins":4321,"inventory":{"key":2}}'
 print("APPEARANCE PROCESS ",mode,": ","PASS" if ok else "FAIL")
 quit(0 if ok else 1)
