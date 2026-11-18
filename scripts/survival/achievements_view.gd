extends "res://scripts/ui/lobby_screen.gd"
## 2.0.25 업적 — 시안(달빛 사원의 업적 현황) 복제.
## 왼쪽: 금테 레일(전체·전투·생장·수집), 가운데: 월계관 메달 카드 목록(진행 게이지·보상·수령),
## 오른쪽: 달빛 정자 그림 + 리본 "업적 달성 현황" + 달성 수·게이지·보상/다음 목표.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const RAIL:=Rect2(18,132,146,286)
const LIST:=Rect2(180,86,706,600)
const SUMMARY_X:=898.0
const ROW_H:=88.0
const ROW_GAP:=8.0
const CATEGORIES=[["all","전체","crown",["matches","wins","seals","rescues","doors","disguises"]],
	["battle","전투","swords",["matches","wins","seals"]],
	["life","성장","flower",["rescues","doors"]],
	["collect","수집","spark",["disguises"]]]
var rows: Array=[]
var summary_parts: Array=[]
var tabs: Dictionary={}
var scroll: Dictionary={}
var list_content: Control
var category:="all"
var count_label_ref: Label

func build() -> void:
	header("업적","다양한 도전 과제를 달성하고 보상을 획득하세요","trophy")
	for index in range(CATEGORIES.size()):
		var spec: Array=CATEGORIES[index]
		var key: String=String(spec[0])
		var target:=V.Tab.new()
		target.text=String(spec[1])
		target.glyph=String(spec[2])
		target.font_size=19
		target.name="AchievementTab_"+key
		target.custom_minimum_size=Vector2.ZERO
		target.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		target.pressed.connect(func()->void:
			if target.usable():game.sound.play_clip("button");set_category(key))
		add_child(target)
		game.button_feel(target)
		tabs[key]=target
	var back=V.frame(self,Rect2(0,0,1,1))
	back.name="AchievementListFrame"
	place(back,LIST)
	var area: Dictionary=scroll_area(Rect2(LIST.position.x+12,LIST.position.y+12,LIST.size.x-34,LIST.size.y-24),LIST.size.y-24)
	scroll=area
	list_content=area.content
	from_scratch()

func set_category(key: String) -> void:
	if category==key:return
	category=key
	from_scratch()

func _items() -> Array:
	var stats: Array=[]
	for spec in CATEGORIES:
		if String(spec[0])==category:stats=spec[3]
	if stats.is_empty():return Market.ACHIEVEMENTS
	var out: Array=[]
	for item in Market.ACHIEVEMENTS:
		if stats.has(String(item.stat)):out.append(item)
	return out

## 목록·요약을 처음부터 다시 그린다(저장 상태가 바뀔 때 호출).
func from_scratch() -> void:
	for row in rows:
		if is_instance_valid(row):row.queue_free()
	rows.clear()
	for child in summary_parts:
		if is_instance_valid(child):child.queue_free()
	summary_parts.clear()
	_paint_tabs()
	var claimed:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):claimed+=1
	var index:=0
	for item in _items():
		_make_card(item,index)
		index+=1
	if list_content!=null:
		var rows_total:=float(_items().size())*(ROW_H+ROW_GAP)+8.0
		list_content.custom_minimum_size=Vector2(LIST.size.x-34,maxf(LIST.size.y-24,rows_total))
	_make_summary(claimed)

func _paint_tabs() -> void:
	for key in tabs:
		var target: V.Tab=tabs[key]
		target.paint(key==category)

## 월계관 메달(수령 완료는 금빛, 미완료는 차분한 은빛).
func _medal(parent: Node,rect: Rect2,done: bool,reward: int) -> void:
	var holder:=Control.new()
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	place(holder,rect)
	var laurel:=TextureRect.new()
	laurel.texture=V.TEX_LAUREL
	laurel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	laurel.stretch_mode=TextureRect.STRETCH_SCALE
	laurel.modulate=Color(1,.97,.90) if done else Color(.72,.72,.86,.9)
	laurel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(laurel)
	laurel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var medal_art:=TextureRect.new()
	medal_art.texture=V.TEX_ICON_MEDAL
	medal_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	medal_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal_art.modulate=Color(1,1,1,1) if done else Color(.72,.72,.82,.85)
	medal_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(medal_art)
	medal_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	medal_art.offset_left=holder.size.x*0.10
	medal_art.offset_top=holder.size.y*0.10
	medal_art.offset_right=-holder.size.x*0.10
	medal_art.offset_bottom=-holder.size.y*0.10
	var seal:=Control.new()
	seal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(seal)
	seal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seal.set_meta("done",done)
	seal.visible=false

