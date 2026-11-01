---
name: boss-replay-geometry
description: How to aim a scripted player shot at one specific boss part (pod/arm/core/keel) in a full-pipeline replay without hitting its neighbours
metadata:
  type: project
---

`BossSystem`'s six parts sit close enough together (core radius 18, keel 13, pod 12, arm 14, offsets
34/44/±27 px from the core) that a naive "put the player under the part I want to hit" placement can
clip a neighbouring part's collider circle instead — a straight-up player shot travels through every
part's x-column it's ever within, not just the one you intended.

**The check that matters:** for target part T and neighbour N, the shot column at x is safe from N when
`|x - N.x| > N.radius + shotRadius`, and hits T when `|x - T.x| <= T.radius + shotRadius`. Solve both
per neighbour, intersect the ranges. For `podLeft` (x = coreX−34, radius 12) with `armLeft` next door
(x = coreX−44, radius 14) and shot radius 1.5: naive alignment (x = podLeft's own centre, 70 with
coreX=104) actually falls *inside* `armLeft`'s hit radius too (arm's vertical-alignment window at that
x starts right at the player's own spawn y), so the shot can hit the arm before the pod. Offsetting to
x = 80 (10 px off the pod's centre, 20 px from the arm's) clears the arm's circle (20 > 14+1.5) while
staying inside the pod's (10 <= 12+1.5). Worth rechecking this arithmetic by hand for any new
full-pipeline boss test rather than trusting "it's roughly under the part" — see
`BossReplayTest.podKillSimulation`'s javadoc for the worked numbers, and [[project_boss-stage-ordering]]
for the ordering quirk that made verifying the outcome after full `TICKS` important here.

Boss part footprint constants (`CORE_RADIUS` 18, `POD_RADIUS` 12, `ARM_RADIUS` 14,
`CORE_KEEL_RADIUS` 13, offsets) live as `private static final` fields in `BossSystem.java` itself, not
in any content JSON — read them from the source when building a new scenario, they won't be in
`docs/planning/`.
