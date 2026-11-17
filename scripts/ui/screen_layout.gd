class_name WooScreenLayout
extends RefCounted
const D=preload("res://scripts/ui/design.gd")
static func safe_margin(game: Node,key: String,base: int) -> int:
 if OS.get_name()!="Android":return base
 var safe:=DisplayServer.get_display_safe_area();var display:=DisplayServer.screen_get_size();var view: Vector2=game.get_viewport().get_visible_rect().size
 if display.x<=0 or display.y<=0:return base
 var margins={"left":safe.position.x*view.x/display.x,"right":(display.x-safe.end.x)*view.x/display.x,"top":safe.position.y*view.y/display.y,"bottom":(display.y-safe.end.y)*view.y/display.y}
 return maxi(base,ceili(margins[key])+8)
static func create(game: Node,kind: String,title: String) -> Dictionary:
 var old: VBoxContainer=game.open_modal(kind)
 if old==null:return {}
 old.get_parent().get_parent().hide()
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for key in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+key,safe_margin(game,key,(150 if key in ["left","right"] else 64) if kind=="rpg" else D.SCREEN_MARGIN))
 game.modal.add_child(margin)
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",D.panel(D.PANEL,10));margin.add_child(panel)
 var art:=preload("res://scripts/ui/screen_ornament.gd").new();art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(art)
 var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",14);panel.add_child(stack)
 var heading:=HBoxContainer.new();stack.add_child(heading)
 var label: Label=game.text(title,28,D.GOLD);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(label)
 var close: Button=game.button("닫기 ×",game.close_modal);close.custom_minimum_size=Vector2(112,54);heading.add_child(close)
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",D.SCREEN_GAP);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(body)
 var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",14);stack.add_child(footer)
 return {"body":body,"footer":footer,"close":close,"panel":panel}
static func button_state(button: Button,selected: bool=false) -> void:
 button.add_theme_stylebox_override("normal",D.panel(Color("30465b") if selected else Color("1a273a"),6))
 var style: StyleBoxFlat=button.get_theme_stylebox("normal").duplicate();style.border_color=D.GOLD if selected else Color("43516a");style.set_border_width_all(2 if selected else 1);button.add_theme_stylebox_override("normal",style)
static func scroll(parent: Control) -> ScrollContainer:
 var node:=ScrollContainer.new();node.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;node.size_flags_vertical=Control.SIZE_EXPAND_FILL;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(node);return node
static func gesture(parent: Node,scroll_node: ScrollContainer) -> void:
 var input:=preload("res://scripts/ui/popup_scroll.gd").new();input.scroll=scroll_node;parent.add_child(input)
