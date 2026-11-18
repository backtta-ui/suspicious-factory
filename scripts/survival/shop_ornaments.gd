class_name ShopOrnaments
extends RefCounted
## 2.0.22 상점 전용 장식 그리기 도구.
## 시안(browser/gpt_shop_ui_v2_full-2026-11-19-015659.png)의 황동 베벨 카드 프레임,
## 원형 도/요 배지, 이름 양옆 깃털선, 육각 베벨 금빛 CTA, 다크네이비+금테 탭/알약을
## 전부 벡터로 그린다(사진 판 위에 가짜 글자를 얹지 않으므로 어떤 해상도에서도 선명하다).
## 모든 그리기는 기준 크기(base) 대비 배율 k로 계산해, 화면 배율이 달라져도 같은 모양이 된다.
const T=preload("res://scripts/ui/lobby_theme.gd")
const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const GOLD=Color(0.85,0.72,0.47)
const BRASS=Color(0.98,0.86,0.56)

## 모서리를 45°로 자른 팔각형. 상점의 탭·버튼·카드가 같은 실루엣을 쓴다.
static func chamfer(box: Rect2,c: float) -> PackedVector2Array:
	var k:=maxf(0.0,minf(c,minf(box.size.x,box.size.y)*.5))
	return PackedVector2Array([
		box.position+Vector2(k,0),Vector2(box.end.x-k,box.position.y),
		Vector2(box.end.x,box.position.y+k),box.end-Vector2(0,k),
		Vector2(box.end.x-k,box.end.y),Vector2(box.position.x+k,box.end.y),
		Vector2(box.position.x,box.end.y-k),box.position+Vector2(0,k)])

## 팔각형 안쪽에 위→아래 세로 그라데이션을 채운다. StyleBoxFlat은 모서리 절단을 못 해서
## 줄 단위로 칠한다. inset은 각 줄의 좌우 여백(=비스듬한 모서리).
static func chamfer_gradient(ci: CanvasItem,box: Rect2,c: float,top: Color,bottom: Color,steps: int=30) -> void:
	if box.size.x<=1.0 or box.size.y<=1.0:return
	var cut:=maxf(0.0,minf(c,minf(box.size.x,box.size.y)*.5))
	for i in range(steps):
		var y0:=box.position.y+box.size.y*float(i)/float(steps)
		var y1:=box.position.y+box.size.y*float(i+1)/float(steps)
		var color:=top.lerp(bottom,(float(i)+.5)/float(steps))
		var inset:=0.0
		if cut>0.01:
			if y0<box.position.y+cut:
				var dy:=cut-(y0-box.position.y)
				inset=cut-sqrt(maxf(0.0,cut*cut-dy*dy))
			elif y1>box.end.y-cut:
				var dy2:=y1-(box.end.y-cut)
				inset=cut-sqrt(maxf(0.0,cut*cut-dy2*dy2))
		ci.draw_rect(Rect2(Vector2(box.position.x+inset,y0),Vector2(maxf(.6,box.size.x-inset*2.0),maxf(.6,y1-y0))),color)

static func stroke(ci: CanvasItem,points: PackedVector2Array,color: Color,width: float) -> void:
	if points.size()<2:return
	var loop:=points.duplicate()
	loop.append(points[0])
	ci.draw_polyline(loop,color,width,true)

static func text_width(font: Font,text_value: String,extent: float) -> float:
	return font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent)))).x

## 세로 가운데 정렬 기준선. Label과 같은 위치에 글자가 오도록.
static func baseline(font: Font,extent: float,box: Rect2) -> Vector2:
	var ascent:=font.get_ascent(maxi(1,int(round(extent))))
	var descent:=font.get_descent(maxi(1,int(round(extent))))
	return Vector2(box.position.x,box.position.y+box.size.y*.5+(ascent-descent)*.5)

