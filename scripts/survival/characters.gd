extends RefCounted
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const PORTRAIT_DIR="res://assets/woo/codex/"
const INGAME_DIR="res://assets/woo/ingame/"
## 2.0.27 신규 6인 원화는 이 폴더에 `{id}-full.png` · `{id}-portrait.png` ·
## `{id}-{front|back|left|right}[-walk1|-walk2].png` · `manifest.json` 이름으로
## 넣으면 게임이 자동으로 집어 든다. 파일이 없으면 아래 fallback 원화를 쓴다.
const V27_DIR="res://assets/woo/v27/"
const V27_MANIFEST=V27_DIR+"manifest.json"
## Shared gameplay skills. Keys never change: rules.gd resolves an ability through
## this table (slot: main = 대표 스킬, sub = 보조 스킬, ult = 궁극기).
const SKILLS={
 "clone":{"name":"분신술","description":"현재 외형의 이동 분신을 8초 세워 요괴의 확인을 낚습니다.","cd":18.0,"icon":"clone","aim":false},
 "transform":{"name":"둔갑술","description":"가까운 항아리·나무상자·등불·고양이·강아지·비석의 모습으로 9초 위장합니다. 다시 누르면 해제합니다.","cd":12.0,"icon":"jar","aim":false},
 "painting":{"name":"화중은신","description":"그림 속 차원으로 4초 숨습니다. 무적이며 벽을 통과하고, 다른 시점에서는 모습·이름표·발자국이 완전히 사라집니다.","cd":55.0,"icon":"shadow","aim":true},
 "wallhop":{"name":"담장넘기","description":"조준한 방향으로 190만큼 담장과 장애물을 넘어 도약합니다.","cd":12.0,"icon":"jump","aim":true},
 "windstep":{"name":"바람발","description":"5초 동안 이동속도가 1.7배로 폭발합니다.","cd":16.0,"icon":"dodge","aim":false},
 "eightleap":{"name":"팔방도약","description":"조준한 방향을 중심으로 세 방향으로 연속 도약하며 분신 잔상을 남깁니다.","cd":50.0,"icon":"blink","aim":true},
 "puppet":{"name":"기관인형","description":"내 모습의 기관 인형을 9초 세워 요괴를 유인합니다.","cd":20.0,"icon":"mimic","aim":false},
 "trap":{"name":"압력기관","description":"밟으면 3초 동안 요괴를 느리게 만드는 압력 덫을 설치합니다.","cd":18.0,"icon":"capture","aim":false},
 "astrolabe":{"name":"천문기계","description":"8초 동안 조선 전역의 요괴 위치를 벽 너머까지 꿰뚫어 봅니다.","cd":60.0,"icon":"track","aim":false},
 "lifelamp":{"name":"생명등불","description":"8초 동안 나와 가까운 동료의 이동속도를 올리고 봉인을 한 번 막습니다.","cd":20.0,"icon":"shield","aim":false},
 "deathflower":{"name":"저승꽃","description":"8초 보호막을 두르고, 봉인되어도 구조 시간을 6초 더 벌어 줍니다.","cd":22.0,"icon":"talisman","aim":false},
 "returnpath":{"name":"귀환의 길","description":"봉인되었거나 위기에 몰린 동료 곁으로 즉시 합류해 보호막을 나눕니다.","cd":55.0,"icon":"rescue","aim":false},
 "ghostgate":{"name":"귀문보기","description":"6초 동안 벽과 한옥 너머의 도사·요괴를 투시합니다.","cd":18.0,"icon":"darkness","aim":false},
 "soulmark":{"name":"혼길표식","description":"혼길 표식을 세웁니다. 궁극기로 이 자리로 순간 귀환합니다.","cd":14.0,"icon":"talisman","aim":false},
 "underworldgate":{"name":"저승문","description":"세워 둔 혼길표식으로 즉시 귀환하고 2초 무적이 됩니다.","cd":45.0,"icon":"blink","aim":false},
 "mimic":{"name":"인간둔갑","description":"가까이 보이는 도사의 외형·이름표·미니맵 표시까지 9초 그대로 복제합니다.","cd":22.0,"icon":"mask","aim":false},
 "foxscent":{"name":"여우향","description":"달콤한 향으로 반경 220의 도사를 4초 느리게 만듭니다.","cd":18.0,"icon":"fake_flame","aim":false},
 "foxdream":{"name":"구미환몽","description":"주변 도사의 시야를 7초 환영으로 어지럽힙니다.","cd":55.0,"icon":"smoke","aim":false},
 "voicemimic":{"name":"목소리흉내","description":"가짜 구조 소리를 내 도사를 유인하고, 가장 가까운 도사의 위치를 3초 드러냅니다.","cd":16.0,"icon":"mask","aim":false},
 "soundhunt":{"name":"청각사냥","description":"4초 동안 도사의 실제 발소리와 발자국을 감지합니다.","cd":18.0,"icon":"track","aim":false},
 "mountaingrowl":{"name":"산군의 울음","description":"반경 320에 충격을 일으켜 도사를 밀쳐내고, 6초 동안 나의 이동속도가 오릅니다.","cd":55.0,"icon":"attack","aim":false},
 "mischief":{"name":"도깨비장난","description":"반경 260의 사물을 뒤엉키게 흔들어 둔갑한 도사를 강제로 드러내고, 6초 동안 둔갑이 막히는 장난 지대를 만듭니다(지대 안의 도사는 느려집니다).","cd":16.0,"icon":"jar","aim":false},
 "faketreasure":{"name":"가짜보물","description":"탐나는 보물 미끼를 설치합니다. 다가온 도사는 3초 동안 꼼짝 못 합니다.","cd":18.0,"icon":"capture","aim":false},
 "goblinfest":{"name":"도깨비잔치","description":"도깨비불이 터져 반경 200의 도사를 둔갑 해제하고 밀쳐냅니다.","cd":50.0,"icon":"fake_flame","aim":false},
 "douse":{"name":"등불끄기","description":"주변 300의 석등 불빛을 9초 동안 실제로 끄고 밤안개를 만듭니다.","cd":16.0,"icon":"darkness","aim":false},
 "blackvision":{"name":"검은시야","description":"가장 가까운 도사의 화면 시야를 6초 동안 좁히고 안개로 덮습니다.","cd":20.0,"icon":"shadow","aim":false},
 "moonlessnight":{"name":"무월야","description":"맵 전역을 8초 암흑으로 덮고 은신 상태로 추격합니다.","cd":60.0,"icon":"darkness","aim":false},
 "shoeprints":{"name":"신발흔적","description":"8초 동안 모든 도사의 발자국을 바닥과 미니맵에 밝게 비춥니다.","cd":16.0,"icon":"track","aim":false},
 "glowpowder":{"name":"야광가루","description":"가장 가까운 도사에게 10초 야광 표식을 묻혀 바닥과 미니맵에 위치를 계속 비춥니다.","cd":18.0,"icon":"talisman","aim":false},
 "footprintmap":{"name":"발자국지도","description":"10초 동안 모든 도사의 최근 동선을 미니맵과 바닥에 그립니다.","cd":55.0,"icon":"capture","aim":false}}
