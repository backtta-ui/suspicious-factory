extends SceneTree
## 로비 검증: 모든 버튼이 실제 화면으로 이어지고, 빠른 매치(도사6:요괴2 고정)·스킨 상점·
## 업적·우편·알림·친구 방 코드·설정이 실제 데이터(저장)까지 바뀌는지 확인한다.
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
## 화면의 모든 버튼 글자를 모아 금지된 선택지가 남아 있지 않은지 확인한다.
func button_texts(node: Node) -> String:
 var out:=""
 for child in node.find_children("*","Button",true,false):
  if child is Button:out+=String(child.text)+"|"
 return out
func wait_screen(game: Node,target: String) -> void:
 for i in range(120):
  await process_frame
  if game.screen==target and not game.changing:return
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
  check(game.ui.find_children("*","Control",true,false).size()>20,"screen "+destination+" is built by the shared lobby frame")
 game.build("lobby");await frames(2)
 # 2) 빠른 매치: 도사 6 : 요괴 2 고정, 8인 인장 슬롯, 대기방 → 경기 준비
 game.open_quick();await wait_screen(game,"quick")
 check(game.screen=="quick" and is_instance_valid(game.quick),"quick match screen opens")
 check(game.quick.slots.size()==8,"quick match draws eight seal slots")
 check(not button_texts(game.quick).contains("요괴 6"),"no daoist2:yokai6 choice remains in the quick match screen")
 check(String(game.quick.status_label.text).contains("/ 8"),"matching progress reads n / 8")
 for i in range(3):game.advance_matching(.5);await frames(1)
 check(game.match_slots>=2,"matching fills slots over time")
 for i in range(40):game.advance_matching(.2);await frames(1)
 check(game.match_slots==8,"all eight slots fill before accepting")
 # 2.0.18: 빠른 매치는 중간 대기실 없이 캐릭터 선택으로 직행한다.
 game.finish_matching();await wait_screen(game,"selection")
 check(game.screen=="selection","quick match accept skips the old waiting room")
 check(game.rules.players.size()==8 and String(game.room.code)!="","quick match has eight players and a share code")
 check(int(game.room.yokai)==2 and game.rules.yokai_count==2,"quick match composition is fixed to two yokai")
 game.rules.players.human.ready=true;game.rules.start()
 check(game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==2,"default composition is 2 yokai of 8")
 # 3) 친구와 함께: 코드로 입장, 8인 도사6:요괴2 구성
 game.join_with_code("달빛-4821");await wait_screen(game,"room")
 check(game.screen=="room" and String(game.room.code)=="달빛-4821","join with a friend code keeps that code")
 check((game.storage.data.room_codes as Array).has("달빛-4821"),"recent room code is remembered")
 check(game.rules.yokai_count==2,"friend rooms use the same two-yokai composition")
 game.join_with_code("abc");await frames(3)
 check(game.modal!=null,"too short room code is rejected with guidance")
 game.close_popup()
 game.build("friends");await frames(3)
 check(game.screen=="friends","friends screen opens")
 check(not button_texts(game.ui).contains("요괴 6"),"friend screen no longer offers the six-yokai room")
 game.create_room("기록",8,true);await wait_screen(game,"room")
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 check(game.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist").size()==6,"six daoists accompany two yokai")
 # 4) 캐릭터 & 스킨 상점: 무료 재화로 해금·장착, 캐릭터 해금, 저장 유지
 game.storage.data.coins=3000;game.build("market");await frames(4)
 check(game.screen=="market" and is_instance_valid(game.shop),"character and skin shop opens")
 check(game.shop.cards.size()==6,"shop shows a two by three gold card grid")
 check(is_instance_valid(game.ui.find_child("ShopTab_character",true,false)),"shop has a character tab")
 check(is_instance_valid(game.ui.find_child("ShopTab_skin",true,false)) and is_instance_valid(game.ui.find_child("ShopTab_aura",true,false)),"shop has skin and title tabs")
 # 2.0.19: 스킨 상점은 기본 도포 1종만 노출한다. 예전 색상 스킨 id는 저장 데이터 호환용으로 남는다.
 check(Market.shop_items("skin").size()==6 and String(Market.shop_items("skin")[0].id)=="default","skin shop lists the default robe plus five coin robes")
 var moon: Dictionary=Market.skin("moon")
 game.market_buy(moon,"skin");await frames(2)
 check(game.storage.owns("moon") and game.storage.equipped("skin")=="moon","skin unlock and equip")
 check(int(game.storage.data.coins)==3000-int(moon.price),"skin price is taken from coins")
 var reload:=Storage.new()
 check(reload.equipped("skin")=="moon" and reload.owns("moon"),"market state persists to disk")
 game.storage.data.coins=100;game.market_buy(Market.skin("ember"),"skin");await frames(2)
 check(game.modal!=null and not game.storage.owns("ember"),"not enough coins is explained, nothing is bought")
 game.close_popup()
 var title: Dictionary=Market.TITLES[2]
 game.storage.data.coins=3000
 game.market_buy(title,"title");await frames(2)
 check(game.storage.equipped("title")=="first_seal","title equips and shows in state")
 game.market_buy(Market.EFFECTS[1],"effect");await frames(2)
 check(game.storage.equipped("effect")=="gold","aura effect equips")
 # 2.0.28 체험판: 10인 전원이 기본 해금이라 해금 구매 없이 대표만 바뀐다.
 var locked: String="daoist:jangyeongsil"
 check(game.storage.owns_character(locked),"every character is unlocked in the trial build")
 var before_coins:=int(game.storage.data.coins)
 game.shop_buy_character(locked);await frames(2)
 check(game.storage.owns_character(locked),"character unlock is recorded")
 check(String(game.storage.data.daoist)==locked,"choosing a character becomes the team representative")
 check(int(game.storage.data.coins)==before_coins and Market.character_price(locked)==0,"an owned character costs no coins in the trial build")
 var owned_now:=Storage.new()
 check(owned_now.owns_character(locked),"character unlock persists to disk")
 # 2.0.22: 상점 해금은 보유만 하고, 대표 캐릭터는 매칭 후 선택창에서 고른다.
 var rep_before:=String(game.storage.data.daoist)
 game.storage.data.coins=3000
 game.shop_unlock_character("daoist:jangyeongsil")
 check(game.storage.owns_character("daoist:jangyeongsil"),"shop unlock records the character")
 check(String(game.storage.data.daoist)==rep_before,"shop unlock leaves the team representative untouched")
 check(game.owned_characters("daoist").has(locked),"owned character appears in the selection pool")
 game.storage.data.coins=50;game.shop_buy_character("yokai:yagwangwi");await frames(2)
 check(int(game.storage.data.coins)==50 and game.storage.owns_character("yokai:yagwangwi"),"the trial build never charges coins for a character")
 # 5) 업적·우편·알림: 실제 진행도와 보상
 game.storage.data.stats.matches=3;game.storage.data.coins=0
 game.build("achievements");await frames(3)
 check(game.screen=="achievements","achievements scroll screen opens")
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
 game.build("mail");await frames(3)
 check(game.screen=="mail","mail screen opens")
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
 game.create_room("기록",6,true);await wait_screen(game,"room")
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 game.rules.winner=game.rules.players.human.role
 game.record_match()
 check(int(game.storage.data.stats.matches)==1 and int(game.storage.data.coins)>0,"finished match records progress and coins")
 game.queue_free();await frames(4)
 print("LOBBY HUB: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
