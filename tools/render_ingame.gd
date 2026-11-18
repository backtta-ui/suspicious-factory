extends SceneTree
## 실제 인게임 프레임을 Godot 렌더러로 캡처한다(플레이 시점 점검용).
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_ingame.gd
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
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
 game.create_room("달빛 모의전",8,true);await create_timer(.4).timeout
 var ids: Array=game.rules.players.keys()
 for i in range(ids.size()):
  var p: Dictionary=game.rules.players[ids[i]]
  p.ready=true
  if p.id=="human":p.role="daoist";p.character="daoist:woochi";continue
  p.role="yokai" if i<3 else "daoist"
  p.character=["yokai:gumiho","yokai:dokkaebi","yokai:jangsanbeom","daoist:yeonhwa","daoist:muyeong","daoist:hongryeon"][i%6]
 game.rules.phase="loading";game.screen="selection"
 game.load_match(1)
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 if game.world==null:
  print("RENDER FAILED: world missing");quit(1);return
 game.rules.ready_map()
 for i in range(40):game.rules.tick(.05)
 game.rules.elapsed=2.0
 var me: Dictionary=game.rules.players.human
 var index:=0
 for p in game.rules.players.values():
  if p.id=="human":continue
  if p.role=="yokai":p.position=Vector2(1000,840) if index<3 else Vector2(1140,760)
  else:
   var spots: Array=[Vector2(760,560),Vector2(880,840),Vector2(560,880),Vector2(1040,780),Vector2(700,760)]
   p.position=spots[index%spots.size()]
  p.facing=2
  index+=1
 if is_instance_valid(game.camera):game.camera.zoom=Vector2(1,1)
 # 1) 한옥 안: 지붕이 열리고 내부·병풍·뒷문이 보이는 플레이 화면
 me.position=Vector2(760,700);me.facing=2;me.form=""
 await settle(Vector2(760,600))
 await capture("res://builds/ingame_render_1280.png")
 # 1b) 한옥 안: 지붕이 열리고 내부·병풍·뒷문이 보이는 시점
 me.position=Vector2(435,505);me.facing=0
 if is_instance_valid(game.camera):game.camera.zoom=Vector2(1.4,1.4)
 await settle(Vector2(660,600),16)
 await capture("res://builds/ingame_inside.png")
 # 2) 마당: 지붕이 닫힌 바깥 시점과 사물·다리
 me.position=Vector2(760,760);me.facing=2
 if is_instance_valid(game.camera):game.camera.zoom=Vector2(1.35,1.35)
 await settle(Vector2(660,720))
 await capture("res://builds/ingame_outside.png")
 # 3) 둔갑 상태: 항아리로 변신한 내 모습과 남은 시간 안내
 me.position=Vector2(700,760);me.form="jar";me.buff.transform=game.rules.elapsed+7.4
 await settle(Vector2(700,740),12)
 await capture("res://builds/ingame_transform.png")
 me.form="";me.buff.erase("transform")
 quit()
