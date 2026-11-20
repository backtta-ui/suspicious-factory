extends SceneTree
## 2.0.18 플레이 감각·UI 점검: 60Hz 고정 스텝, 카메라/캐릭터 비율, 도사·요괴 분리 스폰,
## 시작 6초 봉인 유예, 20:9 와이드 화면에서 로비 하위 화면이 밀리지 않는지,
## 뒤로가기 버튼, 빠른 매치 직행, 연습(봇) 최신 서원 봇전, 이동 속도, 캐릭터 생동감.
const App=preload("res://scenes/survival.tscn")
const AppScript=preload("res://scripts/survival/app.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const IngameSprite=preload("res://scripts/art/ingame_sprite.gd")
const Shop=preload("res://scripts/survival/shop_view.gd")
var checks:=0
var failures:=0
var game: Node
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func named(root: Node,key: String) -> Node:
 return root.find_child(key,true,false)
func labels_outside(card: Control) -> int:
 var box:=card.get_global_rect().grow(2.0)
 var count:=0
 for child in card.get_children():
  if child is Label and child.visible:
   if not box.encloses((child as Label).get_global_rect()):count+=1
 return count
func _initialize() -> void:run.call_deferred()
func run() -> void:
 # 1) 60Hz 고정 스텝 · 시점/캐릭터 비율 · 이동 속도
 check(is_equal_approx(float(AppScript.STEP),1.0/60.0),"gameplay fixed step is 60Hz")
 check(L.CAMERA_ZOOM>=1.85 and L.CAMERA_ZOOM<=1.95,"camera zoom pulled in to about 1.90 for the closer amogus-like view")
 check(L.CAMERA_LIFT<=40.0,"camera lift trimmed to the new zoom")
 check(is_equal_approx(float(C.find("daoist:woochi").speed),135.0),"walk speed raised to 135")
 check(is_equal_approx(float(C.find("daoist:woochi").run_speed),210.0),"run speed raised to 210")
 # 2) 분리 스폰 · 시작 유예
 var daoists:=L.daoist_spawns()
 var yokai:=L.yokai_spawns()
 check(daoists.size()==6 and yokai.size()==2,"six daoist spawns and two yokai spawns are defined")
 var legal:=true;var separated:=true
 for p in daoists:legal=legal and L.can_stand(p)
 for p in yokai:legal=legal and L.can_stand(p)
 for y in yokai:
  for d in daoists:separated=separated and (y as Vector2).distance_to(d)>=L.SPAWN_SEPARATION
 check(legal,"every spawn point stands on legal ground")
 check(separated,"yokai spawn at least 600px from every daoist")
 var room:=Rules.new(9)
 for i in range(8):room.add("p%d"%i,"참가자%d"%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[i%4].id)
 for p in room.players.values():p.ready=true
 check(room.start(),"room starts with split spawns")
 var spaced:=true
 for y in room.players.values():
  if y.role!="yokai":continue
  for d in room.players.values():
   if d.role=="daoist":spaced=spaced and (y.position as Vector2).distance_to(d.position)>=L.SPAWN_SEPARATION
 check(spaced,"real match players use the separated spawn list")
 for i in range(400):
  if room.phase=="loading":break
  room.tick(.1)
 check(room.phase=="loading","bots finish character selection")
 room.ready_map()
 for i in range(31):room.tick(.1)
 var sealed_early:=false
 for p in room.players.values():
  if p.role!="yokai":continue
  sealed_early=sealed_early or float(p.cd.get("seal",0.0))-room.elapsed<5.5
 check(room.phase=="live" and not sealed_early,"yokai receive the six second seal grace at live")
 # 3) 와이드(20:9) 화면에서 하위 화면이 origin만큼 밀리지 않는다
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(8)
 check(is_equal_approx(root.get_visible_rect().size.x,1560.0) and is_equal_approx(root.get_visible_rect().size.y,720.0),"20:9 phone viewport expands to 1560x720")
 game.storage.data.coins=2400
 game.build("market");await frames(4)
 var back: Node=named(game.ui,"LobbyBack")
 check(back!=null and (back as Control).is_visible_in_tree() and (back.get_global_rect().get_center().x)<260.0,"back button sits at the left edge on a wide screen")
 var title: Label=game.shop.title_label
 check(not (back as Control).get_global_rect().intersects(title.get_global_rect()),"wide screen back button never overlaps the title")
 var outside:=0
 for card in game.shop.cards:outside+=labels_outside(card as Control)
 check(outside==0,"shop card labels stay inside their card on a wide screen")
 game.shop.set_tab("skin");await frames(3)
 outside=0
 for card in game.shop.cards:outside+=labels_outside(card as Control)
 check(outside==0,"skin cards keep their labels inside on a wide screen")
 var readable:=true
 for card in game.shop.cards:
  for child in card.get_children():
   if child is Label:
    var size: int=int((child as Label).get_theme_font_size("font_size"))
    readable=readable and size>=13
 check(readable,"every shop card label is at least 13pt")
 # 2.0.21: 미리보기 본문이 패널 밖(20:9 왼쪽)으로 새지 않고, 카드 글씨가 얼굴을 가리지 않는다.
 var shop: Node=game.shop
 # 2.0.33: 20:9에서 판은 오른쪽 끝으로 옮겨지므로, 실제 금테 판의 화면 사각형을 기준으로 본다.
 var panel_rect:=Rect2((shop.preview_frame as Control).get_global_rect())
 var leaked:=0
 for child in shop.preview_body.get_children():
  if child is Control and (child as Control).is_visible_in_tree():
   var box: Rect2=(child as Control).get_global_rect()
   if box.size.x>1.0 and box.size.y>1.0 and not panel_rect.grow(2.0).encloses(box):leaked+=1
 check(leaked==0,"preview panel contents stay inside the panel on a wide screen")
 var band_ok:=true
 for card in shop.cards:
  var card_box: Rect2=(card as Control).get_global_rect()
  var name_node: Label=card.get_meta("name_label")
  if name_node!=null and name_node.get_global_rect().position.y<card_box.position.y+card_box.size.y*.60:band_ok=false
 check(band_ok,"card name band sits low so the portrait face stays uncovered")
 # 2.0.22: 캐릭터는 매칭 수락 후 선택창에서 고르므로 상점 캐릭터 탭에 '장착'이 없다.
 game.shop.set_tab("character");await frames(3)
 game.shop.select_item("daoist:woochi");await frames(3)
 var no_equip_text:=true
 var owned_reads_buy:=false
 for card in game.shop.cards:
  var state_node: Label=card.get_meta("state_label")
  if state_node==null:continue
  if String(state_node.text)=="장착 중":no_equip_text=false
  if String(card.get_meta("id"))=="daoist:woochi" and String(state_node.text)=="보유":owned_reads_buy=true
 check(no_equip_text,"character shop cards never read 장착 중")
 check(owned_reads_buy,"owned character card reads 보유")
 var shop_cta: Button=game.shop.action_button
 check(shop_cta!=null and String(shop_cta.text)=="보유 중" and shop_cta.disabled,"owned character CTA is a finished 보유 중 button")
 # 2.0.28 체험판: 10인 전원 해금이라 어느 캐릭터를 골라도 CTA가 '보유 중'이다.
 var all_owned:=true
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   game.shop.select_item(String(entry.id));await frames(2)
   shop_cta=game.shop.action_button
   if shop_cta==null or String(shop_cta.text)!="보유 중" or not shop_cta.disabled:all_owned=false
 check(all_owned,"every roster character is already unlocked in the trial build")
 game.shop.set_tab("skin");await frames(3)
 check(String(game.shop.action_button.text)!="보유 중","skin tab keeps its equip action")
 game.shop.set_tab("character");await frames(2)
 # 4) 화면마다 뒤로가기가 실제로 보인다
 for destination in ["friends","achievements","mail","alerts","quick"]:
  game.build(destination);await frames(3)
  var button: Node=named(game.ui,"LobbyBack")
  check(button!=null and (button as Control).is_visible_in_tree(),"visible back button on "+destination)
  if destination=="quick":
   check(String((button as Control).get("text")).contains("뒤로"),"quick match back button is labelled")
 game.build("characters");await frames(4)
 check(named(game.ui,"CodexBack")!=null and (named(game.ui,"CodexBack") as Control).size.x>=60.0,"codex back button is large enough for touch")
 # 5) 빠른 매치 직행: 대기실 없이 캐릭터 선택
 game.build("lobby");await frames(2)
 game.open_quick()
 for i in range(200):
  await process_frame
  if game.screen=="quick" and not game.changing:break
 for i in range(30):game.advance_matching(.5)
 game.finish_matching()
 for i in range(200):
  await process_frame
  if game.screen=="selection" and not game.changing:break
 check(game.screen=="selection","quick match accept goes straight to character selection")
 check(named(game.ui,"SelectionBack")!=null and named(game.ui,"SelectionConfirm")!=null,"selection screen has back and confirm buttons")
 check(game.rules.players.size()==8 and game.rules.yokai_count==2,"quick match keeps eight players with two yokai")
 var cards_outside:=0
 for child in game.ui.find_children("SelectCard_*","Button",true,false):cards_outside+=labels_outside(child as Control)
 check(cards_outside==0,"selection card labels stay inside their cards")
 game.back();await frames(2)
 if game.modal!=null:game.close_popup()
 game.build("lobby");await frames(2)
 # 6) 연습(봇)은 최신 월하의 서원 봇전으로 직행한다
 game.start_practice_match()
 for i in range(600):
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match" and is_instance_valid(game.world),"practice hotspot opens the real seowon bot match")
 check(game.room.get("practice",false)==true and game.rules.yokai_count==2,"practice match keeps the six daoist two yokai setup")
 # 7) 인게임: 캐릭터 배율·생동감·부드러운 추적
 var human: Node2D=game.avatars.get("human",null)
 check(human!=null and (human as Node2D).scale.x<1.3 and (human as Node2D).scale.x>1.0,"in-game actor uses the smaller 1.12 scale")
 check(is_instance_valid(game.camera) and not game.camera.position_smoothing_enabled,"camera tracks the 60Hz avatar without extra smoothing")
 var me: Dictionary=game.rules.players.human
 game.bots.clear()
 game.rules.phase="live";game.rules.elapsed=1.0
 var art: Node=human.get("ingame_sprite")
 # 마당 가운데(L.SPAWN)에서 서쪽으로 걸어 애니메이션을 확인한다(사방이 열린 자리).
 me.position=L.SPAWN;me.ground=L.SPAWN;me.facing=4
 game.update_avatars()
 var seen_bob:=false
 var start_pos: Vector2=(human as Node2D).position
 var start_sim: Vector2=me.position
 # 앱 자체 _process가 스틱을 0으로 되돌리지 않게 잠시 끄고 시뮬레이션을 직접 돌린다.
 game.set_process(false)
 var accepted:=0
 for i in range(60):
  game.rules.phase="live"
  if game.rules.command("human","move",{"vector":Vector2(-1,0)}):accepted+=1
  game.rules.tick(1.0/60.0)
  game.update_avatars()
  await process_frame
  if art!=null:
   var inner: Sprite2D=art.get("sprite")
   if inner!=null and absf(inner.position.y)>0.7:seen_bob=true
 game.set_process(true)
 print("MOVE accepted=",accepted," phase=",game.rules.phase," moved=",me.position.distance_to(start_sim)," human_moved=",(human as Node2D).position.distance_to(start_pos)," role=",me.role)
 me.intent=Vector2.ZERO
 check(seen_bob,"walking sprite bobs off the ground instead of sliding")
 check(me.position.distance_to(start_sim)>20.0,"real simulation moved the player")
 check((human as Node2D).position.distance_to(me.position)<8.0,"avatar tracks the moving simulation closely")
 check(art!=null and (art.get("dust") as Array)!=null,"footstep dust buffer exists")
 me.intent=Vector2.ZERO
 # 8) 뒤로가기: 인게임 일시정지 메뉴에도 로비로 나가기가 있다
 game.pause_menu();await frames(3)
 var leave: Node=null
 for child in game.modal.find_children("*","Button",true,false):
  if String((child as Control).get("text")).contains("로비로") or String((child as Control).get("text")).contains("나가기"):leave=child
 check(leave!=null,"match pause menu keeps a visible lobby exit")
 game.close_popup();await frames(2)
 # 9) 2.0.19: 봉인은 요괴 전용 · 희망 진영 배정 · 기본 스킨 1종 · 걷기 프레임
 var bout:=Rules.new(7)
 bout.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):bout.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in bout.players.values():p.ready=true
 bout.start()
 var prey: Dictionary=bout.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[0]
 var hunter: Dictionary=bout.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 prey.position=hunter.position+Vector2(0,10);prey.captured=false;prey.eliminated=false
 prey.facing=6;hunter.facing=2;hunter.cd.seal=0
 check(not bout.seal(prey),"a daoist can never seal anyone")
 check(hunter.get("captured",false)==false,"no seal happened from the daoist side")
 hunter.position=prey.position-Vector2(0,10);hunter.facing=2;hunter.cd={};prey.immune=0;prey.form=""
 bout.phase="live";bout.elapsed=1.0;bout.contact_seal()
 check(prey.captured,"only a yokai seals a daoist by touching")
 var preferred:=Rules.new(9)
 preferred.preferred_role="yokai"
 preferred.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):preferred.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in preferred.players.values():p.ready=true
 preferred.start()
 check(preferred.players.human.role=="yokai","preferred yokai side is honoured")
 check(preferred.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==2,"yokai count stays at two")
 var side_daoist:=Rules.new(11)
 side_daoist.preferred_role="daoist"
 side_daoist.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):side_daoist.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in side_daoist.players.values():p.ready=true
 side_daoist.start()
 check(side_daoist.players.human.role=="daoist","preferred daoist side is honoured")
 check(side_daoist.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist").size()==6,"daoist count stays at six")
 var Market=preload("res://scripts/survival/market.gd")
 check(Market.shop_items("skin").size()>=6 and String(Market.shop_items("skin")[0].id)=="default" and Market.shop_items("skin").any(func(it: Dictionary)->bool:return String(it.id)=="woochi_pancake"),"skin shop keeps the robes plus the v34 pancake skin")
 check(Market.skin("moon").get("id","")=="moon","legacy skin ids still resolve for saved data")
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/ingame/frames.json"))
 var walk_ok:=true
 for id in ["woochi","yeonhwa","muyeong","hongryeon","gumiho","jangsanbeom","dokkaebi","haechi"]:
  for direction in ["front","back","left","right"]:
   var entry: Dictionary=manifest.characters[id].directions[direction]
   var frames_list: Array=entry.get("walk",[])
   if frames_list.size()<2:walk_ok=false;continue
   for frame in frames_list:
    if not ResourceLoader.exists(String(frame.path)):walk_ok=false
 check(walk_ok,"all eight characters have two walk frames per direction")
 var walker:=Actor.new();walker.cosmetic=Looks.base_appearance("woochi");root.add_child(walker);walker.set_physics_process(false)
 walker.ingame_art=true;walker.art_id="woochi";walker.update_sprite()
 walker.gait_weight=1.0;walker.gait_phase=0.0
 walker.ingame_sprite._process(.016)
 var first_pose: String=String(walker.ingame_sprite.pose_name)
 walker.gait_phase=PI*1.05;walker.ingame_sprite._process(.016)
 var second_pose: String=String(walker.ingame_sprite.pose_name)
 walker.gait_phase=PI*2.05;walker.ingame_sprite._process(.016)
 var third_pose: String=String(walker.ingame_sprite.pose_name)
 # 2.0.23: 정지 프레임 없이 두 발이 번갈아 딛는 2프레임 교차 보행.
 check(first_pose=="walk1" and second_pose=="walk2" and third_pose=="walk1","walk cycle alternates front and back leg frames")
 # 2.0.21: 걷기 프레임 위에서 바운스·스쿼시가 과해 젤리처럼 튀지 않는지 실제 변환으로 확인한다.
 var sprite_node: Node2D=walker.ingame_sprite
 var low:=9.0;var high:=0.0;var bob_low:=0.0;var bob_high:=0.0
 walker.gait_weight=1.0
 for i in range(24):
  walker.gait_phase=TAU*float(i)/24.0
  sprite_node._process(.016)
  var sy: float=sprite_node.sprite.scale.y/sprite_node.base_scale
  var sx: float=sprite_node.sprite.scale.x/sprite_node.base_scale
  low=minf(low,minf(sy,sx));high=maxf(high,maxf(sy,sx))
  # 4x4 시트는 발끝 앵커(sheet_base)만큼 위로 올라가 있으므로 그 기준으로 바운스를 잰다.
  var bob_y: float=sprite_node.sprite.position.y-sprite_node.sheet_base.y
  bob_low=minf(bob_low,bob_y);bob_high=maxf(bob_high,bob_y)
 check(low>=.975 and high<=1.03,"walk squash stays within about 2.5% so the feet stay on the ground")
 check(IngameSprite.WALK_BOUNCE<=2.0 and IngameSprite.RUN_BOUNCE<=3.0,"walk/run vertical bounce toned down for the new walk frames")
 check(absf(bob_low)<=3.0 and absf(bob_high)<=3.0,"walk bob stays within a few pixels")
 check(IngameSprite.WALK_TILT<=.04 and IngameSprite.RUN_TILT<=.08,"walk/run lean toned down")
 # 2.0.21: 기기 네이티브 해상도 렌더(canvas_items) + 픽셀 스냅으로 글자가 번지지 않게 한다.
 check(String(ProjectSettings.get_setting("display/window/stretch/mode"))=="canvas_items","stretch mode renders UI at device resolution")
 check(bool(ProjectSettings.get_setting("gui/common/snap_controls_to_pixels")),"controls snap to whole pixels for crisp text")
 walker.queue_free();await frames(2)
 print("PLAYFEEL V2.0: ",checks," checks / ",failures," failures")
 game.queue_free();await frames(4)
 quit(1 if failures else 0)
