<p align="center">
  <a href="https://furkiozknn.github.io/karagoz/"><img src="docs/banner.svg" width="100%" alt="Karagöz: a shadow-theatre light puzzle with Karagöz and Hacivat behind the white cloth screen. Click to play in your browser."></a>
</p>

<p align="center">
  <a href="https://furkiozknn.github.io/karagoz/"><img src="https://img.shields.io/badge/%E2%96%B6_Play_now-in_your_browser-B91C1C?style=for-the-badge&labelColor=120A06" alt="Play now in your browser"></a>
  <img src="https://img.shields.io/badge/Three.js-r170-E9B44C?style=for-the-badge&logo=threedotjs&logoColor=white&labelColor=120A06" alt="Three.js r170">
  <img src="https://img.shields.io/badge/built_by-Claude_Opus_5.5-CDB595?style=for-the-badge&logo=claude&logoColor=white&labelColor=120A06" alt="Built by Claude Opus 5.5">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MIT-79B25E?style=for-the-badge&labelColor=120A06" alt="MIT licence"></a>
  <img src="https://img.shields.io/badge/no_install-desktop_%C2%B7_phone-F4E6CC?style=for-the-badge&labelColor=120A06" alt="No install, desktop and phone">
</p>

<p align="center"><b>A 3D shadow-theatre light puzzle about Karagöz and Hacivat: in a dim Ottoman coffee house at night, slide and turn coloured leather puppets and move the oil lamps until their shadows on the cloth match the story picture.</b></p>

<p align="center">
  <img src="docs/gameplay.gif" width="640" alt="Karagöz gameplay after the redesign: coloured leather puppets and oil lamps move behind the lamp-lit linen screen until the shadows match the gold outline">
</p>

<p align="center"><b>Play online: <a href="https://furkiozknn.github.io/karagoz/">https://furkiozknn.github.io/karagoz/</a></b> (desktop and phone, no install)</p>

<!-- portals:start -->
<p align="center">Also on: <a href="https://furkiozknn.itch.io/karagoz">itch.io</a></p>
<!-- portals:end -->

## Highlights

- **Real shadow optics.** A puppet near the lamp casts a big, soft shadow; near the cloth a small, sharp one. Two lamps
  make two shadows, and the shadows are computed with a true point-light projection and flame penumbra.
- **Coloured light.** Translucent leather multiplies the light, so overlapping pieces mix their colours; with red and
  blue glass lamps, each lamp's shadow shows in the other lamp's colour.
- **Two views.** Work backstage, dragging puppets on their rails and moving or dimming lamps, or switch to the audience
  view and drag the shadows themselves; a small inset always shows what the audience sees.
- **24 scenes in 4 acts.** Mukaddime (the garden), Muhavere (the boat), Fasıl (the witches and the djinn) and Bitiş (the
  donkey); each act adds new puppets, lamp types and mechanics, and act IV adds timed scenes with moving pieces.
- **A show after every solve.** Match the target to 90 % and the puppets act out a short TR / EN dialogue while the
  audience laughs and claps.
- **Played by a bot.** The `?auto` bot plays all 24 scenes, reading the same match % a player sees and making one move
  at a time; every target is rendered from a reference arrangement, so every scene can be solved.
- **One file, made in code.** One `index.html` with Three.js r170 from a CDN; every mesh, texture and sound is
  generated in code.

## How to play

> [!TIP]
> **Goal:** the gold dashed outline on the screen is the target picture. Move the puppets and lamps until the live
> match % in the top bar reaches 90 %. Earn up to 3 stars per scene, 72 in all.

Pick a piece or a lamp from the tray. Backstage, drag a puppet along its rail; pulling it towards or away from the screen
changes its depth. Click a lamp to dim it or put it out, and drag it along its rail to move it. In the audience view, drag
a shadow to slide its puppet; dragging up or down changes the depth.

<details>
<summary><b>More rules</b></summary>

- The buttons next to the tray move, turn, dim or remove the selected piece. Faded pieces are off stage: tap one to put
  it up. Fixed scenery stays put.
- **Stars:** one for solving, one for par or fewer moves, one for using no hint. A hint snaps one piece into place and
  costs a star.
- **Timed scenes (act IV):** the donkey, the boat and the djinn move along their tracks by themselves. Shift their timing
  with Earlier / Later; their shadows must be on the target when the cue marker passes.
- The scenes are one data table in the code, and every target is rendered from a reference arrangement.

</details>

### Controls

