# Plan: Rooms 2.4, 2.5, 2.6 (finish Chapter 2)

Status: **IMPLEMENTED (2026-11-03).** You said "continue it until you finish the chapter 2", so I wrote this plan and the code in one pass. Please check the wording; everything is easy to change.
Same learning loop and same text-row picture as 2.1 to 2.3. All code lines are 35 characters or fewer, and every code panel has at most 5 lines.

## 2.4 The Toll Boundary (Repair): `>` vs `>=`
**Ticket:** "A total of exactly 100 gets no discount. 99 and 101 act as expected."  **Goal:** "A total of 100 or more gets the discount."
```csharp
1  int total = 100;
2  bool discount = total > 100;
3  Console.WriteLine(discount);
```
- **Predict:** "What does this print?" True / **False** / 100 / A crash. (Trap: the goal says 100 gets it.)
- **Rows:** `discount = false`, `total = 100`, `step 1: 100 > 100 = false`.
- **Hypotheses:** "total is the wrong number" (Wrong), "The check is too strict" (Close), **"> leaves out exactly 100. The rule says 100 or more"** (Correct).
- **Fixes:** Best `total >= 100` (pass: 99 False, 100 True, 101 True). Symptom-only `bool discount = true;` (99 would get it too). Wrong `total < 100` (100 still gets none, 99 does).
- **Debrief:** test 99, 100, 101. At work: fare and discount rules (student, PWD, senior).

## 2.5 The Split Treasure (Bug hunt): integer division
**Ticket:** "7 coins split between 2 guards. Each guard gets 3, and one coin vanishes."  **Goal:** "Share 7 coins between 2 guards. No coin may vanish."
```csharp
1  int coins = 7;
2  int guards = 2;
3  var share = coins / guards;
4  Console.WriteLine(share);
```
- **Predict:** 3.5 / **3** / 4 / A crash. (Trap: 3.5.)
- **Rows:** `coins = 7`, `guards = 2`, `share = 3`.
- **Hypotheses:** "7 is odd, so the program breaks" (Wrong), "The answer gets rounded" (Close), **"int divided by int has no decimals, so the .5 is dropped"** (Correct).
- **Fixes:** Best `decimal coins = 7;` (share 3.5). Symptom-only `double coins = 7;` (3.5, but double drifts on money). Wrong `... / guards + 1` (prints 4).
- **Debrief:** use `decimal` for money; check `guards` is not 0 (divide by zero crashes). At work: e-wallet and payroll rounding.
- **Cut from the lesson plan:** the "empty group crashes" half is only mentioned in the debrief, not played, to keep one bug per room.

## 2.6 The Visitor Form (Code review): `Parse` vs `TryParse`
**Ticket:** "A visitor typed abc as their age. The form crashes."  **Goal:** "Read the age safely. Bad input must not crash."
```csharp
1  string t = "abc";
2  int age = int.Parse(t);
3  Console.WriteLine(age);
```
- **Predict:** It prints 0 / It prints abc / **It crashes with an error** / It prints nothing.
- **Rows:** `t = "abc"`, then the red `FormatException`.
- **Hypotheses:** "age is too small" (Wrong), "The text is not a number" (Close), **"int.Parse throws on bad input and nothing checks first"** (Correct).
- **Fixes (the two solutions to compare):** Best: `if (!int.TryParse(t, out int age))` then print "Bad age" else print age. Symptom-only: `int.TryParse(t, out int age);` (no crash, but abc silently becomes 0). Wrong: `Convert.ToInt32(t)` (still crashes).
- **Debrief:** user input is hostile; TryParse returns false, but ignoring that false hides the problem.
- **Cut from the lesson plan:** null, empty and negative values are not played. Only `"abc"`.

## Engine and data changes
1. One new trace event, `TextSet(variable, text)`: shows a value as text (3.5, "abc"). Same rows as arrays, caption "{name} is {text}."
2. Keep catalog (seed and asset): 2-6 added. Chapter 2 now has 6 rooms (36 stars in total with Chapter 1).
3. Count tests updated (6 gate rooms, 12 rooms, 36 stars). 25 new tests (8 + 9 + 8).
