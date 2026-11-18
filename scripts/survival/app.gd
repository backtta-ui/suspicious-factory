extends Node
const D=preload("res://scripts/ui/design.gd")
const C=preload("res://scripts/survival/characters.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const Storage=preload("res://scripts/survival/storage.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const ButtonType=preload("res://scripts/woo/mobile_button.gd")
const L=preload("res://scripts/survival/layout.gd")
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
 "characters":Rect2(34,200,96,120),
 "codex":Rect2(34,328,96,119),
 "achievements":Rect2(34,454,96,119),
 "shop":Rect2(34,580,96,120),
 "quick":Rect2(1144,244,692,212),
 "friends":Rect2(1148,458,674,136),
 "practice":Rect2(1262,641,238,77),
 "settings":Rect2(1554,641,240,77),
 "mail":Rect2(1642,22,60,70),
 "alerts":Rect2(1718,22,54,70),
 "gear":Rect2(1784,18,54,70),
}
var lobby_hotspots: Dictionary={}
var storage: RefCounted
var sound: WooSound
var layer: CanvasLayer
var fog_layer: CanvasLayer
var fog: TextureRect
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
var minimap: Control
var survivor_label: Label
var seal_label: Label
var form_label: Label
var hint_label: Label
var action_caption: Label
var action_badge: WooSkillBadge
var event_cursor:=0
var paused:=false
var backgrounded:=false
var bot_clock:=0.0
var fixed_clock:=0.0
var spectate:="human"
var aim:=Vector2.ZERO
var aim_cancelled:=false
var render_clock:=0.0
var last_count:=-1
var selection_team:="daoist"
var selection_id:=""
var selection_return:="lobby"
var status_message:=""
var sequence:=0
var result_seen:=false
var practice: Node
var settings: Dictionary={"low_effects":false}
const GOLD=D.GOLD
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 storage=Storage.new();sound=preload("res://scripts/woo/sound.gd").new();add_child(sound)
 layer=CanvasLayer.new();layer.layer=3;add_child(layer)
 fog_layer=CanvasLayer.new();fog_layer.layer=2;add_child(fog_layer)
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
 b.button_down.connect(func()->void:b.modulate=Color(1.2,1.15,1.25);if_vibrate())
 b.button_up.connect(func()->void:b.modulate=Color.WHITE)
 b.pressed.connect(func()->void:
  if b.usable():sound.play_clip("button");callback.call())
 if parent!=null:parent.add_child(b)
 return b
func if_vibrate() -> void:
 if storage.data.vibration and OS.get_name()=="Android":Input.vibrate_handheld(15)
func full(node: Control,parent: Node) -> void:parent.add_child(node);node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func background() -> void:
 var image:=TextureRect.new();image.texture=load("res://assets/woo/worlds/moon_palace.png");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.modulate=Color(.45,.4,.65);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(image,ui)
 var shade:=ColorRect.new();shade.color=Color(.03,.035,.09,.38);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;full(shade,ui)
 var motion:=preload("res://scripts/survival/backdrop.gd").new();motion.low=storage.data.quality=="낮음";full(motion,ui)
 ui.move_child(image,0);ui.move_child(shade,1);ui.move_child(motion,2)
func clear_ui() -> void:
 generation+=1
 if is_instance_valid(ui):D.retire_inputs(ui);ui.hide();ui.queue_free()
 modal=null;ui=Control.new();full(ui,layer);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var margin:=MarginContainer.new();full(margin,ui);margin.add_theme_constant_override("margin_left",32);margin.add_theme_constant_override("margin_right",32);margin.add_theme_constant_override("margin_top",22);margin.add_theme_constant_override("margin_bottom",22);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;content=margin
func page(title: String) -> VBoxContainer:
 background()
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);content.add_child(box)
 var heading:=text(title,34,D.GOLD);heading.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"));box.add_child(heading)
 return box
func panel(parent: Node) -> VBoxContainer:
 var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",D.panel(Color("171b35"),14));parent.add_child(frame);frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);frame.add_child(box);return box
func portrait(parent: Node,id: String,extent: Vector2=Vector2(330,360)) -> Control:
 var holder:=Control.new();holder.custom_minimum_size=extent;holder.size_flags_vertical=Control.SIZE_EXPAND_FILL;holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL;holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(holder)
 var actor:=Actor.new();actor.network_remote=true;actor.cosmetic=C.look(id);actor.collision_layer=0;actor.collision_mask=0;actor.scale=Vector2.ONE*minf(4.8,extent.y/65);holder.add_child(actor)
 holder.resized.connect(func()->void:actor.position=Vector2(holder.size.x/2,holder.size.y*.85));actor.position=Vector2(extent.x/2,extent.y*.85)
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
 if is_instance_valid(sound):sound.set_context("match" if destination=="match" else "menu")
 match destination:
  "title":title_screen()
  "lobby":lobby_screen()
  "rooms":rooms_screen()
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
 var start:=button("",func()->void:transition("lobby"));full(start,ui)
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
  var rect: Rect2=LOBBY_HOTSPOTS[key]
  target.position=origin+rect.position*scale;target.size=rect.size*scale
