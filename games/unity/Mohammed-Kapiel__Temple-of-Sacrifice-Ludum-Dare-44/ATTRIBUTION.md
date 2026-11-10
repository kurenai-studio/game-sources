# Attribution — Temple-of-Sacrifice-Ludum-Dare-44

- **Authors / upstream owner:** [Mohammed-Kapiel](https://github.com/Mohammed-Kapiel)
- **Upstream:** https://github.com/Mohammed-Kapiel/Temple-of-Sacrifice-Ludum-Dare-44
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `62c09ae6a2531f204fa700f3f1392d71f519856c` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- Official Unity packages only (Unity 2019.1.0f2), listed in `src/Temple of Sacrifice LD44 - Project/Packages/manifest.json`: TextMesh Pro 2.0.0, Timeline 1.0.0, Collab Proxy 1.2.16, Unity Ads 2.0.8, Analytics 3.3.2, Purchasing 2.0.6, Package Manager UI, and built-in modules. No packages are vendored into this snapshot beyond the TextMesh Pro assets already under `Assets/TextMesh Pro/`.
- [Liberation Sans](https://github.com/liberationfonts/liberation-fonts) (SIL Open Font License 1.1) is the bundled TextMesh Pro default font at `src/Temple of Sacrifice LD44 - Project/Assets/TextMesh Pro/Fonts/` (`LiberationSans - OFL.txt` retained).
- The TextMesh Pro sample [EmojiOne](https://www.emojione.com/) sprites and `EmojiOne.asset`, plus `Assets/TextMesh Pro/Examples & Extras/` and `Assets/TextMesh Pro/Documentation/`, were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared because it pointed at the omitted EmojiOne asset; playable scenes do not require it.
- `Logs/` was omitted.
- The author states the Ludum Dare 44 project (code, art, and music) was made in 48 hours. Game art is `Assets/Sprites/Full Sprite Sheet.png` and `Vases.png`; audio is under `Assets/Audio/`.
- No DOTween, no FXAA, no Unity Standard Assets, no Asset Store packages, no LFS, no DLL. `ProjectSettings/ProjectVersion.txt` is retained.
- Product / jam: Ludum Dare 44 — Temple of Sacrifice. Playable scenes in EditorBuildSettings: `Assets/Scenes/MainMenu.unity`, `Assets/Scenes/Game.unity`. `Assets/Scenes/MainMenu 1.unity` is also present in the project.
