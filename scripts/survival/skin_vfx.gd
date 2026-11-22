extends RefCounted
## 2.0.38 스킨 전용 VFX 훅.
##
## 같은 캐릭터라도 어떤 스킨을 입었는지에 따라 도술 연출이 완전히 달라져야 한다.
## (기본 전우치 = 먹·부적·산수 족자 / 부침개 전우치 = 무쇠팬·반죽·고춧가루)
## 새 스킨은 SKILL_VFX에 한 줄만 추가하면 3도술 모두 전용 연출을 얻는다.
## 규칙·판정은 건드리지 않고 그리기만 바꾼다.
const PANCAKE="woochi_pancake"
## 스킨 id → {도술 id: 연출 id}. 등록되지 않은 도술은 기본 연출을 쓴다.
const SKILL_VFX={
 "woochi_pancake":{"clone":"pancake_clone","transform":"pancake_flip","painting":"pancake_pan"}}
const GOLD=Color("ffd27a")
const BATTER=Color("f2c46a")
const CHILI=Color("e0473c")
const IRON=Color("2a2730")
## 이 스킨·도술에 전용 연출이 있는지(테스트·문서용).
static func key_for(skin: String,skill_id: String) -> String:
 var book: Dictionary=SKILL_VFX.get(skin,{})
 return String(book.get(skill_id,""))
## 전용 연출이 있으면 그리고 true. 없으면 false(기본 signature가 그린다).
static func draw(node: Node2D,at: Vector2,p: float,skin: String,skill_id: String,facing: float) -> bool:
 var key:=key_for(skin,skill_id)
 if key=="":return false
 var center:=at-Vector2(0,20)
 match key:
  "pancake_pan":pancake_pan(node,center,p,facing)
  "pancake_flip":pancake_flip(node,center,p,facing)
  "pancake_clone":pancake_clone(node,center,p,facing)
  _:return false
 return true
## 4단계(차지→발동→지속→소멸) 공통 뼈대.
static func stages(p: float) -> Dictionary:
 return {"prep":clampf(p/0.16,0.0,1.0),"burst":clampf((p-0.16)/0.14,0.0,1.0),
  "sustain":clampf((p-0.30)/0.45,0.0,1.0),"fade":clampf((p-0.78)/0.22,0.0,1.0)}
