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
var drafts: Dictionary={}
var tab_buttons: Dictionary={}
func _ready() -> void:
 wardrobe=game.wardrobe
 wardrobe.refresh(game.rpg.data if game.rpg!=null else game.Save.load_game().get("rpg",{}));wardrobe.save()
 draft=wardrobe.data.appearance.duplicate()
 var frame:=preload("res://scripts/ui/screen_layout.gd").create(game,"wardrobe","도사의 옷장 · 외형만 변경 / 능력치 동일")
 if frame.is_empty():queue_free();return
 var left:=VBoxContainer.new();left.custom_minimum_size.x=430;left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=.62;frame.body.add_child(left)
 var stage:=Control.new();stage.custom_minimum_size=Vector2(430,350);stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;left.add_child(stage)
 preview=preload("res://scripts/woo/actor.gd").new();preview.position=Vector2(215,335);preview.scale=Vector2.ONE*4.25;stage.add_child(preview);preview.set_physics_process(false);preview.collision_layer=0;preview.collision_mask=0
 description=game.text("",19);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size=Vector2(410,62);left.add_child(description)
 var controls:=HBoxContainer.new();left.add_child(controls)
 for entry in [["방향","turn"],["걷기","walk"],["점프","jump"],["공격","attack"]]:
  var mode: String=entry[1];var b: Button=game.button(entry[0],func()->void:
   if mode=="turn":
    var directions: Array=[2,3,4,5,6,7,0,1];preview.facing=directions[(directions.find(preview.facing)+1)%8]
   else:pose="idle" if pose==mode else mode
  );b.custom_minimum_size=Vector2(92,54);b.add_theme_font_size_override("font_size",16);controls.add_child(b)
 var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.body.add_child(right)
 var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",6);right.add_child(tabs)
 var keys:=["character","hair","outfit","hat","accessory","color"];var titles:=["캐릭터","헤어","의상","모자","장신구","색상"]
 for i in range(keys.size()):
  var key: String=keys[i];var b: Button=game.button(titles[i],func()->void:slot=key;refresh());b.custom_minimum_size=Vector2(98,54);b.add_theme_font_size_override("font_size",16);tabs.add_child(b);tab_buttons[key]=b
 var scroll:=preload("res://scripts/ui/screen_layout.gd").scroll(right)
 list=GridContainer.new();list.columns=4;list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("h_separation",8);list.add_theme_constant_override("v_separation",8);scroll.add_child(list)
 detail=game.text("",18);detail.custom_minimum_size=Vector2(600,100);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(detail)
 save_button=game.button("저장 및 돌아가기",save_selection,true);save_button.custom_minimum_size=Vector2(320,58);frame.footer.add_child(save_button)
 frame.footer.add_child(game.button("변경 취소",close));frame.footer.add_child(game.button("기본 차림",func()->void:draft=C.base_appearance(draft.character);refresh()))
 frame.footer.add_child(game.text("외형은 캐릭터별로 저장됩니다",17))
 preload("res://scripts/ui/screen_layout.gd").gesture(game.modal,scroll)
 refresh()
func refresh() -> void:
 for key in tab_buttons:preload("res://scripts/ui/screen_layout.gd").button_state(tab_buttons[key],key==slot)
 for child in list.get_children():list.remove_child(child);child.queue_free()
 var table: Dictionary=C.COLORS if slot=="color" else C.table(slot)
 for id in table:
  if slot=="color" and not C.OUTFITS[draft.outfit].colors.has(id):continue
  var owned:=wardrobe.owned(slot,id)
  var supported: bool=preload("res://scripts/wardrobe/directional_art.gd").supported(slot,id)
  var name: String=C.COLOR_NAMES[id] if slot=="color" else table[id].name
  var b: Button=game.button(("✓ " if draft[slot]==id else "")+name+(" 🔒" if not owned else "")+(" · 방향 준비 중" if not supported else ""),select.bind(id));b.custom_minimum_size=Vector2(150,128);b.add_theme_font_size_override("font_size",16)
  for mode in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_hover_pressed_color"]:b.add_theme_color_override(mode,Color.TRANSPARENT)
  preload("res://scripts/ui/screen_layout.gd").button_state(b,draft[slot]==id)
  b.disabled=not supported;list.add_child(b)
  if slot=="character":
   var mini:=preload("res://scripts/woo/actor.gd").new();mini.cosmetic=C.base_appearance(id);mini.draw_ground=false;mini.position=Vector2(75,74);mini.scale=Vector2.ONE*1.15;b.add_child(mini);mini.set_physics_process(false);mini.collision_layer=0;mini.collision_mask=0
  elif slot!="color" and table[id].cell>=0:
   var image:=TextureRect.new();image.texture=Art.icon(table[id].cell);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.position=Vector2(45,8);image.size=Vector2(60,60);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(image)
  elif slot=="color":
   var swatch:=ColorRect.new();swatch.color=C.COLORS[id];swatch.position=Vector2(45,14);swatch.size=Vector2(60,48);swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(swatch)
  var label: Label=game.text(name,16,game.GOLD if draft[slot]==id else Color("e8e1cc"));label.position=Vector2(4,78);label.size=Vector2(142,24);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.add_child(label)
  var status: Label=game.text(("✓ 선택" if draft[slot]==id else ("보유" if owned else "잠금 · 미리보기")) if supported else "리소스 준비 중",13);status.position=Vector2(3,103);status.size=Vector2(144,20);status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.add_child(status)
 preview.cosmetic=draft.duplicate();preview.update_sprite()
 description.text=C.CHARACTERS[draft.character].name+"\n"+C.CHARACTERS[draft.character].description
 var value: Dictionary={} if slot=="color" else table[draft[slot]]
 detail.text=(C.COLOR_NAMES[draft.color]+" · 의상에 적용" if slot=="color" else value.name+" · "+("보유" if wardrobe.owned(slot,draft[slot]) else "미보유 / 미리보기만 가능")+"\n"+C.RULES[value.rule])
 var pending: String=preload("res://scripts/wardrobe/directional_art.gd").pending(draft)
 if pending!="":detail.text+="\n"+pending
 save_button.disabled=not wardrobe.valid_selection(draft)
func select(id: String) -> void:
 if slot=="character":
  drafts[draft.character]=draft.duplicate()
  draft=drafts.get(id,wardrobe.appearance_for(id)).duplicate()
 else:draft[slot]=id
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
 preview.position.x=preview.get_parent().size.x/2
 preview.animation_time+=delta*9
 preview.gait_weight=1.0 if pose=="walk" else 0.0
 preview.velocity=Vector2.from_angle(preview.facing*PI/4)*88 if pose=="walk" else Vector2.ZERO
 preview.gait_phase+=preview.velocity.length()*delta*.13
 preview.jump_height=maxf(0,sin(Time.get_ticks_msec()*.003)*20) if pose=="jump" else 0.0
 if pose=="attack":preview.action_pose=int(Time.get_ticks_msec()/500)%4;preview.pose_duration=.5;preview.action_left=.5-fmod(Time.get_ticks_msec()*.001,.5)
 else:preview.action_left=0
 preview.update_sprite()
