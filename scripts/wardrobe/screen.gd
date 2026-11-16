class_name WooWardrobeScreen
extends Node
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/art.gd")
var game: Node
var wardrobe: WooWardrobe
var draft: Dictionary
var slot:="character"
var preview: WooActor
var list: GridContainer
var detail: Label
var save_button: Button
var description: Label
var pose:="idle"
func _ready() -> void:
 wardrobe=game.wardrobe
 wardrobe.refresh(game.rpg.data if game.rpg!=null else game.Save.load_game().get("rpg",{}));wardrobe.save()
 draft=wardrobe.data.appearance.duplicate()
 var stack: VBoxContainer=game.open_modal("wardrobe")
 if stack==null:queue_free();return
 stack.get_parent().custom_minimum_size=Vector2(1180,650)
 stack.add_child(game.text("도사의 옷장   ·   외형만 변경 / 능력치 동일",29,game.GOLD))
 var tabs:=HBoxContainer.new();stack.add_child(tabs)
 var keys:=["character","hair","outfit","hat","accessory","color"]
 var titles:=["캐릭터","헤어","의상","모자","장신구","색상"]
 for i in range(keys.size()):
  var key: String=keys[i];var b: Button=game.button(titles[i],func()->void:slot=key;refresh());b.custom_minimum_size=Vector2(170,60);tabs.add_child(b)
 var row:=HBoxContainer.new();stack.add_child(row)
 var left:=VBoxContainer.new();left.custom_minimum_size=Vector2(380,430);row.add_child(left)
 var stage:=Control.new();stage.custom_minimum_size=Vector2(380,300);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;left.add_child(stage)
 preview=preload("res://scripts/woo/actor.gd").new();preview.position=Vector2(190,275);preview.scale=Vector2(4.6,4.6);stage.add_child(preview);preview.set_physics_process(false);preview.collision_layer=0;preview.collision_mask=0
 description=game.text("",19);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size=Vector2(370,65);left.add_child(description)
 var controls:=HBoxContainer.new();left.add_child(controls)
 for entry in [["방향", "turn"],["걷기","walk"],["점프","jump"],["공격","attack"]]:
  var mode: String=entry[1];var b: Button=game.button(entry[0],func()->void:
   if mode=="turn":preview.facing=(preview.facing+1)%8
   else:pose=mode
  );b.custom_minimum_size=Vector2(85,56);b.add_theme_font_size_override("font_size",17);controls.add_child(b)
 var right:=VBoxContainer.new();right.custom_minimum_size=Vector2(730,430);row.add_child(right)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(730,330);right.add_child(scroll)
 list=GridContainer.new();list.columns=3;scroll.add_child(list)
 detail=game.text("",19);detail.custom_minimum_size=Vector2(720,82);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(detail)
 var footer:=HBoxContainer.new();stack.add_child(footer)
 save_button=game.button("저장 및 돌아가기",save_selection,true);save_button.custom_minimum_size.x=390;footer.add_child(save_button)
 footer.add_child(game.button("변경 취소",close))
 footer.add_child(game.text("서버 확정 누적 %d승"%wardrobe.data.verified_wins,18))
 refresh()
func refresh() -> void:
 for child in list.get_children():list.remove_child(child);child.queue_free()
 var table: Dictionary=C.COLORS if slot=="color" else C.table(slot)
 for id in table:
  if slot=="color" and not C.OUTFITS[draft.outfit].colors.has(id):continue
  var owned:=wardrobe.owned(slot,id)
  var name: String=C.COLOR_NAMES[id] if slot=="color" else table[id].name
  var b: Button=game.button(("✓ " if draft[slot]==id else "")+name+(" 🔒" if not owned else ""),select.bind(id));b.custom_minimum_size=Vector2(231,94);b.add_theme_font_size_override("font_size",17)
  if slot!="color" and table[id].cell>=0:b.icon=Art.icon(table[id].cell);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",50)
  list.add_child(b)
 preview.cosmetic=draft.duplicate();preview.update_sprite()
 description.text=C.CHARACTERS[draft.character].name+"\n"+C.CHARACTERS[draft.character].description
 var value: Dictionary={} if slot=="color" else table[draft[slot]]
 detail.text=(C.COLOR_NAMES[draft.color]+" · 의상에 적용" if slot=="color" else value.name+" · "+("보유" if wardrobe.owned(slot,draft[slot]) else "미보유 / 미리보기만 가능")+"\n"+C.RULES[value.rule])
 save_button.disabled=not wardrobe.valid_selection(draft)
func select(id: String) -> void:
 draft[slot]=id
 # Character identity is independent of the five equipment choices.
 draft=C.normalize(draft);refresh()
func save_selection() -> void:
 var err:=wardrobe.equip(draft)
 if err!=OK:detail.text="저장하지 못했습니다. 변경은 적용되지 않았습니다 · "+str(err);return
 if is_instance_valid(game.player):game.player.cosmetic=draft.duplicate()
 game.apply_appearance_ui()
 close()
func close() -> void:game.close_modal();queue_free()
func _process(delta: float) -> void:
 if not is_instance_valid(game.modal):queue_free();return
 if not is_instance_valid(preview):return
 preview.animation_time+=delta*9
 preview.gait_phase+=delta*9;preview.gait_weight=1.0 if pose=="walk" else 0.0
 preview.velocity=Vector2(50,0) if pose=="walk" else Vector2.ZERO
 preview.jump_height=maxf(0,sin(Time.get_ticks_msec()*.003)*30) if pose=="jump" else 0.0
 if pose=="attack":preview.action_pose=int(Time.get_ticks_msec()/500)%4;preview.pose_duration=.5;preview.action_left=.5-fmod(Time.get_ticks_msec()*.001,.5)
 else:preview.action_left=0
 preview.update_sprite()
