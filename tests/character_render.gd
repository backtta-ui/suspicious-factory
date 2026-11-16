extends SceneTree
const C=preload("res://scripts/wardrobe/catalog.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
var actors: Array=[]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var bg:=ColorRect.new();bg.size=Vector2(1280,720);bg.color=Color("162132");bg.z_index=-4096;root.add_child(bg)
 var mode:="directions"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--view="):mode=arg.trim_prefix("--view=")
 var chars: Array=C.CHARACTERS.keys();var facing: Array=[2,6,4,0]
 for row in range(4):
  for col in range(4):
   var actor:=preload("res://scripts/woo/actor.gd").new();actor.cosmetic=C.base_appearance(chars[row]);actor.position=Vector2(160+320*col,155+180*row);actor.scale=Vector2.ONE*2.5;actor.facing=facing[col]
   if mode=="custom":
    actor.facing=2
    if col==1:actor.cosmetic.hair="silver";actor.cosmetic.hat="hood"
    if col==2:actor.cosmetic.outfit="moon";actor.cosmetic.color="white";actor.cosmetic.hat="gat"
    if col==3:actor.cosmetic.outfit="night";actor.cosmetic.color="black_gold";actor.cosmetic.hat="bamboo";actor.cosmetic.accessory="gourd"
   if mode=="custom-directions":
    actor.cosmetic.hair=["long","silver","tied","flower"][row];actor.cosmetic.hat=["bamboo","hood","fox","crown"][row];actor.cosmetic.outfit="moon" if row%2==0 else "night";actor.cosmetic.color="white" if row%2==0 else "black_gold"
   root.add_child(actor);actor.set_physics_process(false);actor.collision_layer=0;actor.collision_mask=0;actor.update_sprite();actors.append(actor)
   if mode=="walk":actor.wardrobe_visual.row_override=1 if col%2==0 else 2;actor.wardrobe_visual.pose_override="core"
   if mode=="actions":actor.wardrobe_visual.row_override=col;actor.wardrobe_visual.pose_override="actions"
   var label:=Label.new();label.text=C.CHARACTERS[chars[row]].name+" · "+str(["정면","후면","왼쪽","오른쪽"][col] if mode!="custom" else actor.cosmetic.outfit+" / "+actor.cosmetic.hat);label.position=Vector2(16+320*col,156+180*row);label.add_theme_font_override("font",FONT);label.add_theme_font_size_override("font_size",16);root.add_child(label)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 var error:=root.get_texture().get_image().save_png("res://builds/characters-"+mode+".png");print("CHARACTER RENDER ",mode," ",error)
 for child in root.get_children():child.queue_free()
 for i in range(3):await process_frame
 quit(0 if error==OK else 1)
