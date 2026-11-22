extends RefCounted
## 2.0.38 네 맵 공통 '상용 2D 카툰' 드로잉 키트.
##
## 바닥 타일·벽 패널·차양·간판·가로등·벤치 같은 것을 매 프레임 다시 계산하지 않고
## 한 번 그리는 정적 레이어(ground/walls/under)에서만 쓴다. 모든 사물은
##  1) 바닥에 번지는 부드러운 그림자 → 2) 몸통(어두운 외곽선) → 3) 윗면 하이라이트
## 순서로 그려, 어떤 배경 위에서도 실루엣이 또렷하게 읽히게 한다.
const INK=Color("0a0d16")
const INK_SOFT=Color(0.03,0.045,0.08,0.55)
const WHITE=Color(1,1,1,0.95)
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
## 바닥·벽 텍스처(2.0.38 생성, 256px 타일). 상업적 재배포 가능(자체 생성).
const TEX_GANGNAM_FLOOR=preload("res://assets/woo/v38/tex_gangnam_floor_256.png")
const TEX_GANGNAM_DIAMOND=preload("res://assets/woo/v38/tex_gangnam_floor_diamond.png")
const TEX_GANGNAM_WALL=preload("res://assets/woo/v38/tex_gangnam_wall_256.png")
const TEX_GANGNAM_PANEL=preload("res://assets/woo/v38/tex_gangnam_panel_256.png")
## 부드러운 접지 그림자(바닥에 눌려 번지는 타원).
static func shadow_blob(node: Node2D,center: Vector2,extent: Vector2,alpha: float=0.35) -> void:
 node.draw_set_transform(center,0,Vector2(1,0.42))
 for i in range(4):
  var k:=1.0-float(i)*0.16
  node.draw_circle(Vector2.ZERO,extent.x*0.5*k,Color(0.02,0.025,0.045,alpha*(0.30-float(i)*0.05)))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 텍스처 바닥 한 장(타일 반복). 1 draw call로 GPU가 반복한다.
static func tiled(node: Node2D,texture: Texture2D,rect: Rect2,tint: Color=Color.WHITE) -> void:
 if texture==null:
  node.draw_rect(rect,tint);return
 node.draw_texture_rect(texture,rect,true,tint)
## 어두운 외곽선이 있는 사각 몸통 + 윗면 하이라이트.
static func slab(node: Node2D,rect: Rect2,fill: Color,top: Color,outline: Color=INK,width: float=2.0,top_h: float=5.0) -> void:
 node.draw_rect(rect.grow(width),outline)
 node.draw_rect(rect,fill)
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,minf(top_h,rect.size.y))),top)
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y)),Color(0,0,0,0.18),false,1.0)
## 둥근 사물 몸통(화분·기둥·쓰레기통). 그림자→본체→테두리→하이라이트.
static func blob(node: Node2D,center: Vector2,radius: Vector2,fill: Color,rim: Color=INK,highlight: Color=Color(1,1,1,0.22)) -> void:
 node.draw_set_transform(center,0,Vector2(1,radius.y/maxf(1.0,radius.x)))
 node.draw_circle(Vector2.ZERO,radius.x+1.6,rim)
 node.draw_circle(Vector2.ZERO,radius.x,fill)
 node.draw_circle(Vector2(-radius.x*0.22,-radius.y*0.24),radius.x*0.52,highlight)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 바닥에 떨어지는 빛 웅덩이(천장 조명·가로등·네온). 여러 겹의 낮은 알파 원.
static func light_pool(node: Node2D,center: Vector2,radius: float,color: Color) -> void:
 for i in range(5):
  var k:=1.0-float(i)*0.19
  node.draw_circle(center,radius*k,Color(color.r,color.g,color.b,color.a*(0.34-float(i)*0.05)))
