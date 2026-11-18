extends "res://scripts/ui/lobby_screen.gd"
## 2.0.23 업적 — 금테 메달 카드 + 진행 게이지 + 보상 배지.
## 왼쪽: 기록 카드(메달·이름·설명·진행도·보상·수령 버튼) / 오른쪽: 큰 메달 요약 판.
## 보상은 실제 저장(storage.stats)과 연결되어 한 번만 받을 수 있다.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const LC=T
const DESIGN_HEIGHT:=720.0
const LIST_POS:=Vector2(26,96)
const CARD_W:=426.0
const CARD_H:=122.0
const GAP_X:=14.0
const GAP_Y:=10.0
var rows: Array=[]
var summary: Control
var summary_rect:=Rect2()
var count_label_ref: Label

func build() -> void:
	header("업적","월하의 서원에서 쌓은 기록 · 완료한 항목에는 금빛 인장이 찍힙니다")
	note("업적 보상은 한 번만 받을 수 있고, 진행도는 실제 경기 기록에서 올라갑니다")
	var back=UIK.nine(self,UIK.TEX_PANEL_SOFT,20)
	place(back,Rect2(LIST_POS.x-8,LIST_POS.y-8,CARD_W*2+GAP_X+16,DESIGN_HEIGHT-132))
	var head:=label(self,"서원의 기록",19,P.BRASS_LIGHT,true)
	place(head,Rect2(LIST_POS.x+4,LIST_POS.y+4,300,26))
	count_label_ref=label(self,"",15,P.HANJI_DIM)
	count_label_ref.name="AchievementCount"
	place(count_label_ref,Rect2(LIST_POS.x+CARD_W*2-250,LIST_POS.y+8,250,22))
	count_label_ref.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var rest:=maxf(236.0,DESIGN_WIDTH-26-(LIST_POS.x+CARD_W*2+GAP_X+18))
	summary_rect=Rect2(LIST_POS.x+CARD_W*2+GAP_X+18,LIST_POS.y-8,rest,DESIGN_HEIGHT-132)
	summary=UIK.nine(self,UIK.TEX_PANEL,40)
	place(summary,summary_rect)
	from_scratch()

## 절대 디자인 좌표(부모 위치 포함)로 자식을 놓는다. 부모가 이미 확대돼 있으므로 로컬 = 절대-부모.
func put(parent: Node,node: Control,r: Rect2) -> void:
	place(node,r)

func from_scratch() -> void:
	for row in rows:
		if is_instance_valid(row):row.queue_free()
	rows.clear()
	for child in get_children():
		if child.has_meta("summary_content"):
			remove_child(child)
			child.queue_free()
	var claimed:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):claimed+=1
	var index:=0
	for item in Market.ACHIEVEMENTS:
		_make_card(item,index)
		index+=1
	if is_instance_valid(count_label_ref):
		count_label_ref.text="완료 %d / %d" % [claimed,Market.ACHIEVEMENTS.size()]
	_make_summary(claimed)

func _medal(parent: Node,r: Rect2,done: bool) -> Control:
	var node:=Control.new()
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.set_meta("medal_done",done)
	node.draw.connect(func()->void:
		var c: Vector2=node.size*.5
		var rad:=minf(node.size.x,node.size.y)*.5-2.0
		var accent:=P.BRASS if bool(node.get_meta("medal_done")) else Color(.44,.46,.58)
		for i in range(4):
			node.draw_circle(c,rad+1.0+float(i)*2.4,P.alpha(accent,(.14-float(i)*.03)))
		LC.gradient_rounded(node,Rect2(c-Vector2(rad,rad),Vector2(rad*2.0,rad*2.0)),Color(.15,.16,.24,1.0),Color(.035,.04,.08,1.0),rad)
		node.draw_arc(c,rad,0,TAU,44,Color(0,0,0,.55),2.4,true)
		node.draw_arc(c,rad-1.2,0,TAU,44,accent,2.2,true)
		node.draw_arc(c,rad-4.4,0,TAU,44,P.alpha(accent,.28),1.0,true)
		node.draw_arc(c,rad-1.2,PI*1.06,PI*1.62,22,Color(1,.96,.84,.5),1.5,true)
		G.draw_glyph(node,"trophy",Rect2(c-Vector2(rad*.56,rad*.56),Vector2(rad*1.12,rad*1.12)),accent.lightened(.24),1.8))
	place(node,r)
	return node

