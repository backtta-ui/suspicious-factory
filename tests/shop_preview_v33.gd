extends SceneTree
## 2.0.33 검증: 상점 오른쪽 미리보기 판.
## 캐릭터를 눌러 미리보기를 다시 그린 뒤에도 금테 판과 내용물(제목·그림·이름·배지·설명·
## 대표 능력·해금 버튼)이 같은 x 기준에 놓여 판 안에 들어가고, 20:9에서는 판이 오른쪽 끝에 붙는다.
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
var game: Node

func _initialize() -> void:run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks+=1
	print("V33SHOP ",checks," ",message," = ",ok)
	if not ok:failures+=1;push_error(message)

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func wait_screen(target: String,seconds: float=20.0) -> void:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.screen==target and not game.changing:return

## 판과 판 안 내용물이 같은 기준 x에 있는지(내용물이 판 밖으로 나가지 않는지).
func check_preview(tag: String) -> void:
	var shop: Node=game.shop
	var frame: Control=shop.preview_frame
	var body: Control=shop.preview_body
	check(is_instance_valid(frame) and is_instance_valid(body),tag+" preview frame and body exist")
	if not (is_instance_valid(frame) and is_instance_valid(body)):return
	var box:=frame.get_global_rect()
	var outside: Array=[]
	for child in body.get_children():
		if not (child is Control):continue
		var rect: Rect2=child.get_global_rect()
		if rect.size==Vector2.ZERO:continue
		if not box.encloses(rect):outside.append("%s %s" % [child.get_class(),rect])
	check(outside.is_empty(),tag+" every preview element stays inside the gold frame %s" % [outside])
	# 부제목 '달빛 미리보기'가 판 안쪽 가운데에 온다.
	var heading: Label=null
	var centered:=true
	for child in body.get_children():
		if child is Label and String(child.text)=="달빛 미리보기":heading=child
	check(heading!=null,tag+" preview heading exists")
	if heading!=null:
		var gap:=absf(heading.get_global_rect().get_center().x-box.get_center().x)
		centered=gap<=2.0
		check(centered,tag+" preview heading is centred in the frame (off by %.1f)" % gap)
	# 20:9에서는 판이 화면 오른쪽 끝에 붙는다.
	var want:=float(shop.dw)-16.0
	check(absf(box.end.x-want)<=2.0,tag+" preview frame hugs the right edge (%.1f vs %.1f)" % [box.end.x,want])

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
	game.market_screen()
	await frames(12)
	check(game.shop!=null,"shop screen opens")

	check_preview("20:9 first paint")
	# 캐릭터를 눌러 미리보기를 다시 그린다(제보 경로).
	game.shop.select_item("daoist:jangyeongsil")
	await frames(8)
	check_preview("20:9 after picking a character")
	check(String(game.shop.selected_id)=="daoist:jangyeongsil","picking a card changes the selection")
	game.shop.select_item("daoist:barigongju")
	await frames(8)
	check_preview("20:9 after picking another character")
	# 탭을 바꿔도 판 안에 남는다.
	game.shop.set_tab("skin")
	await frames(8)
	check_preview("20:9 skin tab")
	game.shop.set_tab("character")
	await frames(8)

	for size in [Vector2i(1280,720),Vector2i(2400,1080)]:
		root.size=size
		await frames(10)
		check_preview(str(size))
		game.shop.select_item("daoist:woochi")
		await frames(8)
		check_preview(str(size)+" after picking a character")

	print("V33SHOP SUMMARY checks=",checks," failures=",failures)
	quit(1 if failures>0 else 0)
