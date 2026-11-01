---
name: hud-contract-and-level-outcome
description: PlayerStatus/CompletionBonus as read-only snapshots off WorldView, and the rule that a game-rule number crossing the boundary must have exactly one implementation
metadata:
  type: project
---

Built across phase 06 (`docs/plan/06-presentation/`). `PlayerStatus` is a plain record snapshot copied
out of `World` the instant `WorldView.player()` is called — never a live wrapper over
`domain.component.Player`, so nothing `game` holds can be walked back into a mutable component. Fields
fill in a safe default in the compact constructor (`""` / `InvulnerabilitySource.NONE`) rather than
letting `game` handle null.

**`WorldView.outcome()` is computed on read, not stored.** `LevelOutcome.COMPLETED` is deliberately not
named `VICTORY` on the `core` side — nothing shipped so far can honestly claim the boss fight the spec
describes (that's phase 07). `game`'s own `VictoryScreen` is still allowed to say "VICTORY" in its copy;
the caveat is about what the signal proves, not what the player is told.

**A rule with a number crossing the boundary needs exactly one implementation, and "it's tested but has
no caller" is the smell that it drifted into the wrong module, not a sign the method is merely unused.**
`ScoreSystem.completionBonus` (the per-life/per-bomb end-of-level bonus, per `10-mvp-initial-values.md`)
was written package-private with a javadoc explaining why it had no caller — and `PlayScreen` had
quietly restated the same multiplication inline instead of calling it. Fixed by exposing it through the
port: `WorldView.completionBonus()` returns a new record, `CompletionBonus(livesBonus, bombsBonus)`,
computed live from the player's current lives/bombs regardless of `LevelOutcome` (same pattern as
`PlayerStatus.score()` — the reader decides when the number is meaningful). `ScoreSystem.completionBonus`
is now `public` and returns `CompletionBonus`; `World.View` is its only caller inside `core`. The lesson
generalises: when a game-rule method's only caller is its own test, that is not "not needed yet", it is
"go look for where it got reimplemented instead."

**`PlayerStatus.attachmentDurability` was removed after the same "no consumer, don't guess" check phase
04 applied to `PatternDefinition`.** No code in `game` read it and no row for it exists in the HUD layout
table — only `attachmentId` is drawn. `Attachment.durability` itself (the mutable domain component) is
unaffected and still exercised directly by `PickupSystemTest`; only the port-crossing copy was pointless.
Before adding a field to a snapshot record "for completeness", check for a real reader the way this
should have been checked the first time.

See [[core-boundary-decisions]] for the general shape of what crosses the boundary, and
[[content-pipeline-design]] for the earlier "no consumer, don't guess" precedent this one repeats.
