extends SceneTree
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
 var actor: WooActor=game.player;actor.facing=2;actor.update_sprite()
 var texture: Texture2D=actor.sprite.texture;var region: Rect2=actor.sprite.region_rect
 check(texture==actor.SHEET and actor.sprite.scale==Vector2.ONE*.34,"original base hero texture and scale are canonical")
 for pose in range(8):
  actor.action_pose=pose;actor.action_left=.3;actor.pose_duration=.4;actor.update_sprite()
  check(actor.sprite.texture==texture and actor.sprite.region_rect==region and actor.sprite.scale==Vector2.ONE*.34,"pose%d never swaps face, hat, costume, pivot or scale"%pose)
 actor.action_left=0;actor.jump();await create_timer(.025).timeout
 check(actor.jump_phase=="preparation" and actor.jump_height==0,"jump has a real short preparation phase")
 await create_timer(.15).timeout;check(actor.jump_phase=="rising" and actor.jump_height>0,"jump rises without reducing character scale")
 await create_timer(.28).timeout;check(actor.jump_phase=="apex" or actor.jump_phase=="falling","jump reaches apex and descent")
 await create_timer(.5).timeout;check(actor.jump_height==0 and actor.sprite.scale==Vector2.ONE*.34,"landing restores only height, never image scaling")
 check(is_instance_valid(game.adventure.jump_button.get_node("SkillBadge")) and game.adventure.jump_button.get_node("SkillBadge").skill=="jump","jump control has its own real icon")
 check(game.adventure.combat_buttons[0].get_node("SkillBadge").skill=="attack","largest attack control uses palm icon")
 var profile:=preload("res://scripts/seal/identity.gd").load_profile()
 check(profile.id.length()==32 and profile.secret.length()==64,"anonymous identity uses random persisted credentials")
 var second:=preload("res://scripts/seal/identity.gd").load_profile();check(second.id==profile.id and second.secret==profile.secret,"anonymous identity survives process/profile reload")
 var state: WooRpgState=game.rpg;var qty:int=state.count("potion")
 check(state.discard_item("potion") and state.count("potion")==qty-1,"discarding one consumable updates actual inventory")
 check(not state.discard_item("key") and state.count("key")==1,"quest valuable cannot be discarded")
 game.save_progress();check(game.Save.load_game().rpg.inventory.potion==qty-1,"item deletion persists through existing save format")
 game.show_menu();await frames();game.show_seal();await frames()
 check(game.screen_name=="seal" and is_instance_valid(game.seal_client),"main menu launches separate real-network mode")
 check(not game.seal_client.connection.authenticated and game.seal_client.state.is_empty(),"no server address never fabricates a connected lobby or players")
 game.go_back();await frames();check(game.screen_name=="menu","Android back safely leaves multiplayer setup")
 game.queue_free();await frames();print("HERO V2.0: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
