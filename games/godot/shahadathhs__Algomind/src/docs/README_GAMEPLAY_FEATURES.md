# Algomind — Gameplay Features

> **Purpose:** Define the player-facing experience and separate MVP gameplay from later ideas.  
> **Rules:** The authoritative rules (commands, execution, progress, sync) are in [README_GAME_RULES.md](README_GAME_RULES.md). This document describes the player-facing feature set.

> **Status:** the MVP loop below works offline with bundled levels: board, tape editor (add, remove, reorder), Run, Step, Pause or Continue, Reset, plain-language results, sequential unlock, local best, theme, and reduce motion. Not built yet: hints (3.6), sound, haptics, and run speed (3.7), remote levels (3.8). Sound, music, and haptics are not offered in Settings because the game has no audio or haptic feedback yet.

## 1. Core gameplay concept

Each level presents a compact board with a starting state and a goal. The player creates a short program using a limited set of available commands. When the player presses **Run**, the automaton executes those commands in order. The player studies the result, changes the program, and tries again until the goal is satisfied.

The challenge comes from planning, reading the board, and understanding how the available rules interact—not from fast reactions or hidden controls.

## 2. Core player loop

1. **Inspect:** Understand the board, the automaton's starting position and direction, obstacles, and goal.
2. **Plan:** Add supported commands to an instruction sequence.
3. **Simulate:** Run the sequence and watch the automaton move one step at a time.
4. **Learn:** Receive clear feedback about success or why the attempt failed.
5. **Adjust:** Edit the sequence, reset the run, or use a hint.
6. **Complete:** Save local progress and continue when the level is solved.

The player should be able to replay a level without friction. There are no lives, energy systems, or timers in the MVP.

## 3. MVP features

### 3.1 Level board

- Display the grid clearly at phone size.
- Distinguish empty tiles, walls/obstacles, the starting position, the goal, and any mechanics supported by that level.
- Make the current automaton position and orientation unambiguous.
- Scale the board to the available viewport without making cells or touch targets too small.
- Use color plus shape, icon, or animation to communicate state; do not rely on color alone.
- **Test boards:** a level with `extraBoards` (the Generalize world, `docs/README_GAME_RULES.md` section 3.5) shows one board at a time with a row of board tabs above it (BOARD 1, BOARD 2, and so on; a single-board level has no tabs). Run, Step and Reset act on the selected board. A board the current program has solved shows a check beside its label; editing the program clears every check. After a successful run the next unsolved board is selected and the objective row reads "BOARD 1 SOLVED". The level is solved, with its result, points and stars, only when the same program has solved every board; steps for scoring are the sum over all boards. A failure names its board ("BOARD 2: ..."). How to play explains test boards in a short paragraph.

### 3.2 Command/program editor

Start with the smallest command set that makes the core puzzle interesting. The settled first command set is:

- `MOVE_FORWARD`
- `TURN_LEFT`
- `TURN_RIGHT`

Add a command such as `INTERACT` only if the initial puzzles need switches or interactable objects. Do not begin with loops, conditions, variables, sensors, or a general-purpose programming language unless those are central to the intended design.

Required behavior:

- Add commands using touch-friendly controls.
- Remove, reorder, and replace commands.
- Show the command limit when a level has one.
- Make the current sequence readable before execution.
- Provide **Run**, **Step**, **Pause/Resume**, and **Reset** as appropriate for the first version.
- Prevent the player from accidentally editing the sequence while a run is executing, or define and test a clear edit-during-run behavior.
- Preserve the current sequence when a run fails so the player can inspect it.

Loops and decisions (rules in [README_GAME_RULES.md](README_GAME_RULES.md) sections 3.1 to 3.3):

