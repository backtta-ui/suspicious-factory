class_name SealClientUI
extends Node
const Connection=preload("res://scripts/seal/connection.gd")
const Identity=preload("res://scripts/seal/identity.gd")
const Catalog=preload("res://scripts/seal/catalog.gd")
const Map=preload("res://scripts/seal/map.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const Village=preload("res://scripts/woo/village.gd")
var game: Node
var connection: SealConnection
var profile: Dictionary
var state: Dictionary={}
var screen:="login"
var status_label: Label
var lobby_art: Control
var lobby_art_key:=""
var roster_label: Label
var title_label: Label
var timer_label: Label
var role_label: Label
var event_label: Label
var world: WooVillage
var camera: Camera2D
var avatars: Dictionary={}
var actor_targets: Dictionary={}
var nameplates: Dictionary={}
var clone_avatars: Dictionary={}
var stick: TouchJoystick
var skill_buttons: Array[Button]=[]
var role_button: Button
var interact_button: Button
var meeting_button: Button
var start_button: Button
var popup: Control
var popup_notice: Label
var meeting_log: Label
var meeting_timer: Label
var move_left:=0.0
var name_input: LineEdit
var address_input: LineEdit
var code_input: LineEdit
var current_role_skill:="capture"
var last_event:=0
var result_round:=-1
var mini: WooLocalMinimap
var message:="서버 주소를 입력하고 연결하세요"
func _ready() -> void:
 profile=Identity.load_profile();connection=Connection.new();connection.profile=profile;connection.room=str(profile.get("last_room",""));add_child(connection)
 connection.packet.connect(receive);connection.status.connect(update_status)
 game.sound.context="village";game.sound.map_id="gyewol_village"
 build_login()
func _exit_tree() -> void:
 if is_instance_valid(connection):connection.stop()
func panel(title: String) -> VBoxContainer:
 game.active_context="seal";game.new_ui()
 var shade:=ColorRect.new();shade.color=Color("121927");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);game.ui.add_child(shade)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=38;margin.offset_right=-38;margin.offset_top=24;margin.offset_bottom=-24;game.ui.add_child(margin)
 var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",8);margin.add_child(stack)
 stack.add_child(game.text(title,32,game.GOLD));return stack
func edit(placeholder: String,value: String) -> LineEdit:
 var line:=LineEdit.new();line.placeholder_text=placeholder;line.text=value;line.custom_minimum_size=Vector2(300,56);line.add_theme_font_size_override("font_size",20);return line
func update_status(value: String) -> void:
 message=value
 if is_instance_valid(status_label):status_label.text=message
 if is_instance_valid(popup_notice):popup_notice.text=message
func build_login() -> void:
 screen="login"
 var stack:=panel("봉인의 밤 · 6~8인 실시간 멀티플레이")
 stack.add_child(game.text("서버 권한 판정 · 익명 접속 · 한 판 약8분",19))
 name_input=edit("닉네임",profile.nickname);name_input.max_length=12;stack.add_child(name_input)
 address_input=edit("https://서버.onrender.com 또는 wss://서버 주소",profile.endpoint);stack.add_child(address_input)
 var row:=HBoxContainer.new();stack.add_child(row)
 row.add_child(game.button("서버 연결",connect_server,true));row.add_child(game.button("공통 도술 두 칸 선택",show_loadout))
 status_label=game.text(message,18,Color("98bad5"));stack.add_child(status_label)
 var actions:=HBoxContainer.new();stack.add_child(actions)
 actions.add_child(game.button("빠른 대전",join_room.bind("quick"),true));actions.add_child(game.button("방 만들기",join_room.bind("create")))
 var code_row:=HBoxContainer.new();stack.add_child(code_row)
 code_input=edit("6자리 방 코드","");code_input.max_length=6;code_row.add_child(code_input);code_row.add_child(game.button("코드 입장",join_room.bind("join")))
 stack.add_child(game.text("주소가 아직 없다면 접속 기능은 대기 상태입니다.\n같은 저장소의 Render 무료 배포 안내를 따라 서버를 만든 후 주소를 입력하세요.",17))
 stack.add_child(game.button("서버 무료 배포 안내",func()->void:OS.shell_open("https://github.com/backtta-ui/suspicious-factory/blob/main/docs/V2.0-SERVER.md")))
 stack.add_child(game.button("메인으로",exit_to_main))
