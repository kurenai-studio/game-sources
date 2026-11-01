# @algomind/level-contract

The single source of truth for the level data format, its validation, the reference simulator, the solver, and the language-neutral fixture suite. The Godot game implements the same rules in GDScript and must pass every fixture in `fixtures/`; a disagreement between the two implementations blocks merge (see `docs/README_ARCHITECTURE.md`, sections 5 and 12).

This README is written so that the rules can be implemented in another language without reading the TypeScript. `fixtures/README.md` specifies the fixture file format.

## Layout

```
schema/level.v1.schema.json            JSON Schema (draft 2020-12) of the public level
schema/level-authoring.v1.schema.json  the same plus the required referenceSolution
src/constants.ts                       limits, command names, directions, patterns
src/types.ts                           TypeScript types
src/validate.ts                        validateLevel, validateAuthoringLevel, validateProgram
src/simulate.ts                        simulate
src/explain.ts                         explainResult (all player-facing failure text)
src/solve.ts                           solve
fixtures/                              levels (valid, invalid), runs, solver; see fixtures/README.md
test/                                  node --test suites, including one that runs every fixture
dist/                                  compiled output (git-ignored, produced by `pnpm build`)
```

The JSON Schema describes structure only. Rules that look at several fields at once (cells inside the board, duplicate walls, start or goal on a wall, goal equals start, duplicate commands and mechanics) are enforced by the validator. The validator is authoritative; the schema is for documentation and editor support.

## The level

```json
{
  "schemaVersion": 1,
  "levelId": "level-intro-001",
  "levelVersion": 1,
  "slug": "first-steps",
  "title": "First Steps",
  "description": "Reach the goal using the available commands.",
  "difficulty": "easy",
  "requires": { "mechanics": [] },
  "board": {
    "width": 5,
    "height": 5,
    "walls": [
      [1, 1],
      [1, 2],
      [3, 3]
    ]
  },
  "initialState": { "position": [0, 4], "direction": "north" },
  "availableCommands": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
  "constraints": { "maxCommands": 12, "maxSteps": 30 },
  "goal": { "type": "reach_tile", "position": [4, 0] },
  "hints": ["Look for a route around the wall."]
}
```

There is no `sortOrder`: placement in a world and chapter is campaign data, not part of a level. Unknown fields are rejected everywhere (use `requires.mechanics` and, later, a typed `entities` array for new mechanics). The authoring form adds `referenceSolution` (a program) and is never served publicly; the public validator rejects a level that contains it.

### Coordinates and directions

- A cell is `[x, y]`. `x` grows to the right, `y` grows downward; `[0, 0]` is the top-left cell. Both are zero-based.
- Directions are `north`, `east`, `south`, `west`. `north` means `y` decreases. Unit steps: north `(0, -1)`, east `(+1, 0)`, south `(0, +1)`, west `(-1, 0)`.
- Turning left (counterclockwise): north -> west -> south -> east -> north. Turning right (clockwise): north -> east -> south -> west -> north.

### Programs

A program is an ordered list of instruction nodes. A node is a primitive (`{ "op": "MOVE_FORWARD" }`, `TURN_LEFT`, `TURN_RIGHT`) or a loop:

```json
{ "op": "REPEAT", "count": 6, "body": [{ "op": "MOVE_FORWARD" }, { "op": "TURN_RIGHT" }] }
```

A loop's `count` is a whole number from 2 to 11 and its `body` is 1 to 8 primitives. **A loop cannot contain a loop.**

A second loop, `{ "op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [...] }`, has no count: before each round it checks whether a wall or the board edge is straight ahead and runs the body again only while it is not. The condition is checked before the first round too, so the body can run zero times. A level offers it by listing `REPEAT_UNTIL` in `availableCommands` (the mechanic `repeat_until`). Its body rules, its slots (1 plus the body), and its step counting are those of `REPEAT`; a loop inside either loop is `NESTED_REPEAT`; `until` must be `BLOCKED` (`INVALID_VALUE`, `REQUIRED`, or `INVALID_TYPE` at `program[i].until`); a `count` on it, or an `until` on a `REPEAT`, is `UNKNOWN_FIELD`. A body that is never blocked runs until the step limit. A level offers loops by listing `REPEAT` in `availableCommands`; the mechanic name `repeat` is then required of the client (the API derives it from the command, so `requires.mechanics` does not repeat it). An empty program is valid.

