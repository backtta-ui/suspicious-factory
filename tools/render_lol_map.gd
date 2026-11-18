extends SceneTree
## 2.0.19 검수용 실제 인게임 렌더: LoL 스타일 바닥 원화가 격자·네모 박스 없이
## 돌길·화단 경계로 읽히는지, 캐릭터·사물 비율이 맵과 맞는지 눈으로 확인한다.
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_lol_map.gd
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
func stage() -> void:
 game.create_room("달빛 모의전",8,true)
 await create_timer(.35).timeout
 var looks: Array=[["daoist","woochi"],["yokai","gumiho"],["yokai","jangsanbeom"],["daoist","yeonhwa"],["daoist","muyeong"],["daoist","hongryeon"],["daoist","yeonhwa"],["daoist","muyeong"]]
 var ids: Array=game.rules.players.keys()
 for i in range(ids.size()):
  var p: Dictionary=game.rules.players[ids[i]]
  p.ready=true;p.role=looks[i][0];p.character=looks[i][0]+":"+looks[i][1]
 game.rules.phase="loading";game.screen="selection"
 game.load_match(1)
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
 me.captured=false;me.eliminated=false;me.deadline=0;me.form="";me.invisible_until=0
 var allies: Array=[]
 var foes: Array=[]
 for p in game.rules.players.values():
  if p.id=="human":continue
  if p.role=="daoist":allies.append(p)
  else:foes.append(p)
 # 마당 팔각 문양 남쪽에서 북쪽 청월당·연못이 함께 보이게 배치
 me.position=Vector2(860,905);me.facing=6
 if allies.size()>0:allies[0].position=Vector2(700,880);allies[0].facing=6
 if allies.size()>1:allies[1].position=Vector2(1030,860);allies[1].facing=6
 if allies.size()>2:allies[2].position=Vector2(760,760);allies[2].facing=6
 if foes.size()>0:foes[0].position=Vector2(1080,760);foes[0].facing=6
 if foes.size()>1:foes[1].position=Vector2(640,1010);foes[1].facing=6
 for i in range(30):
  game.update_avatars();game.update_hud();await process_frame
func shot(path: String,size: Vector2i,at: Vector2) -> void:
 root.size=size
 await frames(6)
 await settle(at,28)
 await capture(path)
func run() -> void:
 game=App.instantiate();root.add_child(game);await frames(8)
 await stage()
 if is_instance_valid(game.hud):game.hud.visible=true
 await shot("/workspace/downloads/lol_map_ingame_render.png",Vector2i(1280,720),Vector2(870,800))
 await shot("/workspace/downloads/lol_map_wide_render.png",Vector2i(1560,720),Vector2(880,790))
 print("LOL MAP RENDER DONE")
 quit()
