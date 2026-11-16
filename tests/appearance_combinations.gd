extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const Fit=preload("res://scripts/wardrobe/compatibility.gd")
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
 var combos:=0
 for character in C.CHARACTERS:
  for hair in C.HAIRS:
   for hat in C.HATS:
    for outfit in C.OUTFITS:
     var look: Dictionary={"character":character,"hair":hair,"hat":hat,"outfit":outfit,"accessory":"none","color":C.OUTFITS[outfit].colors[0]}
     actor.cosmetic=look.duplicate();actor.update_sprite();actor.wardrobe_visual._process(0)
     var visual: WooWardrobeVisual=actor.wardrobe_visual
     var context: String=character+"/"+hair+"/"+hat+"/"+outfit
     check(visual.appearance==look,"appearance IDs preserved: "+context)
     check(actor.scale==Vector2.ONE and actor.sprite.scale==Vector2.ONE*.34,"no hat/character changes actor scale: "+context)
     check(actor.appearance_back.get_index()<actor.hero_rig.get_index() and actor.hero_rig.get_index()<visual.get_index(),"rear/body/front painter order: "+context)
     if visual.custom_head():
      var rear: Sprite2D=visual.pieces.hair_back;var front: Sprite2D=visual.pieces.hair_front
      check(rear.get_parent()==actor.appearance_back and front.get_parent()==visual,"back hair behind clothes: "+context)
      check(rear.region_rect!=front.region_rect and visual.pieces.face.texture==visual.Art.HEAD_PARTS,"separate clean face and hair parts: "+context)
      check(rear.scale==front.scale and (front.offset*front.scale).is_equal_approx(Fit.hair_rect(character).position),"hats never squeeze or reposition hair: "+context)
      check(front.material.get_shader_parameter("front") and rear.material.get_shader_parameter("front")==false,"eyes protected only in front hair: "+context)
     for facing in range(8):
      actor.facing=facing;actor.jump_height=12;actor.action_pose=facing;actor.action_left=.2;actor.pose_duration=.4
      visual._process(.016);actor.hero_rig._process(.016)
      check(visual.appearance==look and actor.cosmetic==look and visual.position.y==-12 and actor.appearance_back.position==visual.position and actor.hero_rig.position==visual.position,"pose/direction/jump preserve attachments: "+context+"/"+str(facing))
     if visual.custom_body():check(visual.pieces.left.position.x<0 and visual.pieces.right.position.x>0 and visual.pieces.left.position.y< -20,"sleeves pivot at shoulders: "+context)
     combos+=1
     if combos%32==0:await frames(1)
 actor.reset_action()
 for character in C.CHARACTERS:
  for accessory in C.ACCESSORIES:
   for color in C.COLORS:
    var look:=C.DEFAULT.duplicate();look.character=character;look.accessory=accessory;look.color=color
    actor.cosmetic=look;actor.wardrobe_visual._process(0)
    check(actor.wardrobe_visual.appearance==look,"accessory/color combination "+accessory+"/"+color)
    if accessory!="none":check((actor.wardrobe_visual.pieces.accessory.get_parent()==actor.appearance_back)==Fit.accessory_behind(accessory),"accessory front/back attachment "+accessory)
 check(Fit.HATS.fox.mode=="mask" and Fit.HATS.hood.mode=="hood","mask uses face rule distinct from crown/hood")
 actor.queue_free();await frames()
 # Actual existing UI, profile format, cancellation and plaza/adventure renderer.
 var profile:=Profile.new();profile.refresh({"completed":["fox_forest"],"loot_claims":["shrine_seal"]})
 var look:=C.DEFAULT.duplicate();look.character="yeonhwa";look.hair="silver";look.hat="hood";look.outfit="night";look.color="navy";look.accessory="ribbon"
 check(profile.equip(look)==OK,"equip owned independent slots")
 var original_owned: Array=profile.data.owned.duplicate()
 check(Profile.new().data.appearance==look and Profile.new().data.owned==original_owned,"existing version1 save retains appearance and unlocks")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.wardrobe=profile;game.start_game(false);await frames()
 check(game.player.cosmetic==look,"plaza uses saved common appearance")
 game.show_wardrobe();await frames()
 var screen: WooWardrobeScreen
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.slot="character";screen.select("muyeong");await frames()
 var expected:=look.duplicate();expected.character="muyeong"
 check(screen.draft==expected and screen.preview.cosmetic==expected,"character change retains hair/outfit/hat/charm/color")
 check(screen.preview.position.y-(50+30)*screen.preview.scale.y>=0 and screen.preview.position.y+4*screen.preview.scale.y<=300,"full-height preview jump and hat stay inside stage at one fixed scale")
 screen.close();await frames()
 check(profile.data.appearance==look and game.player.cosmetic==look,"cancel leaves both saved and live look unchanged")
 game.show_wardrobe();await frames()
 for child in game.get_children():
  if child is WooWardrobeScreen:screen=child
 screen.slot="character";screen.select("muyeong");screen.save_selection();await frames()
 check(profile.data.appearance==expected and game.player.cosmetic==expected,"save applies preview appearance to actual player")
 game.adventure.load_forest(false);await frames()
 check(game.player.cosmetic==expected and game.player.wardrobe_visual.appearance==expected,"adventure and plaza share renderer/data")
 check(profile.data.owned==original_owned and not profile.owned("outfit","dragon"),"rendering fix grants no locked items and loses no owned records")
 game.show_menu(false);game.queue_free();await frames()
 print("APPEARANCE COMBINATIONS: %d combinations, %d checks, %d failures"%[combos,checks,failures]);quit(1 if failures else 0)
