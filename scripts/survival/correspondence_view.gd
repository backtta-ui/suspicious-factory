extends "res://scripts/ui/lobby_screen.gd"
## 2.0.25 우편함 — 시안(월하의 서원 우편함) 복제.
## 왼쪽: 금테 레일(우편/알림) + 봉인된 편지 목록 카드, 오른쪽: 한지 두루마리에 먹글씨 본문과
## 동봉 보상 타일·금빛 촉 수령 버튼. 읽음·수령 상태는 실제 저장과 연결된다.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const RAIL:=Rect2(18,138,140,196)
const LIST:=Rect2(174,82,500,596)
const CARD_H:=106.0
const CARD_GAP:=10.0
const SHEET_Y:=76.0
const SHEET_H:=600.0
const INK=Color("2c2115")
const INK_SOFT=Color("5b4834")
var tab:="mail"
var initial:="mail"
var selected_id:=""
var items: Array=[]
var paper: Control
var paper_frame: NinePatchRect
var tabs: Dictionary={}
var side_buttons: Dictionary={}
var sheet_js: Array=[]

func build() -> void:
	tab=initial
	header("우편" if tab=="mail" else "알림","조선으로 도착한 편지와 중요 안내를 확인하세요","mail")
	for index in range(2):
		var spec: Array=[["mail","우편","mail"],["alerts","알림","spark"]][index]
		var key: String=spec[0]
		var target:=V.Tab.new()
		target.text=String(spec[1])
		target.glyph=String(spec[2])
		target.font_size=19
		target.name="LetterTab_"+key
		target.custom_minimum_size=Vector2.ZERO
		target.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		target.pressed.connect(func()->void:
			if target.usable():game.sound.play_clip("button");switch_tab(key))
		add_child(target)
		game.button_feel(target)
		tabs[key]=target
	var list_frame:=V.frame(self,Rect2(0,0,1,1))
	list_frame.name="MailListFrame"
	place(list_frame,LIST)
	paper=_paper()
	refresh()

func _paper() -> Control:
	var node:=Control.new()
	node.name="MailPaper"
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(node)
	paper_frame=V.patch(node,V.TEX_PARCHMENT,Rect2(0,0,1,1),42)
	paper_frame.name="MailSheet"
	# 오른쪽 위 매화 가지 장식
	var branch:=TextureRect.new()
	branch.texture=V.TEX_BRANCH
	branch.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	branch.stretch_mode=TextureRect.STRETCH_SCALE
	branch.modulate=Color(1,1,1,.95)
	branch.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_child(branch)
	branch.set_meta("deco","branch")
	# 왼쪽 위 매듭 술
	var tassel:=TextureRect.new()
	tassel.texture=V.TEX_TASSEL
	tassel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tassel.stretch_mode=TextureRect.STRETCH_SCALE
	tassel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_child(tassel)
	tassel.set_meta("deco","tassel")
	var seal:=SealStamp.new()
	seal.tint=Color(.62,.20,.18)
	node.add_child(seal)
	seal.name="PaperSeal"
	seal.set_meta("content",true)
	return node

func switch_tab(key: String) -> void:
	if key==tab:return
	tab=key
	selected_id=""
	title_label.text="우편" if tab=="mail" else "알림"
	subtitle_label.text="조선으로 도착한 편지와 중요 안내를 확인하세요" if tab=="mail" else "조선의 공지와 새 소식을 확인하세요"
	refresh()

func _list() -> Array:
	return Market.MAILS if tab=="mail" else Market.ALERTS

func _read_key() -> String:
	return "mail" if tab=="mail" else "alerts"

func refresh() -> void:
	_paint_tabs()
	for item in items:
		if is_instance_valid(item):item.queue_free()
	items.clear()
	if selected_id=="":
		var list:=_list()
		if not list.is_empty():selected_id=String(list[0].id)
	var index:=0
	for entry in _list():
		_make_card(entry,index)
		index+=1
	_paint_sheet()