A third node, `{ "op": "IF", "when": "CLEAR_RIGHT", "then": [primitives], "else": [primitives] }`, is a decision. `when` is `CLEAR_AHEAD`, `CLEAR_LEFT`, or `CLEAR_RIGHT`: true when the cell on that side of the automaton is on the board and not a wall. `then` holds 1 to 4 primitives, `else` holds 0 to 4 (always present, possibly empty). An `IF` may stand at the top level or as an item of a loop body (a body is 1 to 8 items, each a primitive or an `IF`); an `IF` cannot hold an `IF` (`NESTED_IF`) or a loop (`NESTED_REPEAT`). Reading a sensor costs no step. An `IF` is 1 plus its branches in slots, and a loop is 1 plus the slots of its body items. A level offers it with `IF` in `availableCommands` (the mechanic `if`). Missing, mistyped or unknown `when` is `REQUIRED`, `INVALID_TYPE`, `INVALID_VALUE` at `program[i].when`; a branch outside its length is `LENGTH_OUT_OF_RANGE` at `program[i].then` or `.else`; a missing branch is `REQUIRED`. `REPEAT_UNTIL` also accepts `until: "GOAL"`, which is never true at the start of a round, so that loop runs until the goal, a failure, or the step limit. A round of a `REPEAT_UNTIL` in which no primitive runs would repeat for ever and stops the run with `STEP_LIMIT`. In the trace, a primitive inside an `IF` has `node` `[i, k]` (top level) or `[i, j, k]` (body item `j` of loop `i`), where `k` counts the `then` primitives first and the `else` primitives after them.

Two more nodes define and use procedures: `{ "op": "PROC", "name": "A", "body": [...] }` (top level only) and `{ "op": "CALL", "name": "A" }` (top level, or an item of a loop body of the main program). `name` is `A`, `B`, or `C`. A `PROC` body is 1 to 8 items: primitives, `IF`s, and loops; it cannot hold a `CALL` or a `PROC`. A `PROC` is not run where it stands; a `CALL` runs the first `PROC` of that name. A level offers both by listing `PROC` in `availableCommands` (the mechanic `procedures`). Slots: a `CALL` is 1, a `PROC` is 1 plus the slots of its body. New issue codes: `NESTED_PROC` (a `PROC` that is not at the top level, at its `op`), `CALL_NOT_ALLOWED` (a `CALL` where it may not stand, at its `op`), `DUPLICATE_PROCEDURE` and `UNDEFINED_PROCEDURE` (at `name`), and `name` is `REQUIRED`, `INVALID_TYPE`, or `INVALID_VALUE` like the other fields. Every trace entry carries `call`, the path of the `CALL` that is running it or `null`; a primitive inside a procedure has `node` `[p, ...]` with `p` the index of the `PROC`. The solver ignores `PROC`; par for a level that offers it is the reference solution.

Three more additions serve worlds 8 to 10 (the rules are in `docs/README_GAME_RULES.md`, sections 3.6 to 3.8):

