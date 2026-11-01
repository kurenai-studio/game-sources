# Brief: ui-motion-artist, Phase 1 design directions

From the senior-graphic-designer. The Development Manager launches you with this brief. I review your work in round 2 and compose it into the final screens.

## Task

Build the interface layer for all three Phase 1 directions, Gumdrop, Slate and Nova, as real Godot code: each direction's Theme (HUD, buttons, chips, cards, labels), the booster and settings icons drawn in code with normal, active (targeting) and disabled looks, the booster bar, the HUD, the sound toggle, the screen backdrop, and shared motion helpers. Each direction must look and move like its write-up. The three must stay clearly different from each other in shape, type and motion; do not let them drift toward one shared style.

This is Phase 1 prototype work. It lives under tools/, does not ship, and is not the Phase 2 Theme. Nothing goes in src/, scenes/ or tests/ for this task.

## Read first

1. CLAUDE.md
2. docs/BRIEF.md, section 4
3. The three write-ups: docs/design/gumdrop.md, docs/design/slate.md, docs/design/nova.md
4. The token files, which are the source of every value: tools/directions/gumdrop/tokens.gd, tools/directions/slate/tokens.gd, tools/directions/nova/tokens.gd
5. tools/directions/shared/direction_tokens.gd (the token API: `color()`, `num()`, `motion_spec()`, `duration()`, `font()`, `font_size()`, `cased()`, and `text_pairs`)
6. tools/directions/shared/mock_state.gd (scores, booster ids, names and costs, hints, and `format_number()`)

docs/GDD.md is being written in parallel. Do not wait for it. Take every number and every piece of UI text from mock_state.gd so I can sync it in one place later.

## Where you may write

You may create and edit only these paths, plus the `.uid` files Godot makes next to your scripts:

- `tools/directions/ui_common/` (motion helpers and any shared code)
- `tools/directions/gumdrop/ui/`
- `tools/directions/slate/ui/`
- `tools/directions/nova/ui/`
- `docs/design/review/ui-*.png`, written only by the capture tool (see Proof)

Do not edit anything else. That includes the token files, everything in tools/directions/shared/, tools/capture.gd, tools/contrast_check.gd, the `board/` and `screens/` folders, src/, scenes/, tests/ and project.godot. If a value you need is missing, see "Missing values" below.

## Code rules

- Statically typed GDScript everywhere. Untyped declarations are compile errors in this project.
- No `class_name` under tools/. Load scripts with preload into a typed const, for example:
  ```gdscript
  const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
  const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
  const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
  ```
  Get a direction's tokens with `Directions.load_tokens("slate")`.
- Everything is drawn in code: StyleBoxFlat, Theme, `_draw()`, Tweens, and gradients built in code. No image files, no font files, no addons. Theme icons that Godot wants as textures (for example CheckButton) are out; build those controls with `_draw()` instead.
- No MSAA. The capture renders like the game, without it. Use StyleBoxFlat with `anti_aliasing = true`, and pass `antialiased = true` to `draw_line`, `draw_polyline`, `draw_arc` and `draw_circle`.
- 60 fps on a mid range Android phone: redraw only when something changes, build StyleBoxes and gradients once and reuse them, no allocation inside `_draw()` or `_process()`.
- Touch targets are at least `num("touch_min")` px on each side, even when the drawn shape is smaller.
- No em dashes and no double hyphens in comments or UI text.

## Text and color rules

- Type comes only from `tokens.font(role)`, `tokens.font_size(role)` and `tokens.cased(role, text)`. Roles: display, title, body, label.
- Every text color on its background must be one of the pairs in that direction's `text_pairs` in tokens.gd. Find the pair before you use a combination. If you need one that is not listed, do not use it; propose it in your report. The contrast check only proves the pairs that are listed.
- Text sits on flat token colors. No gradient, glow or image behind text.
- Colors come only from the palette tokens. Timings and curves come only from `tokens.motion_spec(name)`.

## What to build

### Shared: `tools/directions/ui_common/motion.gd`

Static helpers that read every duration, transition and ease from the tokens, so no caller hardcodes a timing. At least:

