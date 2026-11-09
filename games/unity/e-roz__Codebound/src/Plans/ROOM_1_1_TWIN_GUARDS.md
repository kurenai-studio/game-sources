# Plan: Room 1.1 "The Twin Guards" (Vertical Slice)

Status: **PLAN v2 (2026-11-03), updated after your check. Waiting for your approval. No code written yet.**
Changes in v2 are marked **[v2]**.
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## 1. Goal
Prove the core idea end to end with one room: the player predicts, watches the Keep act out C# code, investigates,
picks a cause, picks a fix, runs a test, and reads a debrief. Success = a classmate finishes it unassisted and can
explain reference vs value afterwards (see `DEVELOPMENT_ROADMAP.md`).

## 2. The room (content, from `LESSON_PLAN.md` 1.1)
**Ticket:** "Vault B has a sword nobody put there."
```csharp
1  Chest vaultA = new Chest();
2  Chest vaultB = vaultA;
3  vaultA.Add("Sword");
4  Console.WriteLine(vaultB.Count);
```
**[v2] Chest class panel:** a small collapsed "Chest class" box next to the code shows the class the player is not asked to
change, so `Add` and `Count` are not magic:
```csharp
class Chest
{
    List<string> items = new List<string>();
    public void Add(string item) => items.Add(item);
    public int Count => items.Count;
}
```
**Predict:** "What does line 4 print?" Options: `0`, `1`, `2`, `An error`. Correct: `1`.
Explanation: line 2 copies the *reference*, not the chest, so both names point to one chest.

