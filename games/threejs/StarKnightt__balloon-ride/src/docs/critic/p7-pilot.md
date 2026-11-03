VERDICT: FAIL

Critic pass on Phase 7 (the pilot). Frames: `shots/p7/*`. Compared against
`F:\summer-cycle\refs\girl_model_sheet.png`, `rider_turnaround_apose.png`,
`F:\summer-cycle\shots\rider\face_front_cinematic.png`, `shots\face\head_q34.png`
and `F:\bay-ride\public\og.png`. Bay Ride has no other character frames on disk
(no shots/media/tools/character images), so `og.png` is its only reference.
Blender `look` was not used. The frames were enough, and the scene was left untouched.

## Blockers

1. **Right elbow collapses into a hard kink (skinning).** `pilot.png`, at about
   (655–690, 295–335): the raised arm's outer contour turns a sharp corner at the
   elbow, with a pinch crease on the inside. It reads like a folded cardboard tube,
   not a soft bent sleeve. `pilot_burner.png` shows the same thing at about
   (730–765, 440–475). This is the arm the player sees most, because it is on the
   lever in idle and in burner. It needs a rounder elbow: more loops or a corrective
   blend at the joint, or spread the forearm/upper-arm weights over a wider band.
   Also check the shoulder in the same pose. Right now the upper arm seems to come
   out from behind the head with no deltoid shape.

2. **`pilot_burner` does not read as a different pose from idle.** Put
   `pilot.png` and `pilot_burner.png` side by side and the silhouette is the same:
   the right arm is straight up and the hand sits under the T handle. The 13° lever
   travel is not visible. The head tilt up toward the flame is not visible either,
   because her face looks straight into the camera, level. The flame is out of
   frame. The only cue that the burner is firing is the orange glow on the basket
   floor. The pull needs to read as a pull: the elbow drawn down and in, the
   shoulder dropped, the torso leaning or rising onto her toes, and the chin clearly
   up with her eyes on the nozzle. Or reframe the spot so the flame and the upward
   gaze are both in shot. As it stands, the clip cannot be verified from its own
   capture.

3. **The face and collar blow out in the burner frame.** In `pilot_burner.png`,
   the jacket, hair and basket all go warm orange under the glow, but the face goes
   to a flat near-white with no toon band and a hard vertical seam down the middle
   at about (850–870, 560–650). The cream fleece collar becomes a bright white disc
   that reads as a dinner plate held at the chest, at about (825–945, 690–720). In
   `pilot.png` the collar already reads as a thick life-ring or neck brace, not a
   soft fleece collar. Fix both:
   - Bring the face's glow and shade response in line with the skin and hands, so
     it warms the way her mitten does.
   - Flatten the collar or break it into lapels, and darken its albedo a step.

## Nice-to-haves (do not block)

- **Hair reads as a leather cap, not a ginger bob** (`pilot.png`, `pilot_look.png`).
  It is one smooth shell with a cut-out face hole. Summer Cycle's heroine
  (`head_q34.png`) gets her charm from strand clumps and loose fringe locks. Two or
  three separated fringe locks and a few tip clumps would fix it.
- **The arms are uniform tubes with no taper**, and the torso is a straight
  cylinder (`pilot.png`). A slight waist and sleeve puff, as on the Summer Cycle
  rider, would soften the shape.
- **In `pilot_look.png` the hands may clip into the rim.** At about (790–830, 415–430)
  there is a grey-blue sliver shaped like a blade, and the screen-right mitten seems
  to sink into the rim leather. Check it at the clip's mid-frame.
- **Her hand sits under the T handle instead of wrapping around it** (`pilot.png`
  at (705–735, 160–185), `pilot_burner.png` at (800–830, 440–460)). Curling the
  thumb over the bar would sell the grip.
- **No cinematic capture with the pilot.** The cinematic close on the burner is
  where she'll be seen largest, so add a `cine_burner`-style spot before
  re-recording.
- **The scarf only reads as wind-blown in `pilot_look.png`.** In `pilot.png` the
  front tail hangs straight down, and the back tail is not visible.

## Requirements check

- **Scarf:** yes.
- **Goggles on the head:** yes. They read well, and the teal lenses tie to the balloon's teal panel.
- **Hand on the burner:** yes, though weakly gripped.
- **Scale:** good. The rim meets her waist and she fits the basket.
- **Originality:** OK. She has no glasses, a ginger cap-bob and an aviator outfit,
  so she is clearly not the Summer Cycle heroine or the Bay Ride girl.
- **Interpenetration:** none seen with the uprights. Possible hand-into-rim clipping (see above).
- **Skinning:** fails at the elbow (Blocker 1).
- **Regressions:** none. `basket.png` and `down.png` are pixel-identical in
  composition to p6. The V view is unobstructed, with no arm visible. The chase spots
  (`50m`, `200m`, `500m`) show her as a tiny figure in the basket.

## What works

1. The face is charming and on-style. Its tall dark eyes with catch lights, soft
   brows, blush, freckles and small smile match Summer Cycle's painted-face
   treatment, and it reads clearly at the `pilot.png` distance. Nothing about it is
   creepy.
2. `pilot_look.png` is the best frame. The big head tilted down over the rim, one
   eye peeking and the scarf streaming sideways give her a lovely Ghibli character
   beat.
3. The palette harmonises with the world. The rust and ginger, the red-cream scarf
   and the teal lenses echo the balloon's red, cream and teal stripes.
4. The warm brown ink outline and the toon shading match the world and the
   reference games.
5. There are no regressions. The V view, the down view and the chase spots are
   unchanged.