```gdscript
## A Tween on node with trans and ease set from the named motion.
static func tween_for(node: Node, tokens: DirectionTokens, motion_name: String) -> Tween
static func press(control: Control, tokens: DirectionTokens) -> Tween
static func release(control: Control, tokens: DirectionTokens) -> Tween
## Brings a card or sheet in the direction's way: Gumdrop springs up from from_offset,
## Slate wipes in from the top, Nova fades and settles from from_scale.
static func dialog_in(control: Control, tokens: DirectionTokens) -> Tween
static func fade(item: CanvasItem, tokens: DirectionTokens, to_alpha: float) -> Tween
## Counts a label up with score_count, formatted with MockState.format_number().
static func count_up(label: Label, tokens: DirectionTokens, from_value: int, to_value: int) -> Tween
## The target_pulse loop. Returns null when the duration is 0 (Slate).
static func pulse(item: CanvasItem, tokens: DirectionTokens) -> Tween
```

### Per direction, in `tools/directions/<id>/ui/`

| File | What it is |
|---|---|
| `theme_factory.gd` | Builds the direction's Theme |
| `icon_view.gd` | Icons drawn in code |
| `booster_button.gd` | One booster: icon and cost |
| `booster_bar.gd` | The five boosters laid out |
| `hud.gd` | Score, best and settings button |
| `toggle_switch.gd` | The sound toggle |
| `backdrop.gd` | Full screen background |
| `ui_sheet.tscn` | Static review sheet, 1080 by 2400 |
| `ui_demo.tscn` | Looping motion demo, run in a window |

## The interface I compose against

Use exactly these names and signatures in all three directions, so my screen code is the same for each.

`theme_factory.gd`:

```gdscript
static func build(tokens: DirectionTokens) -> Theme
```

The Theme sets the default font to the body role and defines these type variations, with the same names in every direction:

| Variation | Base type | Use |
|---|---|---|
| DisplayLabel | Label | the score |
| TitleLabel | Label | dialog and screen titles |
| BodyLabel | Label | row text, body copy |
| MutedLabel | Label | secondary body text in the muted ink |
| CaptionLabel | Label | small labels, label role, muted ink |
| PrimaryButton | Button | the main action, for example "Shuffle for 1,500" |
| SecondaryButton | Button | the other action, for example "End run" |
| ChipButton | Button | skin chips; toggle mode, the pressed style is "selected" |
| CardPanel | PanelContainer | dialogs and the settings sheet |
| PillPanel | PanelContainer | Gumdrop's score pills; transparent in the other directions |
| HintPanel | PanelContainer | targeting hint background: Gumdrop lemon pill, Slate vermilion bar, Nova transparent |
| Hairline | HSeparator | dividers |

Buttons need normal, hover, pressed, disabled and focus styles. Hover can match normal (this is a touch game), but it must be set. Focus is a visible outline in `accent`.

`icon_view.gd`, extends Control:

```gdscript
const LOOK_NORMAL: int = 0
const LOOK_ACTIVE: int = 1
const LOOK_DISABLED: int = 2
const ICONS: PackedStringArray = ["hammer", "swap", "shuffle", "double", "undo", "settings", "sound_on", "sound_off", "close", "check"]
func setup(tokens: DirectionTokens) -> void
func set_icon(icon_name: String) -> void
func set_look(look: int) -> void
## Overrides the color the look picks, for icons that sit on a button or chip.
func set_color(color: Color) -> void
```

Draw each icon on a 24 unit design grid scaled to `min(size.x, size.y)`, centered, so it is crisp at any size and density. Every icon must read clearly at 48 px. Default colors per look: normal `ink`, disabled `disabled_ink`, active is the text color of that direction's active booster pair. Do not draw letters or digits with a font inside icons; "x2" for Double is drawn as strokes.

`booster_button.gd`, extends Control:

```gdscript
signal pressed(booster_id: String)
func setup(tokens: DirectionTokens, booster_id: String, cost: int) -> void
func set_look(look: int) -> void  # IconView.LOOK_*
```

`booster_bar.gd`, extends Control:

