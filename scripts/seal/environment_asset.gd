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
  draw_rect(Rect2(-12,-22,24,22),Color("75523b"));draw_rect(Rect2(-11,-21,22,20),Color("bc9563"),false,2)
  for y in [-17,-11,-5]:draw_line(Vector2(-11,y),Vector2(11,y),Color("71523a"),1)
  draw_line(Vector2(-10,-20),Vector2(10,-2),Color("d9b77d"),2)
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
