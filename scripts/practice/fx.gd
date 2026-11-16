class_name WooPracticeFx
extends Node2D
const FX=preload("res://scripts/spells/effects.gd")
var practice: Node
var clock:=0.0
func _ready() -> void:z_index=30
func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 if practice.session==null:return
 var session: WooPracticeSession=practice.session;var rules:=session.rules;var p:=session.self_player()
 for effect in rules.effects:
  var point: Vector2=effect.position
  if effect.kind in ["smoke","darkness"]:FX.cloud(self,effect.kind,point,clock,minf(1,effect.until-rules.elapsed))
  elif effect.kind=="fake_flame":FX.sprite(self,"flame",point+Vector2(0,-20+sin(clock*3)*3),Vector2(24,35))
 for id in ["shield","rescue","mask"]:
  if p.buff.get(id,0)>rules.elapsed:FX.sprite(self,id,p.position-Vector2(0,22),Vector2(48,50),.72)
 FX.footprints(self,rules.view("student").footprints)
 for event in session.visual_events:
  var age: float=rules.elapsed-event.time
  if age<.7:FX.sprite(self,event.kind,event.position-Vector2(0,17),Vector2(54,54)*(1+age*.65),1-age/.7,event.get("angle",0.0))
 if practice.aiming or practice.preview_until>rules.elapsed:
  var radius: float={"transform":rules.options.extract_range,"capture":48,"mimic":220,"smoke":130,"darkness":130,"rescue":68,"track":240,"blink":110,"shadow":150,"talisman":session.Attack.TALISMAN_RANGE}.get(session.selected,0)
  if session.selected in ["blink","shadow"]:draw_line(p.position,rules.arena.move(p.position,p.position+Vector2.from_angle(p.facing*PI/4)*radius),Color(.5,.8,1,.6),1.5)
  elif radius>0:draw_arc(p.position,radius,0,TAU,64,Color(.8,.75,.5,.38),1,true)
 var jail: Vector2=rules.arena.jail
 draw_rect(Rect2(jail-Vector2(45,30),Vector2(90,60)),Color(.2,.3,.45,.15))
 for x in range(-40,41,16):draw_line(jail+Vector2(x,-40),jail+Vector2(x,20),Color(.55,.72,1,.6),2)
 for id in session.stats:
  if not rules.can_observe("student",id):continue
  var q: Dictionary=rules.players[id];var stat: Dictionary=session.stats[id]
  if q.buff.get("shield",0)>rules.elapsed:draw_arc(q.position-Vector2(0,17),21,0,TAU,30,Color("f4d18a"),2,true)
  if stat.windup>0:draw_arc(q.position,34,0,TAU,32,Color("ed8f80"),2,true)
  if stat.stun>rules.elapsed:draw_arc(q.position-Vector2(0,34),8,0,TAU,12,Color("e6cf8e"),1.5,true)
