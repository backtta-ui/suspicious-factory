extends SceneTree
const Save = preload("res://scripts/woo/save_game.gd")
const Layout = preload("res://scripts/woo/village_layout.gd")
var checks := 0
var failures := 0
func check(ok: bool, detail: String) -> void:
	checks+=1
	if ok: print("PASS: "+detail)
	else: failures+=1;push_error("FAIL: "+detail)
func _initialize() -> void:
	var state := {"schema":1,"map":Layout.MAP_ID,"position":[900,610],"settings":{"smooth_camera":true,"day_cycle":true},"unlocked":["jar"],"jar":false,"time_of_day":0.22}
	check(Save.save_game(state)==OK,"first atomic save")
	state.position=[932,610]
	check(Save.save_game(state)==OK,"second save keeps backup")
	var file:=FileAccess.open(Save.PATH,FileAccess.WRITE)
	file.store_string("invalid incomplete JSON");file.close()
	var recovered:=Save.load_game()
	print("Recovered position: ",recovered.get("position",[]))
	check(not recovered.is_empty() and Vector2(recovered.position[0],recovered.position[1])==Vector2(900,610),"corrupt primary recovers previous valid save")
	state.position=[916,610]
	check(Save.save_game(state)==OK,"new save after recovery")
	var backup:=Save.read_valid(Save.PATH+".bak")
	check(not backup.is_empty() and Vector2(backup.position[0],backup.position[1])==Vector2(900,610),"corrupt primary cannot overwrite valid backup")
	state.time_of_day={"bad":1}
	check(not Save.valid(state),"malformed atmosphere data rejected")
	state.time_of_day=0.22;state.unlocked=[{"bad":1}]
	check(not Save.valid(state),"malformed spell state rejected")
	state.unlocked=["jar"];state.position=[0,0]
	check(Save.save_game(state)==ERR_INVALID_DATA,"invalid position does not overwrite good save")
	check(not Save.load_game().is_empty(),"good save preserved after invalid write request")
	print("SAVE RECOVERY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
