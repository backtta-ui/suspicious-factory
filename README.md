# 도사: 전우치 — V0.1.1

Godot 4.6.3 / GDScript로 만든 Android 오프라인 싱글플레이 도술 어드벤처의 첫 플레이 버전입니다. 기존 GitHub 저장소와 Android 패키지·서명·내보내기 기반을 유지하고 게임을 전면 개편했습니다.

[갤럭시 APK 다운로드](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/jeon-woochi-0.1.1.apk)

Android 10 이상 ARM64 기기용, 가로 화면입니다. 삼성 내 파일 → 다운로드에서 APK를 눌러 기존 앱 위에 업데이트 설치합니다. 패키지 ID는 `com.suspiciousfactory.game`을 유지하므로 예전 수상한 공장 앱이 새 게임으로 바뀝니다. 앱 표시 이름은 ‘도사: 전우치’, versionName은 0.1.1, versionCode는 5입니다.

## 플레이

- 게임 시작: 계월촌에서 새 이야기를 시작합니다. 기존 전우치 저장 파일이 있으면 새 게임으로 대체합니다.
- 이어하기: 저장한 위치·마을·변신 상태·도술 해금을 복원합니다. 첫 실행에는 비활성화됩니다.
- 왼쪽 조이스틱: 8방향 이동. 오른쪽 달리기는 누르는 동안 동작합니다. 다른 손가락으로 조이스틱을 계속 사용할 수 있습니다.
- 둔갑술: 항아리로 변신하고, 대기시간이 끝나면 같은 버튼으로 인간으로 돌아옵니다. 항아리는 이동 속도가 느립니다.
- 주민 근처에서 대화 버튼, 우물 근처에서 조사 버튼이 표시됩니다.
- 메뉴: 카메라 부드러움·낮과 밤 변화 설정, 저장하고 메인 메뉴 복귀. Android 뒤로가기로 열린 창을 닫습니다.
- PC: WASD/방향키 이동, Shift 달리기, Space 둔갑술, E 상호작용, Esc 메뉴.

8초마다 자동 저장하며, 앱을 벗어날 때·메뉴 복귀·종료 시에도 저장합니다. 주민 대화와 메뉴가 열린 동안 이동 입력을 중지합니다. 로그인·외부 게임 서버·광고·인앱결제를 사용하지 않습니다.

## 현재 콘텐츠

원본 픽셀 도사와 8방향 캐릭터 시트, 한옥 4채, 돌길, 나무 12그루, 우물, 장터, 등불 5개, 마을 주민 3명이 있습니다. 쿼터뷰 바닥과 건물, 깊이 정렬, 그림자, 2D 조명과 낮·밤 분위기를 구현했습니다. 항아리 둔갑술에 변신 이펙트와 재사용 대기시간이 있습니다.

V0.1은 탐험·이동·변신·대화 기반입니다. 완성된 상용 HD-2D 아트, 본격적인 잠입 AI, 전투와 퍼즐 콘텐츠를 구현했다고 주장하지 않습니다. 실제 갤럭시 실행 검증은 사용자 확인이 필요합니다.

## 보존 및 개발

[기존 공장 백업](https://github.com/backtta-ui/suspicious-factory/tree/backup/suspicious-factory)은 미완성 V0.2 작업까지 포함한 `384c857`입니다. main에는 새 게임만 유지합니다. 이전 APK 파일도 배포 브랜치에서 보존합니다.

```text
scenes/main.tscn          진입 씬
scripts/main.gd           메뉴·HUD·대화·설정·저장·터치 연결
scripts/woo/actor.gd      도사·주민, 방향·이동·애니메이션·둔갑
scripts/woo/village*.gd   쿼터뷰 지형·한옥·조명·충돌·마을 데이터
scripts/woo/save_game.gd  검증·백업·원자적 저장
scripts/woo/mobile_button.gd  멀티터치 버튼
scripts/joystick.gd       기존 터치 조이스틱 재사용
scripts/touch_debug.gd    기존 입력 진단 재사용
assets/woo/              원본 픽셀 리소스
assets/fonts/            한글 폰트와 라이선스
```

Godot로 `project.godot`를 가져와 F5로 실행합니다. `bash tools/checkpoint.sh`는 게임·터치·저장·실제 프로세스 종료/재실행 검사 후 APK 빌드와 검증을 수행합니다. [빌드 안내](docs/BUILD.md), [전환·검증 보고서](docs/CONVERSION-V0.1.md), [개인정보 안내](docs/PRIVACY.md)를 참고하세요.

[Actions APK 아티팩트 실행 기록](https://github.com/backtta-ui/suspicious-factory/actions/runs/43703375678) — 게임은 Cloud에서 빌드했으며 이 작업은 해당 APK를 검사·보관합니다. 아티팩트 ZIP의 파일 일치 검증도 통과했습니다.

V0.1.1은 참고 이미지에 맞춰 타이틀, 한옥·벚나무·등불, 도사 8방향 시트와 주민·항아리, 금빛 UI를 교체했습니다. [그래픽 변경·검증 보고서](docs/VISUAL-V0.1.1.md)를 참고하세요.
