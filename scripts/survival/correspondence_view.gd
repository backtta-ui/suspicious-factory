extends "res://scripts/ui/lobby_screen.gd"
## 2.0.23 우편·알림 — 봉인된 편지 목록 + 펼친 한지 두루마리.
## 왼쪽: 붉은 낙관으로 봉인된 편지 카드(선택 시 금테 광) / 오른쪽: 한지 편지지에 먹글씨 본문,
## 아래에 동봉 보상과 입체 황동 수령 버튼. 읽음·수령 상태는 실제 저장과 연결된다.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const LIST_POS:=Vector2(26,132)
const LIST_W:=366.0
const LIST_H:=500.0
const SHEET_POS:=Vector2(410,132)
const SHEET_W:=844.0
const SHEET_H:=500.0
const INK=Color("2a2016")
const INK_SOFT=Color("584634")
var tab:="mail"
var initial:="mail"
var selected_id:=""
var items: Array=[]
var paper: Control
var tabs: Dictionary={}

func build() -> void:
	tab=initial
	header("우편" if tab=="mail" else "알림","서원에서 도착한 봉인된 편지 · 낙관을 눌러 확인합니다")
	note("수령한 보상은 저장에 남고 다시 받을 수 없습니다 · 모두 무료 재화입니다")
	for index in range(2):
		var spec: Array=[["mail","우편"],["alerts","알림"]][index]
		var key: String=spec[0]
		var target:=button(String(spec[1]),func()->void:switch_tab(key),self,key==tab,16)
		target.name="LetterTab_"+key
		place(target,Rect2(26+index*124,90,112,34))
		tabs[key]=target
	var list_frame:=UIK.nine(self,UIK.TEX_PANEL_SOFT,20)
	place(list_frame,Rect2(LIST_POS.x-4,LIST_POS.y-4,LIST_W+8,LIST_H+8))
	paper=_paper()
	refresh()

## 한지 편지지: 크림색 결, 붉은 괘선, 위아래 마구리, 낙관 자리.
func _paper() -> Control:
	var node:=Control.new()
	node.name="MailPaper"
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(node)
	place(node,Rect2(SHEET_POS,Vector2(SHEET_W,SHEET_H)))
	var drawing:=Control.new()
	drawing.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_child(drawing)
	drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing.draw.connect(func()->void:
		var box:=Rect2(Vector2(10,10),drawing.size-Vector2(20,20))
		var w:=box.size.x
		var h:=box.size.y
		# 바깥 그림자
		for i in range(4):
			var grow:=2.0+float(i)*2.6
			LC.rounded_outline(drawing,box.grow(grow),Color(0,0,0,.16-float(i)*.03),8.0+grow,3.0)
		# 한지 그라데이션
		LC.gradient_rounded(drawing,box,Color(.965,.905,.780,1.0),Color(.870,.795,.640,1.0),6.0)
		# 섬유 결(가로 세로 가는 줄)
		var rng:=RandomNumberGenerator.new()
		rng.seed=20261119
		for i in range(46):
			var y:=box.position.y+rng.randf_range(6.0,h-6.0)
			var x0:=box.position.x+rng.randf_range(4.0,w*.4)
			var x1:=x0+rng.randf_range(w*.15,w*.55)
			drawing.draw_line(Vector2(x0,y),Vector2(minf(x1,box.end.x-4.0),y),Color(.55,.44,.28,rng.randf_range(.03,.075)),1.0)
		for i in range(16):
			var x:=box.position.x+rng.randf_range(6.0,w-6.0)
			drawing.draw_line(Vector2(x,box.position.y+6.0),Vector2(x,box.end.y-6.0),Color(.6,.48,.30,.035),1.0)
		# 위아래 마구리(나무 축)
		for y in [box.position.y-2.0,box.end.y-10.0]:
			LC.rounded(drawing,Rect2(Vector2(box.position.x-6.0,y),Vector2(w+12.0,12.0)),Color(.10,.08,.11,1.0),6.0)
			drawing.draw_line(Vector2(box.position.x,y+2.0),Vector2(box.end.x,y+2.0),Color(.95,.84,.60,.35),1.4)
		for side in [box.position.x-6.0,box.end.x+6.0]:
			drawing.draw_circle(Vector2(side,box.position.y+4.0),5.0,Color(.08,.06,.09,1.0))
			drawing.draw_arc(Vector2(side,box.position.y+4.0),5.0,0,TAU,16,Color(.86,.72,.47,.7),1.2,true)
			drawing.draw_circle(Vector2(side,box.end.y-4.0),5.0,Color(.08,.06,.09,1.0))
			drawing.draw_arc(Vector2(side,box.end.y-4.0),5.0,0,TAU,16,Color(.86,.72,.47,.7),1.2,true)
		# 붉은 괘선(왼쪽 여백선)
		drawing.draw_line(Vector2(box.position.x+46.0,box.position.y+18.0),Vector2(box.position.x+46.0,box.end.y-30.0),Color(.62,.22,.20,.30),1.4)
		drawing.draw_line(Vector2(box.position.x+52.0,box.position.y+18.0),Vector2(box.position.x+52.0,box.end.y-30.0),Color(.62,.22,.20,.16),1.0)
		# 안쪽 테두리
		LC.rounded_outline(drawing,box.grow(-1.0),Color(.46,.34,.20,.35),6.0,1.2)
		LC.rounded_outline(drawing,box.grow(-6.0),Color(.46,.34,.20,.14),4.0,1.0))
	return node