func connect_server() -> void:
 var address: String=address_input.text.strip_edges().trim_suffix("/")
 if address.begins_with("https://"):address="wss://"+address.trim_prefix("https://")
 elif address.begins_with("http://"):address="ws://"+address.trim_prefix("http://")
 profile.nickname=Catalog.clean_name(name_input.text);profile.endpoint=address;Identity.save_profile(profile)
 if connection.connect_to(address)!=OK:update_status("주소 형식 또는 네트워크를 확인하세요")
func join_room(op: String) -> void:
 if not connection.authenticated:update_status("먼저 서버 연결을 완료하세요");return
 var forest_mastery:=false
 var save: Dictionary=game.Save.load_game()
 if not save.is_empty():forest_mastery=save.get("completed_paintings",[]).has("fox_forest") or save.get("rpg",{}).get("adventure_unlocks",[]).has("forest_cat")
 connection.send({"op":op,"appearance":game.wardrobe.data.appearance.duplicate(),"name":Catalog.clean_name(name_input.text),"room":code_input.text.strip_edges(),"slots":profile.slots,"forest_mastery":forest_mastery,"form":profile.get("form","jar")})
func show_loadout() -> void:
 var stack:=open_popup("공통 도술 · 두 칸")
 if stack==null:return
 stack.add_child(game.text("모든 참가자에게 같은 기본 선택지를 제공합니다.\n모험 완료는 둔갑 외형 등 수집 선택지로 연결하며 전투력 차이를 만들지 않습니다.",17))
 var grid:=GridContainer.new();grid.columns=4;stack.add_child(grid)
 for id in Catalog.COMMON:
  var b: Button=game.button(Catalog.COMMON[id].name+(" ✓" if profile.slots.has(id) else ""),func()->void:
   if profile.slots.has(id):profile.slots.erase(id)
   elif profile.slots.size()<2:profile.slots.append(id)
   else:profile.slots.pop_front();profile.slots.append(id)
   Identity.save_profile(profile);close_popup();show_loadout())
  b.custom_minimum_size=Vector2(180,90);grid.add_child(b)
 var saved: Dictionary=game.Save.load_game()
 var mastery: bool=not saved.is_empty() and (saved.get("completed_paintings",[]).has("fox_forest") or saved.get("rpg",{}).get("adventure_unlocks",[]).has("forest_cat"))
 var variant: Button=game.button("여우의 숲 고양이 둔갑 · "+("선택: "+str(profile.get("form","jar")) if mastery else "사당 퍼즐 또는 숲 완료로 해금"),func()->void:profile.form="jar" if profile.get("form","jar")=="cat" else "cat";Identity.save_profile(profile);close_popup();show_loadout())
 variant.disabled=not mastery;variant.add_theme_font_size_override("font_size",16);stack.add_child(variant)
 stack.add_child(game.button("닫기",close_popup,true))
func receive(data: Dictionary) -> void:
 var op: String=str(data.get("op",""))
 if op=="joined":profile.last_room=data.room;Identity.save_profile(profile);state={};build_lobby()
 elif op=="left":profile.last_room="";Identity.save_profile(profile);dispose_world();state={};build_login()
 elif op=="error" or op=="reply":
  if data.has("error"):update_status(str(data.error))
  if data.get("room_expired",false):profile.last_room="";Identity.save_profile(profile);dispose_world();state={};build_login()
  if data.has("notice"):update_status(str(data.notice))
  if data.has("challenge"):challenge(data.challenge)
 elif op=="state":
  var previous: String=str(state.get("phase",""));state=data.state
  var wins: int=int(state.self.get("career_wins",0))
  if wins>int(game.wardrobe.data.server_wins.get(connection.endpoint,0)):game.wardrobe.record_server_wins(connection.endpoint,wins)
  if state.phase=="lobby":
   if screen!="lobby":dispose_world();build_lobby()
   update_lobby()
  else:
   if screen!="game":build_world();build_hud()
   if state.phase in ["discuss","vote"] and previous!=state.phase:show_meeting()
   if previous in ["discuss","vote"] and state.phase not in ["discuss","vote"]:close_popup()
   if state.phase=="result" and result_round!=int(state.round):result_round=int(state.round);show_result()
   update_actors()
