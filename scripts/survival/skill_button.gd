extends WooMobileButton
## 원형 금테 스킬 버튼: 눌림 스케일 피드백만 하고 매 프레임 다시 그리지 않는다.
const GOLD=Color("e2c07c")
const GOLD_HOT=Color("ffe9b5")
const INK=Color("0d1526")
var accent:=Color("6fa8d8")
var ring_glow:=0.0
var _settle:=false
func _ready() -> void:
 super._ready()
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(func()->void:pivot_offset=size*.5)
 pivot_offset=size*.5
 _settle=false
 set_process(false)
func _draw() -> void:
 var radius:=minf(size.x,size.y)*.5-3
 var center:=size*.5
 var hot:=button_pressed
 draw_circle(center+Vector2(0,3),radius,Color(.01,.02,.05,.45))
 draw_circle(center,radius,INK)
 draw_circle(center,radius*.92,Color(.09,.13,.22,.9))
 # 은은한 색 기운
 for i in range(3):
  draw_circle(center,radius*(1.0-i*.12),Color(accent.r,accent.g,accent.b,.05+(.04 if i==1 else 0.0)))
 draw_arc(center,radius-1,0,TAU,48,Color(GOLD_HOT if hot else GOLD),3.4 if hot else 2.4,true)
 draw_arc(center,radius-5,0,TAU,48,Color(GOLD.darkened(.35),.55),1,true)
 if disabled:draw_circle(center,radius,Color(.04,.05,.09,.45))
func down() -> void:
 super.down()
 scale=Vector2(.94,.94)
 ring_glow=1.0
 queue_redraw()
func up(inside: bool) -> void:
 var was:=held
 super.up(inside)
 scale=Vector2.ONE
 ring_glow=0
 _settle=true
 set_process(true)
 queue_redraw()
func _process(delta: float) -> void:
 if _settle:
  scale=scale.lerp(Vector2.ONE,delta*18)
  if scale.distance_to(Vector2.ONE)<.005:
   scale=Vector2.ONE;_settle=false;set_process(false)
