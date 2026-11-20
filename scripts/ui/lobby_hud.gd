class_name WooLobbyHud
extends Control
## 2.0.32 메인 로비 상단 HUD.
## 로비 원화(assets/woo/lobby_bg.png)에 그려져 있던 가짜 표시(전우치 · Lv. 12 · 12,350 · 1,280 ·
## 빨간 점 배지)를 반투명 다크네이비 + 금테 판으로 덮고, 그 자리에 storage.gd의 실제 값만 띄운다.
## 이 게임에는 레벨·경험치가 없으므로 Lv·XP 바는 그리지 않는다(초상화 + 이름 + 장착 칭호).
const T=preload("res://scripts/ui/lobby_theme.gd")
const V=preload("res://scripts/ui/ui_v25.gd")
const O=preload("res://scripts/survival/shop_ornaments.gd")
const C=preload("res://scripts/survival/characters.gd")
const Market=preload("res://scripts/survival/market.gd")
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
## 원화 좌표(1846×852)에서 덮을 영역: 오른쪽 위 가짜 HUD가 그려진 곳.
const ART_COVER:=Rect2(1030,0,816,102)
## 원화 좌표 배치값.
const PORTRAIT:=Rect2(1056,10,80,80)
const NAME_RECT:=Rect2(1148,12,236,34)
const TITLE_RECT:=Rect2(1150,48,234,24)
const PILL_H:=42.0
const PILL_Y:=25.0
## Pill은 size.y/28 비율로 글자를 그리므로 실제 글자 크기는 17×(42/28)=25.5 디자인 px다.
const PILL_FONT:=25.5
const PLUS:=Vector2(32,32)
const MAIL_X:=1674.0
const BELL_X:=1726.0
const GEAR_X:=1778.0
const ICON_Y:=28.0
const ICON_SIZE:=44.0
var game: Node
var origin:=Vector2.ZERO
var art_scale:=1.0
var panel_bg: Control
var portrait: TextureRect
var ring: TextureRect
var name_label: Label
var title_label: Label
var coin_pill: Control
var gem_pill: Control
var coin_plus: WooMobileButton
var gem_plus: WooMobileButton
## 초상화·닉네임을 누르면 닉네임을 바꿀 수 있다.
var profile_button: WooMobileButton
var mail_button: WooMobileButton
var bell_button: WooMobileButton
var gear_button: WooMobileButton
var mail_badge: Badge
var bell_badge: Badge
var portrait_id:=""
var built:=false

func setup(game_node: Node) -> void:
	game=game_node
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	build()

func build() -> void:
	if built:refresh();return
	built=true
	panel_bg=Cover.new()
	panel_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(panel_bg)
	portrait=TextureRect.new()
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.material=T.mask_material(0.44,0.48,0.06)
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	ring=TextureRect.new()
	ring.texture=V.TEX_RING_FRAME
	ring.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode=TextureRect.STRETCH_SCALE
	ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	name_label=_label(27,T.IVORY,true)
	title_label=_label(16,Color(0.80,0.84,0.94))
	title_label.clip_text=true
	profile_button=_icon_button("닉네임 바꾸기",func()->void:game.open_nickname_edit())
	move_child(profile_button,0)
	var profile_glyph: Node=profile_button.get_node_or_null("Glyph")
	if profile_glyph!=null:profile_glyph.queue_free()
	coin_pill=_pill("coin")
	gem_pill=_pill("gem")
	coin_plus=_plus_button("코인 획득처",func()->void:game.earn_guide("coin"))
	gem_plus=_plus_button("보석 획득처",func()->void:game.earn_guide("gem"))
	mail_button=_icon_button("우편",func()->void:game.transition("mail"))
	bell_button=_icon_button("알림",func()->void:game.transition("alerts"))
	gear_button=_icon_button("설정",func()->void:game.show_settings())
	(mail_button.get_node("Glyph") as MailGlyph).queue_redraw()
	(bell_button.get_node("Glyph") as BellGlyph).queue_redraw()
	(gear_button.get_node("Glyph") as GearGlyph).queue_redraw()
	mail_badge=Badge.new()
	mail_button.add_child(mail_badge)
	bell_badge=Badge.new()
	bell_button.add_child(bell_badge)
	refresh()