func _paint_tabs() -> void:
	for key in tabs:
		var target: V.Tab=tabs[key]
		target.paint(key==tab)
	for spec in [["mail",Market.MAILS,"mail"],["alerts",Market.ALERTS,"alerts"]]:
		var unread:=0
		for entry in spec[1]:
			if not (game.storage.data[spec[2]].read as Array).has(String(entry.id)):unread+=1
		var target: V.Tab=tabs[spec[0]]
		var previous: Node=target.get_node_or_null("UnreadBadge")
		if unread<=0:
			if previous!=null:previous.queue_free()
			continue
		var badge: TextureRect=previous
		if badge==null:
			badge=TextureRect.new()
			badge.name="UnreadBadge"
			badge.texture=V.TEX_BADGE
			badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			badge.stretch_mode=TextureRect.STRETCH_SCALE
			badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
			target.add_child(badge)
		var extent:=minf(target.size.y*.30,22.0*s)
		badge.size=Vector2(extent,extent)
		badge.position=Vector2(target.size.x-extent*1.4,extent*.25)

## 봉인된 편지 카드 — 시안처럼 봉투 그림 · 제목 · 발신/상태 · 선물 표시.
func _make_card(entry: Dictionary,index: int) -> void:
	var id:=String(entry.id)
	var rect:=Rect2(LIST.position.x+10,LIST.position.y+62+index*(CARD_H+CARD_GAP),LIST.size.x-20,CARD_H)
	var card:=button("",func()->void:open_item(id),self,false,15)
	card.name="Letter_"+id
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		card.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
		card.add_theme_color_override(state,Color(0,0,0,0))
	card.text=""
	place(card,rect)
	var chosen: bool=id==selected_id
	if chosen:
		var glow:=UIK.Glow.new()
		glow.color=Color(1,.82,.44)
		glow.radius=14.0*s
		glow.strength=1.0
		card.add_child(glow)
		glow.position=Vector2(-2,-2)*s
		glow.size=rect.size*s+Vector2(4,4)*s
	var frame:=V.patch(card,V.TEX_CARD_LIT if chosen else V.TEX_CARD,Rect2(Vector2.ZERO,rect.size),26)
	frame.name="CardFrame"
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	var icon:=TextureRect.new()
	icon.texture=V.TEX_ICON_LETTER
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	icon.position=Vector2(12,rect.size.y*.5-27)*s
	icon.size=Vector2(68,54)*s
	if tab=="mail" and not claimed:
		var gift:=TextureRect.new()
		gift.texture=V.TEX_ICON_GIFT
		gift.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		gift.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gift.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(gift)
		gift.position=Vector2(rect.size.x-46,rect.size.y*.5-15)*s
		gift.size=Vector2(32,32)*s
	var title:=label(card,String(entry.title),18.5,V.GOLD_BRIGHT if chosen else V.IVORY,true)
	title.clip_text=true
	title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	place(title,Rect2(LIST.position.x+94,rect.position.y+16,rect.size.x-146,28))
	var role_text: String="조선의 편지" if tab=="mail" else "조선의 공지"
	var status_text: String="수령 가능" if tab=="mail" and not claimed else ("수령 완료" if tab=="mail" else "새 소식")
	if read:status_text=("읽음" if tab=="mail" else "확인함")
	var meta:=label(card,role_text,16,Color(.86,.80,.94))
	place(meta,Rect2(LIST.position.x+94,rect.position.y+50,170,22))
	var bar:=label(card,"|",16,Color(.86,.80,.94))
	place(bar,Rect2(LIST.position.x+94+108,rect.position.y+50,10,22))
	var status:=label(card,status_text,16,Color(1,.84,.52))
	place(status,Rect2(LIST.position.x+94+126,rect.position.y+50,160,22))
	# 아래 구분선
	var under:=divider(card,Color(.85,.72,.47,.22))
	place(under,Rect2(LIST.position.x+94,rect.position.y+80,rect.size.x-120,1))
	items.append(card)

