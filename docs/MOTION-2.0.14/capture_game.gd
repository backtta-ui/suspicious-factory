extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const P=preload("res://scripts/wardrobe/profile.gd")
func _initialize() -> void:run.call_deferred()
func frames(n: int=8) -> void:
 for i in range(n):await process_frame
func run() -> void:
 root.size=Vector2i(1280,720)
 var old:=C.base_appearance("yeonhwa");old.color="green";old.erase("color_override")
 var file:=FileAccess.open(P.PATH,FileAccess.WRITE);file.store_string(JSON.stringify({"version":2,"appearance":old,"per_character":{"yeonhwa":old},"owned":[]}));file.close()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames();game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/MOTION-2.0.14/yeonhwa-default-pink.png")
 screen.slot="outfit";screen.refresh();await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/MOTION-2.0.14/cosmetic-acquisition-unlocked.png")
 screen.slot="color";screen.select("green");await frames()
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/MOTION-2.0.14/yeonhwa-explicit-green.png")
 screen.save_selection();await frames();game.player.running=true
 var touch:=InputEventScreenTouch.new();touch.index=47;touch.pressed=true;touch.position=game.joystick.global_position+game.joystick.size*.5+Vector2(1,1).normalized()*game.joystick.RADIUS;Input.parse_input_event(touch)
 var samples: Array=[]
 for i in range(12):
  for j in range(3):await physics_frame
  samples.append({"time_ms":Time.get_ticks_msec(),"position":[game.player.position.x,game.player.position.y],"speed":game.player.velocity.length(),"phase":game.player.gait_phase,"skin_visible":game.player.wardrobe_visual.locomotion.visible})
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/MOTION-2.0.14/game-run-%02d.png"%i)
 var report:=FileAccess.open("res://docs/MOTION-2.0.14/game-motion-samples.json",FileAccess.WRITE);report.store_string(JSON.stringify(samples,"  "));report.close()
 var moved: float=Vector2(samples[0].position[0],samples[0].position[1]).distance_to(Vector2(samples.back().position[0],samples.back().position[1]))
 var visible_skin: bool=samples.any(func(sample: Dictionary)->bool:return sample.skin_visible)
 var release:=InputEventScreenTouch.new();release.index=47;release.pressed=false;release.position=touch.position;Input.parse_input_event(release)
 game.player.intent=Vector2.ZERO;game.queue_free();await frames()
 if moved<=10 or not visible_skin:push_error("Native input gameplay capture did not move");quit(1);return
 print("Native input gameplay capture: ",moved," world units, animated skin active");quit()
