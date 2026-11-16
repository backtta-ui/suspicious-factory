extends SceneTree
const Catalog=preload("res://scripts/wardrobe/catalog.gd")
const Profile=preload("res://scripts/wardrobe/profile.gd")
const Rules=preload("res://scripts/seal/rules.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 for path in [Profile.PATH,Profile.PATH+".bak"]:
  if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 var profile:=Profile.new()
 check(profile.data.appearance==Catalog.DEFAULT,"legacy/missing wardrobe keeps exact original Woochi defaults")
 check(Catalog.CHARACTERS.size()==4 and Catalog.OUTFITS.size()==8 and Catalog.HAIRS.size()==6 and Catalog.HATS.size()==7 and Catalog.ACCESSORIES.size()==9,"four characters, eight outfits, six hairs/six hats/eight accessories plus none")
 check(profile.owned("character","yeonhwa") and not profile.owned("character","muyeong"),"Yeonhwa free while adventure characters locked")
 var look:=Catalog.DEFAULT.duplicate();look.character="hongryeon"
 check(profile.equip(look)==ERR_UNAUTHORIZED,"locked character cannot be equipped even by direct profile call")
 profile.refresh({"completed":["fox_forest"],"loot_claims":["shrine_seal"]})
 check(profile.owned("character","muyeong") and profile.owned("character","hongryeon") and profile.owned("outfit","night"),"real forest and shrine save IDs unlock characters and night outfit")
 profile.record_server_wins("wss://test.invalid",9);check(not profile.owned("outfit","moon"),"nine confirmed server wins do not unlock ten-win outfit")
 profile.record_server_wins("wss://test.invalid",10);profile.record_server_wins("wss://test.invalid",10)
 check(profile.owned("outfit","moon") and profile.data.verified_wins==10,"cumulative server count replay cannot double rewards")
 profile.record_server_wins("wss://test.invalid",30);check(profile.owned("outfit","wind"),"thirty confirmed server wins unlock wind robe")
 check(not profile.owned("outfit","dragon") and not profile.owned("outfit","snow"),"unreleased event and payment costumes stay locked")
 look=Catalog.DEFAULT.duplicate();look.character="yeonhwa";look.hair="flower";look.outfit="night";look.color="black_gold";look.hat="bamboo";look.accessory="orb"
 check(profile.equip(look)==OK,"each owned layer equips independently")
 check(Profile.new().data.appearance==look,"separate wardrobe survives profile reload without rewriting RPG save")
 check(Catalog.normalize({"character":"unknown","outfit":123,"speed":999})==Catalog.DEFAULT,"unknown IDs and injected stats normalize to safe appearance only")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.wardrobe=profile;game.start_game(false);await frames()
 check(game.player.cosmetic==look,"saved appearance applied in actual plaza actor")
 var base_speed: float=game.player.WALK_SPEED;var shape: float=game.player.get_child(0).shape.radius
 for character in Catalog.CHARACTERS:
  game.player.cosmetic.character=character
  for pose in range(8):game.player.action_pose=pose;game.player.action_left=.3;game.player.jump_height=12;game.player.update_sprite();await frames(1)
  check(game.player.WALK_SPEED==base_speed and game.player.get_child(0).shape.radius==shape and game.player.sprite.scale==Vector2.ONE*.34,"%s keeps speed, collision, scale through all poses"%character)
 game.player.reset_action();game.player.cosmetic=Catalog.DEFAULT.duplicate();game.cast_spell();await create_timer(.5).timeout;await frames()
 check(game.spell_button.get_node("SkillBadge").remaining>0,"plaza transform icon shows real cooldown, not hidden text only")
 game.show_wardrobe();await frames()
 check(game.modal_kind=="wardrobe" and game.paused,"actual wardrobe opens and pauses single-player")
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 check(is_instance_valid(screen) and is_instance_valid(screen.preview),"live full-body preview actor exists")
 screen.slot="hat";screen.select("none");await frames();check(screen.preview.cosmetic.hat=="none","changing hat updates live preview")
 screen.close();await frames();check(game.wardrobe.data.appearance.hat=="bamboo","cancel never overwrites saved equipped appearance")
 var rules:=Rules.new("123456",71)
 for i in range(6):rules.add(str(i),"도사",[]);rules.players[str(i)].ready=true
 rules.command("0",{"op":"appearance","appearance":look})
 check(rules.view("1").roster[0].cosmetic==look,"lobby snapshot synchronizes cosmetics without roles")
 rules.start("0");var original: Dictionary=rules.players["0"].cosmetic.duplicate();var reply:=rules.command("0",{"op":"appearance","appearance":Catalog.DEFAULT})
 check(reply.has("error") and rules.players["0"].cosmetic==original,"server refuses wardrobe changes during match")
 check(rules.players["0"].cosmetic==look,"random role assignment never changes appearance")
 game.show_menu(false);await frames();game.start_game(true);await frames();check(game.player.cosmetic==look,"continue restores appearance alongside existing game")
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal();game.adventure.load_forest(false);await frames()
 var adv: WooAdventure=game.adventure
 var enemies: Array=adv.actions.enemies()
 for enemy in enemies:enemy.set_physics_process(false);enemy.position=Vector2(2000,1000)
 var target: WooGoblin=enemies[0];target.position=Vector2(540,650);target.hp=1000;target.max_hp=1000
 game.player.position=Vector2(600,650);game.player.jar=false;game.player.facing=0;game.joystick.vector=Vector2.LEFT
 adv.basic_attack();await create_timer(.15).timeout
 check(adv.actions.aim.x<0 and target.hp<1000,"attack steers toward live left joystick before impact and actually damages left target")
 check(adv.combat.get_child_count()>0,"authored attack sprite effect is instantiated in real combat")
 game.joystick.vector=Vector2.RIGHT;adv.basic_attack();await create_timer(.42).timeout
 check(adv.actions.aim.x>0,"buffered next attack follows new right direction instead of stale initial facing")
 game.joystick.reset();game.show_menu(false);game.queue_free();await frames()
 print("WARDROBE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
