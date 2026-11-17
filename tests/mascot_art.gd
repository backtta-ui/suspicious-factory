extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:
 for path in ["bodies-cardinal","bodies-diagonal","hair","hats"]:
  var texture: Texture2D=load("res://assets/woo/mascot/"+path+".png")
  var image:=texture.get_image()
  var rows: int=4 if path.begins_with("bodies") else 6
  check(image.get_size()==Vector2i(256,rows*64),path+" normalized cell dimensions")
  for row in range(rows):
   for col in range(4):
    var cell:=image.get_region(Rect2i(col*64,row*64,64,64))
    check(cell.get_used_rect().has_area(),path+" contains real art %d/%d"%[row,col])
 var catalog=preload("res://scripts/wardrobe/catalog.gd")
 for id in ["woochi","yeonhwa","muyeong","hongryeon"]:
  var value: Dictionary=catalog.base_appearance(id)
  check(catalog.normalize(value)==value,"existing base appearance identifiers remain valid: "+id)
 print("MASCOT ART: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
