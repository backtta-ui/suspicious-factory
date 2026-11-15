# Android 빌드와 전달

Godot **4.6.3 stable**, GDScript, GL Compatibility, OpenJDK 21, Android Build Tools 36.0.0을 사용합니다. 최소 API 29, target API 36, ARM64, 가로 화면, immersive 설정, 패키지 `com.suspiciousfactory.game`, 기존 테스트 서명키와 `Android Test` preset을 유지했습니다. versionCode는 5, 새 표시 이름은 도사: 전우치입니다. 오프라인 싱글플레이이므로 Internet 권한을 제거했습니다.

공식 비 Gradle 템플릿의 minSdk를 29로 제한하는 기존 `tools/prepare_android_template.py`와 APK 서명·정렬 절차를 사용합니다.

## 이 Cloud에서

```bash
bash tools/checkpoint.sh
```

`/workspace/toolchain`의 기존 도구·템플릿·에디터 설정을 사용하며 서명키를 소스에 넣지 않습니다. 결과는 `builds/jeon-woochi-0.1.1.apk`입니다. `builds/android-build.log`, `builds/apk-verification.json`, 게임·터치·저장·재실행 로그를 확인합니다.

## 다른 개발 환경

Godot 4.6.3와 같은 버전 export templates, JDK와 Android SDK를 설치하고 Editor Settings → Export → Android에 Java SDK Path, Android SDK Path, Debug Keystore를 설정합니다. 업데이트 설치에는 같은 키가 필요합니다.

```bash
export GODOT_ANDROID_TEMPLATE="/설치된/4.6.3.stable/android_debug.apk"
export ANDROID_HOME="/Android/SDK"
bash tools/checkpoint.sh
```

`tools/test.sh`는 import 후 단독 실행할 수 있습니다. `tools/run_godot_checked.py`는 종료 코드 0이라도 스크립트 오류가 있으면 실패로 처리하고 시간 제한을 둡니다.

## CI와 모바일 전달

기존 `.github/workflows/android-apk.yml`을 유지·갱신했습니다. 원격 실행에는 같은 서명키의 `ANDROID_DEBUG_KEYSTORE_BASE64` secret이 필요합니다. 성공 시 Actions Artifacts에 `woo-apk-실행번호-시도번호` APK·체크섬·보고서를 보관합니다. 실패 시 진단 로그를 보관합니다.

게임 자체의 빌드는 Cloud checkpoint에서 수행했습니다. 별도 `deliver-apk.yml`은 Cloud에서 빌드한 정확한 APK를 고정 커밋에서 받아 SHA256을 검사하고 Actions Artifacts로 보관합니다. [파일 전달 실행 기록](https://github.com/backtta-ui/suspicious-factory/actions/runs/43703375678)이 성공했으며 아티팩트 ZIP을 다시 받아 내부 APK의 체크섬도 확인했습니다. 이는 원격 게임 재컴파일 성공을 뜻하지 않습니다. 원격 빌드 workflow에는 여전히 기존 서명키 secret과 계정 한도 확인이 필요합니다. 새 유료 호스팅이나 게임 서버는 만들지 않았습니다.

APK는 개발용 디버그 서명이며 AAB·출시 서명·Google Play 업로드는 이번 범위에 포함하지 않습니다.

아티팩트 이름은 `jeon-woochi-v0.1-verified-apk`이며 보관 기간은 14일입니다. GitHub 로그인 후 실행 페이지의 Artifacts에서 ZIP을 받습니다. 휴대폰에서는 압축을 푼 뒤 APK를 설치합니다. 직접 APK 다운로드 주소는 별도로 유지됩니다.

V0.1.1은 입력을 물리 틱마다 읽어 HD 리소스 첫 업로드로 렌더 프레임이 지연될 때도 이동 입력이 누락되지 않도록 했습니다. `tests/visual_smoke.gd`는 실제 APK 리소스를 렌더링하며 이동·둔갑·대화를 점검합니다.