func open_item(id: String) -> void:
	selected_id=id
	if tab=="mail":
		for entry in Market.MAILS:
			if String(entry.id)==id:game.open_mail(entry)
	else:
		for entry in Market.ALERTS:
			if String(entry.id)==id:game.read_alert(entry)
	refresh()

func focus_item(id: String) -> void:
	selected_id=id
	refresh()

## 오른쪽 한지 두루마리 — 붉은 낙관 · 제목 · 본문 · 동봉 보상 타일 · 금빛 수령 버튼.
func _paint_sheet() -> void:
	for child in paper.get_children():
		if child.has_meta("content"):child.queue_free()
	var entry: Dictionary={}
	for candidate in _list():
		if String(candidate.id)==selected_id:entry=candidate
	if entry.is_empty():return
	var area:=paper_rect()
	var id:=String(entry.id)
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	var seal: Control=paper.get_node_or_null("PaperSeal")
	if seal!=null:
		seal.set_meta("content",true)
		place(seal,Rect2(area.position.x+area.size.x-92,area.position.y+30,44,44))
		seal.queue_redraw()
	var title:=label(paper,String(entry.title),28,INK,true)
	title.set_meta("content",true)
	place(title,Rect2(area.position.x+40,area.position.y+30,area.size.x-150,38))
	var meta_text: String="보내는 이 : 서원의 편지" if tab=="mail" else "보내는 이 : 서원의 공지"
	var meta:=label(paper,meta_text,15,INK_SOFT)
	meta.set_meta("content",true)
	place(meta,Rect2(area.position.x+42,area.position.y+74,area.size.x-160,20))
	var line:=gold_divider(paper,Rect2(area.position.x+30,area.position.y+100,area.size.x-60,12))
	line.set_meta("content",true)
	var body_text:=String(entry.get("body",""))
	var body:=label(paper,body_text,19,Color(.19,.14,.09))
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	body.add_theme_constant_override("line_spacing",14)
	body.set_meta("content",true)
	var body_w:=area.size.x-84
	var per_line:=maxi(8,int(body_w/(19.0*1.02)))
	var lines:=maxi(1,int(ceil(float(body_text.length())/float(per_line))))
	var body_h:=float(lines)*19.0*1.62+8.0
	place(body,Rect2(area.position.x+42,area.position.y+116,body_w,body_h))
	var lower:=area.position.y+116.0+body_h+34.0
	lower=minf(lower,area.position.y+area.size.y-226.0)
	var signature:=label(paper,"— 조선 지기",14,Color(.40,.30,.20),true)
	signature.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	signature.set_meta("content",true)
	place(signature,Rect2(area.position.x+area.size.x-310,lower-58,260,22))
	var caption: Label=label(paper,"동봉된 보상",16,INK_SOFT,true)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.set_meta("content",true)
	place(caption,Rect2(area.position.x+40,lower,area.size.x-80,22))
	var caption_line:=divider(paper,Color(.52,.38,.20,.40))
	caption_line.set_meta("content",true)
	place(caption_line,Rect2(area.position.x+60,lower+24,area.size.x-120,1))
	if tab=="mail":
		var tile:=V.patch(paper,V.TEX_TILE,Rect2(Vector2.ZERO,Vector2(110,110)),30)
		tile.set_meta("content",true)
		place(tile,Rect2(area.position.x+44,lower+42,110,110))
		var coin:=TextureRect.new()
		coin.texture=V.TEX_ICON_COIN
		coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		paper.add_child(coin)
		coin.set_meta("content",true)
		place(coin,Rect2(area.position.x+70,lower+48,58,58))
		var amount:=label(paper,"×%s"%number(int(entry.reward)),16,V.GOLD_BRIGHT,true)
		amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		amount.set_meta("content",true)
		place(amount,Rect2(area.position.x+40,lower+108,118,24))
		var coin_caption:=label(paper,"코인",12.5,Color(.84,.74,.56))
		coin_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		coin_caption.set_meta("content",true)
		place(coin_caption,Rect2(area.position.x+40,lower+134,118,18))
		# 2.0.32: 함께 동봉된 보석도 실제 지갑에 들어가므로 무루에 함께 보여 준다.
		var gem_amount:=Market.mail_gems(entry)
		if gem_amount>0:
			var gem_tile:=V.patch(paper,V.TEX_TILE,Rect2(Vector2.ZERO,Vector2(110,110)),30)
			gem_tile.set_meta("content",true)
			place(gem_tile,Rect2(area.position.x+170,lower+42,110,110))
			var gem:=TextureRect.new()
			gem.texture=V.TEX_ICON_GEM
			gem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			gem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			gem.mouse_filter=Control.MOUSE_FILTER_IGNORE
			paper.add_child(gem)
			gem.set_meta("content",true)
			place(gem,Rect2(area.position.x+196,lower+48,58,58))
			var gem_text:=label(paper,"×%s"%number(gem_amount),16,Color("d9b8ff"),true)
			gem_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			gem_text.set_meta("content",true)
			place(gem_text,Rect2(area.position.x+166,lower+108,118,24))
			var gem_caption:=label(paper,"보석",12.5,Color(.80,.66,.92))
			gem_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			gem_caption.set_meta("content",true)
			place(gem_caption,Rect2(area.position.x+166,lower+134,118,18))
		var claim:=V.PlateButton.new()
		claim.kind="gold"
		claim.text="보상 수령 완료" if claimed else "보상 수령"
		claim.glyph="check" if claimed else "seal"
		claim.font_size=21
		claim.name="MailClaim"
		claim.custom_minimum_size=Vector2.ZERO
		claim.disabled=claimed
		claim.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		claim.pressed.connect(func()->void:
			if claim.usable():
				game.sound.play_clip("button");game.claim_mail(entry))
		claim.set_meta("content",true)
		paper.add_child(claim)
		place(claim,Rect2(area.position.x+area.size.x-292,lower+58,256,62))
		game.button_feel(claim)
		var hint:=label(paper,"보상은 한 번만 받을 수 있습니다.",12.5,Color(.44,.34,.24,.9))
		hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		hint.set_meta("content",true)
		place(hint,Rect2(area.position.x+24,lower+132,area.size.x-330,18))
	else:
		var confirm:=V.PlateButton.new()
		confirm.kind="gold"
		confirm.text="읽음 표시"
		confirm.glyph="check"
		confirm.font_size=21
		confirm.custom_minimum_size=Vector2.ZERO
		confirm.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		confirm.pressed.connect(func()->void:
			if confirm.usable():game.sound.play_clip("button");game.refresh_correspondence())
		confirm.set_meta("content",true)
		paper.add_child(confirm)
		place(confirm,Rect2(area.position.x+area.size.x-272,lower+58,236,60))
		game.button_feel(confirm)
		var hint2:=label(paper,"새 소식은 로비 알림에 금빛 점으로 표시됩니다.",12.5,Color(.44,.34,.24,.9))
		hint2.set_meta("content",true)
		place(hint2,Rect2(area.position.x+44,lower+64,420,18))
	var footer:=label(paper,"달빛 아래, 조선",12,Color(.44,.34,.24,.65),true)
	footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	footer.set_meta("content",true)
	place(footer,Rect2(area.position.x+40,area.position.y+area.size.y-40,area.size.x-80,20))
	_paint_sides()

