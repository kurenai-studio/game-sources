# Combat

Code: `src/combat/armor.ts`, `src/combat/shells.ts`, `src/combat/ballistics.ts`, `Tank.fire`; numbers: `COMBAT`, `AMMO`, guns in `TANKS` (`src/config/`)

## Firing

- The shell leaves the muzzle along the barrel direction with Gaussian dispersion: reticle radius (m per 100 m) = `dispersion · (1 + bloom)`, circle = 2σ, clipped at 2σ.
- `bloom` grows with movement (0.12 per m/s), hull rotation (0.6 per rad/s), turret rotation (0.3), firing (+2.5) and decays exponentially with the time constant `aimTime / 3`.
- Damaged gun: dispersion ×1.5 for 12 s.
- Elevation is solved analytically (`solveElevation`) from the range and the height difference to the aim point: low trajectory for tanks, high for howitzers. The resulting world direction is converted into the turret frame, so hull pitch and roll on a slope are compensated. The shell flies with gravity 9.8.

## Shells (keys 1/2/3)

| Type | Penetration | Damage | Velocity | Normalisation | Ricochet | Special                           |
| ---- | ----------- | ------ | -------- | ------------- | -------- | --------------------------------- |
| AP   | ×1.0        | ×1.0   | ×1.0     | 5°            | > 70°    | standard                          |
| APCR | ×1.32       | ×0.88  | ×1.25    | 2°            | > 70°    | up to 12 rounds                   |
| HE   | ×0.3        | ×1.45  | ×0.85    | 0°            | none     | splash, damage on non-penetration |

- Switching the type on a loaded gun costs up to 2.5 s of reload.
- A click during the last 0.3 s of the reload is remembered: the shot goes off the moment the gun is loaded (switching the shell cancels it). The end of the reload for guns with a reload of 2 s or more is marked by a short beep.
- Howitzers (SU-122, Hummel) are loaded with HE by default, splash 6–7.5 m.

## Hit (`testShell`)

- The flight segment for the frame is tested against the hull and turret boxes (OBB), houses, rocks and terrain. The first along the path wins. A box inside which the segment starts does not count as a hit: a barrel pushed into a wall fires through it outward. Destroyed tanks are cover: the shell is absorbed without damage.
- The face is chosen by the normal: front / side / rear / roof; the turret has its own values. Hull side below the top of the running gear = **track**.
- Impact angle θ between the shell and the plate normal. If calibre ≥ 3 × thickness — no ricochet, normalisation ×1.4. Otherwise AP/APCR ricochet at θ > 70°.
- Effective armour = nominal / cos(θ − normalisation). Penetration = `pen · (1 ± 25 %)` ≥ effective → damage `dmg · (1 ± 25 %)`.
- HE on non-penetration: `dmg · 0.5 − armour · 1.1` (not less than 0).

## Weak zones (`ZONES`, `plateAt` in `src/combat/armor.ts`)

The hitboxes stayed the same (hull and turret) plus a small commander's cupola box; the zone is determined by the hit point inside the box, so the shell test gets hardly any more expensive.

| Zone               | Where                                                                                                                               | Armour                                                                                           |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Lower glacis       | hull front, lower 45 % of the height                                                                                                | `armor.lowerFront` or front × 0.75 (100 mm on the Tiger)                                         |
| Gun mantlet        | turret (casemate) front, across the mantlet width (`gunLook.mantletW`, otherwise 35 %) and ±30 % of the height around the trunnions | turret front × 1.3; a penetration damages the gun with a 50 % chance                             |
| Commander's cupola | a 0.6 × 0.6 × 0.3 m box on the roof where `turretLook.cupola` is (none on open casemates)                                           | turret side × 0.7, from above — roof; a penetration wounds the commander with a 60 % chance      |
| Side skirts        | hull side when `hullLook.skirts`, turret side and rear when `turretLook.skirts`                                                     | +8 mm against AP and APCR; HE bursts on the skirt: no penetration, non-penetration damage × 0.35 |

- The reticle is coloured by the plate under it: a line from the muzzle to the aim point on the tank; the line under the reticle shows the effective armour of that plate and the zone («нижний лист» (lower glacis), «маска» (mantlet), «башенка» (cupola), «экран» (skirt)) or «рикошет» (ricochet). Howitzers keep the old estimate by projection.

## Modules

| What        | Condition                                                                        | Effect                                                                                                                 |
| ----------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Track       | hit on the running gear, 60 %                                                    | 45 s without driving or turning; hull damage ×0.5                                                                      |
| Fire        | penetration of the engine compartment (rear or rear 30 % of the hull side), 25 % | 25 HP/s for 8 s; fire extinguisher (F), 1 pc.                                                                          |
| Engine      | the same penetration without fire, 40 %                                          | speed and acceleration ×0.5, 15 s                                                                                      |
| Gun         | penetration of the turret front, 15 % (through the mantlet 50 %)                 | dispersion ×1.5, 12 s                                                                                                  |
| Turret ring | penetration of the lower 30 % of the turret (not casemate), 35 %                 | turret rotation ×0.4, 15 s                                                                                             |
| Ammo rack   | penetration of the hull side, turret side or rear                                | 4.5 % — detonation: tank destroyed, the turret is torn off and thrown up; another 18 % — damage: reload ×1.35 for 15 s |

- Repair kit (R), 1 pc., repairs everything at once: track, engine, turret ring and gun. Bots use it when a track is knocked off or the engine is damaged.
- New crits go to the «Крит» (Crit) ribbon and into the crit statistics.

## Ammunition (`AMMO_LOAD`, `src/tank/ammo.ts`)

