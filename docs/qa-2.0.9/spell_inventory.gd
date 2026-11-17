extends SceneTree
func _initialize() -> void:
 var out: Array=[]
 for id in WooPracticeCatalog.all():
  var info: Dictionary=WooPracticeCatalog.all()[id].duplicate();info.id=id;info.category=WooSpellCodex.CATEGORIES[id];out.append(info)
 var f:=FileAccess.open("res://docs/qa-2.0.9/spells.json",FileAccess.WRITE);f.store_string(JSON.stringify(out,"  "));quit()
