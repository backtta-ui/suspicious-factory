class_name WooSkillBadge
extends Control
const SHEET=preload("res://assets/woo/v20/skills.png")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const INDEX={"attack":0,"jump":1,"dodge":2,"talisman":3,"jar":4,"transform":4,"blink":5,"clone":6,"track":7,"shield":8,"smoke":9,"mask":10,"rescue":11,"capture":12,"darkness":13,"fake_flame":14,"shadow":15,"mimic":10,"locked":-1}
var skill:="attack"
var remaining:=0.0
var maximum:=1.0
## 궁극기 배지: 시간 대신 '모은 기운'을 채워지는 호로만 보여 준다.
## 2.0.38: 잠김(기운 모으는 중)·사용 직후 재충전 모두 남은 초를 숫자로 보여 준다
## (다른 스킬 버튼의 10.1 / 5.9 와 같은 표기).
var fill_mode:=false
var locked:=false
var glow:=0.0
var previous_remaining:=0.0
## 궁극기 숫자 표기 여부(테스트가 읽는다). 가득 차면 READY.
func countdown_active() -> bool:
 return fill_mode and remaining>0.05
func countdown_text() -> String:
 if not countdown_active():return ""
 if remaining>=100.0:return "%d"%int(ceil(remaining))
 return "%.1f"%remaining
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 if previous_remaining>0 and remaining<=0:glow=1
 previous_remaining=remaining
 glow=maxf(0,glow-delta*2);queue_redraw()
func _draw() -> void:
 var radius:=minf(size.x,size.y)/2-3
 var center:=size/2
 var pressed: bool=get_parent() is BaseButton and get_parent().button_pressed
 var unavailable: bool=locked or (get_parent() is BaseButton and get_parent().disabled)
 draw_circle(center,radius,Color("344e69") if pressed else preload("res://scripts/ui/design.gd").INK);draw_arc(center,radius,0,TAU,48,Color("fff0c9") if pressed else preload("res://scripts/ui/design.gd").GOLD,3 if pressed else 2,true)
 var index: int=INDEX.get(skill,-1)
 if index>=0:
  var cell:=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/4.0)
  var extent:=radius*1.7
  draw_texture_rect_region(SHEET,Rect2(center-Vector2.ONE*extent/2,Vector2.ONE*extent),Rect2(Vector2(index%4,floori(index/4.0))*cell,cell),Color(.4,.4,.5,.8) if remaining>0 or unavailable else Color.WHITE)
 if fill_mode:
  var charge: float=clampf(1.0-remaining/maxf(maximum,.01),0,1)
  draw_arc(center,radius-2,-PI/2,-PI/2+TAU*charge,48,Color("ffe6a8") if charge>=.999 else Color("c79bff"),4,true)
  if charge>=.999:
   var ready_text: String="READY"
   var ready_w: float=FONT.get_string_size(ready_text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
   draw_string_outline(FONT,center+Vector2(-ready_w*.5,6),ready_text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,3,Color("121528"))
   draw_string(FONT,center+Vector2(-ready_w*.5,6),ready_text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff0c9"))
  else:
   # 남은 초: 아이콘 위에 또렷하게 가운데 정렬(잠금 자물쇠는 오른쪽 위 작은 표식으로).
   var text: String=countdown_text()
   var font_size: int=22 if text.length()<=3 else 19
   var text_w: float=FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
   var at:=center+Vector2(-text_w*.5,float(font_size)*.36)
   draw_circle(center+Vector2(0,1),radius*.60,Color(.02,.03,.06,.55))
   draw_string_outline(FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,5,Color("0b1020"))
   draw_string(FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff0c9"))
   if locked:
    var lock_at:=center+Vector2(radius*.58,-radius*.58)
    draw_circle(lock_at,7.0,Color(.10,.12,.20,.92))
    draw_rect(Rect2(lock_at-Vector2(3.2,0.4),Vector2(6.4,5.2)),Color("cfba88"))
    draw_arc(lock_at-Vector2(0,0.6),2.8,PI,TAU,10,Color("cfba88"),1.8)
 elif remaining>0:
  draw_arc(center,radius-2,-PI/2,-PI/2+TAU*clampf(remaining/maxf(maximum,.01),0,1),48,Color("7fbded"),4,true)
  draw_string_outline(FONT,center+Vector2(-13,8),"%.1f"%remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,20,3,Color("121528"))
  draw_string(FONT,center+Vector2(-13,8),"%.1f"%remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff0c9"))
 if locked and not fill_mode:
  draw_rect(Rect2(center-Vector2(8,3),Vector2(16,13)),Color("cfba88"));draw_arc(center-Vector2(0,3),6,PI,TAU,12,Color("cfba88"),3)
 if glow>0:draw_arc(center,radius+1,0,TAU,48,Color(.5,.8,1,glow),3,true)
