# Algomind — Game Rules & Progress Specification

> **Purpose:** The authoritative definition of how Algomind plays, how a program executes, how progress is saved and synced, and how levels are published. Other docs link here instead of repeating rules.  
> **Status:** Core decisions settled (see below). Details marked _later_ are intentionally deferred.

## Decisions at a glance

| Topic                | Decision                                                                                 |
| -------------------- | ---------------------------------------------------------------------------------------- |
| Core concept         | Visual programming puzzle: build a program, run it, debug it                             |
| First command set    | `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`                                                |
| First board cells    | Floor, Wall, Goal                                                                        |
| First win condition  | Reach the goal cell                                                                      |
| Wall or boundary hit | Execution stops and the run fails, with a clear explanation                              |
| Orientation          | Portrait-first; landscape later                                                          |
| Progress             | Local-first and offline-first; syncs to the cloud when the player signs in and is online |
| Accounts             | Optional; never required to play                                                         |
| Level delivery       | Published from the dashboard; no app rebuild for compatible levels                       |
| Production URLs      | Vercel (web) and Render (API) default URLs, known after the first deployment             |

## 1. Core game concept

Algomind is a programming puzzle game where players construct a program from visual instructions, run it, and guide an automaton to complete each level.

The player does not control the character with a joystick. Instead, they think like a programmer: plan instructions, execute them, observe the outcome, debug mistakes, and try again.

The game teaches computational thinking through play, introducing algorithmic concepts gradually. It must not require players to know programming before playing.

## 2. Core gameplay rules

Each level contains:

- A board with traversable spaces and obstacles.
- An automaton with a starting position and direction.
- A goal the automaton must reach.
- A set of available commands.
- A maximum program size (command budget) and a maximum execution-step limit.
- Optional challenge criteria, such as solving the level with fewer instructions.

### Gameplay loop

1. Open a level and understand the objective.
2. Construct a program by arranging commands.
3. Press Run to execute the program.
4. Watch the automaton perform each instruction.
5. Inspect the outcome.
6. Edit the program and retry if necessary.
7. Complete the level and unlock the next one.

There are no lives, energy systems, or timers.

### Determinism

The simulation is deterministic: the same level and the same program always produce the same outcome and the same step trace. It never depends on animation, frame rate, network, or wall-clock time. The reference simulator (TypeScript) and the game's simulator (GDScript) must agree on every shared fixture; see [README_ARCHITECTURE.md](README_ARCHITECTURE.md).

### Initial board mechanics

Start with three cell types:

- **Floor:** the automaton can move onto it.
- **Wall:** blocks movement.
- **Goal:** reaching it completes the level.

For the first version, reaching the goal completes the level. Do not introduce switches, doors, hazards, moving platforms, or collectibles until the basic gameplay is reliable.

## 3. Command set

Players build programs from a visual command palette, not a text editor. They select and arrange instructions.

### Initial commands

| Command        | Behavior                                                |
| -------------- | ------------------------------------------------------- |
| `MOVE_FORWARD` | Move one cell in the direction the automaton is facing. |
| `TURN_LEFT`    | Rotate 90 degrees counterclockwise without moving.      |
| `TURN_RIGHT`   | Rotate 90 degrees clockwise without moving.             |

These three commands are sufficient for the first levels and establish the core programming concept.

### Added after the basics work

| Command            | Behavior                                               |
| ------------------ | ------------------------------------------------------ |
| `REPEAT(n)`        | Execute a nested sequence a specified number of times. |
| `IF_FRONT_BLOCKED` | Execute a branch if the cell ahead is blocked.         |
| `INTERACT`         | Activate a supported object, such as a switch.         |

Do not implement these all at once. Introduce each command only when the level design has a reason to teach it. Each one requires a rule definition, visual treatment, tutorial level, deterministic simulation behavior, shared fixtures, tests, and a client-compatibility decision (a new command needs a client release; see section 9).

### Program rules

- Players can add, remove, and reorder commands.
- Each level defines its available commands and its program-size limit.
- The current instruction is highlighted during execution.
- Players can run, pause, step through, and reset a program.
- If the program ends without reaching the goal, the level remains incomplete.
- If the automaton tries to move into a wall or outside the board, execution stops with a clear explanation. This is a failure.
- A maximum execution-step limit prevents infinite or unexpectedly long programs.
- Invalid commands are never silently ignored.
- A `REPEAT` counts as one slot plus one slot for each instruction in its body (section 3.1), so the command limit bounds the whole program.

### Program representation

A program is an ordered list of instruction nodes (not bare strings), so `REPEAT` and `IF_FRONT_BLOCKED` can contain nested instructions later without breaking the level format. The same representation is used by the player's program, the reference solution, and the shared fixtures.

### 3.1 REPEAT

> **Status:** built (contract, both simulators, the editors, the Loops world). Original note: The par search was prototyped and measured (bodies up to 8 instructions on boards up to 12 by 12 solve in 3 to 70 ms; allowing a loop inside a loop costs 0.4 to 1.8 s for little gain). Nothing in the contract, either simulator, the editor, or the game implements it yet.

A program node is either a primitive (`MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`) or a loop:

```json
{ "op": "REPEAT", "count": 6, "body": [{ "op": "MOVE_FORWARD" }, { "op": "TURN_RIGHT" }] }
```

- **Body:** one to 8 primitive instructions. A loop cannot contain a loop in version 1. Nesting would be a separate mechanic (`nested_repeat`) with its own client release.
- **Count:** a whole number from 2 to 11. One repetition is just the body, and 11 is the most that can matter on the largest board (12 cells a side).
- **Availability:** a level lists `REPEAT` in `availableCommands`. The mechanic `repeat` is derived from that (the API adds it to the required mechanics), so a client that does not declare `repeat` shows the update screen for that level and never starts it. A loop in the program of a level that does not list `REPEAT` is a content error, never silently skipped.
- **Slots (the command limit):** a primitive is 1. A `REPEAT` is 1 plus the number of instructions in its body. `maxCommands` limits the total. `REPEAT 6 { MOVE_FORWARD, TURN_RIGHT, MOVE_FORWARD, TURN_LEFT }` is 5 slots.
- **Steps:** each executed primitive is one step, as before. The `REPEAT` node itself costs no step. The step limit is checked before every primitive, including inside the loop.
- **Reaching the goal:** the run succeeds the moment the automaton enters the goal, even in the middle of an iteration or of a loop. The rest of the program does not run and is not counted. A body or iteration may therefore be left unfinished.
- **Failure:** a blocked move inside a loop stops the run. The failing tile is the body instruction that was blocked. The message and the tape also show the iteration ("Round 3 of 6").
- **Par:** the fewest slots of any program that solves the level, searched exactly over loop bodies of up to 8 instructions. The solver is TypeScript only (the API publish gate and the dashboard); the game never needs it. The reference solution may use `REPEAT`.
- **Why the metric is slots, not steps:** a loop that repeats a body costs 1 plus the body, whatever the count. A long straight corridor is cheap (`REPEAT 9 { MOVE_FORWARD }` is 2 slots), so a level only needs an algorithm when its structure repeats in a way a plain run of moves cannot capture (stairs, notches, repeated rooms).

**Level design rules for loop levels** (checked by the candidate generator, and by the publish gate where it can be checked mechanically):

1. **Loop par below flat par:** the shortest program without `REPEAT` must be larger than `maxCommands`, so a loop is required, not merely allowed.
2. **The limit sits at or just above loop par.** The intended pattern must fit; the corridor shortcut must not.
3. **No accidental shortcuts:** cells on a corridor must not touch another part of the path, or the board solves with a plain run. The solver finds these (a "teeth" candidate with flat par 6 and loop par 2 was caught this way).
4. **Check par with the solver, never by eye.** On open boards the solver finds patterns the author did not intend (a free 10 by 10 board was solved by `REPEAT 9 { M R M L }`).

