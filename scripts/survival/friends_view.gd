extends "res://scripts/ui/lobby_screen.gd"
## 2.0.25 친구와 함께 — 시안(달빛 아래 친구와 함께) 복제.
## 왼쪽: 기와 지붕·등롱이 걸린 나무 문패 판 "방 만들기" + 금빛 촉 버튼 두 개.
## 오른쪽: 붉은 낙관·술이 달린 한지 판 "코드로 입장" + 코드 입력 + 금빛 입장 버튼 + 최근 코드.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const INK=Color("2c2115")
const INK_SOFT=Color("5b4834")
const LEFT:=Rect2(22,98,590,570)
const JOIN_X:=632.0
const JOIN_W:=616.0
const JOIN_Y:=106.0
const JOIN_H:=562.0

func build() -> void:
	header("친구와 함께","친구와 방을 만들거나, 코드를 입력해 함께 플레이하세요","users")
	_left_panel()
	_right_panel()

# ---------------------------------------------------------------- 방 만들기
func _left_panel() -> void:
	var plate:=V.frame(self,Rect2(0,0,1,1))
	plate.name="FriendsLeftFrame"
	place(plate,LEFT)
	var wall:=TextureRect.new()
	wall.texture=preload("res://assets/woo/codex/codex_bg.jpg")
	wall.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	wall.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wall.modulate=Color(.55,.52,.78,.55)
	wall.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	wall.name="FriendsWall"
	var roof:=TextureRect.new()
	roof.texture=V.TEX_ROOF
	roof.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	roof.stretch_mode=TextureRect.STRETCH_SCALE
	roof.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(roof)
	roof.name="FriendsRoof"
	place(roof,Rect2(LEFT.position.x+LEFT.size.x*.5-150,LEFT.position.y-26,300,120))
	for side in [0,1]:
		var lantern:=TextureRect.new()
		lantern.texture=V.TEX_LANTERN
		lantern.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		lantern.stretch_mode=TextureRect.STRETCH_SCALE
		lantern.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(lantern)
		lantern.name="FriendsLantern%d"%side
		var x: float=LEFT.position.x+(28.0 if side==0 else LEFT.size.x-72.0)
		place(lantern,Rect2(x,LEFT.position.y+34,44,84))
	var sign:=V.patch(self,V.TEX_WOOD,Rect2(Vector2.ZERO,Vector2(1,1)),56)
	sign.name="FriendsSign"
	place(sign,Rect2(LEFT.position.x+LEFT.size.x*.5-176,LEFT.position.y+28,352,96))
	var sign_text:=label(self,"방 만들기",40,V.GOLD_BRIGHT,true)
	sign_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	sign_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	sign_text.name="FriendsSignText"
	place(sign_text,Rect2(LEFT.position.x+LEFT.size.x*.5-176,LEFT.position.y+30,352,92))
	var guide:=label(self,"친구들과 함께할 방을 만들고\n원하는 인원으로 시작할 수 있습니다.",16.5,Color(.92,.90,.98))
	guide.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_constant_override("line_spacing",10)
	place(guide,Rect2(LEFT.position.x+60,LEFT.position.y+140,LEFT.size.x-120,60))
	var create8:=V.PlateButton.new()
	create8.kind="gold"
	create8.text="8인 방 만들기"
	create8.glyph="users"
	create8.font_size=24
	create8.name="CreateEight"
	create8.custom_minimum_size=Vector2.ZERO
	create8.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	create8.pressed.connect(func()->void:
		if create8.usable():game.sound.play_clip("button");game.create_room("친구와 함께",8,true,"",2))
	add_child(create8)
	game.button_feel(create8)
	place(create8,Rect2(LEFT.position.x+56,LEFT.position.y+214,LEFT.size.x-112,74))
	var create6:=V.PlateButton.new()
	create6.kind="dark"
	create6.text="6인 방 만들기"
	create6.glyph="users"
	create6.font_size=24
	create6.name="CreateSix"
	create6.custom_minimum_size=Vector2.ZERO
	create6.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	create6.pressed.connect(func()->void:
		if create6.usable():game.sound.play_clip("button");game.create_room("친구와 함께",6,true,"",2))
	add_child(create6)
	game.button_feel(create6)
	place(create6,Rect2(LEFT.position.x+56,LEFT.position.y+304,LEFT.size.x-112,72))
	var comp:=label(self,"도사 6 : 요괴 2 · 8인 고정",14.5,Color(.86,.82,.96))
	comp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(comp,Rect2(LEFT.position.x+56,LEFT.position.y+396,LEFT.size.x-112,22))
	var line:=gold_divider(self,Rect2(LEFT.position.x+56,LEFT.position.y+426,LEFT.size.x-112,12))
	var tip:=label(self,"빈 자리는 봇으로 채워집니다 · 방 코드는 자동으로 기억됩니다",13.5,Color(.78,.76,.90))
	tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(tip,Rect2(LEFT.position.x+40,LEFT.position.y+446,LEFT.size.x-80,44))
	var marks:=label(self,"달빛 아래, 같은 방에서",14,Color(.84,.74,.56),true)
	marks.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(marks,Rect2(LEFT.position.x+40,LEFT.position.y+LEFT.size.y-44,LEFT.size.x-80,24))

