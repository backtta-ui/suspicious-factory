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
var actions: WooActionController
var jump_button: Button
var hp_bar: ProgressBar
var combo_label: Label
var loot_left:=0.0
var loot_icon: WooItemArt
var loot_label: Label
var attack_cd:=0.0
var talisman_cd:=0.0
var dodge_cd:=0.0
var player_hurt_cd:=0.0
var hit_stop:=0.0
var shake_left:=0.0
var shake_power:=1.0
var mission_done:=false
var completion_opened:=false
var reward_message:=""
var selected_slot:=0
var transition_layer: Control
func _ready() -> void:
 actions=preload("res://scripts/woo/action_controller.gd").new();actions.adventure=self;add_child(actions)
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
 game.close_modal()
 var stack: VBoxContainer=game.open_modal("inventory")
 if stack==null:return
 stack.get_parent().get_parent().hide()
 var bundle:=preload("res://scripts/woo/bundle_ui.gd").new();bundle.adventure=self;game.modal.add_child(bundle)
func show_item(id: String) -> void:
 show_inventory()
 var bundle:=game.modal.get_child(game.modal.get_child_count()-1) as WooBundleUI
 bundle.selected=id;bundle.rebuild()
func show_character() -> void:
 var stack:=page("character","전우치 · Lv.%d" % game.rpg.data.level)
 stack.add_child(game.text("%s\n경험치 %d / %d\n체력 %d / %d     도력 %d / %d\n배운 도술: 둔갑술 · 부적술" % [game.rpg.rank(),game.rpg.data.xp,game.rpg.xp_needed(),game.rpg.data.hp,game.rpg.max_hp(),game.rpg.data.mp,game.rpg.max_mp()],23))
 var portrait:=preload("res://scripts/woo/item_art.gd").new();portrait.item_id="seal";portrait.animated=true;portrait.custom_minimum_size=Vector2(90,70);stack.add_child(portrait)
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
 hp_bar=ProgressBar.new();hp_bar.position=Vector2(30,235);hp_bar.size=Vector2(242,12);hp_bar.show_percentage=false;hp_bar.add_theme_stylebox_override("fill",game.style(Color("be5467"),3));hp_bar.add_theme_stylebox_override("background",game.style(Color("241b2a"),3));hp_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.ui.add_child(hp_bar)
 combo_label=game.text("",25,game.GOLD);combo_label.position=Vector2(330,105);game.ui.add_child(combo_label)
 loot_icon=preload("res://scripts/woo/item_art.gd").new();loot_icon.position=Vector2(305,154);loot_icon.size=Vector2(48,48);loot_icon.hide();game.ui.add_child(loot_icon)
 loot_label=game.text("",17,game.GOLD);loot_label.position=Vector2(360,168);game.ui.add_child(loot_label)
 jump_button=game.button("점프",jump);jump_button.name="JumpButton";jump_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);jump_button.offset_left=-415;jump_button.offset_right=-303;jump_button.offset_top=-144;jump_button.offset_bottom=-44;game.ui.add_child(jump_button)
 stats_label=game.text("",15,game.GOLD);stats_label.position=Vector2(30,205);game.ui.add_child(stats_label)
 for spec in [["AttackButton","공격",Vector2(-174,-160),Vector2(138,126),basic_attack],["DodgeButton","회피",Vector2(-292,-144),Vector2(100,100),dodge],["Skill1","",Vector2(-350,-270),Vector2(100,90),cast_slot.bind(0)],["Skill2","",Vector2(-238,-282),Vector2(100,90),cast_slot.bind(1)],["Skill3","",Vector2(-126,-270),Vector2(100,90),cast_slot.bind(2)]]:
  var b: Button=game.button(spec[1],spec[4],true);b.name=spec[0];b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);b.position=spec[2];b.size=spec[3];b.add_theme_font_size_override("font_size",17);game.ui.add_child(b);combat_buttons.append(b)
  for connection in b.pressed.get_connections():b.pressed.disconnect(connection.callable)
  b.pressed.connect(spec[4])
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
 if is_instance_valid(hp_bar):hp_bar.max_value=game.rpg.max_hp();hp_bar.value=game.rpg.data.hp
 if is_instance_valid(combo_label) and actions!=null:combo_label.text=("%d HIT%s" % [actions.hits," COMBO!" if actions.hits>=4 else ""]) if actions.hits>1 else ""
 if is_instance_valid(jump_button):jump_button.disabled=game.paused or transitioning or game.player.defeated
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
 game.player.reset_action()
 if not game.player.landed.is_connected(actions.landing):game.player.landed.connect(actions.landing)
 actions.cancel()
 game.player.reparent(forest);game.player.collision_mask=1|4;game.player.combat_frozen=false
 var p: Array=game.rpg.data.session.position;game.player.position=ForestLayout.safe(Vector2(p[0],p[1]));game.player.facing=int(game.rpg.data.session.facing)
 if game.rpg.data.hp<=0:game.rpg.data.hp=game.rpg.max_hp()
 game.player.velocity=Vector2.ZERO;game.player.intent=Vector2.ZERO;game.player.reset_physics_interpolation()
 game.world.hide();game.world.process_mode=Node.PROCESS_MODE_DISABLED;game.world.set_process(false)
 for i in range(1,game.actors.size()):game.actors[i].enabled=false
 game.camera.limit_right=int(ForestLayout.SIZE.x);game.camera.limit_bottom=int(ForestLayout.SIZE.y);game.camera.reset_smoothing()
 combat=preload("res://scripts/woo/combat_effects.gd").new();forest.add_child(combat)
 for loot in ForestLayout.LOOT:
  var marker:=preload("res://scripts/woo/forest_loot.gd").new();marker.adventure=self;marker.loot=loot;marker.position=loot.position;forest.add_child(marker)
 for i in range(3):
  if defeated().has(i):continue
  var enemy:=preload("res://scripts/woo/goblin.gd").new();enemy.enemy_id=i;enemy.hp=[60,120,100][i];enemy.position=ForestLayout.GOBLINS[i];enemy.adventure=self;forest.add_child(enemy)
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
 game.world.process_mode=Node.PROCESS_MODE_INHERIT;game.world.show();game.world.set_process(true);game.world.set_completed_stories(game.completed_paintings)
 game.player.reset_action();actions.cancel()
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
 var zone: Dictionary=ForestLayout.zone_at(game.player.position)
 game.place_label.text=zone.name
 if not game.rpg.data.visited.has(zone.id):game.rpg.data.visited.append(zone.id)
 game.quest_label.get_parent().get_child(0).text="여우의 숲"
 game.quest_label.text="도깨비를 물리치세요 (%d/3)" % defeated().size()
 var loot:=nearby_loot()
 game.interact_button.visible=not loot.is_empty() or game.player.position.distance_to(ForestLayout.EXIT)<95
 game.interact_button.text="조사 · 획득" if not loot.is_empty() else "광장 복귀"
 if loot_left>0:
  loot_left=maxf(0,loot_left-delta)
  if loot_left==0:loot_label.text="";loot_icon.hide()
 game.hint.text="항아리 상태에서는 공격할 수 없습니다" if game.player.jar else ("임무 완료 · 광장으로 돌아가세요" if mission_done else "도깨비를 찾아 도술로 물리치세요")
 for i in range(combat_buttons.size()):
  var b:=combat_buttons[i]
  b.disabled=game.paused or transitioning or game.rpg.data.hp<=0
  if i==0:b.text="공격 · %d타" % actions.stage if actions.active else "공격";b.disabled=b.disabled or game.player.jar
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
  var strength: float=HitConfig.SHAKE_PIXELS*shake_power*shake_left/HitConfig.SHAKE_TIME/game.camera.zoom.x
  game.camera.offset=Vector2(sin(shake_left*149),cos(shake_left*173)).limit_length(1.0)*strength
 else:game.camera.offset=Vector2.ZERO
 if game.paused:return
 attack_cd=maxf(0,attack_cd-delta);talisman_cd=maxf(0,talisman_cd-delta);dodge_cd=maxf(0,dodge_cd-delta);player_hurt_cd=maxf(0,player_hurt_cd-delta)
 hit_stop=maxf(0,hit_stop-delta)
 actions.tick(delta)
 game.player.combat_frozen=hit_stop>0
