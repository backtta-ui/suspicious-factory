extends Control
## 2.0.23 캐릭터 선택 — 시안(browser/gpt_char_select_clean-2026-11-19-042612.png) 복제 수준.
## 상단: 철제 뒤로 · 연꽃 문장 · 붓글씨 제목 · 황동 `도사 6 : 요괴 2` 명패 · 모래시계 시간 명패.
## 좌측: 도사/요괴/전체 세로 탭(금테 탭 텍스처) + 2×2 금테 초상 카드(선택 시 금빛 광 + 금색 확인 인장).
## 중앙: 보름달·벚꽃 배경 앞에 전신 원화를 크게 세우고, 발밑 달빛 마법진 단상 위에 인게임 소형 캐릭터.
## 우측: 이름 · 진영/역할 · 소개 · 주요 능력 3개(금테 원형) · 대표 능력 게이지.
## 하단: 선택 현황 8칸 초상 슬롯 + 입체 황동 `✓ 선택 확정` CTA.
## 1280×720 기준 좌표를 화면 높이에 맞춰 확대하고, 가로가 넓으면 중앙 열이 넓어진다.
const LC=preload("res://scripts/ui/lobby_theme.gd")
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LArt=preload("res://scripts/ui/lobby_art.gd")
const C=preload("res://scripts/survival/characters.gd")
const BG=preload("res://assets/woo/codex/codex_bg.jpg")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const DESIGN_HEIGHT=720.0
const MARGIN=14.0

var game: Node
var selection_id:=""
var locked:=false
## 2.0.27 빠른 매치: 배정된 진영만 고를 수 있게 잠근다.
var role_locked:=false
var locked_team:=""
var ready_label: Label
var ready_left:=0.0
var ready_active:=false
var tab:="daoist"
var page:=0
var built:=false
var view:=Vector2.ZERO
var s:=1.0
var width:=1280.0
var timer_label: Label
var team_label: Label
var confirm_button: WooMobileButton
var card_buttons: Array=[]
var tab_buttons: Dictionary={}
var pager: Dictionary={}
var hero_layer: Control
var detail_layer: Control
var cards_layer: Control
var footer_layer: Control
var strip: Control

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resized)
	build()
	built=true

func setup(game_node: Node,selected: String,confirmed: bool) -> void:
	game=game_node
	selection_id=selected
	locked=confirmed
	build()

func _on_resized() -> void:
	if not built:return
	var now:=get_viewport().get_visible_rect().size
	if absf(now.x-view.x)<1.0 and absf(now.y-view.y)<1.0:return
	build()

# ------------------------------------------------------------------ 기본 도구
func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	card_buttons.clear()
	tab_buttons.clear()
	pager.clear()
	hero_layer=null
	detail_layer=null
	cards_layer=null
	footer_layer=null
	strip=null
	timer_label=null
	team_label=null
	confirm_button=null

func _reset_layer(which: String) -> Control:
	var old: Control=null
	match which:
		"cards":old=cards_layer
		"hero":old=hero_layer
		"detail":old=detail_layer
		"footer":old=footer_layer
	if is_instance_valid(old):
		if old.get_parent()!=null:old.get_parent().remove_child(old)
		old.queue_free()
	var made:=Control.new()
	made.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(self,made,Rect2(0,0,width,DESIGN_HEIGHT))
	match which:
		"cards":cards_layer=made
		"hero":hero_layer=made
		"detail":detail_layer=made
		"footer":footer_layer=made
	return made

func _add(parent: Node,node: Control,r: Rect2) -> Control:
	parent.add_child(node)
	node.position=r.position*s
	node.size=r.size*s
	return node

func _place(node: Control,r: Rect2) -> void:
	node.position=r.position*s
	node.size=r.size*s

func _label(parent: Node,text_value: String,extent: float,color: Color,brush: bool=false) -> Label:
	var node:=Label.new()
	node.text=text_value
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",TITLE_FONT if brush else FONT)
	node.add_theme_font_size_override("font_size",maxi(9,int(extent*s)))
	node.add_theme_color_override("font_color",color)
	if brush:
		node.add_theme_color_override("font_shadow_color",Color(0,0,0,.55))
		node.add_theme_constant_override("shadow_offset_x",0)
		node.add_theme_constant_override("shadow_offset_y",2)
	node.add_theme_color_override("font_outline_color",Color(.02,.018,.04,.82))
	node.add_theme_constant_override("outline_size",maxi(2,int(2.6*s)))
	return node

## 9-slice 텍스처 판. glow>0이면 뒤에 금빛 광을 깐다.
func _plate(parent: Node,r: Rect2,texture: Texture2D,margin: int,glow: float=0.0,glow_color: Color=Color(1,.82,.42)) -> NinePatchRect:
	if glow>0.0:
		var halo:=UIK.Glow.new()
		halo.color=glow_color
		halo.radius=minf(16.0,minf(r.size.x,r.size.y)*.12)*s
		halo.strength=glow
		_add(parent,halo,r)
	var node:=NinePatchRect.new()
	node.texture=texture
	node.set_patch_margin(SIDE_LEFT,margin)
	node.set_patch_margin(SIDE_RIGHT,margin)
	node.set_patch_margin(SIDE_TOP,margin)
	node.set_patch_margin(SIDE_BOTTOM,margin)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(parent,node,r)
	return node

