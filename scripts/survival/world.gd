extends Node2D
const L=preload("res://scripts/survival/layout.gd")
const Prop=preload("res://scripts/worlds/plaza_prop.gd")
const GROUND=preload("res://assets/woo/worlds/plaza_ground.png")
var observer:=L.SPAWN
var roofs: Array=[]
var clock:=0.0
var rules: RefCounted
var aim:=Vector2.ZERO
var aim_active:=false
var aim_cancelled:=false
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;y_sort_enabled=true
 var ground:=Node2D.new();ground.z_index=-100;ground.draw.connect(draw_ground);add_child(ground)
 for i in range(L.ROOMS.size()):
  var room: Rect2=L.ROOMS[i]
  var floor:=Polygon2D.new();floor.polygon=PackedVector2Array([room.position,room.position+Vector2(room.size.x,0),room.end,room.position+Vector2(0,room.size.y)]);floor.color=Color("69617f");floor.z_index=-50;add_child(floor)
  var roof:=Node2D.new();roof.position=room.position+Vector2(room.size.x/2,60);roof.z_index=20;add_child(roof)
  var prop:=Prop.new();prop.kind="hanok";prop.scale=Vector2(2,1.5);roof.add_child(prop);prop.collision_layer=0;prop.collision_mask=0
  var plaque:=Label.new();plaque.text=L.NAMES[i];plaque.position=Vector2(-45,-30);plaque.add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJK-Regular.ttc"));plaque.add_theme_font_size_override("font_size",14);roof.add_child(plaque)
  roofs.append({"node":roof,"room":room})
 for p in [Vector2(200,230),Vector2(700,180),Vector2(1160,240),Vector2(1570,160),Vector2(160,970),Vector2(750,1240),Vector2(1560,1200)]:add_prop("great_tree",p,.7)
 for p in [Vector2(240,600),Vector2(690,570),Vector2(1110,470),Vector2(1420,770),Vector2(1120,1150),Vector2(720,1100),Vector2(1520,880)]:add_prop("stone_lantern",p,1)
 for rect in L.BAMBOO:
  for y in range(int(rect.position.y),int(rect.end.y),50):add_prop("bamboo",Vector2(rect.position.x,y),.55)
 for data in L.OBJECTS:
  var asset:=preload("res://scripts/seal/environment_asset.gd").new();asset.kind=data.kind;asset.position=data.p;add_child(asset)
 var fx:=Node2D.new();fx.z_index=5;fx.draw.connect(draw_effects);add_child(fx);fx.name="Effects"
func add_prop(kind: String,p: Vector2,scale_value: float) -> void:
 var prop:=Prop.new();prop.kind=kind;prop.position=p;prop.scale=Vector2.ONE*scale_value;add_child(prop);prop.collision_layer=0;prop.collision_mask=0
func draw_ground() -> void:
 var node: Node2D=get_child(0)
 for y in range(0,int(L.SIZE.y),64):
  for x in range(0,int(L.SIZE.x),64):
   node.draw_texture_rect_region(GROUND,Rect2(x,y,64,64),Rect2(820+(x/64)%3*64,800+(y/64)%3*64,64,64),Color("a8a0b9"))
 for room in L.ROOMS:node.draw_rect(room,Color("656078"))
 node.draw_rect(L.POND,Color("263b5b"));node.draw_rect(L.POND.grow(4),Color("aaa2bd"),false,4)
 for rect in L.HARD+L.BAMBOO:node.draw_rect(rect,Color("766c8d"));node.draw_rect(rect,Color("aea2b2"),false,2)
 for rect in L.LOW:node.draw_rect(rect,Color("b19474"));node.draw_rect(rect,Color("e1c19c"),false,2)
 node.draw_rect(L.ROOF_PATH,Color("645875"))
 for y in range(280,600,18):node.draw_line(Vector2(1280,y),Vector2(1390,y),Color("a393ad"),2)
 # Stairs are the only open entrance to the elevated roof route.
 for y in range(570,625,10):node.draw_line(Vector2(1270,y),Vector2(1400,y),Color("d8c6ac"),3)
 node.draw_arc(L.SPAWN,100,0,TAU,64,Color("9f8eb6"),3,true)
func _process(delta: float) -> void:
 clock+=delta
 for entry in roofs:
  var room: Rect2=entry.room;var hidden: bool=room.grow(25).has_point(observer) or observer.distance_to(room.position+Vector2(room.size.x/2,100))<180
  entry.node.modulate.a=move_toward(entry.node.modulate.a,.16 if hidden else 1,delta*6)
 get_node("Effects").queue_redraw()
func draw_effects() -> void:
 var node: Node2D=get_node("Effects")
 for i in range(8):
  var y:=L.POND.position.y+15+i*20;node.draw_line(Vector2(L.POND.position.x+10,y),Vector2(L.POND.end.x-10,y+sin(clock+i)*3),Color(.45,.62,.85,.3),1)
 for rect in L.HARD+L.BAMBOO:node.draw_rect(rect,Color("766c8d"));node.draw_rect(rect,Color("aaa0b4"),false,2)
 if rules==null:return
 if aim_active:
  var origin: Vector2=rules.players.human.position
  node.draw_line(origin,origin+aim*120,Color("e77b95") if aim_cancelled else Color("9fcaff"),3,true)
  node.draw_arc(origin+aim*120,14,0,TAU,24,Color("e77b95") if aim_cancelled else Color("9fcaff"),2,true)
 var circle: Dictionary=rules.circle();node.draw_arc(circle.center,circle.radius,0,TAU,128,Color(.45,.8,1,.7),2,true)
 node.draw_arc(circle.next_center,circle.next_radius,0,TAU,128,Color(.8,.65,1,.25),1,true)
 var human: Dictionary=rules.players.human
 if human.buff.get("sense",0)>rules.elapsed:
  var marks: Array=[]
  for p in rules.players.values():
   if p.id=="human":continue
   for i in range(p.trail.size()):
    var mark: Dictionary=p.trail[i]
    if mark.position.distance_to(human.position)<220:marks.append([mark.position.x,mark.position.y,mark.facing*PI/4,i%2,rules.elapsed-mark.time])
  preload("res://scripts/spells/effects.gd").footprints(node,marks)
 for e in rules.effects:
  if e.kind=="smoke":preload("res://scripts/spells/effects.gd").cloud(node,"smoke",e.position,clock)
  elif e.kind in ["seal","miss"]:
   node.draw_arc(e.position,60,-PI/3+e.facing*PI/4,PI/3+e.facing*PI/4,24,Color("e2a5f6") if e.kind=="seal" else Color("837d99"),3,true)
