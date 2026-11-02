# Specs

The source of truth for **what** Duck Attack does. The code in `src/duck_attack/` is
**how** it does it. New features start here, as a change to a spec, before any code is
written.

## Capability specs

| Spec | Covers |
| --- | --- |
| [game-flow.md](game-flow.md) | Window, main loop, states and transitions, quitting |
| [name-entry.md](name-entry.md) | Asking for and remembering the player name |
| [round.md](round.md) | A round: timer, shooting, scoring, HUD |
| [ducks.md](ducks.md) | Duck spawning, distance, flight, hit test, falling |
| [round-end.md](round-end.md) | Round-over score screen and high-score screen |
| [high-scores.md](high-scores.md) | The persisted top-10 list |
| [audio.md](audio.md) | Shot sound and ambient duck calls |
| [presentation.md](presentation.md) | Crosshair cursor, text style, assets |
| [distribution.md](distribution.md) | Packaging, releases, CI |

## Format

Each spec has a short **Purpose**, then **Requirements**. Every requirement has:

- an ID (`FLOW-3`, `DUCK-5`, ...) that never changes or gets reused, so it can be
  referenced in discussions, change proposals and commit messages;
- a statement using **must** (required behavior) or **may** (allowed, not required);
- optional **Scenarios** in Given / When / Then form for behavior worth pinning down;
- **Verified by:** the tests that check it (or "manual" when there is no automated test).

Tunable values are written as the `settings.py` name followed by the current value, e.g.
`ROUND_DURATION` (30 s). The spec fixes the behavior; the number may be tuned in
`settings.py` without a spec change.

## Working on a new feature

1. **Propose:** copy [changes/TEMPLATE.md](changes/TEMPLATE.md) to
   `changes/NNNN-short-name.md` (next free number) and describe the motivation and the
   requirement changes: new requirements (with new IDs), changed ones (old vs. new
   wording) and removed ones.
2. **Discuss** the proposal and settle open questions until its status is `Accepted`.
3. **Implement:** change the code and add tests, naming each test in the requirement's
   "Verified by" line.
4. **Fold in:** apply the requirement changes to the capability specs, so they describe
   the game as it now is, and set the proposal's status to `Done`. Removed requirements
   are deleted from the spec; their IDs are not reused.

Small fixes that don't change behavior need no proposal. A bug fix where the code
violates a spec needs none either; fix the code (and add the missing test).
