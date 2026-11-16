class_name WooItemArt
extends Control
const SHEET=preload("res://assets/woo/v14/items.png")
const IDS=["potion","mana_potion","seal","leaf","key","chest"]
var item_id:="potion"
var animated:=false
var clock:=0.0
var reveal:=0.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
 if not animated:return
 clock+=delta;reveal=minf(1,reveal+delta*6);queue_redraw()
func _draw() -> void:
 var index:=IDS.find(item_id)
 if index<0:return
 var cell:=Vector2(SHEET.get_width()/3.0,SHEET.get_height()/2.0)
 var area:=minf(size.x,size.y)*(.9 if not animated else (.80+smoothstep(0,1,reveal)*.1))
 var center:=size/2
 var angle:=0.0
 if animated:
  if item_id=="seal":center.y+=sin(clock*1.8)*5;angle=sin(clock*.7)*.05
  elif item_id=="key":angle=sin(clock*.6)*.15
 draw_set_transform(center,angle)
 draw_texture_rect_region(SHEET,Rect2(Vector2.ONE*-area/2,Vector2.ONE*area),Rect2(Vector2(index%3,floori(index/3.0))*cell,cell))
 draw_set_transform(Vector2.ZERO)
 if animated:
  var color:=Color("7adfff") if item_id in ["mana_potion","leaf"] else Color("f5d18c")
  for i in range(7):
   var t:=clock*.6+i*TAU/7
   var p:=center+Vector2(cos(t)*area*.42,sin(t)*area*.35)
   color.a=.25+sin(clock*2+i)*.18;draw_circle(p,1.8,color)
  if item_id=="potion":
   var p:=center+Vector2(sin(clock*2)*area*.08,area*.14)
   draw_arc(p,area*.14,0,PI,18,Color(1,.6,.55,.36),1.4)
