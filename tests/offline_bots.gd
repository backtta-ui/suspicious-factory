extends SceneTree
const Transport=preload("res://scripts/simulation/transport.gd")
const Main=preload("res://scenes/main.tscn")
const Catalog=preload("res://scripts/seal/catalog.gd")
var checks:=0
var failures:=0
var results: Array=[]
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func session(seed_number: int=9) -> Node:
 var local:=Transport.new();local.seed_value=seed_number;root.add_child(local);local.set_process(false);return local
func start(local: Node) -> void:
 local.send({"op":"ready","value":true});local.send({"op":"start"})
 for i in range(61):local.step(.05)
func run() -> void:
 if OS.get_cmdline_user_args().has("--ui-only"):
  await ui_checks();print("UI CHECKS ",checks," failures ",failures);quit(1 if failures else 0);return
 var local:=session()
 check(local.rules.players.size()==6,"six-person default")
 check(local.rules.players.values().all(func(p: Dictionary)->bool:return p.role==""),"lobby hides roles")
 check(local.rules.players.values().all(func(p: Dictionary)->bool:return p.owned_spells.size()==8),"all eight common spells temporary owned")
 local.send({"op":"ready","value":true});local.send({"op":"start"});check(not local.send({"op":"start"}),"duplicate start blocked")
 check(not local.send({"op":"appearance","appearance":{}}),"countdown locks customization")
 for i in range(61):local.step(.05)
 check(local.rules.phase=="prepare","countdown starts real rules")
 check(local.rules.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai").size()==2,"two random yokai")
 var dao: Array=[];var evil: Array=[]
 for p in local.rules.players.values():
  if p.role=="daoist":dao.append(p)
  else:evil.append(p)
 check(not evil[0].slots.has("transform"),"yokai never receives unusable object spell")
 var view: Dictionary=local.rules.view(dao[0].uid)
 check(view.self.teammates.is_empty() and view.roster.all(func(p: Dictionary)->bool:return not p.has("role")),"private enemy roles not exposed")
 check(local.rules.view(evil[0].uid).self.teammates.has(evil[1].uid),"yokai allies known")
 local.rules.phase="roam";var rules: SealRules=local.rules
 evil[0].position=rules.arena.safe(Vector2(1000,680));dao[0].position=evil[0].position+Vector2(15,0)
 check(not local.act(evil[0].uid,{"op":"cast","skill":"capture","target":dao[0].uid}).has("error"),"real capture")
 check(dao[0].captured and is_equal_approx(dao[0].capture_until-rules.elapsed,45),"45 second deadline")
 check(local.act(evil[0].uid,{"op":"cast","skill":"capture","target":dao[0].uid}).has("error"),"duplicate capture rejected")
 dao[1].position=dao[0].position+Vector2(-18,0)
 check(not local.act(dao[1].uid,{"op":"rescue","target":dao[0].uid}).has("error"),"real rescue starts")
 check(is_equal_approx(rules.channels[dao[1].uid].until-rules.elapsed,4),"rescue exactly four seconds")
 local.act(dao[1].uid,{"op":"cancel_channel"});check(not rules.channels.has(dao[1].uid),"touch release cancels rescue")
 local.act(dao[1].uid,{"op":"rescue","target":dao[0].uid})
 for i in range(39):rules.tick(.1)
 check(dao[0].captured,"not rescued before four seconds")
 rules.tick(.1);rules.tick(.01)
 check(not dao[0].captured and dao[0].protected-rules.elapsed>2.9,"rescue grants three-second immunity")
 evil[0].position=dao[0].position;evil[0].cd={}
 check(local.act(evil[0].uid,{"op":"cast","skill":"capture","target":dao[0].uid}).has("error"),"immediate recapture rejected")
 dao[0].protected=0;local.act(evil[0].uid,{"op":"cast","skill":"capture","target":dao[0].uid});dao[0].capture_until=rules.elapsed+.1
 dao[1].position=dao[0].position;local.act(dao[1].uid,{"op":"rescue","target":dao[0].uid});rules.tick(.1)
 check(dao[0].sealed and not dao[0].captured,"deadline wins over unfinished rescue")
 check(local.act(dao[0].uid,{"op":"cast","skill":"blink"}).has("error"),"eliminated cannot cast")
 evil[0].cd={};evil[0].position=dao[1].position
 local.act(evil[0].uid,{"op":"cast","skill":"mimic","target":dao[1].uid})
 check(evil[0].buff.get("appearance","")==dao[1].uid and evil[0].uid!=dao[1].uid,"mimic keeps real id")
 local.act(evil[0].uid,{"op":"unmask"});check(not evil[0].buff.has("mimic"),"mimic release")
 var caster: Dictionary=dao[2]
 caster.captured=false;caster.sealed=false;caster.penalty=0;caster.position=rules.arena.safe(Vector2(1000,680))
 for skill in Catalog.COMMON:
  caster.slots=[skill];caster.cd={};caster.buff={};caster.forms=["jar"];caster.selected_form="jar"
  check(not local.act(caster.uid,{"op":"cast","skill":skill}).has("error"),"real common cast: "+skill)
  check(caster.cd.has(skill),"cooldown recorded: "+skill)
 for skill in Catalog.EVIL:
  evil[0].cd={};evil[0].buff={};caster.captured=false;caster.sealed=false;caster.protected=0;evil[0].position=caster.position
  check(not local.act(evil[0].uid,{"op":"cast","skill":skill,"target":caster.uid}).has("error"),"real role cast: "+skill)
 # A full autonomous match uses normal time and commands, no teleport or forced outcome.
 local.queue_free();await frames()
 for size in [6,7,8]:
  var sim:=session(1 if size==7 else (9 if size==6 else size+11));sim.configure_size(size,2 if size<8 else 3);start(sim)
  var began:=Time.get_ticks_msec()
  for i in range(9700):
   sim.step(.05)
   if sim.rules.phase=="result":break
  print("Completed match size ",size," phase ",sim.rules.phase," time ",sim.rules.elapsed)
  check(sim.rules.phase=="result","autonomous %d-player match ends"%size)
  var captures: int=sim.history.filter(func(e: Dictionary)->bool:return e.kind=="capture").size()
  var rescues: int=sim.history.filter(func(e: Dictionary)->bool:return e.kind=="rescue").size()
  results.append({"players":size,"map":sim.rules.arena.id,"winner":sim.rules.winner,"simulation_seconds":sim.rules.elapsed,"wall_ms":Time.get_ticks_msec()-began,"captures":captures,"rescues":rescues,"missions_done":sim.rules.missions.filter(func(m: Dictionary)->bool:return m.done).size()})
  check(captures>0,"yokai bots actually capture %d"%size)
  var snapshot: Dictionary={};sim.packet.connect(func(p: Dictionary)->void:snapshot.merge(p,true));sim.publish()
  check(snapshot.state.roster.all(func(p: Dictionary)->bool:return p.has("role")),"result reveals roles")
  sim.send({"op":"rematch"});check(sim.rules.phase=="lobby" and sim.history.is_empty() and sim.rules.players.values().all(func(p: Dictionary)->bool:return not p.sealed and not p.captured and p.role==""),"rematch full reset")
  var round_before: int=sim.rules.round_number;sim.staged_start=true;start(sim);check(sim.rules.round_number>round_before,"rematch gets a fresh round id")
  sim.queue_free();await frames()
 var maps: Dictionary={};var roles: Dictionary={}
 for seed_number in range(1,13):
  var sim:=session(seed_number);sim.staged_start=true;start(sim);maps[sim.rules.arena.id]=true;roles[sim.rules.players[sim.uid].role]=true;sim.queue_free();await frames(1)
 check(maps.size()==2,"both real maps in random pool")
 check(roles.size()==2,"human receives either random role")
 await ui_checks()
 var file:=FileAccess.open("res://builds/offline-bot-matches.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 print("OFFLINE BOTS: ",checks," checks / ",failures," failures; ",JSON.stringify(results));quit(1 if failures else 0)

func ui_checks() -> void:
 root.size=Vector2i(1280,720)
 var game:=Main.instantiate();root.add_child(game);await frames(8);game.start_game(false);await frames(8)
 var before_position: Vector2=game.player.position;var before_face: int=game.player.facing;var before_zoom: Vector2=game.camera.zoom
 var owned: Dictionary=game.wardrobe.data.duplicate(true);game.enter_simulation();await frames(8)
 var client=game.seal_client
 check(is_instance_valid(client) and client.screen=="lobby","plaza to offline lobby")
 check(client.state.roster.size()==6 and client.connection.ws==null,"six real local participants without socket")
 client.show_loadout();await frames();check(is_instance_valid(client.popup),"scrollable spell dialog opens");client.close_popup()
 client.show_characters();await frames();check(is_instance_valid(client.popup),"character dialog opens");client.close_popup()
 client.connection.send({"op":"ready","value":true});client.connection.send({"op":"start"})
 for i in range(61):client.connection.step(.05)
 client.connection.publish()
 for i in range(180):
  await process_frame
  if client.screen=="game" and not client.entering:break
 check(client.screen=="game" and is_instance_valid(client.world) and is_instance_valid(client.camera),"real map and camera prepared")
 check(not game.loading.busy,"shared loading finishes")
 check(game.wardrobe.data==owned,"trial preserves wardrobe and ownership")
 var store_before: Dictionary={}
 for file_name in DirAccess.get_files_at("user://"):store_before[file_name]=FileAccess.get_file_as_bytes("user://"+file_name)
 # A UI-only fixture verifies native hold/release and spectator controls.
 client.connection.set_process(false);client.close_popup()
 var authority: SealRules=client.connection.rules;authority.phase="roam"
 var human: Dictionary=authority.players[client.connection.uid];human.role="daoist";human.position=authority.arena.safe(authority.arena.jail+Vector2(-25,0))
 var prisoner: Dictionary=authority.players["bot-1"];prisoner.role="daoist";prisoner.position=human.position;prisoner.captured=true;prisoner.capture_until=authority.elapsed+45
 client.connection.publish();await frames(6)
 var touch:=InputEventScreenTouch.new();touch.index=73;touch.pressed=true;touch.position=client.role_button.get_global_rect().get_center();Input.parse_input_event(touch);await frames(3)
 if not authority.channels.has(human.uid):print("HOLD DEBUG ",client.role_button.usable()," held ",client.role_button.held," closest ",client.closest(true)," status ",client.message," role ",client.state.self.role," rect ",client.role_button.get_global_rect()," context ",game.active_context)
 check(authority.channels.has(human.uid),"native touch begins rescue channel")
 touch=InputEventScreenTouch.new();touch.index=73;touch.pressed=false;touch.position=client.role_button.get_global_rect().get_center();Input.parse_input_event(touch);await frames(3)
 check(not authority.channels.has(human.uid),"native touch release cancels rescue")
 human.sealed=true;client.connection.publish();await frames();check(client.state.self.sealed and client.state.spectate!="","eliminated human can spectate")
 client.show_spectators();await frames();check(is_instance_valid(client.popup),"spectator target picker");client.close_popup()
 client.exit_to_main();await frames(8)
 check(game.screen_name=="playing" and game.player.position.distance_to(before_position)<.01 and game.player.facing==before_face and game.camera.zoom==before_zoom,"exact plaza anchor and camera restored")
 check(not game.sound.ducked,"plaza audio unducks on return")
 check(game.wardrobe.data==owned,"exit preserves profile")
 for file_name in store_before:check(FileAccess.get_file_as_bytes("user://"+file_name)==store_before[file_name],"persistent file unchanged: "+file_name)
 game.enter_simulation();await frames(5);client=game.seal_client
 game.loading.begin("simulation",Callable(),client.exit_to_main);game.loading.failure("injected missing-resource recovery test");await frames(5)
 check(game.screen_name=="playing" and game.seal_client==null and game.loading.failed and is_instance_valid(game.loading.overlay),"failed load restores safe plaza and preserves error overlay")
 game.loading.dismiss_failure();await frames();check(not game.loading.busy,"failed loading can be dismissed")
 game.queue_free();await frames()