func _button(caption: String,callback: Callable,kind: String,glyph_name: String,r: Rect2,font_size: float=19.0,parent: Node=null) -> WooMobileButton:
	var node: WooMobileButton=UIK.MetalButton.new()
	node.kind=kind
	node.text=caption
	node.glyph=glyph_name
	node.font_size=int(font_size)
	node.use_title_font=kind=="gold"
	node.set_meta("base_font",font_size)
	node.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	node.pressed.connect(func()->void:
		if not node.usable():return
		if game.sound!=null:game.sound.play_clip("button")
		game.if_vibrate()
		callback.call())
	node.custom_minimum_size=Vector2.ZERO
	_add(parent if parent!=null else self,node,r)
	node.pivot_offset=node.size*.5
	game.button_feel(node)
	return node

func me() -> Dictionary:
	return game.rules.players.human

func side() -> String:
	return String(me().get("role","daoist"))

func owned(id: String) -> bool:
	return game.storage.owns_character(id)

func money(value: int) -> String:
	return game.number(value)

func catalog(which: String) -> Array:
	if which=="all":
		var out: Array=[]
		out.append_array(C.catalog("daoist"))
		out.append_array(C.catalog("yokai"))
		return out
	return C.catalog(which)

func page_items() -> Array:
	var items:=catalog(tab)
	var start:=page*4
	var out: Array=[]
	for i in range(4):
		if start+i<items.size():out.append(items[start+i])
	return out

func page_count() -> int:
	return maxi(1,ceili(float(catalog(tab).size())/4.0))

# ------------------------------------------------------------------ build
func build() -> void:
	_clear()
	if game==null:return
	view=get_viewport().get_visible_rect().size
	if view.y<=1.0:view=Vector2(1280,DESIGN_HEIGHT)
	s=clampf(view.y/DESIGN_HEIGHT,.45,3.4)
	width=maxf(1280.0,view.x/s)
	if selection_id=="":selection_id=String(game.storage.data.get(side(),""))
	if tab!="all" and tab!=side():tab=side()
	if not _tab_allowed(tab):tab=side() if _tab_allowed(side()) else "all"
	page=clampi(page,0,page_count()-1)
	_background()
	_header()
	_side_tabs()
	_cards()
	_hero()
	_detail()
	_footer()

# ------------------------------------------------------------------ 배경
func _background() -> void:
	var shade:=ColorRect.new()
	shade.color=Color(.02,.018,.05,1.0)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art:=TextureRect.new()
	art.texture=BG
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate=Color(1.0,.94,1.10,0.95)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scrim:=UIK.Scrim.new()
	scrim.strength=0.42
	add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var moon:=TextureRect.new()
	moon.texture=LC.GLOW
	moon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	moon.stretch_mode=TextureRect.STRETCH_SCALE
	moon.modulate=Color(.74,.78,1.0,.30)
	moon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(self,moon,Rect2(width*.47,-200.0,600.0,600.0))
	var warm:=TextureRect.new()
	warm.texture=LC.GLOW
	warm.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	warm.stretch_mode=TextureRect.STRETCH_SCALE
	warm.modulate=Color(1.0,.72,.40,.16)
	warm.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(self,warm,Rect2(-130.0,430.0,540.0,430.0))
	var embers:=LArt.Embers.new()
	embers.count=32
	embers.speed=6.0
	embers.tint=Color(1.0,.86,.62,.45)
	_add(self,embers,Rect2(0,0,width,DESIGN_HEIGHT))
	var lattice:=LArt.Lattice.new()
	lattice.color=Color(.85,.72,.47,.030)
	_add(self,lattice,Rect2(0,0,width,DESIGN_HEIGHT))
	var frame:=LArt.ScreenFrame.new()
	frame.color=Color(.85,.72,.47,.32)
	_add(self,frame,Rect2(0,0,width,DESIGN_HEIGHT))
	var vignette:=TextureRect.new()
	vignette.texture=LC.VIGNETTE
	vignette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode=TextureRect.STRETCH_SCALE
	vignette.modulate=Color(1,1,1,.55)
	vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# ------------------------------------------------------------------ 상단 바
