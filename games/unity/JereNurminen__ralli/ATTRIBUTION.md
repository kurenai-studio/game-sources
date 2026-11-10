# Attribution — ralli

- **Authors / upstream owner:** [JereNurminen](https://github.com/JereNurminen)
- **Upstream:** https://github.com/JereNurminen/ralli
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `caf664f6024b4fef2817cc660e140014f80796d6` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License (Copyright 2026 Jere Nurminen).

**Third-party notes:**
- Official Unity packages (Unity 6000.0.45f1) listed in `src/Ralli/Packages/manifest.json` and `src/Ralli/Packages/packages-lock.json`: Universal Render Pipeline 17.0.4; Input System 1.14.2; Animation Rigging 1.3.1; AI Navigation 2.0.6; Splines 2.8.3; Timeline 1.8.7; uGUI 2.0.0; Visual Scripting 1.9.6; Multiplayer Center 1.0.0 (official builtin package, not vendored); Collab Proxy; Rider / Visual Studio IDE packages; test framework; and built-in modules. Locked registry packages come from the Unity registry or are builtin. No packages are vendored into this snapshot.
- `com.coplaydev.unity-mcp` is declared as a git dependency on [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp) (MIT License), pinned in `packages-lock.json` to hash `c4393b091e932835acfa6cda6ead8126f530dade`. It is an editor AI-bridge, not required at runtime, and is not vendored here.
- No TextMesh Pro, no bundled fonts, no EmojiOne, no DOTween, no FXAA, no Unity Standard Assets, no Library, no Logs, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained. The Unity project root is `src/Ralli/`.
- [Quaternius Textured LowPoly Trees](https://quaternius.itch.io/textured-lowpoly-trees) (CC0 1.0), credited in the upstream README and `src/docs/third-party-assets.md`. The pack files themselves are gitignored under `Ralli/Assets/ThirdParty/` and are not present in this snapshot; only project-side `src/Ralli/Assets/Materials/Trees/` materials remain.
- `src/Ralli/Assets/Prefabs/GasStation.prefab` references a gitignored [PSX Gas Station Pack by kyjhi](https://github.com/JereNurminen/ralli/blob/master/docs/third-party-assets.md). The pack is not included in this snapshot (upstream documents that the raw files must not be redistributed as standalone assets).
- Other third-party audio, vehicle, skybox, and arm packs listed in `src/docs/third-party-assets.md` are marked Evaluating only and are not present in the repository.
- Playable scene in EditorBuildSettings: `Assets/Scenes/SampleScene.unity`. `Assets/Scenes/RoadPieceAuthoring.unity` is an editor authoring scene and is not in the build list.