# ---------------------------------------------------------------- 코드로 입장
func join_rect() -> Rect2:
	return Rect2(JOIN_X,JOIN_Y,right_edge()-JOIN_X,JOIN_H)

func _right_panel() -> void:
	var sheet:=V.patch(self,V.TEX_PARCHMENT,Rect2(Vector2.ZERO,Vector2(1,1)),42)
	sheet.name="FriendsSheet"
	place(sheet,join_rect())
	var seal:=TextureRect.new()
	seal.texture=V.TEX_ICON_SEAL
	seal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(seal)
	seal.name="FriendsSeal"
	var tassel:=TextureRect.new()
	tassel.texture=V.TEX_TASSEL
	tassel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tassel.stretch_mode=TextureRect.STRETCH_SCALE
	tassel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(tassel)
	tassel.name="FriendsTassel"
	var heading:=label(self,"코드로 입장",40,Color(.24,.16,.10),true)
	heading.name="FriendsJoinTitle"
	place(heading,Rect2(JOIN_X+40,JOIN_Y+18,420,54))
	var guide:=label(self,"친구가 만든 방의 코드를 입력해 입장하세요.",16.5,Color(.28,.22,.15))
	place(guide,Rect2(JOIN_X+40,JOIN_Y+96,JOIN_W-80,26))
	var input:=LineEdit.new()
	input.name="RoomCodeInput"
	input.placeholder_text="방 코드 입력 (예: 달빛-4821)"
	input.max_length=16
	input.add_theme_font_override("font",T.FONT)
	input.add_theme_font_size_override("font_size",20)
	input.add_theme_color_override("font_color",Color("f6e7c8"))
	input.add_theme_color_override("font_placeholder_color",Color(.86,.80,.68,.75))
	input.add_theme_color_override("caret_color",Color("ffd98a"))
	var input_style:=LC.panel_box(Color(.07,.06,.10,.94),12,Color(.92,.78,.50,.75),2)
	input_style.content_margin_left=20;input_style.content_margin_right=20
	var input_focus:=LC.panel_box(Color(.09,.08,.13,.96),12,Color(1,.90,.62,.95),2)
	input_focus.content_margin_left=20;input_focus.content_margin_right=20
	input.add_theme_stylebox_override("normal",input_style)
	input.add_theme_stylebox_override("focus",input_focus)
	add_child(input)
	game.code_input=input
	place(input,Rect2(JOIN_X+40,JOIN_Y+134,JOIN_W-126,58))
	var mark:=V.Glyph.new()
	mark.glyph="scroll"
	mark.tint=Color(.96,.84,.58)
	add_child(mark)
	mark.name="FriendsCodeMark"
	place(mark,Rect2(JOIN_X+JOIN_W-122,JOIN_Y+148,30,30))
	var join:=V.PlateButton.new()
	join.kind="gold"
	join.text="이 코드로 입장"
	join.glyph="invite"
	join.font_size=22
	join.name="JoinWithCode"
	join.custom_minimum_size=Vector2.ZERO
	join.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	join.pressed.connect(func()->void:
		if join.usable():game.sound.play_clip("button");game.join_with_code(input.text))
	add_child(join)
	game.button_feel(join)
	place(join,Rect2(JOIN_X+40,JOIN_Y+212,JOIN_W-80,66))
	var codes: Array=game.storage.data.room_codes
	var recent_line:=divider(self,Color(.52,.38,.20,.40))
	recent_line.name="FriendsRule"
	place(recent_line,Rect2(JOIN_X+40,JOIN_Y+300,JOIN_W-80,1))
	var recent_label:=label(self,"최근 코드",16,INK_SOFT,true)
	place(recent_label,Rect2(JOIN_X+40,JOIN_Y+310,220,24))
	if codes.is_empty():
		var empty:=label(self,"아직 만든 방이 없습니다. 방을 만들면 코드가 여기에 남습니다.",15,Color(.42,.34,.24))
		place(empty,Rect2(JOIN_X+40,JOIN_Y+340,JOIN_W-80,24))
	else:
		var y:=JOIN_Y+340.0
		for code in codes.slice(0,3):
			var strip:=V.patch(self,V.TEX_TILE,Rect2(Vector2.ZERO,Vector2(1,1)),30)
			strip.name="RecentStrip_"+String(code)
			place(strip,Rect2(JOIN_X+40,y,JOIN_W-80,52))
			var pill:=label(self,String(code),17,Color(.98,.90,.72),true)
			pill.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			place(pill,Rect2(JOIN_X+58,y+8,JOIN_W-80-190,36))
			var again:=V.PlateButton.new()
			again.kind="dark"
			again.text="다시 입장"
			again.glyph="invite"
			again.font_size=15
			again.name="RecentTag_"+String(code)
			again.custom_minimum_size=Vector2.ZERO
			again.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
			again.pressed.connect(func()->void:
				if again.usable():game.sound.play_clip("button");game.join_with_code(String(code)))
			add_child(again)
			game.button_feel(again)
			place(again,Rect2(JOIN_X+JOIN_W-80-152,y+7,140,38))
			y+=58.0
	var join_tip:=label(self,"방장이 시작하면 같은 코드로 들어온 친구가 한 번에 입장합니다.",13.5,Color(.42,.34,.24,.95))
	join_tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(join_tip,Rect2(JOIN_X+40,JOIN_Y+JOIN_H-58,JOIN_W-80,40))

