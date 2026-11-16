class_name WooPracticeUI
extends Node
const Catalog=preload("res://scripts/practice/catalog.gd")
const Layout=preload("res://scripts/practice/layout.gd")
const Actor=preload("res://scripts/woo/actor.gd")
var game: Node
var session: WooPracticeSession
var world: WooPracticeWorld
var hero: WooActor
var camera: Camera2D
var stick: TouchJoystick
var avatars: Dictionary={}
var clones: Dictionary={}
var environment: Dictionary={}
var labels: Dictionary={}
var markers: Dictionary={}
var header: Label
var notice: Label
var cast_button: Button
var interact_button: Button
var badge: WooSkillBadge
var combat: WooCombatEffects
var source_scene: Node2D
var original_mode: int
var original_adventure_mode: int
var original_camera_enabled: bool
var original_sound_map: String
var backgrounded:=false
var leaving:=false
func _ready() -> void:
 session=preload("res://scripts/practice/session.gd").new(game.player.cosmetic)
 source_scene=game.player.get_parent();original_mode=source_scene.process_mode;original_adventure_mode=game.adventure.process_mode;original_camera_enabled=game.camera.enabled;original_sound_map=game.sound.map_id
 game.close_modal();game.finish_save();game.save_progress()
 source_scene.hide();source_scene.process_mode=Node.PROCESS_MODE_DISABLED;game.adventure.process_mode=Node.PROCESS_MODE_DISABLED;game.camera.enabled=false
 game.screen_name="practice";game.active_context="practice";game.paused=false;game.sound.map_id="offline_practice"
 world=preload("res://scripts/practice/world.gd").new();add_child(world)
 for id in ["student"]+session.NPCS.keys():
  var actor:=Actor.new();actor.network_remote=true;actor.collision_layer=0;actor.collision_mask=0;world.add_child(actor);actor.set_physics_process(false);avatars[id]=actor
  var marker:=preload("res://scripts/seal/color_marker.gd").new();marker.actor=actor;marker.color_id=session.rules.players[id].color;actor.add_child(marker);markers[id]=marker
  var label: Label=game.text("",10,game.GOLD);label.position=Vector2(-70,-65);label.size.x=140;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_constant_override("outline_size",3);label.add_theme_color_override("font_outline_color",Color("18202b"));actor.add_child(label);labels[id]=label
 hero=avatars.student
 camera=Camera2D.new();camera.zoom=game.camera.zoom;camera.position=Vector2(0,-36);camera.position_smoothing_enabled=game.settings.smooth_camera;camera.position_smoothing_speed=5;camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(Layout.SIZE.x);camera.limit_bottom=int(Layout.SIZE.y);hero.add_child(camera);camera.make_current()
 for asset in session.rules.arena.assets:
  var item:=preload("res://scripts/seal/environment_asset.gd").new();item.kind=asset.kind;world.add_child(item);environment[asset.id]=item
 var fx:=preload("res://scripts/practice/fx.gd").new();fx.practice=self;world.add_child(fx)
 combat=preload("res://scripts/woo/combat_effects.gd").new();world.add_child(combat)
 build_ui();sync(0);camera.reset_smoothing()
func control(title: String,p: Vector2,s: Vector2,call: Callable) -> Button:
 var b: Button=game.button(title,call);b.custom_minimum_size=s;b.add_theme_font_size_override("font_size",18);game.ui.add_child(b)
 if p.x>=700:
  b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if p.y>=300 else Control.PRESET_TOP_RIGHT)
  b.offset_left=p.x-1280;b.offset_right=p.x-1280+s.x;b.offset_top=p.y-(720 if p.y>=300 else 0);b.offset_bottom=b.offset_top+s.y
 else:b.position=p
 return b
