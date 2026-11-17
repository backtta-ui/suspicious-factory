extends SceneTree
const T=preload("res://scripts/simulation/transport.gd")
var failures:=0
var checks:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var t:=T.new();t.staged_start=true;t.seed_value=9;root.add_child(t);t.set_process(false);t.send({"op":"ready","value":true});t.send({"op":"start"})
 for i in range(61):t.step(.05)
 var r: SealRules=t.rules;r.phase="roam"
 var dao: Array=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="daoist")
 var evil: Dictionary=r.players.values().filter(func(p: Dictionary)->bool:return p.role=="yokai")[0]
 var q: Dictionary=dao[0];var a: Dictionary=dao[1];var b: Dictionary=dao[2]
 var center:=r.arena.safe(r.arena.jail)
 for p in [q,a,b,evil]:p.position=center;p.buff={};p.cd={}
 q.captured=true;q.capture_until=r.elapsed+45
 r.command(a.uid,{"op":"rescue","target":q.uid});r.command(b.uid,{"op":"rescue","target":q.uid})
 for i in range(41):r.tick(.1)
 check(not q.captured,"two rescuers complete one shared rescue")
 check(r.actions.filter(func(e: Dictionary)->bool:return e.kind=="rescue" and e.target==q.uid).size()==1,"exactly one result log for simultaneous rescuers")
 check(q.protected>r.elapsed,"simultaneous rescue grants protection once")
 for p in [q,a,b,evil]:p.position=center;p.captured=false;p.sealed=false;p.protected=0;p.cd={}
 r.channels.clear();q.captured=true;q.capture_until=r.elapsed+45;r.command(a.uid,{"op":"rescue","target":q.uid})
 for i in range(20):r.tick(.1)
 r.command(evil.uid,{"op":"cast","skill":"capture","target":a.uid})
 check(a.captured and not r.channels.has(a.uid),"capture interrupts active rescuer")
 for i in range(21):r.tick(.1)
 check(q.captured,"interrupted rescue does not finish")
 for p in [q,a,b,evil]:p.position=center;p.captured=false;p.sealed=false;p.protected=0;p.cd={}
 r.channels.clear();q.captured=true;q.capture_until=r.elapsed+4;r.command(a.uid,{"op":"rescue","target":q.uid})
 for i in range(41):r.tick(.1)
 check(q.sealed and not q.captured,"capture deadline wins when rescue completion coincides")
 for p in [q,a,b,evil]:p.position=center;p.captured=false;p.sealed=false;p.protected=0;p.cd={}
 r.channels.clear();q.captured=true;q.capture_until=r.elapsed+45;r.command(a.uid,{"op":"rescue","target":q.uid})
 var log_size:=r.actions.size();r.result("yokai","test result boundary");t.step(.1)
 check(r.channels.is_empty() and r.actions.size()==log_size and r.winner=="yokai","game result cancels rescue and stays final")
 t.queue_free()
 var file:=FileAccess.open("res://docs/OFFLINE-BOTS-1.1/edge-results.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"environment":"desktop headless common authority fixtures"},"  "));file.close()
 print("OFFLINE EDGE CASES ",checks," checks / ",failures," failures");quit(1 if failures else 0)
