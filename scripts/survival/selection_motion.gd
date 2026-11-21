extends RefCounted
## 2.0.37 선택창 10인 전용 등장·대기 모션.
## 예전에는 10명 모두 같은 걷기·같은 도술 루프라 "누가 누군지 모르겠다"는 지적이 있었다.
## 여기서는 캐릭터마다 확실히 다른 등장 연출(entry 0→1)과 대기 연출(idle)을 도형으로 그린다.
## 모든 그림은 원·선·다각형·사각형만 쓰므로 텍스처 없이 가볍게 그려진다.
const KITS={
 "woochi":{"name":"부적 회전 · 먹물 족자","clip":"spell","bob":2.4,"tilt":0.0},
 "gildong":{"name":"바람 잔상 · 2단 도약","clip":"jump","bob":5.0,"tilt":0.0},
 "yeongsil":{"name":"청동 톱니 · 별자리","clip":"gimmick_turnstile","bob":1.2,"tilt":0.0},
 "bari":{"name":"연꽃 개화 · 영혼 등불","clip":"match_join","bob":3.4,"tilt":0.0},
 "gangrim":{"name":"저승문 개방 · 걸어 나오기","clip":"door","bob":1.8,"tilt":0.0},
 "gumiho":{"name":"여우불 꼬리 3 · 실루엣 깜빡","clip":"spell","bob":2.8,"tilt":0.02},
 "jangsanbeom":{"name":"웅크렸다 도약 · 발톱 참격","clip":"attack","bob":0.8,"tilt":0.0},
 "dokkaebi":{"name":"방망이 쿵 · 도깨비불·금화","clip":"reward","bob":3.0,"tilt":0.03},
 "eoduksini":{"name":"그림자에서 솟아오름 · 보랏빛 눈","clip":"gimmick_lights_off","bob":1.4,"tilt":-0.02},
 "yagwanggwi":{"name":"귀화 통통 · 고개 갸웃","clip":"ui_tab","bob":6.0,"tilt":0.05}}
static func kit_of(art: String) -> Dictionary:return KITS.get(art,KITS["woochi"])
static func motion_name(art: String) -> String:return String(kit_of(art).get("name",""))
static func entry_clip(art: String) -> String:return String(kit_of(art).get("clip","spell"))
## 대기 중 몸이 흔들리는 정도(캐릭터별로 다르게).
static func bob_of(art: String) -> float:return float(kit_of(art).get("bob",2.0))
static func tilt_of(art: String) -> float:return float(kit_of(art).get("tilt",0.0))
## entry: 선택 직후 0→1 (약 0.9초), idle: 계속 흐르는 시간, size: 연출 반경(px).
static func draw(node: Node2D,art: String,entry: float,idle: float,size: float,accent: Color,facing: int=2) -> void:
 var s: float=size/540.0
 var e: float=clampf(entry,0.0,1.0)
 var t: float=idle
 match art:
  "woochi":_woochi(node,e,t,s,accent)
  "gildong":_gildong(node,e,t,s,accent)
  "yeongsil":_yeongsil(node,e,t,s,accent)
  "bari":_bari(node,e,t,s,accent)
  "gangrim":_gangrim(node,e,t,s,accent)
  "gumiho":_gumiho(node,e,t,s,accent)
  "jangsanbeom":_jangsanbeom(node,e,t,s,accent)
  "dokkaebi":_dokkaebi(node,e,t,s,accent)
  "eoduksini":_eoduksini(node,e,t,s,accent)
  "yagwanggwi":_yagwanggwi(node,e,t,s,accent)
  _:_woochi(node,e,t,s,accent)
## 공통: 부드러운 발광 원.
static func _glow(node: Node2D,at: Vector2,radius: float,color: Color) -> void:
 for i in range(4):
  var k: float=1.0-float(i)*.2
  node.draw_circle(at,radius*k,Color(color.r,color.g,color.b,color.a*.22))