func build_ui() -> void:
 game.new_ui();game.active_context="practice"
 var panel:=Panel.new();panel.position=Vector2(16,8);panel.size=Vector2(920,137);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",game.style(Color(.055,.075,.12,.92),8));game.ui.add_child(panel)
 header=game.text("",23,game.GOLD);header.position=Vector2(26,18);game.ui.add_child(header)
 notice=game.text("",17);notice.position=Vector2(26,61);notice.custom_minimum_size=Vector2(760,65);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;game.ui.add_child(notice)
 var guide: Label=game.text("오프라인 자유 체험 · 습득/아이템/온라인 장착 기록과 별개",15,Color("9bbcc5"));guide.position=Vector2(26,118);game.ui.add_child(guide)
 control("이전 모험으로 돌아가기" if game.adventure.in_mission else "광장으로 돌아가기",Vector2(1010,18),Vector2(244,64),leave)
 control("NPC 행동 변경",Vector2(26,153),Vector2(258,60),cycle_npcs)
 stick=preload("res://scripts/joystick.gd").new();stick.size=Vector2(174,174);stick.position=Vector2(74,498);game.ui.add_child(stick)
 cast_button=control("도술 사용",Vector2(1090,546),Vector2(164,142),cast)
 badge=preload("res://scripts/woo/skill_badge.gd").new();badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cast_button.add_child(badge)
 interact_button=control("상호작용",Vector2(865,570),Vector2(203,104),interact)
 control("변신 해제",Vector2(1070,440),Vector2(184,84),release)
 control("도술 목록",Vector2(1070,334),Vector2(184,84),show_spells)
 control("초기화",Vector2(865,440),Vector2(184,84),reset)
 control("표적 공격",Vector2(708,570),Vector2(135,104),attack)
 adjust_safe.call_deferred()
func adjust_safe() -> void:
 var view:=game.get_viewport().get_visible_rect().size
 stick.position.y=view.y-222
 if OS.get_name()=="Android":
  var safe:=DisplayServer.get_display_safe_area();var size:=DisplayServer.screen_get_size()
  if size.x>0 and size.y>0:stick.position.x=74+float(safe.position.x)*view.x/size.x;stick.position.y-=maxf(0,float(size.y-safe.end.y))*view.y/size.y
func cycle_npcs() -> void:
 var modes: Array=["patrol","idle","chase","attack"];session.npc_mode=modes[(modes.find(session.npc_mode)+1)%4];session.message={"patrol":"NPC 산책","idle":"NPC 대기","chase":"NPC 추적 · 분신/연막을 시험하세요","attack":"훈련 요괴 공격 · 호신부로 방어해보세요"}[session.npc_mode]
func show_spells() -> void:
 if is_instance_valid(game.modal):return
 stick.reset()
 var stack: VBoxContainer=game.open_modal("practice_spells");stack.get_parent().custom_minimum_size=Vector2(1080,610);stack.add_child(game.text("도술 익히기 · 모든 도술 자유 체험",26,game.GOLD))
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1030,430);stack.add_child(scroll)
 var grid:=GridContainer.new();grid.columns=2;scroll.add_child(grid)
 for id in Catalog.all():
  var info: Dictionary=Catalog.all()[id]
  var b: Button=game.button(info.name+" · "+("선택됨" if session.selected==id else "체험")+"\n"+info.description,select.bind(id));b.custom_minimum_size=Vector2(500,95);b.add_theme_font_size_override("font_size",15);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;grid.add_child(b)
 stack.add_child(game.button("수련으로",game.close_modal))
func select(id: String) -> void:
 session.select(id);game.close_modal();stick.reset()
func cast() -> void:
 if session.cast():
  game.sound.play_clip("spell")
  if session.selected=="talisman":combat.swing(hero.position,Vector2.from_angle(hero.facing*PI/4),2,"talisman",session.Attack.TALISMAN_RANGE)
func interact() -> void:session.interact()
func release() -> void:session.release()
func attack() -> void:
 if session.attack():game.sound.play_clip("attack");combat.swing(hero.position,Vector2.from_angle(hero.facing*PI/4),1,"ground",112)
func reset() -> void:
 session.reset();stick.reset()
 for clone in clones.values():clone.queue_free()
 clones.clear();camera.reset_smoothing()
func _physics_process(delta: float) -> void:
 var active: bool=not leaving and not backgrounded and not is_instance_valid(game.modal)
 stick.input_enabled=active
 if not active:stick.reset();return
 var input:=stick.vector
 if input==Vector2.ZERO:input=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 session.tick(delta,input);sync(delta)
