# Fixes: ui-motion-artist, the additions review

From the senior-graphic-designer. Verdict: **pass, with one fix.** The star counters, the star moment, Free on the bar, the new icons and the reading screen theme match DESIGN_SYSTEM.md and the mockups in all three skins. The whole review, page by page, is docs/design/briefs/additions-review.md.

Work in `C:\bart\sumup-work` (branch `additions`), never in `C:\bart\numbergame`.

Write paths, unchanged: src/design/, scenes/design/, tests/design/, and docs/design/review/prod-ui-*.png.

## Read first

DESIGN_SYSTEM.md 3.6 (the new bullet "The flying star has an edge"), 4.7 and 6.7 (Star earned effect), 7.5 (the star moment while the offer is open).

## Your questions

- **The stars and flight pages:** accepted. The play page had no room, and a page per subject is easier to review.
- **Nova's spark invisible on the accent pill, and the rising star over its notice:** right on both counts. Gumdrop has the same problem: lemon on lemon for about the first 45% of its flight. Fix 1 below solves all three. The path and the rise distance stay as they are; rising further would put the star over the offer's buttons.
- **Gumdrop's arrow head** (all three corners rounded by 1, the shaft's cap inside the head) and **Nova's chevron and arrow fitted to icon_fit:** approved as built, now written into 4.7 and 6.7.

## Fix 1: an edge under the flying star (Gumdrop, Nova)

Spec: DESIGN_SYSTEM.md 3.6, 4.7, 6.7 and 7.5.

1. The flying star of the star moment, and the star that rises while the offer is open, draw on top of an **edge**:
   - its shape: the star's outline grown outward by the edge width, filled;
   - its color: badge_ink;
   - its width: Gumdrop `target_edge_width` (4 px at full size), Nova `hairline` (2 px).
2. The edge sits under the star. In Nova it sits between the star and its glow, so the glow still blooms around both.
3. It scales and fades with the star: at `from_scale`, Gumdrop's edge is 0.4 of 4 px.
4. Build the grown outline once per size, like the counter's band, never in `_draw()`. StarShape.inset with a negative width gives a mitered grown outline. Use another way if it looks cleaner at Gumdrop's rounded points, as long as it is built once.
5. Nothing else changes:
   - the counter star, the notice's own star and the Free cost stars keep their looks;
   - Slate has no flight and does not change.

## Proof

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`. Add a test in tests/design/ that, in Gumdrop and Nova, the flying star and the offer's rising star carry the edge in badge_ink at the skin's width. Name it in your report.
- `godot --headless --path . --script res://tools/contrast_check.gd` passes.
- Recapture `prod-ui-gumdrop-flight.png` and `prod-ui-nova-flight.png`. To each, add:
  - a frame at 25% of the flight, with the star over the pill;
  - the offer case at 25% of the rise.

  Report the paths, and the frame in which the star is hardest to see.
