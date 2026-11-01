# Structura

A teaching game built by faculty for the BSIT program. Students learn data structures and algorithms by changing the structures directly, either studying on their own or doing work an instructor assigns.

## Language

### World

**Zone**:
A themed area of the world that teaches one data structure through a sequence of Puzzles.
_Avoid_: Level, world, area

**Nexus**:
A Zone for comparing structures. Its Puzzles mix structures taught in earlier Zones.
_Avoid_: Hub

### Play

**Puzzle**:
A single playable task with a starting state and a goal. Every Puzzle has exactly one Puzzle Type and one Stage.
_Avoid_: Level, challenge, exercise

**Puzzle Type**:
What kind of thinking the Puzzle asks for: Build, Repair, Trace, Optimize, Sort, Pathfind, Select or Code.

**Strict Puzzle**:
A Puzzle in which each Move must match the next Move of the Reference Solution, used to teach a specific algorithm. Any other Move is a Glitch. In a free Puzzle, any legal Move is allowed.
_Avoid_: Locked mode, guided mode
_Avoid_: Mode, category

**Repair**:
The Puzzle Type in which the player fixes a structure that breaks its rules. It is only ever a Puzzle Type, never a name for a Stage.
_Avoid_: Using "repair" for the scored end-of-Zone task

**Lesson**:
A non-playable animated explanation, shown before a Zone's Puzzles. It has no goal, so it is not a Puzzle.
_Avoid_: Demo, tutorial, cutscene

**Stage**:
The part a Puzzle plays in its Zone: Guided, Challenge or Boss.
_Avoid_: I Do / We Do / You Do, phase, step

**Move**:
One graded player action: a change to the structure (insert, delete, swap, rotate, push, pop, enqueue, dequeue), visiting a node in a Trace, or choosing an answer. Selecting a node before acting on it is not a Move, and undoing does not remove a Move from the count.
_Avoid_: Step, action, turn

**Star**:
A score of 1 to 3 for a finished Puzzle, based on how close the player's Moves and Glitches were to the Reference Solution and on how many Hints they used. Time does not count.
_Avoid_: Rating, grade

**Tray**:
The values a Puzzle gives the player to place, used strictly in order.
_Avoid_: Inventory, supply, hand

**Output**:
The values removed from a stack or queue, read first to last in the order they were removed. Values deleted from other structures are destroyed, not output. A Puzzle can set its goal on the Output.
_Avoid_: Result, popped values, out, "top" of the Output

**Disruption**:
A scripted change the game makes to a Boss Puzzle's structure partway through. The player must adapt but cannot fail.
_Avoid_: Attack, random event

**Boss**:
The final Puzzle of a Zone. It is longer and has several parts, usually with Disruptions.
_Avoid_: Final exam, boss fight

### Progress

**Profile**:
A student's local identity on one computer: a name and a student ID, with no password. A shared lab PC can hold several Profiles.
_Avoid_: Account, user, login

**Progress Report**:
A signed file a student exports from their Profile and uploads to the class's online classroom, so the instructor can see Stars per Puzzle.
_Avoid_: Save file, transcript, grades export

**Zone Map**:
The clickable screen that shows Zones and the paths between them. It replaces a walkable world.
_Avoid_: Overworld, world map, hub

**Glitch**:
The feedback shown after a wrong move. It explains the mistake but never ends the Puzzle, because players cannot fail.
_Avoid_: Fail, death, game over

### Correctness

**Reference Solution**:
The correct end state and best sequence of moves for a Puzzle, worked out by the game's own data structure code rather than written by hand.
_Avoid_: Expected answer, answer key

**Hint**:
Text a person writes to nudge the player toward the Reference Solution. A Hint is only wording and never decides whether an answer is correct.
_Avoid_: Clue, tip

### Code

**Code Mirror**:
The panel that shows code doing the same thing as the player's moves, step by step, in Python or Java.
_Avoid_: Code view, code panel