- The commands row shows a **Repeat** tile when a level offers `REPEAT` and a **Repeat until** tile (label UNTIL) when it offers `REPEAT_UNTIL`, side by side when both are offered. With five tiles the icon sits above the label.
- Tapping a loop tile starts a loop and opens it; commands tapped next go into its body (at most 8). The same tile now reads END LOOP and closes it; an empty loop cannot be closed and is not a program (Run and Step stay off and the message asks for a command). Only one loop is open at a time, and a loop cannot hold a loop, so the other loop tile waits while one is open.
- A Repeat loop starts at two rounds; selecting its count tile shows minus and plus (2 to 11). A Repeat until loop has no count: its header reads UNTIL BLOCKED, selecting it shows only the move and remove tools, and the loop is ended by the wall or board edge, not by the player.
- A loop costs 1 slot plus one per body command, in the editor, the command counter, the result and the score.
- While a run is shown, a Repeat header reads round/count and a Repeat until header reads ROUND and the round number; a failure inside a body shows the X on that body tile. A Repeat until loop that never meets a wall is stopped by the step limit and the message says the loop never reached a wall.
- A Repeat until loop on a level that also offers `IF` can wait for the goal: the header is selected when the loop opens, and tapping it again (or the extra tile that appears with the move and remove tools) switches UNTIL BLOCKED to UNTIL GOAL and back. A loop that never reaches the goal is stopped by the step limit and the message says the loop never reached the goal; a round in which nothing ran stops the run with the message that a round of the loop did nothing.
- The how-to-play screen explains both loops.

If (rules in section 3.3):

- The commands row shows an **If** tile when a level offers `IF`. Tapping it opens an If group with the sensor AHEAD and selects its header; the extra tile with the move and remove tools (or a second tap on the selected header) switches AHEAD, LEFT and RIGHT. Commands tapped next go to the then branch.
- While an If is open, an **Else** tile appears beside the If tile and switches to the else branch; the If tile reads END IF and closes the group. An If needs one command before Else or End if: a group with an empty then is not a program (Run and Step stay off and the message asks for a command).
- Branches take commands only: up to 4 per branch, no loop and no other If inside, and no loop can open while an If is open. Inside an open loop an If is one of the loop's items, and the loop can only be ended once the If is closed. When the palette has six tiles, the loop tiles that cannot be used give way to Else while an If is open, so the row never has more than six tiles.
- An If costs 1 slot plus one per command in then and else; the Else divider on the tape is not a slot and has no number. Selecting the header and removing deletes the whole If; moving it moves the group. Commands move only within their own branch.
- While a run is shown, a command in a branch that was not taken stays outlined; the X of a failure sits on the command that was blocked, inside whichever branch ran.

Procedures (rules in section 3.4 of the game rules):

- The commands row shows a **Proc** tile when a level offers `PROC`. Tapping it opens the next free definition (A, then B, then C) at the start of the tape and selects its header. Commands tapped next, including Repeat, Repeat until and If groups with their usual open rules, go into the definition. The Proc tile reads END PROC with a check while a definition is open and closes it once it holds a command; when A, B and C all exist it is disabled. A definition with no command is not a program (Run and Step stay off and the message asks for a command).
- While no definition is open, each defined name has a **Call** tile (CALL A, CALL B, CALL C) that appends a CALL to the main program, or into an open main-program loop. No Call tile shows while a definition is open, and a Call is disabled while an If is open. A definition has at most 8 items; a CALL is 1 slot and a definition is 1 plus its items.
- Definitions always come first on the tape, then the main program. Selecting a header and removing deletes the whole definition; its CALL tiles stay, Run and Step turn off, and the message reads "Procedure A is not defined" until the definition is made again or the calls are removed. A definition moves only among the definitions, and a main-program command never moves into them.
- While a run is shown, the tile of the definition that is running is current, and so is the CALL tile that started it. A loop in the main program that holds the running CALL shows its count. When a run fails inside a definition the X sits on that command in the definition.
- The how-to-play screen explains Proc and Call.

Counter, nested loops, breadcrumbs, else-if chains and the sweep goal (rules in sections 3.6 to 3.8 of the game rules):

