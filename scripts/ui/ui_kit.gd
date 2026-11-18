class_name WooUIKit
extends RefCounted
## 2.0.23 공용 UI 키트 — 상업 퀄리티 조선 다크 판타지 프레임·카드·인장·기술 원형·게이지.
## 모든 요소를 Control._draw로 그려 해상도·비율과 무관하게 같은 톤과 선명도를 유지한다.
## 화면 코드는 색·판·테두리·장식을 여기서만 가져다 쓴다(늘린 텍스처 없음).
const T=preload("res://scripts/ui/lobby_theme.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const SKILLS=preload("res://assets/woo/v20/skills.png")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")

## 글자 뒤 어두운 테두리로 어떤 배경 위에서도 대비를 확보한다.
static func outline(label: Label,color: Color=Color(0.03,0.025,0.05,0.75),extent: int=3) -> void:
	label.add_theme_color_override("font_outline_color",color)
	label.add_theme_constant_override("outline_size",extent)

# ------------------------------------------------------------------ 큰 판 프레임
## 화면의 주 판: 어두운 그라데이션 채움 + 이중 황동 테두리 + 안쪽 빛 + 모서리 장식.
class Frame extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const U=preload("res://scripts/ui/ui_palette.gd")
	var radius:=18.0
	var fill_top:=Color(0.105,0.115,0.195,0.94)
	var fill_bottom:=Color(0.032,0.038,0.082,0.96)
	var edge:=Color(0.77,0.61,0.35,0.72)
	var glow:=0.0
	var glow_color:=Color(0.55,0.45,1.0,1.0)
	var ornate:=true
	var arm:=24.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<8.0 or size.y<8.0:return
		var box:=Rect2(Vector2.ZERO,size)
		var r:=minf(radius,minf(size.x,size.y)*.30)
		for i in range(4):
			var grow:=2.0+float(i)*3.0
			T.rounded_outline(self,box.grow(grow),Color(0,0,0,.16-float(i)*.033),r+grow,3.0)
		if glow>0.0:
			for i in range(5):
				var grow:=2.5+float(i)*3.2
				T.rounded_outline(self,box.grow(grow),U.alpha(glow_color,(.20-float(i)*.034)*glow),r+grow,2.6)
		T.gradient_rounded(self,box,fill_top,fill_bottom,r)
		T.gradient_rounded(self,Rect2(Vector2(2.0,2.0),Vector2(size.x-4.0,size.y*.34)),Color(.62,.58,.82,.075),Color(.62,.58,.82,0.0),maxf(1.0,r-2.0))
		draw_rect(Rect2(Vector2(r*.6,1.4),Vector2(size.x-r*1.2,1.6)),Color(.96,.90,.74,.16))
		T.rounded(self,Rect2(Vector2(2.0,size.y*.72),Vector2(size.x-4.0,size.y*.28-2.0)),Color(0,0,0,.14),maxf(0.0,r-2.0))
		T.rounded_outline(self,box,Color(0,0,0,.52),r,2.4)
		T.rounded_outline(self,box.grow(-1.3),edge,r-1.3,1.5)
		T.rounded_outline(self,box.grow(-4.6),U.alpha(edge,.26),r-4.6,1.0)
		if not ornate:return
		var a:=minf(arm,minf(size.x,size.y)*.16)
		var bright:=U.alpha(edge,minf(1.0,edge.a*1.35))
		for spec in [[box.position+Vector2(1.5,1.5),Vector2(1,1)],[Vector2(box.end.x-1.5,box.position.y+1.5),Vector2(-1,1)],[Vector2(box.position.x+1.5,box.end.y-1.5),Vector2(1,-1)],[box.end-Vector2(1.5,1.5),Vector2(-1,-1)]]:
			T.corner_flourish(self,spec[0],spec[1],a,bright)
		for spec in [[Vector2(size.x*.5,0.0),1.0],[Vector2(size.x*.5,size.y),-1.0]]:
			var at: Vector2=spec[0]
			var dir:=float(spec[1])
			T.diamond(self,at+Vector2(0,dir*6.0),4.4,edge)
			draw_line(at+Vector2(0,dir*11.0),at+Vector2(0,dir*16.0),U.alpha(edge,.5),1.2)
			for side in [-1.0,1.0]:
				draw_line(at+Vector2(0,dir*11.0),at+Vector2(side*22.0,dir*11.0),U.alpha(edge,.24),1.0)
				T.diamond(self,at+Vector2(side*26.0,dir*11.0),2.1,U.alpha(edge,.6))

# ------------------------------------------------------------------ 중형 카드 프레임
## 캐릭터·아이템 카드: 선택 시 금빛 광, 미선택은 차분한 황동 테두리.
class Card extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const U=preload("res://scripts/ui/ui_palette.gd")
	var lit:=false
	var edge:=Color(0.77,0.61,0.35,0.55)
	var radius:=12.0
	var fill_top:=Color(0.095,0.10,0.175,0.96)
	var fill_bottom:=Color(0.030,0.035,0.075,0.98)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<6.0 or size.y<6.0:return
		var box:=Rect2(Vector2.ZERO,size)
		var r:=minf(radius,minf(size.x,size.y)*.22)
		for i in range(3):
			var grow:=1.5+float(i)*2.2
			T.rounded_outline(self,box.grow(grow),Color(0,0,0,.18-float(i)*.045),r+grow,2.4)
		if lit:
			for i in range(5):
				var grow:=2.0+float(i)*3.0
				T.rounded_outline(self,box.grow(grow),U.alpha(U.BRASS,.20-float(i)*.034),r+grow,2.4)
		T.gradient_rounded(self,box,fill_top,fill_bottom,r)
		T.gradient_rounded(self,Rect2(Vector2(1.5,1.5),Vector2(size.x-3.0,size.y*.30)),Color(.66,.62,.86,.06),Color(.66,.62,.86,0.0),maxf(1.0,r-1.5))
		T.rounded_outline(self,box,Color(0,0,0,.5),r,2.0)
		var line:=edge
		if lit:line=U.BRASS_LIGHT
		T.rounded_outline(self,box.grow(-1.2),line,r-1.2,2.0 if lit else 1.4)
		T.rounded_outline(self,box.grow(-4.0),U.alpha(line,.22),r-4.0,1.0)
		var a:=minf(16.0,minf(size.x,size.y)*.20)
		for spec in [[box.position+Vector2(2,2),Vector2(1,1)],[Vector2(box.end.x-2,box.position.y+2),Vector2(-1,1)],[Vector2(box.position.x+2,box.end.y-2),Vector2(1,-1)],[box.end-Vector2(2,2),Vector2(-1,-1)]]:
			T.corner_flourish(self,spec[0],spec[1],a,U.alpha(line,.85))

# ------------------------------------------------------------------ 인장(체크 봉인)
## 선택 완료·준비 완료 표시. 어두운 원 위에 황동 테두리와 체크.
class Seal extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const G=preload("res://scripts/ui/room_glyphs.gd")
	var color:=Color(0.86,0.71,0.42)
	var ink:=Color("231705")
	var glowing:=true
	var timed:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		if glowing:set_process(true)
		resized.connect(queue_redraw)
	func _process(delta: float) -> void:
		if not glowing:return
		timed+=delta
		queue_redraw()
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5-1.5
		if r<3.0:return
		if glowing:
			var pulse:=.5+sin(timed*1.6)*.5
			for i in range(4):
				draw_circle(c,r*(1.0+float(i)*.10),Color(color.r,color.g,color.b,.055*(1.0-float(i)/4.0)*(.6+pulse*.6)))
		draw_circle(c,r+1.0,Color(0,0,0,.55))
		T.gradient_rounded(self,Rect2(c-Vector2(r,r),Vector2(r*2.0,r*2.0)),color.lightened(.18),color.darkened(.28),r)
		draw_arc(c,r,0,TAU,40,Color(1,.96,.84,.85),maxf(1.0,r*.10),true)
		G.draw_glyph(self,"check",Rect2(c-Vector2(r*.52,r*.52),Vector2(r*1.04,r*1.04)),ink,maxf(1.4,r*.15))

# ------------------------------------------------------------------ 기술 원형(금테)
## 주요 능력 3개: 실제 스킬 아이콘을 금테 원 안에 넣는다.
class SkillCircle extends Control:
	const P=preload("res://scripts/ui/ui_palette.gd")
	const G=preload("res://scripts/ui/room_glyphs.gd")
	const SHEET=preload("res://assets/woo/v20/skills.png")
	const INDEX={"attack":0,"jump":1,"dodge":2,"talisman":3,"jar":4,"transform":4,"blink":5,"clone":6,"track":7,"shield":8,"smoke":9,"mask":10,"rescue":11,"capture":12,"darkness":13,"fake_flame":14,"shadow":15,"mimic":10,"locked":-1}
	var skill:="attack"
	var accent:=Color("c49b59")
	var dim:=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5-2.0
		if r<4.0:return
		for i in range(4):
			draw_circle(c,r+1.0+float(i)*2.4,Color(accent.r,accent.g,accent.b,.10-float(i)*.022))
		draw_circle(c,r+1.2,Color(0,0,0,.6))
		draw_circle(c,r,Color("0a0e1c"))
		var index: int=int(INDEX.get(skill,-1))
		if index>=0:
			var cell:=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/4.0)
			var extent:=r*1.34
			draw_texture_rect_region(SHEET,Rect2(c-Vector2.ONE*extent*.5,Vector2.ONE*extent),Rect2(Vector2(index%4,floori(index/4.0))*cell,cell),Color(.72,.74,.86,.9) if dim else Color.WHITE)
		draw_arc(c,r,0,TAU,64,Color(0,0,0,.55),3.0,true)
		draw_arc(c,r-1.0,0,TAU,64,accent,2.2,true)
		draw_arc(c,r-4.0,0,TAU,64,Color(accent.r,accent.g,accent.b,.30),1.0,true)
		draw_arc(c,r-1.0,PI*1.06,PI*1.62,24,Color(1,.96,.84,.55),1.6,true)

