---
name: boss-stage-ordering
description: BOSS runs before COLLISION/DAMAGE/CLEANUP in SystemOrder, so BossStatus.hp lags a tick behind an actual kill
metadata:
  type: project
---

`SystemOrder` places `BOSS` between `SPAWNER`/`ENEMY_WEAPON` and `LIFETIME`, well before `COLLISION`,
`DAMAGE` and (later) `CLEANUP`. That means `BossSystem.reportStatus`, which runs inside `updateFight`
every `BOSS` tick, reads part health as it stood at the *start* of that tick — a part killed by this
same tick's collision pass is still "alive" as far as that tick's `reportStatus` call is concerned, and
only shows as gone (health contributing 0, `world.isAlive` false) on the *next* tick's `BOSS` update.

Not a bug, just a same-tick ordering fact worth knowing before writing an assertion that reads
`BossStatus` right after the tick you expect a kill on — read it after the run has settled for a few
more ticks instead, the way `BossReplayTest` runs the full `TICKS` budget before checking anything, per
[[project_boss-replay-geometry]].
