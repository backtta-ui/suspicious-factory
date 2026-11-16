# 《도사》 V1.2 — 광장·NPC·타이틀 개선

[설치용 APK 직접 다운로드 — 약 64MiB](https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/jeon-woochi-1.2.0.apk)

삼성 내 파일 → 다운로드에서 기존 앱 위에 업데이트 설치하세요. Android 10 이상 ARM64, 가로 화면. 기존 패키지·서명 인증서·저장 호환성을 유지합니다.

돌광장 중심으로 상점 앞마당과 거리를 연결했습니다. NPC는 고정 목적지를 실제로 걸어 다니며, 새 4프레임 다리 동작·좌우 발 접지·고정 머리 기준점을 사용합니다. 타이틀은 전체 이미지 흔들기 대신 손 도술·폭포·강물·꽃잎·물안개·구름만 국소적으로 움직입니다. 기존 게임 기능과 음악은 유지합니다. 의상·갓 끈은 원본 손상을 피하려고 움직이지 않습니다.

[실제 소스 Actions 빌드](https://github.com/backtta-ui/suspicious-factory/actions/runs/43783283617)가 성공했습니다. 해당 중간 APK의 임시 서명을 제거한 뒤 Cloud의 기존 키로 최종 서명한 위 APK를 설치하세요. unsigned 중간 아티팩트는 설치용이 아닙니다.

회귀297개·APK26개 검사 통과. 최종 APK 리소스에서도 NPC38·광장50·터치125개 재검사 및 다섯 구역 렌더 예산 검사 통과. 실제 갤럭시 FPS·발열·스피커 검증은 수행하지 않았습니다.

[전체 변경 파일·원인 분석·검증 보고서](reports/jeon-woochi/1.2.0/V1.2.md) / [돌광장](reports/jeon-woochi/1.2.0/screenshots/v12-plaza.png) / [상점 거리](reports/jeon-woochi/1.2.0/screenshots/v12-shops.png) / [타이틀](reports/jeon-woochi/1.2.0/screenshots/v12-title-a.png)

이전 APK와 백업 브랜치를 유지합니다. 파일별 해시는 SHA256SUMS.txt에 있습니다.

[설치용 Actions APK 아티팩트](https://github.com/backtta-ui/suspicious-factory/actions/runs/43785580523) → `jeon-woochi-verified-apk` ZIP을 받아 압축을 풀어 설치합니다. 14일 보관. 공개 APK와 Actions ZIP 재다운로드 해시 확인 완료.
