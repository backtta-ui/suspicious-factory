extends Control
var rules: RefCounted
var observer:="human"
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func at(p: Vector2) -> Vector2:return Vector2(8,8)+p/rules.L.SIZE*(size-Vector2(16,16))
func _draw() -> void:
 if rules==null:return
 draw_style_box(preload("res://scripts/ui/design.gd").panel(Color("12182c")),Rect2(Vector2.ZERO,size))
 for rect in rules.L.HARD:draw_rect(Rect2(at(rect.position),at(rect.end)-at(rect.position)),Color("837ba0"))
 draw_rect(Rect2(at(rules.L.POND.position),at(rules.L.POND.end)-at(rules.L.POND.position)),Color("376288"))
 var circle: Dictionary=rules.circle();var scale_factor: float=(size.x-16)/rules.L.SIZE.x
 draw_arc(at(circle.center),circle.radius*scale_factor,0,TAU,64,Color("89d8ff"),1.5,true);draw_arc(at(circle.next_center),circle.next_radius*scale_factor,0,TAU,64,Color("b48cdb"),1,true)
 for a in rules.visible(observer):
  if a.id=="":continue
  draw_circle(at(a.position),3,Color("ffe392") if a.id==observer else Color("8b95bc"))
func _process(_delta: float) -> void:queue_redraw()
