extends RefCounted
## The two font metrics components use to place text by its letters rather
## than its line box (DESIGN_SYSTEM.md 3.4). They are facts about the fonts,
## not tokens, held once here. tests/design/test_font_metrics.gd measures them
## from every skin's real display, body and label fonts.

## Cap height as a share of the font size. Measured 0.688 to 0.712.
const CAP_HEIGHT: float = 0.70
## How far a comma reaches below the baseline, as a share of the font size.
## An upper bound: measured 0.125 (Segoe UI) to 0.172 (Outfit 900).
const COMMA_DEPTH: float = 0.18
