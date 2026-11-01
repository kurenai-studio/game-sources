# Fixtures

Language-neutral JSON test data for the level contract. The TypeScript tests and the GDScript (GUT) tests both run **every** file here and must produce identical results. The rules these fixtures exercise are specified in `../README.md`; read that first.

Every file is one JSON object and has a `description` string explaining what the case shows. Adding a case means adding a file; no test code changes. File names (without `.json`) are unique within a directory and are used only in test names.

Coordinates are `[x, y]`, x grows right, y grows down. Programs are lists of `{ "op": "<COMMAND>" }` nodes, where a loop is `{ "op": "REPEAT", "count": 3, "body": [ ...primitive nodes ] }`. Numbers are JSON integers.

## `levels/valid/*.json`

```json
{ "description": "...", "mode": "public", "level": {} }
```

- `mode`: `"public"` means call the public validator (`validateLevel`: no `referenceSolution` allowed). `"authoring"` means call the authoring validator (`validateAuthoringLevel`: `referenceSolution` required).
- Expected: the validator returns `ok = true` and no issues.

## `levels/invalid/*.json`

```json
{
  "description": "...",
  "mode": "public",
  "level": "<any JSON value>",
  "expectedIssues": [{ "path": "board.width", "code": "OUT_OF_RANGE" }]
}
```

- `level` may be any JSON value, including `null` or an array.
- Expected: `ok = false`, and the set of `(path, code)` pairs the validator returns equals `expectedIssues` exactly: no missing pairs and no extra ones. Order does not matter; there are no duplicate pairs. `message` is not compared.
- `path` syntax: keys joined with `.`, array indexes in brackets (`board.walls[2]`, `referenceSolution[1].op`), and `""` for the document root.

## `runs/*.json`

```json
{
  "description": "...",
  "level": {},
  "program": [{ "op": "MOVE_FORWARD" }],
  "programIssues": [{ "path": "program[0].op", "code": "COMMAND_NOT_AVAILABLE" }],
  "expected": {
    "status": "FAILED",
    "reason": "BLOCKED_BY_WALL",
    "steps": 2,
    "finalState": { "position": [1, 2], "direction": "east" },
    "blockedCell": [2, 2],
    "trace": [
      {
        "index": 0,
        "op": "MOVE_FORWARD",
        "position": [1, 2],
        "direction": "east",
        "event": "MOVED"
      }
    ]
  }
}
```

- `level` always passes `validateLevel`.
- `programIssues`: the `(path, code)` pairs `validateProgram(level, program)` must return, compared as a set (empty list means the program is valid). The path prefix is `program`.
- `expected`: the exact result of `simulate(level, program)`. **`simulate` runs the program even when `programIssues` is not empty** (it checks neither `availableCommands` nor `maxCommands`); the fixtures `disallowed-command` and `max-commands-exceeded` pin this down. An unknown `op` is the exception: it stops the run with `INVALID_INSTRUCTION`.
- Compare every field. `blockedCell` is `null` unless the reason is `BLOCKED_BY_WALL` or `BLOCKED_BY_BOUNDARY`. `trace` has one entry per executed step in order, `steps` equals its length, and each entry has exactly `index`, `op`, `node`, `call`, `counter`, `round`, `position`, `direction`, `event` (`node` is the path of the instruction, see the README; `call` is the path of the running `CALL` or `null`; `round` is `null` outside a loop). `position` and `direction` in a trace entry and in `finalState` are the state **after** the step; a blocked move leaves the position unchanged. For field values and semantics (what counts as a step, when the limit is checked, what ends a run) see "The simulator" in `../README.md`.

## `boards/*.json`

```json
{
  "description": "...",
  "level": {},
  "program": [{ "op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [{ "op": "MOVE_FORWARD" }] }],
  "programIssues": [],
  "expected": {
    "status": "SUCCEEDED",
    "firstFailure": null,
    "steps": 22,
    "results": [
      {
        "status": "SUCCEEDED",
        "reason": "GOAL_REACHED",
        "steps": 4,
        "finalState": { "position": [4, 1], "direction": "east" },
        "blockedCell": null
      }
    ]
  }
}
```

- `level` carries `extraBoards` (or not) and passes `validateLevel`. `programIssues` is as for runs.
- `expected` is the result of `simulateAll(level, program)` without the traces: `status`, `firstFailure`, the summed `steps`, and for every board its `status`, `reason`, `steps`, `finalState` and `blockedCell`. All boards are always run.

## `solver/*.json`

```json
{
  "description": "...",
  "level": {},
  "expected": {
    "commands": 3,
    "steps": 3,
    "fitsConstraints": true,
    "program": [{ "op": "MOVE_FORWARD" }, { "op": "MOVE_FORWARD" }, { "op": "MOVE_FORWARD" }]
  }
}
```

- `expected` is either `null` (the goal cannot be reached; `solve` must return nothing/null) or an object. Compare `commands`, `steps`, `fitsConstraints`, and the **exact** `program` (same ops in the same order). Different programs of the same length are a failure: the tie-breaking rule in "The solver" in `../README.md` makes the program unique.
- `fitsConstraints` is `commands <= constraints.maxCommands && steps <= constraints.maxSteps`.

## `scoring/*.json`

```json
{
  "description": "...",
  "rules": {
    "version": 1,
    "base": { "easy": 10, "medium": 20, "hard": 30 },
    "parFull": 10,
    "parNear": 5,
    "nearSlots": 2,
    "stepsBonus": 5,
    "firstClear": 10
  },
  "input": { "difficulty": "easy", "par": { "commands": 5, "steps": 5 }, "slots": 5, "steps": 5 },
  "expected": { "stars": 3, "points": 25, "levelScore": 35 }
}
```

- `expected` is the exact result of `scoreResult(rules, input)`: stars (3 at par slots or better, 2 within `nearSlots`, otherwise 1), `points` (base by difficulty plus the par bonus plus the steps bonus) and `levelScore` (`points` plus `firstClear`).
- The game mirrors it in `scripts/contract/scoring.gd` for the provisional score shown offline.

## Pass criteria for an implementation

1. Every `levels/valid` file validates with no issues in its `mode`.
2. Every `levels/invalid` file fails with exactly its `expectedIssues`.
3. Every `runs` file gives exactly its `programIssues` and `expected`.
4. Every `solver` file gives exactly its `expected`.
   (A `boards` file gives exactly its `expected` through `simulateAll`; the GDScript implementation runs these too.)
5. Every `scoring` file gives exactly its `expected`.

The GDScript implementation (`apps/game/scripts/contract/`) satisfies criteria 1 to 3 and 5 and deliberately skips 4: the game gets par from the server and has no solver. It reads these files through `make game-fixtures`, which copies this directory into `apps/game/tests/contract_fixtures/` (git-ignored) before the game's checks and tests run.

The two implementations also share the rule that **the fixtures win**: if an implementation disagrees with a fixture, fix the implementation (or, if the rule itself is wrong, change the README, the fixture, and both implementations together).
