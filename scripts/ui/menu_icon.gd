extends Control
const Art=preload("res://scripts/wardrobe/art.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
var kind:="character"
var character_id:="woochi"
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _draw() -> void:
 if kind in ["character","outfit"]:draw_texture_rect(Art.icon(C.CHARACTERS[character_id].cell if kind=="character" else C.OUTFITS.basic.cell),Rect2(Vector2.ZERO,size),false)
 elif kind=="spell":
  var sheet=preload("res://assets/woo/v20/skills.png");var cell:=Vector2(sheet.get_size())/4;draw_texture_rect_region(sheet,Rect2(Vector2.ZERO,size),Rect2(Vector2(3,0)*cell,cell))
 elif kind=="bag":
  var sheet=preload("res://assets/woo/v14/items.png");var cell:=Vector2(sheet.get_size())/Vector2(3,2);draw_texture_rect_region(sheet,Rect2(Vector2.ZERO,size),Rect2(Vector2(2,1)*cell,cell))
 else:
  var center:=size/2;var points:=PackedVector2Array()
  for i in range(32):points.append(center+Vector2.from_angle(i*TAU/32)*(31 if i%4 in [0,1] else 24))
  draw_colored_polygon(points,Color("c8ab76"));draw_circle(center,13,Color("1a273b"));draw_circle(center,7,Color("c8ab76"))