**Editing:** the palette gains a Repeat tile. Tapping it appends a group with a count of 2 and an empty body that takes the next tapped commands until it is closed; the count is changed with minus and plus tiles on the group. A group is drawn as a count tile followed by its body tiles inside one outlined bracket (dashed while the loop is open). While a loop is open the Repeat tile reads End loop and works once the body has a command; a loop with an empty body is not a program, so Run and Step stay off and the message says to add a command. The limit counter counts slots, one per tape cell. While a program runs, the count tile shows the round ("2/6"); when a run fails inside a loop the X sits on the blocked body tile and the count tile shows the round it failed in. Visual rules are in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md) (to be updated when this is built).

### 3.2 REPEAT_UNTIL (Until)

> **Status:** built (contract, both simulators, the dashboard and game editors, the Until world).

A conditional loop, the second loop node:

```json
{ "op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [{ "op": "MOVE_FORWARD" }] }
```

- **Condition:** `until` is `BLOCKED`, true when a wall or the board edge is straight ahead of the automaton. It is the only condition in version 1 (`IF` sensors in the Decisions world add more, as separate data).
- **When it is checked:** before every round, never in the middle of one. The body runs again only while the condition is false, so a loop whose way ahead is already blocked runs its body zero times, and a loop ends the first time a round starts blocked. The check costs no step and no slot.
- **Body:** one to 8 primitives, as for `REPEAT`. A loop cannot contain a loop of either kind (`NESTED_REPEAT`). There is no `count`; a `count` is an unknown field.
- **Availability:** a level lists `REPEAT_UNTIL` in `availableCommands`. The mechanic `repeat_until` is derived from that, as for `repeat`.
- **Slots and steps:** 1 plus the body for the slots; each executed primitive is one step; the loop node costs none. The step limit is checked before every primitive, which is what stops a loop that is never blocked (a body of only turns): the run fails with the step-limit outcome.
- **Reaching the goal** inside the loop succeeds at once, as in `REPEAT`. A failure in the body sits on that body node, and the trace carries the 1-based round.
- **Par:** the solver adds `REPEAT_UNTIL(BLOCKED, body)` edges for every body, after the counted loops of the same body, and only when `REPEAT_UNTIL` is offered; ties go to the counted loop.
- **Why it matters:** the loop does not need the distance. `REPEAT_UNTIL BLOCKED { MOVE_FORWARD }` runs any corridor to its end, so one program serves boards of every size, which is the point of the Generalize world (generalize).

**Level design rules for the Until world:**

1. A level offers `REPEAT_UNTIL` and not `REPEAT`, so the player learns the condition, not a count to measure.
2. Flat par must be above the limit and `REPEAT_UNTIL` par at or below it, as for loops.
3. Corridors are long (7 to 12 cells) and their lengths are never needed: the point is turning at the wall, so the player reads the shape, not the distance.
4. The goal is at a corner or a dead end, or beside the end of a corridor, never in the middle of a run (a loop would pass through it and the level would teach nothing).

**Editing:** the palette gains a Repeat until tile beside Repeat when a level offers it. A group shows "UNTIL BLOCKED" instead of a count, with no plus and minus tiles; the body is built as for Repeat. While it runs, the group shows the round. Visual rules are in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md).

### 3.3 IF and the sensors (Decisions)

> **Status:** built (contract, both simulators, the dashboard and game editors, the Decisions world).

A decision node, the third kind of instruction:

```json
{ "op": "IF", "when": "CLEAR_RIGHT", "then": [{ "op": "TURN_RIGHT" }], "else": [] }
```

- **Sensors** (`when`): `CLEAR_AHEAD`, `CLEAR_LEFT`, `CLEAR_RIGHT`. A sensor is true when the cell on that side of the automaton (straight ahead, or one quarter turn left or right of its facing) is on the board and not a wall. Reading a sensor costs no step and no slot. A sensor does not see the goal as different from floor.
- **Branches:** `then` holds 1 to 4 primitives and `else` holds 0 to 4 (`else` is always present, and may be empty). The `then` branch runs when the sensor is true, the `else` branch when it is false. An `IF` cannot contain an `IF` or a loop (`NESTED_IF` for an `IF`, `NESTED_REPEAT` for a loop).
- **Where it may stand:** at the top level of a program, or as an item of a loop body (the body of `REPEAT` and `REPEAT_UNTIL` is 1 to 8 items, each a primitive or an `IF`). A loop still cannot contain a loop.
- **Slots:** an `IF` is 1 plus the primitives in `then` plus the primitives in `else`. A loop is 1 plus the slots of its body items. `maxCommands` bounds the sum.
- **Steps:** each executed primitive is one step. Choosing a branch is free. The step limit is checked before each primitive.
- **Trace:** the trace `node` of a primitive inside an `IF` is `[i, k]` at the top level and `[i, j, k]` inside loop `i`, body item `j`, where `k` counts the `then` primitives first and the `else` primitives after them. `round` is the loop's round, as before.
- **Availability:** a level lists `IF` in `availableCommands`; the mechanic is `if`.
- **`REPEAT_UNTIL` gains a second condition:** `until` is `BLOCKED` or `GOAL`. `GOAL` is never true at the start of a round (the run ends the moment the goal is entered), so the loop runs until the goal is reached, a move fails, or the step limit stops it. It is how a program with a decision keeps going.
- **The right-hand rule** in two decisions, the algorithm the Decisions world teaches: `REPEAT_UNTIL GOAL { IF CLEAR_RIGHT { TURN_RIGHT }, IF CLEAR_AHEAD { MOVE_FORWARD } else { TURN_LEFT } }` is 6 slots. In a maze whose walls are all joined to the outer wall, it reaches every cell, so it reaches the goal.
- **Par:** the exact search does not cover `IF` (the number of programs is too large). For a level that offers `IF`, par is the slots and steps of its reference solution, which must solve the level; the publish gate also runs the exact solver with `IF` removed, and the level is accepted as needing `IF` only when that best program does not fit `maxCommands`. The solver in the package ignores `IF`.

**Level design rules for the Decisions world:**

1. The limit equals the slots of the reference solution, and the best program without `IF` does not fit it (by at least 1.5 times).
2. Corridor levels come first (one decision), maze levels after (the right-hand rule).
3. Mazes are simply connected (every wall joined to the outer wall), so the right-hand rule is guaranteed to finish; `maxSteps` is at least twice the steps of the reference run.

**Editing:** the palette gains an If tile. Tapping it opens an `IF` group with the sensor `CLEAR_AHEAD`; tapping the sensor tile on the group cycles through the three sensors. The next tapped commands go to the `then` branch; the palette's Else tile switches to the `else` branch; End if (the If tile while a group is open) closes it. Inside an open loop an `IF` is one of its items; at most one `IF` and one loop are open at the same time, and the loop closes last. An `IF` with an empty `then` is not a program.

### 3.4 PROC and CALL (Procedures)

> **Status:** built (contract, both simulators, the dashboard and game editors, the Procedures world).

Two more nodes. A procedure is a named piece of program, defined once and run from several places:

```json
{ "op": "PROC", "name": "A", "body": [{ "op": "MOVE_FORWARD" }, { "op": "TURN_RIGHT" }] }
{ "op": "CALL", "name": "A" }
```

