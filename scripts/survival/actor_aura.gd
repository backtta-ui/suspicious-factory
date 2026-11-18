extends Node2D
## 캐릭터 발밑 그림자. 캐릭터 자체로 팀을 구분하므로 색깔 링은 그리지 않는다.
## 기운(기운 아이템)을 장착했을 때만 아주 옅은 빛무리를 더한다.
var color:=Color.WHITE
var yokai:=false
var lit:=false
## 둔갑 중이면 이 반지름의 사물 그림자만 그린다(맵의 사물 그림자와 같은 모양).
## 0보다 크면 캐릭터 그림자·불꽃·기운을 모두 숨긴다.
var form_shadow:=0.0
func _ready() -> void:
 z_index=-1
func _draw() -> void:
 if form_shadow>0:
  draw_set_transform(Vector2(0,1),0,Vector2(1,.36))
  draw_circle(Vector2.ZERO,form_shadow,Color(.01,.01,.03,.45))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  return
 # 부드러운 검은 땅 그림자(겹으로 그려 가장자리를 흐리게)
 draw_set_transform(Vector2(0,1),0,Vector2(1,.34))
 for i in range(3):
  draw_circle(Vector2.ZERO,17-i*3,Color(.01,.01,.03,.14+i*.05))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if lit:
  draw_set_transform(Vector2(0,2),0,Vector2(1,.42))
  draw_circle(Vector2.ZERO,15,Color(color.r,color.g,color.b,.08))
  draw_circle(Vector2.ZERO,9,Color(color.r,color.g,color.b,.12))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if yokai:
  # 요괴는 머리 위 작은 불꽃으로만 조용히 구분한다.
  var flame:=PackedVector2Array([Vector2(-2.5,-60),Vector2(0,-67),Vector2(2.5,-60),Vector2(0,-56)])
  draw_colored_polygon(flame,Color(.9,.35,.3,.28))