```gdscript
signal booster_pressed(booster_id: String)
func setup(tokens: DirectionTokens) -> void
## active_id is "" when no booster is targeting.
func show_boosters(ids: PackedStringArray, costs: PackedInt32Array, affordable: Array[bool], active_id: String) -> void
## Targeting hint above the bar. "" hides it. Slate ignores this; its hint lives in the HUD.
func set_hint(text: String) -> void
func preferred_height() -> float
```

I place the bar full width (Gumdrop's dock keeps its `board_margin` from the screen sides inside that) with its bottom edge at `2400 - MockState.SAFE_BOTTOM`. Its height, hint included, is `preferred_height()`.

`hud.gd`, extends Control:

```gdscript
signal settings_pressed
func setup(tokens: DirectionTokens) -> void
func set_scores(score: int, best: int) -> void
## Slate's context row under the header: plain text such as "CHAIN 6", or the
## vermilion hint bar when highlight is true. "" hides it. Gumdrop and Nova ignore this.
func set_context(text: String, highlight: bool) -> void
## Slate: an empty square Control, num("preview_tile") px, at the right of the
## context row, where I put the preview tile. null in Gumdrop and Nova.
func preview_slot() -> Control
func preferred_height() -> float
```

I place the HUD full width with its top edge at `MockState.SAFE_TOP`.

`toggle_switch.gd`, extends Control:

```gdscript
signal toggled(on: bool)
func setup(tokens: DirectionTokens) -> void
func set_on(on: bool, animate: bool = false) -> void
```

`backdrop.gd`, extends Control: `func setup(tokens: DirectionTokens) -> void`. Fills its rect.

## Art direction

### Gumdrop: tactile candy

- Everything is a soft, raised object with a lip in a darker shade underneath, like the tiles. Pills and the dock in `surface` with a `surface_lip` lip; buttons in `surface_raised` with `button_radius` corners and a `button_lip` lip.
- **Icons**: chunky and friendly. Thick strokes (about 3.5 units on the 24 grid) with round caps and joins, filled shapes where it helps, like candy pictograms.
- **HUD**: settings button (a raised squircle with the gear) on the left of the top row, a "Best" PillPanel on the right with the label in `ink_soft` and the number in `ink`. Below them, centered, "Score" as a caption and the score as DisplayLabel.
- **Booster bar**: a floating dock, `dock_height` tall, `dock_radius` corners, with a lip, holding five raised booster buttons, cost inside each under the icon. Active: `accent` fill with `accent_lip`, raised a little higher, icon and cost in `ink_dark`. Disabled: `disabled_surface`, flat with no lip and sitting lower, icon and cost in `disabled_ink`. Hint: a lemon HintPanel pill above the dock, text in `ink_dark`.
- **Toggle**: a chunky pill track with a lip and a round candy knob; on is `accent`.
- **Backdrop**: flat `bg`.
- **Motion**: buttons press to `press_scale` and spring back with back ease. Cards spring up from `from_offset`.

### Slate: editorial and exact

- No boxes and no shadows. Regions are split by `rule` hairlines, `rule_width` thick. Buttons are rectangles with `button_radius` corners, `button_height` tall, full width where they appear.
- **Icons**: geometric signage pictograms. Straight segments and true circles, square caps, about 2 units stroke on the 24 grid, no fills.
- **HUD**: left aligned. "SCORE" CaptionLabel over the DisplayLabel score. On the right, the settings icon (no container, but a full touch area) and "BEST" with the number, right aligned. A Hairline under the header, then the context row: plain caps text in `ink` on `bg`, or a full width `accent` bar with `ink_dark` text when highlighted. The preview slot sits at the right of that row.
- **Booster bar**: a full width strip, `strip_height` tall, with a hairline on top and vertical hairlines between five equal columns. Each column: icon, then the booster name and cost in the label role. Active: the whole column filled with `ink` (paper), content in `ink_dark`. Disabled: content in `disabled_ink` and the cost struck through with a `rule_width` line.
- **Toggle**: a rectangular track with a square knob, hard edges.
- **Backdrop**: flat `bg`.
- **Motion**: near instant presses, no scaling bounce. Cards wipe in from the top. The pulse helper returns null.

### Nova: tiles are stars

- Floating light, almost no containers. Booster buttons are rings: `ring_button` across, `ring_width` line in `ring`. The settings sheet is a CardPanel in `surface` with `sheet_radius` top corners.
- **Icons**: thin and precise. About 1.5 units stroke on the 24 grid, round caps, with a small spark dot as an accent where it suits. The active look adds a soft glow behind the icon.
- **HUD**: centered. DisplayLabel score in the light weight, "best 48,212" as a lowercase CaptionLabel under it. Settings icon in a small ring at the top right.
- **Booster bar**: five ring buttons in a row with no container, cost under each ring. Active: the ring fills with `accent` and a soft glow of `accent` and `accent_violet` around it, icon in `ink_dark`, cost in `accent`. Disabled: ring at reduced alpha, icon and cost in `disabled_ink`. Hint: centered `ink_muted` text above the rings, no panel.
- **Toggle**: a thin ring track with a glowing knob; on is `accent`.
- **Backdrop**: a soft radial glow of `bg_glow` in the upper middle fading to `bg` at the edges and bottom, made once with a GradientTexture2D in code, plus `star_count` star dust dots from a fixed seed, 1.5 to 3.5 px, alpha up to `star_alpha_max`.
- **Motion**: slow sine curves. Buttons press to `press_scale` softly. Cards fade and settle from `from_scale`. The pulse is a slow breathing glow.

## Review scenes

Both scenes have a root Control filling the 1080 by 2400 canvas, with the direction's Backdrop behind everything, and read their data from MockState.

- **ui_sheet.tscn**, static:
  1. The HUD at the top with `SCORE` and `BEST_SCORE` (Slate: context "CHAIN 6").
  2. All ten icons in all three looks, 96 px, each on the surface it would sit on.
  3. The booster bar twice: normal, with Double disabled because it costs more than the score; and targeting, with Hammer active and the hint set to `TARGET_HINT`.
  4. PrimaryButton normal, pressed and disabled; SecondaryButton normal and pressed. Use "Shuffle for 1,500" and `GAMEOVER_END`.
  5. Three ChipButtons with `SKIN_NAMES`, this direction's own name selected.
  6. The toggle, on and off, next to `SOUND_LABEL`.
  7. One sample of each label variation.
  8. A CardPanel with a TitleLabel (`GAMEOVER_TITLE`) and a BodyLabel (`GAMEOVER_BODY`).
- **ui_demo.tscn**: runs in a window and loops: a booster press, targeting on with its pulse, cancel; a disabled booster ignoring a tap; the toggle switching; a card coming in with `dialog_in`; the score counting up from 20,450 to `SCORE`.

## Missing values

If you need a number the tokens do not have (an icon stroke width, a glow size, a knob size), make it a named const at the top of your script with the comment `# Proposed token`, and list it in your report. I move it into the token file in round 2. Do not add colors that are not palette tokens; ask in your report instead. Do not edit the token files.

## Proof

1. Contrast check still passes (you do not change tokens, this is a sanity check):
   `godot --headless --path . --script res://tools/contrast_check.gd` ends with `PASS` and exit code 0.
2. Capture the three review PNGs, each run ending in `1 of 1 written without errors` and exit code 0:
   ```bash
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/gumdrop/ui/ui_sheet.tscn --out docs/design/review/ui-gumdrop-sheet.png
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/slate/ui/ui_sheet.tscn --out docs/design/review/ui-slate-sheet.png
   godot --path . res://tools/capture.tscn -- --scene res://tools/directions/nova/ui/ui_sheet.tscn --out docs/design/review/ui-nova-sheet.png
   ```
   The capture fails on any script or engine error logged while the scene loads or renders, so a clean run is part of the proof. Look at every PNG yourself before you report and fix what does not match this brief.
3. Each demo runs for 20 seconds without an error line in the output:
   `godot --path . res://tools/directions/<id>/ui/ui_demo.tscn --quit-after 1200`

## Report

End with a short report:

1. Files created, by folder.
2. Proof: the commands above and their final lines, and the three PNG paths.
3. Every text color and background combination you used, mapped to its pair name in text_pairs.
4. Every proposed token, with file, name, value and what it does.
5. Anything in this brief that was unclear or that you could not do, and suggestions.
