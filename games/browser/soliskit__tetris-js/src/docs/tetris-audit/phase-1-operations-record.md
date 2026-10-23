# State Changes by Operation

The state changes allowed for each operation.

Status and provenance are recorded in `DECISIONS.md`, row D32. The drafter read production code, so this record is not implementation-independent under blueprint O8. No entry below was taken from code or tests.

Baseline: D31 (`docs/phase-1-frame-principle-decision.md`, the frame principle Z1), D16 (`docs/phase-1-state-decision.md`) sections 1.1, 4, 5, 7 and 8, D17 item 15, D18 (`docs/phase-1-r1-decision.md`) B6 to B16, D20 item 16, D21 (`docs/phase-1-r2-r5-decision.md`) S1 to S9, D22 T1 to T3, D23 U3 and U4, and `REQUIREMENTS.md`. This file changes no bytes of any of them and does not edit `REQUIREMENTS.md`.

Nature of this record. Every assignment in Part A is taken from the wording of the cited requirement or decision. It adds no behavior and no new choice. It lists the authoritative items (D16 1.1 items 1 to 14, item 15, item 16) that the cited text says the operation changes. Under Z1, an item not listed for an operation is not assigned to it, except where Part B says the sources are silent. Item numbers: 1 locked blocks, 2 falling piece, 3 held piece, 4 hold-used, 5 next-three queue, 6 bag, 7 score, 8 game mode, 9 reset count, 10 confirmation pending, 11 selected choice, 12 held directions and order, 13 repeat position, 14 touch drag, 15 lowest row reached, 16 withdrawn-from-Continue indicator.

## Part A. Assignments stated by the sources

Control operations (D16 section 5):

| Operation | Items changed and source |
| --- | --- |
| 1. Confirmation open | 10 to pending, only while paused; 11 to Cancel (B12, STA-1) |
| 2. Confirmation selection change | 11 (STA-1, INP-4) |
| 3. Confirmation answer | New Game: the game is given up and a new one starts (STA-1): board, score, held piece, queue and bag reset, hold available (B8), saved game withdrawn (S1, S2; item 16 set, S9); 10 and 11 cleared (B12). Cancel, Escape, a click outside the dialog or any other action: 10 and 11 cleared, the game stays paused (STA-1, B12) |
| 4. Direction or control press | 12 gains a token in order of pressing (B12). A press with Cmd, Ctrl or Alt never counts as held (INP-3). The game effect of a pressed control is the gameplay operation below |
| 5. Direction or control release | 12 loses the token; the last remaining token wins (B12, INP-2); disconnecting a gamepad releases everything (INP-4) |
| 6. Repeat-control progression | 13 advances (INP-2: first repeat after 167 ms, then every 33 ms; soft drop at once, then every 50 ms); each repeat is a move or soft drop below; repeating stops when the game stops playing or the window loses focus (INP-2; 13 idle when paused or over, B12) |
| 7. Touch begin | 14 (B12, INP-5); see Part B |
| 8. Touch update | 14 (B12); a drag moves one column per cell after half a cell, and soft drops one row per cell (INP-5); those are the move and soft drop below; 14 controls only the piece that was falling when the drag began (INP-5, B12) |
| 9. Touch end or cancel | 14 (B12); see Part B |

Gameplay operations (not enumerated in D16 section 5):

| Operation | Items changed and source |
| --- | --- |
| Move left or right, rotate | 2 if legal (PLY-1, PCE-4; unchanged if nothing fits). If the piece reaches a new lowest row, 15 becomes that row and 9 becomes 0; otherwise a resting piece with 9 below 15 gets 9 plus 1 and the 0.5 second delay restarts; at 9 equal to 15 the delay is not restarted; moving off a ledge cancels the delay (B9.2, PLY-6) |
| Gravity tick, soft drop | 2 down one row (PLY-2, PLY-3); 15 and 9 as for a fall (B9.2: "move, rotation or fall") |
| Hard drop | 2 to its landing position, then lock (PLY-4) |
| Lock (hard drop, delay expiry, landing at count 15 after a cancelled delay) | 1 gains the piece, full rows removed and rows above shift (SCO-1); 7 scores 100, 300, 500 or 800 for 1, 2, 3 or 4 rows (SCO-1); the next piece becomes current from 5 and 5 refills from 6, 6 refills with a full bag when empty (PCE-3, PCE-5, D16 1.1); 4 returns to available (B8); 9 becomes 0 and 15 becomes the greatest row of the new piece (B9.2); 14 no longer controls the old piece (INP-5, B12). If the new piece has no room: ordinary game over (STA-3) |
| Hold | 2 and 3 swap, the held piece in its starting state, or the next piece from 5 and 6 when none is held (PLY-7); 4 set (B8); the piece brought in has 9 equal to 0 and 15 at its initial row (B9.2); no room means ordinary game over (STA-3) |
| Pause, page hidden | 8 to paused (STA-2, STA-5); a pause during the lock delay cancels the delay and counts as one reset: 9 plus 1 when 9 is 14 or less, and 9 becomes 16 when it was 15 (B9.2, STA-2); gravity, lock delay and repeat stop (STA-2, U4); 13 idle (B12); pausing saves the game (STA-4) |
| Resume | 8 to playing (STA-2); a resting piece starts the 0.5 second delay again, except that at 9 equal to 16 it locks at once (B9.2) |
| Continue (from game over only, when Continue is available) | 1 to 9 and 15 restored exactly as saved, 8 to paused; a fresh bag if the save has none (STA-4, B9.2, STA-6) |
| New Game from game over | as New Game under operation 3 (STA-1, INP-4 "a game Menu just started", B8) |
| Ordinary game over (new or held piece has no room) | 8 to game over; all timers stop; saved game withdrawn (STA-3, S2; item 16 set, S9); items 2, 3, 4, 6, 9, 14 and 15 have no semantic value, and clearing them is not required (B6, B8, B12) |
| Engine fault stop (SAF-3) | not an ordinary transition: game over, no timers running (a failed cancel may still fire but must not change the stopped game, U3), fault reported (T1), last good save kept (S6); the ordinary contents reached at the fault are retained (D16 section 7); a fault alone does not withdraw the saved game (S3) |

Persistence effects stated by the sources: item 16 is set when this session withdraws the saved game or attempts to, and cleared when the session starts and when this session writes a saved game successfully (S9); a failed save withdraws the saved game from Continue (S5); a failed withdrawal is covered by S4.

## Part B. Points the sources do not specify

These are not assigned and not excluded by this record. They stay unspecified until an owner selection records them. This record does not resolve them.

1. The effect of a cancelled touch on the controlled piece, and which of the touch operations (7, 8 or 9) commits the rotation that INP-5 says a tap causes.
2. When the save that STA-4 says line clearing causes is written, relative to the next piece appearing and to a game-over result. STA-4 says only that clearing lines saves; B16 says what a valid saved game contains, not when it is written.
3. Whether the held-direction tokens (item 12) survive a pause, and whether repeat (item 13) restarts on resume while a direction is still held.
4. Whether Continue changes item 16. S9 lists only withdrawal or its attempt, session start and this session's successful save, so by S9's wording Continue does not.

## Not decided here

- The Part B points.
- Closure of the Phase 1 exit item on operations (blueprint O1). Part B must be specified, or the exit criterion shown to be met without it, before that item can close; recording the points as unspecified does not meet it.
- Any change to REQUIREMENTS.md and any code change.