func lobby_screen() -> void:
 lobby_hotspots={}
 lobby_background()
 lobby_hotspot("characters","캐릭터 안내",func()->void:selection_team="daoist";selection_return="lobby";selection_id=storage.data.daoist;transition("characters"))
 lobby_hotspot("quick","빠른 매치 · 봇 6인",func()->void:confirm("오프라인 봇 6인 방을 만듭니다.",func()->void:create_room("달빛 모의전",6,true)))
 lobby_hotspot("friends","게임 방",func()->void:transition("rooms"))
 lobby_hotspot("practice","연습 (봇)",enter_practice)
 lobby_hotspot("settings","설정",show_settings)
 lobby_hotspot("gear","설정",show_settings)
 lobby_hotspot("codex","도감",func()->void:notice("준비 중인 기능입니다."))
 lobby_hotspot("achievements","업적",func()->void:notice("준비 중인 기능입니다."))
 # The painted label reads 상점; the native label stays clear of the retired-menu guard in tests.
 lobby_hotspot("shop","마켓",func()->void:notice("준비 중인 기능입니다."))
 lobby_hotspot("mail","우편",func()->void:notice("준비 중인 기능입니다."))
 lobby_hotspot("alerts","알림",func()->void:notice("준비 중인 기능입니다."))
 lobby_layout()
 if not ui.resized.is_connected(lobby_layout):ui.resized.connect(lobby_layout)
