# LAYER SHIFT

**Night shift at the print farm.** Every layer comes out of the nozzle misaligned: shift it back into place before it hits the plate.

Entry for [GitHub Game Off 2026](https://itch.io/jam/game-off-2026) · theme: **SHIFT**.

## The idea

One title, four kinds of shift:

- **Layer shift**: the 3D printing failure where layers slide out of place.
- **Shift keys**: the whole game is played with Left Shift and Right Shift.
- **Bit shift**: every layer is a row of filament bits. Shift it left or right; bits pushed past the edge are lost.
- **Night shift**: the print queue runs from 22:00 to 06:00.

## How to play

| Input | Action |
|---|---|
| **Left Shift** | shift the layer left |
| **Right Shift** | shift the layer right |
| **Both Shifts** | drop the layer now |
| Touch | tap the left / right half of the screen, two fingers to drop |
| **M** | sound on / off |

Match each layer with the blueprint on the right before the timer runs out.

- Filament printed over air sags into **spaghetti**.
- Filament in the wrong place turns red.
- Clean layers in a row build a **combo**.

Finish the night with a clean rocket and see what happens.

## Build

```bash
npm install
npm run build    # dist/ + dist/game-web.zip (itch.io HTML upload)
npm run single   # dist/layer-shift.html, the whole game in one file
npm test         # headless smoke test
npm run play     # headless playthrough of all jobs
```

## Tech

- [Phaser 3](https://phaser.io), bundled with esbuild.
- No image or audio files: every graphic is drawn in code and every sound is synthesized with WebAudio.
- Fonts: [Poppins](https://github.com/itfoundry/Poppins) (SIL OFL 1.1) and DejaVu Sans Mono (Bitstream Vera license). Their licenses are in `public/fonts/`.

## Credits

Made by Emanuele Esposito · [Emanuele Tech](https://www.instagram.com/emanuele_tech).

## License

Code: MIT. Fonts: see their licenses in `public/fonts/`.