func _label(extent: float,color: Color,brush: bool=false) -> Label:
	var node:=Label.new()
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",T.TITLE_FONT if brush else T.FONT)
	node.add_theme_color_override("font_color",color)
	if brush:
		node.add_theme_constant_override("outline_size",4)
		node.add_theme_color_override("font_outline_color",Color(0.06,0.04,0.02,.85))
	node.set_meta("font_size",extent)
	add_child(node)
	return node

func _pill(kind: String) -> Control:
	var pill:=O.Pill.new()
	pill.kind=kind
	pill.accent=Color("f4d98a") if kind=="coin" else Color("c9a4ff")
	pill.ink=Color("fff2cf") if kind=="coin" else Color("efe2ff")
	pill.font_size=17
	pill.glow=true
	pill.name="HudPill_"+kind
	add_child(pill)
	return pill

func _plus_button(tooltip: String,action: Callable) -> WooMobileButton:
	var node:=PlusButton.new()
	node.tooltip_text=tooltip
	node.name="HudPlus_"+tooltip
	node.custom_minimum_size=Vector2.ZERO
	node.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	node.pressed.connect(func()->void:
		if node.usable():game.sound.play_clip("button");action.call())
	add_child(node)
	# _ready가 공용 최소 크기(112×64)를 걸어 두므로 지운다.
	node.custom_minimum_size=Vector2.ZERO
	return node

func _icon_button(tooltip: String,action: Callable) -> WooMobileButton:
	var node:=WooMobileButton.new()
	node.text=""
	node.tooltip_text=tooltip
	node.custom_minimum_size=Vector2.ZERO
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		node.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
		node.add_theme_color_override(state,Color(0,0,0,0))
	node.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	node.pressed.connect(func()->void:
		if node.usable():game.sound.play_clip("button");action.call())
	var glyph: Control
	match tooltip:
		"우편":glyph=MailGlyph.new()
		"알림":glyph=BellGlyph.new()
		_:glyph=GearGlyph.new()
	glyph.name="Glyph"
	glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_child(glyph)
	add_child(node)
	node.custom_minimum_size=Vector2.ZERO
	return node

# ---------------------------------------------------------------- 값 갱신
## storage.gd가 유일한 진실 원천이다. 이 함수만 다시 불러도 지갑·배지가 실제 값으로 맞춰진다.
func refresh() -> void:
	if not built:return
	var daoist:=String(game.storage.data.daoist)
	var spec:=C.find(daoist)
	if daoist!=portrait_id:
		portrait_id=daoist
		var path:=String(spec.get("portrait",""))
		portrait.texture=load(path) if ResourceLoader.exists(path) else null
	var picked:=String(game.storage.nickname()) if game.storage.has_method("nickname") else ""
	name_label.text=picked if picked!="" else String(spec.get("name","도사"))
	var title_name:=String(Market.title(game.storage.equipped("title")).name)
	title_label.text="칭호 · "+title_name if title_name!="" and title_name!="칭호 없음" else "칭호 없음"
	(coin_pill as O.Pill).text_value=_comma(int(game.storage.data.coins))
	(gem_pill as O.Pill).text_value=_comma(int(game.storage.data.gems))
	coin_pill.queue_redraw()
	gem_pill.queue_redraw()
	var mail_left: int=int(game.unread_mail_count()) if game.has_method("unread_mail_count") else 0
	var alerts_left: int=int(game.unread_alert_count()) if game.has_method("unread_alert_count") else 0
	mail_badge.set_count(mail_left)
	bell_badge.set_count(alerts_left)
	place_hud(origin,art_scale)

func _comma(value: int) -> String:
	var text:=str(absi(value))
	var out:=""
	var count:=0
	for i in range(text.length()-1,-1,-1):
		out=text[i]+out
		count+=1
		if count%3==0 and i>0:out=","+out
	return ("-" if value<0 else "")+out

