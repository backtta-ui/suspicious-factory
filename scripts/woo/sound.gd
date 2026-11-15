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
var enabled := true
var voices: Array[AudioStreamPlayer] = []
var played := 0
var step_distance := 0.0
var previous_position := Vector2.ZERO
var tracking := false
func _ready() -> void:
 for i in range(6):
  var voice:=AudioStreamPlayer.new()
  voice.volume_db=-6
  add_child(voice);voices.append(voice)
func set_enabled(value: bool) -> void:
 enabled=value
 if not enabled:
  for voice in voices: voice.stop()
func shutdown() -> void:
 enabled=false
 for voice in voices:
  voice.stop()
  voice.stream=null
func _exit_tree() -> void:
 shutdown()
func play_clip(name: String) -> void:
 if not enabled or not CLIPS.has(name): return
 for voice in voices:
  if not voice.playing:
   voice.stream=CLIPS[name]
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
