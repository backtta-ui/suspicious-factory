extends SceneTree
const State=preload("res://scripts/woo/rpg_state.gd")
const Layout=preload("res://scripts/woo/forest_layout.gd")
const Save=preload("res://scripts/woo/save_game.gd")
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func enemies() -> Array:return game.adventure.actions.enemies()
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var state:=State.new();state.data.level=4;state.data.xp=35;state.data.inventory.potion=7
 var old: Dictionary=JSON.parse_string(JSON.stringify(state.data));old.version=1;old.erase("rarities");old.erase("seen_items");old.erase("loot_claims");old.erase("visited");old.erase("discoveries")
 check(State.valid(old),"real JSON version1 RPG save accepted")
 var migrated:=State.new(old)
 check(migrated.data.version==2 and migrated.data.level==4 and migrated.count("potion")==7,"migration preserves old level XP inventory with version2 defaults")
 check(migrated.data.rarities.key=="영웅" and migrated.data.rarities.potion=="일반","default rarities are real persistent data")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.adventure.jump();await create_timer(.18).timeout
 check(game.player.jump_height>5 and game.player.position.distance_to(game.Layout.SPAWN)<.01,"plaza jump separates height from planted world foot position")
 check(game.player.collision_mask==1,"jump keeps normal world collision mask")
 game.adventure.basic_attack();check(not game.adventure.actions.active,"plaza refuses ground and airborne attacks")
 await create_timer(.7).timeout
 check(game.player.jump_height==0,"jump lands and restores floor height")
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
 var adv: WooAdventure=game.adventure
 for n in enemies():n.set_physics_process(false)
 var enemy: WooGoblin=enemies()[0]
 game.player.position=Vector2(600,650);enemy.position=Vector2(670,685);enemy.hp=1000;enemy.max_hp=1000
 game.player.facing=0
 await physics_frame;await physics_frame
 game.world.process_mode=Node.PROCESS_MODE_INHERIT
 await physics_frame;await physics_frame
 var old_line: bool=adv.actions.visible_line(game.player.position,enemy.position)
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 await physics_frame;await physics_frame
 check(not old_line and adv.actions.visible_line(game.player.position,enemy.position),"reproduce hidden plaza ghost colliders, then remove them from mission physics")
 check(adv.actions.corrected_direction().distance_to((enemy.position-game.player.position).normalized())<.01,"front-biased auto aim corrects moderate angle at world feet")
 var hp:int=enemy.hp
 adv.basic_attack();var attack_facing: int=game.player.facing
 game.joystick.vector=Vector2.LEFT
 await create_timer(.2).timeout
 check(game.player.facing==attack_facing,"movement steering does not reverse a committed attack pose")
 game.joystick.reset()
 check(enemy.hp==hp-20,"wide first palm cone lands on off-axis target")
 await create_timer(.25).timeout
 check(enemy.hp==hp-20,"one attack never damages same enemy twice")
 # A fast burst queues the three following attacks, rather than disabling the button.
 adv.actions.cancel();adv.hit_stop=0;game.player.position=Vector2(600,650);enemy.position=Vector2(660,650);enemy.hp=1000;enemy.jump_height=0
 adv.basic_attack();adv.basic_attack();adv.basic_attack();adv.basic_attack()
 check(adv.actions.queue.size()==3,"rapid taps buffer next three attacks")
 await create_timer(2.1).timeout
 check(adv.actions.stage==4 and enemy.hp==898,"four stages deal 100/110/130/170 percent with single staff impact third stage")
 check(adv.actions.hits>=4,"real contacts drive visible hit counter")
 enemy.set_physics_process(true);await create_timer(.18).timeout
 check(enemy.jump_height>0 or enemy.jump_velocity>0,"fourth rising strike launches monster independently of world position")
 enemy.set_physics_process(false)
 await create_timer(1.2).timeout
 adv.basic_attack();check(adv.actions.stage==1,"combo resets after no input timeout")
 await create_timer(.5).timeout
 adv.actions.cancel();adv.hit_stop=0;game.player.jump_height=0;game.player.jump_velocity=0;game.player.position=Vector2(600,650);enemy.position=Vector2(660,650);enemy.hp=1000
 adv.jump();await create_timer(.15).timeout;adv.basic_attack();await create_timer(.4).timeout
 check(enemy.hp<1000 and game.player.air_chain,"airborne attack hits airborne-capable foot-space targets")
 var after_air:int=enemy.hp
 await create_timer(.5).timeout
 check(game.player.jump_height==0 and enemy.hp<after_air,"air combo produces distinct landing strike")
 adv.actions.cancel();adv.player_hurt_cd=0;game.player.hurt_stun=0;game.player.transforming=.3;game.rpg.data.hp=100
 adv.hurt_player(12,Vector2.LEFT)
 check(game.rpg.data.hp==88,"damage receiver stays active during transformation instead of sharing attack gate")
 check(game.player.hurt_left>0 and game.player.hurt_stun>0 and game.player.hurt_knock.x<0,"player hit flash stun and knockback are real state")
 check(adv.hp_bar.value==88 and Save.load_game().rpg.hp==88,"HP bar and persisted health immediately reflect damage")
 adv.hurt_player(12);check(game.rpg.data.hp==88,"0.5-second injury immunity prevents duplicate strike")
 await create_timer(.55).timeout;adv.hurt_player(12);check(game.rpg.data.hp==76,"injury immunity expires and later hit damages again")
 game.player.transforming=0;game.player.hurt_stun=0;adv.player_hurt_cd=0
 enemy.position=Vector2(620,650);enemy.attack_direction=Vector2.LEFT
 game.player.position=Vector2(575,650)
 check(enemy.can_strike(game.player.position),"monster reachable windup strike covers visual club range")
 game.player.jump_height=24;check(not enemy.can_strike(game.player.position),"jump clears low club strike")
 game.player.jump_height=0;game.player.dash_left=.1;check(not enemy.can_strike(game.player.position),"active dodge clears club strike");game.player.dash_left=0
 game.player.position=Vector2(500,650);check(not enemy.can_strike(game.player.position),"out-of-range strike does not damage")
 # Solid rocks obstruct both player targeting and enemy strike rays.
 enemy.position=Vector2(560,365);game.player.position=Vector2(560,430);enemy.attack_direction=Vector2.DOWN
 check(not enemy.clear_path(game.player.position),"static rock blocks monster attack line")
 game.player.position=Vector2(600,650);game.player.transforming=0;game.player.hurt_stun=0;adv.player_hurt_cd=0;game.rpg.data.hp=1
 adv.hurt_player(12);await frames()
 check(game.player.defeated and game.paused and game.modal_kind=="defeat","zero HP freezes actions and opens retry screen")
 await create_timer(.35).timeout
 check(game.player.sprite.rotation<-.8,"defeat pose visibly collapses while retry UI remains responsive")
 var saved_claims: Array=game.rpg.data.claims.duplicate();adv.retry_mission();await frames()
 check(not game.player.defeated and not game.paused and enemies().size()==3 and adv.defeated().is_empty(),"retry resets monster IDs and goals, restores live player")
 check(game.player.position.distance_to(Layout.SPAWN)<1 and game.rpg.data.hp==game.rpg.max_hp() and game.rpg.data.claims==saved_claims,"retry spawn and HP restore while permanent rewards survive")
 # Compute actual traversable area instead of multiplying texture dimensions.
 var walkable:=0;var legacy_walkable:=0
 var start:=Time.get_ticks_msec()
 for y in range(170,1990,20):
  for x in range(110,2890,20):
   var p:=Vector2(x,y)
   if Layout.can_stand(p):walkable+=1
   if x<1390 and y<910 and Layout.can_stand(p):legacy_walkable+=1
 var ratio:=float(walkable)/legacy_walkable
 check(ratio>=4 and ratio<=6,"actual sampled walkable area expands 4–6x (%.2f)" % ratio)
 for z in Layout.ZONES:
  check(not adv.forest.route(Layout.SPAWN,Layout.safe(z.center)).is_empty(),"navigation connects zone "+z.name)
 game.player.position=Layout.LOOT[0].position;await frames();var qty:int=game.rpg.count("potion")
 check(adv.acquire_loot(Layout.LOOT[0]) and game.rpg.count("potion")==qty+2,"chest gives actual inventory items")
 check(not adv.acquire_loot(Layout.LOOT[0]) and game.rpg.count("potion")==qty+2,"chest cannot be collected twice")
 game.save_progress();var saved: Dictionary=Save.load_game()
 check(saved.rpg.loot_claims.has("bamboo_chest"),"exploration claims survive save and reload")
 adv.show_inventory();await frames()
 var bundle: WooBundleUI=game.modal.get_child(game.modal.get_child_count()-1)
 check(bundle.slot_count==30 and bundle.slots.columns==5,"bundle has actual 5-column 30-slot grid")
 var inv: Dictionary=game.rpg.data.inventory.duplicate()
 bundle.category="의상";bundle.rebuild();check(bundle.selected=="" and game.rpg.data.inventory==inv,"category filters never alter actual inventory")
 bundle.category="전체";bundle.select("mana_potion");await frames()
 check(bundle.selected=="mana_potion" and bundle.detail.get_child(1) is WooItemArt,"selected item has unique large art instead of text glyph")
 bundle.inspect_item("key");await frames();check(is_instance_valid(bundle.inspector),"expanded appreciation screen opens with item art and story")
 game.go_back();await frames();check(not is_instance_valid(bundle.inspector) and game.paused,"Android back closes inspection without unpausing inventory")
 game.rpg.data.mp=1;var potions:int=game.rpg.count("mana_potion");bundle.select("mana_potion");bundle.use_selected()
 check(game.rpg.data.mp==31 and game.rpg.count("mana_potion")==potions-1,"new bundle use applies real MP and consumes exactly one")
 check(Save.load_game().rpg.inventory.mana_potion==potions-1,"bundle quantity and rarity persist after usage")
 game.go_back();check(not game.paused,"closing bundle restores gameplay")
 var report={"checks":checks,"failures":failures,"sampled_walkable_ratio":ratio,"old_grid_cells":legacy_walkable,"new_grid_cells":walkable,"device_test":false}
 var file:=FileAccess.open("res://builds/v14-action-measurements.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.queue_free();await frames();print("ACTION V1.4: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
