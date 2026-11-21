extends RefCounted
## 2.0.36 4맵 실내(어몽어스식) 공용 키트.
## 건물 사각형 하나를 '앞문·뒷문이 있는 방'으로 바꾸고, 캐릭터가 들어가면
## 지붕이 사라지듯 실내 단면(바닥·벽·가구·조명)이 드러나게 그린다.
## 레이아웃은 INTERIORS 목록만 정의하고, 충돌은 build_hard가 문틈을 남긴다.
## world는 draw_room만 호출한다(그림과 판정이 같은 사각형을 본다).
const WALL=26.0
const DOOR=96.0
const TRIM=10.0
## 건물 사각형 → 앞문(남쪽 중앙)·뒷문(북쪽 중앙)·실내 바닥.
static func make_entry(id: String,name: String,rect: Rect2,kind: String,accent: Color,sub: String="") -> Dictionary:
 var front:=Vector2(rect.get_center().x,rect.end.y)
 var back:=Vector2(rect.get_center().x,rect.position.y)
 return {"id":id,"name":name,"sub":sub,"kind":kind,"accent":accent,
  "rect":rect,"interior":rect.grow(-WALL-TRIM),
  "doors":{"front":front,"back":back},"anchor":Vector2(.5,1.0),"art":Vector2(760,727),
  "painted_door":front+Vector2(0,-18)}
## 건물 충돌: 네 벽을 세우되 앞·뒷문 폭만큼 비운다(실제로 걸어 들어간다).
static func add_walls(hard: Array,entry: Dictionary) -> void:
 var rect: Rect2=entry.rect
 var front: Vector2=(entry.doors as Dictionary).front
 var back: Vector2=(entry.doors as Dictionary).back
 var half:=DOOR*.5
 for side in [true,false]:
  var y: float=rect.position.y if side else rect.end.y-WALL
  var door_x: float=back.x if side else front.x
  hard.append(Rect2(rect.position.x,y,door_x-half-rect.position.x,WALL))
  hard.append(Rect2(door_x+half,y,rect.end.x-door_x-half,WALL))
 hard.append(Rect2(rect.position.x,rect.position.y,WALL,rect.size.y))
 hard.append(Rect2(rect.end.x-WALL,rect.position.y,WALL,rect.size.y))
## 문 앞·뒤가 실제로 걸을 수 있는지(테스트·디버그). outside는 레이아웃의 can_stand.
static func doors_open(entry: Dictionary,outside: Callable) -> bool:
 var front: Vector2=(entry.doors as Dictionary).front
 var back: Vector2=(entry.doors as Dictionary).back
 return bool(outside.call(front+Vector2(0,TRIM+DOOR*.5))) and bool(outside.call(back-Vector2(0,TRIM+DOOR*.5)))
