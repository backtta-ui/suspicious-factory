class_name WooLobbyScreen
extends Control
## 로비 하위 화면(상점·빠른 매치·업적·우편·친구)의 공통 뼈대 — 2.0.25 시안 복제.
## 1280×720 디자인 좌표를 화면 높이에 맞춰 확대하고, 가로가 넓으면(20:9) 가운데를 넓혀
## 좌우 가장자리 요소(뒤로·지갑·좌측 레일·우측 판)를 화면 끝에 붙인다.
## 상단: 뒤로 판 · 금테 메달 · 세리프 대제목 · 설명 / 오른쪽: 칭호·보석·코인 알약.
const T=preload("res://scripts/ui/lobby_theme.gd")
const V=preload("res://scripts/ui/ui_v25.gd")
const Art=preload("res://scripts/ui/lobby_art.gd")
const C=preload("res://scripts/survival/characters.gd")
const Market=preload("res://scripts/survival/market.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const DESIGN_WIDTH=1280.0
const MAX_WIDTH=1600.0
var game: Node
var design: Array=[]
var s:=1.0
var origin:=Vector2.ZERO
var view:=Vector2(DESIGN_WIDTH,T.DESIGN_HEIGHT)
var dw:=DESIGN_WIDTH
var backdrop: Control
var title_label: Label
var subtitle_label: Label
var header_rule: Control
var header_medallion: Control
var back_button: WooMobileButton
var wallet_row: Control
var wallet_pills: Array=[]
var note_label: Label
var built:=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop=Art.Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.set("mood",1.28)
	backdrop.set("shade_strength",0.06)
	backdrop.set("lattice_on",false)
	backdrop.set("warm_strength",0.08)
	backdrop.set("vignette_strength",0.30)
	backdrop.set("dim_strength",0.05)
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

func right_edge() -> float:
	return dw-16.0

# ---------------------------------------------------------------- 기본 틀
func header(title: String,subtitle: String,glyph: String="scroll",on_back: Callable=Callable()) -> void:
	back_button=V.PlateButton.new()
	back_button.kind="dark"
	back_button.text="뒤로"
	back_button.glyph="back"
	back_button.font_size=17
	back_button.name="LobbyBack"
	back_button.custom_minimum_size=Vector2.ZERO
	back_button.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	back_button.pressed.connect(func()->void:
		if back_button.usable():game.sound.play_clip("button");(on_back if on_back.is_valid() else func()->void:game.transition("lobby")).call())
	add_child(back_button)
	game.button_feel(back_button)
	back_button.set_meta("base_font",17)
	header_medallion=V.medallion(self,Rect2(154,8,46,46),glyph)
	header_medallion.name="HeaderMedallion"
	title_label=V.title_label(self,title,33,V.GOLD_BRIGHT)
	subtitle_label=label(self,subtitle,14,V.MUTED)
	subtitle_label.clip_text=true
	wallet_row=wallet(self)

## 상단 오른쪽 보유 재화: 시안과 같은 어두운 캡슐 + 아이콘 + 금빛 숫자.
func wallet(parent: Node) -> Control:
	var row:=Control.new()
	row.name="WalletRow"
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	var owned_titles:=0
	for item in (game.storage.data.market.owned as Array):
		if String(item).begins_with("title:"):owned_titles+=1
	var specs: Array=[[V.TEX_ICON_LOTUS,"칭호 ",str(owned_titles),Color("9fe8ff")],
		[V.TEX_ICON_GEM,"보석 ",number(int(game.storage.data.gems)),Color("c9a6ff")],
		[V.TEX_ICON_COIN,"코인 ",number(int(game.storage.data.coins)),Color("f6d896")]]
	for spec in specs:
		var pill:=WalletPill.new()
		pill.name="Wallet_"+String(spec[1]).strip_edges()
		pill.setup(String(spec[1]),String(spec[2]),spec[0],spec[3])
		row.add_child(pill)
		wallet_pills.append(pill)
	return row

func glyph_of(_key: String) -> String:
	return "lotus"

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
	note_label=label(self,text_value,13,Color(0.72,0.70,0.86,0.85))
	note_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

# ---------------------------------------------------------------- 구성 요소
func place(node: Control,rect: Rect2) -> void:
	node.set_meta("design",rect)
	node.set_meta("design_base",_base_of(node))
	if not design.has(node):design.append(node)
	reshape(node,rect)

## 이미 놓인 요소의 디자인 사각형만 바꾼다(가로 확장 대응).
func reshape(node: Control,rect: Rect2) -> void:
	if not is_instance_valid(node):return
	node.set_meta("design",rect)
	node.set_meta("design_base",_base_of(node))
	var local: Vector2=(rect.position-_base_of(node))*s
	node.position=(origin+local) if node.get_parent()==self else local
	node.size=rect.size*s
	if node is Label and node.has_meta("base_font"):
		node.add_theme_font_size_override("font_size",maxi(9,int(float(node.get_meta("base_font"))*s)))
	if node.has_meta("base_font") and node.get("font_size")!=null:
		node.set("font_size",maxi(10,int(float(node.get_meta("base_font"))*s)))
		node.queue_redraw()

func _base_of(node: Node) -> Vector2:
	var parent:=node.get_parent()
	if parent!=null and parent!=self and parent.has_meta("design"):
		return (parent.get_meta("design") as Rect2).position
	return Vector2.ZERO

func label(parent: Node,text_value: String,extent: float,color: Color,brush: bool=false) -> Label:
	var node:=Label.new()
	node.text=text_value
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",V.TITLE_FONT if brush else T.FONT)
	node.add_theme_font_size_override("font_size",int(extent))
	node.add_theme_color_override("font_color",color)
	node.set_meta("base_font",extent)
	if brush:
		V.outline(node,maxi(3,int(extent*.14)),Color(0.10,0.05,0.02,.9))
		node.add_theme_color_override("font_shadow_color",Color(0,0,0,.55))
		node.add_theme_constant_override("shadow_offset_x",0)
		node.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(node)
	return node

## 시안의 금빛 촉 버튼 / 어두운 판 버튼.
func button(caption: String,callback: Callable,parent: Node,primary: bool=false,font_size: int=17) -> WooMobileButton:
	var node:=V.PlateButton.new()
	node.kind="gold" if primary else "dark"
	node.text=caption
	node.font_size=font_size
	node.name="LobbyButton"
	node.custom_minimum_size=Vector2.ZERO
	if parent==null:parent=self
	var ticket: int=int(game.generation)
	node.allowed=func()->bool:return ticket==game.generation and game!=null and not game.changing and game.modal==null
	node.pressed.connect(func()->void:
		if node.usable():game.sound.play_clip("button");callback.call())
	parent.add_child(node)
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

## 큰 보랏빛 판(9-slice 텍스처).
func frame(parent: Node,rect: Rect2) -> NinePatchRect:
	var node:=V.frame(parent,rect)
	if parent!=self and parent.has_meta("design"):
		node.position=Vector2.ZERO
	return node

func figure(parent: Node,id: String,extent: Vector2,tint: Color=Color.WHITE,skin: String="") -> Control:
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
	# 2.0.36: 전용 스킨을 입은 모습은 스킨 8방향 시트로 보여 준다(도포 색 틴트 없음).
	var skin_key:=preload("res://scripts/survival/skill_fx.gd").sheet_key(id,skin)
	actor.art_id=skin_key if skin_key!="" else C.fallback_art(id.trim_prefix("yokai:").trim_prefix("daoist:"))
	actor.skin_tint=tint
	actor.scale=Vector2.ONE*minf(4.6,maxf(.6,extent.y/74.0))
	holder.add_child(actor)
	holder.resized.connect(func()->void:actor.position=Vector2(holder.size.x*.5,holder.size.y*.97))
	actor.position=Vector2(extent.x*.5,extent.y*.97)
	return holder

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

func divider(parent: Node,color: Color=Color(0.85,0.72,0.47,0.22)) -> ColorRect:
	var node:=ColorRect.new()
	node.color=color
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

## 금빛 장식 구분선(가운데 다이아).
func gold_divider(parent: Node,rect: Rect2) -> Control:
	var node:=V.Divider.new()
	parent.add_child(node)
	place(node,rect)
	return node

## 금테 원형 초상(도감 카드·친구 초대).
func circle_portrait(parent: Node,path: String,rect: Rect2,lit: bool=false) -> Control:
	var holder:=Control.new()
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	place(holder,rect)
	var art:=TextureRect.new()
	if ResourceLoader.exists(path):art.texture=load(path)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.material=T.mask_material(0.42,0.46,0.06)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)
	art.position=Vector2(rect.size.x*0.10,rect.size.y*0.10)*s
	art.size=rect.size*s*0.80
	var ring:=TextureRect.new()
	ring.texture=V.TEX_RING_FRAME
	ring.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode=TextureRect.STRETCH_SCALE
	ring.modulate=Color(1,1,1) if lit else Color(.78,.74,.9,.92)
	ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(ring)
	ring.position=Vector2.ZERO
	ring.size=rect.size*s
	return holder

