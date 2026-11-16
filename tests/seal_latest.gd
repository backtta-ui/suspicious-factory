extends SceneTree
const Rules=preload("res://scripts/seal/rules.gd")
const C=preload("res://scripts/seal/catalog.gd")
const Arena=preload("res://scripts/seal/arena.gd")
const Loadout=preload("res://scripts/seal/loadout.gd")
const Study=preload("res://scripts/seal/study.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func room(id: String="village",seed_value: int=103) -> SealRules:
 var r:=Rules.new("101010",seed_value,{"map_pool":[id]})
 for i in range(8):r.add(str(i),"도사%d"%i,["transform","blink"],{"owned_spells":C.COMMON.keys(),"tier":"paid"});r.players[str(i)].ready=true
 r.start("0")
 for i in range(620):r.tick(.05)
 return r
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=71
 var result:=Loadout.select_spells([],"free",C.COMMON.keys(),"mask",rng)
 check(result.slots==["",""] and result.reserve=="","new free player gets empty slots, never free unacquired spells")
 var choices: Array=[]
 for i in range(20):
  result=Loadout.select_spells(["transform","blink","shield"],"free",["mask","smoke"],"mask",rng)
  check(result.slots.size()==2 and result.slots[0]!=result.slots[1] and result.slots.all(func(s: String)->bool:return s in ["transform","blink","shield"]),"free draw %d is unique and acquired only"%i)
  if not choices.has(result.slots):choices.append(result.slots.duplicate())
 check(choices.size()>1,"server random sampler really varies across rounds")
 check(Loadout.select_spells(["blink"],"free",[],"",rng).slots==["blink",""],"fewer than two acquired spells uses configurable empty slot policy")
 check(Loadout.select_spells(["blink"],"paid",["blink","blink"],"",rng).has("error"),"paid duplicate selection rejected")
 check(Loadout.select_spells(["blink"],"paid",["shield"],"",rng).has("error"),"paid unacquired selection rejected")
 result=Loadout.select_spells(["blink","shield","track"],"vip",["blink","shield"],"track",rng)
 check(result.slots==["blink","shield"] and result.reserve=="track","VIP stores two active plus one separate acquired reserve")
 check(Loadout.select_spells(C.COMMON.keys(),"vip",["blink","shield","track"],"",rng).has("error"),"VIP never equips three active spells")
 var maps: Array=[]
 for seed_value in range(1,25):
  var r:=Rules.new("123123",seed_value)
  for i in range(6):r.add(str(i),"도사",[]);r.players[str(i)].ready=true
  r.start("0")
  if not maps.has(r.arena.id):maps.append(r.arena.id)
 check(maps.size()==2,"production registry selects both actual implemented maps across server seeds")
 var village:=room();var forest:=room("forest")
 for player in village.players.values():
  if player.role=="yokai":check(not player.slots.has("transform") and not village.eligible(player).has("transform"),"yokai random/selected slots exclude object transformation")
 var before_role: SealRules=Rules.new("818181",99)
 for i in range(6):before_role.add(str(i),"도사",[],{"owned_spells":["transform","blink","track"],"tier":"free"});before_role.players[str(i)].ready=true
 check(before_role.players.values().all(func(p: Dictionary)->bool:return p.slots==["",""]),"free lobby does not pre-roll a role-ineligible loadout")
 before_role.start("0")
 check(before_role.players.values().all(func(p: Dictionary)->bool:return p.slots.size()==2 and (p.role!="yokai" or not p.slots.has("transform"))),"first and only free allocation is role-filtered during preparation before live play")
 check(village.arena.id=="village" and forest.arena.id=="forest" and village.arena!=forest.arena,"different concurrent rooms own independent map and collision state")
 for r in [village,forest]:
  var colors: Array=[]
  for p in r.players.values():colors.append(p.color)
  check(colors.size()==8 and colors.all(func(c: int)->bool:return colors.count(c)==1),r.arena.id+" has eight unique server identity colors")
  check(r.players.values().all(func(p: Dictionary)->bool:return r.arena.can_stand(p.position)),r.arena.id+" spawns all eight actors on legal ground")
  check(r.arena.data.stations.all(func(p: Vector2)->bool:return r.arena.can_stand(r.arena.safe(p))),r.arena.id+" all mission stations resolve to legal map ground")
  check(not r.arena.can_stand(Vector2(-100,999)) and r.arena.move(r.players["0"].position,Vector2(-100,-100)).x>=0,r.arena.id+" collision prevents out-of-map movement")
  check(r.arena.assets.size()>=10 and r.arena.assets.all(func(a: Dictionary)->bool:return Arena.KINDS.has(a.kind)),r.arena.id+" exposes only real supported object/animal kinds")
 var dao: Dictionary=village.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")[0]
 var evil: Dictionary=village.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 evil.position=village.arena.safe(dao.position+Vector2(30,0));evil.cd={}
 village.command(evil.uid,{"op":"cast","skill":"mimic","target":dao.uid})
 var fake: Dictionary=village.view(dao.uid).actors.filter(func(a: Dictionary)->bool:return a.uid==evil.uid)[0]
 check(fake.uid==evil.uid and fake.color==dao.color and fake.cosmetic==dao.cosmetic and evil.color!=dao.color,"mimic copies current color/costume but retains real ID and original base color")
 check(village.view(dao.uid).roster.filter(func(a: Dictionary)->bool:return a.uid==evil.uid)[0].color==evil.color,"meeting roster still uses original identity color after mimic")
 var asset: Dictionary=village.arena.assets[0];dao.position=village.arena.safe(asset.origin+Vector2(38,0));dao.cd={}
 dao.slots=["blink","shield"]
 check(village.command(dao.uid,{"op":"extract","asset":asset.id}).has("error"),"owning without equipping transformation cannot extract")
 dao.slots=["transform","blink"];dao.owned_spells=["blink"]
 check(village.command(dao.uid,{"op":"extract","asset":asset.id}).has("error"),"forging a transformation slot without acquisition cannot extract or use it")
 check(village.command(dao.uid,{"op":"cast","skill":"transform"}).has("error"),"cast validation independently rejects unacquired spell")
 dao.owned_spells=C.COMMON.keys()
 check(village.command(dao.uid,{"op":"extract","asset":"building"}).has("error"),"unregistered/oversized fake shape IDs are rejected")
 village.command(dao.uid,{"op":"extract","asset":asset.id});
 for i in range(24):village.tick(.05)
 check(dao.forms.has(asset.kind) and dao.selected_form==asset.kind,"stationary channel stores an actually nearby map shape")
 village.command(dao.uid,{"op":"cast","skill":"transform"})
 check(village.view(dao.uid).actors.filter(func(a: Dictionary)->bool:return a.uid==dao.uid)[0].form=="asset:"+asset.kind,"real transformation snapshot uses exact environment renderer kind")
 check(village.move_speed(dao)==46,"object movement uses separate provisional object speed")
 village.command(dao.uid,{"op":"cast","skill":"transform"})
 check(dao.buff.get("transform",0)<=village.elapsed,"human return is allowed while transformation cooldown is active")
 var before: Array=dao.slots.duplicate()
 check(village.command(dao.uid,{"op":"swap_reserve"}).has("error") and dao.slots==before,"VIP in-game reserve swapping explicitly disabled")
 var study:=Study.new();study.position=Study.POINTS[0]
 check(study.command({"op":"study_answer","skill":"transform","nonce":"fake","answer":0}).has("error"),"adventure cannot grant spells from fabricated completion")
 var challenge: Dictionary=study.command({"op":"study_open","skill":"transform"}).study_challenge
 for i in range(3):study.tick(.45);study.command({"op":"study_answer","skill":"transform","nonce":challenge.nonce,"answer":challenge.pattern[i]})
 check(study.owned==["transform"],"three actual ordered study interactions unlock only that spell")
 check(study.command({"op":"study_open","skill":"transform"}).has("notice") and study.owned.size()==1,"replaying an earned adventure cannot duplicate acquisition")
 study.position=Study.POINTS[6];check(not study.command({"op":"study_open","skill":"mask"}).has("error"),"acquired transformation enables chained hidden-mask discovery")
 var novice:=Study.new();novice.position=Study.POINTS[6]
 check(novice.command({"op":"study_open","skill":"mask"}).has("error"),"hidden discovery prerequisite is actually enforced")
 print("SEAL LATEST: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
