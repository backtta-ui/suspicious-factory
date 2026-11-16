class_name WooActionController
extends Node
const C=preload("res://scripts/woo/action_config.gd")
var adventure: WooAdventure
var stage:=0
var elapsed:=0.0
var duration:=0.0
var active:=false
var queue: Array[String]=[]
var reset_left:=0.0
var aim:=Vector2.RIGHT
var mode:="ground"
var struck: Dictionary={}
var hits:=0
var hit_left:=0.0
var last_attack_hit:=false
var pulses:=0
var shake_scale:=1.0
func enemies() -> Array:
 if not is_instance_valid(adventure.forest):return []
 return adventure.forest.get_children().filter(func(n: Node)->bool:return n is WooGoblin and n.hp>0)
func visible_line(a: Vector2,b: Vector2) -> bool:
 return adventure.game.player.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a,b,1)).is_empty()
func corrected_direction() -> Vector2:
 var player: WooActor=adventure.game.player
 var forward:=Vector2.from_angle(player.facing*PI/4)
 var best:=INF;var chosen:=forward
 for enemy in enemies():
  var delta: Vector2=enemy.position-player.position
  if delta.length()>C.AIM_RANGE or delta.length()<1:continue
  var angle:=absf(forward.angle_to(delta))
  if angle>C.AIM_HALF_ANGLE or not visible_line(player.position,enemy.position):continue
  var score: float=delta.length()+angle*95
  if score<best:best=score;chosen=delta.normalized()
 return chosen
func request(kind: String="attack") -> void:
 if not adventure.can_fight() or adventure.game.player.jar:return
 if active:
  if queue.size()<C.BUFFER_SIZE:queue.append(kind)
 else:begin(kind)
func begin(kind: String) -> void:
 var player: WooActor=adventure.game.player
 if kind=="talisman":
  if adventure.talisman_cd>0 or adventure.game.rpg.data.mp<C.TALISMAN_COST:return
  adventure.game.rpg.data.mp-=C.TALISMAN_COST;adventure.talisman_cd=C.TALISMAN_COOLDOWN;mode="talisman";duration=.34
 else:
  if reset_left<=0:stage=0
  else:stage=stage%4
  stage+=1
  mode="air" if player.jump_height>3 else "ground"
  duration=.34 if mode=="air" else C.DURATION[stage-1]
 aim=corrected_direction();player.facing=posmod(roundi(aim.angle()/(PI/4)),8)
 active=true;elapsed=0;struck.clear();pulses=0;last_attack_hit=false;reset_left=C.COMBO_RESET
 adventure.attack_cd=duration
 player.action_pose=5 if mode=="air" else (1 if mode=="talisman" else stage-1)
 player.action_left=duration;player.pose_duration=duration
 player.push_left=.10;player.push_direction=aim
 adventure.game.sound.play_clip("spell" if mode=="talisman" else "attack")
func tick(delta: float) -> void:
 hit_left=maxf(0,hit_left-delta)
 if hit_left==0:hits=0
 if adventure.game.paused:return
 if adventure.hit_stop>0:return
 reset_left=maxf(0,reset_left-delta)
 if not active:return
 elapsed+=delta
 var impact: float=.12 if mode!="ground" else C.IMPACT[stage-1]
 if elapsed>=impact and pulses==0:
  impact_hit(0);pulses=1
 if elapsed>=duration:
  active=false
  if not last_attack_hit:hits=0;hit_left=0;stage=0;reset_left=0
  while not queue.is_empty():
   begin(queue.pop_front())
   if active:break
func impact_hit(pulse: int) -> void:
 var player: WooActor=adventure.game.player
 var range_value: float=145 if mode=="talisman" else (120 if mode=="air" else C.RANGES[stage-1])
 var damage: int=32 if mode=="talisman" else (26 if mode=="air" else C.DAMAGE[stage-1])
 if mode=="air":
  var bolt:=preload("res://scripts/woo/air_talisman.gd").new();bolt.adventure=adventure;bolt.direction=aim;bolt.position=player.position;bolt.height=player.jump_height;adventure.forest.add_child(bolt);return
 adventure.combat.swing(player.position,aim,stage,mode,range_value)
 for enemy in enemies():
  var id: String="%d:%d" % [enemy.get_instance_id(),pulse]
  if struck.has(id):continue
  var delta: Vector2=enemy.position-player.position
  if delta.length()>range_value+12 or absf(aim.angle_to(delta))>C.CONE_HALF_ANGLE or not visible_line(player.position,enemy.position):continue
  struck[id]=true;last_attack_hit=true;hits+=1;hit_left=1.5
  adventure.enemy_hit(enemy,damage,aim,mode=="talisman")
  if mode=="ground" and stage==4:enemy.launch_up(160);adventure.hit_stop=.11 if adventure.game.rpg.data.effects.hit_stop else 0
  if mode=="air":enemy.launch_up(100);player.air_chain=true
func cancel() -> void:
 active=false;queue.clear();stage=0;reset_left=0
func landing() -> void:
 if not adventure.in_mission or not adventure.game.player.air_chain:return
 adventure.game.player.air_chain=false
 if adventure.can_fight():
  adventure.game.player.action_pose=6;adventure.game.player.action_left=.2
  mode="landing";aim=corrected_direction();struck.clear();impact_hit(0)
