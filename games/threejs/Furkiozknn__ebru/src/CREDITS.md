# Credits

## Assets

- `assets/mascot/kedi-uyuyor.png`, `assets/mascot/kedi-kutlama.png` and `assets/mascot/kedi-dusunuyor.png`: the white
  Turkish Van kitten mascot of the Claude Game Arena, downscaled to 256 px (ffmpeg, lanczos) from the author's own
  copies in the video studio (`kedi-uyuyor.png`, `kedi-kutlama.png`, `kedi-dusunuyor.png`). The sleeping kitten is a
  billboard sprite on the workshop table; the cheering and thinking poses appear on the lesson result card. All three
  are skipped with `?noassets` (and on `file://`, where WebGL cannot read a local image).

## Facts

- The "Did you know?" cards quote the UNESCO Representative List entry for ebru:
  https://ich.unesco.org/en/RL/ebru-turkish-art-of-marbling-00644 and the inscription decision
  https://ich.unesco.org/en/decisions/9.COM/10.44.

## Code and libraries

- Three.js r170, loaded from cdn.jsdelivr.net (MIT licence, https://threejs.org/).
- Everything else (the marbling simulation, lessons, workshop models, textures, icons and sounds) is generated in
  `index.html`.
