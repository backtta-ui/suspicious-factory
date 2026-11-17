extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,text: String) -> void:
 checks+=1
 if ok:print("PASS: "+text)
 else:failures+=1;push_error("FAIL: "+text)
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func buttons(node: Node) -> Array:
 var result: Array=[]
 if node is Button:result.append(node)
 for child in node.get_children():result.append_array(buttons(child))
 return result
func layout(node: Node) -> void:
 var bounded:=true
 for b in buttons(node):
  if not b.is_visible_in_tree():continue
  var parent: Node=b.get_parent();var clipped:=false
  while parent!=node and parent!=null:
   if parent is ScrollContainer:clipped=true
   parent=parent.get_parent()
  if clipped:continue
  if not Rect2(Vector2(16,16),root.get_visible_rect().size-Vector2(32,32)).encloses(b.get_global_rect()):bounded=false;print("OVERFLOW: ",b.text," ",b.get_global_rect())
 check(bounded,"fixed controls stay inside safe viewport")
func touch(p: Vector2,on: bool,id: int=7) -> void:
 var event:=InputEventScreenTouch.new();event.position=root.get_final_transform()*p;event.pressed=on;event.index=id;Input.parse_input_event(event);Input.flush_buffered_events()
func tap(button: Button) -> void:
 var p:=button.get_global_rect().get_center();touch(p,true);await frames(1);touch(p,false);await frames()
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.adventure.show_menu();await frames();check(game.modal_kind=="rpg","main menu opens actual modal");layout(game.modal)
 var customize: Button
 for b in buttons(game.modal):
  if b.text=="꾸미기":customize=b
 await tap(customize);check(game.modal_kind=="wardrobe","native menu card opens actual wardrobe");game.go_back();await frames();check(game.modal==null,"Android back closes wardrobe without saving")
 game.show_wardrobe();await frames();var wardrobe
 for node in game.get_children():
  if node is WooWardrobeScreen:wardrobe=node
 check(wardrobe!=null and wardrobe.preview.scale.x>4,"wardrobe uses enlarged actual actor");layout(game.modal)
 var saved: Dictionary=game.wardrobe.data.appearance.duplicate()
 wardrobe.slot="hat";wardrobe.select("none");await frames();check(wardrobe.preview.cosmetic.hat=="none","none hat renders without dictionary error");wardrobe.close();await frames();check(game.wardrobe.data.appearance==saved,"cancel leaves persistent appearance unchanged")
 game.adventure.show_spells();await frames();var codex
 for node in game.get_children():
  if node is WooSpellCodex:codex=node
 check(codex!=null and codex.rows.get_child_count()==14,"all 14 registered skills listed");layout(game.modal)
 var original: Array=game.rpg.data.slots.duplicate();codex.select("mimic");check(not codex.can_equip(),"role skill cannot enter adventure slots");codex.equip_selected();check(game.rpg.data.slots==original,"unsupported equip leaves slots unchanged")
 codex.select("talisman");game.adventure.selected_slot=2;codex.equip_selected();check(game.rpg.data.slots[2]=="talisman" and game.rpg.data.slots.count("talisman")==1,"real equip moves duplicate into selected slot")
 codex.unequip_selected();check(game.rpg.data.slots[2]=="","real unequip clears chosen slot");game.rpg.data.slots=original
 codex.category="이동";codex.rebuild_list();check(codex.rows.get_child_count()==2,"movement filter follows registered skills");codex.category="전체";codex.rebuild_list();await frames();codex.scroll.scroll_vertical=10000;await frames();check(codex.scroll.scroll_vertical>0,"full list scrolls to later spells")
 var last: Button=codex.rows.get_child(codex.rows.get_child_count()-1);check(codex.scroll.get_global_rect().has_point(last.get_global_rect().get_center()),"last registered spell is reachable above fixed footer")
 await tap(last);check(codex.selected=="talisman","native last-card selection chooses actual spell")
 codex.scroll.scroll_vertical=0;await frames();var center: Vector2=codex.scroll.get_global_rect().get_center();touch(center,true,9)
 var drag:=InputEventScreenDrag.new();drag.index=9;drag.position=root.get_final_transform()*(center-Vector2(0,300));drag.relative=Vector2(0,-300);Input.parse_input_event(drag);Input.flush_buffered_events();await frames();touch(center-Vector2(0,300),false,9);await frames()
 check(codex.scroll.scroll_vertical>100 and codex.selected=="talisman","native drag scrolls without accidental spell selection")
 game.close_modal();await frames()
 for aspect in [Vector2i(1600,720),Vector2i(1280,800)]:
  root.size=aspect;await frames();game.adventure.show_spells();await frames();layout(game.modal);game.close_modal();await frames();game.show_wardrobe();await frames();layout(game.modal);game.close_modal();await frames()
 game.queue_free();await frames();print("UI REDESIGN: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
