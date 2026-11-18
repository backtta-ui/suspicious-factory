extends RefCounted
## 월하의 서원 정적 배경화. 무거운 그리기는 월드 시작 시 한 번만 하고,
## 물결·불빛처럼 실제로 움직이는 것만 별도 레이어에서 다시 그린다.
const ATLAS=preload("res://assets/woo/v11/village_atlas.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
const GROUND=preload("res://assets/woo/worlds/plaza_ground.png")
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
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-40,-40),L.SIZE+Vector2(80,80)),Color("0b1420"))
 # A painted courtyard floor keeps the stonework organic; it is drawn once.
 node.draw_texture_rect_region(GROUND,Rect2(Vector2(0,0),L.SIZE),Rect2(700,300,1800,1400),Color(.52,.55,.74))
 node.draw_rect(Rect2(Vector2(0,0),L.SIZE),Color(.05,.07,.16,.34))
 # Moonlight pools and warm lantern spill.
 for p in [Vector2(860,720),Vector2(430,1060),Vector2(1200,860)]:glow(node,p,300,Color(.5,.58,.95,.14))
 for p in LANTERNS:glow(node,p+Vector2(0,-20),150,Color(1,.68,.34,.10))
 glow(node,Vector2(1470,150),230,Color(.62,.66,1,.14))
 star_field(node)
 draw_moon(node)
 # 서원 담장(북·서·동)과 마당을 나누는 기와담.
 wall(node,Rect2(60,120,820,14));wall(node,Rect2(930,120,810,14))
 for rect in L.WALLS:tiled_wall(node,rect)
 courtyard_medallion(node,Vector2(860,720),138)
 # 문 앞 디딤돌만 남기고, 바닥은 원본 석재 텍스처에 맡긴다.
 for i in range(5):
  var p:=Vector2(410+shade(i,1)*52,596+i*13)
  node.draw_circle(p,9+shade(i,2)*4,Color(.28,.27,.33,.5))
 draw_petals(node,260,Rect2(500,480,760,760),Color(.95,.55,.75,.5))
 draw_petals(node,90,Rect2(240,240,400,420),Color(.95,.6,.8,.4))
 draw_ground_decor(node)
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
static func octagon(center: Vector2,radius: float,rotation: float=0.0) -> PackedVector2Array:
 var pts:=PackedVector2Array()
 for i in range(8):pts.append(center+Vector2.from_angle(rotation+i*TAU/8)*radius)
 pts.append(pts[0]);return pts
static func courtyard_medallion(node: Node2D,center: Vector2,radius: float) -> void:
 # 팔각 문양 바닥: 층층의 돌 테두리와 연꽃 문양
 node.draw_colored_polygon(octagon(center,radius),Color(.21,.21,.27,.55))
 node.draw_colored_polygon(octagon(center,radius-5),Color(.29,.28,.35,.5))
 node.draw_colored_polygon(octagon(center,radius-11),Color(.24,.23,.3,.45))
 for ring in [radius-20,radius*.62,radius*.4]:
  node.draw_polyline(octagon(center,ring),Color(.74,.68,.52,.2),1.5)
 for i in range(32):
  var p:=center+Vector2.from_angle(i*TAU/32)*(radius*(.55+shade(i,5)*.4))
  node.draw_circle(p,1.3,Color(.75,.7,.55,.18))
 for i in range(8):
  var angle:=i*TAU/8
  var base:=center+Vector2.from_angle(angle)*(radius*.62)
  var tip:=center+Vector2.from_angle(angle)*(radius*.9)
  var side:=Vector2.from_angle(angle+PI*.5)*10
  node.draw_colored_polygon(PackedVector2Array([base,tip+side,tip-side]),Color(.62,.55,.42,.16))
  node.draw_line(base,tip,Color(.78,.7,.52,.22),1.2)
 for i in range(16):
  var p:=center+Vector2.from_angle(i*TAU/16+PI/16)*(radius*.86)
  node.draw_circle(p,2.2,Color(.8,.72,.52,.4))
 node.draw_colored_polygon(octagon(center,radius*.3,PI/8),Color(.31,.3,.37,.6))
 for i in range(8):
  var p:=center+Vector2.from_angle(i*TAU/8+PI/8)*radius*.22
  node.draw_circle(p,radius*.07,Color(.52,.46,.36,.4))
 node.draw_circle(center,radius*.11,Color(.55,.48,.35,.45))
 node.draw_arc(center,radius*.11,0,TAU,24,Color(.85,.76,.55,.3),1.5,true)
 # 팔각 주변의 작은 석등 받침
 for i in range(4):
  var p:=center+Vector2.from_angle(i*TAU/4+PI/4)*(radius+22)
  node.draw_circle(p,7,Color("43414f"));node.draw_circle(p+Vector2(-1,-2),4,Color("5d5a68"))
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
 # 연못 주변의 돌 테두리와 갈대, 그리고 다리 아래 그림자.
 pond_shore(node)
 # 벤치·평상 (낮은 장애물과 같은 자리)
 for rect in L.LOW:
  node.draw_rect(Rect2(rect.position+Vector2(0,3),rect.size).grow(3),Color(.02,.02,.05,.45))
  node.draw_rect(rect,Color("3c3a46"));node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("565160"))
  node.draw_rect(rect,Color(.1,.1,.14,.7),false,1)
  for i in range(4):
   var p: Vector2=rect.position+Vector2(shade(i,int(rect.position.x),3)*rect.size.x,.3+shade(i,4)*.5)
   node.draw_circle(p,2,Color(.27,.34,.28,.5))
 # 계단·디딤돌
 for i in range(5):
  node.draw_rect(Rect2(390,600+i*8,92,5),Color(.55,.51,.58,.35))
