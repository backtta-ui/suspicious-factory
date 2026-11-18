extends RefCounted
## 월하의 서원 정적 배경화. 무거운 그리기는 월드 시작 시 한 번만 하고,
## 물결·불빛처럼 실제로 움직이는 것만 별도 레이어에서 다시 그린다.
const ATLAS=preload("res://assets/woo/v11/village_atlas.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
const GROUND=preload("res://assets/woo/worlds/plaza_ground.png")
## 2.0.19: 격자·타일 블록 없이 통으로 그린 바닥 원화(1800x1400).
## 이동 가능 마스크·충돌은 tools/bake_seowon_ground.py가 layout.gd 수치로 1:1 합성한다.
const GROUND_ART=preload("res://assets/woo/seowon/seowon_ground.png")
const WALL_TEX=preload("res://assets/woo/seowon/wall_h.png")
const L=preload("res://scripts/survival/layout.gd")
const HANOK_CELL=Rect2(0,0,512,512)
const HANOK_B_CELL=Rect2(512,0,512,512)
const PAVILION_CELL=Rect2(0,512,512,512)
const CHERRY_CELL=Rect2(512,512,512,512)
const BAMBOO_CELL=Rect2(1024,512,512,512)
const DECOR_CELL=Vector2(425,411)
const DECOR_JARS=6
const DECOR_LANTERN=7
const DECOR_BRIDGE=8
const TREE_BASE=472.0
## 벚꽃나무·석등·대나무 숲의 실제 배치(충돌은 layout.gd가 담당).
const TREES=[Vector2(1040,330),Vector2(1690,880),Vector2(120,1160),Vector2(640,1100),Vector2(1470,1210),Vector2(950,300)]
const LANTERNS=[Vector2(330,700),Vector2(990,640),Vector2(1140,1070),Vector2(770,470),Vector2(560,930),Vector2(1240,1130),Vector2(700,600),Vector2(1120,530),Vector2(1240,760),Vector2(900,1030),Vector2(240,800),Vector2(640,1180)]
static func shade(x: int,y: int,salt: int=0) -> float:
 var n: int=(x*73856093)^(y*19349663)^(salt*83492791)
 n=(n^(n>>13))*1274126177
 return float(abs(n%10000))/10000.0
static func round_rect(node: Node2D,rect: Rect2,color: Color,radius: float) -> void:
 var r:=minf(radius,minf(rect.size.x,rect.size.y)*.5)
 node.draw_rect(Rect2(rect.position+Vector2(r,0),rect.size-Vector2(r*2,0)),color)
 node.draw_rect(Rect2(rect.position+Vector2(0,r),rect.size-Vector2(0,r*2)),color)
 for corner in [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),Vector2(rect.position.x+r,rect.end.y-r),rect.end-Vector2(r,r)]:node.draw_circle(corner,r,color)
static func glow(node: Node2D,center: Vector2,radius: float,color: Color) -> void:
 for i in range(4):
  var t:=1.0-float(i)/4
  node.draw_circle(center,radius*t,Color(color.r,color.g,color.b,color.a*.22*(1.0-t*.55)))
static func star_field(node: Node2D) -> void:
 for i in range(70):
  var x:=shade(i,7)*1800;var y:=shade(i,11)*170
  node.draw_circle(Vector2(x,y),.6+shade(i,3)*1.3,Color(1,.95,.82,.18+shade(i,5)*.35))
static func draw_moon(node: Node2D) -> void:
 var center:=Vector2(1470,150)
 glow(node,center,150,Color(.62,.68,1,.55))
 node.draw_circle(center,86,Color("f6f0d6"));node.draw_circle(center+Vector2(-16,-10),70,Color("fffdf0") )
 for i in range(6):
  var c:=center+Vector2(-46+shade(i,21)*92,-40+shade(i,22)*80);node.draw_circle(c,5+shade(i,23)*10,Color(.86,.84,.72,.35))
 # cloud band
 for i in range(9):
  var p:=Vector2(1210+i*70,120+sin(i*1.7)*16);node.draw_circle(p,20+shade(i,31)*14,Color(.52,.55,.78,.16))
 for i in range(7):
  var p:=Vector2(1330+i*62,205+cos(i*1.3)*10);node.draw_circle(p,16+shade(i,41)*10,Color(.48,.5,.72,.12))