- Shells are finite. The whole load is enough for 240 s of continuous fire (`240 / reload`, from 8 to 250 rounds, or `gun.rounds`): T-34-85 43, Tiger 33, IS-2 21, KV-2 12, autocannons 250.
- Layout: APCR 20 % (no more than 12), the second running shell 25 % (HE on guns, AP on howitzers), the rest is the standard one. Howitzers and "derp guns" have no APCR; rocket artillery carries only HE salvoes.
- When the selected shell runs out, the gun switches to the standard one, and if there is none — to the one with the most rounds. Completely empty — the gun is silent.
- Resupply: standing still (up to 2 m/s) within 35 m of the centre of own base, every 0.5 s adds 5 % of the full stock of each type (from zero to full takes about 10 s). The shell panel shows counters, an empty type is red, plus the line «боекомплект на исходе» (ammunition running low) (below 15 %).
- Used consumables are returned there too: repair kit, first aid kit and fire extinguisher — all together after 5 s on the base (`kitTime`). The panel line is «пополнение: снаряды и расходники» (resupply: shells and consumables), on completion the log says «Пополнение завершено» (Resupply complete).
- Bots with less than 15 % of the stock (unless hunting the last enemy) drive to their base, fill up to 90 % and re-plan the battle from there.

## Crew (`CREW`, `src/tank/crew.ts`)

- A penetration wounds, with a 30 % chance, one crew member from the compartment behind the penetrated plate: turret — commander, gunner, loader; hull front — driver; hull side — driver or loader; roof — anyone; rear (engine) and running gear — nobody. HE fragments through the roof — 12 % × proximity to the burst (×2.5 on open casemates).
- A wounded member (until a first aid kit) degrades the vehicle: commander — view range ×0.85, gunner — dispersion and aim time ×1.25, driver — speed, acceleration and hull rotation ×0.85, loader — reload ×1.25.
- First aid kit (E), 1 pc., heals everyone. Bots use it on their own after 3–8 s × (1.3 − skill).
- The status shows a crew line (wounded in red); crit counts are kept for ribbons: wound, ammo rack, gun.

- Ramming: closing speed > 3 m/s → damage `1.4 · speed · mass ratio` (mass = hit points). A pair is resolved once per frame (from the side of the tank with the smaller uid), both vehicles lose speed.
- Rocket artillery (`gun.salvo`): a shot launches a salvo, the remaining rockets leave on their own at `salvoInterval` intervals (`Tank.salvoTick`, polled by the game loop), each along the current position of the rails with its own dispersion; the reload counts from the first rocket. HE only, an attempt to switch the shell is rejected.
- Empty rack: no shot happens, the gun switches to another shell on its own with the switch delay (see "Ammunition").
- HE splash: everyone within the radius takes `0.6 · dmg · (1 − d/r)` minus `roof · 1.1`, 30 % chance to knock off a track.
- The kill is credited to whoever dealt the last damage (including fire and ramming). A destroyed tank becomes a wreck: dark, turret askew, smoking. After an ammo rack detonation the turret flies off (9–13 m/s upward, 1.5–4 m/s sideways, tumbling) and lands on the hull roof or on the ground nearby — also cover only by the hull (the turret box stays in place).

## Artillery view (SPG, Shift)

Code: `src/fx/artyView.ts`, `src/fx/groundMarks.ts` (`splashRing`), `src/game/combatFeedback.ts` (the «Мимо» (Miss) marker)

- A "satellite" camera looks at the aim point from above; the on-screen reticle circle is hidden, instead a dispersion ellipse is drawn on the ground: radius = `reticle · range / 100`, stretched along the line of fire by `1 / sin(angle of fall)`. Colour: white, by the penetration chance over a target (green / orange / red), red when out of range.
- Howitzer ballistics are gamey (`HOWITZER` in `ballistics.ts`): flight time = 2 s + range / 150 (300 m → 4 s, 900 m → 8 s), "gravity" 40 m/s², velocity and angle are computed for that time (angle 47–55°, apex 80–320 m, over any hills). Range 1150 m — the whole map. Bots and the player use the same law.
- The trajectory from the muzzle to the aim point is shown as an arc; `aimInfo` shows the flight time or «ВНЕ ДОСЯГАЕМОСТИ» (OUT OF RANGE).
- Camera: height 90–520 m (wheel), 260 by default; the mouse moves the aim point 1:1 over the ground (screen "right" = (−cos yaw, sin yaw)); fog in this mode is pushed back (900–2400 m). Enter: Shift or wheel forward from the closest arcade distance; exit: Shift or wheel back from the maximum height.
- Own shells in flight are marked with a marker of constant screen size. Any HE shell with splash > 3 m draws an expanding ring of the splash radius on the ground (0.9 s).
- If the direct hit and the fragments dealt no damage, «Мимо» (Miss) pops up at the impact point; damage is shown by the usual floating numbers.

## Gun marker

Code: `src/combat/trace.ts` (`traceShot`), `src/hud/reticle.ts` (`updateGunMarker`), `artyView.ts` (`gunRing`)

- The turret traverses at `turretTurn`, the barrel elevates at 1.5 rad/s, so the gun lags behind the reticle. The shell always leaves along the real barrel (direction from the gun's world matrix in `Tank.fire`).
- A yellow marker shows where the shell would land if fired right now: a parabola from the muzzle along the current direction with the real velocity and gravity (for howitzers — the `HOWITZER` law), in segments of ≈ 7 m against tanks, houses and terrain. In arcade and sniper view it is a small circle on screen (clamped to the edge if the point is off-frame), in artillery view — a ring on the ground at the real impact point.