func build_lobby() -> void:
 screen="lobby";var stack:=panel("봉인의 밤 · 방 "+connection.room)
 stack.add_child(game.text("6~8명 모두 준비하면 방장만 시작할 수 있습니다. 요괴는 항상2명입니다.",19))
 lobby_art=Control.new();lobby_art.custom_minimum_size=Vector2(720,90);stack.add_child(lobby_art);lobby_art_key=""
 roster_label=game.text("참가자 확인 중…",17);stack.add_child(roster_label)
 status_label=game.text(message,17,Color("98bad5"));stack.add_child(status_label)
 var row:=HBoxContainer.new();stack.add_child(row)
 row.add_child(game.button("준비 / 취소",func()->void:
  var ready:=false
  for p in state.get("roster",[]):
   if p.uid==connection.uid:ready=p.ready
  connection.send({"op":"ready","value":not ready}),true))
 start_button=game.button("방장 시작",func()->void:connection.send({"op":"start"}));row.add_child(start_button)
 row.add_child(game.button("방 코드 복사",func()->void:DisplayServer.clipboard_set(connection.room)))
 stack.add_child(game.button("방 나가기",leave_room))
func update_lobby() -> void:
 if not is_instance_valid(roster_label):return
 var art_key:=JSON.stringify(state.roster)
 if art_key!=lobby_art_key and is_instance_valid(lobby_art):
  lobby_art_key=art_key
  for child in lobby_art.get_children():child.queue_free()
  for i in range(state.roster.size()):
   var hero:=Actor.new();hero.network_remote=true;hero.cosmetic=state.roster[i].get("cosmetic",{});hero.position=Vector2(45+i*88,88);hero.scale=Vector2(1.7,1.7);lobby_art.add_child(hero);hero.collision_layer=0;hero.collision_mask=0
 var lines: Array[String]=[]
 for p in state.roster:lines.append(("♔ " if state.host==p.uid else "")+p.name+" · "+("준비" if p.ready else "대기")+(" · 재접속 대기" if not p.connected else ""))
 start_button.disabled=state.host!=connection.uid or state.roster.size()<6 or not state.roster.all(func(p: Dictionary)->bool:return p.ready and p.connected)
 roster_label.text="%d / 8명\n"%state.roster.size()+"\n".join(lines)
func build_world() -> void:
 if is_instance_valid(world):return
 world=Village.new();world.cycle_enabled=false;world.time_of_day=.5;add_child(world)
 var fx:=preload("res://scripts/seal/world_fx.gd").new();fx.client=self;fx.z_index=5;world.add_child(fx)
func dispose_world() -> void:
 if is_instance_valid(world):world.queue_free()
 world=null;camera=null;avatars.clear();actor_targets.clear();nameplates.clear();clone_avatars.clear()
func update_actors() -> void:
 if not is_instance_valid(world):return
 var visible_ids: Array=[]
 for info in state.actors:
  var id: String=info.uid;visible_ids.append(id)
  if not avatars.has(id):
   var actor:=Actor.new();actor.network_remote=true;actor.position=Vector2(info.position[0],info.position[1]);world.add_child(actor);avatars[id]=actor
   var label: Label=game.text("",11,Color("ebe5d7"));label.position=Vector2(-60,-65);label.size=Vector2(120,20);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;actor.add_child(label);nameplates[id]=label
   if id==connection.uid:
    camera=Camera2D.new();camera.zoom=Vector2(2,2);camera.position=Vector2(0,-36);camera.position_smoothing_enabled=true;camera.position_smoothing_speed=6;camera.limit_left=0;camera.limit_top=0;camera.limit_right=3400;camera.limit_bottom=1900;actor.add_child(camera);camera.make_current()
  var actor: WooActor=avatars[id];actor_targets[id]=Vector2(info.position[0],info.position[1]);actor.cosmetic=info.get("cosmetic",{});actor.facing=int(info.facing);actor.appearance_form=info.form;actor.jar=false;actor.velocity=Vector2(20,0) if info.moving else Vector2.ZERO
  if info.casting:actor.transforming=.12
  nameplates[id].text=info.name+(" · 나" if id==connection.uid else "")
 for id in avatars.keys():
  if not visible_ids.has(id):avatars[id].queue_free();avatars.erase(id);actor_targets.erase(id);nameplates.erase(id)
 # Decoys use the same base actor/name presentation, without public owner or role data.
 var clones: Array=[]
 for e in state.effects:
  if e.kind!="clone":continue
  var id: String=str(e.id);clones.append(id)
  if not clone_avatars.has(id):
   var clone:=Actor.new();clone.network_remote=true;clone.position=Vector2(e.position[0],e.position[1]);world.add_child(clone);clone_avatars[id]=clone
   var label: Label=game.text(e.name,11);label.position=Vector2(-60,-65);label.size.x=120;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;clone.add_child(label)
  clone_avatars[id].facing=int(e.facing);clone_avatars[id].cosmetic=e.get("cosmetic",{})
 for id in clone_avatars.keys():
  if not clones.has(id):clone_avatars[id].queue_free();clone_avatars.erase(id)
