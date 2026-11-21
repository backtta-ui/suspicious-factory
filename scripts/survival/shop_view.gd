extends "res://scripts/ui/lobby_screen.gd"
## 캐릭터 & 캐릭터 스킨 상점.
## 왼쪽: 탭 + 2×3 황동 베벨 카드 그리드 / 오른쪽: 달빛 아치 단상 위 대형 미리보기.
## 2.0.22: 시안(browser/gpt_shop_ui_v2_full-2026-11-19-015659.png)의 프레임·질감·장식을
## 복제 수준으로 맞춘다. 배경(아치·등불·룬 단상)은 images로 만든 순수 아트만 깔고,
## 글자·배지·버튼은 전부 Godot 노드/벡터로 그려 가짜 글자가 섞이지 않게 한다.
## 인앱결제·광고는 없고, 모든 해금은 경기·업적·우편 보상으로 모은 게임 재화로만 한다.
const O=preload("res://scripts/survival/shop_ornaments.gd")
const RoomButton=preload("res://scripts/ui/metal_button.gd")
const ShopArt=preload("res://assets/woo/shop/preview_arch.jpg")
const ShopGarden=preload("res://assets/woo/shop/garden_bg.jpg")
const TABS=[{"id":"character","label":"캐릭터"},{"id":"skin","label":"스킨"},{"id":"aura","label":"칭호·기운"}]
## 탭 아이콘은 대기실과 같은 벡터 글리프를 쓴다(텍스처 없음 → 어떤 해상도에서도 선명).
const TAB_GLYPHS={"character":"lotus","skin":"flower","aura":"crown"}
const COLS:=3
const ROWS:=2
const PER_PAGE:=COLS*ROWS
## 2.0.22: 시안 비율(카드 204×244, 패널 396×574)로 넓혀 화면을 꽉 채운다.
const GRID_POS:=Vector2(206,92)
const GRID_WIDTH:=640.0
const CARD_GAP:=13.0
const CARD_HEIGHT:=244.0
const PANEL_POS:=Vector2(858,88)
const PANEL_SIZE:=Vector2(396,574)
## 미리보기 패널 안쪽 세로 기준선(패널 좌상단 기준).
const ART_TOP:=46.0
const ART_HEIGHT:=240.0
const NAME_TOP:=292.0
var tab:="character"
var page:=0
## 지갑 알약: 실제 storage 값이 바뀌면(구매·보상 수령) refresh()가 다시 그린다.
var wallet_parts: Array=[]
var selected_id:=""
var cards: Array=[]
var slots: Array=[]
var preview_body: Control
## 미리보기 판(가로가 넓은 20:9 화면에서 오른쪽 끝에 붙인다).
var preview_frame: Control
var action_button: WooMobileButton
var page_label: Label
var page_buttons: Array=[]
var tab_buttons: Dictionary={}
var grid_hint: Label

func build() -> void:
	# 화면 배경: 시안과 같은 달빛 매화 정원 아트(글자·캐릭터 없음).
	if backdrop!=null and backdrop.has_method("use_texture"):
		backdrop.call("use_texture",ShopGarden)
	header("캐릭터 · 스킨 상점","달빛 아래, 도사와 요괴의 차림을 고르세요 · 해금은 게임 재화로만")
	note("보유한 캐릭터와 스킨은 경기·업적·우편 보상으로 모은 코인으로 해금합니다")
	_build_back()
	_build_crest()
	_build_wallet()
	# 좌측 탭: 다크네이비 팔각 판 + 금테(선택 시 금빛 광).
	for i in range(TABS.size()):
		var spec: Dictionary=TABS[i]
		var key: String=spec.id
		var target=O.TabPlate.new()
		target.text=String(spec.label)
		target.glyph=String(TAB_GLYPHS.get(key,"lotus"))
		target.chosen=key==tab
		target.font_size=19
		target.accent=T.GOLD
		target.name="ShopTab_"+key
		add_child(target)
		place(target,Rect2(22,96+i*74,160,62))
		target.pressed.connect(func()->void:set_tab(key))
		tab_buttons[key]={"button":target}
	# 페이지 이동: 시안의 금테 팔각 화살표.
	for spec in [[true,-1],[false,1]]:
		var target:=O.ArrowButton.new()
		target.left=bool(spec[0])
		target.accent=T.GOLD
		target.name="ShopPage_"+("prev" if bool(spec[0]) else "next")
		add_child(target)
		target.pressed.connect(func()->void:turn_page(int(spec[1])))
		page_buttons.append(target)
	page_label=label(self,"1 / 1",17,T.IVORY)
	page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	grid_hint=label(self,"카드를 눌러 오른쪽에서 미리 보세요",15,Color(0.90,0.91,0.96,0.92))
	# 미리보기 판: 먹색 그라데이션 + 황동 모서리 장식(대기실 RoomPanel 톤).
	var frame:=Art.RoomPanel.new()
	frame.fill_top=Color(0.105,0.085,0.170,0.94)
	frame.fill_bottom=Color(0.030,0.026,0.060,0.95)
	frame.radius=14.0
	frame.arm=26.0
	frame.edge=Color(0.85,0.72,0.47,0.72)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	preview_frame=frame
	place(frame,preview_box())
	refresh()

