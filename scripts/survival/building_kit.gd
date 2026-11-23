extends RefCounted
## 2.0.39 2D 카툰 건물 키트.
##
## 네 맵의 건물·담장·차양·바닥을 '상용 2D 카툰' 규칙 하나로 그린다.
##  - 지붕: 512px 타일 아틀라스(v39)를 지붕 크기에 맞춰 반복 + 용마루 + 처마 끝 + 접지 그림자
##  - 외벽: 벽 텍스처 + 아래로 갈수록 어두워지는 AO + 굽도리 + 처마 밑 그늘
##  - 상점: 유리창(따뜻한 실내광·진열 실루엣·반사) + 차양(물결 밑단) + 간판
##  - 모든 몸통은 남색 잉크 외곽선(2px)으로 캐릭터·사물과 같은 선 굵기를 쓴다.
## 좌표는 각 맵 layout의 사각형을 그대로 받으므로 그림과 충돌이 어긋나지 않는다.
const Q=preload("res://scripts/survival/quality.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const INK=Color("0b1020")
const INK_SOFT=Color(0.03,0.04,0.07,0.55)
const CREAM=Color(0.96,0.93,0.86)
const DIR="res://assets/woo/v39/tiles/"
const TEX={
 "roof_giwa":preload(DIR+"roof_giwa.png"),
 "roof_slate":preload(DIR+"roof_slate.png"),
 "roof_metal":preload(DIR+"roof_metal.png"),
 "roof_shingle":preload(DIR+"roof_shingle.png"),
 "wall_brick":preload(DIR+"wall_brick.png"),
 "wall_plaster":preload(DIR+"wall_plaster.png"),
 "wall_concrete":preload(DIR+"wall_concrete.png"),
 "wall_wood":preload(DIR+"wall_wood.png"),
 "floor_paving":preload(DIR+"floor_paving.png"),
 "floor_asphalt":preload(DIR+"floor_asphalt.png"),
 "floor_marble":preload(DIR+"floor_marble.png"),
 "floor_boardwalk":preload(DIR+"floor_boardwalk.png")}
## 지붕 스타일별 타일 크기(월드 px) — 너무 잘거나 굵어 보이지 않는 값.
const CELL={"roof_giwa":230.0,"roof_slate":240.0,"roof_metal":260.0,"roof_shingle":190.0,
 "wall_brick":175.0,"wall_plaster":235.0,"wall_concrete":280.0,"wall_wood":200.0,
 "floor_paving":260.0,"floor_asphalt":300.0,"floor_marble":300.0,"floor_boardwalk":230.0}
## 처마·용마루 색은 지붕 재질에서 파생한다(맵마다 같은 규칙).
const ROOF_TONE={
 "roof_giwa":Color("26304a"),"roof_slate":Color("2a3040"),
 "roof_metal":Color("39445a"),"roof_shingle":Color("3e2c24")}
static func tex(key: String) -> Texture2D:
 return TEX.get(key)
## 텍스처를 정해진 월드 크기로 잘라 반복한다(한 장을 늘려 쓰지 않는다).
static func tiled(node: Node2D,key: String,rect: Rect2,tint: Color=Color.WHITE) -> void:
 var texture: Texture2D=tex(key)
 if texture==null:
  node.draw_rect(rect,tint);return
 var size: Vector2=texture.get_size()
 var cell: float=float(CELL.get(key,220.0))
 var step:=Vector2(cell,cell*size.y/size.x)
 if rect.size.y<step.y:step.y=maxf(8.0,rect.size.y)
 else:step.y=maxf(8.0,fmod(rect.size.y,step.y) if fmod(rect.size.y,step.y)>8.0 else step.y)
 var y:=rect.position.y
 while y<rect.end.y-0.5:
  var h:=minf(step.y,rect.end.y-y)
  var x:=rect.position.x
  while x<rect.end.x-0.5:
   var w:=minf(step.x,rect.end.x-x)
   var src:=Rect2(Vector2.ZERO,Vector2(size.x*w/step.x,size.y*h/step.y))
   node.draw_texture_rect_region(texture,Rect2(x,y,w,h),src,tint)
   x+=step.x
  y+=step.y
## 바닥에 번지는 접지 그림자(남동쪽). 건물·사물이 떠 보이지 않게 한다.
static func contact(node: Node2D,rect: Rect2,spread: float=14.0,alpha: float=0.34) -> void:
 for i in range(4):
  var grow:=spread*float(i)/3.0
  var a:=alpha*(1.0-float(i)*0.22)
  node.draw_rect(Rect2(rect.position+Vector2(grow*0.35,rect.size.y*0.20+grow*0.55),
   Vector2(rect.size.x+grow*0.8,rect.size.y*0.80+grow*0.45)),Color(.01,.015,.03,a*0.55))
 node.draw_set_transform(Vector2(rect.get_center().x,rect.end.y+3.0),0,Vector2(1.0,.26))
 for i in range(3):
  node.draw_circle(Vector2.ZERO,rect.size.x*0.52-float(i)*7.0,Color(.01,.015,.03,alpha*0.30))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 지붕 위를 덮는 그늘·빛(위는 밝고 아래는 어둡다).
static func roof_relief(node: Node2D,roof: Rect2) -> void:
 var band:=maxf(6.0,roof.size.y*0.34)
 for i in range(4):
  var t:=float(i)/4.0
  node.draw_rect(Rect2(roof.position+Vector2(0,roof.size.y-band*(1.0-t)*0.9),
   Vector2(roof.size.x,band*(1.0-t)*0.9)),Color(.02,.03,.06,0.05))
 node.draw_rect(Rect2(roof.position,Vector2(roof.size.x,4.0)),Color(1,1,1,.07))
 node.draw_rect(roof.grow(-1.0),Color(.02,.03,.06,.16),false,2.0)
## 처마 끝(기와 마구리 줄)과 그 아래 그늘.
static func eave_trim(node: Node2D,roof: Rect2,tone: Color,rows: bool=true) -> void:
 var y:=roof.end.y
 # 처마 밑 어두운 띠(벽에 드리우는 그늘)
 node.draw_rect(Rect2(roof.position.x-2,y-2,roof.size.x+4,7.0),Color(.01,.015,.03,.55))
 node.draw_rect(Rect2(roof.position.x-2,y+4,roof.size.x+4,5.0),Color(.01,.015,.03,.28))
 node.draw_rect(Rect2(roof.position.x,y-4,roof.size.x,3.0),tone.lightened(0.18))
 # 마구리(둥근 기와 끝) 줄
 if rows:
  var x:=roof.position.x+6.0
  while x<roof.end.x-4.0:
   node.draw_circle(Vector2(x,y-3.0),2.6,Color(tone.r,tone.g,tone.b,1.0))
   node.draw_circle(Vector2(x,y-3.0),2.6,Color(.02,.02,.04,.85),false,1.0)
   node.draw_circle(Vector2(x-0.8,y-3.8),1.1,Color(1,1,1,.30))
   x+=9.0
## 용마루(지붕 북쪽 능선) + 취두 장식.
static func ridge(node: Node2D,roof: Rect2,tone: Color,ornaments: bool=true) -> void:
 var top:=roof.position.y
 node.draw_rect(Rect2(roof.position.x-3,top-1,roof.size.x+6,7.0),Color(.01,.015,.03,.85))
 node.draw_rect(Rect2(roof.position.x-2,top,roof.size.x+4,4.4),tone.lightened(0.28))
 node.draw_rect(Rect2(roof.position.x-2,top+4.4,roof.size.x+4,1.6),Color(.02,.02,.05,.75))
 var x:=roof.position.x+3.0
 while x<roof.end.x-2.0:
  node.draw_line(Vector2(x,top+1),Vector2(x,top+4.4),Color(.03,.04,.07,.55),1.0)
  x+=11.0
 if ornaments:
  for side in [-1.0,1.0]:
   var cx: float=roof.position.x+3.0 if side<0 else roof.end.x-3.0
   var pts:=PackedVector2Array([Vector2(cx,top+5),Vector2(cx+side*9.0,top-3.0),Vector2(cx+side*13.0,top+1.0),Vector2(cx+side*6.0,top+7)])
   node.draw_colored_polygon(pts,Color(.02,.02,.04,.95))
   node.draw_colored_polygon(PackedVector2Array([Vector2(cx,top+5),Vector2(cx+side*7.0,top-1.0),Vector2(cx,top+1.0)]),tone.lightened(0.4))
## 처마 모서리 들림(한옥). 지붕 아래 좌우 모서리에만 붙인다.
static func eave_flare(node: Node2D,roof: Rect2,tone: Color,size: float=13.0) -> void:
 for side in [-1.0,1.0]:
  var cx: float=roof.position.x if side<0 else roof.end.x
  var y:=roof.end.y
  var pts:=PackedVector2Array([Vector2(cx, y-6.0),Vector2(cx+side*size, y-2.0),Vector2(cx+side*(size+3.0), y+5.0),Vector2(cx, y+2.0)])
  node.draw_colored_polygon(pts,Color(.02,.025,.045,.94))
  node.draw_line(Vector2(cx+side*2.0,y-4.0),Vector2(cx+side*size,y-1.0),tone.lightened(0.42),2.0,true)
  node.draw_line(Vector2(cx+side*size,y-1.0),Vector2(cx+side*(size+2.0),y+4.0),Color(1,1,1,.14),1.4,true)
## 지붕 위 설비: 환풍구·물탱크·굴뚝·태양광. 도시형 지붕에만.
static func roof_units(node: Node2D,roof: Rect2,tone: Color,seed: int,kind: String="city") -> void:
 if Q.low:return
 var w:=roof.size.x
 if w<150.0:return
 var base:=Vector2(roof.position.x+w*0.20,roof.position.y+roof.size.y*0.34)
 if kind=="market":
  # 굴뚝 하나 + 빨랫줄
  var chimney:=Rect2(base-Vector2(9,16),Vector2(18,20))
  node.draw_rect(Rect2(chimney.position+Vector2(3,4),chimney.size),Color(.02,.02,.04,.35))
  node.draw_rect(chimney.grow(1.2),INK)
  node.draw_rect(chimney,Color(.34,.24,.20))
  node.draw_rect(Rect2(chimney.position,Vector2(chimney.size.x,4)),Color(.52,.36,.28))
  for k in range(3):
   node.draw_circle(chimney.position+Vector2(-4.0+float(k)*4.0,-6.0-float(k)*7.0),4.0+float(k)*2.0,Color(.86,.88,.92,.07))
  return
 # 도시: 물탱크 + 환풍구 2 + 배기관
 var tank:=Rect2(Vector2(roof.position.x+w*0.62,roof.position.y+roof.size.y*0.22),Vector2(34,26))
 node.draw_rect(Rect2(tank.position+Vector2(4,5),tank.size),Color(.02,.02,.04,.35))
 node.draw_rect(tank.grow(1.4),INK)
 node.draw_rect(tank,Color(.30,.33,.40))
 node.draw_rect(Rect2(tank.position,Vector2(tank.size.x,6)),tone.lightened(0.35))
 for k in range(3):
  node.draw_line(Vector2(tank.position.x+5.0+float(k)*10.0,tank.position.y+8),Vector2(tank.position.x+5.0+float(k)*10.0,tank.end.y-4),Color(.16,.17,.22,.55),1.4)
 var vent:=Rect2(Vector2(roof.position.x+w*0.30,roof.position.y+roof.size.y*0.58),Vector2(26,16))
 node.draw_rect(vent.grow(1.2),INK)
 node.draw_rect(vent,Color(.22,.24,.30))
 for k in range(3):
  node.draw_rect(Rect2(vent.position+Vector2(3,3.0+float(k)*4.0),Vector2(vent.size.x-6,2.0)),Color(.52,.56,.66,.7))
 if w>260.0:
  var ac:=Rect2(Vector2(roof.position.x+w*0.72,roof.position.y+roof.size.y*0.56),Vector2(30,22))
  node.draw_rect(ac.grow(1.2),INK)
  node.draw_rect(ac,Color(.63,.66,.72))
  node.draw_arc(ac.get_center(),8.0,0,TAU,18,Color(.32,.34,.40),2.0,true)
  for k in range(3):
   node.draw_line(Vector2(ac.position.x+4,ac.position.y+5.0+float(k)*5.0),Vector2(ac.end.x-4,ac.position.y+5.0+float(k)*5.0),Color(.40,.42,.48,.8),1.2)
## 지붕 전체(그림자→타일→음영→용마루→처마).
static func roof(node: Node2D,footprint: Rect2,style: String,seed: int,face_h: float,eave: float=10.0) -> Rect2:
 var tone: Color=ROOF_TONE.get(style,Color("2b3448"))
 var drawn:=Rect2(footprint.position+Vector2(-eave,-eave),
  Vector2(footprint.size.x+eave*2.0,maxf(28.0,footprint.size.y-face_h+eave*0.55)))
 # 처마가 만드는 바닥 그림자(남쪽).
 for i in range(3):
  var a:=0.16-float(i)*0.04
  node.draw_rect(Rect2(drawn.position.x+4.0+i*3.0,drawn.end.y+2.0+i*3.0,drawn.size.x,6.0+i*3.0),Color(.01,.015,.03,a))
 # 지붕 몸통
 node.draw_rect(drawn.grow(2.2),Color(.015,.02,.035,.95))
 tiled(node,style,drawn,Color(1,1,1,1))
 roof_relief(node,drawn)
 var giwa:=style=="roof_giwa"
 ridge(node,drawn,tone,giwa)
 if giwa:eave_flare(node,drawn,tone,12.0)
 else:
  # 슬레이트·금속: 처마 물받이 홈
  node.draw_rect(Rect2(drawn.position.x,drawn.end.y-3.0,drawn.size.x,3.0),Color(.02,.02,.04,.55))
 eave_trim(node,drawn,tone,giwa)
 roof_units(node,drawn,tone,seed,"market" if style=="roof_shingle" else "city")
 return drawn
## 상점 유리창 한 줄: 검은 창틀 + 따뜻한 실내광 + 살 + 반사.
static func glass_row(node: Node2D,glass: Rect2,accent: Color,pane_w: float=38.0) -> void:
 node.draw_rect(glass.grow(2.0),Color(.02,.025,.04,.96))
 node.draw_rect(glass,Color(.10,.09,.12,.98))
 var x:=glass.position.x
 var index:=0
 while x<glass.end.x-4.0:
  var pane:=Rect2(x,glass.position.y+2.0,minf(pane_w,glass.end.x-x)-3.0,glass.size.y-4.0)
  if pane.size.x>3.0:
   # 실내광: 위는 밝고 아래로 어두운 따뜻한 그라데이션
   node.draw_rect(pane,Color(accent.r*0.42,accent.g*0.34,accent.b*0.24,1.0))
   for k in range(3):
    var t:=float(k)/3.0
    node.draw_rect(Rect2(pane.position+Vector2(0,pane.size.y*(0.55+t*0.15)),Vector2(pane.size.x,pane.size.y*0.16)),Color(accent.r,accent.g,accent.b,0.20-float(k)*0.05))
   # 진열 실루엣
   if index%2==0:
    node.draw_rect(Rect2(pane.position+Vector2(pane.size.x*0.22,pane.size.y*0.52),Vector2(pane.size.x*0.24,pane.size.y*0.40)),Color(.06,.05,.07,.60))
   else:
    node.draw_rect(Rect2(pane.position+Vector2(pane.size.x*0.30,pane.size.y*0.62),Vector2(pane.size.x*0.42,pane.size.y*0.30)),Color(.06,.05,.07,.45))
   # 유리 반사(대각 하이라이트)
   node.draw_line(pane.position+Vector2(3,pane.size.y*0.72),pane.position+Vector2(pane.size.x*0.55,3),Color(1,1,1,.13),2.0,true)
   node.draw_rect(pane,Color(.02,.02,.05,.55),false,1.2)
  x+=pane_w
  index+=1
 ## 처마 밑 그늘(유리 위쪽)
 node.draw_rect(Rect2(glass.position.x-2,glass.position.y-3,glass.size.x+4,4),Color(.01,.015,.03,.55))
## 차양: 줄무늬 천 + 물결 밑단 + 아래 그늘. 상점 파사드 위에 붙는다.
static func awning(node: Node2D,rect: Rect2,color: Color,stripe_ratio: float=0.5) -> void:
 var stripes:=maxi(3,int(rect.size.x/22.0))
 var sw:=rect.size.x/float(stripes)
 for i in range(stripes):
  var x:=rect.position.x+sw*float(i)
  var c: Color=color if i%2==0 else Color(.95,.93,.87)
  node.draw_rect(Rect2(x,rect.position.y,sw+0.4,rect.size.y),c)
  # 천의 결(위에서 아래로)
  node.draw_line(Vector2(x+sw*0.5,rect.position.y+1),Vector2(x+sw*0.5,rect.end.y-1),Color(.02,.02,.04,.12),1.0)
 # 물결 밑단
 for i in range(stripes):
  var cx:=rect.position.x+sw*(float(i)+0.5)
  node.draw_set_transform(Vector2(cx,rect.end.y-1.0),0,Vector2(1.0,0.55))
  node.draw_circle(Vector2.ZERO,sw*0.5+0.4,color if i%2==0 else Color(.95,.93,.87))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_rect(rect.grow(1.3),Color(.02,.02,.04,.9),false,1.6)
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,2.6)),Color(1,1,1,.20))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,1.4)),Color(.02,.02,.04,.5))
## 간판: 어두운 판 + 색 테두리 + 글자 + 판 그림자.
static func sign_board(node: Node2D,rect: Rect2,text: String,border: Color,font_size: int=17,text_color: Color=Color(1,.97,.9),font: Font=FONT) -> void:
 node.draw_rect(Rect2(rect.position+Vector2(2,3),rect.size),Color(0,0,0,.45))
 node.draw_rect(rect.grow(1.6),INK)
 node.draw_rect(rect,Color(.05,.045,.07,.97))
 node.draw_rect(rect,Color(border.r,border.g,border.b,.88),false,1.8)
 node.draw_rect(Rect2(rect.position+Vector2(2,2),Vector2(rect.size.x-4,1.6)),Color(1,1,1,.18))
 var baseline:=rect.position+Vector2(7,rect.size.y*0.5+float(font_size)*0.36)
 node.draw_string(font,baseline,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,text_color)
