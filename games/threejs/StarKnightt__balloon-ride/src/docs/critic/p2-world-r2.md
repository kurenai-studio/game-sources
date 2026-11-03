# Critic: Phase 2 world, round 2 (shots/p2b)

VERDICT: FAIL

The frames reviewed were all golden frames (`ground`, `50m`, `200m`, `500m`, `down`, `basket`, `vlow`, `river`, `lake`), plus `200m_sunset`, `500m_sunrise` and `down_blue`. I zoomed into crops of `200m`, `200m_sunset`, `500m` and `vlow`. I compared them against `refs/aerial_*.jpg` and Summer Cycle `refs/user_village_field.jpg`.

This is a large step up. `down`, `basket` and `vlow` now read as a dense, hand-made miniature village, with joined terraces, burgage plots, a churchyard, a square, smoke and long gable shadows. `200m` and `500m` show patchwork, a meandering river, the lake and a readable village with a spire. The world itself is close to a PASS.

What fails it is one horizon artefact that appears in every aerial frame, plus one smaller compositing bug. Both are narrow fixes.

## Old items

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Village was sparse boxes on a lawn | **Fixed** | `down` and `basket` have continuous terraces along every street, back wings, sheds and orchards. The south-east quarter is looser but has texture. |
| 2 | Garden plots were black wire rectangles | **Fixed** | `vlow` and `river` show hedge and stone-wall bounds with veg rows and sheds. Every plot has its house. A few `down` plots (x≈1000–1100, y≈640–720) are still plain mown squares. That is acceptable. |
| 3 | Khaki haze, mustard sky | **Fixed** | `200m` and `500m` have a blue-to-peach sky and cream haze, and the greens stay green. `200m_sunset` gives a rose and violet grade. The foreground darks are clean. |
| 4 | Trees not hazed, all lime | **Fixed** | In `500m` the far trees fade with the fields. Crown tones vary in `vlow` and `river`. The foreground crowns in `200m` are still slightly bright, which is fine. |
| 5 | down_blue streaks, ghost circles, wedge | **Fixed** | `down_blue` is clean, with lit windows. `down` has no circles and no wedge. |
| 6 | River was a ruled canal | **Fixed** | `500m` and `500m_sunrise` show 3–4 bends, varying width and bank trees. |
| 7 | Village and windmill unreadable at 500 m | **Fixed** | In `500m` the village is a red cluster with a pale spire (x≈790, y≈410), and the windmill is a white mark (x≈475, y≈390). In `200m` the windmill sits on a bald hill (x≈205, y≈355). |
| 8 | Cold water, tiled ripples | **Partly fixed** | The tiling is gone, and `50m` and `river` show good tree reflections. `lake` and `down` still read as cool grey-blue rather than reflected peach. This is a nice-to-have. |
| 9 | Lake shore was a clean blob | **Partly fixed** | `lake` now has a tree fringe with gaps, but no reeds or jetty can be read. The shore is still an oval. This is a nice-to-have. |
| 10 | Shadows disagree | **Fixed** | Houses cast long gable shadows in `basket` and `vlow`. Tree shadows are dappled and no longer dominate. |
| 11 | Church did not read | **Fixed** | `vlow` and `basket` show a tower and spire, a slate nave, a churchyard with yews and stones. |
| 12 | Bridge and roads | **Mostly fixed** | In `river` the arched bridge with parapets lines up with the road. Village roads are crisp, with a paved square in `down` and `basket`. Country roads are unchanged and acceptable. |
| 13 | Flat foreground fields | **Partly fixed** | `lake`, `200m` and `500m` show strokes and tonal drift. `ground` is still a flat green plane. This is a nice-to-have, because `ground` is not a ride view. |
| 14 | Ink too heavy, black grid | **Fixed** | At 200–500 m the hedges are lighter and greener, with gaps. |
| 15 | Backdrop stage flats | **Not fixed, and now an artefact** | See N1 below. |
| 16 | Sheep and smoke | **Sheep fixed, smoke not** | Sheep are cream dots in `50m` and `lake`, and `ground` has a nice toon sheep. For the smoke, see N3. |

## New problems

**N1. BLOCKER: the far ridge band is a smear of translucent dark discs.** It shows in `200m`, `500m`, `lake`, `river`, `50m` and `200m_sunset`, at y≈130–240.

The two "hazy" ridges are drawn as overlapping, semi-transparent circular blobs. Their darker overlaps show through as dirty grey-green rings, as if alpha-blended billboards were mis-sorted or the fog was applied per sprite. Their edges are hard and stair-stepped, and a flat pale fog strip runs under them (`200m` y≈235, `500m` y≈200). Crop `500m` (0–700, 120–260) shows this clearly.

It is the most visible thing on the horizon of every aerial shot, and it reads as a rendering bug, not as paint. Make the ridges opaque, or one flat silhouette with a painted gradient, all at one haze value. Melt the base into the terrain haze instead of using a strip.

**N2. BLOCKER: the mountain ink line is drawn through a cloud.** In `500m` top-left (x≈0–160, y≈110–150), the cloud sits in front of the lilac mountain, but the mountain's outline still shows as a thin dark line across the cloud. The cloud is also cut off by a hard horizontal edge where the ridge band begins. Either the depth or the ink pass ignores the clouds, or the cloud is partly transparent. Clouds must fully occlude the backdrop outlines.

**N3. Nice-to-have: chimney smoke reads as chains of grey bubbles.** In `vlow` (x≈1050–1130, y≈450–620) and `river` (x≈1150–1250, y≈270–380), each puff is a distinct, hard-ish disc. Blend the puffs into a soft continuous wisp that fades out sooner.

**N4. Nice-to-have: plain prefab houses up close.** In `vlow` and `river` the gable houses are untextured flat walls with tiny dark square windows. They have no doors visible, no shutters and no wall colour variation beyond 3–4 tints. At 200 m and above they are fine.

**N5. Nice-to-have: tree cards clipped by the near plane.** In `50m`, bottom edge (x≈1180–1320, y≈840–900), tree crowns are cut off and break into fragments.

**N6. Nice-to-have: the lake does not reflect the sky.** The lake and the river in `down` and `lake` are cool grey-blue under a peach sky (see item 8). Warming the reflection would tie the water into the golden-hour grade.

## Blockers vs nice-to-haves
- **Blockers:** N1 (ridge band disc smear) and N2 (ink through the cloud and the hard cloud cut). Fix these, re-shoot, and the world passes. The look-down views (`down`, `basket`, `vlow`) are already good enough.
- **Nice-to-haves (not blocking):** N3 to N6, items 8, 9 and 13 (lake warmth, reeds and jetty, the `ground` foreground) and the country-road centre.
