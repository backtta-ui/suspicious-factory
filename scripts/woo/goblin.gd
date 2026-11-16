class_name WooGoblin
extends CharacterBody2D
const ART=preload("res://assets/woo/v13/goblin.png")
const Config=preload("res://scripts/woo/hit_config.gd")
var adventure: WooAdventure
var enemy_id:=0
var hp:=60
var max_hp:=60
var jump_height:=0.0
var jump_velocity:=0.0
var stagger:=0.0
var poise_cd:=0.0
var attack_direction:=Vector2.RIGHT
var attack_attempts:=0
var successful_attacks:=0
var state:="idle"
var state_time:=1.2
var attack_time:=0.0
var attack_fired:=false
var sealed:=0.0
var flash:=0.0
var knocked:=Vector2.ZERO
var origin:=Vector2.ZERO
var target:=Vector2.ZERO
var travelled:=0.0
var stuck:=0.0
var plan_count:=0
var route: PackedVector2Array=[]
var route_timer:=0.0
var white_material: ShaderMaterial
var facing_left:=false
var sprite: Sprite2D
var last_frame:=-1
var death_left:=.4
func _ready() -> void:
 collision_layer=4;collision_mask=1|2|4
 var shape:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=9;shape.shape=circle;add_child(shape)
 white_material=ShaderMaterial.new();white_material.shader=preload("res://assets/woo/v13/hit_flash.gdshader")
 max_hp=hp
 origin=position;target=position;state_time=1.2+enemy_id*.4
 sprite=Sprite2D.new();sprite.texture=ART;sprite.material=white_material;sprite.region_enabled=true;sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
 # Fixed cell pivot and common planted-foot baseline, never alpha-bounds per frame.
 sprite.scale=Vector2.ONE*.115;sprite.position=Vector2(-224,-427)*.115
 update_frame(4);queue_redraw()
func choose_patrol() -> void:
 plan_count+=1
 var offsets=[Vector2(80,0),Vector2(0,-65),Vector2(-70,30),Vector2(40,75)]
 var next: Vector2=origin+offsets[(plan_count+enemy_id)%offsets.size()]
 target=next if WooForestLayout.can_stand(next,15) else origin
 state="patrol";state_time=5.0;stuck=0
func _physics_process(delta: float) -> void:
 if not is_instance_valid(adventure.game.player) or adventure.game.paused:return
 if hp<=0:
  death_left-=delta;sprite.modulate.a=maxf(0,death_left/.4);sprite.scale*=1-delta*.6
  if death_left<=0:queue_free()
  return
 if adventure.hit_stop>0:return
 flash=maxf(0,flash-delta);sealed=maxf(0,sealed-delta);stagger=maxf(0,stagger-delta);poise_cd=maxf(0,poise_cd-delta)
 if jump_height>0 or jump_velocity>0:
  jump_height=maxf(0,jump_height+jump_velocity*delta);jump_velocity-=500*delta
  if jump_height==0:jump_velocity=0
 sprite.position.y=-427*.115-jump_height
 white_material.set_shader_parameter("white_amount",1.0 if flash>0 else 0.0)
 route_timer=maxf(0,route_timer-delta)
 state_time-=delta
 var p: Vector2=adventure.game.player.position
 var distance:=position.distance_to(p)
 var move:=Vector2.ZERO
 if jump_height>0 or stagger>0:
  state="hit";state_time=.1
 elif sealed>0:
  state="sealed";state_time=.25
 elif state=="attack":
  attack_time+=delta
  if attack_time>=WooActionConfig.WINDUP and not attack_fired:
   attack_fired=true
   attack_attempts+=1
   if can_strike(p):
    var before: int=adventure.game.rpg.data.hp
    adventure.hurt_player(12,(p-position).normalized())
    if adventure.game.rpg.data.hp<before:successful_attacks+=1
  if attack_time>.65:state="rest";state_time=.7
 elif state=="rest":
  if state_time<=0:state="idle";state_time=.1
 elif distance<WooActionConfig.MONSTER_START and clear_path(p):
  state="attack";attack_time=0;attack_fired=false;attack_direction=(p-position).normalized()
 elif distance<210 and not adventure.game.player.jar:
  state="chase";move=steer(p)*48
 elif state=="patrol":
  if position.distance_to(target)<7 or state_time<=0:state="idle";state_time=1.5+enemy_id*.2
  else:move=steer(target)*24
 else:
  state="idle"
  if state_time<=0:choose_patrol()
 if move.x>.5:facing_left=false
 elif move.x<-.5:facing_left=true
 sprite.flip_h=facing_left
 velocity=move+knocked;knocked=knocked.move_toward(Vector2.ZERO,delta*230)
 var previous:=position
 move_and_slide()
 var travel:=position.distance_to(previous)
 travelled+=travel
 if move.length()>1 and travel<delta*2:stuck+=delta
 else:stuck=0
 if stuck>.4:state="rest";state_time=1.0;stuck=0
 var frame:=4
 if state=="attack":frame=5 if attack_time<WooActionConfig.WINDUP else 6
 elif flash>0:frame=7
 elif travel>delta*2:frame=posmod(int(travelled/6),4)
 update_frame(frame);queue_redraw()
