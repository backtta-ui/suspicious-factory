extends SceneTree
const Actor=preload("res://scripts/woo/actor.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const Direction=preload("res://scripts/wardrobe/direction.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/original/frames.json"))
 var source:=Image.load_from_file(manifest.source)
 for id in manifest.characters:
  var data: Dictionary=manifest.characters[id]
  var actor:=Actor.new();actor.cosmetic=C.base_appearance(id);root.add_child(actor);actor.set_physics_process(false)
  var visual=actor.wardrobe_visual
  for dir in range(4):
   actor.facing=Direction.FACING[dir];visual._process(0)
   var key: String=["front","back","left","right"][dir];var frame: Dictionary=data[key]
   var raw:=Image.load_from_file(frame.path);var r: Array=frame.source_rect
   check(raw.get_data()==source.get_region(Rect2i(r[0],r[1],r[2],r[3])).get_data(),"lossless original crop "+id+key)
   check(visual.uses_original and visual.original_direction==key and visual.original_sprite.texture.resource_path==frame.path,"correct actual full-body direction "+id+key)
   var sprite: Sprite2D=visual.original_sprite
   check(sprite.scale.x==sprite.scale.y and is_equal_approx(sprite.scale.x,float(data.scale)) and not sprite.flip_h,"uniform fixed scale without mirroring "+id+key)
   check(sprite.offset==-Vector2(frame.foot[0],frame.foot[1]),"foot pivot at actor ground origin "+id+key)
   check(visual.pieces.values().all(func(piece: Polygon2D)->bool:return not piece.visible) and not actor.sprite.visible,"no modular or legacy image mixing "+id+key)
   for pose in [0,3,5]:
    actor.action_pose=pose;actor.action_left=.2;actor.jump_height=12;visual._process(0)
    check(sprite.texture.resource_path==frame.path and visual.position.y==-12,"action keeps same original design and jump scale "+id+key)
  actor.queue_free();await process_frame
 print("ORIGINAL SPRITES: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
