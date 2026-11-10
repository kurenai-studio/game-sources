# Tiny Ages — Copilot Instructions

Tiny Ages is a **2D desktop-companion game** built with **Godot 4.7** and
**GDScript** (standard build, not .NET): a tiny settlement that lives at the edge of
the screen. The Godot project is in **`game/`**; everything else in the repo is
docs, art sources and art tooling.

Read before designing anything:

- `docs/mvp-concept.md` — what the game is and, just as important, what it is **not**
  (no clicker loops, no timers, no FOMO, no LLM, no combat).
- `docs/engine-and-art.md` — engine/art decisions, style rules, open questions.

The MVP is a concept, not a spec. Do not invent systems, data models or progression
beyond what those docs say. When a request is ambiguous, ask. This file covers *how*
to write code here, not *what* to build.

## Non-negotiables

- **Godot 4 API only.** Godot 3 snippets are the most common failure mode:
  `yield` → `await`, `instance()` → `instantiate()`, `KinematicBody2D` →
  `CharacterBody2D`, `export` → `@export`, `onready` → `@onready`,
  `connect("sig", self, "_m")` → `sig.connect(_m)`, `emit_signal("sig")` →
  `sig.emit()`. `move_and_slide()` takes no arguments.
- **No C#.** No `.cs` files, no `[Export]` / `GetNode<T>()`.
- **Static typing everywhere** — `var speed: float = 0.0`,
  `func take(n: int) -> void:`. Use `:=` only when the type is unambiguous on the
  same line. Nested typed collections (`Array[Array[int]]`) are not supported.
- **Every reusable script gets a `class_name`.** Search for collisions first.
- Tabs, LF, lines ≤ 100 characters. `snake_case` files/functions/variables,
  `PascalCase` classes/nodes/enum names, `CONSTANT_CASE` constants and enum members,
  `_leading_underscore` for private members, signals in the past tense. Prefer
  `and`/`or`/`not`. `.editorconfig` enforces whitespace; Godot's official style guide
  covers the rest.

## Declaration order

```
@tool / @icon, @abstract, class_name, extends, ## doc comment
signals, enums, constants, static vars, @export vars, regular vars, @onready vars
_static_init, static methods
_init, _enter_tree, _ready, _process, _physics_process, other virtuals
remaining methods, inner classes
```

Enums come **before** constants; `@onready` comes **last** among variables.

## Engine idioms

| Don't | Do |
| --- | --- |
| `get_node("../../X")` | `@export var x: Node2D`, wired in the editor, or `%UniqueName` |
| Polling a flag in `_process` | A `signal`, connected with `.connect()` |
| Input checks in `_process` | `_input()` / `_unhandled_input()` |
| Deep inheritance | Composition — child nodes for discrete behaviours |
| Hardcoded tunables | `@export` vars or a custom `Resource` |
| `get_nodes_in_group()` every frame | Cache in `_ready()` |
| A `Timer` node for a one-off delay | `await get_tree().create_timer(0.5).timeout` |
| `queue_free()` then touching the node | Free last, or guard `is_instance_valid()` |
| `load()` in a hot path | `preload()` or `@export var scene: PackedScene` |
| A dictionary of magic numbers | A `Resource` subclass with typed `@export`s |

- **Calls go down, signals come up.** A child never reaches up the tree. Every
  scene should run standalone (F6).
- **Connect signals in code**, not in the editor. Disconnect capturing lambdas
  explicitly.
- `await` is a coroutine, not a thread; guard with `is_instance_valid(self)` after a
  long await.
- Use `is` / `is not` / `assert()` for type checks; `as` silently yields `null`.

## Architecture rules specific to Tiny Ages

- **Simulation is separate from rendering.** The settlement sim (characters, needs,
  events, time) must run without drawing and be testable headless. Prefer
  `RefCounted` for sim objects; nodes only render and forward input.
- **Offline catch-up is timestamp-based.** Store a last-seen time; on launch advance
  the sim in coarse steps and summarise as journal entries, never resource dumps.
