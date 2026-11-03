# Response to the p7 pilot critic pass

New frames are in `shots/p7b/`. The old spots (`ground`, `50m`, `200m`, `500m`, `down`, `basket`, `cloud`
and `burner`) were diffed pixel by pixel against `shots/p7`:
- `basket`, `down` and `burner` are identical (0 px over 24/255).
- The chase and ground spots differ only in a box of about 12x14 px round the tiny pilot in the basket.

## Blocker 1: the right elbow kink (fixed)
- **Cause:** the right sleeve was two separate overlapping tubes (`sleeve_R` 0–0.53 and `forearm_R`
  0.47–1.0) that met right at the elbow. It also had a 4.5 cm upper arm/forearm blend and rings every
  6 cm. The joint was folding where two capped tubes overlapped.
- **Now:**
  - **One tube.** The right sleeve is built as one tube, subdivided, then split 7 cm past the elbow
    (`split_off`). The two halves share the cut ring exactly and get the whole sleeve's normals as
    custom normals, so there is no shading seam. `forearm_R` stays a separate mesh for the basket view.
  - **Denser rings.** The sleeves are sampled every ~2 cm (12 sides, Catmull-Clark on top).
  - **Elbow helper bones.** `elbow_L/R` are deform bones parented to the upper arm and aligned with the
    forearm. A local Copy Rotation from the forearm at 0.5 influence makes them turn half as far.
  - **Wide weights.** The sleeve goes upper arm → helper → forearm over a 16 cm smoothstep band, so the
    bend is two half-bends spread over the joint. Shoulder → upper arm blends over 10 cm.
  - **Poses that don't over-bend.** In idle the arms are nearly straight. In the burner hold the elbow
    bends about 80°, drawn out to her side by an animated pole.
- `pilot.png` and `pilot_burner.png` both show a round, soft elbow.

## Blocker 2: burner looked like idle (fixed)
- **Idle:** both hands rest on the front rim. The wrist targets were moved onto the leather roll, and
  the mittens now sit on its top (z 1.187 vs the roll top at 1.185). The lever hangs free.
- **Burner** (now 3.3 s: reach 0–0.45 s, pull to 0.7 s, hold loop 0.7–2.7 s, release to 3.3 s):
  - She reaches up from the rim to the T handle in an arc.
  - She pulls the lever **10 cm down**. The rod slides through a fixed bushing at the valve block (its
    top runs up inside the block, so no gap opens), and her hand rides down with the handle.
  - Her shoulder lifts with the reach, then drops as she pulls.
  - The torso leans back, and she rises 1.2 cm onto her toes.
  - She looks up toward the nozzle: neck −10°, head −26° and turned toward her right hand.
  - The left hand bears down on the rim.
- **`pilot_burner` reframed:** the camera is now on her right and below her. Her upturned face, the
  pulled lever, both burner cans, the flame columns and the orange glow on the basket are all in frame.
- **`pilot.ts` changes:**
  - The subclip bounds are now 21/81 frames.
  - In the V basket view her forearm and hand show only while the arm is up on the lever
    (pull/hold/release), so the resting hands never enter the V view. `basket.png` is pixel-identical.

## Blocker 3: face and collar blow-out (fixed)
- **Face** (her own face shader, in `pilot.ts`):
  - The burner light is a warm orange wash (1.0, 0.56, 0.28), soft-clamped (`1 - exp(-x)`, max 0.36).
  - It is split into one toon band by the facing toward the nozzles.
  - Only 30% of it lifts the sun's shade, so the face keeps its cel band under the glow.
  - In `pilot_burner` she now has a shaded side, blush and a warm tint, with no white-out.
- **Seam:** the head had no duplicate vertices. The line was the 32-segment sphere's faceting showing
  through the toon step. The head is now a 48x28 sphere, and no seam is visible in either frame.
- **Clothes:** her copies of the uber shader are patched at load (`toneGlow`, only on her cloned
  materials; `materials.ts` is untouched):
  - The glow emission is soft-clamped on its brightest channel, so the hue is kept and pale cloth goes
    orange instead of white.
  - The glow lifts only 15% of the shade, so the toon bands stay.
  - The jacket still warms under the burner.
- **Collar:** it is its own object and material (`collar`, ink id `ID.rider`), so the ink draws its edge
  against the jacket and the scarf.
  - The albedo is a warm cream (`#d4b588`, was `#efe1c4`), so it never takes the blue-grey "white in
    shade" path.
  - The shape is a flat band on the shoulders, open at the front where it turns down into two lapels.
    It no longer reads as a life ring or plate.

## Cheap improvements also done
- **Torso:** the hem flares (0.172 vs 0.158), with a waist at 1.02 m, a fuller chest and squarer
  shoulders.
- **Arms:** they taper from 5.8 cm at the shoulder to 3.6 cm at the wrist, under a knit cuff.
- **Scarf stripes:** warmer cream (`#e9c79b`). The tip no longer reads as a pale blue-grey band.
- **Hand clipping:** the hands no longer sink into the rim (the `pilot_look` nice-to-have). They sit on
  the leather roll.

## Not done (nice-to-haves)
- Strand clumps or separate fringe locks in the hair.
- A thumb curled over the T bar.
- A dedicated cinematic pilot spot. The cinematic was re-recorded with her in it, though.

## Cinematic
- **Opening reframed (`cinematic.ts`, approved narrow edit):** for 0–8 s a close shot rides on the
  basket and is laid over the existing path. It is defined in the basket's frame (yaw 0.4), and the
  Catmull-Rom keys are not touched.
  - The shot holds to 2.5 s, then eases (smoothstep) into the original path by 8 s.
  - From 8 s on, `pose()` is the original path exactly. `keepOffPath` (10–30 s) and the reveal are
    unchanged.
- **In shot:** the pilot pulling the lever down and looking up, with the flame, the glow and the
  envelope's lower throat.
- **The pilot follows the cinematic burner:** `ride.ts` sets `f.burner = cine.burning(s)`, which drives
  her pull/hold clip during the 0–6.5 s burst.
- **Re-recorded:** `recordings/balloon-ride-cinematic.mp4`.
  - h264 (NVENC), 1920x1080, 60 fps, 3000 frames, 50.0 s, 248 MB.
  - Recorded on the RTX 4060 (D3D11).
- **Frames checked at 1, 3, 6, 10, 20 and 40 s:**
  - At 1 and 3 s she is clearly at the lever under the flame.
  - At 6 s the shot is pulling back.
  - 10, 20 and 40 s match the previous recording: mean difference 1.9–2.9/255, and only 83–218 px
    over 24, which is encode noise.
- The frames were deleted afterwards.
