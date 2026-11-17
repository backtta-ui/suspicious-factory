class_name WooMenuHub
extends RefCounted
const Layout=preload("res://scripts/ui/screen_layout.gd")
static func show(adventure: Node) -> void:
 var game=adventure.game;var frame:=Layout.create(game,"rpg","메뉴")
 if frame.is_empty():return
 var center:=CenterContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.body.add_child(center)
 var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);center.add_child(grid)
 var entries=[["캐릭터","현재 능력과 성장 기록",adventure.show_character,"character"],["꾸미기","의상 · 헤어 · 모자 · 장신구",game.show_wardrobe,"outfit"],["도술 도감","도술 정보와 모험 장착",adventure.show_spells,"spell"],["가방","획득한 아이템 감상과 관리",adventure.show_inventory,"bag"],["설정","소리 · 화면 · 게임 환경",game.show_settings,"settings"]]
 for entry in entries:
  var call: Callable=entry[2];var button: Button=game.button(entry[0],func()->void:game.close_modal();call.call());button.custom_minimum_size=Vector2(250,148)
  for color in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:button.add_theme_color_override(color,Color.TRANSPARENT)
  Layout.button_state(button);grid.add_child(button)
  var icon:=preload("res://scripts/ui/menu_icon.gd").new();icon.kind=entry[3];icon.character_id=game.wardrobe.data.appearance.character;icon.position=Vector2(95,8);icon.size=Vector2(60,60);button.add_child(icon)
  var label: Label=game.text(entry[0],23,game.GOLD);label.position=Vector2(8,75);label.size=Vector2(234,30);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.add_child(label)
  var description: Label=game.text(entry[1],15);description.position=Vector2(8,110);description.size=Vector2(234,26);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.add_child(description)
 for item in [["임무 일지",adventure.show_journal],["지도",adventure.show_map]]:frame.footer.add_child(game.button(item[0],item[1]))
 if adventure.in_mission:frame.footer.add_child(game.button("광장으로 돌아가기",adventure.return_to_plaza))
 frame.footer.add_child(game.button("저장하고 메인으로",func()->void:game.close_modal();game.show_menu()))
 frame.footer.add_child(game.button("돌아가기",game.close_modal))
