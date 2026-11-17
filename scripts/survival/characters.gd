extends RefCounted
const Looks=preload("res://scripts/wardrobe/catalog.gd")
const SKILLS={
 "clone":{"name":"분신술","description":"현재 외형의 이동 분신을 8초 생성합니다.","cd":18.0,"icon":"clone","aim":false},
 "smoke":{"name":"연막술","description":"6초 동안 연막 너머의 시야를 가립니다.","cd":20.0,"icon":"smoke","aim":false},
 "blink":{"name":"순간이동","description":"조준 방향으로 120만큼 축지합니다. 벽은 통과하지 않습니다.","cd":10.0,"icon":"blink","aim":true},
 "transform":{"name":"사물 둔갑","description":"가까운 항아리·상자의 모습으로 9초 위장합니다. 다시 누르면 해제합니다.","cd":14.0,"icon":"jar","aim":false},
 "dash":{"name":"그림자 돌진","description":"조준 방향으로 160만큼 이동합니다. 벽은 통과하지 않습니다.","cd":14.0,"icon":"shadow","aim":true},
 "sense":{"name":"요기 감지","description":"4초 동안 가까운 실제 발자국을 확인합니다.","cd":18.0,"icon":"track","aim":false},
 "mimic":{"name":"외형 복제","description":"가까이 보이는 참가자의 외형·색상을 9초 복제합니다.","cd":25.0,"icon":"mimic","aim":false},
 "shield":{"name":"호신부","description":"8초 동안 다음 봉인 한 번을 막습니다.","cd":22.0,"icon":"shield","aim":false}}
static func catalog(team: String) -> Array:
 var result: Array=[]
 var keys: Array=["woochi","yeonhwa","muyeong","hongryeon"]
 var skills: Array=["clone","smoke","blink","transform"] if team=="daoist" else ["dash","sense","mimic","shield"]
 for i in range(4):
  var id: String=keys[i];var skill: String=skills[i]
  result.append({"id":team+":"+id,"name":Looks.CHARACTERS[id].name+" · 임시","team":team,"body":id,"sprite":"res://assets/woo/mascot/original/"+id+"-front.png","animation":"native-eight-direction-rig","speed":88.0,"run_speed":142.0,"jump_seconds":.8,"passive":"지속 능력 없음 · 공통 이동 성능","active":skill,"skill":SKILLS[skill],"description":"교체 가능한 테스트 캐릭터입니다. 최종 이름·능력은 미확정입니다."})
 return result
static func find(id: String) -> Dictionary:
 for team in ["daoist","yokai"]:
  for data in catalog(team):
   if data.id==id:return data.duplicate(true)
 return {}
static func look(id: String) -> Dictionary:
 var data:=find(id)
 return Looks.base_appearance(data.get("body","woochi"))