- **The game must be cheap when ignored.** No per-frame work that is not visible.
  Frame-rate caps and render pausing are decided in the window spike — do not
  hard-code them elsewhere.
- **Nothing is demanded of the player.** No timers that expire, no penalties for
  being away, no sound/flash notifications by default.
- **Data belongs in Resources** (events, buildings, traits, journal entries), not
  JSON loaders or dictionaries. Resources are shared by default — `.duplicate()` or
  *Local to Scene* when you need a per-instance copy.
- **No game autoloads without justification.** The only entry today is
  `_mcp_game_helper`, owned by the committed Godot AI plugin
  (`game/addons/godot_ai/`); leave it alone. No global event bus.

## Fail loudly

```gdscript
if not ResourceLoader.exists(path):
	push_error("Missing resource: %s" % path)
	return null
```

`push_error` for faults, `push_warning` for recoverable problems. Prefer guard
clauses. No `print()` in committed code.

## Godot 4.7 specifics

Docs: <https://docs.godotengine.org/en/4.7/>.

- Mouse/keyboard device IDs are `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`,
  not `0`. Dispatch on event type.
- An override of a method with a typed return inherits that return type and needs an
  explicit `return`.
- `CanvasItem` line drawing no longer adds an antialiasing feather.
- Third-party content comes from the **Asset Store**; the Asset Library is gone.

## Project layout

```
docs/                 design notes and decisions
art/reference/        generated reference PNGs (1x) + previews
tools/art/            LibreSprite art-generation scripts (see its README)
game/                 the Godot project (open game/project.godot)
  scenes/             .tscn, mirroring scripts/   (ui/ for menus, HUD, overlays)
  scripts/sim/        the settlement simulation: headless, no nodes (see below)
  scripts/game/       `Game`: owns the sim, real-time clock, save/autosave, dev flags
  scripts/view/       the on-screen world: `WorldView`, villager actors, planner (see below)
  scripts/ui/         the panels and strip icons: presenters (pure, tested), `PanelHost`, `StripIcons`
  scripts/window/     desktop-window handling;  scripts/dev/  dev/spike scenes
  assets/             art/audio/fonts the game loads — only what is in use
  resources/sim/      authored sim content (.tres): config, events, buildings, plants
  tests/              test suites (test_*.gd) and shared fixtures
  tools/              one-off Godot CLI/editor scripts, not shipped code
  addons/godot_ai/    committed Godot AI (MCP) editor plugin — do not edit
```

### The simulation (`game/scripts/sim/`)

Plain `RefCounted` rules over plain `Resource` state, so it runs headless and is
reproducible from a seed. Never put node or scene-tree code in it; the view reads
`WorldState` and calls `Simulation`'s public methods and signals.

- `state/` — `WorldState` and the things it holds. Everything saved is an `@export` field.
- `data/` — authored definitions: `SimConfig` (all tunables, incl. the 20 min/day pace),
  `ContentLibrary`, `EraDef`, `EventDef`, `ChoiceDef`, `SimCondition`, `SimEffect`,
  `BuildingDef`, `PlantDef`. Content is data, never code: add new behaviour as a `Kind` on
  a condition or effect. **Append enum members at the end** — saved `.tres` files store the
  integer. Ages are linear and gated by hidden milestones plus a minimum time (`EraDef`,
  `ADVANCE_ERA`, forward only); gate content with `ERA_AT_LEAST`, and pace an age's own
  milestones with `ERA_DAYS_AT_LEAST` (days since it began; `SETTLED_DAY`). The game is
  open-ended: the newest age has no gate out, and a later age is added as data (see
  `docs/ages.md`, G6–G7).
