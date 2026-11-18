extends SceneTree
## 실제 인게임/로비 프레임을 Godot 렌더러로 캡처한다(플레이 시점 점검용).
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_ingame.gd
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const Market=preload("res://scripts/survival/market.gd")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func settle(camera_at: Vector2,count: int=24) -> void:
 for i in range(count):
  game.update_avatars();game.update_hud()
  if is_instance_valid(game.camera):
   game.camera.position=camera_at;game.camera.reset_smoothing()
  await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())
func run() -> void:
 root.size=Vector2i(1280,720)
 game=App.instantiate();root.add_child(game);await frames(8)
 game.storage.data.coins=2400
 game.create_room("달빛 모의전",8,true);await create_timer(.4).timeout
 var ids: Array=game.rules.players.keys()
 var looks: Array=[["daoist","woochi"],["yokai","gumiho"],["yokai","dokkaebi"],["daoist","yeonhwa"],["daoist","muyeong"],["daoist","hongryeon"],["yokai","jangsanbeom"],["yokai","haechi"]]
 for i in range(ids.size()):
  var p: Dictionary=game.rules.players[ids[i]]
  p.ready=true
  p.role=looks[i][0];p.character=looks[i][0]+":"+looks[i][1]
 game.rules.phase="loading";game.screen="selection"
 game.load_match(1)
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 if game.world==null:
  print("RENDER FAILED: world missing");quit(1);return
 game.rules.ready_map()
 game.bots.clear()  # 쇼케이스 프레임: 봇 AI가 도사를 봉인하지 않게 한다.
 for i in range(40):game.rules.tick(.05)
 game.rules.phase="live";game.rules.elapsed=2.0
 var me: Dictionary=game.rules.players.human
 me.captured=false;me.eliminated=false;me.deadline=0;me.form="";me.invisible_until=0
 var allies: Array=[]
 var foes: Array=[]
 for p in game.rules.players.values():
  if p.id=="human":continue
  if p.role=="daoist":allies.append(p)
  else:foes.append(p)
 var hall: Dictionary=L.buildings()[0]
 var front: Vector2=(hall.doors as Dictionary).front
 # 동료는 문 옆에, 요괴는 마당 쪽에 세워 실제 플레이처럼 보이게 한다.
 var spots: Array=[front+Vector2(-120,46),front+Vector2(120,40),Vector2(860,760),Vector2(760,860)]
 for i in range(allies.size()):allies[i].position=spots[i%2];allies[i].facing=6
 for i in range(foes.size()):
  foes[i].position=spots[2+mini(1,i)]+Vector2(i*46,0);foes[i].facing=6
 for i in range(3):
  me.position=front+Vector2(16,26);me.facing=6;game.update_avatars();game.update_hud();await process_frame
 me.position=front+Vector2(16,30);me.facing=6
 await settle(me.position+Vector2(0,-L.CAMERA_LIFT))
 await capture("res://builds/ingame_outside.png")
 # 한옥 안: 지붕이 열리고 바깥은 밤안개 (캐릭터는 방 안쪽을 바라본 뒷모습)
 me.position=(hall.interior as Rect2).get_center()+Vector2(10,20);me.facing=6
 for i in range(30):game.update_avatars();await process_frame
 await settle(me.position+Vector2(0,-L.CAMERA_LIFT),10)
 await capture("res://builds/ingame_inside.png")
 # 두 번째 출입 한옥(서고) 실내
 var second: Dictionary=L.buildings()[1]
 me.position=(second.interior as Rect2).get_center();me.facing=4
 for i in range(30):game.update_avatars();await process_frame
 await settle(me.position+Vector2(0,-L.CAMERA_LIFT),10)
 await capture("res://builds/ingame_inside_seogo.png")
 # 마당: 팔각 문양·연못·아치 다리
 me.position=Vector2(860,760);me.facing=2
 for i in range(24):game.update_avatars();await process_frame
 await settle(me.position+Vector2(0,-L.CAMERA_LIFT),10)
 await capture("res://builds/ingame_courtyard.png")
 # 둔갑 상태
 me.position=L.OBJECTS[0].p;me.form="jar";me.buff.transform=game.rules.elapsed+7.4
 await settle(me.position+Vector2(0,-L.CAMERA_LIFT),10)
 await capture("res://builds/ingame_transform.png")
 me.form="";me.buff.erase("transform")
 # 로비 실화면: 마켓 · 빠른 매치
 game.cleanup_match();game.room={};game.build("lobby");await frames(6)
 await capture("res://builds/lobby_main.png")
 game.build("market");await frames(8)
 await capture("res://builds/lobby_market.png")
 game.build("lobby");game.open_quick()
 for i in range(9):game.advance_matching(.5);await frames(2)
 await capture("res://builds/lobby_matching.png")
 game.build("achievements");await frames(6)
 await capture("res://builds/lobby_achievements.png")
 quit()
