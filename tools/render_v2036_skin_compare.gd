extends SceneTree
## 2.0.36 기본 전우치 vs 부침개 전우치 구분 캡처.
## 기본=기본 도사 복장 + 수묵 부적/산수 족자, 부침개=부침개 모자·김치전 막/부침개 뒤집기.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node
var L: Script
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(name: String) -> void:
 for i in range(3):await process_frame
 var image:=root.get_texture().get_image()
 if image==null or image.is_empty():print("EMPTY ",name);return
 image.save_png(OUT+name);print("RENDER SAVED ",OUT+name)
func start(id: String) -> void:
 game.cleanup_match();game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("2.0.36 스킨 비교",8,true,"",2,id)
 for i in range(240):
  await process_frame
  if game.screen=="room" and not game.changing:break
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(300):
  if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
  if game.rules.phase=="loading":break
  await process_frame
 for i in range(900):
  await process_frame
  if game.screen=="match" and not game.changing:break
 for i in range(80):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 L=game.L;game.ui.visible=false
func cast(skin: String,skill_slot: String,shot_name: String) -> void:
 var human: Dictionary=game.rules.players.human
 human.role="daoist";human.character="daoist:woochi";human.skin=skin
 human.position=L.SPAWN;human.ground=L.SPAWN;human.captured=false;human.eliminated=false
 human.cd={};human.ult=game.rules.ULT_MAX;human.buff={};human.form="";human.immune=0.0
 game.rules.elapsed=30.0;game.rules.effects.clear()
 for p in game.rules.players.values():
  if p.id!="human":
   p.position=Vector2(-700,-700);p.ground=p.position
 game.update_avatars()
 var aim:=Vector2.RIGHT
 game.rules.skill(human,aim,skill_slot)
 for i in range(12):game.rules.tick(.045)
 game.set_process(false);game.update_avatars();game.update_hud()
 game.camera.position=human.position+Vector2(0,-L.CAMERA_LIFT);game.camera.zoom=Vector2(2.2,2.2)
 await frames(4)
 await capture(shot_name)
 game.set_process(true)
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game);await frames(10)
 game.storage.data.market.owned.append("woochi_pancake")
 # 선택창 두 장
 game.create_room("2.0.36 스킨",8,true,"",2,"seowon");await create_timer(.3).timeout
 game.rules.players.human.ready=true
 game.start_match();await create_timer(.4).timeout
 game.rules.select_character("human","daoist:woochi")
 game.selection_id="daoist:woochi";game.selection_team="daoist"
 # 카운트다운이 선택창을 지나치지 않게 phase를 고정하고, 한 번 만든 화면에서 스킨만 갈아입는다.
 game.rules.phase="selection"
 game.storage.equip("skin","default")
 game.build("selection");await create_timer(.9).timeout
 game.rules.phase="selection"
 await frames(10)
 await capture("v2036_woochi_base_selection.png")
 var sel: Node=game.selection_view
 if sel!=null:sel._equip_skin("woochi_pancake")
 game.rules.phase="selection"
 await create_timer(.5).timeout
 await frames(8)
 await capture("v2036_woochi_pancake_selection.png")
 # 인게임
 await start("seowon")
 await cast("","main","v2036_woochi_base_clone.png")
 await cast("","ult","v2036_woochi_base_painting.png")
 await cast("woochi_pancake","main","v2036_woochi_pancake_clone.png")
 await cast("woochi_pancake","ult","v2036_woochi_pancake_painting.png")
 print("V2036 SKIN COMPARE DONE")
 quit(0)