## 바닥에 드리우는 따뜻한 실내광.
static func light_spill(node: Node2D,center: Vector2,radius: float,color: Color) -> void:
 for i in range(4):
  var k:=1.0-float(i)*0.2
  node.draw_set_transform(center,0,Vector2(1.0,0.42))
  node.draw_circle(Vector2.ZERO,radius*k,Color(color.r,color.g,color.b,color.a*(0.30-float(i)*0.06)))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 상점 앞면(외벽 + 간판 띠 + 차양 + 유리 + 문). 벽 종류는 맵이 고른다.
static func facade(node: Node2D,footprint: Rect2,face_h: float,wall: String,accent: Color,label: String,kind: String,seed: int=0) -> void:
 var face:=Rect2(Vector2(footprint.position.x,footprint.end.y-face_h),Vector2(footprint.size.x,face_h))
 # 1) 벽체: 텍스처 + 아래로 갈수록 어두운 AO + 굽도리
 node.draw_rect(face.grow(1.6),INK)
 tiled(node,wall,face,Color(1,1,1,1))
 var fourth:=face.size.y*0.30
 for i in range(3):
  var t:=float(i)/3.0
  node.draw_rect(Rect2(face.position.x,face.end.y-fourth*(0.55+t*0.45),face.size.x,fourth*(0.55+t*0.45)),Color(.02,.02,.05,0.14))
 node.draw_rect(Rect2(face.position,Vector2(face.size.x,3.0)),Color(1,1,1,.10))
 node.draw_rect(Rect2(face.position.x,face.end.y-8.0,face.size.x,8.0),Color(.09,.08,.10,.90))
 node.draw_rect(Rect2(face.position.x,face.end.y-8.0,face.size.x,1.8),Color(.44,.42,.44,.55))
 var sign_h:=minf(21.0,face.size.y*0.40)
 var awning_h:=minf(13.0,face.size.y*0.24)
 var glass_top:=face.position.y+sign_h+awning_h+3.0
 var glass_h:=maxf(8.0,face.end.y-9.0-glass_top)
 # 2) 간판 띠(벽 상단, 처마 바로 아래)
 if label!="":
  var width:=minf(face.size.x-14.0,16.0+FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+14.0)
  sign_board(node,Rect2(Vector2(face.position.x+7.0,face.position.y+2.0),Vector2(width,sign_h-3.0)),label,accent,15)
  # 간판 옆 작은 네온 점·전구
  var lx:=face.position.x+12.0+width
  while lx<face.end.x-10.0:
   node.draw_circle(Vector2(lx,face.position.y+sign_h*0.5),1.7,Color(accent.r,accent.g,accent.b,.55))
   lx+=16.0
 # 3) 창·문
 if kind=="shop" or kind=="market":
  var glass:=Rect2(Vector2(face.position.x+9.0,glass_top),Vector2(face.size.x-18.0,glass_h))
  glass_row(node,glass,accent)
  var door:=Rect2(Vector2(face.end.x-38.0,glass_top-2.0),Vector2(24.0,glass_h+4.0))
  node.draw_rect(door.grow(1.4),Color(.02,.02,.04,.96))
  node.draw_rect(door,Color(.28,.22,.19))
  node.draw_rect(door.grow(-2.0),Color(accent.r*0.52,accent.g*0.44,accent.b*0.30,.95))
  node.draw_circle(Vector2(door.end.x-5.0,door.get_center().y),1.6,Color(1,.88,.60,.95))
  # 4) 차양(간판과 유리 사이)
  awning(node,Rect2(face.position.x+2.0,face.position.y+sign_h,face.size.x-4.0,awning_h),accent)
 elif kind=="house":
  var left:=Rect2(Vector2(face.position.x+10.0,glass_top),Vector2(34.0,glass_h))
  var right:=Rect2(Vector2(face.end.x-44.0,glass_top),Vector2(34.0,glass_h))
  for win in [left,right]:
   node.draw_rect(win.grow(1.4),Color(.02,.02,.04,.95))
   node.draw_rect(win,Color(accent.r*0.46,accent.g*0.38,accent.b*0.26))
   node.draw_rect(Rect2(win.position,Vector2(win.size.x,win.size.y*0.35)),Color(1,.92,.72,.20))
   for k in range(3):
    node.draw_line(Vector2(win.position.x+win.size.x*float(k)/3.0,win.position.y),Vector2(win.position.x+win.size.x*float(k)/3.0,win.end.y),Color(.20,.13,.08,.9),1.6)
   for k in range(2):
    node.draw_line(Vector2(win.position.x,win.position.y+win.size.y*float(k)/2.0),Vector2(win.end.x,win.position.y+win.size.y*float(k)/2.0),Color(.20,.13,.08,.9),1.6)
  var door_h:=Rect2(Vector2(face.get_center().x-13.0,glass_top-2.0),Vector2(26.0,glass_h+4.0))
  node.draw_rect(door_h.grow(1.4),Color(.02,.02,.04,.96))
  node.draw_rect(door_h,Color(.27,.18,.12))
  node.draw_rect(door_h,Color(.62,.44,.24,.55),false,1.4)
  node.draw_circle(Vector2(door_h.end.x-4.0,door_h.get_center().y),1.5,Color(1,.86,.56,.9))
  awning(node,Rect2(face.position.x+2.0,face.position.y+sign_h,face.size.x-4.0,awning_h),accent)
 else:
  # 설비 벽: 패널 이음 + 배관
  var x:=face.position.x+14.0
  while x<face.end.x-10.0:
   node.draw_line(Vector2(x,face.position.y+3),Vector2(x,face.end.y-9),Color(.02,.02,.05,.22),1.4)
   x+=46.0
  node.draw_rect(Rect2(face.position+Vector2(6,6),Vector2(face.size.x-12,1.6)),Color(1,1,1,.10))
 # 5) 처마 밑 그늘(지붕이 덮는 위쪽 어두운 띠)
 node.draw_rect(Rect2(face.position.x-2,face.position.y-2,face.size.x+4,3.0),Color(.01,.015,.03,.55))
