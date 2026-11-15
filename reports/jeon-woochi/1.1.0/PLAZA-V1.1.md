# 《도사》 V1.1 — 확장 광장·음악·입장 연출

## 기존 프로젝트 확인과 보존

실제 사용 엔진은 Godot 4.6.3 stable, GDScript, GL Compatibility입니다. 작업 전 저장소의 실제 버전은 V0.1.2였으며, 기존 코드의 checkpoint APK 빌드와 검사를 통과한 뒤 `backup/jeon-woochi-v0.1.2` 브랜치(`b49327a`)를 원격에 보존했습니다. 기존 공장 백업과 이전 APK도 유지합니다. 저장소를 새로 만들지 않았습니다.

이번 앱 표시는 V1.1, Android versionName은 `1.1.0`, versionCode는 `7`입니다. 패키지 `com.suspiciousfactory.game`, 기존 서명 인증서, 최소 Android 10 / API29, target36, ARM64, 가로 화면을 유지합니다. 기존 앱 위에 업데이트 설치해야 저장 파일을 이어서 사용할 수 있습니다.

## 실제 맵 규모

- 맵 렌더링 범위: 1800×960 → **3400×1900 월드 단위**.
- 이동 경계 다각형 자체를 확장했습니다. 카메라 확대율 2.0과 캐릭터 이동 속도는 유지합니다.
- 40단위 격자로 같은 `can_stand()` 판정에 캐릭터 반경을 적용한 비교: 기존 668,800 → 새 3,739,200 제곱 단위, **약 5.59배**. 이는 격자 표본 추정이며, 전체 직사각형 픽셀 면적을 이동 면적으로 주장하지 않습니다.
- 각 구역까지 연결 경로를 찾고, 실제 CharacterBody2D와 이동 입력을 사용해 다섯 구역까지 걸어가는 검사를 수행합니다. 테스트에서 시간을 가속할 뿐 게임 속도는 변경하지 않습니다.

## 다섯 구역

| 구역 | 구현 내용 |
|---|---|
| 중앙 벚꽃 광장 | 천년 벚꽃나무, 원형 돌 모자이크, 석등·전통 등불, 휴식 의자, 화단, 우물, 기존 주민 |
| 신비로운 그림 장터 | 그림 보관소, 독립된 족자 진열대 3개, 그림지기, 은은한 빛, 접근 감지·소개창 |
| 조선 상점 거리 | 주막·먹거리 노점·부적방·도술 도구점·잡화점·창고, 상인·수레·항아리·상품 진열·간판 |
| 벚꽃 정원과 연못 | 충돌 가능한 연못, 실제 건너는 돌다리, 정자·대나무·벚나무·석등·반딧불이, 물결 |
| 도술 수련소 | 사당, 도술 스승, 부적이 붙은 수련 허수아비와 나무 지지대, 둔갑 연습 공간 |

그림은 ‘여우의 숲’, ‘탐관오리의 관아’, ‘도깨비의 밤’입니다. 가까이서 ‘그림 보기’를 터치하면 이름·이야기 소개와 비활성 ‘준비 중’ 버튼을 표시합니다. 닫으면 이동을 다시 허용합니다. 세 그림 속 스테이지는 **아직 구현하지 않았고 입장 가능한 것처럼 표시하지 않습니다.**

상점은 외형·상인 대화·상품 장식까지 구현했으며 구매·경제 시스템은 추가하지 않았습니다. 신규 도술·전투·잠입 임무·고양이/강아지는 추가하지 않았습니다. 기존 항아리 둔갑은 유지합니다.

## 그래픽과 검은 공간 수정

전체 세계를 한 장의 AI 배경으로 붙이지 않습니다. 실제 지형 데이터, 정적인 바닥 재질, 독립된 건물·장식 Sprite2D, 별도의 물 표면, 충돌체, 주민과 플레이어를 Y 깊이 순서로 구성합니다.

