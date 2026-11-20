extends Node
const D=preload("res://scripts/ui/design.gd")
const C=preload("res://scripts/survival/characters.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const Storage=preload("res://scripts/survival/storage.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const ButtonType=preload("res://scripts/woo/mobile_button.gd")
const SEOWON_LAYOUT=preload("res://scripts/survival/layout.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
## 2.0.34: 지금 경기의 맵 레이아웃(월하의 서원 / 서울 강남역).
var L: Script=SEOWON_LAYOUT
const Market=preload("res://scripts/survival/market.gd")
const LC=preload("res://scripts/ui/lobby_theme.gd")
const LCR=preload("res://scripts/ui/ui_palette.gd")
const LArt=preload("res://scripts/ui/lobby_art.gd")
const RoomIcon=preload("res://scripts/ui/room_icon.gd")
const RoomButton=preload("res://scripts/ui/metal_button.gd")
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
const TITLE_ART="res://assets/woo/title_bg.png"
const TITLE_IMAGE=Vector2(1846,852)
## The settings capsule already painted into the key art (relative to the image).
const TITLE_SETTINGS_CENTER=Vector2(.949,.073)
const TITLE_SETTINGS_EXTENT=Vector2(.086,.08)
const LOBBY_ART="res://assets/woo/lobby_bg.png"
const LOBBY_IMAGE=Vector2(1846,852)
## Controls already painted into the lobby key art, in image pixels (position/size).
## Native targets are laid over these rects, so they track the artwork at every aspect.
const LOBBY_HOTSPOTS={
 "codex":Rect2(34,202,96,119),
 "achievements":Rect2(34,391,96,119),
 "shop":Rect2(34,580,96,120),
 "quick":Rect2(1144,244,692,212),
 "friends":Rect2(1148,458,674,136),
 "practice":Rect2(1262,641,238,77),
 "settings":Rect2(1554,641,240,77),
}
## 2.0.32: 우편·알림·설정 아이콘은 원화에 그려진 가짜 배지 대신 상단 HUD가 직접 그린다.
var lobby_hotspots: Dictionary={}
var lobby_hud: Control
var storage: RefCounted
var sound: WooSound
var layer: CanvasLayer
var fog_layer: CanvasLayer
var fog: TextureRect
## 2.0.30 시야 연출 레이어(월드 위, HUD 아래). 시야 좁히기·등불끄기 안개가 여기에 그려진다.
var vision_layer: CanvasLayer
var vision: Control
var ui: Control
var content: Control
var modal: Control
var screen:="title"
var generation:=0
var changing:=false
var room: Dictionary={}
var rules: RefCounted
var world: Node2D
var nav: RefCounted
var camera: Camera2D
var avatars: Dictionary={}
var clones: Dictionary={}
var bots: Array=[]
var stick: TouchJoystick
var timer_label: Label
var status_label: Label
var count_label: Label
var circle_label: Label
var stamina_label: Label
var action_button: WooMobileButton
var run_button: WooMobileButton
var jump_button: WooMobileButton
var skill_button: WooMobileButton
var skill_badge: WooSkillBadge
## 2.0.28: 범용 '상호작용' 버튼을 없앴다. 행동이 실제로 가능한 순간에만
## 그 자리에 전용 버튼(구출 / 둔갑 / 확인)이 하나씩 나타난다.
## 2.0.30: 건물 문은 늘 열려 있어 문 열기 버튼 없이 그냥 걸어 드나든다.
var rescue_button: WooMobileButton
var disguise_button: WooMobileButton
var gimmick_button: WooMobileButton
var cctv_view: Control
var rescue_markers: Control
var confirm_button: WooMobileButton
var action_buttons: Dictionary={}
## 2.0.27: 대표·보조·궁극기 세 버튼과 각 배지.
var skill_buttons: Dictionary={}
var skill_badges: Dictionary={}
var ult_button: WooMobileButton
## 도감 통합 화면이 처음 보여 줄 진영 탭(all/daoist/yokai).
var codex_filter:="all"
## 전체 지도 오버레이(닫기 버튼·바깥 클릭·Esc로 닫힌다).
var map_overlay: Control
## 지도를 연/닫은 직후의 입력을 삼키는 시각(ms). 전체 지도를 여는 그 손가락이
## 곧바로 어두운 배경(닫기)으로도 전달돼 '눌러도 안 열리는' 것처럼 보이던 문제를 막는다.
var map_guard_msec:=0
var minimap: Control
var survivor_label: Label
var seal_label: Label
var form_label: Label
var hint_label: Label
var action_caption: Label
var action_badge: WooSkillBadge
## 둔갑 가능 표시: 상호작용 버튼 뒤 금빛 링.
var form_pulse: Panel
## 상단 HUD(초상화·하트·기력·참가자 목록·알림 배너).
var hud_view: Control
var banner_left:=0.0
## 2.0.34 안전구역 밖 경고 펄스음 간격.
var warning_sound_left:=0.0
var banner_name:=""
var banner_kind:=""
var zone_stage_seen:=-1
var event_cursor:=0
var paused:=false
var backgrounded:=false
var bot_clock:=0.0
var fixed_clock:=0.0
## 인게임 고정 스텝: 20Hz(0.05)에서 60Hz(1/60)로 올려 이동이 끊기지 않게 한다.
const STEP=1.0/60.0
## 캐릭터 원화 배율. 2.0.19에서 LoL식 비율(돌길 폭·한옥 문/계단·항아리·석등)에
## 맞춰 1.12 → 1.05로 미세 조정했다. 모바일에서 식별되는 크기는 유지한다.
const ACTOR_SCALE=1.05
## 화면상 위치는 60Hz 목표점을 매 프레임 부드럽게 따라간다(텔레포트만 즉시 붙는다).
const AVATAR_FOLLOW=26.0
## 한 프레임 이동(최대 210px/s)보다 큰 이동은 텔레포트로 보고 즉시 붙인다.
const AVATAR_SNAP=40.0
var spectate:="human"
var aim:=Vector2.ZERO
var aim_cancelled:=false
var aim_slot:="main"
var render_clock:=0.0
var last_count:=-1
var selection_team:="daoist"
## 희망 진영: any / daoist / yokai. 매칭·대기실에서 고르고 rules.start()가 배정에 반영한다.
var preferred_role:="any"
var selection_id:=""
var selection_return:="lobby"
var status_message:=""
var sequence:=0
var result_seen:=false
var recorded:=false
## 2.0.32 매치 보상 내역(코인·보석). 결과 화면이 그대로 보여 준다.
var last_reward: Dictionary={}
var practice: Node
var selection_view: Node
var settings: Dictionary={"low_effects":false}
var matching:=0.0
var match_slots:=0
var room_code:=""
var code_input: LineEdit
var sensitivity:=1.0
const GOLD=D.GOLD
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 storage=Storage.new();sound=preload("res://scripts/woo/sound.gd").new();add_child(sound)
 layer=CanvasLayer.new();layer.layer=3;add_child(layer)
 fog_layer=CanvasLayer.new();fog_layer.layer=2;add_child(fog_layer)
 vision_layer=CanvasLayer.new();vision_layer.layer=1;add_child(vision_layer)
 vision=preload("res://scripts/survival/vision_overlay.gd").new();vision.visible=false;full(vision,vision_layer)
 fog=TextureRect.new();fog.texture=preload("res://assets/woo/seowon/vignette.png");fog.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;fog.stretch_mode=TextureRect.STRETCH_SCALE;fog.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(fog,fog_layer);fog.visible=false
 for bus in ["DosaMusic","DosaSfx"]:
  if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
 sound.music.bus="DosaMusic"
 for voice in sound.voices:voice.bus="DosaSfx"
 apply_settings();build("title")
 if storage.error!="":call_deferred("notice",storage.error)
 get_viewport().size_changed.connect(safe_layout)
func apply_settings() -> void:
 for spec in [["DosaMusic",storage.data.music,storage.data.get("music_mute",false)],["DosaSfx",storage.data.sfx,storage.data.get("sfx_mute",false)]]:
  var index:=AudioServer.get_bus_index(spec[0]);AudioServer.set_bus_mute(index,bool(spec[2]) or float(spec[1])<=.001);AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.001,float(spec[1]))))
func pill(node: Label,color: Color=Color(.03,.04,.09,.55),radius: int=10) -> void:
 var style:=D.panel(color,radius);style.border_color=Color(GOLD,.3);style.set_border_width_all(1);style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=2;style.content_margin_bottom=2
 node.add_theme_stylebox_override("normal",style)
 node.add_theme_color_override("font_outline_color",Color(.02,.02,.05));node.add_theme_constant_override("outline_size",2)
func text(value: String,font_size: int=22,color: Color=D.TEXT) -> Label:
 var node:=Label.new();node.text=value;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;node.add_theme_font_override("font",D.FONT);node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",color);return node
func button(value: String,callback: Callable,primary: bool=false,parent: Node=null,type: Script=ButtonType) -> WooMobileButton:
 var b: WooMobileButton=type.new();b.text=value;b.custom_minimum_size=Vector2(130,58);b.add_theme_font_override("font",D.FONT);b.add_theme_font_size_override("font_size",22)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style:=D.button_style(state,primary)
  style.bg_color=Color("43305d") if primary and state=="normal" else style.bg_color
  style.set_corner_radius_all(14);style.set_border_width_all(2 if primary else 1);b.add_theme_stylebox_override(state,style)
 b.add_theme_color_override("font_color",Color("fff0ce") if primary else D.TEXT)
 var ticket:=generation;var scope: Control=modal
 b.allowed=func()->bool:return ticket==generation and not changing and (modal==scope) and not backgrounded
 button_feel(b)
 b.pressed.connect(func()->void:
  if b.usable():sound.play_clip("button");callback.call())
 if parent!=null:parent.add_child(b)
 return b
## 모든 버튼의 눌림 스케일·금빛 글로우·클릭음을 한 곳에서 맞춘다.
func button_feel(b: WooMobileButton) -> void:
 var ring:=Panel.new();ring.name="PressGlow";ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style:=D.panel(Color(0,0,0,0),16);style.border_color=Color(GOLD,.95);style.set_border_width_all(2)
 style.content_margin_left=0;style.content_margin_right=0;style.content_margin_top=0;style.content_margin_bottom=0
 ring.add_theme_stylebox_override("panel",style)
 ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ring.modulate.a=0.0
 b.add_child(ring)
 b.resized.connect(func()->void:b.pivot_offset=b.size*.5)
 b.button_down.connect(func()->void:
  b.modulate=Color(1.2,1.15,1.25);if_vibrate()
  b.pivot_offset=b.size*.5
  var squeeze:=b.create_tween();squeeze.tween_property(b,"scale",Vector2(.95,.95),.07)
  var light:=ring.create_tween();light.tween_property(ring,"modulate:a",.85,.06))
 b.button_up.connect(func()->void:
  b.modulate=Color.WHITE
  var release:=b.create_tween();release.tween_property(b,"scale",Vector2.ONE,.14).set_trans(Tween.TRANS_BACK)
  var light:=ring.create_tween();light.tween_property(ring,"modulate:a",0.0,.2))
func if_vibrate() -> void:
 if storage.data.vibration and OS.get_name()=="Android":Input.vibrate_handheld(15)
func full(node: Control,parent: Node) -> void:parent.add_child(node);node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func background() -> void:
 # 로비 하위 화면과 같은 달빛 한옥 배경을 쓴다.
 var art:=LArt.Backdrop.new()
 art.mood=.7
 full(art,ui)
 ui.move_child(art,0)
func clear_ui() -> void:
 generation+=1
 if is_instance_valid(ui):D.retire_inputs(ui);ui.hide();ui.queue_free()
 modal=null;ui=Control.new();full(ui,layer);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var margin:=MarginContainer.new();full(margin,ui);margin.add_theme_constant_override("margin_left",32);margin.add_theme_constant_override("margin_right",32);margin.add_theme_constant_override("margin_top",22);margin.add_theme_constant_override("margin_bottom",22);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;content=margin
func page(title: String) -> VBoxContainer:
 background()
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);content.add_child(box)
 var heading:=text(title,32,LC.GOLD_SOFT);heading.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"));box.add_child(heading)
 var rule_line:=ColorRect.new();rule_line.color=Color(0.85,0.72,0.47,0.28);rule_line.custom_minimum_size.y=1;box.add_child(rule_line)
 return box
func panel(parent: Node) -> VBoxContainer:
 var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",LC.panel_box(Color(0.035,0.043,0.085,0.92),12,Color(0.85,0.72,0.47,0.42),1));parent.add_child(frame);frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var trim:=LArt.Filigree.new();trim.color=Color(0.85,0.72,0.47,0.38);trim.arm=18.0;frame.add_child(trim)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);frame.add_child(box);return box
func portrait(parent: Node,id: String,extent: Vector2=Vector2(330,360)) -> Control:
 var holder:=Control.new();holder.custom_minimum_size=extent;holder.size_flags_vertical=Control.SIZE_EXPAND_FILL;holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL;holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(holder)
 var actor:=Actor.new();actor.network_remote=true;actor.cosmetic=C.look(id);actor.collision_layer=0;actor.collision_mask=0;actor.scale=Vector2.ONE*minf(4.4,extent.y/72);holder.add_child(actor);actor.ingame_art=true;actor.art_id=C.fallback_art(id.trim_prefix("yokai:").trim_prefix("daoist:"));actor.skin_tint=Market.skin_color(storage.equipped("skin")).lerp(Color.WHITE,.45)
 holder.resized.connect(func()->void:
  actor.position=Vector2(holder.size.x/2,holder.size.y*.85)
  actor.scale=Vector2.ONE*minf(7.2,holder.size.y/72.0))
 actor.position=Vector2(extent.x/2,extent.y*.85)
 return holder
func transition(destination: String) -> void:
 if changing:return
 changing=true;D.cancel_controls(ui)
 var ticket:=generation
 var tween:=create_tween();tween.tween_property(ui,"modulate:a",0.0,.15);await tween.finished
 if not is_inside_tree() or ticket!=generation:changing=false;return
 build(destination);ui.modulate.a=0
 var intro:=create_tween();intro.tween_property(ui,"modulate:a",1.0,.15);await intro.finished;changing=false
func build(destination: String) -> void:
 clear_ui();screen=destination
 if is_instance_valid(fog):fog.visible=destination=="match"
 if is_instance_valid(vision):
  vision.visible=false
  vision.rules=rules if destination=="match" else null
 if is_instance_valid(sound):sound.set_context("match" if destination=="match" else "menu")
 match destination:
  "title":title_screen()
  "nickname":nickname_screen()
  "lobby":lobby_screen()
  "rooms":rooms_screen()
  "quick":quick_screen()
  "friends":friends_screen()
  "market":market_screen()
  "achievements":achievements_screen()
  "mail":mail_screen()
  "alerts":alerts_screen()
  "room":room_screen()
  "characters":characters_screen()
  "selection":selection_screen()
  "loading":loading_screen()
  "match":hud()
  "result":result_screen()
 safe_layout()
func title_background() -> void:
 var night:=ColorRect.new();night.color=Color(.22,.16,.28);night.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(night,ui)
 var art:=TextureRect.new();art.texture=load(TITLE_ART);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(art,ui)
func title_screen() -> void:
 title_background()
 # Full-screen native start target; the painted controls stay above it.
 var start:=button("",enter_from_title);full(start,ui)
 for state in ["normal","pressed","hover","hover_pressed"]:start.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 var view:=get_viewport().get_visible_rect().size
 var scale:=minf(view.x/TITLE_IMAGE.x,view.y/TITLE_IMAGE.y)
 var shown:=TITLE_IMAGE*scale
 var center:=(view-shown)/2+TITLE_SETTINGS_CENTER*shown
 var extent:=TITLE_SETTINGS_EXTENT*shown+Vector2(16,16)
 # Invisible native target exactly over the painted gear capsule.
 var settings:=button("설정",show_settings)
 settings.custom_minimum_size=Vector2.ZERO
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:settings.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:settings.add_theme_color_override(state,Color(0,0,0,0))
 ui.add_child(settings)
 settings.position=center-extent/2;settings.size=extent
 ui.move_child(start,0)
## 타이틀에서 게임 시작: 닉네임을 아직 정하지 않았으면 먼저 닉네임 설정 화면으로 간다.
func enter_from_title() -> void:
 transition("lobby" if storage.has_nickname() else "nickname")
func display_name() -> String:
 var chosen: String=String(storage.nickname())
 return chosen if chosen!="" else "나"
