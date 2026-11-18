extends RefCounted
## 도술 이펙트: 화면을 가리지 않는 얇은 빛·부적·불꽃만 그린다.
## 모든 형태는 원/선/다각형 몇 개로 끝나며 텍스처·폰트를 새로 만들지 않는다.
const GOLD=Color("f0c46a")
const TALISMAN=Color("ffd98a")
const FOX=Color("7fe4d6")
const FLAME=Color("ff8a3c")
const GHOST=Color("8fd8ff")
const SHADOW=Color("b48cf0")
static func draw(node: Node2D,e: Dictionary,now: float) -> void:
 var life: float=maxf(.01,float(e.get("until",now+.5))-float(e.get("born",now)))
 var p: float=clampf((now-float(e.get("born",now)))/life,0,1)
 var at: Vector2=e.get("position",Vector2.ZERO)
 match String(e.get("kind","")):
  "fx_talisman":talisman(node,at,p,float(e.get("facing",0)))
  "fx_foxfire":foxfire(node,at,p)
  "fx_flame":flame(node,at,p)
  "fx_ghost":ghost(node,at,p)
  "fx_shadow":shadow(node,at,p,float(e.get("facing",0)))
  "fx_poof":poof(node,at,p)
  "fx_rescue":rescue(node,at,p)
  "fx_door":door(node,at,p)
  "seal":seal(node,at,p)
  "miss":miss(node,at,p)
  "clone":afterimage(node,at,p,float(e.get("facing",0)))
  "smoke":haze(node,at,p)
static func talisman(node: Node2D,at: Vector2,p: float,facing: float) -> void:
 var alpha:=1-p
 for i in range(5):
  var angle:=facing*PI/4+i*.6+p*2.4
  var radius:=10+p*30
  var pos:=at+Vector2.from_angle(angle)*radius-Vector2(0,14)
  node.draw_set_transform(pos,angle,Vector2(1,.65))
  node.draw_rect(Rect2(-4,-7,8,14),Color(1,.85,.5,alpha*.9))
  node.draw_rect(Rect2(-4,-7,8,14),Color(1,.62,.25,alpha*.7),false,1)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_arc(at-Vector2(0,10),8+p*26,0,TAU,28,Color(1,.87,.55,alpha*.5),2,true)
 for i in range(6):
  var q:=at+Vector2.from_angle(i*TAU/6+p)* (20+p*34)
  node.draw_circle(q,1.8,Color(1,.9,.6,alpha*.7))
static func foxfire(node: Node2D,at: Vector2,p: float) -> void:
 var alpha:=1-p
 for i in range(3):
  var angle:=i*TAU/3+p*3.0
  var pos:=at+Vector2.from_angle(angle)*(6+p*26)-Vector2(0,18+p*8)
  node.draw_circle(pos,5.5,Color(.5,1,.92,alpha*.9))
  node.draw_circle(pos,2.4,Color(.92,1,.98,alpha))
  node.draw_line(pos,pos+Vector2.from_angle(angle+PI)*(10+p*8),Color(.45,.95,.9,alpha*.35),3)
 node.draw_arc(at-Vector2(0,18),12+p*24,0,TAU,24,Color(.5,1,.92,alpha*.25),1.5,true)
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