- The commands row shows an **Inc** tile (label INC, a "+1" icon) when a level offers `INC` and a **Mark** tile (a dot with an arrow behind it) when it offers `MARK`. Both are actions: they go to the main program, a loop body, a definition or an If branch, cost one slot and one step, and move nothing. With nine commands offered the row wraps to two rows of at least 44 px height.
- **Counter.** When the level offers `INC`, the count of a Repeat loop has one more value after 11: **N** (the plus tool steps 2 to 11 and then N; minus goes back). The tape shows N with a counter icon (three rising bars) on a tall tile and as "xN" on a compact one. While a run is shown the caption above the tape reads "PROGRAM N 3" with the counter's value after the last shown step (N is 1 before the first step). A Repeat with N reads "2/N" while it runs. A run stopped by the step limit inside such a loop says that the loop that counts with N ran for too many steps.
- **Nested loops.** On a level that lists `nested_loops`, the loop tiles stay as they are while a loop is open: tapping one starts an inner loop inside the open loop (two levels at most, so both loop tiles wait while two are open), and a separate **End loop** tile (a check) appears while any loop is open. It closes the inner loop first, then the outer one. On other levels the loop tile that opened a loop ends it, as before. Nested loops are drawn as two brackets, the inner inside the outer; the slot goes inside the open inner bracket. A loop that holds a loop shows its own round, counted from the run so far, and the inner loop shows its round. Selecting, moving and removing work on the whole group: removing an outer loop removes the inner one.
- **Breadcrumb sensors.** When the level offers `MARK`, tapping a selected If header cycles through nine sensors: CLEAR, then FRESH (shown as NEW), then BACK, each ahead, left and right. The header reads IF over an icon and the side word: an arrow for CLEAR, an arrow ending at an empty square for NEW, a dot with an arrow leaving it for BACK. On a compact tile (no icon) the family word is a line of its own (NEW or BACK) so the sensor is always readable as text.
- **Else if.** While an If is open on its else branch and the else holds no command, an **Else if** tile appears beside Else. It starts an If in the else (sensor ahead, selected) that opens on its then branch; Else inside it switches that If to its own else, and End if closes the innermost If together with the chain that leads to it. A chain holds up to six Ifs. The tape draws the whole chain inside the bracket of its first If: the first header, its then tiles, then an ELSE IF header (the word ELSE IF over the sensor) with its then tiles, and so on, with no ELSE divider before an ELSE IF; the last If may have a plain ELSE divider and else tiles. An ELSE IF header is a slot like any header. Removing an ELSE IF header removes everything after it in the chain.
- **Breadcrumbs on the board.** A cell with a breadcrumb shows an ink arrow that points to the cell it leads back to, in place of the trail marker. Breadcrumbs appear step by step as the run is shown and are static (no animation), so Reduce motion changes nothing.
- **Visit every cell.** A board whose goal is `visit_all` has no target ring. Cells the automaton has entered carry the trail tint and marker, so what is left is the plain floor. The status area shows "12 / 30 CELLS" under the command counter while building and running. The objective reads VISIT EVERY CELL while building; a failure that ends with cells left says so ("Cells left: 3"), after the usual text for a program that ended or ran too long. A level with test boards may mix goals: each board draws and counts by its own goal.
- A level that offers `INC` or `MARK` or has a `visit_all` goal needs a game version that knows the mechanics `counter`, `markers` and `visit_all`; `nested_loops` is listed by the level. An older game refuses such a level like any other mechanic it does not know.
- The how-to-play screen explains the counter, loops in loops, breadcrumbs with else-if chains, and the sweep goal.

### 3.3 Deterministic simulation

- Commands execute in a defined order.
- Walls, board boundaries, and blocked movement follow consistent rules.
- Each run starts from the exact level-defined initial state.
- Reset restores the initial state and rewinds simulation feedback.
- The simulation has a maximum step/instruction budget to prevent accidental infinite runs.
- The simulation engine is independent from animation and UI code so it can be unit-tested.

The simulation must not depend on animation frame rate, network latency, or wall-clock time. Animations display simulation events; they do not define game logic.

### 3.4 Win and failure states

Each level defines its goal condition. For the initial version, reaching the goal tile is enough unless a specific level introduces another already-supported goal rule.

Possible result states:

- **Solved:** Goal condition reached.
- **Blocked:** A move into a wall or outside the board stops the run. This is a failure.
- **Program ended:** All commands executed without reaching the goal.
- **Instruction budget reached:** The safety limit was hit.
- **Invalid level:** Level data failed validation; this is a content/runtime error, not a player failure.