# ------------------------------------------------------------------ 진행 게이지
## 업적·로딩 공용. 어두운 홈 + 황동 채움 + 눈금.
class Gauge extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var value:=0.0
	var maximum:=1.0
	var tint:=Color("c49b59")
	var ticks:=4
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func set_value(now_value: float,total: float) -> void:
		value=now_value
		maximum=maxf(1.0,total)
		queue_redraw()
	func _draw() -> void:
		if size.x<4.0 or size.y<3.0:return
		var radius:=size.y*.5
		var box:=Rect2(Vector2.ZERO,size)
		T.gradient_rounded(self,box,Color(.02,.025,.06,.96),Color(.05,.055,.10,.96),radius)
		T.rounded_outline(self,box,Color(0,0,0,.5),radius,1.6)
		T.rounded_outline(self,box.grow(-1.0),Color(tint.r,tint.g,tint.b,.30),radius-1.0,1.0)
		var ratio:=clampf(value/maximum,0.0,1.0)
		if ratio>0.0:
			var fill:=Rect2(Vector2(1.5,1.5),Vector2(maxf(size.y-3.0,(size.x-3.0)*ratio),size.y-3.0))
			T.gradient_rounded(self,fill,tint.lightened(.30),tint.darkened(.22),radius-1.0)
			draw_rect(Rect2(fill.position+Vector2(radius*.6,0.6),Vector2(maxf(0.0,fill.size.x-radius*1.2),maxf(1.0,fill.size.y*.34))),Color(1,.97,.88,.30))
			T.rounded_outline(self,fill,Color(1,.94,.78,.55),radius-1.0,1.0)
		if ticks>0:
			for i in range(1,ticks):
				var x:=size.x*float(i)/float(ticks)
				draw_line(Vector2(x,size.y*.24),Vector2(x,size.y*.76),Color(0,0,0,.28),1.0)