func switch_tab(key: String) -> void:
	if key==tab:return
	tab=key
	selected_id=""
	title_label.text="우편" if tab=="mail" else "알림"
	subtitle_label.text="서원에서 도착한 봉인된 편지 · 낙관을 눌러 확인합니다" if tab=="mail" else "서원의 공지 · 새 소식은 금빛 점으로 표시됩니다"
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
		var target: WooMobileButton=tabs[key]
		var chosen: bool=key==tab
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			var box:=T.panel_box(Color(0.13,0.10,0.06,0.96) if chosen else Color(0.05,0.055,0.11,0.9),10,Color(0.90,0.76,0.48,0.95) if chosen else Color(0.85,0.72,0.47,0.30),1,Color(0.85,0.72,0.47,0.35) if chosen else Color(0,0,0,0),12 if chosen else 0)
			target.add_theme_stylebox_override(state,box)
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
			target.add_theme_color_override(state,T.GOLD_SOFT if chosen else Color(0.82,0.86,0.96))

func _make_card(entry: Dictionary,index: int) -> void:
	var id:=String(entry.id)
	var height:=104.0
	var rect:=Rect2(LIST_POS.x+8,LIST_POS.y+8+index*(height+9),LIST_W-16,height)
	var card:=button("",func()->void:open_item(id),self,false,15)
	card.name="Letter_"+id
	place(card,rect)
	var chosen: bool=id==selected_id
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		card.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var glow:=UIK.Glow.new()
	glow.color=Color(1,.84,.46)
	glow.radius=10.0*s
	glow.visible=chosen
	card.add_child(glow)
	place(glow,Rect2(0,0,rect.size.x,rect.size.y))
	var frame:=UIK.nine(card,UIK.TEX_CARD_LIT if chosen else UIK.TEX_CARD,22)
	frame.position=Vector2.ZERO
	frame.size=rect.size*s
	# 낙관
	var stamp:=Control.new()
	stamp.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stamp.draw.connect(func()->void:
		var c: Vector2=stamp.size*.5
		var rad:=minf(stamp.size.x,stamp.size.y)*.5-1.0
		stamp.draw_circle(c,rad,Color(.56,.16,.15,.98) if tab=="mail" else Color(.72,.56,.24,.98))
		stamp.draw_circle(c,rad*.86,Color(.72,.24,.22,1.0) if tab=="mail" else Color(.84,.68,.34,1.0))
		stamp.draw_arc(c,rad,0,TAU,28,Color(1,.94,.86,.35),1.2,true)
		G.draw_glyph(stamp,"seal",Rect2(c-Vector2(rad*.52,rad*.52),Vector2(rad*1.04,rad*1.04)),Color(1,.94,.88,.92),1.2))
	card.add_child(stamp)
	stamp.position=Vector2(12,16)*s
	stamp.size=Vector2(42,42)*s
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var title:=label(card,String(entry.title),16.5,T.GOLD_SOFT if chosen else T.IVORY,true)
	title.clip_text=true
	place(title,Rect2(rect.position.x+64,rect.position.y+10,rect.size.x-110,24))
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	var status:=("새 편지" if not read else "읽음")
	if tab=="mail":status+=" · 보상 %s 코인"%number(int(entry.reward))+(" · 수령 완료" if claimed else "")
	var status_label:=label(card,status,13.5,Color(0.86,.88,.96) if chosen else T.MUTED)
	place(status_label,Rect2(rect.position.x+64,rect.position.y+36,rect.size.x-88,20))
	var preview_text:=String(entry.get("body",""))
	if preview_text.length()>28:preview_text=preview_text.substr(0,28)+"…"
	var body_preview:=label(card,preview_text,13,Color(0.74,.76,.86,0.95))
	body_preview.clip_text=true
	place(body_preview,Rect2(rect.position.x+14,rect.position.y+64,rect.size.x-28,20))
	# 수령 대기 표시
	if tab=="mail" and not claimed:
		var dot:=UIK.Seal.new()
		dot.glowing=false
		dot.color=Color(.86,.70,.40)
		card.add_child(dot)
		dot.position=Vector2(rect.size.x*s-30.0*s,10.0*s)
		dot.size=Vector2(20,20)*s
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