## 2.0.33: 미리보기 판의 실제 배치. 20:9에서는 판을 오른쪽 끝으로 옮긴다.
## 판과 그 안의 내용물(제목·그림·이름·배지·설명·능력·버튼)이 항상 이 한 값을 쓴다.
func preview_box() -> Rect2:
	var dx:=right_edge()-(PANEL_POS.x+PANEL_SIZE.x)
	return Rect2(Vector2(PANEL_POS.x+dx,PANEL_POS.y),PANEL_SIZE)

## 판과 내용물을 같은 기준 x로 맞춘다. 내용물을 다시 그린 뒤에도 반드시 부른다.
func align_preview() -> void:
	var box:=preview_box()
	if is_instance_valid(preview_frame):reshape(preview_frame,box)
	if is_instance_valid(preview_body):
		preview_body.position=origin+Vector2(box.position.x-PANEL_POS.x,0)*s

# ---------------------------------------------------------------- 상단 바
## 뒤로가기: 시안의 다크네이비 팔각 판 + 금테. 기존 상단 뒤로가기와 같은 이름·자리를 쓴다.
func _build_back() -> void:
	if is_instance_valid(back_button):
		# 같은 이름(LobbyBack)으로 새 판을 달아야 하므로 이전 버튼은 트리에서 먼저 뺀다.
		if back_button.get_parent()!=null:back_button.get_parent().remove_child(back_button)
		design.erase(back_button)
		back_button.queue_free()
	var plate=O.TabPlate.new()
	plate.text="뒤로"
	plate.glyph="back"
	plate.font_size=18
	plate.accent=T.GOLD
	plate.name="LobbyBack"
	plate.custom_minimum_size=Vector2.ZERO
	plate.tooltip_text="로비로 돌아가기"
	add_child(plate)
	plate.pressed.connect(func()->void:game.transition("lobby"))
	back_button=plate

## 제목 앞 연꽃 문장(시안의 금테 메달).
func _build_crest() -> void:
	var crest:=O.Medallion.new()
	crest.glyph="lotus"
	crest.accent=T.GOLD
	crest.name="ShopCrest"
	add_child(crest)
	place(crest,Rect2(150,7,40,40))

## 보유 재화: 아이콘이 든 다크네이비 금테 알약 세 개를 오른쪽에 붙인다.
func _build_wallet() -> void:
	if is_instance_valid(wallet_row):wallet_row.visible=false
	for node in wallet_parts:
		if is_instance_valid(node):node.queue_free()
	wallet_parts.clear()
	var title_name:=String(Market.title(game.storage.equipped("title")).name)
	var title_text:=title_name if title_name.begins_with("칭호") else "칭호 · "+title_name
	var specs:Array=[
		["lotus",title_text,Color("9fe8ff")],
		["gem","보석 "+number(int(game.storage.data.gems)),Color("c9a4ff")],
		["coin","코인 "+number(int(game.storage.data.coins)),Color("f4d98a")]]
	var widths:Array=[]
	var total:=0.0
	for spec in specs:
		var width:=O.Pill.measure(String(spec[0]),String(spec[1]),15)
		widths.append(width)
		total+=width+8.0
	var x:=DESIGN_WIDTH-26.0-total+8.0
	for i in range(specs.size()):
		var spec:Array=specs[i]
		var pill:=O.Pill.new()
		pill.text_value=String(spec[1])
		pill.kind=String(spec[0])
		pill.accent=Color(spec[2])
		pill.ink=T.IVORY
		pill.font_size=15
		pill.name="ShopWallet_"+String(spec[0])
		add_child(pill)
		place(pill,Rect2(x,11,float(widths[i]),34))
		wallet_parts.append(pill)
		x+=float(widths[i])+8.0

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

