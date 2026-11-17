extends Node
const Actor = preload("res://scripts/woo/actor.gd")
const Village = preload("res://scripts/worlds/plaza.gd")
const Layout = preload("res://scripts/worlds/plaza_layout.gd")
const Rpg = preload("res://scripts/woo/rpg_state.gd")
const Adventure = preload("res://scripts/woo/adventure.gd")
var hero_portrait: TextureRect
var hero_name: Label
var wardrobe: WooWardrobe
var rpg: WooRpgState
var adventure: WooAdventure
const Save = preload("res://scripts/woo/save_game.gd")
const MobileButton = preload("res://scripts/woo/mobile_button.gd")
const Joystick = preload("res://scripts/joystick.gd")
const Ornament = preload("res://scripts/woo/ornament.gd")
const MiniMap = preload("res://scripts/woo/minimap.gd")
const TitleFont = preload("res://assets/fonts/WooTitle.otf")
const ArtFrames = preload("res://scripts/woo/art_frames.gd")
const DebugInput = preload("res://scripts/touch_debug.gd")
const FONT = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const INK := Color("191825")
const GOLD := Color("d8b87e")
var practice: WooPracticeUI
var near_practice:=false
var near_simulation:=false
var seal_client: SealClientUI
var screen_name := "menu"
var active_context := "menu"
var ui_generation := 0
var action_pending := false
var layer: CanvasLayer
var ui: Control
var modal: Control
var modal_kind := ""
var world: WooStoryPlaza
var player: WooActor
var camera: Camera2D
var actors: Array[WooActor] = []
var joystick: TouchJoystick
var run_button: WooMobileButton
var interact_button: WooMobileButton
var spell_button: WooMobileButton
var hint: Label
var place_label: Label
var touch_debug: TouchDebug
var sound: WooSound
var settings := {"smooth_camera":true,"day_cycle":true,"sound":true}
var unlocked: Array = ["jar"]
var talked_to_elder := false
var quest_label: Label
var hud_map: WooLocalMinimap
var nearest_npc := -1
var near_well := false
var dialogue_index := 0
var dialogue_lines: Array = []
var dialogue_name := ""
var paused := false
var save_elapsed := 0.0
var saved_indicator := 0.0
var last_save_error := OK
var save_thread: Thread
var quitting := false
var menu_motion: Control
var nearest_painting:=-1
var completed_paintings: Array=[]
var return_anchor: Dictionary={}
var legacy_position: Array=[]

func _ready() -> void:
 get_tree().auto_accept_quit = false
 wardrobe=preload("res://scripts/wardrobe/profile.gd").new()
 wardrobe.refresh(Save.load_game().get("rpg",{}))
 settings = Save.settings()
 sound = preload("res://scripts/woo/sound.gd").new()
 add_child(sound)
 sound.set_enabled(settings.sound)
 sound.set_music_enabled(settings.music)
 layer = CanvasLayer.new()
 layer.layer = 1
 add_child(layer)
 loading=preload("res://scripts/ui/loading_manager.gd").new();loading.game=self;add_child(loading)
 show_menu(false)
 touch_debug = DebugInput.new()
 touch_debug.target = self
 add_child(touch_debug)

func style(color: Color, radius: int = 5) -> StyleBoxFlat:
 return preload("res://scripts/ui/design.gd").panel(color,radius)

func text(value: String, font_size: int = 22, color: Color = Color("e8e1cc")) -> Label:
 var label := Label.new()
 label.text = value
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 return label

func button(value: String, callback: Callable, primary: bool = false) -> WooMobileButton:
 var node := MobileButton.new()
 node.text = value
 var context := active_context
 var generation := ui_generation
 node.allowed = func() -> bool: return context==active_context and generation==ui_generation and not content_loading and not (is_instance_valid(adventure) and adventure.transitioning)
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:node.add_theme_stylebox_override(mode,preload("res://scripts/ui/design.gd").button_style(mode,primary))
 node.custom_minimum_size.y=preload("res://scripts/ui/design.gd").BUTTON_HEIGHT
 node.add_theme_color_override("font_color",Color("f4d99d") if primary else Color("e8e1cc"))
 node.add_theme_color_override("font_pressed_color",Color("fff4cd"))
 node.observed.connect(func(event: InputEvent) -> void:
  if is_instance_valid(touch_debug): touch_debug.observe(event,screen_name,ui))
 node.pressed.connect(func() -> void:
  if action_pending or quitting: return
  action_pending = true
  perform_action.call_deferred(weakref(node),callback))
 var ornament := Ornament.new()
 ornament.primary = primary
 ornament.visible = primary
 ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 node.add_child(ornament)
 return node

