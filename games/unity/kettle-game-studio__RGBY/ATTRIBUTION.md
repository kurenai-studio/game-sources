# Attribution — RGBY

- **Authors / upstream owner:** [kettle-game-studio](https://github.com/kettle-game-studio) (Kettle Game Studio / Kettle Studio)
- **Upstream:** https://github.com/kettle-game-studio/RGBY
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `f3d57bbddb2f96b79adc5935267d8fa8b3f1975a` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The authors released the work under the MIT License (Copyright 2024 Kettle Game Studio).

Jam / product: MMCS Game Jam 2024 3D platformer [RGBY](https://kettle-studio.itch.io/rgby) (itch.io lists the code license as MIT). A parrot changes color to reach its favorite treat. Playable scenes enabled in EditorBuildSettings: `Assets/Scenes/Level01.unity` through `Level05.unity`, and `Assets/Scenes/Finish.unity`.

Team credits from the itch.io page:
- Олег Арутюнов (Oleg Arutyunov) — 3D art, game design
- Николь Беликова (Nicole Belikova) — soundtrack
- Сергей Дуюнов (Sergey Duyunov) — code, visual effects
- Вячеслав Иванченко (Viacheslav Ivanchenko) — level design, code
- Петруша и Кеша — moral support

**Third-party notes:**
- Official Unity 6000.0.26f1 packages (changeset `ccb7c73d2c02`) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: URP 17.0.3; uGUI 2.0.0; Input System 1.11.2; AI Navigation 2.0.4; Timeline 1.8.7; Visual Scripting 1.9.4; test framework; IDE packages (Rider / Visual Studio); Collab Proxy; Multiplayer Center; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scenes do not require it.
- Music under `src/Assets/Sounds/` (`RGBY.mp3`, `RGBY_pomenshe.mp3`, `flying.mp3`, `steps.mp3`) is credited on itch.io to team composer Николь Беликова (Nicole Belikova) and is included under the repository MIT License. A commit on the default branch is titled "Soundtrack".
- Original Blender / Krita sources and marketing images under `src/Blends/` and the parrot/apple/block FBX + albedo textures under `src/Assets/Models/` are treated as the team's own art (itch credits Олег Арутюнов with 3D art) and retained.
- `src/Assets/Models/122_original.jpeg` (md5 `2662126aad260e3df7b807f4bcd8d78d`, 800×638 JPEG, only a JFIF header) was omitted together with its `.meta`. It is a close-up photograph of reddish millet-like seeds with a visible Depositphotos watermark in the bottom-right corner, so it is not redistributable whitelist OSS. The material `Assets/Models/Materials/122_original.mat` and any scene GUID references may remain.
- `src/Assets/Models/korma-dlja-ptic-kartinka.jpg` (md5 `8d09efedca2867f8f56aeb2bdfe9c925`, 2560×2036 JPEG; filename is Russian for "bird-feed picture") was omitted together with its `.meta`. It is a professional-looking photograph of mixed bird seed. Embedded EXIF UserComment is an ASCII hex fingerprint (`562ebd391c795e9e5a140887669e29a40b742a25ffd0135913dbda9dce8756b52aa42df10fa5d01ac18d37f67f10b8f32674239a48ef128d255a4dcddb3bc7cc2a3555fad9194187afbc3690a35215cd`) rather than camera metadata; source could not be verified as original and it is treated like stock photography (verified_only). The material `Assets/Models/Materials/korma-dlja-ptic-kartinka.mat` and any scene GUID references may remain.
- `src/Assets/Models/bars.png` (md5 `5d2597257f5538ce23c0086e61ff67d0`) is a stylized black-and-white cage-bar texture clearly made for this game and is retained. `src/Assets/Models/marble.png` (md5 `2cb80ea0f45ac7a6aba1978ec432cef9`) is a stylized airbrushed grayscale pattern (not a photogrammetry / PBR albedo) and is retained.
- The unused Unity URP template scene `Assets/Scenes/SampleScene.unity` (not listed in EditorBuildSettings) was omitted together with its `.meta`.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`, no Git LFS. `ProjectSettings/ProjectVersion.txt` is retained. Editor `.vscode/` and `UserSettings/` were omitted.
