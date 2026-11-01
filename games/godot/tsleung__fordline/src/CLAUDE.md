# CLAUDE.md

Fordline is a Godot 4.5 real-time tactics game (GDScript). Read
`docs/DESIGN.md` first, then `README.md`.

## Documentation

`docs/README.md` maps the docs: `docs/DESIGN.md` (the game, and what was
measured), `docs/ARCHITECTURE.md` (the engine and how it grows),
`docs/HISTORY.md` (what was built when, and why). Keep them current in the
same commit as the change they describe.

## Private paths

`notes/prompts.md` is the owner's verbatim prompt log about Fordline. On his
machine it is a gitignored symlink into his private notebook
(`~/github/terranleung.com/notes/fordline/prompts.md`), so what is written
here lands there; on any other machine it is absent. This repo is public:
the log is never committed here, and `test.sh` fails if it is tracked.

- When the path exists, append each of the owner's prompts about Fordline
  verbatim (typos and all) under a dated one-line context, the format the
  file already uses. Never create the path where it does not exist.
- Before you finish, if you appended to it, commit it in the notebook with
  `npm --prefix ~/github/terranleung.com run commit-logs`. It commits the
  logs there and nothing else.
- Nothing else from the notebook is copied into this repo unless the owner
  says so.

## Rules for editing

- **One writer.** `scripts/battle.gd` is the only code that writes battle
  state. Input and AI produce order dictionaries for `apply_orders`; views
  read fields and drain `take_events()`. Keep it that way.
- **Pure where it can be.** `combat.gd`, `campaign.gd` and `ai.gd` are
  functions over values: `campaign.gd` returns new run state and never
  mutates its argument (the tests check this).
- **Balance changes go through the headless battles.** After touching
  stats, combat, morale or the AI, run `./test.sh` and read the battle
  table it prints (winner, time, kills, resolve). A battle running past
  seven minutes fails the suite.
- **Godot binary:** `/Applications/Godot.app/Contents/MacOS/Godot`
  (4.5.1). Run `./test.sh` after every nontrivial edit; it fails on any
  script error, not only on failed checks.
- GDScript can't infer a type from a Variant (a Dictionary field, an untyped
  ternary): give such variables an explicit type.
- The design numbers in `docs/DESIGN.md` must match the code.
- Scripts and probes never launch an installed browser; use Godot's own
  window, the Claude browser pane, or Playwright's bundled Chromium.
