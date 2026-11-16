class_name WooNpcDriver
extends RefCounted
var navigation: WooNpcNavigation
var goals: Array=[]
var role:="resident"
var state:="wait"
var timer:=0.0
var wait_duration:=0.0
var path:=PackedVector2Array()
var cursor:=0
var last_goal:=-1
var blocked_time:=0.0
var work_time:=0.0
var movement_speed:=28.0
var rng:=RandomNumberGenerator.new()
var travelled:=0.0
var replans:=0
var gaze_bucket:=-1
var social_cooldown:=0.0
func _init(data: Dictionary,nav: WooNpcNavigation) -> void:
 navigation=nav;goals=data.get("patrol",[data.position]);role=data.get("role","resident")
 rng.seed=absi(str(data.get("id","resident")).hash())+120
 movement_speed={"elder":16.0,"merchant":24.0,"master":22.0}.get(role,28.0)
 timer=rng.randf_range(1.2,3.8);wait_duration=timer
func begin_wait(seconds: float=-1) -> void:
 state="work" if role=="merchant" else "wait"
 timer=seconds if seconds>=0 else rng.randf_range(3.2,6.0 if role=="elder" else 4.8)
 wait_duration=timer;blocked_time=0;path=PackedVector2Array();cursor=0;work_time=0
func step(actor: CharacterBody2D,delta: float,attention: bool) -> Vector2:
 social_cooldown=maxf(0,social_cooldown-delta)
 if attention:
  if state!="attention":state="attention";path=PackedVector2Array()
  return Vector2.ZERO
 if state=="attention":begin_wait(.8)
 if state in ["wait","work"]:
  timer=maxf(0,timer-delta);work_time+=delta
  # Looking around is discrete, not a continuously recalculated tiny movement.
  if timer>0:
   var bucket:=int(work_time/1.8)
   if bucket!=gaze_bucket:
    gaze_bucket=bucket
    if role!="merchant":actor.facing=[0,2,4,6][rng.randi()%4]
   return Vector2.ZERO
  if goals.size()<2:begin_wait();return Vector2.ZERO
  var next: int=(last_goal+1+rng.randi_range(0,goals.size()-2))%goals.size()
  path=navigation.route(actor.position,goals[next]);replans+=1;last_goal=next;cursor=0
  if path.is_empty():begin_wait(2.5);return Vector2.ZERO
  state="walk"
 while cursor<path.size() and actor.position.distance_to(path[cursor])<4:cursor+=1
 if cursor>=path.size():begin_wait();return Vector2.ZERO
 return (path[cursor]-actor.position).normalized()
func report_progress(distance: float,desired: Vector2,delta: float) -> void:
 travelled+=distance
 if state!="walk":return
 if desired.length()>.05 and distance<delta*1.0:blocked_time+=delta
 else:blocked_time=0
 if blocked_time>.65:begin_wait(2.0)

func pause_near_resident() -> void:
 if role=="resident" and state=="walk" and social_cooldown<=0:
  begin_wait(1.4);social_cooldown=8.0
