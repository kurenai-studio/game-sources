# Third-party notices

## Three.js r180 / npm three@0.180.0

- Repository: https://github.com/mrdoob/three.js/tree/r180
- License: MIT; full license in `dist/vendor/THREE-LICENSE.txt`.
- Copyright 2010–2025 Three.js Authors.
- Vendored unmodified runtime: `dist/vendor/three.module.min.js`, `dist/vendor/three.core.min.js`.
- Vendored unmodified addon: `dist/vendor/PointerLockControls.js`.
- Download source: `https://cdn.jsdelivr.net/npm/three@0.180.0/` with matching `build/` and `examples/jsm/controls/` paths. This CDN is used only during development; the shipped game has no CDN requests.
- Multi-view viewport/scissor rendering technique adapted from https://github.com/mrdoob/three.js/blob/r180/examples/webgl_multiple_views.html (MIT).
- Mouse look reuses https://github.com/mrdoob/three.js/blob/r180/examples/jsm/controls/PointerLockControls.js (MIT).

## Original project content

All road segments, railings, pillars, characters, hands, and monsters are generated from `BoxGeometry` in `dist/js/world.js`. No artwork, models, textures, or external fonts are loaded. UI uses system fonts. Effects use oscillator synthesis in `dist/js/sound.js`. `dist/assets/hey.wav` is synthesized speech (“Hey!”), generated with the installed Microsoft Zira Desktop (en-US, female) voice through Windows System.Speech; no voice engine or model is bundled. These project sources are distributed under the root MIT license. No generated concept images are included in the game or public source archive.
