extends "res://scripts/woo/mobile_button.gd"
## 대기실 상단 바와 하단 CTA가 쓰는 입체 버튼.
## 글자·아이콘·금빛 광택·눌림을 전부 직접 그려서, 사진을 깐 판 위에 투명 버튼을
## 얹는 방식이 아니라 실제 노드 하나가 상태(호버·눌림·비활성)에 따라 스스로 변한다.
const T=preload("res://scripts/ui/lobby_theme.gd")
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")

## metal: 다크 메탈 보조 버튼 · gold: 금빛 주 동작 · capsule: 방 코드 알약 · ghost: 테두리만
var variant:="metal"
var glyph:=""
var accent:=Color("d9b878")
var font_size:=18
var use_title_font:=false
var radius:=-1.0
var glow_strength:=1.0
var lit:=0.0
var press:=0.0

func _ready() -> void:
	super()
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_outline_color"]:
		add_theme_color_override(state,Color(0,0,0,0))
	add_theme_constant_override("outline_size",0)
	focus_mode=Control.FOCUS_NONE
	mouse_entered.connect(func()->void:_light(1.0))
	mouse_exited.connect(func()->void:_light(0.0))
	resized.connect(func()->void:
		pivot_offset=size*.5
		queue_redraw())
	queue_redraw()

func _light(target: float) -> void:
	lit=target
	queue_redraw()

func _process(delta: float) -> void:
	var lit_target:=1.0 if (is_hovered() or is_pressed()) else 0.0
	var press_target:=1.0 if is_pressed() else 0.0
	var changed:=false
	if absf(lit-lit_target)>.004:
		lit=move_toward(lit,lit_target,delta*7.0);changed=true
	else:lit=lit_target
	if absf(press-press_target)>.004:
		press=move_toward(press,press_target,delta*14.0);changed=true
	else:press=press_target
	if changed:queue_redraw()

func _caption() -> String:
	return text

## 글자 폭에 맞춰 단추가 스스로 넓어진다(방 코드 알약처럼 내용이 긴 단추).
func _get_minimum_size() -> Vector2:
	var font: Font=TITLE_FONT if use_title_font else FONT
	var icon_part:=minf(56.0,float(font_size)+10.0)+8.0 if glyph!="" else 0.0
	return Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+icon_part+34.0,0.0)

func _draw() -> void:
	var box:=Rect2(Vector2.ZERO,size)
	if box.size.x<4.0 or box.size.y<4.0:return
	var r:=radius if radius>=0.0 else minf(13.0,size.y*.30)
	var disabled_state:=disabled
	match variant:
		"gold":_draw_gold(box,r,disabled_state)
		"capsule":_draw_capsule(box,r,disabled_state)
		"lit":_draw_lit(box,r,disabled_state)
		"ghost":_draw_ghost(box,r,disabled_state)
		_: _draw_metal(box,r,disabled_state)
	var ink:=Color("201503") if variant=="gold" else (Color("ffe6a8") if variant=="capsule" else (Color("ffe9b4") if variant=="lit" else Color("f2e8d2")))
	if disabled_state:ink=Color(ink.r,ink.g,ink.b,.45)
	_draw_content(box,ink)

func _draw_metal(box: Rect2,r: float,off: bool) -> void:
	var dim:=0.55 if off else 1.0
	var lift:=lit*0.08
	T.gradient_rounded(self,box,Color(.185+lift,.20+lift,.27+lift,.96),Color(.048,.055,.085,.97),r)
	# 위쪽 금속 광
	draw_rect(Rect2(Vector2(r*.6,1.2),Vector2(box.size.x-r*1.2,1.2)),Color(.72,.78,.95,.16*dim))
	T.gradient_rounded(self,Rect2(Vector2(2,2),Vector2(box.size.x-4,box.size.y*.42)),Color(.55,.60,.74,.10*dim),Color(.55,.60,.74,0.0),maxf(2.0,r-2))
	# 테두리: 바깥 검정 + 안쪽 황동 실선
	T.rounded_outline(self,box,Color(0,0,0,.55),r,2.4)
	T.rounded_outline(self,box.grow(-1.6),Color(accent.r,accent.g,accent.b,(.30+.35*lit)*dim),r-1.6,1.0)
	if lit>.01:
		T.halo(self,box,Color(accent.r,accent.g,accent.b,.35*lit),r,5.0,4)
	var shade:=Rect2(Vector2(2,box.size.y*.55),Vector2(box.size.x-4,box.size.y*.45-2))
	T.rounded(self,shade,Color(0,0,0,.18),maxf(0.0,r-2))
	if press>.01:
		T.rounded(self,box,Color(0,0,0,.16*press),r)

