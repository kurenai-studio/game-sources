# Rat

`Rat extends Area2D` holds one rat's needs, personality, status, relationships,
and activity state. `RatManager` drives its simulation ticks and scheduled
decisions; the rat does not run its own timer.

## Need is condition; urgency is want

- **Need value** (`RatState.needs`) records how fulfilled each of the five needs is,
  from `-100` (deprived) to `+100` (satisfied). It changes through baseline
  decay and applicable location or job effects. A need value is not a measure
  of how strongly the rat wants to act.
- **Urgency** is the rat's subjective level of want for that need. Its
  per-need `Curve` maps the current need value to a `0..1` urgency. The curves
  have different shapes because the same need value need not feel equally
  pressing for nutrition, social contact, stimulation, energy, and vice.
  Urgency may be nonzero when a need is neutral or positive.
- **Location pull** describes how appealing a location is for a need. The
  evaluator combines the rat's urgency with each location's pull to choose
  where to go. Pull is separate from the location's physical effect on the
  need; choosing a location does not itself satisfy a need.
- **Stress** is a mental state that changes over time with how the rat feels.
  Need conditions and the importance felt through urgency inform that response.
  In the stress calculation, a need whose net change is positive
  after decay and applicable modifiers samples its urgency as if fully
  satisfied (`+100`); the stored need and location-choice urgency still use
  the actual value. This does not add a
  separate independent "Current feeling" stat. `Rat` caches the resulting
  effective average urgency (`0..1`) for its stress tick and debug display.
  See `entities/rat/systems/stress/` for the tier calculation and tunable rates. Active work
  at a station for the assigned job adds a flat
  stress rate after the need-based tier is selected; assignment or travel alone
  does not.

For example, `social = 0` describes a neutral level of social fulfillment. It
does not imply that the rat has no desire to socialize. Read the social urgency
curve to find that desire.

## Runtime responsibilities

GameClock emits ticks to RatManager. The manager requests each rat's update
draft, gathers location/job rates, invokes NeedSystem then StressSystem,
and asks Rat to validate and apply the completed draft. Rat has no tick entry
point. Need decay continues during travel. While the rat is at a location,
location modifiers offset that decay; job modifiers also apply when it is
working at one of its assigned job's stations. `request_destination_choice()` runs
only on the rat's assigned decision slot: Rat supplies copied needs to NeedSystem
for urgency sampling, then asks `LocationChoice` to pick a location using those
urgencies and manager-supplied options. `_process()` delegates travel to
`_travel_to_destination()`. On arrival,
Rat records its location, clears its destination, becomes idle, and signals
RatManager. The manager checks current assignment and requests active work at an
assigned station through `request_start_work()`; Rat owns acceptance. Stationary
assignment changes also start eligible work or stop invalid work through
`request_stop_work()`, while travelling rats continue.

Rat privately owns an exported `RatState` Resource created during initialization.
`get_state_snapshot()` returns a native deep copy for consumers to read.
Attribute Resources and relationships are independent; location and destination
are stable StringName IDs. Editing this detached copy leaves the rat unchanged.
`request_state_replacement()` validates a complete proposed state and accepts
an owned copy, preserving bounds and emitting only after an actual change.
`get_state_update_draft()` creates a narrow `RatStateUpdateDraft` directly from
current rat values: rat ID, independently copied needs, stress, and effective
average urgency. Both systems modify the draft through `apply_tick_effects()`.
`request_state_update()` checks ownership and complete result validation before
applying any values. Changed results emit `state_changed` once after application;
unchanged or rejected drafts emit nothing. Stress is compared after clamping.
Destination changes, arrival, and work requests follow the same settled
`state_changed` contract. RatManager forwards these events by rat ID.

See `data/attributes/` for the rat's value Resources, `data/state/` for owned
state and captured copies, `data/simulation/` for detached update drafts,
`config/needs/` for decay and urgency
configuration, `systems/decisions/` for destination choice, and
`config/generation/` for starting values. `rat_constants.gd` holds the activity
and crisis enums. Per-vice tracking and job skills remain deferred; the current
simulation uses one `vice_satisfaction` need. Scalar owner relationship,
currency, crisis, and activity belong to RatState rather than an Other Resource.