static func pond_shore(node: Node2D) -> void:
 var p:=L.POND.grow(14)
 round_rect(node,p,Color("4c4a5e"),22)
 round_rect(node,p.grow(-6),Color("2b3348"),20)
 round_rect(node,L.POND,Color("2b3450"),18)
 # 바위 테두리
 for i in range(26):
  var angle:=i*TAU/26
  var center:=L.POND.get_center()+Vector2(cos(angle)*L.POND.size.x*.56,sin(angle)*L.POND.size.y*.60)
  node.draw_circle(center,7+shade(i,61)*6,Color("6f6d80"))
  node.draw_circle(center+Vector2(-2,-3),4+shade(i,62)*3,Color("8d8a9d"))
 # 연못가 석재 난간
 for i in range(14):
  var angle:=i*TAU/14
  var post: Vector2=L.POND.get_center()+Vector2(cos(angle)*L.POND.size.x*.55,sin(angle)*L.POND.size.y*.60)
  node.draw_circle(post+Vector2(0,2),4.5,Color(.05,.05,.09,.5))
  node.draw_rect(Rect2(post+Vector2(-2.5,-13),Vector2(5,15)),Color("514e5d"))
  node.draw_circle(post+Vector2(0,-14),3.2,Color("6d6a7a"))
 for i in range(7):
  var side:=i%2
  var x:=L.POND.position.x+30+i*46
  var base_y:=L.POND.end.y-6 if side==0 else L.POND.position.y+8
  for k in range(3):
   node.draw_line(Vector2(x+k*4,base_y),Vector2(x+k*4-6+shade(i,63)*12,base_y-18-shade(i,64)*16),Color(.45,.55,.42,.7),1.6)
