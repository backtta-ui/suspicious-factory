class_name WooAdventure
extends Node
const State=preload("res://scripts/woo/rpg_state.gd")
const ForestLayout=preload("res://scripts/woo/forest_layout.gd")
const HitConfig=preload("res://scripts/woo/hit_config.gd")
var game: Node
var in_mission:=false
var transitioning:=false
var forest: Node2D
var combat: Node2D
var combat_buttons: Array[Button]=[]
var stats_label: Label
var attack_cd:=0.0
var talisman_cd:=0.0
var dodge_cd:=0.0
var player_hurt_cd:=0.0
var hit_stop:=0.0
var shake_left:=0.0
var mission_done:=false
var completion_opened:=false
var reward_message:=""
var selected_slot:=0
var transition_layer: Control
func dispose() -> void:
 if is_instance_valid(transition_layer):transition_layer.queue_free()
 if is_instance_valid(forest):forest.queue_free()
 if is_instance_valid(game.camera):game.camera.offset=Vector2.ZERO
func show_menu() -> void:
 var stack: VBoxContainer=game.open_modal("rpg")
 if stack==null:return
 stack.add_child(game.text("도사의 여정",29,game.GOLD))
 var grid:=GridContainer.new();grid.columns=3;stack.add_child(grid)
 for entry in [["가방",show_inventory],["캐릭터",show_character],["도술",show_spells],["임무 일지",show_journal],["지도",show_map],["의상",show_outfits]]:
  var b: Button=game.button(entry[0],entry[1]);b.custom_minimum_size=Vector2(220,70);grid.add_child(b)
 stack.add_child(game.button("설정",func()->void:game.close_modal();game.show_settings()))
 stack.add_child(game.button("저장하고 메인으로",func()->void:game.close_modal();game.show_menu()))
 stack.add_child(game.button("돌아가기",game.close_modal,true))
func page(kind: String,title: String) -> VBoxContainer:
 game.close_modal()
 var stack: VBoxContainer=game.open_modal(kind)
 if stack:stack.add_child(game.text(title,28,game.GOLD))
 return stack
func footer(stack: VBoxContainer) -> void:
 stack.add_child(game.button("메뉴로",func()->void:game.close_modal();show_menu()))
 stack.add_child(game.button("게임으로",game.close_modal,true))
func show_inventory() -> void:
 var stack:=page("inventory","가방  %d / 30칸  ·  엽전 %d" % [game.rpg.data.inventory.size(),game.rpg.data.coins])
 if stack==null:return
 var grid:=GridContainer.new();grid.columns=5;stack.add_child(grid)
 for id in State.ITEMS:
  if game.rpg.count(id)<=0:continue
  var item: Dictionary=State.ITEMS[id]
  var b: Button=game.button("%s\n%s ×%d" % [item.icon,item.name,game.rpg.count(id)],show_item.bind(id))
  b.custom_minimum_size=Vector2(140,108);b.add_theme_font_size_override("font_size",17);grid.add_child(b)
 stack.add_child(game.text("같은 아이템은 중첩 보관됩니다. 아이템을 눌러 확인하세요.",17))
 footer(stack)
func show_item(id: String) -> void:
 if not State.ITEMS.has(id):return
 var item: Dictionary=State.ITEMS[id]
 var stack:=page("item",item.name)
 stack.add_child(game.text("%s · 보유 %d개" % [item.kind,game.rpg.count(id)],20))
 stack.add_child(game.text(item.description,21))
 var usable: bool=item.has("hp") or item.has("mp")
 var use: Button=game.button("사용" if usable else "사용 불가 · 보관용",func()->void:
  var before: Dictionary=game.rpg.data.duplicate(true)
  if game.rpg.use_item(id):
   game.save_progress()
   if game.last_save_error!=OK:game.rpg.data=before
  show_item(id),true)
 use.disabled=not usable or game.rpg.count(id)<=0 or (item.has("hp") and game.rpg.data.hp>=game.rpg.max_hp()) or (item.has("mp") and game.rpg.data.mp>=game.rpg.max_mp())
 stack.add_child(use)
 stack.add_child(game.button("가방으로",show_inventory))
