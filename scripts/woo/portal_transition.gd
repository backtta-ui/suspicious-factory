extends Control
var painting: Texture2D=preload("res://assets/woo/v13/fox_painting.png")
var world_title:="여우의 숲"
var clock:=0.0
var reverse:=false
var reduced:=false
var finishing:=false
var finish_alpha:=1.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_STOP;z_index=100
func _process(delta: float) -> void:
 clock+=delta
 if finishing:finish_alpha=maxf(0,finish_alpha-delta/.7)
 queue_redraw()
func _draw() -> void:
 var p:=clampf(clock/1.65,0,1)
 draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.018,.04,clampf(p*1.5,0,1)*finish_alpha))
 var zoom:=smoothstep(0,1,1-p if reverse else p)
 var rect:=Rect2(size/2-(Vector2(730,290).lerp(size,zoom))/2,Vector2(730,290).lerp(size,zoom))
 draw_texture_rect(painting,rect,false,Color(1,1,1,finish_alpha*(1-p*.75)))
 draw_rect(rect,Color(1,.84,.45,(1-p)*finish_alpha),false,3+sin(clock*8)*1.5)
 var center:=size/2
 for i in range(6 if reduced else 12):
  var angle:=clock*3+i*TAU/12
  var radius: float=(1-p)*290+30
  var point:=center+Vector2(cos(angle),sin(angle)*.55)*radius
  draw_circle(point,3,Color(.5,.75,1,(1-p)*finish_alpha))
  if i%3==0:draw_set_transform(point,angle*.2);draw_rect(Rect2(-5,-11,10,22),Color(.9,.75,.4,(1-p)*finish_alpha));draw_line(Vector2(-2,-6),Vector2(2,6),Color(.5,.1,.08,(1-p)*finish_alpha),2);draw_set_transform(Vector2.ZERO)
 # Ink tendrils independently spiral inward, never move/warp the entire title/plaza.
 for i in range(8):
  var points:=PackedVector2Array()
  for j in range(24):
   var t:=float(j)/23
   var angle: float=i*TAU/8+t*3.8+clock*2*( -1 if reverse else 1)
   var radius: float=t*size.length()*.65*(.5+p)
   points.append(center+Vector2(cos(angle),sin(angle)*.65)*radius)
  draw_polyline(points,Color(.025,.02,.045,p*finish_alpha),4+p*70,true)
 if p>.8:draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.02,.045,(p-.8)*5*finish_alpha))

 draw_string(preload("res://scripts/ui/design.gd").FONT,size/2+Vector2(-260,100),("광장으로 돌아갑니다" if reverse else world_title+" · 그림을 펼칩니다"),HORIZONTAL_ALIGNMENT_CENTER,520,22,Color(1,.9,.7,finish_alpha))
