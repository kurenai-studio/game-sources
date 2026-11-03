<p align="center">
  <a href="https://furkiozknn.github.io/mehter/"><img src="docs/banner.svg" width="100%" alt="Mehter: a 3D rhythm march with an Ottoman military band down a parade avenue. Click to play in your browser."></a>
</p>

<p align="center">
  <a href="https://furkiozknn.github.io/mehter/"><img src="https://img.shields.io/badge/%E2%96%B6_Play_now-in_your_browser-D4A017?style=for-the-badge&labelColor=0B0D1A" alt="Play now in your browser"></a>
  <img src="https://img.shields.io/badge/Three.js-r170-FFD76A?style=for-the-badge&logo=threedotjs&logoColor=white&labelColor=0B0D1A" alt="Three.js r170">
  <img src="https://img.shields.io/badge/built_by-Claude_Haiku_5.5-9B1C1C?style=for-the-badge&logo=claude&logoColor=white&labelColor=0B0D1A" alt="Built by Claude Haiku 5.5">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MIT-2E7BD6?style=for-the-badge&labelColor=0B0D1A" alt="MIT licence"></a>
  <img src="https://img.shields.io/badge/no_install-desktop_%C2%B7_phone-F2E6C9?style=for-the-badge&labelColor=0B0D1A" alt="No install, desktop and phone">
</p>

<p align="center"><b>A 3D rhythm march down an old Ottoman parade avenue: the mehter band walks towards you while notes roll down four lanes for the davul, kös, zurna and zil. Hit them on the beat and keep the band's spirit up.</b></p>

<p align="center">
  <img src="docs/gameplay.gif" width="640" alt="Mehter gameplay after the redesign: Perfect hits on the gilded hit line as the band marches down the crimson carpet between arcaded houses and banners">
  <br>
  <sub>Watch the promo: <a href="https://github.com/Furkiozknn/social-videos/releases/download/promo-2026-10/2026-10-28-mehter-en.mp4">EN</a> · <a href="https://github.com/Furkiozknn/social-videos/releases/download/promo-2026-10/2026-10-28-mehter-tr.mp4">TR</a></sub>
</p>

<p align="center"><b>Play online: <a href="https://furkiozknn.github.io/mehter/">https://furkiozknn.github.io/mehter/</a></b> (desktop and phone, no install)</p>

<!-- portals:start -->
<p align="center">Also on: <a href="https://furkiozknn.itch.io/mehter">itch.io</a></p>
<!-- portals:end -->

## Highlights

- **A whole band in front of you.** Kös and davul drummers, zurna players, a çevgen bearer and the mehterbaşı march
  towards the camera down a torch-lit avenue lined with plane trees and a cheering crowd.
- **Four lanes, four instruments.** Davul, kös, zurna and zil on `D` `F` `J` `K` (rebindable) or four touch zones; long
  zurna notes have to be held to the end.
- **Six songs in three difficulties.** From Düyek March at 96 BPM to March of Victory at 176 BPM, each in Easy, Normal and
  Hard; harder charts add notes from the same rhythm patterns, so every chart matches the music.
- **Timing you can trust.** Music is synthesised and scheduled on the audio clock, hits are judged against that clock,
  and a calibration screen measures your input offset.
- **Played by a bot.** The `?auto` bot plays all six songs; on the last one it hit all 907 notes perfectly for an S grade,
  with and without the optional assets.
- **Light on a laptop GPU.** 61 fps (the display cap) on an Intel UHD GPU at 1280x720 with 29 draw calls, before and
  after the asset pass ([measurements](docs/assets.md)).
- **One file, made in code.** One `index.html` with Three.js r170 from a CDN; the world, the band, the songs and the
  music are generated in code, with an optional CC0 asset pass loaded on top.

## How to play

> [!TIP]
> **Goal:** hit the notes on the beat and keep the band's spirit above zero until the end of the song. A clean run earns
> an S grade.

Notes roll towards the hit line on the road in front of the band. Press the lane key when a note reaches the line:
**Perfect** within 45 ms, **Good** within 110 ms, otherwise a miss. Zurna notes are long: press, then hold until the end
of the note.

<details>
<summary><b>More rules</b></summary>

- Releasing a zurna note too early breaks it.
- Combos raise the score multiplier: x2 at 10, x3 at 25, x4 at 50.
- Band spirit drops on misses and rises on hits. At zero the song ends.
- Results show a grade (S, A, B, C), a hit-timing histogram and your best score per song and difficulty.
- **Calibration:** open Calibration from the title screen, press Start and tap a key or the Tap button on each
  metronome beat. The median offset is saved and subtracted from every hit judgement.

