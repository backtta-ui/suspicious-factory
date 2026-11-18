extends RefCounted
## 로비 하위 화면이 공유하는 상업용 조선 다크 판타지 그림 요소.
## 전부 그리기 노드(Control._draw)로 그려서 해상도·비율과 무관하게 같은 톤을 유지한다.

## 은은한 한옥 창살 문양(전체 화면 위에 아주 옅게 깔아 질감을 준다).
class Lattice extends Control:
	var cell:=Vector2(58,58)
	var color:=Color(0.85,0.72,0.47,0.055)
	var inset:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var x:=inset-cell.x+1.0
		while x<size.x-inset:
			draw_line(Vector2(x,inset),Vector2(x,size.y-inset),color,1.0)
			x+=cell.x
		var y:=inset-cell.y+1.0
		while y<size.y-inset:
			draw_line(Vector2(inset,y),Vector2(size.x-inset,y),color,1.0)
			y+=cell.y
		var heavy:=Color(color.r,color.g,color.b,color.a*1.5)
		var step:=cell.x*4.0
		x=inset
		while x<size.x-inset:
			draw_line(Vector2(x,inset),Vector2(x,size.y-inset),heavy,1.4)
			x+=step
		y=inset
		while y<size.y-inset:
			draw_line(Vector2(inset,y),Vector2(size.x-inset,y),heavy,1.4)
			y+=step

## 떠다니는 금빛 먼지. 아주 느리게 흐른다.
class Embers extends Control:
	var count:=26
	var speed:=7.0
	var tint:=Color(0.95,0.82,0.52,0.5)
	var time:=0.0
	var seeds: Array=[]
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		var rng:=RandomNumberGenerator.new()
		rng.seed=20261118
		for i in range(count):
			seeds.append({"x":rng.randf(),"y":rng.randf(),"r":rng.randf_range(.8,2.1),"w":rng.randf_range(.5,1.4),"p":rng.randf()*TAU})
		set_process(true)
	func _process(delta: float) -> void:
		time+=delta
		queue_redraw()
	func _draw() -> void:
		for seed in seeds:
			var y:=fposmod(float(seed.y)-time*speed*float(seed.w)/maxf(1.0,size.y),1.0)
			var x:=float(seed.x)+sin(time*.35+float(seed.p))*.02
			var alpha:=0.35+sin(time*.8+float(seed.p))*.25
			draw_circle(Vector2(x*size.x,y*size.y),float(seed.r),Color(tint.r,tint.g,tint.b,tint.a*alpha))

## 로비 하위 화면 공통 배경: 한옥 달빛 원화 + 먹색 안개 + 창살 + 금빛 액자.
class Backdrop extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var mood:=0.80
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(_rebuild)
		_rebuild()
	func _rebuild() -> void:
		if size.x<2.0:return
		for child in get_children():
			remove_child(child)
			child.queue_free()
		var image:=TextureRect.new()
		image.texture=T.BG
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.modulate=Color(mood*.92,mood*.84,mood*1.16)
		image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(image)
		image.position=Vector2.ZERO;image.size=size
		var shade:=ColorRect.new()
		shade.color=Color(0.03,0.035,0.075,0.52)
		shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(shade);shade.position=Vector2.ZERO;shade.size=size
		var warm:=TextureRect.new()
		warm.texture=T.GLOW
		warm.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		warm.stretch_mode=TextureRect.STRETCH_SCALE
		warm.modulate=Color(1.0,0.74,0.42,0.16)
		warm.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(warm)
		warm.position=Vector2(-size.x*.18,size.y*.52);warm.size=Vector2(size.x*.9,size.y*.9)
		var moon:=TextureRect.new()
		moon.texture=T.GLOW
		moon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		moon.stretch_mode=TextureRect.STRETCH_SCALE
		moon.modulate=Color(0.72,0.78,1.0,0.18)
		moon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(moon)
		moon.position=Vector2(size.x*.60,-size.y*.30);moon.size=Vector2(size.y*.95,size.y*.95)
		var lattice:=Lattice.new()
		lattice.color=Color(0.85,0.72,0.47,0.06)
		add_child(lattice);lattice.position=Vector2.ZERO;lattice.size=size
		var embers:=Embers.new()
		add_child(embers);embers.position=Vector2.ZERO;embers.size=size
		var dim:=ColorRect.new()
		dim.color=Color(0.02,0.025,0.06,0.16)
		dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(dim);dim.position=Vector2.ZERO;dim.size=size
		var vignette:=TextureRect.new()
		vignette.texture=T.VIGNETTE
		vignette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		vignette.stretch_mode=TextureRect.STRETCH_SCALE
		vignette.modulate=Color(1,1,1,0.5)
		vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(vignette);vignette.position=Vector2.ZERO;vignette.size=size
		var frame:=ScreenFrame.new()
		add_child(frame);frame.position=Vector2.ZERO;frame.size=size

