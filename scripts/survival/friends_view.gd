extends "res://scripts/ui/lobby_screen.gd"
## 2.0.23 친구와 함께 — 두 개의 큰 패널.
## 왼쪽 `방 만들기`: 등불이 걸린 황동 문패 판 + 금빛 방 만들기 버튼.
## 오른쪽 `코드로 입장`: 붉은 낙관이 찍힌 한지 초대장 + 코드 입력과 최근 코드.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const INK=Color("2a2016")
const INK_SOFT=Color("584634")
const LEFT_POS:=Vector2(26,96)
const LEFT_SIZE:=Vector2(560,548)
const RIGHT_POS:=Vector2(610,96)
const RIGHT_SIZE:=Vector2(644,548)

func build() -> void:
	header("친구와 함께","방 코드를 만들어 보내거나, 받은 코드로 같은 방에 입장합니다")
	note("빈 자리는 오프라인 봇으로 채워집니다 · 인앱결제·광고 없음")
	_make_panel()
	_join_panel()

# ---------------------------------------------------------------- 방 만들기
func _make_panel() -> void:
	var plate:=UIK.nine(self,UIK.TEX_PANEL,40)
	plate.self_modulate=Color(.92,.90,.98,1.0)
	place(plate,Rect2(LEFT_POS,LEFT_POS+LEFT_SIZE))
	# 등불 + 문패
	var lantern:=Control.new()
	lantern.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(lantern)
	place(lantern,Rect2(LEFT_POS.x+26,LEFT_POS.y+24,42,42))
	lantern.draw.connect(func()->void:G.draw_glyph(lantern,"lantern",Rect2(Vector2.ZERO,lantern.size),P.BRASS_LIGHT,1.8))
	var heading:=label(self,"방 만들기",30,T.GOLD_SOFT,true)
	place(heading,Rect2(LEFT_POS.x+80,LEFT_POS.y+18,300,40))
	var guide:=label(self,"방 코드를 만들어 친구에게 보내면 같은 방에서 함께 시작합니다. 방장이 시작하면 8인이 한 번에 입장합니다.",15.5,Color(0.86,0.90,0.97))
	guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(guide,Rect2(LEFT_POS.x+28,LEFT_POS.y+66,LEFT_SIZE.x-56,52))
	var create8=UIK.MetalButton.new()
	create8.kind="gold"
	create8.text="8인 방 만들기 · 도사 6 : 요괴 2"
	create8.glyph="swords"
	create8.font_size=int(19)
	create8.name="CreateEight"
	create8.custom_minimum_size=Vector2.ZERO
	create8.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	create8.pressed.connect(func()->void:
		if create8.usable():game.sound.play_clip("button");game.create_room("친구와 함께",8,true,"",2))
	add_child(create8)
	place(create8,Rect2(LEFT_POS.x+28,LEFT_POS.y+132,LEFT_SIZE.x-56,62))
	game.button_feel(create8)
	var create6=UIK.MetalButton.new()
	create6.kind="iron"
	create6.text="6인 방 만들기 · 도사 4 : 요괴 2"
	create6.glyph="swords"
	create6.font_size=int(17)
	create6.name="CreateSix"
	create6.custom_minimum_size=Vector2.ZERO
	create6.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	create6.pressed.connect(func()->void:
		if create6.usable():game.sound.play_clip("button");game.create_room("친구와 함께",6,true,"",2))
	add_child(create6)
	place(create6,Rect2(LEFT_POS.x+28,LEFT_POS.y+206,LEFT_SIZE.x-56,54))
	game.button_feel(create6)
	var line:=divider(self,Color(0.85,0.72,0.47,0.24))
	place(line,Rect2(LEFT_POS.x+30,LEFT_POS.y+284,LEFT_SIZE.x-60,1))
	# 구성
	var comp_caption:=label(self,"구성",14,T.MUTED)
	place(comp_caption,Rect2(LEFT_POS.x+30,LEFT_POS.y+298,80,22))
	for i in range(8):
		var dot:=Control.new()
		dot.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		place(dot,Rect2(LEFT_POS.x+80+float(i)*26.0,LEFT_POS.y+296,22,22))
		var dao:=i<6
		dot.draw.connect(func()->void:
			var c: Vector2=dot.size*.5
			var rad:=dot.size.x*.42
			dot.draw_circle(c,rad,Color(.10,.09,.08,.9))
			dot.draw_arc(c,rad,0,TAU,24,Color(.86,.72,.42,.95) if dao else Color(.74,.58,1.0,.95),1.5,true)
			G.draw_glyph(dot,"lotus" if dao else "fox",Rect2(c-Vector2(rad*.6,rad*.6),Vector2(rad*1.2,rad*1.2)),Color(.86,.72,.42) if dao else Color(.78,.64,1.0),1.2))
	var comp:=label(self,"도사 6명 · 요괴 2명 · 8인 고정",14.5,T.gold(.9))
	place(comp,Rect2(LEFT_POS.x+300,LEFT_POS.y+298,LEFT_SIZE.x-330,22))
	var code_caption:=label(self,"방 코드 형식",14,T.MUTED)
	place(code_caption,Rect2(LEFT_POS.x+30,LEFT_POS.y+334,200,22))
	var sample:=label(self,"달빛-0000 · 서원-0000 처럼 만들어집니다",16.5,T.GOLD)
	place(sample,Rect2(LEFT_POS.x+30,LEFT_POS.y+358,LEFT_SIZE.x-60,24))
	var tip:=label(self,"최근에 만든 코드는 자동으로 기억되어 다시 입장할 수 있습니다.",14,Color(0.78,0.80,0.90,0.94))
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(tip,Rect2(LEFT_POS.x+30,LEFT_POS.y+392,LEFT_SIZE.x-60,44))
	# 문패 장식(아래)
	var plaque:=UIK.nine(self,UIK.TEX_PLAQUE,24)
	place(plaque,Rect2(LEFT_POS.x+30,LEFT_POS.y+LEFT_SIZE.y-92,LEFT_SIZE.x-60,68))
	var plaque_text:=label(self,"달빛 아래, 같은 방에서",16,P.BRASS_LIGHT,true)
	plaque_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(plaque_text,Rect2(LEFT_POS.x+40,LEFT_POS.y+LEFT_SIZE.y-74,LEFT_SIZE.x-80,30))

