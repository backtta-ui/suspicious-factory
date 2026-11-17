extends SceneTree
const State=preload("res://scripts/woo/rpg_state.gd")
const Save=preload("res://scripts/woo/save_game.gd")
const Layout=preload("res://scripts/woo/forest_layout.gd")
const Surface=preload("res://scripts/woo/terrain_surface.gd")
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func touch(p: Vector2,pressed: bool,index: int=0) -> void:
 var e:=InputEventScreenTouch.new();e.position=root.get_final_transform()*p;e.pressed=pressed;e.index=index;Input.parse_input_event(e)
func tap(b: Control,index: int=0) -> void:
 if not is_instance_valid(b):check(false,"required touch target exists");return
 var p:=b.get_global_rect().get_center();touch(p,true,index);await frames(2);touch(p,false,index);await frames(4)
func find_button(value: String,node: Node=null) -> Button:
 if node==null:node=game.ui
 if node is Button and node.text==value and node.is_visible_in_tree():return node
 for c in node.get_children():
  var found:=find_button(value,c)
  if found!=null:return found
 return null
func enemies() -> Array:
 return game.adventure.forest.get_children().filter(func(n: Node)->bool:return n is WooGoblin and n.hp>0)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var state:=State.new()
 check(State.valid(state.data),"default RPG save is valid")
 check(state.CAPACITY==30 and state.data.inventory.size()==5,"30 slots and five real starter items")
 check(not state.add_item("fake",1) and not state.add_item("potion",-2),"reject unknown and negative grants")
 check(not state.use_item("potion") and state.count("potion")==3,"full health does not consume potion")
 state.data.hp=20;check(state.use_item("potion") and state.data.hp==65 and state.count("potion")==2,"potion heals and consumes exactly one")
 state.data.mp=1;check(state.use_item("mana_potion") and state.data.mp==31,"mana potion works")
 check(not state.use_item("key") and not state.equip(0,"clone"),"key and unimplemented clone cannot be used")
 check(state.equip(2,"jar") and state.data.slots[1]=="" and state.data.slots[2]=="jar","spell equip moves without duplication")
 state.grant_xp(120);check(state.data.level==2 and state.data.xp==20,"level up retains XP overflow")
 var bad:=state.data.duplicate(true);bad.inventory.potion=-1;check(not State.valid(bad),"negative inventory fails save validation")
 bad=state.data.duplicate(true);bad.inventory["fake"]=1;check(not State.valid(bad),"unknown inventory fails save validation")
 bad=state.data.duplicate(true);bad.slots=["jar","jar",""];check(not State.valid(bad),"duplicate equipped spell fails validation")
 check(Surface.at(Vector2(1080,700))=="stone" and Surface.at(Vector2(2400,1000))=="grass","real plaza surface differs between stone and grass")
 check(Surface.at(Vector2(1810,795))=="stone" and Surface.at(Vector2(1700,1300))=="stone","shop courtyards and actual stone bridge use stone footsteps")
 check(Layout.surface(Vector2(220,790))=="wood" and Layout.surface(Vector2(1100,430))=="water","forest wood and shallow water classifications")
 check(not Layout.can_stand(Vector2(1100,300)) and Layout.can_stand(Vector2(1100,430)),"deep pond blocks, shallow edge walkable")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
 game.start_game(false);await frames()
 var adv: WooAdventure=game.adventure
 check(game.joystick.position.x>=74 and abs(game.joystick.position.y-(game.ui.size.y-222))<1,"joystick inset right30/up12 with size174")
 check(game.joystick.size==Vector2(174,174),"joystick design size preserved")
 var count:int=game.sound.played;game.sound.tracking=false
 game.sound.update_steps(Vector2(1080,700),true,false);game.sound.update_steps(Vector2(1092,700),true,false);game.sound.update_steps(Vector2(1104,700),true,false)
 check(game.sound.last_surface=="stone" and game.sound.played==count+1,"stone surface sample plays on distance cadence")
 game.sound.update_steps(Vector2(2400,1000),true,false);game.sound.update_steps(Vector2(2412,1000),true,false);game.sound.update_steps(Vector2(2424,1000),true,false)
 check(game.sound.last_surface=="grass","grass sample switches at real player foot coordinates")
 check(adv.combat_buttons.all(func(b: Button)->bool:return not b.visible),"plaza combat controls hidden")
 adv.basic_attack();check(adv.attack_cd==0,"plaza rejects basic attack in gameplay code")
 var original: Vector2=game.player.position;var facing:int=game.player.facing
 game.show_painting_intro(1);await frames();check(not find_button("그림 속으로").disabled,"new palace exploration is genuinely open");game.close_modal()
 game.player.position=Vector2(1690,395);original=game.player.position;game.player.facing=3;facing=3
 game.show_painting_intro(0);await frames()
 check(game.modal_kind=="painting" and not find_button("그림 속으로").disabled,"large painting viewer has real forest entrance")
 check(game.return_anchor.facing==facing and game.return_anchor.position==[original.x,original.y],"painting records exact plaza position and facing")
 await tap(find_button("그림 속으로"))
 check(adv.transitioning and game.paused,"portal locks inputs immediately")
 adv.enter_painting();check(adv.transitioning,"duplicate portal request ignored")
 await create_timer(2.5).timeout;await preload("res://tests/loading_wait.gd").settle(self,3)
 check(adv.in_mission and not game.paused and not adv.transitioning,"portal finishes loading playable forest")
 check(enemies().size()==3,"forest contains exactly three live goblins")
 check(adv.combat_buttons.all(func(b: Button)->bool:return b.visible),"combat buttons activate only inside painting")
 check(game.player.position.distance_to(Layout.SPAWN)<1,"player spawns at actual forest entry")
 # Native multi-touch: ownership survives dragging outside stick while second finger attacks.
 var stick: Control=game.joystick;var center:=stick.get_global_rect().get_center()
 touch(center+Vector2(60,0),true,0);await frames()
 var e:=InputEventScreenDrag.new();e.index=0;e.position=root.get_final_transform()*(center+Vector2(180,0));Input.parse_input_event(e);await frames()
 check(game.joystick.finger==0 and game.joystick.vector.x>.95,"joystick retains finger outside original radius")
 await tap(adv.combat_buttons[0],1)
 check(adv.attack_cd>0 and game.joystick.finger==0,"moving plus second-finger attack works")
 var mana:int=game.rpg.data.mp
 await tap(adv.combat_buttons[2],1);await create_timer(.55).timeout
 check(game.rpg.data.mp==mana-12 and game.joystick.finger==0,"moving plus skill spends real mana once")
 touch(center,false,0);await frames()
 # Collision-respecting dash into deep pond.
 game.player.position=Vector2(920,300);game.player.facing=0;adv.dodge_cd=0;adv.dodge();await create_timer(.25).timeout
 check(game.player.position.x<945 and adv.dodge_cd>0,"dodge stops at pond collision")
 game.player.dash_left=0;game.player.position=Vector2(520,570);game.player.facing=0
 for enemy in enemies():enemy.set_physics_process(false)
 var enemy: WooGoblin=enemies()[0];enemy.position=Vector2(575,570)
 adv.actions.cancel();adv.attack_cd=0;adv.basic_attack();await create_timer(.2).timeout
 check(enemy.hp==40,"actual magic projectile deals damage after physics ray hit")
 check(adv.combat.particles.size()==12 and adv.combat.numbers.size()==1,"blue hit emits bounded 12 shards and damage number")
 check(adv.shake_left>0 and game.camera.offset.length()>0,"camera shake runs independently of HUD")
 await create_timer(.4).timeout
 check(game.camera.offset.length()==0,"camera shake decays back to original offset")
 adv.talisman_cd=0;game.rpg.data.mp=50;adv.cast_slot(0);await create_timer(.3).timeout
 check(enemy.hp==8 and enemy.sealed>0,"gold talisman damage and sealing apply")
 # Freeze only combat actors, leaving timers/UI and save usable.
 adv.enemy_hit(enemy,1,Vector2.RIGHT,false)
 check(adv.hit_stop>0 and Engine.time_scale==1,"hit stop never changes global time scale")
 game.save_progress();check(game.last_save_error==OK,"save works during hit stop")
 await create_timer(.15).timeout
 # Save/resume an actual partial mission, preserving dead IDs and anchor.
 adv.enemy_hit(enemy,20,Vector2.RIGHT,false);await frames()
 check(adv.defeated()==[0],"first goblin death recorded once")
 game.save_progress();var data:=Save.load_game()
 check(data.rpg.session.defeated==[0] and Vector2(data.position[0],data.position[1]).distance_to(original)<.01,"mission save keeps plaza position and partial kill state")
 game.show_menu();await frames(5);game.start_game(true);await frames(5);adv=game.adventure
 check(adv.in_mission and enemies().size()==2 and adv.defeated()==[0],"continue resumes forest without resurrecting dead goblin")
 for n in enemies():n.set_physics_process(false)
 var before_hp:int=game.rpg.data.hp;adv.player_hurt_cd=0;adv.hurt_player(12)
 check(game.rpg.data.hp==before_hp-12,"enemy attack applies bounded player damage")
 adv.hurt_player(12);check(game.rpg.data.hp==before_hp-12,"damage cooldown prevents repeated contact loss")
 await create_timer(.2).timeout
 for n in enemies():adv.enemy_hit(n,1000,Vector2.RIGHT,true)
 await frames(5)
 check(adv.mission_done and adv.defeated().size()==3 and game.modal_kind=="complete","three actual deaths open completion screen")
 check(game.rpg.data.level==2 and game.rpg.data.xp==20 and game.rpg.data.coins==50,"completion grants XP level and coins")
 check(game.rpg.count("potion")==5 and game.rpg.count("leaf")==4,"rewards arrive in actual inventory")
 check(game.rpg.data.claims==["fox_forest"] and not game.rpg.claim_fox_reward(),"persistent claim blocks duplicate rewards")
 var saved: Dictionary=Save.load_game()
 check(saved.rpg.claims==["fox_forest"],"reward claim committed before completion UI")
 await tap(find_button("광장으로 돌아가기"));await create_timer(2.5).timeout;await preload("res://tests/loading_wait.gd").settle(self,3)
 check(not adv.in_mission and not game.paused and not adv.transitioning,"reverse portal returns to plaza safely")
 check(game.player.position.distance_to(original)<.1 and game.player.facing==facing,"exact plaza entry position and direction restored")
 check(adv.combat_buttons.all(func(b: Button)->bool:return not b.visible),"plaza combat controls hidden again")
 check(game.completed_paintings.has("fox_forest") and game.rpg.data.session.is_empty(),"completed painting feeds plaza tree, clears mission session")
 game.rpg.data.hp=30;adv.show_inventory();await frames();adv.show_item("potion");await frames();await tap(find_button("사용"));await frames()
 check(game.rpg.data.hp==75 and game.rpg.count("potion")==4,"native inventory use heals and persists one consumed item")
 game.close_modal();game.save_progress();saved=Save.load_game();saved.erase("rpg")
 check(Save.valid(saved) and State.new(saved.get("rpg",{})).data.level==1,"V1.2 save without RPG migrates with safe defaults")
 game.queue_free();await frames(4)
 print("RPG V1.3: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
