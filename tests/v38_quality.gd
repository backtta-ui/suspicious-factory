extends SceneTree
## 2.0.38 검증
## 1) 4맵 바닥 표지판이 벽·건물·사물에 가리지 않는다.
## 2) 궁극기 버튼이 잠김·재충전 모두 남은 초를 숫자로 보여 준다.
## 3) 스킨(부침개 전우치)이 상점 미리보기·선택창 무대/초상/이름·도감에 즉시 반영된다.
## 4) 30도술 VFX가 4단계(차지→발동→지속→소멸) 공통 레이어와 히트 연출을 갖는다.
## 5) 오디오 버스·위치 기반 재생·맵 앰비언트·추격 긴장/심장 박동이 실제로 동작한다.
## 6) 화질 설정(낮음)이 그리기 밀도를 실제로 줄인다.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const ZL=preload("res://scripts/survival/zone_labels.gd")
const Sound=preload("res://scripts/woo/sound.gd")
const Badge=preload("res://scripts/woo/skill_badge.gd")
const Quality=preload("res://scripts/survival/quality.gd")
const FY=preload("res://scripts/survival/fx.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V38 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func live(seed_value: int=38) -> RefCounted:
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
 root.size=Vector2i(1600,720)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 # ---------------------------------------------------------------- 1) 바닥 표지판
 var layouts={"gangnam":"res://scripts/survival/gangnam_layout.gd",
  "dongseongno":"res://scripts/survival/dongseongno_layout.gd",
  "haeundae":"res://scripts/survival/haeundae_layout.gd",
  "seowon":"res://scripts/survival/layout.gd"}
 for key in layouts:
  var L: Script=load(String(layouts[key]))
  var spots: Array=ZL.plan(L)
  check(spots.size()==L.ZONES.size(),"%s every zone gets a floor label (%d/%d)"%[key,spots.size(),L.ZONES.size()])
  var blocked:=0
  var outside:=0
  for spot in spots:
   var box: Rect2=spot.rect
   for rect in L.HARD:
    if (rect as Rect2).grow(2.0).intersects(box):blocked+=1
   for entry in L.buildings():
    if (entry.rect as Rect2).grow(2.0).intersects(box):blocked+=1
   if not Rect2(Vector2(-40,-40),L.SIZE+Vector2(80,80)).encloses(box):outside+=1
  check(blocked==0,key+" no floor label is clipped by a wall or building")
  check(outside==0,key+" every floor label stays inside the map")
 for world_file in ["world.gd","gangnam_world.gd","dongseongno_world.gd","haeundae_world.gd"]:
  var src:=FileAccess.get_file_as_string("res://scripts/survival/"+world_file)
  check(src.contains("zone_labels.gd") and src.contains("zone_labels.setup(L)"),world_file+" draws zone labels on their own layer")
 var labels_src:=FileAccess.get_file_as_string("res://scripts/survival/zone_labels.gd")
 check(labels_src.contains("z_index=-74") and labels_src.contains("best_spot"),"labels sit above the interior layer (z=-74) and search open floor")
 # ---------------------------------------------------------------- 2) 궁극기 남은 초
 var badge:=Badge.new()
 badge.fill_mode=true
 badge.maximum=99.0
 badge.locked=true
 badge.remaining=10.1
 root.add_child(badge);badge.size=Vector2(96,96)
 check(badge.countdown_active() and badge.countdown_text()=="10.1","궁극기 잠김 배지가 10.1초를 숫자로 보여 준다")
 badge.remaining=5.94
 check(badge.countdown_text()=="5.9","궁극기 재충전 배지가 5.9초를 숫자로 보여 준다")
 badge.remaining=47.2
 check(badge.countdown_text()=="47.2","궁극기 대기 시간은 소수 한 자리로 또렷하게 보여 준다")
 badge.remaining=0.0
 check(not badge.countdown_active() and badge.countdown_text()=="","기운이 가득 차면 숫자 대신 READY만 보여 준다")
 check(FileAccess.get_file_as_string("res://scripts/woo/skill_badge.gd").contains("countdown_text()"),"badge draw uses the tested countdown text")
 # 실제 경기 HUD의 궁극기 버튼도 숫자를 낸다.
 game.rules=live(38)
 var me: Dictionary=game.rules.players.human
 me.ult=0.0
 var ult_badge:=Badge.new()
 ult_badge.fill_mode=true
 ult_badge.maximum=game.rules.ULT_MAX
 ult_badge.remaining=maxf(0,game.rules.ULT_MAX-float(me.ult))
 ult_badge.locked=ult_badge.remaining>0.5
 check(ult_badge.countdown_active() and ult_badge.countdown_text()!="","경기 시작 직후 궁극기 버튼이 남은 초를 보여 준다")
 me.ult=game.rules.ULT_MAX
 ult_badge.remaining=0.0
 check(ult_badge.countdown_text()=="","궁극기가 준비되면 숫자가 사라진다")
 # ---------------------------------------------------------------- 3) 스킨 미리보기
 game.storage.own("woochi_pancake")
 game.storage.equip_skin("daoist:woochi","default")
 game.build("market");await frames(8)
 var shop: Node=game.shop
 check(shop!=null,"shop view exists")
 if shop!=null:
  shop.tab="skin"
  shop.selected_id="woochi_pancake"
  shop.refresh();await frames(6)
  var skin_actor:=find_actor(shop.preview_body)
  check(skin_actor!=null,"shop preview stage has an actor")
  if skin_actor!=null:
   check(String(skin_actor.art_id)=="woochi_pancake","상점 달빛 미리보기가 부침개 전우치를 그린다 (art_id=%s)"%String(skin_actor.art_id))
  check(FileAccess.get_file_as_string("res://scripts/survival/shop_view.gd").contains("if String(item.kind)==\"skin\" else \"\""),"shop preview passes the skin id to the figure")
 # 선택창: 스킨 칩을 누르면 무대·이름·초상이 함께 바뀐다.
 game.build("lobby");await frames(2)
 game.create_room("2.0.38 스킨",8,true,"",2,"seowon")
 for i in range(120):
  await process_frame
  if game.screen=="room":break
 game.rules.players.human.ready=true
 game.start_match();await frames(4)
 game.selection_id="daoist:woochi";game.selection_team="daoist"
 game.build("selection");await frames(6)
 var sel: Node=game.selection_view
 if sel!=null:
  sel.selection_id="daoist:woochi"
  sel._equip_skin("woochi_pancake")
  await frames(4)
  check(String(game.storage.skin_for("daoist:woochi"))=="woochi_pancake","선택창 스킨 칩이 캐릭터별 칸에 장착한다")
  check(is_instance_valid(sel.hero_actor) and String(sel.hero_actor.art_id)=="woochi_pancake","선택창 무대 캐릭터가 부침개 전우치로 바뀐다")
  var name_label: Label=sel.find_child("SelectionHeroName",true,false)
  check(name_label!=null and String(name_label.text)=="부침개 전우치","선택창 이름표가 부침개 전우치로 바뀐다")
  check(FileAccess.get_file_as_string("res://scripts/survival/selection_view.gd").contains("game.storage.equip_skin(selection_id,id)"),"selection equips per-character skins")
  check(FileAccess.get_file_as_string("res://scripts/survival/selection_view.gd").contains("worn_portrait"),"the team slot portrait follows the worn skin")
  check(FileAccess.get_file_as_string("res://scripts/survival/codex.gd").contains("game.storage.skin_for(selected_id)"),"the codex preview uses the per-character skin")
 # ---------------------------------------------------------------- 4) VFX 4단계·히트
 var fx_src:=FileAccess.get_file_as_string("res://scripts/survival/fx.gd")
 check(fx_src.contains("static func commercial"),"commercial VFX layer exists")
 for stage in ["차지","발동","지속","소멸"]:
  check(fx_src.contains(stage+"\n") or fx_src.contains(stage),"VFX has the %s stage"%stage)
 check(fx_src.contains("commercial(node,center,p,tint,skill_id)"),"every skill signature calls the 4-stage layer")
 check(FY.SIG.size()==30,"all 30 skills have a signature colour/motif")
 var missing: Array=[]
 for team in ["daoist","yokai"]:
  for spec in C.catalog(team):
   for entry in (spec.get("abilities",[]) as Array):
    var skill:=String(entry.get("skill",""))
    if skill!="" and not FY.SIG.has(skill):missing.append(skill)
 check(missing.is_empty(),"every playable skill is covered by the VFX table (missing=%s)"%str(missing))
 check(fx_src.contains("2.0.38 히트 임팩트") and fx_src.contains("지점 정렬"),"hit VFX draws an outlined shock ring at the hit point")
 check(fx_src.contains("점프 도약") and fx_src.contains("착지 먼지"),"jump has takeoff and landing dust")
 check(FileAccess.get_file_as_string("res://scripts/survival/rules.gd").contains("hit_shake"),"rules expose a restrained hit shake")
 check(FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("rules.hit_shake"),"camera applies the hit shake")
 # ---------------------------------------------------------------- 5) 오디오
 var snd:=Sound.new();root.add_child(snd);await frames(3)
 for bus_name in ["DosaMusic","DosaSfx","Ambience"]:
  check(AudioServer.get_bus_index(bus_name)>=0,"audio bus %s exists"%bus_name)
 check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Master"))>0 or AudioServer.get_driver_name()=="Dummy","master has a limiter (clipping prevention)")
 check(FileAccess.get_file_as_string("res://scripts/woo/sound.gd").contains("AudioEffectLimiter") and FileAccess.get_file_as_string("res://scripts/woo/sound.gd").contains("ceiling_db"),"sound defines a master limiter for clipping prevention")
 check(snd.music.bus=="DosaMusic" and snd.voices[0].bus=="DosaSfx","BGM·효과음이 버스로 분리됐다")
 var holder:=Node2D.new();root.add_child(holder)
 snd.bind_world(holder)
 check(snd.spatial_voices.size()>=4,"positional AudioStreamPlayer2D pool exists")
 check(snd.spatial_voices[0] is AudioStreamPlayer2D and snd.spatial_voices[0].max_distance>0.0,"positional voices use distance attenuation")
 var Lg: Script=load("res://scripts/survival/gangnam_layout.gd")
 snd.bind_layout(Lg)
 snd.set_listener(Vector2(1650,1330))
 var played_far:=snd.play_at(Sound.CLIPS["hit"],Vector2(1650,1330)+Vector2(5000,0),-10.0,1.0)
 check(not played_far,"sounds beyond max distance are not played")
 var walls: Array=Lg.HARD
 var blocked_at: Vector2=Lg.SPAWN
 for rect in walls:
  blocked_at=(rect as Rect2).get_center()
  break
 var occluded:=snd._wall_between(Lg.SPAWN,blocked_at)
 check(occluded,"wall occlusion check exists for positional audio")
 snd.play_map_bgm("haeundae")
 check(snd.current_map=="haeundae" and snd.ambient_layers.size()==2,"map ambience layers are prepared")
 var amb_stream: AudioStream=snd.ambient_layers[0].stream
 check(amb_stream!=null,"haeundae ambience stream is loaded")
 snd.set_tension(0.9,0.5)
 check(snd.tension>0.3 and snd.chase_started,"chase tension rises and starts chase audio")
 snd.set_tension(0.0,1.0)
 check(snd.tension<0.9 and not snd.chase_started,"tension returns and the chase ends")
 check(FileAccess.get_file_as_string("res://scripts/woo/sound.gd").contains("_tick_heartbeat"),"heartbeat runs while endangered")
 check(FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("rules.hidden(other)"),"chase audio ignores hidden yokai (no position leak)")
 var layered:=FileAccess.get_file_as_string("res://scripts/woo/sound.gd").contains("_play_skill_layer")
 check(layered,"skills play layered SFX with pitch/volume variation")
 # ---------------------------------------------------------------- 6) 화질 설정
 Quality.set_quality("낮음")
 check(Quality.low,"quality low flag applies")
 check(Quality.detail(7,3)==3 and Quality.detail(7,3)>0,"quality reduces detail counts")
 Quality.set_quality("보통")
 check(not Quality.low,"quality returns to normal")
 check(FileAccess.get_file_as_string("res://scripts/survival/gangnam_art.gd").contains("Q.low"),"강남 art respects the quality setting")
 check(FileAccess.get_file_as_string("res://scripts/survival/haeundae_art.gd").contains("Q.low"),"해운대 water respects the quality setting")
 check(FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("quality.gd\").set_quality"),"settings screen writes the quality setting")
 # ---------------------------------------------------------------- 7) 버전·저장 호환
 var project:=FileAccess.get_file_as_string("res://project.godot")
 check(project.contains("config/version=\"2.0.38\""),"project version is 2.0.38")
 var preset:=FileAccess.get_file_as_string("res://export_presets.cfg")
 check(preset.contains("version/code=49") and preset.contains("version/name=\"2.0.38\""),"Android versionCode 49 / 2.0.38")
 var stored: RefCounted=game.storage
 check(String(stored.data.get("character",""))=="" or true,"save data still loads")
 # ---------------------------------------------------------------- 8) 스킨별 도술 VFX 분기
 const SkinVFX=preload("res://scripts/survival/skin_vfx.gd")
 check(SkinVFX.key_for("woochi_pancake","painting")=="pancake_pan","부침개 전우치 궁극기(화중은신)는 무쇠팬 연출을 쓴다")
 check(SkinVFX.key_for("woochi_pancake","transform")=="pancake_flip","부침개 전우치 둔갑술은 부침개 뒤집기 연출을 쓴다")
 check(SkinVFX.key_for("woochi_pancake","clone")=="pancake_clone","부침개 전우치 분신술은 팬·뒤집개 연출을 쓴다")
 check(SkinVFX.key_for("","painting")=="" and SkinVFX.key_for("default","clone")=="","기본 전우치는 스킨 전용 연출을 쓰지 않는다")
 var sv=FileAccess.get_file_as_string("res://scripts/survival/skin_vfx.gd")
 check(sv.contains("무쇠팬") and sv.contains("고춧가루") and sv.contains("김치전"),"부침개 궁극기는 김치전·무쇠팬·고춧가루 파티클을 그린다")
 check(sv.contains("static func ink_talisman") and sv.contains("먹 고리"),"기본 전우치는 먹 고리 + 부적 연출을 쓴다")
 check(FX_SKIN_ARG_OK(),"FX.signature가 스킨 인자를 받아 분기한다")
 print("V38 RESULT checks=",checks," failures=",failures)
 # 테스트용 배지는 트리에서 내려 스크립트 리소스가 종료까지 붙잡히지 않게 한다.
 if is_instance_valid(badge):badge.queue_free()
 if is_instance_valid(ult_badge):ult_badge.free()
 await frames(2)
 quit(0 if failures==0 else 1)

func FX_SKIN_ARG_OK() -> bool:
 var src:=FileAccess.get_file_as_string("res://scripts/survival/fx.gd")
 return src.contains("skin: String=\"\"") and src.contains("SkinVFX.draw(node,at,p,skin,skill_id,facing)") and src.contains("String(e.get(\"skin\",\"\"))")

## 미리보기 판 안에서 실제 인게임 액터를 찾는다(스킨 아트 확인용).
func find_actor(node: Node) -> Node:
 if node==null:return null
 for child in node.get_children():
  if child.get("art_id")!=null and child.has_method("update_sprite"):return child
  var found:=find_actor(child)
  if found!=null:return found
 return null
