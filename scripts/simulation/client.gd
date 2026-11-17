extends SealClientUI
## Same online world/HUD/puzzles, with an isolated in-process authority transport.
const Local=preload("res://scripts/simulation/transport.gd")
var original_camera:=true
var original_mode:=Node.PROCESS_MODE_INHERIT
var original_sound:=""
var role_round:=-1
var role_until:=0.0
var rescue_held:=false
const DESCRIPTIONS={"transform":"가까운 사물·동물 형상을 추출한 뒤 변신합니다.","blink":"바라보는 방향으로 이동합니다. 벽을 통과하지 않습니다.","clone":"현재 외형의 이동 분신을 만들어 교란합니다.","track":"근처 참가자가 실제로 남긴 최근 발자국을 봅니다.","shield":"포획을 한 번 막는 호신부를 준비합니다.","smoke":"연막을 만들어 범위 안팎의 시야를 차단합니다.","mask":"이름과 신원을 숨깁니다. 가까운 거리에서는 보입니다.","rescue":"해봉술 유지 중 동료 구출 시간이 단축됩니다."}
var entering:=false
func _ready() -> void:
 profile={"nickname":"나","wins":0,"played":0,"server_wins":{}}
 original_camera=game.camera.enabled;original_mode=game.world.process_mode;original_sound=game.sound.map_id
 game.world.hide();game.world.process_mode=Node.PROCESS_MODE_DISABLED;game.camera.enabled=false
 connection=Local.new();connection.staged_start=true;connection.appearance=game.wardrobe.data.appearance.duplicate(true)
 connection.packet.connect(receive);connection.status.connect(update_status);add_child(connection)
 message="오프라인 테스트 · 영구 해금/전적/재화/패스 변경 없음";connection.publish()
func receive(data: Dictionary) -> void:
 if entering:return
 if data.get("op","")=="state" and data.state.phase=="prepare" and screen=="lobby":
  enter_match(data);return
 super.receive(data)
func enter_match(data: Dictionary) -> void:
 entering=true;connection.suspended=true
 if not game.loading.begin("simulation",Callable(),exit_to_main):entering=false;connection.suspended=false;return
 game.loading.overlay.title="도술 모의전 · "+str(data.state.map_name)+" 준비 중..."
 if not await game.loading.prepare([connection.rules.arena.data.scene]):return
 connection.nav=Local.Nav.new(connection.rules.arena,false)
 await connection.nav.build(get_tree())
 super.receive(data)
 await get_tree().process_frame
 if not is_instance_valid(world) or not is_instance_valid(camera):game.loading.failure("모의전 맵/카메라 준비에 실패했습니다.");return
 game.loading.complete();game.loading.input_ready();entering=false;connection.suspended=false
func build_lobby() -> void:
 screen="lobby";var stack:=panel("도술 모의전 · 오프라인 대기실")
 stack.add_child(game.text("플레이어 1명 + 봇 5~7명 · 역할은 시작 후 결정 · 실제 계정 권한과 분리",18))
 lobby_art=Control.new();lobby_art.custom_minimum_size=Vector2(720,90);stack.add_child(lobby_art);lobby_art_key=""
 roster_label=game.text("",16);stack.add_child(roster_label);status_label=game.text(message,16);stack.add_child(status_label)
 var row:=HBoxContainer.new();stack.add_child(row)
 row.add_child(game.button("준비 완료 / 취소",func()->void:connection.send({"op":"ready","value":not state.roster[0].ready}),true))
 start_button=game.button("모의전 시작",func()->void:connection.send({"op":"start"}),true);row.add_child(start_button)
 row.add_child(game.button("캐릭터 선택",show_characters));row.add_child(game.button("도술 선택",show_loadout))
 var options:=HBoxContainer.new();stack.add_child(options)
 for size in [6,7,8]:options.add_child(game.button("%d인"%size,func()->void:connection.configure_size(size,connection.test_slots)))
 options.add_child(game.button("테스트 2/3슬롯",func()->void:connection.configure_size(connection.count,3 if connection.test_slots==2 else 2)))
 stack.add_child(game.button("광장 복귀",exit_to_main))
func update_lobby() -> void:
 super.update_lobby()
 if is_instance_valid(roster_label):roster_label.text=roster_label.text.replace("내 장착(무료는 역할 배정 후 확정)","테스트 장착")
 if is_instance_valid(start_button):start_button.disabled=start_button.disabled or connection.countdown>=0
 if is_instance_valid(status_label) and connection.countdown>=0:status_label.text="%.0f초 후 시작 · 맵과 역할 무작위 선정"%ceilf(connection.countdown)
