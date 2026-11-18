class_name WooV25
extends RefCounted
## 2.0.25 시안 복제용 UI 키트 — 고해상도로 구운 재질(황동 촉 버튼 · 보랏빛 판 · 한지 ·
## 나무 문패 · 금관 화환 · 부적 고리)을 9-slice로 늘려 쓴다.
## 화면 코드는 색·판·버튼·장식을 여기서만 가져다 쓴다.

const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/BlackHanSans.ttf")
const BRUSH_FONT=preload("res://assets/fonts/NanumBrushScript.ttf")
const G=preload("res://scripts/ui/room_glyphs.gd")
const T=preload("res://scripts/ui/lobby_theme.gd")

const TEX_PANEL=preload("res://assets/ui/v25/panel.png")
const TEX_PANEL_SOFT=preload("res://assets/ui/v25/panel_soft.png")
const TEX_CARD=preload("res://assets/ui/v25/card.png")
const TEX_CARD_LIT=preload("res://assets/ui/v25/card_lit.png")
const TEX_GOLD=preload("res://assets/ui/v25/btn_gold.png")
const TEX_GOLD_PRESSED=preload("res://assets/ui/v25/btn_gold_pressed.png")
const TEX_GOLD_OFF=preload("res://assets/ui/v25/btn_gold_off.png")
const TEX_DARK=preload("res://assets/ui/v25/btn_dark.png")
const TEX_DARK_PRESSED=preload("res://assets/ui/v25/btn_dark_pressed.png")
const TEX_TAB=preload("res://assets/ui/v25/tab.png")
const TEX_TAB_LIT=preload("res://assets/ui/v25/tab_lit.png")
const TEX_PILL=preload("res://assets/ui/v25/pill.png")
const TEX_PARCHMENT=preload("res://assets/ui/v25/parchment.png")
const TEX_WOOD=preload("res://assets/ui/v25/plaque_wood.png")
const TEX_MEDALLION=preload("res://assets/ui/v25/medallion.png")
const TEX_SLOT=preload("res://assets/ui/v25/slot.png")
const TEX_RING_FRAME=preload("res://assets/ui/v25/ring_frame.png")
const TEX_RING=preload("res://assets/ui/v25/ring.png")
const TEX_LAUREL=preload("res://assets/ui/v25/laurel.png")
const TEX_RIBBON=preload("res://assets/ui/v25/ribbon.png")
const TEX_VS=preload("res://assets/ui/v25/vs.png")
const TEX_LETTER=preload("res://assets/ui/v25/letter.png")
const TEX_TASSEL=preload("res://assets/ui/v25/tassel.png")
const TEX_DIVIDER=preload("res://assets/ui/v25/divider.png")
const TEX_GAUGE=preload("res://assets/ui/v25/gauge_fill.png")
const TEX_GAUGE_TRACK=preload("res://assets/ui/v25/gauge_track.png")
const TEX_BADGE=preload("res://assets/ui/v25/badge.png")
const TEX_BRANCH=preload("res://assets/ui/v25/branch.png")
const TEX_TILE=preload("res://assets/ui/v25/tile.png")
const TEX_SCENE=preload("res://assets/ui/v25/scene_round.png")
const TEX_ROOF=preload("res://assets/ui/v25/roof.png")
const TEX_ICON_COIN=preload("res://assets/ui/v25/icon_coin.png")
const TEX_ICON_GEM=preload("res://assets/ui/v25/icon_gem.png")
const TEX_ICON_LETTER=preload("res://assets/ui/v25/icon_letter.png")
const TEX_ICON_MEDAL=preload("res://assets/ui/v25/icon_medal.png")
const TEX_ICON_GIFT=preload("res://assets/ui/v25/icon_gift.png")
const TEX_ICON_SEAL=preload("res://assets/ui/v25/icon_seal.png")
const TEX_ICON_LOTUS=preload("res://assets/ui/v25/icon_lotus.png")
const TEX_LANTERN=preload("res://assets/ui/v25/lantern.png")

const GOLD_COLOR=Color("f2cf8e")
const GOLD_BRIGHT=Color("ffe6b4")
const IVORY=Color("f4e7cd")
const INK=Color("2a1c10")
const MUTED=Color("b9b1cc")