## 항목을 화면 표시용으로 정리한다. item.kind는 카드 종류, item.ability는 미리보기 능력 이름.
func view_item(raw: Dictionary) -> Dictionary:
	if tab=="character":
		var spec:=C.find(String(raw.id))
		var owned: bool=game.storage.owns_character(String(raw.id))
		return {"id":String(raw.id),"kind":"character","name":String(spec.get("name","")),"team":String(spec.get("team","daoist")),
			"role":String(spec.get("role","")),"intro":String(spec.get("intro","")),"portrait":String(spec.get("portrait","")),
			"ability":String((spec.get("skill",{}) as Dictionary).get("name","")),
			"price":int(raw.price),"owned":owned}
	if tab=="skin":
		# 2.0.36: 스킨은 그 캐릭터 전용 의상이다. 미리보기·초상도 그 캐릭터의 전용 원화를 쓴다.
		var owner_id: String=String(raw.get("character",""))
		var owner_spec:=C.find(owner_id)
		return {"id":String(raw.id),"kind":"skin","name":String(raw.name),
			"role":"%s 전용 스킨"%String(owner_spec.get("name","전용")),"intro":String(raw.desc),
			"color":Color(String(raw.get("color","ffffff"))),"ability":String(owner_spec.get("name","전용"))+" 외형",
			"price":int(raw.price),"owned":game.storage.owns(String(raw.id)),
			"character":owner_id,"portrait":String(raw.get("portrait","")),
			"full":String(raw.get("full","")),"sheet":String(raw.get("sheet","")),
			"skin_of":String(raw.get("skin_of","")),"team":String(owner_spec.get("team","daoist"))}
	var item: Dictionary=raw.title
	var kind: String=String(raw.get("kind","title"))
	return {"id":String(raw.id),"kind":kind,"name":String(item.name),"role":"칭호" if kind=="title" else "기운",
		"intro":String(item.desc),"color":Color(String(item.get("color","d9b8ff"))),"price":int(item.price),
		"ability":"칭호 표시" if kind=="title" else "기운 연출",
		"owned":game.storage.owns(String(item.id)) or String(item.id)=="","item":item}

func refresh() -> void:
	if not is_inside_tree():return
	# 구매·보상 수령 뒤에도 상점 지갑이 실제 잔액을 보여 주도록 매번 다시 그린다.
	_build_wallet()
	if selected_id=="":selected_id=_default_id()
	_rebuild_cards()
	_rebuild_preview()
	_paint_tabs()
	_paint_pager()
	_place_wallet_right()

# ---------------------------------------------------------------- 카드 그리드
func _rebuild_cards() -> void:
	for card in cards:
		if is_instance_valid(card):card.queue_free()
	cards.clear()
	for slot in slots:
		if is_instance_valid(slot):slot.queue_free()
	slots.clear()
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
	# 남는 칸은 옅은 점선 프레임으로 채워 격자가 비어 보이지 않게 한다(스킨 탭 등).
	for index in range(PER_PAGE):
		if page*PER_PAGE+index<items.size():continue
		var col:=index%COLS
		var row:=index/COLS
		var rect:=Rect2(GRID_POS.x+col*(card_width+CARD_GAP),GRID_POS.y+row*(CARD_HEIGHT+CARD_GAP),card_width,CARD_HEIGHT)
		var slot:=Panel.new()
		slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
		slot.name="ShopEmpty%d"%index
		slot.add_theme_stylebox_override("panel",T.dashed_box(Color(0.035,0.038,0.075,0.45),Color(0.85,0.72,0.47,0.16),10))
		add_child(slot)
		place(slot,rect)
		var mark:=O.TitleMark.new()
		mark.text_width=0.0
		mark.color=Color(0.85,0.72,0.47,0.22)
		slot.add_child(mark)
		place(mark,Rect2(rect.position.x+rect.size.x*.5-40,rect.position.y+rect.size.y*.5-13,80,26))
		slots.append(slot)
	_paint_cards()

