class_name WooSound
extends Node
## Preloaded local clips and a bounded voice pool: no synthesis or disk IO on touch.
## 2.0.37: 합성음을 모두 버리고 OpenGameArt CC0 실제 녹음으로 교체했다.
## 출처·라이선스는 assets/audio/CC0_SOURCES.md, 재생성은 tools/prepare_v37_audio.py.
const CLIPS = {
 "attack":preload("res://assets/audio/attack.wav"),
 "hit":preload("res://assets/audio/hit.wav"),
 "reward":preload("res://assets/audio/reward.wav"),
 "button":preload("res://assets/audio/button.wav"),
 "step":preload("res://assets/audio/steps/stone_1.wav"),
 "jar_step":preload("res://assets/audio/steps/jar_1.wav"),
 "spell":preload("res://assets/audio/spell.wav"),
 "dialogue":preload("res://assets/audio/dialogue.wav"),
 "jump":preload("res://assets/audio/jump.wav"),
 "door":preload("res://assets/audio/door.wav"),
 "seal":preload("res://assets/audio/seal.wav"),
 "rescue":preload("res://assets/audio/rescue.wav"),
 "transform":preload("res://assets/audio/transform.wav"),
 ## UI·기믹 사운드(나무·종이·금속 실제 녹음).
 "ui_tap":preload("res://assets/audio/ui_tap.wav"),
 "ui_tab":preload("res://assets/audio/ui_tab.wav"),
 "ui_back":preload("res://assets/audio/ui_back.wav"),
 "match_join":preload("res://assets/audio/match_join.wav"),
 "match_found":preload("res://assets/audio/match_found.wav"),
 "lock_in":preload("res://assets/audio/lock_in.wav"),
 "gimmick_turnstile":preload("res://assets/audio/gimmick_turnstile.wav"),
 "gimmick_cctv":preload("res://assets/audio/gimmick_cctv.wav"),
 "gimmick_lights_off":preload("res://assets/audio/gimmick_lights_off.wav"),
 "gimmick_lights_on":preload("res://assets/audio/gimmick_lights_on.wav"),
 "gimmick_shutter":preload("res://assets/audio/gimmick_shutter.wav"),
 "zone_warning":preload("res://assets/audio/zone_warning.wav")
}
## 기존 호출부 호환: button/tab/back을 새 목재·종이 사운드로 연결한다.
const ALIASES={"button":"ui_tap","tab":"ui_tab","back":"ui_back"}
## 2.0.37 바닥 재질별 실제 발소리. 재질마다 3~5개 변형을 돌려 쓰고 피치를 조금씩 흔든다.
## (모두 CC0 실제 녹음 — Fantozzi steps, TinyWorlds kdd steps, Kenney RPG audio, Peludo beach sand)
const STEP_LIBRARY={
 "grass_dirt":[
  preload("res://assets/audio/steps/grass_dirt_1.wav"),
  preload("res://assets/audio/steps/grass_dirt_2.wav"),
  preload("res://assets/audio/steps/grass_dirt_3.wav"),
  preload("res://assets/audio/steps/grass_dirt_4.wav"),
  preload("res://assets/audio/steps/grass_dirt_5.wav")],
 "stone":[
  preload("res://assets/audio/steps/stone_1.wav"),
  preload("res://assets/audio/steps/stone_2.wav"),
  preload("res://assets/audio/steps/stone_3.wav"),
  preload("res://assets/audio/steps/stone_4.wav"),
  preload("res://assets/audio/steps/stone_5.wav")],
 "wood":[
  preload("res://assets/audio/steps/wood_1.wav"),
  preload("res://assets/audio/steps/wood_2.wav"),
  preload("res://assets/audio/steps/wood_3.wav"),
  preload("res://assets/audio/steps/wood_4.wav"),
  preload("res://assets/audio/steps/wood_5.wav")],
 "tile_indoor":[
  preload("res://assets/audio/steps/tile_indoor_1.wav"),
  preload("res://assets/audio/steps/tile_indoor_2.wav"),
  preload("res://assets/audio/steps/tile_indoor_3.wav"),
  preload("res://assets/audio/steps/tile_indoor_4.wav"),
  preload("res://assets/audio/steps/tile_indoor_5.wav")],
 "asphalt":[
  preload("res://assets/audio/steps/asphalt_1.wav"),
  preload("res://assets/audio/steps/asphalt_2.wav"),
  preload("res://assets/audio/steps/asphalt_3.wav"),
  preload("res://assets/audio/steps/asphalt_4.wav"),
  preload("res://assets/audio/steps/asphalt_5.wav")],
 "sand":[
  preload("res://assets/audio/steps/sand_1.wav"),
  preload("res://assets/audio/steps/sand_2.wav"),
  preload("res://assets/audio/steps/sand_3.wav"),
  preload("res://assets/audio/steps/sand_4.wav"),
  preload("res://assets/audio/steps/sand_5.wav")],
 "water":[
  preload("res://assets/audio/steps/water_1.wav"),
  preload("res://assets/audio/steps/water_2.wav"),
  preload("res://assets/audio/steps/water_3.wav"),
  preload("res://assets/audio/steps/water_4.wav"),
  preload("res://assets/audio/steps/water_5.wav")],
 "escalator":[
  preload("res://assets/audio/steps/escalator_1.wav"),
  preload("res://assets/audio/steps/escalator_2.wav"),
  preload("res://assets/audio/steps/escalator_3.wav")],
 "jar":[
  preload("res://assets/audio/steps/jar_1.wav"),
  preload("res://assets/audio/steps/jar_2.wav"),
  preload("res://assets/audio/steps/jar_3.wav")]}
