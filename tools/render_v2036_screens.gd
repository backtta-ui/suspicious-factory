extends SceneTree
## 2.0.36 핵심 화면 캡처(20:9 1600×720): 선택창·4맵 실내·강남 에스컬레이터/CCTV·
## 해운대 밀물 자기장·동성로 실내·전체 지도 장소명. 결과는 /workspace/downloads/v2036_*.png
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
 image.save_png(OUT+name);print("RENDER SAVED ",OUT+name," ",image.get_size())
func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return
func start(id: String) -> void:
 game.cleanup_match();game.build("lobby");await frames(4)
 game.preferred_role="daoist"
 game.create_room("2.0.36 화면",8,true,"",2,id)
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
 await wait_screen("match")
 for i in range(80):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 L=game.L
func place(at: Vector2,zoom: float=1.45) -> void:
 var human: Dictionary=game.rules.players.human
 human.position=at;human.ground=at;human.captured=false;human.eliminated=false
 game.update_avatars()
 game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(zoom,zoom)
 await frames(4)
 game.camera.position=at+Vector2(0,-L.CAMERA_LIFT)
 game.camera.zoom=Vector2(zoom,zoom)
 await frames(2)
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game);await frames(10)
 # ---------------------------------------------------------------- 선택창
 game.create_room("2.0.36 선택",8,true,"",2,"seowon");await create_timer(.3).timeout
 game.rules.players.human.ready=true
 game.start_match();await create_timer(.4).timeout
 game.rules.players.human.role="daoist"
 game.rules.select_character("human","daoist:woochi")
 game.selection_id="daoist:woochi";game.selection_team="daoist"
 game.build("selection");await create_timer(.9).timeout;await frames(8)
 await capture("v2036_selection.png")
 print("SELECTION skin chips ",game.selection_view.get_children().size())
 # ---------------------------------------------------------------- 조선 실내
 await start("seowon")
 var human: Dictionary=game.rules.players.human
 game.rules.elapsed=120.0
 var hall: Dictionary=L.buildings()[0]
 await place((hall.interior as Rect2).get_center(),1.35)
 await capture("v2036_joseon_interior.png")
 # 봉인된 동료 구출 카운트다운 시인성
 var mate: Dictionary={}
 for p in game.rules.players.values():
  if p.id!="human" and String(p.role)=="daoist":mate=p;break
 if not mate.is_empty():
  mate.position=human.position+Vector2(150,30);mate.ground=mate.position
  mate.captured=true;mate.deadline=game.rules.elapsed+8.0;mate.sealed_by="yokai"
  game.update_avatars();await frames(4)
  await capture("v2036_rescue_countdown.png")
  mate.captured=false
 # 전체 지도(장소명)
 game.show_map();await frames(8);game.set_process(false);await frames(3)
 await capture("v2036_joseon_map_zones.png")
 game.set_process(true);game.close_map();await frames(2)
 # ---------------------------------------------------------------- 강남 에스컬레이터·CCTV
 await start("gangnam")
 game.rules.elapsed=100.0
 var esc: Dictionary=L.GIMMICKS[1]
 await place((esc.rect as Rect2).get_center()+Vector2(0,40),1.30)
 game.rules.tick(.25);game.update_hud();await frames(3)
 await capture("v2036_gangnam_escalator.png")
 # CCTV 실제 피드
 human=game.rules.players.human
 human.position=Vector2(2840,430);game.rules.gimmicks.cooldown.clear()
 game.rules.command("human","gimmick");game.update_hud()
 await place(Vector2(2840,430),1.15)
 game.ui.visible=true
 await frames(6);game.set_process(false);await frames(4)
 await capture("v2036_gangnam_cctv.png")
 game.set_process(true)
 # ---------------------------------------------------------------- 해운대 밀물 자기장
 await start("haeundae")
 game.rules.elapsed=430.0
 var g: RefCounted=game.rules.gimmicks
 g.wave_until=game.rules.elapsed+5.0;g.tide_until=game.rules.elapsed+6.0
 game.rules.players.human.outside=0.0
 var ring: Dictionary=game.rules.circle()
 var human_h: Dictionary=game.rules.players.human
 human_h.position=ring.center;human_h.ground=ring.center
 game.update_avatars()
 game.camera.position=ring.center;game.camera.zoom=Vector2(.40,.40)
 await frames(5);game.camera.position=ring.center;game.camera.zoom=Vector2(.40,.40);await frames(3)
 await capture("v2036_haeundae_tide_zone.png")
 # ---------------------------------------------------------------- 동성로 실내
 await start("dongseongno")
 game.rules.elapsed=120.0
 var shop: Dictionary=L.buildings()[0]
 await place((shop.interior as Rect2).get_center(),1.30)
 await capture("v2036_dongseongno_interior.png")
 print("V2036 SCREENS DONE")
 quit(0)
