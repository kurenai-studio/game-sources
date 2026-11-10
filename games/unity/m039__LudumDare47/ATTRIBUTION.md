# Attribution — LudumDare47

- **Authors / upstream owner:** [m039](https://github.com/m039) (Dmitry Mozgin)
- **Upstream:** https://github.com/m039/LudumDare47
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `658abaa227b1824084b7872fa342ea3071b0cec4` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- Official Unity packages only (Unity 2019.4.11f1): Universal Render Pipeline 7.3.1, ProBuilder 4.4.0, TextMesh Pro 2.1.1, Timeline, uGUI, Recorder 2.3.0-preview.3, and built-in modules listed in `src/Packages/manifest.json`.
- [m039/CommonUnityLibrary](https://github.com/m039/CommonUnityLibrary) (MIT, Copyright 2019 Dmitry Mozgin) is vendored at `src/Packages/CommonUnityLibrary/` pinned to `e5b4aa23e9df125d9005bb2aa291bf207196875c` (`LICENSE` retained; submodule `.git` removed).
- [Roboto](https://fonts.google.com/specimen/Roboto) by Christian Robertson / Google, Apache License 2.0, at `src/Assets/Art/Fonts/Roboto/` (`LICENSE.txt` retained).
- [Secular One](https://fonts.google.com/specimen/Secular+One) by Michal Sahar, SIL Open Font License 1.1, at `src/Assets/Art/Fonts/Secular_One/` (`OFL.txt` retained).
- [Liberation Sans](https://github.com/liberationfonts/liberation-fonts) (SIL Open Font License 1.1) is the bundled TextMesh Pro default font at `src/Assets/ThirdParty/TextMesh Pro/Fonts/` (`LiberationSans - OFL.txt` retained).
- The Unity Asset Store [Game Jam Template](https://assetstore.unity.com/) under `Assets/ThirdParty/Game Jam Template/` (including `intro_music_gjt.aif`) was omitted because Asset Store packages are not redistributed here. Author-written menu/gameplay scripts under `src/Assets/Scripts/` are kept.
- The TextMesh Pro sample [EmojiOne](https://www.emojione.com/) sprites and `EmojiOne.asset`, plus `Assets/ThirdParty/TextMesh Pro/Documentation/`, were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared because it pointed at the omitted EmojiOne asset; playable scenes do not require it.
- No DOTween, no FXAA, no Unity Standard Assets, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: [Ludum Dare 47 — Spinning Around](https://ldjam.com/events/ludum-dare/47/spinning-around). Also on [itch.io](https://m039.itch.io/spinning-around-ld47). Playable scenes in EditorBuildSettings: `Assets/Scenes/Welcome.unity`, `Assets/Scenes/Menu.unity`, `Assets/Scenes/Orbits.unity`.
