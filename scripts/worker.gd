class_name FactoryWorker
extends CharacterBody2D

var hat: int = 1
var vest: int = 0
var nickname: String = "나"
var input_vector := Vector2.ZERO
var enabled := true
var facing := 1.0
var step := 0.0
const SPEED := 230.0
const OUTLINE := Color("172332")
const BLUE := Color("4386df")
const GREEN := Color("58a66c")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 17
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	var keyboard := Vector2.ZERO
	if enabled:
		keyboard = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := input_vector if input_vector.length() > 0.05 else keyboard
	velocity = direction.limit_length() * SPEED if enabled else Vector2.ZERO
	move_and_slide()
	if absf(velocity.x) > 1:
		facing = signf(velocity.x)
	step += delta * (12.0 if velocity.length() > 5 else 2.0)
	queue_redraw()

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var angle := TAU * i / 32
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
	draw_polyline(points, OUTLINE, 2.5, true)

func _draw() -> void:
	var moving := velocity.length() > 5
	var bob := sin(step) * (2.2 if moving else 0.6)
	var leg := sin(step) * (5.0 if moving else 0.0)
	draw_ellipse_shadow()
	ellipse(Vector2(-11, -3 + leg), Vector2(9, 9), Color("263448"))
	ellipse(Vector2(11, -3 - leg), Vector2(9, 9), Color("263448"))
	var body := Color("decdae") if vest == 0 else (BLUE if vest == 1 else GREEN)
	draw_style_box(body_style(body), Rect2(-24, -47 + bob, 48, 42))
	ellipse(Vector2(-29, -26 + bob - leg * 0.3), Vector2(8, 14), Color("eee1c5"))
	ellipse(Vector2(29, -26 + bob + leg * 0.3), Vector2(8, 14), Color("eee1c5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-5,-43+bob), Vector2(5,-43+bob), Vector2(7,-22+bob), Vector2(0,-15+bob), Vector2(-7,-22+bob)]), Color("f6ce4f"))
	draw_style_box(body_style(Color("eef3e6")), Rect2(11, -33 + bob, 10, 12))
	draw_line(Vector2(13,-29+bob), Vector2(19,-29+bob), BLUE, 2)
	ellipse(Vector2(0, -65 + bob), Vector2(36, 30), Color("fff9eb"))
	var eye_offset := facing * 2
	ellipse(Vector2(-11 + eye_offset, -65 + bob), Vector2(3.0, 5.0), OUTLINE)
	ellipse(Vector2(11 + eye_offset, -65 + bob), Vector2(3.0, 5.0), OUTLINE)
	draw_circle(Vector2(-24, -54 + bob), 5, Color("f2adad"))
	draw_circle(Vector2(24, -54 + bob), 5, Color("f2adad"))
	draw_arc(Vector2(eye_offset, -56 + bob), 5, 0.15, PI - 0.15, 12, OUTLINE, 2, true)
	if hat != 0:
		var cap := BLUE if hat == 1 else GREEN
		ellipse(Vector2(0,-83+bob), Vector2(35,19), cap)
		draw_style_box(body_style(cap.lightened(0.08)), Rect2(-36, -85+bob, 76, 12))
		draw_line(Vector2(-6,-97+bob), Vector2(-12,-87+bob), cap.lightened(0.4), 3, true)
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	var text_size := font.get_string_size(nickname, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	draw_string_outline(font, Vector2(-text_size.x / 2,-112), nickname, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, Color("101b2b"))
	draw_string(font, Vector2(-text_size.x / 2,-112), nickname, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func body_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = OUTLINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0,3), 0, Vector2(1,0.3))
	draw_circle(Vector2.ZERO, 33, Color(0,0,0,0.28))
	draw_set_transform(Vector2.ZERO)