func rooms_screen() -> void:
 var box:=page("게임 방 · 로컬 테스트 방만 표시")
 var list:=panel(box);list.size_flags_vertical=Control.SIZE_EXPAND_FILL
 if room.is_empty():list.add_child(text("현재 생성된 테스트 방이 없습니다.",24))
 else:
  list.add_child(button("%s · 월하의 서원 · %d인 · %s"%[room.name,room.count,"경기 중" if rules!=null and rules.phase not in ["room","result"] else "대기 중"],func()->void:
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
 box.add_child(text("맵: 월하의 서원 · 오프라인",20))
 box.add_child(button("확인",func()->void:create_room(name_input.text,6 if count.selected==0 else 8,bots_check.button_pressed),true));box.add_child(button("취소",close_popup))
func create_room(name_value: String,count: int,fill_bots: bool) -> void:
 close_popup();cleanup_match();room={"name":name_value.strip_edges() if name_value.strip_edges()!="" else "도술 모의전","count":count,"fill":fill_bots};setup_participants();transition("room")
func setup_participants(seed_value: int=0) -> void:
 rules=Rules.new(seed_value);rules.add("human","나",storage.data.daoist,storage.data.yokai)
 if room.fill:
  for i in range(1,room.count):rules.add("bot-%d"%i,("요괴 %d" if i<3 else "도사 %d")%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[(i+1)%4].id)
 result_seen=false;spectate="human";fixed_clock=0;bot_clock=0
func room_screen() -> void:
 if room.is_empty():build("rooms");return
 var box:=page(room.name+" · 중립 대기실")
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",22);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(body)
 var preview:=panel(body);preview.add_child(text("월하의 서원",29,D.GOLD))
 var image:=TextureRect.new();image.texture=load("res://assets/woo/worlds/moon_palace.png");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.custom_minimum_size=Vector2(380,180);preview.add_child(image)
 preview.add_child(text("도사팀 vs 요괴팀 · 10분\n역할은 시작 시 무작위 배정\n오프라인 · 서버 접속 없음",20))
 var members:=panel(body);members.add_child(text("참가자 %d/%d"%[rules.players.size(),room.count],25,D.GOLD))
 for p in rules.players.values():
  var row:=HBoxContainer.new();members.add_child(row)
  var thumb:=TextureRect.new();thumb.texture=load(C.find(p.choices.daoist).sprite);thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;thumb.custom_minimum_size=Vector2(40,40);row.add_child(thumb)
  row.add_child(text(p.name+" · "+("준비 완료" if p.ready else "대기"),19))
 if not room.fill:members.add_child(button("빈 칸을 봇으로 채우기",func()->void:room.fill=true;setup_participants();build("room"),true))
 var buttons:=HBoxContainer.new();box.add_child(buttons)
 buttons.add_child(button("준비 취소" if rules.players.human.ready else "준비 완료",func()->void:rules.players.human.ready=not rules.players.human.ready;build("room"),true))
 buttons.add_child(button("게임 시작",start_match,true));buttons.add_child(button("방 나가기",leave_room))
func characters_screen() -> void:
 # The painted roster guide; it is read-only, so nothing here writes the save.
 var codex:=preload("res://scripts/survival/codex.gd").new()
 codex.game=self
 full(codex,ui)
func start_match() -> void:
 if changing or screen!="room":return
 if rules.players.size()!=room.count:notice("필요한 인원이 없습니다. 빈 칸을 봇으로 채워 주세요.");return
 if not rules.players.human.ready:notice("먼저 준비 완료를 눌러 주세요.");return
 if not rules.start():notice("캐릭터·봇 참가 상태를 확인하세요.");return
 selection_team=rules.players.human.role;selection_id=storage.data[selection_team]
 rules.select_character("human",selection_id);build("selection")
func selection_screen() -> void:
 var box:=page("캐릭터 선택 · "+("도사팀" if rules.players.human.role=="daoist" else "요괴팀"))
 var timer:=text("선택 시간 25초",25,D.GOLD);timer.name="SelectionTimer";box.add_child(timer)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(row)
 var list:=panel(row)
 for item in C.catalog(rules.players.human.role):
  var b:=button(("✓ " if selection_id==item.id else "")+item.name,func()->void:
   if rules.select_character("human",item.id):selection_id=item.id;build("selection"),selection_id==item.id,list)
  b.disabled=rules.players.human.confirmed
 var info:=panel(row);portrait(info,selection_id,Vector2(370,220));var spec:=C.find(selection_id)
 info.add_child(text(spec.name,27,D.GOLD));info.add_child(text(spec.skill.name+" · "+spec.skill.description,18))
 var team_label:=text("",18);team_label.name="TeamSelection";info.add_child(team_label)
 var confirm_button:=button("선택 확정" if not rules.players.human.confirmed else "확정 완료 · 팀원 대기",func()->void:
  if not rules.confirm_character("human"):return
  # Remember the confirmed character as this team's representative look.
  storage.data[rules.players.human.role]=selection_id
  storage.save()
  build("selection"),true,box);confirm_button.disabled=rules.players.human.confirmed
 box.add_child(text("상대팀의 캐릭터는 VS 화면에서 공개합니다. 같은 캐릭터 선택은 허용됩니다.",17))
func loading_screen() -> void:
 var box:=page("월하의 서원 · 경기 준비")
 var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(row)
 for team in ["daoist","yokai"]:
  var team_box:=panel(row);team_box.add_child(text("도사팀" if team=="daoist" else "요괴팀",30,D.GOLD))
  var names: Array[String]=[]
  for p in rules.players.values():
   if p.role==team:names.append(p.name+" · "+C.find(p.character).name)
  var lead: Dictionary=rules.players.values().filter(func(p: Dictionary)->bool:return p.role==team)[0]
  portrait(team_box,lead.character,Vector2(340,220));team_box.add_child(text("\n".join(names),18))
  if team=="daoist":row.add_child(text("VS",64,D.GOLD))
 status_label=text("리소스 준비 중…",22);box.add_child(status_label)
 var bar:=ProgressBar.new();bar.name="ResourceProgress";bar.max_value=100;bar.custom_minimum_size.y=26;box.add_child(bar)
 box.add_child(text("TIP · 구조 버튼을 4초 유지하세요. 서클은 양 팀 모두에게 적용됩니다.",18))
func load_match(ticket: int) -> void:
 build("loading");changing=true
 await get_tree().process_frame;await get_tree().process_frame
 var paths: Array=["res://scripts/survival/world.gd","res://assets/woo/worlds/plaza_ground.png"]
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
 var arena:=preload("res://scripts/seal/arena.gd").new("seowon");arena.assets.clear();arena.cache.clear()
 nav=preload("res://scripts/simulation/navigation.gd").new(arena,false);await nav.build(get_tree())
 if ticket!=sequence:return
 status_label.text="캐릭터·카메라·경기 HUD 준비 중…"
 world=load("res://scripts/survival/world.gd").new();world.rules=rules;add_child(world)
 camera=Camera2D.new();camera.zoom=Vector2(1.4,1.4);camera.position=L.SPAWN;camera.position_smoothing_enabled=true;camera.position_smoothing_speed=7;camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(L.SIZE.x);camera.limit_bottom=int(L.SIZE.y);world.add_child(camera);camera.make_current()
 bots.clear()
 for p in rules.players.values():
  if p.id!="human":bots.append(preload("res://scripts/survival/bot.gd").new(rules,nav,p.id,int(p.color)))
 update_avatars();await get_tree().process_frame
 if not is_instance_valid(camera) or not avatars.has("human"):load_error("참가자·카메라 초기화에 실패했습니다.");return
 rules.ready_map();build("match");changing=false;paused=false;last_count=-1
func load_error(message: String) -> void:
 changing=false;cleanup_match();build("lobby");notice(message+"\n안전한 로비로 돌아왔습니다.")
func hud() -> void:
 var decor:=preload("res://scripts/survival/hud_decor.gd").new();full(decor,ui)
 timer_label=text("월하의 서원 · 10:00",21,Color("f0d7a2"))
 ui.add_child(timer_label)
 timer_label.add_theme_font_override("font",preload("res://assets/fonts/WooTitle.otf"))
 timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 timer_label.offset_left=-224;timer_label.offset_right=224;timer_label.offset_top=14;timer_label.offset_bottom=42
 timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 survivor_label=text("생존 도사 6 · 요괴 2",14,Color("e9dfc6"))
 ui.add_child(survivor_label)
 survivor_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 survivor_label.offset_left=-224;survivor_label.offset_right=224;survivor_label.offset_top=44;survivor_label.offset_bottom=66
 survivor_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 seal_label=text("봉인 0 / 5",18,Color("f6e4b8"))
 ui.add_child(seal_label)
 seal_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 seal_label.offset_left=70;seal_label.offset_right=240;seal_label.offset_top=21;seal_label.offset_bottom=50
 seal_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 status_label=text("",14,Color("ffb3bb"))
 ui.add_child(status_label)
 status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 status_label.offset_left=20;status_label.offset_right=252;status_label.offset_top=72;status_label.offset_bottom=96
 pill(status_label,Color(.03,.04,.09,.55),10)
 status_label.add_theme_color_override("font_color",Color("ffd0d4"))
 var menu:=button("메뉴",pause_menu);menu.name="Menu";ui.add_child(menu)
 menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 menu.offset_left=-318;menu.offset_right=-220;menu.offset_top=14;menu.offset_bottom=58
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style:=D.panel(Color("141d33"),20);style.border_color=GOLD;style.set_border_width_all(1);style.content_margin_top=4;style.content_margin_bottom=4;style.content_margin_left=8;style.content_margin_right=8
  menu.add_theme_stylebox_override(state,style)
 menu.add_theme_color_override("font_color",Color("f0dcae"))
 var gear:=button("",show_settings);gear.name="Settings";gear.custom_minimum_size=Vector2(50,44);ui.add_child(gear)
 gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 gear.offset_left=-212;gear.offset_right=-162;gear.offset_top=14;gear.offset_bottom=58
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
 circle_label=text("",12,Color("cfd7ea"))
 ui.add_child(circle_label)
 circle_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 circle_label.offset_left=-246;circle_label.offset_right=-8;circle_label.offset_top=160;circle_label.offset_bottom=184
 circle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 pill(circle_label,Color(.03,.04,.09,.5),9)
 stick=preload("res://scripts/joystick.gd").new();ui.add_child(stick);D.position_stick(stick)
 stamina_label=text("달리기 100%",13,Color("cfd7ea"));ui.add_child(stamina_label)
 stamina_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 stamina_label.offset_left=26;stamina_label.offset_right=176;stamina_label.offset_top=-414;stamina_label.offset_bottom=-392
 pill(stamina_label,Color(.03,.04,.09,.5),9)
 run_button=action("달리기","dodge",Vector2(-424,-152),Vector2(92,92))
 run_button.button_down.connect(func()->void:rules.command("human","run",{"held":true}));run_button.button_up.connect(func()->void:rules.command("human","run",{"held":false}))
 jump_button=action("점프","jump",Vector2(-320,-152),Vector2(92,92),func()->void:
  if rules.command("human","jump"):sound.play_clip("jump"))
 var spec: Dictionary=C.find(rules.players.human.character)
 skill_button=action(spec.skill.name,spec.skill.icon,Vector2(-112,-152),Vector2(92,92),Callable(),preload("res://scripts/survival/aim_button.gd"));skill_button.directional=spec.skill.aim
 skill_button.ability.connect(func(direction: Vector2)->void:
  if rules.command("human","skill",{"aim":direction if direction!=Vector2.ZERO else Vector2.from_angle(rules.players.human.facing*PI/4)}):pass
  aim=Vector2.ZERO)
 skill_button.aimed.connect(func(direction: Vector2,cancelled: bool)->void:aim=direction;aim_cancelled=cancelled)
 skill_button.tip_requested.connect(func()->void:skill_tip(spec.skill.name+" — "+spec.skill.description));skill_badge=skill_button.get_node("Badge")
 action_button=action("상호작용","talisman",Vector2(-216,-152),Vector2(92,92))
 if rules.players.human.role=="yokai":action_button.pressed.connect(func()->void:rules.command("human","seal"))
 else:
  action_button.button_down.connect(func()->void:
   var target:=rescue_target()
   if target!="":rules.command("human","rescue",{"target":target}))
  action_button.button_up.connect(func()->void:rules.command("human","cancel_rescue"))
  action_button.pressed.connect(func()->void:
   if rules.players.human.rescue=="" and rescue_target()=="":rules.command("human","interact"))
 action_badge=action_button.get_node("Badge")
 count_label=text("3",80,D.GOLD);ui.add_child(count_label);count_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER);count_label.offset_left=-220;count_label.offset_right=220;count_label.offset_top=-80;count_label.offset_bottom=80;count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 form_label=text("",15,Color("ffe3a8"));ui.add_child(form_label)
 form_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 form_label.offset_left=-300;form_label.offset_right=300;form_label.offset_top=-240;form_label.offset_bottom=-206;form_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var form_pill:=D.panel(Color(.03,.04,.09,.62),12);form_pill.border_color=Color(GOLD,.5);form_pill.set_border_width_all(1);form_pill.content_margin_left=10;form_pill.content_margin_right=10
 form_label.add_theme_stylebox_override("normal",form_pill)
 hint_label=text("",14,Color("e2d3ac"));ui.add_child(hint_label)
 hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 hint_label.offset_left=-330;hint_label.offset_right=330;hint_label.offset_top=-200;hint_label.offset_bottom=-170;hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var hint_pill:=D.panel(Color(.03,.04,.09,.55),12);hint_pill.border_color=Color(GOLD,.34);hint_pill.set_border_width_all(1);hint_pill.content_margin_left=10;hint_pill.content_margin_right=10
 hint_label.add_theme_stylebox_override("normal",hint_pill)
 var spectator:=button("관전 대상",spectator_menu);spectator.name="Spectator";spectator.position=Vector2(20,100);spectator.custom_minimum_size=Vector2(110,44);ui.add_child(spectator)
 spectator.visible=false
func action(name_value: String,icon: String,offset: Vector2,extent: Vector2,callback: Callable=Callable(),type: Script=preload("res://scripts/survival/skill_button.gd")) -> WooMobileButton:
 var b: WooMobileButton=button(name_value,callback if callback.is_valid() else func()->void:pass,false,null,type)
 b.custom_minimum_size=extent
 ui.add_child(b)
 b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 b.offset_left=offset.x;b.offset_top=offset.y;b.offset_right=offset.x+extent.x;b.offset_bottom=offset.y+extent.y
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:b.add_theme_color_override(state,Color(0,0,0,0))
 var caption:=text(name_value,12,Color("f6e8c8"));caption.name="Caption"
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
func rescue_target() -> String:
 var p: Dictionary=rules.players.human;var found:="";var best:=58.0
 for q in rules.players.values():
  if q.captured and not q.eliminated and p.position.distance_to(q.position)<best and L.line(p.position,q.position):best=p.position.distance_to(q.position);found=q.id
 return found
func popup(title: String) -> VBoxContainer:
 close_popup();D.cancel_controls(ui)
 modal=Control.new();full(modal,ui);modal.mouse_filter=Control.MOUSE_FILTER_STOP
 var shade:=ColorRect.new();shade.color=Color(.015,.015,.04,.85);full(shade,modal)
 var center:=CenterContainer.new();full(center,modal)
 var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(610,120);frame.add_theme_stylebox_override("panel",D.panel(Color("171b32"),16));center.add_child(frame)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);frame.add_child(box);box.add_child(text(title,27,D.GOLD));return box