- 새로운 한옥·주막·부적방·사당·정자·큰 벚꽃나무·대나무 아틀라스, 그림 3종·먹거리·수레·장독·허수아비·석등 아틀라스와 잔디 재질을 생성해 사용합니다. 원본은 별도로 보존하고 잘라 편집하지 않고 아틀라스 영역으로 표시합니다.
- 세밀한 잔디·꽃잎·자갈 재질 위에 불규칙한 돌길, 흙 가장자리, 구역별 마당을 개발 시점에 렌더링합니다. 돌길과 돌다리는 사전 렌더링해 휴대폰에서 수천 번의 정적 그리기를 반복하지 않습니다.
- 건물·나무·물·지도 경계 충돌은 시각 이미지와 별도 데이터입니다. 돌다리의 통과 구간과 물 충돌 구간도 분리합니다.
- 바닥이 카메라의 전체 허용 범위를 덮습니다. 이전 다이아몬드 바깥의 빈 부분을 잔디·숲·울타리·돌 경계로 채우고, 북쪽 산 실루엣을 고정 원경으로 둡니다. 이전처럼 카메라를 따라다니는 산·달 그림을 바닥 위에 겹치지 않습니다.
- 카메라 offset을 없애 경계를 넘어 밀리지 않게 하고, 가로로 긴 Android 화면에는 viewport/aspect expand를 적용해 좌우 레터박스를 줄입니다. 상단 메뉴와 행동 버튼은 오른쪽 앵커를 사용합니다.
- 밤과 낮은 기존 시간 시스템을 이어 쓰며, 밤에도 길과 캐릭터를 읽을 수 있게 밝기를 조정합니다. 등불은 가산 혼합 이미지이며 실시간 PointLight2D는 사용하지 않습니다.

## 입장 전 화면과 소리

메인 메뉴의 기존 일러스트에는 느린 줌·패닝·약한 빛 변화와 별도의 벚꽃잎을 적용했습니다. 버튼은 움직이는 이미지와 분리해 고정된 터치 영역을 유지합니다. ‘환경 효과: 간소화’에서는 움직임과 입자 수를 줄입니다.

기존 전자음 효과를 교체했습니다. Kenney의 CC0 RPG 녹음 샘플을 편집해 버튼 옷깃 소리, 종이 넘김, 발걸음 3종, 항아리 소리를 만들고, 실제 방울 녹음과 옷깃 소리를 섞어 둔갑 효과를 구성했습니다. 음량 정규화·피크 제한·EQ·페이드로 믹스를 맞췄습니다.

배경음악은 공유마당의 **‘국악 배경음악 #131’(공유마당 / 한국저작권위원회, CC BY 4.0)**을 앱에 포함합니다. 약 72초 원본의 끝·처음을 겹쳐 루프를 만들고 Ogg Vorbis로 인코딩했습니다. 다운로드는 개발 단계에만 수행하며 게임에서는 인터넷 없이 재생합니다.

‘배경음악’과 ‘효과음’ 설정은 독립적으로 저장됩니다. 메뉴·광장·대화 상황에 따라 음악 음량을 부드럽게 조절하고, 앱이 백그라운드에 들어가면 음악과 효과음을 중지·일시정지합니다. 소리 풀은 최대 6개로 제한합니다.

전체 출처·라이선스·편집 내역은 [음원 고지](../assets/audio/NOTICE.txt), 게임 설정의 ‘음원 출처’, APK에 포함한 NOTICE.txt에서 확인할 수 있습니다.

## 저장 호환성과 확장 준비

기존 파일명·스키마1·캐릭터 위치·항아리 상태·둔갑 해금·어른 대화 진행·설정을 유지합니다. 새 충돌체가 원래 좌표를 차지하는 경우에만 가까운 안전한 위치로 옮기며, 원래 위치를 `legacy_position`으로 보존합니다. 저장 백업과 자동 저장 스레드도 유지합니다.

선택적 `map_revision`, `completed_paintings`, `return_anchor`를 추가했습니다. 그림 소개 시 진입 위치를 기록하고, 향후 스테이지에서 돌아올 때 그 위치를 복원하는 함수가 있습니다. 실제 임무가 없으므로 임의의 완료 보상은 지급하지 않습니다. 천년 벚꽃나무는 완료 ID 목록을 받아 금빛 기억을 표시하도록 연결했으며, 현재 정상 새 게임의 완료 목록은 빈 상태입니다.

## 검증

필수 `bash tools/checkpoint.sh`가 게임 53, 터치 125, 저장 복구 11, 효과음·비동기 저장 20, 확장 광장 50개 검사(총 259개), 프로세스 write/read/exit, APK 검사 25개를 수행합니다. 광장 검사는 실제 구역 이동·연못 충돌·돌다리 횡단·그림의 네이티브 터치·잠금 표시·복귀 좌표·기존 저장 이전·완료 데이터 연동을 포함합니다.

추가로 실제 APK 리소스를 추출해 데스크톱 Godot에서 같은 광장 검사, 메인 메뉴 움직임, 다섯 구역·카메라 경계·와이드 화면 렌더링을 검사합니다. 렌더 예산 검사는 구역마다 60프레임 워밍업 후 180프레임을 측정하고 평균 그리기 호출 500회 이하를 확인합니다. 결과는 버전별 JSON과 로그로 제공합니다.