## 크림빛 금화. 카드 가격·재화 알약에 쓴다.
static func coin(ci: CanvasItem,box: Rect2) -> void:
	var r:=minf(box.size.x,box.size.y)*.5
	var c:=box.get_center()
	for i in range(3):
		ci.draw_circle(c,r*(1.0+float(i)*.16),Color(1.0,.82,.36,.10-float(i)*.03))
	ci.draw_circle(c,r,Color(0.55,.36,.08,1))
	ci.draw_circle(c,r*.92,Color(0.93,.75,.32,1))
	ci.draw_circle(c,r*.80,Color(1.0,.90,.58,1))
	ci.draw_arc(c,r*.80,0,TAU,24,Color(.58,.38,.09,.85),maxf(1.0,r*.10),true)
	# 가운데 작은 마름 표식(동전의 전(錢) 자리)
	var mark:=r*.30
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-mark),c+Vector2(mark*.75,0),c+Vector2(0,mark),c+Vector2(-mark*.75,0)]),Color(.55,.35,.07,.9))

## 카드·알약에 붙는 금화 노드.
class Coin extends Control:
	var base:=15.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<3.0:return
		var r:=minf(size.x,size.y)*.5
		var c:=size*.5
		for i in range(3):
			draw_circle(c,r*(1.0+float(i)*.16),Color(1.0,.82,.36,.10-float(i)*.03))
		draw_circle(c,r,Color(0.55,.36,.08,1))
		draw_circle(c,r*.92,Color(0.93,.75,.32,1))
		draw_circle(c,r*.80,Color(1.0,.90,.58,1))
		draw_arc(c,r*.80,0,TAU,24,Color(.58,.38,.09,.85),maxf(1.0,r*.10),true)
		var mark:=r*.30
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-mark),c+Vector2(mark*.75,0),c+Vector2(0,mark),c+Vector2(-mark*.75,0)]),Color(.55,.35,.07,.9))

# ---------------------------------------------------------------- 카드 프레임
## 황동 베벨 카드 테두리. 선택 카드는 바깥으로 금빛 광이 번진다.
class CardFrame extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var edge:=Color(0.88,0.75,0.50,0.62)
	var lit:=false
	var base:=Vector2(204,244)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<10.0 or size.y<10.0:return
		var k:=maxf(.2,size.y/base.y)
		var box:=Rect2(Vector2.ZERO,size)
		var r:=9.0*k
		if lit:
			for i in range(5):
				var grow:=1.6*k+float(i)*2.4*k
				T.rounded_outline(self,box.grow(grow),Color(1,.84,.48,(.22-float(i)*.042)),r+grow,2.2*k)
		T.rounded_outline(self,box,Color(0,0,0,.62),r,2.8*k)
		T.rounded_outline(self,box.grow(-1.2*k),edge,r-1.2*k,1.5*k)
		T.rounded_outline(self,box.grow(-3.4*k),Color(edge.r,edge.g,edge.b,.42 if lit else .20),r-3.4*k,1.0*k)
		# 위쪽 금속 광, 아래쪽 그늘 → 판이 오목하게 들어가 보인다.
		draw_line(Vector2(r,1.9*k),Vector2(size.x-r,1.9*k),Color(1,.96,.85,.20 if lit else .10),1.3*k,true)
		draw_line(Vector2(r,size.y-1.9*k),Vector2(size.x-r,size.y-1.9*k),Color(0,0,0,.42),1.5*k,true)
		var arm:=minf(30.0*k,minf(size.x,size.y)*.15)
		var brass:=Color(edge.r,edge.g,edge.b,minf(1.0,edge.a+.32))
		_corner(Vector2(2.6*k,2.6*k),Vector2(1,1),arm,k,brass)
		_corner(Vector2(size.x-2.6*k,2.6*k),Vector2(-1,1),arm,k,brass)
		_corner(Vector2(2.6*k,size.y-2.6*k),Vector2(1,-1),arm,k,brass)
		_corner(Vector2(size.x-2.6*k,size.y-2.6*k),Vector2(-1,-1),arm,k,brass)
	## 모서리 황동 장식: 끝을 45°로 깎은 선 + 말림 + 작은 마름.
	func _corner(point: Vector2,dir: Vector2,arm: float,k: float,color: Color) -> void:
		T.corner_flourish(self,point,dir,arm,color)
		draw_line(point+Vector2(dir.x*10.0*k,0),point+Vector2(0,dir.y*10.0*k),Color(color.r,color.g,color.b,color.a*.75),1.3*k,true)
		draw_line(point+Vector2(dir.x*arm*.55,dir.y*3.4*k),point+Vector2(dir.x*arm*.55,0),Color(color.r,color.g,color.b,color.a*.30),1.0*k,true)