static func draw_interior(node: Node2D) -> void:
 var floor_rect:=Rect2(L.HANOK.position+Vector2(14,14),L.HANOK.size-Vector2(28,28))
 node.draw_rect(floor_rect.grow(6),Color(.03,.02,.02,.75))
 # 나무 마루: 판자마다 다른 결와 못머리
 var plank:=15
 var row:=0
 for y in range(int(floor_rect.position.y),int(floor_rect.end.y),plank):
  row+=1
  var offset: float=shade(row,11)*70
  var x0:=floor_rect.position.x
  while x0<floor_rect.end.x:
   var w:=minf(56+shade(int(x0),row,3)*46,floor_rect.end.x-x0)
   var tone:=0.82+shade(int(x0),row,5)*0.26
   node.draw_rect(Rect2(x0,y,w-1,plank-1),Color(.48*tone,.33*tone,.2*tone))
   node.draw_line(Vector2(x0,y+1),Vector2(x0+w-2,y+1),Color(.86,.66,.42,.13),1)
   node.draw_line(Vector2(x0+w-1,y),Vector2(x0+w-1,y+plank),Color(.16,.1,.06,.5),1)
   for k in range(2):
    var gx:=x0+8+shade(int(x0),row+k,7)*(w-16)
    node.draw_line(Vector2(gx,y+3),Vector2(gx+6+shade(row,k,9)*10,y+plank-3),Color(.32,.2,.11,.35),1)
   node.draw_circle(Vector2(x0+4,y+3),1.2,Color(.2,.14,.09,.8))
   x0+=w+offset*0.04
 # 벽 안쪽 띠: 회벽 + 목재 틀 + 창호
 var band:=16.0
 var top:=Rect2(floor_rect.position,Vector2(floor_rect.size.x,band))
 var bottom:=Rect2(floor_rect.position+Vector2(0,floor_rect.size.y-band),Vector2(floor_rect.size.x,band))
 var left:=Rect2(floor_rect.position,Vector2(band,floor_rect.size.y))
 var right:=Rect2(floor_rect.position+Vector2(floor_rect.size.x-band,0),Vector2(band,floor_rect.size.y))
 for rect in [top,bottom,left,right]:
  node.draw_rect(rect,Color("5b4128"));node.draw_rect(rect.grow(-2),Color("8d815f"))
 # 창호 격자(따뜻한 불빛) - 좌우 벽
 for spec in [[Vector2(floor_rect.position.x+1,300),Vector2(9,78)],[Vector2(floor_rect.position.x+1,404),Vector2(9,78)],[Vector2(floor_rect.end.x-10,300),Vector2(9,78)],[Vector2(floor_rect.end.x-10,404),Vector2(9,78)]]:
  var rect:=Rect2(spec[0],spec[1])
  node.draw_rect(rect,Color(.95,.76,.42,.9))
  for y in range(int(rect.position.y)+4,int(rect.end.y)-2,9):node.draw_line(Vector2(rect.position.x,rect.end.y-1-(y-rect.position.y)),Vector2(rect.end.x,rect.end.y-1-(y-rect.position.y)),Color(.3,.2,.12,.85),1)
  for x in range(int(rect.position.x)+3,int(rect.end.x),5):node.draw_line(Vector2(x,rect.position.y+2),Vector2(x,rect.end.y-2),Color(.3,.2,.12,.7),1)
  glow(node,rect.get_center(),46,Color(1,.72,.36,.3))
 # 기둥(모서리·중간) - 입체 음영
 for p in [floor_rect.position+Vector2(5,5),floor_rect.position+Vector2(floor_rect.size.x-5,5),floor_rect.position+Vector2(5,floor_rect.size.y-5),floor_rect.position+Vector2(floor_rect.size.x-5,floor_rect.size.y-5),floor_rect.position+Vector2(floor_rect.size.x*.5,5),floor_rect.position+Vector2(floor_rect.size.x*.5,floor_rect.size.y-5)]:
  node.draw_circle(p+Vector2(2,2),6,Color(.06,.04,.03,.7))
  node.draw_circle(p,6,Color("3d2817"));node.draw_circle(p+Vector2(-1.5,-1.8),3.6,Color("805435"))
 # 병풍 4폭: 금빛 산수화
 var screen:=Rect2(276,300,16,122)
 node.draw_rect(Rect2(screen.position+Vector2(3,3),screen.size).grow(5),Color(.05,.03,.02,.8))
 for i in range(4):
  var panel:=Rect2(screen.position.x+1,screen.position.y+3+i*29,14,25)
  node.draw_rect(panel,Color("6a4630"))
  var art:=panel.grow(-1.5)
  node.draw_rect(art,Color(.1,.13,.21))
  node.draw_rect(Rect2(art.position+Vector2(0,art.size.y*.62),Vector2(art.size.x,art.size.y*.38)),Color(.16,.2,.16))
  node.draw_colored_polygon(PackedVector2Array([art.position+Vector2(2,art.size.y*.7),art.position+Vector2(art.size.x*.45,art.size.y*.32),art.position+Vector2(art.size.x*.8,art.size.y*.66)]),Color(.28,.32,.3))
  node.draw_circle(art.position+Vector2(art.size.x*.7,art.size.y*.24),2.6,Color(.95,.85,.6,.85))
  node.draw_line(art.position+Vector2(3,art.size.y-4),art.position+Vector2(art.size.x-3,art.size.y-5),Color(.7,.6,.4,.4),1)
 # 북벽 병풍: 산수화 4폭(문 양옆)
 for i in range(4):
  var panel:=Rect2(292+i*27,282,25,16)
  node.draw_rect(panel,Color("6a4630"));node.draw_rect(panel.grow(-1.5),Color(.11,.14,.22))
  node.draw_colored_polygon(PackedVector2Array([panel.position+Vector2(2,12),panel.position+Vector2(11,4),panel.position+Vector2(20,11)]),Color(.3,.35,.33))
  node.draw_circle(panel.position+Vector2(17,5),1.6,Color(.95,.86,.62,.8))
  for j in range(2):node.draw_line(panel.position+Vector2(3,3+j*4),panel.position+Vector2(22,3+j*4),Color(.75,.66,.44,.25),1)
 # 동벽의 큰 병풍: 산수화 4폭
 var big:=Rect2(556,304,14,150)
 node.draw_rect(Rect2(big.position+Vector2(3,3),big.size),Color(.05,.03,.02,.7))
 for i in range(4):
  var panel:=Rect2(big.position.x,big.position.y+2+i*37,big.size.x,34)
  node.draw_rect(panel,Color("6a4630"))
  var art:=Rect2(panel.position+Vector2(1,1),panel.size-Vector2(2,2))
  node.draw_rect(art,Color(.1,.13,.21))
  node.draw_rect(Rect2(art.position+Vector2(0,art.size.y*.58),Vector2(art.size.x,art.size.y*.42)),Color(.15,.19,.15))
  node.draw_colored_polygon(PackedVector2Array([art.position+Vector2(1,art.size.y*.66),art.position+Vector2(art.size.x*.5,art.size.y*.28),art.position+Vector2(art.size.x-1,art.size.y*.62)]),Color(.3,.34,.32))
  node.draw_circle(art.position+Vector2(art.size.x*.64,art.size.y*.22),2.2,Color(.95,.86,.62,.8))
  node.draw_line(art.position+Vector2(3,art.size.y-3),art.position+Vector2(art.size.x-3,art.size.y-4),Color(.75,.66,.44,.45),1)
  node.draw_circle(panel.position+Vector2(panel.size.x*.5,panel.size.y-1),1.1,Color(.85,.7,.4,.7))
 # 남벽 주련(글씨 천)
 for i in range(2):
  var p: Vector2=Vector2(492+i*54,540)
  node.draw_rect(Rect2(p+Vector2(0,-2),Vector2(16,40)),Color(.86,.8,.62,.9))
  node.draw_rect(Rect2(p+Vector2(0,-2),Vector2(16,40)),Color(.4,.28,.16,.8),false,1)
  for k in range(5):node.draw_line(Vector2(p.x+5,p.y+4+k*7),Vector2(p.x+11,p.y+4+k*7),Color(.22,.18,.16,.75),1.8)
 # 돗자리: 구름 문양(가구보다 먼저 깔린다)
 var rug:=Rect2(356,352,206,152)
 node.draw_rect(rug,Color(.2,.11,.11))
 node.draw_rect(rug.grow(-5),Color(.5,.26,.23))
 node.draw_rect(rug.grow(-10),Color(.56,.3,.26))
 for i in range(5):
  for j in range(3):
   var p:=Vector2(rug.position.x+24+i*38,rug.position.y+28+j*42)
   node.draw_arc(p,8,PI*.15,PI*1.15,10,Color(.88,.68,.44,.28),1.4,true)
   node.draw_arc(p+Vector2(9,0),6,PI*.2,PI*1.1,8,Color(.88,.68,.44,.2),1.2,true)
 for k in range(9):
  var x:=rug.position.x+8+k*24
  node.draw_line(Vector2(x,rug.end.y+2),Vector2(x,rug.end.y+9),Color(.86,.68,.42,.5),1.2)
  node.draw_line(Vector2(x,rug.position.y-9),Vector2(x,rug.position.y-2),Color(.86,.68,.42,.5),1.2)
 node.draw_rect(rug,Color(.86,.68,.42,.3),false,1.2)
 for corner in [rug.position,Vector2(rug.end.x,rug.position.y),Vector2(rug.position.x,rug.end.y),rug.end]:
  node.draw_circle(corner,4,Color(.8,.62,.38,.35))
 # 서안: 서책·붓·촛불·다기
 var desk:=Rect2(432,376,96,50)
 node.draw_rect(Rect2(desk.position+Vector2(2,3),desk.size).grow(2),Color(.05,.03,.02,.6))
 node.draw_rect(desk,Color("4a2f1c"));node.draw_rect(Rect2(desk.position,Vector2(desk.size.x,6)),Color("9a6c40"))
 node.draw_rect(Rect2(desk.position+Vector2(6,10),Vector2(22,12)),Color(.86,.78,.58));node.draw_line(desk.position+Vector2(10,12),desk.position+Vector2(24,12),Color(.45,.35,.2,.6),1)
 node.draw_rect(Rect2(desk.position+Vector2(32,12),Vector2(16,10)),Color(.72,.64,.46))
 node.draw_rect(Rect2(desk.position+Vector2(56,10),Vector2(9,8)),Color(.35,.26,.18))
 for k in range(3):node.draw_line(desk.position+Vector2(58+k*2,10),desk.position+Vector2(56+k*2,-2),Color(.85,.75,.5,.8),1)
 node.draw_circle(desk.position+Vector2(70,16),4,Color(.9,.9,.86));node.draw_circle(desk.position+Vector2(70,16),3,Color(.45,.38,.3))
 node.draw_rect(Rect2(desk.position+Vector2(66,30),Vector2(5,10)),Color(.75,.62,.4));node.draw_circle(desk.position+Vector2(68.5,28),2.6,Color(1,.86,.5));glow(node,desk.position+Vector2(68.5,28),26,Color(1,.7,.3,.45))
 # 서가: 색색의 서책과 항아리
 node.draw_rect(Rect2(540,468,42,88),Color("3c2817"));node.draw_rect(Rect2(540,468,42,5),Color("8d6338"))
 for j in range(3):
  var shelf_y:=476+j*26
  node.draw_rect(Rect2(543,shelf_y,36,2),Color(.2,.13,.08))
  for k in range(4):
   var colors: Array=[Color(.55,.28,.24),Color(.28,.42,.36),Color(.62,.52,.3),Color(.3,.32,.48)]
   node.draw_rect(Rect2(545+k*8,shelf_y+4,6,15),colors[k])
   node.draw_line(Vector2(546+k*8,shelf_y+6),Vector2(550+k*8,shelf_y+6),Color(1,.92,.7,.35),1)
 node.draw_rect(Rect2(546,545,12,9),Color(.5,.28,.24))
 # 화로와 불씨
 node.draw_circle(Vector2(318,502),17,Color(.16,.14,.13));node.draw_circle(Vector2(318,502),13,Color(.36,.2,.13));node.draw_circle(Vector2(318,500),7,Color(1,.5,.2,.85))
 for i in range(6):node.draw_circle(Vector2(318+sin(i*1.7)*7,496+cos(i)*5),1.4,Color(1,.8,.4,.7))
 glow(node,Vector2(318,502),54,Color(1,.55,.25,.4))
 # 방석과 다기
 for p: Vector2 in [Vector2(392,452),Vector2(536,458),Vector2(500,462)]:
  node.draw_circle(p+Vector2(1,2),12,Color(.1,.06,.05,.5))
  node.draw_circle(p,12,Color(.62,.34,.3));node.draw_arc(p,12,0,TAU,20,Color(.86,.66,.42,.7),1.2,true)
  for k in range(4):node.draw_line(p+Vector2(-6+k*4,10),p+Vector2(-8+k*4,15),Color(.85,.68,.4,.7),1)
 # 돗자리: 구름 문양
 # 남벽 창호 격자
 for spec in [[Vector2(300,556),Vector2(70,10)],[Vector2(480,556),Vector2(90,10)]]:
  var rect:=Rect2(spec[0],spec[1])
  node.draw_rect(rect,Color(.95,.78,.44,.85))
  for x in range(int(rect.position.x)+3,int(rect.end.x)-2,7):node.draw_line(Vector2(x,rect.position.y+1),Vector2(x,rect.end.y-1),Color(.3,.2,.12,.85),1)
  node.draw_line(Vector2(rect.position.x,rect.position.y+rect.size.y*.5),Vector2(rect.end.x,rect.position.y+rect.size.y*.5),Color(.3,.2,.12,.85),1)
  glow(node,rect.get_center(),34,Color(1,.72,.36,.35))
 # 매달린 등불·촛불
 for p in [Vector2(470,300),Vector2(330,430),Vector2(560,400),Vector2(430,548)]:
  node.draw_line(p+Vector2(0,-22),p+Vector2(0,-10),Color(.16,.1,.06),1.4)
  node.draw_rect(Rect2(p+Vector2(-4,-10),Vector2(8,10)),Color(.85,.6,.3))
  node.draw_circle(p+Vector2(0,-16),4.2,Color(1,.88,.58));glow(node,p+Vector2(0,-16),38,Color(1,.72,.36,.45))
 # 실내 전체의 따뜻한 기운과 벽 그림자
 glow(node,floor_rect.get_center()+Vector2(0,20),floor_rect.size.x*.55,Color(1,.72,.4,.13))
 for i in range(3):
  var inset:=4+i*5
  node.draw_rect(Rect2(floor_rect.position+Vector2(inset,inset),floor_rect.size-Vector2(inset*2,inset*2)),Color(.02,.01,.01,.10),false,4)
 # 문턱과 새어드는 달빛(앞·뒷문)
 node.draw_rect(Rect2(398,262,74,14),Color(.55,.68,1,.16))
 node.draw_rect(Rect2(398,562,74,14),Color(.55,.68,1,.12))