func arrange() -> void:
	if not built:return
	reshape(self.get_node_or_null("FriendsLeftFrame"),LEFT)
	reshape(self.get_node_or_null("FriendsWall"),Rect2(LEFT.position+Vector2(10,10),LEFT.size-Vector2(20,20)))
	reshape(self.get_node_or_null("FriendsRoof"),Rect2(LEFT.position.x+LEFT.size.x*.5-150,LEFT.position.y-26,300,120))
	for side in [0,1]:
		var lantern: Node=self.get_node_or_null("FriendsLantern%d"%side)
		if lantern!=null:
			var x: float=LEFT.position.x+(28.0 if side==0 else LEFT.size.x-72.0)
			reshape(lantern,Rect2(x,LEFT.position.y+34,44,84))
	reshape(self.get_node_or_null("FriendsSign"),Rect2(LEFT.position.x+LEFT.size.x*.5-176,LEFT.position.y+28,352,96))
	reshape(self.get_node_or_null("FriendsSignText"),Rect2(LEFT.position.x+LEFT.size.x*.5-176,LEFT.position.y+30,352,92))
	reshape(self.get_node_or_null("FriendsSheet"),join_rect())
	reshape(self.get_node_or_null("FriendsSeal"),Rect2(JOIN_X+JOIN_W-70,JOIN_Y+26,52,52))
	reshape(self.get_node_or_null("FriendsTassel"),Rect2(JOIN_X+JOIN_W-60,JOIN_Y+74,30,104))
	reshape(self.get_node_or_null("FriendsCodeMark"),Rect2(JOIN_X+JOIN_W-122,JOIN_Y+148,30,30))
	var input: Node=self.get_node_or_null("RoomCodeInput")
	if input!=null:reshape(input as Control,Rect2(JOIN_X+40,JOIN_Y+134,JOIN_W-126,58))

## 붉은 밀랍 낙관.
class SealBadge extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var rad:=minf(size.x,size.y)*.5-1.0
		draw_circle(c,rad,Color(.50,.14,.14,1))
		draw_circle(c,rad*.84,Color(.66,.22,.20,1))
		draw_arc(c,rad*.95,0,TAU,28,Color(1,.90,.80,.30),1.1,true)
		G.draw_glyph(self,"seal",Rect2(c-Vector2(rad*.52,rad*.52),Vector2(rad*1.04,rad*1.04)),Color(1,.93,.86,.9),1.2)