| Action | Mouse / touch | Keyboard |
|---|---|---|
| Move the selected piece | drag the puppet (backstage) or its shadow (audience view) | `Left` / `Right` slide, `Up` further from the screen, `Down` nearer |
| Move / dim a lamp | drag it along its rail, click to dim or put out | `Left` / `Right` move, `Up` / `Down` brighten or dim |
| Rotate | wheel, two-finger twist, tray buttons | `Q` / `E` |
| Select a piece or lamp | tray | `1`-`9` (an off-stage piece is put up) |
| Take a piece off stage | tray button | `Del` / `Backspace` |
| Backstage / audience view | view button | `V` or `Tab` from the stage (`Shift+Tab` reaches the buttons) |
| Undo / reset | undo and reset buttons | `Z` / `R` |
| Hint (costs a star) | hint button | `H` |
| Pause | pause button | `P` / `Esc` |
| Music / effects / language | HUD buttons | `M` / `X` / `L` |

Settings are saved in `localStorage` under `arena.karagoz.settings`; progress (stars per scene and the scene in
progress) under `arena.karagoz.save`, the best star total under `arena.karagoz.best`. The language follows the browser;
phones start on the Low tier.

<details>
<summary><b>URL flags for testing</b></summary>

| Flag | Effect |
|---|---|
| `?auto` | a bot plays all 24 scenes to the end, reading the same match % a player sees and making one move at a time |
| `?debug` | fps, draw calls, triangles, GPU name and JS errors on screen; `window.karagozSim(seconds)` and `window.karagozDebug` |
| `?sim=N` | fast-forward N seconds of simulation before the first frame |
| `?low` | shadows off, pixel ratio 1, smaller screen texture, half the dust particles |
| `?scene=N` | jump straight to scene N (1-24) |
| `?view=aud` | start in the audience view |
| `?lang=en` / `?lang=tr` | language |
| `?nosave` | do not write to `localStorage` |
| `?noassets` | accepted; the game ships no asset files, so it changes nothing |

The live state is on `window.karagoz`.

</details>

## Screenshots

<table>
  <tr>
    <td width="33%"><img src="docs/01-title.png" alt="Title screen"><br><sub>Title screen</sub></td>
    <td width="33%"><img src="docs/02-backstage.png" alt="Backstage: puppets on rails in front of the oil lamp"><br><sub>Backstage: big shadow, small shadow</sub></td>
    <td width="33%"><img src="docs/03-audience.png" alt="Audience view after a solved scene with the dialogue"><br><sub>Scene solved: Karagöz and Hacivat talk</sub></td>
  </tr>
  <tr>
    <td><img src="docs/04-colour-lamps.png" alt="Act III, red and blue glass lamps"><br><sub>Act III: red lamp, blue lamp</sub></td>
    <td><img src="docs/05-act-map.png" alt="Act map"><br><sub>Act map</sub></td>
    <td><img src="docs/06-phone.png" alt="Karagöz on a phone"><br><sub>On a phone</sub></td>
  </tr>
  <tr>
    <td><img src="docs/07-cafe.png" alt="The coffee house from the audience side"><br><sub>The café, audience side</sub></td>
  </tr>
</table>

## Redesign (2026-11)

<p align="center"><img src="docs/redesign-before-after.png" width="100%" alt="Before and after the redesign: the backstage view"></p>

**Art direction: traditional shadow theatre.** Lamp amber `#FFB000`, screen linen `#F3E5C0`, leather dyes red `#B22222`,
green `#2E8B57` and indigo `#283593`, curtain maroon `#5D1A1A`; translucent tooled leather in an oil-lit coffee house.

- **Café:** lime-plaster walls with an İznik-style tile dado and a stencilled frieze, a carved walnut proscenium with an
  ogee arch and lamp-lit lattice panels, kilims on the floor, swaying brass lanterns with amber glass, nargile pipes
  with rising smoke, audience in coloured robes, a planked puppet table backstage.
- **Puppets and lamps:** the leather now has grain, darker cut edges and punched dot rows, both on the 3D puppets and
  in their shadows (display only: the match is still scored from the plain shapes); puppets glow like backlit hide and
  sway a little on their rods. The lamps are turned brass kandils with a bulb chimney and a handle.
- **Stage:** the cloth reads as lamp-lit linen (warm glow on each kandil, darker amber edges, weave, vignette); the leather
  shadows get a render-only stained-glass overlay with grain, outlines and punched dots; backstage, maroon drapes with
  gold tassels and a carved ogee arch frame the screen, and the stage floor falls from warm near the lamps to dark edges.
- **FX:** a slow oil-lamp breathing on top of the flicker, flame wobble, gold sparks along the screen on every solve.
- **UI:** cut-leather panels with a row of punched holes inside the edge, a maroon curtain valance over every menu,
  a walnut top bar, dye-coloured act cards and dialogue tags; 14 px minimum body text on phones and a compact
  landscape layout.
