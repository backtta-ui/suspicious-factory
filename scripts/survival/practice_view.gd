extends WooPracticeUI
## Adapter for the existing spell test session. No plaza, RPG state or ownership IO.
func _ready() -> void:
 session=preload("res://scripts/practice/session.gd").new(preload("res://scripts/survival/characters.gd").look(game.storage.data.daoist))
 world=preload("res://scripts/practice/world.gd").new();add_child(world)
 for id in ["student"]+session.NPCS.keys():
  var actor:=Actor.new();actor.network_remote=true;actor.collision_layer=0;actor.collision_mask=0;world.add_child(actor);actor.set_physics_process(false);avatars[id]=actor
  var marker:=preload("res://scripts/seal/color_marker.gd").new();marker.actor=actor;marker.color_id=session.rules.players[id].color;actor.add_child(marker);markers[id]=marker
  var plate:=preload("res://scripts/practice/nameplate.gd").new();plate.position=Vector2(0,-65);actor.add_child(plate);labels[id]=plate
 hero=avatars.student
 camera=Camera2D.new();camera.zoom=Vector2(2,2);camera.position=Vector2(0,-36);camera.position_smoothing_enabled=true;camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(Layout.SIZE.x);camera.limit_bottom=int(Layout.SIZE.y);hero.add_child(camera);camera.make_current()
 for asset in session.rules.arena.assets:
  var item:=preload("res://scripts/seal/environment_asset.gd").new();item.kind=asset.kind;world.add_child(item);environment[asset.id]=item
 var fx:=preload("res://scripts/practice/fx.gd").new();fx.practice=self;world.add_child(fx)
 combat=preload("res://scripts/woo/combat_effects.gd").new();world.add_child(combat)
 build_ui();sync(0);camera.reset_smoothing()
func build_ui() -> void:
 header=game.text("도술 시험 · 저장 기록 미반영",23);header.position=Vector2(24,18);game.ui.add_child(header)
 var back: Button=game.button("로비 복귀",request_leave,false,game.ui);back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);back.offset_left=-160;back.offset_right=-20;back.offset_top=18;back.offset_bottom=76
 var list: Button=game.button("도술 목록",show_spells,false,game.ui);list.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);list.offset_left=-310;list.offset_right=-170;list.offset_top=18;list.offset_bottom=76
 notice=game.text("",17);notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);notice.offset_left=-420;notice.offset_right=250;notice.offset_top=-70;notice.offset_bottom=-20;notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;game.ui.add_child(notice)
 stats_label=game.text("",17);stats_label.position=Vector2(24,58);game.ui.add_child(stats_label)
 vitality=preload("res://scripts/ui/vital_bar.gd").new();vitality.position=Vector2(24,90);vitality.size=Vector2(200,10);game.ui.add_child(vitality)
 stick=preload("res://scripts/joystick.gd").new();game.ui.add_child(stick);adjust_safe()
 cast_button=game.action("도술 사용","jar",Vector2(-156,-180),Vector2(132,132),cast);badge=cast_button.get_node("Badge")
 interact_button=game.action("상호작용","rescue",Vector2(-286,-160),Vector2(112,112),interact)
 game.action("표적 공격","attack",Vector2(-416,-160),Vector2(112,112),attack)
 release_button=game.button("변신 해제",release,false,game.ui);release_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);release_button.offset_left=-180;release_button.offset_right=-24;release_button.offset_top=-270;release_button.offset_bottom=-210
 var reset_button: Button=game.button("초기화",reset,false,game.ui);reset_button.position=Vector2(24,112)
func show_spells() -> void:
 var stack: VBoxContainer=game.popup("도술 시험 · 기존 등록 기능 14종")
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(680,350);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(scroll)
 var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for id in Catalog.all():
  var entry: Dictionary=Catalog.all()[id]
  var b: Button=game.button(entry.name+" · %d초"%entry.cd,select.bind(id),session.selected==id,list);b.custom_minimum_size.x=620
 var gesture:=preload("res://scripts/ui/popup_scroll.gd").new();gesture.scroll=scroll;game.modal.add_child(gesture)
 stack.add_child(game.button("닫기",game.close_popup))
func select(id: String) -> void:
 session.select(id);game.close_popup();stick.reset()
func _physics_process(delta: float) -> void:
 var active: bool=not leaving and not game.backgrounded and game.modal==null and game.screen=="practice"
 stick.input_enabled=active
 if not active:stick.reset();return
 session.tick(delta,stick.vector);sync(delta)
func show_training_settings() -> void:pass
func request_leave(_to_plaza: bool=false) -> void:
 if leaving:return
 leaving=true;stick.reset();session.clear_effects();game.close_popup();game.practice_done()
func leave() -> void:request_leave()
