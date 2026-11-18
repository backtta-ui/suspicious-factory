extends SceneTree
## 지도 수치 검수: layout.gd의 새 3400x2600 지도에서
## 1) 담장·건물·대나무·연못이 서로 겹쳐 그림이 깨지는 곳,
## 2) 둔갑 사물·문·스폰이 설 수 없는 곳에 놓인 것,
## 3) 중앙 마당에서 걸어 닿지 못하는 구역이 있는지
## 를 한 번에 확인한다. 사용:
## godot --headless --path . --script res://tools/validate_map.gd
const L=preload("res://scripts/survival/layout.gd")
var failures:=0
var step:=20.0
func fail(message: String) -> void:
 failures+=1
 print("FAIL ",message)
func overlap(a: Rect2,b: Rect2) -> bool:
 return a.intersects(b,false)
func _initialize() -> void:
 print("MAP ",L.SIZE," spawn ",L.SPAWN)
 # 1) 겹침: 건물 본체 vs 담장/대나무/연못
 for building in L.buildings():
  var rect: Rect2=building.rect
  for entry in L.WALLS:
   if overlap(rect.grow(-2),entry):
    fail("wall inside %s at %s" % [building.id,entry])
  for entry in L.BAMBOO:
   if overlap(rect.grow(-2),entry):
    fail("bamboo inside %s at %s" % [building.id,entry])
  if overlap(rect.grow(-2),L.POND):
   fail("pond inside %s" % building.id)
  if overlap(rect.grow(-2),L.STONE):
   fail("stone plaza inside %s" % building.id)
 for i in range(L.buildings().size()):
  for j in range(i+1,L.buildings().size()):
   var a: Rect2=L.buildings()[i].rect
   var b: Rect2=L.buildings()[j].rect
   if overlap(a.grow(-2),b.grow(-2)):fail("buildings overlap %s/%s" % [L.buildings()[i].id,L.buildings()[j].id])
 for entry in L.WALLS:
  if overlap(entry,L.POND):fail("wall in pond at %s" % entry)
  if overlap(entry,L.STONE):fail("wall on the central plaza at %s" % entry)
  for k in L.BAMBOO:
   if overlap(entry,k):fail("wall in bamboo at %s" % entry)
 # 2) 사물·문·스폰이 설 수 있는 자리인가
 for object in L.OBJECTS:
  if not L.can_stand(object.p,9):fail("object %s at %s not standable" % [object.kind,object.p])
 for building in L.buildings():
  var door: Vector2=(building.doors as Dictionary).front
  if not L.can_stand(door+Vector2(0,14),9):fail("door approach %s" % building.id)
  if not L.can_stand((building.interior as Rect2).get_center(),9):fail("interior %s" % building.id)
  var back: Vector2=(building.doors as Dictionary).back
  if not L.can_stand(back+Vector2(0,-14),9):fail("back door approach %s" % building.id)
 for p in L.ORBS:if not L.can_stand(p,9):fail("stamina orb %s" % p)
 for p in L.daoist_spawns():if not L.can_stand(p,9):fail("daoist spawn %s" % p)
 for p in L.yokai_spawns():if not L.can_stand(p,9):fail("yokai spawn %s" % p)
 # 3) 걸어서 닿는가: 20px 격자 BFS
 var cols:=int(L.SIZE.x/step)+1
 var rows:=int(L.SIZE.y/step)+1
 var free:=PackedByteArray();free.resize(cols*rows)
 for y in range(rows):
  for x in range(cols):
   free[y*cols+x]=1 if L.can_stand(Vector2(x*step+step*.5,y*step+step*.5),9) else 0
 var seen:=PackedByteArray();seen.resize(cols*rows)
 var start:=Vector2i(int(L.SPAWN.x/step),int(L.SPAWN.y/step))
 if free[start.y*cols+start.x]==0:fail("spawn cell not free")
 var queue: Array=[start];seen[start.y*cols+start.x]=1
 var reached:=0
 while not queue.is_empty():
  var cell: Vector2i=queue.pop_back();reached+=1
  for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
   var n: Vector2i=cell+d
   if n.x<0 or n.y<0 or n.x>=cols or n.y>=rows:continue
   if seen[n.y*cols+n.x]==1 or free[n.y*cols+n.x]==0:continue
   seen[n.y*cols+n.x]=1;queue.append(n)
 var total:=0
 for i in range(free.size()):total+=free[i]
 print("REACH %d / %d free cells (%.1f%%)" % [reached,total,100.0*reached/maxf(1,total)])
 if reached<total*.98:fail("connectivity leaves %d cells cut off" % (total-reached))
 var unreachable:=0
 for object in L.OBJECTS:
  var cell:=Vector2i(int(object.p.x/step),int(object.p.y/step))
  var ok:=false
  for dy in range(-2,3):
   for dx in range(-2,3):
    var n:=Vector2i(cell.x+dx,cell.y+dy)
    if n.x<0 or n.y<0 or n.x>=cols or n.y>=rows:continue
    if seen[n.y*cols+n.x]==1:ok=true
  if not ok:unreachable+=1;print("  object isolated ",object.kind," ",object.p)
 if unreachable>0:fail("%d objects unreachable" % unreachable)
 for building in L.buildings():
  var cell:=Vector2i(int(((building.doors as Dictionary).front as Vector2).x/step),int(((building.doors as Dictionary).front as Vector2).y/step))
  var ok:=false
  for dy in range(-2,3):
   for dx in range(-2,3):
    var n:=Vector2i(cell.x+dx,cell.y+dy)
    if n.x<0 or n.y<0 or n.x>=cols or n.y>=rows:continue
    if seen[n.y*cols+n.x]==1:ok=true
  if not ok:fail("door unreachable %s" % building.id)
 # 스폰 거리
 for y in L.yokai_spawns():
  for d in L.daoist_spawns():
   if y.distance_to(d)<L.SPAWN_SEPARATION:fail("spawn separation %.0f < %.0f" % [y.distance_to(d),L.SPAWN_SEPARATION])
 print("MAP VALIDATION: ",failures," failures")
 quit(1 if failures>0 else 0)
