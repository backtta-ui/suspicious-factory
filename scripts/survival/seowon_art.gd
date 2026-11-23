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
const BK=preload("res://scripts/survival/building_kit.gd")
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
const TREES=[Vector2(1150,300),Vector2(2150,250),Vector2(2950,250),Vector2(200,700),Vector2(950,600),Vector2(1900,950),Vector2(2200,950),Vector2(1200,1750),Vector2(1500,1600),Vector2(1850,1750),Vector2(2300,1600),Vector2(2600,1600),Vector2(3160,1050),Vector2(3160,2150),Vector2(1700,2250),Vector2(900,2380),Vector2(500,2320),Vector2(2500,2400)]
const LANTERNS=[Vector2(880,900),Vector2(1100,1060),Vector2(1400,1130),Vector2(1750,1190),Vector2(2100,1120),Vector2(2400,1050),Vector2(2600,940),Vector2(2750,1050),Vector2(2900,1250),Vector2(3050,1500),Vector2(3100,1750),Vector2(3000,2000),Vector2(2800,2100),Vector2(2500,2160),Vector2(2200,2150),Vector2(1800,2120),Vector2(1400,2080),Vector2(1100,2150),Vector2(950,2250),Vector2(700,2200),Vector2(600,2000),Vector2(560,1800),Vector2(600,1600),Vector2(700,1450),Vector2(800,1200),Vector2(900,1000),Vector2(1600,1000),Vector2(1750,850),Vector2(520,1150),Vector2(2100,340),Vector2(1500,850),Vector2(2300,1300)]
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
 # 2.0.39: 돌 사이 흙벽 질감(은은하게, 원래 톤을 해치지 않게).
 BK.tiled(node,"wall_plaster",rect,Color(STONE_BASE.r*0.9,STONE_BASE.g*0.88,STONE_BASE.b*0.85,.42))
 # 3) 기와 지붕 띠: 담장 위쪽으로 얹는다.
 var roof_depth:=13.0
 if horizontal:
  var top:=rect.position.y-roof_depth
  node.draw_rect(Rect2(rect.position.x-5,top,rect.size.x+10,roof_depth+4),TILE_DARK)
  # 2.0.39: 기와 타일 한 줄을 반복해 담장 기와를 그린다(물받이 곡선이 살아 있다).
  BK.tiled(node,"roof_giwa",Rect2(rect.position.x-4,top+1,rect.size.x+8,roof_depth),Color(1,1,1,1))
  var x2:=rect.position.x-4
  while x2<rect.end.x+4:
   node.draw_circle(Vector2(x2,top+roof_depth*.82),1.6,Color(TILE_LIGHT,.55))
   x2+=9.0
  node.draw_rect(Rect2(rect.position.x-6,top-2,rect.size.x+12,3),TILE_LIGHT)
  node.draw_rect(Rect2(rect.position.x-6,top-3,rect.size.x+12,1.5),Color(.72,.76,.86,.55))
  node.draw_rect(Rect2(rect.position.x-5,rect.position.y-1,rect.size.x+10,3),Color(.02,.02,.04,.5))
 else:
  var left:=rect.position.x-roof_depth
  node.draw_rect(Rect2(left,rect.position.y-5,roof_depth+4,rect.size.y+10),TILE_DARK)
  BK.tiled(node,"roof_giwa",Rect2(left+1,rect.position.y-4,roof_depth,rect.size.y+8),Color(1,1,1,1))
  var y2:=rect.position.y-4
  while y2<rect.end.y+4:
   node.draw_circle(Vector2(left+roof_depth*.82,y2),1.6,Color(TILE_LIGHT,.55))
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
## 2.0.30 보행 경계를 자연스럽게 보여 주는 바닥 연출.
## 인위적인 경계선 대신, 막힌 곳마다 돌 턱·단차 그림자·흙·잔디 턱을 깐다.
static func draw_edges(node: Node2D) -> void:
 for rect in L.LOW:low_ledge(node,rect)
 pond_rim(node)
 for rect in L.BAMBOO:bamboo_base(node,rect)
 # 한옥은 원화 자체에 계단·기단 그림자가 있어 따로 덧그리지 않는다(떠 보이는 띠 방지).