## 2.0.37 도술별 맞춤 효과음 30종 — 실제 악기·금속·종이·공포 녹음을 잘라 만들었다
## (Kenney RPG audio, Vehicle tinysized SFX, JaggedStone magic spells,
##  TinyWorlds horror SFX, congusbongus abyss, Kresiek dark stinger — 모두 CC0).
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
## 로비·맵 BGM: OpenGameArt CC0 게임 음악을 그대로 넣었다(재인코딩 없음).
## 2.0.38 심장 박동(CC0 hit.wav를 저음으로 다듬은 파생음 — 추격 위험 연출).
const HEARTBEAT=preload("res://assets/audio/heartbeat.wav")
const MUSIC=preload("res://assets/audio/bgm/lobby_fantasy.ogg")
const MAP_BGM={
 "seowon":preload("res://assets/audio/bgm/seowon_battle.ogg"),
 "gangnam":preload("res://assets/audio/bgm/gangnam_trance.ogg"),
 "haeundae":preload("res://assets/audio/bgm/haeundae_beach.ogg"),
 "dongseongno":preload("res://assets/audio/bgm/dongseongno_urban.ogg")}
## 곡마다 녹음 레벨이 달라, 같은 세기로 들리도록 측정한 게인(dB)을 준다.
## tools/verify_v37_audio.py가 실제 피크·RMS로 이 표를 검사한다.
const BGM_GAIN_DB={
 "lobby_fantasy":5.0,"seowon_battle":-8.0,"gangnam_trance":-6.5,
 "haeundae_beach":1.5,"dongseongno_urban":-4.5}
## 2.0.38 맵별 환경음(CC0 실제 녹음). 강남=도심 인파, 동성로=차량 통행,
## 해운대=파도·바닷바람, 서원=밤바람. 출처는 assets/audio/CC0_SOURCES.md.
const AMBIENCE={
 "gangnam":["res://assets/audio/ambience/amb_gangnam_city.ogg"],
 "dongseongno":["res://assets/audio/ambience/amb_dongseongno_traffic.ogg"],
 "haeundae":["res://assets/audio/ambience/water_flowing.ogg","res://assets/audio/forest_wind.ogg"],
 "seowon":["res://assets/audio/forest_wind.ogg"]}
