extends SceneTree
## 2.0.33 검증: 캐릭터 선택 하단.
##  1) 우리 팀(청월) 슬롯과 상대 팀(자줏빛·비공개) 슬롯이 VS를 사이에 두고 분리된다.
##  2) 빠른 매치 진영 잠금 안내와 공개 안내가 겹치지 않는다(하단 라벨 전수 검사).
##  3) 1280×720 · 2340×1080(20:9) · 2400×1080에서도 라벨·슬롯·확정 버튼이 화면 안에서 겹치지 않는다.
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
var game: Node

func _initialize() -> void:run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks+=1
	print("V33FOOTER ",checks," ",message," = ",ok)
	if not ok:failures+=1;push_error(message)

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func wait_screen(target: String,seconds: float=25.0) -> void:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.screen==target and not game.changing:return

func quick(preference: String) -> void:
	game.preferred_role=preference
	game.open_quick()
	await wait_screen("quick")
	await frames(4)
	game.finish_matching()
	await wait_screen("selection")
	await frames(6)

func named(value: String) -> Node:
	return game.ui.find_child(value,true,false)

## 하단 바 안의 글자가 있는 라벨만 모은다(빈 라벨·숨은 라벨은 뺀다).
func footer_labels(view: Node) -> Array:
	var out: Array=[]
	for child in view.footer_layer.get_children():
		if child is Label and child.visible and String(child.text)!="":out.append(child)
	return out

func slots(view: Node,group: String) -> Array:
	var out: Array=[]
	for child in view.strip.get_children():
		if String(child.name).begins_with("SelectionSlot_%s_" % group):out.append(child)
	return out

## 모든 라벨·슬롯·확정 버튼이 서로 겹치지 않는지 전수 검사한다.
func check_no_overlap(view: Node,tag: String) -> void:
	var labels:=footer_labels(view)
	check(labels.size()>=4,tag+" footer carries its labels")
	var boxes: Array=[]
	for label in labels:boxes.append({"name":"label:"+String(label.text),"rect":label.get_global_rect()})
	for group in ["own","foe"]:
		for slot in slots(view,group):
			boxes.append({"name":"slot:"+String(slot.name),"rect":slot.get_global_rect()})
	var confirm: Control=view.confirm_button
	if is_instance_valid(confirm):boxes.append({"name":"confirm","rect":confirm.get_global_rect()})
	var clashes:=0
	for i in range(boxes.size()):
		for j in range(i+1,boxes.size()):
			var a: Rect2=boxes[i].rect
			var b: Rect2=boxes[j].rect
			if a.intersects(b):
				clashes+=1
				print("  OVERLAP ",boxes[i].name," ",a," <> ",boxes[j].name," ",b)
	check(clashes==0,tag+" footer labels, slots and CTA never overlap")

## 라벨과 슬롯이 실제 배치된 하단 판 안에 들어오는지 확인한다.
func check_inside(view: Node,tag: String) -> void:
	var plate: Control=view.footer_layer.get_child(0)
	var plate_rect:=plate.get_global_rect()
	var inside:=true
	for label in footer_labels(view):
		if not plate_rect.encloses(label.get_global_rect()):
			inside=false
			print("  OUTSIDE ",label.text," ",label.get_global_rect()," plate ",plate_rect)
	for group in ["own","foe"]:
		for slot in slots(view,group):
			if not plate_rect.encloses(slot.get_global_rect()):inside=false
	check(inside,tag+" every footer element sits inside the footer plate")

