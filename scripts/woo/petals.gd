class_name WooPetals
extends Node2D
var time := 0.0
const PANORAMA = preload("res://assets/woo/hd/panorama.png")
func _ready() -> void:
	z_index=90
func _process(delta: float) -> void:
	time+=delta;queue_redraw()
func _draw() -> void:
	var camera:=get_viewport().get_camera_2d()
	if not camera: return
	var view:=get_viewport_rect().size/camera.zoom
	var corner:=camera.get_screen_center_position()-view/2
	for i in range(36):
		var x:=fposmod(i*0.618+time*(0.012+(i%4)*0.003),1)
		var y:=fposmod(i*0.417+time*(0.016+(i%5)*0.003),1)
		var p:=corner+Vector2(x*view.x+sin(time+i)*4,y*view.y)
		var scale:=1.0+(i%4)*0.45
		draw_colored_polygon(PackedVector2Array([p+Vector2(-2,-1)*scale,p+Vector2(1,-2)*scale,p+Vector2(3,1)*scale,p+Vector2(-1,2)*scale]),Color(0.96,0.61,0.78,0.3+(i%3)*0.2))
	var source:=Rect2(0,PANORAMA.get_height()*0.72,PANORAMA.get_width(),PANORAMA.get_height()*0.28)
	draw_texture_rect_region(PANORAMA,Rect2(corner+Vector2(sin(time*0.12)*14,view.y*0.4),Vector2(view.x,view.y*0.6)),source,Color(1,1,1,0.08))
