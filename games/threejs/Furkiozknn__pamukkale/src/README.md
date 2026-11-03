<p align="center">
  <a href="https://furkiozknn.github.io/pamukkale/"><img src="docs/banner.svg" width="100%" alt="Pamukkale: a calm water-flow puzzle on white travertine terraces with turquoise pools, warm water running down from a steaming spring. Click to play in your browser."></a>
</p>

<p align="center">
  <a href="https://furkiozknn.github.io/pamukkale/"><img src="https://img.shields.io/badge/%E2%96%B6_Play_now-in_your_browser-12868C?style=for-the-badge&labelColor=173B44" alt="Play now in your browser"></a>
  <img src="https://img.shields.io/badge/Three.js-r170-E8B04B?style=for-the-badge&logo=threedotjs&logoColor=white&labelColor=173B44" alt="Three.js r170">
  <img src="https://img.shields.io/badge/built_by-Claude_Haiku_5.5-2EC4C9?style=for-the-badge&logo=claude&logoColor=white&labelColor=173B44" alt="Built by Claude Haiku 5.5">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MIT-D9644F?style=for-the-badge&labelColor=173B44" alt="MIT licence"></a>
  <img src="https://img.shields.io/badge/no_install-desktop_%C2%B7_phone-FBF7EE?style=for-the-badge&labelColor=173B44" alt="No install, desktop and phone">
</p>

<p align="center"><b>A calm 3D water-flow puzzle on the white travertine terraces of Pamukkale: guide warm spring water down the hillside into the target pools with stones, dams and splitters, while still water slowly builds new white calcium rims and changes the terraces as you play.</b></p>

<p align="center">
  <img src="docs/gameplay.gif" width="640" alt="Pamukkale gameplay after the redesign: turquoise spring water spreads over the pastel travertine terraces around the placed stones and fills the pools">
</p>

<p align="center"><b>Play online: <a href="https://furkiozknn.github.io/pamukkale/">https://furkiozknn.github.io/pamukkale/</a></b> (desktop and phone, no install)</p>

<!-- portals:start -->
<p align="center">Also on: <a href="https://furkiozknn.itch.io/pamukkale">itch.io</a></p>
<!-- portals:end -->

## Highlights

- **Three tools, limited.** A stone raises a cell by one step so the water turns around it, a dam raises it by two
  and holds water back, and a splitter divides the flow between every lower neighbour.
- **Living terraces.** Water that stands still for a while builds calcium: dry cells beside a standing pool rise to
  the water line, so the board changes while the water runs.
- **20 levels in 4 areas.** Lower Pools, Middle Shelves, Ancient Pool and Sunset. Three stars per level: all pools
  full, no water spilled, and tool saving (at most the par number of tools).
- **Every level checked.** Layouts come from seeded random hillsides and were kept only if the empty board fails and
  a short solution fills every pool; `tools/solve-levels.mjs` re-checks each stored solution with the same simulation
  code.
- **Played by a bot.** `?auto` replays each level's stored solution through the same placement function a click uses.
  Measured on the redesign branch: **20/20 levels, 46/60 stars**, zero JavaScript errors, with and without `?noassets`.
- **One file, made in code.** One `index.html` with Three.js r170 from a CDN; terrain, water and tools are procedural
  geometry, and a saz-like plucked loop, a flute line, trickling water, splashes and birdsong are synthesised with
  Web Audio.

## How to play

> [!TIP]
> Watch where the water leaves the board and block that path first: spilled water costs the "no water spilled" star,
> and every tool you keep in the tray counts towards the tool-saving star.

Warm water comes out of the spring at the top of the terraces. Place your tools on the grid, then start the water.
Fill every target pool to its mark: the ring in each pool shows the mark and turns turquoise when the pool is full.
Water that runs off the bottom edge is spilled and wasted.

### Controls

| Action | Keys / mouse / touch |
|---|---|
| Place the selected tool | click or tap a cell |
| Remove a tool | right-click, or long-press on touch |
| Select tool | `1` stone, `2` dam, `3` splitter, or tap the tray |
| Start / stop water | `Space` (or the water button) |
| Fast forward | `F` |
| Undo last tool change | `Z` |
| Reset level | `R` |
| Pause / resume | `P` or `Esc` |
| Music / effects / language | `M` / `X` / `L` |
| Orbit / zoom | drag (mouse or one finger) / mouse wheel or pinch |

Turkish is the default language (`L` or the **EN** toggle switches). Progress is saved in `localStorage` under
`arena.pamukkale.save`, settings under `arena.pamukkale.settings` and the best result under `arena.pamukkale.best`.

<details>
<summary><b>URL flags for testing</b></summary>

| Flag | Effect |
|---|---|
| `?auto` | the bot plays all 20 levels, replaying each stored solution at 3x speed |
| `?debug` | fps, draw calls, triangles and any JavaScript errors on screen |
| `?sim=N` | start the first level with N seconds of water already fast-forwarded |
| `?low` | shadows off, fewer particles, pixel ratio 1 |
| `?lang=en` | English |
| `?noassets` | accepted; the game has no asset files, so nothing changes |

`window.pamukkaleSim(seconds)` fast-forwards the simulation without rendering and returns the live state.

</details>

## Screenshots

## Redesign (2026-11)

**Art direction:** bright pastel travertine on a sage meadow: turquoise water with shore foam and caustic light,
peach sunset sky, airy white cards with turquoise accents. Palette: travertine `#F5F3EE`, turquoise `#2EC4C9`,
sunset peach `#FFC9A9`, ruin stone `#CDB89A`, sky `#BFE6FF`.

