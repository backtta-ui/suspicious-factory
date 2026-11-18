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

static func _cloud(ci: CanvasItem,c: Vector2,u: float,color: Color,line: float) -> void:
	var dim:=Color(color.r,color.g,color.b,color.a*.8)
	ci.draw_arc(c+Vector2(-.34,.04)*u,.30*u,PI,TAU,16,dim,line)
	ci.draw_arc(c+Vector2(.02,-.10)*u,.36*u,PI,TAU,18,dim,line)
	ci.draw_arc(c+Vector2(.40,.04)*u,.26*u,PI,TAU,16,dim,line)
	ci.draw_line(c+Vector2(-.64,.04)*u,c+Vector2(.66,.04)*u,dim,line)
	for side in [-1.0,1.0]:
		ci.draw_arc(c+Vector2(.10*side,.10)*u,.26*u,0,PI,14,Color(dim.r,dim.g,dim.b,.4),line*.8)