# ---------------------------------------------------------------- 도/요 배지
class TeamBadge extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var letter:="도"
	var daoist:=true
	var base:=27.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var k:=maxf(.2,size.y/base)
		var r:=minf(size.x,size.y)*.5
		var c:=size*.5
		if daoist:
			draw_circle(c,r,Color(.42,.29,.06,.95))
			draw_circle(c,r*.93,Color(.97,.90,.71,1))
			draw_circle(c,r*.86,Color(1.0,.955,.82,1))
			draw_arc(c,r*.99,0,TAU,32,Color(1,.93,.70,.95),1.5*k,true)
		else:
			draw_circle(c,r,Color(.10,.05,.18,.95))
			draw_circle(c,r*.93,Color(.45,.28,.72,1))
			draw_circle(c,r*.86,Color(.56,.38,.86,1))
			draw_arc(c,r*.99,0,TAU,32,Color(.80,.64,1,.9),1.5*k,true)
		var ink:=Color(.24,.15,.03,1) if daoist else Color(1,.97,1,1)
		var extent:=15.0*k
		var width:=ShopOrnaments.text_width(ShopOrnaments.TITLE_FONT,letter,extent)
		var at:=ShopOrnaments.baseline(ShopOrnaments.TITLE_FONT,extent,Rect2(Vector2(c.x-width*.5,c.y-r),Vector2(width,r*2.0)))
		draw_string(ShopOrnaments.TITLE_FONT,at,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),ink)
		draw_string_outline(ShopOrnaments.TITLE_FONT,at,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),2,Color(0,0,0,.35))

# ---------------------------------------------------------------- 제목 문장
## 상점 제목 앞의 금테 메달(연꽃). 시안의 제목 왼쪽 문장을 그대로 옮긴다.
class Medallion extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const Glyphs=preload("res://scripts/ui/room_glyphs.gd")
	var glyph:="lotus"
	var accent:=Color(0.85,0.72,0.47)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.y<6.0:return
		var k:=size.y/40.0
		var r:=minf(size.x,size.y)*.5
		var c:=size*.5
		for i in range(3):
			draw_circle(c,r*(1.0+float(i)*.13),Color(accent.r,accent.g,accent.b,.10-float(i)*.025))
		draw_circle(c,r*.98,Color(.06,.045,.03,.92))
		draw_circle(c,r*.90,Color(.13,.10,.06,.95))
		draw_arc(c,r*.96,0,TAU,32,Color(accent.r,accent.g,accent.b,.92),1.8*k,true)
		draw_arc(c,r*.80,0,TAU,32,Color(accent.r,accent.g,accent.b,.35),1.0*k,true)
		Glyphs.draw_glyph(self,glyph,Rect2(c-Vector2(r*.52,r*.52),Vector2(r*1.04,r*1.04)),Color(accent.r,accent.g,accent.b,1.0),1.7*k,0.5)

# ---------------------------------------------------------------- 이름 양옆 깃털선
class NameWings extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var text_width:=60.0
	var color:=Color(0.85,0.72,0.47,.9)
	var base:=Vector2(340,38)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var k:=maxf(.2,size.y/base.y)
		var cy:=size.y*.5
		var cx:=size.x*.5
		var half:=text_width*k*.5
		for side: float in [-1.0,1.0]:
			var inner:=cx+side*(half+8.0*k)
			var outer:=minf(cx+side*(size.x*.5-6.0*k),cx+side*(half+78.0*k))
			draw_line(Vector2(inner,cy),Vector2(outer,cy),Color(color.r,color.g,color.b,color.a*.62),1.1*k,true)
			T.diamond(self,Vector2(inner+side*10.0*k,cy),3.6*k,color)
			T.diamond(self,Vector2(inner+side*2.2*k,cy),2.0*k,Color(color.r,color.g,color.b,color.a*.75))
			draw_arc(Vector2(outer,cy),4.6*k,0,TAU,14,Color(color.r,color.g,color.b,color.a*.55),1.0*k,true)
			draw_circle(Vector2(outer,cy),1.5*k,Color(color.r,color.g,color.b,color.a*.85))

