extends SceneTree
const Save=preload("res://scripts/woo/save_game.gd")
const State=preload("res://scripts/woo/rpg_state.gd")
func _initialize() -> void:
 var path: String=OS.get_environment("WOO_V13_SAVE_FIXTURE")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var ok: bool=old.rpg.version==1 and Save.valid(old)
 var next:=State.new(old.rpg)
 for k in ["hp","mp","level","xp","coins"]:ok=ok and next.data[k]==old.rpg[k]
 for id in old.rpg.inventory:ok=ok and next.count(id)==int(old.rpg.inventory[id])
 ok=ok and next.data.claims==old.rpg.claims and next.data.slots==old.rpg.slots
 var upgraded:=old.duplicate(true);upgraded.rpg=next.data
 ok=ok and Save.save_game(upgraded)==OK
 var loaded:=Save.load_game()
 ok=ok and loaded.rpg.version==2 and loaded.rpg.claims==old.rpg.claims and loaded.position==old.position
 print("PASS: actual previous V1.3 APK-produced save migrates to V1.4 preserving HP, MP, level, XP, coins, every item, slots, claims and plaza position" if ok else "FAIL: actual V1.3 save migration")
 quit(0 if ok else 1)