func _make_card(item: Dictionary,rect: Rect2) -> void:
	var id: String=String(item.id)
	var card:=button("",func()->void:select_item(id),self,false,15)
	card.name="ShopCard_"+id.replace(":","_")
	place(card,rect)
	card.clip_contents=true
	# 그림: card의 자식들은 card 안쪽 로컬 좌표(3,3)부터 채운다.
	var art_bottom:=rect.size.y-84.0
	match String(item.kind):
		"character":
			var aura:=TextureRect.new()
			aura.texture=T.GLOW
			aura.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			aura.stretch_mode=TextureRect.STRETCH_SCALE
			aura.modulate=Color(0.78,0.62,1.0,0.30)
			aura.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(aura)
			place(aura,Rect2(rect.position.x-16,rect.position.y-6,rect.size.x+32,art_bottom+26))
			cover_art(card,String(item.portrait),Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,art_bottom-3.0)),0.02)
		"skin":
			# 2.0.36: 도포 색이 아니라 그 캐릭터가 스킨을 입은 모습(전용 원화)을 보여 준다.
			var aura2:=TextureRect.new()
			aura2.texture=T.GLOW
			aura2.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			aura2.stretch_mode=TextureRect.STRETCH_SCALE
			aura2.modulate=Color(1.0,.82,.42,.26)
			aura2.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(aura2)
			place(aura2,Rect2(rect.position.x-16,rect.position.y-6,rect.size.x+32,art_bottom+26))
			# 전용 전신 원화가 있으면 아트를, 없으면 스킨 시트를 입은 인게임 캐릭터를 보여 준다.
			var full_art:=String(item.get("full",""))
			if full_art!="" and ResourceLoader.exists(full_art):
				cover_art(card,full_art,Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,art_bottom-3.0)),0.0)
			else:
				var holder:=figure(card,String(item.get("character",game.storage.data.daoist)),Vector2(rect.size.x-34,art_bottom-30.0),Color.WHITE,String(item.id))
				place(holder,Rect2(rect.position.x+17,rect.position.y+8,rect.size.x-34,art_bottom-30.0))
		"effect":
			var orb:=Art.Orb.new()
			orb.color=Color(item.color)
			card.add_child(orb)
			orb.position=Vector2(rect.size.x*.5-50,10);orb.size=Vector2(100,100)
			var ring:=Art.AuraRing.new()
			ring.color=Color(item.color)
			card.add_child(ring)
			ring.position=Vector2(0,art_bottom-118);ring.size=Vector2(rect.size.x,120)
		"title":
			var plaque:=Art.Plaque.new()
			card.add_child(plaque)
			plaque.position=Vector2(22,8);plaque.size=Vector2(rect.size.x-44,art_bottom-32.0)
			var plate_text:=label(card,String(item.name),24,T.GOLD_SOFT,true)
			plate_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			plate_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			place(plate_text,Rect2(rect.position.x+22,rect.position.y+8,rect.size.x-44,art_bottom-32.0))
	# 이름 띠: 초상화 아래로 어두워지는 그라데이션 위에 글자를 얹는다.
	var veil:=TextureRect.new()
	veil.texture=T.fade_texture(Color(0.030,0.026,0.055,0.0),Color(0.018,0.016,0.040,0.99))
	veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode=TextureRect.STRETCH_SCALE
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(veil)
	veil.position=Vector2(3,art_bottom-46.0)
	veil.size=Vector2(rect.size.x-6,rect.size.y-art_bottom+43.0)
	if String(item.kind)=="skin":
		# 카드 위쪽에 옷감 색을 얇은 금테 띠로 표시한다.
		var band:=Panel.new()
		band.mouse_filter=Control.MOUSE_FILTER_IGNORE
		band.add_theme_stylebox_override("panel",T.panel_box(Color(item.color).lerp(Color.WHITE,.10),3,T.gold(.7),1))
		card.add_child(band)
		place(band,Rect2(rect.position.x+16,rect.position.y+art_bottom-8.0,rect.size.x-32,4))
	# 칭호 카드는 명패 안에 이름을 크게 쓰므로 아래 띠에서는 이름을 되풀이하지 않는다.
	var band_name:=String(item.name) if String(item.kind)!="title" else String(item.role)
	var name_label:=label(card,band_name,23 if String(item.kind)!="title" else 19,T.IVORY,true)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_constant_override("outline_size",2)
	name_label.add_theme_constant_override("shadow_offset_y",1)
	name_label.add_theme_color_override("font_shadow_color",Color(0,0,0,.5))
	place(name_label,Rect2(rect.position.x+8,rect.position.y+rect.size.y-84.0,rect.size.x-16,32))
	if String(item.kind)!="title":
		var sub_label:=label(card,String(item.role),14,T.MUTED)
		sub_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		place(sub_label,Rect2(rect.position.x+8,rect.position.y+rect.size.y-48.0,rect.size.x-16,16))
	_make_card_state(card,item,rect,item)
	# 도/요 원형 배지와 황동 베벨 프레임은 원화 위에 마지막으로 얹는다.
	if String(item.kind)=="character" or String(item.kind)=="skin":
		var badge:=O.TeamBadge.new()
		var daoist:=String(item.get("team","daoist"))=="daoist" if String(item.kind)=="character" else true
		badge.letter="도" if daoist else "요"
		badge.daoist=daoist
		badge.name="ShopBadge"
		card.add_child(badge)
		place(badge,Rect2(rect.position.x+11,rect.position.y+11,27,27))
	var frame:=O.CardFrame.new()
	frame.edge=Color(0.85,0.72,0.47,0.55)
	card.add_child(frame)
	place(frame,Rect2(rect.position,rect.size))
	card.set_meta("name_label",name_label)
	card.set_meta("frame",frame)
	card.set_meta("id",id)
	cards.append(card)

