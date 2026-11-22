extends RefCounted
## 2.0.38 화질 설정(설정 › 화면): '낮음'이면 무대 위 장식·조명·물결 밀도를 줄여
## 모바일에서 60fps를 지킨다. 게임 규칙·충돌·시야 판정은 전혀 바꾸지 않는다.
## 값은 app이 저장된 설정에서 읽어 한 번만 넣어 준다(그리기 코드가 매 프레임 읽는다).
static var low:=false
static func set_quality(value: String) -> void:
 low = String(value)=="낮음"
static func detail(full_count: int, low_count: int) -> int:
 return low_count if low else full_count
static func enabled() -> bool:
 return not low
