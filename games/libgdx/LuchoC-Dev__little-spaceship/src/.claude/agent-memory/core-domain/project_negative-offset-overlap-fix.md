---
name: negative-offset-overlap-fix
description: Why WavePlacement's negative-offset clamp had to move from "always" to "only the Cleared case", and the reasoning trap that made a naive fix look safe but wasn't.
metadata:
  type: project
---

Fixed in #126/PR #127. `SpawnSystem.scheduleNext` clamped every placement's start to
`Math.max(previousEndTime + offsetSeconds, levelTime)`. Because `resolveEnded` always called it with
`previousEndTime == levelTime`, the clamp silently erased every negative offset — see
[[defensive-chain-and-collision-design]] and [[wave-content-contract]] for the surrounding design.

**Why a purely reactive fix cannot produce real overlap.** `resolveEnded` removes an ended wave from
`activeWaves` and only then calls `scheduleNext` for its follower, both inside the same loop iteration.
That means there is structurally never a tick where the ended wave and its follower coexist in
`activeWaves` if the follower is scheduled reactively — no matter what formula computes the offset. Real
overlap requires the follower to be added to `activeWaves` *before* the predecessor is detected as
ended, i.e. predictive scheduling. Reactive-with-a-different-formula still can't overlap; only
reactive-vs-predictive is the axis that matters. Spent real effort suspecting a formula tweak would do
it before running the "removal happens synchronously" trace and ruling that out.

**Why the fix doesn't move the golden fingerprint despite reworking the scheduling model.**
`LevelScoreReplayTest` uses `withSingleWavePlacement` (one placement only) — there is no follower to
chain into, so the new recursive `scheduleChain` path in `scheduleNext` never executes for that test at
all. Before assuming a scheduling rewrite is safe against a golden test, check whether the golden
fixture's own content actually exercises the changed code path — it may not.

**Predictive vs. reactive split, by end condition.** `FixedDuration`'s end (`start + seconds`) is known
the instant it starts, so its follower is resolved immediately, recursively, chaining through as many
consecutive `FixedDuration` placements as follow — no clamp against `levelTime`. `Cleared`'s end is only
discoverable after CLEANUP runs (next tick, per `SystemOrder`), so it keeps the old reactive path with
the clamp intact. Do not conflate the two cases again; that conflation was the entire original bug.

**Falsification method that worked.** Disable only the recursive predictive call (revert `resolveEnded`
to call `scheduleNext` for every ended wave, not just `Cleared`) — this exactly reproduces the original
bug without touching anything else. Rerunning `SpawnSystemTest` then failed exactly the negative-offset
assertion (24 run, 1 failed), leaving the paired zero-offset assertion and the rest of the suite green —
good evidence the rewritten test isolates the rule rather than something incidental.