func _draw_gold(box: Rect2,r: float,off: bool) -> void:
	var dim:=0.5 if off else 1.0
	var lift:=lit*0.05
	# 뒤로 번지는 금빛
	for i in range(6):
		var grow:=2.0+float(i)*2.4
		T.rounded_outline(self,box.grow(grow),Color(1,.86,.52,(.16-float(i)*.022)*(dim+.35*lit)),r+grow,2.6)
	T.gradient_rounded(self,box,Color(.99+lift,.92+lift,.72,.99),Color(.76,.55,.20,.99),r)
	# 윗면 광택과 아랫면 그늘
	T.gradient_rounded(self,Rect2(Vector2(2.5,2.0),Vector2(box.size.x-5.0,box.size.y*.46)),Color(1,.99,.92,.55),Color(1,.95,.78,0.0),maxf(1.0,r-2))
	draw_rect(Rect2(Vector2(r*.5,box.size.y-2.6),Vector2(box.size.x-r,1.8)),Color(.45,.30,.08,.35))
	T.rounded_outline(self,box,Color(1,.96,.80,.95),r,2.2)
	T.rounded_outline(self,box.grow(-3.0),Color(1,.90,.62,.45),r-3.0,1.0)
	# 좌우 장식 다이아몬드
	for side in [-1.0,1.0]:
		var at:=Vector2(box.size.x*.5+side*(box.size.x*.5-r*1.15),box.size.y*.5)
		T.diamond(self,at,4.2,Color(.45,.30,.08,.55))
	if press>.01:T.rounded(self,box,Color(.30,.20,.05,.18*press),r)

func _draw_lit(box: Rect2,r: float,off: bool) -> void:
	var dim:=0.6 if off else 1.0
	T.gradient_rounded(self,box,Color(.30,.225,.50,.96),Color(.115,.085,.235,.98),r)
	for i in range(5):
		var grow:=2.0+float(i)*2.2
		T.rounded_outline(self,box.grow(grow),Color(.64,.48,1.0,(.14-float(i)*.024)*dim),r+grow,2.4)
	draw_rect(Rect2(Vector2(r*.6,1.5),Vector2(box.size.x-r*1.2,1.4)),Color(1,.94,1,.20))
	T.rounded_outline(self,box,Color(.96,.82,.50,.95),r,1.8)
	T.rounded_outline(self,box.grow(-3.5),Color(.96,.82,.50,.26),r-3.5,1.0)
	if press>.01:T.rounded(self,box,Color(.02,.01,.06,.22*press),r)

func _draw_capsule(box: Rect2,r: float,off: bool) -> void:
	var dim:=0.6 if off else 1.0
	var rr:=minf(box.size.y*.5,r if r>0 else box.size.y*.5)
	T.gradient_rounded(self,box,Color(.14,.12,.09,.96),Color(.055,.045,.035,.97),rr)
	T.rounded_outline(self,box,Color(accent.r,accent.g,accent.b,(.55+.3*lit)*dim),rr,1.4)
	T.rounded_outline(self,box.grow(-2.5),Color(accent.r,accent.g,accent.b,.18*dim),rr-2.5,1.0)
	if lit>.01:T.gradient_rounded(self,box,Color(accent.r,accent.g,accent.b,.10*lit),Color(accent.r,accent.g,accent.b,0.0),rr)
	for side in [-1.0,1.0]:
		T.diamond(self,Vector2(box.size.x*.5+side*(box.size.x*.5-6.0),box.size.y*.5),2.6,Color(accent.r,accent.g,accent.b,.8))

func _draw_ghost(box: Rect2,r: float,off: bool) -> void:
	var dim:=0.5 if off else 1.0
	if lit>.01:T.rounded(self,box,Color(accent.r,accent.g,accent.b,.10*lit),r)
	T.rounded_outline(self,box,Color(accent.r,accent.g,accent.b,(.45+.4*lit)*dim),r,1.2)

func _draw_content(box: Rect2,ink: Color) -> void:
	var caption:=_caption()
	var font: Font=TITLE_FONT if use_title_font else FONT
	var icon_size:=minf(size.y*.46,28.0)
	var has_icon:=glyph!=""
	var text_width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var total:=text_width+(icon_size+8.0 if has_icon else 0.0)
	var start:=Vector2((box.size.x-total)*.5,0)
	var offset_y:=press*1.6
	if has_icon:
		var box_icon:=Rect2(Vector2(start.x,box.size.y*.5-icon_size*.5+offset_y),Vector2(icon_size,icon_size))
		var icon_color:=ink
		if variant=="gold":icon_color=Color("2a1a04")
		Glyphs.draw_glyph(self,glyph,box_icon,icon_color,1.9,0.6)
		start.x+=icon_size+8.0
	var baseline:=box.size.y*.5+offset_y+(font.get_ascent(font_size)-font.get_descent(font_size))*.5
	draw_string_outline(font,Vector2(start.x,baseline),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color(0,0,0,.35 if variant!="gold" else .25))
	draw_string(font,Vector2(start.x,baseline),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
