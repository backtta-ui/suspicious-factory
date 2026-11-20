extends SceneTree
## 2.0.32 실제 재화 점검: 결제 없이 게임·보상으로만 코인·보석을 얻고, 상점에서 실제로 차감되며,
## 메인 로비 상단 HUD가 원화에 박힌 가짜 숫자(12,350 / 1,280 / Lv. 12)가 아니라 storage.gd의
## 실제 값을 보여 주는지 끝까지 확인한다. 이 게임에는 레벨·경험치가 없다.
const App=preload("res://scenes/survival.tscn")
const Storage=preload("res://scripts/survival/storage.gd")
const Market=preload("res://scripts/survival/market.gd")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
var game: Node

func check(ok: bool,message: String) -> void:
 checks+=1
 if ok:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)

func frames(n: int=4) -> void:
 for i in range(n):await process_frame

func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return

## 화면에 실제로 그려진 글자를 모두 모은다(원화에 박힌 가짜 숫자가 노드로 남아 있는지 확인).
func all_text(node: Node) -> String:
 var out:=""
 for child in node.find_children("*","Label",true,false):
  if child is Label:out+=String(child.text)+"\n"
 return out

func _initialize() -> void:run.call_deferred()

func run() -> void:
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(12)
 # ── ⓪ 최초 진입 닉네임 설정: 처음 실행하면 닉네임 화면이 먼저 뜨고, 정한 이름이 저장·표시된다.
 check(not bool(game.storage.has_nickname()),"새 저장에는 닉네임이 없다")
 check(game.screen=="title","앱은 타이틀 화면에서 시작한다")
 game.enter_from_title();await wait_screen("nickname")
 check(game.screen=="nickname","닉네임이 없으면 시작 시 닉네임 설정 화면이 먼저 뜬다")
 check(is_instance_valid(game.nickname_input),"닉네임 입력칸이 있다")
 # 잘못된 입력은 저장되지 않고 안내를 보여 준다.
 game.nickname_input.text="a"
 game.submit_nickname();await frames(2)
 check(game.screen=="nickname" and not bool(game.storage.has_nickname()),"1자 닉네임은 저장되지 않는다")
 check(String(game.nickname_hint.text)!="","짧은 닉네임에는 안내 문구가 뜬다")
 game.nickname_input.text="달빛 전우치"
 game.submit_nickname();await frames(2)
 check(game.screen=="nickname" and not bool(game.storage.has_nickname()),"공백이 든 닉네임은 저장되지 않는다")
 game.nickname_input.text="달빛전우치"
 game.submit_nickname();await wait_screen("lobby")
 check(game.screen=="lobby","올바른 닉네임을 정하면 바로 메인 로비로 들어간다")
 check(String(game.storage.nickname())=="달빛전우치","정한 닉네임이 storage에 저장된다")
 var nickname_reload: RefCounted=Storage.new()
 check(String(nickname_reload.data.nickname)=="달빛전우치","닉네임은 재실행 후에도 유지된다")
 check(String(game.lobby_hud.name_label.text)=="달빛전우치","로비 상단 프로필에 내 닉네임이 보인다")
 # 설정·프로필에서 닉네임을 바꿀 수 있다.
 game.open_nickname_edit();await wait_screen("nickname")
 check(game.screen=="nickname" and String(game.nickname_input.text)=="달빛전우치","수정 화면에 기존 닉네임이 채워진다")
 game.nickname_input.text="밤새는도사"
 game.submit_nickname();await wait_screen("lobby")
 check(String(game.storage.nickname())=="밤새는도사" and String(game.lobby_hud.name_label.text)=="밤새는도사","바꾼 닉네임이 로비 상단에 바로 반영된다")
 # ── ① 신규 저장: 실제 재화는 0에서 시작하고 레벨·경험치는 없다.
 check(int(game.storage.data.coins)==0 and int(game.storage.data.gems)==0,"새 저장은 코인 0 · 보석 0에서 시작한다")
 check(not game.storage.data.has("level") and not game.storage.data.has("xp"),"이 게임에는 레벨·경험치 저장값이 없다")
 game.build("lobby");await frames(8)
 check(is_instance_valid(game.lobby_hud),"메인 로비에 실제 값 HUD가 붙는다")
 var lobby_text:=all_text(game.ui)
 check(not lobby_text.contains("12,350") and not lobby_text.contains("1,280"),"가짜 12,350 / 1,280 텍스트가 화면에 없다")
 check(not lobby_text.contains("Lv.") and not lobby_text.contains("Lv "),"가짜 Lv. 12 표시가 화면에 없다")
 check(game.ui.find_children("LobbyBadges","*",true,false).is_empty(),"좌측 하단 임시 상태 알약이 사라졌다")
 var pill_coin: Control=game.lobby_hud.coin_pill
 var pill_gem: Control=game.lobby_hud.gem_pill
 check(String(pill_coin.text_value)=="0" and String(pill_gem.text_value)=="0","로비 지갑이 실제 0 코인·0 보석을 보여 준다")
 check(String(game.lobby_hud.name_label.text)==String(game.storage.nickname()),"상단 프로필은 내 닉네임을 보여 준다")
 check(String(game.lobby_hud.title_label.text).contains("칭호"),"상단 프로필은 장착 칭호 자리를 보여 준다")
 # 실제 값이 바뀌면 HUD도 따라 바뀐다(원화에 박힌 숫자가 아니라 storage가 기준).
 game.storage.data.coins=12350;game.storage.data.gems=1280;game.refresh_lobby_hud();await frames(2)
 check(String(pill_coin.text_value)=="12,350" and String(pill_gem.text_value)=="1,280","지갑은 storage 값(콤마 표기)을 그대로 따른다")
 game.storage.data.coins=0;game.storage.data.gems=0;game.refresh_lobby_hud();await frames(2)
 check(String(pill_coin.text_value)=="0" and String(pill_gem.text_value)=="0","다시 0으로 되돌리면 지갑도 0이 된다")
 # 배지 숫자는 실제 미독·미수령 수와 같다.
 check(int(game.lobby_hud.mail_badge.count)==game.unread_mail_count(),"우편 배지 숫자 = 실제 확인할 우편 수")
 check(int(game.lobby_hud.bell_badge.count)==game.unread_alert_count(),"알림 배지 숫자 = 실제 읽지 않은 알림 수")
 check(int(game.lobby_hud.mail_badge.count)>0 and game.lobby_hud.mail_badge.visible,"확인할 우편이 있으면 배지가 보인다")

 # ── ② 매치 종료 보상: 코인 + 보석 + XP? (XP 없음)
 game.preferred_role="daoist"
 game.start_practice_match()
 await wait_screen("match")
 await frames(4)
 check(game.screen=="match","연습(봇) 매치가 시작된다")
 check(String(game.rules.players.human.name)=="밤새는도사","방·경기에서 내 이름이 닉네임으로 표시된다")
 var me: Dictionary=game.rules.players.human
 me.stats.seals=2;me.stats.rescues=1
 game.rules.winner="daoist"
 game.rules.phase="result"
 await wait_screen("result")
 var reward: Dictionary=game.last_reward
 check(not reward.is_empty(),"매치가 끝나면 보상 내역이 만들어진다")
 check(int(reward.get("coins",0))>0 and int(reward.get("gems",0))>0,"매치 보상은 코인과 보석을 함께 준다")
 check(int(game.storage.data.coins)==int(reward.coins),"보상 코인이 실제 지갑에 들어간다")
 check(int(game.storage.data.gems)==int(reward.gems),"보상 보석이 실제 지갑에 들어간다")
 check(not reward.has("xp") and not reward.has("level"),"매치 보상에 레벨·경험치가 없다")
 var disk_before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://survival_v13.json"))
 check(int(disk_before.coins)==int(game.storage.data.coins) and int(disk_before.gems)==int(game.storage.data.gems),"매치 보상은 즉시 파일에 저장된다")
 var result_text:=all_text(game.ui)
 check(result_text.contains("이번 경기 보상"),"결과 화면에 보상 안내가 보인다")
 check(result_text.contains("코인") and result_text.contains("보석"),"결과 화면에 +코인 · +보석이 보인다")
 check(not result_text.contains("Lv."),"결과 화면에도 레벨 표시가 없다")
 var coins_after_match:=int(game.storage.data.coins)
 # 결과 화면을 다시 그려도 보상이 중복 지급되지 않는다.
 game.build("result");await frames(3)
 check(int(game.storage.data.coins)==coins_after_match,"결과 화면을 다시 열어도 보상이 중복 지급되지 않는다")

 # ── ③ 업적·우편 보상 수령과 중복 방지
 game.build("achievements");await frames(3)
 var before_coins:=int(game.storage.data.coins)
 game.claim_achievement(Market.ACHIEVEMENTS[0]);await frames(2)
 check(int(game.storage.data.coins)==before_coins+int(Market.ACHIEVEMENTS[0].reward),"업적 보상이 실제 코인으로 들어간다")
 var paid:=int(game.storage.data.coins)
 game.claim_achievement(Market.ACHIEVEMENTS[0]);await frames(2)
 check(int(game.storage.data.coins)==paid,"같은 업적 보상을 두 번 받을 수 없다")
 check((game.storage.data.achievements.claimed as Array).has(String(Market.ACHIEVEMENTS[0].id)),"수령한 업적은 영구히 기록된다")
 game.build("mail");await frames(3)
 var mail: Dictionary=Market.MAILS[0]
 var coins_now:=int(game.storage.data.coins)
 var gems_now:=int(game.storage.data.gems)
 game.claim_mail(mail);await frames(2)
 check(int(game.storage.data.coins)==coins_now+int(mail.reward),"우편 코인 보상이 실제 지갑에 들어간다")
 check(int(game.storage.data.gems)==gems_now+Market.mail_gems(mail),"우편 보석 보상이 실제 지갑에 들어간다")
 var coins_after_mail:=int(game.storage.data.coins)
 var gems_after_mail:=int(game.storage.data.gems)
 game.claim_mail(mail);await frames(2)
 check(int(game.storage.data.coins)==coins_after_mail and int(game.storage.data.gems)==gems_after_mail,"같은 우편 보상을 두 번 받을 수 없다")
 game.claim_all_mail();await frames(2)
 check(game.unread_mail_count()==0,"모두 수령·확인하면 우편 배지 수가 0이 된다")
 game.read_all_alerts();await frames(2)
 check(game.unread_alert_count()==0,"알림을 모두 읽으면 알림 배지 수가 0이 된다")
 game.build("lobby");await frames(3)
 check(not game.lobby_hud.mail_badge.visible and not game.lobby_hud.bell_badge.visible,"배지 숫자가 0이면 로비 배지가 사라진다")

 # ── ④ 상점: 실제 차감 · 보유/장착 · 잔액 부족
 game.build("market");await frames(4)
 game.storage.data.coins=3000;game.storage.data.gems=12
 var moon: Dictionary=Market.skin("moon")
 game.market_buy(moon,"skin");await frames(3)
 check(int(game.storage.data.coins)==3000-int(moon.price),"스킨 값이 실제 코인에서 차감된다")
 check(game.storage.owns("moon") and game.storage.equipped("skin")=="moon","구매한 스킨이 보유·장착으로 저장된다")
 var shop_coin: Node=game.ui.find_child("ShopWallet_coin",true,false)
 var shop_gem: Node=game.ui.find_child("ShopWallet_gem",true,false)
 check(shop_coin!=null and String(shop_coin.get("text_value")).contains("2,550"),"상점 지갑이 차감된 실제 코인을 보여 준다")
 check(shop_gem!=null and String(shop_gem.get("text_value")).contains("12"),"상점 지갑이 실제 보석 잔액을 보여 준다")
 game.storage.data.coins=100
 game.market_buy(Market.skin("ember"),"skin");await frames(2)
 check(int(game.storage.data.coins)==100 and not game.storage.owns("ember"),"코인이 모자라면 차감 없이 안내만 한다")
 check(game.modal!=null,"잔액 부족은 안내 팝업으로 알린다")
 game.close_popup();await frames(2)
 var gem_item: Dictionary=Market.EFFECTS[1]
 check(Market.gem_price(gem_item)>0,"보석으로 해금할 수 있는 상품이 있다")
 game.storage.data.gems=Market.gem_price(gem_item)
 game.market_buy(gem_item,"effect","gem");await frames(3)
 check(int(game.storage.data.gems)==0,"보석 구매는 실제 보석에서 차감된다")
 check(game.storage.owns(String(gem_item.id)) and game.storage.equipped("effect")==String(gem_item.id),"보석으로 해금한 기운이 장착·저장된다")
 var before_gems:=int(game.storage.data.gems)
 game.market_buy(Market.EFFECTS[2],"effect","gem");await frames(2)
 check(int(game.storage.data.gems)==before_gems and not game.storage.owns(String(Market.EFFECTS[2].id)),"보석이 모자라면 해금되지 않는다")
 game.close_popup();await frames(1)

 # ── ⑤ 재로드 후 영속성
 var reloaded: RefCounted=Storage.new()
 check(int(reloaded.data.coins)==int(game.storage.data.coins),"재로드 후 코인이 유지된다")
 check(int(reloaded.data.gems)==int(game.storage.data.gems),"재로드 후 보석이 유지된다")
 check(reloaded.owns("moon") and reloaded.equipped("skin")=="moon","재로드 후 보유·장착 상태가 유지된다")
 check((reloaded.data.achievements.claimed as Array).has(String(Market.ACHIEVEMENTS[0].id)),"재로드 후 업적 수령 기록이 유지된다")
 check((reloaded.data.mail.claimed as Array).has(String(Market.MAILS[0].id)),"재로드 후 우편 수령 기록이 유지된다")
 check(reloaded.save()==OK,"저장 파일을 다시 쓸 수 있다")

 # ── ⑥ 로비 상단 바: 실제 지갑 값과 캐릭터·칭호
 game.storage.data.coins=1240;game.storage.data.gems=6
 game.storage.equip("title","moon_guard")
 game.storage.save()
 game.build("lobby");await frames(4)
 check(String(game.lobby_hud.coin_pill.text_value)=="1,240","로비 상단 지갑이 실제 코인 1,240을 보여 준다")
 check(String(game.lobby_hud.gem_pill.text_value)=="6","로비 상단 지갑이 실제 보석 6을 보여 준다")
 check(String(game.lobby_hud.title_label.text).contains("달빛지기"),"로비 상단 프로필이 장착 칭호를 보여 준다")
 var final_text:=all_text(game.ui)
 check(not final_text.contains("12,350") and not final_text.contains("Lv."),"최종 로비 화면에도 가짜 숫자·레벨이 없다")
 print("ECONOMY V32: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
