extends SceneTree
## 2.0.28 검수 렌더: 도감(전체·스킬 상세·스킨 미리보기) · 상점 1/2페이지·스킨 탭 ·
## 동물 크기(고양이·강아지 vs 항아리·상자) · 도술 이펙트(화중은신·분신술·도깨비잔치).
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2028.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT+name
	image.save_png(path)
	print("RENDER SAVED ",path," ",image.get_size())

func wait_screen(target: String) -> void:
	for i in range(900):
		await process_frame
		if game.screen==target and not game.changing:return
	print("WAIT TIMEOUT ",target," screen ",game.screen)

## 이전 장면의 잔여 효과(면역·감지·표식)를 지워 깨끗한 그림을 잡는다.
func p_stale_clear(authority: RefCounted) -> void:
	for p in authority.players.values():
		p.buff={};p.immune=0.0;p.stun=0.0;p.blind_until=0.0;p.slow_until=0.0;p.captured=false
	authority.reveal_until=0.0;authority.map_dark_until=0.0;authority.dark_until=0.0
	authority.trail_all_until=0.0;authority.lantern_until.clear();authority.marks.clear();authority.pings.clear()

func codex() -> Node:
	for node in game.ui.get_children():
		if node.get_script()!=null and String(node.get_script().resource_path).ends_with("codex.gd"):return node
	return null

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(16)
	game.build("lobby");await frames(6)
	# ---------------------------------------------------------------- 1) 도감 전체
	game.codex_filter="all"
	game.build("characters");await frames(10)
	var book: Node=codex()
	print("CODEX NODE ",book!=null)
	await frames(6)
	await capture("v2028_codex_all.png")
	# 2) 스킬 상세(홍길동 궁극기 = 팔방도약) — 카드/쿨타임/설명/도포 스킨이 겹치지 않는지.
	book._select("daoist:honggildong")
	await frames(6)
	book._show_tip(2)
	await frames(6)
	await capture("v2028_codex_skill_tip.png")
	# 3) 도포 스킨 미리보기(미보유 = 달빛 도포)
	var moon: Dictionary={}
	for item in preload("res://scripts/survival/market.gd").SKINS:
		if String(item.id)=="moon":moon=item
	book._pick_skin(moon)
	await frames(8)
	await capture("v2028_codex_skin_preview.png")
	# ---------------------------------------------------------------- 4) 상점 1/2 페이지 + 스킨 탭
	game.build("market");await frames(12)
	await capture("v2028_shop_characters_p1.png")
	game.shop.turn_page(1);await frames(8)
	await capture("v2028_shop_characters_p2.png")
	game.shop.set_tab("skin");await frames(10)
	await capture("v2028_shop_skins.png")
	# ---------------------------------------------------------------- 5) 인게임: 동물 크기·도술 이펙트
	game.build("lobby");await frames(4)
	game.preferred_role="daoist"
	game.start_practice_match()
	await wait_screen("match")
	await frames(20)
	game.set_process(false)
	game.rules.phase="live";game.rules.elapsed=30.0
	if game.rules.walkers.is_empty():game.rules.build_walkers()
	var me: Dictionary=game.rules.players.human
	# 동물과 사물을 한 화면에 모아 크기를 비교한다(항아리·상자 vs 고양이·강아지).
	var spot: Vector2=Vector2(1430,560)
	var jar: Dictionary=L.OBJECTS[L.OBJECTS.size()-1]
	game.rules.effects.clear();game.rules.traps.clear()
	me.position=spot+Vector2(-40,40);me.ground=me.position;me.facing=2
	me.form="";me.buff={};me.cd={};me.immune=0.0;p_stale_clear(game.rules)
	var walkers: Array=game.rules.walkers
	if walkers.size()>=4:
		walkers[0].p=jar.p+Vector2(70,10);walkers[0].moving=false;walkers[0].phase=0.0;walkers[0].facing=2
		walkers[1].p=jar.p+Vector2(120,14);walkers[1].moving=false;walkers[1].phase=0.0;walkers[1].facing=2
		walkers[2].p=jar.p+Vector2(-60,18);walkers[2].moving=false;walkers[2].phase=0.0;walkers[2].facing=6
	game.camera.position=jar.p+Vector2(20,0)-Vector2(0,L.CAMERA_LIFT)
	game.camera.zoom=Vector2(L.CAMERA_ZOOM,L.CAMERA_ZOOM)
	game.update_avatars();game.update_hud()
	await frames(12)
	await capture("v2028_ingame_animals.png")
	# 화중은신: 족자를 펼치고 그림 속으로 숨는 장면(본인 시점에는 반투명 먹잔상).
	me.character="daoist:woochi";me.role="daoist"
	me.position=L.SPAWN+Vector2(-90,10);me.ground=me.position
	me.cd={};me.ult=game.rules.ULT_MAX
	me.trail=[];me.buff={}
	game.camera.position=me.position-Vector2(0,L.CAMERA_LIFT)
	game.rules.skill(me,Vector2.RIGHT,"ult")
	game.update_avatars();game.update_hud()
	for i in range(6):
		await process_frame
	await capture("v2028_ingame_painting.png")
	# 분신술 + 도깨비잔치: 분신이 서 있고 요괴의 도깨비불이 터지는 장면.
	me.buff={};me.cd={};me.ult=game.rules.ULT_MAX
	me.position=L.SPAWN+Vector2(-90,10);me.ground=me.position
	game.rules.skill(me,Vector2.RIGHT,"main")
	var yokai: Dictionary={}
	for p in game.rules.players.values():
		if p.role=="yokai":yokai=p;break
	if not yokai.is_empty():
		yokai.position=L.SPAWN+Vector2(60,30);yokai.ground=yokai.position;yokai.character="yokai:dokkaebi";yokai.cd={};yokai.ult=game.rules.ULT_MAX
		game.rules.skill(yokai,Vector2.LEFT,"ult")
	game.update_avatars();game.update_hud()
	for i in range(3):
		await process_frame
	await capture("v2028_ingame_skills.png")
	# 8방향 걷기: 대각선(남서 front_left·북동 back_right)으로 걷는 모습.
	me.buff={};me.cd={};me.immune=0.0
	game.rules.effects.clear()
	me.position=L.SPAWN+Vector2(-60,20);me.ground=me.position;me.facing=5
	me.intent=Vector2(-1,1).normalized()*0.0
	var rival: Dictionary={}
	for p in game.rules.players.values():
		if p.role=="yokai":rival=p;break
	if not rival.is_empty():
		rival.position=L.SPAWN+Vector2(90,-30);rival.ground=rival.position;rival.facing=7
		rival.character="yokai:gumiho"
	game.camera.position=me.position-Vector2(0,L.CAMERA_LIFT)
	for i in range(20):
		me.facing=5;me.intent=Vector2(-1,1).normalized()*.6
		if not rival.is_empty():rival.facing=7;rival.intent=Vector2(1,-1).normalized()*.5
		game.update_avatars();game.update_hud()
		await process_frame
	me.intent=Vector2.ZERO
	if not rival.is_empty():rival.intent=Vector2.ZERO
	print("8DIR rows: human=",game.avatars["human"].ingame_sprite.current_key if game.avatars.has("human") else "-")
	await capture("v2028_ingame_8dir.png")
	print("V2028 RENDER DONE")
	quit()
