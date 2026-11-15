class_name WooVillage
extends Node2D
const Layout = preload("res://scripts/woo/village_layout.gd")
const Prop = preload("res://scripts/woo/village_prop.gd")
var ambience: CanvasModulate
var lanterns: Array[PointLight2D] = []
var time_of_day := 0.4
var cycle_enabled := true
func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ground := Node2D.new()
	ground.z_index = -100
	ground.draw.connect(draw_ground.bind(ground))
	add_child(ground)
	add_child(preload("res://scripts/woo/scenery.gd").new())
	add_child(preload("res://scripts/woo/petals.gd").new())
	for data in Layout.PROPS:
		var prop := Prop.new()
		prop.kind = data.kind
		prop.position = data.position
		add_child(prop)
		if is_instance_valid(prop.light): lanterns.append(prop.light)
	var boundary := StaticBody2D.new()
	boundary.collision_layer = 1
	boundary.collision_mask = 2
	for i in range(Layout.BOUNDS.size()):
		var shape := SegmentShape2D.new()
		shape.a = Layout.BOUNDS[i]
		shape.b = Layout.BOUNDS[(i+1)%Layout.BOUNDS.size()]
		var collider := CollisionShape2D.new()
		collider.shape = shape
		boundary.add_child(collider)
	add_child(boundary)
	ambience = CanvasModulate.new()
	add_child(ambience)
func _process(delta: float) -> void:
	if cycle_enabled: time_of_day = fposmod(time_of_day+delta/150.0,1.0)
	var night := (sin(time_of_day*TAU-PI/2)+1)/2
	ambience.color = Color("f2dfdf").lerp(Color("8094c6"),night*0.55)
	for light in lanterns: light.energy = 0.2+night*1.5
func draw_ground(canvas: Node2D) -> void:
	for u in range(26):
		for v in range(26):
			var p := Vector2(900+(u-v)*32,80+(u+v)*16)
			var tile := PackedVector2Array([p+Vector2(0,-16),p+Vector2(32,0),p+Vector2(0,16),p+Vector2(-32,0)])
			var road := absi(u-12)<=2 or absi(v-12)<=2 or p.distance_to(Vector2(900,530))<210
			var hash_value := absi(u*7919+v*104729+u*v*73)
			var color := Color("5d5265") if road else Color("293c3c")
			color = color.lightened(float(hash_value%7)*0.009)
			canvas.draw_colored_polygon(tile,color)
			if road:
				var colors: Array[Color]=[Color("726574"),Color("7a6c79"),Color("6f6473"),Color("82717e"),Color("736975")]
				for j in range(16):
					var a:=j%4;var b:=floori(float(j)/4)
					var c: Vector2=p+Vector2((a-b)*8,(a+b)*4-12)
					var stone:=PackedVector2Array([c+Vector2(-7.5,0),c+Vector2(0,-3.5),c+Vector2(7.5,0),c+Vector2(0,3.5)])
					canvas.draw_colored_polygon(stone,colors[(hash_value+j*7)%colors.size()])
					canvas.draw_line(c+Vector2(-7,0),c+Vector2(0,3),Color("413b4b"),1)
					canvas.draw_line(c+Vector2(0,-3),c+Vector2(7,0),Color("a48a93"),0.7)
			else:
				for j in range(4):
					var offset:=Vector2((hash_value+j*7)%25-12,(hash_value+j*11)%14-7)
					canvas.draw_line(p+offset,p+offset+Vector2(0,-3),Color("53634e"))
			if hash_value%3==0:
				canvas.draw_rect(Rect2(p+Vector2((hash_value%19)-9,hash_value%7),Vector2(2,1)),Color("bb829d"))

	# Boundary is independently collidable; stones and fence silhouettes show its extent.
	for i in range(Layout.BOUNDS.size()):
		var a: Vector2 = Layout.BOUNDS[i]
		var b: Vector2 = Layout.BOUNDS[(i+1)%Layout.BOUNDS.size()]
		var count := ceili(a.distance_to(b)/22)
		for j in range(count):
			var p := a.lerp(b,float(j)/count)
			canvas.draw_rect(Rect2(p-Vector2(8,5),Vector2(16,9)),Color("424e4b"))
			canvas.draw_line(p+Vector2(-6,-5),p+Vector2(7,-5),Color("7a8272"),2)
