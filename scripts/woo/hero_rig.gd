class_name WooHeroRig
extends Node2D
## Canonical original pixels at a single scale. Face/hat never come from a second atlas.
const SHEET=preload("res://assets/woo/hd/hero.png")
const FRAMES=preload("res://scripts/woo/art_frames.gd")
const SCALE=.34
var actor: WooActor
func _process(_delta: float) -> void:
 if not is_instance_valid(actor):return
 visible=not actor.npc and not actor.jar and actor.appearance_form=="human"
 position=Vector2(0,-actor.jump_height)
 modulate=actor.sprite.modulate
 rotation=actor.sprite.rotation
 if visible:queue_redraw()
func section(frame: Array,x: float,y: float,w: float,h: float,pivot: Vector2=Vector2.ZERO,angle: float=0) -> void:
 if w<=0 or h<=0:return
 var p:=Vector2((x-frame[4])*SCALE,(y-frame[5])*SCALE)
 draw_set_transform(pivot,angle)
 draw_texture_rect_region(SHEET,Rect2(p-pivot,Vector2(w,h)*SCALE),Rect2(frame[0]+x,frame[1]+y,w,h))
 draw_set_transform(Vector2.ZERO)
func _draw() -> void:
 if not is_instance_valid(actor):return
 var frame: Array=FRAMES.HERO[32+actor.facing]
 var head:=98.0;var hips:=127.0
 # Rigid head and common foot pivot preserve identity and apparent size.
 var center: float=frame[4]
 section(frame,center-17,head,34,hips-head)
 var phase: float=clampf(1-actor.action_left/maxf(actor.pose_duration,.001),0,1)
 var pulse:=sin(phase*PI)
 var stride:=sin(actor.animation_time*TAU/4) if actor.velocity.length()>2 and actor.action_left<=0 and actor.jump_height==0 else 0.0
 var left:=stride*.2;var right:=-stride*.2
 if actor.action_left>0:
  match actor.action_pose:
   0:left=-.25*pulse;right=-1.1*pulse
   1:left=.7*pulse;right=-.8+phase*1.7
   2:left=-.5*pulse;right=.8-phase*2
   3:left=.4*pulse;right=-1.3*pulse
   5:left=.6*pulse;right=.9*pulse
   6:left=-.3;right=.3
 if actor.jump_preparation>0:left=.25;right=-.25
 if actor.jump_height>0:
  var spread:=.45 if actor.jump_phase=="apex" else (.25 if actor.jump_phase=="rising" else .1)
  left-=spread;right+=spread
 if actor.landing_left>0:left=-.3*actor.landing_left/.18;right=.3*actor.landing_left/.18
 var shoulder_l:=Vector2(-6,-16);var shoulder_r:=Vector2(6,-16)
 section(frame,0,head,center-17,hips-head,shoulder_l,left)
 section(frame,center+17,head,frame[2]-center-17,hips-head,shoulder_r,right)
 section(frame,0,hips,center,frame[3]-hips,Vector2(-3,-5),sin(phase*PI)*.13 if actor.action_left>0 else stride*.2)
 section(frame,center,hips,frame[2]-center,frame[3]-hips,Vector2(3,-5),-sin(phase*PI)*.13 if actor.action_left>0 else -stride*.2)
 if actor.action_left>0:
  var direction:=Vector2.from_angle(actor.facing*PI/4)
  var hand:=Vector2(0,-17)+direction*(12+pulse*8)
  if actor.action_pose==2:
   var rod:=direction.rotated((phase-.5)*1.8)*26
   draw_line(hand-rod,hand+rod,Color("40333a"),5)
   draw_line(hand-rod,hand+rod,Color("b3986b"),2)
   draw_circle(hand+rod,2,Color("ead49a"))
  elif actor.action_pose in [1,5]:
   draw_set_transform(hand,phase*1.5);draw_rect(Rect2(-3,-7,6,14),Color("e8cf91"));draw_line(Vector2(-1,-4),Vector2(1,4),Color("b34342"),1);draw_set_transform(Vector2.ZERO)
  else:
   draw_arc(hand,3+pulse*5,-PI,PI,12,Color(.4,.8,1,pulse*.75),2)

 # Keep canonical face/hat above weapon trails; articulation never substitutes its pixels.
 section(frame,0,0,frame[2],head)
