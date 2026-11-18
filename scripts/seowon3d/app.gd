extends Node
const World=preload("res://scripts/seowon3d/world.gd")
const Player=preload("res://scripts/seowon3d/player.gd")
const Orbit=preload("res://scripts/seowon3d/camera.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var world: Node3D
var player: CharacterBody3D
var orbit: Node3D
var layer: CanvasLayer
var ui: Control
var stick: TouchJoystick
var run_button: WooMobileButton
var jump_button: WooMobileButton
var location_label: Label
var state_label: Label
var menu_panel: Control
var paused:=false
var backgrounded:=false
var sound: WooSound
var storage: RefCounted
var low:=false
func _ready() -> void:
 get_tree().auto_accept_quit=false
 storage=preload("res://scripts/survival/storage.gd").new()
 world=World.new();add_child(world)
 player=Player.new();player.position=World.SPAWN;add_child(player)
 orbit=Orbit.new();orbit.target=player;orbit.world=world;add_child(orbit)
 sound=preload("res://scripts/woo/sound.gd").new();add_child(sound)
 layer=CanvasLayer.new();layer.layer=3;add_child(layer)
 build_hud();get_viewport().size_changed.connect(layout_hud)
 if storage.error!="":state_label.text=storage.error
func label(value: String,font_size: int=20) -> Label:
 var l:=Label.new();l.text=value;l.add_theme_font_override("font",FONT);l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Color("fff1d1"));l.add_theme_color_override("font_shadow_color",Color("101424"));l.add_theme_constant_override("shadow_offset_x",2);l.add_theme_constant_override("shadow_offset_y",2);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func style(primary: bool=false,disabled: bool=false) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=Color("141e34",.92) if not disabled else Color("1c2232",.8);box.border_color=Color("cfb783") if primary else Color("6d7296");box.set_border_width_all(2 if primary else 1);box.set_corner_radius_all(24);box.content_margin_left=12;box.content_margin_right=12;return box
func button(value: String,callback: Callable,parent: Node=null,primary: bool=false) -> WooMobileButton:
 if parent==null:parent=ui
 var b:=preload("res://scripts/woo/mobile_button.gd").new();b.text=value;b.custom_minimum_size=Vector2(108,62);b.add_theme_font_override("font",FONT);b.add_theme_font_size_override("font_size",20)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var box:=style(primary,state=="disabled")
  if state in ["pressed","hover_pressed"]:box.bg_color=Color("4a456b")
  b.add_theme_stylebox_override(state,box)
 b.add_theme_color_override("font_color",Color("f4e5c7"));b.add_theme_color_override("font_disabled_color",Color("7e8197"))
 b.allowed=func()->bool:return not backgrounded and ((not paused and parent==ui) or (paused and parent!=ui))
 b.pressed.connect(func()->void:
  if b.usable():sound.play_clip("button");callback.call())
 parent.add_child(b);return b
func build_hud() -> void:
 ui=Control.new();layer.add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var title:=label("우울할 땐 도사",26);title.position=Vector2(28,18);ui.add_child(title)
 location_label=label("월하의 서원 · 3D 조작 시험",22);ui.add_child(location_label);location_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);location_label.offset_left=-260;location_label.offset_right=260;location_label.offset_top=20;location_label.offset_bottom=55;location_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 state_label=label("오른쪽 빈 화면 드래그: 시야 회전",18);state_label.position=Vector2(28,56);ui.add_child(state_label)
 var menu:=button("메뉴",show_menu,ui);menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);menu.offset_left=-142;menu.offset_right=-28;menu.offset_top=20;menu.offset_bottom=80
 stick=preload("res://scripts/joystick.gd").new();ui.add_child(stick);var move:=label("이동",20);move.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;move.position=Vector2(20,154);move.size.x=134;stick.add_child(move)
 run_button=button("달리기",func()->void:pass,ui,true);run_button.name="Run";run_button.button_down.connect(func()->void:player.running=true);run_button.button_up.connect(func()->void:player.running=false)
 jump_button=button("점프",func()->void:player.jump(),ui,true);jump_button.name="Jump"
 for i in range(4):
  var b:=button("스킬 %d\n미확정"%(i+1),func()->void:pass,ui);b.name="FutureSkill%d"%i;b.disabled=true;b.add_theme_font_size_override("font_size",16)
 var seal:=button("봉인·구조\n준비 중",func()->void:pass,ui);seal.name="FutureSeal";seal.disabled=true;seal.add_theme_font_size_override("font_size",17)
 layout_hud()
