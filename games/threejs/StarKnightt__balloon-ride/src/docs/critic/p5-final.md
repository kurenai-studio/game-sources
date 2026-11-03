# Critic: Phase 5 final (shots/p5 + re-recorded cinematic)

VERDICT: FAIL

One blocker remains, and it is a new regression in the cinematic reveal. All five p4-final blockers are fixed, and the definition-of-done visual requirement is met.

## What I reviewed
- **All 38 frames in `shots/p5`:** eight spots at four times, `og*` and `mobile_*`.
- **`public/og.png`:** identical to `shots/p5/og.png`.
- **Zoom crops:**
  - the `500m` and `500m_blue` sky band
  - the `500m` former starburst area (1100–1600, 400–700)
  - the `50m_blue` and `200m_blue` backdrop
  - the top-right corner of `mobile_landscape`
- **Cinematic frames** from `recordings/balloon-ride-cinematic.mp4`, decoded with `-hwaccel cuda`. The file is h264, 1920x1080, 60 fps, 50.0 s.
  - I viewed 2, 20, 35 and 48 s, plus 17 and 23 s to bracket the reveal, and a full-res crop of 20 s.
  - The coordinates below are at 1280 px wide, and the frames are called c2 to c48.
  - The frames were deleted afterwards.
- **References:** `refs/*.jpg` and `F:\summer-cycle\refs\user_village_field.jpg`.

| # | System | Verdict |
|---|---|---|
| 1 | World / terrain / village | **PASS** |
| 2 | Balloon | **PASS** |
| 3 | Clouds and wind | **PASS** (B1, B2 and B3 fixed) |
| 4 | Other balloons | **PASS** |
| 5 | Look-down / basket camera | **PASS** |
| 6 | Time of day | **PASS** (B4 fixed) |
| 7 | Cinematic | **FAIL**: new regression R1 |
| 8 | Mobile UI | **PASS** |
| 9 | Polish | **PASS** (B5 fixed) |
| — | Definition of done (visual) | **PASS** |

## p4-final blockers

| Blocker | Status | Evidence |
|---|---|---|
| **B1:** `down` has no clouds | **FIXED** | A low puff group sits between the basket and the village (315–655, 165–435) in all four `down*` frames. It is lilac-shaded at blue hour and cool white at sunrise. I could not pick out a distinct cloud shadow on the village, but the puff alone meets the B1 minimum. |
| **B2:** mid cumulus are blurry, flat-based slabs | **FIXED** | In `500m*`, the mid cumulus at (80–530, 0–200), (580–750, 50–195) and (1075–1160, 115–180) show whole, with lit crowns, cauliflower bumps and rounded shaded bases above the hills. There is no ruled base anywhere. In c48 the right-hand puff (780–1280, 65–450) has crisp crowns, bumps and lilac shade, so it is not a blob. |
| **B3:** `cloud_sunrise` is a flat cream cut-out | **FIXED** | The puff (610–1045, 410–820) now has a lilac-grey shade side on the left and lower lobes, and shaded billow bottoms. |
| **B4:** blue-hour backdrop is glossy, with pink blotches | **FIXED** | In `50m_blue` (100–590, 110–250), `200m_blue` (100–560, 0–80) and `basket_blue` (20–560, 60–135), the banks are dim, matte and cool. They have no gloss and no glow at their bases, and they sit at the value of the afterglow. |
| **B5:** windmill starburst | **FIXED** | There is no white star at (1370, 540) in any `500m*` frame. The mill reads as a small matte four-sail mill in `200m` (70, 385) and `200m_sunset`. |

## Blocker

**R1. NEW BLOCKER (regression): the cinematic reveal is wiped by a featureless pillow cloud.**
- **c20:** p4 called this the best frame of the project. Now a huge near-camera cumulus fills the top-right third (700–1150, 0–230).
- **What the full-res crop shows:** the crown has a few bumps. The whole lower two thirds is one smooth, even lilac-cream mass, with no billows, no terminator and no internal form. It reads as an inflatable pillow parked over the hills, the festival balloons and the head of the river.
- **Timing:** it is absent at c17. By c23 it drifts into the centre of the frame over the river (340–490, 85–195 at 640 px).
- **Cause:** this is the same class of fault as p4's c48 blob, moved earlier now that the camera keys and the low wisps have changed. The crisp outline and the rounded base are new and good, but the bland body and the size close to the lens are the problem.
- **Fix:** route the 15–25 s reveal so that no cloud closer than about 400 m enters the upper frame. Alternatively, make sure large near lobes carry billow and shade breakup on their undersides.
- **Check:** re-check c17, c20 and c23.

