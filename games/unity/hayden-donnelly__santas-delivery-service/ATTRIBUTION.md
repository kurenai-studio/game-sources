# Attribution — santas-delivery-service

- **Authors / upstream owner:** [Hayden Donnelly](https://github.com/hayden-donnelly) (programmer; itch.io: [Bizbud](https://bizbud.itch.io/santas-delivery-service)); [Peter Prickarz](https://github.com/peterprickarz) (artist); Eric Goetz (composer)
- **Upstream:** https://github.com/hayden-donnelly/santas-delivery-service
- **License:** MIT (see `LICENSE`) — copyright 2020 Hayden Donnelly, Peter Prickarz, Eric Goetz (git blob `08715366a8dd0c261d12316a50667ce1f781a99e`)
- **Pinned commit:** `2a498073d9f6847a0bb0e91e674ca094c7855605` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference.

**Third-party notes:**
- Engine: Unity 2017.2.0f3 (`src/ProjectSettings/ProjectVersion.txt`). The README says the project was last tested on 2017.4.1f1. `src/UnityPackageManager/manifest.json` has an empty dependency list. No TextMesh Pro assets are vendored. No DOTween, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL.
- Playable scenes enabled in `EditorBuildSettings`: `Assets/Scenes/MainMenu.unity`, `Assets/Scenes/Levels/Level01.unity`, `Assets/Scenes/Levels/Level02.unity`, `Assets/Scenes/Levels/Level03.unity`, and `Assets/Scenes/Levels/Level04.unity`. Disabled prototyping/testing scenes remain in the snapshot.
- Upstream tracks images, audio, models, and fonts with Git LFS. The LFS objects were pulled at the pinned commit and stored here as regular git blobs; `filter=lfs` rules were removed from `src/.gitattributes` so this snapshot has no LFS dependency.
- The vendored Unity Post Processing Stack v1 under `src/Assets/PostProcessing/` is credited to Unity Technologies (BSD-3-Clause, official PostProcessing repository). Bluenoise textures under `src/Assets/PostProcessing/Resources/Bluenoise64/` are CC0-1.0 by Christoph Peters (`LICENSE.txt` / `COPYING.txt` retained).
- NVIDIA FXAA 3.11 was omitted because `FXAA3.cginc` carries "Copyright (C) 2010, 2011 NVIDIA Corporation. All rights reserved." Omitted: `FXAA.shader`, `FXAA3.cginc`, `FxaaComponent.cs`, and their `.meta` files. GUID / shader includes may remain.
- `WheelMovecs.FBX` under `src/Assets/PostProcessing/Utilities/CustomMotionTexture/Models/` was stored upstream as a Git LFS pointer with an uppercase `.FBX` suffix that was not matched by the `*.fbx` LFS rules, so the object was not pulled. The pointer and its `.meta` were omitted rather than leaving an LFS pointer in the archive.
- `src/Assets/Fonts/Good Morning.ttf` (md5 `e12e3a71829ccbac262325062f827e96`) and its `.meta` were omitted. The font name table identifies it as Good Morning / IMAGEX / imagex-fonts.com, Version 1.00 August 30, 2017, with the notice "Free for personal use ONLY." Unity `.meta` `licenseType: Free` is not an OSS grant. Referenced from `Assets/Scenes/MainMenu.unity` and `Assets/Prefabs/Essentials/Essentials.prefab`; GUID references may remain.
- Music is retained under the repository MIT License: `src/Assets/Music/LD40_Soundtrack.wav` (md5 `e2f38aeec95eabf93e7bc1952e30d662`, embedded artist tag "Eric") credited to composer Eric Goetz; `src/Assets/Music/Holy shit that scared me.wav` (md5 `0bfc8c0271a254b5364521372904fdf2`, title "That Scared Me", artist "Hayden Donnelly").
- `.DS_Store` and `.vscode/` were omitted.
- Product / jam: Ludum Dare 40 — The more you have, the worse it is. Itch.io: https://bizbud.itch.io/santas-delivery-service
