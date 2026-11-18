extends "res://scripts/ui/lobby_screen.gd"
## 캐릭터 & 캐릭터 스킨 상점.
## 왼쪽: 탭 + 2×3 금빛 장식 카드 그리드 / 오른쪽: 달빛 단상 대형 미리보기 + 해금·장착 버튼 하나.
## 인앱결제·광고는 없고, 모든 해금은 경기·업적·우편 보상으로 모은 게임 재화로만 한다.
const RoomButton=preload("res://scripts/ui/metal_button.gd")
const TABS=[{"id":"character","label":"캐릭터"},{"id":"skin","label":"스킨"},{"id":"aura","label":"칭호·기운"}]
## 탭 아이콘은 대기실과 같은 벡터 글리프를 쓴다(텍스처 없음 → 어떤 해상도에서도 선명).
const TAB_GLYPHS={"character":"lotus","skin":"flower","aura":"diamond"}
const COLS:=3
const ROWS:=2
const PER_PAGE:=COLS*ROWS
const GRID_POS:=Vector2(150,96)
const GRID_WIDTH:=716.0
const CARD_GAP:=12.0
const CARD_HEIGHT:=208.0
const PANEL_POS:=Vector2(882,96)
const PANEL_SIZE:=Vector2(372,556)
## 카드에서 이름·역할·가격이 차지하는 아래 띠 높이. 초상화는 그 위까지만 그린다.
const PORTRAIT_INSET:=64.0
var tab:="character"
var page:=0
var selected_id:=""
var cards: Array=[]
var preview_body: Control
var action_button: WooMobileButton
var page_label: Label
var page_buttons: Array=[]
var tab_buttons: Dictionary={}
var grid_hint: Label

func build() -> void:
	header("캐릭터 · 스킨 상점","달빛 아래, 도사와 요괴의 차림을 고르세요 · 해금은 게임 재화로만")
	note("보유한 캐릭터와 스킨은 경기·업적·우편 보상으로 모은 코인으로 해금합니다 · 인앱결제·광고 없음")
	# 좌측 탭
	for i in range(TABS.size()):
		var spec: Dictionary=TABS[i]
		var key: String=spec.id
		# 2.0.21: 대기실과 같은 입체 금속 버튼(RoomButton)으로 탭을 그린다.
		var target=RoomButton.new()
		target.text=String(spec.label)
		target.glyph=String(TAB_GLYPHS.get(key,"lotus"))
		target.variant="lit" if key==tab else "metal"
		target.font_size=18
		target.accent=T.GOLD
		target.name="ShopTab_"+key
		target.custom_minimum_size=Vector2(122,64)
		target.pressed.connect(func()->void:set_tab(key))
		add_child(target)
		place(target,Rect2(26,96+i*72,122,64))
		tab_buttons[key]={"button":target}
	# 페이지 이동
	for spec in [["‹",-1],["›",1]]:
		var target:=button(String(spec[0]),func()->void:turn_page(int(spec[1])),self,false,20)
		page_buttons.append(target)
	page_label=label(self,"1 / 1",15,T.MUTED)
	page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	grid_hint=label(self,"카드를 눌러 오른쪽에서 미리 보세요",15,Color(0.76,0.80,0.90,0.9))
	# 미리보기 판: 대기실 RoomPanel과 같은 먹색 그라데이션 + 황동 모서리 장식.
	var frame:=Art.RoomPanel.new()
	frame.fill_top=Color(0.105,0.085,0.170,0.94)
	frame.fill_bottom=Color(0.030,0.026,0.060,0.95)
	frame.radius=14.0
	frame.arm=22.0
	frame.edge=Color(0.85,0.72,0.47,0.66)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	place(frame,Rect2(PANEL_POS,PANEL_SIZE))
	refresh()

func set_tab(id: String) -> void:
	if id==tab:return
	tab=id
	page=0
	selected_id=""
	refresh()

func turn_page(delta: int) -> void:
	var count:=maxi(1,ceili(float(_items().size())/PER_PAGE))
	page=posmod(page+delta,count)
	refresh()

func _items() -> Array:
	return Market.shop_items(tab)

