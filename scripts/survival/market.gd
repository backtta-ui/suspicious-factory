extends RefCounted
## 무료 꾸미기 마켓·업적·우편·알림 카탈로그.
## 재화는 경기·업적·우편 보상으로만 얻고,
## 모든 아이템은 게임 안에서 실제로 장착되어 화면에 반영된다.
## 2.0.36 스킨 정리: 기본/달빛/연꽃/먹빛/불꽃/옥빛 같은 '도포 색깔 스킨'은
## 상점·도감·선택창에서 완전히 뺐다. 스킨은 이제 그 캐릭터만 쓰는 전용 의상이다.
## 저장 데이터 호환을 위해 예전 색 스킨 id는 LEGACY_SKINS에서만 해석한다(판매·표시 없음).
const DEFAULT_SKIN={"id":"default","name":"기본 모습","price":0,"color":"ffffff",
 "desc":"스킨을 입히지 않은 캐릭터 본래의 모습입니다."}
const SKINS=[
 ## 2.0.34: 전우치 전용 스킨(부침개 전우치). 전용 8방향·김치전 은신·부침개 이펙트가 붙는다.
 {"id":"woochi_pancake","name":"부침개 전우치","price":0,"color":"ffd79a","character":"daoist:woochi","skin_of":"woochi",
  "desc":"김치전을 둘러쓴 부침개 전우치 · 전우치 전용 스킨",
  "portrait":"res://assets/woo/skins/woochi_pancake/portrait.png",
  "full":"res://assets/woo/skins/woochi_pancake/full.png",
  "sheet":"res://assets/woo/skins/woochi_pancake/walk_8dir.png",
  "fx_stealth":"res://assets/woo/skins/woochi_pancake/fx_kimchijeon_cloak.png",
  "fx_cast":"res://assets/woo/skins/woochi_pancake/fx_pancake_flip.png"}]
## 판매·표시하지 않는다. 예전 저장의 장착 id만 조용히 해석한다.
const LEGACY_SKINS=[
 {"id":"moon","name":"달빛 도포","price":450,"color":"cfe0ff","desc":"달빛을 머금은 옅은 청백색으로 물듭니다."},
 {"id":"lotus","name":"연꽃 도포","price":600,"color":"ffc9d8","desc":"연꽃빛 분홍이 감도는 도포."},
 {"id":"ink","name":"먹빛 도포","price":750,"color":"9aa0c8","desc":"밤 먹물처럼 깊게 가라앉은 색."},
 {"id":"ember","name":"불꽃 도포","price":900,"color":"ffb27a","desc":"홍련의 불씨를 닮은 주황빛."},
 {"id":"jade","name":"옥빛 도포","price":1100,"color":"a8f0d8","desc":"서원의 이끼 낀 옥빛."}]
## `gems`는 코인 대신 낼 수 있는 보석 가격이다(2.0.32). 없으면 코인으로만 해금한다.
const TITLES=[
 {"id":"","name":"칭호 없음","price":0,"desc":"칭호를 비웁니다."},
 {"id":"moon_guard","name":"달빛지기","price":300,"desc":"조선의 밤을 지키는 이."},
 {"id":"first_seal","name":"첫 봉인","price":350,"desc":"요괴의 봉인을 처음 막아낸 도사."},
 {"id":"rescue_hand","name":"구조의 손","price":500,"desc":"봉인된 동료를 세 번 구출했습니다."},
 {"id":"shadow_hunter","name":"그림자 사냥꾼","price":700,"gems":15,"desc":"어둠 속 요괴를 쫓는 추적자."},
 {"id":"library_keeper","name":"서고지기","price":800,"gems":20,"desc":"세 한옥의 문을 모두 열어 본 이."}]
