extends SceneTree
## 2.0.32 검수 렌더: 실제 재화 연동(코인·보석)·매치 보상·상점 지갑.
##  - v2032_lobby_real_economy.png : 메인 로비 상단 HUD가 실제 값(초상화·이름·칭호·코인·보석·배지)을 보여 준다
##  - v2032_match_reward.png       : 결과 화면의 +코인 / +보석 보상
##  - v2032_shop_wallet.png        : 상점 지갑이 실제 잔액을 보여 준다
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2032.gd
const App=preload("res://scenes/survival.tscn")
const Market=preload("res://scripts/survival/market.gd")
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

func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return
 print("WAIT TIMEOUT ",target," screen ",game.screen)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(16)

 # ── 최초 진입 닉네임 설정 화면(실제 첫 실행 상태).
 game.enter_from_title()
 await wait_screen("nickname")
 await frames(8)
 game.nickname_input.text="달빛전우치"
 await frames(3)
 await capture("v2032_nickname_setup.png")
 game.submit_nickname()
 await wait_screen("lobby")
 await frames(6)

 # ── 연습(봇) 경기를 실제로 끝내 코인·보석을 얻는다(결제 없음).
 game.preferred_role="daoist"
 game.start_practice_match()
 await wait_screen("match")
 await frames(6)
 var me: Dictionary=game.rules.players.human
 me.stats.seals=3
 me.stats.rescues=2
 game.rules.elapsed=95.0
 game.rules.winner="daoist"
 game.rules.phase="result"
 await wait_screen("result")
 await frames(10)
 print("MATCH REWARD coins=",game.last_reward.get("coins",0)," gems=",game.last_reward.get("gems",0))
 await capture("v2032_match_reward.png")

 # ── 우편·업적 보상을 실제로 수령해 지갑을 키운다(화면에 보일 실제 값).
 # 마지막 편지 하나는 일부러 읽지 않고 남겨 로비 우편 배지가 실제로 뜨는 모습을 남긴다.
 for entry in Market.MAILS:
  if String(entry.id)!="lobby_bgm":game.claim_mail(entry)
 game.storage.data.stats.matches=3
 game.storage.data.stats.wins=2
 game.storage.data.stats.seals=5
 game.storage.data.stats.rescues=3
 game.storage.save()
 for entry in Market.ACHIEVEMENTS:
  game.claim_achievement(entry)
 game.claim_achievement(Market.ACHIEVEMENTS[0])
 game.storage.equip("title","moon_guard")
 game.storage.save()
 print("LOBBY WALLET coins=",int(game.storage.data.coins)," gems=",int(game.storage.data.gems))

 game.build("lobby");await frames(10)
 await capture("v2032_lobby_real_economy.png")

 # ── 상점 지갑: 실제 잔액과 보석 해금 버튼.
 game.build("market");await frames(10)
 game.shop.set_tab("aura")
 await frames(4)
 game.shop.select_item("effect:gold")
 await frames(6)
 await capture("v2032_shop_wallet.png")
 print("DONE coins=",int(game.storage.data.coins)," gems=",int(game.storage.data.gems))
 quit(0)
