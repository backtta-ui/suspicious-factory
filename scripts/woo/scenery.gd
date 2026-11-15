class_name WooScenery
extends Node2D
## Fixed northern mountain/forest silhouettes, never a panorama painted over walkways.
func _ready() -> void:z_index=-95
func _draw() -> void:
 for layer in range(3):
  var points:=PackedVector2Array([Vector2(0,0)])
  for i in range(35):
   points.append(Vector2(i*100,22+layer*24+absf(sin(i*0.72+layer))*46))
  points.append(Vector2(3400,0))
  draw_colored_polygon(points,[Color("667385"),Color("495d6b"),Color("374f58")][layer])
