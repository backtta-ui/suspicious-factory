# V0.1.1 Android 터치 오류 수정

## 실제 원인과 재현 근거

엔진은 Godot 4.6.3 stable, UI는 CanvasLayer 아래 GDScript로 생성하는 Control/Button입니다. V0.1.0의 `project.godot`에는 `input_devices/pointing/emulate_mouse_from_touch=false`가 명시되어 있었습니다. 버튼은 기본 BaseButton 동작을 사용하므로 ScreenTouch가 GUI까지 전달돼도 마우스 버튼 이벤트로 변환되지 않으면 button_down / pressed 신호를 발생시키지 않았습니다. 기존 테스트는 메뉴 콜백을 직접 실행했으므로 이 실제 입력 경로를 검증하지 못했습니다.

동일한 버튼과 동일한 위치에 실제 `Input.parse_input_event(InputEventScreenTouch)`를 넣고 엔진 GUI 처리 결과를 비교했습니다. 임의로 pressed 시그널을 emit하거나 메뉴 콜백을 호출하지 않았습니다.

| 설정 | GUI의 ScreenTouch 수신 | 변환된 MouseButton 수신 | pressed 신호 | 설정 창 |
|---|---|---|---|---|
| false (V0.1.0) | 수신 | 없음 | 0 | 열리지 않음 |
| true (V0.1.1) | 수신 | 수신 | 1 | 열림 |

`tests/touch_ui.gd`는 기존 false 설정을 런타임에 재현하여 메인 버튼 3개 모두 동작하지 않는 것을 확인하는 음성 대조군 검사를 포함합니다. 이어서 수정 설정에서 같은 입력으로 실제 화면 전환을 확인합니다.

## 검사한 UI 및 좌표 경로

- 메인 버튼 3개는 disabled=false이며 pressed 시그널 연결이 존재했습니다.
- UI 루트와 배경 ColorRect는 MOUSE_FILTER_IGNORE였습니다. 버튼 위를 덮는 투명 입력 차단 노드는 원인이 아니었습니다.
- 버튼은 MOUSE_FILTER_STOP, 버튼을 놓았을 때 실행하는 ACTION_MODE_BUTTON_RELEASE를 명시했습니다. 최소 높이 64, 최소 너비 100의 논리 좌표 터치 영역을 사용합니다.
- 기존 CanvasLayer 구조를 유지합니다. 새 디버그 CanvasLayer의 전체 Control과 Label, 표식은 모두 IGNORE이며 입력을 소비하지 않습니다.
- stretch는 canvas_items, 1280×720 기준이며 기존 가로 모드와 immersive 설정을 유지합니다.
- 실제 Window 픽셀 좌표를 최종 Window 변환으로 계산해 주입하고, 엔진이 전달하는 논리 좌표가 버튼 중심과 일치하는지 검사했습니다. 게임 코드에서 좌표를 다시 나누거나 이중 변환하지 않습니다.
- 조이스틱은 원본 ScreenTouch/ScreenDrag를 처리하고 DEVICE_ID_EMULATION인 마우스 이벤트를 무시합니다. 실제 PC 마우스 조이스틱은 유지합니다.

## 수정한 동작

1. 터치→마우스 변환을 활성화했습니다. 반대 방향 마우스→터치 변환은 끕니다.
2. 기존 눌림 색상 스타일을 유지하고 모든 메뉴 버튼에 내려감·올라감·pressed 로그를 연결했습니다. 눌림 상태와 실제 색상 차이를 검사합니다.
3. UI 동작을 deferred 호출로 실행하고 같은 이벤트 사이클에서 중복 전환을 막습니다. 공장 시작에도 중복 월드 생성 가드를 둡니다.
4. 설정 창을 연 동안 조이스틱의 입력 획득을 중지합니다. 닫으면 다시 활성화합니다.
5. Android 뒤로가기 및 Esc는 설정 창 닫기, 꾸미기에서 메인 메뉴 복귀로 처리합니다.
6. versionName=0.1.1, versionCode=2로 올립니다. 기존 서명키를 그대로 사용합니다.

캐릭터·맵·물리·카메라·외형 저장 기능은 유지합니다. 멀티플레이 기능은 추가하지 않았습니다.

## 임시 터치 디버깅