const AMBIENCE_DB=-27.0
## 추격 긴장: 요괴가 가까울수록 BGM 피치·볼륨이 올라가고 심장 박동이 빨라진다.
const HEARTBEAT_DB=-11.0
const MUSIC_MENU_DB=-7.0
const MUSIC_MATCH_DB=-10.0
const STEP_DB=-9.0
const SKILL_DB=-11.0
var terrain_stream: AudioStream
var last_surface:="stone"
var nearby_trackers: Dictionary={}
var map_id:="seowon"
## 지금 깔린 경기 BGM의 맵 id(서원/강남역/해운대/동성로).
var current_map:="seowon"
var ambience: AudioStreamPlayer
## 맵 환경음 2겹(파도+바람처럼 겹쳐 깔린다).
var ambient_layers: Array[AudioStreamPlayer] = []
## 2.0.38 위치 기반 효과음: AudioStreamPlayer2D가 거리 감쇠·좌우 패닝을 담당한다.
var spatial_voices: Array[AudioStreamPlayer2D] = []
var sound_world: Node=null
var listener:=Vector2.ZERO
var listener_ready:=false
## 지금 재생 중인 경기 BGM 원본(추격 시 피치를 올린다).
var base_music_pitch:=1.0
var tension:=0.0
var tension_target:=0.0
var heartbeat_clock:=0.0
var danger_was:=false
var chase_started:=false
var layout_script: Script=null
const WIND=preload("res://assets/audio/forest_wind.ogg")
var music: AudioStreamPlayer
var lobby_track: AudioStream
var music_level: float=MUSIC_MENU_DB
var music_gain: float=0.0
var music_enabled:=true
var music_requested:=false
var context:="menu"
var ducked:=false
var backgrounded:=false
var step_index:=0
var step_cursor: Dictionary={}
var steps_played:=0
var enabled := true
var voices: Array[AudioStreamPlayer] = []
var played := 0
## 어떤 도술 소리를 마지막으로 냈는지(테스트·디버그용).
var last_skill:=""
## 마지막으로 낸 일반 클립(테스트·디버그용).
var last_clip:=""
var clips_played:=0
var skills_played:=0
var step_distance := 0.0
var previous_position := Vector2.ZERO
var tracking := false
func _ready() -> void:
 _ensure_buses()
 ambience=AudioStreamPlayer.new();ambience.stream=WIND;ambience.stream.loop=true;ambience.volume_db=-25
 ambience.bus="Ambience"
 add_child(ambience)
 for i in range(2):
  var layer:=AudioStreamPlayer.new();layer.bus="Ambience";layer.volume_db=AMBIENCE_DB;add_child(layer)
  ambient_layers.append(layer)
 lobby_track=_loopable(MUSIC)
 music=AudioStreamPlayer.new();music.stream=lobby_track;music.volume_db=-60;music.bus="DosaMusic";add_child(music)
 set_music_enabled(true)
 for i in range(8):
  var voice:=AudioStreamPlayer.new()
  voice.volume_db=-6;voice.bus="DosaSfx"
  add_child(voice);voices.append(voice)
## OGG/WAV를 코드에서 확실히 반복 재생한다(가져오기 설정과 무관하게).
func _loopable(stream: AudioStream) -> AudioStream:
 if stream is AudioStreamOggVorbis:
  var ogg: AudioStreamOggVorbis=(stream as AudioStreamOggVorbis).duplicate()
  ogg.loop=true
  ogg.loop_offset=0.0
  return ogg
 if stream is AudioStreamWAV:
  var wav: AudioStreamWAV=(stream as AudioStreamWAV).duplicate()
  wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
  wav.loop_begin=0
  wav.loop_end=maxi(1,int(wav.get_length()*wav.mix_rate)-1)
  return wav
 return stream
## 파일 이름으로 측정된 곡 게인을 찾는다(맵·로비 공통).
func _gain_for(path: String) -> float:
 for key in BGM_GAIN_DB:
  if path.contains(String(key)):return float(BGM_GAIN_DB[key])
 return 0.0
func _play_music(target: AudioStream,level: float) -> void:
 if not is_instance_valid(music):return
 music_level=level
 if music.stream==target:
  return
 var was_playing:=music.playing
 music.stop()
 music.stream=target
 if was_playing or music_requested:
  if music_enabled and AudioServer.get_driver_name()!="Dummy":music.play()
## 맵 id에 따라 BGM을 갈아 끼운다. 서원=긴장된 판타지 배틀, 강남역=도심 트랜스,
## 해운대=해변 펑키, 동성로=네온 업비트.
func play_map_bgm(map_id_value: String) -> void:
 current_map=map_id_value
 tension=0.0;tension_target=0.0;chase_started=false;heartbeat_clock=0.0
 play_map_ambience(map_id_value,1 if preload("res://scripts/survival/quality.gd").low else 2)
 var source: AudioStream=MAP_BGM.get(map_id_value,MAP_BGM["seowon"])
 var target: AudioStream=_loopable(source)
 music_gain=_gain_for(source.resource_path)
 _play_music(target,MUSIC_MATCH_DB if context=="match" else MUSIC_MENU_DB)
