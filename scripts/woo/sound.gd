class_name WooSound
extends Node
## Preloaded local clips and a bounded voice pool: no synthesis or disk IO on touch.
const CLIPS = {
 "attack":preload("res://assets/audio/attack.wav"),
 "hit":preload("res://assets/audio/hit.wav"),
 "reward":preload("res://assets/audio/reward.wav"),
 "button":preload("res://assets/audio/button.wav"),
 "step":preload("res://assets/audio/step.wav"),
 "jar_step":preload("res://assets/audio/jar_step.wav"),
 "spell":preload("res://assets/audio/spell.wav"),
 "dialogue":preload("res://assets/audio/dialogue.wav"),
 "jump":preload("res://assets/audio/jump.wav"),
 "door":preload("res://assets/audio/door.wav"),
 "seal":preload("res://assets/audio/seal.wav"),
 "rescue":preload("res://assets/audio/rescue.wav"),
 "transform":preload("res://assets/audio/transform.wav")
}
const INGAME=preload("res://assets/audio/seowon_ingame.wav")
## 2.0.31 도술별 맞춤 효과음: 도사·도술마다 다른 재질(종이·바람·나무·대나무·현·북·연기·차임)로
## 합성한 30종. `tools/prepare_v31_audio.py`가 만들고 `tools/verify_v31_audio.py`가 검증한다.
const SKILLS={
 "clone":preload("res://assets/audio/skills/clone.wav"),
 "transform":preload("res://assets/audio/skills/transform.wav"),
 "painting":preload("res://assets/audio/skills/painting.wav"),
 "wallhop":preload("res://assets/audio/skills/wallhop.wav"),
 "windstep":preload("res://assets/audio/skills/windstep.wav"),
 "eightleap":preload("res://assets/audio/skills/eightleap.wav"),
 "puppet":preload("res://assets/audio/skills/puppet.wav"),
 "trap":preload("res://assets/audio/skills/trap.wav"),
 "astrolabe":preload("res://assets/audio/skills/astrolabe.wav"),
 "lifelamp":preload("res://assets/audio/skills/lifelamp.wav"),
 "deathflower":preload("res://assets/audio/skills/deathflower.wav"),
 "returnpath":preload("res://assets/audio/skills/returnpath.wav"),
 "ghostgate":preload("res://assets/audio/skills/ghostgate.wav"),
 "soulmark":preload("res://assets/audio/skills/soulmark.wav"),
 "underworldgate":preload("res://assets/audio/skills/underworldgate.wav"),
 "mimic":preload("res://assets/audio/skills/mimic.wav"),
 "foxscent":preload("res://assets/audio/skills/foxscent.wav"),
 "foxdream":preload("res://assets/audio/skills/foxdream.wav"),
 "voicemimic":preload("res://assets/audio/skills/voicemimic.wav"),
 "soundhunt":preload("res://assets/audio/skills/soundhunt.wav"),
 "mountaingrowl":preload("res://assets/audio/skills/mountaingrowl.wav"),
 "mischief":preload("res://assets/audio/skills/mischief.wav"),
 "faketreasure":preload("res://assets/audio/skills/faketreasure.wav"),
 "goblinfest":preload("res://assets/audio/skills/goblinfest.wav"),
 "douse":preload("res://assets/audio/skills/douse.wav"),
 "blackvision":preload("res://assets/audio/skills/blackvision.wav"),
 "moonlessnight":preload("res://assets/audio/skills/moonlessnight.wav"),
 "shoeprints":preload("res://assets/audio/skills/shoeprints.wav"),
 "glowpowder":preload("res://assets/audio/skills/glowpowder.wav"),
 "footprintmap":preload("res://assets/audio/skills/footprintmap.wav")
}
## 로비 음악: tools/prepare_ingame_audio.py가 numpy로 직접 합성한 무저작권 WAV.
const MUSIC=preload("res://assets/audio/lobby_night.wav")
const STEPS=[preload("res://assets/audio/step.wav"),preload("res://assets/audio/step2.wav"),preload("res://assets/audio/step3.wav")]
const SURFACES={"stone":STEPS[0],"grass":preload("res://assets/audio/grass.wav"),"dirt":preload("res://assets/audio/dirt.wav"),"wood":preload("res://assets/audio/wood.wav"),"water":preload("res://assets/audio/water.wav")}
var terrain_stream: AudioStream
var last_surface:="stone"
var nearby_trackers: Dictionary={}
var map_id:="gyewol_village"
var ambience: AudioStreamPlayer
const WIND=preload("res://assets/audio/forest_wind.ogg")
var music: AudioStreamPlayer
var ingame: AudioStreamWAV
var lobby: AudioStreamWAV
var music_enabled:=true
var music_requested:=false
var context:="menu"
var ducked:=false
var backgrounded:=false
var step_index:=0
var enabled := true
var voices: Array[AudioStreamPlayer] = []
var played := 0
## 2.0.31: 어떤 도술 소리를 마지막으로 냈는지(테스트·디버그용).
var last_skill:=""
var skills_played:=0
var step_distance := 0.0
var previous_position := Vector2.ZERO
var tracking := false
func _ready() -> void:
 ambience=AudioStreamPlayer.new();ambience.stream=WIND;ambience.stream.loop=true;ambience.volume_db=-25;add_child(ambience)
 ingame=INGAME.duplicate()
 ingame.loop_mode=AudioStreamWAV.LOOP_FORWARD;ingame.loop_begin=0
 ingame.loop_end=int(ingame.get_length()*ingame.mix_rate)
 lobby=MUSIC.duplicate()
 lobby.loop_mode=AudioStreamWAV.LOOP_FORWARD;lobby.loop_begin=0
 lobby.loop_end=maxi(1,int(lobby.get_length()*lobby.mix_rate)-1)
 music=AudioStreamPlayer.new();music.stream=lobby;music.volume_db=-60;add_child(music)
 set_music_enabled(true)
 for i in range(6):
  var voice:=AudioStreamPlayer.new()
  voice.volume_db=-6
  add_child(voice);voices.append(voice)
