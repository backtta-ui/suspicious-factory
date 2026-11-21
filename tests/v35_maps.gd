extends SceneTree
## 2.0.35 검증: 4맵 풀(서원·강남역·해운대·동성로) · 새 맵 연결성/둔갑/기믹 ·
## 8방향 걷기 시트 행 순서 · 맵별 BGM 전환 · 서원 리뉴얼 11종 ·
## 2.0.34 피드백(부침개 이펙트 크기·강남 바닥 뎁스)까지 한 번에 확인한다.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const SeowonL=preload("res://scripts/survival/layout.gd")
const GangnamL=preload("res://scripts/survival/gangnam_layout.gd")
const HaeundaeL=preload("res://scripts/survival/haeundae_layout.gd")
const DongseongnoL=preload("res://scripts/survival/dongseongno_layout.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V35 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
## 40px 격자 flood fill: 걸어 다닐 수 있는 바닥이 한 덩어리인지.
func components(L: Script) -> Array:
 var step:=40.0
 var cells:= {}
 for y in range(int(L.SIZE.y/step)):
  for x in range(int(L.SIZE.x/step)):
   var p:=Vector2((x+.5)*step,(y+.5)*step)
   if L.can_stand(p,9):cells[Vector2i(x,y)]=true
 var seen:= {}
 var sizes: Array=[]
 for key in cells:
  if seen.has(key):continue
  var stack: Array=[key];seen[key]=true;var count:=0
  while not stack.is_empty():
   var cell: Vector2i=stack.pop_back();count+=1
   for off in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
    var other: Vector2i=cell+off
    if cells.has(other) and not seen.has(other):seen[other]=true;stack.append(other)
  sizes.append(count)
 sizes.sort();sizes.reverse()
 return sizes
func check_map(L: Script,map_id: String,zone_count: int) -> void:
 check(L.map_id()==map_id,"%s 레이아웃 id"%map_id)
 check(L.SIZE==Vector2(3400,2600),"3400×2600 대형 맵: "+map_id)
 check(L.ZONES.size()==zone_count,"%s 구역 %d개" % [map_id,zone_count])
 var sizes:=components(L)
 check(sizes.size()==1,"%s 걸어 다닐 수 있는 바닥이 하나로 이어져 있다(고립 구역 없음): %s" % [map_id,str(sizes)])
 var bad_props: Array=[]
 for object in L.OBJECTS:
  if not L.can_stand(object.p,10):bad_props.append(object.p)
 check(bad_props.is_empty(),"%s 모든 둔갑 사물이 이동 가능한 자리에 있다: %s" % [map_id,str(bad_props.slice(0,4))])
 check(L.OBJECTS.size()>=40,"%s 둔갑 사물 40개 이상: %d" % [map_id,L.OBJECTS.size()])
 check(L.WALKER_ROUTES.size()>=3,"%s 움직이는 둔갑 순찰로 3개 이상" % map_id)
 var moving_ok:=true
 for object in L.OBJECTS:
  if not bool(L.form(String(object.kind)).get("moving",false)):moving_ok=false
 check(moving_ok,"%s 둔갑 사물 전부 자유 이동" % map_id)
 for route in L.WALKER_ROUTES:
  var kind: String=String(route.kind)
  check(not C.prop_sheet(kind).is_empty(),"%s 움직이는 8방향 시트 등록: %s" % [map_id,kind])
 check(L.gimmicks().size()==3,"%s 핵심 기믹 3종" % map_id)
 check(L.circle_final_center().distance_to(L.SPAWN)<2000.0,"%s 최종 안전구역 중심이 맵 안" % map_id)
 for zone in L.ZONES:
  var near: Vector2=L.safe((zone.rect as Rect2).get_center())
  var cell:=Vector2i(int(near.x/40.0),int(near.y/40.0))
  check(L.can_stand(near,9),"%s 구역 도달 가능: %s %s" % [map_id,zone.name,str(cell)])
 for y in L.yokai_spawns():
  for d in L.daoist_spawns():
   check(y.distance_to(d)>=L.SPAWN_SEPARATION,"%s 스폰 거리 확보" % map_id)
func run() -> void:
 # ---------------------------------------------------------------- 1) 4맵 풀
 check(Maps.ids().size()==4,"맵 풀이 4개")
 for id in ["seowon","gangnam","haeundae","dongseongno"]:
  check(Maps.ids().has(id) and Maps.exists(id),"맵 등록: "+id)
 check(Maps.name_of("haeundae")=="부산 해운대" and Maps.name_of("dongseongno")=="대구 동성로","새 맵 이름 표시")
 check(Maps.scene_of("haeundae").ends_with("haeundae_world.gd") and Maps.arena_of("haeundae")=="haeundae","해운대 월드·아레나 연결")
 check(Maps.scene_of("dongseongno").ends_with("dongseongno_world.gd"),"동성로 월드 연결")
 check(Maps.layout_of("haeundae")==HaeundaeL and Maps.layout_of("dongseongno")==DongseongnoL,"맵별 레이아웃 스크립트")
 var seen:= {}
 var rng:=RandomNumberGenerator.new();rng.seed=1234
 for i in range(200):seen[Maps.pick(rng)]=true
 check(seen.size()==4,"빠른 매치 무작위가 4맵을 모두 고른다: "+str(seen.keys()))
 for id2 in Maps.ids():
  Maps.set_preferred(String(id2))
  check(Maps.pick(rng)==String(id2),"디버그 맵 지정 우선: "+String(id2))
 Maps.set_preferred("random");Maps.set_current("seowon")
 # ---------------------------------------------------------------- 2) 새 맵 구조
 check_map(HaeundaeL,"haeundae",8)
 check_map(DongseongnoL,"dongseongno",9)
 check(HaeundaeL.WATER.size()>=5 and HaeundaeL.TIDE_RECT.size.x>0.0,"해운대 비대칭 해안선·밀물 지름길")
 check(not HaeundaeL.can_stand(HaeundaeL.WATER[0].get_center(),4),"해운대 바다로 걸어 들어갈 수 없다")
 check(DongseongnoL.BUILDINGS_RECTS.size()>=40,"동성로 불규칙 격자 골목(건물 40동 이상)")
 # 상표권 안전: 실제 상호 텍스트가 코드/에셋 이름에 없다
 var dong_src:=FileAccess.get_file_as_string("res://scripts/survival/dongseongno_layout.gd")
 var art_src:=FileAccess.get_file_as_string("res://scripts/survival/dongseongno_art.gd")
 check(not dong_src.contains("스파크랜드") and not dong_src.contains("인생네컷") and not art_src.contains("스파크랜드"),"동성로 상표권 안전(패러디 명칭만)")
 check(dong_src.contains("별빛랜드") and dong_src.contains("반월당"),"동성로 공공 지명·패러디 명칭 사용")
 # ---------------------------------------------------------------- 3) 8방향 시트 행 순서
 var expected:=["front","front_left","left","back_left","back","back_right","right","front_right"]
 for kind in ["seagull","crab","mascot","delivery_cart"]:
  var sheet: Dictionary=C.prop_sheet(kind)
  check(not sheet.is_empty() and Array(sheet.get("rows",[]))==expected,"8방향 시트 행 순서(S·SW·W·NW·N·NE·E·SE): "+kind)
  var cell: Array=sheet.get("cell",[])
  check(cell.size()==2 and int(cell[0])==192 and int(cell[1])==192,"시트 셀 192×192: "+kind)
  check(C.eight_direction(Array(sheet.get("rows",[]))),"8방향 행 인식: "+kind)
  for facing in range(8):
   var mapped: Dictionary=C.sheet_row(Array(sheet.get("rows",[])),facing)
   check(int(mapped.row)>=0 and String(mapped.view)!="", "방향 매핑: %s facing %d → %s" % [kind,facing,mapped.view])
 # 남쪽(S, facing 2)이 0행, 동쪽(E, facing 0)이 6행인지 실제 순서 검증
 var rows: Array=C.prop_sheet("seagull").get("rows",[])
 check(int(C.sheet_row(rows,2).row)==0,"남쪽은 0행(front)")
 check(int(C.sheet_row(rows,0).row)==6,"동쪽은 6행(right)")
 check(int(C.sheet_row(rows,6).row)==4,"북쪽은 4행(back)")
 check(int(C.sheet_row(rows,4).row)==2,"서쪽은 2행(left)")
 var sheet_file:=FileAccess.get_file_as_string("res://assets/woo/ingame/walk_sheets.json")
 check(sheet_file.contains("seagull_walk.png") and sheet_file.contains("mascot_walk.png") and sheet_file.contains("delivery_cart_walk.png") and sheet_file.contains("crab_walk.png"),"walk_sheets.json에 4종 시트 등록")
 # ---------------------------------------------------------------- 4) 서원 리뉴얼 11종
 var kinds:= {}
 for object in SeowonL.OBJECTS:kinds[String(object.kind)]=true
 for kind2 in ["jar","bamboo_pot","book_chest","brazier","folding_screen"]:
  check(kinds.has(kind2),"서원 둔갑 사물 리뉴얼: "+kind2)
  check(not SeowonL.form(kind2).is_empty() and float(SeowonL.form_visual(kind2).height)>=40.0,"서원 사물 정의·크기: "+kind2)
  var art: String=Maps.form_art_path(kind2,"seowon")
  check(art!="" and ResourceLoader.exists(art),"서원 사물 원화: "+art)
 check(bool(SeowonL.form("cat").moving) and bool(SeowonL.form("dog").moving),"서원 고양이·강아지 둔갑 유지")
 check(C.eight_direction(Array(C.animal_sheet("cat").get("rows",[]))) and C.eight_direction(Array(C.animal_sheet("dog").get("rows",[]))),"서원 고양이·강아지 8방향 유지")
 for asset in ["res://assets/woo/seowon/gimmicks/gimmick_lantern_on.png","res://assets/woo/seowon/gimmicks/gimmick_lantern_off.png","res://assets/woo/seowon/gimmicks/gimmick_pavilion_pillar.png","res://assets/woo/seowon/gimmicks/gimmick_stone_bridge.png","res://assets/woo/seowon/env/env_cherry_tree.png","res://assets/woo/seowon/env/env_bamboo_clump.png"]:
  check(ResourceLoader.exists(asset),"서원 리뉴얼 에셋: "+asset)
 # 새 맵 둔갑 사물 원화
 for pair in [["parasol","haeundae"],["beach_ball","haeundae"],["photobooth","dongseongno"],["claw_machine","dongseongno"]]:
  var path: String=Maps.form_art_path(String(pair[0]),String(pair[1]))
  check(path!="" and ResourceLoader.exists(path),"새 맵 둔갑 원화: "+path)
 # ---------------------------------------------------------------- 5) BGM
 for map_id in ["haeundae","dongseongno"]:
  check(ResourceLoader.exists("res://assets/audio/bgm_%s.wav"%map_id),"맵 전용 BGM 파일: "+map_id)
 root.size=Vector2i(1600,720)
 var game:=App.instantiate();root.add_child(game)
 await frames(10)
 var snd=game.sound
 if snd!=null:
  for map_id2 in ["haeundae","dongseongno","gangnam","seowon"]:
   snd.play_map_bgm(map_id2)
   check(snd.current_map==map_id2 and snd.music!=null and snd.music.stream!=null,"BGM 전환: "+map_id2)
  # ------------------------------------------------------------- 6) 해운대 매치·기믹
  game.create_room("V35 해운대",8,true,"",2,"haeundae")
  await create_timer(.35).timeout
  game.rules.players.human.ready=true
  game.start_match();await frames(6)
  game.rules.confirm_character("human")
  for i in range(320):
   if game.rules.phase=="selection":game.rules.tick(.1)
   await process_frame
   if game.screen=="match" and not game.changing:break
  check(game.screen=="match","해운대 매치 화면 진입")
  for i in range(80):
   if game.rules.phase=="live":break
   game.rules.tick(.2)
  check(game.rules.phase=="live" and Maps.current_id=="haeundae","해운대 라이브·맵 확정")
  check(game.world!=null and game.world.has_method("draw_gimmick_objects"),"해운대 전용 월드 로드")
  check(str(game.timer_label.text).contains("부산 해운대"),"HUD에 해운대 표시")
  if game.minimap!=null:game.minimap.sync_map()
  check(game.minimap!=null and game.minimap.L.map_id()=="haeundae","미니맵이 해운대 구조")
  var human: Dictionary=game.rules.players.human
  human.role="daoist"
  game.rules.elapsed=30.0
  var g: RefCounted=game.rules.gimmicks
  # 7종 둔갑 사물 전부 자유 이동
  for kind3 in ["parasol","tube","surfboard","cooler","pocha_stall","plastic_chair","beach_ball"]:
   human.form=kind3;human.buff.transform=game.rules.elapsed+20.0
   human.position=Vector2(1690,790);human.intent=Vector2(1,0)
   var before: Vector2=human.position
   for i in range(6):game.rules.tick(.05)
   check(human.position.distance_to(before)>6.0,"해운대 둔갑 사물도 이동: "+kind3)
  human.form="";human.buff.erase("transform");human.intent=Vector2.ZERO
  # 파도 경보: 해안 구역 감속
  g.wave_until=game.rules.elapsed+5.0
  human.position=Vector2(1200,1700)
  check(g.speed_factor(human)<0.8,"파도 경보가 해안가 이동을 느리게 한다")
  human.position=Vector2(1690,790)
  check(is_equal_approx(g.speed_factor(human),1.0),"내륙에서는 파도 영향 없음")
  g.wave_until=0.0
  # 밀물: 다리 지름길 차단·해제
  g.tide_rect=HaeundaeL.TIDE_RECT
  g.tide_until=game.rules.elapsed+5.0
  check(g.blocked(HaeundaeL.TIDE_RECT.get_center()),"밀물이 다리 지름길을 막는다")
  g.tide_until=0.0
  check(not g.blocked(HaeundaeL.TIDE_RECT.get_center()),"밀물이 빠지면 다시 지나갈 수 있다")
  # 물안개: 시야 감소
  human.position=Vector2(2210,540)
  g.cooldown.clear()
  var mist_used: bool=g.interact(human)
  check(mist_used and g.mist_active() and g.zone_mist("surf"),"샤워기 물안개 발동")
  check(float(game.rules.vision_for("human").get("fog",0.0))>0.2,"물안개가 실제 시야를 흐린다")
  # 등대·천막 2프레임 연출
  check(ResourceLoader.exists("res://assets/woo/haeundae/gimmicks/lighthouse_beam_2f.png") and ResourceLoader.exists("res://assets/woo/haeundae/gimmicks/pocha_tent_sway_2f.png"),"해운대 2프레임 연출 에셋")
  # 자동 주기(밀물/파도)가 실제 tick에서 발동
  g.wave_until=0.0;g.tide_until=0.0;g.wave_next=game.rules.elapsed+0.01;g.tide_next=game.rules.elapsed+0.02
  game.rules.tick(.05)
  check(g.wave_active() and g.tide_active(),"파도·밀물이 주기적으로 자동 발동")
  game.cleanup_match();await frames(4)
  # ------------------------------------------------------------- 7) 동성로 매치·기믹
  game.preferred_role="daoist"
  game.create_room("V35 동성로",8,true,"",2,"dongseongno")
  await create_timer(.35).timeout
  game.rules.players.human.ready=true
  game.start_match();await frames(6)
  game.rules.confirm_character("human")
  for i in range(320):
   if game.rules.phase=="selection":game.rules.tick(.1)
   await process_frame
   if game.screen=="match" and not game.changing:break
  check(game.screen=="match","동성로 매치 화면 진입")
  for i in range(80):
   if game.rules.phase=="live":break
   game.rules.tick(.2)
  check(game.rules.phase=="live" and Maps.current_id=="dongseongno","동성로 라이브·맵 확정")
  check(game.world!=null and game.world.has_method("draw_gimmick_objects"),"동성로 전용 월드 로드")
  check(str(game.timer_label.text).contains("대구 동성로"),"HUD에 동성로 표시")
  if game.minimap!=null:game.minimap.sync_map()
  check(game.minimap!=null and game.minimap.L.map_id()=="dongseongno","미니맵이 동성로 구조")
  var human2: Dictionary=game.rules.players.human
  human2.role="daoist"
  game.rules.elapsed=40.0
  var g2: RefCounted=game.rules.gimmicks
  for kind4 in ["photobooth","claw_machine","tteokbokki_stall","neon_sign","speaker","shopping_bags"]:
   human2.form=kind4;human2.buff.transform=game.rules.elapsed+20.0
   human2.position=Vector2(1600,1400);human2.intent=Vector2(1,0)
   var before2: Vector2=human2.position
   for i in range(6):game.rules.tick(.05)
   check(human2.position.distance_to(before2)>6.0,"동성로 둔갑 사물도 이동: "+kind4)
  human2.form="";human2.buff.erase("transform");human2.intent=Vector2.ZERO
  # 도술네컷 플래시: 근처 요괴 눈부심 + 소리
  var yokai_id: String=""
  for p in game.rules.players.values():
   if String(p.role)=="yokai" and p.id!="human":yokai_id=String(p.id);break
  var yokai: Dictionary=game.rules.players[yokai_id]
  yokai.position=Vector2(1440,1120)
  human2.position=Vector2(1440,1120)
  g2.cooldown.clear()
  g2.interact(human2)
  check(g2.flash_active() and float(yokai.get("blind_until",0.0))>game.rules.elapsed,"도술네컷 플래시가 요괴를 눈부시게 한다")
  check(g2.noise_until>game.rules.elapsed,"플래시 소리가 요괴에게 들린다")
  # 버스킹 스피커: 발소리 교란
  human2.position=Vector2(2050,1420)
  g2.cooldown.clear()
  g2.interact(human2)
  check(g2.speaker_active() and g2.trail_blocked(Vector2(2050,1420)),"버스킹 스피커가 발소리를 덮는다")
  human2.trail=[]
  human2.position=Vector2(1800,1420);human2.intent=Vector2(1,0)
  for i in range(6):game.rules.tick(.05)
  check(human2.trail.is_empty(),"교란 범위에서는 발자국이 남지 않는다")
  human2.intent=Vector2.ZERO
  # 환풍기 연기: 시야 차단
  human2.position=Vector2(2500,780)
  g2.cooldown.clear()
  g2.interact(human2)
  check(g2.fog_active(),"환풍기 연기 발동")
  check(g2.line_blocked(Vector2(2600,780),Vector2(2400,780)),"연기가 시선을 막는다")
  check(float(game.rules.vision_for("human").get("fog",0.0))>0.2,"연기 속에서는 화면이 뿌옇다")
  # 2프레임 연출 에셋
  for asset2 in ["sparkland_wheel_2f.png","arcade_gate_glow_2f.png","neon_sign_glow_2f.png","sparkland_gate.png","banwoldang_stairs.png","arcade_gate.png"]:
   check(ResourceLoader.exists("res://assets/woo/dongseongno/gimmicks/"+asset2),"동성로 연출 에셋: "+asset2)
  game.cleanup_match();await frames(4)
  # ------------------------------------------------------------- 8) 2.0.34 피드백
  var human3: Dictionary={"id":"human","position":Vector2(1600,1400),"character":"daoist:woochi","skin":"woochi_pancake","facing":2,"buff":{}}
  game.rules.players.human=human3
  game.rules.effects.clear()
  game.rules.signature(human3,"painting")
  var pancake_ok:=false
  for e in game.rules.effects:
   if String(e.get("kind",""))=="fx_png" and String(e.get("file","")).contains("kimchijeon"):
    pancake_ok=float(e.get("size",999.0))<=100.0 and float(e.get("alpha",1.0))<=0.86
  check(pancake_ok,"부침개 이펙트가 캐릭터를 가리지 않게 크기·투명도 조정")
  var gangnam_art_src:=FileAccess.get_file_as_string("res://scripts/survival/gangnam_art.gd")
  check(gangnam_art_src.contains("조명 뎁스") or gangnam_art_src.contains("glow_radius"),"강남역 바닥 구역 색조·조명 뎁스 보강")
  # 전체 스위트는 tools/test.sh가 확인한다(이 파일은 새 맵 전용).
 print("V35 RESULT checks=",checks," failures=",failures)
 quit(1 if failures>0 else 0)