const TEAM_NAMES={"daoist":"도사","yokai":"요괴"}
const TEAM_ROLES={"daoist":"생존/지원","yokai":"추적/봉인"}
## 2.0.27 선출시 로스터: 도사 5인 · 요괴 5인. 캐릭터마다 대표 스킬 1 + 보조 스킬 1 +
## 궁극기 1(인게임 HUD 3버튼)을 실제로 쓴다. `art`는 인게임 원화 id이며 신규 6인은
## 아직 전용 원화가 없어 기존 아틀라스로 폴백하고, v27 폴더에 원화가 들어오면 그대로
## 연결된다. `body`는 도감 단상·프로필이 쓰는 wardrobe 몸이다.
const ROSTER={
 "daoist":[
  {"id":"woochi","name":"전우치","art":"woochi","body":"woochi","tint":"ffe0a8","role":"교란·은신","intro":"둔갑과 분신으로 요괴를 속이고 그림 속으로 숨는 도사","abilities":[
   {"slot":"main","skill":"clone","name":"분신술","icon":"clone","cd":18.0,"description":"현재 모습 그대로의 이동 분신을 8초 세워 요괴의 확인을 낚습니다."},
   {"slot":"sub","skill":"transform","name":"둔갑술","icon":"jar","cd":12.0,"description":"가까운 항아리·나무상자·등불·고양이·강아지·비석으로 9초 둔갑해 움직이며 숨습니다."},
   {"slot":"ult","skill":"painting","name":"화중은신","icon":"shadow","cd":55.0,"description":"그림 속 차원으로 4초 숨습니다. 무적이며 벽을 통과해 이동합니다."}]},
  {"id":"honggildong","name":"홍길동","art":"gildong","body":"muyeong","tint":"a9c8ff","role":"기동·도주","intro":"담장을 넘고 바람을 밟아 추격을 뿌리치는 도사","abilities":[
   {"slot":"main","skill":"wallhop","name":"담장넘기","icon":"jump","cd":12.0,"description":"조준한 방향으로 190만큼 담장과 장애물을 넘어 도약합니다.","aim":true},
   {"slot":"sub","skill":"windstep","name":"바람발","icon":"dodge","cd":16.0,"description":"5초 동안 이동속도가 1.7배로 폭발합니다."},
   {"slot":"ult","skill":"eightleap","name":"팔방도약","icon":"blink","cd":50.0,"description":"조준한 방향을 중심으로 세 방향으로 연속 도약하며 분신 잔상을 남깁니다.","aim":true}]},
  {"id":"jangyeongsil","name":"장영실","art":"yeongsil","body":"hongryeon","tint":"ffcf9a","role":"설치·정보","intro":"기관 인형과 천문 기계로 조선을 읽는 도사","abilities":[
   {"slot":"main","skill":"puppet","name":"기관인형","icon":"mimic","cd":20.0,"description":"내 모습의 기관 인형을 9초 세워 요괴를 유인합니다."},
   {"slot":"sub","skill":"trap","name":"압력기관","icon":"capture","cd":18.0,"description":"밟으면 3초 동안 요괴를 느리게 만드는 압력 덫을 설치합니다."},
   {"slot":"ult","skill":"astrolabe","name":"천문기계","icon":"track","cd":60.0,"description":"8초 동안 조선 전역의 요괴 위치를 벽 너머까지 꿰뚫어 봅니다."}]},
  {"id":"barigongju","name":"바리공주","art":"bari","body":"yeonhwa","tint":"ffd6e6","role":"지원·생존","intro":"저승의 길을 알고 동료를 되살리는 도사","abilities":[
   {"slot":"main","skill":"lifelamp","name":"생명등불","icon":"shield","cd":20.0,"description":"8초 동안 나와 가까운 동료의 이동속도를 올리고 봉인을 한 번 막습니다."},
   {"slot":"sub","skill":"deathflower","name":"저승꽃","icon":"talisman","cd":22.0,"description":"8초 보호막을 두르고, 봉인되어도 구조 시간을 6초 더 벌어 줍니다."},
   {"slot":"ult","skill":"returnpath","name":"귀환의 길","icon":"rescue","cd":55.0,"description":"봉인되었거나 위기에 몰린 동료 곁으로 즉시 합류해 보호막을 나눕니다."}]},
  {"id":"gangnim","name":"강림도령","art":"gangrim","body":"hongryeon","tint":"c9b6ff","role":"공간·이동","intro":"귀문을 열어 벽 너머를 보고 표식으로 돌아오는 도사","abilities":[
   {"slot":"main","skill":"ghostgate","name":"귀문보기","icon":"darkness","cd":18.0,"description":"6초 동안 벽과 한옥 너머의 도사·요괴를 투시합니다."},
   {"slot":"sub","skill":"soulmark","name":"혼길표식","icon":"talisman","cd":14.0,"description":"혼길 표식을 세웁니다. 궁극기로 이 자리로 순간 귀환합니다."},
   {"slot":"ult","skill":"underworldgate","name":"저승문","icon":"blink","cd":45.0,"description":"세워 둔 혼길표식으로 즉시 귀환하고 2초 무적이 됩니다."}]}],
 "yokai":[
  {"id":"gumiho","name":"구미호","art":"gumiho","body":"yeonhwa","tint":"ff9ee0","role":"위장·기만","intro":"인간으로 둔갑해 도사들 사이에 섞이는 요괴","abilities":[
   {"slot":"main","skill":"mimic","name":"인간둔갑","icon":"mask","cd":22.0,"description":"가까이 있는 도사의 외형·이름표·미니맵 표시를 9초간 그대로 복제해 혼란을 줍니다."},
   {"slot":"sub","skill":"foxscent","name":"여우향","icon":"fake_flame","cd":18.0,"description":"달콤한 향으로 반경 220의 도사를 4초 느리게 만듭니다."},
   {"slot":"ult","skill":"foxdream","name":"구미환몽","icon":"smoke","cd":55.0,"description":"주변 도사의 시야를 7초 환영으로 어지럽힙니다."}]},
  {"id":"jangsanbeom","name":"장산범","art":"jangsanbeom","body":"muyeong","tint":"8fc8ff","role":"청각·추격","intro":"목소리를 흉내 내며 발소리로 먹잇감을 쫓는 요괴","abilities":[
   {"slot":"main","skill":"voicemimic","name":"목소리흉내","icon":"mask","cd":16.0,"description":"가짜 구조 소리로 도사를 유인하고, 가장 가까운 도사의 위치를 3초 드러냅니다."},
   {"slot":"sub","skill":"soundhunt","name":"청각사냥","icon":"track","cd":18.0,"description":"4초 동안 도사의 실제 발소리와 발자국을 감지합니다."},
   {"slot":"ult","skill":"mountaingrowl","name":"산군의 울음","icon":"attack","cd":55.0,"description":"반경 320에 충격을 일으켜 도사를 밀쳐내고, 6초간 이동속도가 크게 오릅니다."}]},
  {"id":"dokkaebi","name":"도깨비","art":"dokkaebi","body":"woochi","tint":"ffc46b","role":"장난·함정","intro":"사물을 옮기고 가짜 보물로 도사를 꾀는 요괴","abilities":[
   {"slot":"main","skill":"mischief","name":"도깨비장난","icon":"jar","cd":16.0,"description":"반경 260의 사물을 뒤엉키게 흔들어 둔갑한 도사를 강제로 드러내고, 6초 동안 둔갑이 막히는 장난 지대를 만듭니다. 지대 안의 도사는 느려집니다."},
   {"slot":"sub","skill":"faketreasure","name":"가짜보물","icon":"capture","cd":18.0,"description":"보물 미끼를 설치합니다. 다가온 도사는 3초 동안 꼼짝 못 합니다."},
   {"slot":"ult","skill":"goblinfest","name":"도깨비잔치","icon":"fake_flame","cd":50.0,"description":"도깨비불이 터져 반경 200의 도사를 둔갑 해제하고 밀쳐냅니다."}]},
  {"id":"eodubsimi","name":"어둑시니","art":"eoduksini","body":"muyeong","tint":"9a8fd0","role":"어둠·기습","intro":"등불을 끄고 어둠 속에서 덮치는 요괴","abilities":[
   {"slot":"main","skill":"douse","name":"등불끄기","icon":"darkness","cd":16.0,"description":"주변 300의 석등 불빛을 9초 동안 실제로 끄고 밤안개를 만듭니다."},
   {"slot":"sub","skill":"blackvision","name":"검은시야","icon":"shadow","cd":20.0,"description":"가장 가까운 도사의 화면 시야를 6초 동안 좁히고 안개로 덮습니다."},
   {"slot":"ult","skill":"moonlessnight","name":"무월야","icon":"darkness","cd":60.0,"description":"맵 전역을 8초 암흑으로 덮고 은신 상태로 추격합니다."}]},
  {"id":"yagwangwi","name":"야광귀","art":"yagwanggwi","body":"hongryeon","tint":"d8f0ff","role":"흔적·탐지","intro":"도사의 신발과 발자국을 좇는 요괴","abilities":[
   {"slot":"main","skill":"shoeprints","name":"신발흔적","icon":"track","cd":16.0,"description":"8초 동안 모든 도사의 발자국을 바닥과 미니맵에 밝게 비춥니다."},
   {"slot":"sub","skill":"glowpowder","name":"야광가루","icon":"talisman","cd":18.0,"description":"가장 가까운 도사에게 10초 야광 표식을 묻혀 바닥과 미니맵에 위치를 계속 비춥니다."},
   {"slot":"ult","skill":"footprintmap","name":"발자국지도","icon":"capture","cd":55.0,"description":"10초 동안 모든 도사의 최근 동선을 미니맵과 바닥에 그립니다."}]}]}