## 매칭 합류: 인원이 늘수록 음이 올라가는 영롱한 차임.
func play_match_join(count: int) -> void:
 if not enabled or backgrounded or not CLIPS.has("match_join"):return
 _play(CLIPS["match_join"],-10.0,pow(2.0,clampf(float(count)/12.0,0.0,1.0)),"match_join")
func set_context(value: String) -> void:
 if context==value:return
 context=value
 if value=="match":
  var source: AudioStream=MAP_BGM.get(current_map,MAP_BGM["seowon"])
  music_gain=_gain_for(source.resource_path)
  _play_music(_loopable(source),MUSIC_MATCH_DB)
 else:
  music_gain=_gain_for(MUSIC.resource_path)
  _play_music(lobby_track,MUSIC_MENU_DB)
  stop_ambience()
  tension=0.0;tension_target=0.0;chase_started=false
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
## 발소리가 BGM에 묻히지 않도록 BGM은 낮게 깔고, 위험·구출 클립만 크게 낸다.
func _process(delta: float) -> void:
 var wind_on: bool=enabled and not backgrounded and map_id=="fox_forest"
 if is_instance_valid(ambience):
  if not wind_on:ambience.stop()
  elif not ambience.playing and AudioServer.get_driver_name()!="Dummy":ambience.play()
  ambience.volume_db=-32 if ducked else -25
 if is_instance_valid(music):
  var target: float=music_level+music_gain+(-9.0 if ducked else 0.0)+tension*1.8
  music.volume_db=move_toward(music.volume_db,target,delta*16)
  music.pitch_scale=move_toward(music.pitch_scale,base_music_pitch+tension*0.06,delta*0.2)
 _tick_heartbeat(delta)
## 2.0.38 오디오 버스 분리: Music / SFX / Ambience + Master 리미터(클리핑 방지).
func _ensure_buses() -> void:
 for bus_name in ["DosaMusic","DosaSfx","Ambience"]:
  if AudioServer.get_bus_index(bus_name)<0:
   AudioServer.add_bus()
   var index:=AudioServer.bus_count-1
   AudioServer.set_bus_name(index,bus_name)
   AudioServer.set_bus_send(index,"Master")
 var master:=AudioServer.get_bus_index("Master")
 # 헤드리스(Dummy 드라이버)에서는 오디오 서버가 종료 시 효과 리소스를 붙잡으므로 만들지 않는다.
 if master>=0 and AudioServer.get_driver_name()!="Dummy" and AudioServer.get_bus_effect_count(master)==0:
  var limiter:=AudioEffectLimiter.new()
  limiter.ceiling_db=-1.0
  limiter.threshold_db=-3.0
  AudioServer.add_bus_effect(master,limiter)
## 월드가 만들어지면 위치 기반 재생기를 그 아래에 붙인다(카메라가 2D 리스너).
func bind_world(node: Node) -> void:
 if node==null or node==sound_world:return
 sound_world=node
 spatial_voices.clear()
 for i in range(6):
  var player:=AudioStreamPlayer2D.new()
  player.bus="DosaSfx"
  player.max_distance=560.0
  player.attenuation=1.4
  player.panning_strength=0.85
  player.volume_db=-6.0
  node.add_child(player)
  spatial_voices.append(player)
## 현재 맵의 충돌 레이아웃(벽 너머 소리를 줄이는 데 쓴다).
func bind_layout(script_ref: Script) -> void:
 layout_script=script_ref
func set_listener(at: Vector2) -> void:
 listener=at
 listener_ready=true
## 거리 감쇠 + 좌우 패닝 + 벽 너머 감쇠를 적용한 위치 효과음.
## 소리는 실제 위치에서 나지만, 같은 거리라도 벽이 사이에 있으면 작게 들린다.
func play_at(stream: AudioStream,at: Vector2,volume_db: float=SKILL_DB,pitch: float=1.0) -> bool:
 if stream==null or not enabled or backgrounded:return false
 var player: AudioStreamPlayer2D=null
 for candidate in spatial_voices:
  if not candidate.playing:player=candidate;break
 if player==null:return false
 var distance:=listener.distance_to(at) if listener_ready else 0.0
 if distance>620.0:return false
 var occlusion:=0.0
 if layout_script!=null and listener_ready and distance>40.0:
  if _wall_between(listener,at):occlusion=-7.0
 player.stream=stream
 player.position=at
 player.volume_db=volume_db+occlusion
 player.pitch_scale=pitch
 if AudioServer.get_driver_name()!="Dummy":player.play()
 played+=1
 return true
