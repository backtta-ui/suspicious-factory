extends "res://scripts/ui/lobby_screen.gd"
## 친구와 함께: 전통 문패 카드 두 장으로 방 만들기와 코드 입장을 나눈다.
## 8인 구성은 도사 6 : 요괴 2로 고정이다.
const LEFT_POS:=Vector2(26,104)
const LEFT_SIZE:=Vector2(560,396)
const RIGHT_POS:=Vector2(606,104)
const RIGHT_SIZE:=Vector2(648,396)

func build() -> void:
	header("친구와 함께","방 코드를 만들어 보내거나, 받은 코드로 같은 방에 입장합니다")
	note("빈 자리는 오프라인 봇으로 채워집니다 · 인앱결제·광고 없음")
	_plaque(LEFT_POS,LEFT_SIZE)
	_plaque(RIGHT_POS,RIGHT_SIZE)
	# 좌: 방 만들기
	var heading:=label(self,"방 만들기",23,T.GOLD_SOFT,true)
	place(heading,Rect2(LEFT_POS.x+28,LEFT_POS.y+12,300,30))
	var guide:=label(self,"방 코드를 만들어 친구에게 보내면 같은 방에서 함께 시작합니다. 방장이 시작하면 8인이 한 번에 입장합니다.",12.5,Color(0.80,0.84,0.94))
	guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(guide,Rect2(LEFT_POS.x+28,LEFT_POS.y+50,LEFT_SIZE.x-56,44))
	var create8:=button("8인 방 만들기 · 도사 6 : 요괴 2",func()->void:game.create_room("친구와 함께",8,true,"",2),self,true,15)
	create8.name="CreateEight"
	place(create8,Rect2(LEFT_POS.x+28,LEFT_POS.y+112,LEFT_SIZE.x-56,50))
	var create6:=button("6인 방 만들기 · 도사 4 : 요괴 2",func()->void:game.create_room("친구와 함께",6,true,"",2),self,false,14)
	create6.name="CreateSix"
	place(create6,Rect2(LEFT_POS.x+28,LEFT_POS.y+174,LEFT_SIZE.x-56,46))
	var line:=divider(self,Color(0.85,0.72,0.47,0.2))
	place(line,Rect2(LEFT_POS.x+28,LEFT_POS.y+238,LEFT_SIZE.x-56,1))
	var strip_label:=label(self,"구성",11.5,T.MUTED)
	place(strip_label,Rect2(LEFT_POS.x+28,LEFT_POS.y+250,60,18))
	var dots:=HBoxContainer.new()
	dots.add_theme_constant_override("separation",5)
	dots.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(dots)
	place(dots,Rect2(LEFT_POS.x+76,LEFT_POS.y+248,320,20))
	for i in range(8):
		var dot:=label(dots,"●",10,T.DAO if i<6 else T.YOKAI)
		dot.custom_minimum_size=Vector2(12,18)
	var comp:=label(self,"도사 6명 · 요괴 2명 · 8인 고정",11.5,T.gold(.85))
	place(comp,Rect2(LEFT_POS.x+236,LEFT_POS.y+250,LEFT_SIZE.x-264,18))
	var code_caption:=label(self,"방 코드 형식",11.5,T.MUTED)
	place(code_caption,Rect2(LEFT_POS.x+28,LEFT_POS.y+282,240,18))
	var sample:=label(self,"달빛-0000 · 서원-0000 처럼 만들어집니다",12.5,T.GOLD)
	place(sample,Rect2(LEFT_POS.x+28,LEFT_POS.y+302,LEFT_SIZE.x-56,20))
	var tip:=label(self,"최근에 만든 코드는 자동으로 기억되어 다시 입장할 수 있습니다.",11,Color(0.70,0.74,0.84,0.85))
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(tip,Rect2(LEFT_POS.x+28,LEFT_POS.y+334,LEFT_SIZE.x-56,34))

	# 우: 코드로 입장
	var join_heading:=label(self,"코드로 입장",23,T.GOLD_SOFT,true)
	place(join_heading,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+12,300,30))
	var join_guide:=label(self,"친구에게 받은 방 코드를 입력하면 같은 방으로 들어갑니다. 코드는 4자 이상입니다.",12.5,Color(0.80,0.84,0.94))
	join_guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(join_guide,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+50,RIGHT_SIZE.x-56,40))
	var input:=LineEdit.new()
	input.name="RoomCodeInput"
	input.placeholder_text="예: 달빛-4821"
	input.max_length=16
	input.add_theme_font_override("font",T.FONT)
	input.add_theme_font_size_override("font_size",15)
	input.add_theme_color_override("font_color",T.IVORY)
	input.add_theme_color_override("font_placeholder_color",Color(0.6,0.64,0.74))
	var input_style:=T.panel_box(Color(0.02,0.03,0.06,0.92),8,Color(0.85,0.72,0.47,0.45),1)
	input_style.content_margin_left=14;input_style.content_margin_right=14
	var input_focus:=T.panel_box(Color(0.03,0.04,0.08,0.95),8,Color(0.95,0.83,0.55,0.9),2)
	input_focus.content_margin_left=14;input_focus.content_margin_right=14
	input.add_theme_stylebox_override("normal",input_style)
	input.add_theme_stylebox_override("focus",input_focus)
	add_child(input)
	place(input,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+104,330,46))
	game.code_input=input
	var join:=button("이 코드로 입장",func()->void:game.join_with_code(input.text),self,true,15)
	join.name="JoinWithCode"
	place(join,Rect2(RIGHT_POS.x+372,RIGHT_POS.y+104,248,46))
	var recent_line:=divider(self,Color(0.85,0.72,0.47,0.2))
	place(recent_line,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+172,RIGHT_SIZE.x-56,1))
	var recent_label:=label(self,"최근 코드",11.5,T.MUTED)
	place(recent_label,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+184,240,18))
	var codes: Array=game.storage.data.room_codes
	if codes.is_empty():
		var empty:=label(self,"아직 만든 방이 없습니다.",11.5,T.MUTED)
		place(empty,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+208,RIGHT_SIZE.x-56,18))
	else:
		var y:=206.0
		for code in codes.slice(0,3):
			var pill:=label(self,String(code),13,T.IVORY)
			pill.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			pill.add_theme_stylebox_override("normal",T.pill_box(Color(0.02,0.03,0.06,0.72),8,Color(0.85,0.72,0.47,0.3)))
			place(pill,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+y,RIGHT_SIZE.x-56-136,36))
			var again:=button("다시 입장",func()->void:game.join_with_code(String(code)),self,false,12)
			again.name="RecentTag_"+String(code)
			place(again,Rect2(RIGHT_POS.x+RIGHT_SIZE.x-28-124,RIGHT_POS.y+y,124,36))
			y+=44.0
	var join_tip:=label(self,"방장이 시작하면 같은 코드로 들어온 친구가 한 번에 입장합니다.",11,Color(0.70,0.74,0.84,0.85))
	place(join_tip,Rect2(RIGHT_POS.x+28,RIGHT_POS.y+346,RIGHT_SIZE.x-56,20))


func _plaque(pos: Vector2,size_value: Vector2) -> void:
	var plaque:=Art.Plaque.new()
	plaque.cords=false
	add_child(plaque)
	place(plaque,Rect2(pos,size_value))

func arrange() -> void:
	pass
