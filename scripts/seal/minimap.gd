extends Control
var client: Node
var own:=Vector2.ZERO
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_local(p: Vector2,_done: bool) -> void:own=p;queue_redraw()
func point(p: Vector2) -> Vector2:return size/2+(p-client.arena.data.size/2)*(size.x-18)/client.arena.data.size.x
func _draw() -> void:
 if client==null:return
 draw_circle(size/2,size.x/2-3,Color("172434"))
 var bounds: Vector2=client.arena.data.size
 draw_rect(Rect2(point(Vector2.ZERO),point(bounds)-point(Vector2.ZERO)),Color("3d5052"))
 for mission in client.state.get("missions",[]):
  if not mission.done:draw_circle(point(Vector2(mission.position[0],mission.position[1])),2,Color("efd47b"))
 draw_circle(point(own),3,Color("7cbcff"))
 draw_arc(size/2,size.x/2-3,0,TAU,48,Color("c9ae78"),2,true)
