extends RefCounted
const TEXTURE=preload("res://assets/woo/mascot/props.png")
const KINDS={"hanok":0,"tavern":0,"magic_shop":1,"market":1,"shrine":2,"pavilion":3,"gate":4,"wall":5,"bamboo":6,"great_tree":7,"tree":8,"pine":8,"rock":9,"jars":10,"jar":10,"crate":11,"lantern":12,"stone_lantern":12,"bridge":13,"well":14,"basket":15}
static func apply(sprite: Sprite2D,kind: String,width: float) -> bool:
 if not KINDS.has(kind):return false
 var index: int=KINDS[kind]
 var bounds: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/woo/mascot/prop_bounds.json"))
 sprite.texture=TEXTURE;sprite.region_enabled=true
 sprite.region_rect=Rect2(Vector2(index%4,floori(index/4.0))*160,Vector2(160,160))
 sprite.offset=Vector2(0,-74)
 sprite.scale=Vector2.ONE*width*.70/float(bounds[index][2]);sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 return true