func _make_card(item: Dictionary,index: int) -> void:
	var rect:=Rect2(LIST.position.x+10,LIST.position.y+10+index*(ROW_H+ROW_GAP),LIST.size.x-20,ROW_H)
	var value: int=game.storage.stat(String(item.stat))
	var done: bool=value>=int(item.goal)
	var claimed: bool=(game.storage.data.achievements.claimed as Array).has(String(item.id))
	var holder:=Control.new()
	holder.name="AchievementRow_"+String(item.id)
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	list_content.add_child(holder)
	place(holder,rect)
	var frame:=V.patch(holder,V.TEX_CARD_LIT if (done and not claimed) else V.TEX_CARD,Rect2(Vector2.ZERO,rect.size),26)
	frame.name="RowFrame"
	frame.name="RowFrame"
	_medal(holder,Rect2(rect.position.x+14,rect.position.y+14,60,60),done,int(item.reward))
	var name_label:=label(holder,String(item.name),20.5,V.GOLD_BRIGHT if done else V.IVORY,true)
	place(name_label,Rect2(rect.position.x+86,rect.position.y+10,rect.size.x-260,26))
	var desc:=label(holder,String(item.desc),15,Color(.84,.86,.96))
	desc.clip_text=true
	place(desc,Rect2(rect.position.x+86,rect.position.y+38,rect.size.x-200,20))
	var gauge:=GaugeBar.new()
	gauge.tint=Color(0.95,0.78,0.44) if done else Color(0.86,0.80,0.66)
	gauge.set_value(value,int(item.goal))
	holder.add_child(gauge)
	place(gauge,Rect2(rect.position.x+86,rect.position.y+64,300,12))
	var counter:=label(holder,"%d / %d"%[mini(value,int(item.goal)),int(item.goal)],15,V.GOLD_BRIGHT if done else Color(.80,.78,.90))
	counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	place(counter,Rect2(rect.position.x+396,rect.position.y+58,70,20))
	# 코인 보상 알약
	var reward_box:=Control.new()
	reward_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(reward_box)
	place(reward_box,Rect2(rect.position.x+456,rect.position.y+38,104,36))
	var coin_art:=TextureRect.new()
	coin_art.texture=V.TEX_ICON_COIN
	coin_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(coin_art)
	coin_art.position=Vector2(462,40)*s
	coin_art.size=Vector2(30,30)*s
	reward_box.draw.connect(func()->void:
		var box:=Rect2(Vector2.ZERO,reward_box.size)
		LC.gradient_rounded(reward_box,box,Color(.16,.12,.10,.96),Color(.07,.05,.05,.97),box.size.y*.5)
		LC.rounded_outline(reward_box,box,Color(.86,.70,.42,.55),box.size.y*.5,1.2)
		var font:=LC.FONT
		var extent:=maxi(10,int(14.5*s))
		reward_box.draw_string(font,Vector2(box.size.y*1.35,box.size.y*.5+(font.get_ascent(extent)-font.get_descent(extent))*.5),number(int(item.reward)),HORIZONTAL_ALIGNMENT_LEFT,-1,extent,Color("f6dfae")))
	var claim:=V.PlateButton.new()
	claim.kind="gold" if (done and not claimed) else "dark"
	claim.text="수령 완료" if claimed else "보상 받기"
	claim.glyph="check" if claimed else "mail"
	claim.font_size=15
	claim.name="Claim_"+String(item.id)
	claim.custom_minimum_size=Vector2.ZERO
	claim.disabled=claimed or not done
	claim.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	claim.pressed.connect(func()->void:
		if claim.usable():game.sound.play_clip("button");game.claim_achievement(item))
	holder.add_child(claim)
	place(claim,Rect2(rect.position.x+rect.size.x-140,rect.position.y+24,128,40))
	game.button_feel(claim)
	rows.append(holder)

