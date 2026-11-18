extends Node2D
## 캐릭터 구분용 발밑 기운. 색이 바뀔 때만 다시 그린다(프레임 부하 없음).
var color:=Color.WHITE
var yokai:=false
func _ready() -> void:
 z_index=-1
func _draw() -> void:
 # 발밑 접지 그림자
 draw_set_transform(Vector2(0,1),0,Vector2(1,.34))
 draw_circle(Vector2.ZERO,17,Color(.01,.01,.03,.5))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_set_transform(Vector2(0,2),0,Vector2(1,.42))
 for i in range(3):
  draw_circle(Vector2.ZERO,16-i*4,Color(color.r,color.g,color.b,.05+i*.03))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if yokai:
  # 요괴는 머리 위 작은 불꽃으로 한눈에 구분한다.
  var flame:=PackedVector2Array([Vector2(-2.5,-60),Vector2(0,-67),Vector2(2.5,-60),Vector2(0,-56)])
  draw_colored_polygon(flame,Color(.9,.35,.3,.35))