- **Names:** `A`, `B`, or `C`. A name is defined at most once (`DUPLICATE_PROCEDURE` at the later `name`), and a `CALL` to a name no `PROC` defines is `UNDEFINED_PROCEDURE`. A `CALL` may come before the definition in the list.
- **Where they stand:** a `PROC` only at the top level (`NESTED_PROC` elsewhere). A `CALL` at the top level or as an item of a loop body of the main program. A procedure cannot call a procedure unless the level lists the mechanic `recursion` (3.16), so a `CALL` inside a `PROC` body, inside an `IF` branch, or inside a loop that stands in a procedure is `CALL_NOT_ALLOWED`; with the mechanic a `CALL` may stand directly in a procedure body.
- **A procedure body:** 1 to 8 items, each a primitive, an `IF`, or a loop (`REPEAT` or `REPEAT_UNTIL`, with the bodies and rules they already have; a loop still cannot hold a loop).
- **Running:** a `PROC` is not run where it stands. The main program is the other top-level nodes in order; a `CALL` runs the body of the first `PROC` of that name and then goes on. A `PROC` costs no step and a `CALL` itself costs none.
- **Slots:** a `CALL` is 1; a `PROC` is 1 plus the slots of its body items. The whole program, definitions included, is bounded by `maxCommands`. Reuse is what pays: a six-instruction procedure used three times costs 7 + 3 slots instead of 18.
- **Trace:** a primitive run inside a procedure has `node` `[p, j, ...]`, where `p` is the index of the `PROC` in the program and the path goes on as if the `PROC` were a loop. Every trace entry has `call`: the path of the `CALL` that is running it, or `null` in the main program. `round` is the round of the innermost loop the instruction stands in (null for a procedure's own top-level items).
- **Availability:** a level lists `PROC` in `availableCommands`; that offers both the definition and the call. The mechanic is `procedures`.
- **Par:** as for `IF`, the exact search does not cover procedures. Par for a level that offers `PROC` is the slots and steps of its reference solution. The publish gate also runs the exact solver without `PROC`, and the level is accepted as needing procedures only when that best program does not fit `maxCommands`.

**Level design rules for the Procedures world:**

1. The idea is a shape that comes back at uneven intervals: the same sequence of moves and turns appears three or four times along the route with different runs between, so a counted loop cannot say it once but a named procedure can.
2. The limit is the slots of the reference solution, and the best program without procedures is at least 1.3 times the limit.
3. Levels offer `REPEAT` and `PROC` (not `REPEAT_UNTIL` and `IF`), so the player decomposes the route and does not solve it with a wall follower.
4. Later chapters use two procedures (`A` and `B`) and a procedure that contains a loop.

**Editing:** the palette gains a Proc tile. Tapping it starts the next free name (A, then B, then C) as a definition group drawn at the top of the tape with its name; tapped commands go into it until the tile (now reading End proc) is tapped. While no definition is open, each defined name has a Call tile that appends a call to the main program. The main program is drawn below the definitions. A definition with an empty body is not a program.

### 3.5 Test boards (Generalize)

> **Status:** specified 2026-10-21; the contract and the game (validator, simulator, board tabs on the play screen) are built; the editor and the API still follow.

A level may carry more than one board, and one program must solve all of them. Nothing changes in how a board is run; what changes is what solving a level means.

```json
{
  "...": "the level's own board, initialState and goal as always",
  "extraBoards": [
    {
      "board": { "width": 9, "height": 3, "walls": [] },
      "initialState": { "position": [0, 1], "direction": "east" },
      "goal": { "type": "reach_tile", "position": [8, 1] }
    }
  ]
}
```

- **Shape:** `extraBoards` is optional and holds 1 to 5 test boards. Each has the same three fields as the level's own board (`board`, `initialState`, `goal`) and the same rules (size, walls, start and goal on the board and not on a wall). Everything else (commands, `maxCommands`, `maxSteps`, hints) is the level's and is shared. Issue paths are prefixed, for example `extraBoards[0].goal.position`.
- **Running:** a program is run on every board, the level's own first. `simulateAll` returns one result per board, whether the level is solved (every board `SUCCEEDED`), the index of the first board that failed (0 is the level's own board), and the sum of the steps. `maxSteps` limits each run, not the sum.
- **Slots and par:** slots are counted once, as for any program. Par is the reference solution's slots and its **total** steps over all boards (the exact solver covers one board only, so par for a level with test boards is the reference solution, as for `IF` and `PROC`).
- **Why it exists:** a program that works because of one board's measurements (move exactly seven times) fails on the next board. The only programs that pass are the ones that ask the board (until blocked, if clear) instead of counting.
- **Availability:** the mechanic `multi_board` is derived by the API from the content (a level with `extraBoards` requires it), so a client that cannot show several boards never starts such a level.
- **Gates:** the reference solution must solve every board, and the publish gate runs the exact solver on the level's own board: if that best program already solves every other board within the limit, the level does not need an algorithm and is flagged (`BOARDS_NOT_REQUIRED`, a warning).
- **Playing:** the board area shows one board at a time with one tab per board (BOARD 1, BOARD 2, and so on). Run runs the program on the selected board. A board a program has solved shows a check (a shape and the word, never colour alone). The level is solved when the same program has solved every board; editing the program clears the checks. After a successful run the next unsolved board is selected. A failure names its board ("Board 2: the automaton tried to move into a wall").

**Level design rules for the Generalize world:**

1. Every level has 2 to 4 boards that differ in size and shape, never a rotation of one another.
2. The limit is the slots of the reference solution, and the best program for the first board alone must fail on at least one other board (the `BOARDS_NOT_REQUIRED` check).
3. Levels offer every tool of worlds 1 to 6, so the player chooses the right one (a loop to the wall, a decision, a procedure) and not a new one.
4. Early levels use boards that differ only in length or size; later ones use boards with different shapes where the right-hand rule or a loop with a decision is needed.

### 3.6 Counters and nested loops (Counters)

> **Status:** built (contract, both simulators, the dashboard and game editors, the levels of this world).

Two additions that belong together: a loop inside a loop, and one counter that a loop can use.

- **The counter `N`.** A run starts with `N = 1`. The instruction `{ "op": "INC" }` adds one (it stops at 11, the most a loop can use). `INC` is an action like a turn: one slot, one step, and the trace entry (`event` `COUNTED`) does not move the automaton. A level offers it by listing `INC` in `availableCommands`; the mechanic is `counter`.
- **A loop that counts with `N`.** A `REPEAT` takes `"count": "N"` instead of a number. The loop reads `N` when it starts and runs that many rounds (1 to 11), whatever happens to `N` inside it. It needs `INC` offered (`COMMAND_NOT_AVAILABLE` at `.count` otherwise).
- **Trace.** Every trace entry has `counter`: the value of `N` after the step.
- **Loops in loops.** A loop body may hold one loop, which may not hold another (two levels at most, in the main program and inside a procedure alike). A level allows it by listing the mechanic `nested_loops` in `requires.mechanics`; without it a loop inside a loop is `NESTED_REPEAT`, as before, and so is a third level. Slots are recursive: a loop is 1 plus the slots of its body items. In the trace, a primitive in an inner loop has `node` `[i, j, k]` (loop `i`, body item `j` is the inner loop, item `k` of its body) and `round` is the **inner** loop's round.
- **Par:** the exact solver reads neither the counter nor nesting, so par for a level that offers `INC` or `nested_loops` is its reference solution, as for `IF`, `PROC` and test boards.

**Level design rules for the Counters world:** the idea is a number that changes: shapes that grow (a spiral outward, a widening staircase, triangles). The limit is the reference solution's slots; the best program without the counter and nesting is at least twice the limit.

### 3.7 Breadcrumbs and the Tremaux search (Memory)

> **Status:** built (contract, both simulators, the dashboard and game editors, the levels of this world).

The board remembers what the automaton leaves on it. This is what lets a program explore a maze that has loops and still finish.