## 오른쪽 요약 판 — 월계관 정자 그림 · 리본 · 달성 수 · 게이지 · 보상/다음 목표.
func _make_summary(claimed: int) -> void:
	var box:=Rect2(SUMMARY_X,76.0,right_edge()-SUMMARY_X,606)
	var frame:=V.frame(self,Rect2(0,0,1,1))
	frame.name="AchievementSummaryFrame"
	place(frame,box)
	summary_parts.append(frame)
	var center:=box.position.x+box.size.x*.5
	# 달빛 정자(코덱스 배경을 원형으로 잘라 금테 안에)
	var art:=TextureRect.new()
	art.texture=V.TEX_SCENE
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_SCALE
	art.modulate=Color(1.05,1.0,1.06)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art)
	summary_parts.append(art)
	place(art,Rect2(center-84,box.position.y+26,168,168))
	var laurel:=TextureRect.new()
	laurel.texture=V.TEX_LAUREL
	laurel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	laurel.stretch_mode=TextureRect.STRETCH_SCALE
	laurel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(laurel)
	summary_parts.append(laurel)
	place(laurel,Rect2(center-104,box.position.y+8,208,208))
	# 리본
	var ribbon:=TextureRect.new()
	ribbon.texture=V.TEX_RIBBON
	ribbon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ribbon.stretch_mode=TextureRect.STRETCH_SCALE
	ribbon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ribbon)
	summary_parts.append(ribbon)
	place(ribbon,Rect2(center-150,box.position.y+184,300,76))
	var ribbon_text:=label(self,"업적 달성 현황",20,V.GOLD_BRIGHT,true)
	ribbon_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ribbon_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	summary_parts.append(ribbon_text)
	place(ribbon_text,Rect2(center-150,box.position.y+184,300,76))
	var total:=Market.ACHIEVEMENTS.size()
	var ratio:=label(self,"%d / %d"%[claimed,total],34,V.GOLD_BRIGHT,true)
	ratio.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	summary_parts.append(ratio)
	place(ratio,Rect2(box.position.x,box.position.y+262,box.size.x,44))
	var percent:=0 if total<=0 else int(round(float(claimed)*100.0/float(total)))
	var overall:=GaugeBar.new()
	overall.tint=Color(0.96,0.80,0.46)
	overall.set_value(claimed,total)
	add_child(overall)
	summary_parts.append(overall)
	place(overall,Rect2(box.position.x+26,box.position.y+316,box.size.x-126,16))
	var percent_label:=label(self,"%d%%"%percent,17,V.IVORY,true)
	summary_parts.append(percent_label)
	place(percent_label,Rect2(box.position.x+box.size.x-92,box.position.y+310,70,26))
	var line:=gold_divider(self,Rect2(box.position.x+26,box.position.y+348,box.size.x-52,12))
	summary_parts.append(line)
	var caption:=label(self,"받은 보상",17,V.GOLD_COLOR,true)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	summary_parts.append(caption)
	place(caption,Rect2(box.position.x+26,box.position.y+364,box.size.x-52,24))
	var income:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):income+=int(item.reward)
	var tile:=V.patch(self,V.TEX_TILE,Rect2(Vector2.ZERO,Vector2(96,96)),30)
	summary_parts.append(tile)
	place(tile,Rect2(box.position.x+34,box.position.y+396,96,96))
	var coin:=TextureRect.new()
	coin.texture=V.TEX_ICON_COIN
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	summary_parts.append(coin)
	place(coin,Rect2(box.position.x+50,box.position.y+390,64,64))
	var amount:=label(self,number(income),16,V.GOLD_BRIGHT,true)
	amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	summary_parts.append(amount)
	place(amount,Rect2(box.position.x+34,box.position.y+450,96,22))
	var amount_caption:=label(self,"누적 코인",13,Color(.86,.76,.58))
	amount_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	summary_parts.append(amount_caption)
	place(amount_caption,Rect2(box.position.x+34,box.position.y+472,96,18))
	# 다음 목표 3개
	var next_caption:=label(self,"다음 목표",15,V.GOLD_COLOR,true)
	summary_parts.append(next_caption)
	place(next_caption,Rect2(box.position.x+148,box.position.y+392,box.size.x-170,22))
	var y:=box.position.y+420
	var shown:=0
	for item in Market.ACHIEVEMENTS:
		if shown>=3:break
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):continue
		var value: int=game.storage.stat(String(item.stat))
		if value>=int(item.goal):continue
		var entry:=label(self,String(item.name),14.5,V.IVORY)
		entry.clip_text=true
		summary_parts.append(entry)
		place(entry,Rect2(box.position.x+148,y,box.size.x-230,20))
		var goal:=label(self,"%d/%d"%[value,int(item.goal)],13,V.GOLD_COLOR)
		goal.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		summary_parts.append(goal)
		place(goal,Rect2(box.position.x+box.size.x-86,y,64,20))
		var mini:=GaugeBar.new()
		mini.tint=Color(0.80,0.74,0.90)
		mini.set_value(value,int(item.goal))
		add_child(mini)
		summary_parts.append(mini)
		place(mini,Rect2(box.position.x+148,y+22,box.size.x-200,7))
		y+=40
		shown+=1
	if shown==0:
		var all_done:=label(self,"서원의 모든 기록을 세웠습니다.",14.5,V.GOLD_BRIGHT)
		summary_parts.append(all_done)
		place(all_done,Rect2(box.position.x+148,box.position.y+420,box.size.x-170,22))
	var tip:=label(self,"경기를 끝내면 진행도가 저장됩니다.",13,Color(.78,.76,.90))
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	summary_parts.append(tip)
	place(tip,Rect2(box.position.x+26,box.position.y+box.size.y-46,box.size.x-52,36))