## 2.0.32 최초 진입 닉네임 설정. 2.0.25 시안과 같은 달빛 한옥 + 금테 판 + 금빛 세리프 제목
## + 먹빛 입력칸 + 금빛 버튼으로 만들고, 친구 방·결과 화면·로비 상단 프로필에 그대로 쓴다.
var nickname_edit:=false
var nickname_input: LineEdit
var nickname_hint: Label
var nickname_suggest: Array=[]
const NICKNAME_SUGGESTIONS=["달빛도사","서원지기","밤새는전우치","매화검객","한지붕도사","달그림자","안개술사","종이호랑이"]
func nickname_screen() -> void:
 var V=preload("res://scripts/ui/ui_v25.gd")
 var view:=get_viewport().get_visible_rect().size
 var s:=clampf(view.y/720.0,.5,3.0)
 var dw:=view.x/s
 # 2.0.25 시안과 같은 달빛 한옥 배경(가짜 숫자·레벨이 없는 순수 아트) + 금테 먹색 판.
 var backdrop:=LArt.Backdrop.new()
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.set("mood",1.18)
 backdrop.set("shade_strength",0.10)
 backdrop.set("lattice_on",false)
 backdrop.set("warm_strength",0.10)
 backdrop.set("vignette_strength",0.38)
 backdrop.set("dim_strength",0.42)
 ui.add_child(backdrop)
 var dim:=ColorRect.new();dim.color=Color(0.015,0.018,0.045,0.36);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(dim);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var panel_rect:=Rect2((dw-800.0)*.5,70.0,800.0,580.0)
 var glow:=Panel.new();glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
 glow.add_theme_stylebox_override("panel",LC.panel_box(Color(0.05,0.055,0.115,0.94),20,Color(0.85,0.72,0.47,0.55),1,Color(0.55,0.45,1.0,0.20),24))
 ui.add_child(glow);glow.position=panel_rect.position*s;glow.size=panel_rect.size*s
 var frame:=V.frame(ui,Rect2(Vector2.ZERO,panel_rect.size))
 frame.name="NicknameFrame";frame.modulate=Color(1,1,1,0.55)
 frame.position=panel_rect.position*s;frame.size=panel_rect.size*s
 var trim:=LArt.Filigree.new();trim.color=Color(0.85,0.72,0.47,0.55);trim.arm=30.0
 ui.add_child(trim);trim.set_anchors_preset(Control.PRESET_TOP_LEFT);trim.position=panel_rect.position*s;trim.size=panel_rect.size*s
 var center:=panel_rect.position.x+panel_rect.size.x*.5
 var title_text:="닉네임 바꾸기" if nickname_edit else "도호를 정하세요"
 var title:=text(title_text,50,LC.GOLD_SOFT);title.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.position=Vector2(panel_rect.position.x,panel_rect.position.y+44)*s;title.size=Vector2(panel_rect.size.x,64)*s
 title.add_theme_font_size_override("font_size",maxi(16,int(50*s)))
 ui.add_child(title)
 ui.add_child(nickname_rule(Vector2(center-150,panel_rect.position.y+118),Vector2(300,2),s))
 var lead:="게임에서 부를 이름입니다. 친구 방과 결과 화면에도 이 이름이 보입니다." if not nickname_edit else "새로 부를 이름을 정해 주세요."
 var lead_label:=text(lead,17,Color(0.82,0.85,0.95));lead_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 lead_label.position=Vector2(panel_rect.position.x+40,panel_rect.position.y+132)*s;lead_label.size=Vector2(panel_rect.size.x-80,26)*s
 lead_label.add_theme_font_size_override("font_size",maxi(10,int(17*s)))
 ui.add_child(lead_label)
 nickname_input=LineEdit.new()
 nickname_input.name="NicknameInput"
 nickname_input.max_length=10
 nickname_input.placeholder_text="2~10자 · 한글·영문·숫자"
 nickname_input.text=storage.nickname()
 nickname_input.alignment=HORIZONTAL_ALIGNMENT_CENTER
 nickname_input.add_theme_font_override("font",LC.FONT)
 nickname_input.add_theme_font_size_override("font_size",maxi(12,int(28*s)))
 nickname_input.add_theme_color_override("font_color",Color("f6efdf"))
 nickname_input.add_theme_color_override("font_placeholder_color",Color(0.72,0.74,0.86,0.6))
 nickname_input.add_theme_color_override("caret_color",Color("f2cf8e"))
 var input_box:=LC.panel_box(Color(0.055,0.045,0.10,0.97),10,Color(0.85,0.72,0.47,0.8),2)
 input_box.content_margin_left=18;input_box.content_margin_right=18;input_box.content_margin_top=8;input_box.content_margin_bottom=8
 nickname_input.add_theme_stylebox_override("normal",input_box)
 var focus_box:=input_box.duplicate() as StyleBoxFlat
 focus_box.bg_color=Color(0.085,0.070,0.145,0.98)
 focus_box.border_color=Color(1.0,0.88,0.60,0.95)
 nickname_input.add_theme_stylebox_override("focus",focus_box)
 nickname_input.text_submitted.connect(func(_text: String)->void:submit_nickname())
 ui.add_child(nickname_input)
 nickname_input.position=Vector2(center-232,panel_rect.position.y+180)*s;nickname_input.size=Vector2(464,68)*s
 nickname_hint=text("",15,Color("ff9b8a"));nickname_hint.name="NicknameHint";nickname_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 nickname_hint.position=Vector2(panel_rect.position.x+40,panel_rect.position.y+256)*s;nickname_hint.size=Vector2(panel_rect.size.x-80,24)*s
 nickname_hint.add_theme_font_size_override("font_size",maxi(9,int(15*s)))
 ui.add_child(nickname_hint)
 var pick: Label=text("추천 이름",14,Color(0.76,0.78,0.90));pick.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 pick.position=Vector2(panel_rect.position.x+40,panel_rect.position.y+290)*s;pick.size=Vector2(panel_rect.size.x-80,20)*s
 pick.add_theme_font_size_override("font_size",maxi(9,int(14*s)))
 ui.add_child(pick)
 nickname_suggest=[]
 var picks: Array=NICKNAME_SUGGESTIONS.duplicate()
 picks.shuffle()
 for i in range(3):
  var suggestion:=String(picks[i])
  var chip:=nickname_plate(suggestion,func()->void:nickname_input.text=suggestion;nickname_input.grab_focus();nickname_hint.text="",false)
  chip.name="NicknameSuggestion%d"%i
  chip.position=Vector2(center-312.0+i*212.0,panel_rect.position.y+316)*s
  chip.size=Vector2(190,46)*s
  nickname_suggest.append(chip)
 var submit:=nickname_plate("이름 정하고 시작하기" if not nickname_edit else "이 이름으로 저장",submit_nickname,true)
 submit.name="NicknameSubmit"
 submit.position=Vector2(center-200,panel_rect.position.y+392)*s;submit.size=Vector2(400,64)*s
 var foot:=text("인게임 이름표는 캐릭터 이름으로 표시됩니다 · 최초 설정",13,Color(0.70,0.72,0.84))
 foot.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 foot.position=Vector2(panel_rect.position.x+40,panel_rect.position.y+482)*s;foot.size=Vector2(panel_rect.size.x-80,20)*s
 foot.add_theme_font_size_override("font_size",maxi(9,int(13*s)))
 ui.add_child(foot)
 if nickname_edit:
  var cancel:=nickname_plate("취소",func()->void:nickname_edit=false;transition("lobby"),false)
  cancel.name="NicknameCancel"
  cancel.position=Vector2(center-90,panel_rect.position.y+512)*s;cancel.size=Vector2(180,40)*s
 if not OS.has_feature("mobile"):nickname_input.grab_focus()

## 닉네임 화면용 금빛/어두운 9-slice 판 버튼(2.0.25 상점·대기실과 같은 질감).
func nickname_plate(caption: String,action: Callable,primary: bool) -> WooMobileButton:
 var V=preload("res://scripts/ui/ui_v25.gd")
 var node: WooMobileButton=V.PlateButton.new()
 node.text=caption
 node.kind="gold" if primary else "dark"
 node.font_size=22 if primary else 17
 node.custom_minimum_size=Vector2.ZERO
 node.name="NicknamePlate"
 node.allowed=func()->bool:return not changing and modal==null
 node.pressed.connect(func()->void:
  if node.usable():sound.play_clip("button");action.call())
 ui.add_child(node)
 node.custom_minimum_size=Vector2.ZERO
 button_feel(node)
 return node

## 화면 제목 아래 금빛 장식선.
func nickname_rule(at: Vector2,extent: Vector2,scale_value: float) -> Control:
 var node:=Control.new()
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.position=at*scale_value
 node.size=extent*scale_value
 var draw:=func()->void:
  var y:=node.size.y*.5
  node.draw_line(Vector2(0,y),Vector2(node.size.x,y),Color(0.85,0.72,0.47,0.55),1.6,true)
  LC.diamond(node,Vector2(node.size.x*.5,y),4.0*scale_value,Color(0.85,0.72,0.47,0.8))
 node.draw.connect(draw)
 return node

func submit_nickname() -> void:
 if nickname_input==null:return
 var message:=Storage.nickname_error(nickname_input.text)
 if message!="":
  nickname_hint.text=message
  nickname_input.grab_focus();return
 storage.set_nickname(nickname_input.text)
 if storage.save()!=OK:notice("닉네임을 저장하지 못했습니다.");return
 # 내 플레이어 표시 이름(친구 방·결과 화면)도 새 닉네임으로 맞춘다.
 if rules!=null and rules.players.has("human"):rules.players.human.name=display_name()
 nickname_edit=false
 transition("lobby")
func open_nickname_edit() -> void:
 if changing:return
 # 설정 팝업에서 부르면 그 팝업을 닫고 수정 화면으로 간다(경기 중에는 열지 않는다).
 if modal!=null:close_popup()
 if screen not in ["lobby","rooms","title"]:return
 nickname_edit=true
 if screen=="lobby":transition("nickname")
 else:build("nickname")
func lobby_background() -> void:
 var night:=ColorRect.new();night.color=Color(.19,.14,.28);night.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(night,ui)
 var art:=TextureRect.new();art.texture=load(LOBBY_ART);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(art,ui)
## Transparent target laid exactly over a control painted into the lobby key art.
func lobby_hotspot(key: String,label: String,callback: Callable) -> void:
 var target:=button(label,callback)
 # The native label is only kept for the input/tests; clip it so the target keeps the painted size.
 target.name=key;target.clip_text=true;target.add_theme_font_size_override("font_size",11)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:target.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:target.add_theme_color_override(state,Color(0,0,0,0))
 ui.add_child(target)
 # Cleared after _ready, which otherwise pins the shared 112x64 mobile minimum.
 target.custom_minimum_size=Vector2.ZERO
 lobby_hotspots[key]=target
func lobby_layout() -> void:
 if screen!="lobby" or not is_instance_valid(ui):return
 var view:=get_viewport().get_visible_rect().size
 var scale:=minf(view.x/LOBBY_IMAGE.x,view.y/LOBBY_IMAGE.y)
 var origin:=(view-LOBBY_IMAGE*scale)/2
 for key in lobby_hotspots:
  var target: WooMobileButton=lobby_hotspots[key]
  if not is_instance_valid(target):continue
  # 우편·알림·설정은 상단 HUD가 스스로 배치한다.
  if not LOBBY_HOTSPOTS.has(key):continue
  var rect: Rect2=LOBBY_HOTSPOTS[key]
  target.position=origin+rect.position*scale;target.size=rect.size*scale
 if is_instance_valid(lobby_hud):lobby_hud.place_hud(origin,scale)
func lobby_screen() -> void:
 lobby_hotspots={}
 lobby_hud=null
 lobby_background()
 # 2.0.29: 그림의 캐릭터 메달을 지우고 도감·업적·상점 세 칸만 같은 간격으로 남겼다.
 lobby_hotspot("quick","빠른 매치",open_quick)
 lobby_hotspot("friends","친구와 함께",func()->void:transition("friends"))
 lobby_hotspot("practice","연습 (봇)",start_practice_match)
 lobby_hotspot("settings","설정",show_settings)
 lobby_hotspot("codex","도감",func()->void:open_codex("all"))
 lobby_hotspot("achievements","업적",func()->void:transition("achievements"))
 # 그림에는 상점으로 그려져 있고, 화면은 무료 마켓으로 연결된다.
 lobby_hotspot("shop","마켓",func()->void:transition("market"))
 # 2.0.32: 원화 위에 박혀 있던 가짜 지갑·LV·빨간 점 배지를 반투명 금테 HUD로 덮고
 # 그 자리에 storage.gd의 실제 값(초상화·이름·칭호·코인·보석·우편/알림 배지)을 띄운다.
 lobby_hud=preload("res://scripts/ui/lobby_hud.gd").new()
 lobby_hud.name="LobbyHud"
 ui.add_child(lobby_hud)
 lobby_hud.setup(self)
 lobby_hotspots["mail"]=lobby_hud.mail_button
 lobby_hotspots["alerts"]=lobby_hud.bell_button
 lobby_hotspots["gear"]=lobby_hud.gear_button
 lobby_layout()
 if not ui.resized.is_connected(lobby_layout):ui.resized.connect(lobby_layout)
## 지갑·배지가 실제 storage 값으로 맞도록 HUD만 다시 그린다.
func refresh_lobby_hud() -> void:
 if is_instance_valid(lobby_hud):lobby_hud.refresh()
## 우편 배지: 읽지 않았거나 보상을 받지 않은 편지 수(전부 확인·수령하면 0).
func unread_mail_count() -> int:
 var count:=0
 for mail in Market.MAILS:
  var id:=String(mail.id)
  if not (storage.data.mail.read as Array).has(id) or not (storage.data.mail.claimed as Array).has(id):count+=1
 return count
## 알림 배지: 확인하지 않은 공지 수.
func unread_alert_count() -> int:
 var count:=0
 for alert in Market.ALERTS:
  if not (storage.data.alerts.read as Array).has(String(alert.id)):count+=1
 return count
## 로비 지갑의 + 버튼: 결제가 아니라 게임 안 획득처를 알려 준다.
func earn_guide(kind: String) -> void:
 if changing:return
 var gem:=kind=="gem"
 var box:=popup("보석 획득처" if gem else "코인 획득처")
 var lead:=text("경기·업적·우편 보상으로 모은 게임 재화입니다. 지금 값은 실제 지갑 값입니다.",17,Color(.86,.88,.96))
 lead.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(lead)
 var lines:=(["· 경기 승리 보너스","· 첫 경기·첫 승리 보너스","· 봉인 3회 보너스","· 우편 동봉 보상"] if gem else ["· 경기 참가·봉인·구출·생존 보상","· 경기 승리 보너스","· 업적 달성 보상","· 우편 동봉 보상"])
 for line in lines:
  box.add_child(text(String(line),17,Color(.93,.95,1.0)))
 box.add_child(text("현재 보유: 코인 %s · 보석 %s"%[comma(int(storage.data.coins)),comma(int(storage.data.gems))],20,D.GOLD))
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);box.add_child(row)
 row.add_child(button("업적 보기",func()->void:close_popup();transition("achievements"),true))
 row.add_child(button("우편 보기",func()->void:close_popup();transition("mail")))
 row.add_child(button("상점 열기",func()->void:close_popup();transition("market")))
 row.add_child(button("닫기",close_popup))
func rooms_screen() -> void:
 var box:=page("게임 방 · 로컬 테스트 방만 표시")
 var list:=panel(box);list.size_flags_vertical=Control.SIZE_EXPAND_FILL
 if room.is_empty():list.add_child(text("현재 생성된 테스트 방이 없습니다.",24))
 else:
  list.add_child(button("%s · %s · %d인 · %s"%[room.name,Maps.name_of(String(room.get("map","seowon"))),room.count,"경기 중" if rules!=null and rules.phase not in ["room","result"] else "대기 중"],func()->void:
   if rules!=null and rules.phase not in ["room","result"]:notice("이미 경기가 진행 중입니다.")
   else:transition("room"),true))
 var row:=HBoxContainer.new();box.add_child(row)
 row.add_child(button("방 만들기",room_dialog,true));row.add_child(button("빠른 입장",func()->void:
  if room.is_empty():notice("입장할 테스트 방이 없습니다. 방을 만들어 주세요.")
  else:transition("room")))
 row.add_child(button("새로고침",func()->void:build("rooms")));row.add_child(button("뒤로가기",func()->void:transition("lobby")))
func room_dialog() -> void:
 var box:=popup("게임 방 만들기")
 var name_input:=LineEdit.new();name_input.placeholder_text="방 이름";name_input.text="월하의 모의전";name_input.max_length=16;name_input.custom_minimum_size.y=56;name_input.add_theme_font_override("font",D.FONT);box.add_child(name_input)
 var count:=OptionButton.new();count.add_item("6인전 · 도사4 / 요괴2");count.add_item("8인전 · 도사6 / 요괴2");count.custom_minimum_size.y=56;count.add_theme_font_override("font",D.FONT);box.add_child(count)
 var bots_check:=CheckBox.new();bots_check.text="봇 자동 채우기";bots_check.button_pressed=true;bots_check.custom_minimum_size.y=56;bots_check.add_theme_font_override("font",D.FONT);box.add_child(bots_check)
 box.add_child(text("맵: %s · 오프라인"%Maps.name_of(String(room.get("map","seowon"))),20))
 box.add_child(button("확인",func()->void:create_room(name_input.text,6 if count.selected==0 else 8,bots_check.button_pressed),true));box.add_child(button("취소",close_popup))
func create_room(name_value: String,count: int,fill_bots: bool,code: String="",yokai: int=2,map_id: String="") -> void:
 close_popup();cleanup_match()
 var label_text: String=name_value.strip_edges() if name_value.strip_edges()!="" else "도술 모의전"
 var used_code: String=code if code.strip_edges()!="" else generate_code()
 ## 2.0.34: map_id를 주면 그 맵으로 고정한다(테스트·디버그). 비우면 설정/무작위.
 room={"name":label_text,"count":count,"fill":fill_bots,"code":used_code,"yokai":yokai,"map":map_id if map_id!="" else "seowon"}
 room_code=used_code;remember_code(used_code)
 setup_participants();transition("room")
func setup_participants(seed_value: int=0) -> void:
 ## 2.0.34: 빠른 매치는 두 맵(서원·강남역)을 무작위로 고른다. 테스트·디버그는
 ## room.map 또는 설정의 맵 지정으로 특정 맵을 강제할 수 있다.
 Maps.resolve(String(room.get("map","seowon")),null)
 room["map"]=Maps.current_id
 L=Maps.layout()
 rules=Rules.new(seed_value);rules.yokai_count=int(room.get("yokai",2));rules.preferred_role=preferred_role;rules.add("human",display_name(),storage.data.daoist,storage.data.yokai)
 rules.use_map(Maps.current_id)
 rules.players.human.skin=String(storage.equipped("skin"))
 if room.fill:
  var daoists: Array=C.catalog("daoist");var yokai: Array=C.catalog("yokai")
  # 2.0.33 봇 7명에게도 자연스러운 닉네임을 붙인다(중복 없음). 이름표는 '닉네임 [캐릭터명]' 형식.
  var nicknames: Array=Rules.bot_nicknames(room.count-1,seed_value)
  for i in range(1,room.count):rules.add("bot-%d"%i,String(nicknames[i-1]),String(daoists[i%daoists.size()].id),String(yokai[i%yokai.size()].id))
 result_seen=false;recorded=false;last_reward={};spectate="human";fixed_clock=0;bot_clock=0
