# Name entry

## Purpose

Before each round the player enters a name, which is shown in the high-score list. The
last name is remembered so a returning player only has to confirm it.

## Requirements

**NAME-1:** The name entry screen must show the title "Your name", the current name in
the highlight color followed by a cursor `_` that blinks twice per second, and a hint:
"Type your name" while the name is empty, otherwise "Press Enter or click to start". The
background is dimmed.
Verified by: manual

**NAME-2:** The name field must be prefilled with the last saved player name (empty if
there is none or it can't be read).
Verified by: `test_name_is_remembered_between_sessions`,
`test_missing_file_gives_empty_name`, `test_saved_name_is_loaded`

**NAME-3:** Typed text must be appended to the name (any characters the keyboard /
input method produces); `Backspace` must delete the last character.
Verified by: `test_game_starts_with_name_entry_and_enter_starts_the_round`

**NAME-4:** The name must not start with whitespace and must be at most
`PLAYER_NAME_MAX_LENGTH` (16) characters; input beyond that is ignored.
Verified by: `test_name_is_trimmed_and_limited_in_length`

**NAME-5:** `Enter` (main or keypad) or a left click must start a round, with the name
trimmed of surrounding whitespace. If the trimmed name is empty, nothing happens.
- *Scenario:* Given the name field is empty, when the player presses Enter, then the
  name entry stays open.
- *Scenario:* Given the name "Ann ", when the player clicks, then a round starts for
  "Ann".

Verified by: `test_game_starts_with_name_entry_and_enter_starts_the_round`,
`test_name_is_trimmed_and_limited_in_length`

**NAME-6:** A click on the name entry screen must not count as a shot (no sound, no
score change).
Verified by: `test_no_shooting_during_name_entry`

**NAME-7:** When a round starts, the name must be saved to `PLAYER_NAME_FILE`
(`~/.duck-attack/player.txt`, plain text), creating the folder if needed.
Verified by: `test_name_is_remembered_between_sessions`
