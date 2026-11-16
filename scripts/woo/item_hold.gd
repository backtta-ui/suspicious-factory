extends Node
var callback: Callable
var elapsed:=0.0
func _process(delta: float) -> void:
 var parent:=get_parent() as WooMobileButton
 if parent.held:
  elapsed+=delta
  if elapsed>=.55:parent.cancel();elapsed=0;callback.call()
 else:elapsed=0
