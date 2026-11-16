class_name WooSpellEffects
extends RefCounted
const ATLAS=preload("res://assets/woo/spells/effects.png")
const FOOTPRINTS=preload("res://assets/woo/spells/footprints.svg")
const CELLS={"transform":0,"blink":1,"clone":2,"track":3,"shield":4,"smoke":5,"mask":6,"rescue":7,"capture":8,"darkness":9,"fake_flame":10,"flame":10,"shadow":11,"mimic":12,"talisman":13}
static func sprite(c: Node2D,id: String,p: Vector2,size: Vector2,alpha: float=1.0,angle: float=0.0) -> void:
 var index: int=CELLS.get(id,0);var cell:=Vector2(ATLAS.get_size())/4.0
 c.draw_set_transform(p,angle)
 c.draw_texture_rect_region(ATLAS,Rect2(-size/2,size),Rect2(Vector2(index%4,index/4)*cell,cell),Color(1,1,1,clampf(alpha,0,1)))
 c.draw_set_transform(Vector2.ZERO)
static func cloud(c: Node2D,kind: String,p: Vector2,clock: float,fade: float=1.0) -> void:
 # Irregular ink silhouettes tile within the actual 130-unit effect radius.
 # Same geometry is used offline and online; no full-screen black overlay.
 for i in range(9):
  var phase:=clock*.34+i*1.73;var offset:=Vector2.from_angle(i*TAU/9+sin(phase)*.13)*(36 if i%3==0 else 77)
  sprite(c,"smoke" if kind=="smoke" else "darkness",p+offset+Vector2(0,-14),Vector2(100,86)*(1+.08*sin(phase)),fade*(.64 if kind=="smoke" else .78),sin(phase)*.1)
static func footprints(c: Node2D,marks: Array) -> void:
 for mark in marks:
  if mark.size()<5:continue
  c.draw_set_transform(Vector2(mark[0],mark[1]),float(mark[2])+PI/2)
  c.draw_texture_rect_region(FOOTPRINTS,Rect2(-3,-5,6,10),Rect2(int(mark[3])*16,0,16,28),Color(1,1,1,1.0-float(mark[4])/6))
 c.draw_set_transform(Vector2.ZERO)
