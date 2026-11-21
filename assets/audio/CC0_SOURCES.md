# 2.0.37 CC0 오디오 출처 (전부 CC0 1.0 — 저작자 표기 의무 없음)

《우울할 땐 도사》 2.0.37부터 배경음악·발소리·도술 효과음을 모두 **OpenGameArt의 CC0 실제 녹음**으로
교체했습니다. 합성음(2.0.36까지의 numpy 생성 WAV)은 폐기했습니다.
`tools/prepare_v37_audio.py`가 원본을 잘라 44.1kHz 스테레오 WAV로 정규화하며,
`tools/verify_v37_audio.py`가 형식·레벨·고주파·무음 여부를 검사합니다.

## 배경음악 (원본 .ogg 그대로 사용, 재인코딩 없음)

| 게임 파일 | 원곡 | 저작자 | 원본 |
|---|---|---|---|
| `bgm/lobby_fantasy.ogg` | Heartfelt Battle (Loopable, fantasy, strings/piano/horn) | request | https://opengameart.org/content/heartfelt-battle-loopable-fantasy-stringspianohorn |
| `bgm/seowon_battle.ogg` | Fairy Battles (BPM180, loopable) | MintoDog | https://opengameart.org/content/fairy-battles |
| `bgm/gangnam_trance.ogg` | Trance City (BPM130, loopable) | MintoDog | https://opengameart.org/content/trance-city |
| `bgm/haeundae_beach.ogg` | Beach Sports Theme (Loop) | Trex0n (Cal McEachern) | https://opengameart.org/content/beach-sports-theme-loop |
| `bgm/dongseongno_urban.ogg` | Urban Theme (BPM115, loopable) | MintoDog | https://opengameart.org/content/urban-theme |

라이선스: CC0 1.0 Universal — https://creativecommons.org/publicdomain/zero/1.0/
(원 페이지에서 CC0로 명시된 것을 확인하고 내려받았습니다.)

## 발소리 (바닥 재질별)

| 게임 파일 | 원본 팩 | 저작자 | 라이선스 | 원본 |
|---|---|---|---|---|
| `steps/grass_dirt_*.wav` | Fantozzi's Footsteps (Grass/Sand & Stone) — Sand L/R 1~3 | Fantozzi (qubodup 업로드) | CC0 | https://opengameart.org/content/fantozzis-footsteps-grasssand-stone |
| `steps/stone_*.wav` | 같은 팩 — Stone L/R 1~3 | Fantozzi | CC0 | 위와 같음 |
| `steps/sand_*.wav` | Water Splash and sand footsteps — `sand_footsteps.mp3`에서 발소리 구간 추출 | Peludo | CC0 | https://opengameart.org/content/water-splash-and-sand-footsteps |
| `steps/water_*.wav` | 같은 팩 `splash1.wav`·`splash2.wav` + TinyWorlds water-drop | Peludo · TinyWorlds | CC0 | 위와 같음 |
| `steps/wood_*.wav` | Different steps on wood/stone/leaves/gravel/mud — wood01~03 | TinyWorlds (kdd) | CC0 | https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud |
| `steps/wood_4/5`, `steps/escalator_*` | Fantasy SFX (Tinysized) boots/step·Kenney RPG footstep04·metalLatch | Vehicle · Kenney | CC0 | https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx · https://opengameart.org/content/50-rpg-sound-effects |
| `steps/tile_indoor_*.wav` | Fantozzi Stone을 밝게 다듬고 짧은 반사(타일 홀) 추가 | Fantozzi 파생 | CC0 | 위 Fantozzi |
| `steps/asphalt_*.wav` | kdd gravel·leaves·stone + 둔탁하게 깎은 돌 | TinyWorlds · Fantozzi | CC0 | 위 두 팩 |
| `steps/jar_*.wav` | Kenney metalPot 1~3을 낮게 피치 이동(옹기 소리) | Kenney | CC0 | https://opengameart.org/content/50-rpg-sound-effects |

## 도술 30종 · 기본 SFX

| 원본 팩 | 저작자 | 라이선스 | 쓰인 곳 |
|---|---|---|---|
| 50 RPG sound effects (`RPGsounds_Kenney.zip`) | Kenney (kenney.nl) | CC0 | 분신·둔갑·화중은신·기관인형·압력기관·인간둔갑·문·봉인 등 금속·천·종이·동전 |
| Fantasy Sound Effects (Tinysized, 96 files) | Vehicle (Jan Schupke) | CC0 | 바람·종이·나무·물·금속·가루·발소리 계열 |
| Magic Spell SFX (`magical_1~7.ogg`) | JaggedStone | CC0 | 생명등불·저승꽃·귀환의 길·혼길표식·천문기계·여우향 |
| Horror SFX (`horror_effect1/2.wav`) | TinyWorlds | CC0 | 등불끄기·검은시야·무월야·산군의 울음·목소리흉내 |
| String and piano horror stings (`abyss.ogg`) | congusbongus | CC0 | 귀문보기·검은시야 보조 |
| Dark Stinger 1 (`dark_stinger_0.ogg`) | Kresiek The Furry | CC0 | 저승문·무월야 |
| Different steps (kdd) | TinyWorlds | CC0 | 아스팔트·나무 발소리 |

원본 URL
- Kenney RPG: https://opengameart.org/content/50-rpg-sound-effects
- Tinysized: https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx
- Magic Spells: https://opengameart.org/content/magic-spell-sfx
- Horror SFX: https://opengameart.org/content/horror-sfx
- abyss: https://opengameart.org/content/string-and-piano-horror-stings
- Dark Stinger: https://opengameart.org/content/dark-stinger-1

모든 파일은 CC0 1.0이라 표기는 의무가 아니지만, 원저작자를 밝히기 위해 이 문서를 남깁니다.
