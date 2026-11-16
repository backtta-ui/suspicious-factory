class_name WooExplorationLayout
extends RefCounted
const SIZE=Vector2(1800,1300)
const PALACE=[Vector2(70,100),Vector2(1730,100),Vector2(1730,1200),Vector2(70,1200)]
const COAST=[Vector2(80,140),Vector2(950,100),Vector2(1130,280),Vector2(1080,450),Vector2(1200,690),Vector2(1150,850),Vector2(1200,1120),Vector2(880,1200),Vector2(80,1200)]
static func bounds(id: String) -> PackedVector2Array:return PackedVector2Array(PALACE if id=="moon_palace" else COAST)
static func spawn(id: String) -> Vector2:return Vector2(900,850) if id=="moon_palace" else Vector2(350,1050)
static func objects(id: String) -> Array:
 if id=="moon_palace":return [{"index":0,"p":Vector2(900,1150),"width":330.0},{"index":1,"p":Vector2(900,350),"width":400.0},{"index":1,"p":Vector2(650,830),"width":260.0},{"index":1,"p":Vector2(1150,830),"width":260.0},{"index":2,"p":Vector2(400,200),"width":400.0},{"index":2,"p":Vector2(1400,200),"width":400.0},{"index":3,"p":Vector2(900,435),"width":210.0}]
 return [{"index":4,"p":Vector2(160,320),"width":280.0},{"index":4,"p":Vector2(170,770),"width":240.0},{"index":5,"p":Vector2(1180,1080),"width":150.0},{"index":5,"p":Vector2(1190,460),"width":140.0},{"index":6,"p":Vector2(1060,710),"width":135.0},{"index":7,"p":Vector2(610,350),"width":260.0}]
static func sites(id: String) -> Array:
 if id=="moon_palace":return [{"id":"palace_moon","p":Vector2(600,630),"name":"달 문양","glyph":0},{"id":"palace_star","p":Vector2(1200,630),"name":"별 문양","glyph":1},{"id":"palace_scroll","p":Vector2(900,500),"name":"궁궐의 기록","glyph":2}]
 return [{"id":"sea_shell","p":Vector2(520,910),"name":"달빛 소라","glyph":0},{"id":"sea_tide","p":Vector2(1060,760),"name":"파도의 제단","glyph":1},{"id":"sea_stone","p":Vector2(760,400),"name":"해안의 기억","glyph":2}]
static func footprint(object: Dictionary) -> Rect2:
 var w: float=object.width*.60;return Rect2(object.p-Vector2(w/2,26),Vector2(w,45))
static func safe(id: String,p: Vector2) -> Vector2:
 if not Geometry2D.is_point_in_polygon(p,bounds(id)):return spawn(id)
 for object in objects(id):
  if footprint(object).grow(14).has_point(p):return spawn(id)
 return p
