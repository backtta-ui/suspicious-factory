class_name WooPopupScroll
extends Node
var scroll: ScrollContainer
var tap: Callable
var finger:=-1
var start:=Vector2.ZERO
var initial:=0
var dragged:=false
func cancel_buttons(node: Node) -> void:
 if node is WooMobileButton:node.cancel()
 for child in node.get_children():cancel_buttons(child)
func _input(event: InputEvent) -> void:
 if not is_instance_valid(scroll) or not scroll.is_visible_in_tree():return
 if event is InputEventScreenTouch:
  if event.pressed and finger<0 and scroll.get_global_rect().has_point(event.position):finger=event.index;start=event.position;initial=scroll.scroll_vertical;dragged=false
  elif not event.pressed and event.index==finger:
   finger=-1
   if dragged:get_viewport().set_input_as_handled()
   elif tap.is_valid() and scroll.get_global_rect().has_point(event.position):tap.call(event.position);get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index==finger:
  if not dragged and start.distance_to(event.position)>12:dragged=true;cancel_buttons(scroll)
  if dragged:scroll.scroll_vertical=initial+roundi(start.y-event.position.y);get_viewport().set_input_as_handled()
