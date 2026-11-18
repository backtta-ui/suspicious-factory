# 월하의 서원 2단계-B — 2.5D 줌 · 대형 한옥 3채 · 로비 실화면 · 앱 아이콘

버전 2.0.17 / versionCode 28. 이 문서는 이번 변경의 실제 구현, 검증 근거, 남은 한계를 기록합니다.

## 1. 인게임 시점과 대형 한옥

- 기본 카메라 `zoom = 1.75` (`scripts/survival/layout.gd`의 `CAMERA_ZOOM`), 내 캐릭터를 화면 중앙보다
  56px(월드 단위 `CAMERA_LIFT`) 아래에 두고 부드럽게 추적합니다(`app.gd` `load_match`/`update_avatars`).
- 출입 한옥 3채: **청월당**(폭 540), **서고**(470), **별채**(470). 각각 앞문·뒷문이 있고 실내 바닥이 있습니다.
  - 외관 스프라이트의 문 위치 비율(`DOOR_ANCHOR = (0.80, 0.965)`)에서 외곽·실내·충돌 벽·문 좌표를 역산하므로
    문 앞에 서면 그림의 문과 충돌 문이 같은 자리입니다(`layout.gd` `_make_buildings/_make_hard`).
  - 실내에 들어가면 그 건물의 지붕만 크로스페이드로 열리고(외관 alpha 1 → 0.06, 실내 alpha 0 → 1),
    방 바깥은 10겹 밤안개로 어두워집니다(`world.gd` `update_buildings`, `draw_interior_fog`).
  - 다른 한옥의 지붕은 그대로 닫혀 있습니다.
- 남은 프로시저럴 도형이던 **연못·아치 목교·마당 팔각 문양**을 `images`로 그린 원화로 교체했습니다.
  (`assets/woo/seowon/pond_night.png`, `bridge_wood.png`, `medallion_octagon.png`,
  원본 초록 크로마키는 `art_sources/seowon/`, 변환은 `tools/build_seowon_assets.py`).
  물결·달빛 반사만 얇게 애니메이션으로 얹습니다.
- 프러스텀 컬링(`world.gd` `update_cull`)과 비네팅, 비공격(HP 없음) 규칙은 그대로 유지했습니다.

## 2. 8인 2.5D 캐릭터 (8방향)

- 전우치·연화·무영·홍련·구미호·장산범·도깨비·해치 8명의 2.5D 아니메 스프라이트를 앞·뒤·좌·우 4방향으로
  생성해 `assets/woo/ingame/`에 두었습니다. 원본 시트는 `art_sources/ingame/`,
  분할·크로마키·캐릭터별 공통 배율은 `tools/build_ingame_characters.py`.
- `scripts/art/ingame_sprite.gd`가 `actor.facing`(0=동,1=남동,2=남,3=남서,4=서,5=북서,6=북,7=북동)을
  그대로 받아 매핑합니다.
  - 남·남서·남동 → 정면, 북·북서·북동 → 뒷모습, 동·서 → 옆모습, 대각선은 이동 방향으로 좌우 반전.
  - 점프·시전 중에는 `facing`을 바꾸지 않습니다(뒤돌아 점프하면 뒷모습 그대로).
  - 점프 높이에 맞춘 발밑 그림자 축소, 상승 스트레치·착지 스쿼시, 보행 흔들림, 도술 시전 링을 연결했습니다.
- 기존 `assets/woo/mascot/original/` 원화와 `tests/original_sprite.gd`는 그대로 보존되어,
  옷장·코덱스 등 기존 경로는 이전 동작을 유지합니다. 인게임 액터만 새 원화를 씁니다.

## 3. 로비 전 버튼 실화면

| 버튼 | 화면 | 실제 동작 |
| --- | --- | --- |
| 빠른 매치 | 매칭 화면 | 8인 슬롯이 차례로 차고, 도사6:요괴2 / 도사2:요괴6 선택, 완료 시 방 코드가 있는 대기방으로 진입 |
| 친구와 함께 | 방 코드 화면 | 6·8인 방 생성, 코드 생성·클립보드 복사·초대 문구 복사, 코드 입력 입장, 최근 코드 재입장 |
| 연습(봇) | 도술 연습장 | 기존 그대로 즉시 진입 |
| 마켓 | 무료 꾸미기 | 도포·칭호·기운 해금/장착, 캐릭터 미리보기, 코인 차감과 저장(인앱결제·광고 없음) |
| 업적 | 전용 화면 | 경기·봉인·구출·문·둔갑 기록으로 진행도, 완료 시 코인 보상(중복 수령 불가) |
| 우편 | 전용 화면 | 공지 열람·읽음 표시, 보상 1회 수령 |
| 알림 | 전용 화면 | 공지 읽음 상태 저장, 모두 읽음 |
| 설정 | 설정 모달 | 배경음악·효과음 볼륨, 음소거, 진동, 화질, 조작감(감도) |
| 캐릭터/도감 | 캐릭터 안내 | 기존 로스터 화면 |

- 로비 BGM은 `tools/prepare_ingame_audio.py`가 numpy로 직접 합성한 `assets/audio/lobby_night.wav`입니다.
  외부 음원·샘플을 쓰지 않습니다(인게임 BGM·효과음도 같은 방식).
- 모든 버튼에 눌림 스케일·금빛 글로우·클릭음을 넣고, 화면 전환은 페이드로 이어집니다(`app.gd` `button_feel`).

## 4. 앱 아이콘

- 사용자가 확정한 아이콘을 `assets/icon.png`(512 런처), `assets/icon_foreground.png`(432 어댑티브 앞면,
  안전영역 패딩), `assets/splash.png`(256)로 적용했습니다.
- `export_presets.cfg`의 `launcher_icons/main_192x192`, `launcher_icons/adaptive_foreground_432x432`가
  이 파일을 가리키며, Android mipmap은 내보내기 시 생성됩니다(CI APK에서 확인).

## 5. 검증

`bash tools/test.sh` (Godot 4.6.3 headless, 스위트 9종)

- 2D CLEANUP 39 / CHARACTER CODEX 59 / SURVIVAL V1.3 48 / SEOWON INGAME 83 / LOBBY HUB 46 /
  ORIGINAL SPRITES 128 / OFFLINE PRACTICE 61 / SPELL INTEGRITY 8 — **전부 0 failures**.
- 새 검증 항목: 세 한옥의 앞·뒤 문 walkable, 문 앞 상호작용, 1.75 줌·42→56px 리프트 추적,
  실내 지붕 크로스페이드·밖 안개, 8방향 매핑(남동/북서 대각선 포함), 뒤돌아 점프 시 뒷모습 유지,
  로비 8인 매칭→대기방, 방 코드 입장, 마켓 해금·장착·저장, 업적/우편 중복 수령 방지, 자체 합성 로비 BGM.
- 렌더 캡처: `docs/ingame-2.5d-b/` (야외·청월당 실내·서고 실내·마당·로비·마켓·매칭·업적).

## 6. 남은 한계

- 실제 갤럭시 기기에서의 FPS·터치 감도는 검증하지 않았습니다(렌더는 Linux Xvfb 기준).
- 친구와 함께의 "같은 방"은 오프라인 봇 채우기로 동작합니다. 서버 권한 실시간 멀티플레이는
  기존 Render 서버 구성 문서(`docs/V2.0-SERVER.md`)의 범위이며 이번 변경에 포함되지 않았습니다.
- 실내 원화는 세 건물이 같은 실내 아트를 공유합니다(색온도만 다름).