func set_context(value: String) -> void:
 if context==value:return
 context=value
 if not is_instance_valid(music):return
 var target: AudioStream=ingame if value=="match" else lobby
 if music.stream==target:return
 var was_playing:=music.playing
 music.stop();music.stream=target
 if was_playing or music_requested:
  if music_enabled and AudioServer.get_driver_name()!="Dummy":music.play()
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
 var wind_on: bool=enabled and not backgrounded and map_id=="fox_forest"
 if is_instance_valid(ambience):
  if not wind_on:ambience.stop()
  elif not ambience.playing and AudioServer.get_driver_name()!="Dummy":ambience.play()
  ambience.volume_db=-32 if ducked else -25
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
 if is_instance_valid(ambience):ambience.stop();ambience.stream=null
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
   voice.stream=(terrain_stream if terrain_stream!=null else STEPS[step_index%STEPS.size()]) if name=="step" else CLIPS[name]
   if name=="step":step_index+=1
   voice.volume_db=-11 if name in ["step","jar_step"] else (-7 if name=="spell" else -10)
   voice.pitch_scale=1.0+(-.025 if step_index%2==0 else .025) if name=="step" else 1.0
   # Dummy has no mixer to retire WAV playbacks (headless/render CI).
   if AudioServer.get_driver_name()!="Dummy": voice.play()
   played+=1;return
## 2.0.31: 도술 id에 맞는 효과음을 낸다. 등록되지 않은 id는 공용 도술음으로 대체한다.
## 내 시전과 주변 인물의 시전 모두 이 함수를 쓴다(2.0.30까지는 전부 'spell' 하나였다).
func play_skill(skill_id: String) -> void:
 if not enabled or backgrounded: return
 if not SKILLS.has(skill_id): play_clip("spell");return
 var stream: AudioStream=SKILLS[skill_id]
 for voice in voices:
  if not voice.playing:
   voice.stream=stream
   voice.volume_db=-8
   voice.pitch_scale=1.0
   if AudioServer.get_driver_name()!="Dummy": voice.play()
   played+=1;skills_played+=1;last_skill=skill_id
   return
func update_steps(p: Vector2, moving: bool, jar: bool) -> void:
 if not tracking: previous_position=p;tracking=true
 var distance:=p.distance_to(previous_position);previous_position=p
 if not moving or distance>20:
  step_distance=0;return
 step_distance+=distance
 if step_distance >= (17.0 if jar else 23.0):
  step_distance=0
  last_surface=preload("res://scripts/woo/terrain_surface.gd").at(p,map_id)
  terrain_stream=STEPS[step_index%STEPS.size()] if last_surface=="stone" else SURFACES[last_surface]
  play_clip("jar_step" if jar else "step")

func update_npc_steps(id: int,p: Vector2,moving: bool,listener: Vector2) -> void:
 var last: Dictionary=nearby_trackers.get(id,{"p":p,"distance":0.0})
 var travel: float=p.distance_to(last.p)
 last.p=p
 if not moving or travel>20 or p.distance_to(listener)>140:last.distance=0.0
 else:last.distance+=travel
 if last.distance>=22:
  last.distance=0.0
  var surface: String=preload("res://scripts/woo/terrain_surface.gd").at(p,map_id)
  var previous:=terrain_stream;terrain_stream=SURFACES[surface]
  play_clip("step");terrain_stream=previous
 nearby_trackers[id]=last
