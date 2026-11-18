extends CharacterBody3D
const MODEL=preload("res://assets/seowon3d/woochi-prototype.glb")
var model: Node3D
var animation: AnimationPlayer
var clips: Dictionary={}
var input_vector:=Vector2.ZERO
var camera_yaw:=0.0
var running:=false
var enabled:=true
var walk_speed:=2.8
var run_speed:=5.2
var acceleration:=11.0
var last_direction:=Vector3.FORWARD
var landing:=0.0
var air_time:=0.0
var animation_state:="idle"
var preview:=""
var preview_left:=0.0
var distance_walked:=0.0
var was_grounded:=false
func _ready() -> void:
 collision_layer=4;collision_mask=3;floor_snap_length=.3;floor_max_angle=deg_to_rad(42)
 var collider:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.27;capsule.height=2.05;collider.shape=capsule;collider.position.y=1.025;add_child(collider)
 model=MODEL.instantiate();add_child(model);model.rotation.y=PI
 animation=model.find_children("*","AnimationPlayer",true,false)[0]
 for name in animation.get_animation_list():
  var clean: String=str(name).get_slice("/",str(name).get_slice_count("/")-1)
  clips[clean]=name
  if clean in ["idle","walk","run","air","sealed","rescue"]:animation.get_animation(name).loop_mode=Animation.LOOP_LINEAR
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  for i in range(mesh.mesh.get_surface_count()):
   var original: Material=mesh.get_active_material(i)
   if original is StandardMaterial3D:
    var m: StandardMaterial3D=original.duplicate();m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON;m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED;m.roughness=.9;mesh.set_surface_override_material(i,m)
 play("idle")
func play(state: String) -> void:
 if not clips.has(state):return
 if animation_state==state and animation.current_animation==clips[state]:return
 animation_state=state;animation.play(clips[state],.12)
func jump() -> bool:
 if not enabled or not is_on_floor() or preview!="":return false
 velocity.y=5.2;air_time=0;play("jump_start");return true
func show_animation(state: String) -> void:
 if not clips.has(state):return
 preview=state;preview_left=2.0;play(state)
func _physics_process(delta: float) -> void:
 var grounded:=is_on_floor()
 if not grounded:velocity.y-=9.8*delta;air_time+=delta
 elif not was_grounded:landing=.22
 if preview_left>0:preview_left-=delta
 else:preview=""
 var desired:=Vector3.ZERO
 if enabled and preview=="":
  var axes:=Basis(Vector3.UP,camera_yaw);desired=(axes.x*input_vector.x+(-axes.z)*(-input_vector.y)).limit_length(1)
 var speed:=run_speed if running else walk_speed
 velocity.x=move_toward(velocity.x,desired.x*speed,acceleration*delta);velocity.z=move_toward(velocity.z,desired.z*speed,acceleration*delta)
 if desired.length()>.05:
  last_direction=desired.normalized();var heading:=atan2(-desired.x,-desired.z)+PI;model.rotation.y=lerp_angle(model.rotation.y,heading,1-exp(-delta*12))
 var before:=position;move_and_slide();distance_walked+=Vector2(position.x-before.x,position.z-before.z).length()
 if preview!="":play(preview)
 elif not is_on_floor():play("jump_start" if air_time<.15 else "air")
 elif landing>0:landing-=delta;play("land")
 elif Vector2(velocity.x,velocity.z).length()>.15:
  play("run" if running else "walk");animation.speed_scale=clampf(Vector2(velocity.x,velocity.z).length()/speed,.35,1.15)
 else:play("idle");animation.speed_scale=1
 was_grounded=grounded
