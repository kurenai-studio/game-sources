# Plan: Chapter 5 "The Great Hall" (OOP in Practice) and Chapter 6 "The Messenger Towers" (Data & Systems)

Status: **APPROVED 2026-11-04. Chapter 5 BUILT (6 rooms, 404 tests pass, all fix paths played in Unity). Chapter 6 BUILT (6 rooms, 452 tests pass, all fix paths played in Unity).**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
All wording is a draft for you to change. Exact code, options and hints get written per batch while building. Sample names in game text use only your list: Jean, Thea, Coco, Mokky, Toffee (no Ana, Ben).

---

## 1. Where we are
Chapters 1 to 4 are done and pushed (24 rooms, 72 stars, 356 tests). `STORY.md` gives the themes: **Ch 5** "tangled ancient designs", where **Bato leaves** and only short notes remain; **Ch 6** "messages arrive wrong, late, or twice". The GDD table lists both as stretch chapters (OOP in Practice; SQL, HTTP, JSON). Deadline is 10 Dec 2026, about 5 weeks away.

## 2. What is different from Chapter 4
| Area | Chapter 4 | Chapters 5 and 6 | Engine work |
|---|---|---|---|
| Code length | 4 to 8 lines | Same (8-row panel, 35 characters per line) | None. SQL, JSON and HTTP are written as short lines |
| Keep picture | Collection rows, counters | Object rows (`guard.Name = Thea`), call rows, "table" rows (`users: 3 rows`), message rows (`sent: order #7 (twice)`) | Reuse `TextSet`, `ArraySet`, `IntSet`, `CallReturned`, `ExceptionThrown`. No new event expected |
| Mentor | Confirms or refutes | **Ch 5: Bato is gone.** Hints become short notes only, signed by Tala (wording change only). Ch 6 same | Hint text only |
| Keep map | Archive open | Great Hall opens after Chapter 4, Towers opens after Chapter 5 (same unlock rule) | `isSealed` off for two wings; tests (36 rooms, 108 stars) |
| Industry link | Collections | OOP habits in real codebases; databases, JSON and web calls | None |

## 3. Chapter 5 rooms (sketches)
| # | Type | Room | Bug / idea | Picture | Industry link |
|---|---|---|---|---|---|
| 5.1 | Predict | **The Shared Counter** | `static int count` is shared by all guards, so every guard sees the same number. Fix: instance field | `Thea.count`, `Jean.count` both 2 | Static state shared by accident |
| 5.2 | Bug hunt | **The Open Door** | A public field lets any code set `Gold = -50`. Fix: private field with a method that checks the value | `chest.Gold = -50` | Encapsulation: protect invariants |
| 5.3 | Trace | **The Quiet Alarm** | Base reference calls the base method because `virtual` and `override` are missing, so the guard's alarm never rings. Fix: `virtual` / `override` | Call rows: `alarm.Ring() returns "..."` | Polymorphism bugs in plugins |
| 5.4 | Bug hunt | **The Identical Twins** | Two objects with the same data are not `==` (reference equality). Fix: `Equals` (or a `record`) | `a == b` is false though both are Coco | Duplicate checks in lists and dictionaries |
| 5.5 | Repair | **The Flightless Bird** | `Penguin : Bird` inherits `Fly()` and throws. Fix: split into an interface (`ICanFly`) or composition | `Penguin.Fly()` throws `NotSupportedException` | Inheritance vs composition |
| 5.6 | Code review | **Depend on the Interface** | A class creates its own database with `new`, so it cannot be tested. Pick the better design: pass an `IStore` in | Rows list what the test can replace | Dependency injection, interview favourite |

## 4. Chapter 6 rooms (sketches)
| # | Type | Room | Bug / idea | Picture | Industry link |
|---|---|---|---|---|---|
| 6.1 | Predict | **The Lost Customers** | `INNER JOIN` drops customers with no orders. Fix: `LEFT JOIN` | `customers: 3 rows`, `joined: 2 rows` | Reports with missing rows |
| 6.2 | Bug hunt | **The Missing WHERE** | `UPDATE ... SET ...` with no `WHERE` changes every row. Fix: add `WHERE id = 7` | `rows changed: 500` | The classic production incident |
| 6.3 | Trace | **The Empty Name** | JSON key is `"name"`, the class property is `Name` with strict matching, so the value is null and later code crashes. Fix: match the key | `json.name = Mokky`, `user.Name = null` | API data that parses "fine" but is empty |
| 6.4 | Bug hunt | **The Order That Arrives Twice** | A timeout makes the client retry a POST, so the order is created twice. Fix: an idempotency key | `sent: order #7`, `server: 2 orders` | Retries and duplicate payments |
| 6.5 | Repair | **The Hidden 404** | Code treats any reply as success, so a `404` is saved as data. Fix: check the status code (retry on 5xx only) | `status = 404`, `saved: "Not found"` | Reading HTTP status codes |
| 6.6 | Code review | **Trust No Input** | Query built with `+` from user text lets `' OR 1=1` in. Pick the safer version: a parameterised query | Rows show the final query text | SQL injection, a top security topic |

Fix options follow the usual pattern: **Best**, **SymptomOnly** (quieter but the cause stays), **Wrong** (plausible but still fails).

## 5. Suggested build order (four batches, same loop each time)
- **Batch 5A:** Great Hall wing opens, 5.1 to 5.3. **Batch 5B:** 5.4 to 5.6.
- **Batch 6A:** Towers wing opens, 6.1 to 6.3. **Batch 6B:** 6.4 to 6.6.
- Each batch: code, unit tests (headless), play every room in Unity with all three fixes, update this file, **commit only when you say so**, then ask about pushing.

## 6. Risks
- **SQL, JSON and HTTP are shown as simulated traces**, not a real database or server (authored traces, decision D-07). The debriefs say so.
- **Some 6.x code lines are long** (35-character limit). I will shorten names and split queries over lines as I did before.
- **Time.** Four batches at the same pace as Chapters 3 and 4. If the schedule gets tight, Chapter 5 alone is a complete chapter and Chapter 6 can stop after 6A.
- **Teaching accuracy.** I will keep each fix a recognised best practice (for example `ContainsKey` before `TryGetValue` style trade-offs are mentioned in the debrief), and you can veto any room that does not match your lessons.

## 7. Questions for you
1. Is Chapter 6 (SQL, HTTP, JSON) OK for IT students in your course, or do you want a different Chapter 6 topic (for example Git or testing)?
2. Build everything in order (5A, 5B, 6A, 6B) and report after each batch, or stop after Chapter 5 for your check?
3. Do you want the Inspector header from Chapter 4's plan after all, or keep plain rows?


## 8. Chapter 5 built (2026-11-04)

Rooms 5.1 to 5.6 are in (Room51..Room56, tests Room51Tests..Room56Tests). Great Hall wing opens after Chapter 4. Each room was played in Unity on all three fix paths; layouts fit, messages correct. Side fix: the Observe message no longer says "it printed ." when a room prints nothing (RoomFlow.ObserveBody). Totals: 30 rooms, 90 stars.

## 9. Chapter 6 built (2026-11-04)

Rooms 6.1 to 6.6 are in (Room61..Room66, tests Room61Tests..Room66Tests): INNER vs LEFT JOIN, UPDATE without WHERE, JSON key vs property, retries and idempotency, ignoring HTTP status, SQL injection. The Towers wing opens after Chapter 5. No new engine code. Totals: 36 rooms, 108 stars. Only the Architect's Chamber stays sealed.
