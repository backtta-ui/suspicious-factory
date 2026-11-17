class_name WooSpellCodex
extends Node
const L=preload("res://scripts/ui/screen_layout.gd")
const Catalog=preload("res://scripts/practice/catalog.gd")
const State=preload("res://scripts/woo/rpg_state.gd")
const CATEGORIES={"transform":"변신","blink":"이동","clone":"보조","track":"보조","shield":"보조","smoke":"보조","mask":"변신","rescue":"보조","capture":"공격","darkness":"보조","fake_flame":"보조","shadow":"이동","mimic":"변신","talisman":"공격"}
var adventure: Node
var game: Node
var selected:="transform"
var category:="전체"
var rows: VBoxContainer
var detail: VBoxContainer
var slots: VBoxContainer
var preview: WooActor
var scroll: ScrollContainer
func _ready() -> void:
 game=adventure.game;game.close_modal()
 var frame:=L.create(game,"spells","도술 도감 · 모험 장착")
 if frame.is_empty():queue_free();return
 var left:=VBoxContainer.new();left.custom_minimum_size.x=304;frame.body.add_child(left)
 var categories:=HBoxContainer.new();categories.add_theme_constant_override("separation",4);left.add_child(categories)
 for title in ["전체","공격","보조","이동","변신"]:
  var b: Button=game.button(title,func()->void:category=title;rebuild_list());b.custom_minimum_size=Vector2(56,48);b.add_theme_font_size_override("font_size",15);categories.add_child(b)
 scroll=L.scroll(left);rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows);L.gesture(game.modal,scroll)
 detail=VBoxContainer.new();detail.add_theme_constant_override("separation",8);detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.custom_minimum_size.x=350;frame.body.add_child(detail)
 slots=VBoxContainer.new();slots.add_theme_constant_override("separation",4);slots.custom_minimum_size.x=270;frame.body.add_child(slots)
 frame.footer.add_child(game.button("메뉴로",func()->void:game.close_modal();adventure.show_menu()))
 frame.footer.add_child(game.button("게임으로",game.close_modal,true))
 frame.footer.add_child(game.text("체험은 습득·장착 기록을 변경하지 않습니다",17))
 rebuild_list();rebuild_detail();rebuild_slots()
func icon(id: String,extent: float) -> Control:
 var badge:=preload("res://scripts/woo/skill_badge.gd").new();badge.skill="jar" if id=="transform" else id;badge.custom_minimum_size=Vector2.ONE*extent;return badge
func clear(node: Node) -> void:
 for child in node.get_children():node.remove_child(child);child.queue_free()
func rebuild_list() -> void:
 clear(rows)
 for id in Catalog.all():
  if category!="전체" and CATEGORIES[id]!=category:continue
  var b: Button=game.button(Catalog.all()[id].name,select.bind(id));b.custom_minimum_size=Vector2(296,76);b.add_theme_font_size_override("font_size",19);b.alignment=HORIZONTAL_ALIGNMENT_RIGHT;L.button_state(b,id==selected);rows.add_child(b)
  for color in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color"]:b.add_theme_color_override(color,Color.TRANSPARENT)
  var title: Label=game.text(Catalog.all()[id].name,19);title.position=Vector2(76,10);b.add_child(title)
  var key: String="jar" if id=="transform" else id
  var learned: bool=State.SPELLS.has(key) and State.SPELLS[key].available
  var status: Label=game.text("습득 · 모험 장착 가능" if learned else "수련 체험 · 모험 장착 미지원",12);status.position=Vector2(76,43);b.add_child(status)
  var image:=icon(id,56);image.position=Vector2(8,10);b.add_child(image)
func select(id: String) -> void:
 if not Catalog.all().has(id):return
 selected=id;rebuild_list();rebuild_detail();rebuild_slots()
func alias() -> String:return "jar" if selected=="transform" else selected
func can_equip() -> bool:return State.SPELLS.has(alias()) and State.SPELLS[alias()].available
func rebuild_detail() -> void:
 clear(detail)
 var info: Dictionary=Catalog.all()[selected]
 detail.add_child(icon(selected,80));detail.add_child(game.text(info.name+" · "+CATEGORIES[selected],25,game.GOLD))
 var description: Label=game.text(info.description,19);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size=Vector2(340,60);detail.add_child(description)
 detail.add_child(game.text("수련 기준 · 재사용 %.1f초 / 지속 %.1f초"%[info.cd,info.get("duration",0)],16))
 detail.add_child(game.text("도력 소모 12" if selected=="talisman" else "체험: 수련장 임시 권한",17))
 var stage:=Control.new();stage.custom_minimum_size=Vector2(340,100);stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;detail.add_child(stage)
 preview=preload("res://scripts/woo/actor.gd").new();preview.cosmetic=game.wardrobe.data.appearance.duplicate();preview.position=Vector2(170,100);preview.scale=Vector2.ONE*1.5;stage.add_child(preview);preview.set_physics_process(false);preview.collision_layer=0;preview.collision_mask=0
 var hint: Label=game.text("동작 미리보기 · 효과는 체험하기에서 확인",14);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_child(hint)
func rebuild_slots() -> void:
 clear(slots);slots.add_child(game.text("장착한 도술 · 최대 3개",22,game.GOLD))
 for i in range(3):
  var id: String=game.rpg.data.slots[i]
  var b: Button=game.button("슬롯 %d  %s"%[i+1,State.SPELLS[id].name if id!="" else "비어 있음"],func()->void:adventure.selected_slot=i;rebuild_slots());b.custom_minimum_size=Vector2(270,60);b.add_theme_font_size_override("font_size",18);L.button_state(b,i==adventure.selected_slot);slots.add_child(b)
 var status: Label=game.text("모험에서 사용 가능" if can_equip() else ("요괴 고유 능력 · 수련 가능" if selected in ["capture","darkness","fake_flame","shadow","mimic"] else "모험 장착 미지원 · 수련 가능"),16);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size=Vector2(270,36);slots.add_child(status)
 var equip: Button=game.button("선택 슬롯에 장착",equip_selected,true);equip.custom_minimum_size.y=54;equip.add_theme_font_size_override("font_size",18);equip.disabled=not can_equip();slots.add_child(equip)
 var remove: Button=game.button("장착 해제",unequip_selected);remove.disabled=game.rpg.data.slots[adventure.selected_slot]=="";remove.custom_minimum_size.y=48;remove.add_theme_font_size_override("font_size",18);slots.add_child(remove)
 var trial: Button=game.button("체험하기",func()->void:game.enter_practice(selected));trial.custom_minimum_size.y=54;trial.add_theme_font_size_override("font_size",18);slots.add_child(trial)
 var note: Label=game.text("온라인 장착은 봉인의 밤 준비 화면에서 설정합니다",15);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;slots.add_child(note)
func equip_selected() -> void:
 if can_equip() and game.rpg.equip(adventure.selected_slot,alias()):game.save_progress();rebuild_slots()
func unequip_selected() -> void:
 if game.rpg.unequip(adventure.selected_slot):game.save_progress();rebuild_slots()
func _process(delta: float) -> void:
 if not is_instance_valid(game.modal) or game.modal_kind!="spells":queue_free();return
 if is_instance_valid(preview):preview.animation_time+=delta*9;preview.action_pose=1;preview.pose_duration=1;preview.action_left=.7;preview.update_sprite()
