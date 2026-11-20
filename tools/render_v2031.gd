extends SceneTree
## 2.0.31 인간둔갑 재검증 렌더: '구미호가 도사로 둔갑'하는 방향이 맞는지 두 시점으로 나눠 남긴다.
##  - v2031_mimic_gumiho_self.png : 구미호 본인 화면(전우치 모습 + HUD '인간둔갑 · 전우치 모습')
##  - v2031_mimic_daoist_view.png : 도사(=진짜 전우치) 화면(둔갑한 구미호가 전우치로만 보인다)
##  - v2031_mimic_released.png     : 풀린 뒤 구미호로 돌아온 모습
## 사용: xvfb-run -a godot --path . --script res://tools/render_v2031.gd
const App=preload("res://scenes/survival.tscn")
const L=preload("res://scripts/survival/layout.gd")
const C=preload("res://scripts/survival/characters.gd")
const OUT="/workspace/downloads/"
var game: Node

func _initialize() -> void:
 run.call_deferred()

func frames(n: int=4) -> void:
 for i in range(n):await process_frame

func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(OUT+name)
 print("RENDER SAVED ",OUT+name," ",image.get_size())

func wait_screen(target: String) -> void:
 for i in range(900):
  await process_frame
  if game.screen==target and not game.changing:return
 print("WAIT TIMEOUT ",target," screen ",game.screen)

func clear_states() -> void:
 for p in game.rules.players.values():
  p.buff={};p.immune=0.0;p.stun=0.0;p.blind_until=0.0;p.slow_until=0.0;p.speed_until=0.0
  p.captured=false;p.form="";p.copy="";p.trail=[]
 game.rules.reveal_until=0.0;game.rules.map_dark_until=0.0;game.rules.dark_until=0.0
 game.rules.trail_all_until=0.0;game.rules.lantern_until.clear()
 game.rules.marks.clear();game.rules.pings=[];game.rules.traps=[];game.rules.effects.clear()

func start(role: String) -> void:
 game.cleanup_match()
 game.build("lobby");await frames(4)
 game.preferred_role=role
 game.start_practice_match()
 await wait_screen("match")
 game.rules.phase="live";game.rules.elapsed=120.0
 game.paused=true
 await frames(6)

func role_ids(role: String) -> Array:
 var out: Array=[]
 for p in game.rules.players.values():
  if p.role==role and not p.eliminated:out.append(String(p.id))
 return out

func park(id: String,at: Vector2) -> void:
 var q: Dictionary=game.rules.players[id]
 q.position=L.safe(at);q.ground=q.position;q.character_name=""
