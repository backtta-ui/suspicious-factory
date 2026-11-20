extends SceneTree
## 2.0.31 미니맵 터치: 안드로이드처럼 '터치 이벤트만'으로도 전체 지도가 열리고,
## 닫기 버튼·바깥 배경·지도 다시 누르기 어느 쪽으로도 닫히는지 실제 입력으로 확인한다.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("MAP ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
## 터치만 보낸다(마우스 에뮬레이션에 기대지 않는지 확인하려고 generate_mouse=false).
func touch(at: Vector2,pressed: bool,finger: int=61) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=finger;event.pressed=pressed;event.position=at
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func tap(at: Vector2,finger: int=61) -> void:
 touch(at,true,finger);await frames(2);touch(at,false,finger);await create_timer(.35).timeout
func run() -> void:
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game)
 await frames(8)
 game.create_room("미니맵 터치",6,true)
 await create_timer(.4).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames()
 game.rules.confirm_character("human")
 for i in range(300):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match","match screen reached for the minimap test")
 var map: Control=game.minimap
 check(map!=null and map.is_visible_in_tree(),"minimap widget is on screen")
 var inside:bool=map.get_global_rect().size.x>40.0 and game.get_viewport().get_visible_rect().encloses(map.get_global_rect())
 check(inside,"minimap inside the viewport with a tappable size")
 # 미니맵을 덮는 컨트롤이 있는지: 그 점에서 가장 위에 있는 컨트롤이 미니맵(또는 그 자식)이어야 한다.
 var center: Vector2=map.get_global_rect().get_center()
 var top: Control=game.get_viewport().gui_get_hovered_control()
 # 미니맵 위에 겹쳐서 터치를 가로챌 수 있는(보이고 mouse_filter가 STOP/PASS인) 컨트롤 점검.
 var blockers: Array=[]
 for node in game.ui.find_children("*","Control",true,false):
  var c:=node as Control
  if c==null or c==map or map.is_ancestor_of(c) or c.is_ancestor_of(map):continue
  if not c.is_visible_in_tree() or c.mouse_filter==Control.MOUSE_FILTER_IGNORE:continue
  if not c.get_global_rect().intersects(map.get_global_rect()):continue
  blockers.append(String(c.name)+str(c.get_global_rect()))
 check(blockers.is_empty(),"no visible control steals taps over the minimap: "+str(blockers))
 await tap(center)
 check(game.map_overlay!=null and is_instance_valid(game.map_overlay),"touch alone opens the full map")
 if game.map_overlay!=null:
  var close_button: Button=game.map_overlay.find_child("MapClose",true,false)
  check(close_button!=null and close_button.is_visible_in_tree(),"full map has a visible close button")
  if close_button!=null:
   await tap(close_button.get_global_rect().get_center(),62)
   check(game.map_overlay==null,"close button tap closes the full map")
  await tap(center)
  check(game.map_overlay!=null,"map reopens after closing")
  if game.map_overlay!=null:
   # 전체 지도(한가운데 큰 지도)를 다시 누르면 닫힌다.
   await tap(Vector2(root.size.x,root.size.y)*.5,63)
   check(game.map_overlay==null,"tapping the open map closes it")
  # 바깥 어두운 배경을 눌러도 닫힌다.
  if game.map_overlay==null:await tap(center)
  await tap(Vector2(8,root.size.y-8),64)
  check(game.map_overlay==null,"tapping the dim backdrop closes the map")
  # 지도는 열린 동안에도 시뮬레이션을 세우지 않는다(일시정지 팝업).
  game.rules.phase="live";game.rules.elapsed=30.0
  await tap(center)
  var before: float=game.rules.elapsed
  await frames(10)
  check(game.map_overlay!=null and game.rules.elapsed>before,"the open map keeps the live match clock running (2.0.34)")
  if game.map_overlay!=null:game.close_map()
 # 다른 화면비에서도 미니맵이 화면 안에 있다.
 for size in [Vector2i(2400,1080),Vector2i(960,540)]:
  root.size=size;await frames(8)
  check(game.get_viewport().get_visible_rect().encloses(game.minimap.get_global_rect()),"minimap inside viewport "+str(size))
 print("MINIMAP TOUCH: ",checks," checks / ",failures," failures")
 print("HOVERED ",top)
 quit(1 if failures else 0)
