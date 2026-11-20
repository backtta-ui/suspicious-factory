extends RefCounted
## 맵 기믹 판정(2.0.35). 그림은 각 맵 world가 같은 상태를 읽어 그리므로
## 보이는 것과 실제 효과가 어긋나지 않는다.
## 강남역: 개찰구 · 에스컬레이터 · 자판기 · CCTV · 조명 · 셔터
## 해운대: 파도 경보 · 밀물 · 샤워기 물안개 · 전망대 망원경 · 포장마차 주문벨 · 등대/천막 연출
## 동성로: 도술네컷 플래시 · 인형뽑기 소음 · 버스킹 스피커 · 아케이드 셔터 · 환풍기 연기 · 네온 연출
const TURNSTILE_LOCK=4.0
const TURNSTILE_COOLDOWN=1.5
const ESCALATOR_FLIP=8.0
const NOISE_LIFE=3.0
const NOISE_RADIUS=620.0
const VENDING_COOLDOWN=4.0
const LIGHT_OFF_TIME=12.0
const CCTV_TIME=8.0
const SHUTTER_TIME=5.0
const MIST_TIME=5.0
const MIST_COOLDOWN=12.0
const TELESCOPE_TIME=5.0
const TELESCOPE_COOLDOWN=14.0
const BELL_RADIUS=760.0
const FLASH_BLIND=1.2
const FLASH_COOLDOWN=10.0
const SPEAKER_TIME=7.0
const SPEAKER_RADIUS=300.0
const SPEAKER_COOLDOWN=14.0
const SMOKE_TIME=6.0
const SMOKE_COOLDOWN=12.0
const WAVE_PERIOD=26.0
const WAVE_TIME=6.0
const WAVE_SLOW=0.74
const TIDE_PERIOD=34.0
const TIDE_TIME=8.0
## rules를 강한 참조로 들면 rules↔gimmicks 순환이 생겨 경기 객체가 해제되지 않는다.
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
## 2.0.35 신규 기믹 상태.
var wave_until:=0.0
var wave_next:=12.0
var wave_zones: Array=[]
var tide_until:=0.0
var tide_next:=18.0
var tide_rect:=Rect2()
var mist_until:=0.0
var mist_zone:=""
var mist_pos:=Vector2.ZERO
var mist_radius:=250.0
var telescope_until:=0.0
var telescope_zones: Array=[]
var flash_until:=0.0
var flash_pos:=Vector2.ZERO
var flash_radius:=280.0
var speaker_until:=0.0
var speaker_pos:=Vector2.ZERO
var speaker_radius:=SPEAKER_RADIUS
var smoke_until:=0.0
var smoke_pos:=Vector2.ZERO
var smoke_radius:=230.0
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
 wave_until=0.0;wave_next=12.0;wave_zones=[]
 tide_until=0.0;tide_next=18.0;tide_rect=Rect2()
 mist_until=0.0;mist_zone="";mist_pos=Vector2.ZERO;mist_radius=250.0
 telescope_until=0.0;telescope_zones=[]
 flash_until=0.0;flash_pos=Vector2.ZERO;flash_radius=280.0
 speaker_until=0.0;speaker_pos=Vector2.ZERO;speaker_radius=SPEAKER_RADIUS
 smoke_until=0.0;smoke_pos=Vector2.ZERO;smoke_radius=230.0
 for item in defs:
  var kind: String=String(item.get("kind",""))
  var id: String=String(item.get("id",""))
  if kind=="wave":
   wave_zones=Array(item.get("zones",[]))
   wave_next=float(item.get("first",12.0))
  elif kind=="tide":
   tide_rect=item.get("rect",Rect2())
   tide_next=float(item.get("first",18.0))
  elif kind=="mist":
   mist_pos=item.get("pos",Vector2.ZERO)
   mist_radius=float(item.get("radius",250.0))
  elif kind=="flash":
   flash_pos=item.get("pos",Vector2.ZERO)
   flash_radius=float(item.get("radius",280.0))
  elif kind=="speaker":
   speaker_pos=item.get("pos",Vector2.ZERO)
   speaker_radius=float(item.get("radius",SPEAKER_RADIUS))
  elif kind=="smoke":
   smoke_pos=item.get("pos",Vector2.ZERO)
   smoke_radius=float(item.get("radius",230.0))
  state[id]=true
