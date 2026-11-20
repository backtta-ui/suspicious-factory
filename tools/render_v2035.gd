extends SceneTree
## 2.0.35 검수 렌더(20:9 = 1600×720):
##  - v2035_seowon_renew.png    서원 리뉴얼 11종(장독·화분·화로·궤짝·병풍·석등·정자 기둥·석난간·벚꽃·대숲)
##  - v2035_haeundae.png        부산 해운대 전체(전통시장·백사장·동백섬·밀물·파도 경보)
##  - v2035_dongseongno.png     대구 동성로 전체(별빛랜드·아케이드·먹자골목·반월당)
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2035.gd
const App=preload("res://scenes/survival.tscn")
const Maps=preload("res://scripts/survival/maps.gd")
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
func start(map_id: String,role: String="daoist") -> void:
 game.cleanup_match()
 game.build("lobby");await frames(4)
 game.preferred_role=role
 game.create_room("2.0.35 렌더",8,true,"",2,map_id)
 for i in range(220):
  await process_frame
  if game.screen=="room" and not game.changing:break
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(260):
  if game.rules.phase in ["selection","ready","loading"]:game.rules.tick(.25)
  if game.rules.phase=="loading":break
 await wait_screen("match")
 for i in range(60):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
func focus(at: Vector2,zoom: float) -> void:
 var human: Dictionary=game.rules.players.human
 human.position=at
 game.camera.position=at+Vector2(0,-game.L.CAMERA_LIFT)
 game.camera.zoom=Vector2(zoom,zoom)
 await frames(6)
 game.camera.position=at+Vector2(0,-game.L.CAMERA_LIFT)
 await frames(4)
func run() -> void:
 root.size=Vector2i(1600,720)
 game=App.instantiate();root.add_child(game)
 await frames(10)
 # ---------------------------------------------------------------- 1) 서원 리뉴얼
 await start("seowon")
 var human: Dictionary=game.rules.players.human
 human.role="daoist";human.character="daoist:woochi"
 game.rules.elapsed=95.0;human.outside=0.0
 # 마당 동쪽(정자 기둥·연못 목교·석등이 함께 보이는 자리)
 await focus(Vector2(1750,1300),.86)
 # 둔갑 표시(항아리)를 켜서 리뉴얼 사물 크기를 보여 준다
 human.position=Vector2(1560,1260)
 await frames(6)
 await capture("v2035_seowon_renew.png")
 # ---------------------------------------------------------------- 2) 해운대
 await start("haeundae")
 var human2: Dictionary=game.rules.players.human
 human2.role="daoist";human2.character="daoist:woochi"
 game.rules.elapsed=120.0;human2.outside=0.0
 var g: RefCounted=game.rules.gimmicks
 g.wave_until=game.rules.elapsed+4.0
 g.tide_until=game.rules.elapsed+6.0
 g.mist_until=game.rules.elapsed+3.0;g.mist_zone="surf";g.mist_pos=Vector2(2210,540)
 await focus(Vector2(1750,1350),.52)
 human2.position=Vector2(1750,1350)
 await frames(6)
 await capture("v2035_haeundae.png")
 # ---------------------------------------------------------------- 3) 동성로
 await start("dongseongno")
 var human3: Dictionary=game.rules.players.human
 human3.role="daoist";human3.character="daoist:woochi"
 game.rules.elapsed=130.0;human3.outside=0.0
 var g2: RefCounted=game.rules.gimmicks
 g2.speaker_until=game.rules.elapsed+5.0;g2.speaker_pos=Vector2(2050,1420);g2.speaker_radius=300.0
 g2.smoke_until=game.rules.elapsed+4.0;g2.smoke_pos=Vector2(2500,780);g2.smoke_radius=230.0
 await focus(Vector2(1700,1250),.58)
 human3.position=Vector2(1700,1250)
 await frames(6)
 await capture("v2035_dongseongno.png")
 quit(0)