## 텍스처를 비율에 맞춰 9분할해 그린다(모서리 장식·뾰족한 끝이 크기와 무관하게 유지).
## cap_x/cap_y는 텍스처 폭·높이에 대한 가장자리 비율.
static func draw_nine(ci: CanvasItem, texture: Texture2D, rect: Rect2, cap_x: float=0.30,
		cap_y: float=0.12, tint: Color=Color.WHITE) -> void:
	if texture==null or rect.size.x<2.0 or rect.size.y<2.0:return
	var tw: float=texture.get_width()
	var th: float=texture.get_height()
	var k: float=rect.size.y/th
	var cw: float=tw*cap_x*k
	var ch: float=th*cap_y*k
	if cw*2.0>rect.size.x-1.0 or ch*2.0>rect.size.y-1.0:
		var scale: float=minf(rect.size.x/tw,rect.size.y/th)
		var size:=Vector2(tw*scale,th*scale)
		ci.draw_texture_rect(texture,Rect2(rect.position+(rect.size-size)*.5,size),false,tint)
		return
	var sx:=tw*cap_x
	var sy:=th*cap_y
	var sw:=tw-sx*2.0
	var sh:=th-sy*2.0
	var dw:=rect.size.x-cw*2.0
	var dh:=rect.size.y-ch*2.0
	var p:=rect.position
	# 모서리 4
	ci.draw_texture_rect_region(texture,Rect2(p,Vector2(cw,ch)),Rect2(0,0,sx,sy),tint)
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(rect.size.x-cw,0),Vector2(cw,ch)),Rect2(tw-sx,0,sx,sy),tint)
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(0,rect.size.y-ch),Vector2(cw,ch)),Rect2(0,th-sy,sx,sy),tint)
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(rect.size.x-cw,rect.size.y-ch),Vector2(cw,ch)),Rect2(tw-sx,th-sy,sx,sy),tint)
	# 위/아래 변
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(cw,0),Vector2(dw,ch)),Rect2(sx,0,sw,sy),tint)
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(cw,rect.size.y-ch),Vector2(dw,ch)),Rect2(sx,th-sy,sw,sy),tint)
	# 좌/우 변
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(0,ch),Vector2(cw,dh)),Rect2(0,sy,sx,sh),tint)
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(rect.size.x-cw,ch),Vector2(cw,dh)),Rect2(tw-sx,sy,sx,sh),tint)
	# 가운데
	ci.draw_texture_rect_region(texture,Rect2(p+Vector2(cw,ch),Vector2(dw,dh)),Rect2(sx,sy,sw,sh),tint)

## 9-slice 판. 모서리 장식이 찌그러지지 않게 화면 크기에 맞춰 여백을 줄인다.
static func patch(parent: Node, texture: Texture2D, rect: Rect2, base: int=64) -> NinePatchRect:
	var node:=NinePatchRect.new()
	node.texture=texture
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position=Vector2.ZERO
	node.size=rect.size
	node.set_meta("patch_base",base)
	refit(node)
	node.resized.connect(func()->void:refit(node))
	return node

## 모서리 장식이 찌그러지지 않게 현재 크기에 맞춰 9-slice 여백을 다시 계산한다.
static func refit(node: NinePatchRect) -> void:
	if node==null or not is_instance_valid(node):return
	var base: int=int(node.get_meta("patch_base",64))
	var w: float=node.size.x
	var h: float=node.size.y
	var mx:=clampi(int(minf(float(base),w*0.34)),4,int(maxf(4.0,w*0.5-1.0)))
	var my:=clampi(int(minf(float(base),h*0.34)),4,int(maxf(4.0,h*0.5-1.0)))
	node.set_patch_margin(SIDE_LEFT,mx)
	node.set_patch_margin(SIDE_RIGHT,mx)
	node.set_patch_margin(SIDE_TOP,my)
	node.set_patch_margin(SIDE_BOTTOM,my)

## 큰 판(배경 위 어두운 판). 선택 시 금빛 광.
static func frame(parent: Node, rect: Rect2, base: int=64) -> NinePatchRect:
	return patch(parent, TEX_PANEL, rect, base)

## 목록 카드. lit이면 금테 + 따뜻한 광.
static func card(parent: Node, rect: Rect2, lit: bool=false) -> NinePatchRect:
	return patch(parent, TEX_CARD_LIT if lit else TEX_CARD, rect, 26)

