# 수상한 공장 — 갤럭시 테스트 APK

## 최신 버전 V0.1.1: Android 버튼 터치 오류 수정

[최신 APK 다운로드](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/suspicious-factory-0.1.1.apk)

약 42MB, Android 10 이상 ARM64, 가로 화면. 삼성 내 파일 → 다운로드에서 APK를 열어 기존 앱 위에 업데이트 설치하세요. 같은 테스트 서명키를 유지했고 versionCode를 2로 올렸습니다.

터치→마우스 변환이 꺼져 기본 Godot 버튼의 pressed 신호가 발생하지 않던 문제를 수정했습니다. 버튼 피드백, 손을 놓을 때 실행, 중복 화면 전환 방지, 뒤로가기와 조이스틱의 변환 입력 중복 방지도 검증했습니다.

게임 검사 33개, 실제 입력 경로 터치 검사 180개, APK 검사 18개가 통과했습니다. Linux 렌더링 및 APK 추출 리소스로 같은 터치 검사를 반복했습니다. V0.1.1 갤럭시 실기기 실행은 아직 확인하지 않았습니다.

메뉴에서 설정 → 뒤로가기, 꾸미기 → 모자·조끼 선택, 공장 들어가기 → 조이스틱 이동 순서로 확인하세요. 노란 터치 원과 화면 아래 진단 줄은 임시 디버깅 기능입니다.

[원인·수정·테스트 상세](reports/0.1.1/TOUCH-FIX-0.1.1.md) / [소스](https://github.com/backtta-ui/suspicious-factory/tree/main)

V0.1.0 APK는 보존하지만 메인 버튼 터치 오류가 있으므로 최신 0.1.1을 사용하세요. SHA256SUMS.txt에는 두 파일의 체크섬이 있습니다. 키·토큰은 포함하지 않습니다.
