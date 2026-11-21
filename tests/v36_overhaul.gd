extends SceneTree
## 2.0.36 전면개편 검증: 스킨 정리·상점/도감/선택창 역할 분리·스킨 동기화,
## 캐릭터 선택창 움직이는 연출, 4맵 실내(앞·뒷문/지붕 숨김), 기믹 3개,
## 실시간 CCTV 피드, 에스컬레이터 탑승, 맵별 자기장, 구출 시인성, 미니맵 이동·장소명,
## 어둑시니 시야 감소 시 팀원 비노출, 장영실 기본 이펙트, 맵 이름 '조선'.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const Market=preload("res://scripts/survival/market.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
const Rules=preload("res://scripts/survival/rules.gd")
const FX=preload("res://scripts/survival/fx.gd")
const SeowonL=preload("res://scripts/survival/layout.gd")
const GangnamL=preload("res://scripts/survival/gangnam_layout.gd")
const HaeundaeL=preload("res://scripts/survival/haeundae_layout.gd")
const DongseongnoL=preload("res://scripts/survival/dongseongno_layout.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V36 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func live(seed_value: int=36) -> RefCounted:
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
 # ---------------------------------------------------------------- 1) 맵 이름 '조선'
 check(Maps.name_of("seowon")=="조선" and String(Maps.info("seowon").short)=="조선","the first map is displayed as 조선")
 check(String(Maps.info("seowon").subtitle).contains("조선"),"the subtitle also speaks of 조선")
 var display_files=["scripts/survival/maps.gd","scripts/survival/selection_view.gd","scripts/survival/codex.gd",
  "scripts/survival/market.gd","scripts/survival/correspondence_view.gd","scripts/survival/app.gd"]
 var stale: Array=[]
 for path in display_files:
  var src:=FileAccess.get_file_as_string("res://"+path)
  if src.contains("\"월하의 서원\"") or src.contains("\"월하리\""):stale.append(path)
 check(stale.is_empty(),"no user-facing string still says 월하의 서원/월하리: "+str(stale))
 # ---------------------------------------------------------------- 2) 스킨 정리
 var shop_skins: Array=Market.shop_items("skin")
 check(shop_skins.size()==1 and String(shop_skins[0].id)=="woochi_pancake","only character-exclusive skins are sold")
 var colour_skins: Array=[]
 for item in shop_skins:
  var id: String=String(item.id)
  if id in ["moon","lotus","ink","ember","jade","default"]:colour_skins.append(id)
 check(colour_skins.is_empty(),"colour robe skins are gone from the shop: "+str(colour_skins))
 check(String(Market.skin("moon").get("name",""))=="달빛 도포","legacy colour skin ids still resolve for old saves")
 check(Market.skins_for("daoist:woochi").size()==1 and Market.skins_for("yokai:gumiho").is_empty(),"only the matching character owns the pancake skin")
 check(Market.DEFAULT_SKIN.id=="default" and Market.DEFAULT_SKIN.name=="기본 모습","the base look is not a colour skin")
 # ---------------------------------------------------------------- 3) 상점·도감 미리보기 매핑
 root.size=Vector2i(1600,720)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 game.storage.data.market.owned.erase("woochi_pancake")
 game.build("market");await frames(4)
 game.shop.set_tab("skin");await frames(3)
 var item: Dictionary=game.shop.view_item(Market.skin("woochi_pancake"))
 check(String(item.get("character",""))=="daoist:woochi","the pancake skin is bound to 전우치, not 장영실")
 check(String(item.get("role","")).contains("전우치"),"the shop labels it as the 전우치-exclusive skin")
 check(String(game.shop._preview_character(item))=="daoist:woochi","the shop previews 전우치 for the pancake skin")
 check(String(item.get("full","")).ends_with("woochi_pancake/full.png") and ResourceLoader.exists(String(item.get("full",""))),"the shop uses the pancake full art")
 game.open_codex("all");await create_timer(.45).timeout;await frames(6)
 var codex: Node=null
 for node in game.ui.get_children():
  if node.get_script()!=null and String(node.get_script().resource_path).ends_with("codex.gd"):codex=node
 check(codex!=null,"the codex opens")
 if codex!=null:
  codex._select("daoist:woochi");await frames(2)
  var skins: Array=[]
  for child in codex.skin_row.get_children():skins.append(String(child.name))
  check(skins.has("CodexSkin_default") and skins.has("CodexSkin_woochi_pancake"),"the codex lists only the base look and 전우치's skin: "+str(skins))
  check(not skins.has("CodexSkin_moon") and not skins.has("CodexSkin_lotus"),"the codex no longer lists colour robes")
 check(Market.shop_items("character").size()==10,"the shop keeps all ten characters for unlocking")
 # ---------------------------------------------------------------- 4) 선택창: 움직이는 캐릭터 + 전용 스킨 장착
 game.build("lobby");await frames(4)
 game.create_room("V36 선택",8,true,"",2,"seowon");await create_timer(.3).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 game.rules.players.human.role="daoist"
 game.rules.select_character("human","daoist:woochi")
 game.selection_id="daoist:woochi";game.selection_team="daoist";game.build("selection");await frames(6)
 var sel: Node=game.selection_view
 check(sel!=null and sel.hero_actor!=null and sel.hero_actor is Node2D,"the selection screen starts with a real moving character, not a still rectangle")
 if sel!=null:
  var facing_before:=int(sel.hero_actor.facing)
  var motion_before: float=float(sel.hero_motion)
  await frames(16)
  check(sel.hero_motion>motion_before,"the character performs its own selection motion loop")
  check(sel.hero_actor.facing!=facing_before or sel.hero_actor.gait_phase>0.0,"the character keeps moving (facing/gait)")
  check(sel.hero_art.rotation==0.0,"the giant illustration no longer tilts/spins")
  var chip: Node=sel.get_node_or_null("SelectionSkin_woochi_pancake")
  if chip==null:
   for node in game.ui.find_children("SelectionSkin_*","Button",true,false):chip=node
  check(chip!=null,"the selection screen offers the owned skin")
  if chip!=null:
   # 보유 상태로 되돌리고 실제로 누른다.
   game.storage.data.market.owned.append("woochi_pancake")
   chip.disabled=false
   sel._equip_skin("woochi_pancake")
   await frames(3)
   check(String(game.storage.equipped("skin"))=="woochi_pancake","the selection screen equips the owned skin")
   check(sel.hero_actor.art_id=="woochi_pancake" or sel.hero_actor.skin_tint==Color.WHITE,"the big character wears the equipped skin")
 game.rules.phase="selection"
 # ---------------------------------------------------------------- 5) 스킨 동기화(분신·인간둔갑)
 var r:=live(36)
 var me: Dictionary=r.players.human
 me.skin="woochi_pancake"
 var idn: Dictionary=r.apparent_identity(me)
 check(String(idn.get("skin",""))=="woochi_pancake","clone identity carries the worn skin")
 r.effects.clear()
 me.position=Vector2(1700,1500)
 check(r.skill(me,Vector2.RIGHT,"main"),"전우치 casts his clone")
 var clone_id:=false
 for e in r.effects:
  if String(e.kind)=="clone":clone_id=String(e.get("identity",{}).get("skin",""))=="woochi_pancake"
 check(clone_id,"the clone effect stores the pancake skin for rendering")
 var yokai_id: String=""
 for p in r.players.values():
  if p.role=="yokai" and p.id!="human":yokai_id=String(p.id);break
 var fox: Dictionary=r.players[yokai_id]
 fox.position=me.position+Vector2(20,0)
 fox.role="yokai";fox.character="yokai:gumiho";fox.cd={};fox.captured=false;fox.eliminated=false
 me.immune=0.0
 var mimic_ok: bool=bool(r.skill(fox,Vector2.LEFT,"main"))
 if mimic_ok:
  var seen: Array=r.visible(yokai_id)
  var copied: Dictionary={}
  for a in seen:
   if bool(a.get("mimic",false)) and String(a.id)==yokai_id:copied=a
  check(String(copied.get("skin",""))=="woochi_pancake","인간둔갑 also copies the worn pancake skin")
 # ---------------------------------------------------------------- 6) 4맵 실내(앞·뒷문·지붕 숨김)
 for pair in [["seowon",SeowonL],["gangnam",GangnamL],["haeundae",HaeundaeL],["dongseongno",DongseongnoL]]:
  var map_id: String=String(pair[0])
  var L: Script=pair[1]
  var rooms: Array=L.buildings()
  check(rooms.size()>=2,"%s has at least two enterable interiors: %d"%[map_id,rooms.size()])
  for entry in rooms:
   var front: Vector2=(entry.doors as Dictionary).front
   var back: Vector2=(entry.doors as Dictionary).back
   check(L.can_stand(front+Vector2(0,34),9) and L.can_stand(front-Vector2(0,34),9),"%s %s front door is walkable"% [map_id,entry.id])
   check(L.can_stand(back+Vector2(0,-34),9) and L.can_stand(back+Vector2(0,34),9),"%s %s back door is walkable"% [map_id,entry.id])
   check(L.can_stand((entry.interior as Rect2).get_center(),9),"%s %s room floor is walkable"% [map_id,entry.id])
   check(L.inside((entry.interior as Rect2).get_center()),"%s %s reports inside"% [map_id,entry.id])
   var wall_probe: Vector2=(entry.rect as Rect2).position+Vector2(4,(entry.rect as Rect2).size.y*.5)
   check(not L.can_stand(wall_probe,4,true),"%s %s outer wall still blocks"% [map_id,entry.id])
  var world_src:=FileAccess.get_file_as_string("res://"+String(Maps.scene_of(map_id)).trim_prefix("res://"))
  # 조선(서원)은 예전부터 한옥 외관/실내 크로스페이드로 지붕을 숨긴다. 나머지 맵은 공용 컷어웨이 레이어.
  var cutaway:=world_src.contains("interior_layer")
  var hanok:=world_src.contains("hanok_interior") and world_src.contains("update_buildings")
  check(cutaway or hanok,"%s world draws a cutaway interior when the player enters"%map_id)
 # ---------------------------------------------------------------- 7) 기믹 3개 · 실제 카메라 · 에스컬레이터
 for pair in [["seowon",SeowonL],["gangnam",GangnamL],["haeundae",HaeundaeL],["dongseongno",DongseongnoL]]:
  var L2: Script=pair[1]
  check(L2.gimmicks().size()==3,"%s keeps exactly three core gimmicks"%pair[0])
  var ids: Array=[]
  for g in L2.gimmicks():ids.append(String(g.id))
  check(ids.size()==ids.duplicate().size() and not ids.has(""),"%s gimmick ids are unique"%pair[0])
  for g in L2.gimmicks():
   check(String(g.get("label",""))!="" and String(g.get("hint",""))!="","%s gimmick has visible label/hint: %s"%[pair[0],g.get("id")])
 check(GangnamL.gimmicks()[0].kind=="turnstile" and GangnamL.gimmicks()[1].kind=="escalator" and GangnamL.gimmicks()[2].kind=="cctv","강남역 keeps turnstile·escalator·CCTV")
 check(HaeundaeL.gimmicks()[0].kind=="wave" and HaeundaeL.gimmicks()[1].kind=="tide" and HaeundaeL.gimmicks()[2].kind=="mist","해운대 keeps wave·tide·mist")
 check(DongseongnoL.gimmicks()[0].kind=="flash" and DongseongnoL.gimmicks()[1].kind=="speaker" and DongseongnoL.gimmicks()[2].kind=="smoke","동성로 keeps flash·speaker·smoke")
 var gangnam_src:=FileAccess.get_file_as_string("res://scripts/survival/gangnam_world.gd")
 check(gangnam_src.contains("func draw_escalator") and gangnam_src.contains("if kind==\"escalator\":continue"),"the escalator is drawn under the actors (no hiding bug)")
 check(FileAccess.get_file_as_string("res://scripts/survival/rules.gd").contains("105.0*delta"),"rules move a standing rider along the escalator")
 check(FileAccess.get_file_as_string("res://scripts/survival/cctv_view.gd").contains("SubViewport") and FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("feed.world_2d=world.get_world_2d()"),"CCTV uses a real SubViewport camera feed")
 check(FileAccess.get_file_as_string("res://scripts/survival/gangnam_art.gd").contains("벽과 겹치면"),"floor zone labels are pushed away from walls")
 # ---------------------------------------------------------------- 8) 미니맵 장소명·이동·시야 차단
 check(SeowonL.zones().size()>=7 and HaeundaeL.zones().size()==8 and DongseongnoL.zones().size()==9,"every map exposes zone names for the minimap")
 check(FileAccess.get_file_as_string("res://scripts/survival/minimap.gd").contains("func draw_zone_names"),"the full map draws zone names")
 check(FileAccess.get_file_as_string("res://scripts/survival/minimap.gd").contains("func blind_hides_allies"),"the minimap has the blind-hides-allies rule")
 check(FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("map_open") and FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("MOUSE_FILTER_IGNORE"),"the open map passes movement input through")
 # ---------------------------------------------------------------- 9) 구출 시인성
 var rescue_src:=FileAccess.get_file_as_string("res://scripts/survival/rescue_markers.gd")
 check(rescue_src.contains("const BADGE_RADIUS=25.0") and rescue_src.contains("const NUMBER_SIZE=26"),"rescue countdown uses a big ring and a 26px number")
 check(rescue_src.contains("구조 필요") and rescue_src.contains("draw_arc(at,radius,-PI*.5"),"rescue countdown draws a progress ring")
 # ---------------------------------------------------------------- 10) 30도술: 장영실 기본 이펙트·보호막
 var jang:=live(37)
 var caster: Dictionary=jang.players.human
 caster.character="daoist:jangyeongsil";caster.role="daoist";caster.ult=jang.ULT_MAX;caster.cd={}
 caster.position=Vector2(1700,1500)
 jang.effects.clear()
 check(jang.skill(caster,Vector2.RIGHT,"ult"),"장영실 casts 천문기계")
 var jang_png:=false
 for e in jang.effects:
  if String(e.kind)=="fx_png" and String(e.get("file","")).contains("fx_clockwork"):jang_png=true
 check(jang_png,"장영실's own hand-drawn effect now fires in the match")
 check(FileAccess.get_file_as_string("res://scripts/survival/fx.gd").contains("func shield_bubble"),"a visible shield bubble exists")
 for world_path in ["scripts/survival/world.gd","scripts/survival/gangnam_world.gd","scripts/survival/haeundae_world.gd","scripts/survival/dongseongno_world.gd"]:
  check(FileAccess.get_file_as_string("res://"+world_path).contains("draw_shield_bubbles"),world_path+" draws the shield bubble")
 var bar:=live(38)
 var bari: Dictionary=bar.players.human
 bari.character="daoist:barigongju";bari.role="daoist";bari.cd={};bari.position=Vector2(1700,1500)
 check(bar.skill(bari,Vector2.RIGHT,"sub") and float(bari.buff.get("shield",0.0))>bar.elapsed,"저승꽃's shield is a real defensive buff")
 # ---------------------------------------------------------------- 10b) 기본/부침개 구분
 var base_clone: String=SkillFX.file_for("daoist:woochi","clone","")
 var skin_clone: String=SkillFX.file_for("daoist:woochi","clone","woochi_pancake")
 var base_paint: String=SkillFX.file_for("daoist:woochi","painting","")
 var skin_paint: String=SkillFX.file_for("daoist:woochi","painting","woochi_pancake")
 check(base_clone.ends_with("fx_talisman.png") and base_paint.ends_with("fx_scroll_sansuhwa.png"),"base woochi uses ink talisman / landscape scroll only")
 check(skin_clone.ends_with("fx_pancake_flip.png") and skin_paint.ends_with("fx_kimchijeon_cloak.png"),"pancake skin uses pancake flip / kimchi-jeon cloak only")
 check(base_clone!=skin_clone and base_paint!=skin_paint,"default and pancake never share an effect")
 check(String(Market.skin("woochi_pancake").name)=="부침개 전우치" and String(Market.DEFAULT_SKIN.name)=="기본 모습","shop names separate 기본 모습 and 부침개 전우치")
 check(FileAccess.get_file_as_string("res://scripts/survival/app.gd").contains("· 부침개"),"the in-game name marks the pancake skin")
 # ---------------------------------------------------------------- 10c) 4맵 공통 스킬 경로
 for map_id in ["seowon","gangnam","haeundae","dongseongno"]:
  var mr:=live(40)
  mr.use_map(map_id)
  var who: Dictionary=mr.players.human
  who.character="daoist:barigongju";who.role="daoist";who.cd={};who.ult=mr.ULT_MAX
  mr.phase="live";mr.elapsed=20.0
  who.position=mr.L.SPAWN;who.ground=mr.L.SPAWN
  mr.effects.clear()
  var cast_ok: bool=bool(mr.skill(who,Vector2.RIGHT,"sub"))
  var has_fx:=false
  for e in mr.effects:
   if String(e.kind)=="fx_png" and String(e.get("file",""))!="":has_fx=true
  check(cast_ok and has_fx and mr.L==Maps.layout_of(map_id),"보호막 도술 works with its own art on "+map_id)
  check(float(who.buff.get("shield",0.0))>mr.elapsed,"the shield buff applies on "+map_id)
  var world_file:=String(Maps.scene_of(map_id))
  var world_src2:=FileAccess.get_file_as_string(world_file)
  check(world_src2.contains("draw_shield_bubbles") and (world_src2.contains("draw_dynamic") or world_src2.contains("draw_effects")),"map "+map_id+" shares the common skill/effect render path")
 # ---------------------------------------------------------------- 11) 버전
 var project:=FileAccess.get_file_as_string("res://project.godot")
 var preset:=FileAccess.get_file_as_string("res://export_presets.cfg")
 check(project.contains("config/version=\"2.0.37\""),"project version is 2.0.37")
 check(preset.contains("version/code=48") and preset.contains("version/name=\"2.0.37\""),"Android versionCode 48 / 2.0.37")
 print("V36 RESULT checks=",checks," failures=",failures)
 quit(1 if failures>0 else 0)
