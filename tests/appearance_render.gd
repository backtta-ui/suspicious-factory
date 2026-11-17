extends SceneTree
const Actor=preload("res://scripts/woo/actor.gd")
const Catalog=preload("res://scripts/wardrobe/catalog.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var actors: Array=[]
func frames(n: int=6) -> void:
 for i in range(n):await process_frame
func _initialize() -> void:run.call_deferred()
func label(value: String,p: Vector2) -> void:
 var text:=Label.new();text.text=value;text.position=p;text.add_theme_font_override("font",FONT);text.add_theme_font_size_override("font_size",15);root.add_child(text)
func run() -> void:
 root.size=Vector2i(1280,720)
 var bg:=ColorRect.new();bg.size=Vector2(1280,720);bg.color=Color("172132");bg.z_index=-4096;root.add_child(bg)
 var phase:="before"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--phase="):phase=arg.trim_prefix("--phase=")
 if phase in ["game","game-jump","plaza","forest"]:
  var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.start_game(false);await frames()
  var look:=Catalog.DEFAULT.duplicate();look.character="yeonhwa";look.hair="silver";look.hat="hood";look.color="purple";look.color_override=true
  game.wardrobe.equip(look);game.player.cosmetic=look
  if phase in ["game","game-jump"]:
   game.show_wardrobe();await frames()
   if phase=="game-jump":
    for child in game.get_children():
     if child is WooWardrobeScreen:child.set_process(false);child.preview.jump_height=30;child.preview.jump_phase="apex";child.preview.update_sprite()
  elif phase=="forest":
   game.player.position=Vector2(1690,395);game.show_painting_intro(0);game.close_modal()
   if not game.adventure.load_forest(false):push_error("Forest capture entry failed");quit(1);return
   await frames()
 elif phase=="gallery":
  var combinations: Array=[]
  for character in Catalog.CHARACTERS:
   for hair in Catalog.HAIRS:
    for hat in Catalog.HATS:
     for outfit in Catalog.OUTFITS:combinations.append({"character":character,"hair":hair,"hat":hat,"outfit":outfit,"accessory":"none","color":Catalog.OUTFITS[outfit].colors[0]})
  for page in range(ceili(combinations.size()/128.0)):
   var group:=Node2D.new();root.add_child(group)
   for i in range(128):
    var index:=page*128+i
    if index>=combinations.size():break
    var actor:=Actor.new();actor.cosmetic=combinations[index];actor.position=Vector2(40+(i%16)*80,75+(i/16)*90);actor.scale=Vector2(1.25,1.25);actor.facing=2;group.add_child(actor);actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0
   await frames();await RenderingServer.frame_post_draw
   var err:=root.get_texture().get_image().save_png("res://builds/appearance-gallery-%02d.png"%page)
   if err!=OK:quit(1);return
   group.queue_free();await frames(2)
  print("APPEARANCE GPU GALLERY: ",combinations.size()," actual actor renders / 11 pages")
  quit(0);return
 elif phase=="reference":
  var art:=preload("res://assets/woo/hd/hero.png")
  var sprite:=Sprite2D.new();sprite.texture=art;sprite.centered=false;sprite.region_enabled=true;sprite.region_rect=Rect2(384,694,192,158);sprite.position=Vector2(35,35);sprite.scale=Vector2(3,3);root.add_child(sprite)
  for i in range(4):
   var y: int=45+i*10;var part:=Sprite2D.new();part.texture=art;part.centered=false;part.region_enabled=true;part.region_rect=Rect2(384+85,694+y,55,42);part.position=Vector2(660+(i%2)*300,70+(i/2)*280);part.scale=Vector2(4,4);root.add_child(part);label("face source y="+str(y),part.position+Vector2(0,180))
 else:
  var variants: Array=[["black","gat","basic","navy"],["silver","hood","moon","white"],["long","bamboo","night","black_gold"],["flower","fox","wind","green"]]
  var chars: Array=Catalog.CHARACTERS.keys()
  for row in range(4):
   for col in range(4):
    var variant: Array=variants[col]
    if phase=="uncovered":variant=[Catalog.HAIRS.keys()[col],"none","basic","navy"]
    var actor:=Actor.new();actor.cosmetic={"character":chars[row],"hair":variant[0],"hat":variant[1],"outfit":variant[2],"color":variant[3],"accessory":"scroll" if phase=="poses" else "none"};actor.position=Vector2(155+col*320,154+row*180);actor.scale=Vector2(2.7,2.7);actor.facing=2;root.add_child(actor);actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0;actors.append(actor)
    if phase=="poses":
     actor.facing=[2,4,6,0][col];actor.jump_height=15 if col==2 else 0;actor.action_pose=col;actor.action_left=.2 if col==3 else 0;actor.pose_duration=.4;actor.gait_weight=1 if col==1 else 0;actor.gait_phase=1
    label(Catalog.CHARACTERS[chars[row]].name+" · "+str(variant[0])+" / "+str(variant[1]),Vector2(12+col*320,155+row*180))
 await frames();await RenderingServer.frame_post_draw
 var error:=root.get_texture().get_image().save_png("res://builds/appearance-"+phase+".png")
 print("APPEARANCE CAPTURE ",phase," error=",error)
 for child in root.get_children():child.queue_free()
 await frames(2);quit(0 if error==OK else 1)