# ------------------------------------------------------------------ 명패(작은 알약)
## 아이콘 + 글자 알약. 상단 바·머리글에 쓴다.
class Plaque extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const G=preload("res://scripts/ui/room_glyphs.gd")
	const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	var text_value:=""
	var glyph:=""
	var accent:=Color("c49b59")
	var font_size:=15
	var ink:=Color("f1e2c5")
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var box:=Rect2(Vector2.ZERO,size)
		var radius:=minf(size.y*.5,16.0)
		T.gradient_rounded(self,box,Color(.13,.12,.10,.92),Color(.045,.04,.032,.95),radius)
		T.rounded_outline(self,box,Color(accent.r,accent.g,accent.b,.55),radius,1.4)
		T.rounded_outline(self,box.grow(-2.2),Color(accent.r,accent.g,accent.b,.18),radius-2.2,1.0)
		var icon_size:=minf(size.y*.62,font_size*1.3) if glyph!="" else 0.0
		var width:=FONT.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var total:=width+icon_size+(6.0 if glyph!="" else 0.0)
		var x:=(size.x-total)*.5
		if glyph!="":
			G.draw_glyph(self,glyph,Rect2(Vector2(x,size.y*.5-icon_size*.5),Vector2(icon_size,icon_size)),accent,1.5)
			x+=icon_size+6.0
		var baseline:=size.y*.5+(FONT.get_ascent(font_size)-FONT.get_descent(font_size))*.5
		draw_string(FONT,Vector2(x,baseline),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)