## 목록 판 아래 금빛·어두운 버튼.
func _paint_sides() -> void:
	for key in side_buttons:
		var node: Node=side_buttons[key]
		if is_instance_valid(node):node.queue_free()
	side_buttons.clear()
	var left:=Rect2(LIST.position.x+14,LIST.position.y+LIST.size.y-62,212,48)
	var right:=Rect2(LIST.position.x+234,LIST.position.y+LIST.size.y-62,LIST.size.x-248,48)
	var specs: Array=[]
	if tab=="mail":
		specs=[[left,"모두 수령","gold","mail",func()->void:game.claim_all_mail()],[right,"모두 읽음","dark","check",func()->void:game.read_all_mail()]]
	else:
		specs=[[left,"모두 읽음","gold","check",func()->void:game.read_all_alerts()],[right,"우편함 열기","dark","mail",func()->void:switch_tab("mail")]]
	for spec in specs:
		var node:=V.PlateButton.new()
		node.kind=String(spec[2])
		node.text=String(spec[1])
		node.glyph=String(spec[3])
		node.font_size=16
		node.name="MailSide_"+String(spec[1])
		node.custom_minimum_size=Vector2.ZERO
		var action: Callable=spec[4]
		node.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		node.pressed.connect(func()->void:
			if node.usable():game.sound.play_clip("button");action.call())
		add_child(node)
		game.button_feel(node)
		place(node,spec[0])
		side_buttons[node.name]=node