## 카드 아래 가격·상태. 잠긴 카드는 시안처럼 금테 알약 안에 금화 + 숫자.
## 2.0.22: 캐릭터는 매칭 수락 후 선택창에서 고르므로 상점에서 '장착'을 쓰지 않는다.
func _make_card_state(card: Control,item: Dictionary,rect: Rect2,_raw_item: Dictionary) -> void:
	var text_value:=""
	var with_coin:=false
	if String(item.kind)=="character":
		if _owned(item):
			text_value="보유"
		else:
			text_value=str(int(item.price))
			with_coin=true
	elif _equipped(item):
		text_value="장착 중"
	elif _owned(item):
		text_value="보유"
	else:
		text_value=str(int(item.price))
		with_coin=true
	var extent:=16.0
	var top:=rect.position.y+rect.size.y-27.0
	var text_w:=T.FONT.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x
	if with_coin:
		var coin_w:=16.0
		var gap:=6.0
		var inner:=text_w+coin_w+gap
		var pill_w:=inner+22.0
		var pill_h:=23.0
		var left:=rect.position.x+(rect.size.x-pill_w)*.5
		var pill:=Panel.new()
		pill.mouse_filter=Control.MOUSE_FILTER_IGNORE
		pill.add_theme_stylebox_override("panel",T.panel_box(Color(0.02,0.02,0.05,0.55),pill_h*.5,T.gold(.42),1))
		card.add_child(pill)
		place(pill,Rect2(left,top,pill_w,pill_h))
		var coin:=O.Coin.new()
		coin.name="ShopCardCoin"
		card.add_child(coin)
		place(coin,Rect2(left+11.0,top+(pill_h-coin_w)*.5,coin_w,coin_w))
		var price_label:=label(card,text_value,extent,T.GOLD_SOFT)
		price_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		price_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		place(price_label,Rect2(left+11.0+coin_w+gap,top-1.0,text_w+4.0,pill_h+2.0))
		card.set_meta("state_label",price_label)
		return
	# 보유/장착 상태는 가는 금선 없이 한 줄로 또렷하게(글자와 선이 겹치지 않게).
	var plain:=label(card,text_value,extent,T.GOLD_SOFT if text_value=="장착 중" else Color(0.90,0.91,0.96))
	plain.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	plain.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	place(plain,Rect2(rect.position.x+8,top-1.0,rect.size.x-16,24))
	card.set_meta("state_label",plain)

func _owned(item: Dictionary) -> bool:
	return bool(item.get("owned",false))

func _paint_cards() -> void:
	for card in cards:
		if not is_instance_valid(card):continue
		var chosen: bool=String(card.get_meta("id"))==selected_id
		var box:=T.panel_box(Color(0.05,0.045,0.09,0.96),10,T.gold(.75 if chosen else .35),1,T.gold(.45) if chosen else Color(0,0,0,0),16 if chosen else 0)
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			card.add_theme_stylebox_override(state,box)
		var frame: Control=card.get_meta("frame")
		if frame!=null:
			frame.edge=Color(0.98,0.86,0.56,0.95) if chosen else Color(0.85,0.72,0.47,0.55)
			frame.lit=chosen
			frame.queue_redraw()
		var name_label: Label=card.get_meta("name_label")
		if name_label!=null:name_label.add_theme_color_override("font_color",Color("ffeec8") if chosen else T.IVORY)
		card.modulate=Color(1.03,1.02,1.0) if chosen else Color(0.93,0.94,1.0)

func _paint_tabs() -> void:
	for key in tab_buttons:
		var spec: Dictionary=tab_buttons[key]
		var target=spec.button
		target.chosen=String(key)==tab
		target.accent=T.GOLD
		target.queue_redraw()

func _paint_pager() -> void:
	var count:=maxi(1,ceili(float(_items().size())/PER_PAGE))
	page_label.text="%d / %d" % [page+1,count]
	for i in range(page_buttons.size()):
		var target: Button=page_buttons[i]
		target.disabled=count<=1
		target.modulate.a=0.45 if count<=1 else 1.0
		target.queue_redraw()

