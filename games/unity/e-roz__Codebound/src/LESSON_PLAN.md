# CODEBOUND — Lesson Plan (Chapters 1–3, MVP)

Status: **Draft v1, approved to save.** 18 rooms. Room wording, scenario names and "at work" lines are drafts.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

Every room follows the loop in `MECHANICS.md`: ticket → predict → observe → investigate → hypothesis → fix (choose
from options) → prove (test) → debrief ("where this appears at work"). Each chapter ends with a Code Review or
Interview room. Language: **C#**. Target: IT students in the Philippines.

Developer habits trained across the game: read before writing · predict then verify · model the state · debug with a
method · think adversarially · clarify requirements · weigh trade-offs · decompose · write for the next person · prove
it works.

---

## Chapter 1 — The Vaults (Data & Memory)
Mentor: Bato explains. Tools earned: Watch, Step Through. Habits: model the state, predict then verify.

| # | Type | Room / Ticket | Concept (C#) | At work |
|---|---|---|---|---|
| 1 | Predict | **The Twin Guards.** Vault B holds a sword nobody put there; two guards are tied to one chest. | Reference types: `Chest b = a;` copies the reference, not the object | Shared objects in caches and settings change behind your back |
| 2 | Trace | **Copy That.** Copying a coin pouch (`int`) leaves the original alone, copying a chest does not; a copied and edited name plaque (`string`) does not change the original. | Value types vs references; string immutability | Knowing when a copy is a copy prevents the most confusing bugs |
| 3 | Bug Hunt | **The Shared Inventory.** Two adventurers see each other's loot. | A `List<T>` assigned from another variable instead of copied | "My cart shows another user's items" |
| 4 | Repair | **Copy of a Copy.** The new list is separate, but changing a sword in one list changes it in the other. | Shallow vs deep copy | Config and DTO copies that still share inner objects |
| 5 | Bug Hunt | **The Empty Chest.** The machinery crashes opening a `null` chest. | `NullReferenceException`; null checks vs masking the problem | The most common production error |
| 6 | Interview | **Who Changed My Guard?** A method that modifies a passed-in object vs one that reassigns it. | Reference passed by value; mutation vs reassignment | Favourite interview question; source of surprising side effects |

Story link: first Architect note about the single master key.

## Chapter 2 — The Gates (Logic & Flow)
Mentor: hint questions. New tool: Breakpoint. Habits: adversarial thinking, edge cases.

| # | Type | Room / Ticket | Concept (C#) | At work |
|---|---|---|---|---|
| 1 | Predict | **The Gate Rules.** The wrong visitors get in. | `&&` / `\|\|` precedence, parentheses | Access-control and permission bugs |
| 2 | Bug Hunt | **The Last Guard.** One guard is never checked, or the roll call crashes. | Off-by-one: `<` vs `<=`; `IndexOutOfRangeException` | Pagination and batch jobs that skip or crash on the last record |
| 3 | Trace | **The Gate That Never Closes.** The loop never ends. | `while` condition that never changes; using breakpoints | Runaway jobs and timeouts |
| 4 | Repair | **The Toll Boundary.** A discount applies at 100 but not at exactly 100. | `>` vs `>=`; testing 99, 100, 101 | Fare and discount rules (student, PWD, senior); QA's favourite cases |
| 5 | Bug Hunt | **The Split Treasure.** 7 coins among 2 guards gives 3; an empty group crashes. | Integer division, divide by zero, `decimal` for money | E-wallet and payroll rounding errors |
| 6 | Code Review | **The Visitor Form.** Compare two solutions that read a visitor's age. | `int.Parse` vs `TryParse`; null, empty, negative values | User input is hostile |

Story link: the Drift first appears as a flickering shadow.

## Chapter 3 — The Workshop (Functions & Errors)
Mentor: confirms or refutes your hypothesis only. New tools: Log Reader, Test Runner.
Habits: read before writing, debug with a method, decompose, prove it works.

| # | Type | Room / Ticket | Concept (C#) | At work |
|---|---|---|---|---|
| 1 | Predict | **The Healer Machine.** `Heal()` computes a value but the caller ignores it. | Return values, parameters, scope | Reading someone else's methods without assuming |
| 2 | Bug Hunt | **The Greedy Counter.** Asking for the total secretly resets the list. | Side effects; methods that should only read | Surprising order-dependent bugs |
| 3 | Trace | **The Stack of Clues.** A crash reports a failure far from its cause. | Reading a stack trace; origin vs where it blew up | The most useful skill on day one of a job |
| 4 | Bug Hunt | **The Silent Failure.** `catch (Exception) { }` hides a broken machine. | Specific exceptions, logging, rethrow, `finally` | Silent failures that only appear as customer complaints |
| 5 | Repair | **Red, Then Green.** Choose the test that reproduces the bug before fixing it. | Unit test basics: arrange, act, assert | Regression tests; "prove it works" |
| 6 | Code Review | **The Forty-Line Monster.** One method does four jobs; choose the better split. | Decomposition, naming, single responsibility | Code review comments, maintainability, handover |

Story link: Bato begins answering with questions.

---

## Authoring notes
- Each room needs: code snippet, event trace (object created / reference assigned / object mutated / line executed),
  predict question, evidence for hypothesis options, fix options (with plausible wrong ones and what each wrong one
  does), a test, a debrief line. Author as data (ScriptableObject or JSON). **[RECOMMENDED]**
- The C# claims in each concept should be verified by a C# expert on the team (the project lead) before content is
  built.
- Chapters 4–7 outlines are in `STORY.md` and the curriculum discussion; they are outside the MVP.

## Open points
- Add, drop or swap rooms after playtesting. **[OPEN]**
- Whether to use local scenarios (fares, enrollment, e-wallets) in the *ticket text* too, not only in "at work"
  lines. **[OPEN]**