const SLOT_NAMES={"main":"대표","sub":"보조","ult":"궁극기"}
## 인게임 원화 id(없으면 art 폴백). 신규 6인 파일이 v27 폴더에 오면 자동 사용.
## 파일 존재 검사는 비싸므로 결과를 한 번만 확인해 캐시한다.
static var _art_cache: Dictionary={}
## 신규 캐릭터가 아직 전용 원화가 없을 때 빌려 쓸 기존 아틀라스 id.
static func fallback_art(id: String) -> String:
 for team in ["daoist","yokai"]:
  for entry in ROSTER.get(team,[]):
   if String(entry.id)==id:return String(entry.get("art",entry.body))
 return id
static func art_file(id: String,kind: String) -> String:
 var key: String=id+":"+kind
 if _art_cache.has(key):return String(_art_cache[key])
 var resolved:=""
 var candidates: Array=["%s%s-%s.png" % [V27_DIR,id,kind],PORTRAIT_DIR+id+"-"+kind+".png"]
 var art: String=fallback_art(id)
 if art!=id:
  candidates.append("%s%s-%s.png" % [V27_DIR,art,kind])
  candidates.append(PORTRAIT_DIR+art+"-"+kind+".png")
 for path in candidates:
  if ResourceLoader.exists(String(path)):resolved=String(path);break
 _art_cache[key]=resolved
 return resolved
