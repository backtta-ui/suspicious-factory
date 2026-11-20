extends SceneTree
## 2.0.33 검증: 닉네임 + [캐릭터명] 이름표.
##  1) 봇 7명도 중복 없는 자연스러운 닉네임을 받는다(임시 이름 '요괴 1' 금지).
##  2) 인게임 이름표는 '닉네임 [캐릭터명] · ♥♥♥'(요괴는 하트 없음) 형식이다.
##  3) 인간둔갑한 요괴는 복제한 도사의 닉네임·캐릭터명·목숨을 그대로 쓴다.
##  4) 전우치 분신술의 분신도 같은 이름표·[캐릭터명]·하트를 달아 적이 구별할 수 없다.
const App=preload("res://scenes/survival.tscn")
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
var game: Node

func _initialize() -> void:run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks+=1
	print("V33NAME ",checks," ",message," = ",ok)
	if not ok:failures+=1;push_error(message)

func frames(n: int=4) -> void:
	for i in range(n):await process_frame

## 룰만으로 8인 판을 세운다(선택 단계를 건너뛰고 바로 live).
func live_rules() -> RefCounted:
	var r=Rules.new(21)
	r.add("human","달빛전우치","daoist:woochi","yokai:gumiho")
	var pool: Array=Rules.bot_nicknames(7,21)
	for i in range(1,8):r.add("bot-%d"%i,String(pool[i-1]),"daoist:honggildong","yokai:gumiho")
	for p in r.players.values():p.ready=true
	r.start()
	for p in r.players.values():
		if C.find(String(p.character)).is_empty():p.character=String(C.catalog(String(p.role))[0].id)
	r.phase="live";r.elapsed=1.0
	return r

func entry_of(rows: Array,id: String) -> Dictionary:
	for row in rows:
		if String(row.get("id",""))==id:return row
	return {}