func show_character() -> void:
 var stack:=page("character","전우치 · Lv.%d" % game.rpg.data.level)
 stack.add_child(game.text("%s\n경험치 %d / %d\n체력 %d / %d     도력 %d / %d\n배운 도술: 둔갑술 · 부적술" % [game.rpg.rank(),game.rpg.data.xp,game.rpg.xp_needed(),game.rpg.data.hp,game.rpg.max_hp(),game.rpg.data.mp,game.rpg.max_mp()],23))
 stack.add_child(game.text("등급 승급은 추후 수련 조건에 연결됩니다.",17))
 footer(stack)
func show_spells() -> void:
 var stack:=page("spells","도술 도감 · 최대 3슬롯")
 var slots:=HBoxContainer.new();stack.add_child(slots)
 for i in range(3):
  var id: String=game.rpg.data.slots[i]
  slots.add_child(game.button("슬롯 %d%s\n%s" % [i+1," ✓" if i==selected_slot else "",State.SPELLS[id].name if id!="" else "비어 있음"],func()->void:selected_slot=i;show_spells()))
 for id in State.SPELLS:
  var spell: Dictionary=State.SPELLS[id]
  var b: Button=game.button("%s · %s" % [spell.name,spell.description],func()->void:game.rpg.equip(selected_slot,id);game.save_progress();show_spells())
  b.disabled=not spell.available;b.add_theme_font_size_override("font_size",17);stack.add_child(b)
 footer(stack)
func show_journal() -> void:
 var stack:=page("journal","임무 일지")
 stack.add_child(game.text("첫걸음 · 마을 어른과 대화하기 (%d/1)" % int(game.talked_to_elder),22))
 stack.add_child(game.text("여우의 숲 · 도깨비 퇴치 (%d/3)" % defeated().size(),22))
 stack.add_child(game.text("그림 완료: "+("여우의 숲" if game.rpg.data.completed.has("fox_forest") else "없음"),21))
 stack.add_child(game.text("첫 완료 보상: 경험치 120 · 엽전 50 · 회복약 2 · 신비한 잎 3\n수령 상태: "+("수령 완료" if game.rpg.data.claims.has("fox_forest") else "미수령"),18))
 stack.add_child(game.text("탐관오리의 관아 · 도깨비의 밤: 준비 중",17))
 footer(stack)
func show_map() -> void:
 var stack:=page("map", "여우의 숲" if in_mission else "계월촌 전체 지도")
 var map:=preload("res://scripts/woo/minimap.gd").new()
 map.custom_minimum_size=Vector2(640,310);map.mission=in_mission;map.local_position=game.player.position;map.elder_done=game.talked_to_elder;stack.add_child(map)
 stack.add_child(game.text("파랑: 내 위치 · 노랑: 임무 / 출구 · 보라: 그림 장터",17))
 footer(stack)
func show_outfits() -> void:
 var stack:=page("outfits","의상")
 stack.add_child(game.text("검은 갓과 도포 · 현재 착용 중\n현재 보유한 다른 의상이 없습니다.",23))
 footer(stack)
