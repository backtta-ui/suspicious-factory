extends SceneTree
const Session=preload("res://scripts/practice/session.gd")
const C=preload("res://scripts/practice/catalog.gd")
const Appearance=preload("res://scripts/wardrobe/catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error(label)
func advance(s: WooPracticeSession,seconds: float) -> void:
 for i in range(ceili(seconds/.05)):s.tick(.05,Vector2.ZERO)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var look:=Appearance.DEFAULT.duplicate();look.character="yeonhwa";look.hair="silver";look.hat="hood";look.color="purple"
 var s:=Session.new(look)
 for prop in preload("res://scripts/practice/layout.gd").PROPS:check(not s.rules.arena.can_stand(prop[1]),"shared movement collision includes solid practice "+prop[0]+str(prop[1]))
 check(C.all().size()==14,"registered eight common + five role skills + adventure talisman, jar alias only")
 for id in C.all():check(s.select(id) and s.selected==id,"select actual registered skill "+id)
 s.reset();s.npc_mode="idle";s.select("transform")
 var jar: Dictionary=s.rules.arena.find_asset("practice_jar");s.self_player().position=jar.origin+Vector2(22,0)
 check(s.interact(),"real extract channel accepts nearby jar")
 advance(s,2)
 check(s.self_player().forms.has("jar") and s.self_player().selected_form=="jar" and s.message.contains("추출 완료"),"extraction completion stores temporary actual form and gives usable feedback")
 check(s.cast() and s.rules.view("student").actors.any(func(p: Dictionary)->bool:return p.uid=="student" and p.form=="asset:jar"),"same server transform rule yields real jar form")
 s.release();check(not s.self_player().buff.has("transform"),"explicit human restoration")
 for kind in ["cat","dog","chicken","crate","basket","lantern","straw","door","dummy"]:
  s.reset();s.npc_mode="idle";s.select("transform");var a: Dictionary=s.rules.arena.find_asset("practice_"+kind);s.self_player().position=a.origin+Vector2(22,0);s.interact();advance(s,2)
  check(s.self_player().forms.has(kind) and s.cast(),"actual asset/animal extraction and transform "+kind)
 s.reset();s.npc_mode="idle";s.select("blink");s.self_player().position=Vector2(920,410);s.self_player().facing=0
 check(s.cast() and s.self_player().position.x<942,"blink uses shared swept collision and cannot cross wooden wall")
 s.select("shadow");s.self_player().position=Vector2(920,410);check(s.cast() and s.self_player().position.x<942,"shadow movement also blocked by same wall")
 s.reset();s.npc_mode="idle";s.select("clone");check(s.cast(),"real clone effect created");var clone_start: Vector2=s.rules.effects[0].position;advance(s,.6)
 check(s.rules.effects[0].position.distance_to(clone_start)>5 and s.rules.effects[0].cosmetic==look,"clone really moves with original appearance")
 advance(s,8);check(s.rules.effects.is_empty(),"clone expires and is removed")
 s.reset();s.select("track");advance(s,1.5);check(s.cast() and not s.rules.view("student").footprints.is_empty(),"tracks reveal NPC actual movement footprints")
 s.reset();s.npc_mode="attack";s.select("shield");s.self_player().position=Vector2(740,740);s.rules.players.yokai.position=Vector2(775,740);advance(s,.6);check(s.cast(),"shield activates shared protection rule")
 var before:=s.hp;advance(s,2.0);check(s.blocks>0 and s.hp==before,"training attack really consumes shield and prevents HP loss")
 advance(s,4);check(s.hp<before,"unshielded training attack decreases temporary HP")
 s.reset();s.npc_mode="idle";s.self_player().position=Vector2(600,640);s.rules.players.blue.position=Vector2(600,480);s.select("smoke");check(s.rules.can_observe("student","blue") and s.cast() and not s.rules.can_observe("student","blue"),"smoke blocks actual shared observation query")
 advance(s,6.2);check(s.rules.can_observe("student","blue"),"smoke expiration restores observation")
 s.select("darkness");check(s.cast() and not s.rules.can_observe("student","blue"),"darkness actually obscures vision")
 s.select("mimic");s.rules.players.blue.position=s.self_player().position+Vector2(30,0);check(s.cast(),"intrinsic mimic accepts nearby training daoist")
 var shown: Dictionary=s.rules.view("student").actors.filter(func(p: Dictionary)->bool:return p.uid=="student")[0]
 check(shown.uid=="student" and shown.cosmetic==s.rules.players.blue.cosmetic and shown.color==s.rules.players.blue.color,"mimic copies complete appearance/color but not player ID")
 s.release();shown=s.rules.view("student").actors.filter(func(p: Dictionary)->bool:return p.uid=="student")[0];check(shown.cosmetic==look,"mimic restoration preserves original customized outfit")
 s.select("capture");s.self_player().position=s.rules.players.blue.position+Vector2(20,0);check(s.cast() and s.rules.players.blue.captured,"actual capture sends training target to jail")
 s.select("rescue");s.self_player().position=s.rules.players.rescuee.position-Vector2(30,0);check(s.cast() and s.interact(),"rescue skill and actual channel begin")
 advance(s,1.4);check(not s.rules.players.rescuee.captured,"accelerated real rescue channel frees prisoner")
 s.select("fake_flame");check(s.cast() and s.rules.effects[0].kind=="fake_flame","real fake-soul effect created")
 s.select("mask");check(s.cast() and s.rules.view("student").actors.filter(func(p: Dictionary)->bool:return p.uid=="student")[0].concealed,"identity concealment flag applied")
 s.select("talisman");s.self_player().position=Vector2(600,650);s.self_player().facing=0;s.rules.players.red.position=Vector2(650,650);s.rules.players.red.captured=false;var hp: int=s.stats.red.hp
 check(s.cast() and s.stats.red.hp<hp and s.stats.red.stun>s.rules.elapsed,"shared combat cone/damage/seal actually hit training NPC")
 s.select("blink");check(s.rules.effects.is_empty() and not s.self_player().buff.has("mask") and s.rules.channels.is_empty(),"skill switch clears prior effects, channels, disguise")
 s.reset();s.select("talisman");s.npc_mode="guard";s.self_player().position=Vector2(600,650);s.self_player().facing=0;s.rules.players.red.position=Vector2(650,650);advance(s,.1);var guarded_hp: int=s.stats.red.hp;s.cast();check(s.stats.red.hp==guarded_hp and s.defenses>0,"training NPC really blocks an attack using shared shield consumption")
 s.reset();check(s.hp==100 and s.rules.effects.is_empty() and s.self_player().forms.is_empty(),"reset clears only isolated session state")
 var secure:=preload("res://scripts/seal/rules.gd").new("111111",5);secure.add("u","이용자",[]);secure.phase="roam";secure.players.u.role="daoist"
 check(secure.command("u",{"op":"cast","skill":"shield"}).has("error"),"production rules still reject unowned and unequipped skill")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.player.position=game.Layout.safe_position(preload("res://scripts/practice/layout.gd").DOOR);game.player.cosmetic=look.duplicate();game.player.facing=3;game.camera.zoom=Vector2(2.1,2.1);await frames()
 check(game.near_practice and game.interact_button.visible and game.interact_button.text=="도술 익히기 입장","walk-up entrance uses actual plaza interaction button")
 var position: Vector2=game.player.position;var facing: int=game.player.facing;var zoom: Vector2=game.camera.zoom;var rpg: Dictionary=game.rpg.data.duplicate(true);var wardrobe: Dictionary=game.wardrobe.data.duplicate(true)
 game.interact();await frames();check(game.screen_name=="practice" and is_instance_valid(game.practice) and not is_instance_valid(game.seal_client),"plaza opens real offline map with no server object")
 var room: WooPracticeUI=game.practice
 var disk_before: Dictionary=game.Save.load_game().rpg.duplicate(true)
 var identity_path: String=preload("res://scripts/seal/identity.gd").PATH
 var online:=FileAccess.open(identity_path,FileAccess.WRITE);online.store_string("online-rights-and-wins-sentinel");online.close();var online_hash:=FileAccess.get_sha256(identity_path)
 game._process(12.0);game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);await frames()
 check(room.backgrounded and room.stick.finger==-1,"background suspends local session and releases touch")
 game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);await frames()
 check(game.Save.load_game().rpg==disk_before and FileAccess.get_sha256(identity_path)==online_hash,"autosave/background cannot write training progress or online identity/rights file")
 check(room.hero.cosmetic==look and room.world!=game.world,"separate practice world shares actual customized actor")
 room.stick.vector=Vector2.RIGHT;var p: Vector2=room.hero.position;await create_timer(.3).timeout;check(room.hero.position.distance_to(p)>8,"real frame-time movement works in training")
 room.show_spells();await frames();check(game.modal_kind=="practice_spells","real scrollable skill selection opens")
 room.select("clone");room.cast();await frames();check(not room.clones.is_empty(),"actual clone actor appears in scene")
 room.select("mimic");room.session.self_player().position=room.session.rules.players.blue.position+Vector2(25,0);room.cast();await frames();check(room.hero.cosmetic==room.session.rules.players.blue.cosmetic and room.markers.student.color_id==room.session.rules.players.blue.color,"actual mimic renderer copies outfit and identity marker color")
 game.go_back();await frames();check(game.screen_name=="playing" and game.player.position.is_equal_approx(position) and game.player.facing==facing and game.camera.zoom==zoom,"back restores exact plaza node, location, direction and camera zoom")
 check(game.rpg.data==rpg and game.wardrobe.data==wardrobe and game.player.cosmetic==look,"no RPG progress, unlock, inventory, wardrobe or wins changed")
 game.adventure.show_spells();await frames();game.enter_practice("shield");await frames();check(game.practice.session.selected=="shield","codex routes to same offline room with selected skill")
 game.practice.leave();await frames()
 game.save_progress();var legacy: Dictionary=game.Save.load_game();var progress: Dictionary=legacy.rpg.duplicate(true);legacy.map_revision=3;var entrance: Vector2=preload("res://scripts/practice/layout.gd").ENTRANCE;legacy.position=[entrance.x,entrance.y]
 var file:=FileAccess.open(game.Save.PATH,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
 var migrated: Dictionary=game.Save.load_game()
 check(not migrated.is_empty() and migrated.rpg==progress and migrated.map_revision==4 and game.Layout.can_stand(Vector2(migrated.position[0],migrated.position[1])),"old revision3 save under new entrance migrates safely without losing RPG progress")
 game.show_menu(false);game.queue_free();await frames()
 print("OFFLINE PRACTICE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