func refresh() -> void:
	from_scratch()

func arrange() -> void:
	if not built:return
	var keys: Array=["all","battle","life","collect"]
	for i in range(keys.size()):
		var key: String=String(keys[i])
		reshape(tabs[key],Rect2(RAIL.position.x+2,RAIL.position.y+2+i*74,RAIL.size.x-4,66))
		tabs[key].queue_redraw()
	var frame: Node=self.get_node_or_null("AchievementListFrame")
	if frame!=null:reshape(frame,LIST)
	if not scroll.is_empty() and is_instance_valid(scroll.holder):
		reshape(scroll.holder,Rect2(LIST.position.x+12,LIST.position.y+12,LIST.size.x-34,LIST.size.y-24))
	reshape(self.get_node_or_null("AchievementSummaryFrame"),Rect2(SUMMARY_X,76.0,right_edge()-SUMMARY_X,606))
	# 요약 내용은 판 크기가 바뀌면 다시 그린다.
	var claimed:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):claimed+=1
	_make_summary(claimed)

## 진행 게이지(금빛 채움 + 눈금).
class GaugeBar extends Control:
	var value:=0.0
	var maximum:=1.0
	var tint:=Color("f2cf8e")
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func set_value(now: int,total: int) -> void:
		value=float(maxi(0,now))
		maximum=float(maxi(1,total))
		queue_redraw()
	func _draw() -> void:
		if size.x<6.0 or size.y<3.0:return
		var box:=Rect2(Vector2.ZERO,size)
		var radius:=size.y*.5
		LC.gradient_rounded(self,box,Color(.10,.08,.14,.96),Color(.05,.04,.08,.96),radius)
		LC.rounded_outline(self,box,Color(.82,.68,.44,.55),radius,1.2)
		var ratio:=clampf(value/maximum,0.0,1.0)
		if ratio>0.0:
			var fill:=Rect2(Vector2(1,1),Vector2(maxf(size.y-2.0,(size.x-2.0)*ratio),size.y-2.0))
			LC.gradient_rounded(self,fill,tint.lightened(.28),tint.darkened(.22),radius-1.0)
			draw_rect(Rect2(fill.position+Vector2(radius*.5,0.8),Vector2(maxf(0.0,fill.size.x-radius),maxf(1.0,fill.size.y*.33))),Color(1,.98,.90,.35))
			LC.rounded_outline(self,fill,Color(1,.94,.76,.5),radius-1.0,1.0)

## 금빛 동전 아이콘.
class CoinBadge extends Control:
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
