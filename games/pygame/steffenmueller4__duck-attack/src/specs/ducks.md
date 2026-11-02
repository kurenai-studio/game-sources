# Ducks

## Purpose

Ducks fly across the sky from left to right at random heights and distances. Distance
makes a duck smaller, slower and worth more points.

## Requirements

**DUCK-1:** Each duck must get a random distance, expressed as a scale between
`DUCK_MIN_SCALE` (0.35, farthest) and `DUCK_MAX_SCALE` (1.0, closest). Its on-screen
width is `DUCK_WIDTH` (140 px) × scale, keeping the image's aspect ratio.
Verified by: `test_random_scale_stays_in_range`, `test_duck_image_is_scaled_and_transparent`

**DUCK-2:** A duck's speed must be `DUCK_SPEED` (260 px/s) × (0.6 + 0.4 × scale), so the
farthest ducks fly at roughly 74 % of the closest ducks' speed.
Verified by: `test_far_ducks_are_smaller_slower_and_worth_more`

**DUCK-3:** A duck's points must be `POINTS_PER_HIT` (10) / scale, rounded to the
nearest multiple of `POINTS_ROUNDING` (5), and at least `POINTS_PER_HIT`.
- *Scenario:* scale 1.0 → 10 points; scale 0.5 → 20; scale 0.35 → 30.

Verified by: `test_far_ducks_are_smaller_slower_and_worth_more`

**DUCK-4:** A duck must enter from just off the left edge, at a random height between
`DUCK_MIN_Y` (40) and `DUCK_MAX_Y` (320) px, and fly to the right with a gentle up-and-down
bob (amplitude 12 px × scale).
Verified by: `test_duck_starts_off_screen_left_and_flies_right`

**DUCK-5:** A duck that leaves the screen on the right must be removed (it escapes; no
penalty).
Verified by: `test_duck_is_removed_after_leaving_screen_right`

**DUCK-6:** A shot must only hit a duck on a non-transparent pixel of its image; clicks
on the transparent area around it are misses.
Verified by: `test_click_on_duck_pixel_hits`, `test_click_on_transparent_corner_misses`

**DUCK-7:** A shot duck must turn upside down and fall with gravity
`DUCK_FALL_GRAVITY` (1500 px/s²), keeping a little forward motion, until it leaves the
bottom of the screen and is removed. A falling duck can't be hit again.
Verified by: `test_shot_duck_falls_and_is_removed`

**DUCK-8:** When ducks overlap, closer (larger) ducks must be drawn in front of farther
ones.
Verified by: manual
