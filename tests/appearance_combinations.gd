extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const Art=preload("res://scripts/wardrobe/directional_art.gd")
const Direction=preload("res://scripts/wardrobe/direction.gd")
const Actor=preload("res://scripts/woo/actor.gd")
const Profile=preload("res://scripts/wardrobe/profile.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func frames(n: int=3) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var actor:=Actor.new();root.add_child(actor);actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0
 var visual: WooWardrobeVisual=actor.wardrobe_visual
 var combos:=0
 for character in C.CHARACTERS:
  for hair in C.HAIRS:
   for hat in C.HATS:
    for outfit in C.OUTFITS:
     var look:=C.base_appearance(character);look.hair=hair;look.hat=hat;look.outfit=outfit;look.color=C.OUTFITS[outfit].colors[0];look.color_override=look.color!=C.base_appearance(character).color;actor.cosmetic=look.duplicate()
     for direction in range(8):
      actor.facing=Direction.FACING[direction]
      for kind in ["core","actions"]:
       for row in range(4 if kind=="core" else 6):
        visual.pose_override=kind;visual.row_override=row;actor.jump_height=12 if row==3 else 0;visual._process(0)
        var context: String=character+"/"+hair+"/"+hat+"/"+outfit+"/"+str(direction)+kind+str(row)
        check(visual.appearance==look and actor.cosmetic==look,"pose never mutates look "+context)
        check(visual.direction==direction and visual.pose_set==kind and visual.pose_row==row and visual.position.y==-actor.jump_height,"whole body direction and ground height "+context)
        check(visual.uses_original,"all saved combinations use original renderer "+context)
        if visual.uses_original:
         var sprite: Sprite2D=visual.original_sprite
         check(sprite.visible and str(sprite.texture.resource_path).contains(character+"-"),"approved complete original source "+context)
         check(sprite.scale.x==sprite.scale.y and not sprite.flip_h and not sprite.flip_v,"original aspect and handedness preserved "+context)
        else:
         var body: Polygon2D=visual.pieces.body
         check(body.visible and body.texture!=null and body.polygon.size()>=4 and body.uv.size()==body.polygon.size(),"real directional body geometry "+context)
         check(str(body.texture.resource_path).contains("mascot/bodies-") and int(body.uv[0].y/64)==["woochi","yeonhwa","muyeong","hongryeon"].find(character),"selected-character SD atlas row "+context)
         check((visual.pieces.hair_back.visible if direction in [1,6,7] else visual.pieces.hair_front.visible),"directional hair attached "+context)
         if outfit!="basic":check(visual.pieces.outfit.visible and str(visual.pieces.outfit.texture.resource_path).contains(outfit+"_"+kind),"real garment motion source "+context)
         check(body.scale==Vector2.ONE,"modular pose never shrinks body "+context)
        check(actor.scale==Vector2.ONE,"pose never shrinks actor "+context)
     combos+=1
     if combos%16==0:await frames(1)
 for character in C.CHARACTERS:
  for accessory in C.ACCESSORIES:
   for color in C.COLORS:
    var look:=C.base_appearance(character);look.accessory=accessory;look.color=color;look.color_override=color!=C.base_appearance(character).color;actor.cosmetic=look;visual._process(0)
    check(visual.appearance==C.normalize(look),"accessory/color preserves character identity")
  actor.cosmetic=C.base_appearance(character);actor.facing=2;visual.row_override=0;visual.pose_override="core";visual._process(0)
  check(visual.uses_original and visual.original_sprite.visible and str(visual.original_sprite.texture.resource_path).contains(character+"-front"),"complete approved original retains selected character "+character)
  for outfit in C.OUTFITS:
   if Art.READY_OUTFITS.has(outfit):continue
   var look:=C.base_appearance(character);look.outfit=outfit;actor.cosmetic=look;visual._process(0)
   check(visual.effective.outfit=="basic" and actor.cosmetic.outfit==outfit and Art.pending(look)!="" and not Art.supported("outfit",outfit),"missing resources explicitly unavailable, stored IDs retained")
 # Read actual baked pixels: a bad source cut or oversized pose must not spill
 # into an adjacent cell even if its resource IDs and geometry are valid.
 for character in C.CHARACTERS:
  for kind in ["core","actions"]:
   var image: Image=Art.texture("base_"+character+"_"+kind).get_image()
   check(image.get_size()==Vector2i(640,640 if kind=="core" else 960),"canonical native canvas "+character+kind)
   for row in range(4 if kind=="core" else 6):
    for col in range(4):
     var clean:=true
     for pixel in range(160):
      for point in [Vector2i(col*160+pixel,row*160),Vector2i(col*160+pixel,row*160+159),Vector2i(col*160,row*160+pixel),Vector2i(col*160+159,row*160+pixel)]:
       if image.get_pixelv(point).a>.5:clean=false
     check(clean,"native pose fits cell without clipping "+character+kind+str(row)+"/"+str(col))
 check(Direction.resolve(1,0)==4 and Direction.resolve(1,3)==4 and Direction.resolve(5,1)==6,"real diagonal frames never fall back to cardinal columns")
 check(Direction.quantize(Vector2.from_angle(PI/8+.02),0)==0 and Direction.quantize(Vector2.from_angle(PI/8+.1),0)==1,"joystick angular hysteresis suppresses boundary flicker")
 actor.queue_free();await frames()
 # Migrate a genuine v1 single-character save without inventing other character looks.
 var legacy:=C.base_appearance("yeonhwa");legacy.hair="silver";legacy.hat="hood"
 var old:={"version":1,"appearance":legacy,"owned":["outfit:future_item","outfit:wind"],"server_wins":{"test":30}}
 var file:=FileAccess.open(Profile.PATH,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
 var profile:=Profile.new();profile.refresh({"completed":["fox_forest"],"loot_claims":["shrine_seal"]})
 check(profile.data.version==3 and profile.data.appearance==legacy and profile.appearance_for("yeonhwa")==legacy,"v1 appearance migrates only to its owner")
 check(profile.appearance_for("muyeong")==C.base_appearance("muyeong") and profile.appearance_for("woochi")==C.DEFAULT,"other characters start from complete own defaults")
 var mu:=C.base_appearance("muyeong");mu.hat="bamboo";check(profile.equip(mu)==OK,"independent Muyeong save")
 var restored:=Profile.new();check(restored.appearance_for("yeonhwa")==legacy and restored.appearance_for("muyeong")==mu and restored.data.owned.has("outfit:future_item") and restored.data.owned.has("outfit:wind") and restored.data.verified_wins==30,"save/reload preserves both looks, unknown ownership and verified wins")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.wardrobe=profile;game.start_game(false);await frames()
 check(game.player.cosmetic==mu,"plaza uses active saved appearance")
 game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.slot="character";screen.select("yeonhwa");await frames();check(screen.draft==legacy and screen.preview.cosmetic==legacy,"switch restores that character's saved look")
 screen.select("hongryeon");await frames();check(screen.draft==C.base_appearance("hongryeon"),"unsaved character uses own complete defaults")
 screen.slot="hair";screen.select("short");var draft:=screen.draft.duplicate();screen.slot="character";screen.select("yeonhwa");screen.select("hongryeon");check(screen.draft==draft,"unsaved editor drafts remain per-character without writing save")
 screen.close();await frames();check(profile.data.appearance==mu and game.player.cosmetic==mu and profile.appearance_for("hongryeon")==C.base_appearance("hongryeon"),"cancel does not save temporary drafts or change live actor")
 game.show_wardrobe();await frames()
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.slot="character";screen.select("yeonhwa");screen.save_selection();await frames();check(game.player.cosmetic==legacy and Profile.new().data.appearance==legacy and Profile.new().appearance_for("muyeong")==mu,"save applies preview to real game without overwriting another character")
 game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal()
 check(game.adventure.load_forest(false),"real painting anchor permits forest entry");await frames()
 check(game.adventure.in_mission and game.player.get_parent()==game.adventure.forest and game.player.cosmetic==legacy and game.player.wardrobe_visual.appearance==legacy,"actual forest instance shares appearance renderer")
 game.show_menu(false);game.queue_free();await frames()
 print("APPEARANCE COMBINATIONS: %d stored combinations / %d checks / %d failures"%[combos,checks,failures]);quit(1 if failures else 0)
