class_name SealEnvironmentAsset
extends Node2D
const AnimalArt=preload("res://scripts/spells/animal_regions.gd")
const Arena=preload("res://scripts/seal/arena.gd")
const ANIMALS=preload("res://assets/woo/seal/animals.png")
const FRAMES=preload("res://scripts/woo/art_frames.gd")
const JARS=preload("res://assets/woo/hd/villagers_jars.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
var kind:="jar"
var clock:=0.0
var moving:=false
var facing:=0
func _ready() -> void:texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
 clock+=delta
 if kind in ["cat","dog","chicken"]:queue_redraw()
func _draw() -> void:
 if not Arena.KINDS.has(kind):return
 var size: Vector2=Arena.KINDS[kind].size
 draw_set_transform(Vector2.ZERO,0,Vector2(-1 if facing in [3,4,5] else 1,1))
 if kind in ["cat","dog","chicken"]:
  var row: int=["cat","dog","chicken"].find(kind);var cell:=Vector2(ANIMALS.get_width()/4.0,ANIMALS.get_height()/3.0)
  var frame:=int(clock*7)%4 if moving else 0
  var region: Array=AnimalArt.REGIONS[row*4+frame];size=AnimalArt.SIZES[kind]
  draw_texture_rect_region(ANIMALS,Rect2(-size.x/2,-size.y,size.x,size.y),Rect2(region[0],region[1],region[2],region[3]))
 elif kind=="jar":
  var f: Array=FRAMES.VILLAGERS_JARS[6]
  draw_texture_rect_region(JARS,Rect2(-size.x/2,-size.y,size.x,size.y),Rect2(f[0],f[1],f[2],f[3]))
 elif kind in ["dummy","lantern"]:
  var cell:=Vector2(DECOR.get_width()/3.0,DECOR.get_height()/3.0);var index:=6 if kind=="dummy" else 7
  var region: Array=AnimalArt.DECOR_REGIONS[0 if kind=="dummy" else 1]
  draw_texture_rect_region(DECOR,Rect2(-size.x/2,-size.y,size.x,size.y),Rect2(region[0],region[1],region[2],region[3]))
 elif kind=="crate":
  var w: float=size.x;var h: float=size.y
  draw_set_transform(Vector2.ZERO,0,Vector2(1,.45));draw_circle(Vector2(2,2),w*.62,Color(0,0,0,.35));draw_set_transform(Vector2.ZERO)
  draw_colored_polygon(PackedVector2Array([Vector2(-w*.5,-h*.72),Vector2(-w*.22,-h*.98),Vector2(w*.62,-h*.86),Vector2(w*.5,-h*.6)]),Color(.72,.53,.32))
  var top_pts:=PackedVector2Array([Vector2(-w*.5,-h*.72),Vector2(-w*.22,-h*.98),Vector2(w*.62,-h*.86),Vector2(w*.5,-h*.6),Vector2(-w*.5,-h*.72)])
  draw_polyline(top_pts,Color(.3,.2,.12,.55),1)
  for i in range(3):
   var t:=float(i+1)/4
   draw_line(Vector2(-w*.5,-h*.72).lerp(Vector2(-w*.22,-h*.98),t),Vector2(w*.5,-h*.6).lerp(Vector2(w*.62,-h*.86),t),Color(.45,.3,.18,.5),1)
  draw_rect(Rect2(-w*.5,-h*.72,w,h*.72),Color(.62,.44,.27))
  for y in [-h*.72+h*.18,-h*.72+h*.36,-h*.72+h*.54]:
   draw_line(Vector2(-w*.5,y),Vector2(w*.5,y),Color(.28,.18,.1,.6),1.2)
  draw_line(Vector2(-w*.5,-h*.72),Vector2(-w*.5,0),Color(.4,.26,.15,.8),2)
  draw_line(Vector2(w*.5,-h*.72),Vector2(w*.5,0),Color(.3,.19,.11,.8),2)
  draw_line(Vector2(-w*.46,-h*.16),Vector2(w*.46,-h*.62),Color(.74,.56,.34,.85),2.4)
  for corner in [Vector2(-w*.5,-h*.72),Vector2(w*.5,-h*.72),Vector2(-w*.5,-h*.1),Vector2(w*.5,-h*.1)]:
   draw_rect(Rect2(corner+Vector2(-2.4,-1.4),Vector2(4.8,3.2)),Color(.28,.26,.3))
  draw_line(Vector2(-w*.5,-h*.72)+Vector2(1,1),Vector2(w*.5,-h*.72)+Vector2(-1,1),Color(.95,.8,.55,.5),1.2)
  draw_circle(Vector2(0,-h*.42),1.6,Color(.25,.18,.12,.8))
 elif kind=="stele":
  var w: float=size.x;var h: float=size.y
  draw_set_transform(Vector2.ZERO,0,Vector2(1,.42));draw_circle(Vector2(2,3),w*.62,Color(0,0,0,.4));draw_set_transform(Vector2.ZERO)
  draw_rect(Rect2(-w*.5-5,-7,w+10,7),Color(.3,.29,.34))
  draw_rect(Rect2(-w*.5-3,-11,w+6,5),Color(.44,.43,.49))
  draw_rect(Rect2(-w*.5-3,-11,w+6,2),Color(.6,.59,.65,.6))
  var slab:=Rect2(-w*.42,-h,w*.84,h-11)
  draw_rect(slab,Color(.36,.35,.41))
  draw_circle(Vector2(0,slab.position.y+3),w*.42,Color(.36,.35,.41))
  draw_rect(Rect2(slab.position+Vector2(1,2),slab.size-Vector2(2,2)),Color(.52,.51,.57))
  draw_circle(Vector2(0,slab.position.y+4),w*.42-1.4,Color(.52,.51,.57))
  draw_rect(Rect2(w*.16,-h+4,w*.24,h-16),Color(.2,.2,.25,.45))
  draw_line(Vector2(-w*.34,-h+6),Vector2(-w*.34,-14),Color(.85,.84,.9,.35),1.4)
  draw_rect(Rect2(-w*.22,-h*.66,w*.44,w*.44),Color(.24,.22,.28,.55),false,1.2)
  for i in range(4):
   draw_line(Vector2(-3,-h*.6+i*5),Vector2(3,-h*.6+i*5),Color(.24,.2,.26,.8),1.4)
   draw_line(Vector2(-3,-h*.6+i*5),Vector2(-3,-h*.6+i*5+2),Color(.24,.2,.26,.8),1.4)
  for i in range(3):draw_rect(Rect2(-w*.2,-h*.3+i*5,w*.4,1.6),Color(.28,.25,.3,.55))
  draw_circle(Vector2(-w*.34,-8),3,Color(.28,.36,.26,.6))
  draw_circle(Vector2(w*.3,-6),2.2,Color(.28,.36,.26,.5))
  draw_rect(Rect2(-w*.42,-h,w*.84,h-11),Color(.15,.14,.18,.5),false,1)
  draw_circle(Vector2(0,-h*.5),1.6,Color(.91,.77,.44,.55))
 elif kind=="basket":
  draw_arc(Vector2(0,-12),10,PI,TAU,12,Color("b59164"),2)
  draw_colored_polygon(PackedVector2Array([Vector2(-12,-12),Vector2(12,-12),Vector2(8,0),Vector2(-8,0)]),Color("a77b4d"))
  for y in [-10,-6,-2]:draw_line(Vector2(-10,y),Vector2(10,y),Color("dfbd7d"),1)
 elif kind=="straw":
  draw_colored_polygon(PackedVector2Array([Vector2(-12,0),Vector2(-6,-24),Vector2(5,-24),Vector2(12,0)]),Color("c4aa68"))
  for x in range(-6,7,3):draw_line(Vector2(x,-22),Vector2(x*1.6,0),Color("ebd391"),1)
  draw_line(Vector2(-8,-10),Vector2(8,-10),Color("795c3c"),2)
 elif kind=="door":
  draw_rect(Rect2(-9,-35,18,35),Color("5e4540"));draw_rect(Rect2(-7,-33,14,30),Color("d5c2a0"))
  for x in [-4,0,4]:draw_line(Vector2(x,-33),Vector2(x,-3),Color("866548"),1)
  for y in [-26,-17,-9]:draw_line(Vector2(-7,y),Vector2(7,y),Color("866548"),1)
 draw_set_transform(Vector2.ZERO)
