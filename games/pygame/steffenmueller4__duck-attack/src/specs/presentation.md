# Presentation

## Purpose

Shared look and feel across all screens.

## Requirements

**PRES-1:** The mouse cursor must be the crosshair image, `CROSSHAIR_SIZE` (64 px)
square, on every screen, with its hotspot (the aim point) on the crosshair's red dot
(`CROSSHAIR_HOTSPOT`).
Verified by: `test_crosshair_cursor_is_scaled_with_hotspot_on_red_dot`,
`test_game_uses_crosshair_cursor`

**PRES-2:** All on-screen text must be drawn with a dark drop shadow
(`TEXT_SHADOW_COLOR`) so it stays readable on the background. Normal text uses
`TEXT_COLOR` (white), emphasized text `HIGHLIGHT_COLOR` (gold).
Verified by: manual

**PRES-3:** The name entry, round-over and high-score screens must dim the background
with `OVERLAY_COLOR`.
Verified by: manual

**PRES-4:** Images that need transparency (duck, crosshair) must have a real alpha
channel.
Verified by: `test_duck_image_is_scaled_and_transparent`

**PRES-5:** Everything loaded at runtime must live under `src/duck_attack/assets/`.
Verified by: the release smoke test (see DIST-3)
