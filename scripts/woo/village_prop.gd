class_name WooVillageProp
extends StaticBody2D
const Layout = preload("res://scripts/woo/village_layout.gd")
var kind := "tree"
var light: PointLight2D
func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var poly := Layout.footprint(kind)
	if not poly.is_empty():
		var collider := CollisionPolygon2D.new()
		collider.polygon = poly
		add_child(collider)
	else:
		var collider := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = Layout.radius(kind)
		collider.shape = circle
		add_child(collider)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/woo/"+kind+".png")
	sprite.position.y = -sprite.texture.get_height()/2.0+4
	add_child(sprite)
	if kind=="lantern":
		light = PointLight2D.new()
		light.texture = preload("res://assets/woo/light.png")
		light.texture_scale = 3.4
		light.position.y = -50
		light.color = Color("ffc987")
		light.energy = 1.25
		light.shadow_enabled = false
		add_child(light)
func _draw() -> void:
	var width := 72.0 if kind=="hanok" else (40.0 if kind=="market" else 17.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-width,-2),Vector2(4,-width*0.4),Vector2(width+18,8),Vector2(16,width*0.4+9)]),Color(0.035,0.06,0.07,0.4))