## 화면 가장자리 금빛 액자와 모서리 장식.
class ScreenFrame extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(0.85,0.72,0.47,0.34)
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var box:=Rect2(Vector2(11,11),size-Vector2(22,22))
		draw_rect(box,color,false,1.0)
		draw_rect(box.grow(-3),Color(color.r,color.g,color.b,color.a*.45),false,1.0)
		for spec in [[box.position,Vector2(1,1)],[Vector2(box.end.x,box.position.y),Vector2(-1,1)],[Vector2(box.position.x,box.end.y),Vector2(1,-1)],[box.end,Vector2(-1,-1)]]:
			T.corner_flourish(self,spec[0],spec[1],42.0,Color(color.r,color.g,color.b,minf(1.0,color.a*2.2)))

## 판 위에 얹는 모서리 장식(패널 전용).
class Filigree extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(0.85,0.72,0.47,0.6)
	var arm:=22.0
	var inset:=1.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:T.frame(self,Rect2(Vector2.ZERO,size),color,arm,inset)

## 달빛 단상: 미리보기 캐릭터가 서는 돌 제단.
class Pedestal extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var glow:=Color(0.72,0.66,1.0,0.25)
	var time:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		time+=delta
		queue_redraw()
	func _draw() -> void:
		var w:=size.x
		var h:=size.y
		var cx:=w*.5
		for i in range(9):
			var k:=1.0-i/9.0
			draw_circle(Vector2(cx,h*.78),w*.44*k,Color(glow.r,glow.g,glow.b,.05*(1.0-k*.4)))
		var pulse:=0.5+sin(time*1.1)*0.5
		draw_circle(Vector2(cx,h*.8),w*.30,Color(glow.r,glow.g,glow.b,.09+pulse*.05))
		for step in [[0.62,0.32],[0.72,0.27],[0.82,0.21]]:
			var half:=w*float(step[1])
			var rect:=Rect2(cx-half,h*float(step[0]),half*2.0,h*0.10)
			T.rounded(self,rect,Color(0.12,0.13,0.21,0.96),rect.size.y*.5)
			draw_arc(Vector2(cx,rect.get_center().y),half,PI*.08,PI*.92,40,Color(0.85,0.72,0.47,.26),1.2,true)
		draw_arc(Vector2(cx,h*.74),w*.19,PI*.08,PI*.92,40,Color(0.85,0.72,0.47,.34),1.4,true)
		draw_arc(Vector2(cx,h*.74),w*.12,PI*.08,PI*.92,40,Color(0.85,0.72,0.47,.20),1.0,true)

