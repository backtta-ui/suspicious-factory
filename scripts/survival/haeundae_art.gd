extends RefCounted
## 부산 해운대 정적 배경(2.0.35): 밤바다·백사장·전통시장 골목.
## 좌표는 haeundae_layout.gd를 그대로 쓴다(그림과 충돌이 어긋나지 않는다).
## 밝은 밤바다(청록 물빛·흰 파도) + 따뜻한 포장마차 등불 + 어두운 남색 건물.
const L=preload("res://scripts/survival/haeundae_layout.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const SAND=Color("c8ab7d")
const SAND_LIGHT=Color("dcc08f")
const DECK=Color("7a5a3c")
const CITY=Color("454b5c")
const CITY_LIGHT=Color("5a6172")
const DEEP=Color("0a2238")
const SEA=Color("123f5c")
const SEA_LIGHT=Color("2a7a9c")
const FOAM=Color(.86,.96,1,.85)
const WALL_FILL=Color("1b2436")
const WALL_TOP=Color("3a4a68")
const WALL_ROOF=Color("2a3320")
const NEON=Color("5fe6ff")
const WARM=Color("ffc06a")
const TEX={
 "sand":"res://assets/woo/haeundae/tiles/tile_sand.png",
 "boardwalk":"res://assets/woo/haeundae/tiles/tile_boardwalk.png",
 "promenade":"res://assets/woo/haeundae/tiles/tile_promenade.png",
 "seawall":"res://assets/woo/haeundae/tiles/wall_seawall.png"}
static var _tex: Dictionary={}
static func tex(key: String) -> Texture2D:
 if _tex.has(key):return _tex[key]
 var path: String=String(TEX.get(key,""))
 var texture: Texture2D=load(path) if path!="" and ResourceLoader.exists(path) else null
 _tex[key]=texture
 return texture
## 바다 한 칸: 깊은 물 → 물빛 → 물결 띠 → 거품 테두리.
static func water_rect(node: Node2D,rect: Rect2,alpha: float=1.0) -> void:
 node.draw_rect(rect,Color(DEEP.r,DEEP.g,DEEP.b,alpha))
 node.draw_rect(rect.grow(-6),Color(SEA.r,SEA.g,SEA.b,alpha))
 var y: float=rect.position.y+10.0
 var i: int=0
 while y<rect.end.y-6:
  var shade: Color=Color(SEA_LIGHT.r,SEA_LIGHT.g,SEA_LIGHT.b,.20 if i%2==0 else .10)
  node.draw_line(Vector2(rect.position.x+8,y),Vector2(rect.end.x-8,y),Color(shade.r,shade.g,shade.b,shade.a*alpha),2.0)
  y+=14.0
  i+=1
 node.draw_rect(rect,Color(FOAM.r,FOAM.g,FOAM.b,.28*alpha),false,3.0)
 node.draw_rect(rect.grow(-4),Color(FOAM.r,FOAM.g,FOAM.b,.12*alpha),false,1.5)
static func fill_texture(node: Node2D,key: String,rect: Rect2,tint: Color) -> void:
 var texture:=tex(key)
 if texture!=null:node.draw_texture_rect(texture,rect,true,tint)
 else:node.draw_rect(rect,tint)
## 바닥: 밤바다 → 백사장 → 도심 보도블록 → 산책로 데크 → 구역 색조·이름.
static func draw_base(node: Node2D) -> void:
 node.draw_rect(Rect2(Vector2(-300,-300),L.SIZE+Vector2(600,600)),Color("060a12"))
 # 바다를 가장 먼저 깔아 해안선이 지도 밖까지 이어지게 한다.
 node.draw_rect(Rect2(2300,1500,1100,1100),Color(DEEP.r,DEEP.g,DEEP.b,.65))
 node.draw_rect(Rect2(2300,1500,1100,1100),Color(SEA.r,SEA.g,SEA.b,.35))
 for rect in L.WATER:
  water_rect(node,rect)
 # 백사장(남쪽·남동쪽)
 var beach:=Rect2(150,1560,2300,860)
 fill_texture(node,"sand",beach,Color(1,.98,.92,.98))
 fill_texture(node,"sand",Rect2(2380,1560,860,420),Color(.86,.93,1,.6))
 node.draw_rect(beach,Color(SAND_LIGHT.r,SAND_LIGHT.g,SAND_LIGHT.b,.14))
 # 도심 바닥: 어두운 보도블록, 그 위에 밝은 큰길
 fill_texture(node,"promenade",Rect2(150,140,3090,1440),Color(.52,.56,.64,.95))
 node.draw_rect(Rect2(150,140,3090,1440),Color(CITY.r,CITY.g,CITY.b,.36))
 for path in L.PATHS:
  var w: float=float(path.w)
  var pts: Array=path.p
  var wood: bool=String(path.get("surface","stone"))=="wood"
  for i in range(pts.size()-1):
   var a: Vector2=pts[i]
   var b: Vector2=pts[i+1]
   var rect:=Rect2(Vector2(minf(a.x,b.x)-w*.5,minf(a.y,b.y)-w*.5),Vector2(absf(b.x-a.x)+w,absf(b.y-a.y)+w))
   if wood:fill_texture(node,"boardwalk",rect,Color(.98,.94,.88,.98))
   else:fill_texture(node,"promenade",rect,Color(.92,.96,1,.95))
   edge_curb(node,rect,wood)
 # 구역 색조: 넓은 사각 채우기 대신 부드러운 빛무리 + 얇은 경계만.
 for zone in L.ZONES:
  var rect2: Rect2=zone.rect
  var accent: Color=zone.accent
  var center:=rect2.get_center()
  var radius:=maxf(rect2.size.x,rect2.size.y)*.62
  for k in range(5):
   var t:=float(k)/5.0
   node.draw_circle(center,radius*(1.0-t),Color(accent.r,accent.g,accent.b,.035*(1.0-t)),true,-1.0,true)
  node.draw_rect(rect2.grow(-6),Color(accent.r,accent.g,accent.b,.14),false,2.0)
  zone_label(node,rect2,String(zone.name),accent)
 coast_line(node)
## 길 가장자리 연석.
static func edge_curb(node: Node2D,rect: Rect2,wood: bool) -> void:
 var c: Color=Color(.30,.24,.17,.55) if wood else Color(.72,.78,.86,.40)
 node.draw_rect(rect,c,false,2.0)
static func shade_edges(node: Node2D,rect: Rect2,strength: float) -> void:
 var band:=46.0
 var shade:=Color(.02,.04,.08,strength)
 node.draw_rect(Rect2(rect.position,Vector2(rect.size.x,band)),shade)
 node.draw_rect(Rect2(Vector2(rect.position.x,rect.end.y-band),Vector2(rect.size.x,band)),shade)
 node.draw_rect(Rect2(rect.position,Vector2(band,rect.size.y)),shade)
 node.draw_rect(Rect2(Vector2(rect.end.x-band,rect.position.y),Vector2(band,rect.size.y)),shade)
## 해안 거품: 백사장과 바다가 만나는 선을 물결 모양으로 긋는다.
static func coast_line(node: Node2D) -> void:
 var pts: Array=[Vector2(150,1560),Vector2(700,1562),Vector2(1300,1558),Vector2(1900,1564),
  Vector2(2380,1560),Vector2(2450,1610),Vector2(2446,1720),Vector2(2452,1820),
  Vector2(2448,1930),Vector2(2452,2030)]
 for i in range(pts.size()-1):
  var a: Vector2=pts[i]
  var b: Vector2=pts[i+1]
  var steps:=maxi(1,int(a.distance_to(b)/22.0))
  for k in range(steps):
   var p: Vector2=a.lerp(b,float(k)/steps)+Vector2(0,sin(float(k)*.9)*3.0)
   node.draw_circle(p,3.2,Color(FOAM.r,FOAM.g,FOAM.b,.35))
   if k%2==0:node.draw_circle(p+Vector2(-6,7),2.0,Color(FOAM.r,FOAM.g,FOAM.b,.18))
static func zone_label(node: Node2D,rect: Rect2,text: String,accent: Color) -> void:
 var at:=rect.position+Vector2(28,52)
 var width: float=22.0+text.length()*27.0
 node.draw_rect(Rect2(at-Vector2(14,34),Vector2(width,52)),Color(.02,.04,.08,.52))
 node.draw_rect(Rect2(at-Vector2(14,34),Vector2(width,52)),Color(accent.r,accent.g,accent.b,.55),false,2.0)
 node.draw_rect(Rect2(at-Vector2(14,34),Vector2(6,52)),accent)
 node.draw_string(TITLE_FONT,at-Vector2(2,32),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color(0,0,0,.45))
 node.draw_string(TITLE_FONT,at-Vector2(4,36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color(1,1,1,.94))
## 건물: 위에서 본 지붕면 + 남쪽 외벽(창문·차양·간판). 2.5D에서 가장 읽기 좋은 형태.
static func draw_walls(node: Node2D) -> void:
 var sign_words=["시장","포차","횟집","분식","서핑","샤워","카페","호텔","매점","어묵","조개","커피"]
 var roof_colors=[Color("4a3a33"),Color("3c3a4e"),Color("443a2e"),Color("39424f")]
 for index in range(L.BUILDINGS_RECTS.size()):
  var rect: Rect2=L.BUILDINGS_RECTS[index]
  node.draw_rect(Rect2(rect.position+Vector2(10,16),rect.size),Color(0,0,0,.5))
 for index2 in range(L.BUILDINGS_RECTS.size()):
  var rect2: Rect2=L.BUILDINGS_RECTS[index2]
  var roof_c: Color=roof_colors[index2%roof_colors.size()]
  var face_h: float=34.0
  var roof:=Rect2(rect2.position,Vector2(rect2.size.x,rect2.size.y-face_h))
  # 지붕면
  node.draw_rect(rect2.grow(4),Color(.02,.03,.05,.92))
  node.draw_rect(roof,roof_c)
  var ry: float=roof.position.y
  while ry<roof.end.y:
   node.draw_line(Vector2(roof.position.x,ry),Vector2(roof.end.x,ry),Color(.08,.08,.11,.35),1.2)
   ry+=10.0
  var rx: float=roof.position.x
  while rx<roof.end.x:
   node.draw_line(Vector2(rx,roof.position.y),Vector2(rx,roof.end.y),Color(.08,.08,.11,.22),1.0)
   rx+=24.0
  node.draw_rect(Rect2(roof.position,Vector2(roof.size.x,4)),Color(1,1,1,.10))
  # 옥상 설비·물탱크·환풍구
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.62,rect2.size.y*.30),Vector2(30,22)),Color("28324a"))
  node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.62,rect2.size.y*.30),Vector2(30,5)),Color("4d638a"))
  node.draw_circle(rect2.position+Vector2(rect2.size.x*.28,rect2.size.y*.42),11,Color("1f2738"))
  node.draw_circle(rect2.position+Vector2(rect2.size.x*.28,rect2.size.y*.42),6,Color("3d4c66"))
  if rect2.size.x>240.0:
   node.draw_rect(Rect2(rect2.position+Vector2(rect2.size.x*.80,rect2.size.y*.24),Vector2(20,20)),Color("303a52"))
  # 남쪽 외벽
  var face:=Rect2(Vector2(rect2.position.x,rect2.end.y-face_h),Vector2(rect2.size.x,face_h))
  var wall_c: Color=Color("35506a").lerp(Color("4a6584"),float(index2%3)*.2)
  node.draw_rect(face,wall_c)
  node.draw_rect(Rect2(face.position,Vector2(face.size.x,4)),Color(.05,.07,.10,.9))
  var wx: float=face.position.x+14.0
  while wx<face.end.x-26.0:
   node.draw_rect(Rect2(Vector2(wx-2,face.position.y+9),Vector2(24,18)),Color(.04,.05,.08,.95))
   node.draw_rect(Rect2(Vector2(wx,face.position.y+11),Vector2(20,14)),Color(WARM.r,WARM.g,WARM.b,.9))
   node.draw_rect(Rect2(Vector2(wx,face.position.y+11),Vector2(20,3)),Color(1,1,1,.25))
   wx+=40.0
  # 출입문
  var door_c:=Vector2(rect2.get_center().x,face.position.y+8)
  node.draw_rect(Rect2(door_c-Vector2(15,6),Vector2(30,face_h-8)),Color(.06,.05,.08,.96))
  node.draw_rect(Rect2(door_c-Vector2(13,-2),Vector2(26,face_h-14)),Color(.48,.30,.20,.95))
  # 차양
  var awning_colors=[Color("e8574d"),Color("f0a24d"),Color("4db6c8"),Color("d8588f"),Color("7fc66a")]
  var awning: Color=awning_colors[index2%awning_colors.size()]
  for k in range(int(rect2.size.x/34.0)):
   var x2: float=rect2.position.x+float(k)*34.0
   var col: Color=awning if k%2==0 else Color(.96,.96,.96)
   node.draw_rect(Rect2(Vector2(x2,face.position.y-7),Vector2(34,9)),Color(col.r,col.g,col.b,.95))
  node.draw_rect(Rect2(Vector2(rect2.position.x,face.position.y+2),Vector2(rect2.size.x,2)),Color(0,0,0,.35))
  # 지붕 위 간판(세워 둔 판)
  var word: String=sign_words[index2%sign_words.size()]
  var board_w: float=minf(rect2.size.x-30.0,120.0)
  var board:=Rect2(Vector2(rect2.position.x+16,rect2.position.y+10),Vector2(board_w,24))
  node.draw_rect(board.grow(2),Color(0,0,0,.55))
  node.draw_rect(board,Color(.04,.06,.10,.92))
  node.draw_rect(board,Color(awning.r,awning.g,awning.b,.9),false,2.0)
  node.draw_string(FONT,board.position+Vector2(6,18),word,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(1,.95,.85,.96))
  node.draw_rect(rect2,Color(.60,.76,1,.24),false,1.8)
 # 바다 호안벽
 for rect3 in L.WATER:
  node.draw_rect(rect3.grow(2),Color(.72,.78,.86,.38),false,2.4)
  node.draw_rect(rect3.grow(7),Color(.05,.09,.14,.35),false,1.2)