## Per-system notes

### 1. World: PASS (carried over)
- There is no regression.
- `down` is still a hand-painted miniature: the green, the church, the crossroads market, terraces and allotments.
- c35 is a superb village pass, with the spire, bridge, river and orchards.

### 2. Balloon: PASS (carried over)
- The `burner*` close-ups are unchanged.
- **Nice-to-have, carried over:** the inner-disc edge at x≈375 and x≈1225.

### 3. Clouds and wind: PASS
- There are now three cloud levels plus cirrus at 500 m: wisps below, puffs at 250–330 m and the cumulus above.
- **Nice-to-haves:**
  - **Sawtooth terminator.** The light/shade boundary on the 500 m mid cumulus is a stepped sawtooth (`500m` crop, 250–400, 90–150). It reads slightly aliased.
  - **A "bitten" concave crater** in the big cumulus's crown (280–345, 30–65).
  - **Ground undersides.** In `ground` the big left cumulus (0–460, 0–400) is soft and low-contrast from below.
  - **Pellet puffs.** The row of identical pellet puffs is still there (`50m_sunrise` and `50m_sunset`, 510–730, 145–160).
  - **Dark motes.** There are still a few dark specks right of the envelope in `50m` (1000–1100, 280–300).

### 4. Other balloons: PASS (carried over)
They are distinct and layered at all times.

### 5. Look-down / basket: PASS
- **Nice-to-have, new:** the new wisp in `basket*` sits right over the village centre (705–840, 435–530) and hides part of the spire composition. Nudge its timing.
- **Carried over:** the basket share in `down`, the flat floor and the sliver under the rim.

### 6. Time of day: PASS
- All four times are distinct and beautiful.
- **Nice-to-haves:**
  - In `500m_blue`, the lavender river meets the underside of the cloud at (1340, 600), so the cloud reads as a mushroom on a stalk.
  - The backdrop cards at blue hour are slightly olive and ghostly (`200m_blue`, top left).
  - **Carried over:** the pink sunset river and the lime hedges at blue hour.

### 7. Cinematic: FAIL (R1)
- c2 (the burner close-up with twin flames) and c35 are excellent.
- c48 ends above a well-shaped puff. It covers the right third, which is acceptable.
- **Nice-to-have, carried over:** the player balloon is absent from the ending.

### 8. Mobile UI: PASS (carried over)
- **Nice-to-have, new:** in the top-right corner of `mobile_landscape` (orig 2020–2250, 130–280), a fading, semi-translucent cloud shows straight dark field and hedge lines through its body. Make fading clouds shrink, not go transparent, on this tier too.
- **Carried over:** mobile antialiasing.

### 9. Polish: PASS
B5 is gone, and there are no new emissive artefacts.

## Definition of done (visual): PASS

| Frame | Houses | Patchwork | Roads | River | Layered clouds |
|---|---|---|---|---|---|
| `50m` | yes | yes | yes | yes | yes (puffs, cumulus, backdrop) |
| `200m` | yes | yes | yes | yes, plus the lake | yes |
| `500m` | yes (village, spire) | yes, dense | yes | yes | yes (wisps, puffs, mid cumulus) |
| `down` | yes, superb | yes | yes (crossroads) | yes | yes (a low puff group below the basket) |

## Blockers (fix, re-record)
1. **R1:** a featureless pillow cloud wipes the cinematic reveal (c20 top right, drifting to the centre of c23).

## Nice-to-haves (do not block)
- Ghost lines through the fading cloud in `mobile_landscape`, and mobile antialiasing.
- The wisp occluding the village in `basket*`.
- The sawtooth terminator and the crown crater on the 500 m cumulus.
- The pellet-puff row and the dark motes.
- The `500m_blue` cloud-on-a-stalk.
- The pink sunset river and the lime hedges at blue hour.
- The burner inner disc, the basket floor and rim sliver, and the share of `down` taken by the basket.
- The player balloon at the end of the cinematic, and the bell tierce.
