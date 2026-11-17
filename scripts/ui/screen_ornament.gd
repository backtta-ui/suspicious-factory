extends Control
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;resized.connect(queue_redraw)
func _draw() -> void:
 # Quiet cloud silhouettes and a single heading divider; controls remain native.
 var cloud:=Color("1b2940",.65)
 for side in [0,1]:
  var origin:=Vector2(34 if side==0 else size.x-34,36 if side==0 else size.y-28)
  for i in range(4):
   var p:=origin+Vector2((i*22)*(1 if side==0 else -1),-sin(i)*8)
   draw_rect(Rect2(p-Vector2(12,5),Vector2(24,10)),cloud)
 draw_line(Vector2(22,70),Vector2(size.x-22,70),Color("c8ab76",.18),1)