func _default_id() -> String:
	var items:=_items()
	if items.is_empty():return ""
	if tab=="character":
		var equipped:=String(game.storage.data[String(C.find(String(game.storage.data.daoist)).get("team","daoist"))])
		for item in items:
			if String(item.id)==equipped:return equipped
	elif tab=="skin":
		var skin: String=game.storage.equipped("skin")
		for item in items:
			if String(item.id)==skin:return skin
	else:
		for kind in ["title","effect"]:
			var equipped: String=game.storage.equipped(kind)
			for item in items:
				if item.get("kind","")==kind and String(item.title.id)==equipped:return String(item.id)
	return String(items[0].id)

## 항목을 화면 표시용으로 정리한다.
func view_item(raw: Dictionary) -> Dictionary:
	if tab=="character":
		var spec:=C.find(String(raw.id))
		var owned: bool=game.storage.owns_character(String(raw.id))
		return {"id":String(raw.id),"kind":"character","name":String(spec.get("name","")),"team":String(spec.get("team","daoist")),
			"role":String(spec.get("role","")),"intro":String(spec.get("intro","")),"portrait":String(spec.get("portrait","")),
			"price":int(raw.price),"owned":owned}
	if tab=="skin":
		return {"id":String(raw.id),"kind":"skin","name":String(raw.name),"role":"도포 색","intro":String(raw.desc),
			"color":Color(String(raw.color)),"price":int(raw.price),"owned":game.storage.owns(String(raw.id))}
	var item: Dictionary=raw.title
	var kind: String=String(raw.get("kind","title"))
	return {"id":String(raw.id),"kind":kind,"name":String(item.name),"role":"칭호" if kind=="title" else "기운",
		"intro":String(item.desc),"color":Color(String(item.get("color","d9b8ff"))),"price":int(item.price),
		"owned":game.storage.owns(String(item.id)) or String(item.id)=="","item":item}

func refresh() -> void:
	if not is_inside_tree():return
	if selected_id=="":selected_id=_default_id()
	_rebuild_cards()
	_rebuild_preview()
	_paint_tabs()
	_paint_pager()

# ---------------------------------------------------------------- 카드 그리드
func _rebuild_cards() -> void:
	for card in cards:
		if is_instance_valid(card):card.queue_free()
	cards.clear()
	var items:=_items()
	var count:=maxi(1,ceili(float(items.size())/PER_PAGE))
	page=clampi(page,0,count-1)
	var card_width:=(GRID_WIDTH-CARD_GAP*(COLS-1))/COLS
	for index in range(PER_PAGE):
		var item_index:=page*PER_PAGE+index
		if item_index>=items.size():break
		var item:=view_item(items[item_index])
		var col:=index%COLS
		var row:=index/COLS
		var rect:=Rect2(GRID_POS.x+col*(card_width+CARD_GAP),GRID_POS.y+row*(CARD_HEIGHT+CARD_GAP),card_width,CARD_HEIGHT)
		_make_card(item,rect)
	_paint_cards()