func _make_card(item: Dictionary,index: int) -> void:
	var col:=index%2
	var row:=index/2
	var rect:=Rect2(LIST_POS.x+col*(CARD_W+GAP_X),LIST_POS.y+30+row*(CARD_H+GAP_Y),CARD_W,CARD_H)
	var value: int=game.storage.stat(String(item.stat))
	var done: bool=value>=int(item.goal)
	var claimed: bool=(game.storage.data.achievements.claimed as Array).has(String(item.id))
	var holder:=Control.new()
	holder.name="AchievementRow_"+String(item.id)
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	place(holder,rect)
	var frame:=UIK.nine(holder,UIK.TEX_CARD_LIT if (done and not claimed) else UIK.TEX_CARD,22)
	frame.position=Vector2.ZERO
	frame.size=rect.size*s
	_medal(holder,Rect2(rect.position.x+14,rect.position.y+18,58,58),done)
	var name_label:=label(holder,String(item.name),18.5,P.BRASS_LIGHT if done else P.HANJI,true)
	place(name_label,Rect2(rect.position.x+84,rect.position.y+12,CARD_W-200,24))
	var desc:=label(holder,String(item.desc),13.5,Color(.82,.86,.95))
	desc.clip_text=true
	place(desc,Rect2(rect.position.x+84,rect.position.y+36,CARD_W-104,20))
	var gauge:=UIK.Gauge.new()
	gauge.tint=P.BRASS if done else Color(.60,.60,.74)
	gauge.maximum=float(maxi(1,int(item.goal)))
	gauge.value=mini(value,int(item.goal))
	gauge.ticks=0
	holder.add_child(gauge)
	place(gauge,Rect2(rect.position.x+84,rect.position.y+62,CARD_W-196,10))
	var counter:=label(holder,"%d / %d" % [mini(value,int(item.goal)),int(item.goal)],13,P.BRASS_LIGHT if done else P.HANJI_DIM)
	counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	place(counter,Rect2(rect.position.x+CARD_W-108,rect.position.y+56,96,18))
	# 보상 배지
	var reward:=Control.new()
	reward.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(reward)
	place(reward,Rect2(rect.position.x+84,rect.position.y+84,120,26))
	var reward_amount:=int(item.reward)
	reward.draw.connect(func()->void:
		var box:=Rect2(Vector2.ZERO,reward.size)
		var radius:=box.size.y*.5
		LC.gradient_rounded(reward,box,Color(.17,.14,.08,.95),Color(.06,.05,.03,.97),radius)
		LC.rounded_outline(reward,box,P.alpha(P.BRASS,.6),radius,1.2)
		var c:=Vector2(box.size.y*.5,box.size.y*.5)
		reward.draw_circle(c,box.size.y*.30,P.BRASS)
		reward.draw_arc(c,box.size.y*.30,0,TAU,20,P.BRASS_LIGHT,1.2,true)
		reward.draw_circle(c,box.size.y*.13,Color(.35,.22,.05,.8))
		var font:=LC.FONT
		var extent:=maxi(10,int(13.5*s))
		reward.draw_string(font,Vector2(box.size.y*1.0,box.size.y*.5+(font.get_ascent(extent)-font.get_descent(extent))*.5),"보상 "+number(reward_amount),HORIZONTAL_ALIGNMENT_LEFT,-1,extent,P.BRASS_LIGHT))
	var claim=UIK.MetalButton.new()
	claim.kind="gold" if (done and not claimed) else "iron"
	claim.text="수령 완료" if claimed else "보상 받기"
	claim.glyph="check" if claimed else "trophy"
	claim.font_size=int(13)
	claim.name="Claim_"+String(item.id)
	claim.custom_minimum_size=Vector2.ZERO
	claim.disabled=claimed or not done
	claim.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	claim.pressed.connect(func()->void:
		if claim.usable():game.sound.play_clip("button");game.claim_achievement(item))
	holder.add_child(claim)
	place(claim,Rect2(rect.position.x+CARD_W-136,rect.position.y+CARD_H-48,124,38))
	game.button_feel(claim)
	if claimed:
		var seal:=UIK.Seal.new()
		seal.glowing=false
		seal.color=Color(.72,.64,.44)
		holder.add_child(seal)
		seal.position=Vector2(50,8)*s
		seal.size=Vector2(26,26)*s
	rows.append(holder)

