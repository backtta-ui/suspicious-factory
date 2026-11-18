extends "res://scripts/ui/lobby_screen.gd"
## 2.0.25 빠른 매치 — 시안(달빛 한옥 정원 빠른 매치) 복제.
## 가운데 부적 고리 위에 8인의 인장이 차례로 들어오고, 안쪽 원에 달과 "수련생 찾는 중…"·남은 시간.
## 위: 희망 진영 탭 3개 / 아래: 매칭 취소 · 매칭 시작.
const UIK=preload("res://scripts/ui/ui_kit.gd")
const P=preload("res://scripts/ui/ui_palette.gd")
const G=preload("res://scripts/ui/room_glyphs.gd")
const SLOTS:=8
const DAOISTS:=6
const RING:=176.0
const SLOT_SIZE:=92.0
const NAMES=["나","달빛여우","서원지기","밤도사","호랑이님","그림자","연꽃","도깨비"]
var slots: Array=[]
var status_label: Label
var timer_label: Label
var inner_label: Label
var match_slots:=0
var side_buttons: Dictionary={}
var ring_visual: Control
var inner_disc: Control
var role_row: Control

func build() -> void:
	header("빠른 매치","원하는 진영을 선택하고 빠르게 매칭하세요","swords")
	# 희망 진영 탭
	for spec in [["도사 희망","daoist","lotus"],["요괴 희망","yokai","fox"],["상관없음","any","shuffle"]]:
		var value: String=String(spec[1])
		var target:=V.Tab.new()
		target.text=String(spec[0])
		target.glyph=String(spec[2])
		target.font_size=20
		target.name="QuickSide_"+value
		target.custom_minimum_size=Vector2.ZERO
		target.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
		target.pressed.connect(func()->void:
			if target.usable():game.sound.play_clip("button");game.set_preferred_role(value))
		add_child(target)
		game.button_feel(target)
		side_buttons[value]=target
	ring_visual=Control.new()
	ring_visual.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ring_visual)
	ring_visual.draw.connect(_draw_ring)
	inner_disc=Control.new()
	inner_disc.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(inner_disc)
	inner_disc.name="QuickInner"
	inner_disc.draw.connect(_draw_inner)
	status_label=label(self,"수련생 찾는 중…",21,V.GOLD_BRIGHT,true)
	status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status_label.name="QuickStatus"
	timer_label=label(self,"00:24",34,V.IVORY,true)
	timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inner_label=label(self,"도사 6 : 요괴 2",13.5,Color(.84,.80,.96))
	inner_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i in range(SLOTS):
		var slot:=Slot.new()
		slot.index=i
		add_child(slot)
		slots.append(slot)
	var cancel:=V.PlateButton.new()
	cancel.kind="dark"
	cancel.text="매칭 취소"
	cancel.glyph="cross"
	cancel.font_size=22
	cancel.name="MatchCancel"
	cancel.custom_minimum_size=Vector2.ZERO
	cancel.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	cancel.pressed.connect(func()->void:
		if cancel.usable():game.sound.play_clip("button");game.transition("lobby"))
	add_child(cancel)
	game.button_feel(cancel)
	var start:=V.PlateButton.new()
	start.kind="gold"
	start.text="매칭 시작"
	start.glyph="swords"
	start.font_size=22
	start.name="MatchStart"
	start.custom_minimum_size=Vector2.ZERO
	start.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
	start.pressed.connect(func()->void:
		if start.usable():game.sound.play_clip("button");game.finish_matching())
	add_child(start)
	game.button_feel(start)
	refresh_sides()
	set_slots(maxi(1,match_slots))

func _process(delta: float) -> void:
	if not built:return
	if is_instance_valid(timer_label):
		var left:=maxi(0,int(ceil(24.0-game.matching)))
		if match_slots>=SLOTS:left=0
		timer_label.text="00:%02d"%left
	if is_instance_valid(inner_disc):inner_disc.queue_redraw()

## 중심 좌표(디자인 좌표).
func center() -> Vector2:
	return Vector2(dw*.5,392)

