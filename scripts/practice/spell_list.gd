class_name WooPracticeSpellList
extends Control
const C=preload("res://scripts/practice/catalog.gd")
var practice: WooPracticeUI
var selected:="transform"
var scroll: ScrollContainer
var cards: Dictionary={}
var detail: Label
var selected_icon: WooSkillBadge
var finger:=-1
var origin:=Vector2.ZERO
var initial_scroll:=0
var dragged:=false
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 selected=practice.session.selected
 var game=practice.game
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",30);margin.add_theme_constant_override("margin_right",30);margin.add_theme_constant_override("margin_top",24);margin.add_theme_constant_override("margin_bottom",24);add_child(margin)
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",game.style(Color("121d30"),10));margin.add_child(panel)
 var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",12);panel.add_child(stack)
 var heading: Label=game.text("도술 목록 · 자유 체험",27,game.GOLD);stack.add_child(heading)
 var body:=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",18);stack.add_child(body)
 scroll=ScrollContainer.new();scroll.name="SpellScroll";scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=12;body.add_child(scroll)
 var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list)
 for id in C.all():
  var info: Dictionary=C.all()[id];var card:=PanelContainer.new();card.custom_minimum_size=Vector2(0,92);card.mouse_filter=Control.MOUSE_FILTER_PASS;list.add_child(card);cards[id]=card
  var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
  var icon:=preload("res://scripts/woo/skill_badge.gd").new();icon.skill=info.icon;icon.custom_minimum_size=Vector2(70,70);row.add_child(icon)
  var text: Label=game.text(info.name+"\n"+info.description,17);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(text)
  card.gui_input.connect(func(event: InputEvent)->void:
   if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:choose(id))
 var right:=VBoxContainer.new();right.custom_minimum_size=Vector2(330,0);body.add_child(right)
 selected_icon=preload("res://scripts/woo/skill_badge.gd").new();selected_icon.custom_minimum_size=Vector2(100,100);right.add_child(selected_icon)
 detail=game.text("",19);detail.custom_minimum_size=Vector2(320,0);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(detail)
 var footer:=HBoxContainer.new();footer.alignment=BoxContainer.ALIGNMENT_CENTER;stack.add_child(footer)
 var use: Button=game.button("선택하여 수련",func()->void:practice.select(selected),true);use.custom_minimum_size=Vector2(330,66);footer.add_child(use)
 var close: Button=game.button("수련으로",game.close_modal);close.custom_minimum_size=Vector2(230,66);footer.add_child(close)
 var gesture:=preload("res://scripts/ui/popup_scroll.gd").new();gesture.scroll=scroll;gesture.tap=pick_at;add_child(gesture)
 choose(selected)
func choose(id: String) -> void:
 selected=id
 for key in cards:cards[key].add_theme_stylebox_override("panel",practice.game.style(Color("293c57") if key==id else Color("182538"),6))
 var info: Dictionary=C.all()[id];selected_icon.skill=info.icon;detail.text=info.name+"\n\n"+info.description+"\n\n재사용 %.1f초 · 유지 %.1f초\n\n서버 없는 체험입니다. 실제 습득·장착·재화 기록은 바뀌지 않습니다."%[info.cd,info.duration]
func pick_at(point: Vector2) -> void:
 for id in cards:
  if cards[id].get_global_rect().has_point(point):choose(id);break
