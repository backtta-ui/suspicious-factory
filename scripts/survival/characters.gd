extends RefCounted
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const PORTRAIT_DIR="res://assets/woo/codex/"
## Shared gameplay skills. Keys never change: rules.gd resolves a character's
## active skill through this table, and the practice sandbox reuses the same ids.
const SKILLS={
 "clone":{"name":"분신술","description":"현재 외형의 이동 분신을 8초 생성합니다.","cd":18.0,"icon":"clone","aim":false},
 "smoke":{"name":"연막술","description":"6초 동안 연막 너머의 시야를 가립니다.","cd":20.0,"icon":"smoke","aim":false},
 "blink":{"name":"순간이동","description":"조준 방향으로 120만큼 축지합니다. 벽은 통과하지 않습니다.","cd":10.0,"icon":"blink","aim":true},
 "transform":{"name":"사물 둔갑","description":"가까운 항아리·상자의 모습으로 9초 위장합니다. 다시 누르면 해제합니다.","cd":14.0,"icon":"jar","aim":false},
 "dash":{"name":"그림자 돌진","description":"조준 방향으로 160만큼 이동합니다. 벽은 통과하지 않습니다.","cd":14.0,"icon":"shadow","aim":true},
 "sense":{"name":"요기 감지","description":"4초 동안 가까운 실제 발자국을 확인합니다.","cd":18.0,"icon":"track","aim":false},
 "mimic":{"name":"외형 복제","description":"가까이 보이는 참가자의 외형·색상을 9초 복제합니다.","cd":25.0,"icon":"mimic","aim":false},
 "shield":{"name":"호신부","description":"8초 동안 다음 봉인 한 번을 막습니다.","cd":22.0,"icon":"shield","aim":false}}
const TEAM_NAMES={"daoist":"도사","yokai":"요괴"}
const TEAM_ROLES={"daoist":"생존/지원","yokai":"추적/봉인"}
## The 2:6 hunt roster: four daoists and four yokai. Every character keeps one of
## the eight shared skill ids as its in-match active ability (`key` on the ability
## that the game actually runs). `body` stays a wardrobe body, so the in-match
## actor always has a complete, valid appearance.
const ROSTER={
 "daoist":[
  {"id":"woochi","name":"전우치","body":"woochi","role":"교란·도주","intro":"둔갑과 분신으로 요괴를 속이는 도사","active":"clone","abilities":[
   {"key":"clone","name":"분신술","icon":"clone","cd":18.0,"description":"현재 모습 그대로 분신을 8초간 남겨 요괴의 시선을 끕니다."},
   {"key":"","name":"이동부","icon":"blink","cd":10.0,"description":"부적을 태워 조준한 방향으로 120만큼 순간이동합니다."},
   {"key":"","name":"둔갑술","icon":"jar","cd":14.0,"description":"가까운 항아리나 상자로 9초간 둔갑해 모습을 감춥니다."}]},
  {"id":"yeonhwa","name":"연화","body":"yeonhwa","role":"지원·구조","intro":"동료를 보호하고 봉인에서 구출하는 도사","active":"shield","abilities":[
   {"key":"shield","name":"보호결계","icon":"shield","cd":22.0,"description":"8초 동안 다음 봉인을 한 번 막아 주는 결계를 두릅니다."},
   {"key":"","name":"신속구조","icon":"rescue","cd":12.0,"description":"봉인된 동료 곁에서 구출 시간을 4초로 앞당깁니다."},
   {"key":"","name":"연꽃연막","icon":"smoke","cd":20.0,"description":"연꽃 향의 연기로 6초 동안 서로의 시야를 가립니다."}]},
  {"id":"muyeong","name":"무영","body":"muyeong","role":"은신·기동","intro":"그림자 사이를 이동하며 추격을 피하는 도사","active":"blink","abilities":[
   {"key":"","name":"그림자숨기","icon":"darkness","cd":24.0,"description":"그림자에 몸을 숨겨 6초 동안 모습을 감춥니다."},
   {"key":"blink","name":"그림자도약","icon":"blink","cd":10.0,"description":"그림자를 밟고 120만큼 앞으로 도약합니다."},
   {"key":"","name":"잔상술","icon":"shadow","cd":16.0,"description":"잔상을 남겨 요괴가 엉뚱한 곳을 쫓게 만듭니다."}]},
  {"id":"hongryeon","name":"홍련","body":"hongryeon","role":"방해·생존","intro":"불꽃으로 요괴의 추격을 방해하는 도사","active":"smoke","abilities":[
   {"key":"smoke","name":"화염장벽","icon":"fake_flame","cd":20.0,"description":"불꽃과 연기로 6초 동안 시야를 막는 장벽을 세웁니다."},
   {"key":"","name":"불꽃질주","icon":"dodge","cd":9.0,"description":"불꽃을 밟고 빠르게 달아나 추격을 뿌리칩니다."},
   {"key":"","name":"섬광부","icon":"talisman","cd":14.0,"description":"눈부신 부적으로 요괴의 시야를 잠시 잃게 합니다."}]}],
 "yokai":[
  {"id":"gumiho","name":"구미호","body":"yeonhwa","role":"기만·추적","intro":"환술과 변신으로 도사를 속이는 요괴","active":"mimic","abilities":[
   {"key":"mimic","name":"플레이어 둔갑","icon":"mask","cd":25.0,"description":"가까이 있는 도사의 외형을 9초간 복제해 혼란을 줍니다."},
   {"key":"","name":"여우불 추적","icon":"track","cd":18.0,"description":"4초 동안 도사가 남긴 실제 발자국을 드러냅니다."},
   {"key":"","name":"매혹환영","icon":"fake_flame","cd":20.0,"description":"매혹의 환영으로 도사를 불러 세운 뒤 추격합니다."}]},
  {"id":"jangsanbeom","name":"장산범","body":"muyeong","role":"추적·기습","intro":"목소리를 흉내 내며 먹잇감을 추격하는 요괴","active":"sense","abilities":[
   {"key":"","name":"목소리 흉내","icon":"mask","cd":16.0,"description":"도사의 목소리를 흉내 내 발길을 돌리게 만듭니다."},
   {"key":"","name":"맹수도약","icon":"dodge","cd":12.0,"description":"낮게 웅크렸다 크게 뛰어 순식간에 거리를 좁힙니다."},
   {"key":"sense","name":"기척감지","icon":"track","cd":18.0,"description":"4초 동안 숨은 도사의 실제 발자국을 읽습니다."}]},
  {"id":"dokkaebi","name":"도깨비","body":"woochi","role":"교란·봉쇄","intro":"장난스러운 도술로 도사의 탈출로를 막는 요괴","active":"transform","abilities":[
   {"key":"","name":"도깨비불","icon":"fake_flame","cd":14.0,"description":"정체 모를 도깨비불을 띄워 도사의 시선을 끕니다."},
   {"key":"","name":"방망이충격","icon":"attack","cd":12.0,"description":"장난감 방망이를 내리쳐 스턴과 함께 넉백시킵니다."},
   {"key":"transform","name":"길막환술","icon":"jar","cd":14.0,"description":"사물로 둔갑해 길목을 틀어막고 도사의 시야를 속입니다."}]},
  {"id":"haechi","name":"해치","body":"hongryeon","role":"수호·탐지","intro":"신비한 감각으로 숨은 도사를 찾아내는 추적자","active":"dash","abilities":[
   {"key":"","name":"진실의 눈","icon":"track","cd":18.0,"description":"4초 동안 숨은 도사와 발자국을 꿰뚫어 봅니다."},
   {"key":"dash","name":"돌진","icon":"dodge","cd":14.0,"description":"몸을 낮춰 160만큼 단숨에 돌진해 덮칩니다."},
   {"key":"","name":"봉인강화","icon":"shield","cd":22.0,"description":"8초 동안 봉인을 한 번 더 버티는 가호를 둡니다."}]}]}