func _header() -> void:
	var back:=_button("뒤로",func()->void:game.back(),"iron","back",Rect2(MARGIN,10,104,52),17.0)
	back.name="SelectionBack"
	# 연꽃 문장
	var crest:=Control.new()
	crest.mouse_filter=Control.MOUSE_FILTER_IGNORE
	crest.draw.connect(func()->void:
		var c: Vector2=crest.size*.5
		var r:=minf(crest.size.x,crest.size.y)*.5-1.0
		for i in range(4):
			crest.draw_circle(c,r+1.0+float(i)*2.2,P.alpha(P.BRASS,.13-float(i)*.028))
		LC.gradient_rounded(crest,Rect2(c-Vector2(r,r),Vector2(r*2.0,r*2.0)),P.BRASS_LIGHT,P.BRASS_DEEP,r)
		crest.draw_arc(c,r,0,TAU,44,Color(1,.96,.84,.8),1.8,true)
		G.draw_glyph(crest,"lotus",Rect2(c-Vector2(r*.62,r*.62),Vector2(r*1.24,r*1.24)),Color("2b1c06"),1.7))
	_add(self,crest,Rect2(MARGIN+112,16,44,44))
	var title:=_label(self,"캐릭터 선택",34,P.HANJI,true)
	_add(self,title,Rect2(MARGIN+164,4,430,44))
	var subtitle:=_label(self,"월하의 서원 · 8인 생존전",14.5,Color(.84,.82,.94),false)
	_add(self,subtitle,Rect2(MARGIN+166,48,430,22))
	# 도사 6 : 요괴 2 명패
	var roster=game.rules
	var daoists:=int(roster.players.size())-int(roster.yokai_count)
	var pill_rect:=Rect2(width*.5-124,12,248,46)
	_plate(self,pill_rect,UIK.TEX_PLAQUE,24)
	var roster_text:="도사 %d  :  요괴 %d" % [daoists,int(roster.yokai_count)]
	var text_w:=FONT.get_string_size(roster_text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(9,int(17*s))).x/s
	var group_w:=26.0+8.0+text_w+8.0+26.0
	var start:=124.0-group_w*.5
	var lotus:=Control.new()
	lotus.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lotus.draw.connect(func()->void:G.draw_glyph(lotus,"lotus",Rect2(Vector2.ZERO,lotus.size),P.BRASS_LIGHT,1.7))
	_add(self,lotus,Rect2(pill_rect.position.x+start,pill_rect.position.y+10,26,26))
	var value:=_label(self,roster_text,17,P.BRASS_LIGHT,true)
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_add(self,value,Rect2(pill_rect.position.x+start+34.0,pill_rect.position.y+7,text_w+2.0,32))
	var foe:=Control.new()
	foe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	foe.draw.connect(func()->void:G.draw_glyph(foe,"fox",Rect2(Vector2.ZERO,foe.size),Color(.88,.74,1.0),1.7))
	_add(self,foe,Rect2(pill_rect.position.x+start+42.0+text_w,pill_rect.position.y+10,26,26))
	# 남은 시간 명패
	var plate:=Rect2(width-MARGIN-214,10,214,58)
	_plate(self,plate,UIK.TEX_PLAQUE,24)
	var sand:=Control.new()
	sand.mouse_filter=Control.MOUSE_FILTER_IGNORE
	sand.draw.connect(func()->void:G.draw_glyph(sand,"hourglass",Rect2(Vector2.ZERO,sand.size),P.BRASS_LIGHT,1.8))
	_add(self,sand,Rect2(plate.position.x+16,plate.position.y+16,26,26))
	var cap:=_label(self,"선택 남은 시간",12.5,Color(.86,.82,.88),false)
	_add(self,cap,Rect2(plate.position.x+50,plate.position.y+9,150,18))
	timer_label=_label(self,"00:25",24,P.BRASS_LIGHT,true)
	timer_label.name="SelectionTimer"
	_add(self,timer_label,Rect2(plate.position.x+50,plate.position.y+25,150,30))

# ------------------------------------------------------------------ 좌측 탭
func _side_tabs() -> void:
	var labels: Dictionary={"daoist":"도사","yokai":"요괴","all":"전체"}
	var glyphs: Dictionary={"daoist":"lotus","yokai":"fox","all":"grid"}
	var index:=0
	for key in ["daoist","yokai","all"]:
		var chosen: bool=String(key)==tab
		var shut:=not _tab_allowed(String(key))
		var caption: String=String(labels[key])+(" · 잠김" if shut else "")
		var target:=_button(caption,func()->void:_set_tab(String(key)),"tab_lit" if chosen else "tab",String(glyphs[key]),Rect2(MARGIN,96.0+index*70.0,98,62),15.0 if shut else 16.0)
		target.name="SelectionTab_"+String(key)
		target.disabled=shut
		target.modulate=Color(1,1,1,.55) if shut else Color.WHITE
		tab_buttons[key]=target
		index+=1

## 배정된 진영이 있으면 그 진영 탭만 열린다(빠른 매치).
func _tab_allowed(key: String) -> bool:
	if not role_locked or locked_team=="":return true
	return key==locked_team
func _set_tab(key: String) -> void:
	if not _tab_allowed(key):return
	if key==tab:return
	tab=key
	page=0
	_cards()
	_paint_tabs()

