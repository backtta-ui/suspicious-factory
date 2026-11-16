extends "res://scripts/seal/server.gd"
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:run.call_deferred()
func _process(_delta: float) -> bool:return false
func run() -> void:
 var room:=Rules.new("777777",10)
 for i in range(6):
  var id: String="%032d"%i;var uid: String=id.sha256_text().left(16)
  identities[id]={"uid":uid,"hash":"a".repeat(64),"wins":9};room.add(uid,"도사",[]);room.players[uid].ready=true
 room.start(room.host)
 var winner:="daoist";room.result(winner,"서버 테스트")
 settle(room)
 for id in identities:
  var row: Dictionary=identities[id];var expected:=10 if room.players[row.uid].role==winner else 9
  check(row.wins==expected,"server awards a win only to actual winning role")
 settle(room)
 check(identities.values().filter(func(p: Dictionary)->bool:return int(p.wins)==10).size()==4,"repeated result settlement cannot duplicate wins")
 var disk=JSON.parse_string(FileAccess.get_file_as_string(CAREER_PATH))
 check(disk==JSON.parse_string(JSON.stringify(identities)),"server career totals and hashed authentication persist in server-only file")
 room.phase="lobby"
 for p in room.players.values():p.ready=true
 room.start(room.host);room.result("yokai","요괴 승리 테스트");settle(room)
 var total:=0
 for p in identities.values():total+=int(p.wins)
 check(total==60,"both teams' real victories count across separate rounds")
 print("SERVER REWARDS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