# ---------------------------------------------------------------- 미리보기 제목 장식
## '◇ 달빛 미리보기 ◇' — 글자 양옆 다이아와 패널 모서리까지 이어지는 가는 선.
class TitleMark extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var text_width:=0.0
	var color:=Color(0.85,0.72,0.47,.75)
	var base:=Vector2(340,26)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var k:=maxf(.2,size.y/base.y)
		var cy:=size.y*.5
		var cx:=size.x*.5
		var half:=text_width*k*.5
		for side: float in [-1.0,1.0]:
			var inner:=cx+side*(half+10.0*k)
			var outer:=cx+side*(size.x*.5-12.0*k)
			draw_line(Vector2(inner+side*7.0*k,cy),Vector2(outer,cy),Color(color.r,color.g,color.b,color.a*.50),1.0*k,true)
			T.diamond(self,Vector2(inner,cy),3.4*k,color)
			draw_arc(Vector2(outer,cy),3.4*k,0,TAU,12,Color(color.r,color.g,color.b,color.a*.55),1.0*k,true)

## 가운데 마름이 있는 가는 구분선.
class PanelRule extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(0.85,0.72,0.47,.28)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var cy:=size.y*.5
		draw_line(Vector2(0,cy),Vector2(size.x,cy),color,1.0,true)
		var half:=size.x*.5
		var fade:=Color(color.r,color.g,color.b,color.a*1.6)
		T.diamond(self,Vector2(half,cy),3.2,Color(minf(1.0,fade.a),fade.g*.94,fade.b*.86,.85))
		T.diamond(self,Vector2(14,cy),2.0,color)
		T.diamond(self,Vector2(size.x-14,cy),2.0,color)

# ---------------------------------------------------------------- 대표 능력 아이콘
## 보랏빛 룬이 빛나는 원형 메달. 미리보기 '대표 능력' 줄 왼쪽에 붙는다.
class RuneSeal extends Control:
	var accent:=Color(.72,.50,1.0)
	var base:=30.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var k:=maxf(.2,size.y/base)
		var r:=minf(size.x,size.y)*.5
		var c:=size*.5
		for i in range(4):
			draw_circle(c,r*(1.0+float(i)*.22),Color(accent.r,accent.g,accent.b,.10-float(i)*.022))
		draw_circle(c,r,Color(.07,.04,.14,1))
		draw_circle(c,r*.94,Color(.16,.09,.30,1))
		draw_arc(c,r*.70,0,TAU,28,Color(accent.r,accent.g,accent.b,.55),1.4*k,true)
		# 룬: 위로 뻗은 세 갈래
		var w:=r*.52
		var h:=r*.66
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-h),c+Vector2(w*.62,h*.42),c+Vector2(-w*.62,h*.42)]),Color(accent.r,accent.g,accent.b,.85))
		draw_line(c+Vector2(0,-h*.35),c+Vector2(0,h*.42),Color(1,1,1,.65),1.2*k,true)
		draw_line(c+Vector2(-w*.32,h*.10),c+Vector2(w*.32,h*.10),Color(1,1,1,.55),1.0*k,true)
		draw_arc(c,r*.99,0,TAU,32,Color(0.93,.76,.44,.95),1.6*k,true)

