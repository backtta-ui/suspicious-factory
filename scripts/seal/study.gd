class_name SealStudy
extends RefCounted
## A short authoritative adventure on the existing forest; client cannot grant spell IDs.
const Arena=preload("res://scripts/seal/arena.gd")
const C=preload("res://scripts/seal/catalog.gd")
const POINTS=[Vector2(330,780),Vector2(440,690),Vector2(570,680),Vector2(670,610),Vector2(820,650),Vector2(940,680),Vector2(1030,610),Vector2(1140,690)]
const STORIES={"transform":"항아리 곁의 문양을 읽고 형상을 기억하세요.","blink":"길을 살펴 순간 이동 문양을 발견하세요.","clone":"겹쳐진 그림자에서 분신의 비밀을 찾으세요.","track":"돌길에 남은 발자국의 문양을 읽으세요.","shield":"돌등의 빛을 모아 호신부를 배웁니다.","smoke":"대나무 안개 속 연막 문양을 찾으세요.","mask":"둔갑술을 배운 뒤 감춰진 천면 문양을 읽으세요.","rescue":"봉인끈을 풀어 동료를 돕는 해봉술을 배웁니다."}
var arena:=Arena.new("forest")
var position:=Vector2(260,780)
var intent:=Vector2.ZERO
var facing:=0
var time:=0.0
var idle:=0.0
var owned: Array=[]
var challenge: Dictionary={}
func _init(learned: Array=[]) -> void:owned=learned.duplicate()
func tick(delta: float) -> void:idle+=delta;time+=delta;position=arena.move(position,position+intent*88*delta)
func command(data: Dictionary) -> Dictionary:
 idle=0.0
 var op: String=str(data.get("op",""))
 if op=="study_move":
  intent=C.vector(data.get("intent",[]))
  if intent.length()>.1:facing=posmod(roundi(intent.angle()/(PI/4)),8)
  return {}
 var skill: String=str(data.get("skill",""));var index:=C.COMMON.keys().find(skill)
 if index<0:return {"error":"등록되지 않은 발견 지점입니다"}
 if position.distance_to(POINTS[index])>78 or not arena.line(position,POINTS[index]):return {"error":"그림 속 도술 문양 가까이 접근하세요"}
 if skill=="mask" and not owned.has("transform"):return {"error":"먼저 둔갑술 문양을 배우세요"}
 if owned.has(skill):return {"notice":"이미 습득한 도술입니다"}
 if op=="study_open":
  var bytes:=Crypto.new().generate_random_bytes(3)
  challenge={"skill":skill,"nonce":Crypto.new().generate_random_bytes(8).hex_encode(),"pattern":[int(bytes[0])%4,int(bytes[1])%4,int(bytes[2])%4],"step":0,"began":time,"next":time+.4}
  return {"study_challenge":{"skill":skill,"nonce":challenge.nonce,"pattern":challenge.pattern,"step":0,"story":STORIES[skill]}}
 if op=="study_answer":
  if challenge.is_empty() or challenge.skill!=skill or str(data.get("nonce",""))!=challenge.nonce or time<challenge.next:return {"error":"수련 문양 또는 입력 시간을 확인하세요"}
  if not C.whole(data.get("answer",-1),0,3) or int(data.answer)!=int(challenge.pattern[challenge.step]):challenge={};return {"error":"문양이 다릅니다. 다시 살펴보세요"}
  challenge.step+=1;challenge.next=time+.4
  if challenge.step==3:owned.append(skill);challenge={};return {"learned":skill,"notice":C.COMMON[skill].name+"을 실제로 습득했습니다"}
  return {"study_challenge":{"skill":skill,"nonce":challenge.nonce,"pattern":challenge.pattern,"step":challenge.step,"story":STORIES[skill]}}
 return {}
func view() -> Dictionary:return {"position":[position.x,position.y],"facing":facing,"owned":owned.duplicate(),"points":POINTS.map(func(p: Vector2)->Array:return [p.x,p.y]),"time":time,"assets":arena.public_assets(time)}