func _paint_tabs() -> void:
	for key in tab_buttons:
		var node: UIK.MetalButton=tab_buttons[key]
		if not is_instance_valid(node):continue
		var chosen:=String(key)==tab
		node.set_kind("tab_lit" if chosen else "tab")
		node.queue_redraw()

# ------------------------------------------------------------------ 카드
func _cards() -> void:
	card_buttons.clear()
	var layer:=_reset_layer("cards")
	var area:=Rect2(MARGIN+110,96,352,462)
	_plate(layer,area,UIK.TEX_PANEL_SOFT,20)
	var items:=page_items()
	for i in range(4):
		var col:=i%2
		var row:=i/2
		var card:=Rect2(area.position.x+6+col*172.0,area.position.y+6+row*198.0,166,192)
		if i<items.size():_make_card(items[i],card,layer)
		else:_make_empty(card,layer)
	var page_row:=Rect2(area.position.x+8,area.end.y-46.0,336,30)
	var left_btn:=_button("",func()->void:_turn_page(-1),"iron","back",Rect2(page_row.position.x,page_row.position.y,50,30),12.0,layer)
	left_btn.name="SelectionPage_prev"
	var right_btn:=_button("",func()->void:_turn_page(1),"iron","next",Rect2(page_row.end.x-50,page_row.position.y,50,30),12.0,layer)
	right_btn.name="SelectionPage_next"
	var page_text:=_label(layer,"%d / %d" % [page+1,page_count()],14.5,Color(.88,.86,.94))
	page_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_add(layer,page_text,Rect2(page_row.position.x+56,page_row.position.y+2,224,24))
	pager={"prev":left_btn,"next":right_btn,"label":page_text}
	_paint_cards()
	_paint_pager()

func _turn_page(delta: int) -> void:
	page=posmod(page+delta,page_count())
	_cards()
	_paint_tabs()

func _paint_pager() -> void:
	if pager.is_empty():return
	var count:=page_count()
	for key in ["prev","next","label"]:
		var node: Control=pager.get(key)
		if is_instance_valid(node):node.visible=count>1
	var text: Label=pager.get("label")
	if is_instance_valid(text):text.text="%d / %d" % [page+1,count]

func _make_empty(r: Rect2,parent: Node) -> void:
	var plate:=UIK.nine(parent,UIK.TEX_SLOT,16)
	_place(plate,r)
	var mark:=Control.new()
	mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	mark.draw.connect(func()->void:
		var box:=Rect2(Vector2.ZERO,mark.size)
		G.draw_glyph(mark,"spark",Rect2(box.get_center()-Vector2(box.size.x*.14,box.size.x*.14),Vector2(box.size.x*.28,box.size.x*.28)),P.alpha(P.BRASS,.30),1.3))
	_add(parent,mark,r)