func build_hud() -> void:
 screen="game";game.active_context="seal";game.new_ui()
 title_label=game.text("봉인의 밤",20,game.GOLD);title_label.position=Vector2(24,14);game.ui.add_child(title_label)
 role_label=game.text("",17);role_label.position=Vector2(24,48);game.ui.add_child(role_label)
 timer_label=game.text("",17);timer_label.position=Vector2(24,76);game.ui.add_child(timer_label)
 event_label=game.text("",17,Color("e9d8b1"));event_label.position=Vector2(24,110);event_label.custom_minimum_size.x=500;game.ui.add_child(event_label)
 status_label=game.text(message,14,Color("96b6ca"));status_label.position=Vector2(24,145);game.ui.add_child(status_label)
 var menu: Button=game.button("메뉴",show_pause);menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);menu.offset_left=-280;menu.offset_right=-162;menu.offset_top=22;menu.offset_bottom=82;game.ui.add_child(menu)
 mini=preload("res://scripts/woo/minimap.gd").new();mini.elder_done=true;mini.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);mini.offset_left=-150;mini.offset_right=-18;mini.offset_top=10;mini.offset_bottom=142;game.ui.add_child(mini)
 stick=preload("res://scripts/joystick.gd").new();stick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);stick.position=Vector2(74,-222);stick.size=Vector2(174,174);game.ui.add_child(stick)
 skill_buttons=[]
 for i in range(2):
  var b:=skill_button("도술%d"%i,Vector2(-280+i*126,-260),Vector2(112,112),cast_common.bind(i));skill_buttons.append(b)
 role_button=skill_button("역할 능력",Vector2(-162,-146),Vector2(128,128),role_action)
 interact_button=skill_button("상호작용",Vector2(-306,-132),Vector2(112,112),interact)
 meeting_button=game.button("봉인 회의",func()->void:connection.send({"op":"meeting"}));meeting_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);meeting_button.offset_left=-180;meeting_button.offset_right=-28;meeting_button.offset_top=-350;meeting_button.offset_bottom=-286;game.ui.add_child(meeting_button)
func skill_button(label: String,pos: Vector2,dimensions: Vector2,callback: Callable) -> Button:
 var b: Button=game.button(label,callback,true);b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);b.position=pos;b.size=dimensions;game.ui.add_child(b)
 for child in b.get_children():child.hide()
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:b.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
 for mode in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:b.add_theme_color_override(mode,Color(0,0,0,0))
 var badge:=preload("res://scripts/woo/skill_badge.gd").new();badge.name="Badge";badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);b.add_child(badge)
 return b
func closest(captured_only: bool=false) -> String:
 if state.is_empty():return ""
 var origin:=Vector2(state.self.position[0],state.self.position[1]);var distance:=250.0;var found:=""
 for p in state.actors:
  if p.uid==connection.uid:continue
  if captured_only:
   var jailed:=false
   for r in state.roster:
    if r.uid==p.uid:jailed=r.captured
   if not jailed:continue
  var d:=origin.distance_to(Vector2(p.position[0],p.position[1]))
  if d<distance:distance=d;found=p.uid
 return found
func cast_common(index: int) -> void:
 if state.is_empty():return
 var id: String=state.self.slots[index]
 connection.send({"op":"cast","skill":id,"target":closest()})
