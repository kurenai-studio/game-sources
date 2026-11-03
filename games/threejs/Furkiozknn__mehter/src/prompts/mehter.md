# Arena round 3, game 4: Mehter (rhythm game) — built by Claude Haiku 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm if needed).
A 3D rhythm game called "Mehter" (the Ottoman military band). Do not ask questions, build it end to end.

WORLD: a parade avenue in an old city at dusk with banners, plane trees and cheering crowds; the band marches
towards the camera in rows: kös and davul drummers, zurna players, a çevgen (jingling staff) bearer, the
mehterbaşı leading. Built entirely in code, no external models or textures. Rich red, gold and deep blue palette,
flat shading, soft shadows, one accent colour (#D4A017 gold).

LIFE: the band marches in the mehter step (step, step, turn) in time with the music, the crowd waves and throws
petals on good streaks, banners flutter, the sky darkens and torches light up over a song.

GAME RULES: four lanes (davul, kös, zurna, zil/çevgen) with notes scrolling towards a hit line on the road in
front of the band; hit them in time (Perfect / Good / Miss windows in milliseconds), hold notes for zurna, a
combo multiplier, a band-spirit meter that drops on misses (fail at zero). 6 songs generated in code (marches
in usul rhythms such as düyek and sofyan, with increasing tempo and density) each in Easy / Normal / Hard,
note charts derived from the same patterns so they always match the music. Accuracy grade (S/A/B/C), best
score per song and difficulty saved. An input-latency calibration screen. Audio must be scheduled on the Web
Audio clock, and hits judged against the audio clock, not frame time.

INTERACTION: keys D F J K for the lanes (rebindable), tap the lanes on touch screens, gamepad buttons if
available. Pause on P / Esc, restart song.

HUD: top bar (logo, song, difficulty, score, combo, accuracy, pause, sound, language), the lane highway with
hit feedback, the band-spirit meter, a song select with previews, title, results screen with the grade and a
hit-timing histogram.

EXTRAS: drums, cymbals and a zurna-like lead synthesised with Web Audio, crowd cheers on streaks, metronome in
calibration.
```

The shared rules in `_sablonlar/arena-round3-common.md` are appended to this prompt.
