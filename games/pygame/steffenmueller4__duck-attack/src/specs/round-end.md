# Round end screens

## Purpose

After a round the player first sees their score, then where it ranks among the best
rounds, and can start the next round from there.

## Requirements

### Round-over screen

**END-1:** The round-over screen must show "Round over!", the final score as
`<n> points` in the highlight color, and a countdown "High scores in <s> ..." (whole
seconds, rounded up), over the dimmed background.
Verified by: manual

**END-2:** After `SCORE_SCREEN_DURATION` (10 s) the high-score screen must follow
automatically. Clicks don't skip it.
Verified by: `test_score_screen_then_highscores_then_click_restarts`,
`test_clicks_do_not_shoot_after_round_is_over`

### High-score screen

**END-3:** The high-score screen must show the title "High Scores" and one row per entry
of the high-score list, best first, with the columns: rank (`1.`), player name (`-` if
empty; clipped if too long for its column), date and time of the round
(`YYYY-MM-DD  HH:MM`) and score.
Verified by: manual

**END-4:** The row of the round just played must be shown in the highlight color. If the
round didn't make the list, a note "Your score: <n> (not in the top list)" must be shown
instead.
Verified by: `test_round_ends_after_duration_and_records_highscore` (rank only; the
note is manual)

**END-5:** The screen must show the hint "Click to play again"; a left click must go to
the name entry.
Verified by: `test_score_screen_then_highscores_then_click_restarts`
