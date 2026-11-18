extends SceneTree
## 아이콘 시트 검수: 모든 글리프를 큰 크기(56)와 작은 크기(26)로 나란히 그린다.
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const NAMES=["lantern","copy","invite","back","users","lotus","fox","shuffle","clock","swords","crown","check","cross","exit","flower","cloud","diamond"]
class Sheet extends Control:
	func _draw() -> void:
		var x:=20.0
		var y:=30.0
		for name in NAMES:
			Glyphs.draw_glyph(self,name,Rect2(Vector2(x,y),Vector2(56,56)),Color("f0dcae"),2.0)
			Glyphs.draw_glyph(self,name,Rect2(Vector2(x,y+70),Vector2(26,26)),Color("f0dcae"),1.6)
			draw_string(FONT,Vector2(x,y+120),name,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.7,.7,.8))
			x+=96.0
			if x>size.x-96.0:x=20.0;y+=150.0
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1120,400)
	var sheet:=Sheet.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(sheet)
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/work/glyph_sheet.png")
	print("GLYPHS SAVED")
	quit()