func _paint_sheet() -> void:
	for child in paper.get_children():
		if child.has_meta("content"):child.queue_free()
	var entry: Dictionary={}
	for candidate in _list():
		if String(candidate.id)==selected_id:entry=candidate
	if entry.is_empty():return
	var id:=String(entry.id)
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	# 낙관(제목 옆)
	var stamp:=Control.new()
	stamp.set_meta("content",true)
	stamp.mouse_filter=Control.MOUSE_FILTER_IGNORE
	paper.add_child(stamp)
	place(stamp,Rect2(SHEET_POS.x+34,SHEET_POS.y+30,58,58))
	stamp.draw.connect(func()->void:
		var c: Vector2=stamp.size*.5
		var rad:=minf(stamp.size.x,stamp.size.y)*.5-1.0
		stamp.draw_circle(c,rad,Color(.60,.18,.17,.96) if tab=="mail" else Color(.74,.58,.26,.96))
		stamp.draw_circle(c,rad*.82,Color(.96,.90,.80,.20))
		G.draw_glyph(stamp,"seal",Rect2(c-Vector2(rad*.56,rad*.56),Vector2(rad*1.12,rad*1.12)),Color(1,.94,.86,.92),1.3))
	var title:=label(paper,String(entry.title),27,INK,true)
	title.set_meta("content",true)
	place(title,Rect2(SHEET_POS.x+108,SHEET_POS.y+34,SHEET_W-160,36))
	var meta_text:="월하의 서원 지기 · "+("읽음" if read else "새 편지")
	if tab=="mail":meta_text+=" · 동봉 %s 코인"%number(int(entry.reward))+(" · 수령 완료" if claimed else " · 수령 전")
	var meta:=label(paper,meta_text,13.5,INK_SOFT)
	meta.set_meta("content",true)
	place(meta,Rect2(SHEET_POS.x+108,SHEET_POS.y+70,SHEET_W-160,20))
	var line:=divider(paper,Color(.45,.33,.20,.35))
	line.set_meta("content",true)
	place(line,Rect2(SHEET_POS.x+40,SHEET_POS.y+104,SHEET_W-80,1))
	var body:=label(paper,String(entry.get("body","")),17,Color(.22,.16,.12))
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	body.set_meta("content",true)
	place(body,Rect2(SHEET_POS.x+64,SHEET_POS.y+118,SHEET_W-128,214))
	var signature:=label(paper,"— 월하의 서원 지기",14.5,Color(.40,.30,.20),true)
	signature.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	signature.set_meta("content",true)
	place(signature,Rect2(SHEET_POS.x+SHEET_W-270,SHEET_POS.y+340,214,24))
	# 워터마크 낙관
	var water:=Control.new()
	water.set_meta("content",true)
	water.mouse_filter=Control.MOUSE_FILTER_IGNORE
	water.modulate.a=0.13
	paper.add_child(water)
	place(water,Rect2(SHEET_POS.x+SHEET_W-206,SHEET_POS.y+140,150,150))
	water.draw.connect(func()->void:
		var c: Vector2=water.size*.5
		var rad:=minf(water.size.x,water.size.y)*.5-2.0
		water.draw_arc(c,rad,0,TAU,48,Color(.55,.18,.16),4.0,true)
		water.draw_arc(c,rad*.86,0,TAU,48,Color(.55,.18,.16),2.0,true)
		G.draw_glyph(water,"seal",Rect2(c-Vector2(rad*.5,rad*.5),Vector2(rad,rad)),Color(.55,.18,.16),2.0))
	var rule_line:=divider(paper,Color(.45,.33,.20,.28))
	rule_line.set_meta("content",true)
	place(rule_line,Rect2(SHEET_POS.x+40,SHEET_POS.y+372,SHEET_W-80,1))
	if tab=="mail":
		var reward:=label(paper,"동봉된 보상",13.5,INK_SOFT)
		reward.set_meta("content",true)
		place(reward,Rect2(SHEET_POS.x+56,SHEET_POS.y+384,240,20))
		var amount:=label(paper,"%s 코인"%number(int(entry.reward)),23,Color(.34,.22,.06),true)
		amount.set_meta("content",true)
		place(amount,Rect2(SHEET_POS.x+78,SHEET_POS.y+406,260,32))
		var coin:=Control.new()
		coin.set_meta("content",true)
		coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		paper.add_child(coin)
		place(coin,Rect2(SHEET_POS.x+46,SHEET_POS.y+412,26,26))
		coin.draw.connect(func()->void:
			var c: Vector2=coin.size*.5
			coin.draw_circle(c,coin.size.x*.46,Color(.80,.60,.24))
			coin.draw_arc(c,coin.size.x*.46,0,TAU,24,Color(.55,.36,.10),1.4,true)
			coin.draw_circle(c,coin.size.x*.16,Color(.40,.26,.06,.85)))
		var claim=UIK.MetalButton.new()
		claim.kind="gold"
		claim.text="보상 수령 완료" if claimed else "보상 수령"
		claim.glyph="check" if claimed else "mail"
		claim.font_size=int(17)
		claim.use_title_font=false
		claim.name="MailClaim"
		claim.custom_minimum_size=Vector2.ZERO
		claim.disabled=claimed
		claim.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		claim.pressed.connect(func()->void:
			if claim.usable():
				game.sound.play_clip("button");game.claim_mail(entry))
		claim.set_meta("content",true)
		paper.add_child(claim)
		place(claim,Rect2(SHEET_POS.x+SHEET_W-286,SHEET_POS.y+396,250,58))
		game.button_feel(claim)
		var hint:=label(paper,"보상은 한 번만 받을 수 있습니다.",12.5,Color(.44,.34,.24,0.9))
		hint.set_meta("content",true)
		place(hint,Rect2(SHEET_POS.x+56,SHEET_POS.y+448,360,18))
	else:
		var confirm=UIK.MetalButton.new()
		confirm.kind="gold"
		confirm.text="읽음 표시"
		confirm.glyph="check"
		confirm.font_size=int(17)
		confirm.custom_minimum_size=Vector2.ZERO
		confirm.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		confirm.pressed.connect(func()->void:
			if confirm.usable():game.sound.play_clip("button");game.refresh_correspondence())
		confirm.set_meta("content",true)
		paper.add_child(confirm)
		place(confirm,Rect2(SHEET_POS.x+SHEET_W-266,SHEET_POS.y+400,230,54))
		game.button_feel(confirm)
		var hint2:=label(paper,"새 소식은 로비 알림에 금빛 점으로 표시됩니다.",12.5,Color(.44,.34,.24,0.9))
		hint2.set_meta("content",true)
		place(hint2,Rect2(SHEET_POS.x+56,SHEET_POS.y+412,420,18))

func arrange() -> void:
	pass