## 실내 단면: 바닥·벽·가구·조명. alpha=1이면 완전히 실내, 0이면 그리지 않는다.
## kind별로 가구가 다르다(카페=카운터·테이블, 상점=진열장, 오락실=기계, 식당=탁자).
static func draw_room(node: Node2D,entry: Dictionary,alpha: float,clock: float) -> void:
 if alpha<=.02:return
 var rect: Rect2=entry.rect
 var room: Rect2=entry.interior
 var accent: Color=entry.get("accent",Color("e8c98b"))
 var kind: String=String(entry.get("kind","shop"))
 var plank: Color=Color("8a6a48") if kind!="arcade" else Color("2c2a3a")
 var floor_color:=Color(plank.r,plank.g,plank.b,alpha)
 # 1) 바닥: 밝은 판자/타일 결 + 가운데 러그
 node.draw_rect(rect,Color(.05,.04,.06,alpha))
 node.draw_rect(room.grow(WALL*.4),Color(floor_color.r*.78,floor_color.g*.74,floor_color.b*.70,alpha))
 if kind=="shop" or kind=="food":
  var tile:=36.0
  var ty:=room.position.y
  while ty<room.end.y:
   node.draw_line(Vector2(room.position.x,ty),Vector2(room.end.x,ty),Color(1,.90,.72,alpha*.16),1.0)
   ty+=tile
  var tx:=room.position.x
  while tx<room.end.x:
   node.draw_line(Vector2(tx,room.position.y),Vector2(tx,room.end.y),Color(1,.90,.72,alpha*.12),1.0)
   tx+=tile
  node.draw_rect(Rect2(room.position+Vector2(room.size.x*.10,room.size.y*.55),Vector2(room.size.x*.80,room.size.y*.30)),Color(.55,.18,.24,alpha*.55))
  node.draw_rect(Rect2(room.position+Vector2(room.size.x*.10,room.size.y*.55),Vector2(room.size.x*.80,room.size.y*.30)),Color(1,.80,.62,alpha*.35),false,2.0)
 var step:=26.0
 var y:=room.position.y
 while y<room.end.y:
  node.draw_line(Vector2(room.position.x,y),Vector2(room.end.x,y),Color(plank.r*.8,plank.g*.8,plank.b*.8,alpha*.55),1.0)
  y+=step
 # 2) 벽: 방 둘레의 목벽/타일
 var wall_color:=Color(.62,.52,.38,alpha) if kind in ["shop","food"] else (Color(.24,.17,.12,alpha) if kind!="arcade" else Color(.12,.11,.18,alpha))
 node.draw_rect(Rect2(room.position-Vector2(WALL,WALL),Vector2(room.size.x+WALL*2,WALL)),wall_color)
 node.draw_rect(Rect2(room.position.x-WALL,room.end.y,room.size.x+WALL*2,WALL),wall_color)
 node.draw_rect(Rect2(room.position.x-WALL,room.position.y-WALL,WALL,room.size.y+WALL*2),wall_color)
 node.draw_rect(Rect2(room.end.x,room.position.y-WALL,WALL,room.size.y+WALL*2),wall_color)
 # 벽 하이라이트와 액자·창
 node.draw_rect(Rect2(room.position-Vector2(WALL,WALL),Vector2(room.size.x+WALL*2,3)),Color(1,.9,.7,alpha*.18))
 for i in range(3):
  var wx:=room.position.x+room.size.x*(.22+float(i)*.28)
  node.draw_rect(Rect2(Vector2(wx,room.position.y-WALL+7),Vector2(28,12)),Color(accent.r,accent.g,accent.b,alpha*.30))
 # 3) 문틈: 앞·뒷문 바닥을 밝게(어디로 나가는지 읽힌다)
 var front: Vector2=(entry.doors as Dictionary).front
 var back: Vector2=(entry.doors as Dictionary).back
 for at in [front,back]:
  node.draw_rect(Rect2(Vector2(at.x-DOOR*.5, at.y-WALL if at==back else at.y-WALL),Vector2(DOOR,WALL)),Color(1,.86,.55,alpha*.22))
  node.draw_rect(Rect2(Vector2(at.x-DOOR*.5, at.y-2),Vector2(DOOR,4)),Color(1,.9,.62,alpha*.55))
 # 4) 가구
 match kind:
  "cafe":
   counter(node,room,accent,alpha)
   for i in range(3):
    var t:=Vector2(room.position.x+40+float(i)*room.size.x*.28,room.position.y+room.size.y*.62)
    node.draw_circle(t,9,Color(.45,.30,.20,alpha))
    node.draw_circle(t,6,Color(.72,.54,.36,alpha))
  "shop":
   # 진열장 2개: 화려한 상품이 꽂힌 3단 + 가격 카드
   for i in range(2):
    var shelf:=Rect2(room.position.x+18+float(i)*room.size.x*.48,room.position.y+14,room.size.x*.38,room.size.y*.42)
    node.draw_rect(shelf,Color(.16,.12,.10,alpha))
    node.draw_rect(shelf.grow(-2),Color(.88,.78,.62,alpha))
    for k in range(3):
     var row_y:=shelf.position.y+6+float(k)*(shelf.size.y-10)/3.0
     node.draw_rect(Rect2(shelf.position.x+3,row_y,shelf.size.x-6,3),Color(.55,.42,.30,alpha))
     for j in range(5):
      var col:=Color.from_hsv(fmod(.08+float(j)*.13+float(k)*.05+float(i)*.2,1.0),.55,.95,alpha)
      node.draw_rect(Rect2(shelf.position.x+6+float(j)*(shelf.size.x-12)/5.0,row_y+4,(shelf.size.x-12)/5.0-3,9),col)
   counter(node,room,accent,alpha)
   # 계산대 위 금전등록기와 꽃병
   var reg:=Vector2(room.position.x+room.size.x*.42,room.end.y-room.size.y*.30)
   node.draw_rect(Rect2(reg-Vector2(14,20),Vector2(28,20)),Color(.12,.12,.16,alpha))
   node.draw_rect(Rect2(reg-Vector2(11,17),Vector2(22,10)),Color(accent.r,accent.g,accent.b,alpha*.8))
   node.draw_circle(reg+Vector2(26,-8),5,Color(1,.55,.65,alpha*.9))
   node.draw_line(reg+Vector2(26,-3),reg+Vector2(26,4),Color(.25,.45,.25,alpha),2.0)
  "arcade":
   for i in range(4):
    var cab:=Vector2(room.position.x+26+float(i%2)*room.size.x*.52,room.position.y+26+float(i/2)*room.size.y*.44)
    node.draw_rect(Rect2(cab,Vector2(34,48)),Color(.10,.09,.16,alpha))
    node.draw_rect(Rect2(cab+Vector2(5,6),Vector2(24,18)),Color(accent.r,accent.g,accent.b,alpha*.55+.20*sin(clock*3.0+float(i))))
    node.draw_rect(Rect2(cab+Vector2(6,30),Vector2(22,6)),Color(.5,.5,.6,alpha*.5))
  "food":
   for i in range(3):
    var table:=Vector2(room.position.x+34+float(i)*room.size.x*.30,room.position.y+room.size.y*.55)
    node.draw_rect(Rect2(table-Vector2(16,9),Vector2(32,18)),Color(.42,.28,.18,alpha))
    node.draw_circle(table+Vector2(-12,14),4,Color(.5,.36,.24,alpha))
    node.draw_circle(table+Vector2(12,14),4,Color(.5,.36,.24,alpha))
   counter(node,room,accent,alpha)
  "control":
   counter(node,room,accent,alpha)
   for i in range(3):
    var mon:=Vector2(room.position.x+28+float(i)*room.size.x*.30,room.position.y+24)
    node.draw_rect(Rect2(mon,Vector2(30,22)),Color(.06,.10,.14,alpha))
    node.draw_rect(Rect2(mon+Vector2(3,3),Vector2(24,16)),Color(accent.r,accent.g,accent.b,alpha*.5))
  _:
   counter(node,room,accent,alpha)
 # 5) 천장 등: 따뜻한 빛 웅덩이
 for i in range(3):
  var lamp:=Vector2(room.position.x+room.size.x*(.22+float(i)*.28),room.position.y+room.size.y*.28)
  node.draw_line(lamp-Vector2(0,26),lamp,Color(.25,.18,.12,alpha),1.5)
  node.draw_circle(lamp,26,Color(1,.84,.52,alpha*.08))
  node.draw_circle(lamp,5,Color(1,.92,.72,alpha*.75))
  node.draw_arc(lamp,9,0,TAU,16,Color(1,.86,.55,alpha*.35),1.4,true)
static func counter(node: Node2D,room: Rect2,accent: Color,alpha: float) -> void:
 var bar:=Rect2(room.position.x+room.size.x*.12,room.end.y-room.size.y*.26-WALL*.5,room.size.x*.52,18)
 node.draw_rect(bar,Color(.24,.17,.12,alpha))
 node.draw_rect(Rect2(bar.position,Vector2(bar.size.x,4)),Color(.48,.34,.22,alpha))
 node.draw_rect(bar.grow(1),Color(accent.r,accent.g,accent.b,alpha*.35),false,1.4)
## 문 앞 간판(실내 이름). world가 건물 위에 띄운다.
static func sign_text(entry: Dictionary) -> String:
 return String(entry.get("name",""))
