# High scores

## Purpose

The best rounds on this computer are kept across sessions so players can compete.

## Requirements

**HS-1:** The list must hold at most `MAX_HIGHSCORES` (10) entries. Each entry has the
score, the start time of its round (which identifies the round) and the player name.
Verified by: `test_add_returns_rank_or_none_when_list_is_full`

**HS-2:** Entries must be ordered by score, highest first; on equal scores the earlier
round comes first (so a new round never pushes out an older one with the same score).
Verified by: `test_sorted_by_score_then_earlier_round`

**HS-3:** Every finished round must be offered to the list, including rounds with zero
or negative scores; it enters if it ranks within the top `MAX_HIGHSCORES`.
Verified by: `test_round_ends_after_duration_and_records_highscore`,
`test_add_returns_rank_or_none_when_list_is_full`

**HS-4:** The list must be saved after every round to `HIGHSCORES_FILE`
(`~/.duck-attack/highscores.json`), creating the folder if needed, and loaded at start.
Format: a JSON array of `{"score": int, "timestamp": ISO 8601, "name": str}`.
Verified by: `test_persisted_between_sessions`, `test_names_are_persisted`

**HS-5:** Entries without a `name` (saved by older versions) must still load, with an
empty name.
Verified by: `test_entries_without_name_still_load`

**HS-6:** A missing or corrupt file must not stop the game; the list then starts empty
(and the file is overwritten after the next round).
Verified by: `test_corrupt_file_starts_fresh`