- `systems/` — `VillagerSystem`, `ConstructionSystem`, `PlantSystem`, `EventSystem`,
  `EraSystem`, `EffectRunner`, driven by `Simulation._step()`. All randomness uses
  `Simulation.rng`. `EraSystem` opens the next age when its hidden gate is met (required
  achievements and a minimum time, on `EraDef`); the gate is never shown to the player.
  New worlds start without fire (`fire_found`); tests that are about something later use
  `SimFixture.new_sim()`, which starts lit (pass `lit = false` for the fire story).
- Time is ticks (`ticks_per_day`, default 24). `advance_ticks` is exact; offline catch-up
  is `advance_real_time(now)` and must equal ticking the same amount.
- **Seasons and weather** (P14 in `docs/gameplay.md`): the calendar is `SimConfig`
  (`season_at(tick)`, 20 days a season); weather is `WorldState.weather` with `WeatherDef`s
  (`SET_WEATHER`, `WeatherSystem`), and it scales what villagers and buildings bring in. Weather
  can break a building (`BuildingDef.tags`, `DAMAGE_BUILDING`, `BuildingState.damaged`; half output,
  mended by hand after `self_repair_days`). Content is `_weather_events` in the builder: a fork is
  damage plus `_mend_now` (wood) and `_mend_later`, never a pass. A story decision that names a
  season gets `_season(Season.X)`; `SEASON_IS`, `WEATHER_IS` and `HAS_BUILDING_TAG` are *passing*
  conditions for `is_decision_stale`, so a decision asked in its season is not withdrawn. Tests that
  jump the clock must land in the right season.
- **The tide** (issue #9): `SimConfig.tide_at(tick)` is a pure function of the tick (period
  `tide_period_ticks`, 12.4, so low tide drifts through the day), `is_low_tide` and
  `SimCondition.Kind.TIDE_LOW` use it, and it is a *passing* condition for `is_decision_stale`.
  Nothing is saved. Forks that are asked at low tide are authored once per answer to "The hard
  crossing" (`low_tide_stones`, `low_tide_log`, `fish_on_the_turn_*`) because there is no OR
  condition and old saves already hold one of the two flags.
- Design rules baked in: decisions wait indefinitely and never penalise waiting; nothing
  fails or kills; open-ended with chapter milestones, no ending.
- Content seeds come from `tools/build_sim_content.gd` (a bootstrap — after running it,
  edit the `.tres` in the inspector; re-running overwrites them). `ContentLibrary.validate()`
  must stay empty; a test enforces it. Pacing numbers live in its tables: `UNLOCK_DAY`
  (milestones), `STORY_DAY` (the small story decisions between them), `AMBIENT_CHANCE`,
  `GATHER_RATE`; `SimConfig.comfortable_stock` stops villagers and buildings piling up stock.
  The Settled Age has the same tables in days *into the age*: `SETTLED_DAY` (milestones),
  `SETTLED_STORY_DAY`, `SETTLED_AMBIENT_CHANCE`, with `_settled_story`, `_settled_ambient` and
  friends, and the Bronze Age the same with `BRONZE_DAY`, `BRONZE_STORY_DAY`,
  `BRONZE_AMBIENT_CHANCE`, `_bronze_road` (a decision that earns a milestone), `_route`,
  `_bronze_story` and `_bronze_ambient`, the Iron Age with `IRON_DAY`, `IRON_STORY_DAY`,
  `IRON_AMBIENT_CHANCE`, `_iron_road`, `_iron_route`, `_iron_story` and `_iron_ambient`, and the Classical
  Age with `CLASSICAL_DAY`, `CLASSICAL_STORY_DAY`, `CLASSICAL_AMBIENT_CHANCE`, `_classical_road`,
  `_classical_route`, `_classical_story` and `_classical_ambient`. A
  milestone gets more than one road and one road open to
  every group; the Settled Age's gate out is its six milestones plus 8640 ticks and *The metal's
  road* (`path_smithing` / `path_trading`) opens the Bronze Age, and the Bronze Age's gate out is
  its six plus 8640 ticks and *A harder fire* (`path_bloomery` / `path_ore`) opens the Iron Age.
  The Iron Age's last forks (*A stone with a name*, *A rider with a sash*, *A
  table for strangers*) lead into the Classical Age: its six plus 8640 ticks and *A seat at the table*
  (`path_assembly` / `path_league`) open it. The Classical Age has no gate out (a Medieval Age is only a
  direction, `docs/ages.md`) and adds no building. **Each age has a profile on its `EraDef`** (`max_villagers`,
  `food_need_scale`, `food_yield_scale`, `wood_yield_scale`; `PROFILES` in the builder): a villager stands for the
  settlement's people, not a head count, so the ceiling only gates arrivals (`WorldState.room()`) and nobody is
  ever removed; a later age's villager eats and brings in more. `VillagerSystem.PROFESSION_BIAS`
  lets a Forager, Smith or Trader tilt (never assign) a villager's day. A story decision is `_story`/`_story_about` plus `_answer` choices (two answers, both
  harmless, a journal line each, a flag for later lines); a quiet moment is `_ambient`,
  `_ambient_about` (a trait) or `_remembered` (a flag). Costs are a `_has` requirement plus
  a `_spend` effect, so the panel shows "needs 8 wood". A decision is a fork (P13 in
  `docs/gameplay.md`): it is only asked while two answers are open (`EventDef.min_choices`) and
  has no pass answer; every authored decision follows it, and `test_decision_rules.gd` enforces it.