func perform_action(source: WeakRef, callback: Callable) -> void:
 var node = source.get_ref()
 if is_instance_valid(node) and node.is_inside_tree() and node.usable():
  sound.play_clip("button")
  callback.call()
 action_pending = false

func new_ui() -> void:
 ui_generation += 1
 if is_instance_valid(ui):
  ui.hide()
  ui.queue_free()
 modal = null
 modal_kind = ""
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var theme := Theme.new()
 theme.default_font = preload("res://scripts/ui/design.gd").FONT
 theme.default_font_size = 22
 theme.set_constant("separation","VBoxContainer",12)
 theme.set_constant("separation","HBoxContainer",18)
 ui.theme = theme
 layer.add_child(ui)
 if is_instance_valid(touch_debug): touch_debug.record("SCREEN",screen_name)

func show_menu(save_before: bool = true) -> void:
 if save_before and screen_name=="playing": save_progress()
 if is_instance_valid(adventure):adventure.dispose();adventure.queue_free()
 if is_instance_valid(world):
  world.queue_free()
  world = null
 player = null
 camera = null
 actors.clear()
 paused = false
 screen_name = "menu"
 active_context = "menu"
 new_ui()
 sound.context="menu"
 menu_motion=preload("res://scripts/woo/menu_motion.gd").new()
 menu_motion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu_motion.reduced=settings.low_effects
 ui.add_child(menu_motion)
 var shade := ColorRect.new()
 shade.color = Color(0.04,0.025,0.07,0.14)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(shade)
 var title := text("도사",106,Color("f5e5c7"))
 title.add_theme_font_override("font",TitleFont)
 title.add_theme_color_override("font_outline_color",Color("3a2432"))
 title.add_theme_constant_override("outline_size",7)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 title.offset_left=-490;title.offset_right=-100;title.offset_top=78;title.offset_bottom=248
 ui.add_child(title)
 var subtitle:=text("전우치",36,GOLD)
 subtitle.add_theme_font_override("font",TitleFont)
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 subtitle.offset_left=-490;subtitle.offset_right=-100;subtitle.offset_top=228;subtitle.offset_bottom=280
 ui.add_child(subtitle)
 var motto:=text("달빛에 숨고, 도술로 길을 열다",17,Color("ddd0bb"))
 motto.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 motto.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 motto.offset_left=-490;motto.offset_right=-100;motto.offset_top=291;motto.offset_bottom=325
 ui.add_child(motto)
 var menu:=VBoxContainer.new()
 menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 menu.offset_left=-485;menu.offset_right=-105;menu.offset_top=342;menu.offset_bottom=626
 ui.add_child(menu)
 menu.add_child(button("봉인의 밤 · 온라인",show_seal,true))
 var resume:=button("이어하기",request_start.bind(true))
 resume.disabled=Save.load_game().is_empty()
 menu.add_child(resume)
 menu.add_child(button("설정",show_settings))
 menu.add_child(button("종료",quit_game))
 var multiplayer_button:=button("그림 속 모험",request_start.bind(false),true)
 multiplayer_button.position=Vector2(30,594);multiplayer_button.custom_minimum_size=Vector2(360,64);ui.add_child(multiplayer_button)
 var dress:=button("도사 꾸미기",show_wardrobe)
 dress.position=Vector2(30,516);dress.custom_minimum_size=Vector2(360,64);ui.add_child(dress)
 var chapter:=text("第一章  ·  계월촌",16,GOLD)
 chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 chapter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 chapter.offset_left=-490;chapter.offset_right=-100;chapter.offset_top=656;chapter.offset_bottom=676
 ui.add_child(chapter)
 var version:=text("V%s   ·   그림 속 모험 · 봉인의 밤" % ProjectSettings.get_setting("application/config/version"),14,Color("c3b7bc"))
 version.position=Vector2(30,676)
 ui.add_child(version)

func apply_appearance_ui() -> void:
 var look: Dictionary=wardrobe.data.appearance
 if is_instance_valid(hero_name):hero_name.text=preload("res://scripts/wardrobe/catalog.gd").CHARACTERS[look.character].name
 if is_instance_valid(hero_portrait):
  hero_portrait.texture=preload("res://scripts/wardrobe/art.gd").icon(preload("res://scripts/wardrobe/catalog.gd").CHARACTERS[look.character].cell)