# ---------------------------------------------------------------- 코드로 입장
func _join_panel() -> void:
	var panel:=Control.new()
	panel.name="JoinPaper"
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	place(panel,Rect2(RIGHT_POS,RIGHT_SIZE))
	var drawing:=Control.new()
	drawing.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(drawing)
	drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing.draw.connect(func()->void:
		var box:=Rect2(Vector2(10,10),drawing.size-Vector2(20,20))
		var w:=box.size.x
		var h:=box.size.y
		for i in range(4):
			var grow:=2.0+float(i)*2.8
			LC.rounded_outline(drawing,box.grow(grow),Color(0,0,0,.18-float(i)*.035),8.0+grow,3.0)
		LC.gradient_rounded(drawing,box,Color(.965,.905,.780,1.0),Color(.868,.792,.636,1.0),6.0)
		var rng:=RandomNumberGenerator.new()
		rng.seed=830417
		for i in range(52):
			var y:=box.position.y+rng.randf_range(6.0,h-6.0)
			var x0:=box.position.x+rng.randf_range(4.0,w*.4)
			var x1:=x0+rng.randf_range(w*.15,w*.55)
			drawing.draw_line(Vector2(x0,y),Vector2(minf(x1,box.end.x-4.0),y),Color(.55,.44,.28,rng.randf_range(.03,.07)),1.0)
		LC.rounded_outline(drawing,box.grow(-1.0),Color(.46,.34,.20,.38),6.0,1.2)
		LC.rounded_outline(drawing,box.grow(-6.0),Color(.46,.34,.20,.15),4.0,1.0)
		# 위 마구리
		LC.rounded(drawing,Rect2(Vector2(box.position.x-6.0,box.position.y-2.0),Vector2(w+12.0,12.0)),Color(.10,.08,.11,1.0),6.0)
		drawing.draw_line(Vector2(box.position.x,box.position.y+2.0),Vector2(box.end.x,box.position.y+2.0),Color(.95,.84,.60,.35),1.4))
	# 낙관
	var stamp:=Control.new()
	stamp.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(stamp)
	place(stamp,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+30,56,56))
	stamp.draw.connect(func()->void:
		var c: Vector2=stamp.size*.5
		var rad:=minf(stamp.size.x,stamp.size.y)*.5-1.0
		stamp.draw_circle(c,rad,Color(.60,.18,.17,.96))
		stamp.draw_circle(c,rad*.84,Color(.96,.90,.80,.18))
		G.draw_glyph(stamp,"seal",Rect2(c-Vector2(rad*.56,rad*.56),Vector2(rad*1.12,rad*1.12)),Color(1,.94,.86,.92),1.3))
	var heading:=label(panel,"코드로 입장",30,INK,true)
	place(heading,Rect2(RIGHT_POS.x+104,RIGHT_POS.y+24,360,40))
	var guide:=label(panel,"친구에게 받은 방 코드를 입력하면 같은 방으로 들어갑니다. 코드는 4자 이상입니다.",15,Color(.30,.24,.16))
	guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(guide,Rect2(RIGHT_POS.x+104,RIGHT_POS.y+68,RIGHT_SIZE.x-128,44))
	var line:=divider(panel,Color(.45,.33,.20,.35))
	place(line,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+120,RIGHT_SIZE.x-68,1))
	var input:=LineEdit.new()
	input.name="RoomCodeInput"
	input.placeholder_text="예: 달빛-4821"
	input.max_length=16
	input.add_theme_font_override("font",T.FONT)
	input.add_theme_font_size_override("font_size",int(20.0*s))
	input.add_theme_color_override("font_color",INK)
	input.add_theme_color_override("font_placeholder_color",Color(.45,.38,.28,.75))
	input.add_theme_color_override("caret_color",Color(.35,.24,.10))
	var input_style:=LC.panel_box(Color(.99,.97,.92,.96),10,Color(.42,.30,.16,.55),1)
	input_style.content_margin_left=16;input_style.content_margin_right=16
	var input_focus:=LC.panel_box(Color(1,1,.98,1.0),10,Color(.62,.42,.14,.95),2)
	input_focus.content_margin_left=16;input_focus.content_margin_right=16
	input.add_theme_stylebox_override("normal",input_style)
	input.add_theme_stylebox_override("focus",input_focus)
	panel.add_child(input)
	place(input,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+140,356,58))
	game.code_input=input
	var join=UIK.MetalButton.new()
	join.kind="gold"
	join.text="이 코드로 입장"
	join.glyph="invite"
	join.font_size=int(18)
	join.name="JoinWithCode"
	join.custom_minimum_size=Vector2.ZERO
	join.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	join.pressed.connect(func()->void:
		if join.usable():game.sound.play_clip("button");game.join_with_code(input.text))
	panel.add_child(join)
	place(join,Rect2(RIGHT_POS.x+402,RIGHT_POS.y+140,RIGHT_SIZE.x-436,58))
	game.button_feel(join)
	var recent_line:=divider(panel,Color(.45,.33,.20,.30))
	place(recent_line,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+216,RIGHT_SIZE.x-68,1))
	var recent_label:=label(panel,"최근 코드",14,INK_SOFT,false)
	place(recent_label,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+228,240,22))
	var codes: Array=game.storage.data.room_codes
	if codes.is_empty():
		var empty:=label(panel,"아직 만든 방이 없습니다. 방을 만들면 코드가 여기에 남습니다.",14.5,Color(.40,.32,.22))
		place(empty,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+258,RIGHT_SIZE.x-68,24))
	else:
		var y:=254.0
		for code in codes.slice(0,4):
			var strip:=UIK.nine(panel,UIK.TEX_PLAQUE,20)
			strip.self_modulate=Color(1,1,1,.95)
			place(strip,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+y,RIGHT_SIZE.x-68,48))
			var pill:=label(panel,String(code),16.5,P.BRASS_LIGHT,true)
			pill.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			place(pill,Rect2(RIGHT_POS.x+50,RIGHT_POS.y+y+6,RIGHT_SIZE.x-68-150,36))
			var again=UIK.MetalButton.new()
			again.kind="iron"
			again.text="다시 입장"
			again.glyph="invite"
			again.font_size=int(15)
			again.name="RecentTag_"+String(code)
			again.custom_minimum_size=Vector2.ZERO
			again.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
			again.pressed.connect(func()->void:
				if again.usable():game.sound.play_clip("button");game.join_with_code(String(code)))
			panel.add_child(again)
			place(again,Rect2(RIGHT_POS.x+RIGHT_SIZE.x-34-146,RIGHT_POS.y+y+5,132,38))
			game.button_feel(again)
			y+=56.0
	var join_tip:=label(panel,"방장이 시작하면 같은 코드로 들어온 친구가 한 번에 입장합니다.",13.5,Color(.40,.32,.22,.95))
	place(join_tip,Rect2(RIGHT_POS.x+34,RIGHT_POS.y+RIGHT_SIZE.y-54,RIGHT_SIZE.x-68,22))

func arrange() -> void:
	pass