func _make_summary(claimed: int) -> void:
	var total:=Market.ACHIEVEMENTS.size()
	var income:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):income+=int(item.reward)
	var box:=summary_rect
	var medal:=Control.new()
	medal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	medal.set_meta("summary_content",true)
	add_child(medal)
	place(medal,Rect2(box.get_center().x-70,box.position.y+24,140,140))
	medal.draw.connect(func()->void:
		var c: Vector2=medal.size*.5
		var rad:=minf(medal.size.x,medal.size.y)*.5-3.0
		for i in range(6):
			medal.draw_circle(c,rad+2.0+float(i)*3.4,P.alpha(P.BRASS,.10-float(i)*.014))
		LC.gradient_rounded(medal,Rect2(c-Vector2(rad,rad),Vector2(rad*2.0,rad*2.0)),Color(.19,.17,.11,1.0),Color(.04,.04,.06,1.0),rad)
		medal.draw_arc(c,rad,0,TAU,52,Color(0,0,0,.55),3.0,true)
		medal.draw_arc(c,rad-1.4,0,TAU,52,P.BRASS,2.6,true)
		medal.draw_arc(c,rad-6.4,0,TAU,52,P.alpha(P.BRASS,.30),1.2,true)
		G.draw_glyph(medal,"trophy",Rect2(c-Vector2(rad*.56,rad*.56),Vector2(rad*1.12,rad*1.12)),P.BRASS_LIGHT,2.2))
	var ratio:=label(self,"%d / %d" % [claimed,total],27,P.BRASS_LIGHT,true)
	ratio.set_meta("summary_content",true)
	ratio.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(ratio,Rect2(box.position.x,box.position.y+176,box.size.x,34))
	var ratio_caption:=label(self,"완료한 업적",13.5,P.HANJI_DIM)
	ratio_caption.set_meta("summary_content",true)
	ratio_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(ratio_caption,Rect2(box.position.x,box.position.y+208,box.size.x,20))
	var overall:=UIK.Gauge.new()
	overall.tint=P.BRASS
	overall.maximum=float(maxi(1,total))
	overall.value=claimed
	overall.ticks=total
	overall.set_meta("summary_content",true)
	add_child(overall)
	place(overall,Rect2(box.position.x+24,box.position.y+242,box.size.x-48,13))
	var line:=divider(self,Color(0.85,0.72,0.47,0.24))
	line.set_meta("summary_content",true)
	place(line,Rect2(box.position.x+24,box.position.y+276,box.size.x-48,1))
	var income_label:=label(self,"받은 보상",13.5,P.HANJI_DIM)
	income_label.set_meta("summary_content",true)
	place(income_label,Rect2(box.position.x+24,box.position.y+290,box.size.x-48,20))
	var income_value:=label(self,"%s 코인"%number(income),22,P.BRASS_LIGHT,true)
	income_value.set_meta("summary_content",true)
	place(income_value,Rect2(box.position.x+24,box.position.y+312,box.size.x-48,28))
	var next_label:=label(self,"다음 목표",13.5,P.HANJI_DIM)
	next_label.set_meta("summary_content",true)
	place(next_label,Rect2(box.position.x+24,box.position.y+356,box.size.x-48,20))
	var y:=382.0
	var shown:=0
	for item in Market.ACHIEVEMENTS:
		if shown>=3:break
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):continue
		if game.storage.stat(String(item.stat))>=int(item.goal):continue
		var entry:=label(self,"· %s"%String(item.name),13.5,P.HANJI)
		entry.set_meta("summary_content",true)
		entry.clip_text=true
		place(entry,Rect2(box.position.x+28,box.position.y+y,box.size.x-104,20))
		var goal:=label(self,"%d / %d" % [game.storage.stat(String(item.stat)),int(item.goal)],12.5,P.BRASS_LIGHT)
		goal.set_meta("summary_content",true)
		goal.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		place(goal,Rect2(box.position.x+box.size.x-100,box.position.y+y,70,20))
		var mini_bar:=UIK.Gauge.new()
		mini_bar.tint=Color(.68,.64,.80)
		mini_bar.maximum=float(maxi(1,int(item.goal)))
		mini_bar.value=game.storage.stat(String(item.stat))
		mini_bar.ticks=0
		mini_bar.set_meta("summary_content",true)
		add_child(mini_bar)
		place(mini_bar,Rect2(box.position.x+32,box.position.y+y+22,box.size.x-64,7))
		y+=44.0
		shown+=1
	if shown==0:
		var all_done:=label(self,"서원의 모든 기록을 세웠습니다.",14,P.BRASS_LIGHT)
		all_done.set_meta("summary_content",true)
		place(all_done,Rect2(box.position.x+24,box.position.y+y,box.size.x-48,22))
	var tip:=label(self,"경기를 끝내면 진행도가 저장됩니다.",12.5,Color(0.76,0.78,0.88,0.92))
	tip.set_meta("summary_content",true)
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(tip,Rect2(box.position.x+24,box.end.y-52,box.size.x-48,40))

func refresh() -> void:
	from_scratch()

func arrange() -> void:
	pass