static func kind_icon(kind: String) -> String:
 match kind:
  "turnstile":return "gate"
  "escalator":return "stairs"
  "vending","bell","claw":return "machine"
  "cctv","telescope":return "eye"
  "light":return "lamp"
  "shutter":return "shutter"
  "wave":return "wave"
  "tide":return "tide"
  "mist","smoke":return "mist"
  "flash":return "flash"
  "speaker":return "sound"
  "lighthouse","wheel","arcade_gate","neon","stairs":return "lamp"
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
## 통행 차단: 잠긴 개찰구 · 내려온 셔터 · 밀물에 잠긴 지름길.
func blocked(p: Vector2) -> bool:
 var now:=_now()
 if turnstile_until>now:
  for item in by_kind("turnstile"):
   if (item.get("rect",Rect2()) as Rect2).grow(4).has_point(p):return true
 if shutter_until>now:
  for item in by_kind("shutter"):
   if (item.get("rect",Rect2()) as Rect2).grow(4).has_point(p):return true
 if tide_until>now and tide_rect.size.x>0.0 and tide_rect.grow(2).has_point(p):return true
 return false
func wave_active() -> bool:return wave_until>_now()
func tide_active() -> bool:return tide_until>_now()
func mist_active() -> bool:return mist_until>_now()
func fog_active() -> bool:return smoke_until>_now()
func flash_active() -> bool:return flash_until>_now()
func speaker_active() -> bool:return speaker_until>_now()
func telescope_active() -> bool:return telescope_until>_now()
## 파도 경보: 해안 구역에 있는 동안 이동이 느려진다(그림의 물결 띠와 같은 판정).
func speed_factor(p: Dictionary) -> float:
 var now:=_now()
 if wave_until<=now or wave_zones.is_empty() or p.is_empty():return 1.0
 var owner:=R()
 if owner==null:return 1.0
 var zone_id: String=String(owner.L.zone_at(p.position).get("id",""))
 if wave_zones.has(zone_id):return WAVE_SLOW
 return 1.0
## 조명이 꺼졌거나 물안개가 낀 구역은 멀리서 식별되지 않는다.
func zone_dark(zone_id: String) -> bool:
 if zone_id=="":return false
 return float(lights.get(zone_id,0.0))>_now()
func zone_mist(zone_id: String) -> bool:
 return mist_until>_now() and zone_id!="" and zone_id==mist_zone
func zone_obscured(zone_id: String) -> bool:
 return zone_dark(zone_id) or zone_mist(zone_id)
func lit_zones() -> Dictionary:
 var out: Dictionary={}
 for key in lights.keys():
  if float(lights[key])>_now():out[key]=float(lights[key])-_now()
 return out
## 버스킹 스피커가 발소리를 덮는 자리(발자국 표시를 지운다).
func trail_blocked(p: Vector2) -> bool:
 return speaker_until>_now() and p.distance_to(speaker_pos)<=speaker_radius
func line_blocked(a: Vector2,b: Vector2) -> bool:
 var now:=_now()
 if shutter_until>now:
  for item in by_kind("shutter"):
   var rect: Rect2=(item.get("rect",Rect2()) as Rect2).grow(2)
   if rect.intersects(Rect2(a,b-a)):return true
 ## 환풍기 연기: 원 안을 지나는 시선을 막는다(원 안에 있는 사람도 가려진다).
 if smoke_until>now and smoke_radius>0.0:
  var closest:=Geometry2D.get_closest_point_to_segment(smoke_pos,a,b)
  if closest.distance_to(smoke_pos)<=smoke_radius:return true
 return false
func say(text: String,seconds: float=2.6) -> void:
 last_message=text;last_message_until=_now()+seconds
## 소음: 근처 요괴에게 위치 핑(미니맵·시야). radius를 키우면 더 멀리 들린다.
func _noise(item: Dictionary,radius: float,tag: String,pid: String="") -> void:
 noise_pos=item.pos;noise_until=_now()+NOISE_LIFE;noise_kind=String(item.id)
 var owner:=R()
 owner.burst(item.pos,"fx_sound",1.2,{"big":true})
 owner.event("gimmick",pid,String(item.id),{"kind":String(item.kind)})
 for q in owner.players.values():
  if String(q.role)!="yokai" or q.eliminated:continue
  if (q.position as Vector2).distance_to(item.pos)>radius:continue
  owner.pings.append({"pos":item.pos,"until":_now()+2.4,"color":Color("ffd08a"),"target":q.id})
 say("%s 소음 발생 · 근처 요괴에게 들립니다"%tag,2.2)
