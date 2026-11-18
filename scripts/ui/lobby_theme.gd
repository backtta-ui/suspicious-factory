class_name WooLobbyTheme
extends RefCounted
## 로비 하위 화면(상점·빠른 매치·업적·우편·친구·설정)이 함께 쓰는 상업 UI 기준.
## 어두운 먹색/딥네이비 판 + 금빛 모서리 장식(필리그리) + 달빛 배경 + 붓글씨 대제목.
## 화면 코드는 색·판·버튼·장식을 여기서만 가져다 쓴다.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const BG=preload("res://assets/woo/codex/codex_bg.jpg")
const VIGNETTE=preload("res://assets/woo/seowon/vignette.png")
const GLOW=preload("res://assets/woo/light.png")
const PORTRAIT_DIR="res://assets/woo/codex/"
const INK=Color("080c18")
const INK_SOFT=Color(0.035,0.045,0.085,0.92)
const PANEL=Color(0.043,0.055,0.105,0.9)
const PANEL_DEEP=Color(0.026,0.033,0.066,0.95)
const NAVY_LIGHT=Color("1b2742")
const GOLD=Color("d9b878")
const GOLD_SOFT=Color("f4e2b6")
const GOLD_DEEP=Color("a5813c")
const IVORY=Color("f6efdf")
const MUTED=Color("b6c0d6")
const VIOLET=Color("8b6bd6")
const DAO=Color("f0d79b")
const YOKAI=Color("cfa9ff")
const CRIMSON=Color("c0564f")
const GOLD_A45=Color(0.851,0.722,0.471,0.45)
const GOLD_A70=Color(0.851,0.722,0.471,0.7)
const GOLD_A32=Color(0.851,0.722,0.471,0.32)
const DESIGN_HEIGHT=720.0
const MARGIN=26.0

static func gold(alpha: float=1.0,base: Color=GOLD) -> Color:
	return Color(base.r,base.g,base.b,alpha)

## 먹색 반투명 판. 금빛 테두리와 은은한 외곽 광을 함께 준다.
static func panel_box(fill: Color=PANEL,radius: int=12,border: Color=GOLD_A45,width: int=1,glow: Color=Color(0,0,0,0),glow_size: int=0) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=fill
	box.border_color=border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left=0;box.content_margin_right=0;box.content_margin_top=0;box.content_margin_bottom=0
	if glow_size>0:
		box.shadow_color=glow
		box.shadow_size=glow_size
		box.shadow_offset=Vector2(0,2)
	return box

## 선택된 항목의 금빛 글로우 판.
static func lit_box(fill: Color=Color(0.24,0.17,0.07,0.92),radius: int=12) -> StyleBoxFlat:
	return panel_box(fill,radius,gold(.98),2,gold(.5),18)

## 상점·친구 화면 공통 버튼. primary는 금빛으로 채운 주 동작 하나에만 쓴다.
static func button_box(state: String,primary: bool=false) -> StyleBoxFlat:
	if primary:
		var fill:=Color("e6c684")
		if state in ["pressed","hover_pressed"]:fill=Color("c9a765")
		elif state=="hover":fill=Color("f2d99b")
		elif state=="disabled":fill=Color(0.10,0.09,0.075,0.92)
		return panel_box(fill,10,Color("fff0cc") if state!="disabled" else gold(.45),1,gold(.45) if state!="disabled" else Color(0,0,0,0),14 if state!="disabled" else 0)
	var fill:=Color(0.07,0.085,0.15,0.9)
	if state in ["pressed","hover_pressed"]:fill=Color(0.15,0.13,0.2,0.96)
	elif state=="hover":fill=Color(0.11,0.12,0.2,0.94)
	elif state=="disabled":fill=Color(0.05,0.055,0.09,0.7)
	return panel_box(fill,10,gold(.7 if state!="disabled" else .25),1,gold(.22) if state!="disabled" else Color(0,0,0,0),10 if state!="disabled" else 0)

## 값 표시용 알약. 글자가 테두리에 붙지 않도록 안쪽 여백을 둔다.
static func pill_box(fill: Color=Color(0.02,0.025,0.06,0.62),radius: int=15,border: Color=Color(0.851,0.722,0.471,0.34)) -> StyleBoxFlat:
	var box:=panel_box(fill,radius,border,1)
	box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=3;box.content_margin_bottom=3
	return box

## 탭/작은 칩.
static func chip_box(active: bool,accent: Color=GOLD) -> StyleBoxFlat:
	if active:return panel_box(Color(accent.r,accent.g,accent.b,.17),18,Color(accent.r,accent.g,accent.b,.95),1,Color(accent.r,accent.g,accent.b,.35),14)
	return panel_box(Color(0.05,0.06,0.12,0.82),18,Color(accent.r,accent.g,accent.b,.32),1)

