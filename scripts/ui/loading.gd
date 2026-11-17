class_name WooLoadingOverlay
extends Control
const D=preload("res://scripts/ui/design.gd")
const PAPER=preload("res://assets/woo/v14/items.png")
var title:="공간을 준비하고 있습니다"
var clock:=0.0
var reduced:=false
var error:=false
var portal_intro:=false
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=110;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:clock+=delta;queue_redraw()
func _draw() -> void:
 if portal_intro:
  draw_rect(Rect2(0,size.y-92,size.x,92),Color(.04,.07,.11,.94))
  var p:=Vector2(size.x/2-260,size.y-47);var cell:=Vector2(PAPER.get_width()/3.0,PAPER.get_height()/2.0)
  draw_texture_rect_region(PAPER,Rect2(p-Vector2(15,27),Vector2(30,54)),Rect2(Vector2(2,0)*cell,cell))
  draw_arc(p,32,clock,clock+PI*1.4,24,Color(.2,.65,1,.6),2,true)
  draw_string(D.FONT,Vector2(size.x/2-210,size.y-38),title,HORIZONTAL_ALIGNMENT_CENTER,460,21,D.TEXT)
  return
 draw_rect(Rect2(Vector2.ZERO,size),D.INK)
 var center:=size/2-Vector2(0,24);var reveal:=clampf(clock/.35,0,1)
 for side in [-1,1]:
  for i in range(4):
   var p:=center+Vector2(side*(190+i*18),65+sin(i)*9)
   draw_rect(Rect2(p,Vector2(38,8)),Color(.15,.21,.3,.35))
 draw_arc(center,112,0,TAU,64,Color(.4,.5,.6,.14),1)
 for i in range(2):
  var line:=PackedVector2Array()
  for j in range(32):
   var a:=clock*(.55 if reduced else .9)+i*PI+j*.045;line.append(center+Vector2(cos(a)*112,sin(a)*62))
  draw_polyline(line,Color(.2,.65,1,.5*reveal),3,true)
 var cell:=Vector2(PAPER.get_width()/3.0,PAPER.get_height()/2.0)
 draw_texture_rect_region(PAPER,Rect2(center-Vector2(48,78+sin(clock*1.6)*3),Vector2(96,144)),Rect2(Vector2(2,0)*cell,cell),Color(1,.97+.03*sin(clock*2),.91+.07*sin(clock*2),reveal))
 draw_arc(center,78,-PI*.8,-PI*.2,24,Color(.9,.76,.43,(.25+.1*sin(clock*2))*reveal),1)
 for i in range(6 if reduced else 12):
  var a:=i*2.4+clock*.22;var p:=center+Vector2(cos(a)*(92+i%3*13),sin(a)*80-fposmod(clock*12+i*11,35));draw_rect(Rect2(p,Vector2(2,2)),Color(.48,.8,1,(.25+.2*sin(clock+i))*reveal))
 var lines:=title.split("\n")
 for i in range(lines.size()):draw_string(D.FONT,Vector2(size.x/2-320,center.y+142+i*32),lines[i],HORIZONTAL_ALIGNMENT_CENTER,640,22,D.TEXT if not error else Color("e7bbaa"))
