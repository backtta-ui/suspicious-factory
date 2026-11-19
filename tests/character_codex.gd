extends SceneTree
## 통합 도감(2.0.27): 10인 로스터 데이터 + 로비에서 실제 터치 경로.
## 캐릭터 단독 화면은 없어졌고, 로비의 캐릭터·도감 두 자리 모두 이 도감으로 들어간다.
## 도감은 캐릭터 정보·스킬 3종에 더해 도포 스킨 장착까지 한 화면에서 처리한다.
const App=preload("res://scenes/survival.tscn")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("CODEX ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func tap(position: Vector2,finger: int=81) -> void:
 var at: Vector2=root.get_screen_transform()*position
 var event:=InputEventScreenTouch.new();event.index=finger;event.pressed=true;event.position=at;Input.parse_input_event(event)
 await frames(2)
 event=InputEventScreenTouch.new();event.index=finger;event.pressed=false;event.position=at;Input.parse_input_event(event)
 await create_timer(.45).timeout
func named(node: Node,value: String) -> Button:
 for child in node.find_children("*","Button",true,false):
  if child.name==value:return child
 return null
func codex_of(game: Node) -> Node:
 for node in game.ui.get_children():
  if node.get_script()!=null and String(node.get_script().resource_path).ends_with("codex.gd"):return node
 return null
func run() -> void:
 # --- roster data -------------------------------------------------------
 var roster: Array=C.roster()
 check(roster.size()==10,"ten characters in the roster")
 check(C.catalog("daoist").size()==5 and C.catalog("yokai").size()==5,"five daoists and five yokai")
 var names: Array=[]
 for entry in roster:
  names.append(entry.name)
  check(entry.abilities.size()==3,"three abilities for "+entry.name)
  var slots: Array=[]
  for ability in entry.abilities:slots.append(String(ability.slot))
  check(slots==["main","sub","ult"],"main/sub/ult slots for "+entry.name)
  check(C.SKILLS.has(entry.active) and not C.find(entry.id).is_empty(),"active skill key stays valid for "+entry.name)
  check(not "임시" in String(entry.name) and not "미확정" in String(entry.description),"no placeholder text on "+entry.name)
  check(ResourceLoader.exists(entry.sprite) and ResourceLoader.exists(entry.portrait),"dedicated art exists for "+entry.name)
  check(not C.walk_sheet(String(entry.art)).is_empty(),"walk sheet exists for "+entry.name)
 for wanted in ["전우치","홍길동","장영실","바리공주","강림도령","구미호","장산범","도깨비","어둑시니","야광귀"]:
  check(names.has(wanted),"approved name "+wanted)
 var skills: Array=[]
 for entry in roster:
  for ability in entry.abilities:
   if not skills.has(String(ability.skill)):skills.append(String(ability.skill))
 check(skills.size()==30,"thirty distinct gameplay skills")
 check(C.find("daoist:woochi").role=="교란·은신" and C.find("yokai:yagwangwi").intro.contains("발자국"),"role tag and one-line intro carried by the data")
 check(C.look("yokai:gumiho").has("character") and C.look("daoist:barigongju").has("character"),"look() still returns a wardrobe appearance for old and new characters")
 # --- real touch path ---------------------------------------------------
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 game.build("lobby");await frames(6)
 await tap(game.lobby_hotspots["characters"].get_global_rect().get_center())
 await create_timer(.5).timeout
 check(game.screen=="characters","lobby 캐릭터 자리 opens the unified guide")
 var codex:=codex_of(game)
 check(codex!=null,"guide node is built")
 if codex==null:
  print("CODEX CHECK: ",checks," / ",failures);quit(1);return
 await frames(6)
 check(codex.filter=="daoist" and codex.cards.size()==5,"캐릭터 자리 opens on the daoist tab")
 check(named(game.ui,"CodexTab_all")!=null and named(game.ui,"CodexTab_daoist")!=null and named(game.ui,"CodexTab_yokai")!=null,"three role tabs are real buttons")
 await tap(named(game.ui,"CodexTab_all").get_global_rect().get_center())
 await frames(4)
 check(codex.cards.size()==10,"전체 tab shows all ten characters")
 await tap(named(game.ui,"CodexCard_honggildong").get_global_rect().get_center())
 await frames(4)
 check(codex.selected.get("name")=="홍길동" and codex.detail_name.text=="홍길동","card touch swaps the detail panel")
 check(codex.stand.texture.resource_path.ends_with("gildong-full.png"),"standing figure uses the v27 art")
 await tap(named(game.ui,"CodexAbility_2").get_global_rect().get_center())
 check(codex.tip.visible and codex.tip_body.text!="","ultimate row reveals cooldown and description")
 check(codex.tip_meta.text.contains("55") or codex.tip_meta.text.contains("초"),"ultimate row shows its cooldown")
 await tap(named(game.ui,"CodexTab_yokai").get_global_rect().get_center())
 await frames(4)
 check(codex.filter=="yokai" and codex.cards.size()==5,"yokai tab filters the grid to five")
 check(codex.selected.get("team","")=="yokai" and codex.selected.get("name")=="구미호","filtering auto-selects the first yokai")
 await tap(named(game.ui,"CodexCard_yagwangwi").get_global_rect().get_center())
 check(codex.selected.get("name")=="야광귀","filtered card touch selects 야광귀")
 # 도감 안에서 도포 스킨을 바로 장착한다(구매는 마켓 전용).
 var skin:=named(game.ui,"CodexSkin_default")
 check(skin!=null and named(game.ui,"CodexSkin_moon")!=null,"guide lists robe skins for equipping")
 await tap(skin.get_global_rect().get_center())
 check(String(game.storage.equipped("skin"))=="default","tapping a robe equips it in the guide")
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(2340,1080)]:
  root.size=size
  await frames(8)
  var view:=game.get_viewport().get_visible_rect()
  var inside:=true
  for id in codex.cards:
   if not view.encloses(codex.cards[id].get_global_rect()):inside=false
  check(inside,"every card stays inside the viewport at "+str(size))
  check(view.encloses(codex.detail.get_global_rect()) and view.encloses(codex.guide.get_global_rect()),"panels stay inside the viewport at "+str(size))
 root.size=Vector2i(1280,720)
 await frames(6)
 check(named(game.ui,"CodexBack")!=null,"guide has a back control")
 var forbidden: Array=["선택하기","저장","꾸미기","입히기","구매"]
 var found:=false
 for button in game.ui.find_children("*","Button",true,false):
  for word in forbidden:
   if word in button.text:found=true
 check(not found,"guide never sells or selects a character")
 await tap(named(game.ui,"CodexBack").get_global_rect().get_center())
 await create_timer(.6).timeout
 check(game.screen=="lobby","back arrow really returns to the lobby")
 # 도감 자리도 같은 화면으로 들어간다.
 await tap(game.lobby_hotspots["codex"].get_global_rect().get_center())
 await create_timer(.6).timeout
 check(game.screen=="characters" and codex_of(game)!=null,"도감 자리 opens the same unified guide")
 var again:=codex_of(game)
 check(again!=null and again.filter=="all","도감 자리 opens on the 전체 tab")
 print("CHARACTER CODEX: ",checks," checks / ",failures," failures")
 game.queue_free();await frames(2)
 quit(1 if failures else 0)
