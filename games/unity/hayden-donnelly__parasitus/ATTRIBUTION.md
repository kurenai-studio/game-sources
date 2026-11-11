# Attribution — parasitus

- **Authors / upstream owner:** [hayden-donnelly](https://github.com/hayden-donnelly) (Hayden Donnelly)
- **Upstream:** https://github.com/hayden-donnelly/parasitus
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `b9e6930330248fa3dbbdbd7b7be82be03a9cb87c` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License (Copyright 2023 Hayden Donnelly).

**Third-party notes:**
- Official Unity packages (Unity 2021.3.4f1) listed in `src/Packages/manifest.json` and `src/Packages/packages-lock.json`: Universal Render Pipeline 12.1.7; TextMesh Pro 3.0.6; ProBuilder 5.0.7; Timeline 1.6.4; uGUI 1.0.0; Visual Scripting 1.7.8; Collab Proxy; Rider / Visual Studio / VS Code IDE packages; test framework; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- LiberationSans (SIL Open Font License 1.1) is retained as the TextMesh Pro default font, including `src/Assets/TextMesh Pro/Fonts/LiberationSans - OFL.txt`.
- TextMesh Pro EmojiOne sprites and `EmojiOne.asset` were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared and `m_enableEmojiSupport` was set to 0 because they pointed at the omitted EmojiOne asset. The playable scenes do not require it.
- Upstream tracks images, audio, models, and fonts with Git LFS. The LFS objects were pulled at the pinned commit and stored here as regular git blobs; `filter=lfs` rules were removed from `src/.gitattributes` so this snapshot has no LFS dependency.
- TMP Documentation (User Guide PDF) was omitted. No TMP Examples & Extras were included.
- Sound effects under `src/Assets/Sounds/` and original Blender/XCF character sources under `src/NonUnityFiles/` are included under the repository MIT License. The upstream README does not list separate third-party audio credits.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no Library, no Logs, no DLL, no `.DS_Store`. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: Ludum Dare 53 — Delivery (itch.io: Parasitus). Playable scenes in EditorBuildSettings: `Assets/Scenes/MainMenu.unity`, `Assets/Scenes/Main.unity`, `Assets/Scenes/GameOver.unity`, `Assets/Scenes/GameComplete.unity`.
