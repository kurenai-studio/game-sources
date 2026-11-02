# Dataset Guide

This project is built so you can create a different game by replacing the dataset and its assets instead of rewriting the engine.

The active sample pack lives in `datasets/base/`.

Project credit line: `design&concept->motajama coding->Codex @ GPL3 2026`

## Layout

Minimum expected structure:

```txt
datasets/base/
  dataset.json
  lang/
    en.json
    cs.json
  images/
    levels/
    difficulty_faces.png        optional
    guide_head.png              optional
    title.png                   optional
    intro.png                   optional
    game_over.png               optional
    victory.png                 optional
  music/
  sfx/
```

The engine currently loads localization from:

- `datasets/base/lang/en.json`
- `datasets/base/lang/cs.json`

## Core Rules

- Keep `dataset.json` data-only.
- Put UI strings in localization JSON, not directly in `dataset.json`, whenever possible.
- Use paths relative to `datasets/base/` inside `dataset.json`.
- Missing images, fonts, and SFX are allowed; the engine should fall back safely.
- Keep sprite sheets pixel-art friendly and export them without filtering.
- Keep the project credit line visible in shipped builds unless the project identity is intentionally replaced in a fork.

## `dataset.json`

The current engine expects a structure like this:

```json
{
  "title": "DIVADELNI UTOPIE",
  "subtitle": "DATA-DRIVEN LOVE2D SLICE",
  "ui_fonts": {
    "small": { "size": 8, "hinting": "mono" },
    "medium": { "size": 12, "hinting": "mono" },
    "large": { "size": 16, "hinting": "mono" },
    "title": { "size": 24, "hinting": "mono" }
  },
  "languages": ["en", "cs"],
  "title_screen": "images/title.png",
  "intro": {
    "image": "images/intro.png",
    "duration": 3,
    "title_key": "intro_title",
    "body_key": "intro_body",
    "skip_key": "intro_skip"
  },
  "game_over": {
    "image": "images/game_over.png",
    "duration": 3,
    "title_key": "game_over_title",
    "body_key": "game_over_body",
    "hint_key": "game_over_hint"
  },
  "victory": {
    "image": "images/victory.png",
    "duration": 3,
    "title_key": "victory_title",
    "body_key": "victory_body",
    "hint_key": "continue_hint"
  },
  "music": {
    "menu": "menu_theme",
    "level_1": "level_theme_1"
  },
  "sfx": {
    "good_collect": "pickup_good",
    "bad_hit": "pickup_bad",
    "stats_tick": "stats_tick",
    "stats_done": "stats_done",
    "menu_move": "menu_move",
    "menu_confirm": "menu_confirm"
  },
  "difficulty_faces": {
    "sprite": "images/difficulty_faces.png",
    "frame_w": 64,
    "frame_h": 64
  },
  "difficulty": {
    "baby": {
      "label_key": "difficulty.baby",
      "lives": 5,
      "initial_speed": 4,
      "speed_increment": 0.10,
      "good_food_multiplier": 0.8,
      "bad_food_multiplier": 0.5,
      "face_index": 0
    },
    "normal": {
      "label_key": "difficulty.normal",
      "lives": 3,
      "initial_speed": 6,
      "speed_increment": 0.25,
      "good_food_multiplier": 1.0,
      "bad_food_multiplier": 1.0,
      "face_index": 2
    }
  },
  "foods": {
    "signal_fruit": {
      "id": "signal_fruit",
      "name_key": "food_good_name",
      "description_key": "food_good_description",
      "icon": "images/good_food.png",
      "kind": "good"
    },
    "glitch_mine": {
      "id": "glitch_mine",
      "name_key": "food_glitch_mine_name",
      "description_key": "food_glitch_mine_description",
      "icon": "images/glitch_mine.png",
      "kind": "bad"
    }
  },
  "characters": {
    "guide": {
      "name_key": "character_guide_name",
      "sprite": "images/guide_head.png",
      "frame_width": 64,
      "frame_height": 64,
      "frames": 4
    }
  },
  "levels": [
    {
      "id": "level_1",
      "name_key": "level_1_name",
      "description_key": "level_1_description",
      "story_key": "level_1_story",
      "background": "images/levels/level_1.png",
      "music": "level_theme_1",
      "good_food_type": "signal_fruit",
      "bad_food_type": "static_node",
      "theme": {
        "play_bg": "#06121a",
        "play_bg_accent": "#123349",
        "play_panel": "#0a1d29",
        "grid_border": "#17394a",
        "grid_a": "#0d2f21",
        "grid_b": "#13402b",
        "hud_bg": "#07131d",
        "hud_line": "#5ba0c8",
        "hud_text": "#eef7ff",
        "quote_bubble_bg": "#ffffff",
        "quote_bubble_text": "#0c1216",
        "stats_bg": "#120807",
        "stats_panel": "#2b0d08",
        "stats_accent": "#f0a13a",
        "stats_text": "#f6e7cf"
      },
      "grid_width": 14,
      "grid_height": 12,
      "good_count": 7,
      "bad_count": 4,
      "goal_good": 7,
      "hud_quotes": [
        "level_1_quote_1",
        "level_1_quote_2",
        "level_1_quote_3"
      ]
    }
  ]
}
```

