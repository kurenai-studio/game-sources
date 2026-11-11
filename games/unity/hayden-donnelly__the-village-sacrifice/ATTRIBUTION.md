# Attribution — the-village-sacrifice

- **Authors / upstream owner:** [Hayden Donnelly](https://github.com/hayden-donnelly) (programmer; itch.io: [Bizbud](https://bizbud.itch.io/the-village-sacrifice)); [Peter Prickarz](https://github.com/peterprickarz) (artist); Eric Goetz (composer, named in the upstream README)
- **Upstream:** https://github.com/hayden-donnelly/the-village-sacrifice
- **License:** MIT (see `LICENSE`) — copyright 2020 Hayden Donnelly, Peter Prickarz, Eric Goetz (git blob `08715366a8dd0c261d12316a50667ce1f781a99e`)
- **Pinned commit:** `195ad09e1b9d6947bf3ae877a08774960e888e8e` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference.

**Third-party notes:**
- Engine: Unity 2018.2.18f1 (`src/ProjectSettings/ProjectVersion.txt`). Official Unity packages are listed only in `src/Packages/manifest.json` and are not vendored into this snapshot: TextMesh Pro 1.2.4; Ads 2.0.8; Analytics 2.0.16; Purchasing 2.0.3; Package Manager UI 1.9.11; and built-in modules. No TextMesh Pro font or EmojiOne assets are present in the tree. No DOTween, no Library, no Logs, no DLL.
- Playable scenes enabled in `EditorBuildSettings`: `Assets/Scenes/UI Scenes/MainMenu.unity`, `Assets/Scenes/UI Scenes/GameOver.unity`, `Assets/Scenes/Levels/Level02.unity`, `Assets/Scenes/Levels/Level03.unity`, and `Assets/Scenes/Levels/Level04.unity`. `Assets/Scenes/Levels/Level01.unity` is present but disabled in the build list. Unused prototyping scenes under `Assets/Scenes/Prototyping Scenes/` are retained (except that `Prototyping_01.unity` referenced omitted Standard Assets).
- Upstream tracks images, audio, models, and fonts with Git LFS. The LFS objects were pulled at the pinned commit and stored here as regular git blobs; `filter=lfs` rules were removed from `src/.gitattributes` so this snapshot has no LFS dependency.
- The vendored Unity Post Processing Stack v1 under `src/Assets/PostProcessing/` is credited to Unity Technologies (BSD-3-Clause, official PostProcessing repository). Bluenoise textures under `src/Assets/PostProcessing/Resources/Bluenoise64/` are CC0-1.0 by Christoph Peters (`LICENSE.txt` / `COPYING.txt` retained).
- NVIDIA FXAA 3.11 was omitted because `FXAA3.cginc` carries "Copyright (C) 2010, 2011 NVIDIA Corporation. All rights reserved." Omitted: `FXAA.shader`, `FXAA3.cginc`, `FxaaComponent.cs`, and their `.meta` files. GUID / shader includes may remain.
- `WheelMovecs.FBX` under `src/Assets/PostProcessing/Utilities/CustomMotionTexture/Models/` was stored upstream as a Git LFS pointer with an uppercase `.FBX` suffix that was not matched by the `*.fbx` LFS rules, so the object was not pulled. The pointer and its `.meta` were omitted rather than leaving an LFS pointer in the archive.
- `src/Assets/Standard Assets/` (Unity Standard Assets Prototyping) and `Assets/Standard Assets.meta` were omitted. This pack is distributed under a Unity companion / Asset Store license, which is not on the CONTRIBUTING OSS whitelist. The only references outside that folder are in the unused, disabled scene `Assets/Scenes/Prototyping Scenes/Prototyping_01.unity`. GUID references may remain.
- `src/Assets/Music/Eerie Music 1 (YUJ).wav` (md5 `ed2022ba0038a73e972d5d55184fb5cd`, about 28MB, no embedded RIFF/ID3 tags) and its `.meta` were omitted under the verified_only rule. The upstream README names Eric Goetz as composer, but the stock-like filename could not be matched to a verified original work or a whitelist license, and the itch.io page does not give a separate track credit. Scene / AudioClip GUID references may remain.
- Root `AIPlanning` notes are retained. `.vscode/` was omitted (not present at the repo root as a committed game asset requirement).
- Product / jam: Ludum Dare 43 — Sacrifices must be made. Itch.io: https://bizbud.itch.io/the-village-sacrifice