func place_deco(key: String,rect: Rect2) -> void:
	for child in paper.get_children():
		if String(child.get_meta("deco",""))==key:
			place(child as Control,rect)

func paper_rect() -> Rect2:
	return Rect2(690,SHEET_Y,right_edge()-690,SHEET_H)

func arrange() -> void:
	if not built:return
	reshape(tabs["mail"],Rect2(RAIL.position.x+2,RAIL.position.y+2,RAIL.size.x-4,88))
	reshape(tabs["alerts"],Rect2(RAIL.position.x+2,RAIL.position.y+100,RAIL.size.x-4,88))
	for key in tabs:tabs[key].queue_redraw()
	var frame: Node=self.get_node_or_null("MailListFrame")
	if frame!=null:reshape(frame,LIST)
	reshape(paper,paper_rect())
	if paper_frame!=null:
		paper_frame.size=paper.size
		V.refit(paper_frame)
		var area:=paper_rect()
		place_deco("branch",Rect2(area.position.x+area.size.x-236,area.position.y-6,236,146))
		place_deco("tassel",Rect2(area.position.x-15,area.position.y+28,32,112))

	_paint_sheet()

## 붉은 낙관(봉인).
class SealStamp extends Control:
	var tint:=Color(.62,.20,.18)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var rad:=minf(size.x,size.y)*.5-1.0
		draw_circle(c,rad,Color(tint.r*.72,tint.g*.72,tint.b*.72,1))
		draw_circle(c,rad*.86,tint)
		draw_arc(c,rad*.97,0,TAU,28,Color(1,.92,.84,.35),1.1,true)
		G.draw_glyph(self,"seal",Rect2(c-Vector2(rad*.52,rad*.52),Vector2(rad*1.04,rad*1.04)),Color(1,.94,.88,.92),1.3)

## 금빛 동전.
class CoinGlyph extends Control:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5
		draw_circle(c,r,Color(.78,.57,.22))
		draw_circle(c,r*.82,Color(.93,.76,.38))
		draw_arc(c,r*.96,0,TAU,26,Color(.55,.36,.10),1.2,true)
		draw_arc(c,r*.52,0,TAU,22,Color(.58,.40,.12,.9),1.4,true)

## 리본 선물 아이콘(수령 전 표시).
class GiftGlyph extends Control:
	var tint:=Color(1,.92,.70)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var w:=size.x
		var box:=Rect2(w*.12,w*.36,w*.76,w*.52)
		draw_rect(box,tint)
		draw_rect(Rect2(w*.30,box.position.y,w*.10,box.size.y),Color(tint.r*.72,tint.g*.72,tint.b*.72,1))
		draw_rect(Rect2(box.position.x,w*.46,box.size.x,w*.08),Color(tint.r*.72,tint.g*.72,tint.b*.72,1))
		draw_arc(Vector2(w*.34,w*.24),w*.14,0,TAU,20,tint,1.6,true)
		draw_arc(Vector2(w*.64,w*.24),w*.14,0,TAU,20,tint,1.6,true)