## 빠른 매치의 달빛 부적 진법.
class TalismanCircle extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var radius:=132.0
	var phase:=0.0
	var tint:=Color(0.86,0.72,0.44,1.0)
	var violet:=Color(0.62,0.5,1.0,1.0)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		phase+=delta*.22
		queue_redraw()
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(radius,minf(size.x,size.y)*.5)
		var gold:=Color(tint.r,tint.g,tint.b)
		var purple:=Color(violet.r,violet.g,violet.b)
		# 외곽 광
		for i in range(12):
			var k:=1.0-i/12.0
			draw_circle(c,r*(1.02+k*.12),Color(purple.r,purple.g,purple.b,.012*k+.004))
		draw_arc(c,r*1.04,0,TAU,96,Color(gold.r,gold.g,gold.b,.18),7.0,true)
		draw_arc(c,r,0,TAU,96,Color(gold.r,gold.g,gold.b,.6),1.6,true)
		draw_arc(c,r*.955,0,TAU,96,Color(gold.r,gold.g,gold.b,.28),1.0,true)
		# 서로 반대로 도는 점선 고리
		var segments:=48
		for i in range(segments):
			if i%2==1:continue
			var a0:=phase+i*TAU/segments
			draw_arc(c,r*.88,a0,a0+TAU/segments*.72,6,Color(purple.r,purple.g,purple.b,.55),1.8,true)
		for i in range(segments):
			if i%2==0:continue
			var a0:=-phase*1.6+i*TAU/segments
			draw_arc(c,r*.74,a0,a0+TAU/segments*.5,6,Color(gold.r,gold.g,gold.b,.30),1.2,true)
		draw_arc(c,r*.62,0,TAU,72,Color(gold.r,gold.g,gold.b,.22),1.0,true)
		# 인장 슬롯으로 이어지는 가는 광선
		for i in range(8):
			var angle:=-PI*.5+i*TAU/8.0
			var from:=c+Vector2.from_angle(angle)*r*1.05
			var to:=c+Vector2.from_angle(angle)*r*1.24
			draw_line(from,to,Color(gold.r,gold.g,gold.b,.22),1.2,true)
			draw_circle(to,2.0,Color(gold.r,gold.g,gold.b,.45))
		# 8방위 팔괘 눈금: 짧은 막대 세 개를 방향마다 쌓는다.
		for i in range(8):
			var angle:=-PI*.5+i*TAU/8.0
			var normal:=Vector2.from_angle(angle+PI*.5)
			for bar in range(3):
				var center:=c+Vector2.from_angle(angle)*r*(.66+bar*.038)
				var half:=r*(.05 if (i+bar)%3!=0 else .028)
				if (i+bar)%5==0:
					# 끊긴 획(음효)
					draw_line(center-normal*half,center-normal*half*.3,Color(gold.r,gold.g,gold.b,.55),1.6,true)
					draw_line(center+normal*half*.3,center+normal*half,Color(gold.r,gold.g,gold.b,.55),1.6,true)
				else:
					draw_line(center-normal*half,center+normal*half,Color(gold.r,gold.g,gold.b,.55),1.6,true)
			var at:=c+Vector2.from_angle(angle)*r*.98
			draw_circle(at,2.4,Color(gold.r,gold.g,gold.b,.8))
		# 부적 판
		var talisman:=Rect2(c-Vector2(r*.15,r*.34)+Vector2(0,-r*.06),Vector2(r*.30,r*.70))
		T.rounded(self,talisman,Color(0.05,0.05,0.11,.96),5)
		draw_rect(talisman,Color(gold.r,gold.g,gold.b,.62),false,1.4)
		draw_rect(talisman.grow(-4),Color(gold.r,gold.g,gold.b,.22),false,1.0)
		draw_rect(Rect2(Vector2(talisman.position.x-6,talisman.position.y+talisman.size.y*.18),Vector2(6,talisman.size.y*.16)),Color(0.72,0.25,0.24,.9))
		draw_rect(Rect2(Vector2(talisman.end.x,talisman.position.y+talisman.size.y*.18),Vector2(6,talisman.size.y*.16)),Color(0.72,0.25,0.24,.9))
		for i in range(5):
			var y:=talisman.position.y+talisman.size.y*.14+i*talisman.size.y*.10
			var wobble:=sin(phase*2.0+i)*1.6
			var stroke:=Color(0.94,0.86,0.66,.78) if i%2==0 else Color(0.72,0.28,0.26,.8)
			draw_line(Vector2(talisman.position.x+talisman.size.x*.26,y),Vector2(talisman.end.x-talisman.size.x*.26,y+wobble),stroke,1.4,true)
		# 가운데 태극
		var tae:=talisman.position+Vector2(talisman.size.x*.5,talisman.size.y*.86)
		draw_circle(tae,r*.075,Color(0.05,0.05,0.11,1.0))
		draw_circle(tae+Vector2(0,-r*.037),r*.037,Color(gold.r,gold.g,gold.b,.85))
		draw_arc(tae,r*.075,0,TAU,32,Color(gold.r,gold.g,gold.b,.7),1.0,true)