func show_wardrobe() -> void:
 if is_instance_valid(modal):return
 var screen:=preload("res://scripts/wardrobe/screen.gd").new();screen.game=self;add_child(screen)

func enter_simulation() -> void:
 if screen_name!="playing" or paused or content_loading or adventure.in_mission or is_instance_valid(seal_client):return
 save_progress();close_modal();set_paused(true)
 screen_name="seal";active_context="seal";new_ui()
 seal_client=preload("res://scripts/simulation/client.gd").new();seal_client.game=self;add_child(seal_client)

func show_seal() -> void:
 if is_instance_valid(seal_client):return
 screen_name="seal";active_context="seal";new_ui()
 seal_client=preload("res://scripts/seal/client_ui.gd").new();seal_client.game=self;add_child(seal_client)

func start_game(continue_existing: bool = false) -> void:
 if screen_name=="playing": return
 var saved := Save.load_game() if continue_existing else {}
 if continue_existing and saved.is_empty(): return
 screen_name = "playing"
 active_context = "hud"
 paused = content_loading
 if content_loading:loading.mark_phase("resources_ready")
 world = Village.new()
 world.staged_loading=content_loading
 add_child(world)
 world.cycle_enabled = settings.day_cycle
 world.low_effects=settings.low_effects
 if content_loading:loading.mark_phase("plaza_attached")
 sound.context="village"
 rpg=Rpg.new(saved.get("rpg",{}))
 adventure=Adventure.new();adventure.game=self;add_child(adventure)
 if saved.has("time_of_day"): world.time_of_day = clampf(float(saved.time_of_day),0,1)
 player = Actor.new()
 player.name = "JeonWoochi"
 player.enabled=not content_loading
 wardrobe.refresh(rpg.data);player.cosmetic=wardrobe.data.appearance.duplicate()
 player.position = Vector2(saved.position[0],saved.position[1]) if not saved.is_empty() else Layout.SPAWN
 player.jar = bool(saved.get("jar",false))
 unlocked = saved.get("unlocked",["jar"])
 talked_to_elder = bool(saved.get("talked_to_elder",false))
 completed_paintings=saved.get("completed_paintings",[])
 return_anchor=saved.get("return_anchor",{})
 legacy_position=saved.get("legacy_position",[])
 world.set_completed_stories(completed_paintings)
 world.add_child(player)
 actors.append(player)
 for data in Layout.NPCS:
  var npc := Actor.new()
  npc.npc = true
  npc.enabled=not content_loading
  npc.npc_name = data.name
  npc.position = data.position
  npc.tint = Color.WHITE
  npc.npc_variant = int(data.get("variant",actors.size()-1))
  npc.npc_driver=preload("res://scripts/woo/npc_driver.gd").new(data,world.navigation)
  world.add_child(npc)
  actors.append(npc)
  if content_loading:await get_tree().process_frame
 camera = Camera2D.new()
 camera.zoom = Vector2(2,2)
 camera.offset = Vector2.ZERO
 camera.position=Vector2(0,-36)
 camera.position_smoothing_enabled = settings.smooth_camera
 camera.position_smoothing_speed = 5
 camera.limit_left = 0
 camera.limit_top = 0
 camera.limit_right = int(Layout.SIZE.x)
 camera.limit_bottom = int(Layout.SIZE.y)
 player.add_child(camera)
 camera.make_current()
 build_hud()
 if content_loading:loading.mark_phase("actors_camera_hud")
 save_elapsed = 0
 if not rpg.data.session.is_empty():adventure.resume_session()
 save_progress()