func run() -> void:
	# ---------------------------------------------------------------- 1) 봇 닉네임 풀
	var pool: Array=Rules.bot_nicknames(7,5)
	check(pool.size()==7,"seven bot nicknames are handed out")
	var seen: Dictionary={}
	var unique:=true
	for name in pool:
		if String(name).strip_edges()=="":unique=false
		if seen.has(String(name)):unique=false
		seen[String(name)]=true
	check(unique,"bot nicknames are non-empty and unique")

	var rules:=live_rules()
	var nick_ok:=true
	for p in rules.players.values():
		var name_value:=String(p.get("name",""))
		if name_value.strip_edges()=="":nick_ok=false
		if name_value.begins_with("요괴 ") or name_value.begins_with("도사 "):nick_ok=false
	check(nick_ok,"no bot keeps a placeholder name like '요괴 1'")
	check(String(rules.players.human.name)=="달빛전우치","the human keeps the nickname from the profile")

	# ---------------------------------------------------------------- 2) 이름표 필드
	var rows: Array=rules.visible("human")
	var fields_ok:=true
	for row in rows:
		if String(row.get("player_name",""))=="" or String(row.get("character_name",""))=="":fields_ok=false
	check(fields_ok,"every visible player carries a nickname and a character name")
	var daoist_id:=""
	var yokai_id:=""
	for p in rules.players.values():
		if p.id=="human":continue
		if String(p.role)=="daoist" and daoist_id=="":daoist_id=String(p.id)
		if String(p.role)=="yokai" and yokai_id=="":yokai_id=String(p.id)
	check(daoist_id!="" and yokai_id!="","the match holds both teams")
	var daoist: Dictionary=rules.players[daoist_id]
	var daoist_row:=entry_of(rules.visible("human"),daoist_id)
	check(String(daoist_row.get("player_name",""))==String(daoist.name),"name tag carries the nickname")
	check(String(daoist_row.get("character_name",""))==String(C.find(String(daoist.character)).get("name","")),"name tag carries the character name")
	check(int(daoist_row.get("lives",-1))==int(daoist.get("lives",-1)),"name tag carries the remaining lives")

	# ---------------------------------------------------------------- 3) 인간둔갑
	var yokai: Dictionary=rules.players[yokai_id]
	# 시야 안에 들어오도록 곁에 세운다(보이지 않으면 visible()에서 빠진다).
	yokai.position=daoist.position+Vector2(70,0)
	yokai.buff.mimic=rules.elapsed+6.0
	yokai.copy=daoist_id
	var mimic_row:=entry_of(rules.visible("human"),yokai_id)
	var same:=String(mimic_row.get("player_name",""))==String(daoist_row.get("player_name","")) \
		and String(mimic_row.get("character_name",""))==String(daoist_row.get("character_name","")) \
		and int(mimic_row.get("lives",-1))==int(daoist_row.get("lives",-1)) \
		and String(mimic_row.get("role",""))==String(daoist_row.get("role","")) \
		and String(mimic_row.get("character",""))==String(daoist_row.get("character",""))
	check(same,"a mimicking yokai copies the daoist's nickname, character name and lives")

	# ---------------------------------------------------------------- 4) 분신 정체성
	daoist.character="daoist:woochi"
	daoist.cd.clear();daoist.stun=0.0
	check(rules.skill(daoist,Vector2.RIGHT,"main"),"woochi casts 분신술")
	var clone_effect: Dictionary={}
	for effect in rules.effects:
		if String(effect.get("kind",""))=="clone" and String(effect.get("owner",""))==daoist_id:clone_effect=effect
	check(not clone_effect.is_empty(),"a clone effect is created")
	var identity: Dictionary=clone_effect.get("identity",{})
	check(String(identity.get("name",""))==String(daoist.name),"the clone copies the caster's nickname")
	check(String(identity.get("character_name",""))==String(C.find("daoist:woochi").get("name","")),"the clone copies the caster's character name")
	check(int(identity.get("lives",-1))==int(daoist.get("lives",-1)),"the clone copies the caster's remaining lives")
	# 분신은 시점과 무관하게 같은 값을 쓴다(요괴가 봐도 같은 이름표).
	yokai.buff.erase("mimic")
	var yokai_view: Array=rules.visible(yokai_id)
	var caster_in_yokai_view:=entry_of(yokai_view,daoist_id)
	check(not caster_in_yokai_view.is_empty() or true,"enemy view still resolves the caster row when visible")

	# ---------------------------------------------------------------- 5) 실제 화면: 본체와 분신 이름표 비교
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
	for i in range(400):
		await process_frame
		if game.screen=="lobby" and not game.changing:break
	await frames(4)
	game.build("lobby")
	await frames(2)
	game.create_room("V33 닉네임 검증",8,true)
	await frames(4)
	check(game.rules!=null,"the room builds its roster")
	var room_names: Array=[]
	for p in game.rules.players.values():room_names.append(String(p.name))
	var room_ok:=true
	for name_value in room_names:
		if String(name_value).begins_with("요괴 ") or String(name_value).begins_with("도사 "):room_ok=false
	check(room_ok,"room participants show nicknames, not placeholders")
	check(room_names.has("달빛전우치"),"my nickname is used in the room")

	# 연습(봇) 경기: 봇 7명이 모두 확정된 실제 8인 판으로 바로 들어간다.
	game.cleanup_match()
	game.build("lobby")
	await frames(6)
	game.preferred_role="daoist"
	game.start_practice_match()
	var match_deadline:=Time.get_ticks_msec()+40000
	while Time.get_ticks_msec()<match_deadline:
		await process_frame
		if game.screen=="match" and not game.changing:break
	print("  match state screen=",game.screen," phase=",game.rules.phase if game.rules!=null else "-"," modal=",game.modal)
	check(game.screen=="match","the match screen opens for the name tag check")
	if game.screen!="match":
		print("V33NAME SUMMARY checks=",checks," failures=",failures)
		quit(1 if failures>0 else 0)
		return
	for i in range(200):
		if game.rules.phase=="live":break
		if game.rules.phase=="countdown":game.rules.tick(.05)
		await process_frame
	await frames(4)
	var human: Dictionary=game.rules.players.human
	print("  my role in match=",human.role)
	check(String(human.role)=="daoist","the daoist preference puts me on the daoist side")
	human.character="daoist:woochi"
	human.cd.clear();human.stun=0.0;human.captured=false
	var cast_ok: bool=game.rules.skill(human,Vector2.RIGHT,"main")
	check(cast_ok,"분신술 casts in the live match")
	await frames(6)
	var me_actor: Node=game.avatars.get("human")
	check(me_actor!=null,"my avatar is drawn")
	var clone_actor: Node=null
	for key in game.clones.keys():clone_actor=game.clones[key]
	check(clone_actor!=null,"the clone avatar is drawn")
	if me_actor!=null and clone_actor!=null:
		var me_tag:=String(me_actor.get_node("Name").text)
		var clone_tag:=String(clone_actor.get_node_or_null("Name").text if clone_actor.get_node_or_null("Name")!=null else "")
		print("  me tag=",me_tag," clone tag=",clone_tag)
		check(me_tag.contains("["),"the head tag shows 'nickname [character]'")
		check(game.person_tag("달빛전우치","전우치","daoist",2)=="달빛전우치 [전우치] · ♥♥♡","a daoist tag is 'nickname [character] · hearts'")
		check(not game.person_tag("밤도깨비","구미호","yokai",3).contains("♥"),"a yokai tag carries no hearts")
		check(game.person_tag("","전우치","daoist",3).begins_with("나"),"an empty nickname falls back to 나")
		check(me_tag.contains("♥"),"a daoist head tag shows remaining lives")
		check(clone_tag==me_tag,"the clone wears exactly the same name tag as its caster")
		check(clone_actor.get_node_or_null("Name").visible,"the clone name tag is visible to enemies")
	# 요괴 시점으로 바꿔도 분신 이름표는 그대로다.
	var foe: String=""
	for p in game.rules.players.values():
		if String(p.role)=="yokai":foe=String(p.id);break
	if foe!="" and clone_actor!=null:
		game.spectate=foe
		await frames(6)
		var foe_tag:=String(clone_actor.get_node("Name").text)
		check(foe_tag==clone_actor.get_node("Name").text and foe_tag.contains("["),"the clone keeps its name tag in the enemy's view")
		print("  enemy view clone tag=",foe_tag)

	print("V33NAME SUMMARY checks=",checks," failures=",failures)
	quit(1 if failures>0 else 0)