func _draw_ring() -> void:
	var c:=ring_visual.size*.5
	var r:=RING
	for i in range(18):
		ring_visual.draw_arc(c,r+4.0+float(i)*2.6,0,TAU,96,Color(.66,.48,1.0,.055-float(i)*.0026),3.2,true)
	# 금빛 띠
	ring_visual.draw_arc(c,r,0,TAU,120,Color(.06,.04,.10,.85),9.0,true)
	ring_visual.draw_arc(c,r,0,TAU,120,Color(.90,.74,.42,.92),5.0,true)
	ring_visual.draw_arc(c,r-3.6,0,TAU,120,Color(1,.96,.82,.75),1.4,true)
	ring_visual.draw_arc(c,r+3.6,0,TAU,120,Color(.55,.34,.12,.65),1.2,true)
	# 안쪽 보랏빛 고리
	ring_visual.draw_arc(c,r-16.0,0,TAU,110,Color(.72,.56,1.0,.35),1.2,true)
	# 48개 룬 눈금
	for i in range(48):
		var a:=-PI*.5+i*TAU/48.0
		var p:=c+Vector2.from_angle(a)*r
		var size:=5.0 if i%6==0 else 2.8
		ring_visual.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-size),p+Vector2(size*.7,0),p+Vector2(0,size),p+Vector2(-size*.7,0)]),Color(1,.94,.72,.85))

func _draw_inner() -> void:
	var c:=inner_disc.size*.5
	var r:=RING-46.0
	for i in range(6):
		inner_disc.draw_circle(c,r+2.0+float(i)*3.0,Color(.62,.46,.96,.05-float(i)*.006))
	T.gradient_rounded(inner_disc,Rect2(c-Vector2(r,r),Vector2(r*2.0,r*2.0)),Color(.20,.13,.30,.94),Color(.07,.05,.12,.97),r)
	inner_disc.draw_arc(c,r-1.0,0,TAU,80,Color(0,0,0,.5),2.0,true)
	inner_disc.draw_arc(c,r-2.0,0,TAU,80,Color(.92,.76,.46,.90),1.8,true)
	inner_disc.draw_arc(c,r-6.0,0,TAU,80,Color(.92,.76,.46,.28),1.0,true)
	# 달과 구름 장식
	G.draw_glyph(inner_disc,"moon",Rect2(c+Vector2(-16,-r*0.62),Vector2(32,32)),Color(.98,.90,.68),1.6)
	G.draw_glyph(inner_disc,"cloud",Rect2(c+Vector2(r*0.24,-r*0.60),Vector2(34,24)),Color(.86,.78,.98,.55),1.4)
	# 안쪽 작은 별 장식
	for i in range(16):
		var a:=i*TAU/16.0
		var p:=c+Vector2.from_angle(a)*(r-14.0)
		inner_disc.draw_circle(p,1.4,Color(.96,.88,.68,.35))

func set_slots(count: int) -> void:
	match_slots=clampi(count,0,SLOTS)
	for i in range(slots.size()):
		var slot: Slot=slots[i]
		var role: String="daoist" if i<DAOISTS else "yokai"
		var filled:=i<match_slots
		var character:=_character(i,role)
		var portrait:=String(C.find(character).get("portrait",""))
		slot.set_data(filled,role,portrait)
		if filled and not slot.get_meta("popped",false):
			slot.set_meta("popped",true)
			slot.modulate.a=0.0
			var tween:=create_tween()
			tween.tween_property(slot,"modulate:a",1.0,.22)
	if is_instance_valid(status_label):
		status_label.text=("수련생 찾는 중… %d / 8" % match_slots) if match_slots<SLOTS else "모두 찾았습니다 · 8 / 8"
		status_label.add_theme_color_override("font_color",V.GOLD_BRIGHT if match_slots>=SLOTS else V.IVORY)
	if is_instance_valid(inner_label):
		inner_label.text="도사 6 : 요괴 2"

func refresh_sides() -> void:
	var picked: String=String(game.preferred_role) if game!=null else "any"
	for value in side_buttons:
		var target: V.Tab=side_buttons[value]
		if not is_instance_valid(target):continue
		target.paint(value==picked)

func _character(index: int,role: String) -> String:
	if index==0:
		return String(game.storage.data[role])
	var catalog: Array=C.catalog(role)
	return String(catalog[index%catalog.size()].id)