func build_hud() -> void:
 new_ui()
 var header:=PanelContainer.new()
 header.position=Vector2(26,16)
 header.add_theme_stylebox_override("panel",style(Color(0.10,0.07,0.13,0.92),8))
 ui.add_child(header)
 var row:=HBoxContainer.new();header.add_child(row)
 var portrait:=TextureRect.new()
 var atlas:=AtlasTexture.new()
 atlas.atlas=preload("res://assets/woo/hd/hero.png")
 var frame: Array=ArtFrames.HERO[34]
 atlas.region=Rect2(frame[0],frame[1],frame[2],frame[3])
 portrait.texture=atlas
 hero_portrait=portrait
 portrait.custom_minimum_size=Vector2(48,60)
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_child(portrait)
 var lines:=VBoxContainer.new();row.add_child(lines)
 hero_name=text("전우치",20,GOLD);lines.add_child(hero_name)
 apply_appearance_ui()
 place_label=text("계월촌 · 밤",15)
 lines.add_child(place_label)
 var quest:=PanelContainer.new()
 quest.position=Vector2(26,118)
 quest.add_theme_stylebox_override("panel",style(Color(0.10,0.065,0.12,0.9),6))
 ui.add_child(quest)
 var quest_lines:=VBoxContainer.new();quest.add_child(quest_lines)
 quest_lines.add_child(text("첫걸음",19,GOLD))
 quest_label=text("",16)
 quest_lines.add_child(quest_label)
 var settings_button:=button("메뉴  ☰",show_rpg_menu)
 settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 settings_button.offset_left=-280;settings_button.offset_right=-162
 settings_button.offset_top=24;settings_button.offset_bottom=88
 settings_button.add_theme_font_size_override("font_size",16)
 ui.add_child(settings_button)
 hud_map=MiniMap.new()
 hud_map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 hud_map.offset_left=-150;hud_map.offset_right=-18
 hud_map.offset_top=10;hud_map.offset_bottom=142
 ui.add_child(hud_map)
 hint=text("주민에게 다가가 대화해 보세요",16,Color("e0cfbe"))
 hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 hint.offset_left=350;hint.offset_right=-320;hint.offset_top=30
 hint.add_theme_color_override("font_outline_color",Color("211722"))
 hint.add_theme_constant_override("outline_size",4)
 ui.add_child(hint)
 joystick=Joystick.new()
 joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 joystick.position=Vector2(74,-222)
 joystick.resized.connect(adjust_safe_controls)
 joystick.size=Vector2(174,174)
 ui.add_child(joystick)
 run_button=button("달리기",func() -> void: pass)
 run_button.name="RunButton"
 place_action(run_button,-396,"run")
 run_button.button_down.connect(func() -> void: if is_instance_valid(player): player.running=true)
 run_button.button_up.connect(func() -> void: if is_instance_valid(player): player.running=false)
 spell_button=button("둔갑술",cast_spell,true)
 spell_button.name="SpellButton"
 place_action(spell_button,-148,"spell")
 interact_button=button("대화",interact)
 interact_button.name="InteractButton"
 place_action(interact_button,-272,"talk")
 if is_instance_valid(adventure):adventure.build_controls()
 adjust_safe_controls.call_deferred()

func place_action(node: WooMobileButton, top: int, icon: String) -> void:
 node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 node.offset_left=-146;node.offset_right=-34
 node.offset_top=top;node.offset_bottom=top+112
 node.add_theme_font_size_override("font_size",18)
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:
  var box:=style(Color(0.12,0.08,0.13,0.92) if mode!="pressed" and mode!="hover_pressed" else Color("695056"),56)
  box.content_margin_left=8;box.content_margin_right=8
  box.content_margin_top=54;box.content_margin_bottom=8
  box.set_border_width_all(0)
  node.add_theme_stylebox_override(mode,box)
 for child in node.get_children():
  if child is WooOrnament: child.show();child.circular=true;child.icon=icon
 ui.add_child(node)
 preload("res://scripts/ui/design.gd").place_action(node,{"spell":"spell","talk":"interact","run":"run"}[icon])
 if icon=="talk":preload("res://scripts/ui/design.gd").interaction(node)

func set_paused(value: bool) -> void:
 paused = value
 sound.ducked=value
 for actor in actors:
  actor.enabled = not value
  actor.intent = Vector2.ZERO
  actor.velocity = Vector2.ZERO
 if is_instance_valid(player): player.running = false
 if is_instance_valid(joystick):
  joystick.reset()
  joystick.input_enabled = not value
 if is_instance_valid(run_button): run_button.cancel()

func open_modal(kind: String) -> VBoxContainer:
 if is_instance_valid(modal): return null
 preload("res://scripts/ui/design.gd").cancel_controls(ui)
 if screen_name=="playing": set_paused(true)
 active_context = "modal"
 modal_kind = kind
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0.02,0.06,0.08,0.82)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(center)
 var card := PanelContainer.new()
 card.custom_minimum_size.x = 620
 card.add_theme_stylebox_override("panel",style(preload("res://scripts/ui/design.gd").PANEL,10))
 center.add_child(card)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;card.add_child(scroll)
 var stack := VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(stack)
 var gesture:=preload("res://scripts/ui/popup_scroll.gd").new();gesture.scroll=scroll;modal.add_child(gesture)
 fit_popup.call_deferred(scroll,stack)
 preload("res://scripts/ui/design.gd").popup_enter(modal)
 return stack

