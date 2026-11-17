extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const P=preload("res://scripts/wardrobe/profile.gd")
const D=preload("res://scripts/wardrobe/direction.gd")
const Actor=preload("res://scripts/woo/actor.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func run() -> void:
 var old:=C.base_appearance("yeonhwa");old.erase("color_override");old.color="green"
 var file:=FileAccess.open(P.PATH,FileAccess.WRITE);file.store_string(JSON.stringify({"version":2,"appearance":old,"per_character":{"yeonhwa":old},"owned":["outfit:future"],"verified_wins":0}));file.close()
 var p:=P.new()
 check(p.data.appearance.color=="pink" and not p.data.appearance.color_override,"legacy implicit green restores original pink")
 check(p.data.legacy_appearance_v2.appearance.color=="green" and p.data.owned.has("outfit:future"),"legacy appearance and unknown ownership preserved in migration backup")
 for slot in ["hair","hat","outfit","accessory"]:
  for id in C.table(slot):check(p.owned(slot,id),"every cosmetic acquisition unlocked "+slot+id)
 check(not p.owned("character","muyeong"),"character adventure unlock rules unchanged")
 var green:=C.base_appearance("yeonhwa");green.color="green";green.color_override=true
 check(p.equip(green)==OK and P.new().appearance_for("yeonhwa")==green,"direct color choice survives save reload")
 check(p.appearance_for("woochi").color=="navy" and not p.appearance_for("woochi").color_override,"character-specific color never leaks")
 for slot in ["hair","hat","outfit","accessory"]:
  for id in C.table(slot):
   var look:=C.base_appearance("woochi");look[slot]=id
   check(p.equip(look)==OK,"all owned cosmetic IDs save without purchase, level or currency gates")
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/original/frames.json"))
 var actor:=Actor.new();root.add_child(actor);actor.set_physics_process(false)
 for char in C.CHARACTERS:
  actor.cosmetic=C.base_appearance(char)
  for dir in range(8):
   actor.facing=D.FACING[dir];actor.gait_weight=1;actor.velocity=Vector2.from_angle(actor.facing*PI/4)*88;actor.gait_phase=PI/2;actor.wardrobe_visual._process(0)
   var visual=actor.wardrobe_visual;var rig=visual.locomotion
   if dir>=4:
    var rectangle: Array=visual.current_frame.source_rect
    var row:=floori((float(rectangle[1])+float(rectangle[3])*.5)/float(manifest.extension_size[1])*4)
    check(row==["woochi","yeonhwa","muyeong","hongryeon"].find(char),"diagonal crop cannot select another character row")
   check(visual.original_direction==["front","back","left","right","front_right","front_left","back_left","back_right"][dir],"actual eight-direction source "+char+str(dir))
   check(rig.visible and not visual.original_sprite.visible and rig.foot_nodes.size()==2 and rig.leg_nodes.size()==2,"walking uses articulated skin and two actual boot layers")
   var head_a: Vector2=rig.deform(Vector2(-4,-40))-Vector2(-4,-40);var head_b: Vector2=rig.deform(Vector2(4,-40))-Vector2(4,-40)
   check(head_a.distance_to(head_b)<.001,"head proportions stay rigid")
   var before: Vector2=rig.foot_nodes[0].position-rig.foot_nodes[1].position
   rig.animate(PI*1.5,1,false,actor.facing)
   check(before.distance_to(rig.foot_nodes[0].position-rig.foot_nodes[1].position)>1,"feet move in opposite phases, not whole-image bob")
   rig.animate(PI/2,1,false,actor.facing)
   var forward_position: Vector2=rig.foot_nodes[1].position-rig.foot_rest[1]
   var expected: Vector2=Vector2.from_angle(actor.facing*PI/4)*1.3
   if rig.foot_copied:expected+=Vector2(-rig.heading.y,rig.heading.x)*-1
   check(forward_position.distance_to(expected)<.001,"forward foot lands instead of lifting at maximum stride")
   for i in range(2):
    var ankle: Vector2=rig.foot_nodes[i].position+Vector2(rig.foot_nodes[i].texture.get_width()*.5,0)*rig.unit_scale
    check(rig.leg_nodes[i].points[2].distance_to(ankle)<.001,"leg remains connected to animated footwear")
    check(rig.leg_nodes[i].z_index==0 and rig.foot_nodes[i].z_index==0,"limb layer order stays inside character group, above UI background")
   var walk_pose: PackedVector2Array=rig.polygon;rig.animate(PI/2,1,true,actor.facing)
   check(rig.polygon!=walk_pose,"running has distinct skin pose")
   rig.animate(0,0,false,actor.facing);check(rig.polygon==rig.rest,"stop restores exact neutral geometry")
 actor.gait_weight=0;actor.gait_phase=0;actor.running=false;actor.intent=Vector2(1,1).normalized();actor.position=Vector2(100,100);actor.enabled=true;actor.set_physics_process(true)
 var start: Vector2=actor.position
 for i in range(20):await physics_frame
 check(absf(actor.velocity.length()-Actor.WALK_SPEED)<.05,"diagonal walk normalizes speed")
 check(absf(actor.gait_phase-start.distance_to(actor.position)*.13)<.03,"gait clock follows actual world displacement")
 actor.running=true
 for i in range(15):await physics_frame
 check(absf(actor.velocity.length()-Actor.RUN_SPEED)<.05,"running accelerates to existing configured speed")
 var facing_before: int=actor.facing;actor.intent=Vector2.ZERO
 for i in range(25):await physics_frame
 await process_frame
 check(actor.velocity.length()<.01 and actor.gait_weight<.01 and actor.facing==facing_before,"stop ends limb motion and retains final direction")
 actor.intent=Vector2(1,-1).normalized()*.1
 for i in range(12):await physics_frame
 check(actor.facing==7,"low-strength diagonal input updates full-body facing consistently")
 actor.queue_free();await frames()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.wardrobe=p;game.start_game(false);await frames();game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.slot="character";screen.select("woochi");screen.slot="color";screen.select("green");screen.slot="character";screen.select("yeonhwa")
 check(screen.draft==green,"switching restores only that character's explicit saved color")
 screen.slot="character";screen.select("hongryeon");check(screen.draft.color=="red" and not screen.draft.color_override,"new character restores native color")
 screen.slot="character";screen.select("woochi")
 for slot in ["hair","hat","outfit","accessory","color"]:
  screen.slot=slot;screen.refresh();await frames()
  for button in screen.list.get_children():
   check(not button.disabled,"all cosmetic cards selectable without acquisition gating")
   check(button.size.x<=160 and button.get_global_rect().end.x<=game.get_viewport().get_visible_rect().size.x-10,"invisible button titles cannot push last column offscreen")
 game.queue_free();await frames()
 print("MOTION/CUSTOM V14: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