- **Kept:** all 24 scenes, 72 stars, controls, the match maths, the bot, saves (`arena.karagoz.*`), flags, audio and
  i18n. The default language now follows the browser (Turkish for `tr-*`, English otherwise); a saved choice still wins.
- **Measured** (headless Chrome, Intel UHD 620, 1280×720): static scenes 60 fps before and after; draw calls 18-22 →
  28-32; timed act IV scenes 39 fps before and after (they redraw the cloth texture every 30 ms, as before; `?low` gives 60).

## Running locally

Serve the folder over HTTP (ES modules do not load from `file://`):

```
python -m http.server 8000
```

then open <http://localhost:8000/>.

## How it was made

Built by **Claude Opus 5.5** with Claude Code from one prompt: [prompts/karagoz.md](prompts/karagoz.md). Everything is
generated in code:

- **Shadows:** each puppet is a set of 2D leather polygons with perforations, baked at startup into a transmission
  sprite. For each lamp, a canvas layer is filled with the lamp colour and every sprite is drawn on it with `multiply`,
  scaled by the point-light projection `s = D / (D - p)` around the lamp and blurred by the flame penumbra
  `r · p / (D - p)`. The lamp layers are added together into the cloth texture of the 3D screen.
- **Match:** the current and the reference arrangement are drawn into an 80×52 offscreen canvas; the score is a weighted
  Jaccard index of per-pixel, per-channel darkness, times a brightness factor that catches wrongly dimmed lamps.
- **3D:** a flat-shaded, vertex-coloured coffee house merged into a few draw calls, instanced audience silhouettes, one
  shadow-casting directional light, lamp point lights backstage and soft-sprite dust motes. The screen texture is
  redrawn only when something on it changes.
- **Audio:** Web Audio only: a ney melody in makam Hicaz over a tef in an 8-beat usul, a drone, the nareke whistle,
  synthesised audience laughs, applause, cloth rustles and lamp clinks.

Karagöz is part of the **Claude Game Arena** series, where each game is built by a Claude model from one prompt. The
other games: [Hisar](https://furkiozknn.github.io/kale-savunmasi/) ·
[Çay Ocağı](https://furkiozknn.github.io/cay-ocagi/) · [Çini Ustası](https://furkiozknn.github.io/cini-ustasi/) ·
[Martı](https://furkiozknn.github.io/marti/) · [Kervan](https://furkiozknn.github.io/kervan/) ·
[Dolmuş](https://furkiozknn.github.io/dolmus/) · [Peri Golf](https://furkiozknn.github.io/peri-golf/) ·
[Mehter](https://furkiozknn.github.io/mehter/) · [Boğaz Vapuru](https://furkiozknn.github.io/bogaz-vapuru/) ·
[Simit Fırını](https://furkiozknn.github.io/simit-firini/) · [Lale Bahçesi](https://furkiozknn.github.io/lale-bahcesi/)

**Round 5:** [Kapadokya Balonu](https://furkiozknn.github.io/kapadokya-balonu/) ·
[Ebru](https://furkiozknn.github.io/ebru/) · [Kırkpınar](https://furkiozknn.github.io/kirkpinar/) ·
[Çarşı Kaçışı](https://furkiozknn.github.io/carsi-kacisi/)

**Round 6:** [Topkapı Gecesi](https://furkiozknn.github.io/topkapi-gecesi/) ·
[Hamsi](https://furkiozknn.github.io/hamsi/) · [Pamukkale](https://furkiozknn.github.io/pamukkale/) ·
[Mimar Sinan](https://furkiozknn.github.io/mimar-sinan/)

## Türkçe

**Karagöz**, gece bir Osmanlı kahvehanesinde geçen 3D gölge oyunu ışık bulmacası. Perdenin arkasında renkli deri
tasvirleri kaydır ve döndür, kandilleri taşı ya da kıs; gölgeler altın hedef çizgisine %90 uyunca Karagöz ile Hacivat
sahneyi oynar, seyirci güler ve alkışlar. 4 perdede 24 sahne var. Kurulum yok; masaüstünde ve telefonda tarayıcıda
oynanır. Claude Opus 5.5 tarafından Claude Code ile tek bir prompt'tan yapıldı.

**Oyna:** https://furkiozknn.github.io/karagoz/

## License

MIT, see [LICENSE](LICENSE).

Like the game? You can support new rounds on [Buy Me a Coffee](https://buymeacoffee.com/furkiozkann). The game stays free.
