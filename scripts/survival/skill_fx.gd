extends RefCounted
## 2.0.34 기본 스킨 10인 전용 이펙트 + 부침개 전우치 스킨 이펙트 연결.
## rules.signature()가 도술이 터지는 순간 이 표에서 PNG를 찾아 fx_png 이펙트로 남기고,
## fx.gd가 그 PNG를 모션에 맞춰 그린다(설명·판정·그림이 같은 표를 본다).
## 손그림 이펙트가 없는 캐릭터는 빈 문자열을 돌려주고 기존 도형 이펙트만 쓴다.
const DIR="res://assets/woo/v34/fx/"
const SKIN_DIR="res://assets/woo/skins/woochi_pancake/"
## 캐릭터 인게임 원화 id별 기본 이펙트.
const CHAR_FX={
 "woochi":"fx_talisman",
 "gildong":"fx_feather_wind",
 "yeongsil":"fx_clockwork",
 "bari":"fx_lotus_ward",
 "gangrim":"fx_gwimun",
 "gumiho":"fx_foxfire",
 "jangsanbeom":"fx_moon_claw",
 "dokkaebi":"fx_iron_club",
 "eoduksini":"fx_ink_veil",
 "yagwanggwi":"fx_glow_steps"}
## 도술별 전용 이펙트(캐릭터 기본보다 우선). 표에 없으면 캐릭터 기본을 쓴다.
const SKILL_FX={
 "clone":"fx_dojutsu","transform":"fx_dojutsu",
 "painting":"fx_scroll_sansuhwa",
 "wallhop":"fx_feather_wind","windstep":"fx_feather_wind","eightleap":"fx_feather_wind",
 "puppet":"fx_clockwork","trap":"fx_clockwork","astrolabe":"fx_clockwork",
 "lifelamp":"fx_lotus_ward","deathflower":"fx_lotus_ward","returnpath":"fx_lotus_ward",
 "ghostgate":"fx_gwimun","underworldgate":"fx_gwimun",
 "soulmark":"fx_talisman",
 "mimic":"fx_foxfire","foxscent":"fx_foxfire","foxdream":"fx_foxfire",
 "voicemimic":"fx_talisman",
 "soundhunt":"fx_glow_steps","shoeprints":"fx_glow_steps","glowpowder":"fx_glow_steps","footprintmap":"fx_glow_steps",
 "mountaingrowl":"fx_moon_claw",
 "mischief":"fx_iron_club","faketreasure":"fx_iron_club","goblinfest":"fx_iron_club",
 "douse":"fx_ink_veil","blackvision":"fx_ink_veil","moonlessnight":"fx_ink_veil"}
## 스킨 전용 이펙트. stealth는 은신(화중은신·둔갑) 순간, cast는 그 밖의 도술.
const SKIN_FX={
 "woochi_pancake":{"stealth":"fx_kimchijeon_cloak","cast":"fx_pancake_flip"}}
## 은신 계열로 보는 도술(김치전 막이 펼쳐지는 순간).
const STEALTH_SKILLS=["painting","transform","moonlessnight","ghostgate"]
static func art_id(character: String) -> String:
 var id: String=character
 if id.contains(":"):id=id.split(":")[1]
 return preload("res://scripts/survival/characters.gd").fallback_art(id)
## 스킨이 그 캐릭터 전용인지(부침개 전우치는 전우치만).
static func skin_allows(skin: String,character: String) -> bool:
 if skin=="woochi_pancake":return art_id(character)=="woochi"
 return true
static func file_for(character: String,skill: String,skin: String="") -> String:
 var art:=art_id(character)
 if skin!="" and skin_allows(skin,character) and SKIN_FX.has(skin):
  var book: Dictionary=SKIN_FX[skin]
  var chosen: String="stealth" if STEALTH_SKILLS.has(skill) else "cast"
  var base: String=String(book.get(chosen,book.get("cast","")))
  var path: String=SKIN_DIR+base+(".png" if not base.ends_with(".png") else "")
  if ResourceLoader.exists(path):return path
  return ""
 var name_value: String=String(SKILL_FX.get(skill,CHAR_FX.get(art,"")))
 if name_value=="":return ""
 var full: String=DIR+name_value+".png"
 return full if ResourceLoader.exists(full) else ""
## 스킨 장착 시 인게임 걷기 시트 키(전우치 전용). 아니면 "".
static func sheet_key(character: String,skin: String) -> String:
 if skin=="woochi_pancake" and art_id(character)=="woochi":return "woochi_pancake"
 return ""
static func portrait_for(character: String,skin: String) -> String:
 if skin=="woochi_pancake" and art_id(character)=="woochi":
  return SKIN_DIR+"portrait.png"
 return ""
static func full_for(character: String,skin: String) -> String:
 if skin=="woochi_pancake" and art_id(character)=="woochi":
  return SKIN_DIR+"full.png"
 return ""