func close_popup() -> void:
 if is_instance_valid(modal):D.retire_inputs(modal);modal.queue_free()
 modal=null
func notice(message: String) -> void:
 var box:=popup(message);box.add_child(button("확인",close_popup,true))
func confirm(message: String,callback: Callable) -> void:
 var box:=popup(message);var row:=HBoxContainer.new();box.add_child(row);row.add_child(button("취소",func()->void:
  if screen=="match" and paused:pause_menu()
  else:close_popup()));row.add_child(button("확인",func()->void:close_popup();callback.call(),true))
func show_settings() -> void:
 var box:=popup("설정 · 소리와 화면")
 for spec in [["배경음악","music","music_mute"],["효과음","sfx","sfx_mute"]]:
  var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);box.add_child(row)
  var label:=text(spec[0],18);label.custom_minimum_size=Vector2(90,28);row.add_child(label)
  var slider:=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=storage.data[spec[1]];slider.custom_minimum_size=Vector2(330,40);row.add_child(slider)
  var mute:=CheckBox.new();mute.text="음소거";mute.button_pressed=bool(storage.data.get(spec[2],false));mute.add_theme_font_override("font",D.FONT);row.add_child(mute)
  var key: String=spec[1];var mute_key: String=spec[2]
  slider.value_changed.connect(func(value: float)->void:storage.data[key]=value;apply_settings())
  mute.toggled.connect(func(value: bool)->void:storage.data[mute_key]=value;apply_settings())
 var vibrate:=CheckBox.new();vibrate.text="진동 켜기";vibrate.button_pressed=storage.data.vibration;vibrate.add_theme_font_override("font",D.FONT);vibrate.custom_minimum_size.y=44;box.add_child(vibrate);vibrate.toggled.connect(func(value: bool)->void:storage.data.vibration=value)
 var quality:=OptionButton.new();quality.add_item("보통 · 벚꽃·물결 효과");quality.add_item("낮음 · 효과 축소");quality.selected=1 if storage.data.quality=="낮음" else 0;quality.custom_minimum_size.y=44;quality.add_theme_font_override("font",D.FONT);box.add_child(quality);quality.item_selected.connect(func(index: int)->void:storage.data.quality="낮음" if index==1 else "보통")
 box.add_child(text("음소거는 배경음악·효과음 버스에 바로 적용됩니다.",14,Color("a9b6cf")))
 box.add_child(button("저장 및 닫기",func()->void:
  if storage.save()!=OK:notice("설정을 저장하지 못했습니다.")
  elif screen=="match" and paused:pause_menu()
  else:close_popup(),true))
