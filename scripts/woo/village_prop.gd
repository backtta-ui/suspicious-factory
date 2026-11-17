class_name WooVillageProp
extends StaticBody2D
const Layout=preload("res://scripts/woo/village_layout.gd")
const OLD=preload("res://assets/woo/hd/environment.png")
const NEW=preload("res://assets/woo/v11/village_atlas.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
var kind: String="tree"
var variant:=0
var display_name: String=""
var light: Sprite2D
var story_count:=0
var memory_glow: Node2D
func _ready() -> void:
 collision_layer=1;collision_mask=2
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var poly:=Layout.footprint(kind)
 if not poly.is_empty():
  var collider:=CollisionPolygon2D.new();collider.polygon=poly;add_child(collider)
 elif Layout.radius(kind)>0:
  var collider:=CollisionShape2D.new();var shape:=CircleShape2D.new();shape.radius=Layout.radius(kind);collider.shape=shape;add_child(collider)
 if kind in ["bridge","bench"]:return
 if kind=="great_tree":
  memory_glow=Node2D.new();memory_glow.z_index=1;memory_glow.draw.connect(draw_memories);add_child(memory_glow)
 var sheet: Texture2D=OLD
 var index:=0;var width:=150.0;var cell:=Vector2(512,512);var foot:=460.0
 match kind:
  "hanok":index=variant if variant>0 else (0 if position.x<900 else 1)
  "well":index=2;width=85
  "market":index=3;width=128
  "tree":index=4;width=150
  "lantern":index=5;width=90
  "tavern","magic_shop","shrine","pavilion","great_tree","bamboo":
   sheet=NEW
   index=["tavern","magic_shop","shrine","pavilion","great_tree","bamboo"].find(kind)
   width=170 if kind in ["tavern","magic_shop","shrine"] else (220 if kind=="great_tree" else (180 if kind=="pavilion" else 110))
   foot=490
   if variant==1 and kind in ["tavern","magic_shop"]:width=150
   if kind=="hanok" and variant==1:width=140
  "painting","food","cart","jars","dummy","stone_lantern":
   sheet=DECOR;cell=Vector2(DECOR.get_width()/3.0,DECOR.get_height()/3.0)
   index=variant if kind=="painting" else {"food":3,"cart":4,"jars":5,"dummy":6,"stone_lantern":7}.get(kind,0)
   width={"painting":115,"food":145,"cart":95,"jars":55,"dummy":65,"stone_lantern":52}.get(kind,100)
   foot=cell.y-12
 var sprite:=Sprite2D.new();sprite.texture=sheet;sprite.region_enabled=true
 sprite.region_rect=Rect2(Vector2(index%3,floori(float(index)/3))*cell,cell)
 sprite.scale=Vector2.ONE*width/cell.x
 sprite.offset=Vector2(0,cell.y/2-foot)
 sprite.position.y=8
 if variant==1 and kind in ["magic_shop","tavern"]:sprite.modulate=Color("d9dec3")
 preload("res://scripts/art/mascot_props.gd").apply(sprite,kind,width)
 add_child(sprite)
 if kind=="lantern" or kind=="painting":
  light=Sprite2D.new();light.texture=preload("res://assets/woo/light.png")
  light.scale=Vector2.ONE*(2.5 if kind=="lantern" else 2.0)
  light.position.y=-38;light.modulate=Color(1,0.72,0.35,0.25) if kind=="lantern" else Color(0.5,0.65,1,0.22)
  var mat:=CanvasItemMaterial.new();mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;mat.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED;light.material=mat;add_child(light)
 if not display_name.is_empty():
  var label:=Label.new();label.text=display_name;label.position=Vector2(-75,13);label.size.x=150;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size",10);label.add_theme_color_override("font_color",Color("eddbb8"));label.add_theme_color_override("font_outline_color",Color("302d37"));label.add_theme_constant_override("outline_size",2)
  add_child(label)
func set_stories(count: int) -> void:
 story_count=clampi(count,0,3)
 if is_instance_valid(memory_glow):memory_glow.queue_redraw()
func _draw() -> void:
 if kind=="bridge":return
 if kind=="bench":
  draw_line(Vector2(-18,0),Vector2(-18,-12),Color("5c3e32"),4)
  draw_line(Vector2(18,0),Vector2(18,-12),Color("5c3e32"),4)
  for i in range(3):
   var y: float=-14+i*3
   draw_colored_polygon(PackedVector2Array([Vector2(-24,y),Vector2(16,y-7),Vector2(25,y-3),Vector2(-15,y+4)]),Color("a4825d").darkened(i*0.05))
   draw_line(Vector2(-24,y),Vector2(16,y-7),Color("c3a37a"),0.8)
  return
 var width:=72.0 if kind in ["hanok","tavern","magic_shop","shrine","pavilion"] else (40.0 if kind in ["market","food","great_tree"] else 17.0)
 draw_colored_polygon(PackedVector2Array([Vector2(-width,-2),Vector2(4,-width*0.4),Vector2(width+18,8),Vector2(16,width*0.4+9)]),Color(0.035,0.06,0.07,0.34))
func draw_memories() -> void:
  for i in range(story_count):
   var p:=Vector2(-35+i*35,-120-absf(i-1)*13)
   memory_glow.draw_circle(p,5,Color(1,0.7,0.25,0.25));memory_glow.draw_circle(p,2,Color("ffe7a0"))