func view_of(viewer: String,target: String) -> Dictionary:
 for a in game.rules.visible(viewer):
  if String(a.id)==target:return a
 return {}

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(16)
 game.build("lobby");await frames(6)

 # ================================================================ (1) 구미호 본인 화면
 await start("yokai")
 clear_states()
 var rules=game.rules
 var human: Dictionary=rules.players.human
 var daoists:=role_ids("daoist")
 var yokais:=role_ids("yokai")
 human.character="yokai:gumiho";human.cd={};human.ult=rules.ULT_MAX
 var stage: Vector2=L.MEDALLION+Vector2(0,200)
 human.position=L.safe(stage);human.ground=human.position;human.facing=0
 # 둔갑 대상: 바로 옆에 선 전우치 한 명(다른 도사는 멀리).
 var prey_id:=String(daoists[0])
 for i in range(daoists.size()):
  var q: Dictionary=rules.players[daoists[i]]
  if i==0:
   q.character="daoist:woochi"
   q.position=L.safe(stage+Vector2(-300,-60));q.ground=q.position;q.facing=2
  else:park(daoists[i],Vector2(3060+i*30,2360))
 for id in yokais:
  if String(id)!=String(human.id):park(id,Vector2(3080,2320))
 game.camera.position=stage-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud();await frames(8)
 var prey: Dictionary=rules.players[prey_id]
 print("SELF before: me=",human.character," copy='",human.copy,"' prey=",prey.character," prey.copy='",prey.copy,"'")
 var cast: bool=rules.skill(human,Vector2.RIGHT,"main")
 print("SELF cast=",cast," copy=",human.copy," left=",r1(float(human.buff.get("mimic",0.0))-rules.elapsed))
 # 이펙트가 걷힌 뒤(둔갑 자체는 유지) 화면을 남긴다.
 rules.elapsed+=1.4
 rules.effects.clear()
 game.update_avatars();game.update_hud();await frames(8)
 var self_view: Dictionary=view_of("human","human")
 print("SELF view: role=",self_view.get("role","")," character=",self_view.get("character",""),
  " name=",self_view.get("name","")," mimic=",self_view.get("mimic",false),
  " tag=",game.avatars["human"].get_node("Name").text if game.avatars.has("human") else "-")
 print("SELF badge: ",rules.active_effects("human").filter(func(e: Dictionary)->bool:return String(e.key)=="mimic"))
 print("SELF prey unchanged: character=",prey.character," copy='",prey.copy,"' mimic=",float(prey.buff.get("mimic",0.0))>rules.elapsed)
 await capture("v2031_mimic_gumiho_self.png")
 # 풀린 뒤: 원래 구미호로 돌아온다.
 human.buff.erase("mimic");human.copy=""
 game.update_avatars();game.update_hud();await frames(10)
 print("SELF released: art=",game.avatars["human"].art_id," badge=",rules.active_effects("human").filter(func(e: Dictionary)->bool:return String(e.key)=="mimic"))
 await capture("v2031_mimic_released.png")

 # ================================================================ (2) 도사(전우치) 화면
 await start("daoist")
 clear_states()
 rules=game.rules
 human=rules.players.human
 daoists=role_ids("daoist")
 yokais=role_ids("yokai")
 human.character="daoist:woochi";human.cd={};human.ult=rules.ULT_MAX
 var left_spot: Vector2=L.MEDALLION+Vector2(0,210)
 human.position=L.safe(left_spot);human.ground=human.position;human.facing=0
 var i2:=0
 for id in daoists:
  if String(id)==String(human.id):continue
  var q2: Dictionary=rules.players[id]
  q2.character="daoist:honggildong" if i2%2==0 else "daoist:barigongju"
  park(id,Vector2(3060+i2*60,2380-i2*30));i2+=1
 # 둔갑한 구미호를 진짜 전우치와 조금 떨어뜨려 세운다(나란히 붙여 세워 혼동하지 않게).
 var imp_id:=""
 for id in yokais:
  if imp_id=="":imp_id=String(id);continue
  park(id,Vector2(3120,2320))
 var imp: Dictionary=rules.players[imp_id]
 imp.character="yokai:gumiho";imp.cd={};imp.ult=rules.ULT_MAX
 # 카메라가 나를 따라가므로, 둔갑한 구미호는 내 오른쪽에 확실히 보이게 둔다.
 imp.position=human.position+Vector2(190,-10);imp.ground=imp.position;imp.facing=4
 game.camera.position=human.position-Vector2(0,L.CAMERA_LIFT)
 game.update_avatars();game.update_hud();await frames(8)
 var cast2: bool=rules.skill(imp,Vector2.LEFT,"main")
 print("DAOIST cast=",cast2," impostor copy=",imp.copy," target=",rules.players.get(String(imp.copy),{}).get("name",""))
 rules.elapsed+=1.4
 rules.effects.clear()
 game.update_avatars();game.update_hud();await frames(8)
 var seen: Dictionary=view_of("human",imp_id)
 print("DAOIST sees impostor: role=",seen.get("role","")," character=",seen.get("character",""),
  " name=",seen.get("name","")," color=",seen.get("color",-1)," mimic=",seen.get("mimic",false))
 print("DAOIST real me unchanged: character=",human.character," copy='",human.copy,"' role=",human.role," mimic=",bool(rules.visible("human").filter(func(a: Dictionary)->bool:return String(a.id)=="human" and bool(a.get("mimic",false))).size()))
 print("DAOIST tags: real=",game.avatars["human"].get_node("Name").text," fake=",game.avatars[imp_id].get_node("Name").text if game.avatars.has(imp_id) else "-")
 # 검증용 표시(게임 UI가 아니라 QA 렌더에만 붙는다): 실제 화면 좌표 위에 누가 누구인지 적는다.
 var me_at: Vector2=game.avatars["human"].get_global_transform_with_canvas().origin
 var imp_at: Vector2=game.avatars[imp_id].get_global_transform_with_canvas().origin
 mark(me_at,"진짜 나 · 전우치",Color("9fd0ff"))
 mark(imp_at,"구미호가 인간둔갑",Color("ff9ee0"))
 var caption:=Label.new()
 caption.text="검증용 표시 · 파란 이름표 = 진짜 나(전우치) / 분홍 이름표 = 인간둔갑한 구미호. 게임 화면에는 두 사람이 완전히 똑같이 보인다."
 caption.add_theme_font_size_override("font_size",19)
 caption.add_theme_color_override("font_color",Color("ffe6b0"))
 caption.position=Vector2(24,676);caption.size=Vector2(1510,36)
 var bg:=ColorRect.new();bg.color=Color(0.02,0.03,0.06,0.72);bg.position=Vector2(10,668);bg.size=Vector2(1540,42)
 game.ui.add_child(bg);game.ui.add_child(caption)
 await frames(3)
 print("DAOIST on-screen: me=",me_at," impostor=",imp_at)
 print("DAOIST allies=",rules.allies("human").map(func(a: Dictionary)->String:return String(a.get("id",""))+"/"+String(a.get("role",""))))
 await capture("v2031_mimic_daoist_view.png")
 print("RENDER V2031 DONE")
 quit(0)

## 렌더 검증용 이름표(실제 게임에는 없는 표시).
func mark(at: Vector2,text: String,color: Color) -> void:
 var label:=Label.new()
 label.text=text
 label.add_theme_font_size_override("font_size",19)
 label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_outline_color",Color(.02,.02,.05,.95))
 label.add_theme_constant_override("outline_size",8)
 label.position=at-Vector2(86,150)
 label.size=Vector2(200,26)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 game.ui.add_child(label)

func r1(v: float) -> float:
 return snappedf(v,0.1)
