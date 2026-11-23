extends SceneTree
## 2.0.39 검증 캡처: 4맵 · 스킨별 도술 VFX · 궁극기 남은 초 · 상점/선택창 스킨 미리보기.
## 결과는 /workspace/downloads/v2039v_*.png
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node
var L: Script
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func capture(name: String) -> void:
	for i in range(3):await process_frame
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty():print("EMPTY ",name);return
	image.save_png(OUT+name);print("RENDER SAVED ",name)
func wait_screen(target: String) -> void:
	for i in range(900):
		await process_frame
		if game.screen==target and not game.changing:return
func start(id: String) -> void:
	game.cleanup_match();game.build("lobby");await frames(4)
	game.preferred_role="daoist"
	game.create_room("2.0.39 검증",8,true,"",2,id)
	for i in range(240):
		await process_frame
		if game.screen=="room" and not game.changing:break
	game.rules.players.human.ready=true
	game.start_match();await frames(6)
	game.rules.confirm_character("human")
	for i in range(300):
		if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
		if game.rules.phase=="loading":break
		await process_frame
	await wait_screen("match")
	for i in range(80):
		if game.rules.phase=="live":break
		game.rules.tick(.2)
	L=game.L
	game.rules.elapsed=120.0
	game.rules.players.human.immune=game.rules.elapsed+300.0
	game.banner_left=0.0
func place(at: Vector2,zoom: float=1.45) -> void:
	var human: Dictionary=game.rules.players.human
	human.position=at;human.ground=at;human.captured=false;human.eliminated=false
	game.update_avatars()
	game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
	game.camera.zoom=Vector2(zoom,zoom)
	await frames(4)
	game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
	game.camera.zoom=Vector2(zoom,zoom)
	await frames(2)
func clear_area() -> void:
	for p in game.rules.players.values():
		if String(p.id)=="human":continue
		var far: Vector2=L.SPAWN+Vector2(60,60)
		p.position=far;p.ground=far;p.intent=Vector2.ZERO;p.captured=false;p.eliminated=true
		var actor: Node=game.avatars.get(String(p.id))
		if actor!=null:actor.visible=false
	game.update_avatars()
## 내 캐릭터를 전우치로 고정하고 스킨을 입힌 뒤, 지정 도술의 서명 연출을
## 고정된 진행도(p)로 그려 검증 컷을 만든다(렌더러가 느려도 같은 단계가 잡힌다).
func cast_painting(skin: String,slot: String,file_tag: String) -> void:
	var human: Dictionary=game.rules.players.human
	human.character="daoist:woochi"
	human.skin=skin
	human.cd={};human.ult=game.rules.ULT_MAX
	human.form="";human.buff.erase("transform")
	game.storage.equip_skin("daoist:woochi",skin if skin!="" else "default")
	game.update_avatars()
	await frames(3)
	human.position=L.SPAWN;human.ground=human.position
	await place(L.SPAWN,1.75)
	var skill_id:=String(C.ability("daoist:woochi",slot).get("skill",""))
	# 실제 시전도 한 번(규칙 경로 검증) + 고정 프레임 오버레이(화면 검증).
	human.cd={};human.ult=game.rules.ULT_MAX
	game.rules.skill(human,Vector2.DOWN,slot)
	await frames(2)
	for stage in [[0.28,"a"],[0.52,"b"]]:
		var fx:=Node2D.new()
		fx.z_index=12
		var progress: float=stage[0]
		var skin_key: String=skin
		var skill_key: String=skill_id
		fx.draw.connect(func()->void:
			preload("res://scripts/survival/fx.gd").signature(fx,L.SPAWN,progress,skill_key,2.0,skin_key))
		game.world.add_child(fx)
		await frames(2)
		await capture("v2039v_vfx_%s_%s_%s.png"%[file_tag,slot,stage[1]])
		fx.queue_free()
		await frames(1)
func run() -> void:
	root.size=Vector2i(1600,720)
	game=App.instantiate();root.add_child(game);await frames(10)
	# ── 4맵
	for map_id in ["gangnam","dongseongno","haeundae","seowon"]:
		await start(map_id)
		clear_area()
		var spots={"gangnam":Vector2(560,1090),"dongseongno":Vector2(1600,1400),"haeundae":Vector2(2100,1850),"seowon":Vector2(1650,1300)}
		await place(spots[map_id],1.20)
		await capture("v2039v_map_%s.png"%map_id)
	# ── 스킨별 VFX: 기본 vs 부침개 (분신·둔갑·화중은신)
	await start("gangnam")
	clear_area()
	for combo in [["","default"],["woochi_pancake","pancake"]]:
		for slot in ["main","sub","ult"]:
			await cast_painting(String(combo[0]),slot,String(combo[1]))
	# ── HUD: 궁극기 남은 초(잠김)
	await start("gangnam")
	var me: Dictionary=game.rules.players.human
	me.ult=game.rules.ULT_MAX-10.1
	game.update_hud();await frames(3)
	await capture("v2039v_hud_ult_countdown.png")
	me.ult=game.rules.ULT_MAX
	game.update_hud();await frames(3)
	await capture("v2039v_hud_ult_ready.png")
	# ── 상점 미리보기: 부침개 전우치
	game.cleanup_match();game.build("lobby");await frames(3)
	game.storage.own("woochi_pancake")
	game.build("market");await frames(6)
	if is_instance_valid(game.shop):
		game.shop.tab="skin"
		game.shop.selected_id="woochi_pancake"
		game.shop.refresh();await frames(8)
	await capture("v2039v_shop_pancake.png")
	# ── 선택창: 부침개 전우치
	game.build("lobby");await frames(2)
	game.create_room("2.0.39 선택",8,true,"",2,"seowon")
	for i in range(180):
		await process_frame
		if game.screen=="room":break
	game.rules.players.human.ready=true
	game.start_match();await frames(4)
	game.selection_id="daoist:woochi";game.selection_team="daoist"
	game.build("selection");await frames(8)
	if is_instance_valid(game.selection_view):
		game.selection_view.selection_id="daoist:woochi"
		game.selection_view._equip_skin("woochi_pancake")
		await frames(8)
	await capture("v2039v_selection_pancake.png")
	print("V2038 VERIFY DONE")
	quit(0)
