extends Control
var clock:=0.0
var low:=false
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 clock+=delta
 if not low:queue_redraw()
func _draw() -> void:
 var moon:=Vector2(size.x*.78,size.y*.2)
 draw_circle(moon,60,Color("d8d0f0"));draw_circle(moon,66,Color(.7,.65,1,.08));draw_circle(moon,78,Color(.7,.65,1,.04))
 for i in range(8 if low else 25):
  var x:=fposmod(i*157+sin(clock*.3+i)*35,size.x);var y:=fposmod(i*81+clock*(8+i%5),size.y)
  draw_set_transform(Vector2(x,y),sin(clock+i));petal(Vector2(4,2),Color(.95,.6,.8,.35))
 draw_set_transform(Vector2.ZERO)
func petal(radius: Vector2,color: Color) -> void:
 var points:=PackedVector2Array()
 for j in range(10):points.append(Vector2.from_angle(j*TAU/10)*radius)
 draw_colored_polygon(points,color)