## 낮은 담·평상: 눌러 앉은 돌 평상. 윗면(밝은 화강암) + 앞면(그림자) + 접지 그림자.
static func low_ledge(node: Node2D,rect: Rect2) -> void:
 var horizontal:=rect.size.x>=rect.size.y
 var extent:=rect.size.x if horizontal else rect.size.y
 if horizontal:
  var left:=rect.position.x
  var width:=rect.size.x
  var base_y:=rect.end.y
  # 1) 접지 그림자(바닥에 번지는 둥근 그림자)
  node.draw_set_transform(Vector2(rect.get_center().x,base_y+3),0,Vector2(1.0,.30))
  for i in range(4):
   node.draw_circle(Vector2.ZERO,width*.52-float(i)*6.0,Color(.02,.03,.06,.10-float(i)*.02))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  # 2) 앞면(어두운 돌 + 이음새)
  node.draw_rect(Rect2(left,base_y-13.0,width,14.0),Color(.33,.32,.31,1.0))
  node.draw_rect(Rect2(left,base_y-1.0,width,3.0),Color(.18,.17,.17,.85))
  var blocks:=maxi(2,int(width/42.0))
  for i in range(1,blocks):
   var x:=left+width*float(i)/float(blocks)
   node.draw_line(Vector2(x,base_y-12.0),Vector2(x,base_y-1.0),Color(.22,.21,.20,.65),1.0)
  # 3) 윗면(밝은 판석) + 윗모서리 하이라이트
  node.draw_rect(Rect2(left-3.0,base_y-24.0,width+6.0,12.0),Color(.66,.62,.55,1.0))
  node.draw_rect(Rect2(left-3.0,base_y-24.0,width+6.0,2.4),Color(.86,.82,.72,.95))
  # 기와 상판 결: 돌 벤치 위에 얇은 기와 줄을 얹어 회색 막대처럼 보이지 않게 한다.
  var tx:=left
  while tx<left+width:
   node.draw_line(Vector2(tx,base_y-23.0),Vector2(tx,base_y-13.0),Color(.48,.45,.42,.55),1.2)
   node.draw_line(Vector2(tx,base_y-23.0),Vector2(tx+7.0,base_y-23.0),Color(.42,.40,.46,.45),1.0)
   tx+=9.0
  node.draw_rect(Rect2(left-3.0,base_y-13.0,width+6.0,1.6),Color(.42,.41,.39,.9))
  # 4) 이끼와 잔돌
  for i in range(3):
   var spot:=Vector2(left+width*(.18+.32*float(i)),base_y-22.0+float(i%2)*2.0)
   node.draw_circle(spot,2.2,Color(.34,.46,.32,.55))
  for i in range(2):
   node.draw_circle(Vector2(left+width*(.30+.4*float(i)),base_y-4.0),1.4,Color(.52,.50,.46,.5))
 else:
  var top:=rect.position.y
  var height:=rect.size.y
  var right_x:=rect.end.x
  node.draw_set_transform(Vector2(right_x+3,rect.get_center().y),0,Vector2(.30,1.0))
  for i in range(4):
   node.draw_circle(Vector2.ZERO,height*.52-float(i)*6.0,Color(.02,.03,.06,.10-float(i)*.02))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  node.draw_rect(Rect2(right_x-13.0,top,14.0,height),Color(.33,.32,.31,1.0))
  node.draw_rect(Rect2(right_x-1.0,top,3.0,height),Color(.18,.17,.17,.85))
  node.draw_rect(Rect2(right_x-24.0,top-3.0,12.0,height+6.0),Color(.60,.58,.54,1.0))
  node.draw_rect(Rect2(right_x-24.0,top-3.0,2.4,height+6.0),Color(.80,.78,.72,.95))
