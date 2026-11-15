class_name WooActor
extends CharacterBody2D
var intent := Vector2.ZERO
var enabled := true
var running := false
var jar := false
var npc := false
var npc_name := ""
var tint := Color.WHITE
var facing := 2
var animation_time := 0.0
var cooldown := 0.0
var transforming := 0.0
var transform_target := false
var highlighted := false
var sprite: Sprite2D
var npc_origin := Vector2.ZERO
var npc_phase := 0.0
const WALK_SPEED := 88.0
const RUN_SPEED := 142.0
const JAR_SPEED := 46.0
const TRANSFORM_TIME := 0.42
const SPELL_COOLDOWN := 2.5
const SHEET = preload("res://assets/woo/woo_sheet.png")
const NPC_SHEET = preload("res://assets/woo/villager_sheet.png")
const JAR = preload("res://assets/woo/jar.png")
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	collider.shape = circle
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.modulate = tint
	add_child(sprite)
	npc_origin = position
func direction() -> Vector2:
	if not enabled or transforming>0: return Vector2.ZERO
	if npc: return intent.limit_length()
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	return (intent if intent.length()>0.05 else keyboard).limit_length()
func begin_transform() -> bool:
	if npc or not enabled or transforming>0 or cooldown>0: return false
	transform_target = not jar
	transforming = TRANSFORM_TIME
	velocity = Vector2.ZERO
	return true
func _physics_process(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if transforming>0:
		var before := transforming
		transforming = maxf(0,transforming-delta)
		if before>TRANSFORM_TIME/2 and transforming<=TRANSFORM_TIME/2: jar = transform_target
		if transforming==0: cooldown = SPELL_COOLDOWN
	if npc and enabled:
		npc_phase += delta
		var target := npc_origin+Vector2(sin(npc_phase*0.26+float(get_index()))*14,cos(npc_phase*0.22)*8)
		intent = (target-position).normalized()*0.3 if position.distance_to(target)>3 else Vector2.ZERO
	var move := direction()
	var speed := JAR_SPEED if jar else (RUN_SPEED if running or Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED)
	if npc: speed = 24
	velocity = move*speed
	move_and_slide()
	if move.length()>0.05: facing = posmod(roundi(move.angle()/(PI/4)),8)
	animation_time += delta*(11 if running and not jar else 7) if velocity.length()>2 else delta
	update_sprite()
	queue_redraw()
func update_sprite() -> void:
	if jar:
		sprite.texture = JAR
		sprite.region_enabled = false
		sprite.position = Vector2(0,-13)
	else:
		sprite.texture = NPC_SHEET if npc else SHEET
		sprite.region_enabled = true
		var frame := int(animation_time)%4 if velocity.length()>2 else (5 if fmod(animation_time,4)>3.8 else 4)
		sprite.region_rect = Rect2(frame*32,facing*48,32,48)
		sprite.position = Vector2(0,-22)
	if transforming>0:
		sprite.modulate = tint.lerp(Color("e9d29a"),0.5+sin(transforming*30)*0.25)
	else: sprite.modulate = tint
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-10,0),Vector2(0,-4),Vector2(12,1),Vector2(1,5)]),Color(0.02,0.04,0.06,0.38))
	if highlighted:
		draw_colored_polygon(PackedVector2Array([Vector2(-12,0),Vector2(0,-6),Vector2(12,0),Vector2(0,6)]),Color(0.9,0.75,0.4,0.35))
	if transforming>0:
		var phase := 1-transforming/TRANSFORM_TIME
		for i in range(10):
			var angle := TAU*i/10+phase*4
			var p := Vector2(cos(angle)*(10+phase*14),sin(angle)*(6+phase*9)-14)
			draw_rect(Rect2(p.floor(),Vector2(3,3)),Color("f4da8b"))
			if i%2==0: draw_rect(Rect2(p.floor()+Vector2(-4,-4),Vector2(2,2)),Color("8cb5ab"))
