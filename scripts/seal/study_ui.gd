class_name SealStudyUI
extends Node
const C=preload("res://scripts/seal/catalog.gd")
const Study=preload("res://scripts/seal/study.gd")
var client: SealClientUI
var world: Node2D
var hero: WooActor
var stick: TouchJoystick
var label: Label
var button: Button
var state: Dictionary={}
var send_left:=0.0
var env_nodes: Dictionary={}
var markers: Node2D
var arena:=preload("res://scripts/seal/arena.gd").new("forest")
var target:=Vector2(260,780)
func _ready() -> void:
 world=preload("res://scripts/woo/forest.gd").new();add_child(world)
 hero=preload("res://scripts/woo/actor.gd").new();hero.network_remote=true;hero.position=Vector2(260,780);hero.cosmetic=client.game.wardrobe.data.appearance.duplicate();world.add_child(hero)
 var camera:=Camera2D.new();camera.zoom=Vector2(2,2);camera.position=Vector2(0,-30);camera.limit_left=0;camera.limit_top=0;camera.limit_right=3000;camera.limit_bottom=2160;hero.add_child(camera);camera.make_current()
 markers=Node2D.new();markers.draw.connect(draw_markers);world.add_child(markers)
 var jar:=preload("res://scripts/seal/environment_asset.gd").new();jar.kind="jar";jar.position=Study.POINTS[0];world.add_child(jar)
 client.game.new_ui();client.game.active_context="seal"
 label=client.game.text("그림 수련 · 도술 문양을 찾아 습득하세요",20,client.game.GOLD);label.position=Vector2(26,24);client.game.ui.add_child(label)
 stick=preload("res://scripts/joystick.gd").new();stick.position=Vector2(74,498);stick.size=Vector2(174,174);client.game.ui.add_child(stick)
 button=client.game.button("문양 살펴보기",interact,true);button.position=Vector2(970,550);button.custom_minimum_size=Vector2(270,92);client.game.ui.add_child(button)
 var back: Button=client.game.button("수련에서 돌아가기",func()->void:client.connection.send({"op":"study_end"}));back.position=Vector2(950,24);back.custom_minimum_size=Vector2(290,64);client.game.ui.add_child(back)
 var guide: Label=client.game.text("먼저 가까운 항아리 문양 → 둔갑술\n그 옆 푸른 문양 → 축지법 · 2개만 배워도 준비 가능",17);guide.position=Vector2(26,70);client.game.ui.add_child(guide)
func nearest() -> String:
 if state.is_empty():return ""
 var distance:=78.0;var id:=""
 for i in range(Study.POINTS.size()):
  var d:=hero.position.distance_to(Study.POINTS[i])
  if d<distance:distance=d;id=C.COMMON.keys()[i]
 return id
func interact() -> void:
 var id:=nearest()
 if id!="":client.connection.send({"op":"study_open","skill":id})
func update_state(data: Dictionary) -> void:
 state=data
 for asset in data.get("assets",[]):
  if not env_nodes.has(asset.id):
   var node:=preload("res://scripts/seal/environment_asset.gd").new();node.kind=asset.kind;world.add_child(node);env_nodes[asset.id]=node
  var node: SealEnvironmentAsset=env_nodes[asset.id];var position:=Vector2(asset.position[0],asset.position[1]);node.moving=node.position.distance_to(position)>.1;node.facing=4 if position.x<node.position.x else 0;node.position=position
 target=Vector2(data.position[0],data.position[1]);hero.facing=int(data.facing)
 markers.queue_redraw()
func _process(delta: float) -> void:
 if not is_instance_valid(hero):return
 var can_move:=not is_instance_valid(client.popup);stick.input_enabled=can_move and client.connection.authenticated
 var move: Vector2=stick.vector if can_move else Vector2.ZERO
 var previous:=hero.position
 hero.position=arena.move(hero.position,hero.position+move*88*minf(delta,.05))
 if hero.position.distance_to(target)>60:hero.position=target
 else:hero.position=hero.position.lerp(target,minf(1,delta*8))
 hero.velocity=move*88;hero.animation_time+=delta*7;hero.gait_phase+=minf(hero.position.distance_to(previous),60)*.13;hero.gait_weight=move_toward(hero.gait_weight,1.0 if move.length()>.1 else 0.0,delta*10)
 send_left-=delta
 if send_left<=0:send_left=.05;client.connection.send({"op":"study_move","intent":[move.x,move.y]})
 var id:=nearest();button.disabled=id=="" or not can_move
 button.text="문양에 다가가세요" if id=="" else C.COMMON[id].name+" 문양"
 if not state.is_empty():label.text="여우의 숲 · 짧은 도술 발견 수련 · 습득 %d / 8"%state.owned.size()
func draw_markers() -> void:
 for i in range(Study.POINTS.size()):
  var id: String=C.COMMON.keys()[i];var p: Vector2=Study.POINTS[i]
  var learned: bool=state.get("owned",[]).has(id)
  markers.draw_arc(p,20,0,TAU,24,Color("83bd93") if learned else Color("d7be80"),2,true)
  markers.draw_string(preload("res://assets/fonts/NotoSansCJK-Regular.ttc"),p+Vector2(-32,-30),C.COMMON[id].name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0dfb9"))
  if not learned:markers.draw_circle(p+Vector2(0,-9),3,Color("9edaff"))
