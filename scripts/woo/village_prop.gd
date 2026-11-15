class_name WooVillageProp
extends StaticBody2D
const Layout = preload("res://scripts/woo/village_layout.gd")
var kind := "tree"
var light: Sprite2D
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
	var atlas:=AtlasTexture.new()
	atlas.atlas=preload("res://assets/woo/hd/environment.png")
	var index:=0
	var width:=220.0
	match kind:
		"hanok": index=0 if position.x<900 else 1
		"well": index=2;width=85
		"market": index=3;width=128
		"tree": index=4;width=150
		"lantern": index=5;width=100
	atlas.region=Rect2((index%3)*512,(index/3)*512,512,512)
	# Integer row division is explicit; no cropped atlas edits or generated scenery collisions.
	atlas.region.position.y=floori(float(index)/3)*512
	sprite.texture=atlas
	sprite.scale=Vector2.ONE*width/512
	sprite.position.y=(256-460)*width/512+8
	add_child(sprite)
	if kind=="lantern":
		light = Sprite2D.new()
		light.texture = preload("res://assets/woo/light.png")
		light.scale = Vector2.ONE*3.4
		light.position.y = -50
		light.modulate = Color(1.0,0.72,0.35,0.3)
		var glow_material := CanvasItemMaterial.new()
		glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		light.material = glow_material
		add_child(light)
func _draw() -> void:
	var width := 72.0 if kind=="hanok" else (40.0 if kind=="market" else 17.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-width,-2),Vector2(4,-width*0.4),Vector2(width+18,8),Vector2(16,width*0.4+9)]),Color(0.035,0.06,0.07,0.4))