func _make_card(item: Dictionary,rect: Rect2) -> void:
	var id: String=String(item.id)
	var card:=button("",func()->void:select_item(id),self,false,15)
	card.name="ShopCard_"+id.replace(":","_")
	place(card,rect)
	var trim:=Art.Filigree.new()
	trim.color=Color(0.85,0.72,0.47,0.42)
	trim.arm=17.0
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(trim)
	# 그림: card의 자식들은 card 안쪽 로컬 좌표(3,3)부터 채운다.
	match String(item.kind):
		"character":
			card.clip_contents=true
			# 2.0.21: 카드 전체를 덮던 원화 크롭을 이름 띠 위쪽으로 줄이고, 세로는
			# 가운데 기준으로 잘라 8명 모두 얼굴·눈코입이 카드 안에 들어오게 한다.
			var art_height:=rect.size.y-PORTRAIT_INSET
			cover_art(card,String(item.portrait),Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,art_height)),0.4)
			# 이름 띠 위로 어두워지는 그라데이션(불투명 띠 대신)로 글자만 또렷하게.
			var veil:=TextureRect.new()
			veil.texture=T.fade_texture(Color(0.03,0.028,0.06,0.0),Color(0.03,0.028,0.06,0.96))
			veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			veil.stretch_mode=TextureRect.STRETCH_SCALE
			veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(veil)
			veil.position=Vector2(3,rect.size.y-PORTRAIT_INSET-18)
			veil.size=Vector2(rect.size.x-6,PORTRAIT_INSET+18)
			var emblem:=chip(card,"도" if String(item.team)=="daoist" else "요",T.DAO if String(item.team)=="daoist" else T.YOKAI,15,
				Color(0.07,0.05,0.02,1.0) if String(item.team)=="daoist" else Color(0.06,0.03,0.10,1.0))
			emblem.custom_minimum_size=Vector2(32,26)
			place(emblem,Rect2(rect.position.x+11,rect.position.y+11,32,26))
		"skin":
			card.clip_contents=true
			# 도포 색은 얼굴 확대 대신 실제 인게임 캐릭터에 입혀 보여 준다.
			var wash:=ColorRect.new()
			wash.color=Color(item.color).lerp(Color(0.04,0.05,0.11),.78)
			wash.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(wash)
			place(wash,Rect2(rect.position+Vector2(3,3),rect.size-Vector2(6,6)))
			var holder:=figure(card,String(game.storage.data.daoist),Vector2(rect.size.x-30,96),Color(item.color).lerp(Color.WHITE,.45))
			place(holder,Rect2(rect.position.x+15,rect.position.y+4,rect.size.x-30,96))

		"effect":
			var orb:=Art.Orb.new()
			orb.color=Color(item.color)
			card.add_child(orb)
			orb.position=Vector2(rect.size.x*.5-46,10);orb.size=Vector2(92,92)
			var ring:=Art.AuraRing.new()
			ring.color=Color(item.color)
			card.add_child(ring)
			ring.position=Vector2(0,rect.size.y-108);ring.size=Vector2(rect.size.x,110)
		"title":
			var plaque:=Art.Plaque.new()
			card.add_child(plaque)
			plaque.position=Vector2(24,4);plaque.size=Vector2(rect.size.x-48,118)
			var plate_text:=label(card,String(item.name),24,T.GOLD_SOFT,true)
			plate_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			plate_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			place(plate_text,Rect2(rect.position.x+24,rect.position.y+26,rect.size.x-48,48))
	# 이름·역할·가격은 카드 아래 62px 안에 세 줄로 모아, 초상화가 그 위를 넓게 쓴다.
	var text_top:=rect.size.y-66
	var scrim:=TextureRect.new()
	scrim.texture=T.fade_texture(Color(0.028,0.026,0.055,0.0),Color(0.020,0.018,0.042,0.98))
	scrim.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode=TextureRect.STRETCH_SCALE
	scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(scrim)
	scrim.position=Vector2(3,text_top-16);scrim.size=Vector2(rect.size.x-6,rect.size.y-text_top+13)
	var name_label:=label(card,String(item.name),19,T.IVORY,true)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(name_label,Rect2(rect.position.x+8,rect.position.y+text_top,rect.size.x-16,25))
	var sub:=String(item.role)
	var sub_label:=label(card,sub,13,T.MUTED)
	sub_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(sub_label,Rect2(rect.position.x+8,rect.position.y+text_top+25,rect.size.x-16,17))
	var state:=_price_text(item)
	var state_label:=label(card,state,15,T.GOLD if _owned(item) else Color("cdbb92"))
	state_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(state_label,Rect2(rect.position.x+8,rect.position.y+text_top+43,rect.size.x-16,19))
	# 옷감 색 띠는 이름 위에 얇게 올린다(스킨 카드에서만).
	if String(item.kind)=="skin":
		var band:=Panel.new()
		band.mouse_filter=Control.MOUSE_FILTER_IGNORE
		band.add_theme_stylebox_override("panel",T.panel_box(Color(item.color).lerp(Color.WHITE,.08),3,Color(0.95,0.85,0.6,0.8),1))
		card.add_child(band)
		place(band,Rect2(rect.position.x+12,rect.position.y+text_top-6,rect.size.x-24,5))
	# 황동 테두리·모서리 장식은 원화 위에 마지막으로 얹는다(대기실 RoomPanel 톤).
	var frame:=CardFrame.new()
	frame.edge=Color(0.85,0.72,0.47,0.40)
	card.add_child(frame)
	place(frame,Rect2(rect.position,rect.size))
	card.set_meta("name_label",name_label)
	card.set_meta("trim",trim)
	card.set_meta("frame",frame)
	card.set_meta("id",id)
	cards.append(card)

