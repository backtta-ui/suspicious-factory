extends SceneTree
## 캐릭터 안내(도감): roster data plus the real touch path from the lobby.
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
 var event:=InputEventScreenTouch.new();event.index=finger;event.pressed=true;event.position=position;Input.parse_input_event(event)
 await frames(2)
 event=InputEventScreenTouch.new();event.index=finger;event.pressed=false;event.position=position;Input.parse_input_event(event)
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
 check(roster.size()==8,"eight characters in the roster")
 check(C.catalog("daoist").size()==4 and C.catalog("yokai").size()==4,"four daoists and four yokai")
 var names: Array=[]
 for entry in roster:
  names.append(entry.name)
  check(entry.abilities.size()==3,"three abilities for "+entry.name)
  check(C.SKILLS.has(entry.active) and not C.find(entry.id).is_empty(),"active skill key stays valid for "+entry.name)
  check(not "임시" in String(entry.name) and not "미확정" in String(entry.description),"no placeholder text on "+entry.name)
  check(ResourceLoader.exists(entry.sprite) and ResourceLoader.exists(entry.portrait),"dedicated art exists for "+entry.name)
 check(names.size()==8 and names.has("전우치") and names.has("연화") and names.has("무영") and names.has("홍련") and names.has("구미호") and names.has("장산범") and names.has("도깨비") and names.has("해치"),"the approved eight names")
 var actives: Array=[]
 for entry in roster:
  if not actives.has(entry.active):actives.append(entry.active)
 check(actives.size()==8,"all eight gameplay skills are kept")
 check(C.find("daoist:woochi").role=="교란·도주" and C.find("yokai:haechi").intro.contains("숨은 도사"),"role tag and one-line intro carried by the data")
 check(C.look("yokai:gumiho").has("character") and C.look("daoist:yeonhwa").has("character"),"look() still returns a wardrobe appearance")
 # --- real touch path ---------------------------------------------------
 root.size=Vector2i(1280,720)
 var game:=App.instantiate();root.add_child(game);await frames(10)
 game.build("lobby");await frames(6)
 await tap(game.lobby_hotspots["characters"].get_global_rect().get_center())
 await create_timer(.5).timeout
 check(game.screen=="characters","lobby 캐릭터 button opens the character guide")
 var codex:=codex_of(game)
 check(codex!=null,"character guide node is built")
 if codex==null:
  print("CODEX CHECK: ",checks," / ",failures);quit(1);return
 await frames(6)
 check(codex.cards.size()==8 and codex.selected.get("name")=="전우치","whole roster shown with 전우치 selected")
 check(named(game.ui,"CodexTab_all")!=null and named(game.ui,"CodexTab_daoist")!=null and named(game.ui,"CodexTab_yokai")!=null,"three role tabs are real buttons")
 await tap(named(game.ui,"CodexCard_muyeong").get_global_rect().get_center())
 check(codex.selected.get("name")=="무영" and codex.detail_name.text=="무영","card touch swaps the detail panel")
 check(codex.stand.texture.resource_path.ends_with("muyeong-full.png"),"standing figure follows the selected card")
 await tap(named(game.ui,"CodexAbility_1").get_global_rect().get_center())
 check(codex.tip.visible and codex.tip_body.text!="","ability row reveals cooldown and description")
 await tap(named(game.ui,"CodexTab_yokai").get_global_rect().get_center())
 await frames(4)
 check(codex.filter=="yokai" and codex.cards.size()==4,"yokai tab filters the grid to four yokai")
 check(codex.selected.get("team","")=="yokai" and codex.selected.get("name")=="구미호","filtering auto-selects the first yokai")
 await tap(named(game.ui,"CodexCard_haechi").get_global_rect().get_center())
 check(codex.selected.get("name")=="해치","filtered card touch selects 해치")
 await tap(named(game.ui,"CodexTab_daoist").get_global_rect().get_center())
 await frames(4)
 check(codex.selected.get("name")=="전우치" and codex.cards.size()==4,"daoist tab filters and selects 전우치")
 await tap(named(game.ui,"CodexTab_all").get_global_rect().get_center())
 await frames(4)
 check(codex.cards.size()==8,"전체 tab restores all eight cards")
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(2400,1080)]:
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
 check(named(game.ui,"CodexCard_woochi")!=null and named(game.ui,"CodexBack")!=null,"no select/save/dress-up buttons, only guide controls")
 var forbidden: Array=["선택하기","저장","꾸미기","입히기"]
 var found:=false
 for button in game.ui.find_children("*","Button",true,false):
  for word in forbidden:
   if word in button.text:found=true
 check(not found,"guide never offers select, save or dress-up")
 await tap(named(game.ui,"CodexBack").get_global_rect().get_center())
 await create_timer(.6).timeout
 check(game.screen=="lobby","back arrow really returns to the lobby")
 print("CHARACTER CODEX: ",checks," checks / ",failures," failures")
 game.queue_free();await frames(2)
 quit(1 if failures else 0)