## 실제 스크롤되는 목록 영역(휠·스크롤바 드래그로 움직인다).
func scroll_area(rect: Rect2,content_height: float) -> Dictionary:
	var holder:=Control.new()
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	place(holder,rect)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter=Control.MOUSE_FILTER_PASS
	holder.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bar: VScrollBar=scroll.get_v_scroll_bar()
	var grabber:=StyleBoxFlat.new()
	grabber.bg_color=Color(.90,.76,.48,.85)
	grabber.set_corner_radius_all(3)
	var scroll_bg:=StyleBoxFlat.new()
	scroll_bg.bg_color=Color(.06,.05,.10,.55)
	scroll_bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("grabber",grabber)
	bar.add_theme_stylebox_override("grabber_highlight",grabber)
	bar.add_theme_stylebox_override("grabber_pressed",grabber)
	bar.add_theme_stylebox_override("scroll",scroll_bg)
	bar.add_theme_stylebox_override("scroll_focus",scroll_bg)
	var content:=Control.new()
	content.mouse_filter=Control.MOUSE_FILTER_PASS
	content.custom_minimum_size=Vector2(rect.size.x,content_height)
	content.set_meta("design",rect)
	scroll.add_child(content)
	return {"holder":holder,"scroll":scroll,"content":content}

