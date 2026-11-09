# Codebound — Gameplay Systems & Programming Instruction Design

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. Design only; no implementation.

---

## 1. Approach comparison (Task 5)

| Option | What it is | Complexity | Pros | Cons | Fit |
|---|---|---|---|---|---|
| **A. Custom block editor on Unity UI (uGUI)** | We build draggable block UI, snapping, and our own program data model | Medium-high (the biggest single feature) | Full control; fits our exact blocks; runs in a built game; easy to give educational feedback; no licence issues | We must build drag-drop, layout, and nesting ourselves | **Best** |
| B. Unity UI blocks with simplified "slot" model | Same as A but blocks live in ordered *slots* (no free-form snapping) | Medium | Much easier layout and nesting; fewer edge cases; touch/mouse friendly | Less "free" feel than Scratch | **Best way to do A** |
| C. Node-based (wires between nodes) | Graph of nodes and connections | High | Flexible, visually impressive | Wire layout is messy, hard for beginners, hard to show execution order, hard to nest loops | Poor |
| D. Unity Visual Scripting / Bolt | Unity's own graph tool | Medium to integrate, high to customise | Exists already | **Editor tool for developers, not a runtime player-facing editor**; cannot be shown to players as our UI | Not viable |
| E. Third-party block libraries (Blockly via WebView, asset-store block tools) | Embed Google Blockly or buy an asset | High integration risk | Mature drag-drop | Blockly is JavaScript (needs WebView; awkward in Unity desktop builds), looks non-native, licensing/asset quality unknown | Poor for a pixel-art game |
| F. Typed code | Player writes real/pseudo code | High (parser, errors) | Authentic | Wrong target for beginners; syntax errors dominate learning | Not for MVP |

### Recommendation [RECOMMENDED]
**Option B: a custom uGUI block editor with a slot-based, tree-shaped program model.**
- Blocks are prefabs; each block holds a small data object (the *instruction*); containers (Repeat, If, Function)
  own child "slots".
- A drop is a *slot insertion*, not a free-form geometric snap. This removes the hardest class of bugs
  (overlap tests, magnetic snapping, orphaned blocks).
- The visual layer renders the program tree; the **program tree is the source of truth**. UI never executes
  anything.
- Keep a *click-to-append* alternative to drag-drop.

## 2. Separation of concerns (important)
Three layers that never reach into each other:

