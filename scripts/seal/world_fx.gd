extends Node2D
var client: Node
var clock:=0.0
func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 if client.state.is_empty():return
 var catalog=client.arena
 var jail: Vector2=catalog.jail
 draw_arc(catalog.altar,38,0,TAU,48,Color(.75,.65,1,.55),2,true)
 draw_rect(Rect2(jail-Vector2(58,36),Vector2(116,72)),Color(.12,.2,.28,.38))
 for x in range(-60,61,15):draw_line(jail+Vector2(x,-52),jail+Vector2(x,26),Color(.5,.7,1,.45),2)
 for m in client.state.get("missions",[]):
  if m.done:continue
  var p:=Vector2(m.position[0],m.position[1])
  var color:=Color("c3b37d") if m.kind!="soul" else Color("8bdcff")
  draw_arc(p,15,0,TAU,24,color,1.5)
  if m.kind=="soul":draw_circle(p+Vector2(0,-18+sin(clock*2)*3),7,Color(.55,.85,1,.65))
  elif m.kind=="pillars":
   for i in range(3):draw_rect(Rect2(p+Vector2((i-1)*14,-22),Vector2(6,22)),color)
  elif m.kind=="fragments":
   for i in range(3):
    var q: Vector2=catalog.safe(p+Vector2.from_angle(i*TAU/3)*78)
    draw_rect(Rect2(q-Vector2(3,9),Vector2(6,9)),Color("e3c98c"))
 for e in client.state.get("effects",[]):
  var p:=Vector2(e.position[0],e.position[1])
  if e.kind in ["smoke","darkness"]:
   for i in range(4):draw_circle(p+Vector2(sin(i*2.3+clock*.3)*45,cos(i*1.7)*25),48,Color(.12,.14,.22,.28))
  elif e.kind=="flame":draw_circle(p+Vector2(0,-20+sin(clock*2)*3),7,Color(.55,.85,1,.65))
 for mark in client.state.get("footprints",[]):draw_circle(Vector2(mark[0],mark[1]),2,Color(.5,.8,1,.5))
