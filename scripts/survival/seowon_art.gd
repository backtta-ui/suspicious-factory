extends RefCounted
## 월하의 서원 정적 배경화. 무거운 그리기는 월드 시작 시 한 번만 하고,
## 물결·불빛처럼 실제로 움직이는 것만 별도 레이어에서 다시 그린다.
const ATLAS=preload("res://assets/woo/v11/village_atlas.png")
const DECOR=preload("res://assets/woo/v11/decor_atlas.png")
const GROUND=preload("res://assets/woo/worlds/plaza_ground.png")
## 2.0.26: 격자·타일 블록 없이 통으로 그린 바닥 원화(3400x2600, 1:1 해상도).
## 돌길·흙마당·달빛 잔디 구획은 tools/bake_seowon_ground.py가 layout.gd의
## PATHS·건물·연못 수치로 1:1 합성한다.
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
## 벚꽃나무·석등의 실제 배치(충돌은 layout.gd가 담당). 길·화단 안쪽에만 둔다.
const TREES=[Vector2(220,260),Vector2(220,1100),Vector2(220,2060),Vector2(700,1760),Vector2(700,2360),Vector2(820,260),Vector2(820,1100),Vector2(1300,560),Vector2(1300,2360),Vector2(1660,1880),Vector2(1780,260),Vector2(1960,2360),Vector2(2260,860),Vector2(2260,1460),Vector2(2440,2000),Vector2(2500,260),Vector2(3100,920),Vector2(3160,1520)]
const LANTERNS=[Vector2(931,855),Vector2(1262,993),Vector2(1499,716),Vector2(1792,914),Vector2(2061,932),Vector2(2291,992),Vector2(2636,889),Vector2(2886,1121),Vector2(3228,1068),Vector2(3059,1394),Vector2(3281,1676),Vector2(3031,1929),Vector2(2967,2109),Vector2(2748,2193),Vector2(2491,2446),Vector2(2200,2235),Vector2(1918,2461),Vector2(1634,2235),Vector2(1340,2441),Vector2(1120,2186),Vector2(793,2134),Vector2(990,1799),Vector2(764,1519),Vector2(948,1208),Vector2(1771,414),Vector2(1576,1280),Vector2(1804,1559),Vector2(1544,1827),Vector2(1772,2123),Vector2(1529,2396),Vector2(2335,1228),Vector2(1046,1377)]
## 담장 기와 빛깔(밤 하늘 아래 청회색 기와 + 화강석 벽체).
const TILE_DARK=Color("171d2c")
const TILE_MID=Color("42557a")
const TILE_LIGHT=Color("8ea3c8")
const STONE_BASE=Color("746b78")
const STONE_LIGHT=Color("a098a8")
const STONE_DARK=Color("3b3744")
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
## 형태를 따라 번지는 부드러운 접지 그림자. 네모난 검은 상자를 쓰지 않는다.
static func soft_shadow(node: Node2D,center: Vector2,size: Vector2,strength: float=1.0) -> void:
 var layers:=6
 for i in range(layers):
  var t:=1.0-float(i)/layers
  var w:=size.x*t
  var h:=size.y*t
  var alpha:=.055*strength*(1.0-t*.35)
  node.draw_set_transform(center,0,Vector2(1,.5))
  node.draw_circle(Vector2.ZERO,w*.5,Color(.03,.035,.07,alpha))
  node.draw_set_transform(Vector2.ZERO)
  if h<=0.0:break
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
 for i in range(9):
  var p:=Vector2(1210+i*70,120+sin(i*1.7)*16);node.draw_circle(p,20+shade(i,31)*14,Color(.52,.55,.78,.16))
 for i in range(7):
  var p:=Vector2(1330+i*62,205+cos(i*1.3)*10);node.draw_circle(p,16+shade(i,41)*10,Color(.48,.5,.72,.12))
## 바닥은 3400x2600 통 원화 한 장. 격자선·사각 패치·디버그 타일을 그리지 않는다.
static func draw_base(node: Node2D) -> void:
 # 베이크 원화는 world.build_ground()의 셰이더 스프라이트가 깐다.
 # 여기서는 아무것도 덮지 않는다(바닥을 가리면 안 된다).
 pass
