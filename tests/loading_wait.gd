extends RefCounted
## Test-only readiness wait. A product load has no artificial timeout.
static func settle(tree: SceneTree,count: int) -> void:
 for i in range(count):await tree.process_frame
 var deadline:=Time.get_ticks_msec()+30000
 while true:
  var busy:=false
  for node in tree.root.get_children():
   if node.has_method("request_start") and not node.loading.failed:
    if node.content_loading or (is_instance_valid(node.adventure) and node.adventure.transitioning):busy=true
  if not busy:return
  if Time.get_ticks_msec()>deadline:push_error("Test readiness deadline exceeded; loading never became ready");tree.quit(1);return
  await tree.process_frame
