# Plan: Chapter 3 "The Workshop" (Functions & Errors)

Status: **APPROVED (2026-11-04). Batch A (3.1 to 3.3) and Batch B (3.4 to 3.6) implemented. Not committed: Batch B.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
All wording is a draft for you to change. Room details (exact code, options, hints) get written per batch after you approve this overview.

---

## 1. Where we are
Chapters 1 and 2 are done and pushed (12 rooms, 36 stars). Chapter 3 is in the lesson plan and the GDD's MVP ("Chapters 1 to 3"). The roadmap's older "decided scope" listed Chapter 3 as out of scope, so this plan treats it as the **next stretch goal**. Deadline is 10 Dec 2026, so about 5 weeks from today.

## 2. What is different from Chapter 2
| Area | Chapters 1 and 2 | Chapter 3 | Engine work |
|---|---|---|---|
| Code length | 3 to 5 lines (panel has **5 rows**) | Methods need 6 to 8 lines | **Code panel: 5 rows → 8 rows** (scene builder change + scene rebuild) |
| Keep picture | Guards, chests, text rows | Text rows plus **call rows** ("Heal(50) returns 70") | Reuse `Evaluated`/`TextSet`; maybe one `Returned` event |
| Tools | Watch, Step, Test Runner (simple) | **Log Reader** (3.3, 3.4) and a visible **Test Runner** (3.5) | New small panel for log lines; Test Runner panel shows red/green |
| Mentor | Hint questions | "Confirms or refutes your hypothesis only" | Hint wording change (see question 3) |
| Keep map | Wing 3 is sealed | Wing opens after Chapter 2 is complete (existing unlock rule) | `isSealed` off, 6 rooms in seed and asset; tests for counts (18 rooms, 54 stars) |

## 3. The six rooms (sketches only)
| # | Type | Room | Bug / idea | Picture and tool | Engine cost |
|---|---|---|---|---|---|
| 3.1 | Predict | **The Healer Machine** | `Heal(hp)` returns 70 but the caller ignores it, so hp stays 50. Fix: `hp = Heal(hp);` | Rows: `hp = 50`, `Heal(50) returns 70`, `hp = 50` | Low (needs the 8-row panel) |
| 3.2 | Bug hunt | **The Greedy Counter** | `Total()` secretly clears the list, so asking twice gives 2 then 0 | Rows: `items = [Sword, Potion]`, `Total() returns 2`, `items = []` | Low (reuses `ArraySet`, `OutputAppended`) |
| 3.3 | Trace | **The Stack of Clues** | A crash is reported deep in `Parse`, but the real cause is the caller passing `null` | Rows: call stack `Main > Load > Parse`; **Log Reader** shows the stack trace | Medium (call stack rows, Log Reader panel) |
| 3.4 | Bug hunt | **The Silent Failure** | `catch (Exception) { }` hides the broken machine. Fix: catch the specific exception and log it | Log Reader: empty log first, then "ERROR: file not found" | Medium (Log Reader, shared with 3.3) |
| 3.5 | Repair | **Red, Then Green** | Choose the test that reproduces the bug **before** fixing it | **Test Runner** panel: red first, green after the fix | Medium (Test Runner panel; options are tests, not code changes) |
| 3.6 | Code review | **The Forty-Line Monster** | One method does four jobs. Pick the better split (`Validate / Price / Save` vs `Part1 / Part2`) | Rows list the four jobs; options are the two splits | Low to medium (long code shown as a summary, not 40 lines) |

## 4. Suggested build order (two batches)
- **Batch A (no new tools):** panel 5 → 8 rows, then 3.1, 3.2, 3.3 with call rows. Playtest in Unity.
- **Batch B (tools):** Log Reader, then 3.4; Test Runner panel, then 3.5; then 3.6.
- Keep map and catalog change (wing 3 open, 6 rooms) goes in with Batch A so rooms are reachable.
- Each batch ends with all tests passing and a Unity playthrough, like Chapter 2. You decide when to commit.

## 5. Risks
- **Code panel change** needs a scene rebuild; I will re-check Chapters 1 and 2 still look right (long lines at the old 35-character limit).
- **Log Reader and Test Runner** are new UI. If time runs short, the fallback is to show logs and test results as extra text rows (no new panel).
- **3.6** is the hardest to fit in a small code panel; if it does not read well I can swap it for a simpler room later.
- No classmate has played Chapters 1 and 2 yet. The roadmap had a slice playtest as a go/no-go. A short playtest during this chapter would catch problems early.

## 6. Questions for you
1. Is the two-batch order OK, or do you want a different room first?
2. Raise the code panel to **8 rows** (my recommendation), or keep 5 rows and write methods in fewer lines?
3. The lesson plan says the mentor only "confirms or refutes your hypothesis" in Chapter 3. Should the three hints become confirm/refute lines ("Yes, look at the return value" / "No, that part is fine"), or keep the hint questions as in Chapter 2?
4. Do you want to ask a classmate to playtest Chapters 1 and 2 while I build Batch A?

## 7. Batch A: what was built
- Answers used for the open questions: two batches (yes), code panel up to **8 rows** (yes), hints written as confirm/refute lines, classmate playtest skipped for now.
- **Code panel:** 8 rows in the scene. Up to 5 lines keep the old roomy layout; 6 to 8 lines shrink the rows and font to fit the same frame (done in `CodePanelView`, not in the data).
- **New row type:** `CallReturned` shows `Heal(50) returns 70`. Cleared with the rest of the Keep.
- **3.1 Healer Machine:** ignore the return value (best fix `hp = Heal(hp);`). **3.2 Greedy Counter:** `Total()` clears the bag (best fix: remove `bag.Clear();`). **3.3 Stack of Clues:** a null starts at `Load(null)` and crashes in `Parse` (best fix at the caller). In 3.3 the call stack is shown as a row; the Log Reader is **not** used yet, since it belongs to Batch B.
- **Keep map:** The Workshop is open (unlocks after Chapter 2 is complete) with 3 rooms for now. Totals: 15 rooms, 45 stars.
- Line limit stays 35 characters. Expression-bodied methods in 3.3 use a 2-space indent to fit.
- 282 tests pass. Played 3.1 to the end (3 stars), 3.2 to the end, 3.3 to the crash. The symptom-only and wrong fixes were not played in the game.

## 8. Batch B: what was built
- **New events:** `LogOpened`, `LogAppended`, `TestRan`. `KeepState` keeps a report list (Log, Error, Red, Green) apart from the watch rows.
- **Log Reader / Test Runner panel:** 3 text rows in the Keep (header "LOG READER" or "TEST RUNNER"). Log lines start with ">", ERROR lines are red. Tests show RED / GREEN lines.
- **3.4 The Silent Failure:** an empty catch swallows FileNotFoundException, so the log stays empty. Best fix catches it and logs the file name.
- **3.5 Red, Then Green:** `Add` subtracts. Fixes are test-first choices: failing test then fix (best), fix then test (symptom), a test that cannot fail (wrong).
- **3.6 The Forty-Line Monster:** 8 lines, 4 jobs shown as rows. Best fix splits into four named methods.
- **Totals:** Workshop 6 rooms, 18 rooms, 54 stars. 308 tests pass.
- **Played in Unity:** 3.4 and 3.5 best-fix paths (panel renders correctly), 3.6 up to the predict step. Not played: symptom-only and wrong fixes, 3.6 fix path. After the play test, 3.6 got one extra output event ("4") so the predict message no longer says "it printed ." (not re-run).