# ------------------------------------------------------------------ 안개(배경 눌러 주기)
class Scrim extends Control:
	var strength:=0.55
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<2.0:return
		draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.018,.045,strength))
		var rows:=24
		for i in range(rows):
			var t:=float(i)/float(rows)
			draw_rect(Rect2(0,size.y*t,size.x,size.y/float(rows)+1.0),Color(.01,.008,.03,strength*.55*t*t))

# ================================================================ 2.0.23 텍스처 UI
## 고해상도로 구운 황동·보랏빛 텍스처(tools/build_ui_v23.py)를 9-slice로 늘려 쓴다.
## 판·카드·버튼이 단색 StyleBox가 아니라 실제 금속 그라데이션·베벨·장식을 갖는다.
const TEX_GOLD=preload("res://assets/ui/v23/btn_gold.png")
const TEX_GOLD_PRESSED=preload("res://assets/ui/v23/btn_gold_pressed.png")
const TEX_GOLD_DISABLED=preload("res://assets/ui/v23/btn_gold_disabled.png")
const TEX_IRON=preload("res://assets/ui/v23/btn_iron.png")
const TEX_IRON_PRESSED=preload("res://assets/ui/v23/btn_iron_pressed.png")
const TEX_PANEL=preload("res://assets/ui/v23/panel_large.png")
const TEX_PANEL_SOFT=preload("res://assets/ui/v23/panel_soft.png")
const TEX_CARD=preload("res://assets/ui/v23/card_normal.png")
const TEX_CARD_LIT=preload("res://assets/ui/v23/card_lit.png")
const TEX_TAB=preload("res://assets/ui/v23/tab_normal.png")
const TEX_TAB_LIT=preload("res://assets/ui/v23/tab_lit.png")
const TEX_PLAQUE=preload("res://assets/ui/v23/plaque.png")
const TEX_SLOT=preload("res://assets/ui/v23/slot.png")

## 9-slice 판 하나를 만들어 부모에 붙인다(위치는 호출자가 잡는다).
static func nine(parent: Node,texture: Texture2D,margin: int) -> NinePatchRect:
	var node:=NinePatchRect.new()
	node.texture=texture
	node.set_patch_margin(SIDE_LEFT,margin)
	node.set_patch_margin(SIDE_RIGHT,margin)
	node.set_patch_margin(SIDE_TOP,margin)
	node.set_patch_margin(SIDE_BOTTOM,margin)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

