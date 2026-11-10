# Attribution — Lumiere

- **Authors / upstream owner:** [JoshLmao](https://github.com/JoshLmao) (Josh Shepherd)
- **Upstream:** https://github.com/JoshLmao/Lumiere
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `02bf40de5a45a06bbf4c143ff9d16e52687cbcd3` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- [Open Sans Light](https://fonts.google.com/specimen/Open+Sans) (Apache License 2.0; digitized data copyright 2010-2011 Google Corporation; Ascender Corporation) is bundled at `src/Lumiere/Assets/fonts/OpenSansLight.ttf` (name-table license confirmed).
- The author describes Lumière as a first jam game made fully by himself. Sprite/PSD art and short untagged PCM SFX are treated as original to this MIT snapshot.
- Upstream lists a git submodule `Lumiere/Assets/PostProcessing` pointing at [Unity-Technologies/PostProcessing](https://github.com/Unity-Technologies/PostProcessing). That checkout is empty in the pinned tree and was omitted (along with `PostProcessing.meta` and `.gitmodules`). Custom post-processing controller scripts and `Assets/post_processing` profiles remain.
- No DOTween, no EmojiOne, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained (Unity 5.6.0f3).
- Product / jam: [Ludum Dare 39 — Lumière](https://joshlmao.itch.io/lumiere) (theme: Running out of Power). Playable scene in EditorBuildSettings: `Assets/scenes/level.unity`. The Unity project is under `src/Lumiere/`.
