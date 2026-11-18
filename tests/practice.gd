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
 await preload("res://tests/loading_wait.gd").settle(self,n)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var look:=Appearance.DEFAULT.duplicate();look.character="yeonhwa";look.hair="silver";look.hat="hood";look.color="purple";look.color_override=true
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
 print("OFFLINE PRACTICE CORE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
