extends RefCounted
## 무료 꾸미기 마켓·업적·우편·알림 카탈로그.
## 결제(인앱결제·광고)는 없다. 재화는 경기·업적·우편 보상으로만 얻고,
## 모든 아이템은 게임 안에서 실제로 장착되어 화면에 반영된다.
const SKINS=[
 {"id":"default","name":"푸른 도포","price":0,"color":"ffffff","desc":"캐릭터 원화의 기본 색입니다."},
 {"id":"moon","name":"달빛 도포","price":450,"color":"cfe0ff","desc":"달빛을 머금은 옅은 청백색으로 물듭니다."},
 {"id":"lotus","name":"연꽃 도포","price":600,"color":"ffc9d8","desc":"연꽃빛 분홍이 감도는 도포."},
 {"id":"ink","name":"먹빛 도포","price":750,"color":"9aa0c8","desc":"밤 먹물처럼 깊게 가라앉은 색."},
 {"id":"ember","name":"불꽃 도포","price":900,"color":"ffb27a","desc":"홍련의 불씨를 닮은 주황빛."},
 {"id":"jade","name":"옥빛 도포","price":1100,"color":"a8f0d8","desc":"서원의 이끼 낀 옥빛."}]
const TITLES=[
 {"id":"","name":"칭호 없음","price":0,"desc":"칭호를 비웁니다."},
 {"id":"moon_guard","name":"달빛지기","price":300,"desc":"밤 서원을 지키는 이."},
 {"id":"first_seal","name":"첫 봉인","price":350,"desc":"요괴의 봉인을 처음 막아낸 도사."},
 {"id":"rescue_hand","name":"구조의 손","price":500,"desc":"봉인된 동료를 세 번 구출했습니다."},
 {"id":"shadow_hunter","name":"그림자 사냥꾼","price":700,"desc":"어둠 속 요괴를 쫓는 추적자."},
 {"id":"library_keeper","name":"서고지기","price":800,"desc":"세 한옥의 문을 모두 열어 본 이."}]
const EFFECTS=[
 {"id":"","name":"기본 빛","price":0,"color":"d9c8ff","desc":"캐릭터 고유의 기운."},
 {"id":"gold","name":"금빛 기운","price":600,"color":"ffd98a","desc":"발밑에 금빛 테두리가 돕니다."},
 {"id":"moonlight","name":"월광","price":800,"color":"bcd8ff","desc":"푸른 달빛이 감돕니다."},
 {"id":"foxfire","name":"여우불","price":1000,"color":"c39bff","desc":"보랏빛 도깨비불."},
 {"id":"lotus","name":"연꽃 안개","price":1000,"color":"ffb9cf","desc":"분홍 연꽃 안개."}]
const ACHIEVEMENTS=[
 {"id":"first_match","name":"월하의 첫 경기","desc":"경기를 한 번 끝까지 치릅니다.","stat":"matches","goal":1,"reward":300},
 {"id":"ten_matches","name":"서원의 단골","desc":"경기 10회를 완주합니다.","stat":"matches","goal":10,"reward":700},
 {"id":"first_win","name":"첫 승리","desc":"한 번 승리합니다.","stat":"wins","goal":1,"reward":400},
 {"id":"five_wins","name":"달빛의 승자","desc":"5회 승리합니다.","stat":"wins","goal":5,"reward":900},
 {"id":"seal_three","name":"봉인의 손길","desc":"요괴로 도사 3명을 봉인합니다.","stat":"seals","goal":3,"reward":500},
 {"id":"rescue_three","name":"구조의 손길","desc":"봉인된 동료를 3회 구출합니다.","stat":"rescues","goal":3,"reward":500},
 {"id":"door_walker","name":"세 한옥의 문","desc":"한옥 문을 6회 열어 안으로 들어갑니다.","stat":"doors","goal":6,"reward":450},
 {"id":"disguise_five","name":"사물의 달인","desc":"사물 둔갑을 5회 사용합니다.","stat":"disguises","goal":5,"reward":450}]
const MAILS=[
 {"id":"welcome","title":"월하의 서원에 오신 것을 환영합니다","body":"서원의 밤이 열렸습니다. 세 채의 한옥과 연못, 아치 목교를 걸어 보세요. 앞문과 뒷문으로 드나들 수 있고, 지붕은 들어가면 열립니다.","reward":500},
 {"id":"update_zoom","title":"2.5D 시점·대형 한옥 업데이트","body":"기본 시점을 넓은 2.5D(1.32배)로 잡았습니다. 청월당·서고·별채 세 채를 출입할 수 있고, 실내에서는 바깥이 밤안개로 가려집니다.","reward":300},
 {"id":"market_open","title":"무료 마켓이 문을 열었습니다","body":"결제 없이 경기 보상으로만 도포·칭호·기운을 장착할 수 있습니다. 업적과 우편에서도 재화를 받을 수 있습니다.","reward":400},
 {"id":"lobby_bgm","title":"새 로비 음악","body":"로비에는 자체 합성한 국악풍 밤 음악이 흐릅니다. 모든 음원은 이 게임을 위해 직접 합성했고 외부 저작권 음원을 쓰지 않습니다.","reward":200}]
## 캐릭터 상점: 무료 4인(팀별 2인)과 게임 재화로 해금하는 4인. 인앱결제·광고 없음.
const CHARACTERS=[
 {"id":"daoist:woochi","price":0,"tag":"무료"},
 {"id":"daoist:yeonhwa","price":0,"tag":"무료"},
 {"id":"daoist:muyeong","price":800,"tag":"해금"},
 {"id":"daoist:hongryeon","price":900,"tag":"해금"},
 {"id":"yokai:gumiho","price":0,"tag":"무료"},
 {"id":"yokai:jangsanbeom","price":0,"tag":"무료"},
 {"id":"yokai:dokkaebi","price":1000,"tag":"해금"},
 {"id":"yokai:haechi","price":1200,"tag":"해금"}]
const FREE_CHARACTERS=["daoist:woochi","daoist:yeonhwa","yokai:gumiho","yokai:jangsanbeom"]
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
 {"id":"market","title":"마켓은 무료입니다","body":"결제·광고 없이 코인과 보석으로만 꾸미기를 해금합니다. 보상은 경기·업적·우편에서 나옵니다."},
 {"id":"quick","title":"빠른 매치·친구 방 코드","body":"로비에서 빠른 매치와 친구와 함께(방 코드 공유)를 바로 시작할 수 있습니다. 8인 구성은 도사6:요괴2로 고정되었습니다."}]
static func skin(id: String) -> Dictionary:
 for item in SKINS:
  if item.id==id:return item
 return SKINS[0]
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
