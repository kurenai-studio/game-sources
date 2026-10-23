# Rat Ownership Refactor — Behavior Baseline

Captured before tick coordination changes. Reference commit: `4ac4c5f`, plus the existing uncommitted snapshot interface and documentation changes. This describes the inspected working tree, not just that commit.

## Evidence

The rules below were checked against the current scripts and scene resources. This capture does not claim a new visual test pass. The preceding stress sprint was manually confirmed by the maintainer; the new snapshot interface was checked headlessly. Numerical scenarios below are comparison targets from the sprint, not new measurements.

## Clock and update order

- `GameClock` emits a tick every one simulation second; 60 ticks represent one game-hour. Time scaling affects the clock and movement.
- `RatManager` iterates the colony's rats. For each rat it first calls `apply_game_tick_effects(job)`, then checks whether a location decision is due.
- Rats occupy one of 15 decision slots. A rat's decision is reconsidered when its slot matches `tick_count % 15`; need and stress effects still happen every tick.
- Inside Rat: apply and clamp all need changes, calculate effective average urgency, then apply and clamp stress. A decision therefore uses updated needs and affects subsequent movement/effects.

## Needs and effects

- Five needs: nutrition, energy, stimulation, social, vice satisfaction. Each is bounded to `-100..100`; all begin at `80`.
- Every need decays by `-5` per game-hour, including during travel.
- At a current location, add that location's hourly modifiers. While actively working the assigned job there, also add that job's hourly modifiers. Divide the net rate by 60 for each tick.
- Working requires a non-null job, a current location in that job's station list, and activity `WORKING`. Assignment alone is insufficient.
- Pantry adds nutrition `+20/h` and energy `+2/h`: net nutrition `+15/h`, energy `-3/h`, remaining needs `-5/h`.
- Location appeal (`pull`) influences choice; it does not directly improve needs.

## Stress

- Stored stress is bounded to `0..100`, initially zero. Effective average urgency begins as `NAN` until the first simulation update.
- After needs change, sample each need's urgency curve. For any positive net hourly rate, sample the need's maximum value instead of its stored value. This also applies when the need is already capped. A zero or negative rate uses the actual need value.
- Average all five samples equally. This is subjective urgency, not average raw need or an additional need field. Location choice continues using actual need values.
- Select the first tier whose upper bound is strictly greater than the average; if none matches, use the final tier. Exact boundaries enter the next tier.

| Average urgency | Need-derived stress per game-hour |
| --- | ---: |
| Below 0.28 | -6 |
| 0.28 to below 0.34 | -3 |
| 0.34 to below 0.38 | -1 |
| 0.38 to below 0.42 | 0 |
| 0.42 to below 0.48 | +2 |
| 0.48 to below 0.58 | +6 |
| 0.58 and above | +12 |

- Active assigned work adds `+3/h` to the selected rate; assignment or travel adds nothing. Divide the combined rate by 60 and clamp stored stress through its setter.

## Choice, movement, and jobs

- Location options follow LocationManager's direct child order. Only positive pull axes participate in each location's score.
- Score is the power mean (power 3) of urgency times normalized pull, plus employment pressure for an assigned job's stations. Locations without positive pull axes are skipped. Equal scores retain the first candidate.
- Rat owns its destination. Selecting its current location returns without changing activity. A new destination clears the current location and selects travel-to-work or travel-to-location state. No destination selects idle.
- Movement uses `move_toward` at 400 units per scaled second. Arrival assigns the current location, clears the destination, and enters working or idle based on the travel state.
- JobManager owns assignments. Assigning/unassigning changes the map without immediately changing the rat's activity or destination; the next effects/decision read the new assignment.

## Debug and ownership

- One selected rat is inspected at a time. The overlay has foldable stat groups and a read-only stress breakdown. Stress can be edited through Statuses.
- Breakdown shows cached average urgency, derived need tier/rate, current work contribution, and combined rate. Before the first tick, it shows placeholders.
- Stat getters currently expose live Resources; debug edits write directly to them. Enter converts text with `to_float()` without explicit input validation. Numeric readouts use zero decimal places; stress header uses two and urgency uses three.
- Individual stat setters emit refresh signals during an update. The panel can therefore observe partially updated values. Live refresh also replaces unfinished input.
- Speed cycles `1x → 5x → 10x → 0.5x → 1x`. Pause stores the previous scale and sets scale to zero. Its icon is set only at initialization. Changing speed while paused can resume time while the pause flag remains set; later resume can restore a different scale from the speed label.
- The new snapshot methods are present but the tick loop and panel do not use them yet. Snapshots copy Needs; applying preserves live Resource identity, clamps values through setters, and emits one final signal. Currently only wrong-rat IDs are explicitly rejected.

## Comparison scenarios

| Scenario | Expected comparison |
| --- | --- |
| Travelling, no job | All needs decay `-5/h`; no work stress |
| Stationary in Pantry | Nutrition `+15/h`; energy `-3/h`; nutrition stress sample uses full value |
| Assigned job, travelling to its station | No job modifiers or work stress |
| Working assigned job at its station | Baseline + location + job need effects; `+3/h` work stress |
| Needs at either bound; stress at 0 or 100 | Setters preserve bounds |
| No job; nutrition -80, others +50, stress 60 | About .509 urgency and `+6/h` before Pantry; about .321 and `-3/h` while eating, allowing for tick changes |
| Same state and ordered location options | Same selected location, including tie order |
| Two generated rats | Both update each tick; their decisions remain scheduled by their own slots |

Preserve gameplay rules above. Deliberate improvements in this sprint are complete-update inspection, detached ownership, input validation/draft preservation, synchronized time controls, and explicit error handling. Compare those against the agreed design rather than reproducing the listed UI quirks.