func show_characters() -> void:
 if connection.rules.phase!="lobby" or connection.countdown>=0:return
 var stack:=open_popup("테스트 캐릭터 · 현재 캐릭터별 저장 차림 재사용")
 var wardrobe_catalog:=preload("res://scripts/wardrobe/catalog.gd")
 for id in wardrobe_catalog.CHARACTERS:
  stack.add_child(game.button(wardrobe_catalog.CHARACTERS[id].name,func()->void:
   var look: Dictionary=game.wardrobe.data.per_character.get(id,wardrobe_catalog.base_appearance(id)).duplicate(true)
   connection.send({"op":"appearance","appearance":look});close_popup()))
 stack.add_child(game.button("닫기",close_popup))
func show_loadout() -> void:
 if connection.rules.phase!="lobby" or connection.countdown>=0:return
 var stack:=open_popup("모의전 도술 · 임시 전체 해금 · %d칸"%connection.test_slots)
 var chosen: Array=preload("res://scripts/seal/loadout.gd").known(connection.rules.players[connection.uid].slots)
 var info: Label=game.text("현재: "+spell_names(chosen)+" · 눌러 추가/해제",17);stack.add_child(info)
 for id in Catalog.COMMON:
  var skill: String=id;var spec: Dictionary=Catalog.COMMON[id]
  var b: Button=game.button(spec.name+" · 쿨타임 %d초"%spec.cd,func()->void:
   if chosen.has(skill):chosen.erase(skill)
   elif chosen.size()<connection.test_slots:chosen.append(skill)
   info.text="선택: "+spell_names(chosen)+" / %d칸"%connection.test_slots
   refresh_cards(stack,chosen))
  b.text="        "+b.text;b.alignment=HORIZONTAL_ALIGNMENT_LEFT
  var badge:=preload("res://scripts/woo/skill_badge.gd").new();badge.skill=spec.icon;badge.position=Vector2(4,4);badge.size=Vector2(46,46);b.add_child(badge);stack.add_child(b)
  b.custom_minimum_size.x=640;b.clip_text=true;b.set_meta("skill",skill)
  var description: Label=game.text(DESCRIPTIONS[id],17);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(description)
 refresh_cards(stack,chosen)
 for id in Catalog.EVIL:
  var spec: Dictionary=Catalog.EVIL[id]
  stack.add_child(game.text("요괴 전용 · "+spec.name+" · 쿨타임 %d초"%spec.cd,16))
 var note: Label=game.text("요괴 고유 능력은 역할 배정 후 메뉴에서 선택합니다. 요괴의 사물 둔갑은 제외됩니다.",16);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(note)
 stack.add_child(game.button("선택 완료",func()->void:connection.send({"op":"loadout","slots":chosen});close_popup(),true))
 stack.add_child(game.button("취소",close_popup))
func refresh_cards(stack: Control,chosen: Array) -> void:
 for child in stack.get_children():
  if child is Button and child.has_meta("skill"):
   var id: String=child.get_meta("skill");child.text="        "+("✓ " if chosen.has(id) else "")+Catalog.COMMON[id].name+" · 쿨타임 %d초"%Catalog.COMMON[id].cd
func spell_names(ids: Array) -> String:
 var names: Array[String]=[]
 for id in ids:
  if Catalog.COMMON.has(id):names.append(Catalog.COMMON[id].name)
 return " / ".join(names)
func build_hud() -> void:
 super.build_hud()
 # Rescue is a hold action. Releasing the touch cancels the authoritative channel.
 role_button.button_down.connect(func()->void:
  if state.self.role=="daoist":rescue_held=true;connection.send({"op":"rescue","target":closest(true)}))
 role_button.button_up.connect(func()->void:
  if rescue_held:rescue_held=false;connection.send({"op":"cancel_channel"}))
 var spectator: Button=game.button("관전 대상",show_spectators);spectator.position=Vector2(24,180);game.ui.add_child(spectator);spectator.name="SpectatorButton"