</details>

### Controls

| Action | Mouse / touch | Keyboard |
|---|---|---|
| Lanes (davul, kös, zurna, zil) | tap the four lane zones at the bottom | `D` `F` `J` `K` (rebindable in Settings) |
| Pause / back | pause button | `P` / `Esc` |
| Music / effects | sound settings | `M` / `X` |
| Language | TR / EN button | `L` |
| Fullscreen | settings | |

Settings (volumes, TR / EN, Low / High quality, key bindings and the calibration offset) are saved in `localStorage`
under `arena.mehter.settings`; best results under `arena.mehter.best`. Turkish is the default language; phones start on
the Low tier.

<details>
<summary><b>URL flags for testing</b></summary>

| Flag | Effect |
|---|---|
| `?auto` | the bot plays through all six songs (Normal) to the end |
| `?debug` | draw calls, fps, triangles, state and JS errors on screen |
| `?sim=N` | fast-forward N seconds of song time before the first frame, without rendering |
| `?low` | shadows off, half the particles |
| `?noassets` | skip the CC0 asset files and keep the procedural world and synthesised sounds |
| `?lang=en` / `?lang=tr` | language |
| `?song=N` | song index (0-5) for `?auto` and `?sim` |
| `?screen=…` | open `settings`, `pause`, `select`, `calib` or `results` directly (for screenshots) |

In the browser console, `window.mehter.state()` returns the live state (including which assets loaded) and
`window.mehterSim(seconds)` fast-forwards the current song.

</details>

## Screenshots

<table>
  <tr>
    <td width="33%"><img src="docs/title.png" alt="Title screen"><br><sub>Title screen</sub></td>
    <td width="33%"><img src="docs/song-select.png" alt="Song select"><br><sub>Song select</sub></td>
    <td width="33%"><img src="docs/assets-after-gameplay-r2.png" alt="The band marching down the cobbled avenue"><br><sub>The band on the cobbled avenue</sub></td>
  </tr>
  <tr>
    <td><img src="docs/gameplay.png" alt="A perfect hit"><br><sub>A perfect hit</sub></td>
    <td><img src="docs/results.png" alt="Results: S grade on March of Victory"><br><sub>S grade, 907 of 907 perfect</sub></td>
    <td><img src="docs/settings.png" alt="Settings"><br><sub>Settings</sub></td>
  </tr>
</table>

## Redesign (2026-11)

**Art direction:** an Ottoman square at dusk, in crimson, gold and deep green on parchment stone, with torches that
swell on every beat.

<p align="center"><img src="docs/redesign-before-after.png" width="100%" alt="The same avenue before and after the redesign"><br><sub>Same camera, before (left) and after (right)</sub></p>

- **Environment:** arcaded houses with gold cornices and striped awnings, a mosaic floor drawn on a canvas (replaced
  by the cobblestone asset when it loads), canvas-painted banners with a crescent and star, a mosque dome and minarets
  closing the far end, green gardens beside the carpet.
- **Band:** the drum stick strikes on davul notes, the zil ring flashes gold on every zil hit, the zurna sways more
  while a note is held.
- **Look:** a gilded hit line that glows on the beat, gold and crimson sparks and confetti, crimson panels with a gold
  frame, gilded buttons, tuğra-style flourish dividers, Georgia headings (system font, nothing to download).
- **Language:** a first visit follows the browser (Turkish for `tr` browsers, English otherwise).

Measured in headless Chrome on the Intel UHD 620 laptop at 1280x720 with `?debug`, on the first song about 13 s in:
before 60 fps, 29 draw calls, 60,058 triangles; after 60 fps, 31 draw calls, 65,832 triangles. The `?auto` bot
finishes all six songs with 0 JS errors, both with the assets and with `?noassets`; on the last song it hits all 907
notes perfectly (S grade).

Not checked: a real phone (the 500x900 layout was checked in a desktop emulation only), a Turkish-locale browser, and
the drum, zil and zurna motion, which was checked in code and in still frames only. On the 500x900 layout the HUD
wraps the accuracy to a second row.

<details>
<summary><b>Phone layout and the asset pass, before and after</b></summary>