## 네온관: 어두운 받침 위에 밝은 심지 + 번지는 빛.
static func neon(node: Node2D,a: Vector2,b: Vector2,color: Color,width: float=4.0,glow: bool=true) -> void:
 if glow:
  for i in range(3):
   node.draw_line(a,b,Color(color.r,color.g,color.b,0.10+float(i)*0.05),width+8.0-float(i)*2.5,true)
 node.draw_line(a,b,Color(INK.r,INK.g,INK.b,0.85),width+2.0,true)
 node.draw_line(a,b,color,width,true)
 node.draw_line(a,b,Color(1,1,1,0.45),maxf(1.0,width*0.35),true)
## 매달린 간판/벽면 표지. 금속 후광 + 또렷한 글자.
static func sign(node: Node2D,rect: Rect2,text: String,fg: Color,bg: Color,border: Color,font_size: int=18,font: Font=FONT) -> void:
 node.draw_rect(Rect2(rect.position+Vector2(3,4),rect.size),Color(0,0,0,0.45))
 node.draw_rect(rect.grow(1.5),INK)
 node.draw_rect(rect,bg)
 node.draw_rect(rect,border,false,2.0)
 node.draw_rect(Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,2)),Color(1,1,1,0.20))
 var baseline:=rect.position+Vector2(8,rect.size.y*0.5+float(font_size)*0.36)
 node.draw_string(font,baseline,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,fg)
## 바닥에 칠한 안내 화살표.
static func floor_arrow(node: Node2D,at: Vector2,angle: float,color: Color,scale_value: float=1.0) -> void:
 node.draw_set_transform(at,angle,Vector2(scale_value,scale_value))
 var pts:=PackedVector2Array([Vector2(-26,-12),Vector2(6,-12),Vector2(6,-24),Vector2(30,0),Vector2(6,24),Vector2(6,12),Vector2(-26,12)])
 node.draw_colored_polygon(pts,Color(color.r,color.g,color.b,0.20))
 node.draw_polyline(pts,Color(color.r,color.g,color.b,0.55),2.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 벤치(위에서 본 등받이 + 좌판 + 다리 그림자).
static func bench(node: Node2D,at: Vector2,width: float=120.0,wood: Color=Color("4a5d78")) -> void:
 shadow_blob(node,at+Vector2(0,6),Vector2(width*1.15,34),0.42)
 var back:=Rect2(at-Vector2(width*0.5,26),Vector2(width,10))
 var seat:=Rect2(at-Vector2(width*0.5,14),Vector2(width,28))
 node.draw_rect(back.grow(1.5),INK)
 node.draw_rect(back,wood.darkened(0.25))
 node.draw_rect(seat.grow(1.5),INK)
 node.draw_rect(seat,wood)
 node.draw_rect(Rect2(seat.position+Vector2(4,3),Vector2(seat.size.x-8,4)),Color(minf(1.0,wood.r+0.10),minf(1.0,wood.g+0.10),minf(1.0,wood.b+0.10),.45))
 for i in range(1,3):
  var x:=seat.position.x+seat.size.x*float(i)/3.0
  node.draw_line(Vector2(x,seat.position.y+2),Vector2(x,seat.end.y-2),wood.darkened(0.35),1.4)
## 사각 화단(돌 테두리 + 잎 + 작은 꽃) — 지하철 대합실·거리 공통.
static func planter_box(node: Node2D,rect: Rect2,leaf: Color=Color(0.22,0.48,0.32)) -> void:
 shadow_blob(node,rect.get_center()+Vector2(0,6),Vector2(rect.size.x*1.1,rect.size.y*.7),0.42)
 node.draw_rect(rect.grow(2.0),INK)
 node.draw_rect(rect,Color(0.34,0.31,0.30))
 node.draw_rect(rect.grow(-4.0),Color(0.16,0.12,0.10))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,5)),Color(0.56,0.52,0.50))
 for i in range(int(rect.size.x*rect.size.y/900.0)+3):
  var px:=rect.position.x+8.0+fmod(float(i)*37.0,rect.size.x-16.0)
  var py:=rect.position.y+10.0+fmod(float(i)*23.0,maxf(1.0,rect.size.y-18.0))
  node.draw_circle(Vector2(px,py),7.0,INK)
  node.draw_circle(Vector2(px,py),6.0,Color(leaf.r+float(i%3)*0.03,leaf.g+float(i%3)*0.04,leaf.b+float(i%2)*0.03))
  node.draw_circle(Vector2(px-2,py-2),2.4,Color(leaf.r+0.18,leaf.g+0.22,leaf.b+0.10,0.9))
  if i%3==0:node.draw_circle(Vector2(px+3,py+2),2.0,Color(0.95,0.72,0.82,.85))