func arrange() -> void:
	if not built:return
	var c:=center()
	var total:=3*252.0+2*16.0
	var x:=c.x-total*.5
	for key in ["daoist","yokai","any"]:
		var target: V.Tab=side_buttons[key]
		if is_instance_valid(target):
			reshape(target,Rect2(x,84,252,58))
			target.queue_redraw()
		x+=268.0
	if is_instance_valid(ring_visual):
		reshape(ring_visual,Rect2(c.x-RING-24,c.y-RING-24,(RING+24)*2,(RING+24)*2))
		ring_visual.queue_redraw()
	if is_instance_valid(inner_disc):
		reshape(inner_disc,Rect2(c.x-RING-24,c.y-RING-24,(RING+24)*2,(RING+24)*2))
		inner_disc.queue_redraw()
	for i in range(slots.size()):
		var a:=-PI*.5+i*TAU/SLOTS
		var at:=c+Vector2.from_angle(a)*RING
		reshape(slots[i],Rect2(at.x-SLOT_SIZE*.5,at.y-SLOT_SIZE*.5,SLOT_SIZE,SLOT_SIZE))
		slots[i].queue_redraw()
	if is_instance_valid(status_label):
		reshape(status_label,Rect2(c.x-200,c.y-58,400,30))
	if is_instance_valid(timer_label):
		reshape(timer_label,Rect2(c.x-200,c.y-16,400,48))
	if is_instance_valid(inner_label):
		reshape(inner_label,Rect2(c.x-200,c.y+36,400,22))
	var cancel: Node=self.find_child("MatchCancel",true,false)
	if cancel!=null:reshape(cancel,Rect2(c.x-316,592,300,66))
	var start: Node=self.find_child("MatchStart",true,false)
	if start!=null:reshape(start,Rect2(c.x+16,592,300,66))

## 부적 고리 위의 인장 하나 — 빈 자리는 "?" , 들어오면 초상.
class Slot extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	const G=preload("res://scripts/ui/room_glyphs.gd")
	var index:=0
	var filled:=false
	var role:="daoist"
	var portrait:=""
	var texture: Texture2D=null
	var clock:=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_process(true)
	func _process(delta: float) -> void:
		clock+=delta
		if not filled:queue_redraw()
	func set_data(is_filled: bool,role_value: String,path: String) -> void:
		filled=is_filled
		role=role_value
		portrait=path
		texture=null
		if filled and path!="" and ResourceLoader.exists(path):texture=load(path)
		queue_redraw()
	func _draw() -> void:
		var c:=size*.5
		var r:=minf(size.x,size.y)*.5-2.0
		var accent:=Color(.92,.76,.46) if role=="daoist" else Color(.76,.56,.96)
		for i in range(7):
			var grow:=2.0+float(i)*2.6
			draw_circle(c,r+grow,Color(accent.r,accent.g,accent.b,.055-float(i)*.007))
		draw_circle(c,r+1.5,Color(.06,.05,.10,.95))
		if filled and texture!=null:
			draw_texture_rect(texture,Rect2(c-Vector2(r,r),Vector2(r*2.0,r*2.0)),false,Color(.95,.94,1.0))
		else:
			T.gradient_rounded(self,Rect2(c-Vector2(r,r),Vector2(r*2.0,r*2.0)),Color(.17,.15,.24,1.0),Color(.07,.06,.12,1.0),r)
			T.gradient_rounded(self,Rect2(c-Vector2(r*.82,r*.82),Vector2(r*1.64,r*1.64)),Color(.26,.24,.34,.55),Color(.12,.10,.18,.2),r*.82)
			draw_circle(c+Vector2(0,-r*.18),r*.20,Color(.10,.09,.14,.95))
			draw_circle(c+Vector2(0,r*.30),r*.34,Color(.10,.09,.14,.95))
			var font: Font=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
			var extent:=int(r*.86)
			draw_string(font,Vector2(c.x-font.get_string_size("?",HORIZONTAL_ALIGNMENT_LEFT,-1,extent).x*.5,c.y+(font.get_ascent(extent)-font.get_descent(extent))*.5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,extent,Color(.86,.82,.94,.85))
		draw_arc(c,r,0,TAU,56,Color(0,0,0,.55),2.4,true)
		draw_arc(c,r-0.6,0,TAU,56,accent,2.4,true)
		draw_arc(c,r-4.2,0,TAU,56,Color(accent.r,accent.g,accent.b,.30),1.1,true)
		draw_arc(c,r-1.5,PI*1.05,PI*1.65,24,Color(1,.97,.88,.55),1.6,true)
		# 8방향 작은 못
		for i in range(8):
			var a:=i*TAU/8.0
			var p:=c+Vector2.from_angle(a)*(r+2.0)
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-2.6),p+Vector2(2.6,0),p+Vector2(0,2.6),p+Vector2(-2.6,0)]),Color(accent.r,accent.g,accent.b,.9))
