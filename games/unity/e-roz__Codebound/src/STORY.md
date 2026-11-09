# CODEBOUND — Story

Status: **Draft v1, approved in direction (premise A+C, warm and funny tone).** Names and wording are placeholders.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## Premise [CONFIRMED]
Centuries ago, a legendary builder, **the Architect**, created the **Keep**, a huge enchanted dungeon-fortress run on
written instructions called *Bindings*. It is now malfunctioning: chests copy treasure, doors open for the wrong
people, corridors lead nowhere. The Architect vanished long ago with almost no explanation.

The Keep is maintained by caretakers called **Wardens**, bound by oath to leave the Keep better than they found it
(the origin of the name *Codebound*).

## Characters
- **The Apprentice Warden (the player) [CONFIRMED].** Has no fixed backstory. **The player enters their own name**
  at the start of the game. Bato, Tala and the notes address them by that name. Fallback if left empty: "Apprentice".
  Name is stored in the save file. Appearance customization: **[OPEN]**.
- **Senior Warden Bato (mentor).** Tired, funny, 20 years in the Keep. Asks questions instead of giving answers
  ("Don't tell me what you think it does. Show me what you saw."). Leaves in Chapter 5 (scaffold fading).
- **Tala (lantern spirit).** Floating lantern. Acts as the Watch window and the hint system. Cheerful, a little too
  literal.
- **The Drift (antagonist).** Not a monster: the slow corruption of the Keep, bugs given a face.
- **The Architect.** Known only through notes found in the Keep.

## Story beats
- **Prologue — First day.** A door that should be locked is open; the chest behind it holds two copies of one sword.
  Bato: "Welcome. Everything is on fire. Mostly figuratively."
- **Ch 1 — The Vaults (Data & Memory).** Shared chests, null crashes, two guards "holding" the same key. Note:
  *"Used one master key for all vaults. Temporary. Will fix."*
- **Ch 2 — The Gates (Logic & Flow).** Edge and boundary failures. The Drift first appears as a flickering shadow.
- **Ch 3 — The Workshop (Functions & Errors).** Errors swallowed, side effects. Bato starts answering with questions.
- **Ch 4 — The Archive (Collections).** Lost, duplicated, slow records. Note: *"Searching the whole shelf each time
  is fine for now."*
- **Ch 5 — The Great Hall (OOP in Practice).** Tangled ancient designs. **Bato leaves** and sends short notes only.
- **Ch 6 — The Messenger Towers (Data & Systems).** Messages arrive wrong, late, or twice.
- **Ch 7 — The Architect's Chamber (First Week on the Job).** The root cause is found.

## The twist
Every malfunction traces back to **one shortcut on day one**: a single shared master key for every vault, labelled
"temporary, will fix." Centuries of features were built on top of it. Final note: *"If you're reading this, I never
wrote the tests. I'm sorry."* Nobody is evil; it is technical debt that compounded for centuries.

## The ending
The player fixes it properly: find the root cause, make the smallest safe change, prove it with tests, alone. Bato
then walks in; he was never lost, he left so the player would do it alone. He names them a Warden. Last line along
the lines of: "The Keep will break again tomorrow. That's the job."

## Why it supports the learning goal
- Mentor fading = scaffolding fading, told as story.
- The twist teaches that small early shortcuts cause large later failures.
- The Drift ties unrelated bugs into one investigation (root-cause thinking).
- Tone: warm, funny, never talking down.

## Open questions
- **Philippine flavour:** only Bato's name (Tagalog for "stone"), or local-sounding names and a few Filipino
  expressions? **[OPEN]**
- **Player appearance** options (sprite choices) or name only? **[OPEN]**
- Is the "I never wrote the tests" ending the intended tone? **[OPEN]**
- Chapter wing names are placeholders. **[OPEN]**

## Note on existing documents
`GAME_DESIGN_DOCUMENT.md`, `GAMEPLAY_SYSTEMS.md`, `PROJECT_OVERVIEW.md` and the others still describe the earlier
grid-and-blocks concept. They have **not** been updated for the new direction (C# fundamentals for industry
readiness, developer-thinking habits, this story). They will be rewritten after the mechanics are agreed.