const EFFECTS=[
 {"id":"","name":"기본 빛","price":0,"color":"d9c8ff","desc":"캐릭터 고유의 기운."},
 {"id":"gold","name":"금빛 기운","price":600,"gems":12,"color":"ffd98a","desc":"발밑에 금빛 테두리가 돕니다."},
 {"id":"moonlight","name":"월광","price":800,"gems":15,"color":"bcd8ff","desc":"푸른 달빛이 감돕니다."},
 {"id":"foxfire","name":"여우불","price":1000,"gems":20,"color":"c39bff","desc":"보랏빛 도깨비불."},
 {"id":"lotus","name":"연꽃 안개","price":1000,"gems":20,"color":"ffb9cf","desc":"분홍 연꽃 안개."}]
const ACHIEVEMENTS=[
 {"id":"first_match","name":"조선의 첫 경기","desc":"경기를 한 번 끝까지 치릅니다.","stat":"matches","goal":1,"reward":300},
 {"id":"ten_matches","name":"조선의 단골","desc":"경기 10회를 완주합니다.","stat":"matches","goal":10,"reward":700},
 {"id":"first_win","name":"첫 승리","desc":"한 번 승리합니다.","stat":"wins","goal":1,"reward":400},
 {"id":"five_wins","name":"달빛의 승자","desc":"5회 승리합니다.","stat":"wins","goal":5,"reward":900},
 {"id":"seal_three","name":"봉인의 손길","desc":"요괴로 도사 3명을 봉인합니다.","stat":"seals","goal":3,"reward":500},
 {"id":"rescue_three","name":"구조의 손길","desc":"봉인된 동료를 3회 구출합니다.","stat":"rescues","goal":3,"reward":500},
 {"id":"door_walker","name":"세 한옥의 문","desc":"한옥 문을 6회 열어 안으로 들어갑니다.","stat":"doors","goal":6,"reward":450},
 {"id":"disguise_five","name":"사물의 달인","desc":"사물 둔갑을 5회 사용합니다.","stat":"disguises","goal":5,"reward":450}]
## `reward`는 코인, `gems`는 함께 동봉되는 보석이다(2.0.32). 둘 다 수령할 때 실제 지갑에 들어간다.
const MAILS=[
 {"id":"welcome","title":"조선에 오신 것을 환영합니다","body":"조선의 밤이 열렸습니다. 서당·서책방·대나무 숲길·연못 정자·약재실·장독대 뒤뜰을 걸어 보세요. 앞문과 뒷문으로 드나들 수 있고, 지붕은 들어가면 열립니다.","reward":500,"gems":2},
 {"id":"update_zoom","title":"2.5D 시점·대형 한옥 업데이트","body":"기본 시점을 넓은 2.5D(1.32배)로 잡았습니다. 청월당·서고·별채 세 채를 출입할 수 있고, 실내에서는 바깥이 밤안개로 가려집니다.","reward":300,"gems":0},
 {"id":"market_open","title":"무료 마켓이 문을 열었습니다","body":"결제 없이 경기 보상으로만 도포·칭호·기운을 장착할 수 있습니다. 업적과 우편에서도 재화를 받을 수 있습니다.","reward":400,"gems":1},
 {"id":"lobby_bgm","title":"새 로비 음악","body":"2.0.37부터 로비·네 맵 음악과 발소리·도술 효과음을 OpenGameArt CC0 실제 녹음으로 바꿨습니다. 유료 음원·구독 없이 무료 CC0만 쓰며, 출처는 assets/audio/CC0_SOURCES.md에 적어 두었습니다.","reward":200,"gems":0}]
## 캐릭터 상점: 2.0.28 테스트·체험 단계라 10인 전원이 무료 해금 상태다.
const CHARACTERS=[
 {"id":"daoist:woochi","price":0,"tag":"무료"},
 {"id":"daoist:honggildong","price":0,"tag":"무료"},
 {"id":"daoist:jangyeongsil","price":0,"tag":"무료"},
 {"id":"daoist:barigongju","price":0,"tag":"무료"},
 {"id":"daoist:gangnim","price":0,"tag":"무료"},
 {"id":"yokai:gumiho","price":0,"tag":"무료"},
 {"id":"yokai:jangsanbeom","price":0,"tag":"무료"},
 {"id":"yokai:dokkaebi","price":0,"tag":"무료"},
 {"id":"yokai:eodubsimi","price":0,"tag":"무료"},
 {"id":"yokai:yagwangwi","price":0,"tag":"무료"}]