# ---------------------------------------------------------------- 배치
## 원화 좌표를 화면 좌표로 옮긴다(로비 배경과 같은 origin/scale).
func place_hud(origin_value: Vector2,scale_value: float) -> void:
	origin=origin_value
	art_scale=maxf(0.05,scale_value)
	if not built:return
	position=origin+ART_COVER.position*art_scale
	size=ART_COVER.size*art_scale
	# 덮개 판은 HUD 자신과 같은 크기로 HUD 로컬 (0,0)에 놓는다.
	panel_bg.position=Vector2.ZERO
	panel_bg.size=size
	_place(portrait,PORTRAIT)
	_place(ring,PORTRAIT)
	_place(profile_button,Rect2(1046,4,352,92))
	name_label.clip_text=true
	_place(name_label,NAME_RECT)
	name_label.add_theme_font_size_override("font_size",maxi(10,int(27.0*art_scale)))
	_place(title_label,TITLE_RECT)
	title_label.add_theme_font_size_override("font_size",maxi(9,int(16.0*art_scale)))
	# 오른쪽부터: 설정 · 알림 · 우편 · 보석+ · 보석 · 코인+ · 코인 순으로 오른쪽 정렬.
	_place(gear_button,Rect2(GEAR_X,ICON_Y,ICON_SIZE,ICON_SIZE))
	_place(bell_button,Rect2(BELL_X,ICON_Y,ICON_SIZE,ICON_SIZE))
	_place(mail_button,Rect2(MAIL_X,ICON_Y,ICON_SIZE,ICON_SIZE))
	# 오른쪽 우편 아이콘 왼쪽으로 보석+ · 보석 · 코인+ · 코인을 차례로 붙인다.
	var gem_plus_rect:=Rect2(Vector2(MAIL_X-12.0-PLUS.x,PILL_Y+5.0),PLUS)
	_place(gem_plus,gem_plus_rect)
	var gem_width: float=O.Pill.measure("gem",(gem_pill as O.Pill).text_value,PILL_FONT)*art_scale
	var gem_rect:=Rect2(Vector2(gem_plus_rect.position.x-gem_width-4.0,PILL_Y),Vector2(gem_width,PILL_H))
	_place(gem_pill,gem_rect)
	var coin_plus_rect:=Rect2(Vector2(gem_rect.position.x-14.0-PLUS.x,PILL_Y+5.0),PLUS)
	_place(coin_plus,coin_plus_rect)
	var coin_width: float=O.Pill.measure("coin",(coin_pill as O.Pill).text_value,PILL_FONT)*art_scale
	var coin_rect:=Rect2(Vector2(coin_plus_rect.position.x-coin_width-4.0,PILL_Y),Vector2(coin_width,PILL_H))
	_place(coin_pill,coin_rect)
	for child in mail_button.get_children():
		if child is Badge:(child as Badge).layout(art_scale)
	for child in bell_button.get_children():
		if child is Badge:(child as Badge).layout(art_scale)
	for button in [mail_button,bell_button,gear_button]:
		var glyph: Control=button.get_node_or_null("Glyph")
		if glyph==null:continue
		glyph.position=Vector2(7,7)*art_scale
		glyph.size=Vector2(30,30)*art_scale
		glyph.queue_redraw()

## 원화 좌표 사각형을 HUD 로컬 좌표로 바꿔 놓는다.
func _place(node: Control,rect_in_art: Rect2) -> void:
	if not is_instance_valid(node):return
	var local:=rect_in_art.position-ART_COVER.position
	node.position=local*art_scale
	node.size=rect_in_art.size*art_scale
	node.queue_redraw()

func mail_rect() -> Rect2:return mail_button.get_global_rect()
func bell_rect() -> Rect2:return bell_button.get_global_rect()
func gear_rect() -> Rect2:return gear_button.get_global_rect()

