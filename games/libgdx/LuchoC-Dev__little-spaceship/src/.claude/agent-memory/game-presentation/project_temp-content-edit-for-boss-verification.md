---
name: temp-content-edit-for-boss-verification
description: Verifying a long level's late-game content (a boss at 5+ minutes) live, without waiting or grinding, by temporarily editing the content JSON and reverting before commit
metadata:
  type: project
---

Level 1 is ~5:45 long and its boss does not enter until ~5:02 (`docs/plan/07-boss/status.md`). Real-time
play is not a viable verification method for anything boss-related within a normal session. What
worked: overwrite `assets/data/level-01.json` locally with a minimal file — `entersAt` near 1s, one
harmless filler event (a wave timeline needs at least one, per `SimpleWaveTimeline`'s constructor —
an empty `"events": []` throws), and boss health low enough (or high enough, tune per what you're
checking) to reach the fight/defeat/victory in seconds — launch `:desktop:run`, screenshot, then
`cp` the backed-up original back over it before committing. `git status` on the file comes back clean
since the final content matches HEAD exactly.

This caught real rendering behaviour a compile could not: the tell's white outline actually
alternating between both arms (sweep) and both pods (spread) across separate screenshots, and the
boss health bar's `W4` fill visibly shrinking between two captures at different scores. Both were
implemented from the design doc's numbers without a way to eyeball them until this technique.

**Timing gotcha:** a screenshot cadence of ~0.7-0.9s against a 0.25s tell beat will reliably catch
beat 3 (held until the shot fires, the longest-lived state) but can easily miss beats 1/2 entirely by
luck — don't claim to have visually confirmed a state you didn't actually see in a saved image, even
if the code path is shared and reasoned correct.

**Holding a key continuously (not just pressing) from PowerShell:** call `keybd_event` with the
down flag once, do your sleep/screenshot loop, then call it again with `KEYEVENTF_KEYUP` (`0x2`) at
the end — one down, N screenshots, one up. This is what let simulated `SPACE` act as sustained
autofire instead of a single tap, needed to actually kill enough of the boss to reach `VICTORY` in a
short verification window.

See `[[windows-desktop-screenshot-verification]]` for the underlying window-foregrounding and
scan-code mechanics this technique builds on.