## 8인의 원형 인장 슬롯. 채워지면 초상화가 금빛/보랏빛 고리 안에 들어온다.
class SealSlot extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var filled:=false
	var role:="daoist"
	var portrait:=""
	var index:=0
	var phase:=0.0
	var portrait_node: TextureRect
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		phase+=delta
		if filled:queue_redraw()
	func ring_color() -> Color:
		return Color(0.94,0.84,0.55,1.0) if role=="daoist" else Color(0.78,0.55,1.0,1.0)
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5-4.0
		var color:=ring_color()
		if filled:
			var pulse:=0.5+sin(phase*1.4+index)*0.5
			draw_circle(c,r+7.0,Color(color.r,color.g,color.b,.05+pulse*.05))
			draw_circle(c,r,Color(0.045,0.05,0.10,.98))
			draw_circle(c,r-2.0,Color(0.10,0.10,0.19,1.0))
			draw_arc(c,r,0,TAU,64,color,2.2,true)
			draw_arc(c,r-5.0,0,TAU,64,Color(color.r,color.g,color.b,.35),1.0,true)
			# 역할 표식(도사=태극 점, 요괴=뿔)
			var badge:=c+Vector2(0,r*.86)
			draw_circle(badge,9.2,Color(0.05,0.05,0.10,.98))
			draw_arc(badge,9.2,0,TAU,24,color,1.2,true)
			if role=="daoist":
				draw_arc(badge,4.2,0,TAU,20,color,1.6,true)
				draw_circle(badge+Vector2(0,-2.0),1.8,color)
			else:
				draw_colored_polygon(PackedVector2Array([badge+Vector2(-4.6,3.2),badge+Vector2(-1.4,-4.2),badge+Vector2(1.4,-4.2),badge+Vector2(4.6,3.2)]),color)
		else:
			draw_circle(c,r,Color(0.04,0.045,0.09,.72))
			var segments:=28
			for i in range(segments):
				if i%2==1:continue
				var a0:=phase*.5+i*TAU/segments
				draw_arc(c,r,a0,a0+TAU/segments*.8,6,Color(0.72,0.66,0.9,.28),1.4,true)
			draw_arc(c,r-6.0,0,TAU,48,Color(0.72,0.66,0.9,.12),1.0,true)
			draw_line(c+Vector2(-4,0),c+Vector2(4,0),Color(0.72,0.66,0.9,.4),1.2,true)
			draw_line(c+Vector2(0,-4),c+Vector2(0,4),Color(0.72,0.66,0.9,.4),1.2,true)
	func set_data(is_filled: bool,new_role: String,portrait_path: String) -> void:
		filled=is_filled
		role=new_role
		portrait=portrait_path
		if portrait_node!=null:
			portrait_node.queue_free()
			portrait_node=null
		if is_filled and portrait_path!="":
			var image:=TextureRect.new()
			image.texture=load(portrait_path)
			image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
			image.material=T.mask_material(.44,.46,.08)
			image.mouse_filter=Control.MOUSE_FILTER_IGNORE
			add_child(image)
			image.position=Vector2(4,4);image.size=size-Vector2(8,8)
			portrait_node=image
		queue_redraw()

