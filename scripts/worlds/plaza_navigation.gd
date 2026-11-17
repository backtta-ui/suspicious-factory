class_name WooStoryNavigation
extends WooNpcNavigation
const StoryLayout=preload("res://scripts/worlds/plaza_layout.gd")
func _init() -> void:
 graph.clear()
 for i in range(Data.POINTS.size()):graph.add_point(i,Data.POINTS[i])
 for edge in preload("res://scripts/worlds/plaza_nav_edges.gd").EDGES:graph.connect_points(edge[0],edge[1])
func segment_clear(a: Vector2,b: Vector2) -> bool:
 var count:=ceili(a.distance_to(b)/10)
 for i in range(count+1):
  if not StoryLayout.can_stand(a.lerp(b,float(i)/maxi(count,1)),8):return false
 return true
func closest_accessible(p: Vector2) -> int:
 var candidates:=[]
 for i in range(Data.POINTS.size()):
  var distance: float=p.distance_squared_to(Data.POINTS[i])
  if distance<150*150:candidates.append([distance,i])
 candidates.sort_custom(func(a: Array,b: Array)->bool:return a[0]<b[0])
 for entry in candidates.slice(0,12):
  if segment_clear(p,Data.POINTS[entry[1]]):return entry[1]
 return -1
func route(from: Vector2,to: Vector2) -> PackedVector2Array:
 queries+=1
 var start:=closest_accessible(from);var end:=closest_accessible(to)
 if start<0 or end<0:return PackedVector2Array()
 var path:=graph.get_point_path(start,end)
 if path.is_empty():return path
 if segment_clear(path[-1],to):path.append(to)
 return path