<table>
  <tr>
    <td width="50%"><img src="docs/assets-before-gameplay.png" alt="The avenue before the asset pass"><br><sub>Avenue, procedural</sub></td>
    <td width="50%"><img src="docs/assets-after-gameplay-r2.png" alt="The avenue after the asset pass"><br><sub>Avenue, with the asset pass</sub></td>
  </tr>
  <tr>
    <td><img src="docs/asset-preview-band-figure.png" alt="Blender band figure"><br><sub>Band figure model</sub></td>
    <td><img src="docs/asset-preview-band-instruments.png" alt="Blender instruments"><br><sub>Instrument models</sub></td>
  </tr>
</table>

<p align="center"><img src="docs/phone.png" width="300" alt="Mehter on a phone"><br><sub>On a phone</sub></p>

</details>

## Balance

The songs are generated in code from usul rhythm patterns (düyek, sofyan, semai, nevbet, devr and zafer). The bot run
`?auto&sim=99999` plays all six songs without rendering: on the last song all 907 notes were perfect, grade S, with 0 JS
errors, both with the assets and with `?noassets` ([bot run](docs/assets.md#numbers)).

## Running locally

Serve the folder over HTTP (browsers block some features on `file://`):

```
python -m http.server 8000
```

then open <http://localhost:8000/>.

## How it was made

Built by **Claude Haiku 5.5** with Claude Code from one prompt: [prompts/mehter.md](prompts/mehter.md); the shared arena
rules were appended to that prompt. The avenue, crowd, trees, torches and notes are instanced or merged low-poly geometry
with vertex colours, and the music, hit sounds and crowd cheers are synthesised with the Web Audio API.

An optional asset pass (about 1.75 MB, most of it the HDRI) adds Blender-built band figures (kaftan, sash, tall börk) and
instruments (davul, kös, zurna, çevgen), a Poly Haven cobblestone texture for the road, a dusk HDRI on the High tier, and
two Kenney sounds (a UI click and the results fanfare). They load after the first frame and the procedural versions stay
as the fallback (`?noassets` skips them). Licences: [CREDITS.md](CREDITS.md); file list, sizes and fps before and after:
[docs/assets.md](docs/assets.md). Model scripts: `assets/src/`.

Mehter is part of the **Claude Game Arena** series, where each game is built by a Claude model from one prompt. The
other games: [Hisar](https://furkiozknn.github.io/kale-savunmasi/) ·
[Çay Ocağı](https://furkiozknn.github.io/cay-ocagi/) · [Çini Ustası](https://furkiozknn.github.io/cini-ustasi/) ·
[Martı](https://furkiozknn.github.io/marti/) · [Kervan](https://furkiozknn.github.io/kervan/) ·
[Dolmuş](https://furkiozknn.github.io/dolmus/) · [Peri Golf](https://furkiozknn.github.io/peri-golf/) ·
[Boğaz Vapuru](https://furkiozknn.github.io/bogaz-vapuru/) · [Simit Fırını](https://furkiozknn.github.io/simit-firini/)
· [Karagöz](https://furkiozknn.github.io/karagoz/) · [Lale Bahçesi](https://furkiozknn.github.io/lale-bahcesi/)

**Round 5:** [Kapadokya Balonu](https://furkiozknn.github.io/kapadokya-balonu/) ·
[Ebru](https://furkiozknn.github.io/ebru/) · [Kırkpınar](https://furkiozknn.github.io/kirkpinar/) ·
[Çarşı Kaçışı](https://furkiozknn.github.io/carsi-kacisi/)

**Round 6:** [Topkapı Gecesi](https://furkiozknn.github.io/topkapi-gecesi/) ·
[Hamsi](https://furkiozknn.github.io/hamsi/) · [Pamukkale](https://furkiozknn.github.io/pamukkale/) ·
[Mimar Sinan](https://furkiozknn.github.io/mimar-sinan/)

## Türkçe

**Mehter**, eski bir Osmanlı alay caddesinde geçen 3D ritim oyunu. Mehter takımı sana doğru yürürken notalar davul, kös,
zurna ve zil için dört şeritten akar; vuruşu tam zamanında yap, uzun zurna notalarını basılı tut ve takımın ruhunu ayakta
tut. Altı şarkı, üç zorluk ve gecikme kalibrasyonu var. Kurulum yok; masaüstünde ve telefonda tarayıcıda oynanır. Claude
Haiku 5.5 tarafından Claude Code ile tek bir prompt'tan yapıldı.

**Oyna:** https://furkiozknn.github.io/mehter/

## License

MIT, see [LICENSE](LICENSE). Third-party assets are CC0, see [CREDITS.md](CREDITS.md).

Like the game? You can support new rounds on [Buy Me a Coffee](https://buymeacoffee.com/furkiozkann). The game stays free.