## 상호작용: 가장 가까운 기믹 하나를 작동시킨다.
func interact(p: Dictionary) -> bool:
 if p.is_empty():return false
 var item:=entry_at(p.position,110.0)
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
   _noise(item,NOISE_RADIUS,"자판기",String(p.id))
   cooldown[id]=_now()+VENDING_COOLDOWN
   return true
  "bell":
   _noise(item,BELL_RADIUS,"포장마차 주문벨",String(p.id))
   cooldown[id]=_now()+6.0
   return true
  "claw":
   _noise(item,NOISE_RADIUS,"인형뽑기",String(p.id))
   cooldown[id]=_now()+5.0
   return true
  "cctv":
   var zones: Array=R().L.CCTV_ZONES
   if zones.is_empty():return false
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
   say("셔터 내려감 · %.0f초" % SHUTTER_TIME,2.0)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
  "mist":
   mist_until=_now()+MIST_TIME
   mist_zone=String(item.get("zone",""))
   mist_pos=item.pos
   cooldown[id]=_now()+MIST_COOLDOWN
   say("샤워기 물안개 · %.0f초 시야 감소" % MIST_TIME,2.2)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
  "telescope":
   telescope_until=_now()+TELESCOPE_TIME
   telescope_zones=[]
   var owner:=R()
   var seen:=0
   for q in owner.players.values():
    if q.id==p.id or q.eliminated:continue
    owner.pings.append({"pos":q.position,"until":_now()+TELESCOPE_TIME,"color":Color("8ff0ff"),"target":p.id})
    seen+=1
   cooldown[id]=_now()+TELESCOPE_COOLDOWN
   say("망원경 관측 · %d명 위치 확인" % seen,2.2)
   owner.event("gimmick",p.id,id,{"kind":kind})
   return true
  "flash":
   flash_until=_now()+0.9
   flash_pos=item.pos
   flash_radius=float(item.get("radius",280.0))
   var owner2:=R()
   var blinded:=0
   for q in owner2.players.values():
    if q.eliminated:continue
    if (q.position as Vector2).distance_to(item.pos)>flash_radius:continue
    if String(q.role)=="yokai":
     q.blind_until=maxf(float(q.get("blind_until",0.0)),_now()+FLASH_BLIND)
     blinded+=1
   noise_pos=item.pos;noise_until=_now()+NOISE_LIFE;noise_kind=id
   cooldown[id]=_now()+FLASH_COOLDOWN
   say("도술네컷 플래시 · 요괴 %d명 눈부심"%blinded,2.2)
   owner2.event("gimmick",p.id,id,{"kind":kind})
   return true
  "speaker":
   speaker_until=_now()+SPEAKER_TIME
   speaker_pos=item.pos
   speaker_radius=float(item.get("radius",SPEAKER_RADIUS))
   cooldown[id]=_now()+SPEAKER_COOLDOWN
   say("버스킹 스피커 · %.0f초 발소리 교란"%SPEAKER_TIME,2.2)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
  "smoke":
   smoke_until=_now()+SMOKE_TIME
   smoke_pos=item.pos
   smoke_radius=float(item.get("radius",230.0))
   cooldown[id]=_now()+SMOKE_COOLDOWN
   say("환풍기 연기 · %.0f초 시야 차단"%SMOKE_TIME,2.2)
   R().event("gimmick",p.id,id,{"kind":kind})
   return true
  "lighthouse","tent","wheel","arcade_gate","stairs","neon":
   say(String(item.get("label","연출"))+" · "+String(item.get("hint","")),2.0)
   cooldown[id]=_now()+2.0
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
 # 파도 경보: 주기적으로 해안가를 덮친다(감속은 speed_factor가 판정).
 var wave: Dictionary=entry_at_wave()
 if not wave.is_empty():
  if now>=wave_next:
   wave_until=now+float(wave.get("duration",WAVE_TIME))
   wave_next=now+float(wave.get("period",WAVE_PERIOD))
   R().burst(wave.get("pos",R().L.SPAWN),"fx_wave",2.0,{"big":true})
   R().event("gimmick","",String(wave.id),{"kind":"wave"})
   say("파도 경보 · 해안가 이동이 느려집니다",2.4)
 # 밀물: 지름길(동백섬 다리)이 잠깐 잠긴다. 데크 두 갈래는 늘 열려 있다.
 var tide: Dictionary=entry_at_tide()
 if not tide.is_empty():
  if now>=tide_next:
   tide_until=now+float(tide.get("duration",TIDE_TIME))
   tide_next=now+float(tide.get("period",TIDE_PERIOD))
   tide_rect=tide.get("rect",tide_rect)
   R().event("gimmick","",String(tide.id),{"kind":"tide"})
   say("밀물 · 다리 지름길이 잠깁니다 · 데크로 우회",2.6)
 # 암전·물안개·연기·플래시·스피커 만료
 for zone_id in lights.keys():
  if float(lights[zone_id])<=now:lights.erase(zone_id)
 if cctv_until<=now:cctv_zone=""
 if noise_until<=now and noise_kind!="":noise_kind=""
 if mist_until<=now:mist_zone=""
 if flash_until<=now:flash_pos=Vector2.ZERO