## 기와 담장: 기와 지붕 띠 + 화강석 벽체 + 부드러운 접지 그림자.
## 원화 한 조각을 늘려 쓰지 않고 벽 길이에 맞춰 그려서, 줌 1.90에서도 결이 살아 있다.
static func draw_walls(node: Node2D) -> void:
 for i in range(mini(6,L.HARD.size())):wall_sprite(node,L.HARD[i])
 for rect in L.WALLS:wall_sprite(node,rect)
static func wall_sprite(node: Node2D,rect: Rect2) -> void:
 var horizontal:=rect.size.x>=rect.size.y
 var length: float=rect.size.x if horizontal else rect.size.y
 var origin:=Vector2(rect.position.x,rect.position.y+rect.size.y*.5)
 # 1) 부드러운 접지 그림자(아래로 번짐).
 for i in range(5):
  var a:=.10*(1.0-float(i)/5.0)
  if horizontal:
   node.draw_rect(Rect2(rect.position.x-6+i*2,rect.end.y-2+i*5,rect.size.x+12-i*4,6+i*4),Color(.02,.03,.06,a))
  else:
   node.draw_rect(Rect2(rect.position.x-2+i*4,rect.position.y-6+i*2,6+i*4,rect.size.y+12-i*4),Color(.02,.03,.06,a))
 # 2) 화강석 벽체(길이 방향으로 이어 붙인 돌 블록).
 var stones:=maxi(2,int(length/34.0))
 for i in range(stones):
  var t0:=float(i)/stones;var t1:=float(i+1)/stones
  var tone:=.92+shade(i,int(rect.position.x),3)*.16
  var color:=STONE_BASE.lerp(STONE_LIGHT,shade(i,int(rect.position.y),4)*.5)
  color=Color(color.r*tone,color.g*tone,color.b*tone,1.0)
  if horizontal:
   var x:=rect.position.x+rect.size.x*t0
   var w:=rect.size.x*t1-rect.size.x*t0-1.0
   node.draw_rect(Rect2(x,rect.position.y+1,w,rect.size.y),color)
   node.draw_rect(Rect2(x,rect.position.y+1,w,2),Color(STONE_LIGHT,.55))
   node.draw_rect(Rect2(x,rect.end.y-3,w,3),Color(STONE_DARK,.75))
  else:
   var y:=rect.position.y+rect.size.y*t0
   var h:=rect.size.y*t1-rect.size.y*t0-1.0
   node.draw_rect(Rect2(rect.position.x+1,y,rect.size.x,h),color)
   node.draw_rect(Rect2(rect.position.x+1,y,2,h),Color(STONE_LIGHT,.55))
   node.draw_rect(Rect2(rect.end.x-3,y,3,h),Color(STONE_DARK,.75))
 # 3) 기와 지붕 띠: 담장 위쪽으로 얹는다.
 var roof_depth:=13.0
 if horizontal:
  var top:=rect.position.y-roof_depth
  node.draw_rect(Rect2(rect.position.x-5,top,rect.size.x+10,roof_depth+4),TILE_DARK)
  var row:=0.0
  while row<roof_depth:
   var shade_row:=TILE_MID if int(row/4.0)%2==0 else TILE_DARK
   node.draw_rect(Rect2(rect.position.x-4,top+row,rect.size.x+8,3.0),Color(shade_row,.9))
   row+=4.0
  var x2:=rect.position.x-4
  while x2<rect.end.x+4:
   node.draw_line(Vector2(x2,top),Vector2(x2,top+roof_depth*0.75),Color(TILE_DARK,.7),1.0)
   node.draw_circle(Vector2(x2,top+roof_depth*.8),1.6,Color(TILE_LIGHT,.55))
   x2+=9.0
  node.draw_rect(Rect2(rect.position.x-6,top-2,rect.size.x+12,3),TILE_LIGHT)
  node.draw_rect(Rect2(rect.position.x-6,top-3,rect.size.x+12,1.5),Color(.72,.76,.86,.55))
  node.draw_rect(Rect2(rect.position.x-5,rect.position.y-1,rect.size.x+10,3),Color(.02,.02,.04,.5))
 else:
  var left:=rect.position.x-roof_depth
  node.draw_rect(Rect2(left,rect.position.y-5,roof_depth+4,rect.size.y+10),TILE_DARK)
  var row2:=0.0
  while row2<roof_depth:
   var shade_row2:=TILE_MID if int(row2/4.0)%2==0 else TILE_DARK
   node.draw_rect(Rect2(left+row2,rect.position.y-4,3.0,rect.size.y+8),Color(shade_row2,.9))
   row2+=4.0
  var y2:=rect.position.y-4
  while y2<rect.end.y+4:
   node.draw_line(Vector2(left,y2),Vector2(left+roof_depth*0.75,y2),Color(TILE_DARK,.7),1.0)
   node.draw_circle(Vector2(left+roof_depth*.8,y2),1.6,Color(TILE_LIGHT,.55))
   y2+=9.0
  node.draw_rect(Rect2(left-2,rect.position.y-6,3,rect.size.y+12),TILE_LIGHT)
  node.draw_rect(Rect2(left-3,rect.position.y-6,1.5,rect.size.y+12),Color(.72,.76,.86,.55))
  node.draw_rect(Rect2(rect.position.x-1,rect.position.y-5,3,rect.size.y+10),Color(.02,.02,.04,.5))
 # 4) 드문드문 걸린 등불(따뜻한 점).
 if horizontal and length>320:
  var count:=int(length/520.0)
  for i in range(count):
   var p:=Vector2(rect.position.x+length*(0.24+0.52*i/maxf(1,count-1)),rect.position.y-2)
   node.draw_circle(p,3.4,Color(1,.82,.46,.95))
   glow(node,p,26,Color(1,.66,.3,.22))