func _owned(item: Dictionary) -> bool:
	return bool(item.get("owned",false))

func _price_text(item: Dictionary) -> String:
	if tab=="character":
		if String(game.storage.data[String(item.team)])==String(item.id):return "장착 중"
		return "보유" if _owned(item) else "%s 코인"%number(int(item.price))
	if _equipped(item):return "장착 중"
	return "보유" if _owned(item) else "%s 코인"%number(int(item.price))

func _paint_cards() -> void:
	for card in cards:
		if not is_instance_valid(card):continue
		var chosen: bool=String(card.get_meta("id"))==selected_id
		var box:=T.lit_box(Color(0.20,0.14,0.06,0.9),10) if chosen else T.panel_box(Color(0.038,0.045,0.09,0.9),10,Color(0.85,0.72,0.47,0.34),1)
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			card.add_theme_stylebox_override(state,box)
		var trim: Control=card.get_meta("trim")
		if trim!=null:trim.color=Color(0.95,0.82,0.52,0.85) if chosen else Color(0.85,0.72,0.47,0.36)
		var frame: Control=card.get_meta("frame")
		if frame!=null:
			frame.edge=Color(0.98,0.85,0.55,0.95) if chosen else Color(0.85,0.72,0.47,0.40)
			frame.lit=chosen
			frame.queue_redraw()
		var name_label: Label=card.get_meta("name_label")
		if name_label!=null:name_label.add_theme_color_override("font_color",T.GOLD_SOFT if chosen else T.IVORY)
		if not chosen:card.modulate=Color(0.93,0.94,1.0)
		else:card.modulate=Color(1.03,1.02,1.0)

func _paint_tabs() -> void:
	for key in tab_buttons:
		var spec: Dictionary=tab_buttons[key]
		var chosen: bool=key==tab
		var target=spec.button
		# 대기실 '희망 진영' 버튼과 같은 방식: 선택은 금테 보랏빛(lit), 나머지는 다크 메탈.
		target.variant="lit" if chosen else "metal"
		target.accent=T.GOLD if chosen else Color(0.85,0.72,0.47)
		target.queue_redraw()

func _paint_pager() -> void:
	var count:=maxi(1,ceili(float(_items().size())/PER_PAGE))
	page_label.text="%d / %d" % [page+1,count]
	for i in range(page_buttons.size()):
		var target: WooMobileButton=page_buttons[i]
		target.disabled=count<=1
		target.modulate.a=0.45 if count<=1 else 1.0