# ---------------------------------------------------------------- 알약(칩)
## 아이콘 + 글자가 든 다크네이비 알약. 재화·진영·역할 배지가 함께 쓴다.
class Pill extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var text_value:=""
	var kind:="none"
	var accent:=Color(0.85,0.72,0.47)
	var ink:=Color(0.97,0.94,0.87)
	var font_size:=15.0
	var glow:=false
	var base:=28.0
	## 글자 폭 + 아이콘 + 여백. 배치 전에 알약 폭을 정할 때 쓴다(디자인 좌표).
	static func measure(kind_value: String,text_value: String,font_size: float) -> float:
		var width:=ShopOrnaments.text_width(ShopOrnaments.FONT,text_value,font_size)+24.0
		if kind_value!="none":width+=22.0
		return width
	static func icon_width(kind_value: String) -> float:
		return 18.0 if kind_value!="none" else 0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var k:=maxf(.2,size.y/base)
		var box:=Rect2(Vector2.ZERO,size)
		var r:=box.size.y*.5
		if glow:
			for i in range(3):
				var grow:=1.5*k+float(i)*1.8*k
				T.rounded_outline(self,box.grow(grow),Color(accent.r,accent.g,accent.b,.16-float(i)*.04),r+grow,1.6*k)
		T.gradient_rounded(self,box,Color(.10,.10,.19,.96),Color(.035,.035,.075,.97),r)
		if kind!="none":
			T.gradient_rounded(self,Rect2(Vector2(0,0),Vector2(box.size.x,box.size.y*.5)),Color(accent.r,accent.g,accent.b,.14),Color(accent.r,accent.g,accent.b,0.0),r)
		T.rounded_outline(self,box,Color(0,0,0,.55),r,1.8*k)
		T.rounded_outline(self,box.grow(-1.1*k),Color(accent.r,accent.g,accent.b,.85),r-1.1*k,1.2*k)
		draw_line(Vector2(r*.9,1.4*k),Vector2(box.size.x-r*.9,1.4*k),Color(1,.97,.88,.16),1.0*k,true)
		var extent:=font_size*k
		var text:=text_value
		var width:=ShopOrnaments.text_width(ShopOrnaments.FONT,text,extent)
		var icon_w:=icon_width(kind)*k
		var total:=width+icon_w
		var start:=Vector2((box.size.x-total)*.5,0)
		if kind!="none":
			var icon_box:=Rect2(Vector2(start.x,box.size.y*.5-icon_w*.5),Vector2(icon_w,icon_w))
			_draw_icon(icon_box,k)
			start.x+=icon_w
		var at:=ShopOrnaments.baseline(ShopOrnaments.FONT,extent,Rect2(Vector2(start.x,0),Vector2(width,box.size.y)))
		draw_string(ShopOrnaments.FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),ink)
	func _draw_icon(rect: Rect2,k: float) -> void:
		match kind:
			"coin":
				ShopOrnaments.coin(self,rect)
			"lotus":
				Glyphs.draw_glyph(self,"lotus",rect,accent,1.7*k,0.35)
			"gem":
				var c:=rect.get_center()
				var r:=rect.size.x*.5
				draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.82,-r*.18),c+Vector2(0,r),c+Vector2(-r*.82,-r*.18)]),Color(accent.r,accent.g,accent.b,.95))
				draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.82,-r*.18),c+Vector2(0,-r*.06),c+Vector2(-r*.82,-r*.18)]),Color(1,1,1,.35))
				draw_polyline(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.82,-r*.18),c+Vector2(0,r),c+Vector2(-r*.82,-r*.18),c+Vector2(0,-r)]),Color(1,.95,1,.55),1.0*k,true)
			"check":
				Glyphs.draw_glyph(self,"check",rect,accent,1.8*k,0.2)

# ---------------------------------------------------------------- 탭
## 왼쪽 탭: 다크네이비 팔각 판 + 금테. 선택하면 금빛 광과 함께 안쪽이 밝아진다.
class TabPlate extends "res://scripts/ui/metal_button.gd":
	const TH=preload("res://scripts/ui/lobby_theme.gd")
	var chosen:=false
	var base:=Vector2(160,62)
	func _ready() -> void:
		super()
		child_entered_tree.connect(func(node: Node)->void:
			if String(node.name).begins_with("PressGlow"):(node as CanvasItem).visible=false)
	func _draw() -> void:
		if size.x<8.0 or size.y<8.0:return
		var k:=maxf(.2,size.y/base.y)
		var box:=Rect2(Vector2.ZERO,size)
		var cut:=9.0*k
		if chosen:
			for i in range(4):
				var grow:=1.6*k+float(i)*2.0*k
				ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box.grow(grow),cut+grow),Color(1,.84,.48,.20-float(i)*.04),2.0*k)
		ShopOrnaments.chamfer_gradient(self,box,cut,Color(.175,.155,.20,.97) if chosen else Color(.085,.10,.19,.96),Color(.055,.045,.055,.98) if chosen else Color(.020,.026,.055,.97))
		if chosen:
			ShopOrnaments.chamfer_gradient(self,box.grow(-2.0*k),cut,Color(1,.86,.58,.12),Color(1,.86,.58,0.0),12)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box,cut),Color(0,0,0,.55),2.2*k)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box.grow(-1.2*k),cut-1.2*k),Color(accent.r,accent.g,accent.b,.92 if chosen else .48),1.6*k)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box.grow(-4.0*k),cut-4.0*k),Color(accent.r,accent.g,accent.b,.30 if chosen else .14),1.0*k)
		# 양쪽 가운데 작은 마름
		TH.diamond(self,Vector2(box.size.x-8.0*k,box.size.y*.5),2.6*k,Color(accent.r,accent.g,accent.b,.85))
		TH.diamond(self,Vector2(8.0*k,box.size.y*.5),2.6*k,Color(accent.r,accent.g,accent.b,.55))
		_draw_plate_content(box,k)
	func _draw_plate_content(box: Rect2,k: float) -> void:
		var caption:=text
		var extent:=font_size*k
		var icon_size:=minf(box.size.y*.44,24.0*k)
		var width:=ShopOrnaments.text_width(FONT,caption,extent)
		var has_icon:=glyph!=""
		var total:=width+(icon_size+10.0*k if has_icon else 0.0)
		var start:=Vector2((box.size.x-total)*.5,0)
		var ink:=Color("ffeec2") if chosen else Color("f2e8d2")
		if has_icon:
			var icon_box:=Rect2(Vector2(start.x,box.size.y*.5-icon_size*.5),Vector2(icon_size,icon_size))
			Glyphs.draw_glyph(self,glyph,icon_box,Color(accent.r,accent.g,accent.b,1.0) if chosen else Color(accent.r,accent.g,accent.b,.92),1.9*k,0.5 if chosen else 0.15)
			start.x+=icon_size+10.0*k
		var at:=ShopOrnaments.baseline(FONT,extent,Rect2(Vector2(start.x,0),Vector2(width,box.size.y)))
		draw_string_outline(FONT,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),4,Color(0,0,0,.40))
		draw_string(FONT,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),ink)