For a failure, give a concise explanation and offer **Try Again**. Never expose raw API errors or stack traces to players.

### 3.5 Level selection and progression

- Navigation is worlds, then a world screen showing its chapters with their level tiles. Show level number, completion status, and an optional difficulty label.
- Start with a small, curated campaign rather than a huge catalog.
- Unlock levels sequentially along the flattened campaign order (world, chapter, level); the progression rule is simple and consistent.
- Distinguish solved, current, locked, and not-downloaded levels and worlds.
- Allow completed levels to be replayed.
- Store completion and best result locally first (offline-first). Progress syncs to the cloud when the player signs in and is online; see [README_GAME_RULES.md](README_GAME_RULES.md).
- When a newer published version changes a level, preserve progress safely; do not silently reinterpret a stored score against a different level version.

### 3.6 Hints and onboarding

- Teach the controls interactively in the first few levels.
- Introduce one new concept at a time.
- Give optional hints in plain language, stored as level data.
- A hint should point the player toward the relevant idea rather than automatically solve the puzzle.
- Hints are optional and never required to make the game playable.

### 3.7 Audio, motion, theme, and feedback

The look of all screens, the tape, and the board is defined in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md); the screens are listed in [design/SCREENS.md](design/SCREENS.md).

- Provide a sound toggle and respect device mute settings.
- Use subtle audio/visual feedback for command placement, movement, blocked actions, and puzzle completion.
- Provide a reduce-motion setting that also respects the system setting; with it on, the tape and automaton jump instead of sliding.
- Provide a run-speed setting (slow, normal, fast).
- Provide a theme setting: system (default), light, or dark. Both themes are first-class and every screen exists in both.
- Provide a vibration (haptics) toggle and separate sound and music toggles.
- Never make sound necessary to understand whether an action succeeded.

### 3.8 Remote level content

The game should:

- Fetch the published level catalog from the API.
- Fetch a level's published version when the player opens it, or use a cached copy.
- Cache successful responses and include schema/version metadata.
- Display loading, retry, offline, and empty states.
- Validate critical fields before trying to build a board from remote data.
- Avoid replacing a valid cached level with an invalid response.
- Never download or execute arbitrary scripts as level content.

If the service is unavailable, previously downloaded and bundled levels should remain playable. Newly published levels naturally require a successful fetch at least once.

### 3.9 Daily, profile, boards, badges, and sharing (needs an account and a connection)

These screens exist in the Android game only. The browser try-out is offline-only and hides all of them, like the account. The game stays fully playable offline; each of these says plainly when it is offline. The server is the authority for everything below; the game shows what it is told (see [README_SOCIAL_PLAN.md](README_SOCIAL_PLAN.md)).

- **Daily.** Home has a DAILY link. The screen shows today's UTC date, the level's name, difficulty, par and limit, the player's result and streak (current and best, in words), one primary Play action, a secondary link to the day's board, and the next days as plain text. Play opens the existing play screen in daily mode: the title is "DAILY 2026-10-20", there is no Next, Back returns to Daily, and the solved screen offers Share and Ranking. The schedule (`GET /daily`) and each level are kept in `user://daily.json` and `user://daily_content`, so today and the next three days play offline. "Today" is the server's date while the last refresh worked, otherwise the device's UTC date. Daily-pool levels are never part of the campaign and never touch campaign progress.
- **Sending a daily result.** A solve is queued per date (the fewest commands wins) in `PlayerResults`, and `ProgressSync`, still the only uploader, sends it with `dailyDate` at the next sync. Signed out, nothing is sent and the queue waits. A refused result is dropped; a lost connection keeps it. The streak and badges in the answer are kept for display.
- **Profile.** Display name, two ON/OFF rows (Show me on leaderboards, Hide my name), the rank with points and the next rank, and Save. The server's reason for a refused name is shown as it is. A link leads to Badges. Account links to Profile, Badges and Leaderboard.
- **Badges.** Every badge: earned ones solid with a check and the date, locked ones outlined with a lock and the word LOCKED. Badges earned by a sync are named once, in one plain line, on the next Account or Badges screen; there is no notification system.
- **Leaderboard.** One screen for the points board (ALL TIME, WEEK, MONTH), a level's board, and a day's board. Rows show rank, name, and points or "commands / steps". The player's own row is a solid tile with a YOU tag; when it is not on the loaded page, the rows around it follow under "YOUR PLACE". MORE loads the next page. Another player's row has a small REPORT action that asks first and sends the name to moderators. A signed-out player is told boards need an account; a player who is not on the board is told how to appear.
- **Share.** The solved screen's Share copies a plain card ("Algomind daily 2026-10-20: 7 commands, par 5." or "Algomind, level 9 Around the wall: 10 commands, par 10."), no emoji and no solution. Signed in and online, it asks the server for a link and puts it on the next line; otherwise it copies the card alone. The button reads COPIED for two seconds. The Android system share sheet needs a plugin and is not used: sharing is copy only. Ranking opens the level's board, or the day's board for a daily.
- **Stars on tiles.** A solved level's tile on the world screen shows one to three stars (solid for earned, outline for not) and the accessible name says "3 stars". They come from the server's answer when a sync has reported it, otherwise from the best result on the device scored against the bundled par with the same scoring mirror the solved screen uses.