## Top-Level Fields

- `title`: game title used by placeholder title rendering.
- `subtitle`: subtitle used by placeholder title rendering.
- `ui_fonts`: optional font definitions for `small`, `medium`, `large`, and `title`.
- `languages`: list of supported language file codes.
- `title_screen`: optional PNG path for the title image.
- `intro`, `game_over`, `victory`: non-gameplay screen configuration including optional full-screen image paths and text localization keys.
- `music`: logical music ids. The current audio layer is still placeholder-oriented, but keep ids here for forward compatibility.
- `sfx`: logical sound-effect ids. The current engine uses generated fallbacks if real files are missing.

## UI Fonts

`ui_fonts` lets the dataset define the fonts used across menus, HUD, and screens.

Supported slots:

- `small`
- `medium`
- `large`
- `title`

Each slot supports:

- `path`: optional font file relative to `datasets/base/`
- `size`: font size in pixels
- `hinting`: optional Love2D hinting mode such as `mono`

Example:

```json
"ui_fonts": {
  "small": {
    "path": "fonts/pixel-8.ttf",
    "size": 8,
    "hinting": "mono"
  },
  "title": {
    "path": "fonts/pixel-16.ttf",
    "size": 24,
    "hinting": "mono"
  }
}
```

If a font file is missing or invalid, the engine falls back to a built-in font.

## Difficulty Data

The engine expects four gameplay difficulties:

- `baby`
- `easy`
- `normal`
- `death`

Each difficulty entry should define:

- `label_key`
- `lives`
- `initial_speed`
- `speed_increment`
- `good_food_multiplier`
- `bad_food_multiplier`
- `face_index`

These values affect actual gameplay:

- starting lives
- initial snake speed
- speed gain from good food
- good food count
- bad food count

## Difficulty Faces

`difficulty_faces` defines an optional sprite sheet used on the difficulty-selection screen.

Fields:

- `sprite`: PNG path relative to `datasets/base/`
- `frame_w`
- `frame_h`

Current assumptions:

- 4 horizontal frames
- nearest-neighbor scaling
- if the file is missing, the engine draws generated placeholder faces

## Foods

`foods` is a dictionary of named food definitions. Each level chooses which entries it uses.

Each food entry currently supports:

- `id`
- `name_key`
- `description_key`
- `icon`
- `kind`: `good` or `bad`

Example:

```json
"foods": {
  "signal_fruit": {
    "id": "signal_fruit",
    "name_key": "food_good_name",
    "description_key": "food_good_description",
    "icon": "images/good_food.png",
    "kind": "good"
  },
  "glitch_mine": {
    "id": "glitch_mine",
    "name_key": "food_glitch_mine_name",
    "description_key": "food_glitch_mine_description",
    "icon": "images/glitch_mine.png",
    "kind": "bad"
  }
}
```