func steer(goal: Vector2) -> Vector2:
 if route_timer<=0:
  route_timer=.65+enemy_id*.08;plan_count+=1
  route=adventure.forest.route(position,goal)
 while not route.is_empty() and position.distance_to(route[0])<7:route.remove_at(0)
 if route.is_empty():return (goal-position).normalized() if clear_path(goal) else Vector2.ZERO
 return (route[0]-position).normalized()
func clear_path(p: Vector2) -> bool:
 return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,p,1)).is_empty()
func can_strike(p: Vector2) -> bool:
 var player: WooActor=adventure.game.player
 return position.distance_to(p)<=WooActionConfig.MONSTER_REACH and absf(attack_direction.angle_to(p-position))<deg_to_rad(80) and player.jump_height<16 and player.dash_left<=0 and clear_path(p)
func launch_up(speed: float) -> void:
 if hp<=0:return
 jump_velocity=speed;jump_height=maxf(1,jump_height)
func update_frame(frame: int) -> void:
 if frame==last_frame:return
 last_frame=frame
 var cell:=Vector2(ART.get_width()/4.0,ART.get_height()/2.0)
 sprite.region_rect=Rect2(Vector2(frame%4,floori(frame/4.0))*cell,cell)
func receive_damage(amount: int,direction: Vector2,talisman: bool) -> void:
 if hp<=0:return
 hp=maxi(0,hp-amount)
 if adventure.game.rpg.data.effects.flash:flash=Config.FLASH_TIME
 knocked=direction*Config.KNOCKBACK
 if poise_cd<=0:stagger=.16;poise_cd=.9
 if talisman:sealed=1.4
 if hp==0:
  collision_layer=0;collision_mask=0;state="dead";update_frame(7)
  adventure.enemy_died(enemy_id,position)
func _draw() -> void:
 if hp<=0:return
 draw_set_transform(Vector2.ZERO,0,Vector2(1,.35));draw_circle(Vector2.ZERO,12,Color(0,0,0,.3));draw_set_transform(Vector2.ZERO)
 if hp<max_hp:draw_rect(Rect2(-13,-55,26,3),Color("29232e"));draw_rect(Rect2(-13,-55,26*hp/float(max_hp),3),Color("db8f92"))
 if state=="attack" and attack_time<WooActionConfig.WINDUP:draw_arc(Vector2.ZERO,30,0,TAU,24,Color(1,.4,.3,.4),1.5)
 if sealed>0:draw_arc(Vector2(0,-14),18,0,TAU,24,Color("f4d27f"),1.5)
