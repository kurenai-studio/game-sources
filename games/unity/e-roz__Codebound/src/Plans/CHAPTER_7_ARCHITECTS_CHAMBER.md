# Plan: Chapter 7 "The Architect's Chamber" (First Week on the Job) and the Ending

Status: **APPROVED 2026-11-04. BUILT (6 rooms + ending, 507 tests pass, every room played in Unity on all three fix paths). Not committed yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
All wording is a draft for you to change. Exact code, options and hints get written per batch while building. Sample names in game text use only: Jean, Thea, Coco, Mokky, Toffee (no Ana, Ben).

---

## 1. Where we are
Chapters 1 to 6 are done and pushed (36 rooms, 108 stars, 452 tests). Only the Architect's Chamber is sealed. `STORY.md` says Chapter 7 is "First Week on the Job": **the root cause is found**. The twist is one day-one shortcut, a single master key for all vaults ("Temporary. Will fix."), and the final note *"If you're reading this, I never wrote the tests. I'm sorry."* The ending: the player fixes it alone, then Bato walks in and names them a Warden. The deadline is 10 Dec 2026, about 5 weeks away.

## 2. What is different from Chapters 5 and 6
| Area | Chapters 5 and 6 | Chapter 7 | Engine work |
|---|---|---|---|
| Topics | C# language, SQL, HTTP | **Work habits:** Git, reading history, tests, flaky tests, smallest safe change | None. Git and test output are shown as short code lines (35 chars) |
| Callback | Hints from Tala | Room 7.5 revisits the Chapter 1 master key. Hints are one line, no guidance beyond Tala's notes | Text only |
| Last room | Normal debrief | Room 7.6 ends with a **short ending scene** (Bato returns, names the player a Warden, last line) | **Small new UI:** one ending panel and one saved flag `endingSeen`. Replayable from the Keep |
| Keep map | Towers opens after Great Hall | Architect's Chamber opens after Towers (same rule) | `isSealed` off, catalog asset, tests (42 rooms, 126 stars) |

## 3. Chapter 7 rooms (sketches)
| # | Type | Room | Bug / idea | Picture | Industry link |
|---|---|---|---|---|---|
| 7.1 | Predict | **The Conflict Markers** | A merge left `<<<<<<<` and `>>>>>>>` lines in the file, so the build fails. Fix: choose the right parts by hand, keep both changes, delete every marker | Rows: `build = error CS8300` | Merge conflicts happen every week in teams |
| 7.2 | Trace | **The Commit That Broke It** | Eight commits, the door worked at #2 and fails at #8. Find the first bad one by checking the middle (`git bisect`) | Rows: `check #5 = good`, `check #7 = bad`, `first bad = #6` | Finding a regression quickly |
| 7.3 | Bug hunt | **The Test That Cannot Fail** | A test has no `Assert`, or catches the failure, so it is always green. Fix: assert the real result | Rows: `test = passed`, `door = open for everyone` | Green tests that prove nothing |
| 7.4 | Repair | **The Flaky Guard Test** | A test uses the real clock, so it fails at midnight. Fix: pass the time in (a fake clock) | Rows: `now = 23:59`, `test = failed`, `rerun = passed` | Flaky tests that waste team time |
| 7.5 | Trace | **The Master Key** | The root cause: one shared key opens every vault, as in Chapter 1. Fix: one key per vault, behind a test that fails first | Rows: `key = master`, `Vault 3 opened by Vault 1's key` | Root-cause thinking, security |
| 7.6 | Code review | **The Smallest Safe Change** | Choose the best fix for the key problem: a small change plus a test, over a big rewrite or a quick patch. Ends with the ending scene | Rows: `files changed`, `tests = 3 passed` | Small pull requests, tests as proof |

Fix options follow the usual pattern: **Best**, **SymptomOnly** (quieter but the cause stays), **Wrong** (plausible but still fails). In 7.6 the "big rewrite" is the Wrong option and "patch just Vault 1" is SymptomOnly.

## 4. The ending (new, small)
- After the debrief of 7.6 a **plain panel** shows 4 to 6 lines: Tala reads the Architect's last note ("I never wrote the tests. I'm sorry."), Bato walks in, "You did it alone. That is the job." and the last line "The Keep will break again tomorrow. That's the job."
- Then a closing line with the player's name and total stars. A button goes back to the Keep.
- No animation, no art needed (your art can be added later). The scene can be replayed from the Keep map. It saves `endingSeen = true` so the Keep can show a small mark.
- The save file gets one new bool. Old saves load fine (default false).

## 5. Suggested build order (two batches, same loop each time)
- **Batch 7A:** Architect's Chamber opens, rooms 7.1 to 7.3. Tests, play all three fix paths in Unity, update this file.
- **Batch 7B:** rooms 7.4 to 7.6 and the ending panel (code, unit tests for the flag, play in Unity).
- Each batch: **commit only when you say so**, then ask about pushing. Time: about the same as one chapter, a few days.

## 6. Risks
- **Git is shown as simulated text**, not a real repository (authored traces, as in Chapter 6). The debriefs say so.
- **Ending tone.** It follows `STORY.md`, but you wrote "OPEN" on the "I never wrote the tests" line, so I need your word on it.
- **New UI is the only new engine work.** If time is short, the ending can be one text screen and the rest unchanged.
- **Teaching accuracy.** Bisect, fake clocks and small changes are standard practice. You can veto any room that does not match your lessons.

## 7. Questions for you
1. Is Chapter 7 about **Git and testing habits** right for your course, or do you prefer other topics (for example debugging steps or code review)?
2. Is the "I never wrote the tests. I'm sorry." ending line OK, and the Bato returns scene?
3. Ending scene: **plain text panel** (fastest, my plan) or a small animated scene with your art later?
4. Build everything in order (7A, then 7B) and report after each batch, or stop after 7A for your check?


## 8. Built (2026-11-04)

Rooms 7.1 to 7.6 are in (Room71..Room76, tests Room71Tests..Room76Tests). The Architect's Chamber opens after the Towers, so **all 7 wings are playable: 42 rooms, 126 stars**. Questions in section 7 were not answered, so the defaults were used: Git and testing topics, the "I never wrote the tests. I'm sorry." line, plain text ending, build in order.

**Differences from the plan (all smaller, not bigger):**
- **The ending is not a separate panel.** It is the Complete screen of Room 7.6: the ending text replaces the debrief and shows the player's name (`RoomDefinition.Ending`, `RoomFlow.PlayerName`). No new scene or UI. To replay it, replay Room 7.6.
- **`PlayerSave.endingSeen`** is saved when 7.6 is completed. Old saves load as false. **No mark on the Keep map yet** (nothing reads the flag so far).
- **Tala line on the Keep map** changed when everything is complete: "You fixed the Keep, <name>. It will break again tomorrow. Replay any room for more stars." (the old text said sealed wings were waiting).
- **New test `RoomWatchRowLimitTests`:** the Keep panel shows only 6 watch rows, so every room trace and fix is checked against that limit (found and fixed a cut-off in Room 7.2 during the playthrough).

**Playthrough fixes:** Room 7.2 predict question was 3 lines (cut off) and its trace needed 8 rows; both shortened. The ending screen no longer shows the leftover "CORRECT!" and test message under the story text.

**Tests:** 507 pass (452 before). Old tests updated: seed (42 rooms, no sealed wing), unlock rules (126 stars, wing 7 locked until the Towers are done, sealed-wing test now uses its own sealed chapter), Keep map status text.
