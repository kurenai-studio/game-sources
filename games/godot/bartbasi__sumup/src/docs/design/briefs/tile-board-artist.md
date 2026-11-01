# Brief: tile-board-artist, Phase 1 design directions

From the senior-graphic-designer. The Development Manager launches you with this brief. I review your work in round 2 and compose it into the final screens.

## Task

Build the tile and board visuals for all three Phase 1 directions, Gumdrop, Slate and Nova, as real Godot code: tile shapes, the color ramp in use, number rendering with abbreviations, the chain path line, the chain preview, the targeting look, and merge, spawn and fall effects. Each direction must look and move like its write-up. The three must stay clearly different from each other; do not let them drift toward one shared style.

This is Phase 1 prototype work. It lives under tools/, does not ship, and is not the Phase 2 skin system. Nothing goes in src/, scenes/ or tests/ for this task.

## Read first

1. CLAUDE.md
2. docs/BRIEF.md, section 4
3. The three write-ups: docs/design/gumdrop.md, docs/design/slate.md, docs/design/nova.md
4. The token files, which are the source of every value: tools/directions/gumdrop/tokens.gd, tools/directions/slate/tokens.gd, tools/directions/nova/tokens.gd
5. tools/directions/shared/direction_tokens.gd (the token API: `fill_for()`, `ink_for()`, `color()`, `num()`, `motion_spec()`, `duration()`, `font()`, `tile_font_size()`, `cased()`)
6. tools/directions/shared/mock_state.gd (the board, chain, preview, target cell and `tile_label()`)

docs/GDD.md is being written in parallel. Do not wait for it. Take every number and label from mock_state.gd so I can sync it in one place later.

## Where you may write

You may create and edit only these paths, plus the `.uid` files Godot makes next to your scripts:

- `tools/directions/board_common/` (optional shared code for all three directions)
- `tools/directions/gumdrop/board/`
- `tools/directions/slate/board/`
- `tools/directions/nova/board/`
- `docs/design/review/board-*.png`, written only by the capture tool (see Proof)

Do not edit anything else. That includes the token files, everything in tools/directions/shared/, tools/capture.gd, tools/contrast_check.gd, the `ui/` and `screens/` folders, src/, scenes/ and tests/. If a value you need is missing, see "Missing values" below.

## Code rules

- Statically typed GDScript everywhere. Untyped declarations are compile errors in this project.
- No `class_name` under tools/. Load scripts with preload into a typed const, for example:
  ```gdscript
  const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
  const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
  const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
  ```
  Get a direction's tokens with `Directions.load_tokens("gumdrop")`.
- Everything is drawn in code: `_draw()`, StyleBoxFlat, Tweens, and gradients or meshes built in code. No image files, no font files, no addons.
- No MSAA. The capture renders like the game, without it. Use StyleBoxFlat with `anti_aliasing = true` (corner_detail 12 or more for squircles), pass `antialiased = true` to `draw_line`, `draw_polyline`, `draw_arc` and `draw_circle`, and give filled polygons an antialiased outline.
- 60 fps on a mid range Android phone with a full board: redraw only when something changes, create StyleBoxes, gradients and arrays once in `setup()` and reuse them, no allocation inside `_draw()` or `_process()`. No per tile shaders. If you think you need a shader, it must be a canvas_item shader that works on the Compatibility renderer, and you explain why in your report.
- No em dashes and no double hyphens in comments.

## Number and color rules