- **Counter and nested loops.** `{ "op": "INC" }` adds one to the counter `N` (it starts at 1 and stops at 11); `INC` is an action (one slot, one step, trace `event` `COUNTED`) and every trace entry carries `counter`. A `REPEAT` may take `"count": "N"`, read when the loop starts (`COMMAND_NOT_AVAILABLE` at `.count` when `INC` is not offered). A loop may hold one loop, but only when the level lists `nested_loops` in `requires.mechanics` (otherwise, and for a third level, `NESTED_REPEAT`). The simulator runs two levels of loops whether or not the level allows them; `validateProgram` is what refuses. A primitive in an inner loop has `node` `[i, j, k]` and the inner loop's `round`.
- **Breadcrumbs and else-if chains.** `{ "op": "MARK" }` drops a breadcrumb on the cell the automaton stands on, an arrow to the cell behind it; a cell keeps its first. It is an action (trace `event` `MARKED`). `IF.when` gains `FRESH_AHEAD`, `FRESH_LEFT`, `FRESH_RIGHT` (a floor cell with no breadcrumb) and `BACK_AHEAD`, `BACK_LEFT`, `BACK_RIGHT` (the cell this cell's breadcrumb points to); they need `MARK` offered. The `else` of an `IF` may hold exactly one `IF` (an else-if chain, up to 6 IFs); anything else beside it, or an `IF` in `then`, is `NESTED_IF`. A trace path goes into the nested `IF` after the index `then.length`.
- **The sweep goal.** `"goal": { "type": "visit_all" }` has no `position` (a `position` is `UNKNOWN_FIELD`); the board needs at least two floor cells (`GOAL_EQUALS_START` at `goal`). The run succeeds the moment every floor cell has been entered or started on, with reason and event `GOAL_REACHED`. A level's own board and each extra board choose their own goal. The solver returns `null` for it, so par is the reference solution.

A level may also carry `extraBoards`: 1 to 5 more test boards, each an object with `board`, `initialState` and `goal` (the same rules as the level's own; issue paths are prefixed, for example `extraBoards[0].goal.position`). One program must solve every board. `simulate` still runs one board. `simulateAll(level, program)` runs the program on the level's own board and then on each extra board and returns `{ status, firstFailure, steps, results }`: the level is solved only when every result succeeded, `firstFailure` is the index of the first board that failed (0 is the level's own board) or `null`, and `steps` is the sum. `boardsOf(level)` lists the boards and `levelOnBoard(level, i)` gives the level as if board `i` were its only one. Par for a level with extra boards is the reference solution (the solver reads the level's own board only).

A level may also carry `startProgram`, a program the tape starts with (a debug level, `docs/README_GAME_RULES.md` section 3.10). It is validated like the reference solution (known and offered commands, within `constraints.maxCommands`; issue paths `startProgram[...]`) but it need not solve the level: the API's publish gate requires that it does not. It is part of the public level and is optional.

A level may also carry `patrols`, one to three guards `{ pattern, cells }` (`back_and_forth` or `loop`) whose cell depends only on the step number (`docs/README_GAME_RULES.md` section 3.9). `patrolCell` and `patrolMeeting` (in `src/patrol.ts`) give the cell and the collision; a run that meets a guard fails with `HIT_BY_PATROL`. The validator reports `PATROL_ON_WALL`, `PATROL_ON_START`, `PATROL_CELLS_REPEAT`, `PATROL_NOT_CONNECTED` and `PATROLS_WITH_BOARDS`, and `solve` searches over (cell, facing, step) when a level has patrols.

A level may also carry `locks`, one to three `{ key, door }` pairs (`docs/README_GAME_RULES.md` section 3.11): entering a key's cell picks it up, and a door blocks with `BLOCKED_BY_DOOR` until its key is held. The validator reports `LOCK_ON_WALL`, `LOCK_ON_START`, `LOCK_ON_GOAL`, `LOCK_CELLS_REPEAT`, `LOCKS_WITH_BOARDS` and `LOCKS_WITH_SWEEP`, and `solve` adds the keys held to its state.

A level may also carry `deliveries`, one to three `{ item, dock }` pairs (`docs/README_GAME_RULES.md` section 3.12): entering an item's cell with empty hands picks it up (`ITEM_TAKEN`), entering its dock drops it (`ITEM_DROPPED`), and entering the target with an item left fails with `UNDELIVERED`. The validator reports `DELIVERY_ON_WALL`, `DELIVERY_ON_START`, `DELIVERY_ON_GOAL`, `DELIVERY_CELLS_REPEAT` (also against the cells of `locks`), `DELIVERIES_WITH_BOARDS` and `DELIVERIES_WITH_SWEEP`, and `solve` adds what is carried and delivered to its state.

A level may also carry `switches`, one to three `{ switch, gate, open? }` entries (`docs/README_GAME_RULES.md` section 3.13): entering a switch's cell flips its gate every time (`SWITCHED`), a shut gate blocks with `BLOCKED_BY_GATE`, and a gate starts shut unless `open` is true. The validator reports `SWITCH_ON_WALL`, `SWITCH_ON_START`, `SWITCH_ON_GOAL`, `SWITCH_CELLS_REPEAT`, `SWITCHES_WITH_BOARDS` and `SWITCHES_WITH_SWEEP`, and `solve` adds the switches flipped to its state.

A level may also carry `ice` (cells) and `belts` (`{ cell, direction }`) (`docs/README_GAME_RULES.md` section 3.14): a move onto ice slides on while the way is free, a belt carries the automaton one cell after an action that leaves it there, and on such a level every trace entry has `path`, the cells the step entered (events `SLID` and `CARRIED`). The validator reports `ICE_ON_WALL`, `ICE_CELLS_REPEAT`, `ICE_WITH_BOARDS`, `BELT_ON_WALL`, `BELT_CELLS_REPEAT`, `BELT_ON_ICE` and `BELTS_WITH_BOARDS`. `simulate` and `solve` move the automaton through the same `World` class (`src/world.ts`).

A level may also carry `teleports`, one to three `{ a, b }` pairs (`docs/README_GAME_RULES.md` section 3.15): entering one end puts the automaton on the other, facing the same way, with no bounce back (event `TELEPORTED`, and `path` on such a level lists the cell entered and the far end). The validator reports `TELEPORT_ON_WALL`, `TELEPORT_ON_START`, `TELEPORT_ON_GOAL`, `TELEPORT_CELLS_REPEAT` (also against every other tile), `TELEPORTS_WITH_BOARDS` and `TELEPORTS_WITH_SWEEP`.

A level that lists the mechanic `recursion` lets a procedure call procedures and itself (a `CALL` stands directly in a procedure body) and lets a `CALL` carry `when`, a sensor read when the call is reached (the base case: the call is skipped while it is false) (`docs/README_GAME_RULES.md` section 3.16). At most 24 calls may run inside each other; the next ends the run with `TOO_DEEP`. `call` in a trace entry is the path of the innermost running `CALL`.

The solver does not search `IF` programs. With `IF` offered it still finds the best program without one (loops included); par for such a level is the author's reference solution, which the publish gate runs.

**Slots.** The command limit counts slots: a primitive is 1, a `REPEAT` is 1 plus the number of instructions in its body. `REPEAT 6 { MOVE_FORWARD, TURN_RIGHT, MOVE_FORWARD, TURN_LEFT }` is 5 slots. `programSlots(program)` computes it.

### Limits

All are inclusive. Lengths of strings are counted in Unicode code points (not UTF-16 units or bytes). They live in `src/constants.ts` (`LIMITS`), and a test keeps the JSON Schema in sync.

| Field                         | Limit                                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `schemaVersion`               | must be `1`                                                                                                                 |
| `levelId`, `slug`             | 1 to 64 characters, lowercase letters and digits in hyphen-separated groups (`^[a-z0-9]+(-[a-z0-9]+)*$`)                    |
| `levelVersion`                | integer, 1 to 1,000,000                                                                                                     |
| `title`                       | 1 to 60 characters                                                                                                          |
| `description`                 | 0 to 280 characters                                                                                                         |
| `difficulty`                  | `easy`, `medium`, or `hard`                                                                                                 |
| `requires.mechanics`          | at most 8 entries, unique, each 1 to 32 characters matching `^[a-z][a-z0-9_]*$`                                             |
| `board.width`, `board.height` | integer, 3 to 12                                                                                                            |
| `board.walls`                 | at most 100 unique cells                                                                                                    |
| `availableCommands`           | 1 to 9 unique entries from `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`, `INC`, `MARK`, `REPEAT`, `REPEAT_UNTIL`, `IF`, `PROC` |
| `REPEAT` `count`              | integer, 2 to 11                                                                                                            |
| `REPEAT` `body`               | 1 to 8 primitive instructions (no `REPEAT`)                                                                                 |
| `constraints.maxCommands`     | integer, 1 to 64                                                                                                            |
| `constraints.maxSteps`        | integer, 1 to 1000                                                                                                          |
| `hints`                       | at most 5 entries, each 1 to 140 characters                                                                                 |

`requires.mechanics` names are free-form within the pattern: the validator does not know which mechanics a game build supports; the API and the client compare the list with what they support. The first command set needs no mechanics, so the list is normally empty; `REPEAT` needs the mechanic `repeat`, which the API adds from `availableCommands`.

## Validation

`validateLevel(input)` and `validateAuthoringLevel(input)` take any value and return `{ ok, issues }`. They never throw. `validateProgram(level, program)` returns the same shape.

Each issue is `{ path, code, message }`, matching the error contract in `docs/README_ARCHITECTURE.md` section 11.

- `path` is JSON-pointer-like: object keys joined with `.` and array indexes in brackets, for example `board.width`, `board.walls[2]`, `initialState.position`, `referenceSolution[1].op`. The document root is the empty string `""`.
- `code` is stable and machine-readable (table below). `message` is human text and not part of the contract: never match on it, and fixtures do not contain it.
- The order of issues is not part of the contract; compare as a set of `(path, code)` pairs. A given `(path, code)` pair appears at most once.

### Issue codes

| Code                         | Meaning                                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------- |
| `INVALID_TYPE`               | wrong JSON type, a non-integer where an integer is required, or a malformed `[x, y]` pair   |
| `REQUIRED`                   | a required field is absent                                                                  |
| `UNKNOWN_FIELD`              | a field the schema does not define                                                          |
| `UNSUPPORTED_SCHEMA_VERSION` | `schemaVersion` is an integer other than 1                                                  |
| `OUT_OF_RANGE`               | a number outside its inclusive range                                                        |
| `LENGTH_OUT_OF_RANGE`        | a string or array shorter or longer than allowed                                            |
| `INVALID_FORMAT`             | a string that fails its pattern (`levelId`, `slug`, mechanic names)                         |
| `INVALID_VALUE`              | a string outside its enum (`difficulty`, `initialState.direction`, `goal.type`)             |
| `OUTSIDE_BOARD`              | a wall, the start, or the goal outside the board                                            |
| `DUPLICATE_WALL`             | a wall repeats an earlier wall (reported at the later index)                                |
| `START_ON_WALL`              | the start cell is a wall                                                                    |
| `GOAL_ON_WALL`               | the goal cell is a wall                                                                     |
| `GOAL_EQUALS_START`          | the goal cell is the start cell                                                             |
| `UNKNOWN_COMMAND`            | a command name that is not one of the four (also an unknown `op` in a program)              |
| `DUPLICATE_COMMAND`          | a known command repeated in `availableCommands` (reported at the later index)               |
| `DUPLICATE_MECHANIC`         | a mechanic repeated in `requires.mechanics` (reported at the later index)                   |
| `COMMAND_NOT_AVAILABLE`      | a known `op` that the level's `availableCommands` does not offer                            |
| `TOO_MANY_COMMANDS`          | a program that uses more slots than `constraints.maxCommands`; reported at the program path |
| `NESTED_REPEAT`              | a `REPEAT` inside the body of a `REPEAT`; reported at the inner `op`                        |
| `NESTED_IF`                  | an `IF` inside the branch of an `IF`; reported at the inner `op`                            |

### Exact validation rules

1. The input must be an object (not an array, not null) or the only issue is `INVALID_TYPE` at `""`.
2. `schemaVersion`: absent is `REQUIRED`; a non-integer is `INVALID_TYPE`; an integer other than 1 is `UNSUPPORTED_SCHEMA_VERSION` **and validation stops there** (that is the only issue returned, because nothing else can be trusted). Otherwise validation continues.
3. Any key that is not a field of the level (or `referenceSolution` for the authoring validator) is `UNKNOWN_FIELD` at that key. The same applies inside `requires`, `board`, `initialState`, `constraints`, `goal`, and program nodes.
4. A missing field is `REQUIRED` at its own path. A present field of the wrong JSON type is `INVALID_TYPE`. Integers must be whole numbers (a float such as `5.5` or a string such as `"5"` is `INVALID_TYPE`, not `OUT_OF_RANGE`). A field with one error produces one issue; it is not also checked against later rules.
5. Strings: first the type, then the length (`LENGTH_OUT_OF_RANGE`; an empty string where 1 is the minimum is a length error, not a format error), then the pattern (`INVALID_FORMAT`).
6. A container that has the wrong type or is missing (`board`, `initialState`, `goal`, `requires`, `constraints`) gets one issue and its children are not checked.
7. A cell (`board.walls[i]`, `initialState.position`, `goal.position`) must be an array of exactly two integers, else `INVALID_TYPE`. If, and only if, `board.width` and `board.height` are both valid (integers within range), a cell with `x < 0`, `y < 0`, `x >= width`, or `y >= height` is also `OUTSIDE_BOARD`. So a bad board size produces no `OUTSIDE_BOARD` issues.
8. Cell comparisons use every well-formed cell, whether or not it is inside the board:
   - a well-formed wall equal to an earlier well-formed wall is `DUPLICATE_WALL` at the later index;
   - `START_ON_WALL` at `initialState.position`, `GOAL_ON_WALL` at `goal.position`, and `GOAL_EQUALS_START` at `goal.position` when both cells are well-formed.
9. `board.walls` with more than 100 entries is `LENGTH_OUT_OF_RANGE` at `board.walls` (each entry is still checked).
10. `availableCommands`: an empty array is `LENGTH_OUT_OF_RANGE`. Per entry: a non-string is `INVALID_TYPE`; a string that is not one of the four names (names are case sensitive) is `UNKNOWN_COMMAND`; a known name seen earlier is `DUPLICATE_COMMAND`.
11. `requires.mechanics`: more than 8 entries is `LENGTH_OUT_OF_RANGE` at `requires.mechanics`. Per entry: type, length, pattern as in rule 5; a valid name seen earlier is `DUPLICATE_MECHANIC`.
12. `hints`: more than 5 entries is `LENGTH_OUT_OF_RANGE` at `hints`. Per entry: type and length as in rule 5.
13. `goal.type` must be `"reach_tile"` (`INVALID_VALUE` otherwise, `REQUIRED` if absent).
14. **Goal equals start is invalid.** A level the empty program would solve is not a puzzle. (Decision; the docs were silent.)
15. A goal that cannot be reached is **not** a validation issue. The solver decides that (publish gates use `solve`).
16. Authoring only: `referenceSolution` is required and is checked like a program (below) against the level's own `availableCommands` and `constraints.maxCommands`, with paths starting `referenceSolution`. Whether it actually solves the level is checked by running `simulate`, not by the validator.

### Program validation

`validateProgram(level, program)` takes a valid level. The path prefix is `program` (`referenceSolution` for the authoring check).

1. Not an array: `INVALID_TYPE` at `program`.
2. Per node `program[i]`: not an object is `INVALID_TYPE` at `program[i]`; any key other than `op` (and, for a `REPEAT`, `count` and `body`) is `UNKNOWN_FIELD` at `program[i].<key>`; missing `op` is `REQUIRED` at `program[i].op`; a non-string `op` is `INVALID_TYPE`; a string that is not a known command is `UNKNOWN_COMMAND`; a known command that is not in the level's `availableCommands` is `COMMAND_NOT_AVAILABLE`. All at `program[i].op`.
3. Per `REPEAT` node: `count` absent is `REQUIRED`, not an integer is `INVALID_TYPE`, outside 2 to 11 is `OUT_OF_RANGE` (at `program[i].count`). `body` absent is `REQUIRED`, not an array is `INVALID_TYPE`, fewer than 1 or more than 8 entries is `LENGTH_OUT_OF_RANGE` (at `program[i].body`). Each body entry is checked like a primitive node at `program[i].body[j]`; a `REPEAT` there is reported once, as `NESTED_REPEAT` at `program[i].body[j].op`, and its own fields are not checked.
4. Slots (see Programs) greater than `constraints.maxCommands` is a single `TOO_MANY_COMMANDS` at `program`. Every node counts, valid or not. An empty program is valid.

## The simulator

`simulate(level, program)` is deterministic and pure: the same inputs always give the same output, nothing is modified, and there is no clock, randomness, or I/O. It is separate from animation: a game animates the returned trace.

`simulate` expects a level that passed `validateLevel` (behavior on an invalid level is undefined) and does **not** check `availableCommands` or `maxCommands`. Callers run `validateProgram` first. This is deliberate and covered by fixtures, so a port must not add extra checks inside its simulator.

### State

The automaton has a cell and a direction, starting at `initialState`. The goal is `goal.position`.

### Execution

A _step_ is one executed primitive. Every executed primitive counts as one step, turns included, and **a move that is blocked counts as a step too** (it is traced). **A `REPEAT` itself is not a step.** Skipped or unreached instructions are not steps. `steps` always equals the trace length.

Run the nodes in order. For the node at index `i` (zero-based), with `steps` steps done so far:

1. If `steps >= constraints.maxSteps`, stop: `FAILED`, reason `STEP_LIMIT`. (So a run never executes more than `maxSteps` steps. This check happens before the node is looked at, so it wins over `INVALID_INSTRUCTION`.)
2. A primitive node is one object whose string `op` is `MOVE_FORWARD`, `TURN_LEFT`, or `TURN_RIGHT`; run it as in 3 and 4 with trace `node` `[i]` and `round` `null`. A loop node is an object whose `op` is `REPEAT`, whose `count` is an integer from 2 to 11, and whose `body` is an array of 1 to 8 primitive nodes; run it as in 2a. Anything else stops the run: `FAILED`, reason `INVALID_INSTRUCTION`. The node is not executed and is not counted. Nodes are never silently skipped.
   - 2a. For `round` from 1 to `count`, for `j` from 0 to the end of the body: first, if `steps >= constraints.maxSteps`, stop with `STEP_LIMIT`; then run the primitive `body[j]` as in 3 and 4 with trace `node` `[i, j]` and `round`. Anything that stops the run inside the loop stops the whole run; the rest of the body, the remaining rounds, and the remaining nodes are not run.
   - 2b. A `REPEAT_UNTIL` node is run like 2a but without a count: for `round` = 1, 2, 3 and so on, first look at the cell straight ahead; if it is off the board or a wall, the loop is over and the run goes on with node `i + 1`. Otherwise for `j` from 0 to the end of the body: if `steps >= constraints.maxSteps`, stop with `STEP_LIMIT`; then run the primitive `body[j]` as in 3 and 4 with trace `node` `[i, j]` and `round` set to the round. A well-formed `REPEAT_UNTIL` has `until` equal to `BLOCKED` and a body of 1 to 8 primitive nodes; anything else is `INVALID_INSTRUCTION`.
3. `TURN_LEFT` / `TURN_RIGHT`: rotate the direction 90 degrees, keep the cell. Append a trace entry with event `TURNED`.
4. `MOVE_FORWARD`: let `target` be the cell one unit ahead.
   - If `target` is outside the board (`x < 0`, `y < 0`, `x >= width`, `y >= height`): append a trace entry (the position is unchanged, event `BLOCKED_BY_BOUNDARY`) and stop: `FAILED`, reason `BLOCKED_BY_BOUNDARY`, `blockedCell` = `target` (which can contain `-1` or `width` / `height`).
   - Else if `target` is a wall: same, with event and reason `BLOCKED_BY_WALL`.
   - Else move to `target`. If `target` is the goal cell: append a trace entry with event `GOAL_REACHED` and stop: `SUCCEEDED`, reason `GOAL_REACHED`. Any remaining instructions are ignored (not executed, not validated, not counted). Otherwise append a trace entry with event `MOVED`.
5. If the nodes run out without a stop: `FAILED`, reason `PROGRAM_ENDED`. This includes an empty program (zero steps), and a program of exactly `maxSteps` instructions that did not reach the goal (it ends, it does not hit the limit, because the limit is only checked before an instruction that would run).

The goal is only tested when a move enters it. The start cell is never the goal in a valid level.

### Result

```json
{
  "status": "SUCCEEDED | FAILED",
  "reason": "GOAL_REACHED | BLOCKED_BY_WALL | BLOCKED_BY_BOUNDARY | PROGRAM_ENDED | STEP_LIMIT | INVALID_INSTRUCTION",
  "steps": 2,
  "finalState": { "position": [1, 2], "direction": "east" },
  "blockedCell": [2, 2],
  "trace": [
    { "index": 0, "op": "MOVE_FORWARD", "position": [1, 2], "direction": "east", "event": "MOVED" }
  ]
}
```

- `status` is `SUCCEEDED` only with reason `GOAL_REACHED`.
- `finalState` is the state after the last step (the initial state when no step ran). On a blocked move it is the state before the blocked move.
- `blockedCell` is the attempted target cell for the two `BLOCKED_BY_*` reasons, otherwise `null`. The key is always present.
- Each trace entry has exactly the keys `index` (0-based step number), `op` (always a primitive), `node` (where the primitive sits: `[i]` at the top level, `[i, j]` in the body of the loop at `i`), `round` (1-based round of that loop, or `null` outside a loop), `position` and `direction` (the state **after** the step; unchanged position for a blocked move), and `event` (`MOVED`, `TURNED`, `GOAL_REACHED`, `BLOCKED_BY_WALL`, `BLOCKED_BY_BOUNDARY`). `STEP_LIMIT`, `PROGRAM_ENDED`, and `INVALID_INSTRUCTION` add no trace entry.

### Player-facing text

`explainResult(result)` maps a reason to plain language. All of it lives in `src/explain.ts` (`REASON_MESSAGES`):

| Reason                | Text                                                       |
| --------------------- | ---------------------------------------------------------- |
| `GOAL_REACHED`        | Level solved.                                              |
| `BLOCKED_BY_WALL`     | The automaton tried to move into a wall.                   |
| `BLOCKED_BY_BOUNDARY` | The automaton tried to move off the board.                 |
| `PROGRAM_ENDED`       | The program ended before the goal.                         |
| `STEP_LIMIT`          | The program ran too long and was stopped.                  |
| `INVALID_INSTRUCTION` | The program contains an instruction this level cannot run. |

The game shows these in capitals per `docs/README_VISUAL_DESIGN.md` section 7. The text is not part of the fixtures.

## The solver

`solve(level)` returns the shortest program (par), or `null` when the goal cannot be reached with the available commands.

```ts
{
  commands: number;
  steps: number;
  program: Program;
  fitsConstraints: boolean;
}
```

`commands` is the slots the program uses (see Programs). Without `REPEAT` it is the program length and equals `steps`. `steps` is the number of primitives the program executes to reach the goal. `fitsConstraints` is `commands <= constraints.maxCommands && steps <= constraints.maxSteps`. The search ignores both constraints; a `false` means the level's budget is below par.

**Without `REPEAT` in `availableCommands`** it is a breadth-first search over the states `(x, y, facing)`. The tie-breaking is specified so another language produces the **same program**, not only the same length:

1. The queue is FIFO and starts with the initial state, which is marked discovered.
2. Dequeue a state and try the available commands in this fixed order: `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`. Commands not in `availableCommands` are skipped.
3. `MOVE_FORWARD` produces no new state if the cell ahead is off the board or a wall. Otherwise it produces the state with the new cell and the same facing. A turn produces the state with the same cell and the new facing.
4. If the produced state was already discovered, ignore it. Otherwise mark it discovered, remember the dequeued state as its parent and the command used, and append it to the queue.
5. **Stop at the first discovered state whose cell is the goal cell** (checked at the moment of discovery, not when dequeued). The program is the commands on the path from the start to that state.
6. If the queue empties, return `null`.

Because parents are recorded on first discovery and commands are tried in a fixed order, the result is unique. Examples: facing north with the goal directly behind gives `TURN_LEFT, TURN_LEFT, MOVE_FORWARD` (not the equally short `TURN_RIGHT` twin), and a detour that could pass above or below a wall takes the route whose first differing command comes earlier in the order `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`. If the start were the goal (invalid level), the result would be the empty program with 0 commands.

**With `REPEAT` or `REPEAT_UNTIL` offered** the search is exact over programs whose loop bodies hold at most 8 primitives (which is also the most a body may hold). It runs in a few milliseconds to well under a second on boards up to 12 by 12. The method, so another language reproduces the exact program:

1. A _behaviour_ maps every state `(x, y, facing)` to where a piece of program leaves the automaton and the steps it took, or to "failed", or to "entered the goal" (the run stops there, successfully; steps count up to and including the entering move). Behaviours of a sequence and of a loop follow from the simulator rules above.
2. **Bodies** are enumerated by length 1 to 8. Length 1 is the available primitives in the order `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT`. Length k+1 extends each body of length k, in order, by each available primitive in that order. A body whose behaviour equals that of any earlier body is skipped.
3. **Edges** are, in order: the available primitives (cost 1 slot); then for each body length 1 to 8, each body in order, each `count` from 2 to 11, the loop `REPEAT count { body }` (cost 1 + body length), skipped unless `REPEAT` is offered; then, for the same body, the loop `REPEAT_UNTIL BLOCKED { body }` (cost 1 + body length), included only when `REPEAT_UNTIL` is offered. The behaviour of that loop at a state is: while the cell ahead is open, run the body; a state that comes round again without being blocked, or a run that fails, is a failure. An edge with the same behaviour and cost as an earlier edge is skipped.
4. A shortest-path search from the start state over edges. The cost of a path is compared as (slots, then steps). Take the unfinished state with the lowest cost, the lowest state index on ties, and relax every edge in edge order, updating a state only when the new cost is strictly lower. "The goal" is one more state. The program is the edges on the path to it.

Because ties favour fewer steps, then the earlier edge, the result is unique. Two programs with equal slots and equal steps can exist (for example `REPEAT 2 { MOVE_FORWARD }` and two moves); the one discovered first wins.

The game never calls the solver: it gets par from the server.

## Using the package

It ships compiled JavaScript and type declarations in `dist/` as an ES module with no runtime dependencies (the standard library only), so it loads in Node 22 (NestJS built with SWC) and in Next.js 16 alike. Import with the package name:

```ts
import { validateLevel, simulate, solve, explainResult } from "@algomind/level-contract";
import schema from "@algomind/level-contract/schema/level.v1.schema.json" with { type: "json" };
```

The package is private to the workspace; add `"@algomind/level-contract": "workspace:*"` to a consumer's dependencies and run `pnpm build` in this package (or `pnpm --filter @algomind/level-contract build`) before the consumer is built or tested, because `exports` points at `dist/`.

Public API: `validateLevel`, `validateAuthoringLevel`, `validateProgram`, `simulate`, `solve`, `explainResult`, `REASON_MESSAGES`, the small helpers `turn`, `cellAhead`, `isWall`, `isInsideBoard`, the constants (`LIMITS`, `COMMAND_NAMES`, `DIRECTIONS`, `DIFFICULTIES`, `DIRECTION_DELTAS`, `SCHEMA_VERSION`), and the types.

## Scripts

```sh
pnpm --filter @algomind/level-contract build       # tsc -> dist/
pnpm --filter @algomind/level-contract typecheck   # builds, then type-checks src and the tests
pnpm --filter @algomind/level-contract test        # builds, then node --test
```

## Fixtures for other implementations

Read `fixtures/README.md`. In short: every file in `fixtures/` is self-describing JSON. A GDScript (or any other) implementation loads each directory, runs its own validator, simulator, and solver on the `level` / `program` in each file, and compares to the expected values in the same file. Adding a case means adding a file; no test code changes. An implementation passes when every fixture matches exactly.

A new rule, command, or mechanic changes this README, the fixtures, and both implementations in the same change.
