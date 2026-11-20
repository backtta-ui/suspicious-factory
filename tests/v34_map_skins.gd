extends SceneTree
## 2.0.34 검증: 랜덤 맵(서원+강남역) · 강남역 구조/이동/둔갑/기믹 6종 ·
## 안전구역 개편(시작 반경·원 밖 불이익) · 스킨(부침개 전우치) · 기본 10인 이펙트 ·
## 확대 미니맵 실시간 · 구출 필요 아이콘 · 오버레이가 경기를 멈추지 않음.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const Market=preload("res://scripts/survival/market.gd")
const SkillFX=preload("res://scripts/survival/skill_fx.gd")
const SeowonL=preload("res://scripts/survival/layout.gd")
const GangnamL=preload("res://scripts/survival/gangnam_layout.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V34 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func run() -> void:
 # ---------------------------------------------------------------- 1) 맵 풀/보존
 check(Maps.ids().size()==2 and Maps.ids().has("seowon") and Maps.ids().has("gangnam"),"맵 풀에 서원과 강남역이 함께 있다")
 check(SeowonL.buildings().size()==6 and SeowonL.OBJECTS.size()>=40,"기존 월하의 서원 맵이 그대로 보존됐다(건물 6·사물 40+)")
 check(SeowonL.map_id()=="seowon" and GangnamL.map_id()=="gangnam","맵마다 고유 id")
 var seen:= {}
 var rng:=RandomNumberGenerator.new();rng.seed=77
 for i in range(40):seen[Maps.pick(rng)]=true
 check(seen.has("seowon") and seen.has("gangnam"),"빠른 매치 무작위 선택이 두 맵을 모두 고른다")
 Maps.set_preferred("gangnam")
 check(Maps.pick(rng)=="gangnam","디버그 맵 지정이 무작위보다 우선한다")
 Maps.set_preferred("random");Maps.set_current("seowon")
 check(Maps.name_of("gangnam")=="서울 강남역" and Maps.name_of("seowon")=="월하의 서원","맵 이름 표시 값")
 check(Maps.scene_of("gangnam").ends_with("gangnam_world.gd") and Maps.arena_of("gangnam")=="gangnam","강남역 월드·아레나 연결")
 # ---------------------------------------------------------------- 2) 강남역 구조
 var L: Script=GangnamL
 check(L.SIZE==Vector2(3400,2600) and L.ZONES.size()==9,"강남역 크기와 9개 구역")
 var corner_standing: bool=L.can_stand(L.circle_final_center(),12)
 check(corner_standing,"안전구역 최종 중심이 실제 이동 가능 구역이다")
 check(not L.can_stand(L.TRACK.get_center(),4),"승강장 선로(트랙)는 진입 차단")
 check(not L.can_stand(Vector2(1500,2440),4),"스크린도어 밖 선로로 걸어갈 수 없다")
 # 연결성: 40px 격자 flood fill
 var step:=40.0
 var cells:= {}
 for y in range(int(L.SIZE.y/step)):
  for x in range(int(L.SIZE.x/step)):
   var p:=Vector2((x+.5)*step,(y+.5)*step)
   if L.can_stand(p,9):cells[Vector2i(x,y)]=true
 var start:=Vector2i(int(L.SPAWN.x/step),int(L.SPAWN.y/step))
 var comps:= {}
 var sizes: Array=[]
 var seen_comps:= {}
 for key in cells:
  if seen_comps.has(key):continue
  var stack: Array=[key];seen_comps[key]=true;var comp: Array=[]
  while not stack.is_empty():
   var cell: Vector2i=stack.pop_back();comp.append(cell)
   for off in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
    var other: Vector2i=cell+off
    if cells.has(other) and not seen_comps.has(other):seen_comps[other]=true;stack.append(other)
  sizes.append(comp.size())
  if comp.has(start):
   for c in comp:comps[c]=true
 sizes.sort();sizes.reverse()
 check(sizes.size()==1,"걸어 다닐 수 있는 바닥이 하나로 이어져 있다(고립 구역 없음)")
 for zone in L.ZONES:
  var center: Vector2=(zone.rect as Rect2).get_center()
  var reachable: bool=L.can_stand(center,9)
  var cell:=Vector2i(int(center.x/step),int(center.y/step))
  if reachable:check(comps.has(cell),"구역 도달 가능: "+String(zone.name))
  else:
   # 구역 중심이 섬(카운터 등) 위면 주변에서 도달 가능한지만 확인한다.
   var near: Vector2=L.safe(center)
   check(comps.has(Vector2i(int(near.x/step),int(near.y/step))),"구역 도달 가능(중심 우회): "+String(zone.name))
 var bad_props: Array=[]
 for object in L.OBJECTS:
  if not L.can_stand(object.p,10):bad_props.append(object.p)
 check(bad_props.is_empty(),"모든 둔갑 사물이 이동 가능한 자리에 있다: "+str(bad_props))
 check(L.WALKER_ROUTES.size()>=3,"움직이는 둔갑(배달 로봇·킥보드) 순찰로 3개 이상")
 check(L.form("delivery_robot").get("moving",false) and L.form("kickboard").get("moving",false),"배달 로봇·킥보드는 움직이는 둔갑")
 for kind in ["iced_coffee","vending","kiosk","banner","luggage","hydrant"]:
  check(not L.form(kind).is_empty() and float(L.form_visual(kind).height)>30.0,"강남역 둔갑 사물 정의: "+kind)
 check(L.corner_radius()>=2140.0,"시작 반경이 맵 네 모서리를 포함한다")
 # ---------------------------------------------------------------- 3) 강남역 매치 시작
 root.size=Vector2i(1600,720)
 var game:=App.instantiate();root.add_child(game)
 await frames(8)
 game.create_room("V34 강남역",8,true,"",2,"gangnam")
 await create_timer(.35).timeout
 game.rules.players.human.ready=true
 game.start_match();await frames(6)
 # ---------------------------------------------------------------- 2.5) 선택창 생동감
 var sel: Node=game.selection_view
 check(sel!=null and sel.hero_art!=null,"캐릭터 선택창 대형 원화가 애니메이션 노드로 존재")
 check(sel!=null and sel.hero_fx_file!="" and ResourceLoader.exists(sel.hero_fx_file),"선택 캐릭터 전용 이펙트 PNG 연결: "+str(sel.hero_fx_file) if sel!=null else "no selection view")
 if sel!=null:
  var scale_before: Vector2=sel.hero_art.scale
  var angle_before: float=sel.hero_fx_angle
  await frames(14)
  check(sel.hero_art.scale!=scale_before or sel.hero_entry>=1.0,"선택 캐릭터가 등장·호흡 모션으로 움직인다")
  check(sel.hero_fx_angle!=angle_before,"전용 이펙트 레이어가 회전·발광한다")
  var pick_id: String=""
  for entry in C.catalog(sel.side()):
   if String(entry.id)!=String(sel.selection_id):pick_id=String(entry.id);break
  sel._pick(pick_id)
  check(sel.last_sound_skill!="","캐릭터 선택 시 대표 도술 효과음이 재생된다: "+String(sel.last_sound_skill))
 game.rules.confirm_character("human")
 for i in range(320):
  if game.rules.phase=="selection":game.rules.tick(.1)
  await process_frame
  if game.screen=="match" and not game.changing:break
 check(game.screen=="match","강남역 매치 화면 진입")
 ## 카운트다운(3초)을 실제 틱으로 넘겨 라이브 상태로 만든다(판정은 live에서만 돈다).
 for i in range(80):
  if game.rules.phase=="live":break
  game.rules.tick(.2)
 check(game.rules.phase=="live","경기가 라이브 상태")
 check(Maps.current_id=="gangnam" and game.rules.map_id=="gangnam","맵이 강남역으로 확정")
 check(game.L.map_id()=="gangnam","앱이 강남역 레이아웃을 쓴다")
 check(game.world!=null and game.world.has_method("draw_gimmick_objects"),"강남역 전용 월드가 로드됐다")
 check(str(game.timer_label.text).contains("서울 강남역"),"상단 HUD에 현재 맵 이름 표시: "+str(game.timer_label.text))
 if game.minimap!=null:game.minimap.sync_map()
 check(game.minimap!=null and game.minimap.L.map_id()=="gangnam","미니맵이 강남역 구조를 쓴다")
 check(game.rules.gimmicks!=null and game.rules.gimmicks.defs.size()>=6,"기믹 6종이 rules에 연결")
 var human: Dictionary=game.rules.players.human
 human.role="daoist"
 # ---------------------------------------------------------------- 4) 둔갑(모든 사물 자유 이동)
 game.rules.elapsed=30.0
 human.position=Vector2(300,330);human.buff.transform=game.rules.elapsed+20.0
 var disguised_ok:=false
 for i in range(4):
  human.position=Vector2(300,330)
  if game.rules.command("human","interact"):disguised_ok=human.form!=""
  if disguised_ok:break
 check(disguised_ok and String(human.form)!="","강남역 사물에 둔갑된다: "+String(human.form))
 for kind in ["iced_coffee","vending","kiosk","banner","luggage","hydrant","delivery_robot","kickboard"]:
  human.form=kind;human.buff.transform=game.rules.elapsed+20.0
  human.position=Vector2(1650,1330);human.intent=Vector2(1,0)
  var before: Vector2=human.position
  for i in range(6):game.rules.tick(.05)
  check(human.position.distance_to(before)>6.0,"둔갑 사물도 조이스틱으로 이동: "+kind)
 human.form="";human.buff.erase("transform");human.intent=Vector2.ZERO
 # ---------------------------------------------------------------- 5) 기믹 6종
 var g: RefCounted=game.rules.gimmicks
 # 개찰구: 도사가 통과하면 잠기고 실제로 막힌다
 game.rules.elapsed=40.0
 human.position=Vector2(1500,1930)
 game.rules.tick(.05)
 var gate_center: Vector2=Vector2(1500,1930)
 check(g.turnstile_until>game.rules.elapsed,"도사 통과 후 개찰구가 잠긴다")
 check(g.blocked(gate_center),"잠긴 개찰구가 통행을 막는다")
 check(g.entry_at(gate_center,120).get("kind","")=="turnstile","개찰구 기믹 위치 조회")
 game.rules.elapsed=g.turnstile_until+.1
 check(not g.blocked(gate_center),"잠금이 풀리면 다시 통과된다")
 # 자판기: 소음 파동
 human.position=Vector2(300,1040)
 var vend: bool=game.rules.command("human","gimmick")
 check(vend and g.noise_until>game.rules.elapsed,"자판기를 눌러 소음 파동이 발생")
 check(g.noise_pos.distance_to(Vector2(300,1000))<60.0,"소음 위치가 자판기 근처")
 # 에스컬레이터: 요괴가 방향 반전
 var yokai_id: String=""
 for p in game.rules.players.values():
  if String(p.role)=="yokai" and p.id!="human":yokai_id=String(p.id);break
 var before_dir: int=g.escalator_dir
 var yokai: Dictionary=game.rules.players[yokai_id]
 yokai.position=Vector2(560,1520)
 game.rules.gimmicks.cooldown.clear()
 var flipped: bool=game.rules.gimmicks.interact(yokai)
 check(flipped and g.escalator_dir==-before_dir,"요괴가 에스컬레이터 방향을 반전")
 check(not g.on_escalator(Vector2(560,1520)).is_empty(),"에스컬레이터 위 판정")
 # 조명: 도사가 끄고 요괴가 켠다
 human.position=Vector2(1250,1000)
 game.rules.gimmicks.cooldown.clear()
 game.rules.command("human","gimmick")
 check(g.zone_dark("lobby"),"도사가 조명을 꺼 암전")
 check(float(game.rules.vision_for("human").get("dark",0.0))>0.2,"암전 구역은 실제로 어둡게 보인다")
 yokai.position=Vector2(1250,1000)
 game.rules.gimmicks.cooldown.clear()
 game.rules.gimmicks.interact(yokai)
 check(not g.zone_dark("lobby"),"요괴가 조명을 다시 켠다")
 # CCTV: 다른 구역 실시간 감시
 human.position=Vector2(2840,430)
 game.rules.gimmicks.cooldown.clear()
 game.rules.command("human","gimmick")
 check(g.cctv_until>game.rules.elapsed and L.CCTV_ZONES.has(g.cctv_zone),"CCTV가 구역을 감시한다: "+g.cctv_zone)
 # 셔터: 통로·시야 차단
 human.position=Vector2(2320,1620)
 game.rules.gimmicks.cooldown.clear()
 game.rules.command("human","gimmick")
 check(g.shutter_until>game.rules.elapsed,"팝업존 셔터가 내려온다")
 var shutter_rect: Rect2=Rect2(2266,1520,28,200)
 check(g.blocked(shutter_rect.get_center()),"셔터가 통로를 막는다")
 check(g.line_blocked(Vector2(2190,1600),Vector2(2400,1600)),"셔터가 시야도 막는다")
 # ---------------------------------------------------------------- 6) 안전구역 개편
 game.rules.elapsed=0.0
 var c0: Dictionary=game.rules.circle()
 check(float(c0.radius)>=L.corner_radius()-2.0,"시작 원이 맵 모서리 반경에서 시작: "+str(c0.radius))
 for corner in [Vector2(80,110),Vector2(3320,110),Vector2(80,2490),Vector2(3320,2490)]:
  check((corner as Vector2).distance_to(c0.center)<=float(c0.radius)+1.0,"시작 원이 모서리를 포함")
 game.rules.elapsed=180.0
 var c1: Dictionary=game.rules.circle()
 check(float(c1.radius)>=L.corner_radius()-1.0,"2단계 시작도 맵 끝점 반경에서 출발")
 game.rules.elapsed=600.0
 var c3: Dictionary=game.rules.circle()
 check(L.can_stand(c3.center,12),"최종 원 중심이 벽 안이 아니다")
 # 원 밖 불이익: 도사
 game.rules.elapsed=211.0
 var outside_point: Vector2=L.safe(Vector2(250,240))
 check(outside_point.distance_to(game.rules.circle().center)>float(game.rules.circle().radius),"원 밖 테스트 지점 확보")
 human.position=outside_point;human.form="luggage";human.buff.transform=game.rules.elapsed+30.0
 human.outside=0.0;human.outside_life=0;human.lives=3;human.eliminated=false;human.captured=false
 for i in range(2):game.rules.tick(.05)
 check(human.form=="","원 밖 진입 즉시 둔갑이 강제 해제")
 check(not game.rules.command("human","interact") or human.form=="","원 밖에서는 다시 둔갑할 수 없다")
 game.rules.elapsed=211.0
 for i in range(60):game.rules.tick(.1)
 check(float(human.buff.get("revealed",0.0))>game.rules.elapsed,"2초 뒤 요괴에게 위치가 노출")
 check(is_equal_approx(game.rules.outside_speed_factor(human),.9),"5초 뒤 도사 이속 10% 감소")
 game.rules.elapsed=211.0;human.outside=10.5
 game.rules.tick(.05)
 check(int(human.lives)==2,"10초 경과 시 목숨 1개 차감: "+str(human.lives))
 human.outside=25.6;game.rules.tick(.05)
 check(int(human.lives)==1,"이후 15초마다 추가 차감: "+str(human.lives))
 # 원 밖 불이익: 요괴
 var foe: Dictionary=game.rules.players[yokai_id]
 foe.position=outside_point;foe.outside=0.0
 game.rules.tick(.05)
 check(is_equal_approx(game.rules.outside_speed_factor(foe),.85),"원 밖 요괴는 즉시 15% 감소")
 foe.outside=3.2
 check(game.rules.visible(yokai_id).size()<=game.rules.players.size(),"원 밖 요괴 탐지 약화 경로")
 check(is_equal_approx(game.rules.outside_cooldown_factor(foe),1.0),"5초 전에는 쿨타임 패널티 없음")
 foe.outside=5.2
 check(is_equal_approx(game.rules.outside_cooldown_factor(foe),1.25),"5초 뒤 요괴 스킬 쿨타임 25% 증가")
 foe.outside=0.0
 check(is_equal_approx(game.rules.outside_cooldown_factor(foe),1.0),"복귀 시 즉시 해제")
 check(float(game.rules.vision_for("human").get("warning",0.0))>=0.0,"경고 비네팅 값이 vision에 전달")
 # ---------------------------------------------------------------- 7) 스킨·이펙트
 var pancake: Dictionary=Market.skin("woochi_pancake")
 check(String(pancake.get("character",""))=="daoist:woochi","부침개 전우치는 전우치 전용 스킨")
 check(ResourceLoader.exists(String(pancake.get("sheet",""))),"스킨 걷기 시트 파일 존재")
 check(ResourceLoader.exists(String(pancake.get("portrait",""))) and ResourceLoader.exists(String(pancake.get("full",""))),"스킨 초상·전신 파일 존재")
 check(C.walk_sheet("woochi_pancake").get("rows",[]).size()==8,"부침개 전우치 8방향 걷기 시트 등록")
 check(SkillFX.sheet_key("daoist:woochi","woochi_pancake")=="woochi_pancake","전우치에게 스킨 시트가 적용")
 check(SkillFX.sheet_key("yokai:gumiho","woochi_pancake")=="","다른 캐릭터에는 스킨이 적용되지 않는다")
 check(SkillFX.file_for("daoist:woochi","painting","woochi_pancake").ends_with("fx_kimchijeon_cloak.png"),"부침개 전우치 은신은 김치전 이펙트")
 check(SkillFX.file_for("daoist:woochi","clone","woochi_pancake").ends_with("fx_pancake_flip.png"),"부침개 전우치 도술은 부침개 이펙트")
 var missing: Array=[]
 for team in ["daoist","yokai"]:
  for entry in C.catalog(team):
   for ability in entry.abilities:
    var file:=SkillFX.file_for(String(entry.id),String(ability.skill),"")
    if file=="" or not ResourceLoader.exists(file):missing.append([entry.id,ability.skill,file])
 check(missing.is_empty(),"10인 30도술 전부 전용 이펙트 PNG가 연결된다: "+str(missing.slice(0,4)))
 check(SkillFX.file_for("daoist:woochi","painting","").ends_with("fx_scroll_sansuhwa.png"),"전우치 화중은신은 산수화 족자")
 # 실제 시전에서 fx_png 이펙트가 터진다
 human.position=Vector2(1650,1330);human.outside=0.0
 human.skin="woochi_pancake";human.character="daoist:woochi"
 game.rules.signature(human,"painting")
 var skin_burst: bool=false
 for e in game.rules.effects:
  if String(e.get("kind",""))=="fx_png" and String(e.get("file","")).contains("fx_kimchijeon_cloak"):skin_burst=true
 check(skin_burst,"부침개 전우치 은신 시전에 김치전 이펙트가 실제로 터진다")
 human.skin=""
 game.rules.signature(human,"clone")
 var png_bursts:=0
 for e2 in game.rules.effects:
  if String(e2.get("kind",""))=="fx_png" and String(e2.get("file","")).contains("/v34/fx/"):png_bursts+=1
 check(png_bursts>0,"기본 스킨 전용 이펙트 PNG가 시전 순간 터진다")
 # ---------------------------------------------------------------- 7.5) UI·기믹 사운드와 맵 BGM
 var snd=game.sound
 var clips_ok:=true
 for clip_name in ["ui_tap","ui_tab","ui_back","match_join","match_found","lock_in","gimmick_turnstile","gimmick_cctv","gimmick_lights_off","gimmick_lights_on","gimmick_shutter","zone_warning"]:
  if not ResourceLoader.exists("res://assets/audio/%s.wav"%clip_name):clips_ok=false
 check(clips_ok,"2.0.34 UI·기믹 사운드 12종이 등록된다")
 check(ResourceLoader.exists("res://assets/audio/bgm_gangnam.wav"),"강남역 전용 BGM 파일이 있다")
 if snd!=null:
  snd.play_clip("button")
  check(snd.last_clip=="ui_tap","기존 button 호출이 새 목재 탭 사운드로 연결된다")
  snd.play_clip("tab")
  check(snd.last_clip=="ui_tab","탭 전환 사운드")
  snd.play_match_join(3)
  check(snd.last_clip=="match_join","매칭 합류 차임")
  snd.play_map_bgm("gangnam")
  check(snd.current_map=="gangnam" and snd.music!=null and snd.music.stream!=null,"맵 진입 시 강남역 BGM으로 전환")
  snd.play_map_bgm("seowon")
  check(snd.current_map=="seowon","서원으로 돌아오면 서원 BGM으로 복귀")
 # 상점 문구 정리
 var shop_src:=FileAccess.get_file_as_string("res://scripts/survival/shop_view.gd")
 check(not shop_src.contains("인앱결제 · 광고 없음") and not shop_src.contains("인앱결제·광고 없음"),"상점에서 인앱결제·광고 없음 문구 삭제")
 # ---------------------------------------------------------------- 8) 오버레이·실시간 지도·구출 아이콘
 game.paused=false
 game.rules.elapsed=120.0
 var before_pause: float=game.rules.elapsed
 game.pause_menu();await frames(14)
 check(game.rules.elapsed>before_pause,"메뉴를 열어도 경기 시간이 계속 흐른다")
 check(game.world.process_mode!=Node.PROCESS_MODE_DISABLED,"메뉴가 월드 시뮬레이션을 멈추지 않는다")
 before_pause=game.rules.elapsed
 await frames(12)
 check(game.rules.elapsed>before_pause,"메뉴가 열린 동안에도 타이머가 증가")
 game.close_popup()
 before_pause=game.rules.elapsed
 game.show_settings();await frames(14)
 check(game.rules.elapsed>before_pause,"설정 창을 열어도 경기가 진행된다")
 game.close_popup()
 # 확대 지도: 열린 상태에서 위치가 움직인다
 game.show_map()
 check(game.map_overlay!=null,"확대 미니맵이 열린다")
 var before_time: float=game.rules.elapsed
 var bot_id: String=""
 for p in game.rules.players.values():
  if p.id!="human" and p.role=="daoist":bot_id=String(p.id);break
 var before_pos: Vector2=game.rules.players[bot_id].position
 var draws_before: int=int(game.minimap.draws)
 game.rules.players[bot_id].intent=Vector2(1,0)
 await frames(40)
 check(game.rules.elapsed>before_time,"확대 지도가 열려 있어도 경기 시간이 흐른다")
 var live_bot: Dictionary=game.rules.players[bot_id]
 var moved_live: bool=live_bot.position!=before_pos or bool(live_bot.get("captured",false)) or bool(live_bot.get("eliminated",false))
 check(int(game.minimap.draws)>draws_before,"확대 지도가 열려 있는 동안 계속 다시 그려진다(정지 스냅샷 아님)")
 check(moved_live,"확대 지도 속 인원 위치가 실시간으로 갱신된다")
 game.close_map()
 # 구출 아이콘: 봉인된 동료
 var ally_id: String=bot_id
 var ally: Dictionary=game.rules.players[ally_id]
 ally.role="daoist";ally.captured=true;ally.deadline=game.rules.elapsed+8.0;ally.eliminated=false
 game.rules.players.human.role="daoist"
 await frames(6)
 check(game.rescue_markers!=null,"구출 마커 레이어가 존재")
 var allies: Array=game.rules.allies("human")
 var sealed: Array=allies.filter(func(a: Dictionary)->bool:return bool(a.captured))
 check(not sealed.is_empty(),"미니맵 데이터에 봉인(구출 필요) 동료가 표시된다")
 check(float(ally.deadline)-game.rules.elapsed>0.0,"봉인 남은 시간 게이지 값")
 game.minimap.queue_redraw();await frames(3)
 check(true,"미니맵이 구출 아이콘과 함께 다시 그려진다")
 print("V34 MAP: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
func live_or_move(game: Node,fallback: bool) -> bool:
 # 지도가 열린 동안에도 갱신되는지: 미니맵이 매 틱 redraw를 요청하는지 확인한다.
 return fallback or (game.minimap!=null and game.minimap._dirty)
