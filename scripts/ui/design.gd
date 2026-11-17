class_name WooUIDesign
extends RefCounted
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const PANEL=Color("121d30")
const GOLD=Color("c8ab76")
const INK=Color("111a29")
const TEXT=Color("e8e1cc")
const HP=Color("be5467")
const MANA=Color("538cc1")
const PAD=18
const POPUP_TIME=.12
const BUTTON_HEIGHT=54
const SECONDARY_BORDER=Color("43516a")
const SCREEN_MARGIN=24
const SCREEN_GAP=18
static func button_style(state: String,primary: bool=false) -> StyleBoxFlat:
 var box:=panel(PANEL.lightened(.12) if state=="hover" else (Color("344e69") if state in ["pressed","hover_pressed"] else PANEL),6)
 box.border_color=GOLD if primary else SECONDARY_BORDER
 if state=="disabled":box.bg_color=INK;box.border_color=SECONDARY_BORDER.darkened(.4)
 return box

const VITALS_RECT=Rect2(30,235,242,12)
const STATS_POSITION=Vector2(30,205)
const STICK_SIZE=Vector2(174,174)
const STICK_OFFSET=Vector2(74,-222)
const ACTIONS={"attack":Rect2(-174,-160,138,126),"spell":Rect2(-350,-270,100,90),"interact":Rect2(-138,-388,100,96),"run":Rect2(-292,-144,100,100)}
static func panel(color: Color=PANEL,radius: int=8) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=color;box.border_color=GOLD.darkened(.25);box.set_border_width_all(1);box.set_corner_radius_all(radius)
 box.content_margin_left=20;box.content_margin_right=20;box.content_margin_top=12;box.content_margin_bottom=12;return box
static func place_action(control: Control,id: String) -> void:
 var rect: Rect2=ACTIONS[id];control.custom_minimum_size=rect.size;control.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 control.offset_left=rect.position.x;control.offset_top=rect.position.y;control.offset_right=rect.end.x;control.offset_bottom=rect.end.y
static func decorate(button: Button,skill: String,badge_name: String="SkillBadge") -> WooSkillBadge:
 for child in button.get_children():
  if child is WooOrnament:child.hide()
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:button.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
 for mode in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:button.add_theme_color_override(mode,Color(0,0,0,0))
 var badge: WooSkillBadge=button.get_node_or_null(badge_name)
 if badge==null:
  badge=preload("res://scripts/woo/skill_badge.gd").new();badge.name=badge_name;badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.add_child(badge)
 badge.skill=skill;return badge
static func popup_enter(control: Control) -> void:
 control.modulate.a=0
 control.create_tween().tween_property(control,"modulate:a",1.0,POPUP_TIME)
static func popup_exit(control: Control) -> void:
 # Input is disabled immediately; a retiring popup cannot intercept a new one.
 retire_inputs(control)
 var tween:=control.create_tween();tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tween.tween_property(control,"modulate:a",0.0,POPUP_TIME);tween.tween_callback(control.queue_free)
static func position_stick(stick: Control) -> void:
 var view:=stick.get_viewport().get_visible_rect().size;var left:=0.0;var bottom:=0.0
 if OS.get_name()=="Android":
  var safe:=DisplayServer.get_display_safe_area();var display:=DisplayServer.screen_get_size()
  if display.x>0 and display.y>0:left=float(safe.position.x)*view.x/display.x;bottom=maxf(0,float(display.y-safe.end.y))*view.y/display.y
 stick.size=STICK_SIZE;stick.position=Vector2(STICK_OFFSET.x+left,view.y+STICK_OFFSET.y-bottom)

static func retire_inputs(node: Node) -> void:
 node.set_process_input(false)
 if node is Control:node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if node is WooMobileButton:node.cancel()
 if node is BaseButton:node.disabled=true
 for child in node.get_children():retire_inputs(child)

static func wrap_text(node: Node) -> void:
 if node is Label and node.text.length()>45:
  node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.custom_minimum_size.x=0;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for child in node.get_children():wrap_text(child)
static func interaction(button: Button) -> void:
 var ornament: WooOrnament
 for child in button.get_children():
  if child is WooSkillBadge:child.hide()
  if child is WooOrnament:ornament=child
 if ornament==null:
  ornament=preload("res://scripts/woo/ornament.gd").new();ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.add_child(ornament)
 ornament.show();ornament.circular=true;ornament.icon="talk"
 for mode in ["normal","hover","pressed","hover_pressed","disabled"]:
  var box:=panel(Color("344e69") if mode in ["pressed","hover_pressed"] else INK,56);box.content_margin_left=4;box.content_margin_right=4;box.content_margin_top=52;box.content_margin_bottom=4;box.set_border_width_all(0);button.add_theme_stylebox_override(mode,box)
 for mode in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:button.add_theme_color_override(mode,TEXT if mode!="font_disabled_color" else TEXT.darkened(.5))
 button.add_theme_font_size_override("font_size",17)
static func cancel_controls(node: Node) -> void:
 if node is WooMobileButton:node.cancel()
 if node is TouchJoystick:node.reset()
 for child in node.get_children():cancel_controls(child)