## 카드·배너용 둥근 테두리 박스(내용 여백은 카드 크기에 맞춰 작게).
func box_style(fill: Color,radius: int,border: Color,width: int=1) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius)
 style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6
 return style
## 친구와 함께 · 대기실(2.0.20): 달빛 한옥 배경 위에 상단 바, 좌측 지도·희망 진영,
## 우측 2열 참가자 카드, 아래 준비/시작/나가기를 실제 노드로 배치한다.
## 그림은 lobby_art·room_glyphs가 그리는 노드이고, 버튼·복사·토글은 그대로 작동한다.
func room_button(value: String,callback: Callable,variant: String="metal",glyph_name: String="",width: int=0,height: int=54,parent: Node=null) -> Control:
 var b=RoomButton.new()
 b.text=value;b.variant=variant;b.glyph=glyph_name
 b.font_size=19 if variant!="gold" else 23
 b.use_title_font=variant=="gold"
 b.accent=LC.GOLD
 if width<=0:
  var measure: Font=LC.TITLE_FONT if b.use_title_font else LC.FONT
  width=int(measure.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,b.font_size).x)+(30 if glyph_name!="" else 0)+30
 b.custom_minimum_size=Vector2(width,height)
 var ticket:=generation;var scope: Control=modal
 b.allowed=func()->bool:return ticket==generation and not changing and (modal==scope) and not backgrounded
 b.pressed.connect(func()->void:
  if b.usable():sound.play_clip("button");callback.call())
 if parent!=null:parent.add_child(b)
 return b
func room_icon(glyph_name: String,extent: float,color: Color=Color("e8d5a6"),line: float=1.8) -> Control:
 var node=RoomIcon.new()
 node.glyph=glyph_name;node.tint=color;node.line=line
 node.custom_minimum_size=Vector2(extent,extent)
 node.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 return node
func room_rule(color: Color=Color(.85,.72,.47,.5)) -> Control:
 var line:=LArt.Rule.new();line.color=color
 line.custom_minimum_size=Vector2(0,9);line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return line
## 아이콘 + 글자 한 묶음(전황·머리글).
func room_info(glyph_name: String,label: String,extent: float=16,color: Color=Color(.78,.76,.90)) -> Control:
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",5);row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_child(room_icon(glyph_name,extent,Color(.88,.77,.52),1.7))
 row.add_child(text(label,14,color))
 return row
## 초록 체크 알약 `✓ 준비 완료`.
func room_ready_pill() -> Control:
 var pill:=PanelContainer.new()
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(.13,.45,.28,.96);style.border_color=Color(.66,.96,.78,.75)
 style.set_border_width_all(1);style.set_corner_radius_all(11)
 style.content_margin_left=7;style.content_margin_right=9;style.content_margin_top=2;style.content_margin_bottom=2
 pill.add_theme_stylebox_override("panel",style)
 pill.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",4);pill.add_child(row)
 row.add_child(room_icon("check",12,Color(.88,1,.92),2.0))
 row.add_child(text("준비 완료",11,Color(.92,1,.95)))
 return pill
## 방장 표시 `[방장]`.
func room_host_badge() -> Control:
 var badge:=PanelContainer.new()
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(.32,.23,.09,.92);style.border_color=Color(.95,.80,.45,.85)
 style.set_border_width_all(1);style.set_corner_radius_all(5)
 style.content_margin_left=5;style.content_margin_right=5;style.content_margin_top=0;style.content_margin_bottom=0
 badge.add_theme_stylebox_override("panel",style)
 badge.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 badge.add_child(text("[방장]",11,Color("ffe4a4")))
 return badge
## 상단 바: 등불 아이콘 · 붓글씨 제목 · 방 코드 금빛 알약 · 복사/초대/뒤로.
func room_header() -> Control:
 var bar:=LArt.RoomPanel.new()
 bar.fill_top=Color(.10,.085,.155,.94);bar.fill_bottom=Color(.032,.028,.062,.96)
 bar.radius=12.0;bar.arm=16.0;bar.pad=Vector2(14,8)
 bar.custom_minimum_size.y=68
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",9);bar.add_child(row)
 row.add_child(room_icon("lantern",32,Color("f7d99a"),1.8))
 var titles:=HBoxContainer.new();titles.add_theme_constant_override("separation",10)
 titles.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var title:=text(Maps.name_of(String(room.get("map","seowon")))+" · 친구 방",27,Color("f7e4b6"))
 title.add_theme_font_override("font",LC.TITLE_FONT)
 title.add_theme_color_override("font_outline_color",Color(0,0,0,.55));title.add_theme_constant_override("outline_size",5)
 titles.add_child(title)
 var subtitle:=text(String(room.get("name","")) if String(room.get("name",""))!="" else "달빛 모의전",13,Color(.80,.74,.92))
 subtitle.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 subtitle.add_theme_color_override("font_outline_color",Color(0,0,0,.45));subtitle.add_theme_constant_override("outline_size",3)
 titles.add_child(subtitle)
 row.add_child(titles)
 var gap:=Control.new();gap.custom_minimum_size.x=12;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(gap)
 var code=room_button("방 코드  "+String(room.get("code","")),func()->void:Copycode(),"capsule","copy",0,44,row)
 code.name="RoomCodeChip"
 code.font_size=17
 var copy=room_button("코드 복사",func()->void:Copycode(),"metal","copy",104,44,row)
 copy.name="RoomCopy"
 copy.font_size=17
 var invite=room_button("친구 초대",func()->void:Copyinvite(),"metal","invite",112,44,row)
 invite.name="RoomInvite"
 invite.font_size=17
 var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(spacer)
 var back_button=room_button("뒤로",func()->void:leave_room(),"metal","back",96,44,row)
 back_button.name="RoomBack"
 back_button.font_size=17
 return bar
## 좌측: 맵 지도 프리뷰 + 전황 + 희망 진영 3버튼.
func room_map_panel() -> Control:
 var panel:=LArt.RoomPanel.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=1.0
 panel.pad=Vector2(14,12)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
 var head:=HBoxContainer.new();head.add_theme_constant_override("separation",6);head.mouse_filter=Control.MOUSE_FILTER_IGNORE
 head.add_child(room_icon("lotus",20,Color(.94,.80,.52),1.6))
 var title:=text("《%s》"%Maps.name_of(String(room.get("map","seowon"))),21,LC.GOLD_SOFT)
 title.add_theme_font_override("font",LC.TITLE_FONT)
 head.add_child(title)
 box.add_child(head)
 box.add_child(room_rule())
 var preview:=LArt.Preview.new()
 preview.texture=load("res://assets/woo/seowon/map_preview.png")
 preview.custom_minimum_size=Vector2(0,200)
 preview.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(preview)
 var meta:=HBoxContainer.new();meta.add_theme_constant_override("separation",9);meta.mouse_filter=Control.MOUSE_FILTER_IGNORE
 meta.add_child(room_info("swords","도사 %d : 요괴 %d" % [int(room.count)-int(room.get("yokai",2)),int(room.get("yokai",2))],16,Color(.90,.86,.76)))
 var divider:=ColorRect.new();divider.color=Color(.85,.72,.47,.35);divider.custom_minimum_size=Vector2(1,16);divider.size_flags_vertical=Control.SIZE_SHRINK_CENTER;divider.mouse_filter=Control.MOUSE_FILTER_IGNORE;meta.add_child(divider)
 meta.add_child(room_info("clock","10분 생존전",16,Color(.90,.86,.76)))
 box.add_child(meta)
 var side_head:=HBoxContainer.new();side_head.add_theme_constant_override("separation",5);side_head.mouse_filter=Control.MOUSE_FILTER_IGNORE
 side_head.add_child(room_icon("lotus",15,Color(.92,.80,.54),1.6))
 side_head.add_child(text("희망 진영",15,Color("e9dfc6")))
 box.add_child(side_head)
 var sides:=HBoxContainer.new();sides.add_theme_constant_override("separation",8);box.add_child(sides)
 for spec in [["도사 희망","daoist","lotus"],["요괴 희망","yokai","fox"],["상관없음","any","shuffle"]]:
  var value:=String(spec[1])
  var picked:=preferred_role==value
  var target=room_button(String(spec[0]),func()->void:set_preferred_role(value),"lit" if picked else "metal",String(spec[2]),0,72,sides)
  target.name="Side_"+value
  target.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  target.font_size=17
  if picked:target.accent=Color("f2c878")
 box.add_child(text("※ 도사 6명 중 1명 · 요괴 2명 중 1명으로 배정됩니다",11,Color(.68,.70,.84,.85)))
 return panel
## 우측: 참가자 머리글 + 2열 4행 카드 8장.
func room_participants_panel() -> Control:
 var panel:=LArt.RoomPanel.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=1.55
 panel.pad=Vector2(14,12)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
 var head:=HBoxContainer.new();head.add_theme_constant_override("separation",6);head.mouse_filter=Control.MOUSE_FILTER_IGNORE
 head.add_child(room_icon("users",20,Color(.92,.80,.54),1.6))
 head.add_child(text("참가자 %d/%d" % [rules.players.size(),int(room.count)],20,Color("f7e4b6")))
 var head_spacer:=Control.new();head_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head_spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(head_spacer)
 head.add_child(room_icon("check",13,Color(.62,.92,.72),2.0))
 head.add_child(text("초록 배지 = 준비 완료",11,Color(.68,.90,.74)))
 box.add_child(head)
 box.add_child(room_rule())
 var grid:=GridContainer.new();grid.columns=2
 grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8)
 grid.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(grid)
 var order: Array=rules.players.values().duplicate()
 for index in range(int(room.count)):
  var entry: Dictionary={}
  if index<order.size():entry=order[index]
  grid.add_child(room_member_card(entry,index))
 return panel
## 아래: 준비 취소 · 게임 시작(금빛 CTA) · 방 나가기.
func room_actions() -> Control:
 var bar:=LArt.RoomPanel.new()
 bar.fill_top=Color(.075,.062,.12,.90);bar.fill_bottom=Color(.024,.020,.048,.94)
 bar.radius=12.0;bar.arm=14.0;bar.pad=Vector2(10,8)
 bar.custom_minimum_size.y=78
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);bar.add_child(row)
 var human_ready:=bool(rules.players.human.ready)
 var ready_button=room_button("준비 취소" if human_ready else "준비 완료",func()->void:rules.players.human.ready=not rules.players.human.ready;build("room"),"metal","cross" if human_ready else "check",0,58,row)
 ready_button.name="RoomReady"
 ready_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var start_button=room_button("게임 시작",start_match,"gold","swords",0,60,row)
 start_button.name="RoomStart"
 start_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;start_button.size_flags_stretch_ratio=1.45
 var leave_button=room_button("방 나가기",leave_room,"metal","exit",0,58,row)
 leave_button.name="RoomLeave"
 leave_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return bar
func room_screen() -> void:
 if room.is_empty():build("rooms");return
 var art:=LArt.RoomBackdrop.new()
 full(art,ui)
 ui.move_child(art,0)
 var margin:=MarginContainer.new();full(margin,ui)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);margin.add_child(column)
 column.add_child(room_header())
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(body)
 body.add_child(room_map_panel())
 body.add_child(room_participants_panel())
 column.add_child(room_actions())

## 참가자 카드 한 장: 원형 금테 초상화 · 이름 · [방장] · 희망 진영 · 준비 배지.
func room_member_card(entry: Dictionary,index: int) -> Control:
 var frame:=LArt.Card.new()
 frame.name="RoomCard_%d"%index
 var filled:=not entry.is_empty()
 var ready:=filled and bool(entry.get("ready",false))
 var host:=filled and String(entry.get("id",""))=="human"
 frame.filled=filled;frame.is_ready=ready;frame.host=host
 frame.edge=Color(.85,.72,.47,.34) if filled else Color(.58,.55,.72,.20)
 frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",9);frame.add_child(row)
 var portrait:=LArt.Portrait.new()
 portrait.custom_minimum_size=Vector2(68,68)
 portrait.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 portrait.crown=host
 if filled:
  var look: String=String(entry.get("choices",{}).get("daoist","daoist:woochi"))
  var spec: Dictionary=C.find(look)
  if String(spec.get("portrait",""))!="":portrait.path=String(spec.portrait)
 else:
  portrait.ring=Color(.62,.58,.78,.55);portrait.ghost=true
 row.add_child(portrait)
 var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 info.add_theme_constant_override("separation",1)
 row.add_child(info)
 var name_row:=HBoxContainer.new();name_row.add_theme_constant_override("separation",5);name_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 info.add_child(name_row)
 var nick:=text(String(entry.get("name","")) if filled else "빈 자리",18,Color("f5ead2") if filled else Color(.62,.60,.74))
 nick.add_theme_color_override("font_outline_color",Color(0,0,0,.5));nick.add_theme_constant_override("outline_size",3)
 name_row.add_child(nick)
 if host:name_row.add_child(room_host_badge())
 var side_text:="초대를 기다리는 중"
 if filled:
  side_text=side_name(preferred_role) if String(entry.get("id",""))=="human" else "상관없음"
 var side:=text(side_text,12,Color(.76,.74,.90) if filled else Color(.60,.58,.72,.85))
 info.add_child(side)
 if ready:
  row.add_child(room_ready_pill())
 return frame

func side_name(value: String) -> String:
 if value=="daoist":return "희망 · 도사"
 if value=="yokai":return "희망 · 요괴"
 return "희망 · 상관없음"

## 희망 진영을 저장하고 화면을 다시 그린다. 매칭·대기실·배정이 같은 값을 쓴다.
func set_preferred_role(value: String) -> void:
 preferred_role=value if value in ["daoist","yokai","any"] else "any"
 if rules!=null:rules.preferred_role=preferred_role
 if screen=="room":build("room")
 elif screen=="quick" and is_instance_valid(quick):quick.refresh_sides()

## 로비 → 통합 도감. 캐릭터 정보·스킬·도포 스킨 장착이 이 한 화면에 있다.
func open_codex(team: String="all") -> void:
 if changing:return
 codex_filter=team if team in ["all","daoist","yokai"] else "all"
 selection_return="lobby"
 transition("characters")
func characters_screen() -> void:
 var codex:=preload("res://scripts/survival/codex.gd").new()
 codex.game=self
 codex.initial=codex_filter
 full(codex,ui)
func start_match() -> void:
 if changing or screen!="room":return
 begin_match()
## 방에서 캐릭터 선택으로 넘어간다. 빠른 매치·연습 봇전도 같은 진입로를 쓴다.
func begin_match() -> bool:
 rules.yokai_count=int(room.get("yokai",2))
 if rules.players.size()!=room.count:notice("필요한 인원이 없습니다. 빈 칸을 봇으로 채워 주세요.");return false
 if not rules.players.human.ready:notice("먼저 준비 완료를 눌러 주세요.");return false
 if not rules.start():notice("캐릭터·봇 참가 상태를 확인하세요.");return false
 selection_team=rules.players.human.role
 # 해금한 캐릭터만 고를 수 있다. 자동 배정도 보유 목록 안에서만 고른다.
 var owned:=owned_characters(selection_team)
 if not owned.is_empty():rules.restrict_choices("human",owned)
 selection_id=storage.data[selection_team]
 if not owned.is_empty() and not owned.has(selection_id):selection_id=String(owned[0])
 rules.select_character("human",selection_id)
 build("selection")
 return true

func owned_characters(team: String) -> Array:
 var result: Array=[]
 for item in C.catalog(team):
  if storage.owns_character(String(item.id)):result.append(String(item.id))
 return result
func selection_screen() -> void:
 # 롤 스타일 직행 선택 화면: 왼쪽 카드 · 가운데 프리뷰 · 오른쪽 상세/확정.
 # 배정된 진영과 다른 팀 캐릭터가 선택되어 있으면 그 진영의 저장 캐릭터로 맞춘다.
 var role: String=String(rules.players.human.get("role","daoist"))
 if String(C.find(selection_id).get("team",""))!=role:
  selection_id=String(storage.data.get(role,""))
 if String(C.find(selection_id).get("team",""))!=role:
  var catalog: Array=C.catalog(role)
  selection_id=String(catalog[0].id) if not catalog.is_empty() else selection_id
 if not bool(rules.players.human.confirmed):rules.select_character("human",selection_id)
 var view:=preload("res://scripts/survival/selection_view.gd").new()
 view.game=self
 view.selection_id=selection_id
 view.locked=rules.players.human.confirmed
 # 2.0.27: 빠른 매치처럼 진영이 확정된 판은 상대 진영 탭·카드를 잠근다.
 view.role_locked=bool(room.get("quick",false)) or bool(room.get("practice",false))
 view.locked_team=role
 selection_view=view
 full(view,ui)
## 선택 확정: 팀 대표 캐릭터로 저장하고 화면을 다시 그린다.
func confirm_selection(id: String,_view: Node=null) -> void:
 selection_id=id
 if not rules.confirm_character("human"):return
 storage.data[rules.players.human.role]=id
 storage.save()
 build("selection")
