# Level notes: chapter 1 (`game/levels/chapter1.tscn`)

One straight run from x=0 to the exit at x=10900, left to right. Measured against the player: jump rises 128 px, a ledge
can be caught up to about 240 px above the feet, a crate is 56 px, run speed 260 px/s, walk 120 px/s. The ground is
`Floor` (9600 px wide, top at y=0). Ledge zones were placed from the real outline of each wall by measuring its polygon, not
by hand, because the broken-column outline moves the top by up to 18 px.

## Layout

| x | What | Teaches / asks | Checkpoint after |
|---|---|---|---|
| 150 | start | | `CheckpointStart` |
| 520 | `Log1`, 64 px high | jump | |
| 1100 | `Wall1`, 195 px, `Ledge1` | up held plus jump, the hands catch the edge | |
| 1760 | `Rope1` (anchor y=-400) and `RopePlatform` (top y=-186, x 1940 to 2240) | grab the grip at the top of a jump, pump right, let go on the way up when the swing passes 15 degrees. No ledge on the platform and too high to jump: the rope is the only way | `CheckpointRope` 2330 |
| 2560 to 3200 | puzzle 1: `Crate1`, `Plate1` (3000), `Door1` (3200) | push the crate onto the plate; the crate keeps the door open, hop over it to pass. Over-pushing jams it against the door: pull it back | `CheckpointDoor1` 3420 |
| 3900 | puzzle 2: `LeverPlatform` (top y=-163) with `Ledge2`, `Lever2`, `Door2` (4350) | climb the platform, pull the lever, drop down and walk through | `CheckpointLever` 4500 |
| 4750 to 5150 | puzzle 3: `Crate2`, `Wall2` (305 px, `Ledge3`) | too high to jump to: push the crate against the wall, jump onto it, jump again with up held | `CheckpointWall` 5400 |
| 5550 | chase: `ChaseTrigger` wakes `Monster` at x=5100 (190 px/s, stops at 7300) | run; `Log2` (6000), `Log3` (6500) to hop; `Wall3` (6950, 142 px, `Ledge4`) to climb. Dying restarts the chase 350 px behind; the monster stays asleep until the trigger is crossed again | `CheckpointPen` 7480 |
| 7550 | `BossTrigger` wakes `Boss`; pen x 7900 to 8500 | see below | `CheckpointMidFight` 8640 |
| 9050 | after the mini-boss | `CheckpointFinal`, `FinalTrigger` (9120) wakes `FinalBoss` | `CheckpointFinal` 9050 |
| 9500 to 10400 | the final boss pen | see below | `CheckpointFinalMid` 10600 |
| 10900 | `ExitTrigger` | calls `Chapter.finish`: fade to black, wake-up scene, credits | |

## Boss pen

The player enters from the west into the west alcove. Entering the pen while the boss is free is fatal; the alcoves are out
of its reach.

1. West alcove: `LeverWest` (7730) fires `ShockTrap` (7840). Pull it when the boss has crashed into the west edge (state
   `recover`): hit 1, phase 2.
2. Cross the pen while it is held down (about 6 s), light `CheckpointMidFight` (8640) in the east alcove.
3. East alcove: `LeverEast` (8670) fires `DropTrap` (8440). Pull it when the boss has crashed into the east edge: hit 2, it is
   down.
4. Walk out to the exit.

Both traps rearm 8 s after they fire, so a pull at the wrong time costs time, not the chapter.

## Final boss pen

A bigger pen (x 9500 to 10400) and a bigger boss (`FinalBoss`, head 210x240, seven tentacles). Three hits, three phases:

| Phase | After | Speed | Charges in a row | Recovery after a crash | How to hit it |
|---|---|---|---|---|---|
| 1 | start | 1.0x | 1 | 1.2 s | wait for the crash at the west edge, pull `LeverFinalWest` (electric, 9440) |
| 2 | 1 hit | 1.4x | 2 | 0.86 s | cross the pen while it is held, wait for the crash at the east edge, pull `LeverFinalEast` (boulder, 10340) |
| 3 | 2 hits | 1.8x | 3 | 0.33 s | too quick for the boulder: go to the second lever of the east alcove (`LeverFinalFire`, 10710) and light the fire (`FinalFireTrap`, 10390) once the boss has shaken off its stun; it burns 3.5 s and holds the boss when it runs into it |

Alcoves: west lever at 9270, east levers at 10630 (boulder) and 10710 (fire) (the bigger boss reaches about 150 px past its edge, so they sit 230 px
out). Death in the pen returns to `CheckpointFinal` (hits reset) or, once the east alcove is reached, `CheckpointFinalMid`
(hits so far kept).

## Resettable objects per section

Everything that holds state is in group `resettable` and is saved at each checkpoint and put back on death: `Crate1`,
`Crate2`, `Plate1`/`Door1`, `Lever2`/`Door2`, `Rope1`, `Monster`, `ChaseTrigger`, `Boss`, `BossTrigger`, `ShockTrap`,
`DropTrap`, `LeverWest`, `LeverEast`, `FinalBoss`, `FinalTrigger`, `FinalShockTrap`, `FinalDropTrap`, `LeverFinalWest`, `LeverFinalEast`, `FinalFireTrap`, `LeverFinalFire`. Traps and the boss are restored together, so a checkpoint never keeps a spent trap
with a live boss.

## Ambience

Four `AudioZone`s fade the ambient layers (dB; a layer not listed fades out over 2.5 s):

| Zone | x | wind | drips | drone |
|---|---|---|---|---|
| `ZoneIntro` | 0 to 2300 | -12 | | |
| `ZonePuzzles` | 2300 to 5400 | -18 | -22 | -36 |
| `ZoneChase` | 5400 to 7450 | -24 | | -14 |
| `ZonePen` | 7450 to 9200 | -30 | | -8 |
| `ZoneFinal` | 9200 to 11200 | -36 | | -4 |

## Light budget

Shadow-casting lights: `Light1..5` at 900, 3300, 5500, 7600, 9800 and `Shaft1..5` at 2100, 4400, 6600, 8500, 10850, about 1100 px apart,
plus the player's lantern. At most 4 are ever near the screen (tested). Measured at 1920x1080 on an RTX 3060, vsync off:
461 fps average, 309 fps 1% low, worst frame 4.1 ms over 17 spots incl. the final pen (`tools/fps.gd`).

## Tests

`tests/test_chapter.gd`: each section played from its checkpoint (a bot may not die), the whole chapter in one run,
skip attempts (door, rope platform, tall wall must hold), crate over-push, standing still in the chase, the light budget,
and the human-like bot of `test_player_sim.gd` on every stretch. `TEST_ONLY=chapter tools/test.sh`.
