extends RefCounted
## 강남역 전용 상호작용 기믹 6종(2.0.34).
## 판정은 이 한 곳에서만 하고, 그림은 gangnam_world.gd와 CCTV 오버레이가
## 같은 상태를 읽어 그린다(보이는 것과 실제 효과가 어긋나지 않게).
##  - 개찰구: 도사가 통과하면 4초 잠김 → 요괴·추격자는 우회해야 한다.
##  - 에스컬레이터: 작동 방향으로 타면 가속. 요괴가 방향을 반대로 돌릴 수 있다.
##  - 자판기: 누르면 소음 파동. 근처 요괴에게 위치가 들린다(도사에겐 위험).
##  - CCTV: 관리실 모니터에서 대합실·카페·승강장·개찰구를 실시간 감시.
##  - 조명 스위치: 도사는 꺼서 암전(은신 유리), 요괴는 다시 켠다.
##  - 팝업존 셔터: 5초 동안 통로와 시야를 막는다.
const TURNSTILE_LOCK=4.0
const TURNSTILE_COOLDOWN=1.5
const ESCALATOR_FLIP=8.0
const NOISE_LIFE=3.0
const NOISE_RADIUS=620.0
const VENDING_COOLDOWN=4.0
const LIGHT_OFF_TIME=12.0
const CCTV_TIME=8.0
const SHUTTER_TIME=5.0
## rules를 강한 참조로 들면 rules↔gimmicks 순환이 생겨 경기 객체가 해제되지 않는다.
## (테스트 종료 시 스크립트 리소스 누수 경고의 원인) 그래서 약한 참조만 둔다.
var rules_ref: WeakRef
var defs: Array=[]
var state: Dictionary={}
var turnstile_until:=0.0
var turnstile_ready:=0.0
var escalator_dir:=1
var escalator_flip_until:=0.0
var shutter_until:=0.0
var lights: Dictionary={}
var cctv_zone:=""
var cctv_until:=0.0
var noise_pos:=Vector2.ZERO
var noise_until:=0.0
var noise_kind:=""
var cooldown: Dictionary={}
var last_message:=""
var last_message_until:=0.0
var _inside_gate: Dictionary={}
func R() -> RefCounted:return rules_ref.get_ref() if rules_ref!=null else null
func _now() -> float:
 var owner:=R()
 return float(owner.elapsed) if owner!=null else 0.0
func setup(owner: RefCounted) -> void:
 rules_ref=weakref(owner)
 reset()
func reset() -> void:
 var owner:=R()
 defs=owner.L.gimmicks() if owner!=null else []
 state.clear()
 turnstile_until=0.0;turnstile_ready=0.0;escalator_dir=1;escalator_flip_until=0.0
 shutter_until=0.0;lights.clear();cctv_zone="";cctv_until=0.0
 noise_pos=Vector2.ZERO;noise_until=0.0;noise_kind="";cooldown.clear();_inside_gate.clear()
 last_message="";last_message_until=0.0
static func kind_icon(kind: String) -> String:
 match kind:
  "turnstile":return "gate"
  "escalator":return "stairs"
  "vending":return "machine"
  "cctv":return "eye"
  "light":return "lamp"
  "shutter":return "shutter"
 return "gear"
func entry(id: String) -> Dictionary:
 for item in defs:
  if String(item.id)==id:return item
 return {}
func by_kind(kind: String) -> Array:
 var out: Array=[]
 for item in defs:
  if String(item.kind)==kind:out.append(item)
 return out
func entry_at(p: Vector2,reach: float=96.0) -> Dictionary:
 var best: Dictionary={};var gap:=reach
 for item in defs:
  var d: float=p.distance_to(item.pos)
  if d<gap:gap=d;best=item
 return best
