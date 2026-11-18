class_name WooPracticeCatalog
extends RefCounted
const Online=preload("res://scripts/seal/catalog.gd")
const NOTES={"transform":"가까운 사물·동물에서 형상 추출 → 도술 사용. 인간으로 복귀할 수 있습니다.","blink":"바라보는 방향으로 축지합니다. 벽과 사물을 통과하지 않습니다.","clone":"같은 외형의 분신이 이동합니다. 훈련 요괴의 시선을 끌어보세요.","track":"산책하는 훈련 NPC가 남긴 최근 발자국을 탐지합니다.","shield":"훈련 공격·포획을 한 번 방어합니다. 방어 뒤 보호 시간이 생깁니다.","smoke":"연막 안에서는 먼 NPC가 보이지 않으며 요괴도 나를 놓칩니다.","mask":"얼굴과 신원을 감춥니다. 훈련 요괴가 가까이서만 식별합니다.","rescue":"감옥의 도사를 더 빠르게 구출합니다. 사용 뒤 가까이서 상호작용하세요.","capture":"가까운 훈련 도사를 감옥으로 포획합니다.","darkness":"어둠으로 시야를 가리고 가까운 봉인 표적을 방해합니다.","fake_flame":"가짜 혼불로 훈련 NPC를 유인합니다.","shadow":"벽을 통과하지 않는 긴 그림자 이동입니다.","mimic":"가까운 도사의 외형과 색상을 복제합니다. 실제 ID는 유지됩니다.","talisman":"전방의 표적에 부적 피해와 짧은 봉인을 적용합니다."}
static func all() -> Dictionary:
 var out: Dictionary=Online.COMMON.duplicate(true);out.merge(Online.EVIL.duplicate(true))
 out.talisman={"name":"부적술","cd":preload("res://scripts/woo/action_config.gd").TALISMAN_COOLDOWN,"duration":1.4,"icon":"talisman"}
 out.transform.duration=preload("res://scripts/seal/settings.gd").DEFAULTS.transform_seconds
 for id in out:out[id].description=NOTES[id]
 return out
static func canonical(id: String) -> String:return "transform" if id=="jar" else id