## 스킨 카드용 옷감 조각. 도포 실루엣에 스킨 색을 입힌다.
class Swatch extends Control:
	var color:=Color.WHITE
	var accent:=Color(0.85,0.72,0.47,0.9)
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w:=size.x
		var h:=size.y
		var cx:=w*.5
		var top:=h*.10
		var bottom:=h*.94
		var body:=PackedVector2Array([Vector2(cx-w*.30,top+h*.06),Vector2(cx-w*.13,top),Vector2(cx+w*.13,top),Vector2(cx+w*.30,top+h*.06),
			Vector2(cx+w*.36,bottom),Vector2(cx-w*.36,bottom)])
		draw_colored_polygon(body,Color(color.r*.5,color.g*.5,color.b*.5,1.0))
		var inner:=PackedVector2Array([Vector2(cx-w*.22,top+h*.10),Vector2(cx,top+h*.02),Vector2(cx+w*.22,top+h*.10),
			Vector2(cx+w*.28,bottom-h*.02),Vector2(cx-w*.28,bottom-h*.02)])
		draw_colored_polygon(inner,color)
		draw_line(Vector2(cx-w*.20,top+h*.08),Vector2(cx-w*.02,top+h*.34),Color(0.98,0.95,0.88,.85),2.0,true)
		draw_line(Vector2(cx+w*.20,top+h*.08),Vector2(cx+w*.02,top+h*.34),Color(0.98,0.95,0.88,.85),2.0,true)
		draw_rect(Rect2(cx-w*.30,top+h*.40,w*.60,h*.055),Color(accent.r,accent.g,accent.b,.75))
		draw_circle(Vector2(cx,top+h*.427),w*.045,Color(accent.r,accent.g,accent.b,.95))
		draw_circle(Vector2(cx,top+h*.427),w*.02,Color(0.09,0.08,0.12,.9))
		for i in range(3):
			var y:=bottom-h*.10+i*h*.03
			draw_line(Vector2(cx-w*.26,y),Vector2(cx+w*.26,y),Color(accent.r,accent.g,accent.b,.28),1.0,true)
		for i in range(5):
			draw_circle(Vector2(cx-w*.18+i*w*.09,bottom-h*.20),1.5,Color(accent.r,accent.g,accent.b,.35))

## 전통 문패(친구 화면·칭호 미리보기).
class Plaque extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var wood:=Color(0.165,0.125,0.125,0.97)
	var rim:=Color(0.88,0.75,0.5,0.72)
	var cords:=true
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var top_inset:=size.y*.16 if cords else 0.0
		var board:=Rect2(Vector2(0,top_inset),size-Vector2(0,top_inset))
		if cords:
			var top:=board.position.y
			for side in [0.22,0.78]:
				var x: float=size.x*float(side)
				draw_line(Vector2(x,0),Vector2(x,top),Color(0.86,0.78,0.6,.45),1.6,true)
				draw_circle(Vector2(x,0),2.6,Color(0.86,0.78,0.6,.5))
				draw_arc(Vector2(x,top),4.0,0,TAU,12,Color(rim.r,rim.g,rim.b,.6),1.2,true)
		T.rounded(self,board,wood,7)
		# 나무결 결: 위쪽은 밝고 아래로 가라앉는 판
		T.rounded(self,Rect2(board.position+Vector2(2,2),Vector2(board.size.x-4,board.size.y*.5)),Color(wood.r*1.9,wood.g*1.8,wood.b*1.6,.6),6)
		draw_rect(board,rim,false,1.6)
		draw_rect(board.grow(-4),Color(rim.r,rim.g,rim.b,.28),false,1.0)
		for i in range(1,6):
			var x:=board.position.x+board.size.x*i/6.0
			draw_line(Vector2(x,board.position.y+6),Vector2(x,board.end.y-6),Color(0.85,0.72,0.47,.05),1.0,true)
		for i in range(5):
			var y:=board.position.y+8.0+i*(board.size.y-16.0)/4.0
			draw_line(Vector2(board.position.x+8,y),Vector2(board.end.x-8,y),Color(0.85,0.72,0.47,.06),1.0,true)
		# 판 위 은은한 광과 모서리 못
		draw_rect(Rect2(board.position+Vector2(6,6),Vector2(board.size.x-12,board.size.y*.34)),Color(0.5,0.4,0.28,.05))
		for corner in [board.position+Vector2(12,12),Vector2(board.end.x-12,board.position.y+12),Vector2(board.position.x+12,board.end.y-12),board.end-Vector2(12,12)]:
			draw_circle(corner,2.6,Color(rim.r,rim.g,rim.b,.9))