func is_lock(kind: String) -> bool:return String(kind)==""
func blocked(p: Vector2) -> bool:
 if turnstile_until>_now():
  for item in by_kind("turnstile"):
   if (item.get("rect",Rect2()) as Rect2).grow(4).has_point(p):return true
 if shutter_until>_now():
  for item in by_kind("shutter"):
   if (item.get("rect",Rect2()) as Rect2).grow(4).has_point(p):return true
 return false
## 셔터는 시야도 막는다(요괴의 확인·투시가 통과하지 못한다).
func line_blocked(a: Vector2,b: Vector2) -> bool:
 if shutter_until<=_now():return false
 for item in by_kind("shutter"):
  var rect: Rect2=(item.get("rect",Rect2()) as Rect2).grow(2)
  if rect.intersects(Rect2(a,b-a)):return true
 return false
func zone_dark(zone_id: String) -> bool:
 if zone_id=="":return false
 return float(lights.get(zone_id,0.0))>_now()
func lit_zones() -> Dictionary:
 var out: Dictionary={}
 for key in lights.keys():
  if float(lights[key])>_now():out[key]=float(lights[key])-_now()
 return out
func say(text: String,seconds: float=2.6) -> void:
 last_message=text;last_message_until=_now()+seconds
## 상호작용: 가장 가까운 기믹 하나를 작동시킨다.
func interact(p: Dictionary) -> bool:
 if p.is_empty():return false
 var item:=entry_at(p.position,100.0)
 if item.is_empty():return false
 var id: String=String(item.id)
 var kind: String=String(item.kind)
 if float(cooldown.get(id,0.0))>_now():
  var left: float=float(cooldown[id])-_now()
  say("%s 재사용까지 %.1f초" % [String(item.get("label","기믹")),left],1.6)
  return true
 match kind:
  "turnstile":
   var left: float=turnstile_until-_now()
   say("개찰구가 잠겨 있습니다 · %.1f초" % maxf(0.0,left) if left>0.0 else "개찰구는 지나가면 잠깁니다",1.8)
   return true
  "escalator":
   if String(p.role)!="yokai":
    say("요괴만 에스컬레이터 방향을 바꿀 수 있습니다",1.8)
    return true
   escalator_dir=-escalator_dir
   escalator_flip_until=_now()+ESCALATOR_FLIP
   cooldown[id]=_now()+2.0
   say("에스컬레이터 방향 반전 · %s" % ("위로" if escalator_dir>0 else "아래로"),2.2)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
  "vending":
   noise_pos=item.pos;noise_until=_now()+NOISE_LIFE;noise_kind=id
   cooldown[id]=_now()+VENDING_COOLDOWN
   R().burst(item.pos,"fx_sound",1.2,{"big":true})
   R().event("gimmick",p.id,id,{"kind":kind})
   # 소음은 요괴 쪽에만 '들린다': 근처 요괴에게 위치 핑(미니맵·시야).
   for q in R().players.values():
    if String(q.role)!="yokai" or q.eliminated:continue
    if (q.position as Vector2).distance_to(item.pos)>NOISE_RADIUS:continue
    R().pings.append({"pos":item.pos,"until":_now()+2.4,"color":Color("ffd08a"),"target":q.id})
   say("자판기 소음 발생 · 근처 요괴에게 들립니다",2.2)
   return true
  "cctv":
   var zones: Array=R().L.CCTV_ZONES
   var index: int=maxi(0,zones.find(cctv_zone))
   if cctv_until<=_now() or cctv_zone=="":index=0
   else:index=(index+1)%zones.size()
   cctv_zone=String(zones[index])
   cctv_until=_now()+CCTV_TIME
   cooldown[id]=_now()+0.6
   say("CCTV · %s 감시 중" % String(R().L.zone(cctv_zone).get("name",cctv_zone)),2.0)
   R().event("gimmick",p.id,id,{"kind":kind,"zone":cctv_zone})
   return true
  "light":
   var zone_id: String=String(item.get("zone",""))
   var off: bool=zone_dark(zone_id)
   if off and String(p.role)!="yokai":
    say("암전 중입니다 · 요괴만 다시 켤 수 있습니다",1.8)
    return true
   if not off and String(p.role)=="yokai":
    say("도사가 불을 꺼야 암전이 시작됩니다",1.8)
    return true
   if off:
    lights.erase(zone_id)
    say("%s 조명 복구" % String(R().L.zone(zone_id).get("name","구역")),2.0)
   else:
    lights[zone_id]=_now()+LIGHT_OFF_TIME
    say("%s 암전 · %.0f초" % [String(R().L.zone(zone_id).get("name","구역")),LIGHT_OFF_TIME],2.2)
   cooldown[id]=_now()+1.0
   R().event("gimmick",p.id,id,{"kind":kind,"zone":zone_id})
   return true
  "shutter":
   shutter_until=_now()+SHUTTER_TIME
   cooldown[id]=_now()+SHUTTER_TIME+1.0
   say("팝업존 셔터 내려감 · %.0f초" % SHUTTER_TIME,2.0)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
 return false
