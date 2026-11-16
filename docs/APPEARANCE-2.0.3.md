# 외형 조합 수정 — 2.0.3 / versionCode 14

기존 V2.0 게임에 적용하는 꾸미기 수정 빌드입니다. 패키지, 서명, 저장 파일, 아이템 ID 및 획득 조건은 유지합니다. 작업 전 상태는 `backup/dosa-2.0.2-appearance` (`a604d9d`)에 보존했습니다.

## 실제 원인과 수정

- 기존 `layers.png` 얼굴 이미지 자체에 원래 헤어·꽃 장식이 포함되어 있었습니다. 얼굴의 직사각형 일부를 잘라도 헤어가 남아 다른 헤어와 중복되었습니다. 원본 의상·모자·장신구는 보존하고, 머리 없는 얼굴 4개 / 뒷머리 6개 / 앞머리 6개를 분리한 `head_parts.png`를 추가했습니다.
- 긴 머리가 의상 뒤가 아닌 위에 그려졌습니다. 실제 Actor의 자식 순서를 그림자 → 뒷머리/등 장식 → 기존 몸체 → 의상/얼굴/앞머리/모자로 분리했습니다. 전역 Z 순서를 바꾸지 않아 월드의 캐릭터 Y 정렬을 유지합니다.
- 모자 착용 때 앞머리 전체를 줄였고 모든 캐릭터에 동일한 좌표를 적용했습니다. `compatibility.gd`에서 캐릭터별 얼굴·머리·모자 보정, 의상별 목선, 모자별 착용 높이·가림 규칙을 관리합니다. 모자 종류가 바뀌어도 헤어의 원래 크기·등록 좌표는 유지하고 가려지는 부분을 셰이더로 처리합니다. 두건은 얼굴 노출 영역, 여우 가면은 얼굴 착용 규칙을 사용합니다. 후면에서 얼굴/가면과 앞쪽 턱끈을 표시하지 않습니다.
- 기본 캐릭터의 머리 분할선이 원본 셔츠 일부까지 포함했고, 의상 소매는 어깨가 아닌 그림 좌상단을 중심으로 회전했습니다. 분할선을 목 위로 올리고 소매 회전축을 어깨로 옮겼습니다. 원래 전우치 기본 차림은 기존 원본 스프라이트를 계속 사용합니다.
- 캐릭터 선택 이벤트가 헤어·의상·모자·색상까지 기본값으로 덮어썼습니다. 캐릭터 ID만 변경하도록 수정했습니다. 미리보기는 임시 draft, 저장은 기존 Profile.equip, 취소는 draft 폐기를 사용합니다.

## 구현 범위와 남은 점

모든 캐릭터에 6개 헤어, 7개 모자(없음 포함), 8개 의상을 조합할 수 있습니다. 장신구의 등/허리 부착 순서를 분리했습니다. 기존 목록에 별도 ‘붉은 머리’ ID는 없으므로 새 해금 아이템을 임의로 추가하지 않았습니다. 홍련 얼굴에 원래 붙어 있던 헤어/붉은 장식을 얼굴 데이터에서 제거해 선택한 헤어가 우선합니다.

렌더러는 정지·방향·걷기·점프·착지·공격 상태를 외형 데이터와 분리합니다. 점프할 때 뒷머리·몸체·앞쪽 외형의 높이만 함께 바뀌며 그림자는 지면에 남습니다. 광장, 모험, 수련장, 멀티플레이는 기존 공통 WooActor를 사용합니다. 네트워크 외형 프로토콜과 서버 역할/장착 규칙은 변경하지 않았습니다.

꾸미기 화면은 최고점의 점프까지 미리보기 영역 안에 들어가도록 고정 배율을 맞췄습니다. 모자/동작에 따라 배율이 달라지지는 않습니다. 걷기·점프·공격 버튼을 다시 누르면 정지 미리보기로 돌아갑니다.

장식 에셋은 기존 정면 아트를 재사용합니다. 모든 의상에 새 8방향 수작업 원화를 제작한 것은 아니며, 측면은 기존 방식처럼 좌우 반전과 공통 관절 동작을 사용합니다. 픽셀 단위의 모든 조합을 사람이 미술 검수한 것은 아닙니다.

## 비교 화면

동일한 카메라·배율·16개 조합을 실제 게임 렌더러로 출력했습니다. 게임 배경에 콘셉트 이미지를 붙인 결과가 아닙니다.

| 수정 전 | 수정 후 |
|---|---|
| ![수정 전](appearance-2.0.3/before.png) | ![수정 후](appearance-2.0.3/after.png) |

[모자 없는 헤어](appearance-2.0.3/uncovered.png) · [방향·걷기·점프·공격](appearance-2.0.3/poses.png) · [실제 꾸미기 화면](appearance-2.0.3/game.png) · [최고점 점프](appearance-2.0.3/game-jump.png) · [광장](appearance-2.0.3/plaza.png) · [여우의 숲](appearance-2.0.3/forest.png)

## 검증

`tests/appearance_combinations.gd`는 4×6×7×8 = 1,344개 조합과 각 8방향/점프/공격 상태, 장신구·색상, 공통 기준점, 얼굴/헤어 분리, 잠금 상태, 저장/취소, 광장/모험을 검사합니다. 별도 프로세스 쓰기/읽기는 기존 version1 외형·알 수 없는 보유 아이템·별도 진행 파일이 유지되는지 검사합니다.

실제 그래픽 드라이버로 1,344개 Actor를 11페이지에 걸쳐 렌더링했습니다. 재현 명령:

```sh
godot --path . --audio-driver Dummy --script res://tests/appearance_render.gd -- --phase=gallery
godot --path . --audio-driver Dummy --script res://tests/appearance_render.gd -- --phase=after
bash tools/checkpoint.sh
```

