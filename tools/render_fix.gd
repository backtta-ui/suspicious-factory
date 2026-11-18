extends SceneTree
## 2.0.18 점검용 실제 렌더 캡처: 16:9(1280x720)와 20:9 와이드(2340x1080).
## 상점(스킨 탭)·캐릭터 선택·빠른 매치·인게임을 실제 렌더러로 그려 UI 잘림과
## 캐릭터 비율·시야를 눈으로 확인한다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_fix.gd
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size()," viewport ",root.get_visible_rect().size)
func fresh(size: Vector2i) -> void:
 if is_instance_valid(game):game.queue_free();game=null;await frames(4)
 root.size=size
 game=App.instantiate();root.add_child(game);await frames(8)
func room_roles(yokai: int=2) -> void:
 game.create_room("점검 모의전",8,true)
 await create_timer(.35).timeout
 var looks: Array=[["daoist","woochi"],["yokai","gumiho"],["yokai","jangsanbeom"],["daoist","yeonhwa"],["daoist","muyeong"],["daoist","hongryeon"],["daoist","yeonhwa"],["daoist","muyeong"]]
 var ids: Array=game.rules.players.keys()
 print("ROOM players ",ids.size())
 for i in range(ids.size()):
  var p: Dictionary=game.rules.players[ids[i]]
  p.ready=true
  p.role=looks[i][0]
  p.character=looks[i][0]+":"+looks[i][1]
 print("ROOM roles ",game.rules.players.values().map(func(p: Dictionary)->String:return String(p.role)))
func shot_shop(tag: String) -> void:
 game.storage.data.coins=2400
 game.build("market")
 await frames(4)
 game.shop.set_tab("skin")
 await frames(4)
 await capture("res://builds/fix_shop_%s.png"%tag)
 game.shop.set_tab("character")
 await frames(4)
 await capture("res://builds/fix_shopchar_%s.png"%tag)
func shot_selection(tag: String) -> void:
 if game.rules==null:
  game.room={"name":"점검","count":8,"fill":true,"code":"점검-0001","yokai":2}
  game.setup_participants()
 game.rules.phase="room"
 game.rules.players.human.ready=true
 game.rules.start()
 game.selection_id=String(game.storage.data.daoist)
 game.selection_team=game.rules.players.human.role
 game.rules.select_character("human",game.selection_id)
 game.build("selection")
 await frames(6)
 await capture("res://builds/fix_selection_%s.png"%tag)
func shot_matching(tag: String) -> void:
 game.build("lobby")
 await frames(3)
 game.open_quick()
 for i in range(200):
  await process_frame
  if game.screen=="quick" and not game.changing:break
 for i in range(20):game.advance_matching(.5)
 await frames(4)
 await capture("res://builds/fix_matching_%s.png"%tag)
func shot_room(tag: String) -> void:
 game.build("lobby")
 await frames(2)
 game.create_room("달빛 모의전",8,true,"달빛-4821",2)
 for i in range(200):
  await process_frame
  if game.screen=="room" and not game.changing:break
 await frames(3)
 await capture("res://builds/fix_room_%s.png"%tag)
func shot_ingame(tag: String) -> void:
 await room_roles()
 game.rules.phase="loading";game.screen="selection"
 game.load_match(game.sequence)
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 if game.world==null:
  print("RENDER FAILED: world missing");quit(1);return
 game.rules.ready_map()
 game.bots.clear()
 for i in range(40):game.rules.tick(.05)
 game.rules.phase="live";game.rules.elapsed=2.0
 var me: Dictionary=game.rules.players.human
 me.captured=false;me.eliminated=false;me.deadline=0;me.form=""
 var allies: Array=[]
 var foes: Array=[]
 for p in game.rules.players.values():
  if p.id=="human":continue
  if p.role=="daoist":allies.append(p)
  else:foes.append(p)
 var hall: Dictionary=L.buildings()[0]
 var front: Vector2=(hall.doors as Dictionary).front
 var spots: Array=[front+Vector2(-120,46),front+Vector2(120,40),Vector2(860,760),Vector2(760,860)]
 for i in range(allies.size()):allies[i].position=spots[i%2];allies[i].facing=6
 for i in range(foes.size()):
  foes[i].position=spots[2+mini(1,i)]+Vector2(i*46,0);foes[i].facing=6
 me.position=front+Vector2(16,30);me.facing=6
 me.intent=Vector2(1,0)
 for i in range(30):game.update_avatars();game.update_hud();await process_frame
 me.intent=Vector2.ZERO
 await frames(6)
 await capture("res://builds/fix_ingame_%s.png"%tag)
func run() -> void:
 await fresh(Vector2i(1280,720))
 await shot_ingame("16x9")
 await shot_shop("16x9")
 await shot_selection("16x9")
 await shot_matching("16x9")
 await shot_room("16x9")
 await fresh(Vector2i(2340,1080))
 await shot_shop("wide")
 await shot_selection("wide")
 await shot_matching("wide")
 await shot_room("wide")
 await shot_ingame("wide")
 print("RENDER FIX DONE")
 quit()