## 머리글 아이콘 메달(금테 원판).
static func medallion(parent: Node, rect: Rect2, glyph: String, tint: Color=GOLD_COLOR) -> TextureRect:
	var node:=TextureRect.new()
	node.texture=TEX_MEDALLION
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_SCALE
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position=Vector2.ZERO
	node.size=rect.size
	var icon:=Glyph.new()
	icon.glyph=glyph
	icon.tint=tint
	node.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left=rect.size.x*0.22
	icon.offset_right=-rect.size.x*0.22
	icon.offset_top=rect.size.y*0.22
	icon.offset_bottom=-rect.size.y*0.22
	return node

## 입체 아이콘(광택 PNG)을 사각 영역에 얹는다.
static func icon(parent: Node, texture: Texture2D, rect: Rect2, tint: Color=Color.WHITE) -> TextureRect:
	var node:=TextureRect.new()
	node.texture=texture
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.modulate=tint
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position=rect.position
	node.size=rect.size
	return node

## 원형으로 부드럽게 잘라 넣은 초상(도감·대진표).
static func circle_icon(parent: Node, texture: Texture2D, rect: Rect2, focus: float=0.42, radius: float=0.46) -> TextureRect:
	var node:=TextureRect.new()
	node.texture=texture
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.material=T.mask_material(focus,radius,0.05)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position=rect.position
	node.size=rect.size
	return node


## 원형 초상 — 텍스처를 원 다각형에 UV 매핑해 정확히 원으로 잘라 그린다(마스크 셰이더 불필요).
class CirclePortrait extends Control:
	var texture: Texture2D=null
	var focus:=0.42
	var zoom:=1.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if texture==null or size.x<4.0:return
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5-0.5
		var tw:=float(texture.get_width())
		var th:=float(texture.get_height())
		# 정사각으로 덮은 뒤(cover) 확대(zoom)와 초점(focus)을 적용한 UV 창
		var side:=minf(tw,th)/zoom
		var ox:=(tw-side)*.5
		var oy:=(th-side)*focus
		var pts:=PackedVector2Array()
		var uvs:=PackedVector2Array()
		for i in range(64):
			var a:=float(i)/64.0*TAU
			var dir:=Vector2(cos(a),sin(a))
			pts.append(c+dir*r)
			var u:=0.5+dir.x*0.5
			var v:=0.5+dir.y*0.5
			uvs.append(Vector2((ox+u*side)/tw,(oy+v*side)/th))
		draw_polygon(pts,PackedColorArray([Color.WHITE]),uvs,texture)
		draw_arc(c,r-0.5,0,TAU,64,Color(0,0,0,.45),1.2,true)

## 글자에 어두운 테두리.
static func outline(label: Label, extent: int=3, color: Color=Color(0.04,0.03,0.06,0.8)) -> void:
	label.add_theme_color_override("font_outline_color",color)
	label.add_theme_constant_override("outline_size",extent)

## 금빛 제목(붓글씨 대신 세리프 대제목 · 시안과 같은 금 그라데이션 느낌은 색과 테두리로).
static func title_label(parent: Node, text_value: String, extent: float, color: Color=GOLD_BRIGHT) -> Label:
	var node:=Label.new()
	node.text=text_value
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",TITLE_FONT)
	node.add_theme_font_size_override("font_size",int(extent))
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75))
	node.add_theme_constant_override("shadow_offset_x",0)
	node.add_theme_constant_override("shadow_offset_y",3)
	node.add_theme_constant_override("shadow_outline_size",2)
	outline(node,maxi(4,int(extent*0.16)),Color(0.10,0.05,0.02,0.95))
	node.set_meta("base_font",extent)
	parent.add_child(node)
	return node

## 두루마리 머리글 장식(가는 금선 + 가운데 다이아).
class Divider extends Control:
	var color:=Color(0.94,0.78,0.52,0.55)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var y:=size.y*.5
		var mid:=size.x*.5
		draw_line(Vector2(0,y),Vector2(mid-16.0,y),Color(color.r,color.g,color.b,color.a*.55),1.0)
		draw_line(Vector2(mid+16.0,y),Vector2(size.x,y),Color(color.r,color.g,color.b,color.a*.55),1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(mid-7.0,y),Vector2(mid,y-5.0),Vector2(mid+7.0,y),Vector2(mid,y+5.0)]),color)