- **Terraces:** travertine step edges that catch the light (the steepest shelf edges brighten towards `#FBF8F2`),
  slope shading, and stepped travertine ledges down the valley sides. The simulation and level data are unchanged.
- **Scene:** pastel meadow, shrubs, boulders, a pale distant range inside the fog, lathe-turned spring bowl,
  rounded theatre benches and ruin columns.
- **Water and FX:** shore foam, a scrolling caustic texture, a sparkle when a tool is placed, slowly drifting clouds.
- **UI:** white cards, pill buttons, floating HUD pills, and a layout that works on phones and short landscape screens.
- **Language:** the default follows the browser (Turkish or English); a saved setting still wins.

Before and after, same level and camera (level 9):

<p align="center"><img src="docs/redesign-before-after.png" width="100%" alt="Level 9 before (left) and after (right) the redesign"></p>

Measured with headless Chrome at 1280x720 on the redesign branch: draw calls 17 before, 21 after (level 9 in play);
triangles 26k before, 34k after. Frame rate is not claimed; headless rAF is not a GPU budget. The banner, card and
gameplay GIF still show the old look until the media pass.

<table>
  <tr>
    <td width="33%"><img src="docs/01-title.png" alt="Title screen"><br><sub>Title screen</sub></td>
    <td width="33%"><img src="docs/03-gameplay-level1.png" alt="Level 1: water runs from the spring towards the first pool"><br><sub>Level 1</sub></td>
    <td width="33%"><img src="docs/02-gameplay-level9.png" alt="Level 9: three pools filling in turn"><br><sub>Level 9, three pools</sub></td>
  </tr>
  <tr>
    <td><img src="docs/04-ending.png" alt="Ending screen after the bot run with 20 of 20 levels and 46 of 60 stars"><br><sub>Ending after the <code>?auto</code> run: 20/20 levels, 46/60 stars</sub></td>
    <td><img src="docs/05-phone-500x900.png" alt="Pamukkale on a phone"><br><sub>On a phone</sub></td>
    <td></td>
  </tr>
</table>

## Running locally

Serve the folder over HTTP, for example:

```
python -m http.server 8000
```

then open <http://localhost:8000/>. Check every level offline with `node tools/solve-levels.mjs`: it prints a
solution per level, or FAILED.

## How it was made

Built by **Claude Haiku 5.5** with Claude Code from one prompt: [prompts/pamukkale.md](prompts/pamukkale.md).
Everything is generated in code, so there are no asset files and no credits to list.

<details>
<summary><b>Technical notes</b></summary>

- **Simulation:** the water is a small grid automaton in plain JavaScript between the `SIM-BEGIN` and `SIM-END`
  markers in `index.html`; `tools/solve-levels.mjs` runs the same code.
- **3D:** terrain, water and tools are procedural geometry with vertex colours, with instanced meshes for repeated
  objects; 21-22 draw calls measured in play on the redesign branch. The headless frame rate is a rAF reading, not a measured GPU budget, so no fps
  figure is claimed.
- **Known limits:** the terraces are an approximate, plateau-style hillside and the sloped apron at the edge is a
  simplified form; level 16 uses a looser difficulty band than its neighbours.

</details>

Pamukkale is part of the **Claude Game Arena** series, where each game is built by a Claude model from one prompt. The
other games: [Hisar](https://furkiozknn.github.io/kale-savunmasi/) ·
[Çay Ocağı](https://furkiozknn.github.io/cay-ocagi/) · [Çini Ustası](https://furkiozknn.github.io/cini-ustasi/) ·
[Martı](https://furkiozknn.github.io/marti/) · [Kervan](https://furkiozknn.github.io/kervan/) ·
[Dolmuş](https://furkiozknn.github.io/dolmus/) · [Peri Golf](https://furkiozknn.github.io/peri-golf/) ·
[Mehter](https://furkiozknn.github.io/mehter/) · [Boğaz Vapuru](https://furkiozknn.github.io/bogaz-vapuru/) ·
[Simit Fırını](https://furkiozknn.github.io/simit-firini/) · [Karagöz](https://furkiozknn.github.io/karagoz/) ·
[Lale Bahçesi](https://furkiozknn.github.io/lale-bahcesi/)

**Round 5:** [Kapadokya Balonu](https://furkiozknn.github.io/kapadokya-balonu/) ·
[Ebru](https://furkiozknn.github.io/ebru/) · [Kırkpınar](https://furkiozknn.github.io/kirkpinar/) ·
[Çarşı Kaçışı](https://furkiozknn.github.io/carsi-kacisi/)

**Round 6:** [Topkapı Gecesi](https://furkiozknn.github.io/topkapi-gecesi/) · [Hamsi](https://furkiozknn.github.io/hamsi/) ·
**Pamukkale** · [Mimar Sinan](https://furkiozknn.github.io/mimar-sinan/)

## Türkçe

**Pamukkale**, beyaz travertenlerde geçen sakin bir 3D su akışı bulmacası. Kaynaktan çıkan ılık suyu taş, set ve
ayırıcılarla yamaçtan aşağı, hedef havuzlara yönlendirirsin. Durgun su zamanla beyaz kireç kenarlar örer, teraslar
oynarken değişir. 4 bölgede 20 seviye, seviye başına 3 yıldız. Kurulum yok; masaüstünde ve telefonda tarayıcıda
oynanır. Claude Haiku 5.5 tarafından Claude Code ile tek bir prompt'tan yapıldı.

**Oyna:** https://furkiozknn.github.io/pamukkale/

## License

MIT, see [LICENSE](LICENSE).

Like the game? You can support new rounds on [Buy Me a Coffee](https://buymeacoffee.com/furkiozkann). The game stays free.