func _make_card(item: Dictionary,r: Rect2,parent: Node) -> void:
	var id: String=String(item.id)
	var team: String=String(item.get("team","daoist"))
	var mine:=team==side()
	var owned_now:=owned(id)
	var card: UIK.MetalButton=UIK.MetalButton.new()
	card.kind="slot"
	card.text=""
	card.glyph=""
	card.font_size=1
	card.name="SelectCard_"+id.split(":")[1]
	card.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	card.pressed.connect(func()->void:
		if card.usable():game.sound.play_clip("button");game.if_vibrate();_pick(id))
	_add(parent,card,r)
	card.clip_contents=false
	game.button_feel(card)
	card.disabled=(locked and id!=selection_id) or not mine_allowed(team)
	if not mine_allowed(team):card.modulate=Color(.7,.7,.76,.75)
	# 금빛 광 + 카드 텍스처
	var glow:=UIK.Glow.new()
	glow.color=Color(1,.84,.46)
	glow.radius=14.0*s
	glow.strength=1.0
	glow.visible=id==selection_id
	_add(card,glow,Rect2(-2,-2,r.size.x+4,r.size.y+4))
	var frame:=UIK.nine(card,UIK.TEX_CARD,22)
	_place(frame,Rect2(0,0,r.size.x,r.size.y))
	# 초상화: 카드 안쪽을 가득 채운다
	var art_rect:=Rect2(5,5,r.size.x-10,r.size.y-54)
	if ResourceLoader.exists(String(item.portrait)):
		var holder:=Control.new()
		holder.clip_contents=true
		holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_add(card,holder,art_rect)
		var art:=TextureRect.new()
		art.texture=load(String(item.portrait))
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.modulate=Color(1.02,1.01,1.04,1.0 if (owned_now or not mine) else .42)
		_add(holder,art,Rect2(0,0,art_rect.size.x,art_rect.size.y))
	# 아래 이름 띠
	var veil:=TextureRect.new()
	veil.texture=LC.fade_texture(Color(.02,.02,.05,0.0),Color(.012,.013,.03,.99))
	veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode=TextureRect.STRETCH_SCALE
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(card,veil,Rect2(5,r.size.y-96.0,r.size.x-10,54))
	var name_label:=_label(card,String(item.get("name","")),21,P.HANJI,true)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_add(card,name_label,Rect2(6,r.size.y-52.0,r.size.x-12,28))
	var role:=_label(card,String(item.get("role","")),13.5,P.HANJI_DIM,false)
	role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_add(card,role,Rect2(6,r.size.y-24.0,r.size.x-12,18))
	# 진영 표식
	var badge:=Control.new()
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var daoist:=team=="daoist"
	badge.draw.connect(func()->void:
		var c: Vector2=badge.size*.5
		var rad:=minf(badge.size.x,badge.size.y)*.5
		badge.draw_circle(c,rad,Color(.03,.03,.05,.92))
		badge.draw_arc(c,rad,0,TAU,30,P.alpha(P.BRASS,.95) if daoist else P.alpha(Color(.76,.60,1.0),.95),1.7,true)
		G.draw_glyph(badge,"lotus" if daoist else "fox",Rect2(c-Vector2(rad*.58,rad*.58),Vector2(rad*1.16,rad*1.16)),P.BRASS_LIGHT if daoist else Color(.90,.78,1.0),1.5))
	_add(card,badge,Rect2(9,9,26,26))
	if not mine:
		var tag:=_label(card,"선택 불가" if role_locked else "상대 진영",12,Color(.90,.84,1.0),false)
		tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		tag.add_theme_stylebox_override("normal",LC.panel_box(Color(.20,.12,.32,.95),8,P.alpha(Color(.80,.64,1.0),.7),1))
		_add(card,tag,Rect2(r.size.x-76.0,10,64,22))
	elif not owned_now:
		var tag:=_label(card,"미해금",12,Color(.99,.88,.64),false)
		tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		tag.add_theme_stylebox_override("normal",LC.panel_box(Color(.16,.09,.05,.95),8,P.alpha(P.BRASS,.7),1))
		_add(card,tag,Rect2(r.size.x-70.0,10,59,22))
	# 금색 확인 인장(우상단)
	var seal:=UIK.Seal.new()
	seal.visible=id==selection_id
	seal.name="CardSeal"
	_add(card,seal,Rect2(r.size.x-40.0,10,32,32))
	card.set_meta("frame",frame)
	card.set_meta("glow",glow)
	card.set_meta("seal",seal)
	card.set_meta("id",id)
	card.set_meta("name_label",name_label)
	card.set_meta("owned",owned_now)
	card.set_meta("mine",mine)
	card_buttons.append(card)

func _paint_cards() -> void:
	for card in card_buttons:
		if not is_instance_valid(card):continue
		var id: String=String(card.get_meta("id"))
		var chosen:=id==selection_id
		var frame: NinePatchRect=card.get_meta("frame")
		if is_instance_valid(frame):frame.texture=UIK.TEX_CARD_LIT if chosen else UIK.TEX_CARD
		var glow: Control=card.get_meta("glow")
		if is_instance_valid(glow):glow.visible=chosen
		var seal: Control=card.get_meta("seal")
		if is_instance_valid(seal):seal.visible=chosen
		var name_label: Label=card.get_meta("name_label")
		if is_instance_valid(name_label):
			name_label.add_theme_color_override("font_color",Color("fff0cd") if chosen else P.HANJI)
		card.modulate=Color(1.03,1.02,1.0) if chosen else Color(0.96,0.97,1.02)