## 원통형 광고 키오스크(대합실·거리). 은은한 광고 화면이 빛난다.
static func ad_kiosk(node: Node2D,at: Vector2,accent: Color=Color("ffb0d0"),height: float=58.0) -> void:
 shadow_blob(node,at+Vector2(0,8),Vector2(46,26),0.45)
 var body:=Rect2(at-Vector2(16,height*.5),Vector2(32,height))
 node.draw_rect(body.grow(1.6),INK)
 node.draw_rect(body,Color(.16,.18,.24))
 node.draw_rect(Rect2(body.position+Vector2(4,6),Vector2(body.size.x-8,body.size.y-14)),Color(.05,.06,.10))
 node.draw_rect(Rect2(body.position+Vector2(6,9),Vector2(body.size.x-12,body.size.y-22)),Color(accent.r,accent.g,accent.b,.55))
 node.draw_rect(Rect2(body.position+Vector2(6,9),Vector2(body.size.x-12,5)),Color(1,1,1,.35))
 node.draw_rect(Rect2(body.position,Vector2(body.size.x,4)),Color(.42,.46,.56))
 node.draw_rect(Rect2(Vector2(body.position.x,body.end.y-5),Vector2(body.size.x,5)),Color(.10,.11,.16))
 for i in range(3):
  node.draw_rect(Rect2(body.position+Vector2(8,20+float(i)*12),Vector2(body.size.x-16,3)),Color(1,1,1,.18))
## 자판기 3대 묶음(대합실) — 실제 둔갑 사물과 같은 톤.
static func vending_row(node: Node2D,at: Vector2,count: int=3) -> void:
 for i in range(count):
  var spot:=at+Vector2(float(i)*40.0,0)
  shadow_blob(node,spot+Vector2(0,6),Vector2(40,20),0.45)
  var body:=Rect2(spot-Vector2(17,46),Vector2(34,52))
  node.draw_rect(body.grow(1.6),INK)
  node.draw_rect(body,Color(.88,.90,.94))
  node.draw_rect(Rect2(body.position+Vector2(3,3),Vector2(body.size.x-6,20)),Color(.08,.10,.16))
  for k in range(3):
   node.draw_rect(Rect2(body.position+Vector2(5+float(k)*9,6),Vector2(7,5)),Color(.95,.55,.30) if k%2==0 else Color(.35,.75,.95))
  node.draw_rect(Rect2(body.position+Vector2(4,28),Vector2(body.size.x-8,14)),Color(.70,.74,.82))
  node.draw_rect(Rect2(body.position+Vector2(4,28),Vector2(body.size.x-8,3)),Color(.92,.94,.97))
  node.draw_circle(body.position+Vector2(body.size.x-8,39),2.0,Color(.25,.85,.65))
## 사물함(관리실·샤워장).
static func locker_bank(node: Node2D,rect: Rect2,color: Color=Color(.30,.36,.46)) -> void:
 shadow_blob(node,rect.get_center()+Vector2(0,5),Vector2(rect.size.x*1.05,rect.size.y*.6),0.4)
 node.draw_rect(rect.grow(2),INK)
 node.draw_rect(rect,color)
 var cols:=maxi(1,int(rect.size.x/18.0))
 for i in range(cols):
  var x:=rect.position.x+float(i)*rect.size.x/float(cols)
  node.draw_rect(Rect2(Vector2(x+1,rect.position.y+2),Vector2(rect.size.x/float(cols)-2,rect.size.y-4)),color.darkened(0.12))
  node.draw_rect(Rect2(Vector2(x+4,rect.position.y+rect.size.y*.45),Vector2(4,3)),Color(.85,.88,.92,.9))