## 2.0.28 8방향 걷기 시트 준비: 시트의 rows 목록에 아래 8개 이름이 있으면 그 행을
## 그대로 쓰고, 4행(front/left/right/back) 시트는 예전처럼 대각선을 옆모습 행으로
## 대신한다. facing은 rules/actor와 같은 0=동 … 7=북동 시계방향 8방향이다.
const DIRECTIONS8=["front","front_right","right","back_right","back","back_left","left","front_left"]
const FACING_VIEW={0:"right",1:"front_right",2:"front",3:"front_left",4:"left",5:"back_left",6:"back",7:"back_right"}
## 8방향 행이 없는 4행 시트에서 대각선이 빌려 쓸 행(가까운 옆모습).
const VIEW_FALLBACK={"front_right":["right","front"],"back_right":["right","back"],"back_left":["left","back"],"front_left":["left","front"]}
## rows(행 이름 목록)에서 방향에 맞는 행 번호와 실제로 쓴 뷰 이름을 돌려준다.
## 8방향 시트는 좌우 반전이 필요 없고, 4행 폴백은 반전 없이 옆모습을 쓴다.
static func sheet_row(rows: Array, facing: int) -> Dictionary:
 var view: String=String(FACING_VIEW.get(posmod(facing,8),"front"))
 for candidate in [view]+Array(VIEW_FALLBACK.get(view,[])):
  var index: int=rows.find(String(candidate))
  if index<0:index=rows.find(String(candidate).replace("_","-"))
  if index>=0:return {"row":index,"view":String(rows[index])}
 return {"row":0,"view":String(rows[0]) if not rows.is_empty() else "front"}