## 2.0.23 매치 로딩: 달빛 서원 배경 위에 도사 6(금테) : 요괴 2(보랏빛) 대진 카드와 VS 문장,
## 금빛 진행 게이지·팁. 가로가 넓어도 대진은 가운데에 모인다.
func loading_screen() -> void:
 var V=preload("res://scripts/ui/ui_v25.gd")
 var view:=get_viewport().get_visible_rect().size
 var scale:=view.y/720.0
 var dw:=view.x/scale
 ui.set_meta("loading_dw",dw)
 var art:=TextureRect.new()
 art.texture=preload("res://assets/woo/codex/codex_bg.jpg")
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.modulate=Color(1.16,1.06,1.20,1.0)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 full(art,ui)
 var vignette:=TextureRect.new()
 vignette.texture=preload("res://assets/woo/seowon/vignette.png")
 vignette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;vignette.stretch_mode=TextureRect.STRETCH_SCALE
 vignette.modulate=Color(1,1,1,.42);vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
 full(vignette,ui)
 # 좌우 진영 판
 var left_rect:=Rect2(14,92,424,470)
 var right_rect:=Rect2(dw-14-330,92,330,470)
 var left_panel:=V.frame(ui,left_rect)
 left_panel.position=left_rect.position*scale
 left_panel.size=left_rect.size*scale
 V.refit(left_panel)
 left_panel.name="LoadingDaoistPanel"
 var right_panel:=V.patch(ui,V.TEX_PANEL,right_rect,64)
 right_panel.position=right_rect.position*scale
 right_panel.size=right_rect.size*scale
 V.refit(right_panel)
 right_panel.name="LoadingYokaiPanel"
 right_panel.modulate=Color(.92,.82,1.10,1.0)
 loading_team_header(left_rect,"도사 진영","안전구역 안에서 10분을 버티세요","lotus",Color(0.96,0.82,0.50),false)
 loading_team_header(right_rect,"요괴 진영","도사들을 방해하고 생존하세요","fox",Color(0.86,0.66,1.0),true)
 var daoist_members: Array=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")
 var yokai_members: Array=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")
 var count:=0
 for entry in daoist_members:
  var col:=count%3
  var row:=count/3
  loading_card(ui,entry,Rect2(left_rect.position.x+22+col*130,left_rect.position.y+74+row*166,118,152),Color(0.98,0.84,0.52),false)
  count+=1
 var index:=0
 for entry in yokai_members:
  loading_card(ui,entry,Rect2(right_rect.position.x+16+index*152,right_rect.position.y+78,140,258),Color(0.94,0.72,1.0),true)
  index+=1
 if yokai_members.is_empty():
  var empty:=text("배정 중…",18,Color(.82,.78,.94))
  empty.position=(right_rect.position+Vector2(96,180))*scale
  empty.size=Vector2(140,40)*scale
  ui.add_child(empty)
 # 가운데 VS 휘장과 경기 정보
 var center:=dw*0.5
 var versus:=TextureRect.new()
 versus.texture=V.TEX_VS
 versus.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;versus.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 versus.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(versus)
 versus.position=Vector2(center-150,196)*scale
 versus.size=Vector2(300,170)*scale
 var plaque:=V.patch(ui,V.TEX_WOOD,Rect2(Vector2.ZERO,Vector2(280,104)),56)
 plaque.name="LoadingPlaza"
 plaque.position=Vector2(center-140,352)*scale
 var plaque_title:=text(Maps.name(),26,Color("ffe4ae"))
 plaque_title.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 plaque_title.add_theme_constant_override("outline_size",5)
 plaque_title.add_theme_color_override("font_outline_color",Color(.06,.03,.02,.9))
 plaque_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui.add_child(plaque_title)
 plaque_title.position=Vector2(center-140,362)*scale
 plaque_title.size=Vector2(280,34)*scale
 var plaque_sub:=text(Maps.info().get("subtitle","")+" · 2대6 생존전",17,Color("e6d7b6"))
 plaque_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui.add_child(plaque_sub)
 plaque_sub.position=Vector2(center-140,398)*scale
 plaque_sub.size=Vector2(280,26)*scale
 # 하단 상태·게이지
 status_label=text(String(Maps.info().get("tip","달빛이 서원을 비춥니다…")),18,Color("f4e6c6"))
 status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status_label.add_theme_constant_override("outline_size",4)
 status_label.add_theme_color_override("font_outline_color",Color(.05,.03,.08,.9))
 full(status_label,ui)
 status_label.position=Vector2(0,560)*scale
 status_label.size=Vector2(view.x,30*scale)
 var bar_width:=minf(720.0,dw-240.0)
 var bar:=ProgressBar.new()
 bar.name="ResourceProgress";bar.max_value=100
 bar.position=Vector2(center-bar_width*.5,602)*scale
 bar.size=Vector2(bar_width,26)*scale
 bar.custom_minimum_size=Vector2.ZERO
 bar.show_percentage=false
 var track:=StyleBoxTexture.new()
 track.texture=V.TEX_GAUGE_TRACK
 track.set_texture_margin_all(14)
 var fillbox:=StyleBoxTexture.new()
 fillbox.texture=V.TEX_GAUGE
 fillbox.set_texture_margin_all(14)
 bar.add_theme_stylebox_override("background",track)
 bar.add_theme_stylebox_override("fill",fillbox)
 ui.add_child(bar)
 var map_banner:=text("이번 무대 · "+Maps.name()+"  |  "+String(Maps.info().get("subtitle","")),15,Color("ffe6b0"))
 map_banner.name="LoadingMapBanner"
 map_banner.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 map_banner.add_theme_color_override("font_outline_color",Color(.05,.03,.08,.9))
 map_banner.add_theme_constant_override("outline_size",4)
 map_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 full(map_banner,ui)
 map_banner.position=Vector2(0,470)*scale
 map_banner.size=Vector2(view.x,26*scale)
 var tip:=text("TIP · "+String(Maps.info().get("tip","요괴만 도사를 봉인할 수 있습니다.")),13.5,Color("d6d2e6"))
 tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 full(tip,ui)
 tip.position=Vector2(0,640)*scale
 tip.size=Vector2(view.x,24*scale)

## 대진표 머리글: 금테 메달 + 진영 이름 + 안내.
func loading_team_header(rect: Rect2,title: String,subtitle: String,glyph: String,accent: Color,yokai: bool) -> void:
 var scale:=get_viewport().get_visible_rect().size.y/720.0
 var medallion:=TextureRect.new()
 medallion.texture=preload("res://assets/ui/v25/medallion.png")
 medallion.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 medallion.stretch_mode=TextureRect.STRETCH_SCALE
 medallion.modulate=Color(.95,.88,1.0) if yokai else Color.WHITE
 medallion.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(medallion)
 medallion.position=Vector2(rect.position.x+18,rect.position.y+12)*scale
 medallion.size=Vector2(46,46)*scale
 var icon:=Control.new()
 icon.set_script(preload("res://scripts/ui/ui_v25.gd").Glyph)
 icon.set("glyph",glyph)
 icon.set("tint",accent)
 icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 medallion.add_child(icon)
 icon.position=Vector2(11,11)*scale
 icon.size=Vector2(24,24)*scale
 var heading:=text(title,25,accent)
 heading.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 heading.add_theme_constant_override("outline_size",5)
 heading.add_theme_color_override("font_outline_color",Color(.05,.03,.07,.9))
 ui.add_child(heading)
 heading.position=Vector2(rect.position.x+74,rect.position.y+12)*scale
 heading.size=Vector2(rect.size.x-90,34)*scale
 var sub:=text(subtitle,13,Color("e2dcf0") if yokai else Color("e6ddc6"))
 sub.clip_text=true
 ui.add_child(sub)
 sub.position=Vector2(rect.position.x+76,rect.position.y+44)*scale
 sub.size=Vector2(rect.size.x-92,20)*scale

## 대진표 카드 한 장: 초상 + 이름 명패.
func loading_card(parent: Node,entry: Dictionary,rect: Rect2,accent: Color,yokai: bool) -> Control:
 var V=preload("res://scripts/ui/ui_v25.gd")
 var scale:=get_viewport().get_visible_rect().size.y/720.0
 var holder:=V.patch(parent,V.TEX_CARD_LIT if not yokai else V.TEX_CARD,Rect2(Vector2.ZERO,rect.size),26)
 holder.position=rect.position*scale
 holder.size=rect.size*scale
 if yokai:holder.modulate=Color(.96,.88,1.12,1.0)
 var role:=String(entry.get("role","daoist"))
 var character:=String(entry.get("character",""))
 if character=="":character=String(entry.get("choices",{}).get(role,""))
 var spec: Dictionary=C.find(character)
 var portrait:=TextureRect.new()
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 holder.add_child(portrait)
 portrait.position=Vector2(7,7)*scale
 portrait.size=(rect.size-Vector2(14,42))*scale
 if String(spec.get("portrait",""))!="" and ResourceLoader.exists(String(spec.portrait)):portrait.texture=load(String(spec.portrait))
 var plate:=V.patch(holder,V.TEX_TILE,Rect2(rect.size.x-14,rect.size.y-40,rect.size.x-14,34),26)
 plate.position=Vector2(7,rect.size.y-39)*scale
 plate.size=Vector2(rect.size.x-14,32)*scale
 var name_value:=String(spec.get("name",""))
 if name_value=="":name_value=String(entry.get("name",""))
 var name_label:=text(name_value,16,Color("ffe6bc") if not yokai else Color("f0d8ff"))
 name_label.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 plate.add_child(name_label)
 name_label.position=Vector2(0,0)
 name_label.size=Vector2(rect.size.x-14,32)*scale
 return holder

func load_match(ticket: int) -> void:
 build("loading");changing=true
 await get_tree().process_frame;await get_tree().process_frame
 var world_path: String=Maps.scene_of()
 var paths: Array=[world_path]
 if Maps.current_id=="seowon":paths.append("res://assets/woo/seowon/seowon_ground.png")
 for path in paths:
  var error:=ResourceLoader.load_threaded_request(path)
  if error!=OK and error!=ERR_BUSY:load_error("맵 리소스 요청에 실패했습니다.");return
 var bar: ProgressBar=ui.find_child("ResourceProgress",true,false)
 for i in range(paths.size()):
  while ticket==sequence:
   var progress: Array=[];var state:=ResourceLoader.load_threaded_get_status(paths[i],progress)
   if state==ResourceLoader.THREAD_LOAD_FAILED or state==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:load_error("리소스 로딩에 실패했습니다.");return
   bar.value=(i+(float(progress[0]) if not progress.is_empty() else 0))/paths.size()*100
   if state==ResourceLoader.THREAD_LOAD_LOADED:ResourceLoader.load_threaded_get(paths[i]);break
   await get_tree().process_frame
 if ticket!=sequence:return
 bar.value=100;status_label.text="리소스 100% · 이동 경로와 충돌을 준비하는 중…"
 var arena:=preload("res://scripts/seal/arena.gd").new(Maps.arena_of());arena.assets.clear();arena.cache.clear()
 nav=preload("res://scripts/simulation/navigation.gd").new(arena,false);await nav.build(get_tree())
 if ticket!=sequence:return
 status_label.text="캐릭터·카메라·경기 HUD 준비 중…"
 world=load(world_path).new();world.rules=rules;add_child(world)
 camera=Camera2D.new();camera.zoom=Vector2(L.CAMERA_ZOOM,L.CAMERA_ZOOM);camera.position=L.SPAWN+Vector2(0,-L.CAMERA_LIFT);camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(L.SIZE.x);camera.limit_bottom=int(L.SIZE.y);world.add_child(camera);camera.make_current()
 bots.clear()
 for p in rules.players.values():
  if p.id!="human":bots.append(preload("res://scripts/survival/bot.gd").new(rules,nav,p.id,int(p.color)))
 update_avatars();await get_tree().process_frame
 if not is_instance_valid(camera) or not avatars.has("human"):load_error("참가자·카메라 초기화에 실패했습니다.");return
 if is_instance_valid(sound):sound.play_map_bgm(Maps.current_id)
 rules.ready_map();build("match");changing=false;paused=false;last_count=-1
func load_error(message: String) -> void:
 changing=false;cleanup_match();build("lobby");notice(message+"\n안전한 로비로 돌아왔습니다.")
func hud() -> void:
 var decor:=preload("res://scripts/survival/hud_decor.gd").new();full(decor,ui)
 hud_view=preload("res://scripts/survival/hud_status.gd").new();full(hud_view,ui)
 var hud_me: Dictionary=rules.players.human
 var hud_spec: Dictionary=C.find(hud_me.character)
 hud_view.portrait=load(String(hud_spec.get("portrait",""))) if String(hud_spec.get("portrait",""))!="" else null
 hud_view.character_name=String(hud_spec.get("name",""))
 var hud_skin_portrait:=SkillFX.portrait_for(String(hud_me.get("character","")),String(storage.equipped("skin")))
 if hud_skin_portrait!="" and ResourceLoader.exists(hud_skin_portrait):hud_view.portrait=load(hud_skin_portrait)
 hud_view.role=hud_me.role;hud_view.max_lives=rules.LIVES;hud_view.rules=rules
 hud_view.banner="%s · 도사 6·요괴 2 · 10분 생존"%Maps.name();hud_view.banner_alpha=1.0;banner_left=3.0
 timer_label=text(Maps.name()+" · 10:00",23,Color("f0d7a2"))
 ui.add_child(timer_label)
 timer_label.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 timer_label.offset_left=-224;timer_label.offset_right=224;timer_label.offset_top=10;timer_label.offset_bottom=42
 timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 survivor_label=text("생존 도사 6 · 요괴 2",16,Color("e9dfc6"))
 ui.add_child(survivor_label)
 survivor_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 survivor_label.offset_left=-224;survivor_label.offset_right=224;survivor_label.offset_top=42;survivor_label.offset_bottom=66
 survivor_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 seal_label=text("봉인 0 / 5",21,Color("f6e4b8"))
 ui.add_child(seal_label)
 seal_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 seal_label.offset_left=70;seal_label.offset_right=280;seal_label.offset_top=18;seal_label.offset_bottom=52
 seal_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 status_label=text("",17,Color("ffb3bb"))
 ui.add_child(status_label)
 status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 status_label.offset_left=14;status_label.offset_right=330;status_label.offset_top=122;status_label.offset_bottom=152
 pill(status_label,Color(.03,.04,.09,.55),10)
 status_label.add_theme_color_override("font_color",Color("ffd0d4"))
 # 2.0.31 상단 우측 정렬: 미니맵(-156~-6) 왼쪽에 설정(64폭)·메뉴(130폭)를 8px 간격으로
 # 실제 크기대로 배치한다. 기존 오프셋은 최소 크기보다 좁아 버튼이 서로/미니맵을 덮었다.
 var menu:=button("메뉴",pause_menu);menu.name="Menu";ui.add_child(menu)
 menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 menu.offset_left=-366;menu.offset_right=-236;menu.offset_top=14;menu.offset_bottom=58
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style:=D.panel(Color("141d33"),20);style.border_color=GOLD;style.set_border_width_all(1);style.content_margin_top=4;style.content_margin_bottom=4;style.content_margin_left=8;style.content_margin_right=8
  menu.add_theme_stylebox_override(state,style)
 menu.add_theme_color_override("font_color",Color("f0dcae"))
 var gear:=button("",show_settings);gear.name="Settings";gear.custom_minimum_size=Vector2(64,56);ui.add_child(gear)
 gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 gear.offset_left=-228;gear.offset_right=-164;gear.offset_top=14;gear.offset_bottom=58
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style:=D.panel(Color("141d33"),14);style.border_color=GOLD;style.set_border_width_all(1)
  gear.add_theme_stylebox_override(state,style)
 var gear_icon:=Node2D.new();gear_icon.position=Vector2(25,22);gear_icon.draw.connect(func()->void:
  for i in range(8):
   var angle:=i*TAU/8
   gear_icon.draw_line(Vector2.from_angle(angle)*8,Vector2.from_angle(angle)*11.5,Color("f0dcae"),3)
  gear_icon.draw_arc(Vector2.ZERO,8,0,TAU,22,Color("f0dcae"),2.4,true)
  gear_icon.draw_circle(Vector2.ZERO,3.4,Color("141d33")))
 gear.add_child(gear_icon)
 minimap=preload("res://scripts/survival/minimap.gd").new();minimap.rules=rules;minimap.observer="human";ui.add_child(minimap)
 minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 minimap.offset_left=-156;minimap.offset_right=-6;minimap.offset_top=8;minimap.offset_bottom=158
 minimap.map_requested.connect(show_map)
 ## 2.0.34 관리실 CCTV 실시간 미니 뷰(강남역에서만 값이 찬다).
 cctv_view=preload("res://scripts/survival/cctv_view.gd").new();cctv_view.rules=rules;cctv_view.observer="human"
 ui.add_child(cctv_view)
 cctv_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 cctv_view.offset_left=16;cctv_view.offset_right=252;cctv_view.offset_top=170;cctv_view.offset_bottom=340
 cctv_view.visible=false
 ## 2.0.34 봉인된 동료의 구출 필요 아이콘(머리 위·화면 밖 방향 마커).
 rescue_markers=preload("res://scripts/survival/rescue_markers.gd").new();rescue_markers.rules=rules
 ui.add_child(rescue_markers)
 rescue_markers.visible=false
 circle_label=text("",15,Color("cfd7ea"))
 ui.add_child(circle_label)
 circle_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 circle_label.offset_left=-300;circle_label.offset_right=-8;circle_label.offset_top=166;circle_label.offset_bottom=194
 circle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 pill(circle_label,Color(.03,.04,.09,.5),9)
 stick=preload("res://scripts/joystick.gd").new();ui.add_child(stick);D.position_stick(stick)
 stamina_label=text("달리기 100%",16,Color("cfd7ea"));ui.add_child(stamina_label);stamina_label.visible=false
 stamina_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 stamina_label.offset_left=26;stamina_label.offset_right=206;stamina_label.offset_top=-424;stamina_label.offset_bottom=-396
 pill(stamina_label,Color(.03,.04,.09,.5),9)
 run_button=action("달리기","dodge",Vector2(-440,-150),Vector2(120,120))
 run_button.button_down.connect(func()->void:rules.command("human","run",{"held":true}));run_button.button_up.connect(func()->void:rules.command("human","run",{"held":false}))
 jump_button=action("점프","jump",Vector2(-316,-150),Vector2(96,96),func()->void:
  if rules.command("human","jump"):sound.play_clip("jump"))
 var spec: Dictionary=C.find(rules.players.human.character)
 # 2.0.27: 대표 스킬 · 보조 스킬 · 궁극기 세 버튼. 궁극기는 기운이 차야 눌린다.
 skill_buttons={};skill_badges={}
 var layout: Array=[{"slot":"main","at":Vector2(-316,-262),"extent":96.0},{"slot":"sub","at":Vector2(-200,-262),"extent":96.0},{"slot":"ult","at":Vector2(-456,-296),"extent":132.0}]
 for entry in layout:
  var slot: String=String(entry.slot)
  var ability: Dictionary=C.ability(rules.players.human.character,slot)
  if ability.is_empty():continue
  var target:=action(String(ability.get("name","")),ability_hint(ability),entry.at,Vector2(entry.extent,entry.extent),Callable(),preload("res://scripts/survival/aim_button.gd"))
  target.directional=bool(ability.get("aim",false))
  target.name="Skill_"+slot
  target.ability.connect(func(direction: Vector2)->void:cast_slot(slot,direction))
  target.aimed.connect(func(direction: Vector2,cancelled: bool)->void:aim=direction;aim_cancelled=cancelled;aim_slot=slot)
  var caption: Label=target.get_node_or_null("Caption")
  if caption!=null:
   caption.position=Vector2(-16,-22) if slot=="ult" else Vector2(-6,-20)
   caption.text=("궁극기 · " if slot=="ult" else "")+String(ability.get("name",""))
  target.tip_requested.connect(func()->void:skill_tip(String(ability.get("name",""))+" — "+String(ability.get("description",""))))
  skill_buttons[slot]=target;skill_badges[slot]=target.get_node("Badge")
  if slot=="main":
   # 호환: 기존 코드·테스트가 참조하는 대표 스킬 버튼.
   skill_button=target;skill_badge=skill_badges[slot]
 ult_button=skill_buttons.get("ult")
 action_badge=null
 # 2.0.28: 평상시 떠 있는 범용 버튼은 없다. 아래 네 버튼은 필요한 순간에만 보인다.
 action_buttons={}
 if rules.players.human.role=="yokai":
  confirm_button=context_action("확인","confirm","capture")
  confirm_button.pressed.connect(func()->void:
   if rules.command("human","seal"):sound.play_clip("seal"))
 else:
  rescue_button=context_action("구출","rescue","rescue")
  rescue_button.button_down.connect(func()->void:
   var target:=rescue_target()
   if target!="":rules.command("human","rescue",{"target":target}))
  rescue_button.button_up.connect(func()->void:rules.command("human","cancel_rescue"))
  disguise_button=context_action("둔갑","disguise","jar")
  disguise_button.pressed.connect(func()->void:rules.command("human","interact"))
 ## 2.0.34 강남역 전용 기믹 버튼(가까운 기믹이 있을 때만 나타난다).
 gimmick_button=context_action("기믹","gimmick","gear")
 gimmick_button.pressed.connect(func()->void:
  var near: Dictionary=rules.gimmicks.entry_at(rules.players.human.position,72.0) if rules.gimmicks!=null else {}
  var kind_g: String=String(near.get("kind",""))
  if not rules.command("human","gimmick"):return
  var clip_g: String="ui_tap"
  if kind_g=="turnstile":clip_g="gimmick_turnstile"
  elif kind_g=="cctv":clip_g="gimmick_cctv"
  elif kind_g=="shutter":clip_g="gimmick_shutter"
  elif kind_g=="light":clip_g="gimmick_lights_on" if rules.gimmicks.zone_dark(String(near.get("zone",""))) else "gimmick_lights_off"
  elif kind_g=="vending":clip_g="ui_tap"
  sound.play_clip(clip_g))
 # 둔갑 가능할 때 상호작용 버튼 뒤에서 금빛으로 숨 쉬는 링.
 form_pulse=Panel.new();form_pulse.name="FormPulse";form_pulse.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var pulse_style:=D.panel(Color(0,0,0,0),48);pulse_style.border_color=Color(1,.84,.42,.95);pulse_style.set_border_width_all(3)
 pulse_style.content_margin_left=0;pulse_style.content_margin_right=0;pulse_style.content_margin_top=0;pulse_style.content_margin_bottom=0
 form_pulse.add_theme_stylebox_override("panel",pulse_style)
 form_pulse.visible=false
 count_label=text("3",108,Color("ffe6a8"));ui.add_child(count_label)
 count_label.add_theme_constant_override("outline_size",10);count_label.add_theme_color_override("font_outline_color",Color(.05,.03,.08,.92))
 count_label.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"));count_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER);count_label.offset_left=-220;count_label.offset_right=220;count_label.offset_top=-80;count_label.offset_bottom=80;count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 form_label=text("",18,Color("ffe3a8"));ui.add_child(form_label)
 form_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 form_label.offset_left=-330;form_label.offset_right=330;form_label.offset_top=-252;form_label.offset_bottom=-214;form_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var form_pill:=D.panel(Color(.03,.04,.09,.62),12);form_pill.border_color=Color(GOLD,.5);form_pill.set_border_width_all(1);form_pill.content_margin_left=10;form_pill.content_margin_right=10
 form_label.add_theme_stylebox_override("normal",form_pill)
 # 하단 중앙의 긴 힌트 바는 시야를 가려 없앴다. 상태·안내는 좌상단 상태 라벨과
 # 우측 상호작용 버튼 캡션에만 표시한다.
 if form_pulse!=null:
  ui.add_child(form_pulse)
  form_pulse.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
  form_pulse.offset_left=-208;form_pulse.offset_top=-158;form_pulse.offset_right=-96;form_pulse.offset_bottom=-46
  form_pulse.pivot_offset=Vector2(56,56)
 var spectator:=button("관전 대상",spectator_menu);spectator.name="Spectator";spectator.position=Vector2(20,108);spectator.custom_minimum_size=Vector2(160,56);ui.add_child(spectator)
 spectator.visible=false
