extends SceneTree
## 2단계-B 로비 검증: 모든 버튼이 실제 화면으로 이어지고, 매칭·방 코드·마켓·
## 업적·우편·알림·설정이 실제 데이터(저장)까지 바뀌는지 확인한다.
const App=preload("res://scenes/survival.tscn")
const Market=preload("res://scripts/survival/market.gd")
const Storage=preload("res://scripts/survival/storage.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game);await frames(8)
 game.build("lobby");await frames(3)
 for key in ["characters","codex","achievements","shop","quick","friends","practice","settings","mail","alerts","gear"]:
  check(game.lobby_hotspots.has(key) and is_instance_valid(game.lobby_hotspots[key]),"lobby hotspot "+key)
 check(game.sound.context=="menu" and game.sound.music.stream==game.sound.lobby,"self-made lobby bgm in the lobby")
 # 1) 모든 버튼이 임시 팝업이 아니라 실제 화면으로 연결된다
 for destination in ["market","achievements","mail","alerts","friends"]:
  game.build(destination);await frames(2)
  check(game.screen==destination and game.modal==null,"lobby button opens real screen "+destination)
 game.build("lobby");await frames(2)
 # 2) 빠른 매치: 8인 슬롯이 차고 대기방 → 경기 준비까지
 game.open_quick();await create_timer(.4).timeout
 check(game.screen=="quick" and game.match_slots>=1,"quick match screen opens")
 for i in range(12):game.advance_matching(.5);await frames(1)
 await create_timer(.4).timeout
 check(game.screen=="room","quick match fills eight slots and enters the room")
 check(game.rules.players.size()==8 and String(game.room.code)!="","quick room has eight players and a share code")
 game.rules.players.human.ready=true;game.rules.start()
 check(game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==2,"default composition is 2 yokai of 8")
 # 3) 친구와 함께: 코드로 입장, 8인 도사2:요괴6 구성
 game.join_with_code("달빛-4821");await create_timer(.4).timeout
 check(game.screen=="room" and String(game.room.code)=="달빛-4821","join with a friend code keeps that code")
 check((game.storage.data.room_codes as Array).has("달빛-4821"),"recent room code is remembered")
 game.join_with_code("abc");await frames(3)
 check(game.modal!=null,"too short room code is rejected with guidance")
 game.close_popup()
 game.create_room("여섯 요괴",8,true,"달빛-6006",6);await create_timer(.4).timeout
 check(game.rules.yokai_count==6,"eight-player room can use six yokai")
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 check(game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==6,"six yokai composition applies at start")
 check(game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist").size()==2,"two daoists accompany six yokai")
 # 4) 마켓: 무료 재화로 해금·장착하고 저장에 남는다
 game.storage.data.coins=2000;game.build("market");await frames(3)
 check(game.screen=="market","market screen opens")
 var moon: Dictionary=Market.SKINS[1]
 game.market_buy(moon,"skin");await frames(2)
 check(game.storage.owns("moon") and game.storage.equipped("skin")=="moon","skin unlock and equip")
 check(int(game.storage.data.coins)==2000-int(moon.price),"skin price is taken from coins")
 var reload:=Storage.new()
 check(reload.equipped("skin")=="moon" and reload.owns("moon"),"market state persists to disk")
 game.storage.data.coins=100;game.market_buy(Market.SKINS[4],"skin");await frames(2)
 check(game.modal!=null and not game.storage.owns("ember"),"not enough coins is explained, nothing is bought")
 game.close_popup()
 var title: Dictionary=Market.TITLES[2]
 game.storage.data.coins=2000;game.market_buy(title,"title");await frames(2)
 check(game.storage.equipped("title")=="first_seal","title equips and shows in state")
 var effect: Dictionary=Market.EFFECTS[1]
 game.market_buy(effect,"effect");await frames(2)
 check(game.storage.equipped("effect")=="gold","aura effect equips")
 # 5) 업적·우편·알림: 실제 진행도와 보상
 game.storage.data.stats.matches=3;game.storage.data.coins=0
 game.build("achievements");await frames(2)
 var before:=int(game.storage.data.coins)
 game.claim_achievement(Market.ACHIEVEMENTS[0]);await frames(2)
 check(int(game.storage.data.coins)==before+int(Market.ACHIEVEMENTS[0].reward),"achievement reward is paid")
 check((game.storage.data.achievements.claimed as Array).has("first_match"),"claimed achievement is recorded")
 var paid:=int(game.storage.data.coins)
 game.claim_achievement(Market.ACHIEVEMENTS[0]);await frames(2)
 check(int(game.storage.data.coins)==paid,"achievement reward cannot be claimed twice")
 game.storage.data.stats.matches=0
 game.claim_achievement(Market.ACHIEVEMENTS[1]);await frames(2)
 check(not (game.storage.data.achievements.claimed as Array).has("ten_matches"),"unfinished achievement is not claimable")
 game.build("mail");await frames(2)
 var mail: Dictionary=Market.MAILS[0]
 game.open_mail(mail);await frames(2)
 check((game.storage.data.mail.read as Array).has("welcome"),"opening mail marks it read")
 var coins_now:=int(game.storage.data.coins)
 game.claim_mail(mail);await frames(2)
 check(int(game.storage.data.coins)==coins_now+int(mail.reward),"mail reward is paid once")
 check((game.storage.data.mail.claimed as Array).has("welcome"),"claimed mail is recorded")
 game.claim_mail(mail);await frames(2)
 check(int(game.storage.data.coins)==coins_now+int(mail.reward),"mail reward cannot be claimed twice")
 game.build("alerts");await frames(2)
 game.read_alert(Market.ALERTS[0]);await frames(2)
 check((game.storage.data.alerts.read as Array).has(String(Market.ALERTS[0].id)),"alert read state is stored")
 # 6) 설정: 볼륨·음소거·조작감
 game.build("lobby");game.show_settings();await frames(2)
 check(game.modal.find_children("*","HSlider",true,false).size()>=3,"settings expose music, sfx and control sensitivity")
 check(game.modal.find_children("*","CheckBox",true,false).size()>=3,"settings expose mute and vibration")
 game.close_popup()
 # 7) 경기 기록이 업적 진행도와 코인으로 이어진다
 game.storage.data.stats.matches=0;game.storage.data.coins=0
 game.create_room("기록",6,true);await create_timer(.4).timeout
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 game.rules.winner=game.rules.players.human.role
 game.record_match()
 check(int(game.storage.data.stats.matches)==1 and int(game.storage.data.coins)>0,"finished match records progress and coins")
 game.queue_free();await frames(4)
 print("LOBBY HUB: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
