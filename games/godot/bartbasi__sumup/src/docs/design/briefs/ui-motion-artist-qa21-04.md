# Brief: the clear notice plural in Slate (ui-motion-artist, QA21-04)

From: senior-graphic-designer, 2026-10-21. Launched by the DM.

## The problem

Slate cases the clear notice in capitals, and today the plural "s" after a value is cased with the words: "NO MORE 8QS", "NO MORE 2KS", "NO MORE 32QS TO 128QS". The "S" sits against the capital suffix, so "8QS" reads as one label with a two letter suffix. GDD 14.1 keeps every named suffix to exactly one capital so a label can never be misread.

## The decision

The plural "s" belongs to the value, not to the words, so it is never cased, in any skin. Only the words take the skin's case rule. Slate now reads:

- "NO MORE 2s", "NO MORE 2s OR 4s", "NO MORE 2s TO 8s", "NO MORE 2s TO 32s"
- "NO MORE 2Ks", "NO MORE 1024s OR 2Ks"
- "NO MORE 64Qs", "NO MORE 512Qs OR 1aa", "NO MORE 32Qs TO 128Qs"
- unchanged: "NO MORE 64aa", "NO MORE 128aa TO 512aa" (no plural after a lowercase suffix, 7.10)

Gumdrop (as written) and Nova (lowercase) read exactly as today, since their "s" is already lowercase. The stars earned part is unchanged ("NO MORE 2s  +1" and the star).

## Read first

- CLAUDE.md.
- docs/DESIGN_SYSTEM.md 7.10 (the Clear notice row), 14.1 ("Casing"), and 5.7 (Slate's clear notice).
- docs/reviews/qa-2026-10-21.md, QA21-04.

## Files you may touch

- src/design/shared/ui_copy.gd
- tests/design/test_hud.gd, tests/design/test_unlimited_numbers.gd, and a new test in tests/design/ if you prefer one.

Nothing else. No skin, no Theme, no layout change: a lowercase "s" is narrower than "S", so no Slate notice gets wider.

## What to build

In `UiCopy._fill`, when `plurals` is true and a placeholder is followed by the plural "s" (the template's own "s" right after "{a}" or "{b}"):
- if the label ends in a lowercase letter, drop the "s" (as today);
- else append a literal lowercase "s" right after the value, outside the cased part, and case only the rest of the template.

The words around it keep the skin's rule. Do not touch `skin.cased`, the templates, or any other copy: `stars_earned`, `free_held`, `free_cost`, `stars_caption` and `booster_name` stay as they are. Update the doc comments on `clear_notice` and `_fill` to say the plural "s" is never cased (DESIGN_SYSTEM.md 7.10, QA21-04).

## Tests

- tests/design/test_hud.gd `test_clear_notice_copy_matches_the_design`: the Slate row becomes `["NO MORE 2s", "NO MORE 2s OR 4s", "NO MORE 2s TO 8s", "NO MORE 2s TO 32s", "NO MORE 2Ks", "NO MORE 1024s OR 2Ks"]`. Gumdrop and Nova rows unchanged.
- tests/design/test_unlimited_numbers.gd `test_clear_notice_plural_after_suffix_letters`: the Slate row becomes `["NO MORE 64Qs", "NO MORE 64aa", "NO MORE 128aa TO 512aa", "NO MORE 512Qs OR 1aa", "NO MORE 32Qs TO 128Qs"]`. Gumdrop and Nova rows unchanged.
- One new check (in either file): for every skin and every exponent from 1 to 200, the notice for that single value contains the tile label exactly as `NumberFormat.tile_label` gives it, followed either by nothing (label ends in a lowercase letter) or by exactly one lowercase "s"; and in Slate no notice contains a capital letter directly followed by "S" after a digit (no "KS", "MS", "BS", "TS", "QS" pair after a value).

## Proof

- `godot --headless --path . --import`, then `godot --headless --path . --script res://tests/run_tests.gd` exits 0.
- The changed and new test names in your report.
- No screenshot needed; I check it in the next build review.
