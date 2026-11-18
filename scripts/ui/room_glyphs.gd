extends RefCounted
## 대기실(친구 방)이 쓰는 벡터 아이콘 모음. 텍스처를 늘리지 않고 그려서
## 16:9·20:9 어느 화면에서도 같은 선명도와 같은 금빛 톤을 유지한다.
## 모든 좌표는 아이콘 상자의 중심을 0, 반지름을 1로 두고 그린다.
const T=preload("res://scripts/ui/lobby_theme.gd")

static func draw_glyph(ci: CanvasItem,glyph: String,rect: Rect2,color: Color,line: float=1.8,glow: float=0.0) -> void:
	var s:=minf(rect.size.x,rect.size.y)
	if s<=2.0:return
	var center:=rect.get_center()
	var u:=s*.5
	if glow>0.0:
		for i in range(4):
			ci.draw_circle(center,u*(.55-float(i)*.09),Color(color.r,color.g,color.b,.045*glow))
	match glyph:
		"lantern": _lantern(ci,center,u,color,line)
		"copy": _copy(ci,center,u,color,line)
		"invite": _invite(ci,center,u,color,line)
		"back": _back(ci,center,u,color,line)
		"next": _next(ci,center,u,color,line)
		"users": _users(ci,center,u,color,line)
		"lotus": _lotus(ci,center,u,color,line)
		"fox": _fox(ci,center,u,color,line)
		"shuffle": _shuffle(ci,center,u,color,line)
		"clock": _clock(ci,center,u,color,line)
		"swords": _swords(ci,center,u,color,line)
		"crown": _crown(ci,center,u,color,line)
		"check": _check(ci,center,u,color,line)
		"cross": _cross(ci,center,u,color,line)
		"exit": _exit(ci,center,u,color,line)
		"flower": _flower(ci,center,u,color,line)
		"cloud": _cloud(ci,center,u,color,line)
		"grid": _grid(ci,center,u,color,line)
		"hourglass": _hourglass(ci,center,u,color,line)
		"trophy": _trophy(ci,center,u,color,line)
		"mail": _mail(ci,center,u,color,line)
		"seal": _seal(ci,center,u,color,line)
		"moon": _moon(ci,center,u,color,line)
		"spark": _spark(ci,center,u,color,line)
		"scroll": _scroll(ci,center,u,color,line)
		"diamond": T.diamond(ci,center,u*.42,color)
		_: draw_glyph(ci,"diamond",rect,color,line,glow)

static func _lantern(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.5)
	# 고리와 갓
	ci.draw_line(c+Vector2(0,-1.0)*u,c+Vector2(0,-.80)*u,color,line)
	ci.draw_arc(c+Vector2(0,-1.0)*u,.11*u,PI*.15,PI*.85,10,color,line)
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-.34,-.80)*u,c+Vector2(.34,-.80)*u,c+Vector2(.25,-.66)*u,c+Vector2(-.25,-.66)*u]),color)
	# 몸통(배가 부른 등롱)
	var body:=PackedVector2Array([c+Vector2(-.32,-.66)*u,c+Vector2(.32,-.66)*u,c+Vector2(.44,-.18)*u,c+Vector2(.38,.38)*u,c+Vector2(-.38,.38)*u,c+Vector2(-.44,-.18)*u,c+Vector2(-.32,-.66)*u])
	ci.draw_colored_polygon(body,Color(color.r,color.g,color.b,.18))
	ci.draw_polyline(body,color,line,true)
	# 창살
	for x in [-.16,.16]:
		ci.draw_line(c+Vector2(x,-.62)*u,c+Vector2(x*.86,.34)*u,dim,line*.8)
	ci.draw_line(c+Vector2(-.42,-.18)*u,c+Vector2(.42,-.18)*u,dim,line*.8)
	# 아래 갓과 술
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-.26,.38)*u,c+Vector2(.26,.38)*u,c+Vector2(.16,.52)*u,c+Vector2(-.16,.52)*u]),color)
	ci.draw_line(c+Vector2(0,.52)*u,c+Vector2(0,.82)*u,color,line)
	ci.draw_circle(c+Vector2(0,.86)*u,.07*u,color)
	for x in [-.10,.10]:
		ci.draw_line(c+Vector2(0,.70)*u,c+Vector2(x,.92)*u,dim,line*.7)

