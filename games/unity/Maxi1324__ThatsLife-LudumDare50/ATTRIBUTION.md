# Attribution — ThatsLife-LudumDare50

- **Authors / upstream owner:** [Maxi1324](https://github.com/Maxi1324)
- **Upstream:** https://github.com/Maxi1324/ThatsLife-LudumDare50
- **License:** MIT (see `LICENSE`)
- **Pinned commit:** `72b6e9e583e6634d024c7dd1f000ce69e81c9906` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-10 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference. The author released the work under the MIT License.

**Third-party notes:**
- Official Unity packages only (Unity 2020.3.19f1): Universal Render Pipeline 10.6.0, TextMesh Pro 3.0.6, Visual Effect Graph 10.6.0, Timeline, uGUI, and built-in modules. No Asset Store packages, no DOTween, no FXAA, no Unity Standard Assets, no LFS, no DLL.
- [Noisy Nodes](https://github.com/JimmyCushnie/Noisy-Nodes) by Jimmy Cushnie, WTFPL, vendored at `src/Assets/Librarys/Noisy-Nodes-master/`. Shader noise implementations include [keijiro/NoiseShader](https://github.com/keijiro/NoiseShader) (wrapping [webgl-noise](https://github.com/ashima/webgl-noise) by Stefan Gustavson and Ashima Arts, MIT, and K.jpg SuperSimplex/FastSimplex, Unlicense) plus Voronoi/white-noise nodes contributed by fdervaux.
- [Liberation Sans](https://github.com/liberationfonts/liberation-fonts) (SIL Open Font License 1.1; copyright 2010 Google Corporation / 2012 Red Hat, Inc.) is the bundled TextMesh Pro default font at `src/Assets/TextMesh Pro/Fonts/` (`LiberationSans - OFL.txt` retained).
- The TextMesh Pro sample [EmojiOne](https://www.emojione.com/) sprites and `Assets/TextMesh Pro/Examples & Extras/` (including bundled demo fonts such as Electronic Highway Sign) were omitted. `TMP Settings.asset` `m_defaultSpriteAsset` was cleared because it pointed at the omitted EmojiOne asset; playable scenes do not reference it.
- Product / jam: [Ludum Dare 50 Compo — That's Life](https://ldjam.com/events/ludum-dare/50/thatslife) (April 2022). Also on [itch.io](https://maxi1324.itch.io/thats-life). The author states that all art, code, and sound were made in 48 hours for the compo (tools: Unity, Blender, Krita, Audacity, Bosca Ceoil). Playable scenes: `Assets/Scenes/Start.unity`, `Assets/Scenes/Main.unity`, `Assets/Scenes/EndScreen.unity`.
