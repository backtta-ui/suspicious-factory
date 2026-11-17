# DOSA 2.0.11 — SD graphic pilot and confirmed capture rules

This is a staged graphic pilot, **not completion of the whole-game renewal**.

## Implemented

- Preserved original generated turnaround designs separately from runtime atlases (`art_sources/mascot`). Runtime art uses 64px body cells, foot anchor (32,60), nearest filtering and 40px body height.
- Four independently illustrated character body rows, four cardinal and four diagonal body views. Four-view hair (six styles) and headwear (six styles) atlases. Existing saved IDs, ownership, per-character profiles and gameplay geometry are retained.
- Shared actor renderer used by player, wardrobe preview and existing actor-based clone/copy flows. Separate head, torso, arms and feet; distance-based gait and existing attack timing. Rebuild frequency is bounded to animation steps, instead of every rendered frame.
- Shared environment atlas connected to existing plaza/village prop constructors without replacing map geometry or interaction nodes. Sixteen art cells; unsupported kinds retain their existing resources.
- Confirmed server rescue 4s, protection 3s, capture deadline 45s. Deadline is authoritative and visible to the captured client. Existing self-escape mechanics remain unchanged.
- Server-owned `pass` entitlement supports three acquired common spells; ordinary/free tiers remain two. Client requests cannot grant this entitlement. Production entitlement verification/Billing is **MISSING**; without the existing server test entitlement flag, accounts remain free.

## Actual inspection / limitations

- Desktop Godot renders: [wardrobe](wardrobe.png), [plaza](plaza.png), [four characters / eight body directions](eight-directions.png). These are actual runtime captures, not Android captures.
- Cardinal hair/headwear is reused for diagonal body directions. Dedicated diagonal gear and hand-authored action frames are still required. The screenshots expose this limitation; eight fully finished directional animations are **not claimed**.
- Existing moon/night garments and accessories are retained. They have not all been redesigned to SD quality. Existing unavailable outfits remain unavailable without losing ownership.
- NPC artwork, animals, palace/coast unique art, monster effects, UI and the twelve-zone Seowon map are not fully renewed. Existing map assets and gameplay remain in place.
- Actual project contains existing goblins and exploration maps. Gumiho/Moon Warrior/Red Dragon boss implementations, spirit stones and a spell shop were not found; these are **MISSING**, not completed by this art pilot.
- No Galaxy device, public 6–8-device session, Android FPS or memory measurement was performed. These are **BLOCKED** pending devices/server. APK build is separate from device verification.

## Verification

- Focused server suite: 56 checks, zero failures, including deadline boundaries and third-slot rejection.
- Atlas suite: 88 checks, zero failures, verifying actual nonempty runtime cells and legacy appearance identifiers.
- Appearance combination suite: 504 combinations / 269,222 assertions, zero failures. This checks data, atlas row identity, geometry, transitions and save compatibility; it does not certify visual art quality for every combination.
- Mandatory full checkpoint and APK delivery results are recorded after completion below.

## Before / after

- Previous shipped style reference: [2.0.9 wardrobe](../qa-2.0.9/wardrobe.png), [2.0.9 plaza](../qa-2.0.9/plaza.png). These are prior-release references, not a controlled same-frame benchmark.
- After: links above show this pilot. Camera zoom and gameplay collision geometry are unchanged. Visual proportions still require Galaxy review with 1/4/8 players and narrow passages.
- No before/after FPS, load-time or memory improvement is asserted. This environment uses a software desktop GPU and cannot substitute for Android measurements.

## Checkpoint result

`bash tools/checkpoint.sh` exited **0** on 2026-11-17. Full gameplay, touch, server sockets, restart, save and export checks passed. Source snapshot stayed stable throughout export. The APK contains the new SD runtime resources.

- APK: `jeon-woochi-2.0.11.apk`, versionCode 22, 129,937,192 bytes.
- SHA256: `493bd9254ce624b08c7eec7c59779c9e9f44b49f126caf1519763f77ef3df53f`.
- Persistent signing certificate matches 2.0.10. Existing package ID is unchanged; install as update without uninstalling.
- Device test: **not performed**.
- Additional polish remains for palette matching and diagonal gear. Existing pass setup entry still uses a two-slot label; the authoritative pass allocation and in-game three buttons are implemented, but this label needs follow-up.
