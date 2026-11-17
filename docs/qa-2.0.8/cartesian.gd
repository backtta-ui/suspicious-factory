extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
var combinations:=0
var failures:=0
func _initialize() -> void:
 for character in C.CHARACTERS:
  for hair in C.HAIRS:
   for hat in C.HATS:
    for outfit in C.OUTFITS:
     for accessory in C.ACCESSORIES:
      for color in C.OUTFITS[outfit].colors:
       var look: Dictionary={"character":character,"hair":hair,"hat":hat,"outfit":outfit,"accessory":accessory,"color":color}
       if C.normalize(look)!=look:failures+=1
       combinations+=1
 var result={"method":"Full catalog Cartesian DATA validation only; not pixel/animation inspection","combinations":combinations,"failures":failures,"ownership_mutated":false,"rendered_cartesian":false}
 var f:=FileAccess.open("res://builds/qa-cartesian.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print(JSON.stringify(result));quit(1 if failures else 0)
