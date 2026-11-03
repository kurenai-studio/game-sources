VERDICT: PASS

Critic re-check of Phase 7 (the pilot) against `p7-pilot.md` and `p7-pilot-response.md`.

**Frames viewed**
- From `shots/p7b/`: `pilot`, `pilot_burner`, `pilot_look`, `200m`, `500m`, `basket` and `down`. The ones with the pilot in them were also viewed as 2x crops.
- Cinematic frames from `recordings/balloon-ride-cinematic.mp4` at 1, 3, 6, 10, 20, 30 and 45 s, extracted with `-hwaccel cuda`. The 3 s frame was also viewed as a crop. All extracted frames were deleted afterwards.

**References**
- `F:\summer-cycle\refs\girl_model_sheet.png`.
- The Summer Cycle and Bay Ride frames cited in round 1.

**Regression diffs** (ffmpeg difference, threshold 24/255, p6 vs p7b)
- `basket` and `down`: 0 px.
- `200m`: about 63 px. `500m`: about 56 px. `50m`: about 69 px. In every case this is only the tiny pilot in the basket.

## Item table

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Elbow kink | **Fixed** | `pilot.png`: both elbows are soft, rounded bends with no pinch crease. `pilot_burner.png`: the raised right arm bends round over the hood with a smooth outer contour. |
| 2 | Burner pose differs from idle, with the flame in frame | **Fixed** | Idle has both mittens on the rim and the lever hanging free. Burner has the right arm up on the T handle, the lever pulled down and the left hand on the rim, so the silhouettes are completely different. Both cans, the blue flame columns and the warm glow are in frame. |
| 3a | Face white-out or seam under the glow | **Fixed** | `pilot_burner.png` and cine at 1 and 3 s: the face keeps a soft shade band, blush and warm cream. There is no flat white and no hard vertical seam. |
| 3b | Collar | **Fixed** | It now reads as a turned-down band with two lapels. It no longer looks like a life ring or a plate. |
| — | Interpenetration | OK | There is no visible clipping of hand into rim, arm into head or body into upright. The mittens sit on top of the leather roll. |
| — | Skinning | OK | The shoulder and elbow deform cleanly in both poses. |
| — | Scarf | OK, minor | It reads well, and it streams in `pilot_look`. The cream stripe at the tip still goes pale blue-grey in shade (see the nice-to-haves). |
| — | Charm and style match | OK | The idle face (brows, freckles, catch-light eyes, blush) is still on-style with the Summer Cycle painted face. The burner and low-angle views are weaker (see the nice-to-haves). |
| R1 | basket / down / 200m / 500m vs p6 | No regression | Pixel diffs are above. The V view is unobstructed, with no arm or hand in `basket.png`. |
| R2 | Cinematic from 10 s on | No regression | 10 s is the wide shot of the balloon over the fields. 20 s is the reveal of the village and the river. At 30 s the camera glides over the village, and at 45 s over the fields. All are clean. |
| C | Opening shows the pilot firing | **Yes** | At 1 and 3 s she has her arm up on the lever, the lever is pulled, both flame jets roar into the throat, and the basket glows. At 6 s the shot pulls back cleanly to the envelope. |

## Blockers

None.

## Nice-to-haves (do not block)

1. **Her gaze does not go to the nozzle in the burner pose.** In `pilot_burner` and in the cine at 1 and 3 s, her eyes look straight at the camera. The head tilts back, but the painted pupils do not follow the flame. Shifting the iris UVs up and toward her right hand during the hold would sell "watching the burn".
2. **From below, the face reads as a blank egg in a balaclava.** In `pilot_burner` and the cine, the lower two-thirds of the face is featureless cream, and no fringe shows, so the bob reads as a hood. This repeats the round-1 nice-to-have on hair locks. Separate fringe locks and a hint of a nose or chin shadow would bring back the charm of the idle frame.
3. **The scarf tip still goes blue-grey in shade.** In `pilot.png`, at about (815–835, 615–645), the cream stripe at the front tail tips toward blue-grey. It is warmer than before but still the coolest spot on her.
4. **The left lapel in `pilot_burner` reads as a white blade.** At about (870–920, 740–790) the turned-down lapel catches the light as a sharp pale shard. One step darker, or a softer tip, would fix it.
5. **The lower body in `pilot.png` reads like a drum.** The jacket hem ring over the navy trousers at about (745–880, 650–760) looks like a pot rim. A softer hem or a belt line would help.
6. **The mittens are crude.** The idle mittens on the rim are notched white blocks, and the left one reads like a tooth. Her hand also still sits under the T bar instead of wrapping it (thumb over the bar, carried over from round 1).
7. **She is small in the cinematic opening.** She is about 15% of the frame height. Reading the pull still works, but a slightly tighter hold for 0–2.5 s would make her the clear subject.
