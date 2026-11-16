extends Node2D
const Layout=preload("res://scripts/woo/village_layout.gd")
const GLOW=preload("res://assets/woo/light.png")
var low_effects:=false
var night:=0.0
var elapsed:=0.0
var redraw_elapsed:=0.0
func _ready() -> void:z_index=85
func _process(delta: float) -> void:
 elapsed+=delta;redraw_elapsed+=delta
 if redraw_elapsed>=1.0/(15 if low_effects else 30):redraw_elapsed=0;queue_redraw()
func _draw() -> void:
 var camera:=get_viewport().get_camera_2d()
 if not camera:return
 var view:=get_viewport_rect().size/camera.zoom
 var visible_rect:=Rect2(camera.get_screen_center_position()-view/2,view).grow(90)
 for painting in Layout.PAINTINGS:
  var anchor: Vector2=painting.position+Vector2(0,-45)
  if not visible_rect.has_point(anchor):continue
  draw_texture_rect(GLOW,Rect2(anchor-Vector2(66,55),Vector2(132,110)),false,Color(.44,.45,1,.07+night*.04))
  for i in range(2 if low_effects else 6):
   var angle: float=elapsed*.35+i*TAU/6
   var p: Vector2=anchor+Vector2(cos(angle)*42,sin(angle)*24)
   draw_circle(p,1,Color(.65,.7,1,.45+.2*sin(angle)))
 var tree:=Vector2(1050,600)
 if visible_rect.has_point(tree):
  for i in range(3 if low_effects else 7):
   var p:=tree+Vector2(sin(i*2.4+elapsed*.16)*76,-45-fposmod(i*27+elapsed*5,140))
   draw_circle(p,1.2,Color(1,.77,.4,.22+.1*sin(elapsed+i)))
 if not low_effects:
  for anchor in [Vector2(1540,485),Vector2(2260,480)]:
   if not visible_rect.has_point(anchor):continue
   var polygon:=PackedVector2Array()
   var angle:=sin(elapsed*.8+anchor.x)*.04
   for v in [Vector2(-5,0),Vector2(5,0),Vector2(5,26),Vector2(-5,26)]:polygon.append(anchor+v.rotated(angle))
   draw_line(anchor+Vector2(0,-5),anchor,Color("b79e73"),1)
   draw_colored_polygon(polygon,Color("d7c18b"))
   for y in [5,10,15,20]:
    var a: Vector2=anchor+Vector2(-3,y).rotated(angle);var b: Vector2=anchor+Vector2(3,y+2).rotated(angle)
    draw_line(a,b,Color("9f4545"),.8)
  if night>.4:
   for i in range(6):
    var p:=Vector2(1300+i*110,850)+Vector2(sin(elapsed*.25+i)*22,cos(elapsed*.3+i*2)*14)
    if visible_rect.has_point(p):
     draw_circle(p,4,Color(.3,.6,1,.08));draw_circle(p,1.3,Color(.5,.75,1,.42))
