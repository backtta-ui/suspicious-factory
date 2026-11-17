extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var result: Dictionary={};var t:=Time.get_ticks_usec();var nav=preload("res://scripts/worlds/plaza_navigation.gd").new();result.nav_new=(Time.get_ticks_usec()-t)/1000.0
 t=Time.get_ticks_usec();var world=preload("res://scripts/worlds/plaza.gd").new();result.world_new=(Time.get_ticks_usec()-t)/1000.0
 t=Time.get_ticks_usec();root.add_child(world);result.world_ready=(Time.get_ticks_usec()-t)/1000.0
 t=Time.get_ticks_usec();var actor=preload("res://scripts/woo/actor.gd").new();world.add_child(actor);result.actor_new_ready=(Time.get_ticks_usec()-t)/1000.0
 print(JSON.stringify(result));var f:=FileAccess.open("res://docs/loading-2.0.10/profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));world.queue_free();await process_frame;quit()
