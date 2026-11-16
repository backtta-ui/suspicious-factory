class_name WooDirectionalArt
extends RefCounted
const Data=preload("res://scripts/wardrobe/directional_data.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const HAIRS={"black":0,"long":1,"tied":2,"silver":3,"short":4,"flower":5}
const HATS={"gat":0,"bamboo":1,"hood":2,"crown":3,"fox":4,"gold":5}
const ACCESSORIES={"talisman":0,"gourd":1,"bell":2,"ribbon":3,"pouch":4,"orb":5,"scroll":6,"sigil":7}
const READY_OUTFITS=["basic","moon","night"]
static var textures: Dictionary={}
static func sheet_for(sheet: String,direction: int) -> String:return "d_"+sheet if direction>=4 else sheet
static func texture(sheet: String,direction: int=-1) -> Texture2D:
 sheet=sheet_for(sheet,direction)
 if not textures.has(sheet):
  var path: String="res://assets/woo/characters/"+sheet+".png"
  if not ResourceLoader.exists(path):return null
  textures[sheet]=load(path)
 return textures[sheet]
static func frame(sheet: String,row: int,direction: int) -> Dictionary:return Data.SHEETS[sheet_for(sheet,direction)].frames[row*4+posmod(direction,4)]
static func cell(sheet: String,row: int=0,direction: int=0) -> Vector2:return rect(frame(sheet,row,direction).region).size*Vector2(texture(sheet,direction).get_size())
static func supported(slot: String,id: String) -> bool:return slot!="outfit" or READY_OUTFITS.has(id)
static func effective(raw: Dictionary) -> Dictionary:
 var look:=C.normalize(raw)
 if not READY_OUTFITS.has(look.outfit):
  look.outfit="basic"
  if not C.OUTFITS.basic.colors.has(look.color):look.color=C.base_appearance(look.character).color
 return look
static func pending(raw: Dictionary) -> String:
 return "의상 4방향 동작 리소스 준비 중 · 보유/저장 기록 유지, 기본 도사복 표시" if not READY_OUTFITS.has(C.normalize(raw).outfit) else ""
static func idle_height(character: String,direction: int) -> float:
 return float(frame(character+"_core",0,direction).box[3])*cell(character+"_core",0,direction).y
static func rect(value: Array) -> Rect2:return Rect2(value[0],value[1],value[2],value[3])
static func vec(value: Array) -> Vector2:return Vector2(value[0],value[1])