func fit_popup(scroll: ScrollContainer,stack: VBoxContainer) -> void:
 if not is_instance_valid(scroll) or not is_instance_valid(stack):return
 preload("res://scripts/ui/design.gd").wrap_text(stack)
 scroll.custom_minimum_size=Vector2(600,minf(stack.get_combined_minimum_size().y,get_viewport().get_visible_rect().size.y-80))

func retire_popup(control: Control) -> void:
 # Active UI owns only active dialogs, independently of render-frame speed.
 control.theme=ui.theme;control.reparent(layer);layer.move_child(control,0)
 preload("res://scripts/ui/design.gd").popup_exit(control)

func close_modal() -> void:
 if is_instance_valid(modal):
  retire_popup(modal)
 modal = null
 modal_kind = ""
 active_context = "practice" if screen_name=="practice" else ("hud" if screen_name=="playing" else "menu")
 if screen_name=="playing": set_paused(false)

func show_settings() -> void:
 var stack := open_modal("settings")
 if not stack: return
 stack.add_child(text("잠시 쉬어가기",30,GOLD))
 var grid:=GridContainer.new();grid.columns=2;stack.add_child(grid)
 var preferences: Array=[
  ["카메라: "+("부드럽게" if settings.smooth_camera else "즉시 추적"),"smooth_camera"],
  ["낮과 밤 변화: "+("켜짐" if settings.day_cycle else "꺼짐"),"day_cycle"],
  ["효과음: "+("켜짐" if settings.sound else "꺼짐"),"sound"],
  ["배경음악: "+("켜짐" if settings.music else "꺼짐"),"music"],
  ["환경 효과: "+("간소화" if settings.low_effects else "풍부하게"),"low_effects"]]
 for pref in preferences:
  var control:=button(pref[0],toggle_setting.bind(pref[1]));control.custom_minimum_size.x=320;control.add_theme_font_size_override("font_size",18);grid.add_child(control)
 var credits:=button("음원 출처",show_credits);credits.add_theme_font_size_override("font_size",18);grid.add_child(credits)
 if screen_name=="playing":stack.add_child(button("전투 효과 설정",adventure.show_effects))
 stack.add_child(button("돌아가기",close_modal,true))
 if screen_name=="playing":
  stack.add_child(button("저장하고 메인으로",func() -> void: close_modal(); show_menu()))
 stack.add_child(text("기기 내 자동 저장 · 오프라인 진행 유지",16,Color("9db3ac")))

func toggle_setting(key: String) -> void:
 settings[key] = not settings[key]
 Save.save_settings(settings)
 sound.set_enabled(settings.sound)
 sound.set_music_enabled(settings.music)
 if is_instance_valid(camera): camera.position_smoothing_enabled = settings.smooth_camera
 if is_instance_valid(world):
  world.cycle_enabled = settings.day_cycle
  world.low_effects=settings.low_effects
 if content_loading:loading.mark_phase("plaza_attached")
 if is_instance_valid(menu_motion):menu_motion.reduced=settings.low_effects
 close_modal()
 show_settings()

func show_credits() -> void:
 close_modal()
 var stack:=open_modal("credits")
 if not stack:return
 stack.add_child(text("음악과 소리",28,GOLD))
 var body:=text("국악 배경음악 #131 — 공유마당 / 한국저작권위원회\n많은 방울(리버브) — 김용배 / 공유마당\n위 두 음원: CC BY 4.0 · 루프·발췌·음량·음색 편집\n발걸음·옷깃·책장: Kenney RPG Audio · CC0",18)
 stack.add_child(body)
 stack.add_child(button("출처와 이용허락 보기",func() -> void: OS.shell_open("https://github.com/backtta-ui/suspicious-factory/blob/main/assets/audio/NOTICE.txt")))
 stack.add_child(button("돌아가기",func() -> void: close_modal();show_settings(),true))

func request_gallery(index: int) -> void:
 if content_loading or not is_instance_valid(adventure) or adventure.in_mission or is_instance_valid(modal):return
 set_paused(true)
 if not loading.begin("gallery",request_gallery.bind(index)):return
 var paths: Array=[]
 for info in preload("res://scripts/worlds/catalog.gd").WORLDS:paths.append(info.thumbnailAsset)
 if not await loading.prepare(paths):return
 show_painting_intro(index)
 await get_tree().process_frame
 loading.complete();loading.input_ready();save_progress()

