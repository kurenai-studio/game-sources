# CODEBOUND — Core Mechanics

Status: **Draft v1.** Decision made: fixes are applied by **choosing from options** in the MVP (option 1).
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## Core idea [CONFIRMED]
The player does not walk the hero. They **investigate**. Each room is a ticket with a symptom; the player finds and
fixes the cause. The code is the Keep's Binding, and running it makes the dungeon act it out. The top-down grid is a
**stage that visualises the code**, not a maze to walk.

Visual mapping: `new Chest()` spawns a chest; a variable is a guard standing by a chest; a reference is a glowing
thread from guard to object; two guards tied to one chest = two references to one object; a mutation visibly changes
the chest and lights both threads.

## Screen layout [RECOMMENDED]
Left (~55%): Keep scene. Right: C# code panel with line highlighting. Top: ticket and progress. Bottom: Tala's panel
(Watch values, hints, log) and Run / Step / Reset.

## Room loop [CONFIRMED]
1. Ticket (symptom) → 2. Predict (structured question) → 3. Observe (Run, watch Keep and Watch values) →
4. Investigate (Step, inspect, breakpoints when unlocked) → 5. Hypothesis (structured choice from evidence) →
6. Fix (**choose from options, including plausible wrong ones**) → 7. Prove (run a test; a symptom-only fix fails
and the Keep shows why) → 8. Debrief (one line: the concept, and where it appears at work).

Chapter 1 opener example:
```csharp
Chest vaultA = new Chest();
Chest vaultB = vaultA;
vaultA.Add("Sword");
Console.WriteLine(vaultB.Count);   // player predicts first
```

## Room types [RECOMMENDED]
Predict · Trace · Bug Hunt · Repair · Build · Code Review (pick the safer of two solutions) · Interview (scenario in
real interview style).

## Tools earned [RECOMMENDED]
Watch (Ch1), Step Through (Ch1), Breakpoint (Ch2), Log Reader (Ch3), Test Runner (Ch3), Inspector (Ch4),
Git Notes (Ch7). They mirror Visual Studio.

## Mentor fading [CONFIRMED]
Ch1 Bato explains; Ch2 hint questions; Ch3–4 only confirms or refutes hypotheses; Ch5+ Bato is gone, only Tala's
three-tier hints remain.

## Scoring and failure [RECOMMENDED]
No lives, no timers, instant Reset. A wrong fix runs and shows what still goes wrong (never just "Incorrect").
Stars measure process: ★ solved, ★★ correct prediction and hypothesis, ★★★ smallest safe fix with a passing test.
Stars never gate progress. Hint use is tracked, costs nothing.

## Decisions and scope
- **Fix interaction (decided):** choose from options. Restricted code editing is a **later upgrade [OPEN]**.
- **MVP content [RECOMMENDED, OPEN]:** Chapters 1–3, about 18 rooms, authored as data.
- **Event stream:** rooms emit events (object created, reference assigned, object mutated, line executed). These can
  come from authored traces now or from a mini C# interpreter later, so the interpreter spike stays optional and does
  not block the MVP.

## Risks
1. High content cost per room (snippet, trace, evidence, hypothesis options, fix options, test) → data-driven
   authoring and a small MVP.
2. Process grading can feel arbitrary → structured choices only, no free text.
3. Visualisation needs a stable event format designed early.
