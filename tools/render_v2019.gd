extends SceneTree
## 2.0.19 검수: 새 바닥 원화·비율·걷기 프레임 + 로딩/대기실/매칭/선택/상점 화면 캡처.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2019.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())
func settle(at: Vector2,count: int=26) -> void:
 for i in range(count):
  game.update_avatars();game.update_hud()
  if is_instance_valid(game.camera):
   game.camera.position=at;game.camera.reset_smoothing()
  await process_frame
## 배정된 진영에 맞춰 8명의 캐릭터를 채운다(진영 배정은 건드리지 않는다).
func apply_characters() -> void:
 var pools: Dictionary={"daoist":["woochi","yeonhwa","muyeong","hongryeon"],"yokai":["gumiho","jangsanbeom","dokkaebi","haechi"]}
 var index: Dictionary={"daoist":0,"yokai":0}
 var order: Array=game.rules.players.keys()
 for id in order:
  var p: Dictionary=game.rules.players[id]
  var pool: Array=pools.get(String(p.role),pools.daoist)
  var i: int=int(index.get(String(p.role),0))
  p.character=String(p.role)+":"+String(pool[i%pool.size()])
  index[String(p.role)]=i+1
func start_bout(preferred: String) -> void:
 game.preferred_role=preferred
 game.setup_participants()
 game.rules.players.human.ready=true
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 apply_characters()
## 실제 이동 입력으로 걷기 사이클을 돌린다(박자마다 다른 다리 프레임).
func play_move(seconds: float,dir: Vector2) -> void:
 var me: Dictionary=game.rules.players.human
 me.intent=dir
 for i in range(int(seconds*60.0)):
  game.update_avatars();game.update_hud()
  if is_instance_valid(game.camera):
   game.camera.position=Vector2(870,800);game.camera.reset_smoothing()
  await process_frame
 me.intent=Vector2.ZERO
func run() -> void:
 root.size=Vector2i(1280,720)
 game=App.instantiate();root.add_child(game);await frames(8)
 game.create_room("달빛 모의전",8,true)
 await create_timer(.35).timeout
 start_bout("any")
 # 로딩 화면
 game.build("loading")
 await frames(8)
 await capture("res://builds/v2019_loading_16x9.png")
 # 대기실
 game.build("room")
 await frames(8)
 await capture("res://builds/v2019_room_16x9.png")
 # 빠른 매치(희망 진영 버튼)
 game.build("quick")
 await frames(12)
 await capture("res://builds/v2019_matching_16x9.png")
 # 캐릭터 선택(내 진영 · 요괴)
 start_bout("yokai")
 game.selection_id="";game.build("selection")
 await frames(10)
 await capture("res://builds/v2019_selection_16x9.png")
 # 스킨 상점(기본 도포 1종)
 game.storage.data.coins=2400
 game.build("market")
 await frames(4)
 game.shop.set_tab("skin")
 await frames(8)
 await capture("res://builds/v2019_shop_skin_16x9.png")
 # 인게임: 정지 → 걷기 프레임 2종
 game.rules.phase="loading";game.screen="selection"
 game.load_match(1)
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 if game.world==null:
  print("RENDER FAILED: world missing");quit(1);return
 game.rules.ready_map();game.bots.clear()
 for i in range(40):game.rules.tick(.05)
 game.rules.phase="live";game.rules.elapsed=2.0
 var me: Dictionary=game.rules.players.human
 me.captured=false;me.eliminated=false;me.deadline=0;me.form="";me.invisible_until=0
 var allies: Array=[];var foes: Array=[]
 for p in game.rules.players.values():
  if p.id=="human":continue
  if p.role=="daoist":allies.append(p)
  else:foes.append(p)
 me.position=Vector2(860,905);me.facing=6
 if allies.size()>0:allies[0].position=Vector2(700,880);allies[0].facing=6
 if allies.size()>1:allies[1].position=Vector2(1030,860);allies[1].facing=6
 if allies.size()>2:allies[2].position=Vector2(760,760);allies[2].facing=6
 if foes.size()>0:foes[0].position=Vector2(1080,760);foes[0].facing=6
 if foes.size()>1:foes[1].position=Vector2(640,1010);foes[1].facing=6
 await settle(Vector2(870,800),28)
 await capture("/workspace/downloads/lol_map_ingame_render.png")
 await play_move(.22,Vector2(0,1))
 await capture("res://builds/v2019_ingame_walk1.png")
 await play_move(.12,Vector2(0,1))
 await capture("res://builds/v2019_ingame_walk2.png")
 root.size=Vector2i(1560,720)
 await frames(8)
 await play_move(.2,Vector2(0,1))
 await settle(Vector2(880,790),20)
 await capture("/workspace/downloads/lol_map_wide_render.png")
 root.size=Vector2i(2340,1080)
 await frames(8)
 game.build("loading")
 await frames(8)
 await capture("res://builds/v2019_loading_wide.png")
 game.build("room")
 await frames(8)
 await capture("res://builds/v2019_room_wide.png")
 print("V2019 RENDER DONE")
 quit()