## 두 지점 사이를 벽이 막고 있는지(레이아웃의 HARD 사각형을 12점 샘플링).
func _wall_between(a: Vector2,b: Vector2) -> bool:
 if layout_script==null:return false
 var hard: Array=layout_script.HARD
 var steps:=12
 for i in range(1,steps):
  var p:=a.lerp(b,float(i)/float(steps))
  for rect in hard:
   if (rect as Rect2).has_point(p):return true
 return false
## 추격 긴장도(0~1)를 매 프레임 갱신한다. 호출자는 '실제로 보이는' 요괴 거리만 넘긴다.
func set_tension(value: float,delta: float=0.0) -> void:
 tension_target=clampf(value,0.0,1.0)
 var speed:=3.2 if tension_target>tension else 0.9
 tension=move_toward(tension,tension_target,speed*maxf(delta,1.0/60.0))
 if tension_target>0.72 and not chase_started:
  chase_started=true
  _play(CLIPS["zone_warning"],-11.0,0.92,"chase")
 elif tension_target<0.18 and chase_started:
  chase_started=false
  _play(CLIPS["reward"],-15.0,1.18,"escape")
## 심장 박동: 위험할수록 빨라진다. 위치 정보가 아니라 '내 화면의 위험도'만 쓴다.
func _tick_heartbeat(delta: float) -> void:
 if tension<0.45 or not enabled or backgrounded:return
 heartbeat_clock-=delta
 if heartbeat_clock>0.0:return
 heartbeat_clock=lerpf(1.05,0.42,tension)
 _play(HEARTBEAT,HEARTBEAT_DB-6.0*(1.0-tension),0.98+0.04*tension,"heartbeat")
## 맵별 환경음 시작(맵 id). 낮은 품질에서는 한 겹만 깐다.
func play_map_ambience(map_id_value: String,layers_limit: int=2) -> void:
 var files: Array=AMBIENCE.get(map_id_value,AMBIENCE["seowon"])
 for i in range(ambient_layers.size()):
  var player: AudioStreamPlayer=ambient_layers[i]
  if i>=files.size() or i>=layers_limit:
   player.stop();continue
  var stream: AudioStream=load(String(files[i]))
  if stream==null:continue
  player.stream=_loopable(stream)
  player.volume_db=AMBIENCE_DB-float(i)*2.0
  if AudioServer.get_driver_name()!="Dummy":player.play()
func stop_ambience() -> void:
 for player in ambient_layers:player.stop()
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
## 빈 보이스 하나에 스트림을 넣어 재생한다. 재생 기록은 테스트·디버그가 읽는다.
func _play(stream: AudioStream,volume: float,rate_pitch: float=1.0,label: String="") -> bool:
 if stream==null:return false
 for voice in voices:
  if not voice.playing:
   voice.stream=stream
   voice.volume_db=volume
   voice.pitch_scale=rate_pitch
   if AudioServer.get_driver_name()!="Dummy": voice.play()
   played+=1
   if label!="":last_clip=label;clips_played+=1
   return true
 return false
func play_clip(name: String) -> void:
 if ALIASES.has(name): name=String(ALIASES[name])
 if not enabled or backgrounded or not CLIPS.has(name): return
 var label:=name
 var stream: AudioStream=CLIPS[name]
 var volume: float=-10.0
 if name in ["step","jar_step"]:
  label="step"
  stream=step_stream("jar" if name=="jar_step" else "stone")
  volume=STEP_DB
  steps_played+=1
 elif name=="spell":volume=SKILL_DB
 elif name=="seal" or name=="rescue":volume=-7.0
 # 같은 UI 사운드도 매번 미세하게 달라지도록 피치를 흔든다(반복 피로 감소).
 var jitter:=0.0
 if name in ["ui_tap","ui_tab","ui_back","gimmick_cctv","gimmick_turnstile"]:
  jitter=float((played*37)%11-5)/220.0
 var pitch_now:=1.0+jitter
 if name in ["step","jar_step"]:
  pitch_now=1.0+float((step_index*29)%13-6)/150.0
  step_index+=1
 _play(stream,volume,pitch_now,label)
