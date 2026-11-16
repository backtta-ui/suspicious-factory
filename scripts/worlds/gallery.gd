class_name WooPaintingGallery
extends Control
const Catalog=preload("res://scripts/worlds/catalog.gd")
var adventure: WooAdventure
var selected:=0
var panel: Control
var title: Label
var story: Label
var counter: Label
var enter_button: Button
var busy:=false
var finger:=-1
var start:=Vector2.ZERO
var travel:=0.0
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var game=adventure.game
 var shade:=ColorRect.new();shade.color=Color("101522");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
 var layout:=VBoxContainer.new();layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layout.offset_left=32;layout.offset_right=-32;layout.offset_top=12;layout.offset_bottom=-14;layout.add_theme_constant_override("separation",8);add_child(layout)
 var top:=HBoxContainer.new();layout.add_child(top)
 var heading: Label=game.text("신비로운 그림 세계",26,game.GOLD);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(heading)
 var close: Button=game.button("닫기",game.close_modal);close.custom_minimum_size=Vector2(150,54);top.add_child(close)
 panel=Control.new();panel.custom_minimum_size=Vector2(0,360);panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;panel.clip_contents=true;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.add_child(panel)
 title=game.text("",27,game.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;layout.add_child(title)
 story=game.text("",19);story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;layout.add_child(story)
 var bottom:=HBoxContainer.new();bottom.alignment=BoxContainer.ALIGNMENT_CENTER;layout.add_child(bottom)
 bottom.add_child(game.button("◀ 이전",change.bind(-1)));counter=game.text("",20);counter.custom_minimum_size=Vector2(120,55);counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bottom.add_child(counter)
 bottom.add_child(game.button("다음 ▶",change.bind(1)))
 enter_button=game.button("그림 속으로",enter,true);enter_button.custom_minimum_size=Vector2(280,60);bottom.add_child(enter_button)
 draw_painting();refresh()
func draw_painting() -> void:
 var art:=preload("res://scripts/woo/painting_view.gd").new();art.index=selected;art.reduced=adventure.game.settings.low_effects;art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.offset_left=80;art.offset_right=-80;art.offset_top=4;art.offset_bottom=-4;panel.add_child(art)
func refresh() -> void:
 var world: Dictionary=Catalog.WORLDS[selected]
 adventure.selected_world=world.id;title.text=world.title;story.text=world.description;counter.text="%d / %d"%[selected+1,Catalog.WORLDS.size()];enter_button.disabled=busy or not world.unlocked
func change(step: int) -> void:
 if busy or adventure.transitioning:return
 busy=true;enter_button.disabled=true
 var old:=panel.get_child(panel.get_child_count()-1);selected=posmod(selected+step,Catalog.WORLDS.size());draw_painting();var next:=panel.get_child(panel.get_child_count()-1);next.position.x+=panel.size.x*signi(step)
 var tween:=create_tween().set_parallel(true);tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);tween.tween_property(old,"position:x",old.position.x-panel.size.x*signi(step),.24);tween.tween_property(next,"position:x",80.0,.24)
 await tween.finished
 if not is_inside_tree():return
 old.queue_free();busy=false;refresh()
func enter() -> void:
 if busy or adventure.transitioning:return
 busy=true;enter_button.disabled=true;adventure.selected_world=Catalog.WORLDS[selected].id;adventure.enter_painting()
func _input(event: InputEvent) -> void:
 # Only the illustration region owns swipes; menu controls keep normal GUI release behavior.
 if event is InputEventScreenTouch:
  if event.pressed and finger<0 and panel.get_global_rect().has_point(event.position):finger=event.index;start=event.position;travel=0
  elif not event.pressed and event.index==finger:
   var dx: float=event.position.x-start.x;finger=-1
   if absf(dx)>70 and absf(dx)>absf(event.position.y-start.y)*1.4:change(1 if dx<0 else -1)
 elif event is InputEventScreenDrag and event.index==finger:travel+=event.relative.length()