## 정적 소품: 가로등·난간·시장 천막·전구 줄·해변 소품·안내판.
static func draw_decor(node: Node2D) -> void:
 # 해안 난간
 for x in range(160,2440,90):
  node.draw_rect(Rect2(Vector2(x,1546),Vector2(5,28)),Color(.72,.78,.86,.6))
 node.draw_line(Vector2(160,1546),Vector2(2410,1546),Color(.80,.87,.94,.6),3.0)
 node.draw_line(Vector2(160,1560),Vector2(2410,1560),Color(.55,.62,.70,.4),2.0)
 # 가로등
 for spot in [Vector2(430,760),Vector2(900,760),Vector2(1450,760),Vector2(2000,760),Vector2(2380,760),
  Vector2(300,1450),Vector2(900,1450),Vector2(1450,1450),Vector2(2000,1450),Vector2(2330,1450),
  Vector2(700,1660),Vector2(1300,1660),Vector2(1900,1660),Vector2(2250,1980),
  Vector2(300,1900),Vector2(1000,2280),Vector2(1700,2280),Vector2(2200,2280)]:
  node.draw_circle(spot+Vector2(0,6),9,Color(0,0,0,.35))
  node.draw_line(spot,spot+Vector2(0,-58),Color(.12,.16,.22,.95),4.0)
  node.draw_circle(spot+Vector2(0,-62),7,Color(1,.84,.56,.98))
  node.draw_circle(spot+Vector2(0,-62),16,Color(1,.72,.36,.16))
 # 시장 천막(포장마차 골목)
 for tent in [Vector2(300,300),Vector2(660,300),Vector2(980,300),Vector2(300,600),Vector2(880,600),Vector2(1260,380)]:
  node.draw_rect(Rect2(tent-Vector2(58,4),Vector2(116,26)),Color(.32,.12,.16,.92))
  for k in range(4):
   node.draw_rect(Rect2(tent-Vector2(58,4)+Vector2(float(k)*29,0),Vector2(15,26)),Color(.86,.30,.34,.94))
  node.draw_line(tent-Vector2(52,4),tent-Vector2(52,-48),Color(.2,.16,.12,.9),3.0)
  node.draw_line(tent+Vector2(52,4),tent+Vector2(52,-48),Color(.2,.16,.12,.9),3.0)
  node.draw_rect(Rect2(Vector2(tent.x-54,tent.y-50),Vector2(108,10)),Color(.24,.10,.13,.95))
  node.draw_rect(Rect2(Vector2(tent.x-54,tent.y-52),Vector2(108,4)),Color(.55,.20,.24,.95))
 # 전구 줄(구남로·먹자골목)
 for line in [[Vector2(1150,742),Vector2(2050,742)],[Vector2(1150,1490),Vector2(2060,1490)],[Vector2(2200,742),Vector2(3200,742)]]:
  var a: Vector2=line[0]
  var b: Vector2=line[1]
  node.draw_line(a,b,Color(.08,.07,.06,.55),1.6)
  for i in range(int(a.distance_to(b)/70.0)+1):
   var t:=float(i)/maxf(1.0,float(int(a.distance_to(b)/70.0)))
   var p:=a.lerp(b,t)+Vector2(0,sin(t*PI)*16.0)
   node.draw_circle(p,4.2,Color(1,.86,.58,.95))
   node.draw_circle(p,9,Color(1,.78,.40,.14))
 # 서핑샵 안내판
 var sign_at:=Vector2(3140,470)
 node.draw_rect(Rect2(sign_at-Vector2(90,44),Vector2(180,60)),Color(.04,.09,.13,.88))
 node.draw_rect(Rect2(sign_at-Vector2(90,44),Vector2(180,60)),Color(NEON.r,NEON.g,NEON.b,.7),false,2.0)
 node.draw_string(FONT,sign_at-Vector2(78,-2),"서핑 · 샤워",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(.7,.95,1,.95))
 # 해변 소품: 파라솔 그늘·타월·모래성·구명튜브·목책
 for spot2 in [Vector2(700,1980),Vector2(1250,2050),Vector2(1750,1980),Vector2(2200,1900)]:
  node.draw_set_transform(spot2,0,Vector2(1,.42))
  node.draw_circle(Vector2.ZERO,54,Color(.06,.10,.16,.24))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for towel in [[Vector2(820,1975),Color(.90,.36,.42)],[Vector2(1380,2040),Color(.36,.66,.90)],[Vector2(1860,1975),Color(.90,.72,.32)]]:
  var p2: Vector2=towel[0]
  var c2: Color=towel[1]
  node.draw_rect(Rect2(p2-Vector2(34,14),Vector2(68,28)),c2)
  node.draw_rect(Rect2(p2-Vector2(34,14),Vector2(68,28)),Color(1,1,1,.25),false,1.0)
  node.draw_rect(Rect2(p2-Vector2(34,14),Vector2(68,6)),Color(1,1,1,.30))
 node.draw_circle(Vector2(1050,2180),10,Color(.80,.92,1,.85))
 node.draw_arc(Vector2(1050,2180),16,0,TAU,18,Color(.90,.96,1,.9),3.0,true)
 node.draw_circle(Vector2(1520,2150),10,Color(.90,.55,.40,.9))
 node.draw_arc(Vector2(1520,2150),16,0,TAU,18,Color(1,.75,.55,.9),3.0,true)
 # 목책(동백섬 다리·데크)
 for post in [Vector2(2560,1170),Vector2(2560,1240),Vector2(2700,1170),Vector2(2700,1240)]:
  node.draw_rect(Rect2(post-Vector2(4,0),Vector2(8,26)),Color(.42,.30,.20,.95))
 # 야자수(밝은 밤 해변의 실루엣)
 for palm in [Vector2(260,760),Vector2(760,760),Vector2(1320,760),Vector2(2050,760),Vector2(2380,900),
  Vector2(320,1500),Vector2(980,1500),Vector2(1650,1500),Vector2(2260,1500),Vector2(3120,880),Vector2(3140,1500)]:
  node.draw_circle(palm+Vector2(0,6),12,Color(0,0,0,.34))
  var lean: float=0.0
  node.draw_line(palm,palm+Vector2(lean,-96),Color(.24,.18,.14,.98),7.0)
  node.draw_line(palm+Vector2(lean,-96),palm+Vector2(lean,-96),Color(.24,.18,.14,.98),1.0)
  for f in range(6):
   var a: float=float(f)*TAU/6.0+0.4
   var tip: Vector2=palm+Vector2(lean,-96)+Vector2.from_angle(a)*Vector2(58,30)
   node.draw_line(palm+Vector2(lean,-96),tip,Color(.16,.40,.30,.95),6.0)
   node.draw_line(palm+Vector2(lean,-96),tip,Color(.24,.56,.40,.55),2.0)
  node.draw_circle(palm+Vector2(lean,-96),5,Color(.30,.22,.16,.95))
 # 벤치·쓰레기통·자전거 거치대
 for bench in [Vector2(600,800),Vector2(1180,1500),Vector2(2020,1500),Vector2(900,1690)]:
  node.draw_rect(Rect2(bench-Vector2(40,10),Vector2(80,16)),Color(.30,.22,.16,.95))
  node.draw_rect(Rect2(bench-Vector2(40,16),Vector2(80,8)),Color(.42,.32,.22,.95))
 for bin in [Vector2(520,1500),Vector2(1240,1500),Vector2(2160,1500),Vector2(1100,2290)]:
  node.draw_rect(Rect2(bin-Vector2(9,12),Vector2(18,22)),Color(.20,.22,.26,.95))
  node.draw_rect(Rect2(bin-Vector2(9,12),Vector2(18,4)),Color(.36,.40,.46,.95))
 # 샤워장·탈의실(서핑샵 옆)
 for hut in [Vector2(2560,430),Vector2(2760,430)]:
  node.draw_rect(Rect2(hut-Vector2(46,40),Vector2(92,58)),Color(.10,.20,.26,.96))
  node.draw_rect(Rect2(hut-Vector2(46,40),Vector2(92,8)),Color(.24,.44,.54,.96))
  node.draw_rect(Rect2(hut-Vector2(30,28),Vector2(60,44)),Color(.06,.12,.16,.9))
  node.draw_rect(Rect2(hut-Vector2(30,28),Vector2(60,44)),Color(.40,.70,.82,.35),false,2.0)
 # 공유 킥보드·자전거(거치대)
 for scooter in [Vector2(1180,720),Vector2(1980,720),Vector2(430,1450),Vector2(2140,1450)]:
  node.draw_circle(scooter+Vector2(-14,0),6,Color(.06,.06,.08,.9))
  node.draw_circle(scooter+Vector2(14,0),6,Color(.06,.06,.08,.9))
  node.draw_line(scooter+Vector2(-14,4),scooter+Vector2(0,-16),Color(.30,.60,.75,.95),4.0)
  node.draw_line(scooter+Vector2(0,-16),scooter+Vector2(16,-2),Color(.30,.60,.75,.95),4.0)
  node.draw_line(scooter+Vector2(0,-16),scooter+Vector2(6,-26),Color(.30,.60,.75,.95),3.0)
## 사물 발밑 그림자.
static func draw_prop_shadows(node: Node2D) -> void:
 for object in L.OBJECTS:
  var visual: Dictionary=L.form_visual(String(object.kind))
  var side: float=float(visual.get("shadow",10.0))
  node.draw_set_transform(object.p,0,Vector2(1,.45))
  node.draw_circle(Vector2.ZERO,side*1.35,Color(0,0,0,.32))
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
