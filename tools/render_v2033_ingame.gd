extends SceneTree
## 2.0.33 검수 렌더(2340×1080): 인게임 머리 위 이름표 '닉네임 [캐릭터명] · ♥♥♥'.
##  - v2033_ingame_nicknames.png : 내 캐릭터·동료 도사·전우치 분신이 같은 형식의 이름표를 단 모습
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2033_ingame.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(2340,1080)
	game=App.instantiate();root.add_child(game);await frames(14)
	game.enter_from_title()
	var nick_deadline:=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<nick_deadline:
		await process_frame
		if game.screen=="nickname" and not game.changing:break
	if game.screen=="nickname":
		game.nickname_input.text="달빛전우치"
		await frames(3)
		game.submit_nickname()
	var deadline:=Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.screen=="lobby" and not game.changing:break
	await frames(6)
	game.preferred_role="daoist"
	game.start_practice_match()
	deadline=Time.get_ticks_msec()+45000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.screen=="match" and not game.changing:break
	for i in range(300):
		if game.rules.phase=="live":break
		if game.rules.phase=="countdown":game.rules.tick(.05)
		await process_frame
	await frames(6)
	var human: Dictionary=game.rules.players.human
	human.character="daoist:woochi"
	human.cd.clear();human.stun=0.0
	# 이름표가 한 화면에 모이도록 동료 도사를 곁에 세운다.
	var spot: Vector2=Vector2(human.position)
	var seats: Array=[Vector2(-150,40),Vector2(150,30),Vector2(-40,-70)]
	var placed:=0
	for p in game.rules.players.values():
		if placed>=seats.size():break
		if String(p.id)=="human" or String(p.role)!="daoist":continue
		p.position=L.safe(spot+seats[placed]);p.ground=p.position;p.origin=p.position
		placed+=1
	# 전우치 분신: 본체와 같은 이름표를 단다.
	var cast: bool=game.rules.skill(human,Vector2.RIGHT,"main")
	print("RENDER clone cast=",cast)
	await frames(10)
	var tags: Array=[]
	if game.avatars.has("human"):
		tags.append("me="+String(game.avatars["human"].get_node("Name").text))
	for key in game.clones.keys():
		tags.append("clone="+String(game.clones[key].get_node("Name").text))
	for p in game.rules.players.values():
		if game.avatars.has(String(p.id)):tags.append(String(p.id)+"="+String(game.avatars[String(p.id)].get_node("Name").text))
	print("RENDER TAGS ",tags)
	await frames(6)
	await capture("v2033_ingame_nicknames.png")
	quit()
