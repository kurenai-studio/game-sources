# Critic: Phase 6 final (shots/p6 + re-recorded cinematic)

VERDICT: PASS

R1 is fixed, and I found no blocking regression in any of the nine systems. The definition-of-done visual requirement still holds.

## What I reviewed
- **Cinematic frames** from `recordings/balloon-ride-cinematic.mp4`, decoded with `-hwaccel cuda`. I viewed 5, 12, 15, 18, 20, 23, 25, 32, 40 and 48 s at 1280 px wide (called c5 to c48 below). The frames were deleted afterwards.
- **All 10 frames in `shots/p6`.** I compared them side by side with `shots/p5` (`mobile_portrait`, `cloud`, `down`).
- **Zoom crops** of three areas:
  - the top-right corner of `mobile_landscape`
  - the top cloud in `mobile_portrait`
  - the puff in `down`
- **References:** `refs/*.jpg`.
- **Coverage gap:** p6 has no `_sunrise`, `_sunset` or `_blue` variants. Time of day is judged from the cinematic's golden light plus the p5 evidence, which this phase did not touch.

| # | System | Verdict |
|---|---|---|
| 1 | World / terrain / village | **PASS** |
| 2 | Balloon | **PASS** |
| 3 | Clouds and wind | **PASS** |
| 4 | Other balloons | **PASS** |
| 5 | Look-down / basket camera | **PASS** |
| 6 | Time of day | **PASS** (carried over; no variants re-shot) |
| 7 | Cinematic | **PASS** (R1 fixed) |
| 8 | Mobile UI | **PASS** (the p5 ghost lines are fixed) |
| 9 | Polish | **PASS** |
| — | Definition of done (visual) | **PASS** |

## R1: FIXED
- **c18, c20 and c23:** no near cloud enters the upper frame anywhere in the reveal.
- **c20:** this is again the hero frame of the project.
  - The player balloon is over the village.
  - The spire, the bridge, the river and the lake are all clear.
  - Two festival balloons sit behind it, and distant puffs line the hill crest.
- **c23 to c25:** the river now runs cleanly through the centre of the frame, where the pillow cloud used to sit.
- **c48:** the large near puff (780–1280, 65–450) is still there. It keeps the crisp crowns, the bumps and the lilac shade side that p5 accepted, so it is not an R1-class blob.

## Regression check
- **World:** no regression. The density of `down` is unchanged: the green, the church, the crossroads, the allotments and the terraces. c32 and c40 are superb village passes.
- **Balloon:** `burner` is unchanged. The twin-flame plume, the skirt and the inner disc are as before.
- **Clouds:** `cloud` has gained sun-dapple breakup on the big puff below the balloon, which is an improvement over p5's flat cream. The 500 m layering is intact.
- **Other balloons:** distinct and layered in every frame (the zig-zag, the rainbow, the stripes).
- **Cameras:** `basket` and `down` are unchanged in framing.
- **Mobile:** the `mobile_landscape` top-right cloud is now opaque. No field or hedge ink shows through it, so the p5 nice-to-have is resolved.
- **Polish:** there are no emissive stars or new artefacts.

## Definition of done (visual): PASS

| Frame | Houses | Patchwork | Roads | River | Layered clouds |
|---|---|---|---|---|---|
| `50m` | yes | yes | yes | yes | yes: puffs, cumulus, backdrop |
| `200m` | yes | yes | yes | yes, plus the lake | yes: low puffs, mid, backdrop |
| `500m` | yes: village, spire | yes, dense | yes | yes | yes: low puffs, mid cumulus, cirrus |
| `down` | yes, superb | yes | yes: crossroads | yes | yes: a low puff below the basket |

## Blockers
None.

## Nice-to-haves (do not block)
- **`mobile_portrait`, top cloud (orig 350–990, 0–220):** the inner lobe silhouettes now read through the body, and the edges are stair-stepped. It is a flat lilac mass, and mobile antialiasing is still wanting.
- **`down` puff (330–650, 170–430):** the small sphere bumps are now more pronounced. They read as beads or bubble-wrap rather than cauliflower.
- **`ground`:**
  - The right puff (815–1060, 145–370) shows its internal lobe edges.
  - The left cumulus is still soft and low in contrast from below.
- **c5 and c12:** the mid-left clouds (105–295, 210–335 in c5) are smooth pillow blobs with little internal form. They are small and distant, so they do not block.
- **500 m cumulus:** the crown crater and the sawtooth terminator are still there (top-left cumulus in `500m`).
- **Carried over:**
  - the wisp over the village in `basket`
  - the basket's share of `down`, the floor and the rim sliver
  - the pellet puffs and the dark motes
  - the `500m_blue` stalk, the pink sunset river and the lime hedges at blue hour
  - the burner inner disc
  - the player balloon missing from the cinematic ending