## 대표/보조/궁극기 버튼 → rules의 slot 실행. 조준 없이 누르면 바라보는 방향.
func cast_slot(slot: String,direction: Vector2) -> void:
 var me: Dictionary=rules.players.human
 var path_aim: Vector2=direction if direction!=Vector2.ZERO else Vector2.from_angle(me.facing*PI/4)
 # 2.0.31: 어떤 도사가 어떤 도술을 쓰든 그 도술의 효과음을 낸다(전부 'spell' 하나였던 것 수정).
 var cast_id:=String(C.ability(String(me.get("character","")),slot).get("skill",""))
 if rules.command("human","skill",{"aim":path_aim,"slot":slot}):sound.play_skill(cast_id)
 aim=Vector2.ZERO;aim_cancelled=false;aim_slot=slot
## 스킬 버튼 배지에 쓰는 아이콘 이름(능력 설명 문구가 아니라 아이콘).
func ability_hint(ability: Dictionary) -> String:
 return String(ability.get("icon","talisman"))
## 상황 버튼 하나(문·구출·둔갑·확인)를 같은 자리에 만들고 기본은 숨긴다.
func context_action(label_value: String,kind: String,icon: String) -> WooMobileButton:
 var b:=action(label_value,icon,Vector2(-200,-150),Vector2(96,96))
 b.name="Action_"+kind
 b.visible=false
 action_buttons[kind]=b
 return b
## 지금 실제로 가능한 행동 하나를 고른다. 없으면 빈 사전(버튼도 뜨지 않는다).
## 도사에게는 요괴의 '확인'이 절대 나오지 않고, 평상시 빈 상호작용 버튼도 없다.
func interaction_context() -> Dictionary:
 var me: Dictionary=rules.players.human
 if me.eliminated or me.captured:return {}
 if me.role=="yokai":
  var suspect: Dictionary=_suspect_near(me)
  if not suspect.is_empty():
   return {"kind":"confirm","label":"확인","icon":"capture","enabled":float(me.cd.get("seal",0))<=rules.elapsed,"hint":"의심스러운 사물을 쳐서 둔갑한 도사를 찾아냅니다"}
  return {}
 # 둔갑술(transform)을 가진 도사는 윗줄 '둔갑술' 버튼 하나로 둔갑·해제를 모두 한다.
 # 그래서 아래 공통 자리에 '둔갑' 버튼을 따로 띄우지 않는다(중복 표시 금지).
 var has_transform:=_has_transform_skill(me)
 if me.form!="" and not has_transform:return {"kind":"disguise","label":"둔갑 해제","icon":"jar","enabled":true,"hint":"둔갑 중 · 다시 누르면 사물에서 풀려납니다"}
 var target:=rescue_target()
 if target!="":return {"kind":"rescue","label":"구출","icon":"rescue","enabled":true,"hint":"구조 버튼을 2.5초간 유지하면 동료가 풀려납니다"}
 ## 강남역 기믹(개찰구·에스컬레이터·자판기·CCTV·조명·셔터): 코앞에 있으면 우선한다.
 if rules.gimmicks!=null:
  var gimmick: Dictionary=rules.gimmicks.entry_at(me.position,72.0)
  if not gimmick.is_empty():
   var kind_g: String=String(gimmick.kind)
   var label_g: String=String(gimmick.get("label","기믹"))
   var icon_g: String="gear"
   if kind_g=="light":
    var zone_id: String=String(gimmick.get("zone",""))
    var off: bool=rules.gimmicks.zone_dark(zone_id)
    label_g="조명 켜기" if (off and me.role=="yokai") else ("조명 끄기" if not off and me.role=="daoist" else "조명")
    icon_g="lamp"
   elif kind_g=="cctv":icon_g="eye"
   elif kind_g=="vending":icon_g="machine"
   elif kind_g=="escalator":icon_g="stairs"
   elif kind_g=="turnstile":icon_g="gate"
   elif kind_g=="shutter":icon_g="shutter"
   return {"kind":"gimmick","label":label_g,"icon":icon_g,"enabled":true,"hint":String(gimmick.get("hint",""))}
 if has_transform:return {}
 var spot: Dictionary=_form_target_near(me)
 if not spot.is_empty():
  var ready: bool=float(me.cd.get("disguise",0))<=rules.elapsed
  var name_value:=String(L.form(String(spot.kind)).get("name","사물"))
  return {"kind":"disguise","label":"둔갑","icon":"jar","enabled":ready,"hint":("%s(으)로 둔갑해 숨습니다"%name_value) if ready else "둔갑 준비 중입니다","near":spot}
 return {}
## 이 캐릭터가 둔갑술(transform)을 자기 스킬 버튼으로 갖고 있는지.
func _has_transform_skill(me: Dictionary) -> bool:
 for ability in (C.find(String(me.get("character",""))).get("abilities",[]) as Array):
  if String(ability.get("skill",""))=="transform":return true
 return false
## 둔갑할 수 있는 사물·동물이 사거리 안에 있는지.
func _form_target_near(me: Dictionary) -> Dictionary:
 var near_object: Dictionary=L.object_near(me.position,84)
 if near_object.is_empty():near_object=rules.animal_near(me.position,84)
 return near_object
## 요괴의 '확인' 대상: 둔갑 도사가 숨었을 만한 사물, 깔린 기관인형·가짜 구조물.
func _suspect_near(me: Dictionary) -> Dictionary:
 for e in rules.effects:
  if e.kind in ["decoy","fake_rescue"] and me.position.distance_to(e.position)<rules.CONFIRM_REACH+8:return {"kind":"decoy","p":e.position}
 var spot: Dictionary=L.object_near(me.position,rules.CONFIRM_REACH)
 if not spot.is_empty():return {"kind":String(spot.kind),"p":spot.p}
 return {}
func action(name_value: String,icon: String,offset: Vector2,extent: Vector2,callback: Callable=Callable(),type: Script=preload("res://scripts/survival/skill_button.gd")) -> WooMobileButton:
 var b: WooMobileButton=button(name_value,callback if callback.is_valid() else func()->void:pass,false,null,type)
 b.text=""
 b.custom_minimum_size=extent
 ui.add_child(b)
 b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 b.offset_left=offset.x;b.offset_top=offset.y;b.offset_right=offset.x+extent.x;b.offset_bottom=offset.y+extent.y
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:b.add_theme_color_override(state,Color(0,0,0,0))
 var caption:=text(name_value,14,Color("f6e8c8"));caption.name="Caption"
 var ribbon:=D.panel(Color(.03,.04,.09,.72),6);ribbon.border_color=Color(GOLD,.45);ribbon.set_border_width_all(1);ribbon.content_margin_top=0;ribbon.content_margin_bottom=0;ribbon.content_margin_left=4;ribbon.content_margin_right=4
 caption.add_theme_stylebox_override("normal",ribbon)
 caption.add_theme_color_override("font_outline_color",Color(.02,.02,.05));caption.add_theme_constant_override("outline_size",2)
 var caption_y: float=extent.y+1 if offset.y+extent.y<-34 else -20
 caption.position=Vector2(-6,caption_y);caption.size=Vector2(extent.x+12,18);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.add_child(caption)
 if b is WooMobileButton:(b as WooMobileButton).accent=Color("f0c46a") if icon in ["capture","rescue"] else Color("7fb6e8")
 var badge:=preload("res://scripts/woo/skill_badge.gd").new();badge.name="Badge";badge.skill=icon
 var side:=minf(extent.x,extent.y)*.76
 badge.position=Vector2((extent.x-side)/2,(extent.y-side)/2-1);badge.size=Vector2(side,side)
 b.add_child(badge)
 return b
## 조준 중인 스킬 버튼이 있는지(대표·보조·궁극기).
func aiming() -> bool:
 for slot in skill_buttons:
  var target: WooMobileButton=skill_buttons[slot]
  if is_instance_valid(target) and target.held and target.directional and aim!=Vector2.ZERO:return true
 return false
func rescue_target() -> String:
 var p: Dictionary=rules.players.human;var found:="";var best:=58.0
 for q in rules.players.values():
  if q.captured and not q.eliminated and p.position.distance_to(q.position)<best and L.line(p.position,q.position):best=p.position.distance_to(q.position);found=q.id
 return found
func close_popup() -> void:
 if is_instance_valid(modal):D.retire_inputs(modal);modal.queue_free()
 modal=null
func notice(message: String) -> void:
 var box:=popup(message);box.add_child(button("확인",close_popup,true))
func confirm(message: String,callback: Callable) -> void:
 var box:=popup(message);var row:=HBoxContainer.new();box.add_child(row)
 row.add_child(button("취소",func()->void:
  if screen=="match" and paused:pause_menu()
  else:close_popup()))
 row.add_child(button("확인",func()->void:close_popup();callback.call(),true))
func popup(title: String) -> VBoxContainer:
 close_popup();D.cancel_controls(ui)
 modal=Control.new();full(modal,ui);modal.mouse_filter=Control.MOUSE_FILTER_STOP
 var shade:=ColorRect.new();shade.color=Color(.012,.015,.035,.86);full(shade,modal)
 var center:=CenterContainer.new();full(center,modal)
 var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(780,140)
 var popup_style:=LC.panel_box(Color(0.035,0.04,0.085,0.97),14,Color(0.85,0.72,0.47,0.65),1,Color(0.55,0.45,1.0,0.28),18)
 popup_style.content_margin_left=26;popup_style.content_margin_right=26;popup_style.content_margin_top=18;popup_style.content_margin_bottom=18
 frame.add_theme_stylebox_override("panel",popup_style)
 center.add_child(frame)
 var trim:=LArt.Filigree.new();trim.color=Color(0.85,0.72,0.47,0.55);trim.arm=22.0;frame.add_child(trim)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);frame.add_child(box)
 var heading:=text(title,28,LC.GOLD_SOFT);heading.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"));box.add_child(heading)
 var rule_line:=ColorRect.new();rule_line.color=Color(0.85,0.72,0.47,0.3);rule_line.custom_minimum_size.y=1;box.add_child(rule_line)
 return box
func style_slider(slider: HSlider) -> void:
 for key in ["slider","grabber_area","grabber_area_highlight"]:
  var style:=LC.panel_box(Color(0.02,0.03,0.06,0.95),3,Color(0.85,0.72,0.47,0.5),1)
  style.content_margin_top=3;style.content_margin_bottom=3
  if key!="slider":
   style.bg_color=Color(0.80,0.66,0.38,0.92)
   style.border_color=Color(0.95,0.85,0.6,0.6)
  slider.add_theme_stylebox_override(key,style)
func style_check(box: CheckBox) -> void:
 box.add_theme_font_override("font",LC.FONT)
 box.add_theme_font_size_override("font_size",17)
 for color_key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  box.add_theme_color_override(color_key,LC.IVORY)
func settings_row(box: VBoxContainer,title_value: String,detail: String) -> HBoxContainer:
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);box.add_child(row)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);column.custom_minimum_size=Vector2(160,0);row.add_child(column)
 column.add_child(text(title_value,19,LC.IVORY))
 if detail!="":column.add_child(text(detail,14,Color(0.74,0.78,0.88,0.9)))
 return row
