extends "res://scripts/ui/lobby_screen.gd"
## 우편·알림: 봉인된 편지 목록과 붉은 낙관, 오른쪽에 펼친 편지 한 통.
## 읽음/보상 수령 상태는 실제 저장과 연결된다(보상은 한 번만).
const LIST_POS:=Vector2(26,132)
const LIST_SIZE:=Vector2(382,492)
const SHEET_POS:=Vector2(422,132)
const SHEET_SIZE:=Vector2(832,492)
var tab:="mail"
var initial:="mail"
var selected_id:=""
var items: Array=[]
var sheet: Control
var tabs: Dictionary={}

func build() -> void:
	tab=initial
	header("우편" if tab=="mail" else "알림","서원에서 도착한 봉인된 편지 · 붉은 낙관을 눌러 확인합니다")
	note("수령한 보상은 저장에 남고 다시 받을 수 없습니다 · 모두 무료 재화입니다")
	for index in range(2):
		var spec: Array=[["mail","우편"],["alerts","알림"]][index]
		var key: String=spec[0]
		var target:=button(String(spec[1]),func()->void:switch_tab(key),self,key==tab,13)
		target.name="LetterTab_"+key
		place(target,Rect2(26+index*104,92,96,30))
		tabs[key]=target
	var list_frame:=panel(self,Color(0.045,0.048,0.09,0.92),12,Color(0.6,0.35,0.25,0.14))
	place(list_frame,Rect2(LIST_POS,LIST_SIZE))
	sheet=panel(self,Color(0.07,0.065,0.085,0.95),12,Color(0.85,0.72,0.47,0.18))
	place(sheet,Rect2(SHEET_POS,SHEET_SIZE))
	refresh()

func switch_tab(key: String) -> void:
	if key==tab:return
	tab=key
	selected_id=""
	title_label.text="우편" if tab=="mail" else "알림"
	subtitle_label.text="서원에서 도착한 봉인된 편지 · 붉은 낙관을 눌러 확인합니다" if tab=="mail" else "서원의 공지 · 새 소식은 금빛 점으로 표시됩니다"
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
			target.add_theme_stylebox_override(state,T.chip_box(chosen,Color(0.85,0.72,0.47)))
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
			target.add_theme_color_override(state,T.GOLD_SOFT if chosen else Color(0.8,0.84,0.94))

func _make_card(entry: Dictionary,index: int) -> void:
	var id:=String(entry.id)
	var height:=108.0
	var rect:=Rect2(LIST_POS.x+10,LIST_POS.y+10+index*(height+8),LIST_SIZE.x-20,height)
	var card:=button("",func()->void:open_item(id),self,false,12)
	card.name="Letter_"+id
	place(card,rect)
	var chosen: bool=id==selected_id
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		card.add_theme_stylebox_override(state,T.lit_box(Color(0.18,0.12,0.08,0.9),8) if chosen else T.panel_box(Color(0.03,0.035,0.07,0.85),8,Color(0.85,0.72,0.47,0.28),1))
	if tab=="mail":
		var stamp:=Art.Stamp.new()
		stamp.color=Color(0.72,0.25,0.24,1.0) if chosen else Color(0.58,0.24,0.24,0.9)
		card.add_child(stamp)
		stamp.position=Vector2(12,14);stamp.size=Vector2(40,40)
	else:
		var seal:=Art.Stamp.new()
		seal.color=Color(0.78,0.62,0.30,1.0) if chosen else Color(0.55,0.47,0.30,0.9)
		card.add_child(seal)
		seal.position=Vector2(12,14);seal.size=Vector2(40,40)
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var title:=label(card,String(entry.title),12.5,T.GOLD_SOFT if chosen else T.IVORY,true)
	title.clip_text=true
	place(title,Rect2(rect.position.x+62,rect.position.y+12,rect.size.x-78,20))
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	var status:=("새 편지" if not read else "읽음")
	if tab=="mail":status+=" · 보상 %s 코인"%number(int(entry.reward))+(" · 수령 완료" if claimed else "")
	var status_label:=label(card,status,11,Color(0.78,0.82,0.92) if chosen else T.MUTED)
	place(status_label,Rect2(rect.position.x+62,rect.position.y+36,rect.size.x-78,18))
	var preview_text:=String(entry.get("body",""))
	if preview_text.length()>30:preview_text=preview_text.substr(0,30)+"…"
	var body_preview:=label(card,preview_text,10.5,Color(0.66,0.70,0.80,0.9))
	body_preview.clip_text=true
	place(body_preview,Rect2(rect.position.x+62,rect.position.y+56,rect.size.x-78,16))
	if not read:
		var dot:=label(card,"●",9,T.GOLD)
		place(dot,Rect2(rect.position.x+rect.size.x-26,rect.position.y+10,16,16))
		card.set_meta("dot",dot)
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

