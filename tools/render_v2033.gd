extends SceneTree
## 2.0.33 검수 렌더(2340×1080).
##  - v2033_selection_footer_fixed.png : 캐릭터 선택 하단 — 우리 팀(청월 도사 6칸) / VS / 상대 팀(자줏빛 요괴 2칸 비공개) + 겹치지 않는 한 줄 안내
##  - v2033_shop_fixed.png             : 캐릭터를 눌러 미리보기를 다시 그린 뒤에도 금테 판 안에 내용물이 들어간 상점
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2033.gd
const App=preload("res://scenes/survival.tscn")
const OUT="/workspace/downloads/"
var game: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(OUT+name)
	print("RENDER SAVED ",OUT+name," ",image.get_size())

func wait_screen(target: String,seconds: float=25.0) -> void:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.screen==target and not game.changing:return
	print("WAIT TIMEOUT ",target," screen ",game.screen)

func report_selection() -> void:
	var own_label: Node=game.ui.find_child("SelectionOwnLabel",true,false)
	var foe_label: Node=game.ui.find_child("SelectionFoeLabel",true,false)
	var hint: Node=game.ui.find_child("SelectionHint",true,false)
	print("FOOTER own=",game.ui.find_children("SelectionSlot_own_*","Control",true,false).size(),
		" foe=",game.ui.find_children("SelectionSlot_foe_*","Control",true,false).size(),
		" own_label=",own_label.text if own_label!=null else "<missing>",
		" foe_label=",foe_label.text if foe_label!=null else "<missing>",
		" hint=",hint.text if hint!=null else "<missing>",
		" hint_rect=",hint.get_global_rect() if hint!=null else Rect2())

func report_shop() -> void:
	var shop: Node=game.shop
	var frame: Control=shop.preview_frame
	var body: Control=shop.preview_body
	print("SHOP frame=",frame.get_global_rect()," body=",body.position)
	var inside:=true
	for child in body.get_children():
		if not (child is Control):continue
		var r: Rect2=child.get_global_rect()
		if not frame.get_global_rect().encloses(r):
			inside=false
			print("  OUTSIDE ",child.get_class()," ",child.name," ",r)
	print("SHOP all_inside_frame=",inside)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(16)
	game.enter_from_title()
	var nick_deadline:=Time.get_ticks_msec()+20000
	while Time.get_ticks_msec()<nick_deadline:
		await process_frame
		if game.screen=="nickname" and not game.changing:break
	if game.screen=="nickname":
		game.nickname_input.text="달빛전우치"
		await frames(3)
		game.submit_nickname()
	await wait_screen("lobby")
	await frames(8)

	# ── 빠른 매치(도사 배정) 캐릭터 선택
	game.preferred_role="daoist"
	game.open_quick()
	await wait_screen("quick")
	await frames(6)
	game.finish_matching()
	await wait_screen("selection")
	await frames(12)
	report_selection()
	await capture("v2033_selection_footer_fixed.png")

	# ── 상점: 캐릭터를 눌러 미리보기를 다시 그린 뒤에도 금테 판 안에 들어가는지
	game.cleanup_match()
	game.build("lobby")
	await frames(10)
	game.market_screen()
	await frames(20)
	game.shop.select_item("daoist:jangyeongsil")
	await frames(12)
	report_shop()
	await capture("v2033_shop_fixed.png")
	quit()
