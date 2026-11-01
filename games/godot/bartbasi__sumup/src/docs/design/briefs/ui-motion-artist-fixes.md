# Fixes: ui-motion-artist, Phase 1 round 2

From the senior-graphic-designer. Strong work: three clearly different interface languages, and the shared interface made composing the twelve screens straightforward. This list is everything I need changed before the final capture. Where an item contradicts your original brief, this list wins. The existing interface stays; items 5 to 7 add three small functions.

Your write paths are unchanged (ui_common/, gumdrop/ui/, slate/ui/, nova/ui/, docs/design/review/ui-*.png). I have already changed the token files and mock_state.gd; re-read them first.

## Fixes

1. **Costs use the tile label format (GDD D-32).** Booster costs are powers of two and show as tile labels: "2K", not "2,048". In all three booster_button.gd use `MockState.cost_label(cost)`. In ui_sheet.gd and ui_demo.gd build the buy button text with `MockState.buy_text(booster_id, cost)` ("Shuffle for 2K"); it uses the new `MockState.BUY_FOR` you asked for.
2. **Components must work when setup() runs before they are in the scene tree.** Today an icon_button set up outside the tree never draws its icon: the icon is sized while outside the tree, gets no resize notification, and never builds. Make IconView build its drawing when it enters the tree, or whenever it draws at a size other than the last one it built for. Check the other components for the same pattern.
3. **Gumdrop Hairline** is invisible on `bg`. Draw it as a `divider_width` px rounded line in the new palette token `divider` (#3F2956).
4. **Read every accepted proposed token from the tokens** with `tokens.num()` (or the motion spec) and delete the const. Key names are the ones you proposed, with these exact spellings:
   - Gumdrop: `booster_icon`, `active_raise`, `hud_icon`, `icon_stroke`, `button_lip_pressed`, `focus_width`, `focus_gap`, `divider_width`, `toggle_track_w`, `toggle_track_h`, `toggle_knob`, `toggle_knob_lip`
   - Slate: `booster_icon`, `hud_icon`, `icon_stroke`, `focus_width`, `focus_gap`, `toggle_track_w`, `toggle_track_h`, `toggle_knob_inset`
   - Nova: `backdrop_glow_x`, `backdrop_glow_y`, `backdrop_glow_radius`, `star_seed`, `star_size_min`, `star_size_max`, `star_alpha_min`, `booster_icon`, `hud_ring`, `hud_icon`, `icon_stroke`, `icon_spark`, `icon_fit`, `icon_glow_alpha`, `ring_glow_spread`, `ring_glow_alpha`, `disabled_ring_alpha`, `focus_gap`, `divider_width`, `toggle_track_w`, `toggle_track_h`, `toggle_knob`, `toggle_glow_spread`, `toggle_glow_alpha`
   - ui_common/motion.gd: PULSE_ALPHA_LOW becomes `alpha_low` in Nova's `target_pulse` motion spec
5. **Keep text clear of Nova's star dust.** Add `func set_clear_rects(rects: Array[Rect2]) -> void` to all three backdrop.gd files (it does nothing in Gumdrop and Slate). Nova skips every star within `star_clearance` px of any of those rects, in global coordinates, and keeps the same seed for the rest. My screens pass the rects of every text holder.
6. **Booster bar:** add `func content_top() -> float` to all three booster_bar.gd files, returning the local y where the always visible part starts (Gumdrop's dock top, Nova's ring row top, 0 for Slate). At game over, when no hint shows, I let the board use the space the bar keeps for its hint.
7. **HUD:** add `func score_label() -> Label` to all three hud.gd files, as you suggested, so screens can call `Motion.count_up()` on it.
8. **Nova HUD:** "best 96,520" sits tight under the score's comma. Put `space_xs` between them.

## Decisions on your open points

- Slate card motion: no squash. Slate's `dialog_in` is now a slide from `from_offset` (-32 px) and a fade from `from_alpha` (0). Your motion.gd already reads both, so check it in the demo; no code change should be needed.
- Slate toggle on as paper (ink fill, ink_dark knob): accepted, it matches the active booster.
- Slate settings icon as three sliders: accepted, it suits the signage style.
- Slate pair names: renamed. Chips now map to "Text on surface: chips, pressed rows, pressed secondary buttons" and "Labels on surface: chips and pressed rows".
- Nova star dust under text: keep text clear, see fix 5.
- Theme limits (no press scale, no text case, no button alignment): noted. My screens set case and alignment themselves.
- Proposed tokens: all accepted, see fix 4.

## Proof

Same as your brief: contrast check passes, the three review PNGs recaptured without errors, and each demo runs 20 seconds without an error line. Also capture my settings screen for each direction into your own review files, which proves fixes 2, 3 and 5 in context:

```bash
godot --path . res://tools/capture.tscn -- --scene res://tools/directions/gumdrop/screens/settings.tscn --out docs/design/review/ui-gumdrop-settings-check.png
```

and the same for `slate` and `nova`. Do not write to the PNGs directly in docs/design/; those are mine.
