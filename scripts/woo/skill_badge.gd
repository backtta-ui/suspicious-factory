class_name WooSkillBadge
extends Control
const SHEET=preload("res://assets/woo/v20/skills.png")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const INDEX={"attack":0,"jump":1,"dodge":2,"talisman":3,"jar":4,"transform":4,"blink":5,"clone":6,"track":7,"shield":8,"smoke":9,"mask":10,"rescue":11,"capture":12,"darkness":13,"fake_flame":14,"shadow":15,"mimic":10,"locked":-1}
var skill:="attack"
var remaining:=0.0
var maximum:=1.0
## 궁극기 배지: 시간 대신 '모은 기운'을 채워지는 호로만 보여 준다.
var fill_mode:=false
var locked:=false
var glow:=0.0
var previous_remaining:=0.0
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
   draw_string_outline(FONT,center+Vector2(-17,7),"READY",HORIZONTAL_ALIGNMENT_LEFT,-1,15,3,Color("121528"))
   draw_string(FONT,center+Vector2(-17,7),"READY",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff0c9"))
 elif remaining>0:
  draw_arc(center,radius-2,-PI/2,-PI/2+TAU*clampf(remaining/maxf(maximum,.01),0,1),48,Color("7fbded"),4,true)
  draw_string_outline(FONT,center+Vector2(-13,8),"%.1f"%remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,20,3,Color("121528"))
  draw_string(FONT,center+Vector2(-13,8),"%.1f"%remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff0c9"))
 if locked:
  draw_rect(Rect2(center-Vector2(8,3),Vector2(16,13)),Color("cfba88"));draw_arc(center-Vector2(0,3),6,PI,TAU,12,Color("cfba88"),3)
 if glow>0:draw_arc(center,radius+1,0,TAU,48,Color(.5,.8,1,glow),3,true)
