extends RefCounted
## Collision-tested shared graph; paths recompute only when a bot changes its goal.
var graph:=AStar2D.new()
var cells: Dictionary={}
var arena: SealArena
const STEP=56
func _init(source: SealArena,synchronous: bool=true) -> void:
 arena=source
 if synchronous:build()
func build(tree: SceneTree=null) -> void:
 var bounds: Vector2=arena.data.size
 for y in range(1,int(bounds.y/STEP)):
  if tree!=null and y%4==0:await tree.process_frame
  for x in range(1,int(bounds.x/STEP)):
   var p:=Vector2(x*STEP,y*STEP)
   if arena.can_stand(p):
    var id:=graph.get_point_count();cells[Vector2i(x,y)]=id;graph.add_point(id,p)
 var batch:=0
 for cell in cells:
  batch+=1
  if tree!=null and batch%100==0:await tree.process_frame
  for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
   var other: Vector2i=cell+offset
   if not cells.has(other):continue
   var a:=graph.get_point_position(cells[cell]);var b:=graph.get_point_position(cells[other])
   if clear(a,b):graph.connect_points(cells[cell],cells[other])
func clear(a: Vector2,b: Vector2) -> bool:
 var n:=maxi(1,ceili(a.distance_to(b)/6))
 for i in range(n+1):
  if not arena.can_stand(a.lerp(b,float(i)/n)):return false
 return true
func path(a: Vector2,b: Vector2) -> PackedVector2Array:
 if clear(a,b):return PackedVector2Array([b])
 var start: int=graph.get_closest_point(a);var end: int=graph.get_closest_point(b)
 if start<0 or end<0:return PackedVector2Array()
 var result:=graph.get_point_path(start,end)
 if not result.is_empty() and clear(result[-1],b):result.append(b)
 return result