## 바닥은 1800x1400 통 원화 한 장. 격자선·사각 패치·디버그 타일을 그리지 않는다.
## 돌길/화단 경계·돌 턱·이끼 펄·등불 빛웅덩이는 원화에 이미 구워져 있고,
## 그 경계는 layout.gd의 이동 가능 영역과 1:1로 맞춰져 있다.
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-40,-40),L.SIZE+Vector2(80,80)),Color("04070d"))
 node.draw_texture_rect(GROUND_ART,Rect2(Vector2.ZERO,L.SIZE),false)
static func draw_walls(node: Node2D) -> void:
 var segments: Array=[Rect2(60,120,820,14),Rect2(930,120,810,14)]
 for seg in segments:wall_sprite(node,seg)
 for rect in L.WALLS:wall_sprite(node,rect)
static func wall_sprite(node: Node2D,rect: Rect2) -> void:
 var horizontal:=rect.size.x>=rect.size.y
 if horizontal:
  var x:=rect.position.x-4
  while x<rect.end.x:
   var width:=minf(120.0,rect.end.x-x+4)
   node.draw_texture_rect_region(WALL_TEX,Rect2(x,rect.position.y-36,width,62),Rect2(0,0,760,443))
   node.draw_circle(Vector2(x+2,rect.position.y+2),3,Color(.05,.05,.08,.35))
   x+=width
 else:
  node.draw_set_transform(Vector2(rect.get_center().x,-4),PI/2,Vector2(1,1))
  var local: float=-rect.size.y*.5
  while local<rect.size.y*.5:
   var width: float=minf(120.0,rect.size.y*.5-local)
   node.draw_texture_rect_region(WALL_TEX,Rect2(local,-31,width,62),Rect2(0,0,760,443))
   local+=width
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
static func wall(node: Node2D,rect: Rect2) -> void:
 node.draw_rect(rect.grow(4),Color(.02,.03,.06,.5))
 node.draw_rect(rect,Color("332f42"))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y*.42)),Color("454055"))
 node.draw_rect(rect,Color(.13,.12,.18,.85),false,1.5)
 node.draw_rect(Rect2(rect.position+Vector2(-2,-4),Vector2(rect.size.x+4,4)),Color("5a5468"))
 for i in range(10):
  var t:=shade(i,int(rect.position.x)+int(rect.position.y),7)
  var p: Vector2=rect.position+Vector2(t*rect.size.x,(.25+shade(i,3)*.6)*rect.size.y)
  node.draw_circle(p,1.6+shade(i,4)*2.2,Color(.25,.32,.26,.55))
