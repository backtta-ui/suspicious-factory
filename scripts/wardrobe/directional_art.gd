class_name WooDirectionalArt
extends RefCounted
const Data=preload("res://scripts/wardrobe/directional_data.gd")
const C=preload("res://scripts/wardrobe/catalog.gd")
const HAIRS={"black":0,"long":1,"tied":2,"silver":3,"short":4,"flower":5}
const HATS={"gat":0,"bamboo":1,"hood":2,"crown":3,"fox":4,"gold":5}
const ACCESSORIES={"talisman":0,"gourd":1,"bell":2,"ribbon":3,"pouch":4,"orb":5,"scroll":6,"sigil":7}
const READY_OUTFITS=["basic"]
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
static func supported(slot: String,id: String,character: String="") -> bool:
 if slot=="outfit":return id=="basic"
 if slot in ["hair","hat"] and character!="":return id==C.base_appearance(character)[slot]
 return true
static func effective(raw: Dictionary) -> Dictionary:
 var look:=C.normalize(raw)
 var base:=C.base_appearance(look.character)
 for slot in ["hair","hat","outfit"]:
  if not supported(slot,look[slot],look.character):look[slot]=base[slot]
 return look
static func pending(raw: Dictionary) -> String:
 var look:=C.normalize(raw);var missing: Array=[]
 for slot in ["hair","hat","outfit"]:
  if not supported(slot,look[slot],look.character):missing.append({"hair":"헤어","hat":"모자","outfit":"의상"}[slot])
 return "" if missing.is_empty() else "원본용 "+"·".join(missing)+" 레이어 준비 중 · 해당 부위는 원본 차림 표시 / 보유·저장 기록 유지"
static func idle_height(character: String,direction: int) -> float:
 return float(frame(character+"_core",0,direction).box[3])*cell(character+"_core",0,direction).y
static func rect(value: Array) -> Rect2:return Rect2(value[0],value[1],value[2],value[3])
static func vec(value: Array) -> Vector2:return Vector2(value[0],value[1])
