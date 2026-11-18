extends SceneTree
## 서원 지도 수치(layout.gd)를 JSON으로 내보낸다.
## 바닥 원화(tools/bake_seowon_ground.py)가 이동 가능 영역·충돌·문 좌표를
## layout.gd와 1:1로 맞출 수 있도록, 유일한 원본인 layout.gd에서 직접 뽑는다.
## 사용: godot --headless --path . --script res://tools/export_seowon_geometry.gd -- <출력 경로>
const L=preload("res://scripts/survival/layout.gd")
const Art=preload("res://scripts/survival/seowon_art.gd")
func rect(r: Rect2) -> Array:
 return [r.position.x,r.position.y,r.size.x,r.size.y]
func vec(v: Vector2) -> Array:
 return [v.x,v.y]
func pad(r: Rect2,by: float) -> Array:
 var out:=r.grow(by)
 return rect(out)
func _initialize() -> void:
 var args:=OS.get_cmdline_user_args()
 var path:=String(args[0]) if args.size()>0 else "res://builds/seowon_geometry.json"
 var data: Dictionary={
  "size":vec(L.SIZE),
  "walk":rect(Rect2(Vector2(60,70),L.SIZE-Vector2(120,140))),
  "stand_margin":9.0,
  "pond":rect(L.POND),
  "bridge":{"a":vec(L.BRIDGE_A),"b":vec(L.BRIDGE_B),"half":L.BRIDGE_HALF,"rise":L.BRIDGE_RISE},
  "medallion":vec(L.MEDALLION),
  "medallion_radius":L.MEDALLION_RADIUS,
  "stone":rect(L.STONE),
  "hard":[],
  "low":[],
  "bamboo":[],
  "furniture":[],
  "walls":[],
  "buildings":[],
  "doors":[],
  "lanterns":[],
  "trees":[],
  "objects":[],
  "path":[]}
 for r in L.HARD:data.hard.append(rect(r))
 for r in L.LOW:data.low.append(rect(r))
 for r in L.BAMBOO:data.bamboo.append(rect(r))
 for r in L.FURNITURE:data.furniture.append(rect(r))
 for r in L.WALLS:data.walls.append(rect(r))
 for b in L.buildings():
  data.buildings.append({"id":String(b.id),"name":String(b.name),"rect":rect(b.rect),"interior":rect(b.interior),
   "door":vec((b.doors as Dictionary).front),"back":vec((b.doors as Dictionary).back),"painted_door":vec(b.painted_door)})
 for d in L.DOORS:
  data.doors.append({"id":String(d.id),"center":vec(d.center),"side":String(d.side)})
 for p in Art.LANTERNS:data.lanterns.append(vec(p))
 for p in Art.TREES:data.trees.append(vec(p))
 for o in L.OBJECTS:data.objects.append({"kind":String(o.kind),"p":vec(o.p)})
 for p in L.PATH:data.path.append(vec(p))
 var file:=FileAccess.open(path,FileAccess.WRITE)
 if file==null:
  printerr("cannot write ",path);quit(1);return
 file.store_string(JSON.stringify(data," "))
 file.close()
 print("SEOWON GEOMETRY WRITTEN ",path)
 quit()