static func catalog(team: String) -> Array:
 var result: Array=[]
 for entry in ROSTER.get(team,[]):
  result.append(character(team,entry))
 return result
static func character(team: String,entry: Dictionary) -> Dictionary:
 var id: String=entry.id
 var active: String=entry.active
 var skill: Dictionary=SKILLS[active].duplicate(true)
 # The in-match HUD names the ability the player actually won, not the shared id.
 for ability in entry.abilities:
  if ability.key==active:
   skill.name=ability.name;skill.description=ability.description
   break
 return {"id":team+":"+id,"name":entry.name,"team":team,"team_name":TEAM_NAMES[team],"role":entry.role,"intro":entry.intro,
  "body":entry.body,"sprite":PORTRAIT_DIR+id+"-full.png","portrait":PORTRAIT_DIR+id+"-portrait.png","animation":"native-eight-direction-rig",
  "speed":135.0,"run_speed":210.0,"jump_seconds":.8,
  "passive":"지속 능력 없음 · 공통 이동 성능","active":active,"skill":skill,
  "abilities":entry.abilities.duplicate(true),"description":entry.intro}
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
## 인게임 액터 구분용 색. 배경과 겹치지 않는 은은한 기운으로만 쓴다.
const TINTS={
 "daoist:woochi":Color("ffe0a8"),"daoist:yeonhwa":Color("ffadc4"),"daoist:muyeong":Color("a9b8ff"),"daoist:hongryeon":Color("ff9a76"),
 "yokai:gumiho":Color("ff9ee0"),"yokai:jangsanbeom":Color("8fc8ff"),"yokai:dokkaebi":Color("ffc46b"),"yokai:haechi":Color("7ef0d0")}
static func tint(id: String) -> Color:return TINTS.get(id,Color.WHITE)
static func look(id: String) -> Dictionary:
 var data:=find(id)
 return Looks.base_appearance(data.get("body","woochi"))
