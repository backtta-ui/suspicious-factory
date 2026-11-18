extends SceneTree
## 2.0.26 검수 렌더: 확장된 월하의 서원 전체 탑뷰 + 봉인/둔갑 인게임 장면.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2026.gd
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
	for i in range(600):
		await process_frame
		if i%60==0:print("WAIT ",target," frame ",i," screen ",game.screen," changing ",game.changing)
		if game.screen==target and not game.changing:return
	print("WAIT TIMEOUT ",target," screen ",game.screen)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(16)
	game.build("lobby");await frames(6)
	game.preferred_role="daoist"
	print("START PRACTICE")
	game.start_practice_match()
	await wait_screen("match")
	await frames(24)
	game.set_process(false)
	game.rules.phase="live"
	game.rules.elapsed=30.0
	var me: Dictionary=game.rules.players.human
	# ---------------------------------------------------------------- 1) 전체 탑뷰
	var daoists: Array=game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")
	var yokai: Array=game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")
	for i in range(mini(daoists.size(),6)):
		var p: Dictionary=daoists[i]
		p.position=L.daoist_spawns()[i%L.daoist_spawns().size()]
		p.ground=p.position;p.eliminated=false;p.captured=false;p.immune=0
	for i in range(mini(yokai.size(),2)):
		yokai[i].position=L.yokai_spawns()[i%L.yokai_spawns().size()]
		yokai[i].ground=yokai[i].position
	game.ui.visible=false
	root.size=Vector2i(1700,1300)
	await frames(4)
	var fit: float=1700.0/L.SIZE.x*.995
	game.camera.zoom=Vector2(fit,fit)
	game.camera.position=L.SIZE*.5
	game.camera.limit_left=-400;game.camera.limit_top=-400
	game.camera.limit_right=int(L.SIZE.x)+400;game.camera.limit_bottom=int(L.SIZE.y)+400
	game.update_avatars();await frames(10)
	await capture("v2026_big_map_overview.png")
	# ---------------------------------------------------------------- 2) 봉인·둔갑 장면(HUD 포함)
	game.ui.visible=true
	root.size=Vector2i(2340,1080)
	await frames(4)
	game.camera.limit_left=0;game.camera.limit_top=0
	game.camera.limit_right=int(L.SIZE.x);game.camera.limit_bottom=int(L.SIZE.y)
	game.camera.zoom=Vector2(L.CAMERA_ZOOM,L.CAMERA_ZOOM)
	# 중앙 마당의 사물 무리 곁에 내 도사를 둔갑시켜 세우고, 요괴를 바로 앞에 둔다.
	var spot: Vector2=Vector2(1620,1816)
	me.position=spot+Vector2(0,26);me.ground=me.position;me.facing=6
	me.form="crate";me.buff.transform=game.rules.elapsed+9
	me.lives=2
	if not yokai.is_empty():
		yokai[0].position=spot+Vector2(40,70);yokai[0].ground=yokai[0].position;yokai[0].facing=6
	var other: Dictionary=daoists[0] if not daoists.is_empty() else me
	other.captured=true;other.deadline=game.rules.elapsed+7
	other.position=spot+Vector2(-120,40);other.ground=other.position
	game.rules.events.append({"kind":"seal","actor":String(yokai[0].id) if not yokai.is_empty() else "bot-1","target":String(other.id),"time":game.rules.elapsed})
	game.event_cursor=game.rules.events.size()-1
	game.show_banner(String(other.name)+"님이 봉인되었습니다! (10초)",Color("ffb0bf"))
	game.banner_left=2.7
	if game.hud_view!=null:game.hud_view.banner_alpha=1.0
	game.count_label.visible=false
	game.update_avatars()
	for i in range(6):await process_frame
	await capture("v2026_contact_seal.png")
	print("V2026 RENDER DONE")
	quit()
