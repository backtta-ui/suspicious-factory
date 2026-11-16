extends Node2D
var clock:=0.0
var accumulator:=0.0
func _process(delta: float) -> void:
 clock+=delta;accumulator+=delta
 if accumulator>.033:accumulator=0;queue_redraw()
func _draw() -> void:
 # Local water ripples, bounded fireflies and translucent low-cost mist.
 for i in range(6):
  var p:=Vector2(1000+i*44,280+sin(clock*.6+i)*42)
  draw_arc(p,9+sin(clock+i)*4,0,PI,16,Color(.7,.85,1,.16),1)
 for i in range(18):
  var p:=Vector2(1530+(i%6)*86,970+floori(i/6.0)*140+sin(clock*.5+i)*12)
  if p.y>1075 and p.y<1148:continue
  draw_arc(p,12+sin(clock+i)*5,0,PI,14,Color(.58,.8,.85,.22),1)
 for i in range(24):
  var p:=Vector2(260+i*106+sin(clock*.3+i)*18,1000+sin(i*3.7)*700+cos(clock*.5+i)*14)
  draw_circle(p,1.3,Color(.6,.85,1,.3+sin(clock+i)*.2))
 for i in range(5):
  var p:=Vector2(fposmod(i*620+clock*5,3000)-100,700+i%3*420)
  draw_set_transform(p,0,Vector2(1,.035));draw_circle(Vector2.ZERO,155,Color(.6,.7,.86,.035));draw_set_transform(Vector2.ZERO)
 var exit:=WooForestLayout.EXIT
 draw_arc(exit,25,0,TAU,40,Color(.7,.6,1,.7),2)
 for i in range(6):draw_circle(exit+Vector2.from_angle(clock+i*TAU/6)*20,1.4,Color("cbd7ff"))

 var finish:=WooForestLayout.FINISH
 for i in range(6):
  var paw:=finish+Vector2(-70+i*13,20+sin(i)*8)
  draw_circle(paw,2,Color(.65,.84,1,.45));draw_circle(paw+Vector2(2,-3),.8,Color(.8,.95,1,.6))
 var fox:=finish+Vector2(20,-26)
 draw_colored_polygon(PackedVector2Array([fox+Vector2(-10,0),fox+Vector2(3,-5),fox+Vector2(10,-2),fox+Vector2(8,7),fox+Vector2(-8,7)]),Color(.85,.92,1,.62))
 draw_colored_polygon(PackedVector2Array([fox+Vector2(-8,4),fox+Vector2(-22,-4),fox+Vector2(-15,9),fox+Vector2(-4,10)]),Color(.8,.9,1,.55))
 draw_colored_polygon(PackedVector2Array([fox+Vector2(5,-3),fox+Vector2(5,-11),fox+Vector2(9,-5),fox+Vector2(13,-10),fox+Vector2(13,0)]),Color(.9,.95,1,.7))
 draw_circle(fox+Vector2(10,-3),1,Color("efce82"))
 draw_arc(finish,38,0,TAU,36,Color(.7,.8,1,.25+sin(clock)*.08),1)