static func wall(node: Node2D,rect: Rect2) -> void:
 wall_sprite(node,rect)
static func path(node: Node2D,points: PackedVector2Array,width: float) -> void:
 for i in range(points.size()-1):
  node.draw_line(points[i],points[i+1],Color("8f8578").darkened(.35),width+6)
  node.draw_line(points[i],points[i+1],Color("a99a86").darkened(.4),width)
static func draw_petals(node: Node2D,count: int,area: Rect2,color: Color) -> void:
 for i in range(count):
  var p:=area.position+Vector2(shade(i,51)*area.size.x,shade(i,52)*area.size.y)
  var a:=shade(i,53)*TAU;var w:=1.4+shade(i,54)*2.2
  node.draw_set_transform(p,a,Vector2(1,.55))
  node.draw_circle(Vector2.ZERO,w,Color(color.r,color.g,color.b,color.a*(.35+shade(i,55)*.65)))
  node.draw_set_transform(Vector2.ZERO)
## 길이 아닌 잔디 위에만 잔풀·작은 꽃을 벡터로 얹어, 확대해도 결이 뭉개지지 않게 한다.
static func draw_ground_decor(node: Node2D) -> void:
 var tufts:=0
 for i in range(1400):
  var x:=60.0+shade(i,101)*(L.SIZE.x-120.0)
  var y:=70.0+shade(i,102)*(L.SIZE.y-140.0)
  var gap:=L.path_gap(Vector2(x,y))
  if gap>-4.0:continue
  if L.STONE.has_point(Vector2(x,y)):continue
  if L.POND.grow(18).has_point(Vector2(x,y)):continue
  var kind:=int(shade(i,103)*3.0)
  if kind==0:
   for k in range(3):
    var h:=3.0+shade(i,104+k)*5.0
    node.draw_line(Vector2(x+k*1.6-1.6,y),Vector2(x+k*1.6-2.4+shade(i,110+k)*3.0,y-h),Color(.42,.62,.40,.55),1.15)
  elif kind==1:
   node.draw_circle(Vector2(x,y-1),1.25,Color(.62,.85,.66,.72))
   node.draw_circle(Vector2(x+.9,y-1.8),1.0,Color(.72,.9,.72,.6))
  else:
   node.draw_circle(Vector2(x,y-1.4),1.5,Color(.92,.68,.82,.55))
   node.draw_circle(Vector2(x,y-1.4),.6,Color(1,.9,.72,.6))
  tufts+=1
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