## 도술 id에 맞는 효과음을 낸다. 등록되지 않은 id는 공용 도술음으로 대체한다.
## 내 시전과 주변 인물의 시전 모두 이 함수를 쓴다.
func play_skill(skill_id: String) -> void:
 if not enabled or backgrounded: return
 if not SKILLS.has(skill_id): play_clip("spell");return
 # 2.0.38 다중 레이어: 본음 + 공기층/저음층을 조금 다른 피치로 겹쳐 도술마다 질감을 준다.
 var jitter:=0.97+float((played*31)%7)/100.0
 if _play(SKILLS[skill_id],SKILL_DB,jitter,""):
  last_skill=skill_id
  skills_played+=1
  _play_skill_layer(skill_id)
## 다른 사람의 도술: 실제 위치에서 거리·패닝·벽 감쇠를 적용해 들린다.
func play_skill_at(skill_id: String,at: Vector2) -> void:
 if not enabled or backgrounded:return
 if not SKILLS.has(skill_id):return
 if play_at(SKILLS[skill_id],at,SKILL_DB,1.0):
  last_skill=skill_id
  skills_played+=1
## 도술 계열별 보조 레이어(공기 흐름 · 낮은 울림). 같은 소리가 반복되지 않게 피치를 흔든다.
func _play_skill_layer(skill_id: String) -> void:
 var air_skills: Array=["windstep","eightleap","wallhop","clone","painting","foxscent","glowpowder"]
 var low_skills: Array=["trap","astrolabe","puppet","mountaingrowl","underworldgate","ghostgate","moonlessnight"]
 if air_skills.has(skill_id):
  _play(CLIPS["attack"],SKILL_DB-5.0,1.16+float(played%5)*0.012,"")
 elif low_skills.has(skill_id):
  _play(CLIPS["hit"],SKILL_DB-4.0,0.72+float(played%3)*0.01,"")
 else:
  _play(CLIPS["spell"],SKILL_DB-7.0,1.02+float(played%4)*0.01,"")
## 재질 변형을 순서대로 돌려 쓴다(같은 발소리가 반복되지 않게).
func step_stream(material: String) -> AudioStream:
 var book: Array=STEP_LIBRARY.get(material,STEP_LIBRARY["stone"])
 if book.is_empty():return CLIPS["step"]
 var cursor: int=int(step_cursor.get(material,0))
 step_cursor[material]=cursor+1
 return book[cursor%book.size()]
func update_steps(p: Vector2, moving: bool, jar: bool) -> void:
 if not tracking: previous_position=p;tracking=true
 var distance:=p.distance_to(previous_position);previous_position=p
 if not moving or distance>20:
  step_distance=0;return
 step_distance+=distance
 if step_distance >= (17.0 if jar else 23.0):
  step_distance=0
  last_surface="jar" if jar else preload("res://scripts/woo/terrain_surface.gd").at(p,map_id)
  _step_voice(last_surface,STEP_DB,1.0+float((step_index*29)%13-6)/150.0)
  step_index+=1
func _step_voice(material: String,volume: float,pitch_now: float) -> bool:
 var stream: AudioStream=step_stream(material)
 if _play(stream,volume,pitch_now,"step"):
  steps_played+=1
  return true
 return false
## 주변 인물의 발소리: 재질은 그 사람 발밑 기준, 크기는 거리로 줄인다.
func update_npc_steps(id: int,p: Vector2,moving: bool,listener: Vector2) -> void:
 var last: Dictionary=nearby_trackers.get(id,{"p":p,"distance":0.0})
 var travel: float=p.distance_to(last.p)
 last.p=p
 var gap: float=p.distance_to(listener)
 if not moving or travel>20 or gap>150:last.distance=0.0
 else:last.distance+=travel
 if last.distance>=22:
  last.distance=0.0
  var material: String=preload("res://scripts/woo/terrain_surface.gd").at(p,map_id)
  var volume: float=STEP_DB-6.0-clampf(gap/28.0,0.0,12.0)
  _step_voice(material,volume,1.0+float((id*17+int(played))%9-4)/180.0)
 nearby_trackers[id]=last