func show_settings() -> void:
 var box:=popup("설정 · 소리와 화면")
 var nickname_row:=settings_row(box,"닉네임",display_name())
 nickname_row.add_child(button("바꾸기",open_nickname_edit))
 for spec in [["배경음악","music","music_mute","로비·경기 음악"],["효과음","sfx","sfx_mute","버튼·도술 효과음"]]:
  var row:=settings_row(box,String(spec[0]),String(spec[3]))
  var slider:=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=storage.data[spec[1]];slider.custom_minimum_size=Vector2(280,44);style_slider(slider);row.add_child(slider)
  var mute:=CheckBox.new();mute.text="음소거";mute.button_pressed=bool(storage.data.get(spec[2],false));style_check(mute);row.add_child(mute)
  var key: String=spec[1];var mute_key: String=spec[2]
  slider.value_changed.connect(func(value: float)->void:storage.data[key]=value;apply_settings())
  mute.toggled.connect(func(value: bool)->void:storage.data[mute_key]=value;apply_settings())
 var sensitivity_row:=settings_row(box,"조작감","가상 스틱 감도")
 var sensitivity_slider:=HSlider.new();sensitivity_slider.min_value=.6;sensitivity_slider.max_value=1.4;sensitivity_slider.step=.05
 sensitivity_slider.value=float(storage.data.sensitivity);sensitivity_slider.custom_minimum_size=Vector2(280,44);style_slider(sensitivity_slider);sensitivity_row.add_child(sensitivity_slider)
 sensitivity_slider.value_changed.connect(func(value: float)->void:storage.data.sensitivity=value;sensitivity=value)
 ## 2.0.34 테스트·디버그용 맵 지정(빠른 매치는 랜덤).
 var map_row:=settings_row(box,"맵 (테스트)","빠른 매치에서 고를 맵")
 var map_pick:=OptionButton.new()
 map_pick.add_item("무작위")
 var map_keys: Array=["random"]
 for map_id in Maps.ids():
  map_pick.add_item(Maps.name_of(String(map_id)))
  map_keys.append(String(map_id))
 var debug_map: String=String(storage.data.get("debug_map","random"))
 map_pick.selected=maxi(0,map_keys.find(debug_map))
 map_pick.custom_minimum_size=Vector2(220,46)
 map_pick.add_theme_font_override("font",LC.FONT);map_pick.add_theme_font_size_override("font_size",17)
 map_row.add_child(map_pick)
 map_pick.item_selected.connect(func(index: int)->void:
  var value: String=String(map_keys[clampi(index,0,map_keys.size()-1)])
  storage.data.debug_map=value;Maps.set_preferred(value))
 var screen_row:=settings_row(box,"화면·진동","")
 var vibrate:=CheckBox.new();vibrate.text="진동 켜기";vibrate.button_pressed=storage.data.vibration;style_check(vibrate);screen_row.add_child(vibrate)
 var quality:=OptionButton.new();quality.add_item("보통 · 벚꽃·물결 효과");quality.add_item("낮음 · 효과 축소");quality.selected=1 if storage.data.quality=="낮음" else 0;quality.custom_minimum_size.y=46
 quality.add_theme_font_override("font",LC.FONT);quality.add_theme_font_size_override("font_size",17)
 screen_row.add_child(quality)
 vibrate.toggled.connect(func(value: bool)->void:storage.data.vibration=value)
 quality.item_selected.connect(func(index: int)->void:storage.data.quality="낮음" if index==1 else "보통")
 box.add_child(text("음소거는 배경음악·효과음 버스에 바로 적용됩니다.",15,Color(0.74,0.78,0.88,0.9)))
 var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",12);box.add_child(buttons)
 buttons.add_child(button("저장 및 닫기",func()->void:
  if storage.save()!=OK:notice("설정을 저장하지 못했습니다.")
  elif screen=="match" and paused:pause_menu()
  else:close_popup(),true))
 buttons.add_child(button("닫기",func()->void:
  if screen=="match" and paused:pause_menu()
  else:close_popup()))
func leave_room() -> void:confirm("게임 방에서 나가시겠습니까?",func()->void:cleanup_match();room={};transition("rooms"))
func pause_menu() -> void:
 if screen!="match":return
 ## 2.0.34: 메뉴·설정·지도 오버레이는 경기 시간과 시뮬레이션을 멈추지 않는다.
 paused=false
 if is_instance_valid(world):world.process_mode=Node.PROCESS_MODE_INHERIT
 rules.command("human","move",{"vector":Vector2.ZERO});rules.command("human","cancel_rescue")
 var box:=popup("메뉴 · "+Maps.name())
 box.add_child(text("경기는 계속 진행됩니다 · 오버레이를 열어도 타이머·이동·전투가 멈추지 않습니다",15,Color("ffd08a")))
 box.add_child(text("도사 6명 vs 요괴 2명 · 10분간 술래잡기",19,Color("f0dcae")))
 box.add_child(text("도사는 목숨 3개. 봉인되면 10초 안에 동료가 2.5초 구조하면 목숨을 지키고,\n구조받지 못하면 목숨 1개를 잃은 뒤 시작 자리에서 다시 일어납니다. 목숨을 모두 잃으면 탈락합니다.\n항아리·나무 상자·등불·고양이·강아지·비석 6종에 둔갑해 움직이며 숨을 수 있습니다.",16,Color("cfd7ea")))
 box.add_child(button("계속하기",resume_match,true));box.add_child(button("설정",show_settings));box.add_child(button("로비로 나가기",func()->void:confirm("경기를 나가시겠습니까?",func()->void:cleanup_match();room={};paused=false;transition("lobby"))))
func resume_match() -> void:
 close_popup();paused=false
 if is_instance_valid(world):world.process_mode=Node.PROCESS_MODE_INHERIT
func skill_tip(message: String) -> void:
 paused=true
 if is_instance_valid(world):world.process_mode=Node.PROCESS_MODE_DISABLED
 var box:=popup(message);box.add_child(button("닫기 · 경기 계속",resume_match))
func spectator_menu() -> void:
 if not rules.players.human.eliminated:return
 paused=true
 if is_instance_valid(world):world.process_mode=Node.PROCESS_MODE_DISABLED
 var box:=popup("관전 대상")
 for p in rules.players.values():
  if not p.eliminated:box.add_child(button(p.name,func()->void:spectate=p.id;minimap.observer=p.id;resume_match()))
 box.add_child(button("돌아가기",resume_match))
