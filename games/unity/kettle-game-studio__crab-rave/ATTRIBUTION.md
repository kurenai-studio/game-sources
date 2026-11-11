# Attribution — crab-rave (Crab with a Hook)

- **Authors / upstream owner:** [kettle-game-studio](https://github.com/kettle-game-studio) (Kettle Game Studio / Kettle Studio)
- **Upstream:** https://github.com/kettle-game-studio/crab-rave
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `2e6c2210c6857671b5e96a8972f8e546eceea2eb` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The authors released the work under the MIT License (Copyright 2025 Kettle Game Studio). The [itch.io page](https://kettle-studio.itch.io/crab-with-a-hook) also lists the code license as MIT.

Jam / product: Ludum Dare 57 3D adventure [Crab with a Hook](https://kettle-studio.itch.io/crab-with-a-hook) ([ldjam entry](https://ldjam.com/events/ludum-dare/57/crab-with-a-hook)). A crab uses a grappling hook and a rewindable air hose to collect sea shells. The playable game scene enabled in EditorBuildSettings is `Assets/Scenes/SampleScene.unity` (the game was built in that scene; it is not an unused URP template scene).

Team credits from the itch.io / ldjam pages:
- Oleg Arutyunov — code, level art, VFX
- Nicole Akopdzhanova — VFX, 3D
- Sergey Duyunov — 3D
- Viacheslav Ivanchenko — SFX
- Adam Arutyunov — music
- Tigran Mamedov — music

The itch.io page states that no generative AI was used.

**Third-party notes:**
- Official Unity 6000.0.26f1 packages (changeset `ccb7c73d2c02`) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: URP 17.0.3; uGUI 2.0.0; Input System 1.11.2; AI Navigation 2.0.4; Splines 2.6.1; Timeline 1.8.7; Visual Scripting 1.9.4; test framework; IDE packages (Rider / Visual Studio); Collab Proxy; Multiplayer Center; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1, designer Steve Matteson) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scene does not require it.
- Unused Unity URP template leftovers `src/Assets/TutorialInfo/` and `src/Assets/Readme.asset` were omitted together with their `.meta` files. Editor `.vscode/` was omitted.
- The following bundled fonts are not whitelist-redistributable OSS and were omitted together with their TextMesh Pro SDF assets and `.meta` files. Scene or material GUID references may remain:
  - `ALS_SPb.otf` (md5 `92c3a81024570768cb82617442b7cf72`): name table Copyright (c) 2014 by Art Lebedev Studio, All rights reserved; trademark ALS SPb; designer Ksenia Yerulevich. This is a commercial Art Lebedev Studio typeface.
  - `LongIslandAntiqua.ttf` (md5 `1bb4e31f25460668f059f512272fe8a6`): name table Copyright (c) Typographer Mediengestaltung, 2000. All rights reserved.
- Soundtrack under `src/Assets/Sounds/Music/` (`1 — Underwater.mp3`, `2 — Overwater.mp3`, `3 — Innerwater.mp3`, `brapcrave.mp3`) is credited on itch.io / ldjam to Adam Arutyunov and Tigran Mamedov and is included under the repository MIT License. Other sound effects under `src/Assets/Sounds/` are credited to Viacheslav Ivanchenko and are likewise included under the repository MIT License.
- Original Blender / Krita sources under `src/Blend/` and `src/Gamedesign/`, and the painted model atlases (crab, hook, shells, pirate / ruin / sci-fi props, stylized decals and noise textures), are treated as the team's own art and retained.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`, no Git LFS. `ProjectSettings/ProjectVersion.txt` is retained.
