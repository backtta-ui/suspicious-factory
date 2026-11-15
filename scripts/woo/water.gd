extends Node2D
const Layout=preload("res://scripts/woo/village_layout.gd")
var surface: Polygon2D
var time:=0.0
func _ready() -> void:
 z_index=-80
 var r: Rect2=Layout.POND
 surface=Polygon2D.new()
 surface.polygon=PackedVector2Array([r.position+Vector2(30,0),r.position+Vector2(r.size.x-30,0),r.position+Vector2(r.size.x,30),r.end-Vector2(0,30),r.end-Vector2(30,0),r.position+Vector2(30,r.size.y),r.position+Vector2(0,r.size.y-30),r.position+Vector2(0,30)])
 var shader:=Shader.new()
 shader.code="shader_type canvas_item; uniform float clock=0.; uniform float night=0.5; void fragment(){ vec2 p=VERTEX; float ripple=sin(p.x*.045+p.y*.08+clock*.7)*.5+.5; vec3 water=mix(vec3(.14,.34,.37),vec3(.29,.5,.52),pow(ripple,12.)*.45);COLOR=vec4(water*mix(1.,.82,night),1.); }"
 # Fragment VERTEX is viewport-relative; use UV through a white texture for stable ripples.
 shader.code="shader_type canvas_item; uniform float clock=0.; void fragment(){float w=sin(UV.x*46.+clock*.4)*sin(UV.y*74.+clock*.7)*.5+.5;vec3 c=mix(vec3(.14,.30,.34),vec3(.34,.50,.52),pow(w,16.)*.25);COLOR=vec4(c,1.);}"
 var material:=ShaderMaterial.new();material.shader=shader;surface.material=material
 var image:=Image.create(1,1,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE);surface.texture=ImageTexture.create_from_image(image)
 var uv:=PackedVector2Array()
 for p in surface.polygon:uv.append((p-r.position)/r.size)
 surface.uv=uv
 add_child(surface)
 var bridge:=Sprite2D.new();bridge.z_index=1;bridge.texture=load("res://assets/woo/v11/stone_bridge.png");bridge.position=Vector2(1700,1300);add_child(bridge)
 for rect in Layout.WATER_BLOCKS:
  var body:=StaticBody2D.new();body.collision_layer=1;body.collision_mask=2
  var shape:=RectangleShape2D.new();shape.size=rect.size
  var collider:=CollisionShape2D.new();collider.shape=shape;collider.position=rect.get_center();body.add_child(collider);add_child(body)
func _process(delta: float) -> void:
 time+=delta
 surface.material.set_shader_parameter("clock",time)
func _draw() -> void:
 var r: Rect2=Layout.POND
 var rim:=surface.polygon.duplicate();rim.append(rim[0]);draw_polyline(rim,Color("83877a"),10,true)

func draw_bridge(c: Node2D) -> void:
 # Walkable stone bridge is drawn independently above the water and matches the gap.
 for i in range(22):
  var p:=Vector2(1480+i*20,1275)
  for j in range(3):
   var rect:=Rect2(p+Vector2(0,j*17),Vector2(19,16))
   c.draw_rect(rect,Color("b6ada1") if (i+j)%3 else Color("9c9894"))
   c.draw_line(rect.position,rect.position+Vector2(19,0),Color("d1c7b4"),1)
 for y in [1273,1327]:
  c.draw_line(Vector2(1470,y),Vector2(1930,y),Color("777d7c"),5)
  for x in range(1470,1931,46):
   c.draw_rect(Rect2(x-3,y-7,6,12),Color("d2c5ad"))
   c.draw_circle(Vector2(x,y-7),4,Color("ded1b9"))
