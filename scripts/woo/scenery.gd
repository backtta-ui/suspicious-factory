class_name WooScenery
extends Node2D
## Non-colliding far scenery, fading before any foreground prop's ground contact.
var sprite: Sprite2D
const PANORAMA = preload("res://assets/woo/hd/panorama.png")
func _ready() -> void:
	z_index=-90
	sprite=Sprite2D.new()
	sprite.texture=PANORAMA
	sprite.centered=false
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; render_mode unshaded; uniform float opacity=1.0; void fragment(){vec4 t=texture(TEXTURE,UV);COLOR=vec4(t.rgb,t.a*(1.0-smoothstep(0.01,0.16,UV.y))*opacity);}"
	var material:=ShaderMaterial.new();material.shader=shader;sprite.material=material
	add_child(sprite)
func _process(_delta: float) -> void:
	var camera:=get_viewport().get_camera_2d()
	if not camera: return
	var view_size:=get_viewport_rect().size/camera.zoom
	position=camera.get_screen_center_position()-view_size/2
	sprite.scale=Vector2.ONE*view_size.x/PANORAMA.get_width()
	sprite.material.set_shader_parameter("opacity",smoothstep(90,250,position.y))