- `tools/sim_timeline.gd` plays a bot through the sim and prints the journal with real-time
  offsets, every question asked, the longest wait between them and the stock: use it to
  judge pacing instead of guessing (`-- <seed> <days>`).

### The world view (`game/scripts/view/`)

The view only reads `WorldState`, with one exception: `LanePlacer` records where it put each piece
(`WorldState.lane_spaces`, `lane_order`), which the sim never reads. The sim never knows the view
exists. `Game` calls `WorldView.on_world_changed()` after the sim advances.

- **Buildings and props stand in reserved spaces on their lane** (issue #50, `docs/ages.md` V14).
  `LaneSpaces` cuts both lanes into 28 px spaces 4 px apart, the prop lane offset by half a pitch so props
  stand between buildings (terrain by zone, which are across the river; the same spaces in every
  age); `LanePieces.TABLE` says each piece's lane,
  how many spaces it takes, what it may stand on and its rank (1 headline, 2 need, 3 answer, 4
  flavour, 5 decor: the bushes and rocks are pieces too, hidden first); `LanePlacer` puts what the
  world shows in the free run nearest the hall, keeps it
  there, and when a lane is full hides the lowest rank (never 1 or 2). Props on the ground and shore
  all stand on one row, `WorldLayout.PROP_FOOT`, above the lane people walk. **A new building or prop
  needs a `LanePieces.TABLE` entry** (or a place in `LanePieces.BACKDROP` if it is continuous
  scenery) and art that fits its spaces: `test_lane_spaces.gd` checks both, and that every age has
  room for ranks 1 and 2. Do not write an x for a piece: `WorldView` slides its sprite so the art
  sits in the middle of its spaces, and hover, the click region, sites and villagers' spots
  (`LaneLayout`, passed to `VillagerPlanner.plan`) all read the same layout.
- Every art piece (`game/assets/world/<age>/*.png`) is a full 384×80 transparent sprite.
  Most are drawn already at their final position (`BUILDINGS[id]["at"]` and `SceneProps` `at_x` are
  where they were drawn, and what a backdrop piece keeps); the rest
  are *lifted* onto their lane (`BUILDINGS[id]["at"]`, `SceneProps` `at_y`, a plain sprite offset).
  Draw order is z = the foot row (see `WorldLayout`). **Three lanes**: buildings stand on the back lane
  (`WorldLayout.BACK_LANE`, foot row 67, the cave's base), small props on the mid lane (feet 72-76),
  and people walk the front lane (75-79); never put a building on the bottom row, and keep tall
  scenery (pines) behind the village on the back rows (`tools/art/cave_pages.js`). `WorldLayout`
  mirrors the slots in `tools/art/cave_strip.js`: change both together.
- **Ages accumulate; slots are upgraded in place** (`docs/ages.md` V10). Art lives in one folder
  per age (`WorldLayout.ERA_DIRS`); a building, site or prop uses the newest art the current age
  has (`WorldLayout.piece_path`), and `WorldView` retextures when the age turns. A new age draws
  only what changes, with a `tools/art/<age>_*.js` script, and everything else stays. Pieces
  that show because of a flag, achievement or building (not a building of that name) are
  `SceneProps` (pure, tested); add one there and in the art script. **Every prop belongs to a
  `place` (`WorldLayout.PLACES`) and its art must sit inside it**; an age can fold props into a
  tidier piece (`replaced_by`), retire them (`until_era`) or hold one back (`from_era`), and
  `test_scene_props.gd` checks containment, overlaps and a per-page budget in every age (docs/ages.md
  B10). Villagers wear one outfit per age and milestone (`VillagerOutfit`: fur, field clothes,
  woven tunic, town clothes, bronze fittings, checked wool, iron fittings, linen, civic mantle; `WorldLayout.villager_sheet_path(look, outfit)`), and a profession adds an overlay over the body (`WorldLayout.role_sheet_path`, `VillagerActor.set_role`; `tools/art/role_overlays.js`).
- **The world is wider than the viewport** (decision A8). Everything lives in "camp pixels":
  the camp page is x 0..384, the world runs from `WorldLayout.WORLD_LEFT` (−384) to
  `WORLD_RIGHT` (768), and the viewport shows one 384 px page. `WorldView` keeps a scrolling
  container inside a clipping `Control`; `ScrollCamera` (pure, tested) clamps, glides and
  rounds to whole pixels; `ScrollUi` and `PanArrow` are the edge arrows and page dots. The
  side pages have their own art (`west_*`, `east_*`, from `tools/art/cave_pages.js`; see
  `WorldLayout.SIDE_PAGES`). The camp's river blocks the whole ground at its east edge, so
  the east is water and villagers wander west only until the group lays a crossing
  (`stepping_stones` or `log_bridge`: `WorldLayout.crossing_open`); then they may walk to the
  spit. Arrivals always come from the west.
- **River life on the east page** (issue #9, `docs/ages.md` V13): the crossing and the river's
  props are `SceneProps` (the crossing is two pieces, camp and east, `tools/art/cave_river.js`;
  clay pits, flax, the flood bank, boats and the weir are in `settled_camp.js`). Foragers *look*
  like they fish, cut reeds and gather shellfish (`VillagerPlanner._plan_forage`: view-only, the
  sim only knows `forage`). `RiverLife` (deer by the hour) and `TideLook` (how bare the flats
  are) are pure and tested; fish and birds are `east_life_*` frames swapped on a slow clock that
  sleeps off-screen (the fish also rise on the camp page's half of the river: the first 66 columns of each frame laid at x 318, a frame ahead, under the crossing, `WorldLayout.LIFE_WEST_X`), the flats an overlay in three steps (`TideLook.flats_step`) whose foam frames swap with the sea.
- **One signature building per age, not a cave that keeps up** (`docs/ages.md`, "Classical Age"): the camp's landmark (the cave's footprint, 100x54, foot row 66, entrance near x 34) is replaced whole at each turn: a cave, a longhouse, a gatehouse, a hill-fort hall, a civic hall. It is drawn into each age's own `static_back` and `fire_pit_*` pieces (`tools/art/signature_landmarks.js`; `WorldView` retextures static layers and the fire frames when the age turns), shown only because the age turned, and named for its age on hover (`WorldLandmarks.SIGNATURE_NAMES`). The Cave Age's pennant (`cave_standard_cave`, `until_era` 1) is the only dressing left. A new age redraws the landmark in the same footprint with its own fire pit (no firelight inside the cave's mouth); a test checks the footprint, the doorway and the pine beside it (the mammoth is the Cave Age's alone). **Keep it clear of the Bloomery's flank (x 73 and up)** and fold a building into another with `WorldLayout.BUILDING_FOLDED_INTO` rather than letting two stand on one ground.
- **Clickable region across the scroll**: `WorldView` builds a world-wide `Skyline` and the
  `DesktopWindow` reads the slice in view (`set_skyline`, `set_scroll`); the arrows and HUD
  are `set_extra_regions` so they stay clickable. Anything drawn must be inside that polygon
  on Windows (it clips drawing).
- **Hover tooltips** (issue #22): resting the pointer ~0.35 s (`HoverDwell`) on something names it,
  name only, never on its own. `WorldView.thing_at` picks the front-most named thing by z (a villager
  wins a tie): visible props (`SceneProps.PROPS[...]["name"]`: a new prop must have one, a test
  enforces it), buildings and sites (`BuildingDef.display_name`), the fire, the flower, the deer,
  villagers (`VillagerPresenter.tooltip_for`), and `WorldLandmarks` for what is baked into a
  shared layer (cave, pine, mammoth, fish, egrets: rectangles that mirror the art scripts). A pixel
  test (`AlphaHit`) keeps the empty part of a full-width piece from counting. `WorldTooltip` is drawn
  in the HUD layer, and while it is up `Game` adds its `region()` to the click region (so it shows in
  strip and corner mode). Side-page scenery stays unnamed. Look at it with `--hover=x,y`.
- `VillagerPlanner` (pure logic, tested) turns a villager's activity into a spot and pose;
  `VillagerActor` walks and animates; away or sleeping villagers are hidden. A plan's
  `focus_x` is where to face on arrival and can be negative (the world runs west of the camp):
  test `has_focus()`, never `>= 0`.
- `DayNight.tint(hour)` drives a `CanvasModulate` (darker nights while `WorldState.has_fire()` is false).
  The fire pit (`fire_pit_0..3`, flame frames, with the firelight in the cave mouth) is state-driven like a
  building and only shows once the fire is found; it flickers on a 0.2 s clock that sleeps unless the fire is lit
  and in view. `fire_glow.png` is an additive glow that fades in with the dark while there is
  fire. Before fire the group gathers in the cave mouth. Wood is cut at the west forest. Sky only shows in the opaque
  window (decision A7); strip and corner mode keep the far mountains, near hills, trees and ground. The sun, moon and
  stars (`celestial.png`, `stars.png`) are children of the clip, not of the scrolling world, so they stay
  put as you pan; `DayNight` says where they are, and they too exist only in the opaque window.
- Seasons and weather in the view: `SeasonLook` and `WeatherLook` are pure and tested; a shader
  (`assets/world/season_palette.gdshader`) shifts the green of the existing art per season and
  `SeasonOverlay` draws snow, blossom and leaves from the backdrop's own edges (rebuilt only when the
  season turns). **Only what falls is drawn: rain, snow, and rain for a storm and a flood** (`WeatherLayer`, `assets/world/weather.png`,
  `tools/art/weather.js`): in strip and corner mode the whole viewport joins the click region while
  they fall (`WorldView.covers_sky`), because Windows only draws inside it. A drought and a tornado are
  events, journal lines and decisions with no visuals. Look at it with `--season=` and `--weather=`.
- Art regenerates with `python tools/art/bundle.py --run cave_strip cave_pages cave_river cave_villagers cave_celestial cave_stars settled_camp settled_villagers bronze_camp bronze_villagers iron_camp iron_villagers classical_camp signature_landmarks classical_villagers weather ui_seasons ui_skin_bronze ui_skin_iron ui_skin_classical ui_achievements`,
  then `--import` and commit the `.import` files.
- Dev flags for `scenes/main.tscn` are listed in `scripts/game/game.gd` (`--new`, `--nosave`,
  `--days=N`, `--manual`, `--bot`, `--speed=`, `--cam=`, `--panel=`, `--shot=`, `--era=`,
  `--build=hut,field`, `--flag=`, `--earn=`, `--role=smith,trader`, `--season=`, `--weather=`, `--tide=low|high`, `--damaged`, `--hover=x,y`). **`--dev`** turns on the text overlay and the dev
  keys (mode, scale, speed, bot...); `--hud` is the overlay alone. Without them the screen has
  only the player's UI (docs/gameplay.md P12). Always use
  `--nosave` (or `--save=`) in automated runs so the player's save and window settings are not
  touched or read. To check
  GUI input without touching the real mouse, push events with
  `get_viewport().push_input(event, true)` (local coordinates) from a temporary script (and
  remove it afterwards); the headless test runner has no running tree for it.

### The panels (`game/scripts/ui/`)

What the player is shown is built by pure presenters, so it is tested without nodes:
`DecisionPresenter` (title, text and choices; a choice is *listed* if only stock stops it,
*enabled* if nothing does; staged unlocks are never listed), `JournalPresenter`, `AwaySummary`,
`VillagerPresenter` (a clicked villager's name, traits, role and a thought that follows what they
are doing, whether there is fire, and whether food is low; a pure function of the world, so it
holds still between ticks).
`PanelHost` draws them above the strip and only reports the choice picked; `Game` applies it
with `Simulation.resolve_decision`. While a panel is open `DesktopWindow.set_panel_height`
grows the window upward by the panel's current height (`PanelHost.current_height()`; a
villager's panel is shorter, see `PanelHost.HEIGHTS`) and the click region takes in the panel. `StripIcons` is the bulb, the
journal book and a quiet season glyph (picking it opens Stores), the only things always on screen. A right click on the strip
(`WorldView.menu_requested`) opens the menu panel (journal, stores, settings, quit);
`MenuPresenter` builds the stores and settings rows as data, `PanelHost` reports `action_picked`,
and `Game._on_action` applies it. Window settings live in `UserSettings` (`user://settings.cfg`,
separate from the save; launch flags override them). The sim withdraws a decision the world has moved past
(`Simulation.withdraw_stale_decisions`), so the UI never asks a stale question.

**Skins, one per age** (`PanelSkin`, `UiTheme`): a skin is the age's material, colours, font and
where each piece sits in its atlas (`tools/art/ui_skin_<hide|clay>.js`). To add an age: draw the
atlas (same layout as the existing ones), add a factory to `PanelSkin.skins()`; `Game` swaps the
skin on `era_advanced`, and an age without one uses the Cave skin (Cave: hide; Settled: timber
and clay; Bronze: mud-brick and hammered bronze; Iron: a dark iron frame round limewash; Classical: limestone and fluted columns round plaster). The panel's art height is `PanelSkin.PANEL_HEIGHT` and must match the
atlas. The font (`assets/fonts/PixelifySans.ttf`, OFL, licence beside it) is set with no
antialiasing; sizes should stay at 12 (titles use the bold weight). Dev flags for looking at
panels: `--panel=decision|journal|away|villager|menu|stores|settings`, `--manual`, `--fire`,
`--era=settled`,
`--flag=path_hunting`, `--give=wood:6`, `--hour=12`.

Keep a script and its scene at mirrored paths. Every PNG in `game/assets/` is
imported as a texture whether or not it is used — do not add art until it is in use.
`game/assets/preview/strip_v2.png` is a scaffold smoke test and is meant to be
replaced.

Settings that shape the code: base resolution **384×80** shown at 768×160 (2×) with
`canvas_items` stretch and **integer** scale mode, **Nearest** default texture
filter, **`gl_compatibility`** renderer. Art style rules (outline, palette, scale)
are in `docs/engine-and-art.md`; pixel art must stay integer-scaled.

## Files you must not hand-edit

- **`.uid` files** — Godot generates them; commit them; move them with their script.
- **`.import` sidecars** — generated; after adding art/audio/fonts run
  `--headless --path game --import` and commit what it writes.
- **`game/addons/godot_ai/`** and the `[autoload]` / `[editor_plugins]` entries in
  `game/project.godot` that it owns. The plugin updates itself; do not patch it.
- **The `[input]` section of `project.godot`** — write a `tools/setup_input.gd`
  script and let the engine serialise events.
- **Anything under `game/.godot/`** — generated and ignored.
- **`art/reference/*.png`** — generated by `tools/art/`; change the scripts instead.

## Writing `.tscn` / `.tres` by hand

Prefer building scenes in the editor (or via the Godot AI MCP tools). When hand-
authoring is unavoidable:

- Put `script = ExtResource(...)` **before** the exported properties it sets.
- `ExtResource`/`SubResource` ids must be unique and match references exactly.
- Omit `load_steps` and `uid`; never invent a `uid`. Write `format=3`.
- The first `[node]` is the root and takes no `parent=`.

## Commands

Resolve the engine from `$env:GODOT` or `godot_console`/`godot`/`godot4` on `PATH`.
Use a `_console` build — the plain Windows `.exe` prints nothing.

```powershell
pwsh -File game/tools/check.ps1                                  # validate
pwsh -File game/tools/run_game.ps1 [--nosave --days=12 --bot]    # run the game standalone
pwsh -File game/tools/run_spike.ps1 [--mode=...]                 # run the old window spike
pwsh -File game/tools/build_release.ps1                          # try a release build locally; publishing is a tag, see the `release` skill
& $env:GODOT --headless --path game --import                     # import new assets
& $env:GODOT --headless --path game --script res://tools/x.gd    # run a tool script
python tools/art/bundle.py --run                                 # regenerate reference art
```

Window behaviour (borderless, transparent, always-on-top, click-through) does **not** work
when the editor embeds the running game in its Game tab, so test it with
`run_game.ps1` or `run_spike.ps1` (or untick "Embed Game on Next Play"). `scenes/main.tscn` is the main scene;
the old spike is `scenes/dev/window_spike.tscn`. Both take a `--shot=<png>` launch arg that
saves the rendered viewport, alpha included, for automated visual checks.
On Windows, `DisplayServer.window_set_mouse_passthrough()` also clips drawing — anything
that must be visible has to be inside the passthrough polygon.

## Pull requests and releases

Land work with the `pull-request` skill (`.github/skills/pull-request/`): branch, check, commit as the
GitHub noreply address, PR, squash merge. **Every time you open or merge a PR, tell the user in one line
whether a release is due**, from `pwsh -File game/tools/release_check.ps1`. Never tag or publish unless
asked; the `release` skill has the steps.

## Before you claim something works

Run `pwsh -File game/tools/check.ps1`. It parses every `.gd` file with
`--check-only`, boots the project, then runs every suite in `game/tests/` headlessly
(`tools/run_tests.gd`; suites extend `McpTestSuite`; run one with `-- <suite name>`; set
`SH_SLOW_TESTS=1` to list the slowest tests). The whole check takes about 4 minutes, mostly the
tests that play a full age with a bot, so keep new ones short (few seeds, only as many days as needed).
The editor's `test_run` MCP tool cannot run them. **Do not** substitute
`--headless --path . --quit`: it only parses scripts reachable from the main scene
and exits 0 even when it prints a parse error.

New simulation behaviour needs a test, and a bug fix needs a test that fails without it.
Tests must be deterministic: seed the sim, and assert outcomes, not exact random rolls.

A clean check proves only that code parses and loads. It says nothing about behaviour
or feel — never claim a timing, window or visual change is right; describe what to
look for and let the human check it. Window behaviour (transparency, click-through,
always-on-top, multi-monitor/DPI) can only be verified on a real desktop.

## Things to avoid

- Inventing game systems or adding anything the MVP concept excludes.
- Adding addons or plugins unasked.
- `class_name` collisions — search before naming.
- Hardcoding absolute machine paths in committed files.
- Bundling a large refactor with a feature.
- Generating `.md` documentation unless asked.
