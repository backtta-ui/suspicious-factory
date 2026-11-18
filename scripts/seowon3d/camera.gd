extends Node3D
var target: CharacterBody3D
var world: Node3D
var yaw:=0.0
var pitch:=15.0
var distance:=4.5
var actual_distance:=4.5
var camera: Camera3D
var probe: SpringArm3D
var active:=true
var finger:=-1
var mouse_drag:=false
var sensitivity:=.006
var hit_distance:=4.5
func _ready() -> void:
 probe=SpringArm3D.new();probe.spring_length=4.5;probe.margin=.15;probe.collision_mask=1;var sphere:=SphereShape3D.new();sphere.radius=.2;probe.shape=sphere;add_child(probe);probe.add_excluded_object(target.get_rid());probe.add_child(Marker3D.new())
 camera=Camera3D.new();camera.fov=60;camera.keep_aspect=Camera3D.KEEP_HEIGHT;camera.near=.08;camera.far=140;add_child(camera);camera.make_current()
 global_position=target.global_position+Vector3(0,1.5,0);rotation=Vector3(deg_to_rad(-pitch),yaw,0);camera.position.z=distance
func reset_input() -> void:finger=-1;mouse_drag=false
func rotate_input(delta: Vector2) -> void:
 yaw=wrapf(yaw-delta.x*sensitivity,-PI,PI);pitch=clampf(pitch+rad_to_deg(delta.y*sensitivity),-20,55)
func _unhandled_input(event: InputEvent) -> void:
 if not active:return
 var width:=get_viewport().get_visible_rect().size.x
 if event is InputEventScreenTouch:
  if event.pressed and finger<0 and event.position.x>width*.42 and event.position.y>100:finger=event.index;get_viewport().set_input_as_handled()
  elif not event.pressed and event.index==finger:finger=-1;get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index==finger:rotate_input(event.relative);get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
  if event.pressed and event.position.x>width*.42 and event.position.y>100:mouse_drag=true;get_viewport().set_input_as_handled()
  elif not event.pressed:mouse_drag=false
 elif event is InputEventMouseMotion and mouse_drag:rotate_input(event.relative);get_viewport().set_input_as_handled()
func _physics_process(delta: float) -> void:
 var desired: Vector3=target.global_position+Vector3(0,1.5,0);global_position=global_position.lerp(desired,1-exp(-delta*12));rotation=Vector3(deg_to_rad(-pitch),yaw,0)
 var maximum: float=world.indoor_distance(global_position,global_basis.z,distance)
 probe.spring_length=maximum
 hit_distance=minf(maximum,probe.get_hit_length())
 var goal:=maxf(.25,hit_distance-.08)
 actual_distance=minf(actual_distance,goal) if goal<actual_distance else move_toward(actual_distance,goal,delta*2.2)
 camera.position=Vector3(0,0,actual_distance)
 # Never allow a low orbit to put the camera beneath the ground.
 if camera.global_position.y<.25:camera.global_position.y=.25