static func draw_bridge(node: Node2D) -> void:
 var axis:=(L.BRIDGE_B-L.BRIDGE_A).normalized();var side:=axis.orthogonal()*L.BRIDGE_HALF
 var steps:=24
 # 물 위 그림자
 for i in range(steps):
  var t0:=float(i)/steps;var t1:=float(i+1)/steps
  var p0:=L.BRIDGE_A.lerp(L.BRIDGE_B,t0);var p1:=L.BRIDGE_A.lerp(L.BRIDGE_B,t1)
  node.draw_colored_polygon(PackedVector2Array([p0+side+Vector2(0,6),p1+side+Vector2(0,6),p1-side+Vector2(0,6),p0-side+Vector2(0,6)]),Color(.02,.05,.1,.5))
 # 다리 몸체(아치)
 for i in range(steps):
  var t0:=float(i)/steps;var t1:=float(i+1)/steps
  var p0:=L.BRIDGE_A.lerp(L.BRIDGE_B,t0)-Vector2(0,L.bridge_height(t0))
  var p1:=L.BRIDGE_A.lerp(L.BRIDGE_B,t1)-Vector2(0,L.bridge_height(t1))
  var tone:=Color(.36,.29,.23).lightened(.06*sin(t0*PI))
  node.draw_colored_polygon(PackedVector2Array([p0+side,p1+side,p1-side,p0-side]),tone)
  node.draw_line(p0-side,p1-side,Color(.16,.12,.1,.9),3)
  node.draw_line(p0+side,p1+side,Color(.16,.12,.1,.9),3)
  for k in range(1,4):
   var off:=side*(k/2.0)
   node.draw_line(p0+off,p1+off,Color(.24,.19,.15,.35),1)
 # 판자 이음새
 for i in range(1,12):
  var t:=float(i)/12;var p:=L.BRIDGE_A.lerp(L.BRIDGE_B,t)-Vector2(0,L.bridge_height(t))
  node.draw_line(p-side,p+side,Color(.18,.13,.1,.55),2)
  node.draw_line(p-side+Vector2(0,-1),p+side+Vector2(0,-1),Color(.62,.5,.34,.25),1)
 # 난간
 for sign_value in [-1.0,1.0]:
  var rail: Vector2=side*sign_value
  for i in range(steps):
   var t0:=float(i)/steps;var t1:=float(i+1)/steps
   var p0: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,t0)+rail-Vector2(0,L.bridge_height(t0)+12)
   var p1: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,t1)+rail-Vector2(0,L.bridge_height(t1)+12)
   node.draw_line(p0,p1,Color(.14,.1,.08,.95),7)
   node.draw_line(p0+Vector2(0,-1),p1+Vector2(0,-1),Color(.66,.52,.34,.8),2)
  for i in range(1,10):
   var t:=float(i)/10;var base: Vector2=L.BRIDGE_A.lerp(L.BRIDGE_B,t)+rail-Vector2(0,L.bridge_height(t))
   node.draw_line(base,base-Vector2(0,20),Color(.42,.31,.22),5)
   node.draw_line(base,base-Vector2(0,20),Color(.7,.56,.36),2)
   node.draw_circle(base-Vector2(0,22),3.4,Color(.85,.7,.42))
 # 양 끝 석축과 등불
 for end: Vector2 in [L.BRIDGE_A,L.BRIDGE_B]:
  node.draw_circle(end,30,Color("3d3c4c"));node.draw_circle(end+Vector2(0,-4),24,Color("55525f"))
  node.draw_arc(end,30,0,TAU,20,Color(.12,.11,.16,.8),3,true)
 for end: Vector2 in [L.BRIDGE_A,L.BRIDGE_B]:
  var lantern: Vector2=end+axis*24+side*1.2
  node.draw_rect(Rect2(lantern+Vector2(-4,-30),Vector2(8,30)),Color(.2,.15,.12))
  node.draw_rect(Rect2(lantern+Vector2(-9,-46),Vector2(18,18)),Color(.95,.72,.4));node.draw_rect(Rect2(lantern+Vector2(-9,-46),Vector2(18,18)),Color(.25,.16,.1),false,2)
  glow(node,lantern+Vector2(0,-37),70,Color(1,.66,.3,.55))
