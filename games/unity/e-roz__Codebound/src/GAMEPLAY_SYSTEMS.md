# Codebound — Gameplay Systems (v2)

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. Design only; no implementation. Supersedes the v1 block
system. See `MECHANICS.md` for the player-facing loop.

---

## 1. Key idea: a room is data + a replayable trace
A room is described by a **RoomDefinition**. The game does not execute C# in the MVP. Each room carries an **authored
trace**: an ordered list of events saying what each line does to the Keep. "Run" replays the trace; "Step" advances it
one line at a time. [RECOMMENDED]

Why: it gives full control of the lesson, is cheap and reliable, and avoids the largest technical risk (a C#
interpreter). Because rooms emit the same kind of events a real interpreter would, the interpreter can be added later
without redoing content. **[OPEN D-07]**

## 2. RoomDefinition (conceptual fields)
| Field | Meaning |
|---|---|
| `id`, `chapter`, `order`, `type` | Identity and room type (Predict/Trace/Bug Hunt/Repair/Build/Review/Interview) |
| `ticket` | Symptom text, in ticket style |
| `codeLines[]` | The C# shown, line by line |
| `trace[]` | Events for the original (buggy) code |
| `predict` | Question, options, correct answer, explanation |
| `evidence[]` | Facts the investigation can reveal (Watch values, log lines, markers) |
| `hypotheses[]` | Options; marks which are supported by evidence and which is correct |
| `fixOptions[]` | Each: description, code change, `trace` after the change, `testResult`, `consequenceText`, quality (best / works-but-heavy / symptom-only / wrong) |
| `test` | The test shown in the Test Runner (arrange/act/assert), pass/fail rules |
| `debrief` | Concept line + "where this appears at work" |
| `hints[3]` | Tala's three tiers |
| `unlocksTool`, `mentorMode` | Tool unlocked; how Bato behaves |
| `starRules` | Conditions for ★★ and ★★★ |

Authoring format: ScriptableObject or JSON (one per room). Team members with C# expertise can write rooms without
touching game code. **[RECOMMENDED]**

## 3. Trace events (the shared language)
Events are small and typed so both authored traces and a future interpreter can produce them.

| Event | Visual in the Keep |
|---|---|
| `LineExecuted(line)` | Highlight in code panel |
| `ObjectCreated(id, kind, displayName)` | Chest/guard/item appears |
| `VariableDeclared(name, type)` | Guard appears with name tag |
| `ValueAssigned(var, value)` | Value shown in pouch/Watch (value types) |
| `ReferenceAssigned(var, objectId)` | Thread connects guard to object |
| `ObjectMutated(id, change)` | Object changes; all threads to it flash |
| `NullAssigned(var)` | Thread cut; guard holds nothing |
| `Output(text)` | Log/console panel |
| `ExceptionThrown(type, line, message)` | Alarm, stack trace panel |
| `StateChecked(expr, result)` | Gate/door reacts to a condition result |

## 4. Room flow (state machine)
`Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief → Complete`
- Each state has one entry condition and one exit; the player can return to Observe/Investigate at any time before Fix.
- Predict is skippable only on replay of an already-completed room.
- Reset returns to Observe with prediction preserved.

## 5. Tools (what each does)
| Tool | Function | Unlocked |
|---|---|---|
| Watch | Lists variables, values, and which object each reference points to | Ch1 |
| Step Through | Advance one event/line | Ch1 |
| Breakpoint | Mark a line; replay pauses there | Ch2 |
| Log Reader | Console output and stack traces | Ch3 |
| Test Runner | Shows a test, runs it against current code | Ch3 |
| Inspector | Object detail (fields, collections) | Ch4+ |
| Git Notes | Change history of a room | Ch7+ |

## 6. Grading and stars (process-based)
- **Prediction:** correct/incorrect recorded.
- **Hypothesis:** must match the evidence-backed cause.
- **Fix quality:** best / works-but-heavy / symptom-only / wrong.
- **Stars:** ★ passing fix; ★★ correct prediction **and** hypothesis; ★★★ best fix **and** test passes **and**
  no more than one hint tier used. [RECOMMENDED]
- Stars measure mastery, do not gate. Hints are free but tracked.

## 7. Consequences for wrong fixes
Each non-best fix has an authored consequence trace and one-line explanation, tied to a misconception. Example:
copying a list but sharing the items → the Keep shows two lists with the same sword in both, and the test
`Items_AreIndependent` fails with the reason.

## 8. Mentor and Tala (support)
- `mentorMode` per room: `Explains` (Ch1), `AsksHintQuestions` (Ch2), `ConfirmsOnly` (Ch3–4), `Absent` (Ch5+).
- Tala always offers three hint tiers.
- Lines come from a dialogue table keyed by room, mode and trigger (start, wrong fix, hint, success, debrief).
- Player name is substituted into lines. [CONFIRMED]

## 9. Content validation [RECOMMENDED]
An editor-time validator checks each room: unique ids; every trace references real lines; exactly one `best` fix;
hypothesis correct answer exists; every fix has a trace and a test result; hints present; debrief present. Failing
rooms cannot ship.

## 10. Content accuracy
All C# facts reviewed by a C# expert on the team before a room is accepted. Where behaviour varies by runtime or
version, state the version or avoid the case.

## 11. Cautions
- Keep the trace vocabulary small; add an event type only when a room needs it.
- Do not make the player type; do not add free text hypotheses.
- Keep snippets short and consistent in style (naming, braces, formatting).
- Avoid claiming the game runs real code while the MVP replays traces; say "simulation" in credits/UI honestly.