const FREE_CHARACTERS=["daoist:woochi","daoist:honggildong","daoist:jangyeongsil","daoist:barigongju","daoist:gangnim","yokai:gumiho","yokai:jangsanbeom","yokai:dokkaebi","yokai:eodubsimi","yokai:yagwangwi"]
static func character(id: String) -> Dictionary:
 for item in CHARACTERS:
  if item.id==id:return item
 return {"id":id,"price":0,"tag":"무료"}
static func character_price(id: String) -> int:return int(character(id).price)
static func characters() -> Array:return CHARACTERS
## 각 탭의 항목 목록(캐릭터 / 스킨 / 칭호·기운).
static func shop_items(tab: String) -> Array:
 if tab=="character":return CHARACTERS
 if tab=="skin":return SKINS
 var out: Array=[]
 for item in TITLES:out.append({"id":"title:"+String(item.id),"kind":"title","title":item})
 for item in EFFECTS:out.append({"id":"effect:"+String(item.id),"kind":"effect","title":item})
 return out
const ALERTS=[
 {"id":"zoom","title":"카메라 1.32배·대형 한옥 3채","body":"캐릭터를 조금 줄이고 시야를 넓혔습니다. 청월당·서고·별채의 앞문과 뒷문을 모두 열 수 있고, 실내에서는 지붕이 열리고 바깥이 어두워집니다."},
 {"id":"character","title":"8인 2.5D 캐릭터 원화","body":"전우치·연화·무영·홍련·구미호·장산범·도깨비·해치의 인게임 스프라이트를 새로 그렸습니다. 8방향 이동과 점프, 시전 모션까지 연결됩니다."},
 {"id":"market","title":"마켓이 문을 열었습니다","body":"코인과 보석으로 꾸미기를 해금합니다. 보상은 경기·업적·우편에서 나옵니다."},
 {"id":"quick","title":"빠른 매치·친구 방 코드","body":"로비에서 빠른 매치와 친구와 함께(방 코드 공유)를 바로 시작할 수 있습니다. 8인 구성은 도사6:요괴2로 고정되었습니다."}]
static func skin(id: String) -> Dictionary:
 if id=="" or id=="default":return DEFAULT_SKIN
 for item in SKINS+LEGACY_SKINS:
  if item.id==id:return item
 return DEFAULT_SKIN
## 그 캐릭터가 입을 수 있는 스킨만(전용 스킨). 없으면 빈 배열.
static func skins_for(character: String) -> Array:
 var out: Array=[]
 var art: String=character
 if art.contains(":"):art=art.split(":")[1]
 for item in SKINS:
  if String(item.get("skin_of",""))==art:out.append(item)
 return out
static func title(id: String) -> Dictionary:
 for item in TITLES:
  if item.id==id:return item
 return TITLES[0]
static func effect(id: String) -> Dictionary:
 for item in EFFECTS:
  if item.id==id:return item
 return EFFECTS[0]
static func skin_color(id: String) -> Color:
 return Color(String(skin(id).color))
static func effect_color(id: String) -> Color:
 return Color(String(effect(id).color))
static func achievement(id: String) -> Dictionary:
 for item in ACHIEVEMENTS:
  if item.id==id:return item
 return {}
## 보석으로도 해금할 수 있는 항목이면 그 가격, 아니면 0(코인 전용).
static func gem_price(item: Dictionary) -> int:
 return int(item.get("gems",0))
static func mail_gems(item: Dictionary) -> int:
 return int(item.get("gems",0))
