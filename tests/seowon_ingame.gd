extends SceneTree
## 2단계-B 검증: 1.75x 시점·대형 한옥 3채 다중 출입·지붕 크로스페이드·실내 안개·
## 8인 2.5D 캐릭터 8방향 매핑·점프 방향 유지·로비 BGM.
const Rules=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
const L=preload("res://scripts/survival/layout.gd")
const App=preload("res://scenes/survival.tscn")
const Actor=preload("res://scripts/woo/actor.gd")
const Looks=preload("res://scripts/wardrobe/catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n: int=5) -> void:
 for i in range(n):await process_frame
func live_room(count: int=8,seed_value: int=17) -> RefCounted:
 var r:=Rules.new(seed_value)
 for i in range(count):r.add("human" if i==0 else "bot-%d"%i,"참가자%d"%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[i%4].id)
 for p in r.players.values():p.ready=true
 r.start()
 for i in range(300):
  if r.phase!="selection":break
  r.tick(.1)
 r.ready_map()
 for i in range(31):r.tick(.1)
 return r
func _initialize() -> void:run.call_deferred()
func run() -> void:
 # 1) 지도: 세 채의 출입 한옥·앞뒤 문·연못·아치 목교
 check(L.buildings().size()==3,"three enterable hanok")
 var front_ok:=true;var back_ok:=true;var interior_ok:=true;var distinct:=true
 var names: Array=[]
 for building in L.buildings():
  var front: Vector2=(building.doors as Dictionary).front
  var back: Vector2=(building.doors as Dictionary).back
  front_ok=front_ok and L.can_stand(front+Vector2(0,14)) and L.can_stand(front+Vector2(0,-22))
  back_ok=back_ok and L.can_stand(back+Vector2(0,-14)) and L.can_stand(back+Vector2(0,22))
  interior_ok=interior_ok and L.inside((building.interior as Rect2).get_center()) and L.can_stand((building.interior as Rect2).get_center())
  names.append(String(building.id))
 check(front_ok,"front door of every hanok walkable from the courtyard")
 check(back_ok,"back door of every hanok walkable from behind")
 check(interior_ok,"room floor of every hanok walkable")
 check(names.size()==3 and not (names[0]==names[1] or names[1]==names[2] or names[0]==names[2]),"each hanok has its own interior")
 var wide:=true
 for building in L.buildings():
  wide=wide and (building.rect as Rect2).size.x>=450 and (building.rect as Rect2).size.y>=380
 check(wide,"every hanok keeps the enlarged size")
 var solid:=true
 for building in L.buildings():
  var rect: Rect2=building.rect
  var probe: Vector2=rect.position+Vector2(8,rect.size.y*.55)
  solid=solid and not L.can_stand(probe,9,true)
 check(solid,"hanok walls still block even while jumping")
 var bridge_mid: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,.5)
 check(L.on_bridge(bridge_mid) and L.elevation(bridge_mid)>20,"arched bridge carries elevation")
 check(L.can_stand(bridge_mid) and not L.can_stand(L.POND.get_center(),9,true),"bridge crossable, pond not")
 check(L.move(L.BRIDGE_A,L.BRIDGE_B).distance_to(L.BRIDGE_B)<2,"walk the bridge end to end")
 check(L.WALLS.size()>=8 and L.BAMBOO.size()>=5,"tiled walls and bamboo groves divide the map")
 var five: Array=[]
 for object in L.OBJECTS:
  if not five.has(object.kind):five.append(object.kind)
 check(five.size()==5 and L.OBJECTS.size()>=15,"five disguisable prop kinds in dense clusters")
 # 2) 규칙: 문 ID가 건물별로 열리고 둔갑·봉인이 그대로 동작
 var r:=live_room()
 var human: Dictionary=r.players.human
 var first_door:=String((L.DOORS[0] as Dictionary).id)
 human.position=L.door(first_door).center+Vector2(0,26)
 check(r.command("human","interact") and r.doors.get(first_door,0.0)>r.elapsed,"front door opens by interaction")
 check(r.events.any(func(e: Dictionary)->bool:return e.kind=="door"),"door event for sound")
 # 시작 스폰과 겹치지 않는 동쪽 항아리에서 둔갑·근접 봉인을 확인한다.
 var jar_point: Vector2=Vector2(1430,556)
 human.position=jar_point;human.facing=2;human.cd.erase("transform")
 check(r.command("human","interact") and human.form=="jar","jar disguise still works")
 check(L.door_near(jar_point,70)=="","no door reported far from a hanok")
 var evil: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 evil.position=jar_point+Vector2(-18,0);evil.facing=0;evil.cd.erase("seal");human.form=""
 check(r.command(evil.id,"seal") and human.captured,"close seal still works")
 # 3) 앱: 1.75x 카메라·문 앞 상호작용·지붕 크로스페이드·실내 안개
 root.size=Vector2i(1280,720);var game:=App.instantiate();root.add_child(game);await frames(8)
 game.create_room("QA 술래잡기",8,true);await create_timer(.4).timeout
 for p in game.rules.players.values():p.ready=true
 game.rules.start()
 var index:=0
 for p in game.rules.players.values():
  if p.id=="human":p.role="daoist";p.character="daoist:woochi";continue
  index+=1
  if p.role=="":p.role="yokai" if index<3 else "daoist"
  p.character=("yokai:gumiho" if p.role=="yokai" else "daoist:yeonhwa")
 game.selection_id="daoist:woochi";game.selection_team="daoist";game.build("selection");game.rules.phase="loading"
 for i in range(400):
  await process_frame
  if game.screen=="match" and not game.changing:break
 game.rules.phase="live";game.rules.elapsed=2.0
 check(game.screen=="match" and is_instance_valid(game.camera),"match world with camera")
 check(is_instance_valid(game.camera) and is_equal_approx(game.camera.zoom.x,L.CAMERA_ZOOM) and L.CAMERA_ZOOM>=1.2 and L.CAMERA_ZOOM<1.55,"camera zoom 1.32 widens the 2.5D view without shrinking the actor")
 var hall: Dictionary=L.buildings()[0]
 var front: Vector2=(hall.doors as Dictionary).front
 var me: Dictionary=game.rules.players.human
 me.position=front+Vector2(0,16);me.facing=6
 game.update_avatars();game.update_hud();await frames(3)
 check(game.camera.position.distance_to(me.position+Vector2(0,-L.CAMERA_LIFT))<1.5,"camera follows the player with the 36px lift")
 check(game.action_button.get_node("Caption").text=="문 열기","door context label at the enlarged hanok")
 check(game.ui.find_children("*","Button",true,false).size()>=6,"HUD buttons present")
 check(game.world.buildings.size()==3,"world draws three hanok")
 for building in game.world.buildings:
  check((building.data.rect as Rect2).size.x>=450,"world hanok uses the enlarged rect")
  var painted: Vector2=L.painted_door(String(building.data.id))
  var door_anchor: Vector2=(building.data.doors as Dictionary).front
  check(is_instance_valid(building.exterior) and (building.exterior as Sprite2D).scale.x>0,"exterior sprite for "+String(building.data.id))
  check(painted.y<door_anchor.y and painted.x<door_anchor.x,"painted door sits above the stairs foot")
 for i in range(24):
  me.position=front+Vector2(0,16);game.update_avatars();await process_frame
 var outside_alpha: float=game.world.buildings[0].alpha
 check(outside_alpha>.8 and (game.world.buildings[0].exterior as Sprite2D).modulate.a>.7,"exterior closed while outside")
 for i in range(30):
  me.position=(hall.interior as Rect2).get_center();game.update_avatars();await process_frame
 var building: Dictionary=game.world.buildings[0]
 check(building.alpha<.2,"roof crossfade opens the hall when inside")
 check((building.exterior as Sprite2D).modulate.a<.25,"exterior fades out inside")
 check((building.interior as Sprite2D).modulate.a>.6 and (building.interior as Sprite2D).visible,"interior is shown inside")
 check((building.fog as Node2D).visible and (building.fog as Node2D).modulate.a>.6,"outside is blocked by night fog inside")
 check(game.world.buildings[1].alpha>.8,"other hanok keep their roofs")
 me.position=front+Vector2(0,16)
 for i in range(30):game.update_avatars();await process_frame
 check(game.world.buildings[0].alpha>.8 and not (game.world.buildings[0].fog as Node2D).visible,"roof closes again when leaving")
 game.show_settings();await frames(2)
 check(game.modal!=null and game.modal.find_children("*","CheckBox",true,false).size()>=3,"settings with mute and vibration")
 check(game.modal.find_children("*","HSlider",true,false).size()>=3,"settings include volume and control sensitivity")
 game.close_popup()
 # 4) 8인 2.5D 캐릭터: 8방향 매핑·점프 방향 유지·8명 전원 원화
 for id in ["woochi","yeonhwa","muyeong","hongryeon","gumiho","jangsanbeom","dokkaebi","haechi"]:
  for direction in ["front","back","left","right"]:
   var path: String="res://assets/woo/ingame/%s-%s.png" % [id,direction]
   check(ResourceLoader.exists(path),"ingame art %s %s" % [id,direction])
 var actor:=Actor.new();actor.cosmetic=Looks.base_appearance("woochi");root.add_child(actor);actor.set_physics_process(false)
 actor.ingame_art=true;actor.art_id="woochi";actor.update_sprite()
 var mapping:=[[2,"front",false],[1,"front",true],[3,"front",false],[6,"back",false],[5,"back",false],[7,"back",true],[0,"right",false],[4,"left",false]]
 var mapped:=true;var flipped:=true
 for entry in mapping:
  actor.facing=int(entry[0]);actor.ingame_sprite._process(.016)
  mapped=mapped and actor.ingame_sprite.current_key==String("woochi:"+String(entry[1]))
  flipped=flipped and actor.ingame_sprite.sprite.flip_h==bool(entry[2])
 check(mapped,"south/diagonal use front, north uses back, east-west use side")
 check(flipped,"diagonal and east/west views flip with the movement direction")
 # 뒤돌아(북) 점프: 뒷모습 유지
 actor.facing=6;actor.jump_height=22;actor.jump_velocity=120;actor.update_sprite();actor.ingame_sprite._process(.016)
 check(actor.ingame_sprite.current_key=="woochi:back" and not actor.ingame_sprite.sprite.flip_h,"back view kept while jumping north")
 # 북서 대각선 점프: 뒷모습 + 반전 유지
 actor.facing=5;actor.jump_height=30;actor.update_sprite();actor.ingame_sprite._process(.016)
 check(actor.ingame_sprite.current_key=="woochi:back" and not actor.ingame_sprite.sprite.flip_h,"north-west diagonal jump keeps the back view")
 check(actor.ingame_sprite.sprite.position.y<-20,"jump height lifts the sprite")
 check(actor.ingame_sprite.sprite.scale.x>0,"squash and stretch keep a positive scale")
 actor.jump_height=0;actor.jump_velocity=0;actor.update_sprite();actor.ingame_sprite._process(.016)
 check(actor.ingame_sprite.landing>0,"landing squash is triggered on touchdown")
 actor.queue_free();await process_frame
 # 5) 사운드: 로비는 자체 합성 BGM, 경기는 인게임 BGM
 check(ResourceLoader.exists("res://assets/audio/lobby_night.wav"),"self-made lobby bgm file")
 var sound: WooSound=game.sound
 check(sound.context=="match" and sound.music.stream==sound.ingame,"tense Korean BGM in match")
 game.cleanup_match();game.room={};game.build("lobby");await frames(4)
 check(sound.context=="menu" and sound.music.stream==sound.lobby,"self-made lobby bgm plays in the lobby")
 game.queue_free();await frames(6)
 print("SEOWON INGAME: ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