1. **Program model** (pure C#): `Program`, `Instruction` nodes. No UnityEngine types.
2. **Interpreter / simulator** (pure C#): runs the program against a `WorldState` and emits a list of
   *events* ("Hero moved to (3,2)", "Switch toggled", "Hero hit wall").
3. **Presentation** (Unity): block UI, hero animation, highlight, camera, sound — all driven by events.

Why: you can unit test levels without opening Unity's play mode, you can run a solver over every level, and the
animation speed/Step feature falls out for free (replay the same events at any speed).

## 3. Instruction set
**Chapter I — Sequence**
| Block | Effect |
|---|---|
| Move Forward | Move one cell in facing direction; fail if blocked |
| Turn Left / Turn Right | Rotate 90° |
| Interact | Act on the cell in front (lever, key, chest); fail/no-op if nothing there |

**Chapter II — Loops**
| Block | Effect |
|---|---|
| Repeat N times { … } | Run child sequence N times (N chosen by player, limited range) |
| Repeat Until (condition) { … } | Loop while condition false; includes an infinite-loop guard |

**Conditionals**
| Block | Effect |
|---|---|
| If (condition) { … } | Run only when true |
| If / Else | Two branches |
| Conditions (sensors) | Path Ahead Clear, Wall Ahead, On Switch, Item Here, Door Open, Counter > N |

**Variables / counters**
| Block | Effect |
|---|---|
| Set counter to N, Change counter by ±N | Numeric variable (start with one or two named counters, e.g. Keys) |
| Compare | Counter =, <, > value, used as a condition |

**Functions**
| Block | Effect |
|---|---|
| Function “Name” body | Separate program canvas |
| Call Name | Runs that function’s body (no parameters at first) |

Keep parameters, return values, recursion, and multiple data types out of the MVP.

## 4. Program model (concept)
A program is a tree:

```
Program
 └─ Sequence [ Instruction, Instruction, ... ]
        Instruction ∈ { Action(kind), Repeat(count, Sequence), RepeatUntil(Condition, Sequence),
                        If(Condition, Sequence, optional Sequence), SetCounter(...), Call(FunctionId) }
```
Each node has a stable `InstructionId` so the UI can highlight it and error messages can point to it.

## 5. From blocks to character actions
1. **Build:** the UI edits the program tree (add, move, remove).
2. **Validate (pre-run):** check static problems (empty program, call to undefined function, block budget
   exceeded, empty condition slot) and report them *before* running. These are friendly "your program isn't ready"
   messages.
3. **Compile/flatten (optional):** convert the tree to a flat list of steps with jumps, or interpret the tree
   directly with an explicit stack. [RECOMMENDED: an interpreter with an explicit stack, not Unity coroutines
   inside the logic, so Step/Pause is trivial.]
4. **Simulate:** the interpreter advances one *primitive action* at a time against `WorldState`, producing
   `ExecutionEvent`s. It stops on failure, finish, or a step-count cap (infinite loop guard, e.g. 500–2000
   primitive steps).
5. **Play back:** a presenter reads events, animates the hero, highlights the active block, and plays sounds. The
   player may change speed or press Step; the simulation is already complete (or advanced lazily), so playback
   never changes the outcome.
6. **Evaluate:** after the last event, a `GoalEvaluator` compares the final `WorldState` with the level's goals
   and returns Success or a `FailureReason`.
7. **Explain:** `FeedbackService` converts the result into a message.

## 6. Failure reasons and educational feedback (core to the brief)
Every failure is a typed result, not a string:

`ExecutionResult { Outcome, FailureReason, InstructionId, Position, Facing, Context }`

| FailureReason | Example message pattern |
|---|---|
| HitWall | "Block 4 (Move Forward) tried to move into a wall at (3,2). Check how many steps come before this turn." |
| FellInPit | "The hero stepped onto a pit. Count the cells before the pit." |
| NothingToInteract | "Interact found nothing in front of the hero. Face the lever first." |
| SwitchNotActivated | "The door is still closed because the switch was never activated." |
| GoalNotMet | "The program ended, but the hero is not on the exit." |
| IncompleteSequence | "The hero stopped 2 steps short of the exit — the sequence is incomplete." |
| WrongCondition | "The If block ran its branch when the path ahead was clear. Check the condition." |
| LoopTooLong / TooManyRepeats | "The loop ran 8 times, but only 5 were needed; extra moves hit the wall." |
| InfiniteLoop | "The program ran too long. Does your loop have a way to end?" |
| BlockBudgetExceeded | "You used 9 blocks; this room allows 6." |
| EmptySlot | "An If block has no condition yet." |

Rules for messages: say *what happened*, *where* (block highlighted and map cell flashed), and *what to check*, in
that order; never say only "Incorrect"; never give the full answer in the first message. Messages are templates
filled from the `Context`, stored in data (a ScriptableObject or table) so wording can be edited without code.

**Debug-specific support:** Step button, current-instruction highlight, a faint "ghost" path of where the hero has
been, and (later) a small variable/counter inspector panel.

## 7. Puzzle validation
- `GoalEvaluator` supports composable goals: ReachExit, CollectAllItems, ToggleSwitches(set), BlockLimit(n),
  UseConcept(Loop) (e.g. forcing a loop by capping the count of Move blocks).
- A **level solver/validator** (editor-time test) runs reference solutions against every level to ensure each is
  solvable and that intended-concept constraints actually bite. [RECOMMENDED]

## 8. Other mechanics details
- **Facing and turning** use four directions only.
- **Interact** acts on the cell in front, which keeps rules uniform.
- **Switches and doors** link by IDs defined in level data.
- **Determinism:** no randomness inside the simulation. (Random cosmetic effects only in presentation.)
- **Reset** returns `WorldState` to the level's initial state; the program remains in place.
- **Block budget** and **allowed blocks** come from the level definition.

## 9. Design cautions
- Do not allow free-floating blocks; every block lives in a slot.
- Do not add parameters/arguments until Chapter III+ and only if testing shows they are understood.
- Keep condition blocks as small “sensor” chips that drop into If/Repeat Until slots; avoid nested boolean
  algebra (AND/OR/NOT) in the MVP.
- Avoid timing-based mechanics; they undermine determinism and debugging.