# ------------------------------------------------------------------ 중앙 대형 원화
func _hero() -> void:
	var right_edge:=width-MARGIN-368-10
	var left_edge:=MARGIN+110+352+12
	var area:=Rect2(left_edge,96,right_edge-left_edge,462)
	_reset_layer("hero")
	var spec:=C.find(selection_id)
	var daoist:=String(spec.get("team","daoist"))=="daoist"
	var accent:=P.BRASS_LIGHT if daoist else Color(.84,.70,1.0)
	# 달 광륜
	var glow:=TextureRect.new()
	glow.texture=LC.GLOW
	glow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode=TextureRect.STRETCH_SCALE
	glow.modulate=Color(.72,.74,1.0,.34) if daoist else Color(.64,.48,1.0,.30)
	glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var glow_size:=minf(area.size.x*1.02,620.0)
	_add(hero_layer,glow,Rect2(area.get_center().x-glow_size*.5,area.position.y-30,glow_size,glow_size))
	# 진영 문장 원(뒤)
	var crest:=Control.new()
	crest.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var crest_size:=minf(area.size.x*.86,520.0)
	crest.draw.connect(func()->void:
		var c: Vector2=crest.size*.5
		var rad:=minf(crest.size.x,crest.size.y)*.5
		crest.draw_arc(c,rad,0,TAU,96,P.alpha(accent,.16),1.6,true)
		crest.draw_arc(c,rad*.88,0,TAU,96,P.alpha(accent,.10),12.0,true)
		for i in range(28):
			var a0:=i*TAU/28.0
			crest.draw_arc(c,rad*.94,a0,a0+TAU/56.0,6,P.alpha(accent,.26),1.3,true)
		for i in range(8):
			var a0:=i*TAU/8.0+0.12
			crest.draw_line(c+Vector2.from_angle(a0)*rad*.70,c+Vector2.from_angle(a0)*rad*.86,P.alpha(accent,.12),1.2,true)
		G.draw_glyph(crest,"lotus" if daoist else "fox",Rect2(c-Vector2(rad*.44,rad*.44),Vector2(rad*.88,rad*.88)),P.alpha(accent,.13),2.2))
	_add(hero_layer,crest,Rect2(area.get_center().x-crest_size*.5,area.position.y-10,crest_size,crest_size))
	# 전신 원화(크게)
	var sprite_path:=String(spec.get("sprite",""))
	# 상단 배지(도사 6 : 요괴 2)를 가리지 않도록 일러스트 상단을 64 아래에서 시작한다.
	var art_bottom:=area.end.y-44.0
	if ResourceLoader.exists(sprite_path):
		var art:=TextureRect.new()
		art.texture=load(sprite_path)
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.modulate=Color(1.04,1.02,1.02,1.0)
		var art_height:=minf(area.size.y-14.0,448.0)
		var art_width:=minf(area.size.x*.96,art_height*1.05)
		_add(hero_layer,art,Rect2(area.get_center().x-art_width*.5,art_bottom-art_height,art_width,art_height))
	# 달빛 마법진 단상
	var pedestal:=LArt.Pedestal.new()
	pedestal.glow=Color(.78,.70,1.0,.34) if daoist else Color(.72,.54,1.0,.34)
	_add(hero_layer,pedestal,Rect2(area.get_center().x-168.0,art_bottom-52.0,336,92))
	# 단상 위 인게임 소형 캐릭터
	if is_instance_valid(game):
		var holder: Control=game.portrait(hero_layer,selection_id,Vector2(80,100)*s)
		holder.position=Vector2(area.get_center().x-40.0,art_bottom-84.0)*s
		holder.size=Vector2(80,100)*s
	# 이름 워터마크
	var mark:=_label(hero_layer,String(spec.get("name","")),13.5,P.alpha(accent,.92),false)
	mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_add(hero_layer,mark,Rect2(area.position.x,area.end.y-22.0,area.size.x,20))

# ------------------------------------------------------------------ 우측 상세
func _detail() -> void:
	var x0:=width-MARGIN-368
	var area:=Rect2(x0,96,368,462)
	_reset_layer("detail")
	_plate(detail_layer,area,UIK.TEX_PANEL,40,0.75,Color(1,.80,.44))
	detail_layer.get_child(detail_layer.get_child_count()-1).name="SelectionDetail"
	var spec:=C.find(selection_id)
	var daoist:=String(spec.get("team","daoist"))=="daoist"
	var accent:=P.BRASS_LIGHT if daoist else Color(.86,.72,1.0)
	var name_icon:=Control.new()
	name_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	name_icon.draw.connect(func()->void:G.draw_glyph(name_icon,"lotus" if daoist else "fox",Rect2(Vector2.ZERO,name_icon.size),accent,1.8))
	_add(detail_layer,name_icon,Rect2(x0+22,area.position.y+18,30,30))
	var name_label:=_label(detail_layer,String(spec.get("name","")),30,P.HANJI,true)
	name_label.name="SelectionName"
	_add(detail_layer,name_label,Rect2(x0+58,area.position.y+8,296,40))
	var team_name: String="도사" if daoist else "요괴"
	var team_w:=_pill_width(team_name,15.0)+34.0
	var team:=_chip(detail_layer,team_name,Rect2(x0+24,area.position.y+60,team_w,28),accent if daoist else Color(.80,.66,1.0),Color("231705"))
	team.name="SelectionTeamChip"
	var role_w:=_pill_width(String(spec.get("role","")),15.0)+36.0
	_chip(detail_layer,String(spec.get("role","")),Rect2(x0+24+team_w+8,area.position.y+60,role_w,28),Color(.32,.24,.44),Color(.92,.86,1.0))
	var intro:=_label(detail_layer,String(spec.get("intro","")),15,Color(.90,.90,.98),false)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	_add(detail_layer,intro,Rect2(x0+24,area.position.y+100,320,56))
	var line:=ColorRect.new()
	line.color=P.alpha(P.BRASS,.30)
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(detail_layer,line,Rect2(x0+24,area.position.y+162,320,1))
	var head:=_label(detail_layer,"주요 능력",17,P.BRASS_LIGHT,true)
	_add(detail_layer,head,Rect2(x0+24,area.position.y+172,220,24))
	var hint:=_label(detail_layer,"대표 · 보조 · 궁극기",12,Color(.76,.76,.90),false)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	_add(detail_layer,hint,Rect2(x0+190,area.position.y+176,154,20))
	var abilities: Array=spec.get("abilities",[])
	for i in range(mini(3,abilities.size())):
		var ability: Dictionary=abilities[i]
		var cx:=x0+24+58.0+float(i)*106.0
		var circle:=UIK.SkillCircle.new()
		circle.skill=String(ability.get("icon","attack"))
		circle.accent=accent
		circle.name="Skill_%d" % i
		_add(detail_layer,circle,Rect2(cx-40.0,area.position.y+202,80,80))
		var slot_name: String=String(ability.get("slot_name",""))
		var caption:=_label(detail_layer,String(ability.get("name","")),13.5,P.HANJI,false)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_add(detail_layer,caption,Rect2(cx-54.0,area.position.y+286,108,20))
	var line2:=ColorRect.new()
	line2.color=P.alpha(P.BRASS,.30)
	line2.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(detail_layer,line2,Rect2(x0+24,area.position.y+314,320,1))
	var skill: Dictionary=spec.get("skill",{})
	var lead:=_label(detail_layer,"대표 능력",13.5,Color(.82,.82,.92),false)
	_add(detail_layer,lead,Rect2(x0+24,area.position.y+324,92,20))
	var value:=_label(detail_layer,String(skill.get("name","")),16.5,accent,true)
	_add(detail_layer,value,Rect2(x0+112,area.position.y+322,224,22))
	var gauge:=UIK.Gauge.new()
	gauge.tint=P.BRASS if daoist else Color(.74,.58,1.0)
	gauge.maximum=float(maxi(1,int(float(skill.get("cd",10.0)))))
	gauge.value=gauge.maximum*.72
	gauge.ticks=0
	_add(detail_layer,gauge,Rect2(x0+24,area.position.y+348,320,13))
	var desc:=_label(detail_layer,String(skill.get("description","")),13,Color(.84,.86,.96),false)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_add(detail_layer,desc,Rect2(x0+24,area.position.y+368,320,52))
	var cost:=_label(detail_layer,"쿨타임 %d초 · 지속 능력 없음" % int(float(skill.get("cd",0.0))),12,Color(.76,.78,.90),false)
	_add(detail_layer,cost,Rect2(x0+24,area.position.y+414,320,18))