func role_action() -> void:
 if state.is_empty() or state.self.role!="yokai":return
 if current_role_skill=="mimic":
  var stack:=open_popup("복제 대상 선택 · 보이는 참가자")
  for actor in state.actors:
   if actor.uid!=connection.uid:stack.add_child(game.button(actor.name,func()->void:connection.send({"op":"cast","skill":"mimic","target":actor.uid});close_popup()))
  stack.add_child(game.button("취소",close_popup));return
 super.role_action()
func interact() -> void:
 if state.is_empty():return
 var prisoner:=closest(true)
 if prisoner!="" and state.self.role=="daoist":update_status("구출 버튼을 4초 동안 누르세요. 손을 떼면 취소됩니다.");return
 super.interact()
func show_pause() -> void:
 super.show_pause()
 if state.get("phase","") in ["prepare","roam"]:
  var stack: VBoxContainer=popup.find_children("*","VBoxContainer",true,false)[0]
  stack.add_child(game.button("둔갑 해제",func()->void:connection.send({"op":"unmask"});close_popup()))
  for m in state.missions:
   stack.add_child(game.text(m.name+" · "+("완료" if m.done else "%d/3 진행"%m.step),17))
func show_spectators() -> void:
 if state.is_empty() or not state.self.sealed:return
 var stack:=open_popup("관전 · 살아 있는 참가자")
 for member in state.roster:
  if not member.sealed:stack.add_child(game.button(member.name,func()->void:connection.send({"op":"spectate","target":member.uid});close_popup()))
 stack.add_child(game.button("닫기",close_popup))
func show_result() -> void:
 var victory: bool=state.self.role==state.winner
 var stack:=open_popup(("승리" if victory else "패배")+" · "+("도사팀" if state.winner=="daoist" else "요괴팀"))
 stack.add_child(game.text("오프라인 모의전 결과 · 내 역할: "+("도사" if state.self.role=="daoist" else "요괴")+" · 실제 전적/보상 미반영",18))
 for member in state.roster:
  var stats: Dictionary=state.stats[member.uid]
  stack.add_child(game.text("%s · %s · 임무 %d / 포획 %d / 구조 %d"%[member.name,"도사" if member.role=="daoist" else "요괴",stats.tasks,stats.captures,stats.rescues],17))
 stack.add_child(game.button("재대결 · 대기실",func()->void:close_popup();connection.send({"op":"rematch"}),true))
 stack.add_child(game.button("광장 복귀",exit_to_main))
func leave_room() -> void:exit_to_main()
func exit_to_main() -> void:
 if game.loading.busy and not game.loading.failed:game.loading.release()
 connection.stop();dispose_world();close_popup();game.world.show();game.world.process_mode=original_mode
 game.camera.enabled=original_camera;game.camera.make_current();game.camera.reset_smoothing();game.sound.map_id=original_sound
 game.seal_client=null;game.screen_name="playing";game.active_context="hud";game.set_paused(false);game.build_hud();queue_free()
func _process(delta: float) -> void:
 super._process(delta)
 if state.is_empty():return
 if screen=="game":
  title_label.text="도술 모의전 · "+str(state.map_name)+" · 서버 없음"
  timer_label.text+=" · 임무 %d/%d"%[state.missions.filter(func(m: Dictionary)->bool:return m.done).size(),state.missions.size()]
  if role_round!=int(state.round):role_round=int(state.round);role_until=Time.get_ticks_msec()+4500
  if Time.get_ticks_msec()<role_until:event_label.text="요괴를 피해 임무를 완수하고 동료를 구출하세요." if state.self.role=="daoist" else "도사들 사이에 숨어 정체를 들키지 않고 포획하세요."
  if state.self.captured:role_button.disabled=true
  if float(state.self.channel)>0:role_button.get_node("Badge").maximum=4.0
  if state.self.sealed:
   role_label.text="최종 탈락 · 관전 중";var target: String=str(state.get("spectate",""))
   if avatars.has(target) and is_instance_valid(camera):camera.global_position=avatars[target].global_position+Vector2(0,-36)
  if is_instance_valid(game.ui.get_node_or_null("SpectatorButton")):game.ui.get_node("SpectatorButton").visible=state.self.sealed
func _notification(what: int) -> void:
 if what==MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT or what==MainLoop.NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(connection):connection.suspended=true;connection.send({"op":"move","intent":[0,0]});connection.send({"op":"cancel_channel"})
 elif what==MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN or what==MainLoop.NOTIFICATION_APPLICATION_RESUMED:
  if is_instance_valid(connection):connection.suspended=false