## 우리 팀 그룹은 VS 왼쪽, 상대 팀 그룹은 VS 오른쪽, 확정 버튼은 그 오른쪽.
func check_groups(view: Node,own_count: int,foe_count: int,tag: String) -> void:
	var own_slots:=slots(view,"own")
	var foe_slots:=slots(view,"foe")
	check(own_slots.size()==own_count,tag+" our team group holds %d slots (got %d)" % [own_count,own_slots.size()])
	check(foe_slots.size()==foe_count,tag+" enemy team group holds %d slots (got %d)" % [foe_count,foe_slots.size()])
	var own_right:=0.0
	for slot in own_slots:own_right=maxf(own_right,slot.get_global_rect().end.x)
	var foe_left:=99999.0
	for slot in foe_slots:foe_left=minf(foe_left,slot.get_global_rect().position.x)
	var vs: Control=named("SelectionVs")
	check(vs!=null,tag+" VS divider exists")
	if vs!=null:
		var vs_rect:=vs.get_global_rect()
		check(own_right<=vs_rect.position.x and vs_rect.end.x<=foe_left,tag+" VS divider sits between the two groups")
	# 적 슬롯은 캐릭터를 드러내지 않는다.
	var masked:=true
	for slot in foe_slots:
		if not bool(slot.get_meta("concealed",false)):masked=false
	check(masked,tag+" enemy slots stay concealed")
	var own_tint:=true
	for slot in own_slots:
		if String(slot.get_meta("team",""))!="own":own_tint=false
	check(own_tint,tag+" our slots are tagged as our team")
	# 확정 버튼은 두 그룹보다 오른쪽에 있고 화면 안에 있다.
	var confirm: Control=view.confirm_button
	check(is_instance_valid(confirm),tag+" confirm button exists")
	if is_instance_valid(confirm):
		var c:=confirm.get_global_rect()
		check(c.position.x>=foe_left,tag+" confirm button sits right of both groups")
		check(game.get_viewport().get_visible_rect().encloses(c),tag+" confirm button fits the screen")

func run() -> void:
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(10)
	game.enter_from_title()
	var nick_deadline:=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<nick_deadline:
		await process_frame
		if game.screen=="nickname" and not game.changing:break
	if game.screen=="nickname":
		game.nickname_input.text="달빛전우치"
		await frames(3)
		game.submit_nickname()
	await wait_screen("lobby")
	await frames(6)

	# ── 1) 도사 배정 빠른 매치: 우리 팀 도사 6 / 상대 팀 요괴 2
	await quick("daoist")
	var view: Node=game.selection_view
	check(view!=null,"quick match opens the selection screen")
	check(String(view.side())=="daoist","our side is daoist")
	var own_label: Label=named("SelectionOwnLabel")
	var foe_label: Label=named("SelectionFoeLabel")
	var hint: Label=named("SelectionHint")
	check(own_label!=null and String(own_label.text).contains("우리 팀") and String(own_label.text).contains("도사"),"our group label names our team and side")
	check(foe_label!=null and String(foe_label.text).contains("상대 팀") and String(foe_label.text).contains("요괴"),"enemy group label names the other team")
	check(hint!=null and String(hint.text).contains("배정된 진영만 선택") and String(hint.text).contains("경기 시작 때 공개"),"lock note and reveal note share one line")
	var hint_dupes:=0
	for label in footer_labels(view):
		if label!=hint and String(label.text).contains("배정된 진영만 선택"):hint_dupes+=1
	check(hint_dupes==0,"no second lock note is drawn")
	check_groups(view,6,2,"20:9")
	check_no_overlap(view,"20:9")
	check_inside(view,"20:9")
	# 하단 안내는 확정 대기 문구와 겹치지 않는다.
	var ready: Label=named("SelectionReady")
	check(ready!=null and not hint.get_global_rect().intersects(ready.get_global_rect()),"hint does not touch the ready note")

	# ── 2) 화면 크기를 바꿔도 같은 규칙
	for size in [Vector2i(1280,720),Vector2i(2400,1080)]:
		root.size=size
		await frames(8)
		check_no_overlap(view,str(size))
		check_inside(view,str(size))
		check_groups(view,6,2,str(size))

	# ── 3) 요괴 희망 빠른 매치: 우리 팀 요괴 2 / 상대 팀 도사 6
	root.size=Vector2i(2340,1080)
	await frames(4)
	game.cleanup_match()
	game.build("lobby")
	await frames(8)
	await quick("yokai")
	view=game.selection_view
	check(String(view.side())=="yokai","yokai preference puts us on the yokai side")
	var own2: Label=named("SelectionOwnLabel")
	check(own2!=null and String(own2.text).contains("요괴"),"our group label follows the assigned side")
	check_groups(view,2,6,"yokai 20:9")
	check_no_overlap(view,"yokai 20:9")
	check_inside(view,"yokai 20:9")

	print("V33FOOTER SUMMARY checks=",checks," failures=",failures)
	quit(1 if failures>0 else 0)
