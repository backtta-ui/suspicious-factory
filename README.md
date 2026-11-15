# 수상한 공장 — 1차 플레이 테스트

실제 Godot 4.6.3 / GDScript 2D 게임 프로젝트입니다. 버전 **0.1.0**은 V1.0으로 가는 첫 이동 테스트이며, 멀티플레이와 추리 규칙은 아직 없습니다.

## 갤럭시에서 실행

1. `builds/suspicious-factory-0.1.0.apk`를 휴대폰에 내려받습니다.
2. 내 파일 → 다운로드에서 APK를 엽니다. 요청이 나오면 해당 브라우저 또는 내 파일의 ‘이 출처 허용’을 켭니다. 기기 정책에 따라 ‘보안 및 개인정보 보호 → 보안 위험 자동 차단’이 설치를 제한할 수 있습니다.
3. 설치한 **수상한 공장**을 실행합니다. Android 10 이상, ARM64 기기가 필요합니다.
4. ‘캐릭터 꾸미기’에서 닉네임·모자·조끼를 고른 뒤 ‘출근하기’를 누릅니다.
5. 왼쪽 아래 조이스틱을 손가락으로 밀면 이동합니다. 노란 ! 근처에서는 오른쪽 ‘설비 확인’으로 설명을 볼 수 있습니다.

인터넷 접속이나 계정이 필요 없고 서버 비용도 없습니다. APK는 개발용 디버그 서명입니다. Google Play 배포용 파일이 아닙니다.

## 현재 구현

- 가로 화면 / 화면 크기에 맞춰 조정되는 UI / 시작 화면·앱 아이콘
- 메인 메뉴, 캐릭터 꾸미기, 닉네임, 카메라 설정의 기기 내 저장
- 흰 둥근 얼굴·분홍 볼·베이지 작업복·검은 바지·노란 넥타이·명찰
- 모자 없음/파랑/초록 × 조끼 없음/파랑/초록: 독립적인 9가지 조합
- 코드로 그리는 임시 캐릭터와 공장 그래픽, 대기·걷기 움직임
- 생산라인, 조립실, 창고, 전기실, 기계실, 휴게실, 사무실, 중앙 복도
- 컨베이어·로봇팔·설비·상자·책상·배관과 물리 충돌
- 터치 조이스틱, 두 손가락 입력 구분, PC 키보드 이동
- 캐릭터 추적 카메라와 맵 경계 제한
- 방문 구역·이동 거리 표시, 설비 안내, 일시정지, 백그라운드 전환 후 수동 재개

설비 확인은 안내 기능입니다. 미션 완료를 가장하는 기능은 없습니다. 방 만들기·참가 버튼은 실제 네트워크 구현 이후 추가합니다.

## 프로젝트 구조

```text
project.godot           엔진·화면·폰트 설정
export_presets.cfg     Android 테스트 내보내기 설정
scenes/main.tscn        진입 씬
scripts/main.gd        메뉴·꾸미기·HUD·일시정지·저장
scripts/worker.gd      캐릭터 외형·이동·충돌
scripts/factory.gd     맵·설비·충돌체·설비 안내 위치
scripts/joystick.gd    터치·마우스 조이스틱
assets/               아이콘·한글 폰트 및 라이선스 고지
.android-template/    빌드 때 생성하는 Android 10 템플릿 (소스 제외)
tests/stage1.gd        실제 씬·물리·터치 기반 자동 검증
tools/                빌드·테스트 스크립트
docs/                 설치·빌드·단계별 검증 및 후속 설계
builds/               APK·검증 로그·화면 캡처 (게임 리소스 제외)
```

## PC 실행

Godot **4.6.3 stable**로 `project.godot`를 가져온 후 F6가 아니라 **F5**로 실행합니다. 방향키/WASD 이동, E 설비 확인, Esc 설정을 지원합니다. 마우스로 조이스틱을 끌 수도 있습니다.

```bash
godot --path .
bash tools/test.sh
```

빌드 절차는 [docs/BUILD.md](docs/BUILD.md), 휴대폰 점검표와 검증 한계는 [docs/TESTING.md](docs/TESTING.md)를 참고하세요.

## PC 없는 휴대폰 테스트 전달

[갤럭시 테스트 APK 직접 다운로드](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/suspicious-factory-0.1.0.apk) — 공개 HTTPS 재다운로드 및 SHA256 일치 검증을 완료했습니다. 삼성 내 파일 → 다운로드에서 APK를 열어 설치하세요. [전달 방식과 자동 검증 상태](docs/MOBILE-DELIVERY.md)를 참고하세요.

이후 주요 기능 변경의 필수 검증 명령은 `bash tools/checkpoint.sh`입니다. 자동으로 게임 테스트와 APK 빌드·서명·설정·정렬 검증을 실행하고 `builds/apk-verification.json`에 결과를 기록합니다. `.github/workflows/android-apk.yml`은 GitHub 연결 후 사용할 자동 빌드·테스트 APK 전달 준비 파일이며 아직 원격 실행되지 않았습니다.