# ---------------------------------------------------------------- 미리보기
func _rebuild_preview() -> void:
	if is_instance_valid(preview_body):preview_body.queue_free()
	preview_body=Control.new()
	preview_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(preview_body)
	place(preview_body,Rect2(0,0,DESIGN_WIDTH,T.DESIGN_HEIGHT))
	var item:=view_item(_raw(selected_id))
	# ── 제목 '◇ 달빛 미리보기 ◇'
	var title_text:="달빛 미리보기"
	var mark:=O.TitleMark.new()
	mark.text_width=T.TITLE_FONT.get_string_size(title_text,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x
	preview_body.add_child(mark)
	place(mark,Rect2(PANEL_POS.x+8,PANEL_POS.y+12,PANEL_SIZE.x-16,26))
	var heading:=label(preview_body,title_text,19,T.gold(.94),true)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(heading,Rect2(PANEL_POS.x+30,PANEL_POS.y+12,PANEL_SIZE.x-60,26))
	var heading_rule:=divider(preview_body,Color(0.85,0.72,0.47,0.26))
	place(heading_rule,Rect2(PANEL_POS.x+26,PANEL_POS.y+42,PANEL_SIZE.x-52,1))
	# ── 달빛 아치 + 등불 + 룬 단상 아트(글자·캐릭터 없는 배경 전용 이미지)
	var art:=TextureRect.new()
	art.texture=ShopArt
	art.modulate=Color(1.06,1.02,1.10)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(art)
	place(art,Rect2(PANEL_POS.x+5,PANEL_POS.y+ART_TOP,PANEL_SIZE.x-10,ART_HEIGHT))
	# 아트 위를 살짝 눌러 글자 대비를 확보하고, 아래쪽은 판 색으로 자연스럽게 녹인다.
	var veil:=ColorRect.new()
	veil.color=Color(0.05,0.03,0.10,0.10)
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(veil)
	place(veil,Rect2(PANEL_POS.x+5,PANEL_POS.y+ART_TOP,PANEL_SIZE.x-10,ART_HEIGHT))
	var top_fade:=TextureRect.new()
	top_fade.texture=T.fade_texture(Color(0.055,0.042,0.10,0.85),Color(0.055,0.042,0.10,0.0))
	top_fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	top_fade.stretch_mode=TextureRect.STRETCH_SCALE
	top_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(top_fade)
	place(top_fade,Rect2(PANEL_POS.x+5,PANEL_POS.y+ART_TOP,PANEL_SIZE.x-10,22))
	var fade:=TextureRect.new()
	fade.texture=T.fade_texture(Color(0.032,0.026,0.062,0.0),Color(0.032,0.026,0.062,0.99))
	fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode=TextureRect.STRETCH_SCALE
	fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(fade)
	place(fade,Rect2(PANEL_POS.x+5,PANEL_POS.y+ART_TOP+ART_HEIGHT-40.0,PANEL_SIZE.x-10,42))
	# ── 캐릭터(실제 인게임 아트)가 단상 위에 선다
	var character_id:=_preview_character(item)
	var tint:=Color.WHITE
	if tab=="skin":tint=Color.WHITE
	if String(item.kind)=="effect":
		var ring:=Art.AuraRing.new()
		ring.color=Color(item.color)
		preview_body.add_child(ring)
		place(ring,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-124,PANEL_POS.y+168,248,100))
	var figure_holder:=figure(preview_body,character_id,Vector2(190,188),tint)
	place(figure_holder,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-95,PANEL_POS.y+60,190,188))
	if String(item.kind)=="title":
		var plaque:=Art.Plaque.new()
		preview_body.add_child(plaque)
		place(plaque,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-100,PANEL_POS.y+64,200,72))
		var plate:=label(preview_body,String(item.name),17,T.GOLD_SOFT,true)
		plate.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		plate.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		place(plate,Rect2(PANEL_POS.x+PANEL_SIZE.x*.5-92,PANEL_POS.y+84,184,32))
	# ── 이름 + 양옆 깃털선
	var name_text:=String(item.name)
	var wings:=O.NameWings.new()
	wings.text_width=T.TITLE_FONT.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,31).x
	wings.color=T.gold(.92)
	preview_body.add_child(wings)
	place(wings,Rect2(PANEL_POS.x+8,PANEL_POS.y+NAME_TOP-3.0,PANEL_SIZE.x-16,38))
	var name_label:=label(preview_body,name_text,31,T.GOLD_SOFT,true)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(name_label,Rect2(PANEL_POS.x+8,PANEL_POS.y+NAME_TOP,PANEL_SIZE.x-16,38))
	# ── 진영·역할 배지(시안: 연꽃 든 '도사' + 어두운 '지원·구조')
	var team_name:="도사" if _team_of(character_id)=="daoist" else "요괴"
	var team_accent:=T.DAO if team_name=="도사" else T.YOKAI
	var role_text:=String(item.role)
	var team_w:=O.Pill.measure("lotus",team_name,16)
	var role_w:=O.Pill.measure("none",role_text,16)
	var badge_top:=PANEL_POS.y+326.0
	var badge_x:=PANEL_POS.x+(PANEL_SIZE.x-(team_w+8.0+role_w))*.5
	var team_pill:=O.Pill.new()
	team_pill.text_value=team_name
	team_pill.kind="lotus"
	team_pill.accent=team_accent
	team_pill.ink=T.GOLD_SOFT if team_name=="도사" else Color(0.94,0.88,1.0)
	team_pill.font_size=16
	team_pill.glow=true
	preview_body.add_child(team_pill)
	place(team_pill,Rect2(badge_x,badge_top,team_w,28))
	var role_pill:=O.Pill.new()
	role_pill.text_value=role_text
	role_pill.kind="none"
	role_pill.accent=T.GOLD
	role_pill.ink=Color(0.86,0.88,0.96)
	role_pill.font_size=16
	preview_body.add_child(role_pill)
	place(role_pill,Rect2(badge_x+team_w+8.0,badge_top,role_w,28))
	# ── 소개 문구
	var desc:=label(preview_body,String(item.intro),16,Color(0.86,0.89,0.96))
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	place(desc,Rect2(PANEL_POS.x+22,PANEL_POS.y+360,PANEL_SIZE.x-44,32))
	# ── 대표 능력 (보랏빛 룬 메달 + 금빛 값)
	var ability:=String(item.get("ability",""))
	var detail_rule:=O.PanelRule.new()
	preview_body.add_child(detail_rule)
	place(detail_rule,Rect2(PANEL_POS.x+26,PANEL_POS.y+396,PANEL_SIZE.x-52,10))
	var lead:="대표 능력"
	var seal:=O.RuneSeal.new()
	preview_body.add_child(seal)
	var lead_w:=T.FONT.get_string_size(lead,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	var value_w:=T.FONT.get_string_size(ability,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	var detail_w:=30.0+10.0+lead_w+13.0+value_w
	var detail_x:=PANEL_POS.x+(PANEL_SIZE.x-detail_w)*.5
	place(seal,Rect2(detail_x,PANEL_POS.y+401,30,30))
	var lead_label:=label(preview_body,lead,16,Color(0.92,0.93,0.97))
	lead_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	place(lead_label,Rect2(detail_x+40.0,PANEL_POS.y+402,lead_w+2.0,28))
	var bar:=divider(preview_body,T.gold(.55))
	place(bar,Rect2(detail_x+40.0+lead_w+5.0,PANEL_POS.y+409,1.0,14))
	var value_label:=label(preview_body,ability,16,T.GOLD_SOFT)
	value_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	place(value_label,Rect2(detail_x+40.0+lead_w+12.0,PANEL_POS.y+402,value_w+6.0,28))
	# ── 상태 문구
	var state_label:=label(preview_body,_state_text(item),15,T.GOLD_SOFT if _shop_equipped(item) else Color(0.90,0.92,0.97))
	state_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	state_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(state_label,Rect2(PANEL_POS.x+18,PANEL_POS.y+434,PANEL_SIZE.x-36,38))
	# ── 육각 베벨 금빛 CTA
	var cta=O.HexButton.new()
	cta.text=_action_text(item)
	if String(item.kind)=="character":
		cta.icon_kind="check" if _owned(item) else "coin"
	else:
		cta.icon_kind="hanger" if _owned(item) or _equipped(item) else "coin"
	cta.font_size=24
	cta.use_title_font=true
	cta.accent=T.GOLD
	cta.name="ShopAction"
	preview_body.add_child(cta)
	game.button_feel(cta)
	cta.disabled=_cta_disabled(item)
	cta.pressed.connect(func()->void:
		if not _cta_disabled(item):_act(item))
	action_button=cta
	# 2.0.32 보석으로도 해금할 수 있는 항목은 CTA 아래에 보석 가격 버튼을 하나 더 둔다.
	var gem_price:=Market.gem_price(_raw(selected_id)) if not _owned(item) and not _equipped(item) else 0
	if gem_price>0:
		place(cta,Rect2(PANEL_POS.x+14,PANEL_POS.y+468,PANEL_SIZE.x-28,48))
		var gem_cta: WooMobileButton=button("보석 %s로 해금"%number(gem_price),func()->void:_act_gem(item),preview_body,false,16)
		gem_cta.name="ShopGemAction"
		place(gem_cta,Rect2(PANEL_POS.x+88,PANEL_POS.y+520,PANEL_SIZE.x-176,34))
		var gem_note:=label(preview_body,"보석은 경기 승리·우편 보상으로만 얻습니다",12.5,Color(0.82,0.74,0.98,0.9))
		gem_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		place(gem_note,Rect2(PANEL_POS.x+8,PANEL_POS.y+556,PANEL_SIZE.x-16,18))
	else:
		place(cta,Rect2(PANEL_POS.x+14,PANEL_POS.y+476,PANEL_SIZE.x-28,54))
		var pay_note:=label(preview_body,"게임 재화 전용",15,Color(0.78,0.80,0.90,0.86))
		pay_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		place(pay_note,Rect2(PANEL_POS.x+8,PANEL_POS.y+536,PANEL_SIZE.x-16,22))
	# 제목부터 버튼까지 다 놓은 뒤, 판과 같은 기준 x로 맞춘다(캐릭터를 누를 때마다 다시 그린다).
	align_preview()

func _raw(id: String) -> Dictionary:
	for item in _items():
		if String(item.id)==id:return item
	var items:=_items()
	return items[0] if not items.is_empty() else {}

func _team_of(id: String) -> String:
	return String(C.find(id).get("team","daoist"))

func _preview_character(item: Dictionary) -> String:
	if tab=="character":return String(item.id)
	if tab=="skin":return String(item.get("character",game.storage.data.daoist))
	return String(game.storage.data.daoist)

func _equipped(item: Dictionary) -> bool:
	match String(item.kind):
		"character":return String(game.storage.data[String(item.team)])==String(item.id)
		"skin":return game.storage.equipped("skin")==String(item.id)
		"title":return game.storage.equipped("title")==String(item.get("item",{}).get("id",""))
		"effect":return game.storage.equipped("effect")==String(item.get("item",{}).get("id",""))
	return false

## 캐릭터는 상점에서 장착하지 않는다(경기 수락 후 선택창에서 고른다).
func _shop_equipped(item: Dictionary) -> bool:
	if String(item.kind)=="character":return false
	return _equipped(item)

func _state_text(item: Dictionary) -> String:
	if String(item.kind)=="character":
		if _owned(item):return "보유 중 · 매칭 후 캐릭터 선택창에서 고를 수 있습니다"
		return "미보유 · %s 코인으로 해금할 수 있습니다"%number(int(item.price))
	if _equipped(item):return "장착 중 · 경기·로비에 바로 적용됩니다"
	if _owned(item):return "보유 중 · 장착하면 바로 적용됩니다"
	var gems:=Market.gem_price(_raw(selected_id))
	if gems>0:return "해금 %s 코인 또는 보석 %s" % [number(int(item.price)),number(gems)]
	return "해금 %s 코인" % number(int(item.price))

func _action_text(item: Dictionary) -> String:
	if String(item.kind)=="character":
		return "보유 중" if _owned(item) else "해금하기"
	if _equipped(item):return "장착 중"
	if _owned(item):return "장착하기"
	return "해금 · %s" % number(int(item.price))

## 오른쪽 CTA를 누를 수 없는 상태인지(이미 보유한 캐릭터·장착 중인 스킨/칭호).
func _cta_disabled(item: Dictionary) -> bool:
	if String(item.kind)=="character":return _owned(item)
	return _equipped(item)

func _act(item: Dictionary) -> void:
	if _cta_disabled(item):return
	match String(item.kind):
		"character":game.shop_unlock_character(String(item.id))
		"skin":game.market_buy(_shop_dict(String(item.id)),"skin")
		"title":game.market_buy(_shop_dict(String(item.id)),"title")
		"effect":game.market_buy(_shop_dict(String(item.id)),"effect")

## 보석 가격으로 해금(코인 대신 storage.data.gems에서 차감).
## 지갑 알약을 오른쪽 끝에 맞춘다(넓은 화면에서 가운데에 떠 있지 않게).
func _place_wallet_right() -> void:
	if wallet_parts.is_empty():return
	var total:=0.0
	var widths: Array=[]
	for pill in wallet_parts:
		if not is_instance_valid(pill):continue
		var width:=O.Pill.measure(String(pill.get("kind")),String(pill.get("text_value")),15)
		widths.append(width);total+=width+8.0
	var x:=right_edge()-total+8.0
	for i in range(wallet_parts.size()):
		var pill: Control=wallet_parts[i]
		if not is_instance_valid(pill):continue
		reshape(pill,Rect2(x,11,float(widths[i]),34))
		x+=float(widths[i])+8.0

func _act_gem(item: Dictionary) -> void:
	match String(item.kind):
		"skin":game.market_buy(_shop_dict(String(item.id)),"skin","gem")
		"title":game.market_buy(_shop_dict(String(item.id)),"title","gem")
		"effect":game.market_buy(_shop_dict(String(item.id)),"effect","gem")

func _shop_dict(id: String) -> Dictionary:
	for item in _items():
		if String(item.id)==id:return item.get("title",item)
	return {}

func select_item(id: String) -> void:
	selected_id=id
	_paint_cards()
	_rebuild_preview()

func arrange() -> void:
	# 2.0.32: 가로가 넓으면(20:9) 미리보기 판·지갑을 화면 오른쪽 끝에 붙인다(2.0.33: 판과 내용물을 같은 함수로).
	align_preview()
	_place_wallet_right()
	# 제목은 시안처럼 연꽃 문장 오른쪽에서 시작한다.
	if is_instance_valid(title_label):
		title_label.position=origin+Vector2(198,2)*s
		title_label.size=Vector2(520,52)*s
		title_label.add_theme_font_size_override("font_size",maxi(14,int(36.0*s)))
	if is_instance_valid(subtitle_label):
		subtitle_label.position=origin+Vector2(200,50)*s
		subtitle_label.size=Vector2(560,24)*s
	if page_buttons.size()==2:
		place(page_buttons[0],Rect2(GRID_POS.x+GRID_WIDTH*.5-160,601,40,38))
		place(page_buttons[1],Rect2(GRID_POS.x+GRID_WIDTH*.5+120,601,40,38))
	if is_instance_valid(page_label):
		place(page_label,Rect2(GRID_POS.x+GRID_WIDTH*.5-84,604,168,30))
	if is_instance_valid(grid_hint):
		place(grid_hint,Rect2(GRID_POS.x,646,GRID_WIDTH,22))
