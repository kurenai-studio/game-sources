# What an Operation May Change

Each operation may change only the state items assigned to it.

Status and provenance are recorded in `DECISIONS.md`, row D31. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: D16 (`docs/phase-1-state-decision.md`) sections 1.1 and 4, D17, D18 (R1) and D20, which define the authoritative game state items 1 to 16 and the authoritative transition boundary. This file changes no bytes of any of them.

## Decision text

**Z1. Frame principle.** Each legal operation may change only the authoritative game state (D16 section 1.1 items 1 to 14, D17 item 15, D20 item 16) that is explicitly assigned to that operation. All other authoritative game state is preserved by the operation. A change to state not assigned to the operation is a violation, not a permitted side effect.

**Z2. What this does not decide.** Z1 chooses the principle only. It does not adopt any operation table, and it does not assign any item to any operation. Which items each operation is assigned stays to be recorded from the requirements and decisions, operation by operation. Where the sources are silent on an operation's effect on an item, that point stays unspecified and is not treated as assigned or excluded by Z1. The timing and order of persistence effects, such as when a line-clear save is written, are not decided by Z1. Draft tables prepared earlier are proposals and are not adopted.

## Not decided here

- Any operation table, and any assignment of items to operations.
- The effect of a cancelled touch, the timing of the line-clear save, and whether held-direction tokens survive a pause and whether repeat restarts on resume.
- Any change to REQUIREMENTS.md and any code change.
- Closure of the Phase 1 exit item on operations (blueprint O1) or of any other exit item.
