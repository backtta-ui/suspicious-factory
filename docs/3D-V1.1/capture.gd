extends SceneTree
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=15) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/3D-V1.1/"+name+".png")
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/seowon3d.tscn").instantiate();root.add_child(game);await frames(100)
 print("3D clips: ",game.player.animation.get_animation_list())
 await shot("01-courtyard")
 game.orbit.yaw=PI;await shot("02-character-front")
 game.orbit.yaw=0
 var down:=InputEventScreenTouch.new();down.index=21;down.pressed=true;down.position=game.stick.global_position+game.stick.size/2+Vector2(0,-65);Input.parse_input_event(down)
 var run:=InputEventScreenTouch.new();run.index=22;run.pressed=true;run.position=game.run_button.get_global_rect().get_center();Input.parse_input_event(run)
 for i in range(8):
  await frames(6);await shot("run-%02d"%i)
 var up:=InputEventScreenTouch.new();up.index=21;up.pressed=false;up.position=down.position;Input.parse_input_event(up)
 up=InputEventScreenTouch.new();up.index=22;up.pressed=false;up.position=run.position;Input.parse_input_event(up)
 await frames(12);game.player.jump();await frames(8);await shot("03-jump")
 await frames(60);game.player.global_position=Vector3(-10,0,-4);game.player.velocity=Vector3.ZERO;game.orbit.yaw=0;game.orbit.pitch=15;await frames(50);await shot("04-library-interior")
 game.orbit.yaw=PI/2;await frames(35);await shot("05-indoor-camera")
 game.player.global_position=Vector3(3,0,10);game.orbit.yaw=-.3;await frames(60);await shot("06-pond-and-hanok")
 game.show_menu();await shot("07-menu")
 var f:=FileAccess.open("res://docs/3D-V1.1/capture-info.json",FileAccess.WRITE);f.store_string(JSON.stringify({"platform":"Linux desktop Godot OpenGL software renderer","clips":Array(game.player.animation.get_animation_list()),"actual_3d":true,"android_device":false},"  "));f.close()
 game.queue_free();await frames();quit()