func role_action() -> void:
 if state.is_empty():return
 if state.self.captured:connection.send({"op":"escape"});return
 if state.self.role=="yokai":connection.send({"op":"cast","skill":current_role_skill,"target":closest()})
 else:connection.send({"op":"rescue","target":closest(true)})
func interact() -> void:
 if state.is_empty():return
 var origin:=Vector2(state.self.position[0],state.self.position[1])
 var prisoner:=closest(true)
 if prisoner!="":
  for p in state.actors:
   if p.uid==prisoner and origin.distance_to(Vector2(p.position[0],p.position[1]))<68:connection.send({"op":"rescue","target":prisoner});return
 if state.self.carry!="":connection.send({"op":"task_open","mission":int(state.self.carry)});return
 for m in state.missions:
  if m.done:continue
  var p:=Vector2(m.position[0],m.position[1])
  if m.kind=="fragments":
   for i in range(3):
    if origin.distance_to(Map.safe(p+Vector2.from_angle(i*TAU/3)*78))<65 and not state.self.fragments.has(float(i)) and not state.self.fragments.has(i):connection.send({"op":"collect","mission":m.id,"piece":i});return
  if origin.distance_to(p)<85:connection.send({"op":"task_open","mission":m.id});return
 if origin.distance_to(Map.ALTAR)<110:connection.send({"op":"fallback"})
 else:update_status("봉인 미션, 감옥 또는 중앙 봉인진 가까이 접근하세요")
func open_popup(title: String) -> VBoxContainer:
 if is_instance_valid(popup):close_popup()
 game.active_context="seal_modal"
 if is_instance_valid(stick):stick.reset();stick.input_enabled=false
 connection.send({"op":"move","intent":[0,0]})
 popup=Control.new();popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);game.ui.add_child(popup)
 var shade:=ColorRect.new();shade.color=Color(.015,.02,.04,.90);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);popup.add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);popup.add_child(center)
 var panel:=PanelContainer.new();panel.custom_minimum_size.x=720;panel.add_theme_stylebox_override("panel",game.style(Color("171d2c"),12));center.add_child(panel)
 var stack:=VBoxContainer.new();panel.add_child(stack);stack.add_child(game.text(title,28,game.GOLD))
 popup_notice=game.text("",15,Color("e1bd86"));stack.add_child(popup_notice)
 return stack
func close_popup() -> void:
 if is_instance_valid(popup):popup.hide();popup.queue_free()
 popup=null;popup_notice=null;meeting_log=null;meeting_timer=null;game.active_context="seal"
 if is_instance_valid(stick):stick.reset();stick.input_enabled=true
func challenge(info: Dictionary) -> void:
 var stack:=open_popup("봉印 · "+str(info.kind))
 var runes: Array[String]=["山","水","火","風"]
 var pattern: Array=info.pattern
 stack.add_child(game.text("문양: "+runes[int(pattern[0])]+"  "+runes[int(pattern[1])]+"  "+runes[int(pattern[2])],24))
 var buttons: Array[Button]=[]
 if info.kind=="well":
  stack.add_child(game.text("세 문양을 돌려 정화 문양과 맞추세요",18))
  var rotation: Array=[0,0,0];var row:=HBoxContainer.new();stack.add_child(row)
  for i in range(3):
   var b: Button=game.button(runes[0],func()->void:rotation[i]=(int(rotation[i])+1)%4;row.get_child(i).text=runes[rotation[i]])
   row.add_child(b);buttons.append(b)
  var submit: Button=game.button("우물 정화",func()->void:connection.send({"op":"task","mission":info.mission,"nonce":info.nonce,"answer":rotation});close_popup(),true);stack.add_child(submit);buttons.append(submit)
 else:
  stack.add_child(game.text("%d번째 문양에 맞는 부적을 붙이세요"%(int(info.step)+1),19))
  var row:=HBoxContainer.new();stack.add_child(row)
  for i in range(4):
   var b: Button=game.button(runes[i],func()->void:connection.send({"op":"task","mission":info.mission,"nonce":info.nonce,"answer":i});close_popup());row.add_child(b);buttons.append(b)
 for b in buttons:b.disabled=true
 stack.add_child(game.button("닫기",close_popup))
 await get_tree().create_timer(.4).timeout
 for b in buttons:
  if is_instance_valid(b):b.disabled=false
