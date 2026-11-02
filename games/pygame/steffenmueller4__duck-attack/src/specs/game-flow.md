# Game flow

## Purpose

The game runs in a single window and cycles through four screens: name entry, playing a
round, the round's final score, and the high-score list.

```
NAME_ENTRY --(Enter / click, name not empty)--> PLAYING
PLAYING --(timer runs out)--> ROUND_OVER
ROUND_OVER --(after SCORE_SCREEN_DURATION)--> HIGHSCORES
HIGHSCORES --(click)--> NAME_ENTRY
```

## Requirements

**FLOW-1:** The game must open one window titled `TITLE` ("Duck Attack") with a fixed
size of `SCREEN_WIDTH` × `SCREEN_HEIGHT` (1280 × 720) and the background image scaled to
fill it.
Verified by: `test_game_runs_a_few_frames`

**FLOW-2:** The game must start in the name entry screen.
Verified by: `test_game_starts_with_name_entry_and_enter_starts_the_round`

**FLOW-3:** The game must move between screens only as shown in the diagram above. In
particular, a click on the round-over screen does nothing.
Verified by: `test_score_screen_then_highscores_then_click_restarts`,
`test_clicks_do_not_shoot_after_round_is_over`

**FLOW-4:** Pressing `Esc` or closing the window must quit the game from any screen.
Verified by: `test_escape_stops_game`

**FLOW-5:** Only the left mouse button counts as a click, on every screen.
Verified by: manual

**FLOW-6:** The game must aim for `FPS` (60) frames per second, and all timing (round
timer, duck movement, screen durations, sound intervals) must depend on elapsed time,
not on the frame rate.
Verified by: manual (the tests drive all time-based logic through `update(dt)`)

**FLOW-7:** Ducks must only be visible while playing; leaving the round or the name
entry removes all ducks.
Verified by: `test_round_ends_after_duration_and_records_highscore`
