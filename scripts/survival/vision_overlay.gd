extends Control
## 2.0.30 화면 시야 연출(뷰포트 레이어).
## - 시야 좁히기(검은시야·구미환몽): 화면 가장자리에서 안으로 밀려오는 다층 안개 커튼과
##   비네팅. 단색 덮개가 아니라 20여 겹의 옅은 띠와 흐르는 안개 덩어리로 만든다.
## - 등불끄기: 밤그림자 안개가 화면 가장자리를 타고 스며들고, 꺼진 등불의 잔불이 흩어진다.
## - 무월야: 밤하늘이 화면 전체를 덮고 먹구름 띠가 흐른다.
## 값은 rules.vision_for(observer) 하나에서만 온다(판정과 그림이 어긋나지 않게).
var rules: RefCounted
var observer:="human"
var narrow:=0.0
var dark:=0.0
var fog:=0.0
var source:=""
## 부드럽게 따라가는 표시값(스킬이 끝날 때 화면이 툭 밝아지지 않게).
var shown_narrow:=0.0
var shown_dark:=0.0
var shown_fog:=0.0
var clock:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func sync(delta: float) -> void:
 clock+=delta
 var target: Dictionary=rules.vision_for(observer) if rules!=null else {}
 narrow=float(target.get("narrow",0.0));dark=float(target.get("dark",0.0))
 fog=float(target.get("fog",0.0));source=String(target.get("source",""))
 shown_narrow=move_toward(shown_narrow,narrow,delta*2.4)
 shown_dark=move_toward(shown_dark,dark,delta*1.6)
 shown_fog=move_toward(shown_fog,fog,delta*1.4)
 var active: bool=shown_narrow>.01 or shown_dark>.01 or shown_fog>.01
 if visible!=active:visible=active
 visible=active
 queue_redraw()
func _draw() -> void:
 if shown_narrow<=.01 and shown_dark<=.01 and shown_fog<=.01:return
 var view:=size
 if view.x<4.0 or view.y<4.0:view=get_viewport_rect().size
 var center:=view*.5
 var max_radius: float=view.length()*.5+8.0
 # 시야 좁히기: 보이는 창(구멍)이 줄고, 바깥이 안개 커튼으로 덮인다.
 var aperture: float=lerpf(maxf(view.x,view.y)*.62,minf(view.x,view.y)*.26,clampf(shown_narrow,0.0,1.0))
 # 어둠·안개가 함께 세지면 창은 더 좁아진다.
 aperture*=1.0-clampf(shown_fog,0.0,1.0)*.18
 var curtain: float=clampf(maxf(shown_narrow,shown_fog*.8),0.0,1.0)
 if curtain>0.01:draw_curtain(center,aperture,max_radius,curtain)
 if shown_dark>0.01:draw_night(center,max_radius,shown_dark)
 if source=="blind" or (shown_narrow>.05 and source!="painting"):draw_sight_ring(center,aperture)
 if shown_fog>.02:draw_drifting_mist(center,aperture,max_radius,shown_fog)
## 원형 띠 하나를 굵은 호로 채운다(겹칠수록 진해져 자연스러운 그라데이션이 된다).
func band(center: Vector2,inner: float,outer: float,color: Color,_wobble: float=0.0,_seed: float=0.0) -> void:
 var width: float=maxf(1.0,outer-inner)
 draw_arc(center,(inner+outer)*.5,0,TAU,72,color,width,false)
## 어두운 안개 커튼: 구멍(창)에서 바깥으로 갈수록 짙어지는 띠 + 불규칙한 테두리.
func draw_curtain(center: Vector2,aperture: float,outer: float,strength: float) -> void:
 # 바깥으로 갈수록 여러 겹이 겹치도록, 각 띠를 '안쪽 시작점 → 화면 끝'까지 그린다.
 # (겹친 횟수가 거리에 비례해 어둡기가 자연스럽게 짙어진다.)
 var rings:=14
 var span: float=maxf(1.0,outer-aperture)
 var step: float=span/float(rings)
 for i in range(rings):
  var inner: float=aperture+step*float(i)
  var alpha: float=.03+.008*float(i)
  band(center,inner,outer,Color(.010,.008,.026,alpha*strength),.010,clock*.6+float(i)*.7)
 # 창 바로 바깥을 한 번 더 조여 어둠이 '확' 다가오게 한다.
 for i in range(3):
  band(center,aperture*(1.0+.02*float(i)),aperture*(1.16+.05*float(i)),Color(.012,.010,.026,.18*strength),.006,clock*.4)
 # 테두리를 기어오르는 안개 덩어리(불규칙한 경계).
 for i in range(22):
  var angle: float=float(i)*TAU/22.0+sin(clock*.35+float(i))*.05
  var radius2: float=aperture*(1.0+.03*sin(clock*1.1+float(i)*2.1))
  var spot:=center+Vector2.from_angle(angle)*radius2
  var size_value: float=span*(.045+.022*absf(sin(float(i)*1.7+clock*.5)))
  draw_circle(spot,size_value,Color(.03,.025,.06,.16*strength))
  draw_circle(spot+Vector2.from_angle(angle)*size_value*.6,size_value*.55,Color(.05,.04,.09,.12*strength))
## 화면 전체를 덮는 밤: 중심에서 바깥으로 겹겹이 어두워지는 다층 띠.
func draw_night(center: Vector2,outer: float,strength: float) -> void:
 draw_rect(Rect2(Vector2.ZERO,size if size.x>4.0 else get_viewport_rect().size),Color(.010,.011,.030,.34*strength))
 # 흐르는 먹구름 띠.
 for i in range(5):
  var drift: float=clock*.07+float(i)*1.3
  var spot:=center+Vector2(cos(drift)*outer*.55,sin(drift*.8)*outer*.32)
  draw_circle(spot,outer*.34,Color(.02,.022,.055,.05*strength))
## 시야 창의 테두리: 보랏빛 실선과 그 바깥의 번짐(무엇 때문에 좁아졌는지 읽히게).
func draw_sight_ring(center: Vector2,aperture: float) -> void:
 var pulse: float=.5+.5*sin(clock*2.2)
 draw_arc(center,aperture,0,TAU,96,Color(.62,.48,.92,.30+.14*pulse),2.6,true)
 draw_arc(center,aperture+6.0,0,TAU,96,Color(.44,.34,.74,.14+.08*pulse),7.0,false)
 for i in range(10):
  var angle: float=float(i)*TAU/10.0-clock*.4
  var spot:=center+Vector2.from_angle(angle)*(aperture+1.0)
  draw_circle(spot,1.9,Color(.78,.68,1,.30+.18*pulse))
## 흐르는 밤안개: 창 주변을 천천히 지나가는 옅은 덩어리들.
func draw_drifting_mist(center: Vector2,aperture: float,outer: float,strength: float) -> void:
 for i in range(9):
  var phase: float=clock*.13+float(i)*.83
  var angle: float=float(i)*TAU/9.0+sin(phase)*.25
  var radius: float=aperture*(1.02+.10*sin(phase*.7))
  var spot:=center+Vector2.from_angle(angle)*radius
  var extent: float=outer*.10+outer*.05*absf(sin(phase))
  draw_set_transform(spot,angle,Vector2(1.7,.55))
  draw_circle(Vector2.ZERO,extent,Color(.10,.10,.18,.05*strength))
  draw_circle(Vector2.ZERO,extent*.62,Color(.16,.15,.26,.04*strength))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
