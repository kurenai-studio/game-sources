# Requirements

The game's behavior, safeguards, and rules for changing them.

Each behavior has an ID. Tests name the IDs they check, such as `[SCO-1]`
for scoring. The traceability test fails the build if an ID has no test,
a test names an unknown ID, or a test names none. This checks the link
between requirements and test titles, not whether an assertion proves a rule.

Unit tests live in `test/`; browser tests live in `e2e/`. Search both for
an ID to find its tests, for example `grep -rn "SCO-1" test e2e`.

SRS wall kicks are the ordered small position adjustments the Super
Rotation System tries to make a rotation fit. This explanation is not
part of the requirement text.

## Rules for changes

1. Behavior changes are written down. What the player sees, does, saves, or can load changes only when this file changes in the same commit.
2. Protection does not shrink. A runtime check, or the test that proves it works, is loosened only when a requirement changes, and then it is replaced by whatever protection the new rule needs, if any. Otherwise a test must show the same input gets the same result at the same boundary. Types do not count as evidence.
3. Only what is described is protected. Behavior that no requirement and no test describes has no guarantee.

### Classifying changes

Each change to game code (anything under public/) or to a requirement row is one or more of these, and each kind needs its own evidence.

| Class | What changes | Evidence |
| --- | --- | --- |
| Refactor | Code, not behavior | Requirement rows stay unchanged and tests pass. Tests change only to follow renamed or moved code, never to expect different behavior. |
| Bug Fix | Code, to match an existing requirement | A test for that requirement that failed before the fix |
| Intentional Change | Code and requirements | Requirement rows edited in the same commit, with tests updated to match |
| Clarification | Requirements, to describe what the game already does | The new rows and their tests |


A change to neither code nor requirement rows needs no kind. The three rules still apply: weakening a test falls under rule 2, and the gates QA-1 to QA-6 are never lowered or removed.

## Pieces and board

| ID | Requirement |
| --- | --- |
| PCE-1 | The board is 10 columns by 20 rows. Positions outside it hold nothing. |
| PCE-2 | There are seven pieces (I, O, T, S, Z, J, L), each made of four blocks, with the standard Super Rotation System (SRS) rotation states and fixed colors. |
| PCE-3 | A new piece appears in its first rotation, horizontally centered, in the top two rows. |
| PCE-4 | Rotation turns the piece clockwise or counterclockwise, trying that direction's SRS wall kicks in order. If every kick is blocked, the other direction is tried the same way. If nothing fits, the piece is unchanged. The O piece does not rotate. |
| PCE-5 | Pieces are dealt from a shuffled bag of all seven, so each appears once per seven. Every new game starts with a full bag, so its first seven pieces are all different. The random source can be replaced (for tests). |
| PCE-6 | A piece can never be outside the board or overlap a locked block. |

## Play

| ID | Requirement |
| --- | --- |
| PLY-1 | Moving left or right shifts the piece one column when that space is free. |
| PLY-2 | Gravity moves the piece down one row every max(0.25, 0.7 - 0.02 × (level - 1)) seconds while playing. |
| PLY-3 | Soft drop moves the piece down one row and restarts the gravity timer. |
| PLY-4 | Hard drop moves the piece straight to where it would land and locks it at once. |
| PLY-5 | The ghost piece shows where the current piece would land. |
| PLY-6 | A piece locks 0.5 seconds after it comes to rest on the floor or a block, however it got there: falling, moving, turning, appearing, or play resuming. Moving or rotating it while it rests restarts that delay, at most 15 times; reaching a lower row than before resets the count; moving off a ledge cancels the delay; once the 15 are used, landing locks at once. |
| PLY-7 | Hold puts the current piece aside in its starting state and brings in the held piece, or the next piece if none is held. Hold works once per piece. |
| PLY-8 | The next three pieces are always known, and shown while a game is in play or paused. |

## Scoring

| ID | Requirement |
| --- | --- |
| SCO-1 | Clearing 1, 2, 3 or 4 lines at once scores 100, 300, 500 or 800. Cleared rows disappear and everything above moves down. |
| SCO-2 | The level is the score divided by 1000, rounded down, plus 1. |
| SCO-3 | The high score is stored on the device and only replaced by a higher score. |

## Game states

