extends Node2D
## 2.0.36 실내 레이어: 어몽어스식으로 건물에 들어가면 지붕이 사라지고 꾸며진 실내가 보인다.
## 레이아웃의 buildings()(앞문·뒷문·실내 사각형)만 읽으므로 그림과 충돌이 어긋나지 않는다.
## 문 앞에 서 있어도 미리 반쯤 열려 안이 보인다(들어갈 곳임을 알 수 있게).
const Kit=preload("res://scripts/survival/interiors.gd")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE=preload("res://assets/fonts/WooTitle.otf")
var layout: Script
var observer:=Vector2.ZERO
var clock:=0.0
var alphas: Dictionary={}
var tick:=0.0
func _ready() -> void:
 z_index=-78
 draw.connect(draw_rooms)
func _process(delta: float) -> void:
 if layout==null:return
 clock+=delta
 var changed:=false
 for entry in layout.buildings():
  if entry.is_empty():continue
  var id: String=String(entry.id)
  var target:=0.0
  var inside: bool=(entry.interior as Rect2).grow(6).has_point(observer)
  if inside:target=1.0
  else:
   for side in ["front","back"]:
    var at: Vector2=(entry.doors as Dictionary)[side]
    if observer.distance_to(at)<52.0:target=.45
  var current: float=float(alphas.get(id,0.0))
  var next: float=move_toward(current,target,delta*4.5)
  if absf(next-current)>.005:alphas[id]=next;changed=true
 if changed:queue_redraw()
func draw_rooms() -> void:
 if layout==null:return
 for entry in layout.buildings():
  if entry.is_empty():continue
  var alpha: float=float(alphas.get(String(entry.id),0.0))
  if alpha>.02:Kit.draw_room(self,entry,alpha,clock)
  if observer.distance_to((entry.rect as Rect2).get_center())<520.0:draw_sign(entry,alpha)
## 문 위 간판: 실내 이름과 설명. 들어가 있으면 흐려져 실내를 가리지 않는다.
func draw_sign(entry: Dictionary,alpha: float) -> void:
 var front: Vector2=(entry.doors as Dictionary).front
 var rect: Rect2=entry.rect
 var label: String=String(entry.get("name",""))
 if label=="":return
 var sub:=String(entry.get("sub",""))
 var y:=rect.position.y-WALL_SIGN if rect.position.y>48.0 else front.y-40.0
 var font_size:=17
 var width: float=minf(FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+20.0,rect.size.x-6.0)
 var box:=Rect2(Vector2(rect.get_center().x-width*.5,y),Vector2(width,24))
 draw_rect(box,Color(.04,.03,.05,.88))
 draw_rect(box,Color(.85,.72,.47,.85),false,1.4)
 draw_string(FONT,box.position+Vector2(10,17),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("ffe6b0"))
 if sub!="":
  draw_string_outline(FONT,box.position+Vector2(0,38),sub,HORIZONTAL_ALIGNMENT_CENTER,width,11,3,Color(.02,.02,.04,.9))
  draw_string(FONT,box.position+Vector2(0,38),sub,HORIZONTAL_ALIGNMENT_CENTER,width,11,Color(.88,.86,.94,.95))
const WALL_SIGN=24.0