func place(node: Control,left: float,top: float,width: float,height: float) -> void:
 node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);node.offset_left=left;node.offset_top=top;node.offset_right=left+width;node.offset_bottom=top+height
func layout_hud() -> void:
 if not is_instance_valid(stick):return
 var safe_left:=28.0;var safe_right:=24.0;var safe_bottom:=22.0
 if OS.get_name()=="Android":
  var safe:=DisplayServer.get_display_safe_area();var dimensions:=DisplayServer.screen_get_size();var view:=get_viewport().get_visible_rect().size
  if dimensions.x>0 and dimensions.y>0:
   safe_left=maxf(safe_left,safe.position.x*view.x/dimensions.x);safe_right=maxf(safe_right,(dimensions.x-safe.end.x)*view.x/dimensions.x);safe_bottom=maxf(safe_bottom,(dimensions.y-safe.end.y)*view.y/dimensions.y)
 stick.size=Vector2(174,174);stick.position=Vector2(safe_left+20,get_viewport().get_visible_rect().size.y-safe_bottom-188)
 place(run_button,-safe_right-240,-safe_bottom-90,108,86);place(jump_button,-safe_right-120,-safe_bottom-90,108,86)
 for i in range(4):place(ui.get_node("FutureSkill%d"%i),-safe_right-108-(i%2)*112,-safe_bottom-192-floori(i/2.0)*88,100,80)
 place(ui.get_node("FutureSeal"),-safe_right-352,-safe_bottom-96,100,92)
func show_menu() -> void:
 if paused:return
 paused=true;player.process_mode=Node.PROCESS_MODE_DISABLED;orbit.process_mode=Node.PROCESS_MODE_DISABLED;world.process_mode=Node.PROCESS_MODE_DISABLED;player.enabled=false;player.running=false;player.input_vector=Vector2.ZERO;stick.reset();orbit.active=false;orbit.reset_input()
 menu_panel=Control.new();ui.add_child(menu_panel);menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade:=ColorRect.new();shade.color=Color(.015,.02,.04,.88);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);menu_panel.add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);menu_panel.add_child(center)
 var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(560,420);panel.add_theme_stylebox_override("panel",style(true));center.add_child(panel)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);panel.add_child(box);box.add_child(label("3D 이동 검증 · 경기 기능은 미구현",23))
 button("계속하기",resume,box,true)
 button("시작 위치·카메라 복원",func()->void:player.global_position=World.SPAWN;player.velocity=Vector3.ZERO;orbit.yaw=0;orbit.pitch=15;orbit.actual_distance=4.5;resume(),box)
 button("그림자 품질: "+("낮음" if low else "보통"),func()->void:low=not low;world.low_quality=low;resume(),box)
 var row:=HBoxContainer.new();box.add_child(row)
 for spec in [["상호작용","interact"],["봉인 자세","sealed"],["구조 자세","rescue"]]:
  var state: String=spec[1]
  button(spec[0],func()->void:resume();player.show_animation(state),row)
 box.add_child(label("위 동작은 애니메이션 시험입니다. 판정·능력은 없습니다.",16))
 button("종료",func()->void:get_tree().quit(),box)
func resume() -> void:
 if is_instance_valid(menu_panel):menu_panel.queue_free()
 menu_panel=null;paused=false;player.process_mode=Node.PROCESS_MODE_INHERIT;orbit.process_mode=Node.PROCESS_MODE_INHERIT;world.process_mode=Node.PROCESS_MODE_INHERIT;player.enabled=true;orbit.active=true;stick.reset()
func _physics_process(_delta: float) -> void:
 if not is_instance_valid(player):return
 player.input_vector=stick.vector if not paused and not backgrounded else Vector2.ZERO;player.camera_yaw=orbit.yaw
 world.observer=player.global_position
 if not paused:
  location_label.text="월하의 서원 · 서책고 실내" if world.inside(player.global_position) else "월하의 서원 · 중앙 마당"
  state_label.text="3D 조작 시험 · 경기·스킬은 미구현 · "+player.animation_state
 jump_button.disabled=paused or not player.is_on_floor()
func back() -> void:
 if paused:resume()
 else:show_menu()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):back()
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
  backgrounded=true
  if is_instance_valid(sound):sound.set_backgrounded(true)
  if is_instance_valid(ui) and not paused:show_menu()
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
  backgrounded=false
  if is_instance_valid(sound):sound.set_backgrounded(false)
