extends SceneTree
const Actor=preload("res://scripts/woo/actor.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/directional_art.gd")
const D=preload("res://scripts/wardrobe/direction.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var actor:=Actor.new();root.add_child(actor);actor.set_physics_process(false)
 var visual=actor.wardrobe_visual
 for char in C.CHARACTERS:
  for color in C.COLORS:
   for accessory in C.ACCESSORIES:
    var look:=C.base_appearance(char);look.color=color;look.color_override=color!=C.base_appearance(char).color;look.accessory=accessory;actor.cosmetic=look
    for dir in range(8):
     actor.facing=D.FACING[dir];visual._process(0)
     check(visual.uses_original and visual.original_sprite.texture.resource_path.contains(char+"-"),"every accessory/color retains approved native character")
     check(actor.cosmetic==look and visual.appearance==look,"selection is never rewritten to force native rendering")
     check(not actor.sprite.visible and visual.pieces.values().all(func(p: Polygon2D)->bool:return not p.visible or p==visual.pieces.accessory),"no bald body, old face, hair or hat compositor")
     var mat: ShaderMaterial=visual.original_sprite.material
     check(mat.get_shader_parameter("dye_enabled")== (color!=C.base_appearance(char).color),"actual cloth dye state tracks selected color")
     if visual.pieces.accessory.visible:
      var points: PackedVector2Array=visual.pieces.accessory.polygon;var left:=INF;var right:=-INF
      for point in points:left=minf(left,point.x);right=maxf(right,point.x)
      check(right-left<=5.01,"accessory width follows native-body scale")
  for direction in ["front","back","left","right"]:
   var mask: Texture2D=load("res://assets/woo/mascot/original/"+char+"-"+direction+"-dye.png");var image:=mask.get_image();var protected:=true
   for y in range(int(image.get_height()*.60)):
    for x in range(image.get_width()):
     if image.get_pixel(x,y).a>0:protected=false
   check(protected,"color mask never touches original face, hair or hat")
 var look:=C.DEFAULT.duplicate();look.hair="silver";look.hat="bamboo";look.outfit="moon"
 check(Art.pending(look)!="" and Art.effective(look).hat==C.DEFAULT.hat and look.hat=="bamboo","incompatible saved parts explicitly pending without deleting selection")
 check(not Art.supported("hat","bamboo","woochi") and Art.supported("hat","gat","woochi"),"UI compatibility distinguishes native and unavailable headwear")
 actor.queue_free();await process_frame
 print("CUSTOM ORIGINAL: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
