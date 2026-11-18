extends "res://scripts/ui/lobby_screen.gd"
## 업적: 두루마리에 기록을 늘어놓고, 완료된 항목에는 금빛 인장을 찍는다.
## 보상은 실제 저장(storage.stats)과 연결되어 한 번만 받을 수 있다.
const LIST_POS:=Vector2(26,96)
const LIST_SIZE:=Vector2(900,548)
const ROW_HEIGHT:=54.0
const ROW_GAP:=6.0
var rows: Array=[]
var summary: Control

func build() -> void:
	header("업적","월하의 서원에서 쌓은 기록 · 완료한 항목은 금빛 인장이 찍힙니다")
	note("업적 보상은 한 번만 받을 수 있고, 진행도는 실제 경기 기록에서 올라갑니다")
	var scroll:=panel(self,Color(0.055,0.05,0.075,0.94),10,Color(0.6,0.35,0.2,0.18))
	place(scroll,Rect2(LIST_POS,LIST_SIZE))
	var top_roller:=Art.Roller.new()
	add_child(top_roller)
	place(top_roller,Rect2(LIST_POS.x+2,LIST_POS.y-16,LIST_SIZE.x-4,26))
	var bottom_roller:=Art.Roller.new()
	add_child(bottom_roller)
	place(bottom_roller,Rect2(LIST_POS.x+2,LIST_POS.y+LIST_SIZE.y-10,LIST_SIZE.x-4,26))
	var heading:=label(self,"서원의 기록",15,T.GOLD_SOFT,true)
	place(heading,Rect2(LIST_POS.x+24,LIST_POS.y+8,300,24))
	var counts:=label(self,"",12,T.MUTED)
	counts.name="AchievementCount"
	place(counts,Rect2(LIST_POS.x+LIST_SIZE.x-260,LIST_POS.y+10,232,20))
	counts.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var rule_line:=divider(self,Color(0.85,0.72,0.47,0.22))
	place(rule_line,Rect2(LIST_POS.x+24,LIST_POS.y+34,LIST_SIZE.x-48,1))
	summary=panel(self,Color(0.05,0.05,0.1,0.92),14,Color(0.6,0.5,1.0,0.15))
	place(summary,Rect2(LIST_POS.x+LIST_SIZE.x+18,96,1280-52-LIST_SIZE.x-18,548))
	from_scratch()

func from_scratch() -> void:
	for row in rows:
		if is_instance_valid(row):row.queue_free()
	rows.clear()
	for child in summary.get_children():
		if child.has_meta("content"):child.queue_free()
	var claimed:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):claimed+=1
	var index:=0
	for item in Market.ACHIEVEMENTS:
		_make_row(item,index)
		index+=1
	var counts: Label=find_child("AchievementCount",true,false)
	if counts!=null:counts.text="완료 %d / %d" % [claimed,Market.ACHIEVEMENTS.size()]
	_make_summary(claimed)

func _make_row(item: Dictionary,index: int) -> void:
	var row_rect:=Rect2(LIST_POS.x+22,LIST_POS.y+42+index*(ROW_HEIGHT+ROW_GAP),LIST_SIZE.x-44,ROW_HEIGHT)
	var value: int=game.storage.stat(String(item.stat))
	var done: bool=value>=int(item.goal)
	var claimed: bool=(game.storage.data.achievements.claimed as Array).has(String(item.id))
	var back:=panel(self,Color(0.02,0.03,0.06,0.55) if not done else Color(0.12,0.09,0.04,0.55),8,Color(0.6,0.5,1.0,0.1),false)
	back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	place(back,row_rect)
	rows.append(back)
	var seal:=Art.Stamp.new()
	seal.color=Color(0.85,0.70,0.36,1.0) if done else Color(0.30,0.32,0.42,0.85)
	add_child(seal)
	place(seal,Rect2(row_rect.position.x+10,row_rect.position.y+13,28,28))
	if claimed:
		var mark:=label(self,"수령",9.5,Color(0.72,0.25,0.24,1.0))
		mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		place(mark,Rect2(row_rect.position.x+8,row_rect.position.y+34,32,14))
	var name_label:=label(self,String(item.name),14.5,T.GOLD_SOFT if done else T.IVORY,true)
	place(name_label,Rect2(row_rect.position.x+48,row_rect.position.y+6,300,22))
	var desc:=label(self,String(item.desc),11.5,Color(0.76,0.80,0.9))
	place(desc,Rect2(row_rect.position.x+48,row_rect.position.y+29,340,18))
	var bar:=Art.Bar.new()
	bar.tint=Color(0.85,0.72,0.47) if done else Color(0.62,0.6,0.78)
	add_child(bar)
	place(bar,Rect2(row_rect.position.x+398,row_rect.position.y+26,180,8))
	bar.set_value(mini(value,int(item.goal)),float(item.goal))
	var counter:=label(self,"%d / %d"%[mini(value,int(item.goal)),int(item.goal)],11.5,T.gold(.85) if done else T.MUTED)
	place(counter,Rect2(row_rect.position.x+586,row_rect.position.y+20,84,18))
	var reward:=label(self,"보상 %s 코인"%number(int(item.reward)),11.5,T.gold(.8))
	place(reward,Rect2(row_rect.position.x+398,row_rect.position.y+4,180,16))
	var claim:=button("수령 완료" if claimed else "보상 받기",func()->void:game.claim_achievement(item),self,not claimed and done,12)
	claim.name="Claim_"+String(item.id)
	place(claim,Rect2(row_rect.position.x+row_rect.size.x-116,row_rect.position.y+9,106,36))
	claim.disabled=claimed or not done

