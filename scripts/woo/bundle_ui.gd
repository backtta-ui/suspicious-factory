class_name WooBundleUI
extends Control
const State=preload("res://scripts/woo/rpg_state.gd")
const Art=preload("res://scripts/woo/item_art.gd")
const STORIES={"potion":["마을의 약방","산약초와 매화꿀을 달여 담은 붉은 약. 먼 여행길에 작은 위로가 된다."],"mana_potion":["계월촌 · 그림 임무","달빛을 머금은 푸른 물. 병 속의 빛은 도사의 숨결을 따라 흐른다."],"seal":["오래된 사당","거친 한지 위에 정성을 담아 쓴 봉인. 오래된 사당의 기운이 아직 남아 있다."],"leaf":["여우의 숲 · 연못 갈림길","이슬이 마르지 않는 잎. 빛나는 잎맥은 그림 속 세계의 물길을 닮았다."],"key":["처음 받은 보따리","오래전 봉인된 사당에서 발견된 열쇠. 아직 어떤 문을 여는지 알려지지 않았다."]}
var adventure: WooAdventure
var selected:="potion"
var category:="전체"
var slots: GridContainer
var detail: VBoxContainer
var inspector: Control
var slot_count:=0
var status: Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=28;margin.offset_right=-28;margin.offset_top=22;margin.offset_bottom=-22;add_child(margin)
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",adventure.game.style(Color("121724"),14));margin.add_child(panel)
 var root:=VBoxContainer.new();root.add_theme_constant_override("separation",8);panel.add_child(root)
 var top:=HBoxContainer.new();root.add_child(top)
 var title: Label=adventure.game.text("전우치의 도술 보따리",28,adventure.game.GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
 status=adventure.game.text("",16);top.add_child(status)
 top.add_child(adventure.game.button("닫기",adventure.game.close_modal))
 var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",5);root.add_child(tabs)
 for name in ["전체","소모품","부적","재료","귀중품","의상"]:
  var b: Button=adventure.game.button(name,func()->void:category=name;rebuild());b.custom_minimum_size=Vector2(112,54);b.add_theme_font_size_override("font_size",18);tabs.add_child(b)
 var content:=HBoxContainer.new();content.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(content)
 var left_column:=VBoxContainer.new();left_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left_column.size_flags_stretch_ratio=3;content.add_child(left_column)
 var left:=ScrollContainer.new();left.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.name="ItemScroll";left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=3;left.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;left_column.add_child(left)
 slots=GridContainer.new();slots.columns=5;slots.add_theme_constant_override("h_separation",7);slots.add_theme_constant_override("v_separation",7);left.add_child(slots)
 var pages:=HBoxContainer.new();left_column.add_child(pages)
 pages.add_child(adventure.game.button("▲ 위로",func()->void:left.scroll_vertical=maxi(0,left.scroll_vertical-300)))
 pages.add_child(adventure.game.button("▼ 아래로",func()->void:left.scroll_vertical+=300))
 var right:=PanelContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.size_flags_stretch_ratio=2;right.add_theme_stylebox_override("panel",adventure.game.style(Color("1b2130"),10));content.add_child(right)
 detail=VBoxContainer.new();detail.add_theme_constant_override("separation",7);right.add_child(detail)
 rebuild()
func clear(container: Node) -> void:
 for child in container.get_children():container.remove_child(child);child.queue_free()
func rebuild() -> void:
 clear(slots);slot_count=0
 var items: Array=[]
 for id in State.ITEMS:
  if adventure.game.rpg.count(id)>0 and (category=="전체" or State.ITEMS[id].kind==category):items.append(id)
 if not items.has(selected):selected=items[0] if not items.is_empty() else ""
 for i in range(30):
  slot_count+=1
  var id: String=items[i] if i<items.size() else ""
  var b: Button=adventure.game.button("",select.bind(id));b.custom_minimum_size=Vector2(112,94);b.name="ItemSlot%d" % i
  b.disabled=id==""
  for child in b.get_children():child.hide()
  var color: Color=State.RARITIES[adventure.game.rpg.data.rarities.get(id,"일반")]
  var box: StyleBoxFlat=adventure.game.style(Color("252137") if id==selected else Color("151b2a"),7);box.border_color=Color("efd18b") if id==selected else color;box.set_border_width_all(3 if id==selected else 1);b.add_theme_stylebox_override("normal",box)
  b.add_theme_stylebox_override("disabled",box)
  slots.add_child(b);b.custom_minimum_size=Vector2(112,94)
  if id!="":
   var art:=Art.new();art.item_id=id;art.position=Vector2(18,1);art.size=Vector2(76,76);b.add_child(art)
   var quantity: Label=adventure.game.text("×%d" % adventure.game.rpg.count(id),16);quantity.position=Vector2(66,72);b.add_child(quantity)
   if not adventure.game.rpg.data.seen_items.has(id):
    var fresh: Label=adventure.game.text("NEW",12,adventure.game.GOLD);fresh.position=Vector2(6,5);b.add_child(fresh)
   var hold:=preload("res://scripts/woo/item_hold.gd").new();hold.callback=inspect_item.bind(id);b.add_child(hold)
 status.text="%d / 30칸  ·  엽전 %d" % [adventure.game.rpg.data.inventory.size(),adventure.game.rpg.data.coins]
 show_detail()
func select(id: String) -> void:
 if id=="" or is_instance_valid(inspector):return
 selected=id
 if not adventure.game.rpg.data.seen_items.has(id):adventure.game.rpg.data.seen_items.append(id);adventure.game.save_progress()
 rebuild()
func show_detail() -> void:
 clear(detail)
 if selected=="":detail.add_child(adventure.game.text("비어 있는 보따리",23,adventure.game.GOLD));return
 var item: Dictionary=State.ITEMS[selected]
 var rarity: String=adventure.game.rpg.data.rarities.get(selected,"일반")
 var title: Label=adventure.game.text(item.name+" · "+rarity,23,State.RARITIES[rarity]);detail.add_child(title)
 var art:=Art.new();art.item_id=selected;art.animated=true;art.custom_minimum_size=Vector2(230,195);detail.add_child(art)
 var description: Label=adventure.game.text(STORIES[selected][1],17);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size.x=310;detail.add_child(description)
 var effect: Label=adventure.game.text("효과: "+item.description+"\n보유 %d개 · 획득: %s" % [adventure.game.rpg.count(selected),STORIES[selected][0]],16);effect.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_child(effect)
 var use: Button=adventure.game.button("사용" if item.has("hp") or item.has("mp") else "보관용 · 사용 불가",use_selected,true)
 use.disabled=not (item.has("hp") or item.has("mp")) or (item.has("hp") and adventure.game.rpg.data.hp>=adventure.game.rpg.max_hp()) or (item.has("mp") and adventure.game.rpg.data.mp>=adventure.game.rpg.max_mp())
 var action_row:=HBoxContainer.new();detail.add_child(action_row);action_row.add_child(use)
 var discard: Button=adventure.game.button("1개 버리기",confirm_discard);discard.add_theme_font_size_override("font_size",15);discard.disabled=item.kind=="귀중품" or adventure.game.rpg.count(selected)<=0;action_row.add_child(discard)
 var inspect: Button=adventure.game.button("확대 감상 · 길게 눌러도 열림",inspect_item.bind(selected));inspect.add_theme_font_size_override("font_size",16);detail.add_child(inspect)
func use_selected() -> void:
 var before: Dictionary=adventure.game.rpg.data.duplicate(true)
 if adventure.game.rpg.use_item(selected):
  adventure.game.save_progress()
  if adventure.game.last_save_error!=OK:adventure.game.rpg.data=before
 rebuild()
func inspect_item(id: String) -> void:
 if is_instance_valid(inspector):return
 for b in find_children("*","Button",true,false):b.set_meta("prior_disabled",b.disabled);b.disabled=true
 inspector=PanelContainer.new();inspector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);inspector.add_theme_stylebox_override("panel",adventure.game.style(Color(.035,.045,.08,.98),12));add_child(inspector)
 var column:=VBoxContainer.new();column.alignment=BoxContainer.ALIGNMENT_CENTER;inspector.add_child(column)
 var title: Label=adventure.game.text(State.ITEMS[id].name,30,adventure.game.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(title)
 var art:=Art.new();art.item_id=id;art.animated=true;art.custom_minimum_size=Vector2(430,350);column.add_child(art)
 var story: Label=adventure.game.text(STORIES[id][1],20);story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(story)
 column.add_child(adventure.game.button("감상 닫기",close_inspector,true))
func close_inspector() -> void:
 for b in find_children("*","Button",true,false):
  if b.has_meta("prior_disabled"):b.disabled=b.get_meta("prior_disabled");b.remove_meta("prior_disabled")
 if is_instance_valid(inspector):inspector.hide();inspector.queue_free()
 inspector=null

func confirm_discard() -> void:
 inspect_item(selected)
 if not is_instance_valid(inspector):return
 var column:=inspector.get_child(0)
 column.add_child(adventure.game.button("1개 버리기 확정",func()->void:
  var before: Dictionary=adventure.game.rpg.data.duplicate(true)
  if adventure.game.rpg.discard_item(selected):
   adventure.game.save_progress()
   if adventure.game.last_save_error!=OK:adventure.game.rpg.data=before
  close_inspector();rebuild()))