func tick(_delta: float) -> void:
 var now:=_now()
 # 개찰구: 도사가 통과하는 순간 잠긴다(요괴는 우회). 잠금이 풀리면 쿨다운 표시.
 for item in by_kind("turnstile"):
  var rect: Rect2=(item.get("rect",Rect2()) as Rect2)
  for p in R().players.values():
   if String(p.role)!="daoist" or p.eliminated or p.captured:continue
   var inside: bool=rect.grow(10).has_point(p.position)
   var key: String=String(p.id)
   if inside and not bool(_inside_gate.get(key,false)) and turnstile_until<=now and now>=turnstile_ready:
    turnstile_until=now+TURNSTILE_LOCK
    turnstile_ready=turnstile_until+TURNSTILE_COOLDOWN
    R().burst(item.pos,"fx_door",0.7)
    R().event("gimmick",p.id,String(item.id),{"kind":"turnstile"})
   _inside_gate[key]=inside
 # 암전이 끝난 구역은 조명이 자동 복구된다.
 for zone_id in lights.keys():
  if float(lights[zone_id])<=now:lights.erase(zone_id)
 if cctv_until<=now:cctv_zone=""
 if noise_until<=now and noise_kind!="":noise_kind=""
## 화면·HUD가 읽는 한 줄 상태(잠금·암전·셔터·CCTV 남은 시간).
func status_lines() -> Array:
 var out: Array=[]
 var now:=_now()
 if turnstile_until>now:out.append({"kind":"turnstile","text":"개찰구 잠김 %.1f초" % (turnstile_until-now),"left":turnstile_until-now})
 elif turnstile_ready>now:out.append({"kind":"turnstile","text":"개찰구 재가동 %.1f초" % (turnstile_ready-now),"left":turnstile_ready-now})
 if shutter_until>now:out.append({"kind":"shutter","text":"팝업존 셔터 %.1f초" % (shutter_until-now),"left":shutter_until-now})
 for zone_id in lights.keys():
  if float(lights[zone_id])>now:out.append({"kind":"light","text":"%s 암전 %.0f초" % [String(R().L.zone(zone_id).get("name","구역")),float(lights[zone_id])-now],"left":float(lights[zone_id])-now})
 if cctv_until>now and cctv_zone!="":out.append({"kind":"cctv","text":"CCTV · %s" % String(R().L.zone(cctv_zone).get("name",cctv_zone)),"left":cctv_until-now})
 if escalator_flip_until>now:out.append({"kind":"escalator","text":"에스컬레이터 %s" % ("▲" if escalator_dir>0 else "▼"),"left":escalator_flip_until-now})
 return out
## 이 위치가 에스컬레이터 위인지(속도 보정용).
func on_escalator(p: Vector2) -> Dictionary:
 for item in by_kind("escalator"):
  var rect: Rect2=(item.get("rect",Rect2()) as Rect2)
  if rect.has_point(p):return item
 return {}