func show_painting_intro(index: int) -> void:
 if is_instance_valid(adventure):adventure.show_painting(index)

var content_loading:=false
var loading: WooLoadingManager
var loading_focus_hold:=false
func request_start(continue_existing: bool=false) -> void:
 if screen_name=="playing" or (continue_existing and Save.load_game().is_empty()):return
 if not loading.begin("plaza" if continue_existing else "initial",request_start.bind(continue_existing),func()->void:if screen_name=="playing":show_menu(false)):return
 var paths: Array=["res://assets/woo/worlds/plaza_ground.png","res://assets/woo/v11/stone_bridge.png"]
 if continue_existing:
  var saved_world: String=Save.load_game().get("rpg",{}).get("session",{}).get("map","")
  paths.append_array(loading.world_assets(saved_world))
 if not await loading.prepare(paths):return
 await start_game(continue_existing);set_paused(true)
 if not await loading.wait_ready(world):return
 world.set_completed_stories(completed_paintings)
 if adventure.in_mission and not await loading.wait_ready(adventure.forest):return
 if not is_instance_valid(player) or not is_instance_valid(camera) or not camera.is_current():loading.failure("캐릭터 또는 카메라 준비에 실패했습니다.");return
 loading.complete();finish_loading_play();loading.input_ready();save_progress()

func finish_loading_play() -> void:
 loading_focus_hold=sound.backgrounded
 set_paused(loading_focus_hold)

func enter_practice(skill: String="transform") -> void:
 if is_instance_valid(practice) or content_loading or screen_name!="playing" or not is_instance_valid(player) or adventure.transitioning:return
 save_progress();close_modal();set_paused(true)
 if not loading.begin("practice",enter_practice.bind(skill)):return
 if not await loading.prepare(["res://assets/woo/practice_ground.png"]):return
 if quitting or screen_name!="playing" or not is_instance_valid(player):loading.release();return
 practice=preload("res://scripts/practice/ui.gd").new();practice.game=self;add_child(practice);practice.select(skill);practice.backgrounded=sound.backgrounded
 if not is_instance_valid(practice.hero) or not is_instance_valid(practice.camera):loading.failure("수련장 준비에 실패했습니다.");return
 loading.complete();loading.input_ready()

func show_rpg_menu() -> void:
 if is_instance_valid(adventure):adventure.show_menu()

func adjust_safe_controls() -> void:
 if not is_instance_valid(joystick):return
 preload("res://scripts/ui/design.gd").position_stick(joystick)

func restore_plaza_anchor() -> bool:
 if not is_instance_valid(player) or return_anchor.get("map","")!=Layout.MAP_ID:return false
 var p: Array=return_anchor.get("position",[])
 if p.size()!=2:return false
 player.position=Layout.safe_position(Vector2(p[0],p[1]));player.reset_physics_interpolation()
 player.facing=int(return_anchor.get("facing",2))
 if is_instance_valid(camera):
  var z: Array=return_anchor.get("camera_zoom",[2,2]);camera.zoom=Vector2(clampf(float(z[0]),1,4),clampf(float(z[1]),1,4))
  camera.rotation=float(return_anchor.get("camera_rotation",0))
  var q: Array=return_anchor.get("camera_position",[0,-36]);camera.position=Vector2(q[0],q[1])
 if is_instance_valid(camera):camera.reset_smoothing()
 return true

func cast_spell() -> void:
 if screen_name!="playing" or paused or not unlocked.has("jar"): return
 if player.begin_transform(): sound.play_clip("spell")

func interact() -> void:
 if screen_name!="playing" or paused: return
 if is_instance_valid(adventure) and adventure.in_mission:adventure.mission_interact();return
 if near_simulation:
  enter_simulation();return
 if near_practice:
  enter_practice();return
 if nearest_painting>=0:
  request_gallery(nearest_painting)
  return
 if nearest_npc>=0:
  var data: Dictionary = Layout.NPCS[nearest_npc]
  if nearest_npc==2:
   talked_to_elder=true
   save_progress()
  dialogue_lines = data.lines
  dialogue_name = data.name
 elif near_well:
  dialogue_lines = ["차가운 우물물에 달빛이 흔들린다. 멀리서 방울 소리가 들려온다."]
  dialogue_name = "오래된 우물"
 else: return
 dialogue_index = 0
 show_dialogue()

