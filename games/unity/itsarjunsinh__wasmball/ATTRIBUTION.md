# Attribution — wasmball

- **Authors / upstream owner:** [itsarjunsinh](https://github.com/itsarjunsinh) (Arjunsinh Shridevsinh Jadeja)
- **Upstream:** https://github.com/itsarjunsinh/wasmball
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `12d069ccd0a2ff0a4518d409d40b130f65322aae` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- Official Unity packages only (Unity 2019.3.10f1), listed in `src/Packages/manifest.json`: Project Tiny `com.unity.tiny.all` 0.24.0-preview.1, TextMesh Pro 2.0.1 (package only; not vendored under `Assets`), Recorder 2.2.0-preview.4, Collab Proxy, Rider/VS Code IDE packages, test framework, and built-in modules. No packages are vendored into this snapshot.
- The author states this Ludum Dare 46 Compo was built in 48 hours without any third-party assets. UI textures `src/Assets/Materials/Textures/UI/GameLogo.png` and `Rules.png` are original typography made for the game. There are no bundled fonts, audio, or third-party plugins.
- Playable scenes are `Assets/Scenes/Tiny3D.unity` and `Assets/Scenes/TIny3D DOTS Subscene.unity`. They are built with Project Tiny configurations under `src/Assets/BuildConfigurations/` (including `Wasm-Tiny3D.buildconfiguration`). `ProjectSettings/EditorBuildSettings.asset` has an empty `m_Scenes` list, which is expected for this Tiny project.
- No DOTween, no EmojiOne, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: [Ludum Dare 46 — Wasmball](https://ldjam.com/events/ludum-dare/46/wasmball). Also playable at [arjunsinh.dev/wasmball/play](https://arjunsinh.dev/wasmball/play).
