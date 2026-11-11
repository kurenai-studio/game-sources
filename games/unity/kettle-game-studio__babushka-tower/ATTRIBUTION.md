# Attribution — babushka-tower

- **Authors / upstream owner:** [kettle-game-studio](https://github.com/kettle-game-studio) (Kettle Game Studio / Kettle Studio)
- **Upstream:** https://github.com/kettle-game-studio/babushka-tower
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `ca5bc2b983cdfeaa2bc49f170f0de5e217f1704f` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The authors released the work under the MIT License (Copyright 2026 Kettle Game Studio).

Jam / product: Ludum Dare 59 game [Babushka Tower](https://kettle-studio.itch.io/babushka-tower) ([ldjam entry](https://ldjam.com/events/ludum-dare/59/babushka-tower)). A short 3D platformer about stacking objects in the grandparents' garden to catch a phone signal. Playable scenes enabled in EditorBuildSettings: `Assets/Scenes/Intro.unity` and `Assets/Scenes/Game.unity`. The itch page states that no generative AI was used.

Team credits from the itch.io / ldjam pages:
- Oleg Arutyunov (@tetrergeru) — 3D models
- Sergey Duyunov (@sid37) — code
- Viacheslav Ivanchenko (@gs2) — SFX
- Nikole Belikova (@nicole-a) — intro comic
- Adam Arutyunov (@adamci) — music stuff

**Third-party notes:**
- Official Unity 6000.3.13f1 packages (changeset `8c4f11e4fb20`) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: AI Navigation 2.0.12; Collab Proxy 2.12.4; Input System 1.19.0; Universal Render Pipeline 17.3.0; Timeline 1.8.12; uGUI 2.0.0; Visual Scripting 1.9.11; test framework; IDE packages (Rider / Visual Studio); Multiplayer Center; and built-in modules. Locked registry packages come from the Unity registry (`https://packages.unity.com`) or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1, designer Steve Matteson, md5 `bbbd0bdbfba093dec2ee4ca8b62e61f9`) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted, as was the unused `TextMesh Pro/Examples & Extras/` folder (template example fonts including Electronic Highway Sign). `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset.
- The unused Unity template scene `Assets/Scenes/SampleScene.unity` (not listed in EditorBuildSettings) was omitted together with `Assets/Readme.asset` and the editor recovery folder `Assets/_Recovery/`. `Settings/SampleSceneProfile.asset` was retained because `Mobile_RPAsset.asset` and `PC_RPAsset.asset` reference it.
- `Molot.otf` (md5 `41fd7a16df8966e172c862ca3875679f`) and `Molot SDF.asset` were omitted because they are not clearly whitelist-redistributable OSS. The bundled font's name table is “Copyright (c) 2008 by Roman Yershov, Jovanny Lemonad. All rights reserved.” (family Molot, Version 1.000 2008 initial release) and contains no SPDX or OFL notice. Scene or prefab GUID references may remain in `Assets/Scenes/Intro.unity` and `Assets/Prefabs/Player.prefab`.
- `NGGYU_10s.mp3` (md5 `d29a4cb7f8ed8b8ddee5de3a27290d4f`) was omitted. It is a short clip produced in LMMS whose filename refers to the copyrighted song “Never Gonna Give You Up.”
- Music under `src/Assets/Sounds/` credited on itch as “Music: Kevin MacLeod” is retained under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). Credit: [Kevin MacLeod](https://incompetech.com/). Tracks identified from file tags:
  - `Arcadia.mp3` — “Arcadia” (album Scoring: Wonder), md5 `2ed8c79810ec6866d8e6908e731cdb6d`
  - `merry.mp3` — “Merry Go”, md5 `0c0d500b257713e67b0c9264d7b74cfa`
  - `weasel.mp3` — “Scheming Weasel faster” (album Scoring: Comedic), md5 `ad8f64fe300e959c10492d22d36b454d`
- Remaining sound effects under `src/Assets/Sounds/` are credited to team member Viacheslav Ivanchenko and are included under the repository MIT License.
- 3D models, painted and photographic textures (itch: “Photos for textures: Were made by us”), Blender sources under `src/Blends/`, and Krita/docs under `src/Docs/` (including `main_image.png`, md5 `0d5cb35233c0238d7cfafdade1f59679`) are treated as the team's own art (itch credits Oleg Arutyunov with 3D models and Nikole Belikova with the intro comic) and retained.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`, no Git LFS. `ProjectSettings/ProjectVersion.txt` is retained.