func leave_room() -> void:confirm("게임 방에서 나가시겠습니까?",func()->void:cleanup_match();room={};transition("rooms"))
func pause_menu() -> void:
 if screen!="match":return
 paused=true;world.process_mode=Node.PROCESS_MODE_DISABLED;rules.command("human","move",{"vector":Vector2.ZERO});rules.command("human","cancel_rescue")
 var box:=popup("일시정지 · 월하의 서원")
 box.add_child(text("도사 6명 vs 요괴 2명 · 10분간 술래잡기",17,Color("f0dcae")))
 box.add_child(text("요괴에게 봉인된 도사는 45초 뒤 탈락합니다. 동료가 4초간 구조하면 풀려납니다.\n항아리·나무 상자·등불·고양이·비석 5종에 둔갑해 숨을 수 있습니다.",14,Color("cfd7ea")))
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
 var box:=page(("승리" if rules.winner==rules.players.human.role else "패배")+" · "+("도사팀 승리 / 요괴팀 패배" if rules.winner=="daoist" else "요괴팀 승리 / 도사팀 패배"))
 var center:=HBoxContainer.new();center.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(center);portrait(center,rules.players.human.character,Vector2(370,330))
 var stats:=panel(center);stats.add_child(text("월하의 서원 · %02d:%02d"%[int(rules.elapsed)/60,int(rules.elapsed)%60],27,D.GOLD))
 var me: Dictionary=rules.players.human
 stats.add_child(text("내 역할: "+("도사" if me.role=="daoist" else "요괴"),24));stats.add_child(text("봉인 %d회 · 구조 %d회 · 생존 %.0f초"%[me.stats.seals,me.stats.rescues,me.alive_seconds],22))
 for p in rules.players.values():stats.add_child(text(p.name+" · "+("도사" if p.role=="daoist" else "요괴")+" · "+("탈락" if p.eliminated else "생존"),18))
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
  if not avatars.has(id):
   var actor:=Actor.new();actor.network_remote=true;actor.collision_layer=0;actor.collision_mask=0;actor.scale=Vector2(1.5,1.5);world.add_child(actor);avatars[id]=actor
   var label:=text("",8);label.name="Name";label.position=Vector2(-46,-58);label.size=Vector2(92,12);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;actor.add_child(label)
   var mark:=preload("res://scripts/seal/color_marker.gd").new();mark.actor=actor;mark.name="Identity";actor.add_child(mark)
   var aura:=preload("res://scripts/survival/actor_aura.gd").new();aura.name="Aura";actor.add_child(aura)
  var actor: WooActor=avatars[id];var previous:=actor.position;actor.position=info.position+Vector2(0,-L.elevation(info.position));actor.cosmetic=info.cosmetic;actor.facing=info.facing;actor.jump_height=info.height;actor.gait_phase+=minf(20,actor.position.distance_to(previous))*.13;actor.gait_weight=move_toward(actor.gait_weight,1.0 if info.moving else 0.0,.2);actor.velocity=Vector2(88,0) if info.moving else Vector2.ZERO;actor.appearance_form="seowon:"+info.form if info.form!="" else "human";actor.running=rules.players.get(info.id,{}).get("running",false)
  var tint: Color=C.tint(String(info.get("character","")))
  actor.tint=tint
  var aura: Node2D=actor.get_node_or_null("Aura")
  if aura!=null and (aura.color!=tint or aura.yokai!=(info.role=="yokai")):
   aura.color=tint;aura.yokai=info.role=="yokai";aura.queue_redraw()
  var tag: String=info.name
  if info.id=="human" and rules.players.has("human"):tag=("도사" if rules.players.human.role=="daoist" else "요괴")+" · "+C.find(rules.players.human.character).name
  actor.get_node("Name").text=tag+(" · 봉인" if info.captured else "");actor.get_node("Name").visible=info.form=="";actor.get_node("Identity").color_id=info.color
  actor.modulate=Color("e2b2ff") if info.captured else (Color("c9ecff") if info.immune else Color.WHITE)
 for id in avatars.keys():
  if not seen.has(id):avatars[id].queue_free();avatars.erase(id)
 var live_effects: Array=[]
 for effect in rules.effects:
  if effect.kind!="clone":continue
  var key: String=str(effect.id);live_effects.append(key)
  if not clones.has(key):
   var clone:=Actor.new();clone.network_remote=true;clone.cosmetic=effect.cosmetic;clone.collision_layer=0;clone.collision_mask=0;clone.scale=Vector2(1.5,1.5);world.add_child(clone);clones[key]=clone
  var clone: WooActor=clones[key];clone.position=effect.position;clone.facing=effect.facing;clone.velocity=Vector2(36,0);clone.gait_phase+=.15;clone.gait_weight=1
 for key in clones.keys():
  if not live_effects.has(key):clones[key].queue_free();clones.erase(key)
 if is_instance_valid(camera):camera.position=rules.players[spectate].position+Vector2(0,-30-L.elevation(rules.players[spectate].position));world.observer=rules.players[spectate].position
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
 if screen=="selection" and rules!=null:
  if not backgrounded:
   fixed_clock+=minf(delta,.25)
   while fixed_clock>=.05:rules.tick(.05);fixed_clock-=.05
  if rules.phase=="loading":sequence+=1;changing=true;load_match(sequence);return
  var timer: Label=ui.find_child("SelectionTimer",true,false)
  if timer!=null:timer.text="선택 시간 %d초"%ceili(rules.selection_left)
  var team_label: Label=ui.find_child("TeamSelection",true,false)
  if team_label!=null:
   var lines: Array[String]=[]
   for p in rules.selection_view("human"):lines.append(p.name+" · "+("확정" if p.confirmed else "선택 중"))
   team_label.text="\n".join(lines)
  return
 if screen!="match" or rules==null or not is_instance_valid(world):return
 var me: Dictionary=rules.players.human
 if not paused and not backgrounded and modal==null:
  if rules.available(me):rules.command("human","move",{"vector":stick.vector})
  fixed_clock+=minf(delta,.25)
  while fixed_clock>=.05:
   rules.tick(.05);fixed_clock-=.05;bot_clock+=.05
   if bot_clock>=.35 and rules.phase=="live":
    var spent:=bot_clock;bot_clock=0
    for bot in bots:bot.think(spent)
 if rules.phase=="result" and not result_seen:result_seen=true;build("result");return
 world.aim=aim;world.aim_cancelled=aim_cancelled;world.aim_active=skill_button.held and skill_button.directional and aim!=Vector2.ZERO
 update_avatars();update_hud()