func show_dialogue() -> void:
 sound.play_clip("dialogue")
 var stack := open_modal("dialogue")
 if not stack: return
 stack.add_child(text(dialogue_name,26,GOLD))
 var body := text(str(dialogue_lines[dialogue_index]),23)
 body.custom_minimum_size = Vector2(660,120)
 body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stack.add_child(body)
 var row := HBoxContainer.new()
 stack.add_child(row)
 var next := button("다음" if dialogue_index<dialogue_lines.size()-1 else "대화 마치기",next_dialogue,true)
 next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(next)
 row.add_child(button("닫기",close_modal))

func next_dialogue() -> void:
 close_modal()
 dialogue_index += 1
 if dialogue_index<dialogue_lines.size(): show_dialogue()

func finish_save() -> void:
 if save_thread != null:
  last_save_error = save_thread.wait_to_finish()
  save_thread = null

func _exit_tree() -> void:
 finish_save()

func save_progress(background: bool = false) -> void:
 if content_loading:return
 if screen_name!="playing" or not is_instance_valid(player): return
 var data := {"schema":1,"map":Layout.MAP_ID,"position":(return_anchor.position.duplicate() if is_instance_valid(adventure) and adventure.in_mission else [player.position.x,player.position.y]),"settings":settings.duplicate(),"unlocked":unlocked.duplicate(),"jar":player.jar,"time_of_day":world.time_of_day,"talked_to_elder":talked_to_elder,"map_revision":Layout.REVISION,"completed_paintings":completed_paintings.duplicate(),"return_anchor":return_anchor.duplicate(true)}
 if is_instance_valid(adventure):adventure.capture_session()
 if rpg!=null:
  data.rpg=rpg.data.duplicate(true)
  wardrobe.refresh(rpg.data);wardrobe.save()
 if not legacy_position.is_empty():data.legacy_position=legacy_position.duplicate()
 # Serialize all writes. Exit/background/manual saves join any pending auto-save.
 finish_save()
 if background:
  save_thread = Thread.new()
  var error := save_thread.start(func() -> Error: return Save.save_game(data))
  if error != OK:
   save_thread = null
   last_save_error = error
 else:
  last_save_error = Save.save_game(data)
 saved_indicator = 2
 save_elapsed = 0

func quit_game() -> void:
 if quitting: return
 quitting=true
 save_progress()
 Save.save_settings(settings)
 if is_instance_valid(seal_client):seal_client.connection.stop()
 sound.shutdown()
 # Let the audio server release a just-played button voice before engine shutdown.
 await get_tree().create_timer(0.08).timeout
 get_tree().quit()

func _physics_process(_delta: float) -> void:
 # Sample touch on every movement tick, including frames delayed by HD texture upload.
 if screen_name=="playing" and is_instance_valid(player) and is_instance_valid(joystick):
  player.intent=joystick.vector if not paused else Vector2.ZERO
  player.enabled=not paused
  var camera_view:=get_viewport().get_visible_rect().size/camera.zoom
  var animation_rect:=Rect2(camera.get_screen_center_position()-camera_view/2,camera_view).grow(90)
  for i in range(1,actors.size()):
   var resident:=actors[i]
   var distance:=resident.position.distance_to(player.position)
   resident.enabled=not paused and distance<850 and not adventure.in_mission
   resident.npc_render_visible=animation_rect.has_point(resident.position)
   resident.npc_attention=distance<(70 if resident.npc_attention else 48)
   if resident.enabled and not resident.npc_attention:
    for j in range(1,i):
     if resident.position.distance_squared_to(actors[j].position)<24*24:resident.npc_driver.pause_near_resident();break
  if not adventure.in_mission:
   for i in range(1,actors.size()):sound.update_npc_steps(i,actors[i].position,actors[i].npc_walking,player.position)
  sound.update_steps(player.position,not paused and player.velocity.length()>2 and player.transforming<=0,player.jar)