func can_fight() -> bool:return in_mission and not transitioning and not game.paused and game.rpg.data.hp>0 and not mission_done and game.player.transforming<=0 and game.player.hurt_stun<=0 and not game.player.defeated
func basic_attack() -> void:
 actions.request()
func jump() -> void:
 if game.screen_name!="playing" or game.paused or transitioning:return
 game.player.jump()
func cast_slot(slot: int) -> void:
 if slot<0 or slot>=3:return
 var id: String=game.rpg.data.slots[slot]
 if id=="jar":
  if actions.active:return
  game.cast_spell();return
 if id=="talisman":actions.request("talisman")
func launch(talisman: bool) -> void:
 var shot:=preload("res://scripts/woo/projectile.gd").new();shot.adventure=self;shot.talisman=talisman;shot.direction=Vector2.from_angle(game.player.facing*PI/4);shot.position=game.player.position+shot.direction*14;forest.add_child(shot)
func dodge() -> void:
 if not can_fight() or dodge_cd>0:return
 actions.cancel()
 dodge_cd=1.6
 var direction: Vector2=game.player.direction()
 if direction.length()<.1:direction=Vector2.from_angle(game.player.facing*PI/4)
 game.player.dash_direction=direction.normalized();game.player.dash_left=.18
 if game.rpg.data.effects.particles:combat.afterimage(game.player)
