extends RefCounted
## 도술 이펙트: 화면을 가리지 않는 얇은 빛·부적·불꽃만 그린다.
## 모든 형태는 원/선/다각형 몇 개로 끝나며 텍스처·폰트를 새로 만들지 않는다.
## 2.0.27: 캐릭터 30개 능력마다 개성 있는 2.5D 도술(부적 흩날림·여우불·도깨비불·
## 그림자 안개·연꽃 빛·천문진·황금 파동·음파·기관·표식)을 따로 그린다.
const GOLD=Color("f0c46a")
const TALISMAN=Color("ffd98a")
const FOX=Color("7fe4d6")
const FLAME=Color("ff8a3c")
const GHOST=Color("8fd8ff")
const SHADOW=Color("b48cf0")
const LOTUS=Color("ffb9cf")
const GOBLIN=Color("8ff0c8")
static func draw(node: Node2D,e: Dictionary,now: float) -> void:
 var life: float=maxf(.01,float(e.get("until",now+.5))-float(e.get("born",now)))
 var p: float=clampf((now-float(e.get("born",now)))/life,0,1)
 var at: Vector2=e.get("position",Vector2.ZERO)
 var facing: float=float(e.get("facing",0))
 match String(e.get("kind","")):
  "fx_talisman":talisman(node,at,p,facing)
  "fx_stamp":stamp(node,at,p,facing)
  "fx_foxfire":foxfire(node,at,p)
  "fx_flame":flame(node,at,p)
  "fx_ghost":ghost(node,at,p)
  "fx_shadow":shadow(node,at,p,facing)
  "fx_poof":poof(node,at,p)
  "fx_rescue":rescue(node,at,p)
  "fx_door":door(node,at,p)
  "fx_lotus":lotus(node,at,p)
  "fx_astrolabe":astrolabe(node,at,p)
  "fx_goldwave":goldwave(node,at,p)
  "fx_darkness":darkness(node,at,p)
  "fx_goblinfire":goblinfire(node,at,p)
  "fx_howl":howl(node,at,p)
  "fx_wind":wind(node,at,p,facing)
  "fx_gear":gear(node,at,p)
  "fx_trap":trap(node,at,p)
  "fx_chain":chain(node,at,p)
  "fx_ghostgate":ghostgate(node,at,p)
  "fx_soulmark":soulmark(node,at,p)
  "fx_mist":mist(node,at,p)
  "fx_powder":powder(node,at,p)
  "fx_sound":sound(node,at,p)
  "fx_ink":ink(node,at,p)
  "fx_scroll":scroll(node,at,p,facing)
  "fx_sig":signature(node,at,p,String(e.get("skill","")),float(e.get("facing",0)))
  "fx_png":png_burst(node,at,p,e)
  "seal":seal(node,at,p)
  "miss":miss(node,at,p)
  "clone":afterimage(node,at,p,facing)
  "afterimage":afterimage(node,at,p,facing)
  "smoke":haze(node,at,p)