func _make_summary(claimed: int) -> void:
	var total:=Market.ACHIEVEMENTS.size()
	var income:=0
	for item in Market.ACHIEVEMENTS:
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):income+=int(item.reward)
	var box:=Rect2(LIST_POS.x+LIST_SIZE.x+18,96,1280-52-LIST_SIZE.x-18,548)
	var seal:=Art.Stamp.new()
	seal.color=Color(0.80,0.64,0.30,1.0)
	summary.add_child(seal)
	seal.set_meta("content",true)
	place(seal,Rect2(box.get_center().x-44,box.position.y+18,88,88))
	var ratio:=label(summary,"%d / %d" % [claimed,total],20,T.GOLD_SOFT,true)
	ratio.set_meta("content",true)
	ratio.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(ratio,Rect2(box.position.x,box.position.y+112,box.size.x,28))
	var ratio_caption:=label(summary,"완료한 업적",11.5,T.MUTED)
	ratio_caption.set_meta("content",true)
	ratio_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(ratio_caption,Rect2(box.position.x,box.position.y+140,box.size.x,18))
	var line:=divider(summary,Color(0.85,0.72,0.47,0.25))
	line.set_meta("content",true)
	place(line,Rect2(box.position.x+16,box.position.y+168,box.size.x-32,1))
	var income_label:=label(summary,"받은 보상",11.5,T.MUTED)
	income_label.set_meta("content",true)
	place(income_label,Rect2(box.position.x+16,box.position.y+180,box.size.x-32,18))
	var income_value:=label(summary,"%s 코인"%number(income),17,T.GOLD_SOFT,true)
	income_value.set_meta("content",true)
	place(income_value,Rect2(box.position.x+16,box.position.y+200,box.size.x-32,24))
	var next_label:=label(summary,"다음 보상",11.5,T.MUTED)
	next_label.set_meta("content",true)
	place(next_label,Rect2(box.position.x+16,box.position.y+242,box.size.x-32,18))
	var y:=262.0
	for item in Market.ACHIEVEMENTS:
		if y>420.0:break
		if (game.storage.data.achievements.claimed as Array).has(String(item.id)):continue
		if game.storage.stat(String(item.stat))>=int(item.goal):continue
		var entry:=label(summary,"· %s"%String(item.name),11.5,T.IVORY)
		entry.set_meta("content",true)
		place(entry,Rect2(box.position.x+16,box.position.y+y,box.size.x-32,18))
		var goal:=label(summary,"%d / %d" % [game.storage.stat(String(item.stat)),int(item.goal)],10.5,T.MUTED)
		goal.set_meta("content",true)
		place(goal,Rect2(box.position.x+16,box.position.y+y+18,box.size.x-32,16))
		y+=44.0
	var tip:=label(summary,"경기를 끝내면 진행도가 저장됩니다.",10.5,Color(0.68,0.72,0.82,0.8))
	tip.set_meta("content",true)
	tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(tip,Rect2(box.position.x+16,box.position.y+470,box.size.x-32,40))

func refresh() -> void:
	from_scratch()

func arrange() -> void:
	pass