This allows different levels to use different food names, icons, and descriptions.

## Character / Talking Head

The gameplay HUD and story screen share the same talking-head sprite sheet.

`characters.guide` fields:

- `name_key`
- `sprite`
- `frame_width`
- `frame_height`
- `frames`

Current assumptions:

- horizontal strip animation
- default/sample pack uses 4 frames
- if the file is missing, a placeholder sprite sheet is generated

## Level Fields

Each level currently supports:

- `id`
- `name_key`
- `description_key`
- `story_key`
- `background`
- `music`
- `good_food_type`
- `bad_food_type`
- `theme`
- `grid_width`
- `grid_height`
- `good_count`
- `bad_count`
- `goal_good`
- `hud_quotes`

### Level Background

`background` is the image used behind the play grid for that level. If the file is missing, the engine generates a placeholder background.

### Level Food Selection

- `good_food_type` must reference an entry from `foods`
- `bad_food_type` must reference an entry from `foods`

That lets each level show different HUD icons, labels, and gameplay pickups.

### Level Theme

`theme` controls the colors of the play screen, HUD, quote bubble, and stats screen for that level.

Supported keys:

- `play_bg`
- `play_bg_accent`
- `play_panel`
- `play_panel_opacity` for the board panel behind the grid, only drawn when set
- `grid_border`
- `grid_border_opacity`
- `grid_a`
- `grid_b`
- `grid_opacity` or `playboard_opacity` for the board cells
- `hud_bg`
- `hud_line`
- `hud_text`
- `quote_bubble_bg`
- `quote_bubble_text`
- `stats_bg`
- `stats_panel`
- `stats_accent`
- `stats_text`

Use hex colors such as `#123349`.

### HUD Quotes

`hud_quotes` should contain localization keys for the occasional gameplay speech bubble near the talking head.

Example:

```json
"hud_quotes": [
  "level_1_quote_1",
  "level_1_quote_2",
  "level_1_quote_3"
]
```

If a level has no `hud_quotes`, the head stays visible without speaking.

### Count Fields

- `good_count` and `bad_count` are the base counts before difficulty multipliers are applied.
- `goal_good` should usually match the intended base good-food target, but the current gameplay uses the difficulty-adjusted good-food count as the actual level-clear target.

## Localization

All user-facing strings should live in `datasets/base/lang/*.json`.

Current important groups include:

- menu labels
- settings labels
- difficulty labels
- story text
- level names and descriptions
- HUD quote strings
- stats-screen labels
- food names and descriptions

Example:

```json
{
  "difficulty.baby": "Can I play, Daddy?",
  "menu.choose_difficulty": "Choose your difficulty",
  "level_1_story": "Welcome to the training circuit.",
  "level_1_quote_1": "Keep the feed clean.",
  "food_glitch_mine_name": "Glitch Mine"
}
```

## Adding a New Dataset

Suggested workflow:

1. Copy `datasets/base/` to a new dataset folder while designing content.
2. Edit `dataset.json` first:
   - title and subtitle
   - screen images and text keys
   - difficulty values
   - food definitions
   - character sprite references
   - level backgrounds
   - level themes
   - SFX ids
3. Add or update localization keys in `lang/en.json` and `lang/cs.json`.
4. Drop in assets incrementally:
   - title screen
   - intro / game over / victory images
   - talking-head sprite sheet
   - difficulty faces
   - level backgrounds
   - food icons
   - optional font files
5. For each level, point `good_food_type` and `bad_food_type` at the correct food ids.
6. Run the game with:

```sh
love .
```

7. If an asset is missing, the engine should still run with placeholders; use that to iterate incrementally.

## Safe Fallbacks

Current fallback behavior:

- missing title, intro, game-over, victory, food, talking-head, difficulty-face, and level-background images use generated placeholders
- missing fonts use built-in Love2D fonts
- missing SFX use generated tones where supported
- missing `hud_quotes` simply disables speaking quotes for that level
- missing `theme` values fall back to engine defaults
- missing food references fall back to generated good/bad icons
