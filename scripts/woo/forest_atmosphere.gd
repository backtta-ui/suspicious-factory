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
 for i in range(14):
  var p:=Vector2(260+i*79+sin(clock*.3+i)*18,420+sin(i*3.7)*220+cos(clock*.5+i)*14)
  draw_circle(p,1.3,Color(.6,.85,1,.3+sin(clock+i)*.2))
 for i in range(5):
  var p:=Vector2(fposmod(i*330+clock*5,1600)-100,430+i%2*140)
  draw_set_transform(p,0,Vector2(1,.035));draw_circle(Vector2.ZERO,155,Color(.6,.7,.86,.035));draw_set_transform(Vector2.ZERO)
 var exit:=WooForestLayout.EXIT
 draw_arc(exit,25,0,TAU,40,Color(.7,.6,1,.7),2)
 for i in range(6):draw_circle(exit+Vector2.from_angle(clock+i*TAU/6)*20,1.4,Color("cbd7ff"))