## 화중은신(궁극기): 먹빛 고리 대신 무쇠팬 테두리 + 지글거리는 반죽 + 고춧가루.
static func pancake_pan(node: Node2D,center: Vector2,p: float,facing: float) -> void:
 var s:=stages(p)
 var alpha:=1.0-float(s.fade)
 var radius:=lerpf(20.0,58.0,float(s.burst))
 # 1) 무쇠팬: 두꺼운 검은 테두리 + 금속 하이라이트 + 손잡이.
 node.draw_set_transform(center+Vector2(0,10),0,Vector2(1,.52))
 node.draw_circle(Vector2.ZERO,radius+4.0,Color(IRON.r,IRON.g,IRON.b,.66))
 node.draw_arc(Vector2.ZERO,radius+2.0,0,TAU,64,Color(.55,.52,.60,.85),3.0,true)
 node.draw_arc(Vector2.ZERO,radius-1.0,0,TAU,64,Color(1,.86,.55,.55),2.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var handle_dir:=Vector2.from_angle(facing*PI/4+PI)
 var pan_center:=center+Vector2(0,10)
 node.draw_line(pan_center+handle_dir*radius,pan_center+handle_dir*(radius+34.0),Color(IRON.r,IRON.g,IRON.b,.95),9.0,true)
 node.draw_line(pan_center+handle_dir*radius,pan_center+handle_dir*(radius+34.0),Color(.42,.36,.30,.95),4.0,true)
 node.draw_circle(pan_center+handle_dir*(radius+36.0),6.0,Color(.30,.24,.20,.95))
 # 2) 팬 안의 김치전 반죽: 노란 반죽 + 붉은 김치 조각 + 초록 쪽파.
 for i in range(9):
  var a:=float(i)*TAU/9.0+p*0.6
  var r:=radius*(0.18+0.42*float((i*37)%10)/10.0)
  var pos:=center+Vector2(0,10)+Vector2.from_angle(a)*r
  var tone:=CHILI if i%3==0 else (Color(.42,.62,.32) if i%4==1 else BATTER)
  node.draw_set_transform(pos,0,Vector2(1,.62))
  node.draw_circle(Vector2.ZERO,7.0-float(i%3),Color(tone.r,tone.g,tone.b,.90*alpha))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 3) 지글거리는 기름: 팬 테두리에서 튀는 작은 방울 + 파티클.
 for i in range(10):
  var t:=fmod(p*1.7+float(i)*0.13,1.0)
  var a2:=float(i)*TAU/10.0+float(i)*0.7
  var from_r:=radius*0.9
  var pos2:=center+Vector2.from_angle(a2)*(from_r+t*22.0)-Vector2(0,t*t*30.0)
  node.draw_circle(pos2,2.6*(1.0-t),Color(1,.94,.72,.75*alpha*(1.0-t)))
 # 4) 김이 모락모락(따뜻한 흰 김).
 for i in range(4):
  var rise:=fmod(p*1.2+float(i)*0.25,1.0)
  var steam:=center+Vector2(sin(p*6.0+float(i)*1.7)*16.0,-18.0-rise*46.0)
  node.draw_circle(steam,9.0+rise*10.0,Color(.96,.94,.90,.09*alpha*(1.0-rise)))
 # 5) 발동 섬광: 금빛 테두리 한 번.
 if float(s.burst)>0.0 and float(s.burst)<1.0:
  node.draw_set_transform(center,0,Vector2(1,.52))
  node.draw_arc(Vector2.ZERO,radius+14.0*(1.0-float(s.burst)),0,TAU,56,Color(1,.85,.50,.45*(1.0-float(s.burst))),5.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 둔갑술: 부침개를 뒤집는 손목 동작 — 반죽 원반이 떠올라 한 바퀴 돌고 연기가 퍼진다.
static func pancake_flip(node: Node2D,center: Vector2,p: float,facing: float) -> void:
 var s:=stages(p)
 var alpha:=1.0-float(s.fade)
 var dir:=Vector2.from_angle(facing*PI/4)
 # 팬(작게) + 손잡이
 node.draw_set_transform(center+Vector2(0,16),0,Vector2(1,.45))
 node.draw_circle(Vector2.ZERO,30.0,Color(IRON.r,IRON.g,IRON.b,.85))
 node.draw_arc(Vector2.ZERO,30.0,0,TAU,40,Color(.60,.55,.62,.8),2.4,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_line(center+Vector2(0,16)+dir*30.0,center+Vector2(0,16)+dir*54.0,Color(.36,.30,.26,.95),6.0,true)
 # 반죽 원반: 위로 떠올랐다가 회전하며 내려온다(뒤집기 궤적).
 var arc:=sin(clampf(p*1.25,0.0,1.0)*PI)
 var disc:=center+Vector2(dir.x*8.0,-10.0-arc*40.0)
 var spin:=p*10.0
 node.draw_set_transform(disc,0,Vector2(1,.42+absf(cos(spin))*0.55))
 node.draw_circle(Vector2.ZERO,18.0,Color(BATTER.r,BATTER.g,BATTER.b,.92*alpha))
 node.draw_arc(Vector2.ZERO,18.0,0,TAU,28,Color(.62,.42,.18,.9*alpha),2.4,true)
 for i in range(5):
  var a:=float(i)*TAU/5.0+spin
  node.draw_circle(Vector2.from_angle(a)*9.0,3.0,Color(CHILI.r,CHILI.g,CHILI.b,.8*alpha) if i%2==0 else Color(.40,.60,.30,.8*alpha))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 연기: 팬에서 퍼지는 둥근 연기 덩어리(둔갑 뽀옥).
 for i in range(7):
  var a2:=float(i)*TAU/7.0+p*1.6
  var pos:=center+Vector2(0,14)+Vector2.from_angle(a2)*(10.0+float(s.burst)*26.0)
  node.draw_circle(pos,10.0+float(s.burst)*8.0,Color(.90,.86,.80,.16*alpha))
 # 튀는 기름/참깨
 for i in range(8):
  var a3:=float(i)*TAU/8.0+p*2.0
  var pos3:=center+Vector2.from_angle(a3)*(20.0+p*34.0)+Vector2(0,-p*24.0)
  node.draw_circle(pos3,2.0,Color(1,.94,.72,.7*(1.0-p)))
## 분신술: 금빛 팬·뒤집개 궤적이 좌우로 갈라지며 두 반죽 실루엣을 남긴다.
static func pancake_clone(node: Node2D,center: Vector2,p: float,facing: float) -> void:
 var s:=stages(p)
 var alpha:=1.0-float(s.fade)
 # 뒤집개(스패출러)가 그리는 금빛 궤적 두 줄.
 for side in [-1.0,1.0]:
  var sweep:=Vector2(side*26.0,-6.0)
  var pts:=PackedVector2Array()
  for i in range(9):
   var t:=float(i)/8.0
   var a:=lerpf(-0.9,0.9,t)*(0.6+0.4*float(s.sustain))
   pts.append(center+sweep+Vector2.from_angle(a+PI*0.5)* (18.0+t*10.0)+Vector2(side*t*26.0,-t*10.0))
  node.draw_polyline(pts,Color(GOLD.r,GOLD.g,GOLD.b,.55*alpha),6.0,true)
  node.draw_polyline(pts,Color(1,1,1,.35*alpha),2.4,true)
  # 뒤집개 실루엣(손잡이 + 넓은 머리)
  var base:=center+sweep+Vector2(0,4)
  node.draw_line(base,base+Vector2(side*18.0,-22.0),Color(.30,.26,.24,.95),4.4,true)
  node.draw_set_transform(base+Vector2(side*18.0,-22.0),side*0.6,Vector2(1,.6))
  node.draw_rect(Rect2(-7,-9,14,16),Color(.85,.88,.92,.95))
  node.draw_rect(Rect2(-7,-9,14,16),Color(.45,.48,.52,.95),false,1.6)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  # 갈라진 반죽 실루엣(금빛 원반 + 김)
  var disc:=center+sweep*1.6-Vector2(0,10)
  node.draw_set_transform(disc,0,Vector2(1,.62))
  node.draw_circle(Vector2.ZERO,11.0,Color(BATTER.r,BATTER.g,BATTER.b,.55*alpha))
  node.draw_arc(Vector2.ZERO,11.0,0,TAU,22,Color(GOLD.r,GOLD.g,GOLD.b,.75*alpha),2.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(6):
  var a:=float(i)*TAU/6.0+p*2.2
  node.draw_circle(center+Vector2.from_angle(a)*(18.0+float(s.burst)*26.0),2.2,Color(1,.92,.62,.7*alpha))
## 기본 전우치(먹·부적) 화중은신: 검은 먹 고리 + 금빛 부적이 감싼다.
static func ink_talisman(node: Node2D,center: Vector2,p: float) -> void:
 var alpha:=1.0-p
 var ink:=Color(.06,.05,.10,.55*alpha)
 node.draw_set_transform(center+Vector2(0,10),0,Vector2(1,.44))
 node.draw_arc(Vector2.ZERO,26.0+p*18.0,0,TAU,40,ink,6.0,true)
 node.draw_arc(Vector2.ZERO,34.0+p*24.0,0,TAU,40,Color(.30,.22,.42,.28*alpha),3.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(6):
  var a:=float(i)*TAU/6.0+p*1.1
  var pos:=center+Vector2.from_angle(a)*(30.0+p*22.0)-Vector2(0,8)
  node.draw_set_transform(pos,a+PI*.5,Vector2(1,.62))
  node.draw_rect(Rect2(-4,-8,8,16),Color(1,.90,.58,.90*alpha))
  node.draw_rect(Rect2(-4,-8,8,16),Color(.85,.45,.20,.75*alpha),false,1.0)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
