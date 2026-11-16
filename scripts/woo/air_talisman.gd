extends Node2D
var adventure: WooAdventure
var direction:=Vector2.RIGHT
var height:=30.0
var time:=0.0
var hit:=false
func _physics_process(delta: float) -> void:
 if adventure.game.paused or adventure.hit_stop>0:return
 time+=delta
 var step:=direction*120*delta
 var ray:=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,position+step,1))
 if ray.is_empty():position+=step
 height=maxf(0,height-delta*180)
 if height<=0 or time>.4:
  if not hit:
   hit=true;adventure.combat.burst(position,0,false,true);adventure.combat.swing(position,direction,4,"air",90)
   for enemy in adventure.actions.enemies():
    if position.distance_to(enemy.position)<85 and adventure.actions.visible_line(position,enemy.position):
     adventure.enemy_hit(enemy,26,direction,true);adventure.actions.hits+=1;adventure.actions.hit_left=1.5;adventure.actions.last_attack_hit=true;adventure.game.player.air_chain=true
  queue_free()
 queue_redraw()
func _draw() -> void:
 draw_set_transform(Vector2(0,-height-10),time*5)
 draw_rect(Rect2(-3,-7,6,14),Color("e9d59d"));draw_line(Vector2(-1,-4),Vector2(1,4),Color("b84347"),1)