## 전우치: 회전하는 부적 3장 + 위아래로 말리는 먹물 족자 + 좌우 분신이 합쳐진다.
static func _woochi(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var ink:=Color(.90,.86,.74)
 for i in range(3):
  var a:=t*1.6+float(i)*TAU/3.0
  var rad: float=(54.0+18.0*e+6.0*sin(t*2.0+float(i)))*s
  var at:=Vector2.from_angle(a)*rad+Vector2(0,-40.0*s)
  node.draw_set_transform(at,a,.9*Vector2.ONE)
  node.draw_rect(Rect2(Vector2(-5,-16)*s,Vector2(10,32)*s),Color(1,.88,.58,.55+.25*e))
  node.draw_rect(Rect2(Vector2(-5,-16)*s,Vector2(10,32)*s),Color(.42,.22,.08,.6),false,1.2)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 먹물 족자
 var height: float=92.0*e*s
 node.draw_rect(Rect2(Vector2(-14*s,-70*s-height*.5),Vector2(28*s,height)),Color(ink.r,ink.g,ink.b,.22))
 node.draw_rect(Rect2(Vector2(-14*s,-70*s-height*.5),Vector2(28*s,height)),Color(.5,.34,.18,.5),false,1.6)
 # 좌우 분신 실루엣이 합쳐진다
 var merge: float=1.0-e
 for side in [-1.0,1.0]:
  var at2:=Vector2(side*(30.0+90.0*merge)*s,-36*s)
  node.draw_set_transform(at2,0,Vector2(1,.7))
  node.draw_circle(Vector2.ZERO,(16.0-6.0*merge)*s,Color(accent.r,accent.g,accent.b,.18*merge))
  node.draw_arc(Vector2.ZERO,(16.0-6.0*merge)*s,0,TAU,20,Color(accent.r,accent.g,accent.b,.42*merge),1.8,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(7):
  var a2:=t*2.2+float(i)*TAU/7.0
  node.draw_circle(Vector2.from_angle(a2)*(26.0+40.0*e)*s+Vector2(0,-18*s),2.0*s,Color(.12,.09,.16,.45+.3*e))
## 홍길동: 좌우 바람 잔상 + 2단 도약 궤적 + 푸른 회오리.
static func _gildong(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var cyan:=Color(.62,.86,1)
 for i in range(4):
  var off: float=(1.0-e)*120.0+float(i)*16.0*sin(t*3.0+float(i))
  node.draw_line(Vector2(-90*s-off*s,-30*s-float(i)*12*s),Vector2(-160*s-off*s,-34*s-float(i)*12*s),Color(cyan.r,cyan.g,cyan.b,.40*e+.16),2.6*s,true)
  node.draw_line(Vector2(90*s+off*s,-30*s-float(i)*12*s),Vector2(160*s+off*s,-34*s-float(i)*12*s),Color(cyan.r,cyan.g,cyan.b,.40*e+.16),2.6*s,true)
 # 2단 도약: 그림자와 몸이 두 번 튀어 오른다.
 var hop: float=absf(sin(e*PI*2.0))*(1.0-maxf(0.0,e-.85)/.15)
 var height: float=hop*62.0*s
 node.draw_set_transform(Vector2(0,10*s),0,Vector2(1,.34))
 node.draw_circle(Vector2.ZERO,(26.0-8.0*hop)*s,Color(.02,.04,.08,.35))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(3):
  var a:=t*4.0+float(i)*TAU/3.0
  node.draw_arc(Vector2(0,-20*s-height),26.0*s+i*9.0*s,-PI*.9,-PI*.1,16,Color(cyan.r,cyan.g,cyan.b,.30+.18*sin(t*3.0+float(i))),2.2,true)
 for i in range(8):
  var a2:=float(i)*TAU/8.0-t*5.0
  node.draw_circle(Vector2.from_angle(a2)*(46.0+18.0*e)*s+Vector2(0,-18*s),1.8*s,Color(.86,.96,1,.55))
## 장영실: 청동 톱니 링 + 별자리 + 미니 기관인형 조립.
static func _yeongsil(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var bronze:=Color(.85,.66,.34)
 for i in range(14):
  var a:=t*.7+float(i)*TAU/14.0
  var inner: Vector2=Vector2.from_angle(a)*(70.0*s)
  var outer: Vector2=Vector2.from_angle(a)*(70.0+10.0*e)*s
  node.draw_line(inner,outer,Color(bronze.r,bronze.g,bronze.b,.75*e+.2),3.0*s,true)
  node.draw_circle(outer,2.0*s,Color(1,.9,.6,.8))
 node.draw_arc(Vector2(0,-34*s),70.0*s,0,TAU,48,Color(bronze.r,bronze.g,bronze.b,.55),2.0,true)
 # 별자리
 for i in range(7):
  var a2:=t*.5+float(i)*TAU/7.0
  var p:=Vector2.from_angle(a2)*(96.0*s)+Vector2(0,-34*s)
  node.draw_circle(p,2.2*s,Color(1,.96,.78,.55+.35*e))
  if i>0:
   var prev:=Vector2.from_angle(t*.5+float(i-1)*TAU/7.0)*(96.0*s)+Vector2(0,-34*s)
   node.draw_line(prev,p,Color(1,.92,.66,.22),1.2,true)
 # 미니 기관인형 조립: 3조각이 모여 하나가 된다.
 for i in range(3):
  var merge: float=1.0-e
  var base:=Vector2((float(i)-1.0)*36.0*merge,(float(i)-1.0)*20.0*merge-16*s)
  node.draw_rect(Rect2(base-Vector2(6,6)*s,Vector2(12,12)*s),Color(.30,.32,.34,.85))
  node.draw_rect(Rect2(base-Vector2(6,6)*s,Vector2(12,12)*s),Color(bronze.r,bronze.g,bronze.b,.8),false,1.2)
## 바리공주: 연꽃잎 개화 + 금빛·옥빛 영혼 등불 2개 선회.
static func _bari(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var gold:=Color(1,.84,.5)
 var jade:=Color(.62,.98,.86)
 var bloom: float=clampf(e*1.3,0.0,1.0)
 for i in range(8):
  var a:=float(i)*TAU/8.0+t*.35
  var rad: float=(28.0+56.0*bloom)*s
  var at:=Vector2.from_angle(a)*rad+Vector2(0,6*s)
  node.draw_set_transform(at,a+PI*.5,Vector2(1,.6))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-9,0)*s,Vector2(0,-20)*s,Vector2(9,0)*s,Vector2(0,7)*s]),Color(1,.86,.94,.30*bloom))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_arc(Vector2(0,6*s),34.0*s,0,TAU,40,Color(1,.86,.62,.40*bloom),2.0,true)
 for i in range(2):
  var a2:=t*1.2+PI*float(i)
  var lamp:=Vector2.from_angle(a2)*(64.0*s)+Vector2(0,-52*s+sin(t*1.8+float(i))*6.0*s)
  var tint:=gold if i==0 else jade
  node.draw_circle(lamp,10.0*s,Color(tint.r,tint.g,tint.b,.28))
  node.draw_rect(Rect2(lamp-Vector2(5,7)*s,Vector2(10,14)*s),Color(tint.r,tint.g,tint.b,.85))
  node.draw_rect(Rect2(lamp-Vector2(5,7)*s,Vector2(10,14)*s),Color(.5,.34,.12,.6),false,1.0)
## 강림도령: 등 뒤 푸른 저승문이 열리고 그 문에서 걸어 나온다 + 바닥 혼길표식.
static func _gangrim(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var teal:=Color(.5,.92,1)
 var open: float=clampf(e*1.6,0.0,1.0)
 var h: float=140.0*open*s
 var w: float=64.0*open*s
 var gate:=Vector2(0,-30*s)
 node.draw_rect(Rect2(gate-Vector2(w*.5,h*.5),Vector2(w,h)),Color(.02,.05,.12,.55*open))
 node.draw_rect(Rect2(gate-Vector2(w*.5,h*.5),Vector2(w,h)),Color(teal.r,teal.g,teal.b,.75),false,2.4)
 for i in range(6):
  var y: float=-h*.4+float(i)*h*.16
  node.draw_line(gate+Vector2(-w*.42,y),gate+Vector2(w*.42,y),Color(teal.r,teal.g,teal.b,.18*open),1.4,true)
 # 문에서 나오는 잔상 걸음
 var walk: float=(1.0-open)*70.0
 for i in range(3):
  var at:=gate+Vector2(0,h*.42)+Vector2(0,walk*s+float(i)*8.0*s)
  node.draw_set_transform(at,0,Vector2(1,.6))
  node.draw_arc(Vector2.ZERO,(18.0-float(i)*4.0)*s,0,TAU,20,Color(teal.r,teal.g,teal.b,.16*open),1.6,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 바닥 혼길표식
 node.draw_set_transform(Vector2(0,14*s),0,Vector2(1,.4))
 node.draw_arc(Vector2.ZERO,46.0*s,0,TAU,36,Color(teal.r,teal.g,teal.b,.55),2.6,true)
 node.draw_arc(Vector2.ZERO,34.0*s,0,TAU,30,Color(.7,1,1,.35+.2*sin(t*3.0)),1.8,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 구미호: 분홍 여우불 3개가 꼬리처럼 선회, 순간적으로 도사 실루엣이 깜빡인다.
static func _gumiho(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var pink:=Color(1,.62,.86)
 for i in range(3):
  var a:=t*1.1+float(i)*TAU/3.0
  var at:=Vector2.from_angle(a)*(70.0+12.0*e)*s+Vector2(0,-44*s+sin(t*2.0+float(i))*7.0*s)
  node.draw_circle(at,11.0*s,Color(pink.r,pink.g,pink.b,.22))
  node.draw_circle(at,5.0*s,Color(1,.85,.94,.85))
  # 꼬리 궤적
  for k in range(4):
   var a2:=a-0.10*float(k)
   node.draw_circle(Vector2.from_angle(a2)*(70.0+12.0*e)*s+Vector2(0,-44*s),(4.0-float(k)*.7)*s,Color(pink.r,pink.g,pink.b,.18))
 # 환상 실루엣 깜빡임
 var flick:=fmod(t,3.2)
 if flick>2.4:
  var alpha: float=sin((flick-2.4)/0.8*PI)*.30
  node.draw_set_transform(Vector2(0,-34*s),0,Vector2(1,.95))
  node.draw_circle(Vector2(0,-16*s),20.0*s,Color(.86,.92,1,alpha))
  node.draw_rect(Rect2(Vector2(-13*s,-4*s),Vector2(26*s,30*s)),Color(.86,.92,1,alpha))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 장산범: 낮게 웅크렸다 앞으로 훅, 흰 발톱 참격 + 음파 동심원.
static func _jangsanbeom(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var crouch: float=clampf(e/.45,0.0,1.0)
 var lunge: float=clampf((e-.45)/.55,0.0,1.0)
 var drop: float=(1.0-crouch)*0.0+crouch*10.0*s
 node.draw_set_transform(Vector2(0,10*s),0,Vector2(1,.36))
 node.draw_circle(Vector2.ZERO,(30.0+crouch*8.0)*s,Color(.01,.02,.05,.34))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if lunge>0.0 and lunge<1.0:
  for i in range(3):
   var a: float=-0.9+float(i)*0.55
   var from:=Vector2(-60*s+lunge*90*s,-30*s-float(i)*10*s)
   var to:=from+Vector2.from_angle(a)*(90.0*s)
   node.draw_line(from,to,Color(1,1,1,.75*(1.0-lunge)+.15),3.2*s,true)
 # 음파 동심원
 for i in range(3):
  var rad: float=(40.0+float(i)*26.0+fmod(t*40.0,26.0))*s
  node.draw_set_transform(Vector2(0,4*s),0,Vector2(1,.42))
  node.draw_arc(Vector2.ZERO,rad,0,TAU,40,Color(1,.88,.8,.24-i*.06),2.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 도깨비: 금빛 방망이를 크게 휘두르고 바닥 쿵 + 청록 도깨비불·금화가 튄다.
static func _dokkaebi(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var gold:=Color(1,.84,.42)
 var swing: float=clampf(e/.6,0.0,1.0)
 var angle: float=-2.2+swing*3.6
 var handle:=Vector2.from_angle(angle)*(46.0*s)+Vector2(0,-40*s)
 var head:=handle+Vector2.from_angle(angle)*(34.0*s)
 node.draw_line(Vector2(0,-30*s),handle,Color(.74,.56,.32,.95),4.0*s,true)
 node.draw_circle(head,13.0*s,Color(.88,.70,.42,.95))
 node.draw_circle(head,6.5*s,Color(1,.95,.74,.95))
 for i in range(5):
  var a:=angle+float(i)*TAU/5.0
  node.draw_circle(head+Vector2.from_angle(a)*(18.0+6.0*e)*s,2.2*s,Color(gold.r,gold.g,gold.b,.8))
 # 바닥 쿵
 if e>0.55:
  var hit: float=clampf((e-0.55)/0.45,0.0,1.0)
  node.draw_set_transform(Vector2(30*s,10*s),0,Vector2(1,.4))
  node.draw_arc(Vector2.ZERO,(20.0+70.0*hit)*s,0,TAU,40,Color(1,.86,.52,.55*(1.0-hit)),3.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  for i in range(6):
   var a2:=float(i)*TAU/6.0
   var p:=Vector2(30*s,10*s)+Vector2.from_angle(a2)*(30.0+60.0*hit)*s
   node.draw_circle(p,2.6*s,Color(1,.9,.5,.7*(1.0-hit)))
 # 도깨비불
 for i in range(4):
  var a3:=t*2.4+float(i)*TAU/4.0
  node.draw_circle(Vector2.from_angle(a3)*(64.0*s)+Vector2(0,-30*s),6.0*s,Color(.55,1,.78,.26+.2*sin(t*4.0+float(i))))
## 어둑시니: 그림자에서 서서히 솟아오르며 배경이 어두워지고 보랏빛 안광이 번뜩인다.
static func _eoduksini(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var violet:=Color(.72,.55,1)
 var rise: float=(1.0-clampf(e/.8,0.0,1.0))
 # 바닥 그림자가 먼저 번지고
 node.draw_set_transform(Vector2(0,12*s),0,Vector2(1,.34))
 node.draw_circle(Vector2.ZERO,(70.0+30.0*e)*s,Color(.01,.005,.03,.55*e+.12))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 솟아오르는 검은 연기 기둥
 for i in range(7):
  var k: float=float(i)/6.0
  var at:=Vector2(sin(t*1.4+k*3.0)*14.0*s,(-10.0-60.0*k*e)*s)
  node.draw_circle(at,(28.0-14.0*k)*s*e,Color(.03,.02,.06,.30*(1.0-k)))
 # 아직 올라오는 중이면 아래를 가리는 어둠
 if rise>0.02:
  node.draw_rect(Rect2(Vector2(-90*s,-20*s+30*s*(1.0-rise)),Vector2(180*s,120*s)),Color(.01,.01,.03,.55*rise))
 # 보랏빛 눈빛 두 개
 for i in range(2):
  var blink: float=.5+.5*sin(t*2.2+float(i)*.4)
  var at2:=Vector2((-9.0+18.0*float(i))*s,-58*s)
  node.draw_circle(at2,4.4*s,Color(violet.r,violet.g,violet.b,.35+.35*blink))
  node.draw_circle(at2,1.8*s,Color(.96,.9,1,.85))
## 야광귀: 푸른 귀화가 통통 튀고 고개 갸웃·좌우 스텝 + 짚신 불꽃.
static func _yagwanggwi(node: Node2D,e: float,t: float,s: float,accent: Color) -> void:
 var blue:=Color(.6,.9,1)
 var hop: float=absf(sin(t*3.6))*8.0*s
 for i in range(2):
  var side: float=(float(i)*2.0-1.0)
  var at:=Vector2(side*(18.0+6.0*sin(t*2.2))*s,0)
  node.draw_set_transform(at,0,Vector2(1,.4))
  node.draw_circle(Vector2.ZERO,9.0*s,Color(.08,.35,.55,.28))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  # 짚신 불꽃
  var flame:=Vector2(side*14.0*s,-2*s)
  node.draw_circle(flame-Vector2(0,hop),7.0*s,Color(blue.r,blue.g,blue.b,.28))
  node.draw_circle(flame+Vector2(0,-4*s-hop),3.4*s,Color(.9,.98,1,.85))
 # 푸른 귀화 3개가 머리 위에서 통통
 for i in range(3):
  var a:=t*2.0+float(i)*TAU/3.0
  var at2:=Vector2(cos(a)*(42.0*s),-70*s-hop+sin(a)*10.0*s)
  node.draw_circle(at2,6.0*s,Color(blue.r,blue.g,blue.b,.30))
  node.draw_circle(at2,2.6*s,Color(.95,1,1,.9))
 # 좌우 스텝 잔상
 for i in range(3):
  var k: float=(1.0-e)+float(i)*.16
  node.draw_line(Vector2((-70.0-30.0*k)*s,-6*s),Vector2((-40.0-20.0*k)*s,-6*s),Color(blue.r,blue.g,blue.b,.28),2.0*s,true)
  node.draw_line(Vector2((40.0+20.0*k)*s,-6*s),Vector2((70.0+30.0*k)*s,-6*s),Color(blue.r,blue.g,blue.b,.28),2.0*s,true)
