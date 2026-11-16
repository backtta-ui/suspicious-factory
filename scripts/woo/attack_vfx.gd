class_name WooAttackVFX
extends Node2D
const SHEET=preload("res://assets/woo/wardrobe/combat_vfx.png")
var age:=0.0
var duration:=.32
var stage:=0
var direction:=Vector2.RIGHT
var radius:=110.0
var sprite: Sprite2D
func _ready() -> void:
 z_index=55
 sprite=Sprite2D.new();sprite.texture=SHEET;sprite.region_enabled=true
 var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/woo/attack_vfx.gdshader");sprite.material=mat;add_child(sprite)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 rotation=direction.angle();update_frame()
func update_frame() -> void:
 var cell:=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/4.0)
 var frame:=mini(3,int(age/duration*4))
 sprite.region_rect=Rect2(Vector2(frame,clampi(stage,0,3))*cell+Vector2(4,4),cell-Vector2(8,8))
 sprite.position=Vector2(radius*.36,-13)
 var extent:=radius*1.6
 sprite.scale=Vector2(extent,extent*.72)/sprite.region_rect.size
 sprite.modulate.a=minf(1,(duration-age)/.10)
func _process(delta: float) -> void:
 age+=delta
 if age>=duration:queue_free();return
 update_frame();queue_redraw()
func _draw() -> void:
 var t:=age/duration
 var c:=Color("ffda8c") if stage==1 else Color("b2eeff")
 c.a=sin(t*PI)*.7
 draw_line(Vector2(3,-12),Vector2(radius*(.3+t*.65),-12),c,2 if stage<3 else 4,true)
