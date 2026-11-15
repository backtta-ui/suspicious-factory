# Android APK 다시 빌드하기

## 검증한 도구

- Godot **4.6.3.stable.official.7d41c59c4**, 같은 버전의 Android export templates
- OpenJDK 21 (이 환경에서 실제 export 및 서명 검증에 사용)
- Android SDK command-line tools, Platform Tools, Build Tools **36.0.0**
- Android 플랫폼 36 설치. 비 Gradle APK export는 컴파일 없이 기본 템플릿을 패키징합니다.
- 최종 APK: **minSdk 29 / targetSdk 36**, ARM64, 가로 모드. targetSdk는 공식 Godot 4.6.3 템플릿 값을 유지합니다.

## 처음 설정

1. Godot 4.6.3의 Editor → Manage Export Templates에서 4.6.3 템플릿을 설치합니다.
2. Android Studio의 SDK Manager 또는 sdkmanager로 Platform Tools, Build Tools 36.0.0, Android SDK 플랫폼을 설치합니다. SDK 약관을 확인하고 동의합니다.
3. Godot Editor Settings → Export → Android에서 **Android SDK Path**, **Java SDK Path**를 지정합니다.
4. 같은 설정의 Debug Keystore 경로·사용자·암호를 지정합니다. 로컬 테스트용 키가 없다면 아래 명령으로 생성할 수 있습니다. 프로젝트나 배포 소스에 키를 넣지 않습니다.

```bash
keytool -genkeypair -keystore /원하는/경로/debug.keystore \
  -storepass android -alias androiddebugkey -keypass android \
  -dname 'CN=Android Debug,O=Android,C=US' \
  -keyalg RSA -keysize 2048 -validity 10000
```

## 빌드

Linux/macOS 셸 예시입니다. `GODOT_ANDROID_TEMPLATE`은 설치된 공식 템플릿의 `android_debug.apk`입니다.

```bash
export GODOT_ANDROID_TEMPLATE="$HOME/.local/share/godot/export_templates/4.6.3.stable/android_debug.apk"
export ANDROID_HOME="/내/Android/SDK"
bash tools/build_android.sh
```

`builds/suspicious-factory-0.1.0.apk`가 생성됩니다. Windows에서는 Python 스크립트를 먼저 실행하고 Godot의 Project → Export → Android Test → Export Project에서 Export With Debug를 선택할 수 있습니다.

```bash
python3 tools/prepare_android_template.py /공식/템플릿/android_debug.apk
godot --headless --editor --path . --import --quit
godot --headless --path . --export-debug 'Android Test' builds/suspicious-factory-0.1.0.apk
```

공식 템플릿의 최소 지원 버전은 Android 7(API 24)입니다. 비 Gradle 내보내기는 Min SDK를 직접 변경하지 못하므로 `prepare_android_template.py`가 바이너리 Manifest에서 **minSdkVersion 정수 하나만 29로 변경**한 사용자 템플릿을 생성합니다. 이후 Godot 자체 exporter가 패키지명·아이콘·권한·리소스를 적용하고 zipalign 및 서명을 수행합니다. 엔진 코드는 변경하지 않습니다. 생성된 템플릿은 Git 및 게임 리소스에서 제외합니다.

## 결과 확인 / USB 설치

```bash
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose builds/suspicious-factory-0.1.0.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -P 16 4 builds/suspicious-factory-0.1.0.apk
"$ANDROID_HOME/build-tools/36.0.0/aapt" dump badging builds/suspicious-factory-0.1.0.apk
adb install -r builds/suspicious-factory-0.1.0.apk
adb shell am start -n com.suspiciousfactory.game/com.godot.game.GodotApp
```

서명이 다른 예전 설치본이 있으면 업데이트 설치가 거절됩니다. 그 경우 기존 테스트 앱을 삭제한 뒤 설치합니다. 삭제 시 로컬 닉네임·외형 설정도 지워집니다.

## 이 작업 환경의 재빌드 명령

도구는 소스 폴더 밖 `/workspace/toolchain`에 설치했습니다.

```bash
export XDG_DATA_HOME=/workspace/toolchain/data
export XDG_CONFIG_HOME=/workspace/toolchain/config
export XDG_CACHE_HOME=/workspace/toolchain/cache
export ANDROID_HOME=/workspace/toolchain/android-sdk
export GODOT_ANDROID_TEMPLATE=/workspace/toolchain/data/godot/export_templates/4.6.3.stable/android_debug.apk
bash tools/build_android.sh
```

최초 기본 네트워크 연결과 Java SDK Manager 다운로드가 실패하여, 공식 Google 저장소에서 SDK ZIP을 받아 배치했습니다. 최종 빌드 상태는 `builds/android-build.log`와 `builds/apk-verification.txt`에 기록했습니다.

## AAB / 출시 버전

이번 산출물은 APK뿐입니다. AAB는 1차 모바일 테스트 통과 후 정식 출시 준비 단계에서 Gradle build template, 해당 버전이 요구하는 SDK/JDK, 개인 release/upload key와 Play App Signing으로 구성합니다. 현재 debug key를 출시용으로 사용하지 않습니다. 정식 패키지명, 공개 개인정보 처리방침, Data Safety, 등급, 신고·차단·채팅, 오류 수집, Android 기기별 실측 검증도 해당 단계에서 확정합니다.