func show_meeting() -> void:
 var stack:=open_popup("봉인 회의 · "+("토론" if state.phase=="discuss" else "투표"))
 meeting_timer=game.text("",18,game.GOLD);stack.add_child(meeting_timer)
 meeting_log=game.text("",17);meeting_log.custom_minimum_size=Vector2(690,110);meeting_log.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(meeting_log)
 stack.add_child(game.text("무고한 도사를 지목하면 35초 활동 제한. 동점/기권은 봉인하지 않습니다.",17))
 var grid:=GridContainer.new();grid.columns=4;stack.add_child(grid)
 for p in state.roster:
  var b: Button=game.button(p.name+(" · 포획" if p.captured else ""),func()->void:connection.send({"op":"vote","target":p.uid});update_status("투표를 전송했습니다"));b.disabled=state.phase!="vote" or p.sealed or state.self.captured;b.clip_text=true;b.custom_minimum_size=Vector2(180,64);b.add_theme_font_size_override("font_size",16);grid.add_child(b)
 var row:=HBoxContainer.new();stack.add_child(row)
 var skip: Button=game.button("기권",func()->void:connection.send({"op":"vote","target":"skip"}));skip.disabled=state.phase!="vote";row.add_child(skip)
 var chat:=edit("회의 채팅 · 최대72자","");chat.max_length=72;row.add_child(chat);row.add_child(game.button("전송",func()->void:connection.send({"op":"chat","text":chat.text});chat.text=""))
 stack.add_child(game.button("회의 상황 보기",close_popup))
func show_result() -> void:
 var victory: bool=(state.self.role==state.winner)
 var key: String=str(state.get("match",connection.room+":"+str(state.round)))
 if profile.get("last_result","")!=key:
  profile.last_result=key;profile.played=int(profile.get("played",0))+1
  profile.wins=maxi(int(profile.get("wins",0)),int(state.self.get("career_wins",0)))
  Identity.save_profile(profile)
 var stack:=open_popup(("승리 · " if victory else "패배 · ")+("도사 최종 봉인" if state.winner=="daoist" else "요괴의 밤"))
 var portrait:=Control.new();portrait.custom_minimum_size=Vector2(180,135);stack.add_child(portrait)
 var hero:=Actor.new();hero.network_remote=true;hero.cosmetic=game.wardrobe.data.appearance.duplicate();hero.position=Vector2(100,125);hero.scale=Vector2(2.4,2.4);portrait.add_child(hero)
 stack.add_child(game.text("한 판을 마쳤습니다. 방장이 재대전을 열 수 있습니다.",21))
 var rematch: Button=game.button("방장 재대전",func()->void:close_popup();connection.send({"op":"rematch"}),true);rematch.disabled=state.host!=connection.uid;stack.add_child(rematch)
 stack.add_child(game.button("방 나가기",leave_room))
func show_pause() -> void:
 var stack:=open_popup("봉인의 밤")
 stack.add_child(game.text("방 "+connection.room+" · 지연 %dms"%connection.latency_ms,19))
 if not state.is_empty() and state.self.role=="yokai":
  var grid:=GridContainer.new();grid.columns=3;stack.add_child(grid)
  for id in Catalog.EVIL:grid.add_child(game.button(Catalog.EVIL[id].name,func()->void:current_role_skill=id;close_popup()))
 if not state.is_empty() and state.phase in ["discuss","vote"]:stack.add_child(game.button("회의 / 투표",show_meeting))
 stack.add_child(game.button("돌아가기",close_popup,true));stack.add_child(game.button("방 나가기",leave_room))
func leave_room() -> void:
 close_popup();connection.send({"op":"leave"});connection.room="";profile.last_room="";Identity.save_profile(profile);dispose_world();state={};build_login()
func exit_to_main() -> void:
 connection.stop();dispose_world();game.seal_client=null;game.show_menu(false);queue_free()
func back() -> void:
 if is_instance_valid(popup):close_popup()
 elif screen=="game":show_pause()
 elif screen=="lobby":leave_room()
 else:exit_to_main()
