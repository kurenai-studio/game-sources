# Çini Ustası: generated assets

Overnight pass of 2026-10-21. All assets were generated with the Higgsfield MCP (Tripo text-to-3D and GPT Image 2.5),
processed with glTF-Transform and sharp (`claude-game-arena/tools/assets`) and checked by eye (four-side GLB previews and
in-game screenshots). The game loads them at start-up with `GLTFLoader` / `TextureLoader`; anything that fails to load
(and everything when the page is opened from `file://` or with `?noassets`) keeps the original procedural version.

**The tile faces stay procedural on purpose.** Every face is composed at runtime from four edge motifs that must meet their
twin exactly at the edge midpoint, in one of four exact palette colours; generated art cannot guarantee that, and the
puzzle depends on it. The board picture, wall gallery, collection and complete-card preview are painted by the same code.

Credits for this pass: **20** (3 × 5 for Tripo, 4 × 0.5 + 0.5 + 1.5 + 1 for GPT Image). Nothing was rejected or
re-rolled. The account balance is shared with other agents working at the same time, so the before/after numbers
(187.78 → 101.28 at the time of writing) include their jobs too.

## Done

| Asset | Category | Replaces / why | Tool, prompt (short) | File | Format / size | QC | In game |
|---|---|---|---|---|---|---|---|
| Kiln | 3D | Box + half-sphere kiln (looked like a brick crate with a bowl on top) | Tripo `tripo_3d`, 5 cr: "Low-poly stylized traditional Anatolian pottery kiln … domed top, short round chimney at the back-left, large arched firing mouth on the front with a dark open interior, low stone plinth, warm terracotta …, toy-like clay look" | `assets/models/kiln.glb` | 7,446 tris, 1024 px WebP, 290 KB | Open arched mouth with a ledge; file faces +X | Yes. `rotateY(-90°)` so the mouth faces +Z, uniform scale so the depth is 2.4 m (≈ 2.16 × 2.09 × 2.4 m), base centre at (4.55, 0, -2.95). Glow quad 0.18 m inside the front face |
| Sitting cat | 3D | Box cat walking on a shelf at the screen edge, half under the HUD | Tripo, 5 cr: "cute stylised dark grey tabby cat sitting upright … tail curled around its front paws, big yellow eyes" | `assets/models/cat.glb` | 3,748 tris, 512 px WebP, 144 KB | Clean, readable at game distance; file faces +X | Yes. Height 0.46 m, on the stool seat (-4.2, 0.63, 1.4), yaw -0.54 rad (toward the board and the camera) ± 0.3 head turn; appears, breathes (scale.y ± 1.5 % at 0.3 Hz), leaves after 18-32 s, returns after 25-55 s. The procedural box cat stays as the fallback |
| Paint set (jar + brushes + 4 pots on a tray) | 3D | Procedural pots and brushes (brushes had a floating collar/tip, pots clipped the frame) | Tripo, 5 cr: "painter's set: a small wooden tray holding one white Iznik ceramic jar with blue patterns full of five upright paint brushes, and four small round paint pots … cobalt blue, turquoise, coral red and emerald green" | `assets/models/paint-set.glb` | 5,630 tris, 512 px WebP, 214 KB | Colours match the four motif colours | Yes. No rotation (jar at the back), depth 0.6 m (≈ 0.5 × 0.55 × 0.6 m), base centre at (2.68, 1.0, 1.5) |
| Table wood | Texture | Canvas wood lines | GPT Image medium 1k, 0.5 cr: "seamless tileable … worn warm walnut workbench top made of three wide planks running left to right … faint paint stains" | `assets/textures/wood.webp` | 1024², 152 KB | Good, paint specks fit the workshop | Yes, table top map, repeat (1.5, 1) |
| Terracotta floor | Texture | 192 vertex-coloured quads + 30 grout boxes | GPT Image medium 1k, 0.5 cr: "exactly 2 by 2 square handmade terracotta floor tiles with thin dark brown grout lines" | `assets/textures/floor-terracotta.webp` | 512², 27 KB | Seam between repeats has no grout line, barely visible at game distance | Yes, one 16 × 12 plane at y 0 (centre z 1), repeat (8, 6) |
| Lime plaster | Texture | Flat vertex-coloured walls | GPT Image medium 1k, 0.5 cr: "seamless tileable … warm cream lime plaster wall … subtle soft trowel marks" | `assets/textures/plaster.webp` | 512², 8 KB | Subtle, good | Yes, the three wall boxes merged into one mesh, repeat (4, 1.7), tint `#fbf3e3` |
| Window view | Texture | Flat sky gradient (that was also hidden inside the wall, H3) | GPT Image medium 1k 3:2, 0.5 cr: "view through a window … calm Iznik lake with soft green hills at golden hour, Ottoman houses with red tiled roofs and one slender white minaret" | `assets/textures/window-view.webp` | 768 × 512, 55 KB | Very good | Yes, unlit glass quad 2.6 × 1.7 at (-4.0, 2.85, WALL_Z + 0.005) |
| Kilim | Texture | 9 coloured bands + 4 stripes | GPT Image medium 1k 4:5, 0.5 cr: "flat-woven Anatolian kilim … geometric diamond and hooked motifs in deep red, ochre, cobalt blue and cream, short cream fringes" | `assets/textures/kilim.webp` | 512 × 640, 85 KB | Very good | Yes, plane 1.6 × 1.8 facing +X at (-5.975, 2.4, -3.1) |
| Crest | UI | The painted logo tile | GPT Image high 1k transparent, 1.5 cr: "Game logo emblem without any text: a round glazed Iznik ceramic tile medallion, a red tulip and a carnation with saz leaves … thin gold ring" | `assets/ui/crest-256.webp`, `assets/ui/crest-64.png`, `assets/ui/favicon.png` | 256 / 64 / 32 px | Clean, no text | Yes: title card (120 px), HUD (30 px), favicon. The painted tile stays as the fallback |
| Reflection panorama | Texture | No environment (glaze looked matte) | GPT Image medium 2k 16:9, 1 cr: "360 degree equirectangular panorama inside a warm cosy traditional pottery workshop …" | `assets/textures/workshop-pano.webp` | 1024 × 512, 71 KB | Not a true equirectangular seam, irrelevant for blurred reflections | Yes, PMREM → `scene.environment`, `environmentIntensity` 0.45, background unchanged. Fallback (file://, ?noassets): three's `RoomEnvironment` |

Total asset size: about 1.1 MB.

## Not started (tier 2 of the review's plan)

- Terracotta pot with geranium for the sill, copper ibrik + plate for the left table strip, glaze crackle overlay.
  Left out to keep the pass within the tier-1 plan; the procedural sill plant stays.

## Remaining issues

- The floor texture's outer border has a softer grout line than its inner cross, so the seams between repeats are a
  little lighter; hardly visible from the game camera.
- The kiln model is slightly lower than the old procedural kiln (2.09 m vs 2.96 m to the dome top); it reads better
  next to the table and no longer cuts the shelf.
