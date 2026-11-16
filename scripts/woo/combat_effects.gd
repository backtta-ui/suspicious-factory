class_name WooCombatEffects
extends Node2D
const Config=preload("res://scripts/woo/hit_config.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var swings: Array[Dictionary]=[]
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
 ghosts.append({"p":actor.position+Vector2(0,-actor.jump_height),"layers":actor.wardrobe_visual.rendered_layers.duplicate(true),"life":.26})

func swing(p: Vector2,direction: Vector2,stage: int,mode: String,radius: float) -> void:
 if get_child_count()<24:
  var vfx:=preload("res://scripts/woo/attack_vfx.gd").new();vfx.position=p;vfx.direction=direction;vfx.stage=clampi(stage-1,0,3);vfx.radius=radius;add_child(vfx)
 swings.append({"p":p,"angle":direction.angle(),"stage":stage,"mode":mode,"radius":radius,"life":.24})
func _process(delta: float) -> void:
 for i in range(swings.size()-1,-1,-1):
  swings[i].life-=delta
  if swings[i].life<=0:swings.remove_at(i)
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
 for v in swings:
  var c:=Color("f8ce7b") if v.stage==2 or v.mode=="talisman" else (Color("c29eff") if v.stage==3 else Color("77d7ff"))
  c.a=v.life/.24*.75
  var radius: float=v.radius*(1-v.life/.24*.4)
  draw_arc(v.p+Vector2(0,-14),radius,v.angle-1.05,v.angle+1.05,24,c,3 if v.stage<4 else 6,true)
  if v.stage==3:draw_line(v.p-Vector2.from_angle(v.angle)*20,v.p+Vector2.from_angle(v.angle)*radius,Color("dfca92"),4,true)
  if v.stage==3:draw_arc(v.p+Vector2(0,-16),radius-8,v.angle-.9,v.angle+.9,16,Color(.75,.45,1,c.a),2,true)
  if v.stage==4:draw_arc(v.p+Vector2(0,-20),radius*.65,v.angle-1.4,v.angle+1.4,24,c,2,true)
  if v.mode=="air" or v.mode=="landing":draw_arc(v.p,radius*.5,0,TAU,24,c,3,true)
 for v in ghosts:
  draw_set_transform(v.p)
  for layer in v.layers:draw_polygon(layer.points,PackedColorArray([Color(.55,.7,1,v.life/.26*.38)]),layer.uv,layer.texture)
  draw_set_transform(Vector2.ZERO)
 for v in particles:
  var c: Color=v.color;c.a=v.life/Config.PARTICLE_TIME
  draw_rect(Rect2(v.p,Vector2(2,2) if not v.death else Vector2(3,3)),c)
 for n in numbers:
  var c: Color=n.color;c.a=n.life/Config.NUMBER_TIME
  draw_string_outline(FONT,n.p,str(n.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color(0,0,0,c.a))
  draw_string(FONT,n.p,str(n.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,13,c)