| ID | Requirement |
| --- | --- |
| STA-1 | The game opens at game over. New Game works from game over, or while paused to give up that game, never while playing. It resets the board, score, level, held piece, queue and bag, and forgets the saved game. While paused it first asks in a dialog ("Start a new game? This game will be lost."), so one stray press cannot end a game: New Game in the dialog gives the game up, while Cancel, Escape, a click outside the dialog, or any other action before the answer keeps it paused; a click inside the dialog, away from its buttons, does nothing. Cancel is selected when it opens, so a second Enter keeps the game, and the selected button is always highlighted. While the dialog is open, keys go to its buttons, the left and right arrow keys move between them, and a held key repeating presses nothing. |
| STA-2 | Pause works only while playing and resume only while paused. While paused nothing moves: no gravity, no lock delay, no input. Pausing during the lock delay cancels it and counts as one reset, and resuming starts it again. |
| STA-3 | The game ends when a new or held piece has no room to appear. All timers stop and the saved game is forgotten. |
| STA-4 | Pausing saves the game, and so does clearing lines. Continue, from game over only, restores exactly what was saved, paused, including the pieces left in the bag. |
| STA-5 | The game pauses when the page is hidden, for example when switching apps. |
| STA-6 | Only the current saved-game format loads. Older formats are refused. A saved game stored under the names used before APP-6 (without the `tetris.` prefix) is not read. |

## Safety

| ID | Requirement |
| --- | --- |
| SAF-1 | A saved game is untrusted input. Every field is checked and pieces are rebuilt from the built in definitions. Any invalid save is rejected whole and forgotten, never partly loaded. |
| SAF-2 | Storage that is missing, blocked, full, or throws on reads or writes never stops the game. Invalid stored values are ignored. |
| SAF-3 | If anything in the engine throws, the game stops in a safe state (game over, no timers running), the fault is reported, and the last good save is kept. |
| SAF-4 | After every action and every timer the engine checks its invariants: board 20 by 10, three pieces queued, a valid score, and while playing the piece fits, gravity is running and the lock delay runs exactly while the piece rests, otherwise no timers run. A broken invariant is handled like SAF-3. Legal play never breaks one. |
| SAF-5 | An error while drawing or reading a gamepad is reported and the drawing and polling loops keep running. |
| SAF-6 | The rules hold throughout long random play: no overlaps, valid scores and levels, no faults. |

## Input

| ID | Requirement |
| --- | --- |
| INP-1 | Keys: A or Left moves left, D or Right moves right, W or Up rotates clockwise, Z rotates counterclockwise, S or Down soft drops, Space hard drops, H holds, P or Escape pauses and resumes, Enter starts a new game, C continues. |
| INP-2 | Holding a move key moves once, then again after 167 ms, then every 33 ms. The newest direction wins; releasing it goes back to one still held, on the keyboard, the stick or the directional pad. Holding S or Down soft drops a row at once, then every 50 ms, and a resting stick does not cancel it. Repeating stops when the game stops playing or the window loses focus. |
| INP-3 | Keys pressed with Cmd, Ctrl or Alt, and the keyboard's own key repeat, are ignored. A key pressed with Cmd, Ctrl or Alt never counts as held, because macOS may not report its release. Game keys do not trigger the browser's default action (such as scrolling). |
| INP-4 | Gamepad (standard mapping): A hard drops, B rotates, X holds, Y continues, Menu pauses or starts a new game at game over, and View starts a new game. While the pause screen asks to confirm a new game, left and right on the directional pad or stick move between Cancel and New Game, once per push, A presses the one selected and B cancels; nothing else acts. The right shoulder button also rotates and the left one rotates counterclockwise. Buttons act once per press, and two buttons for the same action pressed together act once. Menu and View act alone: other buttons pressed at the same moment do nothing, so A cannot hard drop the first piece of a game Menu just started, and if Menu and View are pressed together, Menu acts. Moving and soft dropping with the stick or directional pad carry on as held. The stick and the directional pad move with the same repeat timing as keys; holding either down soft drops every 50 ms, and up on the directional pad hard drops. A resting stick or pad does not cancel keyboard moves, and letting either go back to the middle returns to a move key still held. Disconnecting releases everything. |
| INP-5 | Touch: a tap on the board rotates, allowing 10 px of finger wobble. Dragging sideways moves one column per cell, starting after half a cell; dragging down soft drops one row per cell. The piece stays on the grid and in step with the finger, even after pushing into a wall. A drag only controls the piece that was falling when it began. Tapping the hold box holds. |
| INP-6 | The hold box is a button to keyboards and screen readers: Tab reaches it, it is named Hold with H as its shortcut, and with keyboard focus Enter or Space hold while playing. Clicking it does not take focus, so those keys keep their game actions. |

