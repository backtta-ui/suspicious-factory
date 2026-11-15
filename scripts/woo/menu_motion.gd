extends Control
## Slow Ken Burns motion with independent petals. Entire layer ignores touch.
var elapsed:=0.0
var reduced:=false
var background: TextureRect
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 background=TextureRect.new();background.texture=preload("res://assets/woo/hd/title.png")
 background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.show_behind_parent=true;add_child(background)
 var shader:=Shader.new()
 shader.code="shader_type canvas_item; uniform float clock=0.;uniform float strength=1.;void fragment(){float z=.958+sin(clock*.11)*.005*strength;vec2 shift=vec2(sin(clock*.075)*.008,cos(clock*.09)*.005)*strength;vec2 uv=(UV-.5)*z+.5+shift;COLOR=texture(TEXTURE,uv);COLOR.rgb*=1.+sin(clock*.8)*.008*strength;}"
 var material:=ShaderMaterial.new();material.shader=shader;background.material=material
func _process(delta: float) -> void:
 elapsed+=delta
 background.material.set_shader_parameter("clock",elapsed)
 background.material.set_shader_parameter("strength",0.0 if reduced else 1.0)
 queue_redraw()
func _draw() -> void:
 if reduced:return
 for i in range(20):
  var p:=Vector2(fposmod(i*.618+elapsed*.009,1)*size.x,fposmod(i*.317+elapsed*.013,1)*size.y)
  var s:=1.0+i%3
  draw_colored_polygon(PackedVector2Array([p+Vector2(-2,-1)*s,p+Vector2(1,-2)*s,p+Vector2(3,1)*s,p+Vector2(-1,2)*s]),Color(.95,.6,.75,.22+i%3*.13))
