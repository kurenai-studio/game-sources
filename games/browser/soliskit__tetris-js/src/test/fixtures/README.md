# Saved Game Fixtures

Released saves kept as fixed inputs for the loading tests.

A fixture is a saved game file the tests load.
These two fixtures preserve saved positions written by released game code.
The session tests continue the current layout and refuse the older layout.
They stand for saves already on players' devices.

- `saved-game-current.json` stores the remaining bag pieces without a saved level.
- `saved-game-with-level.json` stores the remaining bag pieces and a level.

The reader refuses a save with a stored level or a missing bag. Continue then attempts withdrawal: it writes the existing availability flag without deleting the saved data or changing the high score. If that write fails, the flag can remain available. A failed read or a missing save does not write to storage.

These tests cover the two older layouts. They do not establish that the entire current save schema is finalized.

Never edit or regenerate these fixtures.
Keep the older fixture as a refused case so its original bytes continue to test the reader.

Each fixture was recorded after a seeded game cleared a line, held a piece, moved and rotated the falling piece, and paused.
The line breaks make the data easier to inspect without changing its saved position.
The game no longer reads the storage names used by earlier releases.
The capture record attributes the current fixture to releases from PR 27 onward.
It attributes the fixture with a saved level to releases from PR 26 through PR 27.
These are documented capture accounts, not independently replayed original captures.
The current loading tests check selected restored fields; they do not establish that historical capture.