static func draw_water(node: Node2D,time: float) -> void:
 var pond:=L.POND
 round_rect(node,pond,Color("16294a"),18)
 for i in range(10):
  var band:=Rect2(pond.position+Vector2(0,pond.size.y*(i/10.0)),Vector2(pond.size.x,pond.size.y*.11))
  node.draw_rect(band,Color(.12,.27,.44,.18))
 # 달빛 반사
 for i in range(16):
  var y:=pond.position.y+16+i*13
  var x:=pond.position.x+pond.size.x*.72+sin(time*.6+i*.7)*10
  node.draw_line(Vector2(x-26,y),Vector2(x+30,y+sin(time+i)*2),Color(.82,.86,1,.10+.09*absf(sin(time*.8+i))))
 # 연잎과 연꽃
 for i in range(9):
  var p:=pond.position+Vector2(35+shade(i,81)*(pond.size.x-70),40+shade(i,82)*(pond.size.y-80))
  var r:=13+shade(i,83)*10
  node.draw_circle(p,r,Color(.18,.36,.26,.9));node.draw_circle(p+Vector2(-3,-3),r*.8,Color(.26,.46,.32,.85))
  node.draw_line(p,p+Vector2(r*.7,0),Color(.12,.24,.18,.8),1.4)
 for i in range(4):
  var p:=pond.position+Vector2(60+i*74,60+shade(i,84)*(pond.size.y-110))
  for k in range(6):
   var angle:=k*TAU/6;node.draw_circle(p+Vector2.from_angle(angle)*7,5.2,Color(.9,.55,.72))
  node.draw_circle(p,4,Color(1,.86,.55))
 # 물결
 for i in range(7):
  var center:=pond.position+Vector2(40+shade(i,85)*(pond.size.x-80),30+shade(i,86)*(pond.size.y-60))
  var phase:=fmod(time*.35+shade(i,87),1.0)
  node.draw_arc(center,6+phase*26,0,TAU,20,Color(.55,.7,.95,.20*(1-phase)),1.2,true)