func _pill_width(text_value: String,extent: float) -> float:
	return FONT.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(9,int(extent*s))).x/s

func _chip(parent: Node,text_value: String,r: Rect2,fill: Color,ink: Color) -> Label:
	var node:=_label(parent,text_value,15,ink,false)
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	node.add_theme_stylebox_override("normal",LC.panel_box(fill,11,P.alpha(Color(1,.96,.86),.7),1))
	_add(parent,node,r)
	return node

# ------------------------------------------------------------------ 하단 바
func _footer() -> void:
	var area:=Rect2(MARGIN,570,width-MARGIN*2,132)
	_reset_layer("footer")
	_plate(footer_layer,area,UIK.TEX_PANEL,40,0.35,Color(1,.80,.44))
	var count:=0
	var confirmed:=0
	var entries: Array=[]
	entries.append(game.rules.players.human)
	for entry in game.rules.players.values():
		if String(entry.get("id",""))!="human":entries.append(entry)
	for entry in entries:
		if String(entry.get("character",""))!="":count+=1
		if bool(entry.get("confirmed",false)):confirmed+=1
	var head:=_label(footer_layer,"선택 현황",14.5,Color(.90,.86,.80),false)
	_add(footer_layer,head,Rect2(area.position.x+24,area.position.y+10,110,20))
	var count_label:=_label(footer_layer,"%d / %d" % [count,entries.size()],18,P.BRASS_LIGHT,true)
	count_label.name="SelectionCount"
	_add(footer_layer,count_label,Rect2(area.position.x+126,area.position.y+7,90,24))
	team_label=_label(footer_layer,"팀원 확정 %d / %d" % [confirmed,entries.size()],12.5,Color(.84,.84,.94),false)
	_add(footer_layer,team_label,Rect2(area.position.x+214,area.position.y+10,220,20))
	strip=Control.new()
	strip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_add(footer_layer,strip,Rect2(0,0,width,DESIGN_HEIGHT))
	var slots_x:=area.position.x+24
	var slot_y:=area.position.y+36
	for i in range(8):
		var entry: Dictionary={}
		if i<entries.size():entry=entries[i]
		_slot(Rect2(slots_x+float(i)*68.0,slot_y,60,60),entry,i)
	var hint:=_label(footer_layer,"상대 진영 캐릭터는 경기 시작 때 공개됩니다",12,Color(.80,.82,.94),false)
	_add(footer_layer,hint,Rect2(slots_x,area.end.y-28.0,520,18))
	var locked_now:=locked or bool(me().get("confirmed",false))
	confirm_button=_button("확정 완료 · 팀원 대기" if locked_now else "선택 확정",func()->void:game.confirm_selection(selection_id,self),"gold","check",Rect2(area.end.x-330,area.position.y+34,310,66),24.0,footer_layer)
	confirm_button.name="SelectionConfirm"
	confirm_button.disabled=locked_now or not owned(selection_id)
	ready_label=_label(footer_layer,"",13,Color("ffe6a8"),false)
	ready_label.name="SelectionReady"
	ready_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_add(footer_layer,ready_label,Rect2(area.end.x-358,area.end.y-28.0,344,18))
	ready_label.text="팀원 모두의 선택이 끝나면 3초 뒤 경기가 시작됩니다"
	# 진영 잠금 안내
	if role_locked and locked_team!="":
		var lock_note:=_label(footer_layer,"빠른 매치 · 배정된 진영만 선택할 수 있습니다",12,Color(.86,.82,.94),false)
		_add(footer_layer,lock_note,Rect2(area.position.x+24,area.end.y-28.0,420,18))

