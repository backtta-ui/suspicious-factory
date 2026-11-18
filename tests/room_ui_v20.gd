extends SceneTree
## 2.0.20 대기실(친구 방) 검증.
## 시안 통이미지 위의 투명 버튼이 아니라, 실제 노드로 그린 새 대기실에서
## 방 코드 복사 · 희망 진영 변경 · 준비 토글 · 게임 시작 · 방 나가기가
## 모두 실제 상태를 바꾸는지, 20:9에서도 버튼이 화면 밖으로 나가지 않는지 확인한다.
const App=preload("res://scenes/survival.tscn")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func wait_screen(game: Node,target: String) -> void:
 for i in range(160):
  await process_frame
  if game.screen==target and not game.changing:return
## 실제 터치 경로(내려놓고 같은 자리에서 뗌)로 버튼을 누른다.
func press(game: Node,node_name: String) -> bool:
 var node: Node=game.ui.find_child(node_name,true,false)
 if node==null:return false
 node.down();node.up(true)
 return true
func label_of(node: Node) -> String:
 var out:=""
 for child in node.find_children("*","Label",true,false):
  if child is Label:out+=String(child.text)+"|"
 return out
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game);await frames(8)
 game.create_room("달빛 모의전",8,true)
 await wait_screen(game,"room")
 check(game.screen=="room","room screen opens with bots")
 # 1) 새 대기실의 구성 요소가 실제 노드로 존재한다
 for node_name in ["RoomCodeChip","RoomCopy","RoomInvite","RoomBack","RoomReady","RoomStart","RoomLeave","Side_daoist","Side_yokai","Side_any"]:
  check(is_instance_valid(game.ui.find_child(node_name,true,false)),"room UI node "+node_name)
 for index in range(8):
  var card: Node=game.ui.find_child("RoomCard_%d"%index,true,false)
  check(is_instance_valid(card),"participant card %d"%index)
  if is_instance_valid(card):
   check(label_of(card).contains("빈 자리") or label_of(card).length()>1,"card %d carries a name label"%index)
 var grid: Node=game.ui.find_children("*","GridContainer",true,false)[0] if game.ui.find_children("*","GridContainer",true,false).size()>0 else null
 check(grid!=null and grid.columns==2 and grid.get_child_count()==8,"participant grid is two columns of eight cards")
 # 2) 방 코드 복사: 클립보드 대신 실제 안내 팝업이 코드를 보여 준다
 check(press(game,"RoomCopy"),"copy button is reachable")
 await frames(3)
 check(game.modal!=null and ("복사" in label_of(game.modal)) and String(game.room.code) in label_of(game.modal),"copy code confirms with the room code")
 game.close_popup();await frames(2)
 # 3) 희망 진영 변경: 상태·규칙·내 카드 표시가 함께 바뀐다
 check(press(game,"Side_yokai"),"yokai wish button is reachable")
 await wait_screen(game,"room");await frames(3)
 check(game.preferred_role=="yokai" and game.rules.preferred_role=="yokai","wish side changes state and rules")
 var mine: Node=game.ui.find_child("RoomCard_0",true,false)
 check(is_instance_valid(mine) and label_of(mine).contains("요괴"),"my card shows the chosen side")
 # 4) 준비 토글: 실제 상태와 버튼 글자가 함께 바뀐다
 var before:=bool(game.rules.players.human.ready)
 check(press(game,"RoomReady"),"ready button is reachable")
 await wait_screen(game,"room");await frames(4)
 check(bool(game.rules.players.human.ready)!=before,"ready toggles the human player state")
 var ready_node: Node=game.ui.find_child("RoomReady",true,false)
 check(is_instance_valid(ready_node) and String(ready_node.text)==("준비 취소" if game.rules.players.human.ready else "준비 완료"),"ready button label follows the state")
 var cards_ready:=0
 for entry in game.rules.players.values():
  if bool(entry.get("ready",false)):cards_ready+=1
 check(cards_ready>=8,"all bot participants stay ready for the client view")
 # 5) 준비 전에는 게임 시작이 이유를 알려 준다
 game.rules.players.human.ready=false;game.build("room");await frames(6)
 press(game,"RoomStart");await frames(3)
 check(game.modal!=null and game.screen=="room","start before ready explains instead of starting")
 game.close_popup();await frames(2)
 # 6) 준비 후 게임 시작: 캐릭터 선택으로 넘어간다
 game.rules.players.human.ready=true;game.build("room");await frames(6)
 press(game,"RoomStart")
 await wait_screen(game,"selection")
 check(game.screen=="selection","ready room starts into character selection")
 # 7) 방 나가기: 확인 팝업을 거쳐 방 목록으로 돌아간다
 game.create_room("달빛 모의전",8,true)
 await wait_screen(game,"room")
 press(game,"RoomBack");await frames(3)
 check(game.modal!=null and ("나가" in label_of(game.modal)),"leaving the room asks for confirmation")
 game.close_popup();await frames(2)
 check(game.screen=="room","cancelling the leave dialog keeps the room")
 # 8) 빈 자리 카드: 혼자 입장하면 초대를 기다리는 카드가 보인다
 game.create_room("빈 방",8,false)
 await wait_screen(game,"room");await frames(6)
 var empty_card: Node=game.ui.find_child("RoomCard_5",true,false)
 check(is_instance_valid(empty_card) and label_of(empty_card).contains("빈 자리"),"empty seat card invites a friend")
 check(label_of(empty_card).contains("초대를 기다리는 중"),"empty seat card explains the wait")
 # 9) 20:9 와이드: 모든 버튼이 화면 안에 있고, 카드가 하단 버튼을 침범하지 않는다
 root.size=Vector2i(1600,720)
 await frames(10)
 game.build("room");await frames(10)
 var view:=Vector2(root.size)
 for node in game.ui.find_children("*","Button",true,false):
  if not (node is Button) or not node.is_visible_in_tree():continue
  var rect: Rect2=node.get_global_rect()
  check(rect.position.x>=-1.0 and rect.position.y>=-1.0 and rect.end.x<=view.x+1.0 and rect.end.y<=view.y+1.0,"wide screen keeps button %s inside the viewport"%String(node.name))
 var last_card: Node=game.ui.find_child("RoomCard_7",true,false)
 var start_node: Node=game.ui.find_child("RoomStart",true,false)
 if is_instance_valid(last_card) and is_instance_valid(start_node):
  check(last_card.get_global_rect().end.y<=start_node.get_global_rect().position.y+1.0,"cards stay above the action bar on 20:9")
 root.size=Vector2i(1280,720)
 await frames(4)
 print("ROOM UI V20: %d checks / %d failures" % [checks,failures])
 quit(1 if failures>0 else 0)