## 덮개 판: 위/오른쪽은 원화 끝에 붙고, 왼쪽 아래만 둥글게 + 금테.
class Cover extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<20.0 or size.y<10.0:return
		var box:=Rect2(Vector2.ZERO,size)
		var radius:=size.y*0.20
		# 위·오른쪽 모서리는 화면 밖으로 밀어 직선이 원화 끝에 붙게 한다.
		var paint:=Rect2(Vector2(0,-radius*1.2),size+Vector2(radius*1.2,radius*1.2))
		# 원화에 박힌 밝은 가짜 숫자·배지가 비쳐 보이지 않을 만큼은 덮어야 한다.
		T.gradient_rounded(self,paint,Color(0.068,0.074,0.155,0.982),Color(0.024,0.030,0.072,0.992),radius)
		T.rounded_outline(self,paint,Color(0.851,0.722,0.471,0.55),radius,1.6)
		# 아래 금빛 실선과 은은한 위쪽 하이라이트.
		draw_line(Vector2(radius,size.y-1.2),Vector2(size.x,size.y-1.2),Color(0.851,0.722,0.471,0.42),1.2,true)
		draw_line(Vector2(radius*.6,1.0),Vector2(size.x,1.0),Color(1.0,0.96,0.86,0.10),1.0,true)

## 작은 금빛 원형 + 버튼.
class PlusButton extends WooMobileButton:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	func _ready() -> void:
		super._ready()
		text=""
		tooltip_text="획득처 보기"
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5
		draw_circle(c,r,Color(0.10,0.09,0.17,0.95))
		draw_arc(c,r-1.4,0,TAU,24,Color(0.851,0.722,0.471,0.85),1.4,true)
		var arm:=r*.48
		draw_line(c+Vector2(-arm,0),c+Vector2(arm,0),Color("f4dfae"),2.0,true)
		draw_line(c+Vector2(0,-arm),c+Vector2(0,arm),Color("f4dfae"),2.0,true)

class MailGlyph extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		Glyphs.draw_glyph(self,"mail",Rect2(Vector2.ZERO,size),Color("dfe6f6"),1.6,0.0)

class BellGlyph extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var u:=minf(size.x,size.y)*.5
		var color:=Color("dfe6f6")
		draw_line(c+Vector2(0,-u*.95),c+Vector2(0,-.80*u),color,1.6,true)
		draw_arc(c+Vector2(0,-.72*u),.14*u,PI,TAU,12,color,1.6,true)
		var body:=PackedVector2Array([c+Vector2(-.42,-.62)*u,c+Vector2(.42,-.62)*u,c+Vector2(.52,.22)*u,c+Vector2(-.52,.22)*u,c+Vector2(-.42,-.62)*u])
		draw_colored_polygon(body,Color(color.r,color.g,color.b,.22))
		draw_polyline(body,color,1.6,true)
		draw_line(c+Vector2(-.62,.34)*u,c+Vector2(.62,.34)*u,color,1.8,true)
		draw_circle(c+Vector2(0,.56)*u,.12*u,color)

class GearGlyph extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var u:=minf(size.x,size.y)*.5
		var color:=Color("dfe6f6")
		for i in range(8):
			var a:=TAU*float(i)/8.0
			draw_line(c+Vector2(cos(a),sin(a))*.52*u,c+Vector2(cos(a),sin(a))*.86*u,color,2.6,true)
		draw_arc(c,.52*u,0,TAU,26,color,2.0,true)
		draw_arc(c,.26*u,0,TAU,22,color,1.8,true)

## 실제 배지 숫자: 읽지 않음 + 받지 않음이 0이면 사라진다.
class Badge extends Label:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var count:=0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		add_theme_font_override("font",T.FONT)
		visible=false
	func set_count(value: int) -> void:
		count=maxi(0,value)
		visible=count>0
		text=str(mini(count,99))
		var box:=T.panel_box(Color(0.72,0.16,0.20,0.97),11,Color(1,0.86,0.72,0.9),1)
		add_theme_stylebox_override("normal",box)
		add_theme_color_override("font_color",Color("fff4e6"))
	func layout(scale_value: float) -> void:
		var extent:=18.0*scale_value
		if count>9:extent=22.0*scale_value
		size=Vector2(extent,extent)
		position=Vector2(26,2)*scale_value
		add_theme_font_size_override("font_size",maxi(8,int(11.0*scale_value)))
