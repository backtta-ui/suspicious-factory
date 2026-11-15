class_name WooSound
extends Node
## Preloaded local clips and a bounded voice pool: no synthesis or disk IO on touch.
const CLIPS = {
 "button":preload("res://assets/audio/button.wav"),
 "step":preload("res://assets/audio/step.wav"),
 "jar_step":preload("res://assets/audio/jar_step.wav"),
 "spell":preload("res://assets/audio/spell.wav"),
 "dialogue":preload("res://assets/audio/dialogue.wav")
}
const MUSIC=preload("res://assets/audio/moonlit_plaza.ogg")
const STEPS=[preload("res://assets/audio/step.wav"),preload("res://assets/audio/step2.wav"),preload("res://assets/audio/step3.wav")]
var music: AudioStreamPlayer
var music_enabled:=true
var music_requested:=false
var context:="menu"
var ducked:=false
var backgrounded:=false
var step_index:=0
var enabled := true
var voices: Array[AudioStreamPlayer] = []
var played := 0
var step_distance := 0.0
var previous_position := Vector2.ZERO
var tracking := false
func _ready() -> void:
 music=AudioStreamPlayer.new();music.stream=MUSIC;music.stream.loop=true;music.volume_db=-60;add_child(music)
 set_music_enabled(true)
 for i in range(6):
  var voice:=AudioStreamPlayer.new()
  voice.volume_db=-6
  add_child(voice);voices.append(voice)
func set_music_enabled(value: bool) -> void:
 music_enabled=value;music_requested=value
 if not is_instance_valid(music):return
 if not value:music.stop()
 elif not music.playing and AudioServer.get_driver_name()!="Dummy":music.play()
func set_backgrounded(value: bool) -> void:
 backgrounded=value
 if is_instance_valid(music):music.stream_paused=value
 if value:
  for voice in voices:voice.stop()
func _process(delta: float) -> void:
 if is_instance_valid(music):
  var target: float=-20.0 if ducked else (-10.0 if context=="menu" else -15.0)
  music.volume_db=move_toward(music.volume_db,target,delta*16)
func set_enabled(value: bool) -> void:
 enabled=value
 if not enabled:
  for voice in voices: voice.stop()
func shutdown() -> void:
 enabled=false
 music_requested=false
 if is_instance_valid(music):music.stop();music.stream=null
 for voice in voices:
  voice.stop()
  voice.stream=null
func _exit_tree() -> void:
 shutdown()
func play_clip(name: String) -> void:
 if not enabled or backgrounded or not CLIPS.has(name): return
 for voice in voices:
  if not voice.playing:
   voice.stream=STEPS[step_index%STEPS.size()] if name=="step" else CLIPS[name]
   if name=="step":step_index+=1
   voice.volume_db=-11 if name in ["step","jar_step"] else (-7 if name=="spell" else -10)
   voice.pitch_scale=1.0+(step_index%3-1)*0.035 if name=="step" else 1.0
   # Dummy has no mixer to retire WAV playbacks (headless/render CI).
   if AudioServer.get_driver_name()!="Dummy": voice.play()
   played+=1;return
func update_steps(p: Vector2, moving: bool, jar: bool) -> void:
 if not tracking: previous_position=p;tracking=true
 var distance:=p.distance_to(previous_position);previous_position=p
 if not moving or distance>20:
  step_distance=0;return
 step_distance+=distance
 if step_distance >= (17.0 if jar else 23.0):
  step_distance=0
  play_clip("jar_step" if jar else "step")