static func _copy(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var back:=Rect2(c+Vector2(-.66,-.78)*u,Vector2(.98,.98)*u)
	T.rounded_outline(ci,back,Color(color.r,color.g,color.b,color.a*.55),.16*u,line)
	var front:=Rect2(c+Vector2(-.22,-.30)*u,Vector2(.98,.98)*u)
	ci.draw_colored_polygon(T.rounded_points(front,.16*u),Color(color.r,color.g,color.b,.20))
	T.rounded_outline(ci,front,color,.16*u,line)

static func _invite(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var head:=c+Vector2(-.24,-.34)*u
	ci.draw_circle(head,.22*u,Color(color.r,color.g,color.b,.20))
	ci.draw_arc(head,.22*u,0,TAU,20,color,line)
	ci.draw_arc(c+Vector2(-.24,.46)*u,.40*u,PI,TAU,20,color,line)
	ci.draw_line(c+Vector2(.44,-.52)*u,c+Vector2(.44,-.14)*u,color,line*1.15)
	ci.draw_line(c+Vector2(.23,-.33)*u,c+Vector2(.65,-.33)*u,color,line*1.15)

static func _back(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_line(c+Vector2(.62,0)*u,c+Vector2(-.62,0)*u,color,line*1.1)
	ci.draw_line(c+Vector2(-.62,0)*u,c+Vector2(-.18,-.38)*u,color,line*1.1)
	ci.draw_line(c+Vector2(-.62,0)*u,c+Vector2(-.18,.38)*u,color,line*1.1)

## 오른쪽 화살표(페이지 넘김).
static func _next(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_line(c+Vector2(-.62,0)*u,c+Vector2(.62,0)*u,color,line*1.1)
	ci.draw_line(c+Vector2(.62,0)*u,c+Vector2(.18,-.38)*u,color,line*1.1)
	ci.draw_line(c+Vector2(.62,0)*u,c+Vector2(.18,.38)*u,color,line*1.1)

static func _users(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.75)
	for spec in [Vector2(-.46,-.30),Vector2(.46,-.30)]:
		var head: Vector2=spec
		ci.draw_arc(c+head*u,.17*u,0,TAU,16,dim,line*.85)
		ci.draw_arc(c+Vector2(head.x,.52)*u,.34*u,PI,TAU,16,dim,line*.85)
	ci.draw_arc(c+Vector2(0,-.40)*u,.24*u,0,TAU,20,color,line)
	ci.draw_arc(c+Vector2(0,.52)*u,.44*u,PI,TAU,20,color,line)

static func _rot(point: Vector2,angle: float) -> Vector2:
	return Vector2(point.x*cos(angle)-point.y*sin(angle),point.x*sin(angle)+point.y*cos(angle))

## 연꽃: 다섯 잎이 가운데에서 바깥으로 뻗는 모양. 잎을 채워 작은 크기에서도 꽃으로 읽힌다.
static func _lotus(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	for i in range(5):
		var angle:=-PI*.5+i*TAU/5.0
		var dir:=Vector2.from_angle(angle)
		var side:=Vector2.from_angle(angle+PI*.5)
		var w:=u*.30
		var petal:=PackedVector2Array([
			c+dir*(.16*u),
			c+dir*(.34*u)+side*w*.55,
			c+dir*(.62*u)+side*w,
			c+dir*(.88*u)+side*w*.55,
			c+dir*(.98*u),
			c+dir*(.88*u)-side*w*.55,
			c+dir*(.62*u)-side*w,
			c+dir*(.34*u)-side*w*.55])
		ci.draw_colored_polygon(petal,Color(color.r,color.g,color.b,.40 if i%2==0 else .28))
		ci.draw_polyline(PackedVector2Array([petal[0],petal[1],petal[2],petal[3],petal[4],petal[5],petal[6],petal[7],petal[0]]),color,line*.75,true)
	ci.draw_circle(c,.13*u,Color(color.r,color.g,color.b,.9))

static func _swords(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var steel:=Color(color.r,color.g,color.b)
	for dir in [-1.0,1.0]:
		var angle:=float(dir)*.62
		var point:=func(x: float,y: float)->Vector2:return c+_rot(Vector2(x,y)*u,angle)
		var blade:=PackedVector2Array([point.call(0,-.98),point.call(.07,-.86),point.call(.055,.16),point.call(0,.26),point.call(-.055,.16),point.call(-.07,-.86)])
		ci.draw_colored_polygon(blade,Color(steel.r,steel.g,steel.b,.95))
		ci.draw_polyline(PackedVector2Array([blade[0],blade[1],blade[2],blade[3],blade[4],blade[5],blade[0]]),Color(steel.r*.55,steel.g*.45,steel.b*.35,.9),line*.7,true)
		ci.draw_line(point.call(0,-.86),point.call(0,.20),Color(1,1,1,.45),line*.55)
		ci.draw_line(point.call(-.26,.20),point.call(.26,.20),color,line*1.5)
		ci.draw_line(point.call(0,.22),point.call(0,.52),color,line*1.7)
		ci.draw_circle(point.call(0,.60),u*.085,color)

static func _fox(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var face:=PackedVector2Array([c+Vector2(-.52,-.44)*u,c+Vector2(-.28,-.74)*u,c+Vector2(.28,-.74)*u,c+Vector2(.52,-.44)*u,c+Vector2(.44,.20)*u,c+Vector2(0,.70)*u,c+Vector2(-.44,.20)*u,c+Vector2(-.52,-.44)*u])
	ci.draw_colored_polygon(face,Color(color.r,color.g,color.b,.14))
	ci.draw_polyline(face,color,line,true)
	# 귀
	for side in [-1.0,1.0]:
		var ear:=PackedVector2Array([c+Vector2(.30*side,-.70)*u,c+Vector2(.66*side,-1.0)*u,c+Vector2(.52*side,-.34)*u])
		ci.draw_colored_polygon(ear,Color(color.r,color.g,color.b,.22))
		ci.draw_polyline(PackedVector2Array([ear[0],ear[1],ear[2]]),color,line*.9,true)
	# 눈·코·수염
	for side in [-1.0,1.0]:
		ci.draw_line(c+Vector2(.10*side,-.20)*u,c+Vector2(.34*side,-.06)*u,color,line*1.1)
		ci.draw_line(c+Vector2(.46*side,.04)*u,c+Vector2(.76*side,-.04)*u,Color(color.r,color.g,color.b,color.a*.6),line*.7)
		ci.draw_line(c+Vector2(.46*side,.10)*u,c+Vector2(.74*side,.16)*u,Color(color.r,color.g,color.b,color.a*.6),line*.7)
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-.09,.10)*u,c+Vector2(.09,.10)*u,c+Vector2(0,.24)*u]),color)
	ci.draw_line(c+Vector2(0,.24)*u,c+Vector2(0,.34)*u,color,line*.8)

static func _shuffle(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.9)
	for dir in [-1.0,1.0]:
		var start:=c+Vector2(-.74,-.36*dir)*u
		var mid:=c+Vector2(0,.02*dir)*u
		var end:=c+Vector2(.52,.36*dir)*u
		ci.draw_polyline(PackedVector2Array([start,mid,end]),dim,line*1.1,true)
		ci.draw_line(end,end+Vector2(-.20,-.20*dir)*u,dim,line*1.1)
		ci.draw_line(end,end+Vector2(-.26,.06*dir)*u,dim,line*1.1)

static func _clock(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_arc(c,.74*u,0,TAU,32,color,line*1.1)
	ci.draw_line(c+Vector2(0,-.74)*u,c+Vector2(0,-.94)*u,color,line*1.1)
	ci.draw_line(c+Vector2(-.14,-.94)*u,c+Vector2(.14,-.94)*u,color,line*1.1)
	ci.draw_line(c,c+Vector2(0,-.44)*u,color,line*1.1)
	ci.draw_line(c,c+Vector2(.34,.10)*u,color,line*1.1)
	ci.draw_circle(c,.08*u,color)

static func _crown(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var crown:=PackedVector2Array([c+Vector2(-.62,.34)*u,c+Vector2(-.62,-.30)*u,c+Vector2(-.30,-.02)*u,c+Vector2(0,-.56)*u,c+Vector2(.30,-.02)*u,c+Vector2(.62,-.30)*u,c+Vector2(.62,.34)*u])
	ci.draw_colored_polygon(crown,color)
	ci.draw_polyline(crown,Color(color.r*.55,color.g*.45,color.b*.30,color.a),line*.7,true)
	ci.draw_line(c+Vector2(-.62,.34)*u,c+Vector2(.62,.34)*u,Color(color.r*.5,color.g*.4,color.b*.25,color.a),line*.9)
	for peak in [[-.62,-.30],[0,-.56],[.62,-.30]]:
		ci.draw_circle(c+Vector2(float(peak[0]),float(peak[1]))*u,.075*u,Color(1,.98,.9,color.a))
	ci.draw_circle(c+Vector2(0,.10)*u,.07*u,Color(color.r*.55,color.g*.4,color.b*.2,color.a*.8))

static func _check(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_polyline(PackedVector2Array([c+Vector2(-.56,.04)*u,c+Vector2(-.16,.44)*u,c+Vector2(.58,-.46)*u]),color,line*1.35,true)

static func _cross(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	for dir in [-1.0,1.0]:
		ci.draw_line(c+Vector2(-.50,-.50*dir)*u,c+Vector2(.50,.50*dir)*u,color,line*1.2)

static func _exit(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_polyline(PackedVector2Array([c+Vector2(-.12,-.78)*u,c+Vector2(-.68,-.78)*u,c+Vector2(-.68,.78)*u,c+Vector2(-.12,.78)*u]),color,line*1.1,true)
	ci.draw_line(c+Vector2(-.06,0)*u,c+Vector2(.66,0)*u,color,line*1.1)
	ci.draw_line(c+Vector2(.66,0)*u,c+Vector2(.30,-.30)*u,color,line*1.1)
	ci.draw_line(c+Vector2(.66,0)*u,c+Vector2(.30,.30)*u,color,line*1.1)

static func _flower(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	for i in range(5):
		var at:=c+Vector2.from_angle(-PI*.5+i*TAU/5.0)*u*.46
		ci.draw_circle(at,u*.30,Color(color.r,color.g,color.b,color.a*.55))
		ci.draw_arc(at,u*.30,0,TAU,18,Color(color.r,color.g,color.b,color.a*.85),line*.7)
	ci.draw_circle(c,u*.16,Color(color.r,color.g,color.b,color.a*.95))
	for i in range(5):
		ci.draw_circle(c+Vector2.from_angle(-PI*.5+i*TAU/5.0)*u*.44,u*.05,Color(color.r*.6,color.g*.4,color.b*.5,color.a*.8))

## 진영 전체 보기: 2×2 격자.
static func _grid(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	for row in range(2):
		for col in range(2):
			var box:=Rect2(c+Vector2((-.48 if col==0 else .06),(-.48 if row==0 else .06))*u,Vector2(.42,.42)*u)
			T.rounded(ci,box,Color(color.r,color.g,color.b,color.a*.20),u*.06)
			T.rounded_outline(ci,box,color,u*.06,line)

## 남은 시간: 위아래가 뒤집힌 유리병과 흐르는 모래.
static func _hourglass(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.55)
	ci.draw_line(c+Vector2(-.58,-.92)*u,c+Vector2(.58,-.92)*u,color,line*1.4)
	ci.draw_line(c+Vector2(-.58,.92)*u,c+Vector2(.58,.92)*u,color,line*1.4)
	var glass:=PackedVector2Array([c+Vector2(-.46,-.84)*u,c+Vector2(.46,-.84)*u,c+Vector2(.10,.02)*u,c+Vector2(.44,.84)*u,c+Vector2(-.44,.84)*u,c+Vector2(-.10,.02)*u])
	ci.draw_polyline(glass,color,line,true)
	# 위쪽 모래
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-.36,-.74)*u,c+Vector2(.36,-.74)*u,c+Vector2(.20,-.26)*u,c+Vector2(-.20,-.26)*u]),Color(color.r,color.g,color.b,.72))
	# 아래로 떨어지는 가는 모래줄과 아래쪽 더미
	ci.draw_line(c+Vector2(0,-.24)*u,c+Vector2(0,.44)*u,dim,line*1.1)
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-.34,.80)*u,c+Vector2(.34,.80)*u,c+Vector2(.16,.40)*u,c+Vector2(-.16,.40)*u]),Color(color.r,color.g,color.b,.85))

## 업적 메달: 리본 두 갈래와 금테 원, 가운데 별.
static func _trophy(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.62)
	for side in [-1.0,1.0]:
		var ribbon:=PackedVector2Array([c+Vector2(.12*side,.28)*u,c+Vector2(.46*side,.96)*u,c+Vector2(.22*side,.90)*u,c+Vector2(.04*side,.40)*u])
		ci.draw_colored_polygon(ribbon,dim)
	var center:=c+Vector2(0,-.22)*u
	ci.draw_circle(center,u*.56,Color(color.r,color.g,color.b,.20))
	ci.draw_arc(center,u*.56,0,TAU,40,color,line*1.3,true)
	ci.draw_arc(center,u*.44,0,TAU,32,Color(color.r,color.g,color.b,.55),line,true)
	draw_star(ci,center,u*.30,color,maxf(1.0,line*.8))

static func draw_star(ci: CanvasItem,at: Vector2,r: float,color: Color,line: float=1.0) -> void:
	var points:=PackedVector2Array()
	for i in range(10):
		var radius:=r if i%2==0 else r*.44
		points.append(at+Vector2.from_angle(-PI*.5+i*TAU/10.0)*radius)
	points.append(points[0])
	ci.draw_colored_polygon(points,color)
	if line>0.0:ci.draw_polyline(points,Color(color.r*.55,color.g*.42,color.b*.28,color.a),line*.7,true)

## 우편: 봉투와 봉인.
static func _mail(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var box:=Rect2(c+Vector2(-.88,-.56)*u,Vector2(1.76,1.16)*u)
	T.rounded(ci,box,Color(color.r,color.g,color.b,.16),u*.10)
	T.rounded_outline(ci,box,color,u*.10,line*1.1)
	ci.draw_polyline(PackedVector2Array([box.position,Vector2(c.x,box.position.y+box.size.y*.48),Vector2(box.end.x,box.position.y)]),color,line,true)
	ci.draw_circle(Vector2(c.x,box.position.y+box.size.y*.54),u*.16,Color(color.r,color.g,color.b,.85))
	ci.draw_arc(Vector2(c.x,box.position.y+box.size.y*.54),u*.16,0,TAU,16,color,line*.7,true)

## 낙관(붉은 봉인): 네 칸 문양 도장.
static func _seal(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var box:=Rect2(c+Vector2(-.78,-.78)*u,Vector2(1.56,1.56)*u)
	T.rounded(ci,box,Color(color.r,color.g,color.b,.90),u*.14)
	var ink:=Color(1,.95,.88,.92)
	T.rounded_outline(ci,box.grow(-u*.12),ink,u*.08,maxf(1.0,line*.8))
	for i in range(2):
		ci.draw_line(Vector2(box.position.x+u*.20,box.position.y+box.size.y*(.5 if i==0 else 0)),Vector2(box.end.x-u*.20,box.position.y+box.size.y*(.5 if i==0 else 0)),ink,maxf(1.0,line*.6))
	ci.draw_line(Vector2(box.position.x+box.size.x*.5,box.position.y+u*.20),Vector2(box.position.x+box.size.x*.5,box.end.y-u*.20),ink,maxf(1.0,line*.6))

## 달.
static func _moon(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	ci.draw_circle(c,u*.86,Color(color.r,color.g,color.b,.22))
	ci.draw_arc(c,u*.86,0,TAU,48,color,line*1.2,true)
	ci.draw_arc(c+Vector2(.16,-.10)*u,u*.66,PI*.55,PI*1.75,24,Color(color.r,color.g,color.b,.45),line,true)

## 반짝임 네 갈래.
static func _spark(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var points:=PackedVector2Array([c+Vector2(0,-.95)*u,c+Vector2(.18,-.18)*u,c+Vector2(.95,0)*u,c+Vector2(.18,.18)*u,c+Vector2(0,.95)*u,c+Vector2(-.18,.18)*u,c+Vector2(-.95,0)*u,c+Vector2(-.18,-.18)*u])
	ci.draw_colored_polygon(points,Color(color.r,color.g,color.b,.85))
	ci.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[4],points[5],points[6],points[7],points[0]]),color,maxf(1.0,line*.6),true)
	ci.draw_circle(c,u*.18,Color(1,.98,.9,.95))

## 두루마리: 위아래 마구리.
static func _scroll(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var sheet:=Rect2(c+Vector2(-.52,-.72)*u,Vector2(1.04,1.44)*u)
	T.rounded(ci,sheet,Color(color.r,color.g,color.b,.14),u*.04)
	T.rounded_outline(ci,sheet,color,u*.04,line)
	for i in range(3):
		var y:=sheet.position.y+sheet.size.y*(.26+float(i)*.24)
		ci.draw_line(Vector2(sheet.position.x+u*.16,y),Vector2(sheet.end.x-u*.16,y),Color(color.r,color.g,color.b,.55),maxf(1.0,line*.6))
	for side in [-1.0,1.0]:
		var at:=Vector2(sheet.position.x+sheet.size.x*.5,sheet.position.y if side<0 else sheet.end.y)
		T.rounded(ci,Rect2(at-Vector2(u*.62,u*.11),Vector2(u*1.24,u*.22)),color,u*.10)

static func _cloud(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.8)
	ci.draw_arc(c+Vector2(-.34,.04)*u,.30*u,PI,TAU,16,dim,line)
	ci.draw_arc(c+Vector2(.02,-.10)*u,.36*u,PI,TAU,18,dim,line)
	ci.draw_arc(c+Vector2(.40,.04)*u,.26*u,PI,TAU,16,dim,line)
	ci.draw_line(c+Vector2(-.64,.04)*u,c+Vector2(.66,.04)*u,dim,line)
	for side in [-1.0,1.0]:
		ci.draw_arc(c+Vector2(.10*side,.10)*u,.26*u,0,PI,14,Color(dim.r,dim.g,dim.b,.4),line*.8)
