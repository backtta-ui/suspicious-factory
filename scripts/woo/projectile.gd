extends Node2D
var adventure: WooAdventure
var direction:=Vector2.RIGHT
var talisman:=false
var life:=.78
var distance:=0.0
func _physics_process(delta: float) -> void:
 if adventure.game.paused or adventure.hit_stop>0:return
 life-=delta
 if life<=0:queue_free();return
 var movement:=direction*(250 if talisman else 330)*delta
 var query:=PhysicsRayQueryParameters2D.create(global_position,global_position+movement,1|4)
 var hit:=get_world_2d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  if hit.collider.has_method("receive_damage"):adventure.enemy_hit(hit.collider,32 if talisman else 20,direction,talisman)
  queue_free();return
 position+=movement;distance+=movement.length();queue_redraw()
func _draw() -> void:
 if talisman:
  draw_set_transform(Vector2(0,-14),direction.angle())
  draw_rect(Rect2(-8,-4,16,8),Color("ffe2a0"));draw_line(Vector2(-5,-2),Vector2(5,2),Color("be453c"),2)
 else:
  draw_line(Vector2(0,-15)-direction*15,Vector2(0,-15),Color(.3,.6,1,.5),6,true)
  draw_circle(Vector2(0,-15),4,Color("c5f2ff"));draw_arc(Vector2(0,-15),7,direction.angle()-.8,direction.angle()+.8,8,Color("65baff"),2,true)
