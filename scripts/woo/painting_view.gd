class_name WooPaintingView
extends Control
const FOX=preload("res://assets/woo/v13/fox_painting.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
var index:=0
var clock:=0.0
var reduced:=false
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 clock+=delta
 queue_redraw()
func _draw() -> void:
 draw_style_box(border(),Rect2(Vector2.ZERO,size))
 var box:=Rect2(Vector2(6,6),size-Vector2(12,12))
 if index==0:draw_texture_rect(FOX,box,false)
 else:draw_texture_rect_region(DECOR,box,Rect2(index*425,0,425,411))
 # Localized mist, river reflection and foreground bamboo sway; art stays fixed.
 if index==0:
  for i in range(3 if reduced else 6):
   var x:=fposmod(i*.21+clock*.009,1.15)-.1
   var alpha:=.07+sin(clock*.5+i)*.025
   mist_ellipse(Vector2(x,.68+i%2*.06)*size,Vector2(.20,.018)*size,Color(.68,.77,.91,alpha))
  for side in [0,1]:
   for i in range(3):
    var base:=Vector2(size.x*(.025+i*.028 if side==0 else .96-i*.018),size.y*.93)
    var tip:=base+Vector2(sin(clock*.7+i)*2,-size.y*.58)
    draw_line(base,tip,Color(.17,.38,.36,.44),3)
    for leaf in range(3):draw_line(tip+Vector2(0,leaf*22),tip+Vector2((12 if side==0 else -12),leaf*22-5+sin(clock+i)),Color(.39,.61,.51,.45),2)
  var shine:=pow(maxf(0,sin(clock*.6)),20)
  draw_circle(size*Vector2(.772,.498),1.6,Color(1,.9,.5,shine))
  for i in range(4):
   var pos:=Vector2(.57+i*.03,.77+sin(clock*1.3+i)*.006)*size
   draw_line(pos,pos+Vector2(22,0),Color(.65,.85,1,.16),1)
 for i in range(4 if reduced else 10):
  var t:=clock*.23+i*TAU/10
  draw_circle(Vector2(.5+cos(t)*.47,.5+sin(t)*.46)*size,1.5,Color(.66,.82,1,.6))
func mist_ellipse(center: Vector2,radius: Vector2,color: Color) -> void:
 var points:=PackedVector2Array()
 for i in range(24):points.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radius)
 draw_colored_polygon(points,color)
func border() -> StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=Color("171929");s.border_color=Color("c9ad76");s.set_border_width_all(3);return s