## 다른 화면(테스트·로비 알림)에서 특정 편지를 지정할 때.
func focus_item(id: String) -> void:
	selected_id=id
	refresh()

func _paint_sheet() -> void:
	for child in sheet.get_children():
		if child.has_meta("content"):
			child.queue_free()
	var entry: Dictionary={}
	for candidate in _list():
		if String(candidate.id)==selected_id:entry=candidate
	if entry.is_empty():return
	var id:=String(entry.id)
	var stamp:=Art.Stamp.new()
	stamp.color=Color(0.72,0.25,0.24,1.0) if tab=="mail" else Color(0.80,0.64,0.30,1.0)
	sheet.add_child(stamp)
	stamp.set_meta("content",true)
	place(stamp,Rect2(SHEET_POS.x+28,SHEET_POS.y+26,62,62))
	var title:=label(sheet,String(entry.title),22,T.GOLD_SOFT,true)
	title.set_meta("content",true)
	place(title,Rect2(SHEET_POS.x+106,SHEET_POS.y+26,SHEET_SIZE.x-140,32))
	var read: bool=(game.storage.data[_read_key()].read as Array).has(id)
	var claimed: bool=(game.storage.data.mail.claimed as Array).has(id)
	var meta_text:="서원의 편지 · "+("읽음" if read else "새 편지")
	if tab=="mail":meta_text+=" · 동봉 %s 코인"%number(int(entry.reward))+(" · 수령 완료" if claimed else " · 수령 전")
	var meta:=label(sheet,meta_text,11.5,T.MUTED)
	meta.set_meta("content",true)
	place(meta,Rect2(SHEET_POS.x+106,SHEET_POS.y+58,SHEET_SIZE.x-140,18))
	var line:=divider(sheet,Color(0.85,0.72,0.47,0.22))
	line.set_meta("content",true)
	place(line,Rect2(SHEET_POS.x+28,SHEET_POS.y+100,SHEET_SIZE.x-56,1))
	var body:=label(sheet,String(entry.get("body","")),13,Color(0.86,0.88,0.95))
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	body.set_meta("content",true)
	place(body,Rect2(SHEET_POS.x+30,SHEET_POS.y+116,SHEET_SIZE.x-60,236))
	var watermark:=Art.Stamp.new()
	watermark.color=Color(0.68,0.26,0.24)
	watermark.modulate.a=0.09
	sheet.add_child(watermark)
	watermark.set_meta("content",true)
	place(watermark,Rect2(SHEET_POS.x+SHEET_SIZE.x-238,SHEET_POS.y+108,196,196))
	var signature:=label(sheet,"— 월하의 서원 지기",13,T.gold(.8),true)
	signature.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	signature.set_meta("content",true)
	place(signature,Rect2(SHEET_POS.x+30,SHEET_POS.y+330,SHEET_SIZE.x-60,24))
	var rule_line:=divider(sheet,Color(0.85,0.72,0.47,0.14))
	rule_line.set_meta("content",true)
	place(rule_line,Rect2(SHEET_POS.x+28,SHEET_POS.y+366,SHEET_SIZE.x-56,1))
	if tab=="mail":
		var reward:=label(sheet,"동봉된 보상",11.5,T.MUTED)
		reward.set_meta("content",true)
		place(reward,Rect2(SHEET_POS.x+30,SHEET_POS.y+380,220,18))
		var amount:=label(sheet,"%s 코인"%number(int(entry.reward)),20,T.GOLD_SOFT,true)
		amount.set_meta("content",true)
		place(amount,Rect2(SHEET_POS.x+30,SHEET_POS.y+400,260,28))
		var claim:=button("보상 수령 완료" if claimed else "보상 수령",func()->void:game.claim_mail(entry),sheet,not claimed,15)
		claim.name="MailClaim"
		claim.disabled=claimed
		claim.set_meta("content",true)
		place(claim,Rect2(SHEET_POS.x+SHEET_SIZE.x-234,SHEET_POS.y+392,204,46))
		var hint:=label(sheet,"보상은 한 번만 받을 수 있습니다.",10.5,Color(0.68,0.72,0.82,0.75))
		hint.set_meta("content",true)
		place(hint,Rect2(SHEET_POS.x+30,SHEET_POS.y+444,300,16))
	else:
		var confirm:=button("읽음 표시",func()->void:game.refresh_correspondence(),sheet,false,14)
		confirm.set_meta("content",true)
		place(confirm,Rect2(SHEET_POS.x+SHEET_SIZE.x-214,SHEET_POS.y+392,184,44))
		var hint:=label(sheet,"새 소식은 로비 알림에 금빛 점으로 표시됩니다.",10.5,Color(0.68,0.72,0.82,0.75))
		hint.set_meta("content",true)
		place(hint,Rect2(SHEET_POS.x+30,SHEET_POS.y+400,420,16))

func arrange() -> void:
	pass