static func tiled_wall(node: Node2D,rect: Rect2) -> void:
 node.draw_rect(rect.grow(4),Color(.02,.03,.06,.4))
 node.draw_rect(rect,Color("4b4552"))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y*.55)),Color("6d6470"))
 node.draw_rect(rect,Color(.12,.11,.16,.9),false,1.5)
 if rect.size.x>=rect.size.y:
  # 기와 용마루
  node.draw_rect(Rect2(rect.position+Vector2(-2,-5),Vector2(rect.size.x+4,6)),Color("2c2b3c"))
  node.draw_rect(Rect2(rect.position+Vector2(-2,-6),Vector2(rect.size.x+4,2)),Color(.62,.58,.7,.55))
  var x:=rect.position.x+3
  while x<rect.end.x-2:
   node.draw_arc(Vector2(x,rect.position.y-1),4,PI,TAU,6,Color("3a394d"),1.6,true)
   x+=8
  for i in range(int(rect.size.x/26)):
   node.draw_line(Vector2(rect.position.x+i*26,rect.position.y+8),Vector2(rect.position.x+i*26,rect.end.y-4),Color(.28,.25,.32,.35),1)
 else:
  node.draw_rect(Rect2(rect.position+Vector2(-5,-2),Vector2(6,rect.size.y+4)),Color("2c2b3c"))
  node.draw_rect(Rect2(rect.position+Vector2(-6,-2),Vector2(2,rect.size.y+4)),Color(.62,.58,.7,.55))
  var y:=rect.position.y+3
  while y<rect.end.y-2:
   node.draw_arc(Vector2(rect.position.x-1,y),4,PI*.5,PI*1.5,6,Color("3a394d"),1.6,true)
   y+=8
  for i in range(int(rect.size.y/26)):
   node.draw_line(Vector2(rect.position.x+8,rect.position.y+i*26),Vector2(rect.end.x-4,rect.position.y+i*26),Color(.28,.25,.32,.35),1)
 for i in range(6):
  node.draw_circle(Vector2(rect.position.x+shade(i,int(rect.position.x),5)*rect.size.x,rect.position.y+shade(i,6)*rect.size.y),2.2,Color(.3,.4,.3,.45))
static func path(node: Node2D,points: PackedVector2Array,width: float) -> void:
 for i in range(points.size()-1):
  node.draw_line(points[i],points[i+1],Color("8f8578").darkened(.35),width+6)
  node.draw_line(points[i],points[i+1],Color("a99a86").darkened(.4),width)
  for s in range(3):
   var t:=float(s)/3
   node.draw_circle(points[i].lerp(points[i+1],t),width*.42,Color(.63,.6,.62,.18))
static func draw_petals(node: Node2D,count: int,area: Rect2,color: Color) -> void:
 for i in range(count):
  var p:=area.position+Vector2(shade(i,51)*area.size.x,shade(i,52)*area.size.y)
  var a:=shade(i,53)*TAU;var w:=1.4+shade(i,54)*2.2
  node.draw_set_transform(p,a,Vector2(1,.55))
  node.draw_circle(Vector2.ZERO,w,Color(color.r,color.g,color.b,color.a*(.35+shade(i,55)*.65)))
  node.draw_set_transform(Vector2.ZERO)
static func draw_ground_decor(node: Node2D) -> void:
 # 연못·다리·바닥 문양·평상 마루는 원화가 맡고, 여기서는 물가 갈대만 남긴다.
 reeds(node)

static func reeds(node: Node2D) -> void:
 for i in range(7):
  var side:=i%2
  var x:=L.POND.position.x+30+i*46
  var base_y:=L.POND.end.y-6 if side==0 else L.POND.position.y+8
  for k in range(3):
   node.draw_line(Vector2(x+k*4,base_y),Vector2(x+k*4-6+shade(i,63)*12,base_y-18-shade(i,64)*16),Color(.45,.55,.42,.7),1.6)

## 연못 원화 위에 달빛 반사와 물결만 얇게 얹는다(모양은 원화가 담당).
static func draw_water_glints(node: Node2D,pond: Rect2,time: float) -> void:
 for i in range(10):
  var y:=pond.position.y+24+i*19
  var x:=pond.position.x+pond.size.x*.70+sin(time*.6+i*.7)*10
  node.draw_line(Vector2(x-24,y),Vector2(x+28,y+sin(time+i)*2),Color(.85,.9,1,.06+.06*absf(sin(time*.8+i))),1.5)
 for i in range(6):
  var center:=pond.position+Vector2(46+shade(i,85)*(pond.size.x-92),34+shade(i,86)*(pond.size.y-68))
  var phase:=fmod(time*.35+shade(i,87),1.0)
  node.draw_arc(center,8+phase*22,0,TAU,20,Color(.62,.76,1,.16*(1-phase)),1.2,true)
 for i in range(4):
  var center:=pond.position+Vector2(60+i*64,52+shade(i,84)*(pond.size.y-100))
  node.draw_arc(center,10+sin(time+i)*2,0,TAU,18,Color(.8,.72,.95,.05),2,true)