func entry_at_wave() -> Dictionary:
 for item in defs:
  if String(item.kind)=="wave":return item
 return {}
func entry_at_tide() -> Dictionary:
 for item in defs:
  if String(item.kind)=="tide":return item
 return {}
## 화면·HUD가 읽는 한 줄 상태(잠금·암전·셔터·CCTV·파도·밀물·연무 남은 시간).
func status_lines() -> Array:
 var out: Array=[]
 var now:=_now()
 if turnstile_until>now:out.append({"kind":"turnstile","text":"개찰구 잠김 %.1f초" % (turnstile_until-now),"left":turnstile_until-now})
 elif turnstile_ready>now:out.append({"kind":"turnstile","text":"개찰구 재가동 %.1f초" % (turnstile_ready-now),"left":turnstile_ready-now})
 if shutter_until>now:out.append({"kind":"shutter","text":"셔터 %.1f초" % (shutter_until-now),"left":shutter_until-now})
 if tide_until>now:out.append({"kind":"tide","text":"밀물 · 지름길 침수 %.1f초" % (tide_until-now),"left":tide_until-now})
 if wave_until>now:out.append({"kind":"wave","text":"파도 경보 · 해안 감속 %.1f초" % (wave_until-now),"left":wave_until-now})
 for zone_id in lights.keys():
  if float(lights[zone_id])>now:out.append({"kind":"light","text":"%s 암전 %.0f초" % [String(R().L.zone(zone_id).get("name","구역")),float(lights[zone_id])-now],"left":float(lights[zone_id])-now})
 if mist_until>now:out.append({"kind":"mist","text":"물안개 · %s 시야 감소 %.1f초" % [String(R().L.zone(mist_zone).get("name","구역")),mist_until-now],"left":mist_until-now})
 if smoke_until>now:out.append({"kind":"smoke","text":"환풍기 연기 %.1f초" % (smoke_until-now),"left":smoke_until-now})
 if flash_until>now:out.append({"kind":"flash","text":"플래시", "left":flash_until-now})
 if speaker_until>now:out.append({"kind":"speaker","text":"발소리 교란 %.1f초" % (speaker_until-now),"left":speaker_until-now})
 if cctv_until>now and cctv_zone!="":out.append({"kind":"cctv","text":"CCTV · %s" % String(R().L.zone(cctv_zone).get("name",cctv_zone)),"left":cctv_until-now})
 if escalator_flip_until>now:out.append({"kind":"escalator","text":"에스컬레이터 %s" % ("▲" if escalator_dir>0 else "▼"),"left":escalator_flip_until-now})
 return out
## 이 위치가 에스컬레이터 위인지(속도 보정용).
func on_escalator(p: Vector2) -> Dictionary:
 for item in by_kind("escalator"):
  var rect: Rect2=(item.get("rect",Rect2()) as Rect2)
  if rect.has_point(p):return item
 return {}