func _process(delta: float) -> void:
 if content_loading:return
 if save_thread != null and not save_thread.is_alive(): finish_save()
 if screen_name!="playing" or not is_instance_valid(player): return
 if is_instance_valid(adventure) and adventure.in_mission:
  adventure.update_mission_ui(delta)
  save_elapsed+=delta
  if save_elapsed>=8:save_progress(true)
  return
 if is_instance_valid(adventure):adventure.update_stats()
 if is_instance_valid(hud_map): hud_map.update_local(player.position,talked_to_elder)
 if is_instance_valid(quest_label): quest_label.text="마을 어른과 대화하기 (%d/1)" % (1 if talked_to_elder else 0)
 spell_button.disabled = paused or player.cooldown>0 or player.transforming>0 or not unlocked.has("jar")
 spell_button.text = ("둔갑 %.1f" % player.cooldown) if player.cooldown>0 else ("인간 복귀" if player.jar else "둔갑술")
 if spell_button.has_node("SkillBadge"):
  var badge: WooSkillBadge=spell_button.get_node("SkillBadge");badge.maximum=player.SPELL_COOLDOWN;badge.remaining=player.cooldown;badge.locked=not unlocked.has("jar")
 run_button.disabled = player.jar or paused
 place_label.text = "신비로운 그림 장터  ·  "+("밤" if world.time_of_day>0.3 and world.time_of_day<0.7 else "낮")
 if paused: return
 nearest_npc = -1
 var nearest_distance := 58.0
 for i in range(Layout.NPCS.size()):
  var npc := actors[i+1]
  npc.highlighted = false
  var distance := player.position.distance_to(npc.position)
  if distance<nearest_distance:
   nearest_distance = distance
   nearest_npc = i
 if nearest_npc>=0: actors[nearest_npc+1].highlighted = true
 nearest_painting=-1
 if player.position.distance_to(preload("res://scripts/worlds/catalog.gd").ENTRY)<100:nearest_painting=0
 near_practice=player.position.distance_to(preload("res://scripts/practice/layout.gd").DOOR)<80
 near_simulation=player.position.distance_to(preload("res://scripts/simulation/entrance.gd").DOOR)<72
 near_well = player.position.distance_to(Layout.WELL)<60
 interact_button.visible = near_simulation or near_practice or nearest_npc>=0 or near_well or nearest_painting>=0
 interact_button.text = "도술 모의전 입장" if near_simulation else ("도술 익히기 입장" if near_practice else ("그림 세계" if nearest_painting>=0 else ("대화" if nearest_npc>=0 else "우물 조사")))
 interact_button.add_theme_font_size_override("font_size",13 if near_practice else 18)
 hint.text = (str(Layout.NPCS[nearest_npc].name)+" · 대화 가능") if nearest_npc>=0 else ("항아리 둔갑 중 · 이동 속도 감소" if player.jar else "주민과 대화하거나 마을을 탐험하세요")
 if nearest_painting>=0:hint.text="그림 세계 · 세 개의 모험"
 if near_simulation:hint.text="도술 모의전 · 서버 없이 봇과 한 판"
 if near_practice:hint.text="도술 익히기 · 서버 없이 모든 도술 체험"
 if saved_indicator>0:
  saved_indicator -= delta
  if last_save_error != OK: hint.text = "저장 실패: 기기 저장 공간을 확인하세요"
 save_elapsed += delta
 if save_elapsed>=8: save_progress(true)

func go_back() -> void:
 if content_loading:
  if loading.failed:loading.dismiss_failure()
  return
 if screen_name=="practice" and is_instance_valid(practice):
  if is_instance_valid(modal):close_modal()
  else:practice.request_leave()
  return
 if screen_name=="seal" and is_instance_valid(seal_client):seal_client.back();return
 if is_instance_valid(adventure) and adventure.transitioning:return
 if is_instance_valid(modal):
  if modal_kind=="inventory":
   var bundle=modal.get_child(modal.get_child_count()-1)
   if bundle is WooBundleUI and is_instance_valid(bundle.inspector):bundle.close_inspector();return
  close_modal()
 elif screen_name=="playing": show_settings()
 else: show_settings()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE: go_back()
  elif event.keycode==KEY_SPACE: cast_spell()
  elif event.keycode==KEY_E: interact()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(sound):sound.set_backgrounded(true)
  if is_instance_valid(practice):practice.backgrounded=true;practice.stick.reset()
  if screen_name=="playing":
   save_progress()
   if not content_loading and not is_instance_valid(modal) and not (is_instance_valid(adventure) and adventure.transitioning): show_settings()
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_APPLICATION_RESUMED:
  if is_instance_valid(sound):sound.set_backgrounded(false)
  if is_instance_valid(practice):practice.backgrounded=false
  if loading_focus_hold and not content_loading and screen_name=="playing":loading_focus_hold=false;set_paused(false)
 elif what==NOTIFICATION_WM_GO_BACK_REQUEST: go_back()
 elif what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()