## 벽 한 칸(담장·기둥). 지붕 없이 위쪽에 기와 띠만 얹는다.
static func wall_strip(node: Node2D,rect: Rect2,wall: String,tone: Color) -> void:
 var horizontal:=rect.size.x>=rect.size.y
 node.draw_rect(rect.grow(1.4),INK)
 tiled(node,wall,rect,Color(1,1,1,1))
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,3.0)),Color(1,1,1,.10))
 node.draw_rect(rect.grow(-0.5),Color(.02,.02,.05,.22),false,1.2)
 if horizontal:
  var top:=Rect2(Vector2(rect.position.x-4.0,rect.position.y-9.0),Vector2(rect.size.x+8.0,9.0))
  node.draw_rect(top.grow(1.2),Color(.02,.02,.04,.9))
  node.draw_rect(top,tone)
  var x:=top.position.x+4.0
  while x<top.end.x-2.0:
   node.draw_arc(Vector2(x,top.position.y+4.0),3.0,PI,TAU,10,Color(.04,.05,.09,.85),2.0,true)
   node.draw_arc(Vector2(x,top.position.y+4.0),2.2,PI,TAU,10,tone.lightened(0.32),1.2,true)
   x+=8.0
  node.draw_rect(Rect2(top.position,Vector2(top.size.x,1.8)),Color(1,1,1,.16))
  node.draw_rect(Rect2(rect.position.x-1,rect.position.y-1,rect.size.x+2,3.0),Color(.01,.015,.03,.55))
 else:
  var left:=Rect2(Vector2(rect.position.x-9.0,rect.position.y-4.0),Vector2(9.0,rect.size.y+8.0))
  node.draw_rect(left.grow(1.2),Color(.02,.02,.04,.9))
  node.draw_rect(left,tone)
  node.draw_rect(Rect2(left.position,Vector2(1.8,left.size.y)),Color(1,1,1,.16))
