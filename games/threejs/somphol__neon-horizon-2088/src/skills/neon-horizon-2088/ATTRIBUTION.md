# Attribution

## Origin

This skill packages **NEON HORIZON 2088 — Cyberpunk 3D Pinball Studio**, built on
2026-11-01 in a single OpenCode session with **DeepSeek V4.1 Flash**
(`opencode-go/deepseek-v4.1-flash`). The released source is the repository
`somphol/neon-horizon-2088` at <https://github.com/somphol/neon-horizon-2088>; the live
copy is <https://somphol.github.io/neon-horizon-2088/>.

The template in `assets/template/` is a byte-identical copy of the three release source
files (`index.html`, `style.css`, `script.js`). It is included so the table can be
rebuilt or forked without relying on the original session.

## What is original to this project

- The 10 × 22 unit cabinet geometry, lane guides, lower-third layout, flipper/slingshot
  placement, drain box and side-seal clearances.
- The procedural playfield, backglass, city, grid and reflection textures — every pixel
  is drawn at runtime on a canvas.
- The HUD, overlays, responsive layout and cyberpunk visual system.
- The Web Audio synthesiser and all of its voices; no audio files are used.
- The score archive schema, validation, merge behaviour and JSON export/import.
- The anti-trap displacement watchdog, table-escape recovery and four-layer containment
  approach.
- The self-test and automation surface (`window.NEON_HORIZON`).

The lower-third design was informed by public pinball-design discussion (the standard
"Italian bottom": slingshot, inlane, outlane), but the implementation is an original
simplification, not a traced machine layout.

## Licence status

- **Project source:** MIT, as declared in the source repository's `LICENSE`. The template
  is redistributed under the same MIT terms.
- **Three.js r128:** MIT. <https://threejs.org/>
- **Cannon.js 0.6.2:** MIT. <https://schteppe.github.io/cannon.js/>
- **Orbitron:** SIL Open Font License 1.1, delivered by Google Fonts.
- **Rajdhani:** SIL Open Font License 1.1, delivered by Google Fonts.
- **Images, audio, 3D models:** none. There are no third-party art or sound assets in the
  template.

If you publish a derivative, keep the MIT licence notice for the source and the
upstream notices for Three.js, Cannon.js and the fonts. Do not describe the CDN-hosted
libraries as your own work.

## What this skill is not

It is not a generic game engine, not an offline bundle (the libraries and fonts are
remote) and not a guarantee that a recoloured copy will play well. The table geometry
and physics constants must be re-tuned for any new layout; see
`references/method.md` and `references/lessons.md`.