**갤럭시/Android OS 실기기 실행·발열·실제 60FPS·스피커 청취를 직접 검증하지 않았습니다.** Linux 소프트웨어 OpenGL 렌더러의 검사와 프레임 시간은 휴대폰 FPS 측정이 아닙니다. 사용자는 ‘설정 → 환경 효과 → 간소화’로 입자·물결·메뉴 움직임을 줄일 수 있습니다.

## 재현 및 빌드

```bash
bash tools/checkpoint.sh
# 실제 렌더링이 가능한 환경에서 실행:
godot --path . --script res://tests/plaza_visual.gd
godot --path . --script res://tests/plaza_render_budget.gd
# 지형·돌다리 재생성:
godot --path . --script res://tools/bake_ground.gd
```

결과 APK: `builds/jeon-woochi-1.1.0.apk`. 기존 Actions 파일 전달 워크플로를 사용하고, 공개 HTTPS 주소와 Actions 아티팩트를 다시 다운로드해 SHA256을 확인한 뒤 제공할 예정입니다. 게임 재컴파일은 Cloud checkpoint가 수행하며, Actions의 파일 검증·전달 성공과 구분합니다. 공개 저장소의 기존 표준 호스팅 러너를 사용하며 유료 게임 서버나 새 서비스는 추가하지 않았습니다.

## 최종 APK 검증 수치

- APK: 65497063바이트 / SHA256 `c3f97c18cad68a65bc7d1047e3467f7ccb6080621b2510723d84e89100b7d2e3`. 기존 V0.1.2 공개 APK와 서명 인증서 일치.
- 최종 패키지 리소스 광장 검사 50개 통과. 메뉴 움직임·고정 버튼·네 경계 카메라·1600×720 와이드 내부 화면 검사 통과.
- 메뉴 두 프레임의 약 69.3% 픽셀이 변화했으며 버튼 내부는 픽셀 변화가 없어 배경만 움직이는 것을 확인했습니다.
- 구역별 평균 그리기 호출: plaza 274.0회, paintings 258.0회, shops 242.0회, garden 264.4회, training 264.0회. 모든 구역 500회 예산 이하. llvmpipe 소프트웨어 렌더러 결과이며 Android FPS는 아닙니다.
- 물의 반사광·물결은 가벼운 셰이더 표현이며 실시간 장면 반사는 구현하지 않았습니다. NPC 8명은 기존 3종 캐릭터 시트의 외형을 재사용합니다.

## 변경 파일 목록

```text
.github/workflows/deliver-apk.yml
README.md
assets/audio/NOTICE.txt
assets/audio/button.wav
assets/audio/dialogue.wav
assets/audio/jar_step.wav
assets/audio/moonlit_plaza.ogg
assets/audio/moonlit_plaza.ogg.import
assets/audio/provenance.json
assets/audio/spell.wav
assets/audio/step.wav
assets/audio/step2.wav
assets/audio/step2.wav.import
assets/audio/step3.wav
assets/audio/step3.wav.import
assets/woo/ground_baked.png
assets/woo/v11/decor_atlas.png
assets/woo/v11/decor_atlas.png.import
assets/woo/v11/decor_atlas_frames.json
assets/woo/v11/meadow.png
assets/woo/v11/meadow.png.import
assets/woo/v11/stone_bridge.png
assets/woo/v11/stone_bridge.png.import
assets/woo/v11/village_atlas.png
assets/woo/v11/village_atlas.png.import
assets/woo/v11/village_atlas_frames.json
docs/BUILD.md
docs/PLAZA-V1.1.md
export_presets.cfg
project.godot
scripts/main.gd
scripts/woo/menu_motion.gd
scripts/woo/menu_motion.gd.uid
scripts/woo/minimap.gd
scripts/woo/petals.gd
scripts/woo/save_game.gd
scripts/woo/scenery.gd
scripts/woo/sound.gd
scripts/woo/terrain.gd
scripts/woo/terrain.gd.uid
scripts/woo/village.gd
scripts/woo/village_layout.gd
scripts/woo/village_prop.gd
scripts/woo/water.gd
scripts/woo/water.gd.uid
tests/fixtures/legacy_v012_layout.gd
tests/fixtures/legacy_v012_layout.gd.uid
tests/plaza_render_budget.gd
tests/plaza_render_budget.gd.uid
tests/plaza_v11.gd
tests/plaza_v11.gd.uid
tests/plaza_visual.gd
tests/plaza_visual.gd.uid
tests/sound_performance.gd
tests/woo_core.gd
tools/bake_ground.gd
tools/prepare_audio.py
tools/test.sh
tools/verify_apk.py
```

최종 APK 리소스의 다섯 화면 크기 렌더링·네이티브 터치 검사 125개도 통과했습니다. 효과음 PCM 비무음·피크 제한 및 원본 출처 해시 검사도 통과했습니다.