## 4. Level content model

Each level should be described by data, not a special scene or hardcoded `if level_id == ...` branch.

Minimum fields:

- `id`: stable identifier.
- `slug`: human-readable stable URL/key.
- `title` and `description`.
- `schemaVersion`: version of the level-data contract.
- `levelVersion`: version of the published content.
- `difficulty`. (Campaign placement is separate data: world, chapter, and order.)
- `board`: width, height, and cell/entity data.
- `initialState`: starting position and orientation.
- `availableCommands`: commands the player may use.
- `constraints`: optional command or step limits.
- `goal`: structured goal definition.
- `hints`: optional ordered hint text.

Detailed shape and API rules are specified in `README_ARCHITECTURE.md`. Levels are authored in the admin dashboard; its controls are based on supported fields, and validation must happen on both the server and the game client. Authoring content also carries a reference solution (never sent to players) and a `requires.mechanics` list so a client can tell whether it can play a level.

## 5. Scoring

### MVP recommendation

Use a simple completion result first. Record whether the level was solved and which published level version was played. Avoid designing a complex rating system before playtesting the core game.

### Possible later scoring

- A medal or star for completion.
- Optional bonus for staying under a command budget.
- Optional bonus for using fewer steps.

If score rankings are later introduced, define the scoring formula explicitly and version it. Do not compare results across incompatible level versions without a clear policy.

## 6. Future features — only after the core game works

Potential additions, in priority order:

1. More board mechanics (for example, switches, doors, pushable objects, or conveyors) after each mechanic is implemented and tested in the engine.
2. More nuanced goals, such as collecting an item before reaching the exit.
3. Optional accounts and cloud progress sync (local-first; designed for from the start).
4. Leaderboards for a clearly defined challenge mode.
5. Daily or weekly puzzles.
6. Community levels, moderation, and sharing.

Each new mechanic should include a rule definition, visual representation, tutorial/teaching plan, deterministic simulation behavior, unit tests, and compatibility decision. A dashboard toggle alone cannot safely introduce a mechanic the client does not understand.

## 7. Explicit non-goals for MVP

- Multiplayer or player-versus-player features.
- Ads, in-app purchases, subscriptions, or an economy.
- Player-generated content marketplace.
- Cloud-synced save states required to play.
- Procedural generation as a substitute for curated puzzle design.
- Open-ended scripting or downloading executable game logic.

## 8. Gameplay acceptance checklist

- [ ] A new player can understand movement and the goal from the first levels.
- [ ] Every run begins from the same initial state.
- [ ] Commands can be added, removed, and reordered reliably on touch screens.
- [ ] Run, step, pause/resume, reset, success, and failure states work predictably.
- [ ] A level can be represented entirely as data.
- [ ] The client can load a valid bundled level and a valid remote level.
- [ ] Invalid remote data fails safely and does not crash the game.
- [ ] Previously downloaded levels remain available during a temporary network outage.
- [ ] Level completion and progression survive app restart.
- [ ] Every shipped level has been solved in playtesting and has clear instructions/hints where needed.
