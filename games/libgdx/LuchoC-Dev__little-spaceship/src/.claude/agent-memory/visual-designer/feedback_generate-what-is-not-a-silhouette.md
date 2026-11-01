---
name: generate-what-is-not-a-silhouette
description: Hand-draw only the shapes the player reads; generate the rest from a committed script, and always Read the rendered PNG before believing a grid
metadata:
  type: feedback
---

Hand-draw a grid only when its **silhouette** is what the player reads. Everything else — a 47x87
boss part, 29 explosion frames, a widget atlas, a font sheet — comes from a small committed
generator that emits the rows or the PNG.

**Why:** a hand-typed 47x87 grid is 4089 characters and roughly half its errors go unnoticed; the
21/08/2026 session got a 23-wide row wrong twice in a row. None of those pixels is a shape anyone
looks at for more than 16 ms. The generators in this repo — `mockups/generate-boss.py`,
`fx/build-explosions.py`, `skin/build-skin.py`, `fonts/build-fonts.py` — each took less time than
the grid would have and can be re-run after a palette change.

**How to apply:** decide per sprite. Enemies, the player, pickups and icons are drawn by hand.
Boss parts, effects, fonts and widgets are generated. Whichever way it was made, the loop does not
end until the PNG has been **Read**: `render.py` for the sprite table, and every generator writes a
`specimen.png` (gitignored) for the same reason. `check.js` proves a sprite is legal, not that it is
any good, and "it validates" has already been mistaken for "it works" once here — the tank passed
every check while reading like a mascot.

Two tool notes that cost time:

- The `Bash` tool is Git Bash but Python is Windows Python, so a `> /tmp/x` redirect writes
  `C:\tmp\x` and the next `open('/tmp/x')` fails. Use paths relative to the working directory.
- Heredocs containing both quote characters have failed to parse in this harness; when a script has
  awkward quoting, write it with the `Write` tool instead of a heredoc.

Related: [[art-production-needs-a-shell]], [[silhouette-primitives-are-spent]]
