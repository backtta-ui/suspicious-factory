# PC 없이 APK를 받는 개발 흐름

## 현재 사용 가능한 실제 다운로드

- APK: https://raw.githubusercontent.com/backtta-ui/suspicious-factory/apk-downloads/suspicious-factory-0.1.0.apk
- 다운로드 페이지: https://github.com/backtta-ui/suspicious-factory/tree/apk-downloads
- 소스: https://github.com/backtta-ui/suspicious-factory/tree/main

공개 저장소의 `apk-downloads` 브랜치에 APK를 업로드했습니다. 인증 없는 HTTPS GET으로 실제 파일 44,054,383바이트를 다시 내려받아 원본 SHA256과 일치함을 확인했습니다.

SHA256: `1e418c033302ba5ad0b2492e5ffe6ac8c09636611a92c27f0eea8bf430da1e49`

이 주소는 Cloud 내부 경로나 sandbox 링크가 아닙니다. ChatGPT 앱에서 열리지 않으면 삼성 인터넷이나 Chrome 주소창에 전체 HTTPS 주소를 붙여넣습니다. 내려받은 APK는 삼성 내 파일 → 다운로드에서 눌러 설치합니다. 현재 0.1.0은 Android 10 이상 ARM64 가로 화면용 오프라인 이동 테스트이며, 실제 갤럭시 실행은 사용자의 확인이 필요합니다.

## 전달 방식과 권한

GitHub 계정 인증만으로는 업로드되지 않았고, 사용자가 공식 ChatGPT Codex Connector 앱을 `backtta-ui/suspicious-factory` 저장소에 설치한 후 쓰기 권한과 소스 push가 정상 작동했습니다. 저장소는 사용자가 생성한 공개 상태를 유지했습니다.

GitHub Releases 첨부 업로드는 uploads.github.com에서 HTTP 401 인증 오류가 발생했습니다. 성공한 릴리스가 있다고 주장하지 않습니다. 이번에는 GitHub 일반 Git 파일 크기 제한 이내의 APK를 별도 브랜치로 전달했습니다. 이후 APK가 100MB를 넘거나 배포 이력이 커지면 Releases 첨부 인증 또는 다른 바이너리 저장소를 해결해야 합니다.

서명키·토큰은 공개 저장소에 올리지 않았습니다. `apk-downloads` 브랜치를 main에 합칠 필요는 없습니다.

## 주요 기능 개발 후 필수 검증

`bash tools/checkpoint.sh`로 게임 테스트 33개, APK 빌드, 서명·Manifest·ARM64·가로 화면·오프라인 권한·백업 정책·ZIP 및 16KiB 네이티브 라이브러리 정렬·폰트 고지와 시작 이미지·SHA256을 검사합니다. 결과는 `builds/apk-verification.json`, `builds/test-results.txt`, `builds/android-build.log`에 남습니다. 실패하면 이전 정상 APK를 보존하고 완료로 보고하지 않습니다.

다음 테스트 APK 전달 시에는 같은 서명키로 빌드하고, `apk-downloads` 브랜치에 새 버전 APK와 체크섬·검증 결과를 추가한 뒤 실제 공개 URL로 재다운로드해 SHA256 일치를 확인합니다. 기존 정상 APK와 기능을 임의로 지우지 않습니다.

## GitHub Actions 상태와 비용

main의 `.github/workflows/android-apk.yml`은 원격 자동화 준비 파일입니다. 이번 소스와 배포 push에는 `[skip ci]`를 사용했으며 GitHub Actions를 실행하지 않았습니다. 실제 CI 성공을 주장하지 않습니다. 원격 실행 전 동일 테스트 서명키를 Actions secret에 구성하고, 계정 실행 한도·결제 정책을 확인해야 합니다.

이번 전달에는 새 유료 호스팅이나 게임 서버를 만들지 않았습니다. 이후 GitHub Actions와 저장 공간은 계정의 무료 제공량·요금 정책을 따릅니다. GitHub 계정 연결만으로 과금 승인을 받은 것으로 간주하지 않습니다.