# ---------------------------------------------------------------- 미리보기
func _rebuild_preview() -> void:
	if is_instance_valid(preview_body):preview_body.queue_free()
	preview_body=Control.new()
	preview_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(preview_body)
	# 20:9에서 origin만큼 밀리지 않도록 미리보기 본문도 디자인 좌표계(0,0) 노드로
	# place한다. 그러면 안쪽 자식은 PANEL_POS 기준 로컬 좌표로 놓이고,
	# layout()이 화면이 바뀔 때 origin을 다시 적용한다.
	place(preview_body,Rect2(0,0,DESIGN_WIDTH,T.DESIGN_HEIGHT))
	var item:=view_item(_raw(selected_id))
	var heading:=label(preview_body,"달빛 미리보기",16,T.gold(.92),true)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(heading,Rect2(PANEL_POS.x+30,PANEL_POS.y+12,PANEL_SIZE.x-60,24))
	var heading_rule:=divider(preview_body,Color(0.85,0.72,0.47,0.22))
	place(heading_rule,Rect2(PANEL_POS.x+26,PANEL_POS.y+40,PANEL_SIZE.x-52,1))
	var pedestal:=Art.Pedestal.new()
	preview_body.add_child(pedestal)
	place(pedestal,Rect2(PANEL_POS.x+4,PANEL_POS.y+22,PANEL_SIZE.x-8,228))
	# 캐릭터·스킨·칭호 모두 실제 캐릭터로 미리 보여 준다.
	var character_id:=_preview_character(item)
	var tint:=Color.WHITE
	if tab=="skin":tint=Color(item.color).lerp(Color.WHITE,.35)
	var figure_holder:=figure(preview_body,character_id,Vector2(214,238),tint)
	place(figure_holder,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-107,PANEL_POS.y+18,214,238))
	if String(item.kind)=="effect":
		var ring:=Art.AuraRing.new()
		ring.color=Color(item.color)
		preview_body.add_child(ring)
		place(ring,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-124,PANEL_POS.y+176,248,100))
	if String(item.kind)=="title":
		var plaque:=Art.Plaque.new()
		preview_body.add_child(plaque)
		place(plaque,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-100,PANEL_POS.y+24,200,70))
		var plate:=label(preview_body,String(item.name),17,T.GOLD_SOFT,true)
		plate.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		plate.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		place(plate,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-92,PANEL_POS.y+44,184,30))
	var name_label:=label(preview_body,String(item.name),28,T.GOLD_SOFT,true)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(name_label,Rect2(PANEL_POS.x+8,PANEL_POS.y+256,PANEL_SIZE.x-16,38))
	var chips:=HBoxContainer.new()
	chips.alignment=BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation",8)
	chips.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(chips)
	place(chips,Rect2(PANEL_POS.x+8,PANEL_POS.y+298,PANEL_SIZE.x-16,26))
	var team_name:="도사" if _team_of(character_id)=="daoist" else "요괴"
	var team_chip:=chip(chips,team_name,T.DAO if team_name=="도사" else T.YOKAI,15,
		Color(0.07,0.05,0.02,1.0) if team_name=="도사" else Color(0.06,0.03,0.10,1.0))
	team_chip.custom_minimum_size=Vector2(58,26)
	var role_chip:=chip(chips,String(item.role),Color(0.12,0.14,0.22,0.92),15,T.MUTED)
	role_chip.custom_minimum_size=Vector2(maxf(76.0,T.FONT.get_string_size(String(item.role),HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+26),26)
	var desc:=label(preview_body,String(item.intro),16,Color(0.82,0.86,0.94))
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(desc,Rect2(PANEL_POS.x+20,PANEL_POS.y+330,PANEL_SIZE.x-40,54))
	var detail:=label(preview_body,_detail_text(item),15,T.gold(.85))
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(detail,Rect2(PANEL_POS.x+18,PANEL_POS.y+388,PANEL_SIZE.x-36,22))
	var line:=divider(preview_body,Color(0.85,0.72,0.47,0.18))
	place(line,Rect2(PANEL_POS.x+24,PANEL_POS.y+416,PANEL_SIZE.x-48,1))
	var state_label:=label(preview_body,_state_text(item),15,T.GOLD_SOFT if _equipped(item) else T.MUTED)
	state_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(state_label,Rect2(PANEL_POS.x+8,PANEL_POS.y+424,PANEL_SIZE.x-16,22))
	# 2.0.21: 대기실 '게임 시작'과 같은 금빛 입체 CTA.
	var cta=RoomButton.new()
	cta.text=_action_text(item)
	cta.variant="gold" if not _equipped(item) else "metal"
	cta.glyph="check" if _owned(item) else "diamond"
	cta.font_size=21
	cta.use_title_font=true
	cta.accent=T.GOLD
	cta.name="ShopAction"
	cta.custom_minimum_size=Vector2(PANEL_SIZE.x-32,54)
	cta.pressed.connect(func()->void:
		if not _equipped(item):_act(item))
	preview_body.add_child(cta)
	place(cta,Rect2(PANEL_POS.x+16,PANEL_POS.y+452,PANEL_SIZE.x-32,54))
	cta.disabled=_equipped(item)
	action_button=cta
	var pay_note:=label(preview_body,"게임 재화 전용 · 인앱결제·광고 없음",14,Color(0.74,0.78,0.88,0.85))
	pay_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(pay_note,Rect2(PANEL_POS.x+8,PANEL_POS.y+512,PANEL_SIZE.x-16,20))

func _raw(id: String) -> Dictionary:
	for item in _items():
		if String(item.id)==id:return item
	var items:=_items()
	return items[0] if not items.is_empty() else {}

func _team_of(id: String) -> String:
	return String(C.find(id).get("team","daoist"))

func _preview_character(item: Dictionary) -> String:
	if tab=="character":return String(item.id)
	return String(game.storage.data.daoist)

func _equipped(item: Dictionary) -> bool:
	match String(item.kind):
		"character":return String(game.storage.data[String(item.team)])==String(item.id)
		"skin":return game.storage.equipped("skin")==String(item.id)
		"title":return game.storage.equipped("title")==String(item.get("item",{}).get("id",""))
		"effect":return game.storage.equipped("effect")==String(item.get("item",{}).get("id",""))
	return false

func _state_text(item: Dictionary) -> String:
	if _equipped(item):return "장착 중 · 경기·로비에 바로 적용됩니다"
	if _owned(item):return "보유 중 · 장착하면 바로 적용됩니다"
	return "해금 %s 코인"%number(int(item.price))

func _detail_text(item: Dictionary) -> String:
	if tab=="character":
		var spec:=C.find(String(item.id))
		return "대표 능력 · %s" % String((spec.get("skill",{}) as Dictionary).get("name",""))
	if tab=="skin":return "미리보기 캐릭터 · %s"%String(C.find(String(game.storage.data.daoist)).get("name",""))
	if String(item.kind)=="title":return "로비 명패와 경기 결과에 표시됩니다"
	return "캐릭터 발밑에 기운이 돕니다"

func _primary(item: Dictionary) -> bool:return true

func _action_text(item: Dictionary) -> String:
	if _equipped(item):return "장착 중"
	if _owned(item):return "장착하기"
	return "해금 · %s 코인"%number(int(item.price))

func _act(item: Dictionary) -> void:
	if _equipped(item):return
	match String(item.kind):
		"character":game.shop_buy_character(String(item.id))
		"skin":game.market_buy(_shop_dict(String(item.id)),"skin")
		"title":game.market_buy(_shop_dict(String(item.id)),"title")
		"effect":game.market_buy(_shop_dict(String(item.id)),"effect")

func _shop_dict(id: String) -> Dictionary:
	for item in _items():
		if String(item.id)==id:return item.get("title",item)
	return {}

func select_item(id: String) -> void:
	selected_id=id
	_paint_cards()
	_rebuild_preview()

func arrange() -> void:
	if page_buttons.size()==2:
		place(page_buttons[0],Rect2(GRID_POS.x+GRID_WIDTH*.5-160,538,42,40))
		place(page_buttons[1],Rect2(GRID_POS.x+GRID_WIDTH*.5+120,538,42,40))
	if is_instance_valid(page_label):
		place(page_label,Rect2(GRID_POS.x+GRID_WIDTH*.5-84,542,168,30))
	if is_instance_valid(grid_hint):
		place(grid_hint,Rect2(GRID_POS.x,578,GRID_WIDTH,22))

## 카드 한 장의 황동 테두리·모서리 장식. 원화 위에 겹쳐 그려 대기실 RoomPanel과
## 같은 상업용 톤을 내고, 선택된 카드는 금빛 발광으로 바뀐다.
class CardFrame extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var edge:=Color(0.85,0.72,0.47,0.40)
	var lit:=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<8.0 or size.y<8.0:return
		var box:=Rect2(Vector2.ZERO,size)
		var r:=10.0
		if lit:
			for i in range(4):
				var grow:=1.0+float(i)*2.2
				T.rounded_outline(self,box.grow(grow),Color(1,.86,.52,.18-float(i)*.035),r+grow,2.2)
		T.rounded_outline(self,box,Color(0,0,0,.42),r,2.0)
		T.rounded_outline(self,box.grow(-1.2),edge,r-1.2,1.6)
		T.rounded_outline(self,box.grow(-4.8),Color(edge.r,edge.g,edge.b,.34 if lit else .14),r-4.8,1.0)
		var arm:=minf(22.0,minf(size.x,size.y)*.17)
		var brass:=Color(edge.r,edge.g,edge.b,minf(1.0,edge.a+.3))
		T.corner_flourish(self,Vector2(2,2),Vector2(1,1),arm,brass)
		T.corner_flourish(self,Vector2(size.x-2,2),Vector2(-1,1),arm,brass)
		T.corner_flourish(self,Vector2(2,size.y-2),Vector2(1,-1),arm,brass)
		T.corner_flourish(self,Vector2(size.x-2,size.y-2),Vector2(-1,-1),arm,brass)