func build_controls() -> void:
 combat_buttons.clear()
 stats_label=game.text("",15,game.GOLD);stats_label.position=Vector2(30,205);game.ui.add_child(stats_label)
 for spec in [["AttackButton","공격",Vector2(-174,-160),Vector2(138,126),basic_attack],["DodgeButton","회피",Vector2(-292,-144),Vector2(100,100),dodge],["Skill1","",Vector2(-350,-270),Vector2(100,90),cast_slot.bind(0)],["Skill2","",Vector2(-238,-282),Vector2(100,90),cast_slot.bind(1)],["Skill3","",Vector2(-126,-270),Vector2(100,90),cast_slot.bind(2)]]:
  var b: Button=game.button(spec[1],spec[4],true);b.name=spec[0];b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);b.position=spec[2];b.size=spec[3];b.add_theme_font_size_override("font_size",17);game.ui.add_child(b);combat_buttons.append(b)
 update_controls()
 # Mini-map remains visible; an independent touch button overlays its exact area.
 var expand: Button=game.button("",show_map)
 expand.name="MapExpand";expand.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);expand.offset_left=-150;expand.offset_right=-18;expand.offset_top=10;expand.offset_bottom=142
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:expand.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
 for child in expand.get_children():child.hide()
 game.ui.add_child(expand)
func update_controls() -> void:
 for b in combat_buttons:b.visible=in_mission
 game.spell_button.visible=not in_mission
 if in_mission:
  game.run_button.visible=false
  game.interact_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);game.interact_button.offset_left=-138;game.interact_button.offset_right=-38;game.interact_button.offset_top=-388;game.interact_button.offset_bottom=-292
  game.hud_map.mission=true;game.hud_map.queue_redraw()
 else:game.run_button.visible=true;game.hud_map.mission=false
func update_stats() -> void:
 if is_instance_valid(stats_label):stats_label.text="Lv.%d   HP %d/%d   도력 %d/%d" % [game.rpg.data.level,game.rpg.data.hp,game.rpg.max_hp(),game.rpg.data.mp,game.rpg.max_mp()]
func show_painting(index: int) -> void:
 if transitioning or in_mission:return
 var p: Dictionary=game.Layout.PAINTINGS[index]
 var stack: VBoxContainer=game.open_modal("painting")
 if stack==null:return
 game.return_anchor={"map":game.Layout.MAP_ID,"position":[game.player.position.x,game.player.position.y],"facing":game.player.facing,"painting_id":p.id}
 stack.add_child(game.text(p.name,28,game.GOLD))
 var art:=preload("res://scripts/woo/painting_view.gd").new();art.index=index;art.reduced=game.settings.low_effects;art.custom_minimum_size=Vector2(730,290);stack.add_child(art)
 var intro: Label=game.text(p.intro,17);intro.custom_minimum_size.x=730;intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(intro)
 stack.add_child(game.text("도깨비 3마리 처치 · 첫 보상: 경험치 120 / 엽전 50 / 회복약 2 / 잎 3" if index==0 else "봉인된 그림 · 그림 속 임무는 준비 중입니다",16))
 var enter: Button=game.button("그림 속으로" if index==0 else "준비 중",enter_painting,true);enter.disabled=index!=0;stack.add_child(enter)
 stack.add_child(game.button("돌아가기",game.close_modal))
 game.save_progress()
func defeated() -> Array:return game.rpg.data.session.get("defeated",[]) if not game.rpg.data.session.is_empty() else ([0,1,2] if game.rpg.data.completed.has("fox_forest") else [])
func capture_session() -> void:
 if not in_mission or not is_instance_valid(game.player):return
 game.rpg.data.session.position=[game.player.position.x,game.player.position.y];game.rpg.data.session.facing=game.player.facing
func resume_session() -> void:
 if game.return_anchor.is_empty():game.rpg.data.session={};return
 if not load_forest(true):game.rpg.data.session={};game.restore_plaza_anchor()
func enter_painting() -> void:
 if transitioning or in_mission:return
 transitioning=true
 await transition(false)
 if not is_inside_tree():return
 if not load_forest(false):
  game.rpg.data.session={};game.restore_plaza_anchor();game.hint.text="그림을 열지 못했습니다. 광장으로 돌아왔습니다."
 await finish_transition()
 game.save_progress()