## 화분(둥근 잎 + 화분).
static func planter(node: Node2D,at: Vector2,size_value: float=1.0) -> void:
 shadow_blob(node,at+Vector2(2,6),Vector2(54,22)*size_value,0.4)
 var pot:=Rect2(at-Vector2(15,4)*size_value,Vector2(30,24)*size_value)
 node.draw_rect(pot.grow(1.4),INK)
 node.draw_rect(pot,Color("5c4636"))
 node.draw_rect(Rect2(pot.position,Vector2(pot.size.x,4*size_value)),Color("7a5c46"))
 for i in range(3):
  var off:=Vector2(-8.0+float(i)*8.0,(-22.0-float(i%2)*8.0))*size_value
  node.draw_set_transform(at+off+Vector2(0,(1.0-float(i))*2.0),float(i)*0.7,Vector2(1,0.86))
  node.draw_circle(Vector2.ZERO,13.0*size_value,INK)
  node.draw_circle(Vector2.ZERO,11.5*size_value,Color(0.20+float(i)*0.03,0.46+float(i)*0.03,0.30+float(i)*0.02))
  node.draw_circle(Vector2(-4,(-3))*size_value,4.0*size_value,Color(0.36,0.66,0.44,0.9))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 쓰레기통.
static func trash(node: Node2D,at: Vector2,color: Color=Color("3b4658")) -> void:
 shadow_blob(node,at+Vector2(2,5),Vector2(28,14),0.4)
 var body:=Rect2(at-Vector2(11,16),Vector2(22,26))
 node.draw_rect(body.grow(1.4),INK)
 node.draw_rect(body,color)
 node.draw_rect(Rect2(body.position-Vector2(1,4),Vector2(body.size.x+2,6)),color.lightened(0.28))
 node.draw_rect(Rect2(body.position+Vector2(3,10),Vector2(6,9)),Color(0.02,0.03,0.05,0.55))
## 기둥(지하철 대합실). 네온 띠와 바닥 반사를 함께.
static func pillar(node: Node2D,at: Vector2,w: float=54.0,h: float=54.0,accent: Color=Color("ffd98a")) -> void:
 shadow_blob(node,at+Vector2(4,10),Vector2(w*1.5,h*0.9),0.45)
 var rect:=Rect2(at-Vector2(w*0.5,h*0.5),Vector2(w,h))
 node.draw_rect(rect.grow(2),INK)
 node.draw_rect(rect,Color("27324a"))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,8)),Color("465a78"))
 node.draw_rect(rect.grow(-6),Color("1c2739"))
 node.draw_rect(Rect2(rect.position.x+6,rect.position.y+14,rect.size.x-12,4),Color(accent.r,accent.g,accent.b,0.9))
 node.draw_rect(Rect2(rect.position.x+6,rect.position.y+20,rect.size.x-12,2),Color(accent.r,accent.g,accent.b,0.35))
## 가로등(밤거리): 그림자 + 기둥 + 갓 + 바닥 빛.
static func street_lamp(node: Node2D,at: Vector2,height: float=64.0,warm: Color=Color("ffc878")) -> void:
 shadow_blob(node,at+Vector2(0,6),Vector2(30,16),0.42)
 node.draw_line(at+Vector2(0,2),at+Vector2(0,-height),Color(INK.r,INK.g,INK.b,0.95),5.0)
 node.draw_line(at+Vector2(0,2),at+Vector2(0,-height),Color("49536a"),3.0)
 var head:=Rect2(at+Vector2(-11,-height-10),Vector2(22,12))
 node.draw_rect(head.grow(1.2),INK)
 node.draw_rect(head,warm.darkened(0.1))
 node.draw_circle(at+Vector2(0,-height-4),13.0,Color(warm.r,warm.g,warm.b,0.18))
 node.draw_circle(at+Vector2(0,-height-4),5.5,Color(1,0.96,0.82,0.95))
 light_pool(node,at+Vector2(0,10),height*0.9,Color(warm.r,warm.g,warm.b,0.20))