# ---------------------------------------------------------------- 배치
func layout() -> void:
	if not built:return
	view=get_viewport().get_visible_rect().size
	if view.y<=1.0:return
	s=clampf(view.y/T.DESIGN_HEIGHT,.45,3.4)
	dw=clampf(view.x/s,DESIGN_WIDTH,MAX_WIDTH)
	origin=Vector2((view.x-dw*s)*.5,0)
	var alive: Array=[]
	for node in design:
		if not is_instance_valid(node):continue
		alive.append(node)
		var rect: Rect2=node.get_meta("design")
		var base: Vector2=node.get_meta("design_base",Vector2.ZERO)
		var local: Vector2=(rect.position-base)*s
		node.position=(origin+local) if node.get_parent()==self else local
		node.size=rect.size*s
		if node is Label and node.has_meta("base_font"):
			node.add_theme_font_size_override("font_size",maxi(9,int(float(node.get_meta("base_font"))*s)))
	design=alive
	if is_instance_valid(back_button):reshape(back_button,Rect2(16,10,116,42))
	if is_instance_valid(header_medallion):reshape(header_medallion,Rect2(154,4,48,48))
	if is_instance_valid(title_label):
		reshape(title_label,Rect2(218,0,560,46))
		title_label.add_theme_font_size_override("font_size",maxi(16,int(38.0*s)))
	if is_instance_valid(subtitle_label):
		reshape(subtitle_label,Rect2(220,46,700,22))
		subtitle_label.add_theme_font_size_override("font_size",maxi(10,int(14.5*s)))
	if is_instance_valid(wallet_row):
		var total:=0.0
		for pill in wallet_pills:
			if is_instance_valid(pill):total+=pill.wanted_width()
		wallet_row.position=origin+Vector2(dw-16.0-total,14)*s
		wallet_row.size=Vector2(total,36)*s
		var x:=0.0
		for pill in wallet_pills:
			if not is_instance_valid(pill):continue
			var width: float=float(pill.wanted_width())
			pill.position=Vector2(x,0)*s
			pill.size=Vector2(width,36)*s
			pill.reflow(s)
			x+=width+8.0
	if is_instance_valid(header_rule):
		header_rule.visible=false
	if is_instance_valid(note_label):
		note_label.position=origin+Vector2(26,T.DESIGN_HEIGHT-30)*s
		note_label.size=Vector2(dw-52,22)*s
		note_label.add_theme_font_size_override("font_size",maxi(10,int(13.0*s)))
	if is_instance_valid(backdrop) and backdrop.has_method("set"):
		pass
	arrange()