V0.1.1 디버그 APK는 화면에 터치 위치를 노란 원으로 표시하고 아래쪽에 최근 이벤트를 표시합니다. 로그는 Godot 출력과 앱 내부 `user://touch-debug.log`에 기록합니다. 로그 크기는 약 256KiB로 제한하고 닉네임·채팅·키·토큰은 기록하지 않습니다.

- DOWN / UP: 손가락 ID, 논리 좌표, Window 좌표, Viewport 크기, 화면, 해당 위치 버튼과 disabled 상태
- DRAG: 조이스틱이 소비하기 전 드래그 좌표 (100ms 간격)
- MOUSE: 변환 여부와 좌표
- GUI / BUTTON_DOWN / BUTTON_UP / PRESSED: 버튼 이름과 사각형
- SCREEN / MODAL: 실제 화면 전환과 설정 열기·닫기

이 순서로 엔진 입력 누락, 좌표 불일치, GUI 전달 누락, 버튼 신호 누락, 화면 전환 실패를 구분할 수 있습니다. 배포용 release 빌드에서는 기본 비활성화됩니다.

## 검증 결과와 한계

- 기존 게임 테스트: 33개 통과
- 입력→GUI→신호→화면 전환 터치 테스트: 180개 통과
- 실제 Linux OpenGL 렌더링에서 같은 180개 검사 통과 및 화면 캡처
- 생성된 APK의 리소스를 추출해 desktop headless Godot로 실행한 180개 검사도 통과. 이것은 Android OS 실행을 대신하지 않습니다.
- APK 검사 18개: 서명, Manifest, API 29 이상, ARM64, 가로 모드, 정렬, 리소스 등 통과
- V0.1.0과 서명 인증서가 같음을 비교 확인

테스트 해상도는 1280×720, 2400×1080, 2340×1080, 2280×1080, 1920×1080, 960×540입니다. 0.75배·1배·1.5배 좌표 배율과 가로 여백, 그리기 영역 축소를 포함합니다. 실제 Android의 디스플레이 배율 설정·노치·전체 화면 제스처·3버튼 내비게이션 전환은 갤럭시 실측이 필요합니다.

**V0.1.1을 실제 갤럭시나 Android 에뮬레이터에서 실행하지 않았습니다.** 실기기 완료로 보고하지 않습니다.

## 휴대폰 확인 순서

기존 앱을 삭제하지 말고 V0.1.1 APK를 내려받아 업데이트 설치합니다. 타이틀 오른쪽 버전 0.1.1을 확인한 후 아래를 수행합니다.

1. 설정을 누른 채 잠깐 유지: 색상이 바뀌어야 합니다. 손을 놓으면 휴식 화면이 열려야 합니다.
2. 뒤로가기: 메인 메뉴가 보여야 합니다.
3. 캐릭터 꾸미기: 파란/초록 모자와 파란/초록 조끼를 각각 바꾸고 메인 메뉴로 돌아옵니다.
4. 공장 들어가기: 캐릭터와 맵이 나타나야 합니다.
5. 조이스틱을 끌면 이동하고 손을 놓으면 멈춰야 합니다.
6. 여전히 실패하면 노란 터치 원과 화면 아래 디버그 줄이 보이는 화면을 공유합니다. 휴대폰 모델, Android 버전, 표시된 게임 버전도 함께 확인합니다.

## 파일

동작 수정: `project.godot`, `export_presets.cfg`, `scripts/main.gd`, `scripts/joystick.gd`, `scripts/touch_debug.gd`.
검증: `tests/touch_ui.gd`, `tools/build_android.sh`, `tools/test.sh`, `.github/workflows/android-apk.yml` (터치 로그 artifact 추가).
결과: `builds/test-results.txt`, `builds/touch-test-results.txt`, `builds/touch-rendered-results.txt`, `builds/touch-apk-assets-results.txt`, `builds/apk-verification.json`.

`bash tools/checkpoint.sh`는 이제 게임 검사와 180개 터치 검사에 모두 성공해야 APK를 빌드·검증합니다. 원격 GitHub Actions 설정은 유지했습니다. 이번 수정은 기존과 같은 Cloud 빌드 후 `apk-downloads` 브랜치 전달 방식이며, GitHub Actions 원격 실행 성공이라고 주장하지 않습니다.