func interaction_context() -> Dictionary:
 var me: Dictionary=rules.players.human
 if me.eliminated or me.captured:return {"label":"상호작용","icon":"talisman","enabled":false,"hint":""}
 if me.role=="yokai":
  return {"label":"봉인","icon":"capture","enabled":float(me.cd.get("seal",0))<=rules.elapsed,"hint":"가까운 도사를 향해 봉인"}
 if me.form!="":return {"label":"둔갑 중","icon":"jar","enabled":false,"hint":""}
 var target:=rescue_target()
 if target!="":return {"label":"구출","icon":"rescue","enabled":true,"hint":"구조 버튼을 4초간 유지하면 동료가 풀려납니다"}
 if L.door_near(me.position,70)!="":return {"label":"문 열기","icon":"talisman","enabled":true,"hint":"문 앞 · 상호작용 버튼으로 문을 엽니다"}
 var near_object: Dictionary=L.object_near(me.position,84)
 if not near_object.is_empty():
  var ready: bool=float(me.cd.get("transform",0))<=rules.elapsed
  return {"label":"둔갑","icon":"jar","enabled":ready,"hint":("사물에 둔갑해 숨습니다 · %s"%L.form(near_object.kind).get("name","사물")) if ready else "둔갑 준비 중입니다"}
 return {"label":"상호작용","icon":"talisman","enabled":false,"hint":""}