## 텍스처 버튼: 황동 CTA · 철제 보조 · 탭 · 명패.
## 상태별로 다른 텍스처(normal/pressed/disabled)를 쓰고 글자·아이콘은 직접 그린다.
class MetalButton extends "res://scripts/woo/mobile_button.gd":
	const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
	const G=preload("res://scripts/ui/room_glyphs.gd")
	const P=preload("res://scripts/ui/ui_palette.gd")
	const TX={
		"gold":[preload("res://assets/ui/v23/btn_gold.png"),preload("res://assets/ui/v23/btn_gold_pressed.png"),preload("res://assets/ui/v23/btn_gold_disabled.png"),46],
		"iron":[preload("res://assets/ui/v23/btn_iron.png"),preload("res://assets/ui/v23/btn_iron_pressed.png"),preload("res://assets/ui/v23/btn_iron.png"),46],
		"tab":[preload("res://assets/ui/v23/tab_normal.png"),preload("res://assets/ui/v23/tab_normal.png"),preload("res://assets/ui/v23/tab_normal.png"),26],
		"tab_lit":[preload("res://assets/ui/v23/tab_lit.png"),preload("res://assets/ui/v23/tab_lit.png"),preload("res://assets/ui/v23/tab_lit.png"),26],
		"plaque":[preload("res://assets/ui/v23/plaque.png"),preload("res://assets/ui/v23/plaque.png"),preload("res://assets/ui/v23/plaque.png"),24],
		"slot":[preload("res://assets/ui/v23/slot.png"),preload("res://assets/ui/v23/slot.png"),preload("res://assets/ui/v23/slot.png"),16],
	}
	var kind:="gold"
	var glyph:=""
	var font_size:=18
	var use_title_font:=false
	var margins: int=44
	var base_margin: int=44
	var ink:=Color("3a2405")
	var glyph_color:=Color("3a2405")
	var icon_scale:=1.0
	var lit:=0.0
	var press:=0.0
	var _boxes:={}
	func _ready() -> void:
		super()
		_configure(kind)
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_outline_color"]:
			add_theme_color_override(state,Color(0,0,0,0))
		add_theme_constant_override("outline_size",0)
		# 화면이 크기를 직접 잡으므로 공용 112x64 최소 크기를 쓰지 않는다.
		custom_minimum_size=Vector2.ZERO
		resized.connect(func()->void:
			pivot_offset=size*.5
			_fit_margins()
			queue_redraw())
		mouse_entered.connect(func()->void:lit=1.0;queue_redraw())
		mouse_exited.connect(func()->void:lit=0.0;queue_redraw())
		queue_redraw()
		if not Engine.is_editor_hint():set_process(true)
	func _configure(value: String) -> void:
		kind=value if TX.has(value) else "gold"
		base_margin=int(TX[kind][3])
		margins=base_margin
		match kind:
			"gold":
				ink=Color("3a2103")
				glyph_color=Color("3a2103")
			"iron":
				ink=Color("f6ead0")
				glyph_color=Color("e8cf9c")
			"tab","plaque","slot":
				ink=Color("f1e2c5")
				glyph_color=Color("e8cf9c")
			"tab_lit":
				ink=Color("ffeec6")
				glyph_color=Color("ffd89a")
		_build_boxes()
	## 버튼 높이가 텍스처보다 낮으면 모서리 마진을 줄여 판이 찌그러지지 않게 한다.
	func _fit_margins() -> void:
		if size.y<8.0:return
		var target:=maxi(6,int(minf(float(base_margin),size.y*0.40)))
		if target!=margins:
			margins=target
			_build_boxes()
	func _build_boxes() -> void:
		_boxes.clear()
		var pair: Array=TX[kind]
		for state in ["normal","hover","pressed","disabled"]:
			var texture: Texture2D=pair[0]
			if state=="pressed":texture=pair[1]
			elif state=="disabled":texture=pair[2]
			var box:=StyleBoxTexture.new()
			box.texture=texture
			box.set_texture_margin_all(margins)
			box.content_margin_left=0;box.content_margin_right=0;box.content_margin_top=0;box.content_margin_bottom=0
			_boxes[state]=box
	func set_kind(value: String) -> void:
		_configure(value)
		queue_redraw()
	func _process(delta: float) -> void:
		var lit_target:=1.0 if (is_hovered() or is_pressed()) else 0.0
		var press_target:=1.0 if is_pressed() else 0.0
		var changed:=false
		if absf(lit-lit_target)>.01:lit=move_toward(lit,lit_target,delta*8.0);changed=true
		else:lit=lit_target
		if absf(press-press_target)>.01:press=move_toward(press,press_target,delta*16.0);changed=true
		else:press=press_target
		if changed:queue_redraw()
	func _caption() -> String:
		return text
	func _get_minimum_size() -> Vector2:
		var font: Font=TITLE_FONT if use_title_font else FONT
		var icon_part:=0.0
		if glyph!="":icon_part=minf(size.y*.52,font_size*1.35)+8.0
		var extent:=maxi(9,int(font_size))
		return Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x+icon_part+maxf(18.0,margins*.4),0.0)
	func _draw() -> void:
		if size.x<6.0 or size.y<4.0:return
		var state:="normal"
		if disabled:state="disabled"
		elif is_pressed():state="pressed"
		elif lit>.5:state="hover"
		var box: StyleBoxTexture=_boxes.get(state)
		if box==null:return
		if kind=="gold" and state!="disabled":
			# 위로 번지는 금빛 (호버·눌림에서 강해진다)
			for i in range(5):
				var grow:=1.5+float(i)*2.6
				var alpha:=(.10-float(i)*.018)*(1.0+lit*.9)
				draw_rect(Rect2(-grow,-grow,size.x+grow*2.0,size.y+grow*2.0),Color(1,.82,.42,0.0),false)
			var halo:=Rect2(Vector2(-2.0,-2.0),size+Vector2(4.0,4.0))
			draw_style_box(box,halo) if false else null
		box.modulate_color=Color(1.0+lit*.10,1.0+lit*.08,1.0+lit*.04,1.0)
		box.draw(get_canvas_item(),Rect2(Vector2.ZERO,size))
		if disabled and kind=="gold":
			# 비활성 금판은 어두운 철판 위에 크림색 글자 → 죽은 글자 금지
			draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(.03,.03,.05,.28))
		var font: Font=TITLE_FONT if use_title_font else FONT
		var extent:=maxi(9,int(font_size))
		var caption:=text
		var icon_size:=minf(size.y*.52,font_size*1.35)*icon_scale if glyph!="" else 0.0
		var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x
		var gap:=8.0 if glyph!="" else 0.0
		var total:=width+icon_size+gap
		var start:=Vector2((size.x-total)*.5,0)
		var offset_y:=press*1.4
		if glyph!="":
			var icon_box:=Rect2(Vector2(start.x,size.y*.5-icon_size*.5+offset_y),Vector2(icon_size,icon_size))
			var color:=glyph_color
			if disabled:color=Color(glyph_color.r,glyph_color.g,glyph_color.b,.60)
			G.draw_glyph(self,glyph,icon_box,color,maxf(1.2,size.y*.024),0.0)
			start.x+=icon_size+gap
		var baseline:=size.y*.5+offset_y+(font.get_ascent(extent)-font.get_descent(extent))*.5
		var text_color:=ink
		if disabled:text_color=Color(ink.r,ink.g,ink.b,.62) if kind!="gold" else Color("8f8a7c")
		if kind=="gold" and disabled:text_color=Color("cfc7b2")
		if kind!="gold":
			draw_string_outline(font,Vector2(start.x,baseline),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,3,Color(0,0,0,.55))
		draw_string(font,Vector2(start.x,baseline),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,extent,text_color)

## 선택 카드·패널 뒤로 번지는 금빛 광(텍스처 뒤에 깔린다).
class Glow extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(1,.82,.42)
	var radius:=12.0
	var spread:=9.0
	var strength:=1.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<6.0:return
		var box:=Rect2(Vector2.ZERO,size)
		for i in range(5):
			var grow:=2.0+float(i)*(spread/5.0)
			var alpha:=(.30-float(i)*.05)*strength
			T.rounded_outline(self,box.grow(grow),Color(color.r,color.g,color.b,alpha),radius+grow,2.6)