검증 실행 결과·GitHub 링크·APK 체크섬은 최종 검증 기록에 첨부합니다. Galaxy 실기기, 공개 서버에 연결한 Android 기기 간 외형 확인은 이 Cloud 환경에서 수행하지 않았습니다.

## 휴대폰 확인

기존 앱을 삭제하지 말고 업데이트 설치한 후 **이어하기**를 사용하세요. 도사 꾸미기 → 연화/은백색/두건 → 방향·걷기·점프·공격 → 저장 → 광장/그림 속 모험 확인 → 앱 종료·재실행 → 이어하기로 점검합니다. 미보유 캐릭터/의상은 미리보기만 가능하고 기존 조건을 충족해야 저장됩니다.


## 최종 결과

- 캐릭터별 전우치/연화/무영/홍련 각각 **336개 기본 조합**의 등록 좌표·레이어·8방향/점프/공격 검사 통과. 4캐릭터×9장신구(없음 포함)×6색상도 검사했습니다. 합계 **외형 21,848개 항목, 실패 0**입니다.
- **기존 기능 786개 검사, 실패 0**. 정지/걷기/점프/공격, 저장 및 취소, 별도 프로세스 재실행, 광장/모험 일치와 기존 터치/전투/인벤토리/NPC/타이틀을 검사했습니다. 최종 APK에서 추출한 컴파일 게임 코드로도 외형 21,848개 검사를 다시 통과했습니다. 검사 드라이버만 테스트 소스를 사용하고 게임 코드는 APK의 GDC/리소스를 사용했습니다.
- 서버 회귀 검사는 Linux의 실제 WebSocket 서버와 자동화한 6명/8명 클라이언트로 수행했습니다. 외형 동기화/경기 중 변경 금지/재접속 검사 통과. **6~8대 Android 실기기 검사와 공개 서버 배포는 수행하지 않았습니다.**
- 실제 그래픽 드라이버로 1,344개 조합 전체를 렌더링했습니다. [11페이지 전체 이미지](appearance-2.0.3/)는 카탈로그 순서(캐릭터→헤어→모자→의상), 각 페이지 16열×8행입니다. 모든 픽셀에 대한 자동 미술 품질 보증이라는 뜻은 아닙니다.
- Android 정적 검사 **33개 통과**: 동일 서명, 동일 패키지, ARM64, 최소 API29, 타깃36, 가로 화면, 리소스·ZIP·네이티브 정렬 포함. 실제 Galaxy 설치/멀티터치/FPS는 미검증입니다.
- 로컬 최종 `bash tools/checkpoint.sh` 종료 코드 0. [컴파일·전체 테스트 Actions 성공](https://github.com/backtta-ui/suspicious-factory/actions/runs/43872229770). 앱 코드 기준 커밋 `04f5f39d794c35a0642e5ffe3ad532de1d03d8bd`. CI의 미서명 APK는 기존 Cloud 키로 최종 서명했습니다. 설치할 때는 아래 서명된 배포본을 사용하세요.

변경 파일 및 APK 체크섬/다운로드 검증 기록은 [APPEARANCE-2.0.3-VERIFICATION.json](APPEARANCE-2.0.3-VERIFICATION.json)에 있습니다. 수정된 게임 파일은 다음과 같습니다.

- `scripts/wardrobe/art.gd`, `compatibility.gd`, `hair_mask.gdshader`, `visual.gd`, `screen.gd`
- `assets/woo/wardrobe/head_parts.png` 및 Godot import/UID 파일
- `scripts/woo/actor.gd`, `scripts/woo/hero_rig.gd`
- `project.godot`, `export_presets.cfg`
- `tests/appearance_combinations.gd`, `appearance_restart.gd`, `appearance_render.gd`
- `tools/test.sh`, `tools/verify_apk.py`, `README.md`, 이 보고서와 비교 이미지

기존 `profile.gd`, 카탈로그/해금 조건, RPG 저장 스키마, 서버 프로토콜을 변경하지 않았습니다. 기존 보유 기록을 삭제하지 않았고, 예전 APK/배포 커밋도 보존했습니다.


## 서명된 APK 받기

[휴대폰 APK 바로 다운로드](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/255dacc5634be1882a492c7f8ba575621c444034/jeon-woochi-2.0.3.apk) · [설치용 ZIP Actions 성공](https://github.com/backtta-ui/suspicious-factory/actions/runs/43873837830)

PC 없이 삼성 인터넷에서 APK 링크를 열고 **내 파일 → 다운로드 → APK**로 설치합니다. 기존 앱을 삭제하지 말고 업데이트 설치한 후 **이어하기**를 누르세요. ChatGPT 내부에서 다운로드가 안 되면 링크를 길게 눌러 브라우저에서 여세요.

Actions를 이용하면 로그인 → 위 실행 화면 아래 **Artifacts → jeon-woochi-verified-apk** → ZIP 다운로드 → 내 파일에서 **압축 풀기** → 안의 APK 설치 순서입니다. 원본 컴파일 실행의 unsigned APK는 설치용이 아닙니다. Artifacts는 14일 보존되며, 직접 APK 주소는 별도 커밋에 보존됩니다.

최종 배포본은 85,088,825바이트(약 81.1 MiB), SHA256 `2750b5abad20a9b619841e97d984d699958bf35f2c4cd8be4967f12ca7a7c74b`입니다. 공개 HTTPS로 다시 받은 파일과 Actions ZIP 내부 APK 모두 동일 체크섬을 확인했습니다. 로컬 파일은 `/workspace/suspicious-factory/builds/jeon-woochi-2.0.3.apk`입니다.