func result_screen() -> void:
 if not recorded:recorded=true;record_match()
 var box:=page(("승리" if rules.winner==rules.players.human.role else "패배")+" · "+("도사팀 승리 / 요괴팀 패배" if rules.winner=="daoist" else "요괴팀 승리 / 도사팀 패배"))
 var center:=HBoxContainer.new();center.size_flags_vertical=Control.SIZE_SHRINK_CENTER;center.add_theme_constant_override("separation",18);box.add_child(center);portrait(center,rules.players.human.character,Vector2(340,320))
 var stats:=panel(center);stats.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 if stats.get_parent() is Control:(stats.get_parent() as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
 stats.add_child(text("%s · %02d:%02d"%[Maps.name(),int(rules.elapsed)/60,int(rules.elapsed)%60],27,D.GOLD))
 var me: Dictionary=rules.players.human
 stats.add_child(text(display_name()+" · "+("도사" if me.role=="daoist" else "요괴")+(" · 목숨 %s"%hearts(int(me.get("lives",rules.LIVES))) if me.role=="daoist" else ""),24));stats.add_child(text("봉인 %d회 · 구조 %d회 · 생존 %.0f초"%[me.stats.seals,me.stats.rescues,me.alive_seconds],22))
 # 2.0.32 이번 경기 보상: 실제 storage에 지급된 코인·보석을 그대로 보여 준다.
 var reward: Dictionary=last_reward if not last_reward.is_empty() else match_reward()
 var reward_title:=text("이번 경기 보상",23,Color("ffe6b4"));stats.add_child(reward_title)
 var pocket:=HBoxContainer.new();pocket.name="MatchReward";pocket.add_theme_constant_override("separation",12);stats.add_child(pocket)
 var coin_chip:=text("+%s 코인"%comma(int(reward.get("coins",0))),26,Color("ffd98a"));coin_chip.name="MatchRewardCoins";pill(coin_chip,Color(.20,.14,.04,.9),12);pocket.add_child(coin_chip)
 var gem_chip:=text("+%s 보석"%comma(int(reward.get("gems",0))),26,Color("d9b8ff"));gem_chip.name="MatchRewardGems";pill(gem_chip,Color(.12,.07,.20,.9),12);pocket.add_child(gem_chip)
 var detail:=" · ".join(PackedStringArray(reward.get("lines",[])))
 var detail_label:=text(detail,15,Color(.84,.86,.95));detail_label.name="MatchRewardDetail";detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail_label.custom_minimum_size=Vector2(440,0);detail_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats.add_child(detail_label)
 var note_label:=text("획득한 재화는 로비 상단 지갑과 상점에 바로 반영됩니다.",14,Color(.78,.80,.92));stats.add_child(note_label)
 var daoist_alive: int=rules.players.values().filter(func(p: Dictionary)->bool:return String(p.role)=="daoist" and not p.eliminated).size()
 var yokai_alive: int=rules.players.values().filter(func(p: Dictionary)->bool:return String(p.role)=="yokai" and not p.eliminated).size()
 stats.add_child(text("도사 생존 %d · 요괴 생존 %d · 전체 %d인"%[daoist_alive,yokai_alive,daoist_alive+yokai_alive],16,Color(.80,.82,.92)))
 var row:=HBoxContainer.new();box.add_child(row);row.add_child(button("재경기",func()->void:cleanup_match();setup_participants();transition("room"),true));row.add_child(button("메인 로비",func()->void:cleanup_match();room={};transition("lobby")))
func enter_practice() -> void:
 if screen!="lobby" or changing:return
 clear_ui();screen="practice";practice=preload("res://scripts/survival/practice_view.gd").new();practice.game=self;add_child(practice)
func practice_done() -> void:
 if is_instance_valid(practice):practice.queue_free()
 practice=null;transition("lobby")
func cleanup_match() -> void:
 sequence+=1;event_cursor=0
 if is_instance_valid(world):world.queue_free()
 world=null;camera=null;avatars.clear();clones.clear();bots.clear();nav=null;paused=false;fixed_clock=0;bot_clock=0;aim=Vector2.ZERO
func update_avatars() -> void:
 if not is_instance_valid(world) or rules==null:return
 var me: Dictionary=rules.players.human
 if me.eliminated:
  if not rules.players.has(spectate) or rules.players[spectate].eliminated:
   var alive: Array=rules.players.values().filter(func(p: Dictionary)->bool:return not p.eliminated);spectate=alive[0].id if not alive.is_empty() else "human"
 else:spectate="human"
 var visible: Array=rules.visible(spectate);var seen: Array=[]
 for info in visible:
  var id: String=info.id if info.id!="" else "shape:"+str(info.position)
  seen.append(id)
  var target: Vector2=info.position+Vector2(0,-L.elevation(info.position))
  if not avatars.has(id):
   var actor:=Actor.new();actor.network_remote=true;actor.collision_layer=0;actor.collision_mask=0;actor.costume_scale=ACTOR_SCALE;actor.scale=Vector2(ACTOR_SCALE,ACTOR_SCALE);world.add_child(actor);actor.ingame_art=true
   var base_art:=C.fallback_art(String(info.get("character","")).trim_prefix("yokai:").trim_prefix("daoist:"))
   # 2.0.34 부침개 전우치: 장착 스킨이 그 캐릭터 전용이면 전용 8방향 시트를 쓴다.
   var skin_key:=SkillFX.sheet_key(String(info.get("character","")),String(storage.equipped("skin"))) if info.id=="human" else ""
   actor.art_id=skin_key if skin_key!="" else base_art
   if info.id=="human" and skin_key=="":actor.skin_tint=Market.skin_color(storage.equipped("skin")).lerp(Color.WHITE,.45)
   actor.position=target;actor.set_meta("target",target)
   avatars[id]=actor
   # 2.0.33 이름표: '닉네임 [캐릭터명] · ♥♥♥' 길이를 담을 만큼 넓게 잡는다.
   var label:=text("",11);label.name="Name";label.position=Vector2(-120,-68);label.size=Vector2(240,18);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_plate(label);actor.add_child(label)
   var mark:=preload("res://scripts/seal/color_marker.gd").new();mark.actor=actor;mark.name="Identity";actor.add_child(mark)
   var aura:=preload("res://scripts/survival/actor_aura.gd").new();aura.name="Aura";actor.add_child(aura)
  var actor: WooActor=avatars[id]
  # 2.0.30 집합: 겉모습(원화)은 매 프레임 관측자가 보는 character를 따른다.
  # 인간둔갑이 끝나거나 둔갑이 풀리면 원래 모습으로 바로 돌아온다.
  var wanted_art: String=C.fallback_art(String(info.get("character","")).trim_prefix("yokai:").trim_prefix("daoist:"))
  var wanted_skin:=SkillFX.sheet_key(String(info.get("character","")),String(storage.equipped("skin"))) if info.id=="human" else ""
  if wanted_skin!="":wanted_art=wanted_skin
  if wanted_art!="" and actor.art_id!=wanted_art:
   actor.art_id=wanted_art
   actor.update_sprite()
  # 60Hz 목표점을 매 프레임 부드럽게 따라가 뚝뚝 끊기는 이동을 없앤다.
  var previous: Vector2=actor.get_meta("target",target)
  var moved: float=previous.distance_to(target)
  actor.set_meta("target",target)
  var frame: float=clampf(get_process_delta_time(),0.001,0.05)
  if target.distance_to(actor.position)>AVATAR_SNAP:actor.position=target
  else:actor.position=actor.position.lerp(target,1.0-exp(-AVATAR_FOLLOW*frame))
  actor.cosmetic=info.cosmetic;actor.facing=info.facing;actor.jump_height=info.height;actor.gait_phase+=moved/22.0*PI;actor.gait_weight=move_toward(actor.gait_weight,1.0 if info.moving else 0.0,.2);actor.velocity=Vector2(88,0) if info.moving else Vector2.ZERO;  var disguised: bool=info.form!=""
  if disguised:
   # 둔갑하면 맵에 놓인 같은 사물과 100% 같은 크기·원화·그림자로 그린다.
   var shape: Dictionary=L.form_visual(String(info.form))
   actor.form_height=float(shape.get("height",46.0));actor.form_shadow=float(shape.get("shadow",16.0))
  actor.appearance_form=("seowon:" if Maps.current_id=="seowon" else "prop:")+String(info.form) if disguised else "human"
  if disguised:actor.form_art_path=Maps.form_art_path(String(info.form))
  actor.running=rules.players.get(info.id,{}).get("running",false)
  var tint: Color=C.tint(String(info.get("character","")))
  # 둔갑한 도사는 이름·색기운·발밑 표시를 모두 떼어 진짜 사물과 같게 둔다.
  if disguised:tint=Color.WHITE
  actor.tint=tint
  var aura: Node2D=actor.get_node_or_null("Aura")
  # 발밑 색 링은 쓰지 않는다. 기운을 장착한 내 캐릭터만 옅은 빛무리를 더한다.
  var lit_effect: String=storage.equipped("effect") if info.id=="human" else ""
  var aura_color:=Market.effect_color(lit_effect) if lit_effect!="" else tint
  if aura!=null and (aura.form_shadow!=float(actor.form_shadow if disguised else 0.0) or aura.color!=aura_color or aura.yokai!=(info.role=="yokai" and not disguised) or aura.lit!=(lit_effect!="")):
   aura.form_shadow=actor.form_shadow if disguised else 0.0
   aura.color=aura_color;aura.yokai=info.role=="yokai" and not disguised;aura.lit=lit_effect!="" and not disguised;aura.queue_redraw()
  # 2.0.33 이름표: '닉네임 [캐릭터명]' + 도사는 남은 목숨 하트. 인간둔갑한 요괴는
  # 복제한 도사의 닉네임·캐릭터명·하트를 그대로 쓰므로 본인과 구별되지 않는다.
  var tag_nick: String=String(info.get("player_name",info.get("name","")))
  var tag_character: String=String(info.get("character_name",""))
  if tag_character=="" and info.id=="human" and rules.players.has("human"):
   tag_character=String(C.find(rules.players.human.character).get("name",""))
  var lives_left: int=int(info.get("lives",rules.players.get(info.id,{}).get("lives",rules.LIVES)))
  var tag:=person_tag(tag_nick,tag_character,String(info.get("role","")),lives_left)
  actor.get_node("Name").text=tag+(" · 봉인" if info.captured else "");actor.get_node("Name").visible=not disguised;actor.get_node("Identity").color_id=info.color
  actor.get_node("Identity").visible=not disguised
  actor.modulate=Color.WHITE if disguised else (Color("e2b2ff") if info.captured else (Color("c9ecff") if info.immune else Color.WHITE))
  # 화중은신: 다른 시점에는 아예 그려지지 않고, 본인 화면에서만 반투명 먹그림자로 보인다.
  if float(me.get("buff",{}).get("painting",0.0))>rules.elapsed and info.id=="human":
   actor.modulate=Color(.78,.72,.95,.42)
   actor.get_node("Name").visible=false
   actor.get_node("Identity").visible=false
  elif rules.hidden(me) and info.id=="human":
   # 무월야 등 다른 은신: 본인에게만 반투명+은은한 보랏빛으로 남겨, 내가 어디 있는지 잃지 않게 한다.
   actor.modulate=Color(.86,.80,1.0,.55)
   actor.get_node("Name").visible=false
   actor.get_node("Identity").visible=false
 for id in avatars.keys():
  if not seen.has(id):avatars[id].queue_free();avatars.erase(id)
 var live_effects: Array=[]
 for effect in rules.effects:
  if effect.kind not in ["clone","decoy"]:continue
  var key: String=str(effect.id);live_effects.append(key)
  var decoy: bool=effect.kind=="decoy"
  if not clones.has(key):
   var clone:=Actor.new();clone.network_remote=true;clone.cosmetic=effect.cosmetic
   # 2.0.19: 분신도 본체와 같은 2.5D 인게임 원화로 그린다(예전 마스코트가 나오지 않게).
   clone.ingame_art=true
   clone.art_id=C.fallback_art(String(effect.get("character","")).trim_prefix("yokai:").trim_prefix("daoist:"))
   if clone.art_id=="":clone.art_id=String(effect.cosmetic.get("character","woochi"))
   clone.collision_layer=0;clone.collision_mask=0;clone.scale=Vector2(ACTOR_SCALE,ACTOR_SCALE);world.add_child(clone);clone.update_sprite();clones[key]=clone
   # 2.0.33 분신·환영도 본체와 똑같은 이름표를 단다(이름표가 없으면 가짜임이 바로 들킨다).
   var clone_label:=text("",11);clone_label.name="Name";clone_label.position=Vector2(-120,-68);clone_label.size=Vector2(240,18);clone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_plate(clone_label);clone.add_child(clone_label)
   var clone_mark:=preload("res://scripts/seal/color_marker.gd").new();clone_mark.actor=clone;clone_mark.name="Identity";clone.add_child(clone_mark)
  var clone: WooActor=clones[key];clone.position=effect.position;clone.position+=Vector2(0,-L.elevation(effect.position));clone.facing=effect.facing
  # 2.0.33 분신의 정체성: 시전자와 같은 닉네임·[캐릭터명]·남은 목숨 하트(롤 샤코 궁처럼 완전히 동일).
  var identity: Dictionary=effect.get("identity",{})
  var clone_name: Label=clone.get_node_or_null("Name")
  if clone_name!=null:
   var clone_tag:=person_tag(String(identity.get("name","")),String(identity.get("character_name","")),String(identity.get("role","")),int(identity.get("lives",-1)))
   if clone_name.text!=clone_tag:clone_name.text=clone_tag
   clone_name.visible=true
  var clone_mark: Node=clone.get_node_or_null("Identity")
  if clone_mark!=null:clone_mark.color_id=int(identity.get("color",0))
  clone.velocity=Vector2(0,0) if decoy else Vector2(36,0)
  clone.gait_weight=0.0 if decoy else 1.0
  clone.gait_phase+=0.0 if decoy else .15
 for key in clones.keys():
  if not live_effects.has(key):clones[key].queue_free();clones.erase(key)
 if is_instance_valid(camera):
  var focus: Dictionary=rules.players.get(spectate,{})
  var spot: Vector2=Vector2(focus.get("position",L.SPAWN))
  var anchor:=spot-Vector2(0,L.elevation(spot))
  # 화면 속 캐릭터 위치(이미 보간된 값)를 그대로 따라가 카메라 지연·떨림을 없앤다.
  var rendered: Node2D=avatars.get(spectate)
  if rendered!=null:anchor=rendered.position
  camera.position=anchor+Vector2(0,-L.CAMERA_LIFT)
  world.observer=rules.players[spectate].position
func safe_layout() -> void:
 if not is_instance_valid(content):return
 var left:=26;var right:=26;var bottom:=18
 if OS.get_name()=="Android":
  var area:=DisplayServer.get_display_safe_area();var display:=DisplayServer.screen_get_size();var view:=get_viewport().get_visible_rect().size
  if display.x>0:left=maxi(left,int(area.position.x*view.x/display.x));right=maxi(right,int((display.x-area.end.x)*view.x/display.x));bottom=maxi(bottom,int((display.y-area.end.y)*view.y/display.y))
 content.add_theme_constant_override("margin_left",left);content.add_theme_constant_override("margin_right",right);content.add_theme_constant_override("margin_bottom",bottom)
 if screen=="match" and is_instance_valid(stick):D.position_stick(stick)
func _process(delta: float) -> void:
 render_clock+=delta
 if screen=="quick":advance_matching(delta)
 if screen=="selection" and rules!=null:
  if not backgrounded:
   fixed_clock+=minf(delta,.25)
   while fixed_clock>=STEP:rules.tick(STEP);fixed_clock-=STEP
  if rules.phase=="loading":sequence+=1;changing=true;load_match(sequence);return
  if is_instance_valid(selection_view):
   selection_view.set_timer(rules.selection_left)
   selection_view.set_ready(rules.ready_remaining(),rules.phase=="ready")
   var done:=0;var total:=0
   for entry in rules.selection_view("human"):
    if entry.id=="human":continue
    total+=1
    if entry.confirmed:done+=1
   selection_view.set_team({"done":done,"total":total})
  return
 if screen!="match" or rules==null or not is_instance_valid(world):return
 var me: Dictionary=rules.players.human
 ## 2.0.34: 오버레이(지도·설정·메뉴)가 열려 있어도 경기 시뮬레이션과 타이머는 계속 돈다.
 if not backgrounded:
  if modal==null and rules.available(me):rules.command("human","move",{"vector":stick.vector*float(storage.data.sensitivity)})
  elif not modal==null:rules.command("human","move",{"vector":Vector2.ZERO})
  fixed_clock+=minf(delta,.25)
  while fixed_clock>=STEP:
   rules.tick(STEP);fixed_clock-=STEP;bot_clock+=STEP
   if bot_clock>=.35 and rules.phase=="live":
    var spent:=bot_clock;bot_clock=0
    for bot in bots:bot.think(spent)
 if rules.phase=="result" and not result_seen:result_seen=true;build("result");return
 world.aim=aim;world.aim_cancelled=aim_cancelled;world.aim_active=aiming()
 update_avatars();update_hud()
## 남은 목숨을 하트로 보여 준다(도사 전용).
## 상단 중앙 알림 배너.
func show_banner(message: String,color: Color=Color("ffe0a8")) -> void:
 if hud_view!=null:hud_view.banner=message;hud_view.banner_color=color
 banner_left=3.0
func hearts(count: int) -> String:
 return "♥".repeat(maxi(0,count)) + "♡".repeat(maxi(0,rules.LIVES-maxi(0,count))) if rules!=null else ""
## 2.0.33 이름표 한 줄: '닉네임 [캐릭터명]' + 도사는 남은 목숨 하트(요괴는 하트 없음).
func person_tag(nick: String,character_name: String,role: String,lives: int=-1) -> String:
 var tag:=nick if nick!="" else "나"
 if character_name!="":tag=tag+" ["+character_name+"]"
 if role=="daoist" and lives>=0 and rules!=null:tag+=" · "+hearts(lives)
 return tag
## 2.0.33 이름표 가독성: 밝은 바닥 위에서도 읽히도록 얇은 먹색 외곽선을 준다.
func name_plate(label: Label) -> void:
 label.add_theme_color_override("font_outline_color",Color(0.02,0.018,0.04,.88))
 label.add_theme_constant_override("outline_size",3)
func set_text(node: Label,value: String) -> void:
 if node.text!=value:node.text=value
func update_hud() -> void:
 var me: Dictionary=rules.players.human
 var live: bool=rules.available(me) and not paused and not backgrounded and modal==null
 # 화면 시야 연출(시야 좁히기·등불끄기 안개·무월야)을 같은 프레임에 맞춘다.
 if is_instance_valid(vision):
  vision.rules=rules;vision.observer=spectate
  vision.sync(get_process_delta_time())
 if is_instance_valid(minimap):minimap.rules=rules;minimap.observer=spectate
 if is_instance_valid(cctv_view):cctv_view.rules=rules;cctv_view.observer=spectate
 if is_instance_valid(rescue_markers):
  rescue_markers.rules=rules;rescue_markers.observer=spectate;rescue_markers.camera=camera
 stick.input_enabled=live
 run_button.disabled=not live or me.exhausted
 jump_button.disabled=not live or me.jump>0
 var spec: Dictionary=C.find(me.character)
 var form_left: float=maxf(0,float(me.buff.get("transform",0))-rules.elapsed)
 var transformed: bool=me.form!=""
 for slot in skill_buttons:
  var target: WooMobileButton=skill_buttons[slot]
  var badge: WooSkillBadge=skill_badges.get(slot,null)
  if not is_instance_valid(target) or badge==null:continue
  var ability: Dictionary=C.ability(me.character,String(slot))
  if ability.is_empty():continue
  var key: String=String(ability.get("skill",""))
  var remaining: float=maxf(0,float(me.cd.get(key,0))-rules.elapsed)
  if String(slot)=="ult":
   var miss: float=maxf(0,rules.ULT_MAX-float(me.get("ult",0.0)))
   badge.fill_mode=true;badge.remaining=miss;badge.maximum=rules.ULT_MAX
   badge.locked=miss>0.5
   target.disabled=not live or miss>0.5
  else:
   badge.fill_mode=false
   badge.remaining=form_left if transformed and String(key)=="transform" else remaining
   badge.maximum=9.0 if transformed and String(key)=="transform" else float(ability.get("cd",12.0))
   target.disabled=not live or (remaining>0 and not (transformed and String(key)=="transform"))
 var context: Dictionary=interaction_context()
 var active_kind: String=String(context.get("kind",""))
 for key in action_buttons:
  var button: WooMobileButton=action_buttons[key]
  if not is_instance_valid(button):continue
  var shown: bool=key==active_kind and live
  button.visible=shown
  if not shown:continue
  var caption: Label=button.get_node_or_null("Caption")
  if caption!=null:
   set_text(caption,String(context.get("label","")))
   caption.add_theme_color_override("font_color",Color("ffe6a8") if context.has("near") else Color("f6e8c8"))
  var badge: WooSkillBadge=button.get_node_or_null("Badge")
  if badge!=null:
   var icon: String=String(context.get("icon","talisman"))
   if badge.skill!=icon:badge.skill=icon;badge.queue_redraw()
   if key=="confirm":
    badge.remaining=maxf(0,float(me.cd.get("seal",0))-rules.elapsed);badge.maximum=rules.MISS_RECOVER
   elif key=="rescue":
    badge.remaining=maxf(0,rules.RESCUE_TIME-me.progress) if me.progress>0 else 0.0;badge.maximum=rules.RESCUE_TIME
   else:
    badge.remaining=0.0;badge.maximum=1.0
  button.disabled=not live or not bool(context.get("enabled",true))
 if form_pulse!=null:
  var show_pulse: bool=active_kind=="disguise" and String(context.get("label",""))=="둔갑" and bool(context.get("enabled",false)) and live
  form_pulse.visible=show_pulse
  if show_pulse:
   var beat: float=.5+.5*sin(Time.get_ticks_msec()/260.0)
   form_pulse.modulate.a=.35+.55*beat
   form_pulse.scale=Vector2.ONE*(1.0+.05*beat)
 var dao: int=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.eliminated).size()
 var left:=maxf(0,600-rules.elapsed);var seconds:=int(ceil(left))
 set_text(timer_label,"%s · %02d:%02d"%[Maps.name(),seconds/60,seconds%60])
 set_text(survivor_label,"생존 도사 %d · 요괴 2"%dao)
 var captured: int=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and p.captured).size()
 set_text(seal_label,"봉인 %d / 5"%mini(5,captured));seal_label.visible=false
 if hud_view!=null:hud_view.survivor_count=dao;hud_view.sealed_count=captured
 var zone: Dictionary=rules.circle()
 set_text(circle_label,"안전구역 %d단계 · 축소 %02d:%02d"%[zone.stage,int(zone.until)/60,int(zone.until)%60])
 if int(zone.stage)!=zone_stage_seen:
  if zone_stage_seen>=0:show_banner("안전구역 축소 시작! %d단계"%int(zone.stage),Color("ffd08a"))
  zone_stage_seen=int(zone.stage)
 # 상단 HUD(초상화·하트·기력·참가자 목록) 동기화
 if hud_view!=null:
  hud_view.rules=rules;hud_view.role=me.role
  hud_view.lives=int(me.get("lives",rules.LIVES));hud_view.max_lives=rules.LIVES
  hud_view.stamina=me.stamina;hud_view.captured=me.captured;hud_view.eliminated=me.eliminated
  hud_view.character_name=String(spec.get("name",""))
  # 2.0.30 지속 효과·버프·디버프 뱃지(이름 + 남은 시간)와 마지막 시전 칩.
  hud_view.buffs=rules.active_effects(me.id)
  hud_view.cast_name=String(me.get("last_skill_name",""))
  hud_view.cast_left=maxf(0,float(me.get("last_skill_until",0.0))-rules.elapsed)
  if hud_view.portrait==null and String(spec.get("portrait",""))!="":hud_view.portrait=load(String(spec.portrait))
  banner_left=maxf(0,banner_left-get_process_delta_time())
  hud_view.banner_alpha=clampf(minf((3.0-banner_left)/0.2,banner_left/0.7),0,1)
  hud_view.queue_redraw()
 var status:=""
 var mimic_left: float=float(me.get("buff",{}).get("mimic",0.0))-rules.elapsed
 if me.captured:status="구조 대기 %d초 · 목숨 %s" % [maxi(0,int(ceil(me.deadline-rules.elapsed))),hearts(int(me.get("lives",rules.LIVES)))]
 elif me.eliminated:status="탈락 · 관전 중"
 elif me.immune>rules.elapsed:status="재봉인 면역 %.1f초"%maxf(0,me.immune-rules.elapsed)
 elif me.outside>0:status="서클 밖 · 안으로 이동"
 # 2.0.31 인간둔갑: 내 화면에서도 누구로 둔갑했는지 바로 읽게 한다(남의 눈에는 그 도사로만 보임).
 elif mimic_left>0.0:status="인간둔갑"+rules.mimic_label(me)+" · %.1f초" % mimic_left
 else:status="내 역할 · "+("도사" if me.role=="daoist" else "요괴")+" / "+spec.name+(" · 목숨 %s"%hearts(int(me.get("lives",rules.LIVES))) if me.role=="daoist" else "")
 set_text(status_label,status)
 # 안전구역 밖 경고 펄스음(밖에 있는 동안 1.6초 간격).
 if float(me.get("outside",0.0))>0.0:
  warning_sound_left-=get_process_delta_time()
  if warning_sound_left<=0.0:
   warning_sound_left=1.6
   if is_instance_valid(sound):sound.play_clip("zone_warning")
 else:warning_sound_left=0.0
 if aiming():set_text(status_label,"위로 멀리 끌면 취소" if not aim_cancelled else "취소 · 쿨타임 없음")
 set_text(stamina_label,"달리기 %d%%"%int(me.stamina)+(" · 회복 중" if me.exhausted else ""))
 if transformed:
  var form: Dictionary=L.form(me.form)
  var line:="%s 둔갑 · %.1f초 · 움직이며 숨기 · 다시 누르면 해제"%[form.get("name","사물"),form_left]
  set_text(form_label,line);form_label.visible=true
 else:form_label.visible=false
 var hint: String=String(context.get("hint",""))
 if me.captured:hint="봉인됨 · 남은 목숨 %d · 동료가 2.5초 구조하면 목숨을 지킵니다(10초 지나면 목숨 1개 차감)" % int(me.get("lives",3))
 elif me.eliminated:hint="탈락 · 남은 경기를 관전합니다"
 elif me.outside>0:hint="안전구역 밖입니다 · 원 안으로 이동하세요"
 # 하단 힌트 바는 그리지 않는다(가림 방지). 상호작용 안내는 버튼 캡션에만 남긴다.
 if is_instance_valid(hint_label):hint_label.visible=false
 if rules.phase=="countdown":
  var number:=ceili(rules.countdown)
  if number!=last_count:sound.play_clip("button");last_count=number
  count_label.text=str(number);count_label.show()
 else:count_label.visible=rules.elapsed<.55;count_label.text="시작!"
 var spectator: Node=ui.get_node_or_null("Spectator")
 if spectator!=null:spectator.visible=me.eliminated
 # 실제 이동·이벤트에만 발소리/효과음을 낸다.
 if not rules.events.is_empty() and event_cursor<rules.events.size():
  for i in range(event_cursor,rules.events.size()):
   var e: Dictionary=rules.events[i]
   var clip: String=""
   var cast_skill: String=""
   match String(e.kind):
    "seal","miss":clip="seal"
    "rescue","revive","fakerescue":clip="rescue"
    "door":clip="door"
    "transform","untransform":clip="transform"
    "lose_life":clip="seal"
    "outside_damage":clip="zone_warning"
    "gimmick":
     var gk: String=String(e.get("kind",""))
     clip="gimmick_turnstile" if gk=="turnstile" else ("gimmick_cctv" if gk=="cctv" else ("gimmick_lights_off" if gk=="light" and bool(e.get("off",false)) else ("gimmick_lights_on" if gk=="light" else ("gimmick_shutter" if gk=="shutter" else "ui_tap"))))
    "douse":clip="seal"
    # 2.0.31: 시전한 도술 id(e.target)의 맞춤 효과음을 쓴다.
    "skill":cast_skill=String(e.get("target",""))
   var target_name: String=String(rules.players[e.target].name) if rules.players.has(String(e.get("target",""))) else ""
   match String(e.kind):
    "seal":show_banner(target_name+"님이 봉인되었습니다! (10초)",Color("ffb0bf"))
    "rescue":show_banner(target_name+"님이 구출되었습니다!",Color("a8f0d0"))
    "lose_life":show_banner(target_name+"님 목숨 -1 (남은 %d)" % int(rules.players[e.target].get("lives",0)),Color("ffd08a"))
    "revive":show_banner(target_name+"님이 시작 자리에서 다시 일어났습니다",Color("cfe4ff"))
    "eliminate":show_banner(target_name+"님 최종 탈락!",Color("f0a8b8"))
    "skill":
     # 2.0.30: 스킬을 썼는지 바로 읽히게 발동 배너를 띄운다(내 시전은 항상, 남의 시전은 가까울 때).
     var cast_name: String=String(e.get("name",""))
     if String(e.actor)=="human":
      show_banner(("궁극기 · " if String(e.get("slot",""))=="ult" else "")+cast_name+" 발동!",Color("ffe0a8") if me.role=="daoist" else Color("ffc9d8"))
     elif rules.players.has(String(e.actor)) and me.position.distance_to(rules.players[e.actor].position)<700:
      var who: String=String(rules.players[e.actor].get("name",""))
      show_banner(cast_name+" · "+who,Color("cfe4ff") if String(e.get("team",""))=="daoist" else Color("ffb0c8"))
    "skill_fail":
     # 왜 안 됐는지 화면에 그대로 알려 준다(내 시전만).
     if String(e.actor)=="human":
      show_banner(String(e.get("name","도술"))+" — "+String(e.get("reason","지금은 쓸 수 없습니다")),Color("ffc2b8"))
   if (clip!="" or cast_skill!="") and rules.players.has(e.actor):
    if me.position.distance_to(rules.players[e.actor].position)<520:
     if cast_skill!="":sound.play_skill(cast_skill)
     else:sound.play_clip(clip)
    var caster: Node=avatars.get(String(e.actor))
    if caster!=null and String(e.kind) in ["skill","seal","rescue","transform"]:
     caster.action_left=.5
     # 도술마다 다른 발동 모션(시전 고리의 색·형태)을 액터에 전달한다.
     if String(e.kind)=="skill":caster.action_skill=String(e.target)
    if String(e.actor)=="human":
     if String(e.kind)=="door":storage.bump("doors")
     elif String(e.kind)=="transform":storage.bump("disguises")
  event_cursor=rules.events.size()
 if is_instance_valid(sound):
  sound.map_id="seowon"
  sound.update_steps(me.position,me.intent.length()>.05 and live,false)
