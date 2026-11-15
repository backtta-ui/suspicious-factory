extends SceneTree
const Save=preload("res://scripts/woo/save_game.gd")
var checks:=0
var failures:=0
var game: Node
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok: print("PASS: "+label)
 else: failures+=1;push_error("FAIL: "+label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.sound.set_enabled(true)
 check(game.sound.voices.size()==6,"bounded six-voice audio pool")
 for stream in game.sound.CLIPS.values():
  check(stream.get_length()>0.05 and stream.get_length()<1,"local PCM clip has valid bounded duration")
 var count: int=game.sound.played
 game.sound.play_clip("button")
 check(game.sound.played==count+1,"button effect starts a voice")
 game.sound.set_enabled(false)
 game.sound.play_clip("spell")
 check(game.sound.played==count+1 and game.sound.voices.all(func(v: AudioStreamPlayer)->bool:return not v.playing),"mute stops voices and prevents new effects")
 game.sound.set_enabled(true)
 game.start_game(false)
 check(game.world.get_child(0) is Sprite2D,"terrain uses a single pre-baked sprite")
 check(game.world.lanterns.size()>=13 and game.world.lanterns.all(func(v: Sprite2D)->bool:return v.material is CanvasItemMaterial),"expanded additive lanterns without real-time light passes")
 count=game.sound.played
 game.cast_spell()
 check(game.sound.played==count+1,"successful transformation emits effect")
 game.cast_spell()
 check(game.sound.played==count+1,"cooldown prevents repeated spell sound")
 game.sound.set_enabled(false);game.sound.set_enabled(true)
 count=game.sound.played
 game.sound.tracking=false
 game.sound.update_steps(Vector2(900,610),true,false)
 game.sound.update_steps(Vector2(912,610),true,false)
 game.sound.update_steps(Vector2(924,610),true,false)
 check(game.sound.played==count+1,"footstep follows actual travel distance")
 game.sound.update_steps(Vector2(924,610),false,false)
 check(game.sound.played==count+1,"stationary or blocked movement makes no footstep")
 game.sound.update_steps(Vector2(950,610),true,false)
 check(game.sound.played==count+1,"teleport does not emit footstep")
 game.show_settings()
 game.toggle_setting("sound")
 check(not game.settings.sound and not game.sound.enabled and not Save.settings().sound,"sound toggle applies and persists")
 game.toggle_setting("sound");game.close_modal()
 check(game.settings.sound and Save.settings().sound,"sound can be re-enabled")
 game.player.jar=false;game.player.transforming=0
 game.save_progress(true)
 game.save_progress(false)
 check(game.save_thread==null and Save.load_game().position.size()==2,"manual save joins pending async autosave")
 game.player.position=Vector2(916,610)
 game.save_progress(true)
 game.queue_free()
 await process_frame
 await process_frame
 var data:=Save.load_game()
 check(Vector2(data.position[0],data.position[1])==Vector2(916,610),"exit drains asynchronous save without losing position")
 check(ProjectSettings.get_setting("display/window/stretch/mode")=="viewport","phone rendering uses bounded logical viewport")
 print("SOUND/PERFORMANCE: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
