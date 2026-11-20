extends SceneTree
## 2.0.31 사운드: 도사·도술별 맞춤 효과음 30종이 실제로 로드되고,
## 내 시전과 주변 인물의 시전 모두 그 도술의 소리를 내는지 확인한다.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Sound=preload("res://scripts/woo/sound.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("SFX ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func run() -> void:
 # 1) 30개 도술 id 전부에 전용 음원이 있고, 길이·포맷이 정상이다.
 check(Sound.SKILLS.size()>=30,"thirty skill clips are registered")
 var bad: Array=[]
 for id in Sound.SKILLS:
  var stream: AudioStream=Sound.SKILLS[id]
  if not (stream is AudioStreamWAV):bad.append(id+":type");continue
  var wav:=stream as AudioStreamWAV
  if wav.get_length()<0.25 or wav.get_length()>3.2:bad.append("%s:%.2fs" % [id,wav.get_length()])
  if wav.mix_rate not in [22050,44100]:bad.append(id+":rate")
  if wav.stereo:bad.append(id+":stereo")
 check(bad.is_empty(),"every skill clip loads as a short mono WAV: "+str(bad))
 # 2) 로스터의 모든 도술 id가 빠짐없이 등록되어 있다(스킬 버튼 30개).
 var missing: Array=[]
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   for ability in (C.find(String(entry.id)).get("abilities",[]) as Array):
    var id:=String(ability.get("skill",""))
    if id!="" and not Sound.SKILLS.has(id):missing.append(String(entry.id)+"/"+id)
 check(missing.is_empty(),"all thirty roster skills have their own sound: "+str(missing))
 var ids:=Sound.SKILLS.keys()
 ids.sort()
 check(String(ids[0])!="", "skill ids cover the catalogue: "+str(ids.size())+" ids")
 # 3) 소리는 서로 다른 파일이다(같은 음원 재사용 금지).
 var paths: Array=[]
 for id in Sound.SKILLS:paths.append((Sound.SKILLS[id] as AudioStreamWAV).resource_path)
 var unique: Dictionary={}
 for path in paths:unique[path]=true
 check(unique.size()==Sound.SKILLS.size(),"each skill points at its own file: %d/%d" % [unique.size(),Sound.SKILLS.size()])
 # 4) play_skill이 도술 id를 그대로 기록한다(등록되지 않은 id는 공용음으로 대체).
 var sound: Node=Sound.new()
 root.add_child(sound)
 await frames(2)
 sound.play_skill("mimic")
 check(sound.last_skill=="mimic" and sound.skills_played==1,"play_skill plays the requested skill")
 sound.play_skill("unknown-skill")
 check(sound.last_skill=="mimic" and sound.played>=2,"unknown skill id falls back to the shared spell clip")
 sound.queue_free()
 # 5) 실제 경기에서: 내가 쓰는 도술의 소리와 주변 인물의 도술 소리가 각각 그 도술이어야 한다.
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game)
 await frames(8)
 # 진영이 무작위라 요괴가 걸리면 인간둔갑(mimic)은 대상이 없어 시전이 거부된다. 도사로 고정한다.
 game.preferred_role="daoist"
 game.create_room("효과음",6,true)
 await create_timer(.4).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames()
 game.rules.confirm_character("human")
 for i in range(300):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match","match screen for the live sound test")
 var me: Dictionary=game.rules.players.human
 # 카운트다운 중에는 도술 명령이 거부되므로 실제 경기 상태로 만든다.
 game.rules.phase="live";game.rules.countdown=0.0;game.rules.elapsed=6.0
 var slot_id:=String(C.ability(String(me.character),"main").get("skill",""))
 game.cast_slot("main",Vector2.RIGHT)
 check(game.sound.last_skill==slot_id and game.sound.skills_played>=1,"my cast plays my own skill clip (%s)" % slot_id)
 # 내 시전 이벤트를 먼저 소비해 두고, 그 다음 상대 시전만 세도록 한다.
 game.update_hud();await frames(2)
 # 주변 인물의 시전: 가까이에 세우고 그 인물의 도술을 직접 실행한 뒤 HUD 갱신이 이벤트를 소비한다.
 var other_id:=""
 for id in game.rules.players:
  if String(id)!="human":other_id=String(id);break
 var other: Dictionary=game.rules.players[other_id]
 other.character=C.catalog("daoist")[2].id
 other.position=(me.position as Vector2)+Vector2(120,0)
 other.captured=false;other.eliminated=false;other.cd={};other.ult=game.rules.ULT_MAX
 var other_skill:=String(C.ability(String(other.character),"main").get("skill",""))
 var before:=int(game.sound.skills_played)
 var cast: bool=game.rules.skill(other,Vector2.RIGHT,"main")
 game.update_hud()
 check(cast and game.sound.skills_played==before+1 and game.sound.last_skill==other_skill,
  "another player's cast plays that skill's clip (%s)" % other_skill)
 # 마지막으로 등록된 30개가 모두 '서로 다른 소리'라는 것을 사용자에게 보여줄 목록으로 확인.
 print("SFX IDS ",ids)
 print("SKILL SOUND: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