## 시트가 8방향 행을 갖고 있는지(에셋 교체 여부 확인·테스트용).
static func eight_direction(rows: Array) -> bool:
 for name in ["front_right","back_right","back_left","front_left"]:
  if rows.has(name):return true
 return false
## 시트 안 원화 키(px). 스프라이트 배율 = 목표 높이 / 이 값.
static func sheet_art_height(sheet: Dictionary) -> float:
 var explicit: float=float(sheet.get("height",0.0))
 if explicit>0.0:return explicit
 var cell: Array=sheet.get("cell",[300,260])
 return maxf(1.0,float(cell[1]))
## 2.0.27 걷기 시트: 4행(front/left/right/back) x 4열 프레임. 셀 안 캐릭터 키와
## 발끝 앵커가 고정되어 있어 프레임을 바꿔도 위치가 흔들리지 않는다.
const WALK_MANIFEST="res://assets/woo/ingame/walk_sheets.json"
static var _walk_manifest={}
static var _walk_loaded:=false
static func _load_walk() -> void:
 if _walk_loaded:return
 _walk_loaded=true
 if ResourceLoader.exists(WALK_MANIFEST):
  var raw=JSON.parse_string(FileAccess.get_file_as_string(WALK_MANIFEST))
  if raw is Dictionary:_walk_manifest=raw
