# Round

## Purpose

A round is a fixed-length time window in which the player shoots as many ducks as
possible. Hits score points, misses cost points.

## Requirements

**ROUND-1:** A round must last `ROUND_DURATION` (30 s) and start with a score of 0.
Verified by: `test_round_ends_after_duration_and_records_highscore`

**ROUND-2:** Exactly one duck must be flying at any time during a round: a new duck is
sent in as soon as there is no flying duck (at the start, after the previous one left
the screen, or right after it was shot, while it is still falling). See
[ducks.md](ducks.md).
Verified by: `test_left_click_shoots_duck_and_next_one_starts`

**ROUND-3:** Every left click during a round is a shot. A shot must hit at most one
duck: the closest (drawn on top) flying duck whose visible pixels are under the
crosshair's hotspot.
Verified by: `test_left_click_shoots_duck_and_next_one_starts`,
`test_closer_duck_in_front_is_hit_first`

**ROUND-4:** A hit must add the duck's points (see DUCK-3) to the score.
Verified by: `test_each_hit_adds_points`

**ROUND-5:** A miss must subtract `MISS_PENALTY` (5) points. The score may go negative.
- *Scenario:* Given a score of 0, when the player shoots at the empty sky, then the
  score is -5.

Verified by: `test_missed_shot_hits_nothing_and_costs_points`,
`test_miss_penalty_applies_per_miss_after_hits`

**ROUND-6:** There is no ammunition or reload; the player may shoot as often as they
click.
Verified by: manual

**ROUND-7:** When the time is up, the round must end: the ducks disappear, the result is
added to the high-score list (see [high-scores.md](high-scores.md)) and the round-over
screen is shown. Clicks after that are not shots.
Verified by: `test_round_ends_after_duration_and_records_highscore`,
`test_clicks_do_not_shoot_after_round_is_over`

## HUD

**ROUND-8:** During a round, the score must be shown top-right as `Score: <n>` and the
remaining time top-left as `Time: <s>` (whole seconds, rounded up), each
`HUD_MARGIN` (20 px) from the corner.
Verified by: `test_score_top_right_and_timer_top_left`

**ROUND-9:** The time must turn `WARNING_COLOR` (red) once `TIME_WARNING` (10) or fewer
seconds are shown.
Verified by: `test_timer_turns_red_near_the_end`