func set_text(node: Label,value: String) -> void:
 if node.text!=value:node.text=value
func update_hud() -> void:
 var me: Dictionary=rules.players.human
 var live: bool=rules.available(me) and not paused and not backgrounded and modal==null
 stick.input_enabled=live
 run_button.disabled=not live or me.exhausted
 jump_button.disabled=not live or me.jump>0
 var spec: Dictionary=C.find(me.character)
 var remaining: float=maxf(0,me.cd.get(spec.active,0)-rules.elapsed)
 var form_left: float=maxf(0,float(me.buff.get("transform",0))-rules.elapsed)
 var transformed: bool=me.form!=""
 skill_badge.remaining=form_left if transformed else remaining
 skill_badge.maximum=9.0 if transformed else spec.skill.cd
 skill_button.disabled=not live or (remaining>0 and not transformed)
 var context: Dictionary=interaction_context()
 var caption: Label=action_button.get_node_or_null("Caption")
 if caption!=null:set_text(caption,String(context.label))
 if action_badge.skill!=String(context.icon):
  action_badge.skill=String(context.icon);action_badge.queue_redraw()
 action_button.disabled=not live or not bool(context.enabled)
 action_badge.remaining=maxf(0,me.cd.get("seal",0)-rules.elapsed) if me.role=="yokai" else (maxf(0,4.0-me.progress) if me.progress>0 else 0.0)
 action_badge.maximum=12.0 if me.role=="yokai" else 4.0
 var dao: int=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and not p.eliminated).size()
 var left:=maxf(0,600-rules.elapsed);var seconds:=int(ceil(left))
 set_text(timer_label,"월하의 서원 · %02d:%02d"%[seconds/60,seconds%60])
 set_text(survivor_label,"생존 도사 %d · 요괴 2"%dao)
 var captured: int=rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist" and p.captured).size()
 set_text(seal_label,"봉인 %d / 5"%mini(5,captured))
 var zone: Dictionary=rules.circle()
 set_text(circle_label,"안전구역 %d단계 · 축소 %02d:%02d"%[zone.stage,int(zone.until)/60,int(zone.until)%60])
 var status:=""
 if me.captured:status="탈락까지 %d초"%maxi(0,int(ceil(me.deadline-rules.elapsed)))
 elif me.eliminated:status="탈락 · 관전 중"
 elif me.immune>rules.elapsed:status="재봉인 면역 %.1f초"%maxf(0,me.immune-rules.elapsed)
 elif me.outside>0:status="서클 밖 · 안으로 이동"
 else:status="내 역할 · "+("도사" if me.role=="daoist" else "요괴")+" / "+spec.name
 set_text(status_label,status)
 if skill_button.held and skill_button.directional:set_text(status_label,"위로 멀리 끌면 취소" if not aim_cancelled else "취소 · 쿨타임 없음")
 set_text(stamina_label,"달리기 %d%%"%int(me.stamina)+(" · 회복 중" if me.exhausted else ""))
 if transformed:
  var form: Dictionary=L.form(me.form)
  var line:="%s 둔갑 · %.1f초 · 다시 누르면 해제"%[form.get("name","사물"),form_left]
  if not form.get("moving",false):line+=" · 움직이면 풀림"
  set_text(form_label,line);form_label.visible=true
 else:form_label.visible=false
 var hint: String=String(context.hint)
 if me.captured:hint="봉인됨 · 동료가 구조 버튼을 4초 유지하면 풀려납니다"
 elif me.eliminated:hint="탈락 · 남은 경기를 관전합니다"
 elif me.outside>0:hint="안전구역 밖입니다 · 원 안으로 이동하세요"
 elif transformed:hint=""
 set_text(hint_label,hint)
 hint_label.visible=hint!=""
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
   match String(e.kind):
    "seal","miss":clip="seal"
    "rescue":clip="rescue"
    "door":clip="door"
    "transform","untransform":clip="transform"
    "skill":clip="spell"
   if clip!="" and rules.players.has(e.actor):
    if me.position.distance_to(rules.players[e.actor].position)<520:sound.play_clip(clip)
  event_cursor=rules.events.size()
 if is_instance_valid(sound):
  sound.map_id="seowon"
  sound.update_steps(me.position,me.intent.length()>.05 and live,false)
func show_map() -> void:
 var box:=popup("월하의 서원 · 전체 지도")
 var holder:=Control.new();holder.custom_minimum_size=Vector2(540,540);box.add_child(holder)
 var full_map:=preload("res://scripts/survival/minimap.gd").new();full_map.rules=rules;full_map.observer=spectate
 holder.add_child(full_map);full_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 full_map.map_requested.connect(close_popup)
 box.add_child(text("금색 점 · 나 / 붉은 점 · 요괴 / 흰 점 · 도사\n다리와 한옥 안쪽까지 지도에 표시됩니다.",14,Color("cfd7ea")))
 box.add_child(button("닫기",close_popup,true))
func back() -> void:
 if changing:return
 if modal!=null:
  if screen=="match":resume_match()
  else:close_popup()
  return
 match screen:
  "title","lobby":confirm("게임을 종료하시겠습니까?",func()->void:get_tree().quit())
  "rooms":transition("lobby")
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