## 빈 칸 안내용 점선 테두리.
static func dashed_box(fill: Color=Color(0.04,0.05,0.1,0.6),dash: Color=GOLD_A32,radius: int=12) -> StyleBoxFlat:
	return panel_box(fill,radius,dash,1)

# ---------------------------------------------------------------- 그리기 도구
## 둥근 사각 채우기(그리기 노드 위에서 직접 호출).
static func rounded(ci: CanvasItem,rect: Rect2,color: Color,radius: float) -> void:
	var r:=maxf(0.0,minf(radius,minf(rect.size.x,rect.size.y)*.5))
	if r<=0.01:
		ci.draw_rect(rect,color)
		return
	ci.draw_rect(Rect2(rect.position+Vector2(r,0),rect.size-Vector2(r*2,0)),color)
	ci.draw_rect(Rect2(rect.position+Vector2(0,r),rect.size-Vector2(0,r*2)),color)
	for corner in [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),Vector2(rect.position.x+r,rect.end.y-r),rect.end-Vector2(r,r)]:
		ci.draw_circle(corner,r,color)

static func diamond(ci: CanvasItem,center: Vector2,radius: float,color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius*.8,0),center+Vector2(0,radius),center+Vector2(-radius*.8,0)]),color)

static func rule(ci: CanvasItem,from: Vector2,to: Vector2,color: Color=GOLD_A32,width: float=1.0) -> void:
	ci.draw_line(from,to,color,width,true)

## 금빛 모서리 장식 한 곳. dir은 판 안쪽을 향하는 단위 벡터다.
static func corner_flourish(ci: CanvasItem,point: Vector2,dir: Vector2,length: float=30.0,color: Color=GOLD_A70) -> void:
	var thin:=Color(color.r,color.g,color.b,color.a*.42)
	ci.draw_line(point,point+Vector2(dir.x*length,0),color,1.8,true)
	ci.draw_line(point,point+Vector2(0,dir.y*length),color,1.8,true)
	ci.draw_line(point+Vector2(dir.x*6.0,dir.y*5.0),point+Vector2(dir.x*length*.62,dir.y*5.0),thin,1.0,true)
	ci.draw_line(point+Vector2(dir.x*5.0,dir.y*6.0),point+Vector2(dir.x*5.0,dir.y*length*.62),thin,1.0,true)
	# 팔 끝의 말림 장식
	ci.draw_arc(point+Vector2(dir.x*length,dir.y*5.0),4.6,0,TAU,12,Color(color.r,color.g,color.b,color.a*.8),1.1,true)
	ci.draw_arc(point+Vector2(dir.x*5.0,dir.y*length),4.6,0,TAU,12,Color(color.r,color.g,color.b,color.a*.8),1.1,true)
	ci.draw_circle(point+Vector2(dir.x*length,dir.y*10.0),1.5,color)
	ci.draw_circle(point+Vector2(dir.x*10.0,dir.y*length),1.5,color)
	diamond(ci,point+Vector2(dir.x*2.2,dir.y*2.2),3.2,color)

## 판 전체 테두리 + 네 모서리 장식.
static func frame(ci: CanvasItem,rect: Rect2,color: Color=GOLD_A70,arm: float=26.0,inset: float=0.0) -> void:
	var box:=rect.grow(-inset)
	ci.draw_rect(box,Color(color.r,color.g,color.b,color.a*.35),false,1.0)
	for spec in [[box.position,Vector2(1,1)],[Vector2(box.end.x,box.position.y),Vector2(-1,1)],[Vector2(box.position.x,box.end.y),Vector2(1,-1)],[box.end,Vector2(-1,-1)]]:
		corner_flourish(ci,spec[0],spec[1],arm,color)

## 제목 아래 장식선: 양끝 말림 + 가운데 다이아몬드.
static func title_flourish(ci: CanvasItem,from: Vector2,to: Vector2,color: Color=GOLD_A70) -> void:
	rule(ci,from,to,color,1.2)
	var middle:=(from+to)*.5
	diamond(ci,middle,4.0,color)
	for side in [from,to]:
		var inward:=7.0 if side==from else -7.0
		ci.draw_arc(side+Vector2(inward,0),5.4,0,TAU,12,Color(color.r,color.g,color.b,.5),1.0,true)

## 위쪽이 밝고 아래로 사라지는 세로 페이드 텍스처.
static func fade_texture(start: Color,end: Color) -> GradientTexture2D:
	var gradient:=Gradient.new()
	gradient.set_color(0,start);gradient.set_color(1,end)
	var texture:=GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill_from=Vector2(0,0);texture.fill_to=Vector2(0,1)
	texture.width=8;texture.height=128
	return texture