- **Breadcrumbs.** The instruction `{ "op": "MARK" }` drops a breadcrumb on the cell the automaton stands on: an arrow that points to the cell **behind** the automaton, which is the cell it came from when it has just stepped forward. A cell that already has a breadcrumb keeps it (marking twice changes nothing). `MARK` is an action: one slot, one step, trace `event` `MARKED`. A level offers it by listing `MARK` in `availableCommands`; the mechanic is `markers`.
- **Breadcrumb sensors** for `IF.when`, each about the cell ahead, to the left, or to the right: `FRESH_AHEAD`, `FRESH_LEFT`, `FRESH_RIGHT` (a floor cell with no breadcrumb) and `BACK_AHEAD`, `BACK_LEFT`, `BACK_RIGHT` (the cell on that side is the one **this** cell's breadcrumb points to: the way back). A wall, the board edge and a cell with a breadcrumb are not fresh; a cell is `BACK` only for the cell the arrow on the automaton's own cell points at. Reading a sensor is free. They need `MARK` offered (`COMMAND_NOT_AVAILABLE` at `.when`).
- **Else-if chains.** The `else` of an `IF` may hold one `IF` (and nothing else) instead of actions, so one decision can choose between many cases: `IF a { .. } ELSE IF b { .. } ELSE { .. }`. A chain may be up to 6 `IF`s long; an `IF` inside `then`, or an `else` that mixes an `IF` with actions, is `NESTED_IF`. Slots: an `IF` is 1 plus its `then` actions plus the slots of its `else` (the actions, or the nested `IF`). A trace path goes into the nested `IF` after the index `then.length`.
- **In the trace:** `MARKED` entries mark where breadcrumbs were dropped (a repeated `MARK` on a marked cell is still a `MARKED` step). The arrow itself follows from the entry before it: it points to the cell the automaton was on one step earlier, unless the automaton had turned in place.
- **The Tremaux search** (the algorithm the Memory world teaches): mark the cell, step onto a fresh cell ahead, else right, else left; when none is fresh, follow the breadcrumb back (ahead, right, left, and the cell behind when none of those is the way back). A cell is entered fresh at most once and the way back is always known, so the search cannot go round a loop for ever and it reaches every cell it can. As a program: `REPEAT_UNTIL GOAL { MARK, IF FRESH_AHEAD { Move } ELSE IF FRESH_RIGHT { Right, Move } ELSE IF FRESH_LEFT { Left, Move } ELSE IF BACK_AHEAD { Move } ELSE IF BACK_RIGHT { Right, Move } ELSE IF BACK_LEFT { Left, Move } ELSE { Right, Right, Move } }`, 21 slots. (Tremaux's original marks passages with up to two marks. This is the same search written with one breadcrumb per cell; in a trial on 300 random mazes with loops, the two-mark version that marks cells instead of passages went round for ever in 30 of them and this one finished all 300.)
- **Par** is the reference solution (the exact solver reads no breadcrumbs).

**Level design rules for the Memory world:** boards have loops (a wall follower circles for ever on them), the goal is not on the outer wall, and the reference solution solves every board of the level. Limits up to 24 slots are allowed in this world (the Tremaux search is 21), because the tape scrolls and the search is the point of the world. Early levels are small enough to follow the breadcrumbs by eye.

### 3.8 Visit every cell (Sweep)

> **Status:** built (contract, both simulators, the dashboard and game editors, the levels of this world).

A second kind of goal, `visit_all`:

```json
"goal": { "type": "visit_all" }
```

- **Meaning:** the run succeeds the moment every floor (non-wall) cell of the board has been entered or started on. The start cell counts from the start. The goal has no `position` (a `position` is an unknown field). Reason and event are `GOAL_REACHED`, as for a target.
- **Validity:** the board must have at least two floor cells (`GOAL_EQUALS_START` is reported at `goal` for a board whose only floor cell is the start). Cells the automaton can never reach make a level unsolvable; the publish gate catches that because the reference solution must solve the level.
- **Mixed levels:** a level's own board and each extra board choose their own goal type.
- **Par:** the exact solver does not search `visit_all`; par is the reference solution. `maxSteps` should scale with the board (about twice the reference run).
- **Counting in the game:** the board shows the visited cells and the counter reads "12 / 30 CELLS".

**Level design rules for the Sweep world:** the sweep is the lawnmower (run to the wall, step over, run back), which needs nested loops from the Counters world. Later boards have pillars and notches that make a plain lawnmower fail; the step limit is tight enough that wandering fails too.

### 3.9 Patrols (world 13)

A **patrol** (a guard) is an obstacle that walks a fixed route while the program runs. It makes timing part of a puzzle. It is taught in world 13 and reused as the closing chapter of later worlds ([README_WORLD_RESTRUCTURE_PLAN.md](README_WORLD_RESTRUCTURE_PLAN.md)). Built: the contract (types, both validators, both schemas, the reference and GDScript simulators, the solver), the API (`patrol` mechanic, par from the exact search), the game (guards on the flat and depth boards), and six levels.

A level may carry `patrols`, one to three of `{ pattern, cells }`.

- **Deterministic.** A patrol's cell depends only on the step number. There is no randomness, no frame rate, and no real time, so the same level and program always give the same result.
- **Patterns** (two). _back_and_forth_ walks a list of 2 to 12 cells to the end and back (a period of 2 (n - 1)); _loop_ walks a ring of 4 to 12 cells and starts again at the first (a period of n). A _blink_ pattern (a cell blocked on some steps) was considered and left out until a world needs it.
- **Step.** Every action the automaton runs is one step: a move, a turn, `INC` and `MARK`. Every patrol moves one stop on every step. A turn is how the player waits, and two turns (left, then right) wait two steps; a wait of an odd number of steps needs a route with an odd number of turns, which is why some boards cannot be solved by waiting alone.
- **Collision.** After a step, the run fails with `HIT_BY_PATROL` when a patrol stands on the automaton's cell, or when they swapped cells in that step. The check comes before the goal: a guard on the target beats the target. The trace entry carries the automaton's position after the action, and `blockedCell` is the cell of the meeting.
- **Validation.** The route uses floor cells inside the board, never the automaton's start cell for its first stop, no cell twice, each stop next to the one before; a ring also closes (its last stop is next to its first). A level with test boards (`extraBoards`) cannot have patrols. Issue codes: `PATROL_ON_WALL`, `PATROL_ON_START`, `PATROL_CELLS_REPEAT`, `PATROL_NOT_CONNECTED`, `PATROLS_WITH_BOARDS`, plus the usual type and length codes.
- **Display.** Each route is drawn on the board as a thin line with a dot on every cell; the guard is a diamond with a ring and a dot (a shape no wall or automaton has). Guards move with the automaton, step by step, and jump without a tween under reduce motion. When one reaches the automaton the guard turns signal yellow, the failing instruction on the tape shows the failure cross, and the message reads A GUARD REACHED THE AUTOMATON. Not built: the "stop by step" strip.
- **Solver.** With patrols, the exact search is over (cell, facing, step) and goes layer by layer; a command that collides is skipped and the goal is tested after the collision check. It covers flat programs only; where a level offers loops, the reference solution sets par. A test checks the search against brute force.
- **Compatibility.** The mechanic is `patrol`. A client that does not declare it cannot play these levels, and the publish gate checks that.

**Level design rules for the Patrol world:** a level is solved by the exact search with its guards, and the shortest program without them must fail (a test checks this), so the guards always matter. The limit equals the exact par. Open boards teach going around a guard; a ring teaches waiting; the last chapter has two guards with different rhythms.

### 3.10 Start programs (the Debug world)

> **Status:** built (contract, both validators and their fixtures, the publish gate, the game's tape, five levels). Not built: authoring a start program in the dashboard (the editor keeps one that is already there, but cannot make or change it).

A level may carry `startProgram`, a program the tape starts with. It exists for levels about fixing a program: the player runs it, sees where it goes wrong, and changes it.

- **Format and checks.** It is a program like any other (the same node shapes), validated with the level's own limits: every command is known and offered, and it is no longer than `constraints.maxCommands` (issue codes `COMMAND_NOT_AVAILABLE`, `TOO_MANY_COMMANDS` and the others, with the path `startProgram[...]`). It may be empty. It is part of the public level, so a client that does not know the field refuses the level (`UNKNOWN_FIELD`), and the level names the mechanic `start_program`, so an app without it is not offered the level.
- **The publish gate.** The start program must **not** solve the level on every board (code `START_PROGRAM_SOLVES`, gate `start_program`); otherwise there is nothing to fix. The reference solution is the fix and must solve the level as for any level.
- **On the tape.** The game puts a copy of it on the tape, closed and with nothing selected; the player edits it like any program (add, remove, move, change a count). The objective reads FIX THE PROGRAM. Leaving and reopening the level starts again from the start program.
- **Limit and par.** The limit fits the start program and the fix, so it need not equal par; par is the best program there is (the better of the solver and the reference solution), as for other levels.
- **Level design rules for the Debug world:** one bug in a program of the shapes the player already knows (a count, a missing turn, a condition, a branch, a call); the failure message says what happened and never the fix; hints are progressive.

### 3.11 Keys and doors (world 14)

A level may carry `locks`, one to three pairs `{ key, door }`. Built: the contract (types, both validators, both schemas, both simulators, the solver), the API (`keys` mechanic), the game (keys and doors on the flat and depth boards), and six levels.

- **Picking up.** Entering a key's cell picks the key up. There is no command for it, and it costs nothing beyond the move. The trace event of that move is `KEY_TAKEN` instead of `MOVED`. A key is kept for the rest of the run, and it opens only its own door.
- **Doors.** A shut door blocks like a wall: moving into it ends the run with `BLOCKED_BY_DOOR` and `blockedCell` is the door. Once its key is held the door is an ordinary cell. For the sensors (`CLEAR_AHEAD` and the others) a shut door is not floor, so a loop that runs until blocked stops in front of it.
- **With guards.** Keys and patrols can share a level. The guard check comes first: a guard that meets the automaton on a key cell ends the run before the key is taken.
- **Validation.** Keys and doors lie on floor cells inside the board, never on the start or the target, and no two share a cell. Issue codes `LOCK_ON_WALL`, `LOCK_ON_START`, `LOCK_ON_GOAL`, `LOCK_CELLS_REPEAT`, `LOCKS_WITH_BOARDS` (not with `extraBoards`) and `LOCKS_WITH_SWEEP` (not with the visit-every-cell goal).
- **Display.** A key is a ring with a shaft and a tooth; a shut door is a block with a keyhole; an open door is an outline. With more than one lock, a key and its door carry the same number of pips, so the pairing is never only a color. The key disappears when taken and its door opens. The failing instruction is marked on the tape and the message reads THE AUTOMATON TRIED TO GO THROUGH A LOCKED DOOR. Not built: marking the shut door itself on failure.
- **Solver.** The exact search adds the keys held to the state (x, y, facing, keys, and the step when there are guards). Where a level offers loops, the reference solution sets par.
- **Compatibility.** The mechanic is `keys`.

**Level design rules for the Keys world:** the shortest program that ignores the keys and doors must fail (a test checks this), and the limit equals the exact par. Chapter one has one door and a key off the straight way; chapter two has two doors, where a key may lie between them; the last chapter adds a guard.

### 3.12 Delivery (world 15)

A level may carry `deliveries`, one to three pairs `{ item, dock }`. Built: the contract (types, both validators, both schemas, both simulators, the solver), the API (`delivery` mechanic), the game (crates and docks on the flat and depth boards), and six levels. It reuses the pickup rule of keys (3.11) and adds a drop.

- **Picking up.** Entering an item's cell with empty hands picks the item up. There is no command for it. The trace event of that move is `ITEM_TAKEN`. The automaton carries one item at a time: an item met while the hands are full is walked over and stays where it lies.
- **Dropping.** Entering the dock of the item being carried drops it there (`ITEM_DROPPED`) and the item is delivered. A dock accepts only its own item; any other dock, and any dock reached with empty hands, is an ordinary cell. There is no command for dropping and an item cannot be put down anywhere else.
- **The target.** The target counts only when every item is delivered. Entering it with an item left ends the run with `UNDELIVERED` (event `UNDELIVERED`; `blockedCell` is null and the final position is the target). The guard check still comes first.
- **With keys and guards.** Deliveries can share a level with `locks` and `patrols`; the cells of all three are different.
- **Validation.** Items and docks lie on floor cells inside the board, never on the start or the target, and no two (keys and doors included) share a cell. Issue codes `DELIVERY_ON_WALL`, `DELIVERY_ON_START`, `DELIVERY_ON_GOAL`, `DELIVERY_CELLS_REPEAT`, `DELIVERIES_WITH_BOARDS` (not with `extraBoards`) and `DELIVERIES_WITH_SWEEP` (not with the visit-every-cell goal).
- **Display.** An item is a crate: a solid square with a strap. A dock is four corner brackets, with the crate inside once delivered. The crate carried is drawn small on the automaton, in signal yellow. With more than one delivery, a crate and its dock carry the same number of pips, so the pairing is never only a color. The failing instruction is marked on the tape and the message reads THE AUTOMATON REACHED THE TARGET BEFORE EVERY ITEM WAS DELIVERED.
- **Solver.** The exact search adds what is carried and what is delivered to the state, and does not search a move into the target while an item is left. Where a level offers loops, the reference solution sets par.
- **Compatibility.** The mechanic is `delivery`.

**Level design rules for the Delivery world:** the shortest program that ignores the crates, doors and guards must fail (a test checks this), and the limit equals the exact par. Chapter one has one crate; chapter two has two (the second needs the first delivered, because hands hold one); the last chapter adds a key and door, then a guard.

### 3.13 Switches and gates (world 16)

A level may carry `switches`, one to three entries `{ switch, gate, open? }`. Built: the contract (types, both validators, both schemas, both simulators, the solver), the API (`switch` mechanic), the game (switches and gates on the flat and depth boards), and six levels. It is a state machine the player has to count: the state of a gate depends only on how often its switch has been entered.

- **Flipping.** Entering a switch's cell flips its gate, every time (shut to open, open to shut). There is no command for it. The trace event of that move is `SWITCHED`. A gate starts shut unless `open` is true.
- **Gates.** A shut gate blocks like a wall: moving into it ends the run with `BLOCKED_BY_GATE` and `blockedCell` is the gate. An open gate is an ordinary cell. For the sensors a shut gate is not floor, so a loop that runs until blocked stops in front of it.
- **With the rest.** Switches can share a level with keys, deliveries and guards. The guard check comes first: a guard that meets the automaton on a switch cell ends the run before the switch flips.
- **Validation.** Switches and gates lie on floor cells inside the board, never on the start or the target, and no two (keys, doors, items and docks included) share a cell. `open` must be a boolean. Issue codes `SWITCH_ON_WALL`, `SWITCH_ON_START`, `SWITCH_ON_GOAL`, `SWITCH_CELLS_REPEAT`, `SWITCHES_WITH_BOARDS` (not with `extraBoards`) and `SWITCHES_WITH_SWEEP` (not with the visit-every-cell goal).
- **Display.** A switch is a plate with a lever; the knob sits left until the switch has been flipped, right after. A shut gate is a block with bars (raised on the depth board); an open gate is two posts. With more than one pair, a switch and its gate carry the same number of pips. The failing instruction is marked on the tape and the message reads THE AUTOMATON TRIED TO GO THROUGH A SHUT GATE.
- **Solver.** The exact search adds the switches flipped (an odd number of times) to the state. Where a level offers loops, the reference solution sets par.
- **Compatibility.** The mechanic is `switch`.

**Level design rules for the Switches world:** the shortest program that ignores the switches (and crates and guards) must fail (a test checks this), and the limit equals the exact par. Chapter one has one gate, the second level with a gate that starts open and a switch on the only way in; chapter two has two pairs; the last chapter adds a crate, then a guard.

### 3.14 Ice and belts (world 17)

A level may carry `ice` (one to thirty cells) and `belts` (one to twenty `{ cell, direction }`). These two change where an action leaves the automaton, so the simulator and the solver now move it through one shared piece of code (`World` in `world.ts`, `RunWorld` in the game) and keep the rules there. Built: the contract (types, both validators, both schemas, both simulators, the solver), the API (`ice` and `belts` mechanics), the game, and six levels.

- **Ice.** A move onto an ice cell goes on sliding in the same direction while the next cell can be entered (on the board, not a wall, not a shut door or gate). It stops on the first cell that is not ice, or in front of whatever blocks it; being stopped by a wall is not a failure. The slide is one step. Every cell it passes counts as entered: a key is taken, a crate picked up or dropped, a switch flipped there, and a door the key opens is open for the rest of the slide.
- **Belts.** After any action (a move, a turn, `INC`, `MARK`) that leaves the automaton on a belt, it is carried one cell in the belt's direction, unless that cell cannot be entered, in which case it stays and nothing fails. A carry is once per action: it does not chain onto the next belt, and it does not start a slide.
- **The target.** The run ends the moment the target is entered, in a slide or by a belt. With a crate left it fails with `UNDELIVERED` there.
- **Guards.** A guard is checked where the step ends: the cell the automaton stands on afterwards, and a swap with the cell it started the step on. The cells passed on the way are not checked.
- **The trace.** On a level with ice or belts every trace entry has `path`: the cells the step entered, in order (empty for a turn that moved nothing). Its last cell is the entry's `position`. The event is `SLID` for a move that entered more than one cell, `CARRIED` for a turn, `INC` or `MARK` a belt carried, otherwise the usual one; a cell with an effect (`KEY_TAKEN`, `ITEM_TAKEN`, `ITEM_DROPPED`, `SWITCHED`) gives that event, the last such cell of the step winning. Levels without ice or belts have no `path`.
- **Validation.** Ice and belts lie inside the board and not on a wall; no two ice cells or two belts share a cell, and a belt is not on ice. A belt needs `cell` and a `direction` of north, east, south or west. Neither is allowed with `extraBoards`. They are allowed with the visit-every-cell goal and with every other mechanic. Issue codes `ICE_ON_WALL`, `ICE_CELLS_REPEAT`, `ICE_WITH_BOARDS`, `BELT_ON_WALL`, `BELT_CELLS_REPEAT`, `BELT_ON_ICE` and `BELTS_WITH_BOARDS`.
- **Display.** Ice is a floor cell with a thin inset outline and two glints; a belt is two chevrons that point the way it carries. The automaton moves through every cell of a step's `path` in turn.
- **Solver.** Breadth first over the state of the run (cell, facing, keys held, crate carried, delivered, switches flipped) through the same `World` code as the simulator; with guards the layer is the step. Where a level offers loops, the reference solution sets par.
- **Compatibility.** The mechanics are `ice` and `belts`.

**Level design rules for the Ice and belts world:** the shortest program that ignores the ice, belts and guards must fail (a test checks this), and the limit equals the exact par. Chapter one has ice only, chapter two belts only, the last chapter both and then a guard.

### 3.15 Teleporters (world 18)

A level may carry `teleports`, one to three pairs `{ a, b }`. Built: the contract (types, both validators, both schemas, both simulators, the solver), the API (`teleport` mechanic), the game, and five levels. It rides on the shared movement code (3.14), so the solver needed no change.

- **Teleporting.** Entering either end of a pair puts the automaton on the other end in the same step, facing the same way. Arriving does not teleport it back: it stays on the far end until it steps off and in again. The step ends there (a slide or a carry that reached the teleporter stops). The trace event is `TELEPORTED` and `path` lists the cell entered and then the far end.
- **Chains.** A belt may carry the automaton onto a teleporter, and a slide may end on one; the teleporter then sends it on. There is no chaining from the far end.
- **Guards.** A guard is checked where the step ends, on the far end.
- **Validation.** Both ends lie on floor cells inside the board, never on the start or the target, and no cell is shared with another pair, a key, door, crate, dock, switch, gate, ice cell or belt; a pair cannot join a cell to itself. Not allowed with `extraBoards` or the visit-every-cell goal. Issue codes `TELEPORT_ON_WALL`, `TELEPORT_ON_START`, `TELEPORT_ON_GOAL`, `TELEPORT_CELLS_REPEAT`, `TELEPORTS_WITH_BOARDS` and `TELEPORTS_WITH_SWEEP`.
- **Display.** Each end is two concentric rings (the target is a ring around a solid dot). With several pairs the two ends of a pair carry the same number of pips. The automaton walks to the teleporter and appears on the other end.
- **Compatibility.** The mechanic is `teleport`.

**Level design rules for the Teleporters world:** the shortest program that ignores the pairs and guard must fail (a test checks this), and the limit equals the exact par. The pairs are shortcuts, so the limit is well under the walk without them. The last chapter adds a guard.

### 3.16 Recursion (world 19)

A level that lists the mechanic `recursion` in `requires.mechanics` lets a procedure call procedures, itself included, and lets a `CALL` carry a sensor. Built: the contract (types, both validators, the schema, both simulators, fixtures), the API (`recursion` mechanic), the game's tape editor, and five levels. The solver does not search procedures, as before: a level's limit is the slots of its reference solution.

- **Where a CALL may stand.** In the main program as before, and with the mechanic directly in the body of a procedure (not inside a loop or an IF branch). Without the mechanic it is `CALL_NOT_ALLOWED` as before. It names a procedure that is defined at the top level (`UNDEFINED_PROCEDURE` otherwise); that may be the procedure it stands in or another one.
- **The base case.** A `CALL` may carry `when`, one of the nine sensors an `IF` can look at (not allowed without the mechanic: `UNKNOWN_FIELD`; unknown value: `INVALID_VALUE`). The sensor is read when the `CALL` is reached, costs nothing, and the procedure runs only while it is true; otherwise the `CALL` is skipped and the procedure goes on with the next item. That skip is the base case. A `CALL` without `when` always runs.
- **After the call.** What follows a `CALL` in a body runs when the call is over, once for each level of the recursion, deepest level first.
- **Depth.** At most 24 procedure calls may be running inside each other (the `CALL` of the main program is the first). Starting a 25th ends the run with `TOO_DEEP` (no trace entry; the steps taken so far stand). A recursion with no base case therefore ends here, not at the step limit.
- **The trace.** Every trace entry's `call` is the path of the innermost running `CALL`: `[i]` for a call in the main program, `[p, j]` for a call at item j of the body of the procedure at program index p. A primitive in a procedure keeps `node` `[p, j, ...]`.
- **Slots.** A `CALL` is one slot, in a body as anywhere.
- **The editor.** With the mechanic a Call tile can be added while a definition is open, never inside one of its loops or IFs. Selecting a call in the tape shows the sensor tool: it moves the call through no sensor and then the sensors an IF can use. A conditional call reads CALL IF with the sensor's icon.
- **Compatibility.** The mechanic is `recursion` (the level lists it itself, like `nested_loops`).

**Level design rules for the Recursion world:** every level lists `recursion` and carries a reference solution whose procedure calls itself with a sensor; the limit is its slots, and the best program without `PROC` is at least 1.3 times the limit (a test checks this). Levels offer movement and `PROC` only: no loops and no `IF`, so repetition has to come from the procedure. There is no guard chapter: a guard on a one-cell corridor blocks a recursion that cannot wait, and the levels of this world are timing-free.

### 3.17 Capstone (world 20)

The last world has no rule of its own. Each level puts two to four of the board tools of worlds 13 to 18 on one board (keys and doors, crates, switches, ice, belts, teleporters, guards), with movement commands only, so the exact solver gives par and the limit equals it.

**Level design rules for the Capstone world:** every tool on a level must be needed (leaving any one out gives a strictly shorter solution, a test checks this), the shortest program that ignores all of them fails, limits stay within 20 commands, and five of the eight levels have a guard. Loops, `IF` and procedures are not offered here; the worlds that teach them keep them.

## 4. Execution model and feedback

### Controls

- **Run:** execute automatically at a readable speed.
- **Step:** execute one primitive action at a time.
- **Pause/Resume:** stop or continue execution.
- **Reset:** restore the initial simulation state while preserving the program.
- **Retry:** allow edits after a failure.
- **Success feedback:** clearly communicate that the objective is complete.

### Execution states

Use explicit states: `READY`, `RUNNING`, `PAUSED`, `SUCCEEDED`, `FAILED`.

The program cannot be edited while `RUNNING`. Editing from `PAUSED`, `SUCCEEDED`, or `FAILED` returns the simulation to `READY`.

### Outcomes and messages

| Outcome                     | Example message                              |
| --------------------------- | -------------------------------------------- |
| Succeeded                   | “Level solved.”                              |
| Failed: blocked by a wall   | “The automaton tried to move into a wall.”   |
| Failed: blocked by the edge | “The automaton tried to move off the board.” |
| Failed: program ended       | “The program ended before the goal.”         |
| Failed: step limit          | “The program ran too long and was stopped.”  |

Exact counting rules (implemented and tested in `packages/level-contract`, whose README is the authority):

- Every executed instruction is one **step**, turns and blocked moves included. A blocked move stops the run as a failure.
- The run **succeeds the moment the automaton enters the goal cell**; the remaining instructions are not run or counted.
- The step limit is checked before each instruction: if the steps used have reached the limit and an instruction remains, the run fails with the step-limit outcome. A program that ends exactly at the limit without reaching the goal ends with “program ended”. Reaching the goal on the last allowed step succeeds.
- An unknown or malformed instruction stops the run (a content error, never silently skipped).
- A level whose **goal is the start cell** is invalid, because an empty program would solve it.

Never show a bare “Level failed,” a raw error code, or a stack trace. Level data that fails validation is a content error shown with a friendly load message, not a player failure.

### Separation

The simulation engine is separate from visual animation. Animations display simulation events; they never define game logic. The rules are testable without Godot's UI.

## 5. Difficulty progression and campaign structure

> **Built:** the campaign has grown to 20 worlds (Patrol, the item, tile and recursion worlds, and a capstone); see [README_WORLD_RESTRUCTURE_PLAN.md](README_WORLD_RESTRUCTURE_PLAN.md). The table below is the built campaign: 20 worlds, 48 chapters, 113 levels. Levels are listed by name in the seed (`starter-campaign.data.ts`), and the per-level choices are in [README_LEVEL_AUDIT.md](README_LEVEL_AUDIT.md).

The campaign is a tree: **worlds** (one concept each), **chapters** (small groups within a world), and **levels**. Levels unlock sequentially along the flattened order (world, then chapter, then level). The stages below map onto worlds. Placement is campaign data managed in the dashboard, not part of a level's definition.

Teach concepts progressively rather than making early levels arbitrarily difficult. Each world teaches one idea, and from the Loops world on each world needs a mechanic the game must implement first (section 3 and its subsections). The first two worlds need nothing new. Worlds are 5 or 6 levels, so a new idea arrives about every five levels: the first loop is level 11, and the first `IF` is level 22.

| #   | World         | Idea                                 | Algorithm the player uses                                                                               | Needs                                                                      | Levels |
| --- | ------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------ |
| 1   | Basics        | Sequencing and turning               | Step-by-step execution: trace a program by hand and predict where it ends                               | nothing new                                                                | 5      |
| 2   | Routes        | Planning and budgets                 | Shortest-path search (turns cost too) and working backward from the goal                                | nothing new                                                                | 5      |
| 3   | Loops         | Repeating a pattern                  | Pattern detection (find the repeating unit); split a route into loops plus the moves between them       | `REPEAT n` (built; 3.1)                                                    | 6      |
| 4   | Until         | One program for any distance         | Scan until a condition holds (linear search with a stop condition); reason about when a loop ends       | `REPEAT_UNTIL` (built; 3.2)                                                | 5      |
| 5   | Decisions     | Choosing by what you sense           | A greedy local rule: decisions based on the current state                                               | `IF` sensors (built; 3.3)                                                  | 5      |
| 6   | Wall follower | Keeping a hand on the wall           | Wall-following (the right-hand and left-hand rules) in mazes whose walls are all joined                 | `IF` sensors (built; 3.3)                                                  | 5      |
| 7   | Procedures    | Naming and reusing steps             | Abstraction and decomposition: build big solutions from small named parts                               | `PROC` and `CALL` (built; 3.4)                                             | 6      |
| 8   | Debug         | Reading and fixing a program         | Debugging: run it, see where it goes wrong, find the one thing that is wrong and change it              | `startProgram`: a program on the tape from the start (built; 3.10)         | 5      |
| 9   | Generalize    | One program, many boards             | Generalization and edge cases: the solution must work on every test board, including the tricky ones    | multi-board levels (built; 3.5)                                            | 6      |
| 10  | Counters      | Remembering a number and changing it | Accumulation: a value that grows each round (spirals, widening stairs, count to n then act)             | one counter variable and nested loops (built; 3.6)                         | 6      |
| 11  | Memory        | Marking where you have been          | Depth-first search with backtracking (the Tremaux idea): explore, mark, return, never repeat a path     | markers: `MARK`, the fresh and back sensors (built; 3.7)                   | 6      |
| 12  | Sweep         | Covering everything efficiently      | Systematic coverage (the lawnmower sweep) and efficiency: the same job in far fewer steps               | goal type "visit every floor cell"; step budgets that scale with the board | 5      |
| 13  | Patrol        | Timing and prediction                | Obstacles that move by a fixed pattern: read the pattern, go around, or wait for the right step         | patrols: guards on a route that depends on the step number (built; 3.9)    | 6      |
| 14  | Keys          | Order of dependencies                | Fetch what you need before you need it: a door stays shut until its key has been taken                  | keys and doors: `locks`, picked up by entering a cell (built; 3.11)        | 6      |
| 20  | Capstone      | Choosing the right tool              | Combine what the earlier worlds taught: several board tools on one board, each of them needed           | none (levels only, built; 3.17)                                            | 8      |
| 19  | Recursion     | Base case and self-call              | A procedure that calls itself, with a condition as the base case, and work that runs on the way back    | `recursion`: a CALL in a procedure body, a sensor on a CALL (built; 3.16)  | 5      |
| 18  | Teleporters   | Graph jumps                          | Plan the shortcut: a pair of cells is one step apart, so the shortest way is not the shortest walk      | teleporter pairs: `teleports` (built; 3.15)                                | 5      |
| 17  | Ice and belts | Predicting side effects              | Work out where each action leaves you: a slide on ice, a carry on a belt, before choosing the next      | ice and belts: `ice`, `belts`, one shared movement code (built; 3.14)      | 6      |
| 16  | Switches      | State machines, toggled gates        | Count the state: a switch flips its gate every time it is entered, so passing twice undoes it           | switches and gates: `switches`, flipped by entering a cell (built; 3.13)   | 6      |
| 15  | Delivery      | Carry and drop, sub-goals            | Finish a sub-goal before the main goal: carry a crate to its dock, one at a time, then reach the target | crates and docks: `deliveries`, one carried at a time (built; 3.12)        | 6      |

World 2 ends on its longest flat program (19 tiles), so loops are wanted when the Loops world starts. The budget ideas ("the limit equals par") live in the last chapter of the Routes world.

**Decisions for the later worlds** (2026-10-19): the counter is a single variable. The Memory world may change the board during a run, so a run's state then includes the marks and the trace records them. "Visit every floor cell" is its own goal type, not a combination with reaching a tile. Recursion (a procedure that calls itself) and delivery puzzles (pick up and drop items) were considered and left for later.

**Multi-board levels (the Generalize world onward).** A level may carry several test boards, and one program must solve every one of them. The simulator is unchanged (it runs one board); the level, validator, and publish gates check the program against each board and name the first board that fails. With conditions and procedures, par is no longer an exact shortest-program search: it is the author's best known solution, verified on every test board. Bodies, counts, and the step limit stay bounded as in 3.1.

**Boundary.** This is a set of taught, puzzle-specific tools, never a general-purpose programming language (see the not-included list in [README_PROJECT_OVERVIEW.md](README_PROJECT_OVERVIEW.md)).

The game accepts any valid solution unless a level explicitly introduces an optimization challenge. Players must not feel that one particular sequence is required when several correct solutions exist.

## 6. Screen orientation

**Decision: portrait-first** for the initial mobile release. It concentrates design and testing effort on one layout.

### Portrait layout (top to bottom)

1. Top bar: back button, level title or number, settings.
2. Objective area: the goal, command budget, and relevant feedback.
3. Game board: centered and large enough to understand the layout.
4. Program area: ordered command slots, with the active command highlighted.
5. Command palette: available instructions.
6. Execution controls: Run, Step, Pause/Resume, and Reset.

On smaller screens the program area can scroll. Do not shrink the board so much that cells are hard to distinguish. Keep the primary Run button easy to reach, keep touch targets comfortable, and do not hide important information behind decoration. Visual details are in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md).

### Landscape later

Keep the UI responsive enough that landscape remains possible, but do not require a separate landscape layout for the MVP. A later landscape layout could place the board on the left and program controls on the right.

## 7. Progress: local-first, offline-first, cloud sync

**Decision:** progress is stored on the device first. Players can download the game, play, and complete levels with no account and no connection. When the player signs in and the device is online, progress syncs to the cloud.

### Local progress

Save on the device:

- Completed level IDs.
- Highest unlocked level (recomputed from completions and the current campaign order, so reordering never strands a player).
- Best solution metrics per level (fewest commands, fewest steps), when applicable.
- Last played level.
- Settings: sound, music, vibration, reduce motion, run speed, and theme (system, light, dark).

Use a versioned save format so updates can change the data structure without losing progress. Writes must be safe against interruption: if the app closes unexpectedly, previously saved progress stays intact.

Completion is keyed by stable level ID, so publishing a new version of a level does not erase a completion. Best metrics record the level version they were achieved on.

### Cloud sync

Accounts are optional and are never required to play. A signed-out player's progress is never uploaded.

When the player is signed in and online, the game syncs in the background:

- after signing in (an initial merge),
- when a level is completed,
- when the app starts, and
- when connectivity returns after a failed attempt.

Sync failures are silent to the player and retried with backoff. A sync failure, an expired session, or a sign-out never erases or blocks local progress.

### Merge policy

When local and cloud progress both exist, merge them; never blindly replace one with the other:

- Combine completed levels (union).
- Recalculate unlocks from completion data and progression rules.
- Keep the better result for metrics such as fewer commands or fewer steps.
- Use the most recently updated value for settings.
- Never delete local progress because authentication or synchronization failed.

The server merges and returns the result; the client then adopts the merged state. The merge is idempotent, so repeating a sync is safe.

### Trust

Progress and metrics sent by a client are not trusted for competition. Leaderboards, if introduced, need a defined scoring formula and server-side verification (for example, replaying the submitted program on the reference simulator) before any result is shown publicly.

### Delivery phasing

The data model, API shape, and save format are designed for sync from the start, so adding accounts later does not require migrating saves. The accounts and sync feature itself is built after the core loop and dashboard-managed publishing work end to end (see the implementation plan).

## 8. Offline support

The core game remains playable without a constant internet connection.

- Previously downloaded levels are cached locally, keyed by level ID and version.
- A small set of starter levels is bundled with the app so a first launch works offline.
- Local progress keeps saving offline.
- The game clearly indicates when fresh levels are unavailable, and distinguishes “not downloaded” from “locked by progression.”
- Network errors never block already-downloaded levels.
- A bad response never replaces a valid cached level.
- Account sync retries when connectivity returns.

## 9. Dashboard-based level publishing

New levels are content, not new game code.

The Next.js dashboard lets an authorized administrator create, edit, preview, and publish levels. The NestJS API validates and stores the definitions, and PostgreSQL persists them. The Godot game downloads published definitions and renders them with its existing engine.

### Publishing workflow

1. Create a level in the dashboard.
2. Define the board, starting state, goal, available commands, and command budget.
3. Preview and test it with the reference simulator, and record a reference solution.
4. Validate. The level must pass schema rules and be solved by its reference solution. The solver computes par (the shortest program) and flags a command budget below par.
5. Record a playtest. Publishing requires a solved playtest record for the current content.
6. Publish. Publishing is blocked if the level needs a mechanic the deployed app does not support.
7. Place the level in a chapter of a world; placement controls what players see and the unlock order.
8. The game fetches the updated campaign.
9. Players download and play the new level without an app rebuild.

### Versioning and compatibility

- Each level has a stable ID and a version.
- Editing a published level creates a new draft version; it never silently changes a version someone is already playing. Published versions are immutable.
- The game validates downloaded definitions and rejects incompatible data safely.
- Each level lists the mechanics it requires, and each game build declares what it supports. A client skips or flags levels it cannot play.
- New levels can be published without an app update only when they use mechanics the installed game already supports. A brand-new command or mechanic may require a client update.

## 10. MVP acceptance criteria

The first version is ready for broader testing when:

- Players can complete levels without creating an account.
- The command palette supports adding, deleting, and reordering instructions.
- Run, Step, Pause/Resume, and Reset behave consistently.
- The game detects success and failure correctly and explains failures.
- Identical programs produce identical outcomes, and the game, dashboard preview, and API agree on every shared fixture.
- Local progress survives app restarts and interrupted saves.
- Downloaded levels remain playable offline.
- An administrator can publish a new level from the dashboard without rebuilding the game.
- Invalid or unsolvable level definitions are rejected safely.
- The portrait layout works on small mobile screens.
- Core command and simulation rules have automated tests.

Optional accounts and cloud sync have their own acceptance criteria in the implementation plan.

## 11. Final decisions

For the first release, keep the scope focused:

- **Gameplay:** visual programming puzzles with movement, turns, and eventually loops.
- **Orientation:** portrait-first.
- **Progress:** local-first and offline-first, with optional accounts and cloud sync.
- **Backend:** publishes and delivers level content; later stores synced progress.
- **Dashboard:** authors and manages levels from day one.
- **Future expansion:** conditions, interactable objects, leaderboards, and more advanced algorithmic challenges.

The principle: build a small, genuinely enjoyable programming puzzle game first, but design its content and progress systems so new levels can be published, and progress synced, independently of app releases.
