extends Control
## Original image is static. Only water/paper/cloud masks and independent FX animate.
const TITLE=preload("res://assets/woo/hd/title.png")
const GLOW=preload("res://assets/woo/light.png")
var elapsed:=0.0
var reduced:=false
var background: TextureRect
var redraw_elapsed:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 background=TextureRect.new();background.texture=TITLE
 background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.show_behind_parent=true;add_child(background)
 var material:=ShaderMaterial.new();material.shader=preload("res://assets/woo/v12/title_local.gdshader");background.material=material
func image_point(uv: Vector2) -> Vector2:
 var factor:=maxf(size.x/TITLE.get_width(),size.y/TITLE.get_height())
 return (size-TITLE.get_size()*factor)/2+uv*TITLE.get_size()*factor
func _process(delta: float) -> void:
 elapsed+=delta;redraw_elapsed+=delta
 background.material.set_shader_parameter("clock",elapsed)
 background.material.set_shader_parameter("strength",0.35 if reduced else 1.0)
 if redraw_elapsed>=1.0/(20 if reduced else 40):redraw_elapsed=0;queue_redraw()
func _draw() -> void:
 var factor:=maxf(size.x/TITLE.get_width(),size.y/TITLE.get_height())
 var hand:=image_point(Vector2(.367,.565))
 var orbit:=Vector2(51,27)*factor
 # Thin blue/violet arcs and individual orbiting sparks, confined to the hand.
 var points:=PackedVector2Array()
 for i in range(33):
  var angle: float=i*TAU/32+elapsed*.75
  points.append(hand+Vector2(cos(angle),sin(angle))*orbit)
 draw_polyline(points,Color(.45,.62,1,.22),2.4,true)
 var particles:=6 if reduced else 16
 for i in range(particles):
  var angle: float=elapsed*(.55+(i%3)*.17)+i*TAU/particles
  var p:=hand+Vector2(cos(angle)*orbit.x,sin(angle)*orbit.y)+Vector2(0,sin(angle*2)*3)
  draw_circle(p,1.1 if i%3 else 1.8,Color(.52 if i%2 else .72,.61,1,.35+.25*sin(angle)))
 var pulse:=.07+sin(elapsed*1.6)*.015
 draw_texture_rect(GLOW,Rect2(hand-Vector2(64,40)*factor,Vector2(128,80)*factor),false,Color(.25,.45,1,pulse))
 if not reduced and fmod(elapsed,6.0)<.13:
  var bolt:=PackedVector2Array([hand+Vector2(-22,-10),hand+Vector2(-12,-20),hand+Vector2(-8,-13),hand+Vector2(4,-28)])
  draw_polyline(bolt,Color(.7,.81,1,.7),1.2,true)
 # Depth layers: near petals are larger/faster; no wrap pop inside the screen.
 for i in range(7 if reduced else 22):
  var depth: float=.35+float(i%5)*.16
  var x:=fposmod(i*.618+elapsed*(.009+depth*.012),1.12)*size.x-size.x*.06
  var y:=fposmod(i*.317+elapsed*(.011+depth*.017),1.16)*size.y-size.y*.08
  var p:=Vector2(x+sin(elapsed*.6+i)*8,y)
  if Rect2(size.x-505,325,425,315).grow(8).has_point(p):continue
  var face:=image_point(Vector2(.23,.29))
  var face_fade:=smoothstep(65*factor,95*factor,p.distance_to(face))
  if face_fade<=0:continue
  var s:=.8+depth*1.5;var angle:=elapsed*(.3+depth*.3)+i
  var polygon:=PackedVector2Array()
  for v in [Vector2(-2,-1),Vector2(1,-2),Vector2(3,1),Vector2(-1,2)]:polygon.append(p+v.rotated(angle)*s)
  draw_colored_polygon(polygon,Color(.96,.63,.79,(.22+depth*.3)*face_fade))
 # Sparse translucent river mist, independent of the background and moon.
 if not reduced:
  for i in range(3):
   var p:=image_point(Vector2(.55+i*.10,.83+i*.025))+Vector2(sin(elapsed*.08+i)*24,0)
   draw_texture_rect(GLOW,Rect2(p-Vector2(150,24),Vector2(300,48)),false,Color(.7,.77,.9,.035))
