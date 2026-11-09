# Plan: Chapter 4 "The Archive" (Collections)

Status: **APPROVED (2026-11-04). Batch A (4.1 to 4.3) committed. Batch B (4.4 to 4.6) implemented, not committed.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
All wording is a draft for you to change. Exact code, options and hints get written per batch after you approve this overview.

---

## 1. Where we are
Chapters 1 to 3 are done and pushed (18 rooms, 54 stars, 308 tests). Chapter 4 is a stretch goal in the GDD ("Collections"). `STORY.md` gives the theme: lost, duplicated and slow records, and the note *"Searching the whole shelf each time is fine for now."* `MECHANICS.md` says the **Inspector** tool is earned here and the mentor only confirms or refutes (same as Chapter 3). Deadline is 10 Dec 2026, about 5 weeks away.

## 2. What is different from Chapter 3
| Area | Chapter 3 | Chapter 4 | Engine work |
|---|---|---|---|
| Code length | 5 to 8 lines | Same (8-row panel is enough) | None |
| Keep picture | Call rows, log, test panel | Rows that show a collection: `scrolls = [A1, A1]`, `Count = 2`, plus a number row `checks = 1000` | Reuse `ArraySet`, `IntSet`, `TextSet`. No new event expected |
| Tool | Log Reader, Test Runner | **Inspector**: the Keep rows show the inside of a collection (items, count, keys) | Probably just a header on the existing rows (see question 1) |
| Mentor | Confirms or refutes | Same | None |
| Keep map | Workshop open | Archive opens after Chapter 3 is complete (same unlock rule) | `isSealed` off, 6 rooms in seed and asset; tests (24 rooms, 72 stars) |

## 3. The six rooms (sketches only)
| # | Type | Room | Bug / idea | Picture | Industry link |
|---|---|---|---|---|---|
| 4.1 | Predict | **The Duplicate Scrolls** | `List.Add` accepts the same ID twice, so a report counts 2. Fix: `HashSet<string>` (or check `Contains` first) | `scrolls = [A1, A1]`, `Count = 2` | Duplicate customer or order records |
| 4.2 | Bug hunt | **The Shelf That Shrinks** | `Remove` inside `foreach` throws `InvalidOperationException` (collection was modified). Fix: `RemoveAll(...)` | List rows shrinking, then an error | The classic "works on small data" crash |
| 4.3 | Trace | **The Missing Key** | `prices["Potion"]` throws `KeyNotFoundException`. Fix: `TryGetValue` with a fallback | `prices = {Sword, Shield}`, key `Potion` not found | Config or lookup tables that miss a key |
| 4.4 | Bug hunt | **The Case-Sensitive Index** | Key `"Thea"` is stored, the search uses `"thea"`, so nothing is found. Fix: `StringComparer.OrdinalIgnoreCase` | `users = {Thea}`, lookup `thea` finds nothing | Login by email typed in a different case |
| 4.5 | Repair | **Searching the Whole Shelf** | `List.Contains` scans every item (`checks = 1000`). Fix: a `HashSet` (`checks = 1`). The "fine for now" note | Number row `checks`, red then small | Slow page at 100,000 records |
| 4.6 | Code review | **The Right Container** | Pick the better container for a job (queue of orders: `Queue` vs `List` with `RemoveAt(0)`), or a unique-tags job (`HashSet` vs `List`) | Rows list the two containers and their cost | Interview question: "which collection and why?" |

Fix options follow the Chapter 3 pattern: **Best**, **SymptomOnly** (shorter or quieter but does not fix the cause), **Wrong** (a plausible change that still fails).

## 4. Suggested build order (two batches)
- **Batch A:** wing opens in the Keep map and catalog, then 4.1, 4.2, 4.3. Playtest in Unity.
- **Batch B:** 4.4, 4.5, 4.6, plus the Inspector header if you want it.
- Each batch ends with all tests passing and a Unity playthrough, like Chapter 3. You decide when to commit.

## 5. Risks
- **Rows may get crowded.** A collection row plus `Count` plus output must still fit the Keep panel; I will keep each room to at most 4 rows.
- **4.5 shows a performance idea with a number.** It is a simulated count (authored trace), not a real timer. That matches the "authored traces" decision (D-07).
- **4.6 is a judgment room.** If it reads too abstract, I can swap it for another bug room.
- **Time.** Two batches took Chapter 3 about a session each. If the deadline gets tight, Batch A alone (3 rooms) still gives a complete mini chapter.

## 6. Questions for you
1. Inspector: add a small header ("INSPECTOR") above the collection rows like the Log Reader header (my recommendation, small), or skip it and use plain rows?
2. Keep the room order above, or put the "slow search" room (4.5) earlier because it is the most memorable one?
3. Do you want a classmate playtest of Chapters 1 to 3 **before** I build Batch A, or in parallel?

## 7. Batch A: what was built
- **Archive wing open** (unlocks after Chapter 3) with 4.1 to 4.3. Totals: 21 rooms, 63 stars, 332 tests pass.
- **No new engine code.** Rooms reuse `ArraySet`, `IntSet`, `TextSet`, `ExceptionThrown`. The Inspector header is **not** added yet (question 1, decided in Batch B).
- **4.1 The Duplicate Scrolls:** `List` keeps both `A1`; best fix `HashSet`. Variable named `ids` so the HashSet line fits 35 characters.
- **4.2 The Shelf That Shrinks:** list `{1, 1, 2}`, `Remove` inside `foreach` throws; best fix `RemoveAll`. Symptom: try/catch (loop quits early, a 1 is left). Wrong: one `Remove(1)` (only the first 1 goes).
- **4.3 The Missing Key:** `shop[key]` throws `KeyNotFoundException`. **Change from the plan:** best fix is `ContainsKey` (not `TryGetValue`), because the `TryGetValue` line is longer than 35 characters; the debrief mentions `TryGetValue`. Symptom: catch and print 0. Wrong: `shop.Count > 0`.
- **Played in Unity:** all three rooms, all three fix paths each (best fix of each gave the pass message; 4.1 got 3 stars). 8-line layout in 4.2 looks fine.

## 8. Batch B: what was built
- **Archive wing now has 6 rooms.** Totals: 24 rooms, 72 stars, 356 tests pass. No new engine code.
- **Inspector header (question 1): not added.** The plain rows already show the collection contents, so I skipped it (YAGNI). Easy to add later if you want it.
- **4.4 The Case-Sensitive Index:** `thea` vs stored key `Thea`. Best fix: a dictionary created with `StringComparer.OrdinalIgnoreCase`. Symptom: hardcode `Thea`. Wrong: `.ToLower()` on the typed name.
- **4.5 Searching the Whole Shelf:** `checks = 1000` for `List.Contains`. Best fix: `HashSet` (`checks = 1`). Symptom: `IndexOf(id) >= 0` (still 1000). Wrong: `Sort()` first (2000). The counts are simulated; the debrief says so.
- **4.6 The Right Container:** `RemoveAt(0)` on a List shifts items (`moves = 2`). Best fix: `Queue` and `Dequeue()`. Symptom: `Remove(next)`. Wrong: `Stack` (serves C first).
- **Played in Unity:** all three rooms, all three fix paths each.