## ---------------------------------------------------------------- 로비 실화면
## 모든 로비 하위 화면은 scripts/ui/lobby_screen.gd 공통 프레임을 쓴다.
## 빠른 매치 구성은 도사 6 : 요괴 2로 고정이다(사용자·ChatGPT 합의).
var shop: Node
var quick: Node
var achievements_view: Node
var correspondence: Node
var friends: Node

func open_common(view: Script,tab: String="") -> Control:
 var node: Control=view.new()
 node.game=self
 if node.get("initial")!=null:node.set("initial",tab)
 if node.get("match_slots")!=null:node.set("match_slots",match_slots)
 full(node,ui)
 return node

func open_quick() -> void:
 if changing:return
 matching=0.0
 match_slots=1
 transition("quick")

func quick_screen() -> void:
 quick=open_common(preload("res://scripts/survival/matching_view.gd"))

func advance_matching(delta: float) -> void:
 if screen!="quick" or changing:return
 matching+=delta
 var target:=mini(8,1+int(matching/0.45))
 if target!=match_slots:
  match_slots=target
  if is_instance_valid(quick):quick.set_slots(match_slots)

## LoL처럼 중간 대기실 없이 바로 캐릭터 선택 → 맵 로딩 → 인게임으로 직행한다.
func finish_matching() -> void:
 if screen!="quick" or changing:return
 if match_slots<8:match_slots=8
 room={"name":"빠른 매치 · 랜덤 맵","count":8,"fill":true,"code":generate_code(),"yokai":2,"quick":true,"map":String(storage.data.get("debug_map","random"))}
 room_code=String(room.code)
 remember_code(room_code)
 setup_participants()
 room["name"]=String(room.get("name","")).split(" · ")[0]+" · "+Maps.name()
 rules.players.human.ready=true
 if not begin_match():room={};transition("lobby")

## 연습 (봇): 옛 연습장 대신 최신 월하의 서원 8인 봇전으로 직행한다(선택·로딩도 자동).
func start_practice_match() -> void:
 if screen!="lobby" or changing:return
 cleanup_match()
 room={"name":"연습 · 봇전","count":8,"fill":true,"code":generate_code(),"yokai":2,"practice":true,"map":String(storage.data.get("debug_map","random"))}
 room_code=String(room.code)
 setup_participants()
 rules.players.human.ready=true
 if not begin_match():room={};transition("lobby");return
 # 봇과 내 캐릭터를 곧바로 확정하고, 3초 준비 카운트다운만 거쳐 전장으로 들어간다.
 for i in range(200):
  if rules.phase not in ["selection","ready"]:break
  rules.tick(.1)
  if rules.phase=="selection" and not rules.players.human.confirmed:rules.confirm_character("human")
 if rules.phase=="loading":sequence+=1;changing=true;load_match(sequence)

## 친구와 함께: 방 코드를 만들어 공유하거나, 받은 코드로 같은 방에 들어간다.
func friends_screen() -> void:
 friends=open_common(preload("res://scripts/survival/friends_view.gd"))

func Copycode() -> void:
 DisplayServer.clipboard_set(String(room.get("code","")))
 notice("방 코드를 복사했습니다.\n"+String(room.get("code","")))

func Copyinvite() -> void:
 DisplayServer.clipboard_set("도사: 전우치 · "+Maps.name()+"\n방 코드: "+String(room.get("code","")))
 notice("초대 문구를 복사했습니다.\n친구에게 붙여넣어 보내세요.")

func generate_code() -> String:
 var words: Array=["달빛","서원","매화","한옥","밤새","연못","바람","등불"]
 var index:=absi(randi())%words.size()
 return "%s-%04d" % [words[index],absi(randi())%10000]

func remember_code(code: String) -> void:
 var codes: Array=storage.data.room_codes
 codes.erase(code);codes.push_front(code)
 while codes.size()>5:codes.pop_back()
 storage.data.room_codes=codes
 storage.save()

func join_with_code(value: String) -> void:
 var code:=value.strip_edges()
 if code.length()<4:notice("방 코드를 4자 이상 입력해 주세요.");return
 create_room("친구와 함께 · "+code,8,true,code,2)

## 캐릭터 & 캐릭터 스킨 상점: 결제 없는 무료 상점. 재화는 경기·업적·우편 보상뿐이다.
func market_screen() -> void:
 shop=open_common(preload("res://scripts/survival/shop_view.gd"))

func refresh_shop() -> void:
 if is_instance_valid(shop):shop.refresh()
 else:market_screen()

## 스킨·칭호·기운 해금/장착. 테스트와 화면이 같은 경로를 쓴다.
func market_buy(item: Dictionary,kind: String,currency: String="coin") -> void:
 var id: String=String(item.get("id",""))
 if storage.equipped(kind)==id:
  storage.equip(kind,"" if kind!="skin" else "default")
  storage.save();refresh_shop();refresh_lobby_hud();return
 if not storage.owns(id):
  var gem_price:=Market.gem_price(item)
  if currency=="gem" and gem_price>0:
   if not storage.spend_gems(gem_price):notice("보석이 부족합니다. 경기 승리·우편 보상으로 모아 주세요.");return
  else:
   var price:=int(item.get("price",0))
   if not storage.spend_coins(price):notice("코인이 부족합니다. 경기·업적·우편 보상으로 모아 주세요.");return
  storage.own(id)
 storage.equip(kind,id)
 if storage.save()!=OK:notice("장착 상태를 저장하지 못했습니다.")
 refresh_shop()
 refresh_lobby_hud()

## 캐릭터 해금만 한다(2.0.22 상점). 경기 수락 후 캐릭터 선택창에서 고르므로
## 상점 해금은 대표 캐릭터를 바꾸지 않는다.
func shop_unlock_character(id: String) -> void:
 if storage.owns_character(id):refresh_shop();return
 var price:=Market.character_price(id)
 if not storage.spend_coins(price):notice("코인이 부족합니다. 경기·업적·우편 보상으로 모아 주세요.");return
 storage.own_character(id)
 if storage.save()!=OK:notice("캐릭터를 저장하지 못했습니다.")
 refresh_shop()

## 캐릭터 해금: 코인을 내고 보유 목록에 넣은 뒤 그 팀의 대표 캐릭터로 장착한다.
func shop_buy_character(id: String) -> void:
 var team:=String(C.find(id).get("team","daoist"))
 var price:=Market.character_price(id)
 if not storage.owns_character(id):
  if not storage.spend_coins(price):notice("코인이 부족합니다. 경기·업적·우편 보상으로 모아 주세요.");return
  storage.own_character(id)
 storage.data[team]=id
 if storage.save()!=OK:notice("캐릭터를 저장하지 못했습니다.")
 refresh_shop()

## 업적: 실제 경기 기록(storage.stats)으로 진행도가 오르고, 완료 시 코인을 받는다.
func achievements_screen() -> void:
 achievements_view=open_common(preload("res://scripts/survival/achievements_view.gd"))

func claim_achievement(item: Dictionary) -> void:
 var claimed: Array=storage.data.achievements.claimed
 if claimed.has(String(item.id)):return
 if storage.stat(String(item.stat))<int(item.goal):return
 claimed.append(String(item.id))
 # 업적 보상도 코인·보석 모두 실제 지갑에 합산하고 바로 저장한다(중복 수령 불가).
 storage.grant(int(item.reward),int(item.get("gems",0)))
 if storage.save()!=OK:notice("보상을 저장하지 못했습니다.")
 refresh_lobby_hud()
 if is_instance_valid(achievements_view):achievements_view.refresh()
 else:achievements_screen()

## 우편·알림: 시스템 안내와 보상을 확인한다. 보상은 한 번만 받는다.
func mail_screen() -> void:
 correspondence=open_common(preload("res://scripts/survival/correspondence_view.gd"),"mail")

func alerts_screen() -> void:
 correspondence=open_common(preload("res://scripts/survival/correspondence_view.gd"),"alerts")

func open_mail(mail: Dictionary) -> void:
 var read: Array=storage.data.mail.read
 if not read.has(String(mail.id)):read.append(String(mail.id));storage.save()
 if is_instance_valid(correspondence):correspondence.focus_item(String(mail.id))

func claim_mail(mail: Dictionary) -> void:
 var claimed: Array=storage.data.mail.claimed
 if claimed.has(String(mail.id)):return
 claimed.append(String(mail.id))
 # 보상을 받은 편지는 읽은 것으로도 남긴다(배지는 확인·수령이 모두 끝나야 사라진다).
 var read: Array=storage.data.mail.read
 if not read.has(String(mail.id)):read.append(String(mail.id))
 # 우편 동봉 보상(코인 + 보석)을 실제 지갑에 넣고 저장한다. 받은 편지는 다시 수령되지 않는다.
 storage.grant(int(mail.reward),Market.mail_gems(mail))
 if storage.save()!=OK:notice("보상을 저장하지 못했습니다.")
 refresh_lobby_hud()
 refresh_correspondence()

## 우편함의 모든 동봉 보상을 한 번에 수령한다(이미 받은 것은 건너뜀).
func claim_all_mail() -> void:
 for entry in Market.MAILS:
  if (storage.data.mail.claimed as Array).has(String(entry.id)):continue
  claim_mail(entry)
 refresh_correspondence()

## 읽지 않은 우편을 모두 읽음으로 표시한다.
func read_all_mail() -> void:
 for entry in Market.MAILS:
  read_alert(entry)
 refresh_correspondence()

## 읽지 않은 알림을 모두 확인 처리한다.
func read_all_alerts() -> void:
 for entry in Market.ALERTS:
  read_alert(entry)
 refresh_correspondence()

func read_alert(alert: Dictionary) -> void:
 var read: Array=storage.data.alerts.read
 if not read.has(String(alert.id)):read.append(String(alert.id));storage.save()

func refresh_correspondence() -> void:
 if is_instance_valid(correspondence):correspondence.refresh()
 refresh_lobby_hud()

func open_alert(alert: Dictionary) -> void:
 read_alert(alert)
 refresh_correspondence()

## 경기 종료 기록: 업적 진행도와 코인 보상을 실제 저장에 반영한다.
## 2.0.32 매치 보상 내역. 결제 없이 경기만으로 코인·보석을 얻는다(레벨·경험치 없음).
## 승리/패배 · 생존/봉인/구조 성과 · 첫 경기/첫 승리 보너스로 계산한다.
func match_reward() -> Dictionary:
 var me: Dictionary=rules.players.get("human",{}) if rules!=null else {}
 var win: bool=not me.is_empty() and rules!=null and rules.winner==me.role
 var stats: Dictionary=me.get("stats",{}) if not me.is_empty() else {}
 var seals:=int(stats.get("seals",0))
 var rescues:=int(stats.get("rescues",0))
 var first_match: bool=storage.stat("matches")==0
 var first_win: bool=win and storage.stat("wins")==0
 var coins:=120
 var gems:=0
 var lines: Array=["참가 보상 120"]
 if seals>0:
  coins+=seals*40;lines.append("봉인 %d회 +%d"%[seals,seals*40])
 if rescues>0:
  coins+=rescues*30;lines.append("구출 %d회 +%d"%[rescues,rescues*30])
 if win:
  coins+=80;lines.append("승리 +80")
  gems+=2;lines.append("승리 보석 +2")
 if not me.is_empty() and String(me.get("role",""))=="daoist" and not bool(me.get("eliminated",false)):
  coins+=20;lines.append("끝까지 생존 +20")
 if first_match:
  gems+=3;lines.append("첫 경기 보너스 보석 +3")
 if first_win:
  gems+=2;lines.append("첫 승리 보너스 보석 +2")
 if seals>=3:
  gems+=1;lines.append("봉인 3회 보너스 보석 +1")
 return {"coins":coins,"gems":gems,"lines":lines,"win":win,"first_match":first_match,"first_win":first_win}
func record_match() -> void:
 if rules==null or rules.players.is_empty():return
 var reward:=match_reward()
 storage.bump("matches")
 var me: Dictionary=rules.players.get("human",{})
 if not me.is_empty() and rules.winner==me.role:storage.bump("wins")
 if not me.is_empty():
  storage.data.stats.seals=storage.stat("seals")+int(me.stats.get("seals",0))
  storage.data.stats.rescues=storage.stat("rescues")+int(me.stats.get("rescues",0))
 last_reward=reward
 storage.grant(int(reward.coins),int(reward.gems))
 storage.save()
 refresh_lobby_hud()
## 천 단위 콤마(로비 HUD·결과 화면 공통).
func comma(value: int) -> String:
 var text:=str(absi(value))
 var out:=""
 var count:=0
 for i in range(text.length()-1,-1,-1):
  out=text[i]+out
  count+=1
  if count%3==0 and i>0:out=","+out
 return ("-" if value<0 else "")+out
## 2.0.27 전체 지도: 어떤 화면비(20:9 포함)에서도 지도·닫기 버튼이 화면 안에 있어야 한다.
## 팝업의 세로 자동 배치 대신, 화면 크기에 맞춰 지도 한 변을 계산해 직접 배치한다.
func show_map() -> void:
 # 여는 손가락의 여운(같은 터치의 두 번째 이벤트)은 무시한다.
 var now_msec:=Time.get_ticks_msec()
 if now_msec-map_guard_msec<200:return
 map_guard_msec=now_msec
 if modal!=null:close_popup()
 var view:=get_viewport().get_visible_rect().size
 var s:=clampf(view.y/720.0,.62,2.6)
 var overlay:=Control.new();overlay.name="MapOverlay"
 full(overlay,ui)
 overlay.mouse_filter=Control.MOUSE_FILTER_STOP
 modal=overlay;map_overlay=overlay
 var shade:=ColorRect.new();shade.color=Color(.012,.015,.035,.9);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(shade)
 # 바깥(어두운 곳)을 누르면 닫힌다. 지도를 연 손가락이 이 배경까지 닿아도 무시한다.
 shade.gui_input.connect(func(event: InputEvent)->void:
  if Time.get_ticks_msec()-map_guard_msec<200:return
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close_map()
  elif event is InputEventScreenTouch and event.pressed:close_map())
 var header: float=54.0*s
 var pad: float=18.0*s
 var hint_h: float=40.0*s
 var side: float=minf(view.y-header-hint_h-pad*2.6,view.x*.66)
 side=minf(side,1020.0*s)
 var frame_size:=Vector2(side+pad*2.0,side+header+hint_h+pad*2.0)
 var panel:=Panel.new()
 panel.mouse_filter=Control.MOUSE_FILTER_STOP
 var style:=D.panel(Color(.035,.04,.085,.98),int(16*s))
 style.border_color=Color(GOLD,.75);style.set_border_width_all(maxi(1,int(2*s)))
 style.content_margin_left=0;style.content_margin_right=0;style.content_margin_top=0;style.content_margin_bottom=0
 panel.add_theme_stylebox_override("panel",style)
 overlay.add_child(panel)
 panel.size=frame_size
 panel.position=(view-frame_size)*.5
 var title:=text(Maps.name()+" · 전체 지도 (실시간)",int(26*s),Color("f7e4b6"))
 title.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 title.position=Vector2(pad,8*s);title.size=Vector2(frame_size.x-pad*2.0-150*s,header-12*s)
 title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 panel.add_child(title)
 var holder:=Control.new()
 holder.position=Vector2(pad,header);holder.size=Vector2(side,side)
 holder.clip_contents=true
 holder.mouse_filter=Control.MOUSE_FILTER_STOP
 panel.add_child(holder)
 var full_map:=preload("res://scripts/survival/minimap.gd").new();full_map.rules=rules;full_map.observer=spectate
 holder.add_child(full_map);full_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 full_map.map_requested.connect(close_map)
 # 우상단 큰 닫기 버튼(항상 화면 안).
 var close_top:=button("닫기 ✕",close_map,true)
 close_top.name="MapClose"
 close_top.custom_minimum_size=Vector2.ZERO
 panel.add_child(close_top)
 close_top.position=Vector2(frame_size.x-132*s,8*s);close_top.size=Vector2(118*s,header-16*s)
 close_top.add_theme_font_size_override("font_size",int(20*s))
 # 2.0.30 미니맵 범례: 같은 팀만 보이고, 적은 탐지 도술 동안만 나타난다.
 var hint:=text("금빛 테 · 나 / 채운 점 · 같은 팀(도사 파랑 · 요괴 빨강) / 주황 ⊕ = 봉인(구출 필요) · X = 탈락 / 지도는 실시간",int(13*s),Color("cfd7ea"))
 hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(hint)
 hint.position=Vector2(pad,header+side+1*s);hint.size=Vector2(side,20*s)
 var hint2:=text("테두리만 있는 점 = 탐지 도술(천문기계·귀문보기·발자국·야광가루)로 드러난 적",int(12.5*s),Color("a9b6cf"))
 hint2.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(hint2)
 hint2.position=Vector2(pad,header+side+20*s);hint2.size=Vector2(side,20*s)
func close_map() -> void:
 map_guard_msec=Time.get_ticks_msec()
 map_overlay=null
 close_popup()
func back() -> void:
 if changing:return
 if modal!=null:
  if screen=="match":resume_match()
  else:close_popup()
  return
 match screen:
  "title","lobby":confirm("게임을 종료하시겠습니까?",func()->void:get_tree().quit())
  "rooms","quick","friends","market","achievements","mail","alerts":transition("lobby")
  "room":leave_room()
  "characters":transition(selection_return)
  "selection":confirm("선택을 취소하고 로비로 돌아가시겠습니까?",func()->void:cleanup_match();room={};transition("lobby"))
  "practice":
   if is_instance_valid(practice):practice.request_leave()
  "match":pause_menu()
  "result":cleanup_match();room={};transition("lobby")
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:back()
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
  backgrounded=true
  if is_instance_valid(sound):sound.set_backgrounded(true)
  if screen=="match":
   paused=true;D.cancel_controls(ui)
   if is_instance_valid(world):world.process_mode=Node.PROCESS_MODE_DISABLED
 elif what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]:
  backgrounded=false
  if is_instance_valid(sound):sound.set_backgrounded(false)
  if screen=="match" and modal==null:pause_menu()
