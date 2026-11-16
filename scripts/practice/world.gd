class_name WooPracticeWorld
extends Node2D
const L=preload("res://scripts/practice/layout.gd")
const Prop=preload("res://scripts/woo/village_prop.gd")
func _ready() -> void:
 y_sort_enabled=true;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var ground:=Sprite2D.new();ground.texture=load("res://assets/woo/practice_ground.png");ground.centered=false;ground.z_index=-100;add_child(ground)
 for data in [["hanok",Vector2(640,190)],["tree",Vector2(150,220)],["tree",Vector2(1100,240)],["tree",Vector2(150,790)],["tree",Vector2(1150,830)],["lantern",Vector2(450,270)],["lantern",Vector2(850,270)],["lantern",Vector2(1080,680)]]:
  var prop:=Prop.new();prop.kind=data[0];prop.position=data[1];add_child(prop)
 var nameplate:=Label.new();nameplate.text="도술 익히기 · 자유 수련";nameplate.position=Vector2(510,230);nameplate.add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJK-Regular.ttc"));nameplate.add_theme_font_size_override("font_size",16);add_child(nameplate)
func draw_ground(c: Node2D) -> void:
 var terrain=preload("res://scripts/woo/terrain.gd")
 var rng:=RandomNumberGenerator.new();rng.seed=20042004
 for y in range(2):
  for x in range(3):c.draw_texture_rect(terrain.GRASS,Rect2(x*512,y*512,512,512),false,Color("d9d0bc"))
 terrain.pave(c,Vector2(640,535),Vector2(480,320),rng,Color("a0968c"))
 terrain.pave(c,Vector2(640,250),Vector2(170,70),rng,Color("aa9b85"))
 for i in range(110):
  var p:=Vector2(rng.randf_range(70,1200),rng.randf_range(75,900))
  if p.distance_to(Vector2(640,535))>430:c.draw_circle(p,1.2,Color("cfa8ab"))
 for block in L.BLOCKS:
  c.draw_rect(block,Color("5d4b43"));c.draw_rect(block,Color("c0a275"),false,3)
 for y in [38,930]:
  c.draw_line(Vector2(35,y),Vector2(1240,y),Color("82654f"),7)
 for x in [35,1240]:c.draw_line(Vector2(x,38),Vector2(x,930),Color("82654f"),7)
 c.draw_arc(Vector2(620,470),120,0,TAU,64,Color("d4b985"),2,true)
