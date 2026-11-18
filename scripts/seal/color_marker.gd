extends Node2D
## 캐릭터는 원화와 이름표로 구분한다. 발밑에 색깔 링을 그리지 않는다(사용자 요청).
## color_id는 서버·연출 코드가 계속 사용하므로 값만 보관한다.
var color_id:=0
var actor: WooActor