# ---------------------------------------------------------------- 장착하기 CTA
## 시안의 육각 베벨 금빛 버튼: 위가 밝고 아래로 가라앉는 금판 + 안쪽 베벨 + 뾰족한 양끝.
class HexButton extends "res://scripts/ui/metal_button.gd":
	const TH=preload("res://scripts/ui/lobby_theme.gd")
	var base:=Vector2(368,52)
	var icon_kind:="hanger"
	func _ready() -> void:
		super()
		child_entered_tree.connect(func(node: Node)->void:
			if String(node.name).begins_with("PressGlow"):(node as CanvasItem).visible=false)
	func _draw() -> void:
		if size.x<12.0 or size.y<10.0:return
		var k:=maxf(.2,size.y/base.y)
		var box:=Rect2(Vector2.ZERO,size)
		var off:=disabled
		var cut:=11.0*k
		var dim:=0.55 if off else 1.0
		var lift:=lit*0.05
		if not off:
			for i in range(6):
				var grow:=1.8*k+float(i)*2.6*k
				ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box.grow(grow),cut+grow),Color(1,.84,.46,(.16-float(i)*.022)*(dim+.4*lit)),2.6*k)
		# 바깥 얇은 금테(양끝이 뾰족한 육각 실루엣)
		var tip:=9.0*k
		var outer:=PackedVector2Array([
			Vector2(0,box.size.y*.5),Vector2(tip,tip),Vector2(box.size.x*.5,1.4*k),Vector2(box.size.x-tip,tip),
			Vector2(box.size.x,box.size.y*.5),Vector2(box.size.x-tip,box.size.y-tip),Vector2(box.size.x*.5,box.size.y-1.4*k),Vector2(tip,box.size.y-tip)])
		ShopOrnaments.stroke(self,outer,Color(1,.87,.55,.55*dim),1.4*k)
		# 금판
		var plate:=box.grow(-5.5*k)
		ShopOrnaments.chamfer_gradient(self,plate,cut,Color(.99+lift,.92+lift,.70,.99) if not off else Color(.19,.19,.23,.97),Color(.80,.58,.22,.99) if not off else Color(.07,.07,.10,.98))
		# 안쪽 베벨(위 밝게, 아래 어둡게)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(plate.grow(-1.2*k),cut-1.2*k),Color(1,.99,.90,.55*dim),1.4*k)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(plate.grow(-2.6*k),cut-2.6*k),Color(.55,.36,.08,.30*dim),1.0*k)
		draw_line(Vector2(cut+2.0*k,plate.position.y+3.0*k),Vector2(plate.end.x-cut-2.0*k,plate.position.y+3.0*k),Color(1,1,.95,.42*dim),1.6*k,true)
		draw_line(Vector2(cut+2.0*k,plate.end.y-3.0*k),Vector2(plate.end.x-cut-2.0*k,plate.end.y-3.0*k),Color(.42,.26,.05,.35*dim),1.4*k,true)
		# 양끝 다이아
		for side: float in [-1.0,1.0]:
			TH.diamond(self,Vector2(box.size.x*.5+side*(box.size.x*.5-2.4*k),box.size.y*.5),3.4*k,Color(1,.90,.62,.85*dim))
		if press>.01:T.rounded(self,box,Color(.30,.20,.05,.14*press),cut)
		_draw_button_content(box,k,off)
	func _draw_button_content(box: Rect2,k: float,off: bool) -> void:
		var caption:=text
		var extent:=font_size*k
		var font:=TITLE_FONT if use_title_font else FONT
		var icon_size:=minf(box.size.y*.44,26.0*k)
		var width:=ShopOrnaments.text_width(font,caption,extent)
		var total:=width+icon_size+10.0*k
		var start:=Vector2((box.size.x-total)*.5,0)
		# 비활성(보유 중)일 때도 글자가 죽지 않도록 크림색 고대비를 쓴다.
		var ink:=Color(.90,.84,.70,.97) if off else Color(.20,.12,.02,1)
		var icon_box:=Rect2(Vector2(start.x,box.size.y*.5-icon_size*.5),Vector2(icon_size,icon_size))
		if icon_kind=="coin":
			ShopOrnaments.coin(self,icon_box)
		elif icon_kind=="check":
			Glyphs.draw_glyph(self,"check",icon_box,ink,maxf(1.2,2.2*k),0.0)
		else:
			_hanger(icon_box,ink,k)
		start.x+=icon_size+10.0*k
		var at:=ShopOrnaments.baseline(font,extent,Rect2(Vector2(start.x,0),Vector2(width,box.size.y)))
		draw_string_outline(font,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),2,Color(0,0,0,.7) if off else Color(1,.97,.85,.35))
		draw_string(font,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(1,int(round(extent))),ink)
	## 옷걸이 글리프(시안의 장착 아이콘).
	func _hanger(rect: Rect2,color: Color,k: float) -> void:
		var c:=rect.get_center()
		var w:=rect.size.x*.46
		var h:=rect.size.y*.42
		draw_arc(c+Vector2(0,-h*.95),w*.22,PI*.15,PI*1.95,12,color,maxf(1.2,1.6*k),true)
		draw_line(c+Vector2(0,-h*.62),c+Vector2(0,-h*.12),color,maxf(1.2,1.6*k),true)
		draw_polyline(PackedVector2Array([c+Vector2(0,-h*.12),c+Vector2(-w,h*.72),c+Vector2(w,h*.72),c+Vector2(0,-h*.12)]),color,maxf(1.2,1.7*k),true)
		draw_line(c+Vector2(-w*.78,h*.72),c+Vector2(w*.78,h*.72),color,maxf(1.2,1.7*k),true)

