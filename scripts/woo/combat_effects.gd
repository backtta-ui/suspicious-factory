class_name WooCombatEffects
extends Node2D
const Config=preload("res://scripts/woo/hit_config.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var particles: Array[Dictionary]=[]
var numbers: Array[Dictionary]=[]
var ghosts: Array[Dictionary]=[]
var rng:=RandomNumberGenerator.new()
func _ready() -> void:z_index=50;rng.seed=130013
func burst(p: Vector2,amount: int,gold: bool,death: bool) -> void:
 while particles.size()>120:particles.pop_front()
 var color:=Color("f6ce73") if gold else Color("83d5ff")
 for i in range(Config.PARTICLE_COUNT):
  var angle:=TAU*i/Config.PARTICLE_COUNT+rng.randf_range(-.15,.15)
  particles.append({"p":p+Vector2(0,-17),"v":Vector2.from_angle(angle)*rng.randf_range(25,65)*(1.4 if death else 1.0),"life":Config.PARTICLE_TIME,"color":color,"death":death})
 if amount>0:
  if numbers.size()>=16:numbers.pop_front()
  numbers.append({"p":p+Vector2(-6,-45),"life":Config.NUMBER_TIME,"amount":amount,"color":color})
func afterimage(actor: WooActor) -> void:
 if ghosts.size()>=12:ghosts.pop_front()
 ghosts.append({"p":actor.position,"region":actor.sprite.region_rect,"offset":actor.sprite.offset,"scale":actor.sprite.scale,"texture":actor.sprite.texture,"life":.26})
func _process(delta: float) -> void:
 for i in range(particles.size()-1,-1,-1):
  var v:=particles[i];v.life-=delta;v.p+=v.v*delta;v.v*=maxf(0,1-delta*3)
  if v.life<=0:particles.remove_at(i)
 for i in range(numbers.size()-1,-1,-1):
  numbers[i].life-=delta;numbers[i].p.y-=delta*24
  if numbers[i].life<=0:numbers.remove_at(i)
 for i in range(ghosts.size()-1,-1,-1):
  ghosts[i].life-=delta
  if ghosts[i].life<=0:ghosts.remove_at(i)
 queue_redraw()
func _draw() -> void:
 for v in ghosts:
  var rect: Rect2=Rect2(v.p+(v.offset-v.region.size/2)*v.scale,v.region.size*v.scale)
  draw_texture_rect_region(v.texture,rect,v.region,Color(.55,.7,1,v.life/.26*.38))
 for v in particles:
  var c: Color=v.color;c.a=v.life/Config.PARTICLE_TIME
  draw_rect(Rect2(v.p,Vector2(2,2) if not v.death else Vector2(3,3)),c)
 for n in numbers:
  var c: Color=n.color;c.a=n.life/Config.NUMBER_TIME
  draw_string_outline(FONT,n.p,str(n.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color(0,0,0,c.a))
  draw_string(FONT,n.p,str(n.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,13,c)