func transition(reverse: bool) -> void:
 game.close_modal();game.set_paused(true)
 transition_layer=preload("res://scripts/woo/portal_transition.gd").new();transition_layer.reverse=reverse;transition_layer.reduced=game.settings.low_effects;transition_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);game.layer.add_child(transition_layer)
 await get_tree().create_timer(1.65).timeout
func finish_transition() -> void:
 if is_instance_valid(transition_layer):transition_layer.finishing=true
 await get_tree().create_timer(.7).timeout
 if is_instance_valid(transition_layer):transition_layer.queue_free()
 transitioning=false;game.set_paused(false)
 if in_mission and mission_done:show_completion.call_deferred()
func load_forest(resume: bool) -> bool:
 if not is_instance_valid(game.player) or game.return_anchor.is_empty():return false
 if not resume:game.rpg.data.session={"map":"fox_forest","position":[ForestLayout.SPAWN.x,ForestLayout.SPAWN.y],"facing":0,"defeated":[],"completed":false}
 forest=preload("res://scripts/woo/forest.gd").new();game.add_child(forest)
 in_mission=true;mission_done=game.rpg.data.session.completed;completion_opened=false
 game.player.reparent(forest);game.player.collision_mask=1|4;game.player.combat_frozen=false
 var p: Array=game.rpg.data.session.position;game.player.position=ForestLayout.safe(Vector2(p[0],p[1]));game.player.facing=int(game.rpg.data.session.facing)
 if game.rpg.data.hp<=0:game.rpg.data.hp=game.rpg.max_hp()
 game.player.velocity=Vector2.ZERO;game.player.intent=Vector2.ZERO;game.player.reset_physics_interpolation()
 game.world.hide();game.world.set_process(false)
 for i in range(1,game.actors.size()):game.actors[i].enabled=false
 game.camera.limit_right=int(ForestLayout.SIZE.x);game.camera.limit_bottom=int(ForestLayout.SIZE.y);game.camera.reset_smoothing()
 combat=preload("res://scripts/woo/combat_effects.gd").new();forest.add_child(combat)
 for i in range(3):
  if defeated().has(i):continue
  var enemy:=preload("res://scripts/woo/goblin.gd").new();enemy.enemy_id=i;enemy.position=ForestLayout.GOBLINS[i];enemy.adventure=self;forest.add_child(enemy)
 game.nearest_npc=-1;game.nearest_painting=-1;game.near_well=false
 game.sound.map_id="fox_forest";game.sound.tracking=false
 attack_cd=0;talisman_cd=0;dodge_cd=0;player_hurt_cd=0
 update_controls()
 return true
func return_to_plaza() -> void:
 if transitioning or not in_mission:return
 transitioning=true
 await transition(true)
 game.player.reparent(game.world);game.player.collision_mask=1
 game.world.show();game.world.set_process(true);game.world.set_completed_stories(game.completed_paintings)
 game.player.combat_frozen=false;game.player.dash_left=0
 in_mission=false;game.rpg.data.session={};mission_done=false;completion_opened=false
 if is_instance_valid(forest):forest.queue_free()
 forest=null;combat=null
 game.camera.offset=Vector2.ZERO;game.camera.limit_right=int(game.Layout.SIZE.x);game.camera.limit_bottom=int(game.Layout.SIZE.y)
 game.restore_plaza_anchor();game.player.facing=int(game.return_anchor.get("facing",2));game.player.intent=Vector2.ZERO;game.player.running=false
 game.sound.map_id=game.Layout.MAP_ID;game.sound.tracking=false
 game.build_hud()
 await finish_transition()
 game.save_progress()
func show_effects() -> void:
 var stack:=page("effects","전투 효과 설정")
 for pair in [["hit_stop","히트 스톱"],["flash","피격 강조"],["shake","화면 흔들림"],["particles","파편 · 데미지 숫자"]]:
  var b: Button=game.button(pair[1]+("  켜짐" if game.rpg.data.effects[pair[0]] else "  꺼짐"),func()->void:game.rpg.data.effects[pair[0]]=not game.rpg.data.effects[pair[0]];game.save_progress();show_effects())
  stack.add_child(b)
 stack.add_child(game.button("설정으로",func()->void:game.close_modal();game.show_settings()))
 stack.add_child(game.button("게임으로",game.close_modal,true))
