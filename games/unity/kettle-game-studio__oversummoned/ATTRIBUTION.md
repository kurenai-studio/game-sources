# Attribution — oversummoned

- **Authors / upstream owner:** [kettle-game-studio](https://github.com/kettle-game-studio) (Kettle Game Studio / Kettle Studio)
- **Upstream:** https://github.com/kettle-game-studio/oversummoned
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `8d0ce6cc82a999169b5a2ade3664cbe3833eec01` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The authors released the work under the MIT License (Copyright 2024 Kettle Game Studio).

Jam / product: Ludum Dare 55 game [Oversummoned](https://kettle-studio.itch.io/oversummoned) ([ldjam entry](https://ldjam.com/events/ludum-dare/55/oversummoned-1)). Guide little demons to their summoners with pentagrams, upgrade houses, and healing cauldrons. Playable scenes enabled in EditorBuildSettings: `Assets/Prefabs/Scenes/MainMenu.unity`, `Level1.unity` through `Level6.unity`, and `EndMenu.unity`.

Team credits from the itch.io / ldjam pages:
- Oleg Arutyunov (@tetrergeru) — 2D art and code
- Sergey Duyunov (@sid37) — music, sounds, and code
- Nicole Akopdzhanova (@nicole-a) — 3D art
- Viacheslav Ivanchenko (@gs2) — code, QA, and mental support

**Third-party notes:**
- Official Unity 2022.3.24f1 packages (changeset `334eb2a0b267`) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: 2D Sprite 1.0.0; TextMesh Pro 3.0.6; Timeline 1.7.6; uGUI 1.0.0; Visual Scripting 1.9.2; test framework; IDE packages (Rider / Visual Studio / VS Code); Collab Proxy; Linux toolchain; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1, designer Steve Matteson) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted, as was `src/Assets/TextMesh Pro/Documentation/TextMesh Pro User Guide 2016.pdf`. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scenes do not require them.
- The unused Unity template scene `Assets/Prefabs/Scenes/SampleScene.unity` (not listed in EditorBuildSettings) was omitted together with its `.meta`.
- The following bundled fonts are not whitelist-redistributable OSS and were omitted together with their TextMesh Pro SDF/Outline assets and `.meta` files. Scene or material GUID references may remain:
  - `Angel rhapsody.ttf` (md5 `426858ed04a545dda02248f8c4ca1d9d`): name table Copyright (c) 2020 by Stringlabs, All rights reserved; Stringlabs states the font is for personal use unless a commercial license is purchased.
  - `BRIDGE.TTF` (md5 `182bfb90d177a5a093bdc690c31aff35`): name table family Bridgnorth, “Brignorth Regular (C) Copyright PJL '96”; no SPDX or redistributable license in the name table.
  - `FenwickWoodtype.ttf` (md5 `5b17c637fa4b7c1f50527eae2d24f80a`): name table Copyright (c) Typographer Mediengestaltung, 2001. All rights reserved.
- Music and sound effects under `src/Assets/Sound/` (including `DemonWaltz.mp3`, which is also offered as a download on the itch.io page) are credited to team member Sergey Duyunov and are included under the repository MIT License.
- 2D sprites, the painted material atlases (`cauldron.png`, `house1_tex.png`, `house2_tex.png`), and Krita sources (`Demons/`, `concept_1.kra`) are treated as the team's own art (itch credits Oleg Arutyunov with 2D art and Nicole Akopdzhanova with 3D art) and retained.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`, no Git LFS. `ProjectSettings/ProjectVersion.txt` is retained.
