extends SceneTree
const R=preload("res://scripts/survival/rules.gd")
const C=preload("res://scripts/survival/characters.gd")
var results: Array=[]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var arena:=preload("res://scripts/seal/arena.gd").new("seowon");arena.assets.clear();arena.cache.clear();var nav:=preload("res://scripts/simulation/navigation.gd").new(arena)
 for count in [6,8]:
  var r:=R.new(count+3)
  for i in range(count):r.add("human" if i==0 else str(i),"도사%d"%i,C.catalog("daoist")[i%4].id,C.catalog("yokai")[(i+1)%4].id)
  r.players.human.ready=true;r.start();r.ready_map()
  var bots: Array=[]
  for i in range(1,count):bots.append(preload("res://scripts/survival/bot.gd").new(r,nav,str(i),i))
  var decision:=0.0;var began:=Time.get_ticks_msec()
  for i in range(12100):
   r.tick(.05);decision+=.05
   if decision>=.35 and r.phase=="live":
    for bot in bots:bot.think(decision)
    decision=0
   if r.phase=="result":break
  var result: Dictionary={"players":count,"phase":r.phase,"time":r.elapsed,"winner":r.winner,"wall_ms":Time.get_ticks_msec()-began,"seals":r.events.filter(func(e: Dictionary)->bool:return e.kind=="seal").size(),"misses":r.events.filter(func(e: Dictionary)->bool:return e.kind=="miss").size(),"rescues":r.events.filter(func(e: Dictionary)->bool:return e.kind=="rescue").size(),"skills":r.events.filter(func(e: Dictionary)->bool:return e.kind=="skill").size()};results.append(result);print(result)
  if r.phase!="result":push_error("bots failed to end match");quit(1);return
 var f:=FileAccess.open("res://builds/survival-bot-matches.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close();print("SURVIVAL BOTS: 6/8 autonomous matches complete");quit()