## 계단(출구·지하상가): 트레드 줄무늬 + 난간 + 위쪽 어둠.
static func stairs(node: Node2D,rect: Rect2,vertical: bool,accent: Color=Color("8fe3b0")) -> void:
 node.draw_rect(rect.grow(2),INK)
 node.draw_rect(rect,Color("2b3346"))
 var count:=6
 for i in range(count):
  if vertical:
   var y:=rect.position.y+rect.size.y*float(i)/float(count)
   node.draw_rect(Rect2(rect.position.x+2,y+1,rect.size.x-4,4),Color(0.55+float(i)*0.03,0.60+float(i)*0.03,0.70+float(i)*0.03,0.55))
  else:
   var x:=rect.position.x+rect.size.x*float(i)/float(count)
   node.draw_rect(Rect2(x+1,rect.position.y+2,4,rect.size.y-4),Color(0.55+float(i)*0.03,0.60+float(i)*0.03,0.70+float(i)*0.03,0.55))
 node.draw_rect(rect,Color(accent.r,accent.g,accent.b,0.35),false,2.0)
## 창문/쇼윈도 한 줄: 어두운 틀 + 따뜻한 불빛 + 유리 반사.
static func window_row(node: Node2D,rect: Rect2,warm: Color,lit: bool=true,step: float=40.0) -> void:
 node.draw_rect(rect,Color(0.03,0.04,0.07,0.95))
 var x:=rect.position.x+4.0
 while x<rect.end.x-24.0:
  var pane:=Rect2(x,rect.position.y+3,26,rect.size.y-6)
  node.draw_rect(pane,Color(0.02,0.03,0.05,0.98))
  node.draw_rect(pane.grow(-2),Color(warm.r,warm.g,warm.b,0.85 if lit else 0.22))
  node.draw_rect(Rect2(pane.position+Vector2(2,2),Vector2(pane.size.x-4,3)),Color(1,1,1,0.28))
  x+=step
## 차양(줄무늬 + 물결 밑단 + 그림자).
static func awning(node: Node2D,rect: Rect2,color: Color,shade_alpha: float=0.35) -> void:
 var stripes:=maxi(2,int(rect.size.x/26.0))
 for i in range(stripes):
  var x:=rect.position.x+rect.size.x*float(i)/float(stripes)
  var w:=rect.size.x/float(stripes)
  var tone: Color=color if i%2==0 else Color(0.96,0.95,0.93)
  node.draw_rect(Rect2(x,rect.position.y,w,rect.size.y),tone)
 node.draw_rect(rect,Color(INK.r,INK.g,INK.b,0.85),false,1.6)
 for i in range(stripes):
  var x2:=rect.position.x+rect.size.x*float(i)/float(stripes)
  node.draw_set_transform(Vector2(x2+rect.size.x/float(stripes)*0.5,rect.end.y),0,Vector2(1,0.55))
  node.draw_circle(Vector2.ZERO,rect.size.x/float(stripes)*0.5,color if i%2==0 else Color(0.96,0.95,0.93))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_rect(Rect2(rect.position.x,rect.end.y,rect.size.x,7),Color(0.02,0.03,0.05,shade_alpha))
## 벽면 포스터/안내판.
static func poster(node: Node2D,rect: Rect2,accent: Color,lines: int=3) -> void:
 node.draw_rect(Rect2(rect.position+Vector2(3,3),rect.size),Color(0,0,0,0.45))
 node.draw_rect(rect.grow(1.2),INK)
 node.draw_rect(rect,Color(0.92,0.90,0.86))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y*0.34)),accent.darkened(0.15))
 for i in range(lines):
  var y:=rect.position.y+rect.size.y*(0.46+float(i)*0.16)
  node.draw_rect(Rect2(rect.position.x+5,y,rect.size.x-10,2.4),Color(0.18,0.20,0.26,0.55))