- Every tile number uses `tokens.font("tile")`, size `tokens.tile_font_size(side, label)`, color exactly `tokens.ink_for(value)`, and the label from `MockState.tile_label(value)`.
- The number always sits on the flat `tokens.fill_for(value)`. No gradient, highlight, ring, rim, glow, shadow or chain line may pass through the number's bounding box. That is what the contrast check proves, so it must stay true on screen.
- Colors come only from the palette tokens, the ramp, and the derivations the tokens name (for example Gumdrop's lip is `fill.darkened(num("lip_darken"))`).
- Timings and curves come only from `tokens.motion_spec(name)`: `duration`, `trans`, `ease` and the extra numbers listed in each tokens.gd.

## What to build, per direction

In each of `tools/directions/<id>/board/`:

| File | What it is |
|---|---|
| `tile_view.gd` | One tile, as a Control |
| `board_view.gd` | The whole board, as a Control |
| `board_sheet.tscn` | Static review sheet, 1080 by 2400 |
| `board_mock.tscn` | The mock board with the chain being dragged, 1080 by 2400 |
| `board_mock_target.tscn` | The mock board in Hammer targeting mode, 1080 by 2400 |
| `board_demo.tscn` | Looping motion demo, run in a window |

Add any helper scripts you like in the same folder or in `board_common/`.

### The interface I compose against

Use exactly these names and signatures in all three directions, so my screen code is the same for each.

`tile_view.gd`, extends Control:

```gdscript
const STATE_NORMAL: int = 0
const STATE_CHAINED: int = 1
const STATE_TARGET: int = 2
func setup(tokens: DirectionTokens) -> void
func set_value(value: int) -> void
func set_state(state: int) -> void
```

- Draws one tile in its own rect: a square of side `min(size.x, size.y)`, centered. Must look right at any side from 48 px to 400 px, because I use it for the preview tile, the best tile on game over and the mini tiles in the settings skin chips.
- Effects such as Nova's glow or Gumdrop's special rim may draw outside the rect by up to 30% of the side.

`board_view.gd`, extends Control:

```gdscript
func setup(tokens: DirectionTokens) -> void
## MockState.ROWS rows of MockState.COLUMNS values, top row first. 0 is an empty cell.
func set_board(values: Array[PackedInt32Array]) -> void
## Cells as Vector2i(column, row) in drag order. drag_point is in cell units,
## Vector2(0, 0) at the top left of the grid. An empty array clears the chain.
func set_chain(cells: Array[Vector2i], drag_point: Vector2) -> void
## The live result while dragging. 0 hides it. Slate draws nothing here; its header shows the preview.
func set_preview(value: int) -> void
## The tile under the finger in targeting mode. Vector2i(-1, -1) clears it.
func set_target(cell: Vector2i) -> void
## Targeting mode on or off. Starts or stops the target pulse.
func set_targeting(active: bool) -> void
## Local rect of a cell's tile, for overlays.
func cell_rect(cell: Vector2i) -> Rect2
## Height this board needs when it is given this width, tray included.
func preferred_height(width: float) -> float
```

- The control's rect is the whole board area, including Gumdrop's tray. I place it `num("board_margin")` from the screen sides, give it width `1080 - 2 * board_margin` and height `preferred_height(width)`. It must also work in a smaller rect, down to 40% of that size (Slate's game over shows the final board as a small figure): tiles stay square, as large as fit, grid centered.
- An empty cell (value 0) shows the direction's empty look: Gumdrop a flat slot in `slot`, Slate a 2 px frame in `rule`, Nova nothing.
- The static look must be complete in the first frame after the `set_*` calls, with no tween needed to reach it. The capture tool grabs after 12 frames. Looping animations (the target pulse) may be at any phase in a capture, so every phase must look right.
- Put your effect functions (spawn, merge, fall) in `board_view.gd` too, with any names you like, and list them in your report.

## Art direction

### Gumdrop: tactile candy

- **Tile**: squircle, corner radius `tile_radius` times the side. Draw the lip as the full tile shape in `fill.darkened(lip_darken)`, then the top face in the fill, raised by `lip_depth` times the side, so the lip shows only along the bottom. The number is centered on the face. A thin lighter edge along the top of the face is welcome if it stays clear of the number.
- **Board**: a rounded tray in `tray` (`tray_radius`, `tray_padding`), `gap` between tiles.
- **Chain**: the rope is drawn under the tiles, center to center in `chain`, `rope_width` wide, round caps and joints, so it shows in the gaps like beads on a string. It also runs from the last tile toward `drag_point`. Chained tiles press in (lip shrinks to `lip_pressed`, face moves down with it) and get a `ring_width` ring in `chain` just outside the face.
- **Preview**: a rounded bubble in `ink` above the last chain tile (below it if the tile is in the top row), with a small pointer toward the tile, holding a mini tile with lip at `preview_scale` times the tile side.
- **Target**: the targeted tile lifts by `target_lift`, wobbles by `wobble_degrees` on the `target_pulse` loop, and gets a double ring: `target_edge` outside, `target` inside, so it shows on every tile color.
- **Special, from `special_from`**: a candy rim around the face, cycling through the 2 to 256 ramp colors in segments.
- **Motion**: spawn from `from_scale` with back ease and `stagger` per tile. Merge: chain tiles get sucked into the last tile along the chain (`merge_travel`), then the result pops to `peak_scale` and settles elastically (`merge_pop`). Fall with back ease and a `squash` on landing.

### Slate: editorial and exact

- **Tile**: flat, corner radius `tile_radius` px, no shadow, no gradient. Slabs (2 to 64) and blocks (128 up) are both just their fill; the ramp does the work. The number sits top left, inset `number_inset` times the side, its cap top at the inset line.
- **Board**: no tray and no background. `gap` between tiles.
- **Chain**: chained tiles get a `chain_frame` px frame in `chain` inset inside the tile edge. The chain line runs center to center in straight segments: first a `chain_edge` line `line_width + 2 * line_edge` wide, then the `chain` line `line_width` wide, square ends, with a `node_size` square node on each chained tile center. It also runs to `drag_point`. Draw order: fills, frames, line, nodes, numbers.
- **Preview**: none on the board.
- **Target**: four corner brackets in `target`, just outside the tile corners, arms `target_bracket` times the side, `target_bracket_width` thick. They hold still.
- **Special, from `special_from`**: an inner hairline frame in `ink_dark`, `rule_width` thick, inset `special_inset` times the side.
- **Motion**: spawn wipes down from the tile's top edge (scale y from `from_scale_y`, pivot at the top), all at once. Merge: chain tiles slide into the last tile (`merge_travel`), the result shows paper (`ink`) fill for a beat, then cuts to its color (`merge_pop`). Fall with quart ease out, no bounce.

### Nova: tiles are stars

- **Orb**: a circle of diameter `orb_scale` times the cell pitch, flat fill, with a `rim_width` rim in `fill.lightened(rim_lighten)` just inside the edge. Number centered.
- **Glow**: behind each orb, in its fill color. Radius = orb radius times a lerp from `glow_spread_low` to `glow_spread_high`, alpha a lerp from `glow_alpha_low` to `glow_alpha_high`, both by ramp index from 0 (value 2) to 16 (131072). Make one radial GradientTexture2D in code once and draw it tinted per orb.
- **Board**: no tray, no grid lines. The orbs float on the backdrop (the ui-motion-artist draws the backdrop; use a plain `bg` rect behind your sheets and mocks).
- **Chain**: a beam drawn under the orbs: a `beam_glow_width` glow at `beam_glow_alpha` that takes the chained orbs' fill colors along its length, and a `chain` core `beam_width` wide on top, round joints. It also runs to `drag_point`. Chained orbs get a `chain_rim_width` rim in `chain` and a brighter glow.
- **Preview**: a small orb with glow, `preview_scale` times the orb diameter, floating just above the last orb in the chain (below it if the orb is in the top row).
- **Target**: a dashed orbit ring in `target`, radius = orb radius times (1 + `orbit_offset`), `orbit_width` thick, slowly turning and breathing on the `target_pulse` loop, plus a brighter glow.
- **Special, from `special_from`**: corona rays, 12 thin lines around the orb, outside the rim.
- **Motion**: spawn from `from_scale` and `from_alpha` with sine ease, `stagger` per tile, glow blooming in. Merge: orbs glide along the beam path (not straight) into the last orb (`merge_travel`), which blooms to `peak_glow` times its glow and settles (`merge_pop`). Fall with cubic ease out.

## Review scenes

Every scene below has a root Control filling the 1080 by 2400 canvas, starts with a full screen rect in the direction's `bg`, and reads its data from MockState.

- **board_sheet.tscn**:
  1. The full ramp: 2 to 131072 plus 262144, 18 TileViews at the real board tile size, five per row, with the value in small text under each if you like (use a listed text pair).
  2. States: values 64 and 1024, each in normal, chained and target state.
  3. Small size check: 1024, 2K and 128K at 75% of the real tile size.
  4. Effect frames: spawn and merge pop, each frozen at 0, one third, two thirds and the end of its duration (drive your effect code with a fixed progress value).
- **board_mock.tscn**: BoardView placed as in the composition, top edge at y = 432 (Gumdrop), 532 (Slate) or 420 (Nova), showing `MockState.board_values()`, `chain_cells()`, `drag_point()` and preview `CHAIN_PREVIEW`.
- **board_mock_target.tscn**: the same board with no chain, `set_targeting(true)` and `set_target(MockState.TARGET_CELL)`.
- **board_demo.tscn**: runs in a window and loops a scripted sequence on the mock board: the board spawns in, the mock chain builds tile by tile with the preview updating, it commits (merge travel and pop to 256), the other chain cells clear, tiles above fall and new tiles spawn at the top, then about two seconds of targeting on TARGET_CELL, then it starts over. The values are scripted; no game rules needed.

## Missing values

If you need a number the tokens do not have (a ray count, a confetti count, a bubble pointer size), make it a named const at the top of your script with the comment `# Proposed token`, and list it in your report. I move it into the token file in round 2. Do not add colors that are not tokens or named derivations; ask in your report instead. Do not edit the token files.

## Proof

1. Contrast check still passes (you do not change tokens, this is a sanity check):
   `godot --headless --path . --script res://tools/contrast_check.gd` ends with `PASS` and exit code 0.
2. Capture all nine review PNGs, each run ending in `1 of 1 written without errors` and exit code 0:
   ```bash
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/gumdrop/board/board_sheet.tscn --out docs/design/review/board-gumdrop-sheet.png
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/gumdrop/board/board_mock.tscn --out docs/design/review/board-gumdrop-mock.png
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/gumdrop/board/board_mock_target.tscn --out docs/design/review/board-gumdrop-target.png
   ```
   and the same for `slate` and `nova`. The capture fails on any script or engine error logged while the scene loads or renders, so a clean run is part of the proof. Look at every PNG yourself before you report and fix what does not match this brief.
3. Each demo runs for 20 seconds without an error line in the output:
   `godot --path . res://tools/directions/<id>/board/board_demo.tscn --quit-after 1200`

## Report

End with a short report:

1. Files created, by folder.
2. Proof: the commands above and their final lines, and the nine PNG paths.
3. Your effect function names in each board_view.gd.
4. Every proposed token, with file, name, value and what it does.
5. Anything in this brief that was unclear or that you could not do, and suggestions.