## 원형으로 부드럽게 잘라 주는 초상화 셰이더. 검은 배경 원화를 판 위에 자연스럽게 얹는다.
const MASK_CODE="""
shader_type canvas_item;
uniform float focus_y = 0.46;
uniform float radius = 0.47;
uniform float feather = 0.10;
uniform vec4 tint : source_color = vec4(1.0,1.0,1.0,1.0);
void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5, focus_y));
	art.a *= smoothstep(radius + feather, radius - feather, d);
	art.rgb *= tint.rgb;
	COLOR = art;
}
"""

static func mask_material(focus_y: float=0.46,radius: float=0.47,feather: float=0.10,tint: Color=Color.WHITE) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code=MASK_CODE
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("focus_y",focus_y)
	material.set_shader_parameter("radius",radius)
	material.set_shader_parameter("feather",feather)
	material.set_shader_parameter("tint",tint)
	return material

## 대기실(친구 방)이 함께 쓰는 황동·보랏빛·옥색. 기존 화면 색은 건드리지 않고 더한다.
const BRASS=Color("c9a25e")
const BRASS_LIGHT=Color("f6e2ae")
const INK_DEEP=Color(0.024,0.027,0.052,0.94)
const VIOLET_DEEP=Color("241a3c")
const VIOLET_MID=Color("3a2b60")
const JADE=Color("74d69e")
const JADE_DEEP=Color("123a24")
const STEEL=Color("8c93a8")

## 둥근 사각형의 닫힌 외곽선 경로(그리기용).
static func rounded_points(rect: Rect2,radius: float) -> PackedVector2Array:
	var r:=maxf(0.0,minf(radius,minf(rect.size.x,rect.size.y)*.5))
	var points:=PackedVector2Array()
	var corners: Array=[[rect.position+Vector2(r,r),PI,PI*1.5],[Vector2(rect.end.x-r,rect.position.y+r),PI*1.5,TAU],[rect.end-Vector2(r,r),0.0,PI*.5],[Vector2(rect.position.x+r,rect.end.y-r),PI*.5,PI]]
	for corner in corners:
		var center: Vector2=corner[0]
		for step in range(7):
			var angle:=float(corner[1])+(float(corner[2])-float(corner[1]))*step/6.0
			points.append(center+Vector2.from_angle(angle)*r)
	return points

## 둥근 사각형 테두리 한 겹.
static func rounded_outline(ci: CanvasItem,rect: Rect2,color: Color,radius: float,width: float=1.0) -> void:
	if rect.size.x<=1.0 or rect.size.y<=1.0:return
	var points:=rounded_points(rect,radius)
	points.append(points[0])
	ci.draw_polyline(points,color,width,true)

## 위에서 아래로 흐르는 둥근 사각 그라데이션. StyleBoxFlat이 못 하는 세로 결을 픽셀 줄로 그린다.
static func gradient_rounded(ci: CanvasItem,rect: Rect2,top: Color,bottom: Color,radius: float,steps: int=0) -> void:
	if rect.size.x<=1.0 or rect.size.y<=1.0:return
	var r:=maxf(0.0,minf(radius,minf(rect.size.x,rect.size.y)*.5))
	var rows:=steps if steps>0 else int(clampf(rect.size.y*.55,18.0,96.0))
	for i in range(rows):
		var y0:=rect.position.y+rect.size.y*float(i)/float(rows)
		var y1:=rect.position.y+rect.size.y*float(i+1)/float(rows)
		var color:=top.lerp(bottom,(float(i)+.5)/float(rows))
		var inset:=0.0
		if y0<rect.position.y+r:
			var dy:=r-(y0-rect.position.y)-.5
			inset=r-sqrt(maxf(0.0,r*r-dy*dy))
		elif y1>rect.end.y-r:
			var dy:=r-(rect.end.y-y1)-.5
			inset=r-sqrt(maxf(0.0,r*r-dy*dy))
		ci.draw_rect(Rect2(Vector2(rect.position.x+inset,y0),Vector2(rect.size.x-inset*2.0,maxf(.6,y1-y0))),color)

## 판 뒤로 번지는 부드러운 빛. 여러 겹의 둥근 테두리로 만든다.
static func halo(ci: CanvasItem,rect: Rect2,color: Color,radius: float,spread: float=10.0,steps: int=5) -> void:
	for i in range(steps):
		var grow:=spread*(1.0-float(i)/float(steps))
		var alpha:=color.a*(float(i+1)/float(steps))*.30
		rounded_outline(ci,rect.grow(grow),Color(color.r,color.g,color.b,alpha),radius+grow,spread/float(steps)*1.6)

## 금빛/보랏빛 광원.
static func soft_glow(parent: Node,color: Color,rect: Rect2) -> TextureRect:
	var node:=TextureRect.new()
	node.texture=GLOW
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_SCALE
	node.modulate=color
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position=rect.position;node.size=rect.size
	return node
