class_name WooWardrobeArt
extends RefCounted
const SHEET=preload("res://assets/woo/wardrobe/layers.png")
const HEAD_PARTS=preload("res://assets/woo/wardrobe/head_parts.png")
static func head_region(cell: int) -> Rect2:
 var size:=Vector2(HEAD_PARTS.get_size())/4.0
 return Rect2(Vector2(cell%4,cell/4)*size,size)
# Offline alpha bounds: no pixel scanning or image allocation during gameplay.
const REGIONS=[[13, 9, 200, 189], [232, 23, 199, 185], [452, 10, 204, 195], [676, 11, 201, 204], [14, 228, 196, 203], [231, 229, 205, 203], [456, 227, 197, 206], [678, 228, 196, 203], [11, 454, 201, 204], [237, 455, 194, 203], [455, 453, 199, 205], [677, 452, 200, 206], [13, 687, 195, 153], [232, 675, 202, 204], [460, 676, 189, 203], [668, 674, 209, 205], [15, 907, 192, 162], [234, 910, 192, 182], [446, 899, 214, 207], [667, 921, 218, 182], [12, 1117, 187, 201], [234, 1122, 196, 181], [451, 1110, 201, 205], [677, 1116, 199, 193], [29, 1339, 149, 198], [245, 1339, 161, 198], [467, 1339, 184, 188], [684, 1353, 183, 180], [13, 1568, 198, 190], [235, 1561, 191, 204], [452, 1567, 193, 191], [687, 1561, 175, 204]]
static func region(cell: int) -> Rect2:
 var r: Array=REGIONS[clampi(cell,0,31)];return Rect2(r[0],r[1],r[2],r[3])
static func icon(cell: int) -> Texture2D:
 var atlas:=AtlasTexture.new()
 if cell<4:
  atlas.atlas=preload("res://assets/woo/mascot/portraits.png");atlas.region=Rect2(0,cell*96,96,96)
 else:atlas.atlas=SHEET;atlas.region=region(cell)
 return atlas
