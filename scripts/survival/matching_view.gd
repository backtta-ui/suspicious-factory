extends "res://scripts/ui/lobby_screen.gd"
## 빠른 매치: 달빛 부적 진법 위에 8인의 원형 인장이 차례로 들어오는 연출.
## 구성은 도사 6 : 요괴 2로 고정(사용자·ChatGPT 합의). 오프라인 봇 매칭임을 숨기지 않는다.
const SLOTS:=8
const DAOISTS:=6
const CENTER:=Vector2(640,372)
const RING:=176.0
const SLOT_SIZE:=82.0
const NAMES=["나","달빛여우","서원지기","밤도사","호랑이님","그림자","연꽃","도깨비"]
var slots: Array=[]
var status_label: Label
var match_slots:=0
var banner_left: Control
var banner_right: Control

func build() -> void:
	header("빠른 매치","월하의 생존전 · 8인 자동 매칭 (오프라인 봇)")
	note("※ 오프라인 봇 8인과 매칭됩니다 · 매칭이 끝나면 대기방에서 준비하고 캐릭터를 고릅니다")
	title_label.text="빠른 매치"
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size",36)
	title_label.set_meta("base_font",36)
	subtitle_label.text="월하의 생존전"
	subtitle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status_label=label(self,"대전 상대를 찾고 있습니다 · 1 / 8",19,T.IVORY)
	status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var composition:=label(self,"도사 6  ·  요괴 2",15,T.GOLD_SOFT)
	composition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	composition.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	composition.add_theme_stylebox_override("normal",T.panel_box(Color(0.04,0.045,0.1,0.72),13,Color(0.85,0.72,0.47,0.5),1))
	place(composition,Rect2(CENTER.x-116,102,232,30))
	var halo:=T.soft_glow(self,Color(0.56,0.46,1.0,0.22),Rect2(CENTER.x-230,CENTER.y-230,460,460))
	halo.name="MatchHalo"
	var circle:=Art.TalismanCircle.new()
	circle.radius=136.0
	add_child(circle)
	place(circle,Rect2(CENTER.x-210,CENTER.y-210,420,420))
	for i in range(SLOTS):
		var angle:=-PI*.5+i*TAU/SLOTS
		var at:=CENTER+Vector2.from_angle(angle)*RING
		var slot:=Art.SealSlot.new()
		slot.index=i
		add_child(slot)
		place(slot,Rect2(at.x-SLOT_SIZE*.5,at.y-SLOT_SIZE*.5,SLOT_SIZE,SLOT_SIZE))
		slots.append(slot)
	var cancel:=button("매칭 취소",func()->void:game.transition("lobby"),self,false,19)
	cancel.name="MatchCancel"
	place(cancel,Rect2(366,608,250,54))
	var start:=button("매치 수락 · 시작",func()->void:game.finish_matching(),self,true,20)
	start.name="MatchStart"
	place(start,Rect2(632,608,282,54))
	for side in [0,1]:
		var flourish:=Flourish.new()
		flourish.flip=side==1
		add_child(flourish)
		place(flourish,Rect2(CENTER.x-(300 if side==0 else -170),48,130,16))
	banner_left=Art.VerticalBanner.new()
	banner_left.text="달빛 아래 펼치는 도사와 요괴의 생존전"
	add_child(banner_left)
	banner_right=Art.VerticalBanner.new()
	banner_right.text="끝까지 살아남는 자가 이긴다"
	add_child(banner_right)
	set_slots(maxi(1,match_slots))

func set_slots(count: int) -> void:
	match_slots=clampi(count,0,SLOTS)
	for i in range(slots.size()):
		var slot: Control=slots[i]
		var role: String="daoist" if i<DAOISTS else "yokai"
		var filled:=i<match_slots
		var character:=_character(i,role)
		var portrait:=String(C.find(character).get("portrait",""))
		slot.set_data(filled,role,portrait)
		var name_tag: Label=null
		if slot.has_meta("name_tag"):name_tag=slot.get_meta("name_tag")
		if name_tag==null:
			name_tag=label(self,"",14,T.MUTED)
			name_tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			slot.set_meta("name_tag",name_tag)
		name_tag.text=NAMES[i] if filled else "탐색 중"
		name_tag.add_theme_color_override("font_color",T.IVORY if filled else Color(0.62,0.64,0.78,0.8))
		var at:=CENTER+Vector2.from_angle(-PI*.5+i*TAU/SLOTS)*RING
		place(name_tag,Rect2(at.x-74,at.y+SLOT_SIZE*.5,148,20))
		if filled and not slot.get_meta("popped",false):
			slot.set_meta("popped",true)
			slot.modulate.a=0.0
			var tween:=create_tween()
			tween.tween_property(slot,"modulate:a",1.0,.22)
	if is_instance_valid(status_label):
		status_label.text="대전 상대를 찾고 있습니다 · %d / 8"%match_slots
		status_label.add_theme_color_override("font_color",T.GOLD_SOFT if match_slots>=SLOTS else T.IVORY)

func _character(index: int,role: String) -> String:
	if index==0:
		return String(game.storage.data[role])
	var catalog: Array=C.catalog(role)
	return String(catalog[index%catalog.size()].id)

## 제목 옆 장식선.
class Flourish extends Control:
	const T=preload("res://scripts/ui/lobby_theme.gd")
	var flip:=false
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var y:=size.y*.5
		var a:=Vector2(size.x,0) if flip else Vector2(0,0)
		var b:=Vector2(0,0) if flip else Vector2(size.x,0)
		var color:=Color(0.85,0.72,0.47,.45)
		draw_line(a,b,color,1.0,true)
		draw_arc(b,4.0,0,TAU,12,Color(0.85,0.72,0.47,.5),1.0,true)
		T.diamond(self,b-Vector2(4 if flip else -4,y-y),2.6,color)

func arrange() -> void:
	if is_instance_valid(title_label):
		title_label.position=origin+Vector2(240,0)*s
		title_label.size=Vector2(800,50)*s
		title_label.add_theme_font_size_override("font_size",maxi(14,int(36.0*s)))
	if is_instance_valid(subtitle_label):
		subtitle_label.position=origin+Vector2(240,48)*s
		subtitle_label.size=Vector2(800,26)*s
		subtitle_label.add_theme_font_size_override("font_size",maxi(11,int(16.0*s)))
		subtitle_label.add_theme_color_override("font_color",T.gold(.85))
	if is_instance_valid(status_label):
		status_label.position=origin+Vector2(240,78)*s
		status_label.size=Vector2(800,30)*s
		status_label.add_theme_font_size_override("font_size",maxi(11,int(19.0*s)))
	if is_instance_valid(banner_left):
		banner_left.position=origin+Vector2(30,206)*s
		banner_left.size=Vector2(34,286)*s
	if is_instance_valid(banner_right):
		banner_right.position=origin+Vector2(1216,206)*s
		banner_right.size=Vector2(34,286)*s
	if is_instance_valid(banner_left):
		banner_left.position=origin+Vector2(30,206)*s
		banner_left.size=Vector2(34,286)*s
	if is_instance_valid(banner_right):
		banner_right.position=origin+Vector2(1216,206)*s
		banner_right.size=Vector2(34,286)*s
	if is_instance_valid(header_rule):
		header_rule.visible=false
	if is_instance_valid(wallet_row):
		wallet_row.visible=false
