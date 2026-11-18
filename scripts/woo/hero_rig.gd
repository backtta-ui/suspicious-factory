class_name WooHeroRig
extends Node2D
## Shared held-weapon effects. Whole-body art is owned by WooWardrobeVisual.
const SHEET=preload("res://assets/woo/hd/hero.png")
const FRAMES=preload("res://scripts/woo/art_frames.gd")
const SCALE=.34
var actor: WooActor
func _process(_delta: float) -> void:
 if not is_instance_valid(actor):return
 visible=not actor.npc and not actor.jar and actor.appearance_form=="human" and not actor.ingame_art
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
 if not is_instance_valid(actor) or actor.action_left<=0:return
 var phase: float=clampf(1-actor.action_left/maxf(actor.pose_duration,.001),0,1)
 var pulse:=sin(phase*PI)
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
