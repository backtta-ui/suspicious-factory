extends Control
## 상업 HUD의 딥네이비+금빛 장식. 크기가 바뀔 때만 다시 그린다.
const NAVY=Color("111a2e")
const NAVY_LIGHT=Color("1d2946")
const GOLD=Color("d9b878")
const GOLD_SOFT=Color("f3dfae")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func plate(rect: Rect2,radius: float,glow: bool=true) -> void:
 var box:=rect
 draw_rect(Rect2(box.position+Vector2(0,3),box.size),Color(.01,.02,.05,.45))
 rounded(box.grow(2),GOLD.darkened(.45),radius+2)
 rounded(box,GOLD,radius)
 rounded(box.grow(-2),GOLD_SOFT,radius-1)
 rounded(box.grow(-3),NAVY,radius-1)
 # 위쪽 은은한 광
 rounded(Rect2(box.position+Vector2(3,3),Vector2(box.size.x-6,box.size.y*.42)),NAVY_LIGHT.lightened(.05),radius-2)
 if glow:
  for corner in [box.position+Vector2(6,6),Vector2(box.end.x-6,box.position.y+6),Vector2(box.position.x+6,box.end.y-6),box.end-Vector2(6,6)]:
   diamond(corner,4,GOLD_SOFT)
func rounded(rect: Rect2,color: Color,radius: float) -> void:
 var r:=maxf(1,minf(radius,minf(rect.size.x,rect.size.y)*.5))
 draw_rect(Rect2(rect.position+Vector2(r,0),rect.size-Vector2(r*2,0)),color)
 draw_rect(Rect2(rect.position+Vector2(0,r),rect.size-Vector2(0,r*2)),color)
 for corner in [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),Vector2(rect.position.x+r,rect.end.y-r),rect.end-Vector2(r,r)]:
  draw_circle(corner,r,color)
func diamond(center: Vector2,radius: float,color: Color) -> void:
 draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0)]),color)
func cloud(center: Vector2,scale_value: float,color: Color) -> void:
 for offset in [Vector2(-18,0),Vector2(0,-5),Vector2(18,0),Vector2(-8,4),Vector2(9,4)]:
  draw_circle(center+offset*scale_value,10*scale_value,color)
func _draw() -> void:
 var w:=size.x
 # 중앙 타이틀 판
 var title:=Rect2(w*.5-238,8,476,72)
 plate(title,22)
 # 초승달 + 구름
 var moon:=title.position+Vector2(38,32)
 draw_circle(moon,13,Color("f5e6bd"))
 draw_circle(moon+Vector2(6,-3),11.5,NAVY)
 for i in range(3):
  cloud(title.position+Vector2(24+i*140,12),.6+ (i%2)*.1,Color(.55,.6,.85,.16))
 cloud(title.position+Vector2(title.size.x-40,62),.65,Color(.55,.6,.85,.14))
 diamond(title.get_center()+Vector2(0,-38),4,GOLD_SOFT)
 # 좌측 봉인 판
 var seal:=Rect2(12,10,238,62)
 plate(seal,16)
 draw_circle(seal.position+Vector2(35,31),21,Color("223052"))
 draw_circle(seal.position+Vector2(35,31),21,GOLD,false,1.8)
 draw_rect(Rect2(seal.position+Vector2(26,20),Vector2(18,18)),Color("e9c98d"))
 draw_rect(Rect2(seal.position+Vector2(30,24),Vector2(10,10)),Color("223052"))
 for i in range(3):draw_line(seal.position+Vector2(25,41+i*2),seal.position+Vector2(45,41+i*2),GOLD_SOFT,1)
 draw_line(seal.position+Vector2(64,14),seal.position+Vector2(64,48),Color(GOLD,.35),1)