func sync(delta: float) -> void:
 var rules:=session.rules;var snapshot:=rules.view("student");var visible_ids: Array=[]
 for info in snapshot.actors:
  var id: String=info.uid;visible_ids.append(id);var actor: WooActor=avatars[id];var p:=Vector2(info.position[0],info.position[1]);var moved:=actor.position.distance_to(p)>.05
  markers[id].color_id=info.color;actor.position=p;actor.facing=info.facing;actor.cosmetic=info.cosmetic.duplicate();actor.identity_concealed=info.concealed;actor.appearance_form=info.form;actor.jar=false;actor.animation_time+=delta*7;actor.gait_phase+=delta*11;actor.gait_weight=move_toward(actor.gait_weight,1.0 if moved else 0.0,delta*10);actor.velocity=Vector2(60,0) if moved else Vector2.ZERO
  actor.action_pose=1 if id=="student" and session.selected=="talisman" else 0;actor.pose_duration=.45;actor.action_left=maxf(0,rules.players[id].buff.get("casting",0)-rules.elapsed)
  actor.hurt_left=.12 if id!="student" and session.stats[id].stun>rules.elapsed else 0;actor.update_sprite();labels[id].text=(str(info.name)+(" · HP%d"%session.stats[id].hp if id!="student" else ""));labels[id].visible=info.form=="human" and not info.concealed;actor.show()
 for id in avatars:
  if not visible_ids.has(id):avatars[id].hide()
 for asset in rules.arena.assets:
  var item: SealEnvironmentAsset=environment[asset.id];var p:=rules.arena.asset_position(asset,rules.elapsed);item.moving=item.position.distance_to(p)>.1;item.facing=4 if p.x<item.position.x else 0;item.position=p
 var active_clones: Array=[]
 for effect in rules.effects:
  if effect.kind!="clone":continue
  var id: String=str(effect.id);active_clones.append(id)
  if not clones.has(id):
   var copy:=Actor.new();copy.network_remote=true;copy.collision_layer=0;copy.collision_mask=0;world.add_child(copy);copy.set_physics_process(false);clones[id]=copy
   var marker:=preload("res://scripts/seal/color_marker.gd").new();marker.actor=copy;marker.color_id=effect.color;copy.add_child(marker)
   var name: Label=game.text(effect.name,10,game.GOLD);name.position=Vector2(-60,-65);name.size.x=120;name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;copy.add_child(name)
  var copy: WooActor=clones[id];copy.position=effect.position;copy.cosmetic=effect.cosmetic;copy.facing=effect.facing;copy.gait_phase+=delta*11;copy.gait_weight=1;copy.animation_time+=delta*7;copy.update_sprite()
 for id in clones.keys():
  if not active_clones.has(id):clones[id].queue_free();clones.erase(id)
 for hit in session.strikes:combat.burst(hit.position,hit.damage,hit.gold,false)
 session.strikes.clear()
 var info: Dictionary=Catalog.all()[session.selected];var cooldown: float=maxf(0,session.self_player().cd.get(session.selected,0)-rules.elapsed)
 header.text="도술 익히기 · %s  |  쿨타임 %.1f초  |  훈련 HP %d"%[info.name,cooldown,session.hp]
 notice.text=session.message;badge.skill=info.icon;badge.maximum=info.cd;badge.remaining=cooldown;cast_button.disabled=cooldown>0 and not (session.selected=="transform" and session.self_player().buff.get("transform",0)>rules.elapsed)
 var channel: Dictionary=rules.channels.get("student",{})
 interact_button.text="진행 %.1f초"%maxf(0,channel.until-rules.elapsed) if not channel.is_empty() else ("형상 추출" if session.selected=="transform" else "상호작용")
func leave() -> void:
 if leaving:return
 leaving=true;stick.reset();game.close_modal();session.clear_effects();world.hide();world.process_mode=Node.PROCESS_MODE_DISABLED
 source_scene.show();source_scene.process_mode=original_mode;game.adventure.process_mode=original_adventure_mode;game.screen_name="playing";game.active_context="hud";game.paused=false;game.camera.enabled=original_camera_enabled;game.camera.make_current();game.camera.reset_smoothing();game.sound.map_id=original_sound_map
 game.practice=null;game.build_hud();queue_free()
