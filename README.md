# 도사: 전우치 V0.1.2 — 성능·효과음 업데이트

[APK 직접 다운로드 — 약 51MB](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/jeon-woochi-0.1.2.apk)

삼성 내 파일 → 다운로드에서 APK를 열어 기존 앱 위에 업데이트 설치하세요. Android 10 이상 ARM64, 가로 화면. 패키지·서명·저장 호환성을 유지합니다.

돌길 사전 렌더링, 가벼운 등불, 꽃잎 절감, 720p 내부 렌더링, 자동 저장 스레드와 터치 로그 기본 해제로 부하를 줄였습니다. 개발 소프트웨어 렌더러의 같은 장면에서 그리기 호출 10,902→151회. 갤럭시 FPS 측정은 아닙니다.

버튼·발걸음·항아리 이동·둔갑·대화 효과음 5종을 추가했습니다. 설정에서 효과음을 끌 수 있습니다. 네트워크 없이 재생합니다.

게임 53, 네이티브 터치 125, 저장 복구 11, 효과음·비동기 저장 20개 검사, 재실행 검사, APK 검사 23개 통과. 최종 패키지 리소스 실행·성능 비교 통과. 실기기 FPS와 스피커 청취는 아직 검증하지 않았습니다.

[변경·검증 보고서](reports/jeon-woochi/0.1.2/PERFORMANCE-V0.1.2.md) / [성능 비교 JSON](reports/jeon-woochi/0.1.2/performance-comparison.json) / [실제 실행 화면](reports/jeon-woochi/0.1.2/screenshots/village.png)

기존 APK와 공장 백업을 보존했습니다. SHA256SUMS.txt에서 파일별 무결성을 확인할 수 있습니다.

[Actions APK Artifacts](https://github.com/backtta-ui/suspicious-factory/actions/runs/43713439068) → `jeon-woochi-verified-apk` ZIP을 받아 압축을 풀고 APK를 설치할 수도 있습니다. 14일 보관. 공개 다운로드 및 아티팩트 재다운로드 SHA256 확인 완료.