## 연못 물가: 물과 땅 경계에 자연석을 늘어놓고, 물가 흙그림자로 한계를 보여 준다.
static func pond_rim(node: Node2D) -> void:
 var pond:=L.POND
 # 1) 물 밖으로 번지는 축축한 흙 그림자
 for i in range(4):
  node.draw_rect(pond.grow(4.0+float(i)*7.0),Color(.02,.04,.06,.08*(1.0-float(i)/4.0)),false,8.0)
 # 2) 물가의 얇은 젖은 흙 띠
 node.draw_rect(pond.grow(6.0),Color(.16,.17,.14,.55),false,7.0)
 # 3) 물 경계의 어두운 선(깊이감)
 node.draw_rect(pond.grow(1.0),Color(.06,.13,.18,.85),false,2.6)
 # 4) 바깥을 따라 늘어선 둥근 자연석
 var perimeter:=2.0*(pond.size.x+pond.size.y)
 var count:=maxi(12,int(perimeter/54.0))
 for i in range(count):
  var at:=fmod(float(i)*54.0+float(i%2)*13.0,perimeter)
  var spot: Vector2=Vector2.ZERO
  var along_x:=true
  if at<pond.size.x:spot=Vector2(pond.position.x+at,pond.position.y-7.0)
  elif at<pond.size.x+pond.size.y:spot=Vector2(pond.end.x+7.0,pond.position.y+(at-pond.size.x));along_x=false
  elif at<pond.size.x*2.0+pond.size.y:spot=Vector2(pond.end.x-(at-pond.size.x-pond.size.y),pond.end.y+7.0)
  else:spot=Vector2(pond.position.x-7.0,pond.end.y-(at-pond.size.x*2.0-pond.size.y));along_x=false
  var wobble:=0.8+0.45*(float((i*37)%11)/11.0)
  node.draw_set_transform(spot,0,Vector2(1.25,.86) if along_x else Vector2(.86,1.25))
  node.draw_circle(Vector2.ZERO,5.6*wobble,Color(.42,.41,.38,1.0))
  node.draw_circle(Vector2(-.8,-1.2),4.0*wobble,Color(.62,.60,.55,1.0))
  node.draw_circle(Vector2(-1.2,-2.0),1.8*wobble,Color(.76,.74,.68,.9))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 대나무 군락 발치: 흙과 잔디 턱으로 '들어갈 수 없는 덤불'임을 보여 준다.
static func bamboo_base(node: Node2D,rect: Rect2) -> void:
 var center:=Vector2(rect.position.x+rect.size.x*.5,rect.end.y-6.0)
 node.draw_set_transform(center,0,Vector2(1.0,.34))
 node.draw_circle(Vector2.ZERO,rect.size.x*.92,Color(.03,.05,.03,.35))
 node.draw_circle(Vector2.ZERO,rect.size.x*.62,Color(.10,.16,.09,.35))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(7):
  var a:=TAU*float(i)/7.0
  var spot:=center+Vector2.from_angle(a)*rect.size.x*.52+Vector2(0,-2)
  node.draw_circle(spot,2.6,Color(.30,.42,.30,.5))
## 한옥 기단: 건물 발치를 얇은 돌 턱으로 마감해 벽과 마당을 구분한다(떠 보이지 않게).
static func building_base(node: Node2D,building: Dictionary) -> void:
 var rect: Rect2=building.rect
 var bottom:=rect.end.y
 var left:=rect.position.x+6.0
 var width:=rect.size.x-12.0
 for i in range(5):
  node.draw_rect(Rect2(left-4.0,bottom+1.0+float(i)*3.0,width+8.0,3.0),Color(.02,.03,.06,.09-float(i)*.016))
 node.draw_rect(Rect2(left-5.0,bottom-7.0,width+10.0,5.0),Color(.56,.54,.50,1.0))
 node.draw_rect(Rect2(left-5.0,bottom-7.0,width+10.0,1.6),Color(.76,.73,.67,.9))
 node.draw_rect(Rect2(left-5.0,bottom-2.0,width+10.0,3.0),Color(.30,.29,.28,.9))
 var blocks:=maxi(2,int(width/56.0))
 for i in range(1,blocks):
  var x:=left+width*float(i)/float(blocks)
  node.draw_line(Vector2(x,bottom-6.6),Vector2(x,bottom-2.2),Color(.34,.33,.31,.55),1.0)
## 바닥 장식: 길가 잔디·들꽃·갈대.
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
 # 2.0.38 연꽃잎·꽃: 연못 위에 떠 있는 둥근 잎과 분홍 꽃(목표 원화의 연못).
 for i in range(9):
  var at:=pond.position+Vector2(40.0+fmod(float(i)*83.0,pond.size.x-80.0),30.0+fmod(float(i)*61.0,pond.size.y-60.0))
  var bob:=sin(time*.6+float(i))*1.2
  node.draw_set_transform(at+Vector2(0,bob),float(i)*.4,Vector2(1,.62))
  node.draw_circle(Vector2.ZERO,11.0,Color(.16,.30,.22,.85))
  node.draw_arc(Vector2.ZERO,11.0,0.4,TAU-0.4,16,Color(.24,.42,.30,.9),1.6,true)
  node.draw_line(Vector2.ZERO,Vector2.from_angle(float(i)*.8)*9.0,Color(.10,.22,.16,.7),1.4)
  if i%3==0:
   node.draw_circle(Vector2(3,-3),4.2,Color(.96,.72,.82,.92))
   node.draw_circle(Vector2(3,-3),1.8,Color(1,.92,.72,.95))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

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