static func walk_sheet(art_id: String) -> Dictionary:
 _load_walk()
 var characters: Dictionary=_walk_manifest.get("characters",{})
 var data: Dictionary=characters.get(art_id,{})
 if data.is_empty() or not ResourceLoader.exists(String(data.get("sheet",""))):return {}
 return data
## 2.0.34 강남역을 걷는 둔갑 사물(배달 로봇·전동킥보드) 8방향 시트.
static func prop_sheet(kind: String) -> Dictionary:
 _load_walk()
 var props: Dictionary=_walk_manifest.get("props",{})
 var data: Dictionary=props.get(kind,{})
 if data.is_empty() or not ResourceLoader.exists(String(data.get("sheet",""))):return {}
 return data
static func animal_sheet(kind: String) -> Dictionary:
 _load_walk()
 var animals: Dictionary=_walk_manifest.get("animals",{})
 var data: Dictionary=animals.get(kind,{})
 if data.is_empty() or not ResourceLoader.exists(String(data.get("sheet",""))):return {}
 return data
## 하위 호환: 예전 이름으로도 접근할 수 있게 남긴다.
static func walk_frames(id: String) -> Dictionary:
 return walk_sheet(fallback_art(id))
static func catalog(team: String) -> Array:
 var result: Array=[]
 for entry in ROSTER.get(team,[]):
  result.append(character(team,entry))
 return result
static func character(team: String,entry: Dictionary) -> Dictionary:
 var id: String=entry.id
 var abilities: Array=[]
 for ability in entry.abilities:
  var spec: Dictionary=SKILLS.get(String(ability.skill),{})
  var filled: Dictionary=ability.duplicate(true)
  filled.cd=float(filled.get("cd",spec.get("cd",12.0)))
  filled.aim=bool(ability.get("aim",spec.get("aim",false)))
  filled.slot_name=String(SLOT_NAMES.get(String(filled.slot),"대표"))
  abilities.append(filled)
 var main: Dictionary=abilities[0] if not abilities.is_empty() else {}
 var skill: Dictionary={"name":String(main.get("name","")),"description":String(main.get("description","")),
  "cd":float(main.get("cd",12.0)),"icon":String(main.get("icon","attack")),"aim":bool(main.get("aim",false))}
 return {"id":team+":"+id,"name":entry.name,"team":team,"team_name":TEAM_NAMES[team],"role":entry.role,"intro":entry.intro,
  "body":entry.body,"art":entry.art,"tint":String(entry.get("tint","ffffff")),
  "sprite":art_file(id,"full"),"portrait":art_file(id,"portrait"),
  "animation":"native-eight-direction-rig",
  "speed":135.0,"run_speed":210.0,"jump_seconds":.8,
  "passive":"지속 능력 없음 · 공통 이동 성능","active":String(main.get("skill","clone")),"skill":skill,
  "abilities":abilities,"description":entry.intro}
static func roster() -> Array:
 var result: Array=[]
 for team in ["daoist","yokai"]:
  result.append_array(catalog(team))
 return result
static func find(id: String) -> Dictionary:
 for team in ["daoist","yokai"]:
  for data in catalog(team):
   if data.id==id:return data.duplicate(true)
 return {}
## 슬롯(main/sub/ult)으로 그 캐릭터의 능력을 꺼낸다. rules.gd·HUD가 함께 쓴다.
static func ability(id: String,slot: String) -> Dictionary:
 var spec:=find(id)
 for entry in spec.get("abilities",[]):
  if String(entry.slot)==slot:return entry
 return {}
## 인게임 액터 구분용 색. 배경과 겹치지 않는 은은한 기운으로만 쓴다.
const TINTS={
 "daoist:woochi":Color("ffe0a8"),"daoist:honggildong":Color("a9c8ff"),"daoist:jangyeongsil":Color("ffcf9a"),
 "daoist:barigongju":Color("ffd6e6"),"daoist:gangnim":Color("c9b6ff"),
 "yokai:gumiho":Color("ff9ee0"),"yokai:jangsanbeom":Color("8fc8ff"),"yokai:dokkaebi":Color("ffc46b"),
 "yokai:eodubsimi":Color("9a8fd0"),"yokai:yagwangwi":Color("d8f0ff")}
static func tint(id: String) -> Color:return TINTS.get(id,Color.WHITE)
static func look(id: String) -> Dictionary:
 var data:=find(id)
 return Looks.base_appearance(data.get("body","woochi"))
