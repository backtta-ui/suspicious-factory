extends SceneTree
const Layout=preload("res://scripts/woo/village_layout.gd")
func _initialize() -> void:run.call_deferred()
func clear_line(a: Vector2,b: Vector2) -> bool:
 var n:=ceili(a.distance_to(b)/8)
 for i in range(n+1):
  if not Layout.can_stand(a.lerp(b,float(i)/maxi(n,1)),10):return false
 return true
func run() -> void:
 var points:=[];var ids: Dictionary={};var edges:=[]
 for x in range(40,3361,64):
  for y in range(40,1861,64):
   var p:=Vector2(x,y)
   if Layout.can_stand(p,12):ids[Vector2i(x,y)]=points.size();points.append(p)
 for p in points:
  for offset in [Vector2(64,0),Vector2(0,64),Vector2(64,64),Vector2(-64,64)]:
   var q: Vector2=p+offset
   if ids.has(Vector2i(q)) and clear_line(p,q):edges.append([ids[Vector2i(p)],ids[Vector2i(q)]])
 var out:=FileAccess.open("res://scripts/woo/npc_nav_data.gd",FileAccess.WRITE)
 out.store_string("extends RefCounted\n# Baked against Layout revision %d; no per-frame path baking.\nconst POINTS = [\n" % Layout.REVISION)
 for p in points:out.store_string("Vector2(%d,%d)," % [p.x,p.y])
 out.store_string("\n]\nconst EDGES = "+str(edges)+"\n");out.close()
 print("NPC NAV BAKE: ",points.size()," points, ",edges.size()," clear edges");quit()