## 상단 제목 아래 가로 장식.
class Rule extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var y:=size.y*.5
		var color:=Color(0.85,0.72,0.47,.26)
		draw_line(Vector2(0,y),Vector2(size.x,y),color,1.0)
		T.diamond(self,Vector2(size.x*.5,y),3.0,Color(0.85,0.72,0.47,.5))

## 지갑 알약(칭호·보석·코인): 어두운 캡슐 + 아이콘 + 숫자.
class WalletPill extends Control:
	var caption:=""
	var value:=""
	var glyph: Texture2D=null
	var tint:=Color("f6d896")
	var fill: Control
	var icon: Control
	var text: Label
	var extent:=14.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func setup(label_text: String,amount: String,glyph_texture: Texture2D,color: Color) -> void:
		caption=label_text
		value=amount
		glyph=glyph_texture
		tint=color
		if fill==null:
			fill=PillBG.new()
			fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
			add_child(fill)
		if icon==null:
			var art:=TextureRect.new()
			art.texture=glyph
			art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter=Control.MOUSE_FILTER_IGNORE
			add_child(art)
			icon=art
		if text==null:
			text=Label.new()
			text.mouse_filter=Control.MOUSE_FILTER_IGNORE
			text.add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJK-Regular.ttc"))
			add_child(text)
		text.text=caption+value
		text.add_theme_color_override("font_color",tint)
	func wanted_width() -> float:
		var font: Font=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
		return font.get_string_size(caption+value,HORIZONTAL_ALIGNMENT_LEFT,-1,int(16)).x+52.0
	func reflow(scale_value: float) -> void:
		if fill==null:return
		fill.position=Vector2.ZERO
		fill.size=size
		var extent_px:=maxi(9,int(16.0*scale_value))
		text.add_theme_font_size_override("font_size",extent_px)
		icon.position=Vector2(12,size.y*.5-10*scale_value)
		icon.size=Vector2(20,20)*scale_value
		text.position=Vector2(38,0)*scale_value
		text.size=Vector2(size.x-maxf(36.0*scale_value,1.0),size.y)
		text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		if icon.has_method("queue_redraw"):icon.queue_redraw()

## 지갑 알약 배경(비율 유지 9분할).
class PillBG extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		WooV25.draw_nine(self,WooV25.TEX_PILL,Rect2(Vector2.ZERO,size),0.46,0.46,Color.WHITE)

## 지갑 아이콘(연꽃·보석·동전).
class WalletIcon extends Control:
	var kind:="coin"
	var tint:=Color("f6d896")
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5
		match kind:
			"gem":
				draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.8,-r*.2),c+Vector2(-r*.35,-r*.72),c+Vector2(r*.35,-r*.72),c+Vector2(r*.8,-r*.2),c+Vector2(0,r*.78)]),tint)
				draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.8,-r*.2),c+Vector2(0,r*.78),c+Vector2(0,-r*.72)]),Color(tint.r*.7,tint.g*.6,tint.b,1))
				draw_polyline(PackedVector2Array([c+Vector2(-r*.8,-r*.2),c+Vector2(-r*.35,-r*.72),c+Vector2(r*.35,-r*.72),c+Vector2(r*.8,-r*.2),c+Vector2(0,r*.78),c+Vector2(-r*.8,-r*.2)]),Color(1,1,1,.55),1.2)
			"coin":
				draw_circle(c,r*.92,Color(tint.r*.6,tint.g*.42,tint.b*.2,1))
				draw_circle(c,r*.78,tint)
				draw_arc(c,r*.78,0,TAU,24,Color(1,.95,.8,.85),1.2,true)
				draw_arc(c,r*.48,0,TAU,20,Color(tint.r*.55,tint.g*.4,tint.b*.22,.9),1.4,true)
			_:
				# 연꽃(칭호)
				for i in range(5):
					var a:=-PI*.5+(float(i)-2.0)*.52
					draw_colored_polygon(PackedVector2Array([c,c+Vector2(cos(a-.30),sin(a-.30))*r, c+Vector2(cos(a),sin(a))*r*1.28, c+Vector2(cos(a+.30),sin(a+.30))*r]),Color(tint.r,tint.g,tint.b,.95))
				draw_circle(c,r*.30,Color(1,1,1,.55))