## 환풍구/그릴.
static func vent(node: Node2D,rect: Rect2,color: Color=Color("2a3448")) -> void:
 node.draw_rect(rect.grow(1.2),INK)
 node.draw_rect(rect,color)
 var y:=rect.position.y+3.0
 while y<rect.end.y-2.0:
  node.draw_line(Vector2(rect.position.x+3,y),Vector2(rect.end.x-3,y),Color(0.02,0.03,0.05,0.6),1.4)
  y+=4.0
## 맨홀/배수구.
static func manhole(node: Node2D,at: Vector2,radius: float=16.0,moss: Color=Color("3b4a44")) -> void:
 node.draw_set_transform(at,0,Vector2(1,0.62))
 node.draw_circle(Vector2.ZERO,radius+2.0,Color(0.03,0.04,0.06,0.75))
 node.draw_circle(Vector2.ZERO,radius,Color(0.24,0.26,0.30))
 node.draw_circle(Vector2.ZERO,radius-3.0,Color(0.17,0.19,0.23))
 for i in range(4):
  var y:=float(i)*6.0-radius*0.55
  node.draw_line(Vector2(-radius*0.6,y),Vector2(radius*0.6,y),Color(0.09,0.10,0.13,0.9),1.6)
 node.draw_circle(Vector2(radius*0.35,-radius*0.3),2.2,moss)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 물웅덩이(네온 반사).
static func puddle(node: Node2D,at: Vector2,rx: float,ry: float,reflect: Color) -> void:
 node.draw_set_transform(at,0,Vector2(1,ry/rx))
 node.draw_circle(Vector2.ZERO,rx,Color(0.03,0.05,0.09,0.55))
 node.draw_circle(Vector2.ZERO,rx*0.86,Color(0.05,0.08,0.14,0.55))
 node.draw_arc(Vector2(-rx*0.2,0),rx*0.55,PI*0.15,PI*0.85,14,Color(reflect.r,reflect.g,reflect.b,0.35),2.4,true)
 node.draw_arc(Vector2(rx*0.25,rx*0.1),rx*0.30,PI*1.1,PI*1.8,10,Color(reflect.r,reflect.g,reflect.b,0.22),1.8,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 바닥 틈/금.
static func crack(node: Node2D,at: Vector2,length: float,angle: float=0.3) -> void:
 var dir:=Vector2.from_angle(angle)
 var p:=at
 var step:=length/4.0
 node.draw_line(p,p+dir*step,Color(0.06,0.07,0.10,0.55),1.6,true)
 p+=dir*step
 p+=Vector2(-dir.y,dir.x)*3.0
 node.draw_line(p-dir*step,p+dir*step,Color(0.06,0.07,0.10,0.45),1.4,true)
 p+=dir*step
 node.draw_line(p-dir*step,p+dir*step*0.8+Vector2(2,2),Color(0.06,0.07,0.10,0.40),1.2,true)
## 모래 위 잔물결.
static func sand_ripple(node: Node2D,rect: Rect2,tint: Color) -> void:
 var y:=rect.position.y+10.0
 var row:=0
 while y<rect.end.y:
  var x:=rect.position.x+10.0+float(row%2)*16.0
  while x<rect.end.x-30.0:
   node.draw_arc(Vector2(x,y),13.0,PI*0.18,PI*0.82,8,Color(tint.r,tint.g,tint.b,0.09),1.4,true)
   x+=58.0
  y+=30.0
  row+=1
## 파도 띠(해운대): 시간에 따라 흐르는 거품선. 물 레이어에서 매 프레임 그린다.
static func wave_band(node: Node2D,rect: Rect2,time: float,index: int,color: Color) -> void:
 var offset:=fmod(time*18.0+float(index)*13.0,26.0)
 var y:=rect.position.y+offset
 while y<rect.end.y:
  var amp:=2.4+float(index%2)*1.4
  var pts:=PackedVector2Array()
  var x:=rect.position.x+4.0
  while x<rect.end.x-4.0:
   pts.append(Vector2(x,y+sin(x*0.035+time*1.6+float(index))*amp))
   x+=26.0
  node.draw_polyline(pts,Color(color.r,color.g,color.b,0.30),2.2,true)
  y+=26.0