func _process(delta: float) -> void:
 if screen!="game" or state.is_empty() or not is_instance_valid(stick):return
 if is_instance_valid(meeting_log):
  var lines: Array[String]=[]
  for i in range(maxi(0,state.events.size()-4),state.events.size()):lines.append(state.events[i].text)
  meeting_log.text="\n".join(lines)
 if is_instance_valid(meeting_timer):meeting_timer.text="남은 시간 %d초 · %s" % [int(state.phase_time),"투표 완료" if state.self.voted else "토론 / 지목"]
 var self_state: Dictionary=state.self
 var can_move: bool=not is_instance_valid(popup) and state.phase in ["prepare","roam"] and not self_state.captured and not self_state.sealed and self_state.penalty<=0 and not (state.phase=="prepare" and self_state.role=="yokai")
 stick.input_enabled=can_move and connection.authenticated
 move_left-=delta
 if move_left<=0:
  move_left=.05
  var move: Vector2=stick.vector if can_move else Vector2.ZERO
  var face:=posmod(roundi(move.angle()/(PI/4)),8) if move.length()>.1 else int(self_state.facing)
  connection.send({"op":"move","intent":[move.x,move.y],"facing":face})
 for id in avatars:
  var actor: WooActor=avatars[id];var target: Vector2=actor_targets.get(id,actor.position)
  actor.animation_time+=delta*7 if actor.velocity.length()>0 else delta
  actor.gait_phase+=delta*11;actor.gait_weight=move_toward(actor.gait_weight,1.0 if actor.velocity.length()>0 else 0.0,delta*10)
  if id==connection.uid and can_move:
   actor.position=Map.move(actor.position,actor.position+stick.vector*(64 if self_state.carry!="" else Catalog.MOVE_SPEED)*minf(delta,.05))
  if actor.position.distance_to(target)>60:actor.position=target;actor.reset_physics_interpolation()
  else:actor.position=actor.position.lerp(target,minf(1,delta*(10 if id==connection.uid else 12)))
 if is_instance_valid(mini) and avatars.has(connection.uid):mini.update_local(avatars[connection.uid].position,true)
 title_label.text="봉인의 밤 · 방 "+connection.room
 var allies: Array[String]=[]
 for id in self_state.teammates:
  for p in state.roster:
   if p.uid==id:allies.append(p.name)
 role_label.text=("내 역할: 요괴 · 동료 "+", ".join(allies)) if self_state.role=="yokai" else "내 역할: 도사 · 정체를 추리하고 두 요괴를 봉인하세요"
 if self_state.captured:role_label.text="포획됨 · 감옥에서 구출을 기다리거나 12초 안에 자력해봉(1회)을 시작하세요"
 if self_state.sealed:role_label.text="봉인 / 기권 상태 · 현재 판 관전 제한"
 timer_label.text="%02d:%02d · 봉인 기회 %d · %s"%[int(state.time)/60,int(state.time)%60,state.resources,state.phase]
 if not state.events.is_empty():event_label.text=state.events.back().text
 for i in range(2):
  var id: String=self_state.slots[i];var b:=skill_buttons[i];var badge: WooSkillBadge=b.get_node("Badge");badge.skill=Catalog.COMMON[id].icon;badge.maximum=Catalog.COMMON[id].cd;badge.remaining=float(self_state.cooldowns.get(id,0));b.disabled=not can_move or badge.remaining>0
 var role_badge: WooSkillBadge=role_button.get_node("Badge")
 role_badge.skill="rescue" if self_state.role!="yokai" or self_state.captured else Catalog.EVIL[current_role_skill].icon
 role_badge.remaining=float(self_state.channel) if self_state.channel>0 else (float(self_state.cooldowns.get(current_role_skill,0)) if self_state.role=="yokai" else 0);role_badge.maximum=5.0 if self_state.channel>0 else float(Catalog.EVIL[current_role_skill].cd)
 role_button.disabled=(not can_move and not self_state.captured) or (self_state.captured and self_state.escape<=0)
 var interact_badge: WooSkillBadge=interact_button.get_node("Badge");interact_badge.skill="talisman";interact_button.disabled=not can_move
 meeting_button.disabled=not can_move or state.resources<1 or state.phase!="roam"
