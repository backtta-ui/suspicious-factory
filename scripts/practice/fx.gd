class_name WooPracticeFx
extends Node2D
var practice: Node
var clock:=0.0
func _ready() -> void:z_index=30
func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 if practice.session==null:return
 var session: WooPracticeSession=practice.session;var rules:=session.rules;var p:=session.self_player()
 for effect in rules.effects:
  var point: Vector2=effect.position
  if effect.kind in ["smoke","darkness"]:
   for i in range(8):draw_circle(point+Vector2(sin(i*2.1+clock*.3)*46,cos(i*1.4)*24),45,Color(.09,.12,.2,.35 if effect.kind=="smoke" else .5))
  elif effect.kind=="fake_flame":draw_circle(point+Vector2(0,-20+sin(clock*3)*3),8,Color(.4,.8,1,.8))
 if p.buff.get("shield",0)>rules.elapsed:draw_arc(p.position-Vector2(0,17),22,0,TAU,32,Color("f4d18a"),2,true)
 if p.buff.get("rescue",0)>rules.elapsed:draw_arc(p.position,17,0,TAU,24,Color("9de2be"),2,true)
 if p.buff.get("mask",0)>rules.elapsed:draw_arc(p.position-Vector2(0,22),17,-PI,0,24,Color("bea1e7"),2,true)
 for mark in rules.view("student").footprints:draw_circle(Vector2(mark[0],mark[1]),2,Color("94d9ed"))
 var jail: Vector2=rules.arena.jail
 draw_rect(Rect2(jail-Vector2(45,30),Vector2(90,60)),Color(.2,.3,.45,.15))
 for x in range(-40,41,16):draw_line(jail+Vector2(x,-40),jail+Vector2(x,20),Color(.55,.72,1,.6),2)
 for id in session.stats:
  var q: Dictionary=rules.players[id];var stat: Dictionary=session.stats[id]
  if q.buff.get("shield",0)>rules.elapsed:draw_arc(q.position-Vector2(0,17),21,0,TAU,30,Color("f4d18a"),2,true)
  if stat.windup>0:draw_arc(q.position,34,0,TAU,32,Color("ed8f80"),2,true)
  if stat.stun>rules.elapsed:draw_arc(q.position-Vector2(0,34),8,0,TAU,12,Color("e6cf8e"),1.5,true)