func _slot(r: Rect2,entry: Dictionary,index: int) -> void:
	var filled:=not entry.is_empty()
	var confirmed:=filled and bool(entry.get("confirmed",false))
	var host:=filled and String(entry.get("id",""))=="human"
	var character:=String(entry.get("character",""))
	var spec:=C.find(character) if character!="" else {}
	var box:=Control.new()
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	box.name="SelectionSlot_%d" % index
	_add(strip,box,r)
	var glow:=UIK.Glow.new()
	glow.color=Color(1,.84,.46)
	glow.radius=9.0*s
	glow.strength=.9
	glow.visible=confirmed
	_add(box,glow,Rect2(-1,-1,r.size.x+2,r.size.y+2))
	var frame:=UIK.nine(box,UIK.TEX_SLOT,16)
	_place(frame,Rect2(0,0,r.size.x,r.size.y))
	if filled and String(spec.get("portrait",""))!="":
		var holder:=Control.new()
		holder.clip_contents=true
		holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_add(box,holder,Rect2(4,4,r.size.x-8,r.size.y-8))
		var portrait:=TextureRect.new()
		portrait.texture=load(String(spec.portrait))
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		portrait.modulate=Color(1,1,1,1.0 if confirmed else .72)
		_add(holder,portrait,Rect2(0,0,r.size.x-8,r.size.y-8))
	else:
		var q:=Control.new()
		q.mouse_filter=Control.MOUSE_FILTER_IGNORE
		q.draw.connect(func()->void:
			var c: Vector2=q.size*.5
			G.draw_glyph(q,"users",Rect2(c-Vector2(q.size.x*.24,q.size.x*.24),Vector2(q.size.x*.48,q.size.x*.48)),P.alpha(P.HANJI,.30),1.7))
		_add(box,q,Rect2(0,0,r.size.x,r.size.y))
	if host:
		var crown:=Control.new()
		crown.mouse_filter=Control.MOUSE_FILTER_IGNORE
		crown.draw.connect(func()->void:G.draw_glyph(crown,"crown",Rect2(Vector2.ZERO,crown.size),P.BRASS_LIGHT,1.6))
		_add(box,crown,Rect2(4,4,16,16))
	if confirmed:
		var seal:=UIK.Seal.new()
		seal.glowing=false
		_add(box,seal,Rect2(r.size.x-22.0,r.size.y-22.0,19,19))

# ------------------------------------------------------------------ 동작
## 이 진영 카드를 지금 고를 수 있는지(빠른 매치 진영 잠금).
func mine_allowed(team: String) -> bool:
	if not role_locked or locked_team=="":return true
	return team==locked_team
func _pick(id: String) -> void:
	if locked:return
	if not mine_allowed(String(C.find(id).get("team",""))):
		game.notice("빠른 매치에서는 배정된 진영(%s)만 선택할 수 있습니다." % ("도사" if locked_team=="daoist" else "요괴"))
		return
	if String(C.find(id).get("team",""))!=side():
		selection_id=id
		_paint_cards()
		_hero()
		_detail()
		return
	if not owned(id):return
	if game.rules.select_character("human",id):
		selection_id=id
		game.selection_id=id
		_paint_cards()
		_hero()
		_detail()
		_footer()

## 확정 뒤 준비 카운트다운(2.0.27): 0이 되면 맵으로 넘어간다.
func set_ready(left: float,active: bool) -> void:
	if not is_instance_valid(ready_label):return
	if active:
		var seconds:=maxi(1,int(ceil(left)))
		ready_label.text="곧 경기 시작 · %d" % seconds
		ready_label.add_theme_color_override("font_color",Color("a8f0d0"))
	elif locked or bool(me().get("confirmed",false)):
		ready_label.text="확정 완료 · 팀원 대기 중"
		ready_label.add_theme_color_override("font_color",Color("ffe6a8"))
func set_timer(left: float) -> void:
	if is_instance_valid(timer_label):
		var seconds:=maxi(0,int(ceil(left)))
		timer_label.text="00:%02d" % seconds

func set_team(stats: Dictionary) -> void:
	if is_instance_valid(team_label):
		var done:=int(stats.get("done",0))
		var total:=int(stats.get("total",0))
		team_label.text="팀원 확정 %d / %d" % [done,total]
