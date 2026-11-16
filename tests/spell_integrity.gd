extends SceneTree
const Session=preload("res://scripts/practice/session.gd")
const Appearance=preload("res://scripts/wardrobe/catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func _initialize() -> void:
 var s:=Session.new(Appearance.DEFAULT);s.npc_mode="idle";var r:=s.rules;var p: Dictionary=r.players.blue
 p.position=Vector2(600,650);p.intent=Vector2.ZERO
 for i in range(30):r.tick(.05)
 check(p.trail.is_empty(),"stationary NPC creates no fabricated footprints")
 p.intent=Vector2.RIGHT
 for i in range(25):r.tick(.05)
 check(p.trail.size()>=3,"actual walking creates distance-spaced footprints")
 var alternate:=true
 for i in range(1,p.trail.size()):
  if p.trail[i].side==p.trail[i-1].side:alternate=false
  if absf(p.trail[i].heading)>.01:alternate=false
 check(alternate,"left and right soles alternate in actual movement direction")
 p.intent=Vector2.ZERO;p.position=Vector2(600,650);p.trail.clear();p.step_distance=0.0
 p.intent=Vector2.RIGHT;p.position=Vector2(936,410)
 for i in range(30):r.tick(.05)
 check(p.trail.is_empty(),"holding movement against wall creates no footsteps")
 p.intent=Vector2.ZERO;p.position=Vector2(600,650);r.players.student.position=Vector2(600,460)
 r.effects=[{"kind":"smoke","position":p.position,"until":r.elapsed+6}]
 check(not r.can_observe("student","blue"),"smoke hides inside target from outside observer")
 r.players.student.position=Vector2(600,610)
 check(r.can_observe("student","blue"),"nearby recognition remains within 85 world units")
 r.players.student.position=Vector2(600,460);r.effects[0].kind="darkness"
 check(r.can_observe("student","blue"),"darkness has observer-local veil, distinct from smoke crossing")
 r.players.student.position=Vector2(600,550);p.position=Vector2(600,740)
 check(not r.can_observe("student","blue"),"darkness reduces vision for observer inside veil")
 print("SPELL INTEGRITY: %d checks / %d failures"%[checks,failures]);quit(1 if failures else 0)
