extends SceneTree
## 2.0.37 검증: 4맵 공통 이펙트(함정·장판·연막이 어느 맵에서든 보인다), 점프 중 보호막 위치 추적,
## 캐릭터별 스킨 격리(부침개는 전우치 전용), 바닥 재질별 실제 CC0 발소리, 30도술 전용 SFX.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const MapFx=preload("res://scripts/survival/map_fx.gd")
const Sound=preload("res://scripts/woo/sound.gd")
const Surface=preload("res://scripts/woo/terrain_surface.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
const Store=preload("res://scripts/survival/storage.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V37 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func live(seed_value: int=37) -> RefCounted:
 var r:=Rules.new(seed_value)
 r.add("human","나","daoist:woochi","yokai:gumiho")
 for i in range(1,8):r.add("bot-%d"%i,"봇%d"%i,"daoist:woochi","yokai:gumiho")
 for p in r.players.values():p.ready=true
 r.start()
 for p in r.players.values():
  if C.find(p.character).is_empty():p.character=C.catalog(p.role)[0].id
 r.phase="live";r.elapsed=20.0;r.build_walkers()
 return r

func run() -> void:
 var maps: Array=Maps.ids()
 # ---------------------------------------------------------------- 1) 4맵 바닥 연출 공통화
 var sources: Dictionary={}
 for map_id in maps:
  var path: String=Maps.scene_of(map_id)
  var src:=FileAccess.get_file_as_string(path)
  sources[map_id]=src
  check(src.contains("MapFx.floor_layer(floor_fx,rules,clock"),map_id+" draw_floor uses the shared floor renderer")
  check(src.contains("MapFx.detection("),map_id+" detection uses the shared renderer")
  check(src.contains("MapFx.shield_bubbles(") or src.contains("MapFx.body_anchor("),map_id+" anchors body effects to jump height")
  check(src.contains("draw_shield_bubbles"),map_id+" still keeps the shield bubble layer")
 # 실제로 그려지는지: 4맵 모두 같은 rules에 대해 같은 바닥 연출 목록을 낸다.
 for map_id in maps:
  var rules:=live(37)
  rules.use_map(map_id)
  rules.traps=[{"kind":"pressure","owner":"human","pos":rules.players.human.position+Vector2(60,0),"until":rules.elapsed+20.0,"radius":36.0,"armed":true},
               {"kind":"treasure","owner":"human","pos":rules.players.human.position+Vector2(-60,0),"until":rules.elapsed+20.0,"radius":44.0,"armed":true}]
  rules.mischief_zones=[{"pos":rules.players.human.position+Vector2(0,90),"radius":260.0,"until":rules.elapsed+6.0}]
  rules.dark_until=rules.elapsed+9.0
  rules.dark_center=rules.players.human.position
  rules.dark_radius=300.0
  rules.map_dark_until=rules.elapsed+8.0
  var plan: Array=MapFx.floor_plan(rules)
  check(plan.has("traps"),map_id+" floor plan includes 장영실 압력기관 / 도깨비 가짜보물")
  check(plan.has("mischief"),map_id+" floor plan includes the 도깨비장난 zone")
  check(plan.has("douse") and plan.has("moonless"),map_id+" floor plan includes 등불끄기·무월야 shades")
  # 함정 두 종을 모두 그리는지(청동 기계판 + 가짜보물함)는 MapFx의 단일 구현이 책임진다.
  var fx_src:=FileAccess.get_file_as_string("res://scripts/survival/map_fx.gd")
  check(fx_src.contains("func pressure_trap") and fx_src.contains("func treasure_trap"),"the shared renderer owns both trap visuals")
  # 함정은 바닥 좌표에 고정: 점프한 캐릭터의 높이를 따라가지 않는다.
  var trap_pos: Vector2=(rules.traps[0] as Dictionary).pos
  var jumping: Dictionary={"position":trap_pos,"height":36.0}
  check(MapFx.body_anchor(jumping)==trap_pos-Vector2(0,36.0),"jump height lifts body effects, not floor traps")
 # ---------------------------------------------------------------- 2) 점프 중 보호막 위치 추적
 var anchor_rules:=live(38)
 var L=anchor_rules.L
 var who: Dictionary=anchor_rules.players.human
 who.position=Vector2(1200,900);who.height=0.0
 var ground_anchor: Vector2=MapFx.body_anchor(who,L)
 who.height=36.0
 var air_anchor: Vector2=MapFx.body_anchor(who,L)
 check(is_equal_approx(air_anchor.y,ground_anchor.y-36.0),"a jumping character lifts the shield anchor by its jump height")
 check(is_equal_approx(air_anchor.x,ground_anchor.x),"the shield stays directly above the character")
 # 보호막 도술을 쓰면 실제 버프가 서고, 그릴 때 쓰는 기준점은 몸(점프 반영)이다.
 who.character="daoist:barigongju";who.role="daoist";who.cd={};who.ult=anchor_rules.ULT_MAX
 who.position=Vector2(1200,900);who.ground=who.position;who.height=0.0
 anchor_rules.phase="live";anchor_rules.elapsed=20.0
 var cast_ok: bool=bool(anchor_rules.skill(who,Vector2.RIGHT,"sub"))
 check(cast_ok and float(who.buff.get("shield",0.0))>anchor_rules.elapsed,"저승꽃 sets a real shield buff")
 who.height=36.0
 var bubble: Vector2=MapFx.body_anchor(who,L)
 check(is_equal_approx(bubble.y,900.0-36.0),"the shield bubble is drawn 36px higher while jumping (no ground-only bubble)")
 var world_src:=FileAccess.get_file_as_string(Maps.scene_of("seowon"))
 var mapfx_src:=FileAccess.get_file_as_string("res://scripts/survival/map_fx.gd")
 check(world_src.contains("MapFx.shield_bubbles(") and mapfx_src.contains("body_anchor(p,layout)"),"shield bubbles use the jump-aware anchor in the shared map code")
 # ---------------------------------------------------------------- 3) 스킨은 캐릭터별로 격리
 var store:=Store.new()
 store.data.daoist="daoist:woochi"
 store.own("woochi_pancake")
 store.equip_skin("daoist:woochi","woochi_pancake")
 check(store.skin_for("daoist:woochi")=="woochi_pancake","전우치 keeps the pancake skin")
 check(store.skin_for("daoist:barigongju")=="" and store.skin_for("yokai:gumiho")=="","other characters never inherit the pancake skin")
 check(store.skin_for("daoist:honggildong")=="","홍길동 stays on the default look")
 check(SkillFX.skin_allows("woochi_pancake","daoist:woochi") and not SkillFX.skin_allows("woochi_pancake","daoist:barigongju"),"the skin/character compatibility check is enforced")
 store.equip_skin("daoist:barigongju","woochi_pancake")
 check(store.skin_for("daoist:barigongju")=="","an incompatible skin cannot be equipped on another character")
 # 인게임: 전우치에 부침개를 장착해도 바리공주를 고르면 기본 모습·기본 이름표만 나온다.
 root.size=Vector2i(1600,720)
 var game:=App.instantiate();root.add_child(game)
 await frames(8)
 game.storage.own("woochi_pancake")
 game.storage.equip_skin("daoist:woochi","woochi_pancake")
 game.storage.data.daoist="daoist:barigongju"
 game.preferred_role="daoist"
 game.create_room("스킨",6,true,"",2,"seowon")
 await create_timer(.4).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.confirm_character("human")
 for i in range(320):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match","a match is running for the skin check")
 var me: Dictionary=game.rules.players.human
 me.character="daoist:barigongju"
 me.skin=String(game.storage.skin_for(String(me.character)))
 game.update_avatars();await frames(3)
 game.update_hud();await frames(2)
 var bari_name: String=""
 if game.hud_view!=null:bari_name=String(game.hud_view.character_name)
 check(not bari_name.contains("부침개"),"바리공주 HUD never shows · 부침개 (got: "+bari_name+")")
 var bari_tag: String=""
 var bari_actor: Node=game.avatars.get("human")
 if bari_actor!=null and bari_actor.get_node_or_null("Name")!=null:bari_tag=String((bari_actor.get_node("Name") as Label).text)
 check(not bari_tag.contains("부침개"),"바리공주 name tag never shows · 부침개 (got: "+bari_tag+")")
 for info in game.rules.visible("human"):
  if String(info.get("id",""))=="human":
   check(String(info.get("skin",""))=="","the snapshot clears a skin that does not belong to the character")
   break
 # 전우치로 바꾸면 그때만 부침개가 붙는다.
 me.character="daoist:woochi"
 me.skin=String(game.storage.skin_for("daoist:woochi"))
 game.update_avatars();await frames(2)
 game.update_hud();await frames(2)
 var woochi_tag: String=""
 if bari_actor!=null and bari_actor.get_node_or_null("Name")!=null:woochi_tag=String((bari_actor.get_node("Name") as Label).text)
 check(woochi_tag.contains("부침개"),"전우치 name tag shows · 부침개 (got: "+woochi_tag+")")
 game.queue_free()
 await frames(2)
 # ---------------------------------------------------------------- 4) 바닥 재질별 실제 발소리
 var seen_materials: Dictionary={}
 for map_id in maps:
  var layout=Maps.layout_of(map_id)
  for point in [layout.SPAWN,layout.SPAWN+Vector2(120,0),layout.SPAWN+Vector2(-140,60)]:
   var material: String=Surface.at(point,map_id)
   seen_materials[material]=true
   check(Sound.STEP_LIBRARY.has(material),map_id+" surface '"+material+"' has recorded footsteps")
 check(seen_materials.size()>=4,"the four maps produce several distinct floor materials: "+str(seen_materials.keys()))
 for material in ["grass_dirt","stone","wood","tile_indoor","asphalt","sand","water","escalator","jar"]:
  var book: Array=Sound.STEP_LIBRARY.get(material,[])
  check(book.size()>=3,"material "+material+" has 3+ recorded variants (%d)"%book.size())
 var snd: Node=Sound.new()
 root.add_child(snd)
 await frames(2)
 snd.update_steps(Vector2(900,610),true,false)
 for i in range(1,8):snd.update_steps(Vector2(900+i*12,610),true,false)
 check(snd.steps_played>=1 and snd.last_surface!="","footsteps actually play on the seowon floor (%s)"%snd.last_surface)
 snd.map_id="haeundae"
 snd.tracking=false
 var hae: Vector2=Maps.layout_of("haeundae").SPAWN
 for i in range(1,8):snd.update_steps(hae+Vector2(i*12,0),true,false)
 check(snd.last_surface=="sand" or snd.last_surface=="stone","해운대 footsteps use the beach materials (%s)"%snd.last_surface)
 snd.queue_free()
 # ---------------------------------------------------------------- 5) 30도술 전용 SFX·BGM
 var skill_ids: Array=[]
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   for ability in (C.find(String(entry.id)).get("abilities",[]) as Array):
    var id:=String(ability.get("skill",""))
    if id!="" and not skill_ids.has(id):skill_ids.append(id)
 check(skill_ids.size()==30,"the roster defines thirty skills")
 var missing: Array=[]
 var paths: Dictionary={}
 for id in skill_ids:
  if not Sound.SKILLS.has(id):missing.append(id);continue
  var stream: AudioStream=Sound.SKILLS[id]
  paths[(stream as AudioStreamWAV).resource_path]=true
  if (stream as AudioStreamWAV).get_length()<0.25:missing.append(id+":short")
 check(missing.is_empty(),"every skill has its own recorded CC0 clip: "+str(missing))
 check(paths.size()==30,"thirty different files (no shared placeholder)")
 for track in ["lobby_fantasy","seowon_battle","gangnam_trance","haeundae_beach","dongseongno_urban"]:
  check(ResourceLoader.exists("res://assets/audio/bgm/%s.ogg"%track),"CC0 bgm track exists: "+track)
 check(Sound.MAP_BGM.size()==4 and Sound.BGM_GAIN_DB.size()==5,"map bgm table + measured gains are wired")
 var sound:=Sound.new();root.add_child(sound)
 await frames(2)
 for map_id in maps:
  sound.play_map_bgm(map_id)
  check(sound.current_map==map_id and sound.music!=null and sound.music.stream!=null,"bgm switches for "+map_id)
 sound.queue_free()
 # 동성로·해운대·강남역에서도 덫·장판이 사라지지 않았는지 소스로 한 번 더 확인한다.
 for map_id in ["gangnam","haeundae","dongseongno"]:
  var src: String=sources[map_id]
  check(src.contains("MapFx.floor_layer"),map_id+" floor layer is shared (the missing-trap bug cannot return)")
 # ---------------------------------------------------------------- 6) 선택창 10인 전용 모션
 var motion=preload("res://scripts/survival/selection_motion.gd")
 var art_ids: Array=[]
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):art_ids.append(C.fallback_art(String(entry.get("art",entry.id))))
 check(art_ids.size()==10,"ten roster art ids for the selection motion")
 var motion_names: Dictionary={}
 var motion_clips: Dictionary={}
 for art in art_ids:
  var kit: Dictionary=motion.kit_of(art)
  motion_names[String(kit.get("name",""))]=true
  motion_clips[String(kit.get("clip",""))]=true
  check(String(kit.get("name",""))!="" and String(kit.get("clip",""))!="","character "+art+" has its own entrance motion")
 check(motion_names.size()==10,"all ten characters have different entrance motions: "+str(motion_names.size()))
 check(motion_clips.size()>=6,"entrance sounds differ per character (%d clips)"%motion_clips.size())
 var sel_src:=FileAccess.get_file_as_string("res://scripts/survival/selection_view.gd")
 check(sel_src.contains("SelMotion.draw(") and sel_src.contains("SelMotion.bob_of(") and sel_src.contains("SelMotion.entry_clip("),"the selection screen draws the per-character motion and sound")
 var preset:=FileAccess.get_file_as_string("res://export_presets.cfg")
 var project:=FileAccess.get_file_as_string("res://project.godot")
 check(project.contains("config/version=\"2.0.37\""),"project version is 2.0.37")
 check(preset.contains("version/code=48") and preset.contains("version/name=\"2.0.37\""),"Android versionCode 48 / 2.0.37")
 print("V37 RESULT checks=",checks," failures=",failures)
 quit(1 if failures>0 else 0)
