# Attribution — NoOxigen

- **Authors / upstream owner:** [zankorobos13](https://github.com/zankorobos13)
- **Upstream:** https://github.com/zankorobos13/NoOxigen
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `be98ee5189f95f27aa0767c9ddfff36dfafe47b9` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- Official Unity packages only (Unity 2022.3.6f1): 2D feature 2.0.0, Universal Render Pipeline 14.0.8, TextMesh Pro 3.0.6, Timeline, uGUI, Visual Scripting, and built-in modules listed in `src/Packages/manifest.json`. No Asset Store packages, no DOTween, no FXAA, no Unity Standard Assets, no LFS, no DLL.
- [Liberation Sans](https://github.com/liberationfonts/liberation-fonts) (SIL Open Font License 1.1; digitized data copyright 2010 Google Corporation / copyright 2012 Red Hat, Inc.) is the bundled TextMesh Pro default font at `src/Assets/TextMesh Pro/Fonts/` (`LiberationSans - OFL.txt` retained).
- `src/Assets/_NoOxigen/SFX/Submarine.mp3` is [rowrow](https://freesound.org/people/theredshore/sounds/83977/) by theredshore, CC0-1.0 (Freesound). ID3 tags in the file name the title and artist; attribution is not required under CC0.
- The TextMesh Pro sample [EmojiOne](https://www.emojione.com/) sprites and `EmojiOne.asset`, plus `Assets/TextMesh Pro/Documentation/`, were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared because it pointed at the omitted EmojiOne asset; playable scenes do not reference it.
- Product / jam: GMTK Game Jam 2026, published as [Seconds Before the Breath](https://noname90.itch.io/secondsbeforethebreath) on itch.io. Playable scenes in EditorBuildSettings: `Assets/Scenes/Menu.unity`, `Main.unity`, `Submarine.unity`, `Lose.unity`, `Win.unity`.