**Trace (11 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(vaultA), ObjectCreated(#1, Chest), ReferenceAssigned(vaultA → #1) |
| 2 | LineExecuted(2), VariableDeclared(vaultB), ReferenceAssigned(vaultB → #1) |
| 3 | LineExecuted(3), ObjectMutated(#1, "Sword added") |
| 4 | LineExecuted(4), Output("1") |

**Hypotheses (pick the cause):**
- A. "Line 3 adds the sword to both chests." — wrong (there is only one chest).
- B. "Line 2 makes a second chest." — wrong (misconception).
- C. **"Line 2 copies the reference, so both guards point to one chest."** — correct.

**Fix options:**
| Option | Change | Quality | Test result | Consequence shown |
|---|---|---|---|---|
| 1 | `Chest vaultB = new Chest();` | **Best** | Pass | Two chests; vaultA holds the sword, vaultB is empty |
| 2 | Add `vaultA.Remove("Sword");` after line 4 | Symptom-only | Fail | Both guards still share one chest; the sword is lost; test fails ("vaultA should still hold the Sword") |
| 3 | `Chest vaultB = null;` | Wrong | Fail | Guard B holds nothing; line 4 throws NullReferenceException |

**Test (shown in Test Runner):** `vaultA.Count == 1` and `vaultB.Count == 0`.
**Debrief:** "Assigning one object variable to another copies the *reference*, not the object. At work this is the bug
behind shared caches and settings that change behind your back."
**Hints (3 tiers):** (1) "How many chests exist after line 2?" (2) "A class variable holds a reference, like a rope to
the chest." (3) "Line 2 creates a second rope, not a second chest."
**[v2] Stars:** only the best fix passes the test, so "passing fix" and "best fix" are the same thing.
★ = the room is completed (best fix passes). ★★ = ★ and the prediction and the cause were both right on the first try.
★★★ = ★★ and at most 1 hint tier used. Stars never go down on replay (`UnlockRules.Record`).

## 3. Scope of this slice
**In:** everything in §2; Predict/Observe/Investigate/Hypothesis/Fix/Prove/Debrief flow; Run, Step, Reset; code panel
with line highlight; Keep scene using the Kenney tiles already imported; Watch panel; three hints; stars.
**[v2] Now also in (they exist already):** entering from the Keep Map's Enter room button (room 1.1 only; others stay
"coming soon"); saving stars through `PlayerSave.progress` when the room completes; returning to the Keep Map after the
debrief; the Silkscreen UI font and the JetBrains Mono code font; the click sound.
**Out (later):** dialogue service, audio beyond the click, ScriptableObject authoring, validator, Breakpoint/Log
tools, Tala/Bato dialogue. **Room data is written in code for now** (a factory class), converted to
ScriptableObject/JSON in Phase 3. **[RECOMMENDED]**

## 4. Build phases (each ends with check and test)
### Phase A — Core logic, plain C#, no Unity visuals (build first)
Folders: `Assets/_Project/Scripts/Core/` with assembly definition `Codebound.Core` (no engine references);
`Assets/_Project/Tests/EditMode/` with `Codebound.Tests.EditMode` (references Core and NUnit).
Namespace `Codebound.Core`. C# 9 limits in Unity 2022.3: no `record` types.

| Type | Responsibility |
|---|---|
| `TraceEventType` (enum) | LineExecuted, VariableDeclared, ObjectCreated, ReferenceAssigned, ObjectMutated, NullAssigned, Output, ExceptionThrown |
| `TraceEvent` | One immutable event: type, line, variable name, object id, text; static factory methods |
| `TracePlayer` | Holds an event list; `Step()`, `RunToEnd()`, `Reset()`, `Position`, `HasNext`; raises `EventPlayed` |
| `RoomDefinition` | Id, title, ticket, code lines, trace, predict question, hypotheses, fix options, hints, debrief |
| `PredictQuestion`, `Hypothesis`, `FixOption` | Small data classes (FixOption has `FixQuality` enum, consequence trace, test result and message) |
| `RoomSession` | State machine: Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief → Complete; tracks prediction, hypothesis, fix, hints used; computes stars |
| `Room11` | Static factory that builds the room 1.1 `RoomDefinition` |

**Edit-mode tests (NUnit):**
1. `TracePlayer` plays events in order, `Step` advances one, `HasNext` false at end, `Reset` returns to start.
2. `RunToEnd` raises exactly 11 events for room 1.1.
3. `Room11` data is valid: 4 code lines; every event's line is 1–4; exactly one `Best` fix; one correct hypothesis;
   correct prediction index points to the "1" option; 3 hints; debrief present.
4. `RoomSession` rejects out-of-order actions (e.g., choosing a fix before observing).
5. Stars: correct prediction + hypothesis + best fix + ≤1 hint = ★★★; wrong prediction + best fix = ★; symptom-only
   fix = not complete.
6. Wrong fixes do not complete the room and expose their consequence trace and message.

**Phase A done when:** all tests pass in Test Runner; Core has zero `UnityEngine` references.

### Phase B — Keep scene and code panel (Unity editor, guided by you)
**[v2] First step:** a tiny scene loader plus a `GameSession` object that remembers the chosen room id, so the Keep Map's
Enter room opens scene `Room` and the room can return to the `MainMenu` scene (opening on the Keep Map, not the title).
Scene `Room` (2D). Placeholder art: coloured squares/sprites. `KeepView` listens to `TracePlayer.EventPlayed`
and shows: chest (square) appears on ObjectCreated; guard (square with name tag) on VariableDeclared; thread
(`LineRenderer`) on ReferenceAssigned; flash and sword icon on ObjectMutated. `CodePanel` (TextMeshPro) shows lines and
highlights the current one. Layout: left Keep ~55%, right code panel, bottom controls, per `MECHANICS.md`.
**Phase B done when:** pressing Run replays all 11 events visually; Step goes one event at a time; Reset clears.

### Phase C — Flow UI
Predict panel (4 options) → Observe → Investigate (Watch panel: vaultA → #1, vaultB → #1) → Hypothesis (3 options) →
Fix (3 options, each shows its consequence replay) → Prove (Test Runner shows pass/fail) → Debrief + stars. Hint button
(3 tiers). `RoomSessionPresenter` connects `RoomSession` to the UI; **no rule logic in UI scripts**.
**Phase C done when:** the full loop is playable from first screen to debrief with no console errors.

### Phase D — Playtest
You, then one classmate, unassisted. Ask: "Explain why vaultB.Count was 1." Record confusion points.

## 5. Principles for the code
- Core is plain C#; MonoBehaviours only in World/UI.
- Events upward; the UI never mutates `RoomSession` state directly (calls its methods).
- Small classes, one job each; no singletons; no premature abstractions (no interfaces until a second implementation
  exists, **except** `ITraceSource`, deferred until the interpreter spike).
- Match naming: PascalCase types, `_camelCase` private fields, comments only for non-obvious intent.

## 6. Verification matrix (used for the "check against the original plan" step)
| Plan item | Checked how |
|---|---|
| 11 trace events as in §2 | Test 2 and manual replay |
| 3 hypotheses, 1 correct | Test 3 |
| 3 fixes with stated qualities and consequences | Tests 3 and 6, manual run of each |
| Predict question, correct = "1" | Test 3 |
| State order enforced | Test 4 |
| Star rules | Test 5 |
| Core has no UnityEngine dependency | asmdef setting + compile |
| Run/Step/Reset behave as described | Manual check in Phase B |
| Full loop playable | Manual check in Phase C |
| No console errors or warnings introduced | Console check after each phase |

## 7. Risks
- Thread drawing and layout clutter (mitigate: fixed positions, 2 guards and 1 chest only).
- Code panel line highlighting with TextMeshPro rich text (mitigate: one text object per line).
- Unity asmdef and test setup problems (mitigate: do Phase A setup first and run one trivial test).
- Time: slice budget ~24 h (Week 1) plus finish in Week 2; if Phase C slips, cut Step visualisation polish first.

## 8. Your answers (2026-11-03)
1. Content and wording accurate: **yes**. Add the collapsed Chest class panel **[v2]**.
2. Three fixes and consequences good for teaching: **yes**.
3. Room data in code for now: **yes**.
4. Check and test after **each phase**: **yes**.

## 9. Original open questions
1. Is the content in §2 technically accurate and well worded? (You are the C# expert.)
2. Are the three fix options and their consequences right for teaching?
3. Are you happy that room data lives in code for now (Phase 3 moves it to ScriptableObjects)?
4. Do you want the build in four phases, with a check and test after each, or only at the end?

## 10. Change after first playtest (2026-11-03): verdict for every choice
You played Phase C and said wrong choices gave almost no feedback. Now every choice shows a big banner:
**CORRECT!** (green), **CLOSE, BUT NOT YET** (yellow) or **NOT QUITE** (red), plus a one-line reason. It stays until the next
choice. Tried options stay tinted. Stars are unchanged (Close counts as a wrong try).

| Step | Option | Verdict |
|---|---|---|
| Predict | "1" | Correct (shown at once; the answer is not revealed) |
| Predict | 0, 2, An error | Wrong |
| Cause | "Line 2 copies the reference..." | Correct |
| Cause | "Line 2 makes a second chest." | Close (right line, wrong idea) |
| Cause | "Line 3 adds the sword to both chests." | Wrong |
| Fix | `new Chest()` | Correct (after Run test) |
| Fix | `vaultA.Remove("Sword")` | Close (hides the symptom) |
| Fix | `vaultB = null` | Wrong (crashes) |

Result: built, play-tested (wrong prediction, close cause, correct cause, close fix), 154 edit-mode tests pass.

### Second playtest change: the test runs by itself
Players did not know to press **Run test** after a fix replayed, so it looked stuck. The Run test and Pick another fix
buttons are gone. Now: pick a fix, watch it replay, and when it ends the test runs by itself and the verdict banner shows.
A passing fix goes straight to the debrief (Finish button). A wrong or close fix keeps the replay on screen with the fix
list ready, so the player can pick again. Result: built, play-tested, 156 edit-mode tests pass.

### Third playtest change: say what the fix must achieve
- Players could not tell why a new chest counts as the fix. Each room now has a **Goal** line.
- Room 1.1 goal: "Vault A keeps the Sword. Vault B stays empty."
- It shows on the Ticket screen and in the Fix prompt ("Pick a fix. Goal: ...").
- Checked in the game: both texts fit and wrap. 157 edit-mode tests pass.