# ---------------------------------------------------------------- 페이지 이동
class ArrowButton extends Button:
	var left:=false
	var accent:=Color(0.85,0.72,0.47)
	var base:=38.0
	func _ready() -> void:
		focus_mode=Control.FOCUS_NONE
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x<6.0:return
		var k:=maxf(.2,size.y/base)
		var box:=Rect2(Vector2.ZERO,size)
		var cut:=8.0*k
		var dim:=0.5 if disabled else 1.0
		ShopOrnaments.chamfer_gradient(self,box,cut,Color(.12,.11,.19,.97),Color(.03,.03,.07,.98))
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box,cut),Color(0,0,0,.6),1.8*k)
		ShopOrnaments.stroke(self,ShopOrnaments.chamfer(box.grow(-1.2*k),cut-1.2*k),Color(accent.r,accent.g,accent.b,.80*dim),1.4*k)
		var c:=box.get_center()
		var w:=size.x*.14
		var dir:=-1.0 if left else 1.0
		var outer_x:=-dir*w*.62
		var apex_x:=dir*w*.62
		var pts:=PackedVector2Array([c+Vector2(outer_x,-w),c+Vector2(apex_x,0),c+Vector2(outer_x,w)])
		draw_polyline(pts,Color(accent.r,accent.g,accent.b,.92*dim),2.0*k,true)
		draw_circle(c+Vector2(outer_x,-w),1.4*k,Color(accent.r,accent.g,accent.b,.9*dim))
		draw_circle(c+Vector2(outer_x,w),1.4*k,Color(accent.r,accent.g,accent.b,.9*dim))
