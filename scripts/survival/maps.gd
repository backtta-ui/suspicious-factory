extends RefCounted
## 맵 레지스트리(2.0.35). 게임은 이 한 곳에서 '지금 어느 맵인지'를 읽는다.
## - 월하의 서원(seowon): 2.0.33까지의 조선 서원 맵을 그대로 보존한다(삭제 금지).
## - 서울 강남역(gangnam): 2.0.34 어몽어스 스타일 지하철역 맵.
## - 부산 해운대(haeundae): 2.0.35 비대칭 해안선 해변 맵(전통시장·백사장·동백섬).
## - 대구 동성로(dongseongno): 2.0.35 도심 격자 골목 미로(별빛랜드·아케이드·반월당).
## 빠른 매치는 네 맵을 무작위로 고르고(pick), 테스트·디버그는 set_current로
## 특정 맵을 지정한다. rules/app/world/minimap은 모두 Maps.layout()을 통해
## 같은 맵 데이터를 보므로 그림·충돌·둔갑 사물이 어긋나지 않는다.
const SEOWON=preload("res://scripts/survival/layout.gd")
const GANGNAM=preload("res://scripts/survival/gangnam_layout.gd")
const HAEUNDAE=preload("res://scripts/survival/haeundae_layout.gd")
const DONGSEONGNO=preload("res://scripts/survival/dongseongno_layout.gd")
const ORDER=["seowon","gangnam","haeundae","dongseongno"]
const RANDOM="random"
const INFO={
 "seowon":{"id":"seowon","name":"월하의 서원","subtitle":"달빛 아래 조선 서원","short":"서원",
  "accent":"e8c98b","tint":"ffd9a0","arena":"seowon",
  "layout":"res://scripts/survival/layout.gd","scene":"res://scripts/survival/world.gd",
  "tip":"연못과 아치 목교, 여섯 채의 한옥 사이로 숨으세요."},
 "gangnam":{"id":"gangnam","name":"서울 강남역","subtitle":"지하상가 · 승강장","short":"강남역",
  "accent":"7fd4ff","tint":"a9e6ff","arena":"gangnam",
  "layout":"res://scripts/survival/gangnam_layout.gd","scene":"res://scripts/survival/gangnam_world.gd",
  "tip":"개찰구·에스컬레이터·자판기·CCTV·조명·셔터를 활용해 숨고 쫓으세요."},
 "haeundae":{"id":"haeundae","name":"부산 해운대","subtitle":"전통시장 · 백사장 · 동백섬","short":"해운대",
  "accent":"7fe4d6","tint":"b9f1ff","arena":"haeundae",
  "layout":"res://scripts/survival/haeundae_layout.gd","scene":"res://scripts/survival/haeundae_world.gd",
  "tip":"좁은 시장 골목과 백사장 파라솔 사이로 숨고, 파도 경보와 밀물을 살피세요."},
 "dongseongno":{"id":"dongseongno","name":"대구 동성로","subtitle":"별빛랜드 · 아케이드 · 반월당","short":"동성로",
  "accent":"ff8ad8","tint":"ffd0f2","arena":"dongseongno",
  "layout":"res://scripts/survival/dongseongno_layout.gd","scene":"res://scripts/survival/dongseongno_world.gd",
  "tip":"도술네컷 플래시와 오락실 소음, 환풍기 연기를 이용해 골목을 뒤집으세요."}}
## 지금 경기에서 쓰는 맵. rules가 만들어질 때 이 값으로 충돌·스폰·사물이 정해진다.
static var current_id: String="seowon"
## 테스트·디버그용 지정값("random"/"seowon"/"gangnam"). random이면 매 경기 무작위.
static var preferred: String=RANDOM

static func ids() -> Array:return ORDER.duplicate()
static func exists(id: String) -> bool:return INFO.has(id)
static func info(id: String="") -> Dictionary:
 var key: String=id if id!="" else current_id
 return INFO.get(key,INFO["seowon"])
static func name_of(id: String="") -> String:return String(info(id).get("name","월하의 서원"))
static func name() -> String:return name_of(current_id)
static func subtitle_of(id: String="") -> String:return String(info(id).get("subtitle",""))
static func accent_of(id: String="") -> Color:return Color(String(info(id).get("accent","e8c98b")))
## 빠른 매치용 무작위 선택. preferred가 특정 맵이면 그 맵을 따른다.
static func pick(rng: RandomNumberGenerator=null) -> String:
 if exists(preferred):return preferred
 var index: int=0
 if rng!=null:index=posmod(rng.randi(),ORDER.size())
 else:index=absi(randi())%ORDER.size()
 return String(ORDER[index])
static func set_preferred(value: String) -> String:
 preferred=value if (value==RANDOM or exists(value)) else RANDOM
 return preferred
static func set_current(id: String) -> String:
 current_id=id if exists(id) else "seowon"
 return current_id
## 지금 맵의 레이아웃 스크립트(정적 함수·상수를 그대로 호출할 수 있다).
static func layout_of(id: String="") -> Script:
 var key: String=id if id!="" else current_id
 match key:
  "gangnam":return GANGNAM
  "haeundae":return HAEUNDAE
  "dongseongno":return DONGSEONGNO
 return SEOWON
static func layout() -> Script:return layout_of(current_id)
static func scene_of(id: String="") -> String:return String(info(id).get("scene","res://scripts/survival/world.gd"))
static func arena_of(id: String="") -> String:return String(info(id).get("arena","seowon"))
static func is_gangnam() -> bool:return current_id=="gangnam"
## 둔갑 사물 그림: 지금 맵의 props 폴더에서 찾는다(맵마다 사물이 다르다).
static func form_art_path(kind: String,id: String="") -> String:
 var key: String=id if id!="" else current_id
 if kind=="":return ""
 var folder: String="seowon" if key=="seowon" else key
 var path: String="res://assets/woo/%s/props/prop_%s.png"%[folder,kind]
 if ResourceLoader.exists(path):return path
 # 해운대·동성로는 props/ 아래에 원래 파일명으로 둔다.
 var alt: String="res://assets/woo/%s/props/%s.png"%[folder,kind]
 if ResourceLoader.exists(alt):return alt
 var legacy: String="res://assets/woo/%s/prop_%s.png"%[folder,kind]
 return legacy if ResourceLoader.exists(legacy) else ""
## 경기 시작 전 한 번 호출해 맵을 확정한다. room.map이 있으면 그것을, 없으면
## preferred(기본 random)를 따른다.
static func resolve(room_map: String="",rng: RandomNumberGenerator=null) -> String:
 if exists(room_map):return set_current(room_map)
 if room_map==RANDOM or room_map=="":return set_current(pick(rng))
 return set_current(room_map)