## 아이콘 하나(글리프)를 사각 영역에 그린다.
class Glyph extends Control:
	var glyph:="mail"
	var tint:=Color("f2cf8e")
	var line:=1.8
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<3.0:return
		WooV25.G.draw_glyph(self,glyph,Rect2(Vector2.ZERO,size),tint,maxf(1.1,minf(size.x,size.y)*0.055),0.0)

## 시안의 금빛 촉 버튼 / 어두운 판 버튼.
## 상태별 텍스처 + 위아래 마진을 크기에 맞춰 줄여 작은 버튼에서도 뾰족한 끝이 유지된다.
class PlateButton extends "res://scripts/woo/mobile_button.gd":
	const TEX={
		"gold":[preload("res://assets/ui/v25/btn_gold.png"),preload("res://assets/ui/v25/btn_gold_pressed.png"),preload("res://assets/ui/v25/btn_gold_off.png")],
		"dark":[preload("res://assets/ui/v25/btn_dark.png"),preload("res://assets/ui/v25/btn_dark_pressed.png"),preload("res://assets/ui/v25/btn_dark.png")],
	}
	var kind:="gold"
	var glyph:=""
	var font_size:=18
	var use_title_font:=false
	var ink:=Color("2f1e06")
	var glyph_color:=Color("3a2405")
	var margin_x:=46
	var margin_y:=30
	var lit:=0.0
	var _boxes:={}
	func _ready() -> void:
		super()
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_outline_color"]:
			add_theme_color_override(state,Color(0,0,0,0))
		add_theme_constant_override("outline_size",0)
		custom_minimum_size=Vector2.ZERO
		resized.connect(func()->void:
			pivot_offset=size*.5
			_fit()
			queue_redraw())
		mouse_entered.connect(func()->void:lit=1.0;queue_redraw())
		mouse_exited.connect(func()->void:lit=0.0;queue_redraw())
		_configure(kind)
		queue_redraw()
	func _configure(value: String) -> void:
		kind=value if TEX.has(value) else "gold"
		if kind=="gold":
			ink=Color("2f1e06")
			glyph_color=Color("3a2405")
		else:
			ink=Color("f4e7cd")
			glyph_color=Color("f0d49a")
		_fit()
	func _fit() -> void:
		if size.x<8.0 or size.y<8.0:return
		margin_x=clampi(int(minf(46.0,size.x*0.30)),4,46)
		margin_y=clampi(int(minf(30.0,size.y*0.40)),4,30)
		_build_boxes()
	func _build_boxes() -> void:
		_boxes.clear()
		var pair: Array=TEX[kind]
		for state in ["normal","hover","pressed","disabled"]:
			var texture: Texture2D=pair[0]
			if state=="pressed":texture=pair[1]
			elif state=="disabled":texture=pair[2]
			var box:=StyleBoxTexture.new()
			box.texture=texture
			box.set_texture_margin(SIDE_LEFT,margin_x)
			box.set_texture_margin(SIDE_RIGHT,margin_x)
			box.set_texture_margin(SIDE_TOP,margin_y)
			box.set_texture_margin(SIDE_BOTTOM,margin_y)
			box.content_margin_left=0;box.content_margin_right=0
			box.content_margin_top=0;box.content_margin_bottom=0
			_boxes[state]=box
	func set_kind(value: String) -> void:
		_configure(value)
		queue_redraw()
	func _process(delta: float) -> void:
		var target:=1.0 if (is_hovered() or is_pressed()) else 0.0
		if absf(lit-target)>.01:
			lit=move_toward(lit,target,delta*8.0)
			queue_redraw()
	func _get_minimum_size() -> Vector2:
		var font: Font=TITLE_FONT if use_title_font else FONT
		var extent:=maxi(9,int(font_size))
		var icon:=minf(size.y*.46,font_size*1.16)+8.0 if glyph!="" else 0.0
		return Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x+icon+18.0,0.0)
	func _draw() -> void:
		if size.x<8.0 or size.y<6.0:return
		var state:="normal"
		if disabled:state="disabled"
		elif is_pressed():state="pressed"
		elif lit>.5:state="hover"
		var pair: Array=TEX[kind]
		var texture: Texture2D=pair[0]
		if state=="pressed":texture=pair[1]
		elif state=="disabled":texture=pair[2]
		var tint:=Color(1.0+lit*.06,1.0+lit*.05,1.0+lit*.02,1.0)
		WooV25.draw_nine(self,texture,Rect2(Vector2.ZERO,size),0.30,0.10,tint)
		var font: Font=TITLE_FONT if use_title_font else FONT
		var extent:=maxi(9,int(font_size))
		var icon_size:=minf(size.y*.46,font_size*1.16) if glyph!="" else 0.0
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x
		var gap:=7.0 if glyph!="" else 0.0
		var total:=width+icon_size+gap
		var start:=Vector2((size.x-total)*.5,0)
		var shift:=1.2 if is_pressed() else 0.0
		if glyph!="":
			var box_rect:=Rect2(Vector2(start.x,size.y*.5-icon_size*.5+shift),Vector2(icon_size,icon_size))
			var color:=glyph_color
			if disabled:color=Color(glyph_color.r,glyph_color.g,glyph_color.b,.55)
			WooV25.G.draw_glyph(self,glyph,box_rect,color,maxf(1.2,icon_size*.09),0.0)
			start.x+=icon_size+gap
		var baseline:=size.y*.5+shift+(font.get_ascent(extent)-font.get_descent(extent))*.5
		var text_color:=ink
		if disabled:text_color=Color(ink.r,ink.g,ink.b,.62)
		if kind=="gold" and not disabled:
			draw_string_outline(font,Vector2(start.x,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,3,Color(.36,.20,.04,.45))
		elif not disabled:
			draw_string_outline(font,Vector2(start.x,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,3,Color(0,0,0,.55))
		draw_string(font,Vector2(start.x,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,text_color)

## 왼쪽 세로 탭(선택 = 금빛, 미선택 = 어두운 판) + 아이콘.
class Tab extends "res://scripts/woo/mobile_button.gd":
	var glyph:=""
	var lit_state:=false
	var font_size:=17
	var accent:=Color("f6dda6")
	var _normal:=StyleBoxTexture.new()
	var _lit:=StyleBoxTexture.new()
	func _ready() -> void:
		super()
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
			add_theme_color_override(state,Color(0,0,0,0))
		custom_minimum_size=Vector2.ZERO
		for box in [_normal,_lit]:
			box.texture=WooV25.TEX_TAB
			box.set_texture_margin(SIDE_LEFT,30)
			box.set_texture_margin(SIDE_RIGHT,30)
			box.set_texture_margin(SIDE_TOP,26)
			box.set_texture_margin(SIDE_BOTTOM,26)
			box.content_margin_left=0;box.content_margin_right=0;box.content_margin_top=0;box.content_margin_bottom=0
		_lit.texture=WooV25.TEX_TAB_LIT
		resized.connect(queue_redraw)
	func paint(active: bool) -> void:
		lit_state=active
		queue_redraw()
	func _draw() -> void:
		if size.x<8.0 or size.y<6.0:return
		WooV25.draw_nine(self,WooV25.TEX_TAB_LIT if lit_state else WooV25.TEX_TAB,
			Rect2(Vector2.ZERO,size),0.10,0.24,Color.WHITE)
		var font: Font=WooV25.FONT
		var extent:=maxi(10,int(font_size))
		var icon_size:=minf(size.y*.44,extent*1.3)
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x
		var total:=width+icon_size+10.0
		var start:=Vector2((size.x-total)*.5,0)
		var color:=WooV25.INK if lit_state else Color("f0e2c6")
		var glyph_tint:=Color("4a2a06") if lit_state else Color("e8cfa0")
		WooV25.G.draw_glyph(self,glyph,Rect2(Vector2(start.x,size.y*.5-icon_size*.5),Vector2(icon_size,icon_size)),glyph_tint,maxf(1.2,icon_size*.10),0.0)
		start.x+=icon_size+10.0
		var baseline:=size.y*.5+(font.get_ascent(extent)-font.get_descent(extent))*.5
		if not lit_state:
			draw_string(font,Vector2(start.x,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,Color(0,0,0,.45))
		draw_string(font,Vector2(start.x,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,color)