## 두루마리 마구리(위·아래 나무 축).
class Roller extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var rim:=Color(0.85,0.72,0.47,0.8)
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var h:=size.y
		var shaft:=Rect2(Vector2(8,h*.20),Vector2(size.x-16,h*.60))
		T.rounded(self,shaft,Color(0.11,0.09,0.14,.98),h*.30)
		draw_rect(Rect2(shaft.position+Vector2(6,1),Vector2(shaft.size.x-12,shaft.size.y-2)),Color(rim.r,rim.g,rim.b,.2),false,1.0)
		for x in [8.0,size.x-8.0]:
			draw_circle(Vector2(x,h*.5),h*.52,Color(0.09,0.075,0.11,1.0))
			draw_arc(Vector2(x,h*.5),h*.52,0,TAU,20,Color(rim.r,rim.g,rim.b,.6),1.2,true)
			draw_circle(Vector2(x,h*.5),h*.18,Color(rim.r,rim.g,rim.b,.45))

## 붉은 낙관(편지 봉인). 글자 대신 도장 문양을 그려 폰트 의존을 없앤다.
class Stamp extends Control:
	var color:=Color(0.72,0.25,0.24,1.0)
	var pulse:=0.0
	var glyph:=0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		if pulse>0.0:
			pulse=maxf(0.0,pulse-delta*.6)
			queue_redraw()
	func _draw() -> void:
		var r:=minf(size.x,size.y)*.5
		var c:=size*.5
		if pulse>0.0:draw_circle(c,r*(1.0+pulse*.35),Color(color.r,color.g,color.b,.18*pulse))
		draw_circle(c,r,Color(color.r,color.g,color.b,.92))
		draw_arc(c,r,0,TAU,32,Color(color.r*.62,color.g*.5,color.b*.5,.95),1.2,true)
		var ink:=Color(1,0.95,0.88,.92)
		draw_rect(Rect2(c-Vector2(r*.54,r*.54),Vector2(r*1.08,r*1.08)),Color(ink.r,ink.g,ink.b,.8),false,1.0)
		# 도장 안쪽 문양: 밭처럼 나뉜 네 칸과 점선 테두리
		draw_rect(Rect2(c-Vector2(r*.34,r*.34),Vector2(r*.68,r*.68)),ink,false,maxf(1.0,r*.07))
		draw_line(Vector2(c.x-r*.34,c.y),Vector2(c.x+r*.34,c.y),ink,r*.06,true)
		draw_line(Vector2(c.x,c.y-r*.34),Vector2(c.x,c.y+r*.34),ink,r*.06,true)
		for cell in [Vector2(-r*.17,-r*.17),Vector2(r*.17,-r*.17),Vector2(-r*.17,r*.17),Vector2(r*.17,r*.17)]:
			draw_circle(c+cell,r*.055,Color(ink.r,ink.g,ink.b,.85))

