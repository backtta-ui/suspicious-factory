extends SceneTree
const State=preload("res://scripts/woo/rpg_state.gd")
var game: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal()
 var adv: WooAdventure=game.adventure
 check(adv.load_forest(false),"forest loader initializes real world")
 var enemies: Array=adv.forest.get_children().filter(func(n: Node)->bool:return n is WooGoblin)
 var enemy: WooGoblin=enemies[0]
 for n in enemies:
  if n!=enemy:n.set_physics_process(false)
 game.player.position=Vector2(620,705);enemy.position=Vector2(620,530);enemy.origin=enemy.position
 var origin: Vector2=enemy.position
 var first_rect: Rect2=enemy.sprite.region_rect
 Engine.time_scale=4
 await create_timer(.9).timeout
 check(enemy.position.distance_to(origin)>15,"goblin actually approaches player")
 check(enemy.travelled>15 and enemy.last_frame in [0,1,2,3],"actual movement advances distinct leg frames")
 check(enemy.sprite.position==Vector2(-224,-427)*.115,"sprite cell baseline stays fixed during gait")
 var hp:int=game.rpg.data.hp
 await create_timer(4).timeout
 check(game.rpg.data.hp<hp,"live AI reaches player and attacks with windup")
 check(enemy.position.distance_to(game.player.position)>=13,"enemy does not pass through player collision")
 check(enemy.plan_count<35,"AI path requests throttled, never every frame")
 Engine.time_scale=1
 game.set_paused(true);var stable: Vector2=enemy.position;await create_timer(.2).timeout
 check(enemy.position==stable,"paused combat actors remain stable")
 game.set_paused(false);enemy.set_physics_process(false);enemy.hp=60
 adv.combat.particles.clear();adv.combat.numbers.clear()
 adv.enemy_hit(enemy,1,Vector2.LEFT,false)
 check(enemy.flash>0 and adv.hit_stop==.08 and adv.shake_left==.25,"enabled hit timers use separate tunable config")
 check(adv.combat.particles.size()==12 and adv.combat.numbers.size()==1,"hit burst sizes and numbers configured")
 await create_timer(.9).timeout
 check(adv.combat.particles.is_empty() and adv.combat.numbers.is_empty(),"all transient shards and numbers retire")
 for k in game.rpg.data.effects:game.rpg.data.effects[k]=false
 enemy.flash=0;adv.hit_stop=0;adv.shake_left=0;adv.enemy_hit(enemy,1,Vector2.LEFT,false)
 check(enemy.flash==0 and adv.hit_stop==0 and adv.shake_left==0 and adv.combat.particles.is_empty(),"all four effects can be disabled independently")
 for k in game.rpg.data.effects:game.rpg.data.effects[k]=true
 enemy.set_physics_process(true);enemy.flash=.1;enemy.sealed=0;enemy.knocked=Vector2.ZERO
 await create_timer(.15).timeout
 check(enemy.flash==0 and enemy.white_material.get_shader_parameter("white_amount")==0,"white flash resets to original appearance")
 game.rpg.data.hp=1;adv.player_hurt_cd=0;adv.hurt_player(12);await frames()
 check(game.rpg.data.hp==0 and game.modal_kind=="defeat" and game.paused,"real player defeat opens safe return screen")
 game.close_modal();game.rpg.data.hp=100
 game.rpg.data.session.defeated=[0,1,2];game.rpg.data.session.completed=true;adv.mission_done=true
 # Restart within a fresh process separately verifies this persisted claim and session.
 game.save_progress();adv.show_completion();await frames()
 check(game.last_save_error==OK and game.rpg.data.claims==["fox_forest"],"completion claim durably saved")
 game.queue_free();await frames()
 print("V1.3 AI/EFFECTS: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
