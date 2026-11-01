# Dreamrun — GDD (slice)

A child is trapped in a nightmare, chased by a monster. Environmental puzzles and traps push the monster back. No dialogue, no UI text during play.

## Slice scope (`PROMPT.md:48`)
1 chapter, 1 monster, 3 puzzles, 1 chase, 1 trap-based mini-boss (2 phases), checkpoints, pause menu (icons only).
Post-slice (done): audio manager, local save, wake-up cutscene, 3-phase final boss.

## Milestones
| M | Scope | Content |
|---|---|---|
| M0 | slice | skeleton, test runner, input map, ledger |
| M1 | slice | player (idle/walk/run/jump/fall/land), test room, parallax, lights, grain/vignette |
| M2 | slice | fog, light shafts, CanvasModulate |
| M3 | slice | crate, lever, plate, door, rope, ledge; push/pull/climb states |
| M4 | slice | monster chase, die state, checkpoint, respawn |
| M5 | slice | trap system, mini-boss, pause menu (done) |
| M6 | slice | chapter assembly (3 puzzles, chase, mini-boss) (done) |
| M7 | post-slice | audio, local save, wake-up cutscene, credits (done) |

## Input
`move_left`, `move_right`, `jump`, `interact`, `climb_up`, `climb_down`, `pause` — keyboard + gamepad. Walk vs run: no extra action; speed scales with stick deflection and, on keyboard, ramps from walk to run over `run_ramp_time` (AnimationTuning/controller export).

## Interactions (M3)
| Object | How |
|---|---|
| Crate | Stand next to it, **hold** `interact`, move: toward it = push, away = pull. Slow (`grab_speed`). Jump or release lets go. |
| Lever | Press `interact` next to it. Emits `toggled`; wire it to `Door.set_open` in the scene. |
| Pressure plate | Stand on it or leave a crate on it. Emits `pressed_changed`; wire to `Door.set_open`. |
| Door | Stone gate: opens slowly, slams shut fast. |
| Rope | Hangs still until grabbed. Press `interact` in mid-air near the knot; your momentum starts the swing. Hold left/right to pump (it tops out near 55 deg). `jump` or `interact` lets go and you fly off along the swing. |
| Ledge | Jump toward a platform (or hold `climb_up`); once your hands reach the edge you catch it and climb up. Only platforms within reach of a jump work; walking off the edge the other way never re-grabs. |

## Chase, death, checkpoints (M4)
- The monster is invisible until its `Trigger` fires, then walks in at a fixed speed and kills on contact. It is silent; menace is scale.
- Touching it plays a collapse, fades to black and respawns the player at the last `Checkpoint` in under 1 s.
- On a checkpoint every node in group `resettable` (crate, door, lever, rope, monster, trigger) saves its state; on death they all
  restore it. The monster restarts `respawn_lead` px behind so it cannot kill on arrival.

## Targets
60 fps at 1080p, at most 4 shadowed lights per screen (lantern + static + light shafts count), measured per visual milestone. M1 measured 145 fps (vsync-capped, editor window).

## Traps

A trap is wired to a plate or lever in the scene and fires once per checkpoint. A boulder trap drops a rock that pins the monster only if the monster is under it when it lands, so the player times the plate; the pinned monster stays down for the rest of the section, the rock stays as a solid obstacle to hop over, and it crushes a player standing under it as it lands. An electric trap holds the monster for as long as it arcs and never hurts the player. A stunned monster stands still, shudders and does not kill. Put the plate or lever beyond the trap in the monster's direction of travel, or the monster reaches the player first.

## Mini-boss

The boss is penned in an arena and cannot be fought, only trapped. It patrols toward the player, rears up (telegraph), charges at the player's side of the pen and recovers at the edge. The player stays in an alcove beyond the pen's end, out of reach, and fires the trap there when the boss crashes into the edge: that is one hit. The first hit starts phase 2: faster, and each charge is followed by a second one back across the pen. The second hit, from the trap in the opposite alcove, brings it down. The player crosses the pen while the boss is held. Entering the pen while it is free is fatal. A checkpoint between the two alcoves keeps the first hit.

## Pause menu

Esc or Start pauses and shows three icons, no text: play (resume), circular arrow (back to the last checkpoint, with the usual fade), cross (quit). Left/right (arrows, D-pad) choose, accept (Enter, Space, A) confirms, Esc or Start again resumes. Pausing is ignored while the player is dying.

## Chapter 1

A single left-to-right run, about 9000 px: a log, a wall to climb and a rope to swing across (the controls), then three puzzles (crate on a plate holds a door; a lever on a platform opens a door; a crate as the step up to a ledge too high to jump to), a chase with the monster walking after you, and the mini-boss pen. Layout, checkpoints and trap order: `docs/level-notes.md`.

## Sound, saving, ending (M7)

Sound is ambient, never music or voice: a wind bed everywhere, drips in the puzzle country, a low drone that rises through the chase and is loudest in the boss pen. Footsteps follow how far the player walks (longer strides when running, a quiet drag when pushing a crate), landings thud in proportion to the fall, and a monster's rumble swells as it gets close and goes silent while it is held. The game saves each checkpoint to a local file and resumes there next time; a finished chapter starts over. Beating the chapter fades to black and wakes the child in a bright, warm bedroom (the opposite of everything before), then the credits roll and the game offers the chapter again.

## Final boss

After the mini-boss pen the chapter ends with a bigger pen and a bigger boss that takes three hits. Each hit starts the next phase: one slow charge with a long recovery, then a faster double charge, then a triple charge with almost no recovery, so the last trap has to be fired before the boss arrives. The traps: electric from the west alcove, boulder from the east one, and a fire from a second lever in the east alcove for the last hit (it burns for a few seconds, so it does not need the exact moment). Beating it fades to the wake-up scene.