## Display

| ID | Requirement |
| --- | --- |
| DSP-1 | In portrait on a phone the whole game fits the screen with no scrolling, and the board keeps a 1:2 shape. The board keeps one size whether the game is starting, playing, paused or over. |
| DSP-2 | Canvases draw at the screen's full pixel resolution and redraw correctly after the window changes size. |
| DSP-3 | While nothing changes, nothing is redrawn (the engine counts changes to the locked blocks, so the page knows when they need drawing), storage is not read again, and the page does not wake up every frame, to save battery. |
| DSP-4 | The page cannot be zoomed, scrolled by touch, or have its text selected. Quick taps never zoom it in Safari, and the second of two quick taps still works. If Safari zooms in anyway, or opens the page still zoomed after a reload, its pinch and double tap work again, so the player can zoom back out. |
| DSP-5 | The score, high score, buttons and hints always match the game state, including changes made in another tab. |
| DSP-6 | Pieces are drawn in the Display P3 color space using their usual color values, so they look more vivid on iPhone screens. Each canvas gets its drawing context as the page starts, so nothing else can change its color space first, and draws vivid colors only if it really is Display P3. Saved games keep the usual colors. |
| DSP-7 | The screen stays on while playing. Pausing or game over lets it sleep again. If the system takes the wake lock back during play, the game asks for it again. If the wake lock is unsupported or refused, the game plays normally. |
| DSP-8 | At game over the board shows only the locked blocks, with no falling piece, ghost, held or upcoming pieces, since a new game deals its own. So the page opens to an empty board. Once a game ends, Game Over shows over the board until a new game starts or a saved one is continued, and screen readers announce it. |

## App

| ID | Requirement |
| --- | --- |
| APP-1 | The game can be installed to the home screen and opens full screen with its own icon. |
| APP-2 | After the first visit the game opens from its cached copy straight away, online or offline. A new version is downloaded in the background and used from the next launch, and only once every file of it has downloaded. A page loads every file from the version it opened with, even if a newer one finishes downloading while it loads, so the game never runs a mix of two versions. |
| APP-3 | Every file the page uses exists and is referenced by a relative path, so the game works from any folder (GitHub Pages serves it from /tetris-js/). The local server serves each file with the right type. |
| APP-4 | The game supports iOS 27 (Safari 27) and later, on the iPhone 14 Pro Max and newer, in portrait. |
| APP-5 | The page asks for all of its scripts at once rather than one import level at a time, so it starts faster. |
| APP-6 | GitHub Pages serves every project of an account from one origin, which they all share storage and caches with, so the game touches only its own: it stores the high score and saved game under names of its own, and deletes only caches it made. |

## Process

| ID | Requirement |
| --- | --- |
| QA-1 | Every requirement is verified by at least one test, every test names the requirements it verifies, and those requirements exist. |
| QA-2 | The unit tests exercise every line, branch and function of the game logic (`public/game/`). `npm test` fails below 100%. Code that cannot be reached is removed rather than left untested. |
| QA-3 | The browser tests exercise every line, branch and function of the page script (`public/script.js`), measured in Chromium. `npm run test:e2e` fails below 100%. |
| QA-4 | The browser tests pass in WebKit (Safari's engine) at iPhone size, as well as in Chromium at iPhone and desktop sizes. |
| QA-5 | Everything the browser loads (`public/`) passes TypeScript's strictest type checks, with types written as comments in the JavaScript. `npm run typecheck` runs before the tests in CI. |
| QA-6 | Mutation testing (Stryker) of the game logic leaves no mutant alive: every small wrong change to `public/game/` is caught by a failing test, or makes the tests run past the time limit (for example a piece with no blocks, whose ghost falls forever). Loops in tests are bounded, so a broken game fails a test rather than hanging it. A mutant that cannot change behavior is marked in the code with the reason. `npm run test:mutation` fails if any survive. It runs weekly in CI, and on every pull request that changes the game logic or its tests: a change to the game logic alone mutates just the changed files, and a change to the tests runs the full suite. |
