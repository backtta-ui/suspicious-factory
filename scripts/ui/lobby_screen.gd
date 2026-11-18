class_name WooLobbyScreen
extends Control
## 로비 하위 화면(상점·빠른 매치·업적·우편·친구)의 공통 뼈대.
## 1280×720 디자인 좌표를 화면 높이에 맞춰 확대하고, 가로가 넓으면 가운데에 둔다.
## 상단: 뒤로가기 · 붓글씨 대제목 · 설명 · 보유 재화 / 하단: 안내 문구.
const T=preload("res://scripts/ui/lobby_theme.gd")
const Art=preload("res://scripts/ui/lobby_art.gd")
const C=preload("res://scripts/survival/characters.gd")
const Market=preload("res://scripts/survival/market.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const DESIGN_WIDTH=1280.0
var game: Node
var design: Array=[]
var s:=1.0
var origin:=Vector2.ZERO
var view:=Vector2(DESIGN_WIDTH,T.DESIGN_HEIGHT)
var backdrop: Control
var title_label: Label
var subtitle_label: Label
var header_rule: Control
var back_button: WooMobileButton
var wallet_row: HBoxContainer
var note_label: Label
var built:=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop=Art.Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	build()
	built=true
	resized.connect(layout)
	layout()

## 하위 화면이 채운다.
func build() -> void:
	pass

## 하위 화면이 채운다(내용 배치).
func arrange() -> void:
	pass

# ---------------------------------------------------------------- 기본 틀
func header(title: String,subtitle: String,on_back: Callable=Callable()) -> void:
	back_button=button("← 뒤로",on_back if on_back.is_valid() else func()->void:game.transition("lobby"),self,false,18)
	back_button.name="LobbyBack"
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var box:=T.button_box(state,false)
		box.set_border_width_all(2)
		box.border_color=Color(0.92,0.79,0.52,0.9)
		back_button.add_theme_stylebox_override(state,box)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color"]:
		back_button.add_theme_color_override(state,T.IVORY)
	back_button.set_meta("base_font",18)
	title_label=label(self,title,34,T.GOLD_SOFT,true)
	subtitle_label=label(self,subtitle,15,T.MUTED)
	subtitle_label.clip_text=true
	header_rule=Rule.new()
	add_child(header_rule)
	wallet_row=wallet(self)

## 상단 오른쪽 보유 재화. 화면마다 같은 자리·같은 모양으로 둔다.
func wallet(parent: Node) -> HBoxContainer:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.alignment=BoxContainer.ALIGNMENT_END
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	for spec in [["칭호 · "+Market.title(game.storage.equipped("title")).name,T.IVORY],["보석 "+number(int(game.storage.data.gems)),Color("9fe8ff")],["코인 "+number(int(game.storage.data.coins)),Color("f4d98a")]]:
		var pill:=label(row,String(spec[0]),15,spec[1])
		pill.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		pill.add_theme_stylebox_override("normal",T.pill_box())
		pill.custom_minimum_size=Vector2(T.FONT.get_string_size(String(spec[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+26,30)
	return row

func number(value: int) -> String:
	var text:=str(absi(value))
	var out:=""
	var count:=0
	for i in range(text.length()-1,-1,-1):
		out=text[i]+out
		count+=1
		if count%3==0 and i>0:out=","+out
	return ("-" if value<0 else "")+out

func note(text_value: String) -> void:
	note_label=label(self,text_value,14,Color(0.76,0.80,0.90,0.92))
	note_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

# ---------------------------------------------------------------- 구성 요소
func place(node: Control,rect: Rect2) -> void:
	node.set_meta("design",rect)
	node.set_meta("design_base",_base_of(node))
	if not design.has(node):design.append(node)
	# origin은 화면(self)에 직접 놓인 노드에만 더한다. 카드·판 안의 자식은
	# 부모가 이미 origin만큼 이동했으므로 로컬 좌표만 적용해야 겹치거나 밀리지 않는다.
	var local: Vector2=(rect.position-_base_of(node))*s
	node.position=(origin+local) if node.get_parent()==self else local
	node.size=rect.size*s
	if node is Label and node.has_meta("base_font"):
		node.add_theme_font_size_override("font_size",maxi(9,int(float(node.get_meta("base_font"))*s)))

## 부모가 이미 디자인 좌표를 가진 컨트롤이면 그 위치를 빼고 배치한다.
func _base_of(node: Node) -> Vector2:
	var parent:=node.get_parent()
	if parent!=null and parent!=self and parent.has_meta("design"):
		return (parent.get_meta("design") as Rect2).position
	return Vector2.ZERO

func label(parent: Node,text_value: String,extent: float,color: Color,brush: bool=false) -> Label:
	var node:=Label.new()
	node.text=text_value
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",T.TITLE_FONT if brush else T.FONT)
	node.add_theme_font_size_override("font_size",int(extent))
	node.add_theme_color_override("font_color",color)
	node.set_meta("base_font",extent)
	if brush:
		node.add_theme_color_override("font_shadow_color",Color(0,0,0,.55))
		node.add_theme_constant_override("shadow_offset_x",0)
		node.add_theme_constant_override("shadow_offset_y",2)
		node.add_theme_color_override("font_outline_color",Color(0.04,0.03,0.06,.55))
		node.add_theme_constant_override("outline_size",3)
	parent.add_child(node)
	return node

func button(caption: String,callback: Callable,parent: Node,primary: bool=false,font_size: int=17) -> WooMobileButton:
	var node: WooMobileButton=game.button(caption,callback,primary,parent)
	node.custom_minimum_size=Vector2.ZERO
	node.add_theme_font_size_override("font_size",font_size)
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		node.add_theme_stylebox_override(state,T.button_box(state,primary))
	var ink:=Color("2a1e0c") if primary else T.IVORY
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color"]:
		node.add_theme_color_override(state,ink)
	node.add_theme_color_override("font_disabled_color",Color(0.90,0.84,0.68,0.95) if primary else Color(0.62,0.64,0.72,0.9))
	node.set_meta("base_font",font_size)
	return node

func panel(parent: Node,fill: Color=T.PANEL,radius: int=14,glow: Color=Color(0,0,0,0),filigree: bool=true) -> Panel:
	var node:=Panel.new()
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel",T.panel_box(fill,radius,Color(0.85,0.72,0.47,0.45),1,glow,16 if glow.a>0.0 else 0))
	parent.add_child(node)
	if filigree:
		var trim:=Art.Filigree.new()
		trim.color=Color(0.85,0.72,0.47,0.5)
		trim.arm=20.0
		node.add_child(trim)
	return node

## 실제 인게임 아트로 서 있는 캐릭터(실시간 미리보기).
func figure(parent: Node,id: String,extent: Vector2,tint: Color=Color.WHITE) -> Control:
	var holder:=Control.new()
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size=extent
	parent.add_child(holder)
	var actor:=Actor.new()
	actor.network_remote=true
	actor.cosmetic=C.look(id)
	actor.collision_layer=0
	actor.collision_mask=0
	actor.ingame_art=true
	actor.art_id=id.trim_prefix("yokai:").trim_prefix("daoist:")
	actor.skin_tint=tint
	actor.scale=Vector2.ONE*minf(4.6,maxf(.6,extent.y/74.0))
	holder.add_child(actor)
	holder.resized.connect(func()->void:actor.position=Vector2(holder.size.x*.5,holder.size.y*.97))
	actor.position=Vector2(extent.x*.5,extent.y*.97)
	return holder

## 영역을 꽉 채우되 얼굴 쪽으로 초점을 두고 잘라 넣는다(카드 원화용).
func cover_art(parent: Node,path: String,region: Rect2,focus: float=0.2,tint: Color=Color.WHITE) -> TextureRect:
	var node:=TextureRect.new()
	if ResourceLoader.exists(path):node.texture=load(path)
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_SCALE
	node.modulate=tint
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	if node.texture==null or region.size.y<=0.0:
		place(node,region)
		return node
	var aspect:=float(node.texture.get_width())/maxf(1.0,float(node.texture.get_height()))
	var width:=region.size.x
	var height:=width/aspect
	if height<region.size.y:
		height=region.size.y
		width=height*aspect
	var offset:=Vector2((width-region.size.x)*.5,(height-region.size.y)*focus)
	place(node,Rect2(region.position-offset,Vector2(width,height)))
	return node

## 검은 배경 원화를 원형으로 부드럽게 잘라 얹는다.
func portrait_circle(parent: Node,path: String,extent: Vector2,focus: float=0.44) -> TextureRect:
	var node:=TextureRect.new()
	if ResourceLoader.exists(path):node.texture=load(path)
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.material=T.mask_material(focus,.46,.08)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.custom_minimum_size=extent
	return node

func chip(parent: Node,text_value: String,accent: Color,font_size: int=15,ink: Color=Color(0.05,0.04,0.02,1.0)) -> Label:
	var node:=label(parent,text_value,font_size,ink)
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	node.add_theme_stylebox_override("normal",T.panel_box(Color(accent.r,accent.g,accent.b,0.92),11,Color(0,0,0,0),0))
	return node

## 업적·우편 카드 등에 쓰는 가는 구분선.
func divider(parent: Node,color: Color=Color(0.85,0.72,0.47,0.22)) -> ColorRect:
	var node:=ColorRect.new()
	node.color=color
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

# ---------------------------------------------------------------- 배치
func layout() -> void:
	if not built:return
	view=get_viewport().get_visible_rect().size
	if view.y<=1.0:return
	s=clampf(view.y/T.DESIGN_HEIGHT,.45,3.4)
	origin=Vector2((view.x-DESIGN_WIDTH*s)*.5,0)
	var alive: Array=[]
	for node in design:
		if not is_instance_valid(node):continue
		alive.append(node)
		var rect: Rect2=node.get_meta("design")
		var base: Vector2=node.get_meta("design_base",Vector2.ZERO)
		var local: Vector2=(rect.position-base)*s
		# 자식 컨트롤은 부모 기준 로컬 좌표만 쓴다(origin 중복 금지).
		node.position=(origin+local) if node.get_parent()==self else local
		node.size=rect.size*s
		if node is Label and node.has_meta("base_font"):
			node.add_theme_font_size_override("font_size",maxi(9,int(float(node.get_meta("base_font"))*s)))
	design=alive
	if is_instance_valid(back_button):place(back_button,Rect2(20,10,118,52))
	if is_instance_valid(title_label):
		title_label.position=origin+Vector2(152,4)*s
		title_label.size=Vector2(560,48)*s
		title_label.add_theme_font_size_override("font_size",maxi(14,int(34.0*s)))
	if is_instance_valid(subtitle_label):
		subtitle_label.position=origin+Vector2(154,50)*s
		subtitle_label.size=Vector2(600,24)*s
		subtitle_label.add_theme_font_size_override("font_size",maxi(11,int(15.0*s)))
	if is_instance_valid(wallet_row):
		wallet_row.position=origin+Vector2(DESIGN_WIDTH-26-430,14)*s
		wallet_row.size=Vector2(430,34)*s
		for child in wallet_row.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size",maxi(11,int(15.0*s)))
				child.custom_minimum_size=Vector2(0,30*s)
	if is_instance_valid(header_rule):
		header_rule.position=origin+Vector2(26,84)*s
		header_rule.size=Vector2(DESIGN_WIDTH-52,8)*s
		header_rule.queue_redraw()
	if is_instance_valid(note_label):
		note_label.position=origin+Vector2(26,T.DESIGN_HEIGHT-34)*s
		note_label.size=Vector2(DESIGN_WIDTH-52,24)*s
		note_label.add_theme_font_size_override("font_size",maxi(11,int(14.0*s)))
	arrange()

## 상단 제목 아래 가로 장식.
class Rule extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var y:=size.y*.5
		var color:=Color(0.85,0.72,0.47,.26)
		draw_line(Vector2(0,y),Vector2(size.x,y),color,1.0)
		draw_line(Vector2(90,y),Vector2(size.x-90,y),Color(0.85,0.72,0.47,.14),1.0)
		T.diamond(self,Vector2(size.x*.5,y),3.0,Color(0.85,0.72,0.47,.5))