func update_mission_ui(delta: float) -> void:
 update_stats()
 game.hud_map.update_local(game.player.position,true)
 game.place_label.text="그림 속 세계 · 여우의 숲"
 game.quest_label.get_parent().get_child(0).text="여우의 숲"
 game.quest_label.text="도깨비를 물리치세요 (%d/3)" % defeated().size()
 game.interact_button.visible=game.player.position.distance_to(ForestLayout.EXIT)<95
 game.interact_button.text="광장 복귀"
 game.hint.text="항아리 상태에서는 공격할 수 없습니다" if game.player.jar else ("임무 완료 · 광장으로 돌아가세요" if mission_done else "도깨비를 찾아 도술로 물리치세요")
 for i in range(combat_buttons.size()):
  var b:=combat_buttons[i]
  b.disabled=game.paused or transitioning or game.rpg.data.hp<=0
  if i==0:b.text="공격" if attack_cd<=0 else "공격 %.1f" % attack_cd;b.disabled=b.disabled or attack_cd>0 or game.player.jar
  elif i==1:b.text="회피" if dodge_cd<=0 else "회피 %.1f" % dodge_cd;b.disabled=b.disabled or dodge_cd>0
  else:
   var id: String=game.rpg.data.slots[i-2]
   b.text="슬롯 %d\n%s" % [i-1,State.SPELLS[id].name if id!="" else "비어 있음"]
   b.disabled=b.disabled or id=="" or (id=="talisman" and (talisman_cd>0 or game.player.jar or game.rpg.data.mp<12)) or (id=="jar" and (game.player.cooldown>0 or game.player.transforming>0))
 if not game.paused and mission_done and not completion_opened and not transitioning:show_completion.call_deferred()
func _physics_process(delta: float) -> void:
 if not in_mission:return
 if shake_left>0:
  shake_left=maxf(0,shake_left-delta)
  var strength: float=HitConfig.SHAKE_PIXELS*shake_left/HitConfig.SHAKE_TIME/game.camera.zoom.x
  game.camera.offset=Vector2(sin(shake_left*149),cos(shake_left*173)).limit_length(1.0)*strength
 else:game.camera.offset=Vector2.ZERO
 if game.paused:return
 attack_cd=maxf(0,attack_cd-delta);talisman_cd=maxf(0,talisman_cd-delta);dodge_cd=maxf(0,dodge_cd-delta);player_hurt_cd=maxf(0,player_hurt_cd-delta)
 hit_stop=maxf(0,hit_stop-delta)
 game.player.combat_frozen=hit_stop>0
func can_fight() -> bool:return in_mission and not transitioning and not game.paused and game.rpg.data.hp>0 and not mission_done and game.player.transforming<=0
func basic_attack() -> void:
 if not can_fight() or game.player.jar or attack_cd>0:return
 attack_cd=.32;launch(false);game.sound.play_clip("attack")
func cast_slot(slot: int) -> void:
 if slot<0 or slot>=3:return
 var id: String=game.rpg.data.slots[slot]
 if id=="jar":game.cast_spell();return
 if id!="talisman" or not can_fight() or game.player.jar or talisman_cd>0 or game.rpg.data.mp<12:return
 game.rpg.data.mp-=12;talisman_cd=2.2;launch(true);game.sound.play_clip("spell")
func launch(talisman: bool) -> void:
 var shot:=preload("res://scripts/woo/projectile.gd").new();shot.adventure=self;shot.talisman=talisman;shot.direction=Vector2.from_angle(game.player.facing*PI/4);shot.position=game.player.position+shot.direction*14;forest.add_child(shot)