## 2.0.34: 캐릭터·스킨 전용 손그림 이펙트 PNG. 도술 모션과 같은 박자로
## 커졌다가 위로 떠오르며 옅어진다(모션과 한 몸처럼 보이게).
static func png_burst(node: Node2D,at: Vector2,p: float,e: Dictionary) -> void:
 ## 텍스처는 rules.signature가 _draw 밖에서 미리 load해 effect에 담아 둔다.
 ## (_draw 안에서 처음 load하면 플레이스홀더(흰 사각형)가 나오는 경우가 있었다.)
 var texture: Texture2D=e.get("texture")
 if texture==null:
  var file: String=String(e.get("file",""))
  if file=="" or not ResourceLoader.exists(file):return
  texture=load(file)
 if texture==null:return
 var ease_out: float=1.0-pow(1.0-p,2.2)
 var grow: float=lerpf(.62,1.16,ease_out)
 var alpha: float=clampf(1.25-p*1.45,0.0,1.0)
 var lift: float=p*30.0
 var size: Vector2=texture.get_size()
 var scale_value: float=150.0/maxf(1.0,maxf(size.x,size.y))
 node.draw_set_transform(at+Vector2(0,-26-lift),0.0,Vector2(grow*scale_value,grow*scale_value))
 node.draw_texture(texture,-size*.5,Color(1,1,1,alpha))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 ## 바닥에는 같은 색의 옅은 충격 고리가 함께 퍼진다.
 node.draw_set_transform(at,0,Vector2(1,.45))
 node.draw_arc(Vector2.ZERO,10+p*44,0,TAU,30,Color(1,.88,.6,.22*(1.0-p)),2.2,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
static func talisman(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 for i in range(6):
  var angle:=facing*PI/4+i*.6+p*2.4
  var radius:=10+p*30
  var pos:=at+Vector2.from_angle(angle)*radius-Vector2(0,14)
  node.draw_set_transform(pos,angle,Vector2(1,.65))
  node.draw_rect(Rect2(-4,-7,8,14),Color(1,.85,.5,alpha*.9))
  node.draw_rect(Rect2(-4,-7,8,14),Color(1,.62,.25,alpha*.7),false,1)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_arc(at-Vector2(0,10),8+p*26,0,TAU,28,Color(1,.87,.55,alpha*.5),2,true)
 for i in range(6):
  var q:=at+Vector2.from_angle(i*TAU/6+p)*(20+p*34)
  node.draw_circle(q,1.8,Color(1,.9,.6,alpha*.7))
## 부적 흩날림: 먹 붓으로 그린 부적 여러 장이 회오리쳐 사라진다.
static func stamp(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,22)
 for i in range(10):
  var a:=facing*PI/4+i*TAU/10+p*3.2
  var radius:=14+p*52
  var pos:=center+Vector2.from_angle(a)*radius+Vector2(0,p*20)
  var tilt:=a+p*2.0
  node.draw_set_transform(pos,tilt,Vector2(1,.7))
  var tone:=Color(1,.92,.68,alpha*.92) if i%3!=0 else Color(1,.74,.42,alpha*.9)
  node.draw_rect(Rect2(-5,-9,10,18),tone)
  node.draw_rect(Rect2(-5,-9,10,18),Color(.85,.42,.18,alpha*.75),false,1)
  node.draw_line(Vector2(0,-5),Vector2(0,6),Color(.55,.18,.12,alpha*.8),1)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_arc(center,16+p*44,0,TAU,40,Color(1,.86,.55,alpha*.35),2.4,true)
 for i in range(8):
  var q:=center+Vector2.from_angle(i*TAU/8-p*2.0)*(24+p*58)
  node.draw_circle(q,1.6,Color(1,.95,.78,alpha*.8))
static func foxfire(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(4):
  var angle:=i*TAU/4+p*3.0
  var pos:=at+Vector2.from_angle(angle)*(6+p*30)-Vector2(0,18+p*8)
  node.draw_circle(pos,6.0,Color(.5,1,.92,alpha*.85))
  node.draw_circle(pos,2.6,Color(.94,1,.99,alpha))
  node.draw_line(pos,pos+Vector2.from_angle(angle+PI)*(12+p*10),Color(.45,.95,.9,alpha*.30),3)
 node.draw_arc(at-Vector2(0,18),12+p*26,0,TAU,24,Color(.5,1,.92,alpha*.22),1.5,true)
static func flame(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(4):
  var wiggle:=sin(p*12+i)*3
  var h:=18+p*22+i*3
  var base:=at+Vector2(-9+i*6,0)
  node.draw_colored_polygon(PackedVector2Array([base+Vector2(-7,0),base+Vector2(wiggle,-h),base+Vector2(7,0)]),Color(1,.45+i*.06,.15,alpha*.55))
  node.draw_colored_polygon(PackedVector2Array([base+Vector2(-3,0),base+Vector2(wiggle*.6,-h*.6),base+Vector2(3,0)]),Color(1,.82,.4,alpha*.7))
 for i in range(7):
  var q:=at+Vector2(sin(i*2.1+p*4)*22,-14-p*40-Art_shade(i)*20)
  node.draw_circle(q,1.6,Color(1,.7,.3,alpha*.8))
 node.draw_arc(at,10+p*30,PI,TAU,24,Color(1,.55,.2,alpha*.3),2,true)
static func ghost(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(5):
  var angle:=i*TAU/5+p*2.0
  var pos:=at+Vector2.from_angle(angle)*(8+p*30)+Vector2(0,-16-sin(p*8+i)*6)
  node.draw_circle(pos,4,Color(.6,.9,1,alpha*.55))
  node.draw_circle(pos,1.6,Color(.9,1,1,alpha*.9))
  node.draw_line(pos,pos+Vector2(0,10),Color(.5,.8,1,alpha*.25),2)
 node.draw_arc(at-Vector2(0,14),14+p*30,0,TAU,28,Color(.55,.85,1,alpha*.22),1.5,true)
static func shadow(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 var dir:=Vector2.from_angle(facing*PI/4)
 for i in range(4):
  var pos:=at-dir*(8+p*34+i*6)
  node.draw_set_transform(pos,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,8-i,Color(.25,.16,.4,alpha*.5))
  node.draw_circle(Vector2.ZERO,8-i,Color(.7,.5,1,alpha*.25*(1-float(i)/5)),false,1)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_line(at,at-dir*(20+p*30),Color(.65,.45,1,alpha*.3),2)
static func poof(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 node.draw_arc(at-Vector2(0,8),6+p*26,0,TAU,22,Color(1,.9,.6,alpha*.6),2,true)
 node.draw_arc(at-Vector2(0,8),4+p*18,0,TAU,22,Color(.85,.7,1,alpha*.4),1.5,true)
 for i in range(8):
  var angle:=i*TAU/8+p*.8
  var pos:=at+Vector2.from_angle(angle)*(10+p*26)-Vector2(0,8+p*10)
  node.draw_circle(pos,2.4*(1-p*.6),Color(1,.95,.8,alpha*.8))
 for i in range(4):
  var q:=at+Vector2(sin(i*2+p*3)*16,-6-p*20-i*3)
  node.draw_circle(q,5,Color(.9,.85,1,alpha*.16))
static func rescue(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(8):
  var angle:=i*TAU/8+p
  var pos:=at+Vector2.from_angle(angle)*(14+p*18)+Vector2(0,-10-p*48)
  node.draw_circle(pos,2.2,Color(1,.9,.6,alpha*.85))
 node.draw_arc(at-Vector2(0,12),16+p*22,0,TAU,26,Color(1,.86,.5,alpha*.45),2,true)
static func door(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(4):
  node.draw_circle(at+Vector2(sin(i*2.3+p*4)*16,4-p*14-i*4),1.8,Color(1,.85,.55,alpha*.7))
## 연꽃 빛: 여덟 장의 꽃잎이 피어오르며 따뜻한 고리가 퍼진다.
static func lotus(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,16)
 for i in range(8):
  var a:=i*TAU/8+p*.7
  var radius:=8+p*34
  var petal:=center+Vector2.from_angle(a)*radius
  node.draw_set_transform(petal,a,Vector2(1,.62))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-6,0),Vector2(0,-9),Vector2(6,0),Vector2(0,5)]),Color(LOTUS.r,LOTUS.g,LOTUS.b,alpha*.55))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  node.draw_circle(center+Vector2.from_angle(a+PI/8)*(radius*.62),1.5,Color(1,.94,.82,alpha*.8))
 node.draw_arc(center,10+p*40,0,TAU,36,Color(1,.78,.88,alpha*.34),2,true)
 node.draw_circle(center,3.2*(1-p*.5),Color(1,.95,.9,alpha*.75))
## 천문진: 회전하는 두 고리, 눈금, 별.
static func astrolabe(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,26)
 var radius:=26+p*96
 node.draw_arc(center,radius,0,TAU,64,Color(1,.85,.52,alpha*.42),2.0,true)
 node.draw_arc(center,radius*.72,p*2.0,p*2.0+TAU*.72,48,Color(1,.9,.62,alpha*.34),1.4,true)
 node.draw_arc(center,radius*.46,-p*3.0,-p*3.0+TAU*.62,40,Color(.82,.86,1,alpha*.30),1.2,true)
 for i in range(16):
  var a:=i*TAU/16-p*1.4
  var a0:=center+Vector2.from_angle(a)*radius*.86
  var a1:=center+Vector2.from_angle(a)*radius*.98
  node.draw_line(a0,a1,Color(1,.9,.6,alpha*.5),1.2,true)
 for i in range(9):
  var a:=i*TAU/9+p*1.8
  var star:=center+Vector2.from_angle(a)*(radius*(.52+.4*Art_shade(i)))
  node.draw_circle(star,1.7,Color(1,.98,.86,alpha*.8))
  node.draw_line(star-Vector2(2.6,0),star+Vector2(2.6,0),Color(1,.96,.8,alpha*.4),1.0)
## 황금 파동: 바닥에서 퍼지는 금빛 고리와 티끌.
static func goldwave(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(3):
  var radius:=12+p*64+i*14
  node.draw_arc(at,radius,0,TAU,48,Color(1,.84,.46,alpha*(.42-i*.1)),3.0-i*.6,true)
 node.draw_set_transform(at,0,Vector2(1,.42))
 node.draw_arc(Vector2.ZERO,10+p*48,0,TAU,40,Color(1,.9,.6,alpha*.26),2,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(10):
  var a:=i*TAU/10+p*2.2
  node.draw_circle(at+Vector2.from_angle(a)*(18+p*52),1.8,Color(1,.92,.66,alpha*.75))
## 그림자 안개: 먹물이 번지듯 어둠이 퍼진다.
static func darkness(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=sin(p*PI)
 var center:=at-Vector2(0,14)
 for i in range(7):
  var a:=i*TAU/7+p*1.2
  var radius:=18+p*76+Art_shade(i)*22
  var spot:=center+Vector2.from_angle(a)*(p*30)
  node.draw_circle(spot,radius*.42,Color(.04,.03,.10,alpha*.30))
  node.draw_arc(spot,radius*.44,0,TAU,26,Color(.42,.30,.62,alpha*.20),1.4,true)
 node.draw_circle(center,14+p*26,Color(.05,.04,.12,alpha*.34))
## 도깨비불: 청록 불덩이가 터져 흩어진다.
static func goblinfire(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(9):
  var a:=i*TAU/9+p*2.6
  var radius:=8+p*(44+Art_shade(i)*30)
  var pos:=at+Vector2.from_angle(a)*radius-Vector2(0,8+p*14)
  node.draw_circle(pos,4.2*(1-p*.5),Color(.45,.98,.78,alpha*.75))
  node.draw_circle(pos,1.8,Color(.92,1,.98,alpha))
  node.draw_line(pos,pos+Vector2(0,-8-p*8),Color(.55,1,.85,alpha*.35),2)
 node.draw_arc(at-Vector2(0,10),14+p*40,0,TAU,32,Color(.5,1,.85,alpha*.26),2,true)
## 산군의 울음: 음파가 사방으로 퍼진다.
static func howl(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(4):
  var radius:=16+p*90+i*22
  node.draw_arc(at-Vector2(0,18),radius,-PI*.82,-PI*.18,26,Color(1,.62,.36,alpha*(.45-i*.09)),2.6-i*.4,true)
 for i in range(6):
  var a:=-PI*.5+(Art_shade(i)-.5)*1.6
  var pos:=at-Vector2(0,18)+Vector2.from_angle(a)*(20+p*76)
  node.draw_circle(pos,2.0,Color(1,.78,.5,alpha*.7))
## 바람발: 진행 방향으로 바람 자국.
static func wind(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 var dir:=Vector2.from_angle(facing*PI/4)
 for i in range(6):
  var offset:=Vector2(0,-6-i*6)
  var start:=at+offset-dir*(20+p*40)
  node.draw_line(start,start+dir*(26+p*26),Color(.82,.92,1,alpha*.42),2.2,true)
  node.draw_circle(start+dir*8,1.6,Color(.9,.97,1,alpha*.6))
 node.draw_arc(at-Vector2(0,14),14+p*26,0,TAU,24,Color(.78,.9,1,alpha*.24),1.6,true)
## 기관: 톱니 고리가 돌아간다.
static func gear(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,26)
 var radius:=14+p*30
 node.draw_arc(center,radius,0,TAU,40,Color(.86,.84,.78,alpha*.7),2.2,true)
 node.draw_arc(center,radius*.6,0,TAU,30,Color(.72,.70,.66,alpha*.55),1.8,true)
 for i in range(10):
  var a:=i*TAU/10+p*4.0
  var a0:=center+Vector2.from_angle(a)*radius
  var a1:=center+Vector2.from_angle(a)*(radius+5)
  node.draw_line(a0,a1,Color(.92,.90,.82,alpha*.7),3.0,true)
 for i in range(4):
  var a:=i*TAU/4+p*4.0
  node.draw_circle(center+Vector2.from_angle(a)*(radius*.8),1.6,Color(1,.86,.5,alpha*.8))
## 압력기관 덫: 바닥의 톱니 원판.
static func trap(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 node.draw_set_transform(at,0,Vector2(1,.45))
 node.draw_arc(Vector2.ZERO,22,0,TAU,32,Color(1,.82,.46,alpha*.55),2.4,true)
 node.draw_arc(Vector2.ZERO,14,0,TAU,28,Color(.9,.9,.82,alpha*.4),1.6,true)
 for i in range(8):
  var a:=i*TAU/8-p*2.0
  node.draw_line(Vector2.from_angle(a)*6,Vector2.from_angle(a)*20,Color(1,.86,.54,alpha*.5),1.6,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(5):
  var a:=i*TAU/5+p*2.0
  node.draw_circle(at+Vector2.from_angle(a)*(10+p*20)-Vector2(0,6+p*10),1.6,Color(1,.9,.62,alpha*.7))
## 저승꽃: 꽃잎 사슬이 감돌며 보호막을 두른다.
static func chain(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(10):
  var a:=i*TAU/10+p*1.6
  var height:=-8.0-float(i)*5.0-p*18.0
  var radius:=16+sin(i*.9+p*2.0)*5.0
  var pos:=at+Vector2.from_angle(a)*radius+Vector2(0,height)
  node.draw_set_transform(pos,a,Vector2(1,.7))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-4,0),Vector2(0,-6),Vector2(4,0),Vector2(0,4)]),Color(.86,.74,1,alpha*.55))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  node.draw_circle(pos,1.4,Color(1,.95,.9,alpha*.8))
 node.draw_arc(at-Vector2(0,18),20+p*16,0,TAU,32,Color(.82,.7,1,alpha*.3),1.8,true)
## 귀문: 세로로 열린 저승의 문.
static func ghostgate(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=sin(p*PI)
 var height:=44.0+p*26.0
 var width:=18.0+p*16.0
 var base:=at-Vector2(0,2)
 node.draw_rect(Rect2(base-Vector2(width*.5,height),Vector2(width,height)),Color(.06,.04,.14,alpha*.55))
 node.draw_rect(Rect2(base-Vector2(width*.5,height),Vector2(width,height)),Color(.72,.58,1,alpha*.6),false,2.0)
 for i in range(6):
  var y: float=-height*float(i)/6.0
  node.draw_line(base+Vector2(-width*.5,y),base+Vector2(width*.5,y),Color(.8,.68,1,alpha*.28),1.2,true)
 for i in range(7):
  var a:=i*TAU/7+p*2.4
  node.draw_circle(base+Vector2.from_angle(a)*(width*.9)+Vector2(0,-height*.5),1.5,Color(.86,.78,1,alpha*.7))
## 혼길표식: 땅에 꽂힌 부적 기둥.
static func soulmark(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p*.6
 var base:=at-Vector2(0,2)
 var height:=34.0
 node.draw_line(base,base+Vector2(0,-height),Color(.9,.84,1,alpha*.6),2.0,true)
 node.draw_rect(Rect2(base+Vector2(-6,-height-12),Vector2(12,18)),Color(1,.9,.62,alpha*.9))
 node.draw_rect(Rect2(base+Vector2(-6,-height-12),Vector2(12,18)),Color(.86,.5,.2,alpha*.8),false,1)
 node.draw_line(base+Vector2(0,-height-9),base+Vector2(0,-height+3),Color(.55,.2,.12,alpha*.8),1.2,true)
 node.draw_set_transform(base,0,Vector2(1,.4))
 node.draw_arc(Vector2.ZERO,16+p*10,0,TAU,26,Color(1,.88,.6,alpha*.4),2,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 그림자 안개: 낮게 깔리는 보랏빛 안개.
static func mist(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=sin(p*PI)*.7
 for i in range(6):
  var a:=i*TAU/6+p*1.4
  var pos:=at+Vector2.from_angle(a)*(14+p*26)-Vector2(0,10)
  node.draw_circle(pos,20+p*10,Color(.34,.26,.5,alpha*.22))
  node.draw_circle(pos+Vector2(8,-6),14,Color(.52,.42,.72,alpha*.16))
 node.draw_arc(at-Vector2(0,12),20+p*34,0,TAU,30,Color(.6,.5,.86,alpha*.22),1.6,true)
## 야광가루: 반짝이는 가루가 묻는다.
static func powder(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(12):
  var a:=i*TAU/12+p*3.0
  var radius:=6+p*(24+Art_shade(i)*30)
  var pos:=at+Vector2.from_angle(a)*radius+Vector2(0,-12-p*20)
  node.draw_circle(pos,1.8*(1-p*.4),Color(.86,1,.92,alpha*.9))
  node.draw_line(pos-Vector2(2,0),pos+Vector2(2,0),Color(1,1,1,alpha*.5),1.0)
 node.draw_arc(at-Vector2(0,16),12+p*30,0,TAU,28,Color(.8,1,.9,alpha*.26),1.6,true)
## 소리 흉내: 파문과 음표.
static func sound(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,22)
 for i in range(3):
  var radius:=14+p*52+i*16
  node.draw_arc(center,radius,0,TAU,28,Color(1,.86,.58,alpha*(.36-i*.09)),2.0,true)
 for i in range(4):
  var a:=-PI*.5+(Art_shade(i)-.5)*1.4
  var pos:=center+Vector2.from_angle(a)*(20+p*54)
  node.draw_circle(pos,2.4,Color(1,.92,.7,alpha*.8))
  node.draw_line(pos,pos+Vector2(0,-7),Color(1,.92,.7,alpha*.7),1.4,true)
## 수묵: 먹물이 번지며 사라진다.
static func ink(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var center:=at-Vector2(0,16)
 for i in range(6):
  var a:=i*TAU/6+p*1.1
  var radius:=10+p*(26+Art_shade(i)*20)
  node.draw_circle(center+Vector2.from_angle(a)*radius*.4,radius*.42,Color(.08,.06,.16,alpha*.22))
 node.draw_arc(center,18+p*42,0,TAU,32,Color(.6,.5,.8,alpha*.18),2.0,true)
 for i in range(5):
  node.draw_circle(center+Vector2(sin(i*2.4+p*3)*30,-6-p*26-i*3),2.0,Color(.82,.78,1,alpha*.4))
static func seal(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 var radius:=44-p*20
 for i in range(12):
  var angle:=i*TAU/12+ p*.5
  node.draw_circle(at+Vector2.from_angle(angle)*radius,2.4,Color(.95,.7,1,alpha*.85))
 node.draw_arc(at,radius,0,TAU,40,Color(.85,.55,1,alpha*.55),2,true)
 node.draw_arc(at,radius*.72,0,TAU,32,Color(1,.85,.95,alpha*.35),1.5,true)
 node.draw_line(at+Vector2(0,-8),at+Vector2(0,8),Color(1,.9,1,alpha*.6),2)
static func miss(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 node.draw_arc(at+Vector2(0,-6),18+p*14,-PI*.8,-PI*.2,14,Color(.78,.78,.9,alpha*.6),2,true)
 node.draw_circle(at+Vector2(0,-2),3,Color(.7,.7,.85,alpha*.4))
static func afterimage(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=.35*(1-p)
 var dir:=Vector2.from_angle(facing*PI/4)
 for i in range(3):
  var pos:=at-dir*(i*10)-Vector2(0,i*2)
  node.draw_set_transform(pos,0,Vector2(1,.5))
  node.draw_circle(Vector2.ZERO,9-i*2,Color(.55,.4,.85,alpha))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
static func haze(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=sin(p*PI)*.5
 for i in range(5):
  var pos:=at+Vector2.from_angle(i*TAU/5+p)* (16+p*20)-Vector2(0,8)
  node.draw_circle(pos,18,Color(.72,.66,.86,alpha*.18))
  node.draw_circle(pos+Vector2(6,-6),12,Color(.8,.74,.92,alpha*.14))
static func Art_shade(i: int) -> float:return float((i*37)%11)/11.0

## ---------------------------------------------------------------- 2.0.28 서명 연출
## 도술 30종이 각자 다른 모션으로 보이도록, 스킬 id → 도형·색을 고정한다.
## 모두 원·선·다각형만 쓰므로 텍스처 없이 가볍게 그려진다.
const SIG={
 "clone":{"m":"mirror","c":"b48cf0"},"transform":{"m":"smoke","c":"c2a8ff"},"painting":{"m":"scroll","c":"f0d79b"},
 "wallhop":{"m":"arrow","c":"a9c8ff"},"windstep":{"m":"gust","c":"bfe0ff"},"eightleap":{"m":"steps","c":"b48cf0"},
 "puppet":{"m":"gear","c":"e6dcc4"},"trap":{"m":"plate","c":"f0c46a"},"astrolabe":{"m":"star","c":"ffe6a8"},
 "lifelamp":{"m":"lantern","c":"ffd9a0"},"deathflower":{"m":"petal","c":"d9c0ff"},"returnpath":{"m":"thread","c":"a8f0d0"},
 "ghostgate":{"m":"gate","c":"c9b6ff"},"soulmark":{"m":"needle","c":"ffd98a"},"underworldgate":{"m":"abyss","c":"8f6bd6"},
 "mimic":{"m":"mask","c":"ff9ee0"},"foxscent":{"m":"scent","c":"7fe4d6"},"foxdream":{"m":"eye","c":"c39bff"},
 "voicemimic":{"m":"wave","c":"ffd08a"},"soundhunt":{"m":"print","c":"8fd8ff"},"mountaingrowl":{"m":"shock","c":"ff9a5a"},
 "mischief":{"m":"club","c":"8ff0c8"},"faketreasure":{"m":"chest","c":"ffd166"},"goblinfest":{"m":"burst","c":"8ff0c8"},
 "douse":{"m":"blow","c":"7a6a9a"},"blackvision":{"m":"shuteye","c":"9a8fd0"},"moonlessnight":{"m":"moon","c":"d8f0ff"},
 "shoeprints":{"m":"print","c":"d8f0ff"},"glowpowder":{"m":"powder","c":"a8ffe8"},"footprintmap":{"m":"map","c":"ffe0a8"}}
static func signature(node: Node2D,at: Vector2,p: float,skill_id: String,facing: float) -> void:
 var spec: Dictionary=SIG.get(skill_id,{})
 var tint:=Color(String(spec.get("c","f0c46a")))
 var alpha:=1-p
 var center:=at-Vector2(0,18)
 # 2.0.30 모든 도술 공통 발동 섬광: 시전 순간 밝은 핵 + 이중 충격 고리 + 방사 빛살.
 # ("스킬을 쓴 건지 모르겠다"는 문제를 없애기 위한 첫 0.15초 연출)
 var flash: float=clampf(1.0-p*3.2,0.0,1.0)
 if flash>0.01:
  node.draw_circle(center,16.0+30.0*(1.0-flash),Color(tint.r,tint.g,tint.b,.30*flash))
  node.draw_circle(center,8.0+14.0*(1.0-flash),Color(1,1,1,.42*flash))
  for i in range(2):
   node.draw_arc(center,20.0+p*46.0+float(i)*10.0,0,TAU,44,Color(tint.r,tint.g,tint.b,(.55-.18*float(i))*(1.0-p)),3.4-float(i)*1.2,true)
  for i in range(10):
   var ray: float=float(i)*TAU/10.0+p*2.0
   var inner: Vector2=center+Vector2.from_angle(ray)*(20.0+p*26.0)
   var outer: Vector2=center+Vector2.from_angle(ray)*(32.0+p*36.0)
   node.draw_line(inner,outer,Color(tint.r,tint.g,tint.b,.34*(1.0-p)),2.0,true)
 # 캐릭터별 고유 콘셉트 연출을 먼저 크게 깔고, 그 위에 스킬별 형태를 얹는다.
 char_kit(node,at,p,skill_id,facing)
 match String(spec.get("m","")):
  "scroll":
   # 화중은신: 위에서 아래로 펼쳐지는 족자, 그 위에 먹 획과 그림자 잔상.
   var unfold:=clampf(p*2.2,0,1)
   var height: float=96.0*unfold
   var width: float=34.0+10.0*unfold
   node.draw_rect(Rect2(center-Vector2(width*.5,height*.62),Vector2(width,height)),Color(.93,.87,.74,alpha*.92))
   node.draw_rect(Rect2(center-Vector2(width*.5,height*.62),Vector2(width,height)),Color(.42,.30,.18,alpha*.85),false,1.6)
   for i in range(4):
    var y: float=-height*.55+float(i)*height*.28
    node.draw_line(center+Vector2(-width*.32,y),center+Vector2(width*.32-5,y),Color(.10,.08,.16,alpha*.55),2.2,true)
   node.draw_line(center+Vector2(width*.5+4,-height*.62),center+Vector2(width*.5+4,height*.38),Color(.5,.36,.20,alpha*.9),2.0,true)
   node.draw_set_transform(center,0,Vector2(1,.45))
   node.draw_arc(Vector2.ZERO,20+p*34,0,TAU,30,Color(.72,.55,.28,alpha*.30),2.0,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   for i in range(5):
    var pos:=center+Vector2(sin(i*2.1+p*4)*26,-height*.4+i*9)
    node.draw_circle(pos,2.6*(1-p*.5),Color(.16,.12,.22,alpha*.35))
  "mirror":
   # 분신술: 좌우로 갈라지는 두 실루엣과 먹물 방울.
   for side in [-1.0,1.0]:
    var offset:=Vector2(side*(10+p*26),0)
    node.draw_set_transform(center+offset,0,Vector2(1,.72))
    node.draw_circle(Vector2.ZERO,10-p*3,Color(tint.r,tint.g,tint.b,alpha*.32))
    node.draw_arc(Vector2.ZERO,10-p*3,0,TAU,20,Color(tint.r,tint.g,tint.b,alpha*.55),1.6,true)
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   for i in range(8):
    var a:=i*TAU/8+p*2.0
    node.draw_circle(center+Vector2.from_angle(a)*(16+p*30),2.0,Color(.78,.66,1,alpha*.6))
  "smoke":
   # 둔갑술: 몸을 감싸는 연기 덩어리.
   for i in range(7):
    var a:=i*TAU/7+p*1.7
    var pos:=center+Vector2.from_angle(a)*(10+p*26)+Vector2(0,-p*16)
    node.draw_circle(pos,9+p*6,Color(tint.r,tint.g,tint.b,alpha*.18))
   node.draw_arc(center,14+p*30,0,TAU,26,Color(tint.r,tint.g,tint.b,alpha*.34),2.0,true)
  "arrow":
   # 담장넘기: 조준 방향으로 뻗는 세 개의 화살촉과 도약 궤적.
   var dir:=Vector2.from_angle(facing*PI/4)
   for i in range(3):
    var start:=center+dir*(12+p*44+i*10)
    node.draw_line(start,start+dir*16,Color(1,.86,.55,alpha*.7),2.4,true)
    node.draw_line(start+dir*16,start+dir*16+Vector2(-dir.y,dir.x)*6,Color(1,.86,.55,alpha*.7),2.0,true)
    node.draw_line(start+dir*16,start+dir*16-Vector2(-dir.y,dir.x)*6,Color(1,.86,.55,alpha*.7),2.0,true)
   node.draw_arc(center,10+p*30,dir.angle()-1.0,dir.angle()+1.0,16,Color(tint.r,tint.g,tint.b,alpha*.35),2.0,true)
  "gust":
   # 바람발: 발밑에서 일어나는 회오리.
   for i in range(5):
    var radius:=10+p*26+i*4
    node.draw_arc(at-Vector2(0,8),radius,-PI*.9+p*3.0,-PI*.1+p*3.0,18,Color(tint.r,tint.g,tint.b,alpha*.38),2.0,true)
  "steps":
   # 팔방도약: 남는 세 개의 잔상 발자국.
   for i in range(3):
    var pos:=center+Vector2((i-1)*18,-i*10-p*12)
    node.draw_set_transform(pos,0,Vector2(1,.45))
    node.draw_circle(Vector2.ZERO,7-i,Color(tint.r,tint.g,tint.b,alpha*.5))
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   for i in range(6):
    node.draw_circle(center+Vector2.from_angle(i*TAU/6)*(20+p*36),1.8,Color(.95,.9,1,alpha*.5))
  "gear":
   gear(node,at,p)
  "plate":
   trap(node,at,p)
  "star":
   # 천문기계: 별과 눈금 고리.
   for i in range(8):
    var a:=i*TAU/8+p*2.0
    var pos:=center+Vector2.from_angle(a)*(22+p*44)
    node.draw_circle(pos,2.2,Color(1,.95,.75,alpha*.85))
    node.draw_line(pos-Vector2(4,0),pos+Vector2(4,0),Color(1,.92,.7,alpha*.35),1.2)
   node.draw_arc(center,18+p*40,0,TAU,36,Color(tint.r,tint.g,tint.b,alpha*.3),1.6,true)
  "lantern":
   # 생명등불: 떠오르는 등불과 따뜻한 고리.
   var rise:=p*34
   node.draw_circle(center-Vector2(0,rise),8,Color(1,.86,.55,alpha*.30))
   node.draw_rect(Rect2(center-Vector2(7,rise+12),Vector2(14,18)),Color(1,.88,.62,alpha*.85))
   node.draw_rect(Rect2(center-Vector2(7,rise+12),Vector2(14,18)),Color(.7,.45,.18,alpha*.8),false,1.2)
   node.draw_line(center-Vector2(0,rise+30),center-Vector2(0,rise+12),Color(.9,.75,.4,alpha*.7),1.6)
   node.draw_arc(at-Vector2(0,10),16+p*30,0,TAU,26,Color(1,.85,.55,alpha*.28),2.0,true)
  "petal":
   # 저승꽃: 보랏빛 꽃잎이 감도는 보호막.
   for i in range(8):
    var a:=i*TAU/8+p*2.4
    var pos:=center+Vector2.from_angle(a)*(14+p*30)
    node.draw_set_transform(pos,a,Vector2(1,.6))
    node.draw_colored_polygon(PackedVector2Array([Vector2(-5,0),Vector2(0,-8),Vector2(5,0),Vector2(0,5)]),Color(tint.r,tint.g,tint.b,alpha*.6))
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   node.draw_arc(center,20+sin(p*PI)*16,0,TAU,30,Color(tint.r,tint.g,tint.b,alpha*.4),2.2,true)
  "thread":
   # 귀환의 길: 두 지점을 잇는 금빛 실.
   var dir2:=Vector2.from_angle(facing*PI/4)
   var far:=center+dir2*(60+p*70)
   node.draw_line(center,far,Color(tint.r,tint.g,tint.b,alpha*.6),2.2,true)
   for i in range(5):
    var t:=float(i)/5.0+p*.2
    node.draw_circle(center.lerp(far,t),2.0,Color(1,1,1,alpha*.5))
  "gate":
   # 귀문/저승문: 세로로 열린 문과 문턱의 빛.
   var h2:=46.0+p*18.0
   var w2:=20.0+p*10.0
   node.draw_rect(Rect2(center-Vector2(w2*.5,h2),Vector2(w2,h2)),Color(.06,.04,.13,alpha*.55))
   node.draw_rect(Rect2(center-Vector2(w2*.5,h2),Vector2(w2,h2)),Color(tint.r,tint.g,tint.b,alpha*.75),false,2.0)
   node.draw_line(center-Vector2(w2*.5,0),center+Vector2(w2*.5,0),Color(tint.r,tint.g,tint.b,alpha*.6),2.0,true)
  "abyss":
   # 저승문 귀환: 검은 소용돌이가 빨려 들어간다.
   for i in range(4):
    node.draw_arc(center,10+p*40+i*6,p*5.0+i,p*5.0+i+TAU*.6,26,Color(tint.r,tint.g,tint.b,alpha*.36),2.0,true)
   node.draw_circle(center,10.0*(1-p*.6),Color(.03,.02,.07,alpha*.6))
  "mask":
   # 인간둔갑: 떠오르는 여우 가면과 눈매.
   var rise2:=-p*26
   node.draw_set_transform(center+Vector2(0,rise2),0,Vector2(1,.86))
   node.draw_circle(Vector2.ZERO,13,Color(tint.r,tint.g,tint.b,alpha*.30))
   node.draw_arc(Vector2.ZERO,13,0,TAU,24,Color(tint.r,tint.g,tint.b,alpha*.85),1.8,true)
   node.draw_line(Vector2(-8,-3),Vector2(-3,-5),Color(.10,.06,.12,alpha*.9),2.0,true)
   node.draw_line(Vector2(3,-5),Vector2(8,-3),Color(.10,.06,.12,alpha*.9),2.0,true)
   node.draw_colored_polygon(PackedVector2Array([Vector2(-14,-8),Vector2(-8,-17),Vector2(-5,-7)]),Color(tint.r,tint.g,tint.b,alpha*.8))
   node.draw_colored_polygon(PackedVector2Array([Vector2(14,-8),Vector2(8,-17),Vector2(5,-7)]),Color(tint.r,tint.g,tint.b,alpha*.8))
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  "scent":
   # 여우향: 달콤한 향의 동심원과 분말.
   for i in range(3):
    node.draw_arc(at-Vector2(0,12),20+p*70+i*10,0,TAU,30,Color(tint.r,tint.g,tint.b,alpha*(.30-i*.08)),2.0,true)
   for i in range(10):
    node.draw_circle(at+Vector2(sin(i*1.7+p*3)*30,-14-p*30-i*2),1.8,Color(tint.r,tint.g,tint.b,alpha*.7))
  "eye":
   # 구미환몽: 크게 뜨는 환영의 눈.
   var open:=minf(1.0,p*3.0)
   var rx:=30.0
   var ry:=13.0*open
   node.draw_set_transform(center,0,Vector2(1,.62))
   for i in range(24):
    var a0:=PI+i*PI/24
    var a1:=PI+(i+1)*PI/24
    node.draw_line(Vector2.from_angle(a0)*Vector2(rx,ry*2.2),Vector2.from_angle(a1)*Vector2(rx,ry*2.2),Color(tint.r,tint.g,tint.b,alpha*.8),1.6,true)
   node.draw_circle(Vector2.ZERO,6.0,Color(.16,.08,.24,alpha*.85))
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  "wave":
   # 목소리흉내: 부채꼴 음파.
   for i in range(4):
    var r:=16+p*62+i*12
    node.draw_arc(center,r,-.9,.9,18,Color(tint.r,tint.g,tint.b,alpha*(.4-i*.08)),2.2,true)
  "print":
   # 신발흔적·발자국지도: 밝게 빛나는 두 발자국.
   for side in [-1.0,1.0]:
    var pos:=at+Vector2(side*9,0)
    node.draw_set_transform(pos-Vector2(0,p*10),0,Vector2(1,.5))
    node.draw_circle(Vector2.ZERO,5.0,Color(tint.r,tint.g,tint.b,alpha*.5))
    node.draw_arc(Vector2.ZERO,5.0,0,TAU,14,Color(1,1,1,alpha*.55),1.2,true)
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  "shock":
   # 산군의 울음: 낮게 퍼지는 충격 고리와 파편.
   for i in range(3):
    node.draw_arc(at-Vector2(0,6),20+p*80+i*16,0,TAU,40,Color(tint.r,tint.g,tint.b,alpha*(.36-i*.1)),3.0-i*.6,true)
   for i in range(8):
    node.draw_line(at+Vector2.from_angle(i*TAU/8)*(18+p*56),at+Vector2.from_angle(i*TAU/8)*(28+p*72),Color(tint.r,tint.g,tint.b,alpha*.5),2.0,true)
  "club":
   # 도깨비방망이: 크게 휘두르는 방망이와 튀는 별.
   var angle:=-.9+p*2.6
   var handle:=center+Vector2.from_angle(angle)*(10+p*16)
   var head:=handle+Vector2.from_angle(angle)*(18+p*10)
   node.draw_line(center,handle,Color(.72,.55,.32,alpha*.9),3.0,true)
   node.draw_circle(head,8.0,Color(.85,.68,.40,alpha*.9))
   node.draw_circle(head,4.0,Color(1,.92,.7,alpha*.9))
   for i in range(5):
    node.draw_circle(head+Vector2.from_angle(i*TAU/5+p*3)*(14+p*20),1.8,Color(tint.r,tint.g,tint.b,alpha*.8))
  "chest":
   # 가짜보물: 반짝이는 보물 상자.
   var box:=Rect2(center-Vector2(13,6),Vector2(26,16))
   node.draw_rect(box,Color(.30,.22,.10,alpha*.94))
   node.draw_rect(box,Color(1,.82,.42,alpha*.9),false,1.6)
   node.draw_rect(Rect2(box.position,Vector2(box.size.x,6)),Color(.36,.26,.12,alpha*.95))
   node.draw_rect(Rect2(center-Vector2(2,7),Vector2(4,10)),Color(1,.88,.5,alpha*.95))
   for i in range(8):
    var spark:=center+Vector2(sin(i*2.3+p*3)*20,-8-p*26-Art_shade(i)*14)
    node.draw_circle(spark,1.8,Color(1,.96,.7,alpha*.85))
  "burst":
   goblinfire(node,at,p)
  "blow":
   # 등불끄기: 꺼지는 등불과 번지는 어둠 + 피어오르는 불씨·연기.
   node.draw_rect(Rect2(center-Vector2(6,10),Vector2(12,18)),Color(.30,.28,.36,alpha*.9))
   node.draw_rect(Rect2(center-Vector2(6,10),Vector2(12,18)),Color(.55,.5,.65,alpha*.7),false,1.2)
   for i in range(6):
    var pos:=center+Vector2.from_angle(i*TAU/6+p*2)*(8+p*28)-Vector2(0,p*18)
    node.draw_circle(pos,4+p*5,Color(.06,.05,.12,alpha*.20))
   # 불씨가 튀고 연기가 위로 흐른다.
   for i in range(9):
    var a:=float(i)*TAU/9.0
    var reach: float=10.0+p*44.0
    var ember:=center+Vector2.from_angle(a)*reach+Vector2(0,-p*26.0)
    node.draw_circle(ember,1.8*(1-p*.6),Color(1,.6,.24,alpha*.85))
    node.draw_line(ember,ember+Vector2.from_angle(a)*(6.0+p*8.0),Color(1,.45,.18,alpha*.35),1.2,true)
   for i in range(5):
    var smoke:=center+Vector2(sin(p*4.0+float(i)*1.7)*16.0,-10.0-p*54.0-float(i)*6.0)
    node.draw_circle(smoke,5.0+p*5.0,Color(.20,.18,.26,alpha*.14))
   # 어둠이 번지는 테두리 링(단색 원 대신 여러 겹).
   for i in range(3):
    node.draw_arc(at,24.0+p*58.0+float(i)*8.0,0,TAU,40,Color(.30,.24,.44,alpha*(.16-.05*float(i))),2.0,true)
  "shuteye":
   # 검은시야: 감기는 눈과 어두운 커튼.
   var close:=clampf(p*2.0,0,1)
   node.draw_set_transform(center,0,Vector2(1,.55))
   node.draw_arc(Vector2.ZERO,26,0,TAU,26,Color(.08,.06,.14,alpha*.75),3.0*close,true)
   node.draw_arc(Vector2.ZERO,26,0.15,PI-0.15,20,Color(tint.r,tint.g,tint.b,alpha*.5),1.4,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  "moon":
   # 무월야: 먹구름에 잠식되는 달.
   var R:=34.0
   node.draw_circle(center,R,Color(tint.r,tint.g,tint.b,alpha*.30))
   node.draw_arc(center,R,0,TAU,40,Color(tint.r,tint.g,tint.b,alpha*.7),2.0,true)
   node.draw_circle(center+Vector2(p*26,-p*8),R*.98,Color(.03,.02,.08,alpha*.85))
   for i in range(5):
    node.draw_circle(center+Vector2.from_angle(i*TAU/5+p)*(R+10),10.0,Color(.05,.04,.10,alpha*.22))
  "powder":
   powder(node,at,p)
  "map":
   # 발자국지도: 격자 위에 그려지는 동선.
   var rect:=Rect2(center-Vector2(34,26),Vector2(68,52))
   node.draw_rect(rect,Color(.04,.03,.09,alpha*.5))
   for i in range(1,4):
    node.draw_line(Vector2(rect.position.x+rect.size.x*i/4.0,rect.position.y),Vector2(rect.position.x+rect.size.x*i/4.0,rect.end.y),Color(tint.r,tint.g,tint.b,alpha*.18),1.0)
    node.draw_line(Vector2(rect.position.x,rect.position.y+rect.size.y*i/4.0),Vector2(rect.end.x,rect.position.y+rect.size.y*i/4.0),Color(tint.r,tint.g,tint.b,alpha*.18),1.0)
   var path:=PackedVector2Array([rect.position+Vector2(8,42),rect.position+Vector2(24,20),rect.position+Vector2(42,34),rect.position+Vector2(60,10)])
   for i in range(path.size()-1):
    node.draw_line(path[i],path[i+1],Color(tint.r,tint.g,tint.b,alpha*.6*minf(1.0,p*3.0)),2.0,true)
  _:
   node.draw_arc(center,12+p*24,0,TAU,24,Color(tint.r,tint.g,tint.b,alpha*.4),2.0,true)
## 화중은신 전용: 위아래 축이 말리는 족자와 먹물 번짐.
static func scroll(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 var width:=22.0+18.0*clampf(p*2.4,0,1)
 var height:=88.0*clampf(p*2.0,0,1)
 var center:=at-Vector2(0,height*.45)
 node.draw_rect(Rect2(center-Vector2(width*.5,height*.5),Vector2(width,height)),Color(.94,.89,.78,alpha*.9))
 node.draw_rect(Rect2(center-Vector2(width*.5,height*.5),Vector2(width,height)),Color(.38,.27,.16,alpha*.9),false,1.8)
 for i in range(3):
  node.draw_line(center+Vector2(-width*.34,height*(.3-float(i)*.18)),center+Vector2(width*.34,height*(.28-float(i)*.18)),Color(.12,.1,.18,alpha*.5),2.0,true)
 for i in range(2):
  var edge:=center+Vector2(0,(height*.5+2)*(1 if i==0 else -1))
  node.draw_line(edge-Vector2(width*.6,0),edge+Vector2(width*.6,0),Color(.55,.38,.2,alpha*.95),3.0,true)
 node.draw_set_transform(at,0,Vector2(1,.4))
 node.draw_arc(Vector2.ZERO,20+p*26,0,TAU,28,Color(.62,.46,.24,alpha*.3),2.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(6):
  var pos:=at+Vector2(sin(i*2.2+p*3)*24,-10-p*30-i*3)
  node.draw_circle(pos,2.4*(1-p*.4),Color(.1,.08,.14,alpha*.4))


## ---------------------------------------------------------------- 2.0.30 캐릭터별 고유 연출
## 스킬 하나하나가 "아, 그 캐릭터답다"로 읽히도록, 단색 원 대신 여러 겹의 연막·입자·
## 궤적으로 캐릭터 정체성을 그린다. 모두 원·선·다각형만 쓰므로 텍스처 없이 그려진다.
const CHAR_KIT={
 "clone":"ink","transform":"ink","painting":"ink",
 "wallhop":"wind","windstep":"wind","eightleap":"wind",
 "puppet":"machine","trap":"machine","astrolabe":"machine",
 "lifelamp":"lotus","deathflower":"lotus","returnpath":"lotus",
 "ghostgate":"gate","soulmark":"gate","underworldgate":"gate",
 "mimic":"fox","foxscent":"fox","foxdream":"fox",
 "voicemimic":"tiger","soundhunt":"tiger","mountaingrowl":"tiger",
 "mischief":"goblin","faketreasure":"goblin","goblinfest":"goblin",
 "douse":"dark","blackvision":"dark","moonlessnight":"dark",
 "shoeprints":"glow","glowpowder":"glow","footprintmap":"glow"}
static func char_kit(node: Node2D,at: Vector2,p: float,skill_id: String,facing: float) -> void:
 var kit:=String(CHAR_KIT.get(skill_id,"ink"))
 var center:=at-Vector2(0,18)
 match kit:
  "dark":kit_dark(node,at,center,p)
  "ink":kit_ink(node,at,center,p,facing)
  "wind":kit_wind(node,at,center,p,facing)
  "machine":kit_machine(node,at,center,p)
  "lotus":kit_lotus(node,at,center,p)
  "gate":kit_gate(node,at,center,p)
  "fox":kit_fox(node,at,center,p)
  "tiger":kit_tiger(node,at,center,p,facing)
  "goblin":kit_goblin(node,at,center,p)
  "glow":kit_glow(node,at,center,p)
  _:pass
## 여러 겹이 소용돌이치는 연기 덩어리(단색 원 대신 불규칙한 다중 구름).
static func smoke(node: Node2D,center: Vector2,extent: float,t: float,tint: Color,count: int=7,spin: float=1.0) -> void:
 for i in range(count):
  var phase:=float(i)*TAU/float(count)+t*spin
  var radius:=extent*(.22+.30*float((i*37)%11)/11.0)*(0.6+t*.9)
  var spot:=center+Vector2.from_angle(phase)*(extent*.34*(0.4+t)) +Vector2(0,-extent*.18*t)
  var alpha:=(1.0-t)*tint.a*(.55+.45*sin(phase*2.0+t*3.0))
  node.draw_circle(spot,radius,tint_alpha(tint,alpha*.55))
  node.draw_circle(spot+Vector2.from_angle(phase+1.4)*radius*.55,radius*.66,tint_alpha(tint,alpha*.40))
  node.draw_circle(spot+Vector2.from_angle(phase-1.1)*radius*.40,radius*.40,tint_alpha(tint,alpha*.85))
static func tint_alpha(color: Color,a: float) -> Color:
 return Color(color.r,color.g,color.b,clampf(a,0.0,1.0))
## 어둑시니: 먹빛 연막 소용돌이 + 그림자 촉수 + 보랏빛 눈빛 + 연기 입자.
static func kit_dark(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 smoke(node,center,86.0,p,Color(.05,.035,.10,.55),9,1.4)
 smoke(node,center+Vector2(0,-14),54.0,maxf(0.0,p-.2),Color(.11,.07,.19,.42),6,-1.1)
 # 흐느적거리는 그림자 촉수
 for i in range(7):
  var a:=float(i)*TAU/7.0+sin(p*5.0+float(i))*0.25
  var base:=center+Vector2.from_angle(a)*12.0
  var bend:=Vector2.from_angle(a+1.1)*(26.0+p*30.0)
  var tip:=base+bend+Vector2(0,-(10.0+p*24.0))
  node.draw_line(base,base+bend*0.6,Color(.06,.04,.11,alpha*.55),4.0,true)
  node.draw_line(base+bend*0.6,tip,Color(.10,.07,.17,alpha*.35),2.4,true)
 # 보랏빛 눈빛 두 점
 var eye_alpha:=alpha*(0.55+0.45*sin(p*7.0))
 for side in [-1.0,1.0]:
  var eye:=center+Vector2(side*9.0,-26.0+sin(p*3.0)*2.0)
  node.draw_circle(eye,4.6,Color(.55,.30,.85,eye_alpha*.35))
  node.draw_circle(eye,1.8,Color(.90,.72,1.0,eye_alpha*.95))
 # 흩날리는 연기 입자
 for i in range(14):
  var a2:=float(i)*TAU/14.0+p*2.4
  var r2:=18.0+p*58.0+float((i*29)%13)
  var spot:=center+Vector2.from_angle(a2)*r2+Vector2(0,-p*30.0)
  node.draw_circle(spot,1.4+1.2*sin(p*6.0+float(i)),Color(.16,.11,.26,alpha*.70))
## 전우치: 흩날리는 황금 부적 편린 + 먹물 번짐 파동 + 족자 문양.
static func kit_ink(node: Node2D,at: Vector2,center: Vector2,p: float,facing: float) -> void:
 var alpha:=clampf(1.0-p*0.9,0.0,1.0)
 smoke(node,center+Vector2(0,-6),58.0,p,Color(.12,.09,.16,.42),6,1.0)
 for i in range(12):
  var a:=float(i)*TAU/12.0+p*3.4
  var r:=14.0+p*54.0
  var spot:=center+Vector2.from_angle(a)*r+Vector2(0,-10.0-p*22.0)
  var tilt:=a+p*3.0
  node.draw_set_transform(spot,tilt,Vector2(.7,1.0))
  node.draw_rect(Rect2(-3.4,-6.0,6.8,12.0),Color(1,.88,.55,alpha*.92))
  node.draw_rect(Rect2(-3.4,-6.0,6.8,12.0),Color(.72,.38,.16,alpha*.85),false,1.0)
  node.draw_line(Vector2(0,-3.5),Vector2(0,3.5),Color(.45,.16,.10,alpha*.85),1.0)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(3):
  node.draw_arc(center,18.0+p*42.0+float(i)*8.0,0,TAU,40,Color(.09,.07,.13,alpha*(.26-.06*float(i))),2.6,true)
 for i in range(8):
  var q:=center+Vector2(sin(float(i)*2.1+p*4.0)*40.0,-12.0-p*40.0-float(i)*4.0)
  node.draw_circle(q,1.6,Color(.24,.16,.34,alpha*.55))
## 홍길동: 푸른 회오리 바람결 + 잔상 궤적 + 낙엽·먼지 소용돌이.
static func kit_wind(node: Node2D,at: Vector2,center: Vector2,p: float,facing: float) -> void:
 var alpha:=clampf(1.0-p*0.9,0.0,1.0)
 var dir:=Vector2.from_angle(facing*PI/4)
 for i in range(5):
  var r:=14.0+p*34.0+float(i)*7.0
  node.draw_arc(at-Vector2(0,10),r,-PI*.9+p*4.2,-PI*.2+p*4.2,22,Color(.62,.84,1,alpha*(.40-.05*float(i))),2.6,true)
  node.draw_arc(at-Vector2(0,10),r*.66,-PI*.6+p*4.2,PI*.1+p*4.2,20,Color(.82,.93,1,alpha*(.30-.05*float(i))),1.6,true)
 for i in range(9):
  var t:=float(i)/9.0
  var trail:=at-dir*(20.0+p*50.0)*(1.0-t)+Vector2(0,-6.0-t*22.0)+Vector2.from_angle(t*6.0+p*3.0)*(8.0+t*16.0)
  node.draw_circle(trail,2.4*(1.0-t*.5),Color(.74,.90,1,alpha*.55))
  node.draw_line(trail,trail-dir*(10.0+p*14.0),Color(.86,.95,1,alpha*.35),1.6,true)
 for i in range(7):
  var a:=float(i)*TAU/7.0-p*4.0
  var leaf:=at+Vector2.from_angle(a)*(20.0+p*46.0)+Vector2(0,-p*20.0)
  node.draw_set_transform(leaf,a,Vector2(1.0,.5))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-3,0),Vector2(0,-5),Vector2(3,0),Vector2(0,4)]),Color(.86,.62,.42,alpha*.60))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 장영실: 맞물려 돌아가는 다층 황동 톱니 + 혼천의 궤도선 + 별.
static func kit_machine(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 for layer in range(3):
  var radius:=16.0+p*26.0+float(layer)*13.0
  var spin:=p*(4.0-float(layer)*1.2)*(1.0 if layer%2==0 else -1.0)
  var teeth:=10+layer*4
  for i in range(teeth):
   var a:=float(i)*TAU/float(teeth)+spin
   var inner:=Vector2.from_angle(a)*radius
   var outer:=Vector2.from_angle(a)*(radius+4.0)
   node.draw_line(center+inner,center+outer,Color(.92,.80,.52,alpha*(.75-.15*float(layer))),2.6,true)
  node.draw_arc(center,radius,0,TAU,40,Color(.85,.72,.44,alpha*(.55-.1*float(layer))),2.2,true)
  node.draw_arc(center,radius*.58,0,TAU,32,Color(.62,.56,.44,alpha*(.40-.08*float(layer))),1.6,true)
  node.draw_circle(center+Vector2.from_angle(spin)*(radius*.78),1.8,Color(1,.94,.72,alpha*.85))
 for i in range(8):
  var a2:=float(i)*TAU/8.0-p*2.2
  var star:=center+Vector2.from_angle(a2)*(30.0+p*44.0)
  node.draw_line(star-Vector2(3,0),star+Vector2(3,0),Color(1,.96,.82,alpha*.60),1.2,true)
  node.draw_line(star-Vector2(0,3),star+Vector2(0,3),Color(1,.96,.82,alpha*.60),1.2,true)
## 바리공주: 피어오르는 연꽃/저승꽃 꽃잎 + 영혼 띠 + 따뜻한 고리.
static func kit_lotus(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 for i in range(10):
  var a:=float(i)*TAU/10.0+p*1.6
  var rise:=p*40.0+float(i)*2.4
  var petal:=center+Vector2.from_angle(a)*(12.0+p*34.0)+Vector2(0,-rise)
  node.draw_set_transform(petal,a,Vector2(1.0,.62))
  var tint:=Color(.62,.86,1.0,alpha*.55) if i%2==0 else Color(1,.83,.62,alpha*.55)
  node.draw_colored_polygon(PackedVector2Array([Vector2(-5,0),Vector2(0,-9),Vector2(5,0),Vector2(0,5)]),tint)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  node.draw_circle(petal,1.3,Color(1,1,.92,alpha*.8))
 for i in range(4):
  node.draw_arc(center,14.0+p*40.0+float(i)*9.0,0,TAU,36,Color(1,.88,.66,alpha*(.30-.06*float(i))),2.0,true)
 # 영혼 띠: 나선으로 감기는 가는 빛줄기
 for i in range(3):
  var points:=PackedVector2Array()
  for k in range(14):
   var t:=float(k)/13.0
   var a:=t*TAU*1.1+p*3.0+float(i)*TAU/3.0
   points.append(center+Vector2.from_angle(a)*(10.0+t*(30.0+p*26.0))+Vector2(0,-t*26.0))
  for k in range(points.size()-1):
   node.draw_line(points[k],points[k+1],Color(.78,.92,1,alpha*.35),1.4,true)
## 강림도령: 붉은-청록 저승 사슬 궤적 + 삼도천 파동 + 부적 문양.
static func kit_gate(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 for side in [-1.0,1.0]:
  for i in range(6):
   var t:=float(i)/5.0
   var spot:=center+Vector2(side*(26.0+p*20.0)*(1.0-t*.4),-t*(46.0+p*40.0))
   var tint:=Color(.92,.34,.42,alpha*.65) if i%2==0 else Color(.36,.86,.84,alpha*.65)
   node.draw_rect(Rect2(spot-Vector2(4,3),Vector2(8,6)),tint)
   node.draw_rect(Rect2(spot-Vector2(4,3),Vector2(8,6)),Color(.06,.04,.10,alpha*.8),false,1.0)
 for i in range(4):
  node.draw_arc(center+Vector2(0,-6),18.0+p*46.0+float(i)*10.0,PI*1.05,PI*1.95,26,Color(.42,.88,.86,alpha*(.34-.07*float(i))),2.4,true)
  node.draw_arc(center+Vector2(0,-2),14.0+p*36.0+float(i)*8.0,0.1,PI-0.1,24,Color(.94,.42,.46,alpha*(.26-.06*float(i))),2.0,true)
 for i in range(7):
  var a:=float(i)*TAU/7.0+p*2.2
  node.draw_circle(center+Vector2.from_angle(a)*(22.0+p*34.0),1.6,Color(.86,.92,1,alpha*.6))
## 구미호: 아홉 갈래 여우불 꼬리 궤적 + 분홍 꽃잎 소용돌이 + 눈매.
static func kit_fox(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 for i in range(9):
  var a:=-PI*0.85+float(i)*PI*0.85/8.0+p*0.9
  var length:=34.0+p*34.0
  var base:=center+Vector2(0,10.0)
  var tip:=base+Vector2.from_angle(a)*length
  var mid:=base+Vector2.from_angle(a+0.35)*length*0.55
  var tint:=Color(1,.86,.55,alpha*.55) if i%2==0 else Color(1,.58,.84,alpha*.55)
  node.draw_line(base,mid,Color(tint.r,tint.g,tint.b,alpha*.55),3.4,true)
  node.draw_line(mid,tip,Color(tint.r,tint.g,tint.b,alpha*.30),2.0,true)
  node.draw_circle(tip,2.0,Color(1,.95,.98,alpha*.85))
 for i in range(10):
  var a2:=float(i)*TAU/10.0-p*3.0
  var petal:=center+Vector2.from_angle(a2)*(16.0+p*40.0)+Vector2(0,-p*18.0)
  node.draw_set_transform(petal,a2+p*2.0,Vector2(1.0,.55))
  node.draw_colored_polygon(PackedVector2Array([Vector2(-4,0),Vector2(0,-6),Vector2(4,0),Vector2(0,4)]),Color(1,.66,.86,alpha*.60))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_arc(center-Vector2(0,22),12.0+p*18.0,PI*1.1,PI*1.9,20,Color(1,.42,.72,alpha*.55),2.6,true)
## 장산범: 일그러지는 음파/충격 고리 + 붉은 손톱 할퀴기 + 안개.
static func kit_tiger(node: Node2D,at: Vector2,center: Vector2,p: float,facing: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 smoke(node,at-Vector2(0,10),52.0,p,Color(.16,.12,.12,.32),5,1.2)
 for i in range(4):
  var r:=18.0+p*72.0+float(i)*12.0
  node.draw_arc(at-Vector2(0,12),r,0,TAU,48,Color(.96,.52,.30,alpha*(.34-.06*float(i))),3.0-float(i)*.5,true)
  for k in range(3):
   var a:=float(k)*TAU/3.0+p*2.0
   node.draw_arc(at-Vector2(0,12),r*.86,a,a+0.5,12,Color(1,.72,.42,alpha*.22),1.6,true)
 var dir:=Vector2.from_angle(facing*PI/4)
 for i in range(4):
  var offset:=Vector2(-dir.y,dir.x)*(float(i)-1.5)*7.0
  var start:=center+offset-dir*10.0
  var end:=center+offset+dir*(34.0+p*22.0)
  node.draw_line(start,end,Color(.86,.16,.20,alpha*.70),2.2,true)
  node.draw_line(start+Vector2(0,4),end+Vector2(0,4),Color(1,.36,.42,alpha*.40),1.4,true)
## 도깨비: 춤추는 청록 도깨비불 + 지면 균열 충격파 + 방망이 섬광.
static func kit_goblin(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.85,0.0,1.0)
 for i in range(8):
  var a:=float(i)*TAU/8.0+p*2.8
  var spot:=center+Vector2.from_angle(a)*(18.0+p*48.0)+Vector2(0,-12.0-absf(sin(p*8.0+float(i)))*14.0)
  var size:=5.0*(1.0-p*.45)
  node.draw_circle(spot,size,Color(.40,.98,.74,alpha*.60))
  node.draw_circle(spot,size*.5,Color(.92,1,.98,alpha*.85))
  node.draw_line(spot,spot+Vector2(0,-9.0-p*6.0),Color(.55,1,.86,alpha*.30),1.8,true)
  node.draw_circle(spot+Vector2(sin(p*9.0+float(i))*4.0,-6.0),1.4,Color(.86,1,.94,alpha*.70))
 node.draw_set_transform(at,0,Vector2(1.0,.40))
 for i in range(4):
  node.draw_arc(Vector2.ZERO,20.0+p*54.0+float(i)*12.0,0,TAU,44,Color(.52,1,.82,alpha*(.32-.06*float(i))),2.6,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 지면 균열
 for i in range(7):
  var a2:=float(i)*TAU/7.0+0.3
  var crack:=at+Vector2.from_angle(a2)*(14.0+p*40.0)
  node.draw_line(at,crack,Color(.06,.10,.08,alpha*.55),2.0,true)
  node.draw_line(crack,crack+Vector2.from_angle(a2+0.5)*(8.0+p*10.0),Color(.08,.12,.10,alpha*.40),1.4,true)
## 야광귀: 반짝이는 형광 분진 궤적 + 흩날리는 가루 + 발자국 잔상.
static func kit_glow(node: Node2D,at: Vector2,center: Vector2,p: float) -> void:
 var alpha:=clampf(1.0-p*0.8,0.0,1.0)
 for i in range(16):
  var a:=float(i)*TAU/16.0+p*3.6
  var r:=8.0+p*(30.0+float((i*23)%17)*2.4)
  var spot:=center+Vector2.from_angle(a)*r+Vector2(0,-14.0-p*26.0)
  var flicker:=0.55+0.45*sin(p*10.0+float(i)*1.7)
  node.draw_circle(spot,1.5+1.3*flicker,Color(.62,1,.92,alpha*.85*flicker))
  node.draw_line(spot-Vector2(2.4,0),spot+Vector2(2.4,0),Color(1,1,1,alpha*.45*flicker),1.0,true)
  node.draw_line(spot-Vector2(0,2.4),spot+Vector2(0,2.4),Color(1,1,1,alpha*.45*flicker),1.0,true)
 for side in [-1.0,1.0]:
  var print_at:=at+Vector2(side*8.0,0)
  node.draw_set_transform(print_at,0,Vector2(1.0,.5))
  node.draw_circle(Vector2.ZERO,5.4,Color(.45,.96,.86,alpha*.30))
  node.draw_arc(Vector2.ZERO,5.4,0,TAU,16,Color(.82,1,.96,alpha*.60),1.4,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(4):
  node.draw_arc(at-Vector2(0,10),14.0+p*34.0+float(i)*8.0,0,TAU,34,Color(.55,1,.92,alpha*(.24-.05*float(i))),1.6,true)
