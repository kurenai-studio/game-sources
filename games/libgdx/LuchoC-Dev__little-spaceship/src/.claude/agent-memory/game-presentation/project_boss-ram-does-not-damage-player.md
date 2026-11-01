---
name: boss-ram-does-not-damage-player
description: Ramming the boss damages the player once and then stops for the invulnerability window, which is the decided rule and not a bug — it just makes ramming a bad way to force a fast DEFEATED
metadata:
  type: project
---

While verifying the boss music exit edge, I tried to kill the player fast by holding the ship inside
the boss's body via simulated arrow-key input (see `[[windows-desktop-screenshot-verification]]` for
the input-simulation mechanics). One `IMPACT` fired on first contact, lives dropped by one, and then
nothing across tens of seconds of continuous overlap.

**This is the decided rule, not a defect.** `docs/planning/03-game-systems.md` line 62: "All damage
taken grants temporary invulnerability, including losing the shield or the attachment, with a shorter
duration than that of respawn." `DamageSystem` is the single place the defensive chain lives —
invulnerability → shield → attachment → life — and it is also the only place that grants
invulnerability, doing so after any damage. So sustained overlap lands one hit per invulnerability
window, not one hit per tick. An earlier version of this note called this "ram does not repeatedly
damage the player" and guessed it might be a genuine hole; a real play session confirmed ramming does
damage the player normally, and reading `03-game-systems.md` explains why continuous overlap looked
like it did nothing.

The ship visually disappears underneath the boss sprite while overlapping, which is worth knowing if
a screenshot ever shows an "invisible ship" near the boss.

**Practical upshot for next time:** ramming still is not a fast route to `DEFEATED` for a verification
session — one hit per invulnerability window means it costs real time to burn several lives. Prefer
sitting in the boss's projectile line, or accept the exit edge as verified once via `VICTORY` (same
generic non-`PlayScreen` code path in `LittleSpaceshipGame.setScreen`) plus reading the code, per
`[[temp-content-edit-for-boss-verification]]`.

**The wider lesson, which cost more than the fact did:** before recording "the game does not do X",
check whether X is a decided rule in `docs/planning/`. This note originally shipped a guess as a
finding, and it reached `docs/STATUS.md` as an open unknown before a play session corrected it.
