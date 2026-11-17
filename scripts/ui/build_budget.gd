class_name WooBuildBudget
extends RefCounted
# A CPU budget, not an artificial delay: fast devices continue within the same frame.
const SLICE_USEC=2500
var enabled:=false
var slice_started:=Time.get_ticks_usec()
var yields:=0
func checkpoint(tree: SceneTree) -> void:
 if enabled and Time.get_ticks_usec()-slice_started>=SLICE_USEC:
  yields+=1
  await tree.process_frame
  slice_started=Time.get_ticks_usec()