func dodge() -> void:
 if not can_fight() or dodge_cd>0:return
 dodge_cd=1.6
 var direction: Vector2=game.player.direction()
 if direction.length()<.1:direction=Vector2.from_angle(game.player.facing*PI/4)
 game.player.dash_direction=direction.normalized();game.player.dash_left=.18
 if game.rpg.data.effects.particles:combat.afterimage(game.player)
func enemy_hit(enemy: Node,amount: int,direction: Vector2,talisman: bool) -> void:
 if not can_fight() or enemy.hp<=0:return
 enemy.receive_damage(amount,direction,talisman)
 if game.rpg.data.effects.hit_stop:hit_stop=HitConfig.STOP_TIME
 if game.rpg.data.effects.shake:shake_left=HitConfig.SHAKE_TIME
 if game.rpg.data.effects.particles:combat.burst(enemy.position,amount,talisman,false)
 game.sound.play_clip("hit")
func enemy_died(enemy_id: int,p: Vector2) -> void:
 if defeated().has(enemy_id):return
 game.rpg.data.session.defeated.append(enemy_id)
 if game.rpg.data.effects.particles:combat.burst(p,0,true,true)
 if defeated().size()==3:mission_done=true;game.rpg.data.session.completed=true
 game.save_progress()
func hurt_player(amount: int) -> void:
 if not can_fight() or player_hurt_cd>0:return
 player_hurt_cd=.8;game.rpg.data.hp=maxi(0,int(game.rpg.data.hp)-amount);combat.burst(game.player.position,amount,false,false)
 game.sound.play_clip("hit")
 if game.rpg.data.hp<=0:
  game.set_paused(true)
  var stack: VBoxContainer=game.open_modal("defeat")
  if stack:
   stack.add_child(game.text("도술의 기운이 다했습니다",27,game.GOLD));stack.add_child(game.text("획득한 처치 기록은 보존됩니다. 광장에서 회복합니다.",19));stack.add_child(game.button("광장으로",func()->void:game.rpg.data.hp=game.rpg.max_hp();game.rpg.data.mp=game.rpg.max_mp();return_to_plaza(),true))
  game.save_progress()
func mission_interact() -> void:
 if game.player.position.distance_to(ForestLayout.EXIT)>=95:return
 var stack: VBoxContainer=game.open_modal("exit")
 if stack:
  stack.add_child(game.text("광장으로 돌아갈까요?",27,game.GOLD));stack.add_child(game.text("완료하지 않은 임무는 다음 입장 시 다시 시작합니다.",18));stack.add_child(game.button("광장으로",return_to_plaza,true));stack.add_child(game.button("계속 탐험",game.close_modal))
func show_completion() -> void:
 if not in_mission or not mission_done or completion_opened or transitioning or is_instance_valid(game.modal):return
 completion_opened=true
 var before: Dictionary=game.rpg.data.duplicate(true)
 var before_completed: Array=game.completed_paintings.duplicate()
 var granted: bool=game.rpg.claim_fox_reward()
 if not game.completed_paintings.has("fox_forest"):game.completed_paintings.append("fox_forest")
 game.save_progress()
 if game.last_save_error!=OK:
  game.rpg.data=before;game.completed_paintings=before_completed;completion_opened=false
  reward_message="저장 공간을 확인해 주세요. 보상 저장을 다시 시도합니다.";return
 if granted:game.sound.play_clip("reward")
 var stack: VBoxContainer=game.open_modal("complete")
 if stack:
  stack.add_child(game.text("여우의 숲 · 임무 완료",30,game.GOLD))
  stack.add_child(game.text("경험치 +120 · 엽전 +50\n회복약 ×2 · 신비한 잎 ×3" if granted else "첫 완료 보상은 이미 수령했습니다.\n광장의 벚꽃나무에 금빛이 피어납니다.",23))
  stack.add_child(game.button("광장으로 돌아가기",return_to_plaza,true))