## 세로로 세운 주련(빠른 매치 좌우 장식).
class VerticalBanner extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var text:=""
	var tint:=Color(0.85,0.72,0.47,.75)
	var font_size:=13
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var board:=Rect2(Vector2.ZERO,size)
		T.rounded(self,board,Color(0.05,0.05,0.10,.5),5)
		draw_rect(board,Color(tint.r,tint.g,tint.b,.32),false,1.0)
		T.diamond(self,Vector2(size.x*.5,6),3.2,tint)
		var count:=text.length()
		var step:=(size.y-24.0)/maxf(1.0,float(count))
		for i in range(count):
			var at:=Vector2(size.x*.5,14.0+step*(i+.85))
			draw_string(T.FONT,at+Vector2(-font_size*.5,0),text.substr(i,1),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,tint)

## 기운(오라) 미리보기·카드용 빛구슬.
class Orb extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(0.85,0.78,1.0)
	var time:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		time+=delta
		queue_redraw()
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5
		var pulse:=0.5+sin(time*1.3)*0.5
		for i in range(8):
			var k:=1.0-i/8.0
			draw_circle(c,r*(.42+k*.58),Color(color.r,color.g,color.b,.035+pulse*.01))
		for i in range(22):
			var angle:=i*TAU/22.0+time*.3
			var radius:=r*(.52+sin(time*1.7+i)*.14)
			draw_circle(c+Vector2.from_angle(angle)*radius,1.5+sin(i)*.6,Color(color.r,color.g,color.b,.55))
		draw_circle(c,r*.30,Color(1,1,1,.5))
		draw_circle(c,r*.22,Color(color.r,color.g,color.b,.95))
		draw_arc(c,r*.34,0,TAU,32,Color(color.r,color.g,color.b,.7),1.4,true)

## 발밑 기운 고리(기운 미리보기).
class AuraRing extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var color:=Color(0.85,0.78,1.0)
	var time:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		time+=delta
		queue_redraw()
	func _draw() -> void:
		var c:=Vector2(size.x*.5,size.y*.62)
		var rx:=size.x*.42
		var ry:=size.y*.26
		for i in range(4):
			var k:=1.0-i*.16
			var points:=PackedVector2Array()
			for step in range(41):
				var angle:=step/40.0*TAU
				points.append(c+Vector2(cos(angle)*rx*k,sin(angle)*ry*k))
			draw_polyline(points,Color(color.r,color.g,color.b,.34-i*.06),2.0-i*.3,true)
		for i in range(10):
			var angle:=i*TAU/10.0+time*.5
			draw_circle(c+Vector2(cos(angle)*rx*.84,sin(angle)*ry*.84),1.8,Color(color.r,color.g,color.b,.7))

## 업적 진행도 막대(가느다란 금빛 게이지).
class Bar extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var value:=0.0
	var maximum:=1.0
	var tint:=Color(0.85,0.72,0.47)
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func set_value(now: float,total: float) -> void:
		value=now;maximum=maxf(1.0,total)
		queue_redraw()
	func _draw() -> void:
		var radius:=size.y*.5
		T.rounded(self,Rect2(Vector2.ZERO,size),Color(0.02,0.025,0.06,.9),radius)
		draw_rect(Rect2(Vector2.ZERO,size),Color(tint.r,tint.g,tint.b,.35),false,1.0)
		var ratio:=clampf(value/maximum,0.0,1.0)
		if ratio<=0.0:return
		var fill:=Rect2(Vector2(1,1),Vector2(maxf(size.y-2.0,(size.x-2.0)*ratio),size.y-2.0))
		T.rounded(self,fill,Color(tint.r,tint.g,tint.b,.9),radius-1)
		draw_rect(Rect2(fill.position+Vector2(0,0),Vector2(fill.size.x,fill.size.y*.5)),Color(1,0.96,0.85,.28))