func enemy_hit(enemy: Node,amount: int,direction: Vector2,talisman: bool) -> void:
 if not can_fight() or enemy.hp<=0:return
 enemy.receive_damage(amount,direction,talisman)
 if game.rpg.data.effects.hit_stop:hit_stop=HitConfig.STOP_TIME
 if game.rpg.data.effects.shake:shake_left=HitConfig.SHAKE_TIME;shake_power=1.0 if amount>=30 else .45
 if game.rpg.data.effects.particles:combat.burst(enemy.position,amount,talisman,false)
 game.sound.play_clip("hit")
func enemy_died(enemy_id: int,p: Vector2) -> void:
 if defeated().has(enemy_id):return
 game.rpg.data.session.defeated.append(enemy_id)
 if game.rpg.data.effects.particles:combat.burst(p,0,true,true)
 if defeated().size()==3:mission_done=true;game.rpg.data.session.completed=true
 game.save_progress()
func can_take_damage() -> bool:
 return in_mission and not transitioning and not game.paused and game.rpg.data.hp>0 and not mission_done
func hurt_player(amount: int,direction: Vector2=Vector2.ZERO) -> void:
 if not can_take_damage() or player_hurt_cd>0:return
 player_hurt_cd=WooActionConfig.INVULNERABILITY;game.player.hurt_left=.22;game.player.hurt_stun=WooActionConfig.HURT_STUN;game.player.hurt_knock=direction*85;actions.cancel();game.rpg.data.hp=maxi(0,int(game.rpg.data.hp)-amount)
 if game.rpg.data.effects.particles:combat.burst(game.player.position,amount,false,false)
 game.sound.play_clip("hit")
 game.save_progress()
 update_stats()
 if game.rpg.data.hp<=0:
  game.player.defeated=true;game.player.velocity=Vector2.ZERO;game.player.update_sprite()
  game.set_paused(true)
  var stack: VBoxContainer=game.open_modal("defeat")
  if stack:
   stack.add_child(game.button("임무 재시작",retry_mission,true))
   stack.add_child(game.text("도술의 기운이 다했습니다",27,game.GOLD));stack.add_child(game.text("광장에서 회복합니다. 미완료 임무는 다시 시작합니다.",19));stack.add_child(game.button("광장으로",func()->void:game.rpg.data.hp=game.rpg.max_hp();game.rpg.data.mp=game.rpg.max_mp();return_to_plaza(),true))
  game.save_progress()
func retry_mission() -> void:
 if transitioning:return
 game.close_modal();game.set_paused(true)
 game.player.reparent(game.world)
 var old:=forest
 game.rpg.data.hp=game.rpg.max_hp();game.rpg.data.mp=game.rpg.max_mp()
 in_mission=false
 old.queue_free()
 load_forest(false);game.set_paused(false);game.save_progress()
func nearby_loot() -> Dictionary:
 if not in_mission:return {}
 for loot in ForestLayout.LOOT:
  if not game.rpg.data.loot_claims.has(loot.id) and game.player.position.distance_to(loot.position)<75:return loot
 return {}
func acquire_loot(loot: Dictionary) -> bool:
 if game.rpg.data.loot_claims.has(loot.id):return false
 var before: Dictionary=game.rpg.data.duplicate(true)
 var first: bool=not game.rpg.data.discoveries.has(loot.item)
 if not game.rpg.add_item(loot.item,loot.amount):return false
 game.rpg.data.loot_claims.append(loot.id);game.save_progress()
 if game.last_save_error!=OK:game.rpg.data=before;return false
 loot_left=3.0;loot_label.text=("새로운 발견! " if first else "획득 · ")+State.ITEMS[loot.item].name+" ×%d" % loot.amount
 loot_icon.item_id=loot.item;loot_icon.show();loot_icon.queue_redraw();game.sound.play_clip("reward")
 if game.rpg.data.effects.particles:combat.burst(game.player.position,0,true,true)
 return true
func mission_interact() -> void:
 var loot:=nearby_loot()
 if not loot.is_empty():acquire_loot(loot);return
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
